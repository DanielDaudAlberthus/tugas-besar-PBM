// lib/screens/edit_profile_screen.dart
// ... (imports lainnya)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:library_app/providers/user_provider.dart'; // Pastikan ini di-import

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  // Tambahan untuk profile image URL jika ada
  late TextEditingController _profileImageUrlController;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _profileImageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      try {
        await userProvider.updateProfile(
          name: _nameController.text,
          email: _emailController.text,
          profileImageUrl: _profileImageUrlController.text, // Jika ada
        );

        // --- TAMBAHKAN if (!context.mounted) return; DI SINI ---
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );
        Navigator.pop(context); // Kembali ke layar sebelumnya
      } catch (e) {
        // --- TAMBAHKAN if (!context.mounted) return; DI SINI ---
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
    // final currentUserId = userProvider.userId; // Contoh penggunaan, sudah benar sekarang

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: userProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
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
                    // Jika Anda memiliki field untuk Profile Image URL
                    TextFormField(
                      controller: _profileImageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'URL Gambar Profil (Opsional)',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
