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
* Detailed documentation is in the sourcecode.