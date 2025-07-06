// lib/screens/edit_profile_screen.dart
import 'dart:io'; // Import ini
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:library_app/providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController
  _profileImageUrlController; // Tetap pakai ini untuk fallback URL input

  // >>> BARU: Variabel untuk gambar profil <<<
  File? _selectedImage;
  bool _isUploadingImage = false;

  // Konfigurasi Cloudinary (sama seperti di AddBookScreen)
  final String _cloudinaryCloudName =
      'df98xswpr'; // Ganti dengan Cloud Name Anda
  final String _cloudinaryUploadPreset =
      'my_flutter_app_preset'; // Ganti dengan Upload Preset Anda

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(
      text: userProvider.currentUser?.name,
    );
    _emailController = TextEditingController(
      text: userProvider.currentUser?.email,
    );
    _profileImageUrlController = TextEditingController(
      text: userProvider.currentUser?.profileImageUrl,
    );
    // Jika ada gambar profil yang sudah ada, set sebagai selectedImage awal (opsional, hanya untuk preview)
    // if (userProvider.currentUser?.profileImageUrl != null && userProvider.currentUser!.profileImageUrl!.isNotEmpty) {
    //   // Tidak bisa langsung dari URL ke File, ini hanya untuk preview sementara
    // }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _profileImageUrlController.dispose();
    super.dispose();
  }

  // >>> BARU: Metode untuk memilih gambar <<<
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
        // Gunakan Future.microtask untuk mencegah build-during-build errors
        final XFile? pickedFile = await picker.pickImage(source: pickedSource);

        if (pickedFile != null) {
          setState(() {
            _selectedImage = File(pickedFile.path);
          });
        }
      });
    }
  }

  // >>> BARU: Metode untuk mengunggah gambar ke Cloudinary <<<
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

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      String? newProfileImageUrl =
          _profileImageUrlController.text; // Default dari input teks

      // >>> LOGIKA BARU: Unggah gambar jika ada yang dipilih <<<
      if (_selectedImage != null) {
        final uploadedUrl = await _uploadImageToCloudinary(_selectedImage!);
        if (uploadedUrl == null) {
          // Jika gagal mengunggah, jangan lanjutkan menyimpan profil
          return;
        }
        newProfileImageUrl = uploadedUrl; // Gunakan URL yang diunggah
      }
      // >>> AKHIR LOGIKA BARU <<<

      try {
        await userProvider.updateProfile(
          name: _nameController.text,
          email: _emailController.text,
          profileImageUrl:
              newProfileImageUrl, // Gunakan URL gambar yang baru (dari input atau upload)
        );

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        Navigator.pop(context); // Kembali ke layar sebelumnya
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui profil: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(
      context,
    ); // Listen: true jika UI perlu update

    // Dapatkan URL gambar profil saat ini untuk ditampilkan
    final String? currentProfileImageUrl =
        userProvider.currentUser?.profileImageUrl;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body:
          userProvider.isLoading ||
              _isUploadingImage // Tambahkan _isUploadingImage ke kondisi loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // >>> BARU: Tampilan Avatar & Tombol Ganti Foto <<<
                    Center(
                      child: GestureDetector(
                        onTap:
                            _pickImage, // Panggil metode pilih gambar saat avatar diklik
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[300],
                              backgroundImage:
                                  _selectedImage !=
                                      null // Prioritaskan gambar yang baru dipilih
                                  ? FileImage(_selectedImage!) as ImageProvider
                                  : (currentProfileImageUrl != null &&
                                            currentProfileImageUrl.isNotEmpty
                                        ? NetworkImage(currentProfileImageUrl)
                                        : null), // Gunakan gambar dari network jika ada
                              child:
                                  _selectedImage == null &&
                                      (currentProfileImageUrl == null ||
                                          currentProfileImageUrl.isEmpty)
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey[600],
                                    ) // Placeholder jika tidak ada gambar
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.blue,
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            if (_isUploadingImage) // Tampilkan indikator loading upload
                              Positioned.fill(
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // >>> AKHIR BARU <<<
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!value.contains('@')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // >>> OPSIONAL: Field URL Gambar Profil (jika masih mau input manual) <<<
                    TextFormField(
                      controller: _profileImageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Gambar Profil (Opsional)',
                        hintText:
                            'Biarkan kosong untuk menggunakan gambar yang dipilih',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      // Non-aktifkan tombol jika sedang loading user atau mengunggah gambar
                      onPressed: userProvider.isLoading || _isUploadingImage
                          ? null
                          : _saveProfile,
                      child: const Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
