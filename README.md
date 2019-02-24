**hashboot** hashes all files in `/boot` to check them during early boot. It is
intended for when you have encrypted the root partition but not the boot
partition. The checksums are stored in `/var/lib/hashboot.digest` and a backup
of the contents of `/boot` is stored in `/var/cache/boot-backup.tar`. If a
checksum doesn't match, you have the option to restore the file from backup.

# License
    "THE HUG-WARE LICENSE" (Revision 1):
    xo <xo@rotce.de> and tastytea <tastytea@tastytea.de> wrote these files. As long
    as you retain this notice you can do whatever you want with this stuff. If we
    meet some day, and you think this stuff is worth it, you can give us a hug.


# Install
* Make hashboot executable
* Place hashboot anywhere in $PATH
* Install the appropriate init script
* If applicable, copy kernel-hook to /etc/kernel/post{inst,rm}.d/zzz-hashboot (make sure it is called after all other hooks)

Also see [INSTALL](https://git.tastytea.de/?p=hashboot.git;a=blob_plain;f=INSTALL).


# Usage
* Run "hashboot index" to generate checksums and a backup for /boot and MBR
* Run "hashboot check" to check /boot and MBR
* Run "hashboot recover" to replace corrupted files with the backup


# Notes
* A backup is per default stored in /var/cache/bootbackup.tar.gz
* You can't use the openrc/sysv init scripts with parallel boot.
