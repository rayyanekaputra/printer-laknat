# printerfix

[english](README.md) | **bahasa indonesia**

script batch sederhana berbasis menu untuk memperbaiki masalah umum printer sharing di Windows 10 dan Windows 11. dibuat untuk menghemat waktu pada tiket IT support yang berulang.

by IT Indoguna Makassar with Sonnet 5.5

## masalah yang diperbaiki

- error 0x0000011b (level autentikasi RPC)
- error 0x00000709 (tidak bisa terhubung ke printer yang dishare)
- error 0x00000bcb dan 0x0000007c (driver tidak tersedia)
- antrian cetak macet dan print spooler yang crash
- pc host tidak muncul di jaringan
- profil jaringan diset public, bukan private
- masalah guest logon SMB pada build Windows 11 yang lebih baru

## cara pakai

1. salin `PrinterFix.bat` ke pc yang bermasalah
2. klik kanan file lalu pilih **run as administrator**
3. pilih opsi dari menu dan ikuti petunjuknya

## opsi menu

| tombol | fungsi |
|--------|--------|
| 1 | perbaiki 0x0000011b dengan mengatur `RpcAuthnLevelPrivacyEnabled` ke 0, lalu restart spooler |
| 2 | reset print spooler dan bersihkan antrian cetak yang macet |
| 3 | aktifkan file and printer sharing dan network discovery, ubah jaringan public ke private |
| 4 | atur service yang dibutuhkan ke automatic lalu jalankan |
| 5 | izinkan guest logon SMB yang tidak aman |
| 6 | longgarkan pembatasan Point and Print untuk instalasi driver |
| 7 | tambah printer sharing lewat local port yang mengarah ke `\\HOST\Share` |
| 8 | simpan kredensial jaringan untuk sebuah host di credential manager |
| 9 | diagnostik: status spooler, nilai registry, profil jaringan, printer, kredensial, tes port 445 |
| A | jalankan perbaikan umum (1 sampai 4) sekaligus |
| 0 | keluar |

## catatan

- script butuh hak administrator dan akan keluar kalau tidak punya
- opsi 1, 5 dan 6 menurunkan sebagian pengamanan, jadi pakai hanya di jaringan yang dipercaya. opsi 5 dan 6 meminta konfirmasi dulu
- 0x0000011b biasanya diperbaiki di host, tapi di beberapa kasus opsi 1 juga perlu dijalankan di client
- opsi 7 sering menghindari 0x0000011b dan 0x00000709 tanpa ubah registry, jadi coba itu dulu kalau bisa
- opsi 8 menampilkan password saat diketik, jadi hindari di layar yang dilihat orang lain
- file `.bat` tidak bisa di-code-sign. untuk mengatur kepercayaan, deploy lewat Intune, GPO atau tool RMM, atau ubah ke `.ps1` yang ditandatangani
- tes dulu di pc cadangan sebelum dipakai luas. gunakan dengan risiko sendiri

## kebutuhan

- Windows 10 atau Windows 11
- akun administrator
- PowerShell (sudah bawaan Windows)
