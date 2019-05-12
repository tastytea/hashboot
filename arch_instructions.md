# Install hashboot on Arch Linux
## Clone repository
First, clone the git repository:

`git clone https://github.com/tastytea/hashboot.git`

Then distribute the files to the proper path on your drive.

- the hashboot script should go to /usr/bin
- everything in /init/systemd should go to /etc/systemd/system

Then make the hashboot script executable with the command:

`sudo chmod a+x /usr/bin/hashboot`

Then run this command once to generate the configuration file and initial files:

`sudo hashboot index`

## Setting up systemd
Run the command:

`systemctl enable hashboot.service`

## Setting up the post-install kernel hook
Pacman uses [alpm hooks](https://www.archlinux.org/pacman/alpm-hooks.5.html) to facilitate triggering an operation after a file or package has been modified by pacman. The system hooks are stored in the `/usr/share/libalpm/hooks` directory.

Since `hashboot index` should be run after every kernel update (and after all other post-install actions have completed), create the file `zzz-hashboot.hook` in `/usr/share/libalpm/hooks` and give it the following contents:

```
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = linux

[Action]
Description = Generating hashboot checksums of MBR and /boot...
When = PostTransaction
Exec = /usr/bin/hashboot index
```

Now when you update the kernel, hashboot will generate new files.

## Making sure hashboot runs at boot
Immediately after booting, you can view the status of the hashboot service with the command

`systemctl status hashboot.service`

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