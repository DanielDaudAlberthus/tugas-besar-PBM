import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:library_app/providers/book_provider.dart';
import 'package:library_app/models/book.dart';
import 'package:library_app/providers/notification_provider.dart';
import 'package:library_app/models/app_notification.dart';
import 'package:library_app/providers/user_provider.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isUploadingImage = false;
  String? _selectedCategory;

  final List<String> _categories = [
    'Fiksi',
    'Non-Fiksi',
    'Sejarah',
    'Sains',
    'Biografi',
    'Fantasi',
    'Horor',
    'Romansa',
    'Komik',
    'Anak-anak',
    'Umum',
  ];

  final String _cloudinaryCloudName = 'df98xswpr';
  final String _cloudinaryUploadPreset = 'my_flutter_app_preset';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final ImageSource? pickedSource = await showDialog<ImageSource?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          actions: <Widget>[
            TextButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text('Galeri'),
              onPressed: () {
                Navigator.of(context).pop(ImageSource.gallery);
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Kamera'),
              onPressed: () {
                Navigator.of(context).pop(ImageSource.camera);
              },
            ),
          ],
        );
      },
    );

    if (pickedSource != null) {
      Future.microtask(() async {
        final XFile? pickedFile = await picker.pickImage(source: pickedSource);

        if (pickedFile != null) {
          setState(() {
            _selectedImage = File(pickedFile.path);
          });
        }
      });
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    setState(() {
      _isUploadingImage = true;
    });

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final result = json.decode(utf8.decode(responseData));
        return result['secure_url'];
      } else {
        final errorBody = await response.stream.bytesToString();
        print(
          'Cloudinary upload failed with status ${response.statusCode}: $errorBody',
        );
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal mengunggah gambar ke Cloudinary: ${response.statusCode}',
            ),
          ),
        );
        return null;
      }
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan saat mengunggah gambar: $e')),
      );
      return null;
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  void _addBook() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon pilih gambar cover buku.')),
        );
        return;
      }
      if (_selectedCategory == null || _selectedCategory!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon pilih kategori buku.')),
        );
        return;
      }

      final bookProvider = Provider.of<BookProvider>(context, listen: false);
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUserId = userProvider.currentUser?.uid;

      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda harus login untuk menambahkan buku.'),
          ),
        );
        return;
      }

      String? imageUrl;

      imageUrl = await _uploadImageToCloudinary(_selectedImage!);
      if (imageUrl == null) {
        return;
      }

      final newBook = Book(
        title: _titleController.text,
        author: _authorController.text,
        imageUrl: imageUrl,
        description: _descriptionController.text,
        isBorrowed: false,
        category: _selectedCategory!,
      );

      try {
        await bookProvider.addBook(newBook);

        final notification = AppNotification(
          id: '',
          title: 'Buku Baru Ditambahkan!',
          message:
              'Buku "${newBook.title}" (${newBook.category}) oleh ${newBook.author} sekarang tersedia di perpustakaan.',
          timestamp: DateTime.now(),
          type: 'new_book',
          relatedItemId: newBook.id,
          userId: currentUserId,
        );
        await notificationProvider.addNotification(notification);

        if (!mounted) return;

        Future.microtask(() {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Buku berhasil ditambahkan!')),
          );
          Navigator.of(context).pop();
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menambahkan buku: $e')));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookProvider = Provider.of<BookProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Buku Baru')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 150,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt,
                            size: 50,
                            color: Colors.grey,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_isUploadingImage) const LinearProgressIndicator(),
              if (_isUploadingImage) const SizedBox(height: 10),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Buku'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(labelText: 'Penulis'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Penulis tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCategory,
                hint: const Text('Pilih Kategori'),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kategori tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi Buku'),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Deskripsi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: bookProvider.isLoading || _isUploadingImage
                    ? null
                    : _addBook,
                child: bookProvider.isLoading || _isUploadingImage
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Tambah Buku'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
