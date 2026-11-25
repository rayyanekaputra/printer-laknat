```text

░▒▓███████▓▒░░▒▓███████▓▒░░▒▓█▓▒░▒▓███████▓▒░▒▓████████▓▒░▒▓████████▓▒░▒▓███████▓▒░  
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░   ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░   ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓███████▓▒░░▒▓███████▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░   ░▒▓██████▓▒░ ░▒▓███████▓▒░  
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░   ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░   ░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░ 
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░   ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░ 
                                                                                     
                                                                                     
░▒▓█▓▒░       ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░ ░▒▓██████▓▒░▒▓████████▓▒░       
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░           
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░           
░▒▓█▓▒░      ░▒▓████████▓▒░▒▓███████▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓████████▓▒░ ░▒▓█▓▒░           
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░           
░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░           
░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ ░▒▓█▓▒░           
                                                                                     
                                                                                                                                                               
```
     

[english](README.md) | **bahasa indonesia**

script batch sederhana berbasis menu untuk memperbaiki masalah umum printer sharing di Windows 10 dan Windows 11. dibuat untuk menghemat waktu pada tiket IT support yang berulang.

by IT Indoguna Makassar with Sonnet 5.5

## masalah yang diperbaiki

- error 0x0000011b (level autentikasi RPC)
- error 0x00000709 (tidak bisa terhubung ke printer yang dishare)
- error 0x00000079 (timeout: client Windows 11 22H2+ ke host Windows 10)
- error 0x00000bcb dan 0x0000007c (driver tidak tersedia)
- antrian cetak macet dan print spooler yang crash
- pc host tidak muncul di jaringan
- profil jaringan diset public, bukan private
- masalah guest logon SMB, termasuk di Windows 11 24H2 yang mewajibkan SMB signing sehingga guest logon gagal

## cara pakai

1. salin `printer-laknat.bat` ke pc yang bermasalah
2. klik kanan file lalu pilih **run as administrator**
3. pilih opsi dari menu. setiap perbaikan menjelaskan fungsinya dan minta konfirmasi sebelum dijalankan

## preset mana yang dipakai

**server** adalah pc yang tersambung ke printer dan men-share-nya. **client** adalah pc yang terhubung ke printer itu.

| tombol | peran | langkah |
|--------|-------|---------|
| C1 | windows 10 sebagai server (share printer) | 1 + 2 + 3 + 4 + firewall RPC |
| C2 | windows 10 sebagai client (terhubung ke printer sharing) | 2 + 3 + 4 + 8, opsional 5 / 6 |
| C3 | windows 11 sebagai server (share printer) | 1 + 2 + 3 + 4 + firewall RPC |
| C4 | windows 11 sebagai client (terhubung ke printer sharing) | B + 2 + 3 + 4 + 8, opsional 6 |

jalankan preset server di host dulu, lalu preset client di setiap client. setiap langkah di dalam preset tetap minta Y/N, jadi langkah mana pun bisa dilewati.

## opsi menu

| tombol | fungsi |
|--------|--------|
| 1 | perbaiki 0x0000011b dengan mengatur `RpcAuthnLevelPrivacyEnabled` ke 0, lalu restart spooler |
| 2 | reset print spooler dan bersihkan antrian cetak yang macet |
| 3 | aktifkan file and printer sharing dan network discovery, ubah jaringan public ke private |
| 4 | atur service yang dibutuhkan ke automatic lalu jalankan |
| 5 | izinkan guest logon SMB yang tidak aman |
| 6 | longgarkan pembatasan Point and Print untuk instalasi driver |
| 7 | tambah printer sharing lewat local port yang mengarah ke `\\HOST\Share` (cadangan) |
| 8 | simpan kredensial jaringan untuk sebuah host di credential manager |
| B | perbaiki 0x00000079 / 0x00000709 / 0x00000bc4 di client windows 11 22H2+ dengan memaksa RPC lewat named pipe (`RpcUseNamedPipeProtocol` = 1) |
| C1-C4 | perbaikan umum per peran, lihat di atas |
| 9 | diagnostik, lihat di bawah |
| R | kembalikan pengaturan. jika ada folder `printer-laknat.backup` di samping script, pengaturan persis sebelum perbaikan pertama bisa dikembalikan. selain itu, atau jika dipilih, kembalikan ke default Windows: hapus perubahan registry dari 1, 5, 6 dan B, matikan aturan firewall sharing dan discovery, kembalikan jaringan ke public, reset tipe startup service, dan opsional hapus printer dari 7 serta kredensial dari 8 |
| 0 | keluar |

## penjelasan tiap opsi

