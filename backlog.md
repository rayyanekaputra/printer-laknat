# backlog

ideas and planned work that is not started yet.

## linux: print from linux to a windows 10/11 shared printer

goal: add menu items to `printer-laknat.sh` that set up printing from a linux pc to a printer shared by a windows pc.

method: cups `smb://` backend (`smbspool`). it sends the job straight to the smb print share, so windows printer rpc is not used. 0x11b, 0x709 and rpc over tcp problems do not apply. this is the linux version of `.bat` option 7.

planned menu items:

- add a windows shared printer to cups
  - pick the host (or reuse the last diagnostics run), list printer shares, choose one
  - auth: guest (only if the guest test passed) or user/pass
  - user/pass: `-o auth-info-required=username,password` so the password is not in the uri. optional "store in uri" with a warning (plain text in `/etc/cups/printers.conf`)
  - driver: search `lpinfo -m` by model, generic pcl/postscript, or raw (warn: raw only works if the job is already in the printer's language)
  - `lpadmin -p laknat-HOST-SHARE -E -v smb://[WORKGROUP/]HOST/SHARE -m <driver>`
- print a test page (`lp -d QUEUE /usr/share/cups/data/testprint`), follow it with `lpstat`
- remove queues added by this tool (`laknat-*` prefix only)
- show cups queues and the last cups errors (`journalctl -u cups` or `/var/log/cups/error_log`)

rules:

- show WHAT / WHY / RISK / UNDO before every local change, like the `.bat`
- every change has an undo (the remove item)
- needs sudo or the `lpadmin` group

notes for the readme:

- windows side: printer shared, the account exists on the host, file and printer sharing on (option 2)
- win11 24H2 hosts: accounts only, no guest
- old smbspool assuming smb1: set `client min protocol = SMB2` in `/etc/samba/smb.conf`

open question: which distro to test first (package names and paths).

## other

- real test results: win11 24H2 client to win10 host
- convert the `.bat` to a signed `.ps1`
