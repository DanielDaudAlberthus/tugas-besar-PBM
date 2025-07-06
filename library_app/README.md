# TUGAS BESAR PEMROGRAMAN BERBASIS MOBILE

## Kelompok 9

| Nama                  | NIM        |
|-----------------------|------------|
| Siti Intan Nia        | 4522210054 |
| Daniel Daud Alberthus | 4522210055 |
| Ihsan Adi Putra       | 4522210085 |

## MANAJEMEN PERPUSTAKAAN
## Tujuan Project
Tujuan dari aplikasi manajemen perpustakaan ini adalah untuk membangun sistem berbasis mobile yang dapat membantu pengguna dalam mengelola koleksi buku, peminjaman buku, pengembalian buku, dan notifikasi pengguna secara efisien. Aplikasi ini ditujukan agar siswa, pustakawan, maupun guru dapat lebih mudah berinteraksi dengan sistem perpustakaan digital tanpa harus hadir secara fisik

## Alasan Memilih Topik Manajemen Perpustakaan
Beberapa alasan pemilihan topik ini antara lain:
- Masalah peminjaman dan pengelolaan buku secara manual masih banyak ditemui di sekolah atau perpustakaan kecil.

- Topik ini dekat dengan lingkungan kampus dan pendidikan.

- Menjadi sarana belajar untuk menerapkan konsep CRUD (Create, Read, Update, Delete) di aplikasi Flutter.

- Dapat menggabungkan fitur Firebase, notifikasi, serta manajemen data (Provider/MVC).

- Menjadi solusi digitalisasi perpustakaan sederhana yang bermanfaat secara nyata.


## Tampilan Manajemen Perpustakaan User
# * Welcome Screen
Tampilan awal bagi pengguna yang belum memiliki akun dipersilahkan untuk melakukan pendaftaran terlebih dahulu
![WhatsApp Image 2025-07-06 at 12 43 20_22bbc0e4](https://github.com/user-attachments/assets/8123cb54-4b57-4fdd-b60b-c9a712188a0b)

# * Register Screen/Daftar Akun Baru
Gambar dibawah merupakan tampilan daftar akun perpustakaan bagi pengguna
![image](https://github.com/user-attachments/assets/ddd0ed7a-550b-4d33-b04c-e336c5598a91)

# * Tampilan Login
Bagi user yang sudah memiliki akun bisa langsung login dan inilah tampilannya
![WhatsApp Image 2025-07-06 at 12 50 53_dd2de086](https://github.com/user-attachments/assets/bde93e95-e912-418c-87cb-9ede0103cf7a)

# * Tampilan Beranda
* Setelah user berhasil login tampilan awal yang akan user lihat seperti dibawah ini.
User bisa langsung melakukan peminjaman buku di perpusatakaan<br> 
![image](https://github.com/user-attachments/assets/52929787-faf8-4177-b87e-b698571ae526)

# * Detail Buku
User bisa melihat detail buku terlebih dahulu sebelum melakukan peminjaman dan ketika user ingin meminjam maka user harus mengajukan jadwal peminjaman yang sudah ada di tampilan tersebut
* SEBELUM DI PINJAM<br>
![image](https://github.com/user-attachments/assets/3131a286-7f66-4fd9-94e4-23af0ff5972a)<br>

* KEtIKA DI PINJAM<br>
![WhatsApp Image 2025-07-06 at 12 45 19_c2cd8c2a](https://github.com/user-attachments/assets/dec4d81d-8225-4062-aa3c-514452f7cdbc)<br>

* KETIKA INGIN KEMBALIKAN<br>
![WhatsApp Image 2025-07-06 at 13 04 34_45bce174](https://github.com/user-attachments/assets/3ce96d9e-fe1a-4f4d-8abb-23187fbbf71d)<br>

* SETELAH DI KEMBALIKAN<br>
![image](https://github.com/user-attachments/assets/27f03340-b608-4158-b1de-3c5f6f95d7eb)<br>

* Tampilan ketika buku sedang dipinjam user lain<br>
![WhatsApp Image 2025-07-06 at 13 04 34_3ddfdeb4](https://github.com/user-attachments/assets/729eb139-69a4-4072-a84d-526d95b696cb)<br>

# * Akun
  Pada tampilan akun user bisa mencari jenis buku apa yang akan user pinjam
  ![WhatsApp Image 2025-07-06 at 12 45 51_f74fe4c2](https://github.com/user-attachments/assets/9b6b1334-1cd3-455b-a1b2-e26faab591ae)

# * Notification Screen
  Untuk notifikasi user bisa melihat bahwa peminjaman buku diperpustakaan sudah berhasil dan akan ada notifikasi ketika user sudah harus mengembalikan buku tersebut<br>
  ![image](https://github.com/user-attachments/assets/db93fec8-1601-43be-bcd3-5907c46b7484)<br>

# * Edit Profile Screen
  User bisa melakukan edit profile pada tampilan Akun saya<br>
  ![image](https://github.com/user-attachments/assets/76f976e5-f72a-48ae-b51f-d508ec0e72b5)<br>
  Tidak hanya itu user bisa melihat riwayat peminjaman buku yang sudah ataupun sedang dilakukan<br>
![image](https://github.com/user-attachments/assets/8890c6de-7b1b-4634-82ca-e8363eee2b99)<br>
  Tampilan riwayat user ketika sedang melakukan pemeinjaman buku<br>
  ![WhatsApp Image 2025-07-06 at 12 57 26_ff8de55f](https://github.com/user-attachments/assets/fac6e124-7328-4eb3-9e90-ba736c69ef3f)<br>

# Tampilan Manajemen Perpustakaan Admin
* Tampilan Beranda
  Admin bisa melihat bahwa buku itu sedang di pinjam oleh user
  ![WhatsApp Image 2025-07-06 at 12 47 48_e050553d](https://github.com/user-attachments/assets/b6956485-632d-4691-b9a8-4a8b18632155)
  Tampilan ketika admin ingin menginput buku baru untuk di perpustakaan
  ![image](https://github.com/user-attachments/assets/2e9f9a5b-0cde-40b7-b502-f36b6ee454fa)
* Tampilan Akun
  Tampilan akun admin dapat melihat riwayat peminjaman buku oleh user
  ![image](https://github.com/user-attachments/assets/12388c1a-937f-4f2f-90ce-cad2a88fdc91)

## KESIMPULAN
**## Kesimpulan

Aplikasi Manajemen Perpustakaan ini dibangun untuk memberikan kemudahan bagi pengguna dalam mengakses dan mengelola layanan perpustakaan secara digital. Melalui fitur-fitur seperti pencarian buku, peminjaman, pengembalian, notifikasi, dan riwayat aktivitas, aplikasi ini membantu siswa, guru, maupun pustakawan untuk berinteraksi tanpa harus datang langsung ke perpustakaan.

Dari sisi teknis, proyek ini juga menjadi media pembelajaran dalam menerapkan berbagai konsep Flutter, seperti manajemen state, routing antar halaman, integrasi Firebase, serta penggunaan komponen UI interaktif.

Dengan pengembangan yang berkelanjutan, aplikasi ini memiliki potensi untuk diimplementasikan secara nyata di lingkungan sekolah atau perpustakaan kecil sebagai solusi digitalisasi sederhana namun bermanfaat.**