- **1 RPC privacy (0x11b):** sejak update januari 2022, print server mewajibkan RPC terenkripsi dan sebagian client gagal terhubung. nilai 0 membuat client bisa masuk lagi. *risiko:* RPC printer tidak lagi wajib terenkripsi, dan Microsoft pelan-pelan menghapus pengaturan ini. jalankan di server.
- **2 reset spooler:** satu job macet atau spooler yang hang bisa memblokir semuanya. *risiko:* antrian cetak di pc itu terhapus.
- **3 sharing:** di profil public, Windows memblokir SMB (445) dan RPC printer, jadi host tidak terlihat. *risiko:* perangkat lain di LAN bisa melihat pc ini.
- **4 service:** tanpa service server/workstation tidak ada SMB, tanpa service discovery pc tidak muncul di Network. *risiko:* rendah.
- **5 guest logon:** client bisa membuka share tanpa password. *kenapa sekarang dimatikan secara default:* sesi guest tidak bisa ditandatangani atau diverifikasi, jadi siapa pun di LAN bisa menyamar jadi host. windows 11 24H2 mewajibkan SMB signing, jadi guest tetap gagal. pakai 8 sebagai gantinya.
- **6 Point and Print:** user non-admin bisa install driver dari server (0xbcb / 0x7c). *kenapa sekarang dimatikan secara default:* sejak PrintNightmare (2021), server jahat bisa mengirim "driver" yang berjalan sebagai SYSTEM.
- **7 local port:** membuat local port bernama `\\HOST\Share` dan memakai driver yang terpasang di client. *kenapa berhasil:* job dikirim ke share sebagai penulisan file SMB biasa, tanpa koneksi printer lewat RPC, jadi pemeriksaan RPC 0x11b / 0x709 / 0x79 tidak pernah jalan. *kenapa bukan cara normal:* driver harus dipasang sendiri, tidak ada update driver otomatis atau status antrian dari server, dan harus diatur manual di setiap client. ini jalan pintas, bukan perbaikan.
- **8 kredensial:** SMB login memakai akun asli yang ditandatangani, bukan guest. pengganti yang disarankan untuk 5, wajib di windows 11 24H2. pakai akun yang ada di host.
- **B named pipe (0x79):** sejak 22H2, windows 11 berkomunikasi dengan printer lewat RPC over TCP. host windows 10, atau firewall yang memblokir port 135, tidak menjawab, jadi koneksi timeout. B kembali ke RPC lewat named pipe di dalam SMB (port 445). *risiko:* rendah, ini perilaku sebelum 22H2. jalankan di client windows 11.
- **firewall RPC (di C1 / C3):** mengaktifkan aturan "Spooler Service - RPC" dan "RPC-EPMAP" (port 135) supaya client windows 11 bisa menjangkau server lewat TCP, dan menampilkan printer yang di-share pc ini.

## diagnostik

opsi 9 tidak mengubah apa pun. yang ditampilkan:

- versi dan build Windows pc ini, beserta preset yang cocok
- checklist dengan `[OK]`, `[!!]` atau `[--]` per item dan opsi yang memperbaikinya: spooler, service, profil jaringan, aturan firewall, pengaturan RPC, SMB signing, guest logon, Point and Print, printer yang di-share
- **tes host tujuan:** masukkan nama atau IP server. yang dites berurutan: ping, port SMB 445, port RPC 135, share printer yang terlihat dan kredensial yang tersimpan, jadi kelihatan di lapisan mana koneksinya putus
- **cek kode error:** ketik kode yang muncul (misalnya `79` atau `0x0000011b`) untuk melihat kemungkinan penyebab dan opsi yang harus dijalankan
- laporan disimpan di `printer-laknat.reports\` di samping script, supaya hasil client dan server bisa dibandingkan

## alur troubleshooting

1. di client, jalankan 9 dan tes host tujuan
2. perbaiki server dengan C1 atau C3
3. perbaiki client dengan C2 atau C4
4. masih gagal? pakai 7 sebagai cadangan

## catatan

- script butuh hak administrator dan akan keluar kalau tidak punya
- opsi 1, 5, 6 dan B menurunkan sebagian pengamanan, jadi pakai hanya di jaringan yang dipercaya. setiap opsi menjelaskan risikonya dan minta konfirmasi dulu
- 0x0000011b biasanya diperbaiki di host, tapi di beberapa kasus opsi 1 juga perlu dijalankan di client
- 7 adalah cadangan, bukan cara normal: butuh driver lokal di setiap client dan tidak dapat update driver otomatis
- di windows 11 24H2, pakai opsi 8, bukan 5: SMB signing wajib dan guest logon gagal
- opsi 8 menampilkan password saat diketik, jadi hindari di layar yang dilihat orang lain
- laporan diagnostik disimpan di `printer-laknat.reports\` dan tidak ikut terhapus saat restore
- file `.bat` tidak bisa di-code-sign. untuk mengatur kepercayaan, deploy lewat Intune, GPO atau tool RMM, atau ubah ke `.ps1` yang ditandatangani
- tes dulu di pc cadangan sebelum dipakai luas. gunakan dengan risiko sendiri

## kebutuhan

- Windows 10 atau Windows 11
- akun administrator
- PowerShell (sudah bawaan Windows)
