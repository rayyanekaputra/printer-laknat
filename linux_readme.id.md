# printer laknat untuk linux

[english](linux_readme.md) | **bahasa indonesia**

`printer-laknat.sh` memeriksa pc windows 10/11 yang membagikan printer, dari pc linux di lan yang sama. hasilnya: apa yang bermasalah, dan opsi `printer-laknat.bat` mana yang perlu dijalankan di pc mana.

script ini **hanya membaca**. tidak ada yang diubah, baik di pc windows maupun di pc linux kamu. yang ditulis cuma laporan di sebelah script.

untuk tool windows-nya, lihat [README.id.md](README.id.md).

## yang dicek

1. nama host bisa ditemukan (dns, lalu netbios)
2. host membalas ping (cuma peringatan, windows sering memblokir ping)
3. port tcp 445 (smb) terbuka
4. port tcp 135 (rpc) terbuka. client win11 22H2+ butuh port ini
5. smb signing: kalau wajib, login guest pasti gagal (bawaan win11 24H2)
6. guest bisa melihat daftar share
7. akun kamu bisa login (hanya kalau pakai `-u USER`)
8. printer apa saja yang dibagikan
9. print spooler merespons lewat rpc

di akhir ada **kesimpulan**: apa yang harus diperbaiki dan di pc mana.

## yang dibutuhkan

- `smbclient` dan `rpcclient`: debian/ubuntu `smbclient`, fedora `samba-client`, arch `smbclient`
- `nmap` (opsional, untuk cek smb signing)
- `nmblookup` (opsional): debian/ubuntu `samba-common-bin`

cek dengan `./printer-laknat.sh --deps`. kalau ada tool yang belum terpasang, tes itu dilewati, bukan dianggap gagal.

tidak perlu root.

## cara pakai

```sh
chmod +x printer-laknat.sh
./printer-laknat.sh                          # menu
./printer-laknat.sh --diag 192.168.1.20      # guest saja
./printer-laknat.sh --diag PC-ADMIN -u budi  # pakai akun di host (password ditanya)
./printer-laknat.sh --code 0x709             # cari arti kode error
```

format `DOMAIN\user` juga bisa untuk `-u`, asal pakai tanda kutip: `-u 'KANTOR\budi'`.

## laporan

disimpan di `printer-laknat.reports/linux-HOST-TANGGAL.txt`. password tidak pernah masuk laporan. selama tes berjalan, password hanya ada di file sementara (chmod 600), lalu langsung dihapus.

## batasan

- yang dicek hanya host. masalah di **client** windows (driver, point and print, setelan rpc over tcp) tidak kelihatan dari linux. jalankan C2 / C4 di client itu.
- tes spooler memakai rpc lewat named pipe (port 445). client windows 11 22H2+ secara bawaan memakai rpc over tcp, jadi cek port 135 penting untuk mereka.
- sejauh ini baru dicoba di linux tanpa host windows sungguhan. tolong kabari hasilnya.

## rencana

cetak dari linux ke printer yang dibagikan windows: lihat [backlog.md](backlog.md).
