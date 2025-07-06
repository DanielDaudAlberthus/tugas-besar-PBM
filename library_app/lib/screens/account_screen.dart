// lib/screens/account_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:library_app/screens/edit_profile_screen.dart';
import 'package:library_app/screens/borrowed_books_screen.dart';
import 'package:library_app/screens/welcome_screen.dart';
import 'package:library_app/providers/user_provider.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  // >>> BARU: Metode untuk meluncurkan URL <<<
  Future<void> _launchURL(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Tampilkan pesan kesalahan jika URL tidak bisa dibuka
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tidak dapat membuka $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final currentUser =
            userProvider.currentUser; // Ambil data pengguna dari provider

        // Jika pengguna belum login (misalnya setelah logout sukses),
        // bisa arahkan kembali ke WelcomeScreen
        if (currentUser == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              (Route<dynamic> route) => false,
            );
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Akun Saya'),
            backgroundColor: Colors.blue,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings icon ditekan!')),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  // Informasi Profil Singkat
                  CircleAvatar(
                    radius: 50,
                    // Gunakan profileImageUrl dari Firebase jika ada, fallback ke default
                    backgroundImage: NetworkImage(
                      currentUser.profileImageUrl ??
                          'https://www.pngmart.com/files/23/Profile-PNG-HD.png', // Placeholder default
                    ),
                    backgroundColor: Colors.grey,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    currentUser.name, // Gunakan data pengguna dari provider
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    currentUser.email, // Gunakan data pengguna dari provider
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Edit Profil
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: userProvider.isLoading
                          ? null
                          : () {
                              // Non-aktifkan saat loading
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen(),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: userProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Edit Profil',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Opsi Menu Pengaturan
                  _buildSettingsOption(
                    context,
                    icon: Icons.history,
                    title: 'Riwayat Peminjaman',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BorrowedBooksScreen(),
                        ),
                      );
                    },
                  ),
                  // Anda mungkin punya ChangePasswordScreen
                  // _buildSettingsOption(
                  //   context,
                  //   icon: Icons.lock_outline,
                  //   title: 'Ganti Kata Sandi',
                  //   onTap: () {
                  //     // Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
                  //     ScaffoldMessenger.of(context).showSnackBar(
                  //       const SnackBar(content: Text('Halaman Ganti Kata Sandi (simulasi)!')),
                  //     );
                  //   },
                  // ),
                  _buildSettingsOption(
                    context,
                    icon: Icons.notifications_none,
                    title: 'Kelola Notifikasi',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Halaman Kelola Notifikasi (simulasi)!',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildSettingsOption(
                    context,
                    icon: Icons.help_outline,
                    title: 'Bantuan & Dukungan',
                    // >>> PERUBAHAN: Hubungkan ke _launchURL <<<
                    onTap: () {
                      const String githubRepoUrl =
                          'https://github.com/DanielDaudAlberthus/tugas-besar-PBM'; // Ganti dengan URL repo GitHub Anda
                      _launchURL(context, githubRepoUrl);
                    },
                  ),
                  const SizedBox(height: 30),

                  // Tombol KELUAR (Logout)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: userProvider.isLoading
                          ? null
                          : () async {
                              // Non-aktifkan saat loading
                              try {
                                await userProvider.signOut();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Anda telah keluar!'),
                                  ),
                                );
                                // StreamBuilder di main.dart akan otomatis mengarahkan ke WelcomeScreen
                                // Tidak perlu pushAndRemoveUntil secara manual lagi di sini.
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal keluar: $e')),
                                );
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: userProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.red)
                          : const Text(
                              'KELUAR',
                              style: TextStyle(fontSize: 16, color: Colors.red),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget pembantu untuk opsi pengaturan (tidak berubah)
  Widget _buildSettingsOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.blue, size: 24),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 17, color: Colors.black87),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
