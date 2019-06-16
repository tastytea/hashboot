# Install hashboot on Arch Linux
## Setting up hashboot

1. Clone the git repository and enter the directory:

   `git clone https://github.com/tastytea/hashboot.git && cd hashboot`

2. Distribute the files to the proper paths:

   PLEASE NOTE: it's important to know that when using symlinks it's important to NOT delete the original files. DO NOT DELETE THE HASHBOOT GIT FOLDER. If you move the hashboot git folder, you will need to re-link the files before the next boot. The *advantage* to using symlinks is that if the hashboot code on Github is updated, you can pull the changes and not have to re-copy the files.

   If you don't want to use links and therefore want to be able to safely delete the hashboot git folder, replace `ln -sf` with `cp`.

   1. `sudo ln -sf $(readlink -f hashboot) /usr/bin/hashboot`
   2. `sudo ln -sf $(readlink -f init/systemd/emergency.service) /etc/systemd/system/emergency.service`
   3. `sudo ln -sf $(readlink -f init/systemd/emergency.target) /etc/systemd/system/emergency.target`
   4. `sudo ln -sf $(readlink -f init/systemd/hashboot.service) /etc/systemd/system/hashboot.service`

3. Make the hashboot script executable:

   `sudo chmod a+x /usr/bin/hashboot`

4. Generate the configuration file and initial files:

   `sudo hashboot index`

## Setting up systemd
Start the hashboot service on boot:

`sudo systemctl enable hashboot.service`

## Setting up the pacman hook
You may need to first create the hook folder:

`sudo mkdir -p /etc/pacman.d/hooks`

Then make the hashboot hook file:

`sudo nano /etc/pacman.d/hooks/99-hashboot.hook`

It's important to prefix the file with "99-" because pacman will execute hooks in alphabetical order, and hashboot should be among the last to be executed. Likewise, it's important to suffix the file with ".hook" or pacman won't think it's an alpm hook.

Give it the following contents:

```
[Trigger]
Operation = Install
Operation = Upgrade
Operation = Remove
Type = Package
Target = *

[Action]
Description = Regenerating hashboot checksums...
When = PostTransaction
Exec = /usr/bin/hashboot index
```

Now when you install, upgrade, or remove any package, hashboot will generate new files.

## Making sure hashboot runs at boot
Immediately after booting, you can view the status of the hashboot service with the command

`sudo systemctl status hashboot.service`

It should print something like:

```
* hashboot.service - Check for changes made to the boot partition since shutting down
   Loaded: loaded (/etc/systemd/system/hashboot.service; enabled; vendor preset: disabled)
   Active: inactive (dead) since Sun 2019-05-12 09:27:48 PDT; 20s ago
  Process: 1292 ExecStart=/sbin/hashboot check (code=exited, status=0/SUCCESS)
 Main PID: 1292 (code=exited, status=0/SUCCESS)>
 
May 12 09:27:47 hostname systemd[1]: Starting Check for changes made to the boot partition since shutting down...
May 12 09:27:48 hostname systemd[1]: hashboot.service: Succeeded.
May 12 09:27:48 hostname systemd[1]: Started Check for changes made to the boot partition since shutting down.
```

systemd prints the hashboot file as residing in `/sbin`, but that's because in Arch Linux (and many other distributions), `/bin` and `/sbin` are both symlinks to `/usr/bin`. You can verify this with `ls -l /sbin`.

## Notes on pacman hooks
Pacman uses [alpm hooks](https://www.archlinux.org/pacman/alpm-hooks.5.html) to facilitate triggering an operation after a file or package has been modified by pacman. System hooks are stored in the `/usr/share/libalpm/hooks` directory, but user hooks are stored in `/etc/pacman.d/hooks` (the directory might not be present on an unmodified Arch installation). 

`hashboot index` *should* be ran after any modification to `/boot`. However, pacman will not trigger a hook that should be triggered if files are modified in `/boot` if the files modified in `/boot` are only modified in a separate hook and not by pacman itself; that is, if the initramfs is modified by a prior hook, a hashboot hook that should be triggered if files are modified in `/boot` is not properly triggered.

Furthermore, upgrading a package like `btrfs-progs` can trigger an initramfs update. It would be possible to watch the linux modules folders (`/usr/lib/modules/*`), but libalpm does not search for changes in subfolders, and the kernel module folders are hardcoded to the kernel version (e.g. `/usr/lib/modules/5.1.9-arch1-1-ARCH/`), and change with each kernel update. Therefore, it is safest to generate a new hashboot index every time any package is installed, upgraded, or removed.
