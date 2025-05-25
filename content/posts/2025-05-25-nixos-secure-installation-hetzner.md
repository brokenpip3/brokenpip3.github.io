+++
title = 'Nixos encrypted installation with kexec, disko, luks, btrfs and remote luks unblock on a Hetzner auction server (or any cloud provider vps/vds)'
date = 2025-05-05T23:02:08+02:00
draft = false
toc = true
+++

Recently I bought a Hetzner auction server and I wanted to do a secure installation with disk encryption,
like I always do for my vps (even if this one is a bare metal one) and I did it using nixos with disko and flakes.

> This guide is intended for Hetzner auction servers but it should work on any cloud provider vps/vds, even if the cloud
provider does not support nixos as a base image, will try to do some generic disgression in case you want to follow it
in a different cloud provider.

## Hetzner auction server and limitations that will drive this guide

If you don't know what a Hetzner auction server it's basically customized server that has been used by someone else and
now, after the previous owner has finished using it, you can buy it for a low price compared to the same server but new.
If want to take a look you can find the official page [here](https://www.hetzner.com/sb) even if my suggestion is to use
this alternative community [site](https://hetzner-value-auctions.cnap.tech/) with a better user experience and filters
that you can use to find the server you want.

![hetzner auction website](/images/nixos-installation-hetzner/secondhand.jpg "let's check the near to expire corner")

<center><i>the hetzner auction farm</i></center>

Now low prices also comes with some limitations and one of them is that you can't use any custom image, you don't have
a *stable* console access and you can't use the rescue system to boot from a custom image. These are a bit challenging
starting points (especially the absence of a always present console) but not impossible to overcome.
Let's do it with kexec images, disko and flakes.

> the whole process can be done quickly and automatically with tools like nixos-everywhere or disko-install but for
the sake of this guide I will show you how to do it manually, so you can understand every pieces and feel more comfortable
with the entire process.

## The jail of few supported distro images and kexec as the key

Hetzner auction servers like several other cloud provider only give you a few supported distro images to choose from.
Most of the time they are the most popular ones like ubuntu, debian and centos, but very few of them support nixos.

This is not a real problem for us since we use a magical super power: kexec.
Kexec is a Linux kernel feature that allows you to load and execute a new kernel from the currently running kernel
directly in memory. This will let us to boot to the nixos-installer image from another distro running on the server.

But let's start from the beginning, the first step is install any hetzner supported distro image and upload our ssh key to it.
Personally I chose archlinux but you can choose any of the supported ones.

### Key exchange and kexec execution

Once you machine is ready and you have access to it, we need to upload your ssh key to it.

> you can skip this step if you already uploaded your ssh key in the cloud provider console while rebuilding the server

```bash
ssh-copy-id root@<your-server-ip>
```

this will copy all your ssh keys to the server, if you want to use a specific key you can use the `-i` option:

```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub root@<your-server-ip>
```

and the output will be something like:

```bash
$ ssh-copy-id -i ~/.ssh/id_rsa.pub root@<your-server-ip>
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/home/user/.ssh/id_rsa.pub"
root@<your-server-ip>'s password:

Number of key(s) added: 1

Now try logging into the machine, with: "ssh 'root@<your-server-ip>'"
and check to make sure that only the key(s) you wanted were added.
```

Now let's use the [official](https://github.com/nix-community/nixos-images?tab=readme-ov-file#kexec-tarballs) nixos kexec installer
image to boot into the nixos installer:

```bash
$ curl -s -L https://github.com/nix-community/nixos-images/releases/latest/download/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz | tar -xzf- -C /root
$ /root/kexec/run
[..]
+ echo machine will boot into nixos in 6s...
machine will boot into nixos in 6s...
+ test -e /dev/kmsg
+ exec
```

this will load in memory the nixos installer image and execute it, in few seconds if everything went wellyou will be able to ssh
into the server again and this time you will be able to execute any nixos command:

```bash
$ ssh root@<your-server-ip>
Last login: Mon May  5 21:49:05 2025

[root@nixos-installer:~]# nix --version
nix (Nix) 2.24.14
```

Great! our journey has just started

## Disko declarative disk partitioning

The disko repo announces itself as *declarative disk partitioning and formatting using nix*.
However, it is much more than that, not only it will automatically partition and format your disks, but the disko configuration can be
sourced from a nix flake, so you can use it as a base for your nixos configuration and use it to build your whole system without
needing to manually add the partitions, filesystems and boot setup to your nixos configuration.

The best way to start familiarizing with disko is to take a look of one of the [examples](https://github.com/nix-community/disko/tree/master/example) in the repo.
I will give you a couple of examples during this installation and we are going to explain them line by line.

But before that we need something to write our iac configuration so let's install vim (or any other editor you prefer):

```bash
nix --extra-experimental-features "nix-command flakes" shell nixpkgs#vim
```

Now let's create a `disko.nix` file in the current directory:

```bash
vim disko.nix
```

Before showing the disko configuration another quick note about the heztner auction server: most of them have at least 2 disks, the first
disko example I'm going to show you is for a server with 2 disks, the second one is for a generic server with only one disk.

```nix
let
  btrfsopt = [
    "compress=zstd"
    "noatime"
    "ssd"
    "space_cache=v2"
    "user_subvol_rm_allowed"
  ];
in
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
           boot = {
            name = "boot";
            size = "1M";
            type = "ef02";
          };
          esp = {
            name = "esp";
            size = "500M";
            type = "ef00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "nixos";
                passwordFile = "/tmp/pass";
                additionalKeyFiles = [ "/nixos-enc.key" ];
                extraFormatArgs = [
                  "--type luks1"
                  "--iter-time 1000"
                ];
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "@root" = {
                      mountpoint = "/";
                      mountOptions = btrfsopt;
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = btrfsopt;
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = btrfsopt;
                    };
                    "@data" = {
                      mountpoint = "/data";
                      mountOptions = btrfsopt;
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
```

If feels a lot, don't worry, let's break it down:

### Let section

```nix
let
  btrfsopt = [
    "compress=zstd"
    "noatime"
    "ssd"
    "space_cache=v2"
    "user_subvol_rm_allowed"
  ];
in
[...]
```

the `btrfsopt` variable is a list of mounting options that we are going to use for our btrfs filesystem, so we don't have to repeat them.
Be aware that these options are opinionated based on my personal experience, you can change them to your liking, but I suggest
to keep at least the `compress=zstd` and `ssd` options.

### Main boot section

```nix
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
           boot = {
            name = "boot";
            size = "1m";
            type = "ef02";
          };
          esp = {
            name = "esp";
            size = "500m";
            type = "ef00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
    [...]
```


The `disk.devices.disk` section is where we define the disks and partitions that we are going to use for our installation.
In this case I'm going to create a disk with 3 partitions, the first two will be used for boot and the last one for the root encrypted
filesystem.

> do not forget to change the `/dev/sda` to the correct device name for your server, you can use the `lsblk` command to check it.

Again a note about hetzner auction servers, afaik they do not need a efi partition since there do not support uefi booting by default,
but I suggest to create it anyway and use it as boot partition, just in case you want to use it in the future or
if you want to use the same layout for a different cloud provider.
If you are uncertain about if your server supports uefi booting or not, you can use the efibootmgr command to check it:

```bash
nix shell nixpkgs#efibootmgr
efibootmgr
```
If you see a list of boot entries with the `BootOrder` and `BootCurrent` fields, it means that your server supports uefi booting, if
you see an error like `EFI variables are not supported on this system` it means that your server does not support uefi booting.

### Disk section: luks

```nix
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "nixos";
                passwordFile = "/tmp/pass";
                additionalKeyFiles = [ "/nixos-enc.key" ];
                extraFormatArgs = [
                  "--type luks1"
                  "--iter-time 1000"
                ];
                settings = {
                  allowDiscards = true;
                };
```

The luks section is where we define the encrypted partition that we are going to use for our root filesystem.
Now here we can notice a couple of important settings:

- the `extraFormatArgs` option is used to pass additional arguments to the `cryptsetup` command, in this case we are using:
  - `--type luks1` because afaik grub does not have the full support for luks2 yet, so just in case we are going to force the old
  (but stable) version
  - `--iter-time 1000` is used to set the time in milliseconds that luks will wait before trying to unlock the partition, this is useful
  to avoid brute force attacks, but it will also slow down the unlocking process, so made your choice based on your needs.

- `passwordFile` is the file that contains the password for the luks partition, in the setup phase
  will be passed to the `cryptsetup` command. It's up to you to choose to generate it or not.
  for the sake of this guide I will just create a random password and store it in the `/tmp/pass`:
  ```bash
  dd if=/dev/urandom bs=1 count=32 | base64 > /tmp/pass
  ```
  obv let's take a note of the password and store it in a safe place


- `additionalKeyFiles` is a list of additional key files that will be used to unlock the luks partition,
   in this case we are going to create a random key so we can backup it in another place and
   never loose the access to our data. To do so let's use the classic dd command:
   ```bash
   dd if=/dev/urandom of=/nixos-enc.key bs=4096 count=1
   ```
   again do not forget to copy it somewhere safe


### Disk section: btrfs

```nix
                content = {
                  type = "btrfs";
                  subvolumes = {
                    "@root" = {
                      mountpoint = "/";
                      mountOptions = btrfsopt;
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = btrfsopt;
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = btrfsopt;
                    };
                    "@data" = {
                      mountpoint = "/data";
                      mountOptions = btrfsopt;
                    };
                  };
                };
```

More we can see the content with type `btrfs` and the subvolumes that we are going to create, this list should be straightforward
if you are familiar with btrfs, but in case you are not we are going to create 4 subvolumes, one for the whole root filesystem,
one for the home directories (even if in a server you might not need it), one for the nix store and finally one for data (in my case
it will be for cri-o and kubernetes data).
It's up to you to choose the subvolumes you want to create, but I suggest to keep at least the root and the nix store ones.

### Disko example with multiple disks

Like I said now that we familiarized with the disko syntax, let's take a look at a more complex example with multiple disks that will be
the base for a hetzner auction server since most of them have at least 2 disks.

<details>
<summary><b>multiple disks raid disko example, click to show</b></summary>

```nix
let
  btrfsopt = [
    "compress=zstd"
    "noatime"
    "ssd"
    "space_cache=v2"
    "user_subvol_rm_allowed"
  ];
in
{
  disko.devices = {
    disk = {
      disk1 = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            ESP = {
              size = "500M";
              type = "EF00";
              content = {
                type = "mdraid";
                name = "boot";
              };
            };
            mdadm = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "raid1";
              };
            };
          };
        };
      };
      disk2 = {
        type = "disk";
        device = "/dev/nvme1n1";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "ef02";
            };
            ESP = {
              size = "500M";
              type = "EF00";
              content = {
                type = "mdraid";
                name = "boot";
              };
            };
            mdadm = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "raid1";
              };
            };
          };
        };
      };
    };
    mdadm = {
      boot = {
        type = "mdadm";
        level = 1;
        metadata = "1.0";
        content = {
          type = "filesystem";
          format = "vfat";
          mountpoint = "/boot";
          mountOptions = [ "umask=0077" ];
        };
      };
      raid1 = {
        type = "mdadm";
        level = 1;
        content = {
          type = "luks";
          name = "nixos";
          passwordFile = "/tmp/pass";
          additionalKeyFiles = [ "/nixos-enc.key" ];
          extraFormatArgs = [
            "--type luks1"
            "--iter-time 1000"
          ];
          settings = {
            allowDiscards = true;
          };
          content = {
            type = "btrfs";
            subvolumes = {
              "@root" = {
                mountpoint = "/";
                mountOptions = btrfsopt;
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = btrfsopt;
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = btrfsopt;
              };
              "@data" = {
                mountpoint = "/data";
                mountOptions = btrfsopt;
              };
            };
          };
        };
      };
    };
  };
}
```
</details>

the only difference with the previous example is that we are using 2 disks and we are creating a software raid1 array for the luks partition,
using mdadm, all the rest is the same.

## Running disko

Now it's time to see our configuration shine and run disko to partition and format our disks.

Before continue, once again, be sure that:
- you are using the correct device name for your disks (`/dev/sda` or `/dev/nvme0n1` or whatever), if you are not sure use the `lsblk` command to
  check it
- you have created the password file and the additional key file and you have copied them somewhere safe
- you are running it in the right machine :D (obv will be a distruptive action)

let's finally run our disko command:

```bash
$ nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount disko.nix
disko version 1.12.0
[..]
```

```bash
$ nix store gc
1895 store paths deleted, 1178.76 MiB freed
```

however to avoid "no space left on device" on low memory vps you can do the same (even with a slight older disko version) with:

```bash
$ nix-shell -p disko
this path will be fetched (0.03 MiB download, 0.14 MiB unpacked):
  /nix/store/rsynqyw1kzprsifhlr39k396m83sskpl-disko-1.9.0
copying path '/nix/store/rsynqyw1kzprsifhlr39k396m83sskpl-disko-1.9.0' from 'https://cache.nixos.org'...
$ disko --mode disko disko.nix
disko version 1.9.0
[..]
```

you should see several output lines around partitioning and formatting the disks, and don't worry if you receive an error (ex forgot to add the password file),
you can re-run disko multiple times, if you are uncertain about the outcome you can always check the disko command return with

```bash
[..]
+ mountpoint=
+ type=btrfs
+ findmnt /dev/mapper/nixos /mnt/nix
+ mount /dev/mapper/nixos /mnt/nix -o compress=zstd -o noatime -o ssd -o space_cache=v2 -o user_subvol_rm_allowed -o subvol=@nix -o X-mount.mkdir
+ rm -rf /tmp/nix-shell-2791-0/tmp.jzrZ2yCjqz

$ echo $?
0
```

if everything went well you should see the following output from lsblk:

```bash
$ lsblk /dev/sda
NAME      MAJ:MIN RM  SIZE RO TYPE  MOUNTPOINTS
fd0         2:0    1    4K  0 disk
loop0       7:0    0  1.1G  1 loop  /nix/.ro-store
sda         8:0    0    8G  0 disk
├─sda1      8:1    0    1M  0 part
├─sda2      8:2    0  500M  0 part  /mnt/boot
└─sda3      8:3    0  7.5G  0 part
  └─nixos 254:0    0  7.5G  0 crypt /mnt/nix
                                    /mnt/home
                                    /mnt/data
                                    /mnt
```

as you can see the luks partition is mounted in `/mnt/nix` and the other subvolumes are mounted in their respective mountpoints under the `/mnt` directory.

## Nixos installation

Finally we can start the nixos installation phase.

Like I mention I'm going to show how to do already with flakes, but in case of low memory vps you can use the standard method, the configs options
will be exactly the same.

### Generate

Ok let's use the `nixos-generate-config` command to generate automatically the system configuration.

One of the greatest thing of disko is that by sourcing the disko configuration we don't need to add the partitions and filesystems, it wil take
care of it for us.
If like me you did already a nixos installation with btrfs probably you the bug with the `nixos-generate-config` command that will not generate
the subvolumes mount options, so you will need to add them manually. Disko will take care of it and also configure the bootloader/luks parts for you.

Enough introduction, let's run the command:

```bash
nixos-generate-config --no-filesystems --root /mnt
writing /mnt/etc/nixos/hardware-configuration.nix...
writing /mnt/etc/nixos/configuration.nix...
For more hardware-specific settings, see https://github.com/NixOS/nixos-hardware.
```

this will generate the hardware configuration and the system configuration files, we are going to modify them later.

Now let's copy the disko configuration file to the `/mnt/etc/nixos` directory and jump into it:

```bash
cp disko.nix /mnt/etc/nixos/
cd /mnt/etc/nixos
```

### Flake

Like I said before, I'm going to show you how to do it with flakes, so let's create a flake.nix file in the `/mnt/etc/nixos` directory:

```bash
vim flake.nix
```

> Another disclamer: if you already your own nix dotfiles with your flake you already know what to do. I'm showing this example for
the ones that are not familiar with it and want to start using nix directly with flakes from the beginning. The example will be super simple
and mono-system but again it's a precise choice to show you how to do it.

one example base flake will be:

```nix
{
  description = "New server flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    {
      ...
    }@inputs:
    {
      nixosConfigurations.nixos = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.disko.nixosModules.disko
          ./configuration.nix
          ./disko.nix
        ];
      };
    };
}

```

here we need to notice a couple of things:

- we have, apart the classic nixpkgs stable branch, also the disko input that will be used to
  import the disko module in the nixos configuration

- we are importing directly in the flake the `disko.nix` file, you can also import it in the
  `configuration.nix` file, in this example will be there just to be more explicit.


### Bootlooader settings

Ok so we got our flake, we are sourcing the disko module and config, what else we need?

We need to add only one configuration that our disko config will not provide for us, the grub device(s).

> In case of uefi booting you also need to add the `boot.loader.efi.canTouchEfiVariables = true;` option.

let's open the `configuration.nix` file and add the following lines:

```nix
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda"; # or /dev/nvme0n1 or whatever your disk is
    efiSupport = false; # set to true if you are using uefi booting
  };
```

in case like my hetnzer auction server you have multiple disks, you can add the `devices` option to specify
multiple devices, like so:

```nix
  boot.loader.grub = {
    enable = true;
    devices = [ "/dev/sda" "/dev/sdb" ]; # or ["/dev/nvme0n1" "/dev/nvme1n1" ] or whatever your disks are
    efiSupport = false; # set to true if you are using uefi booting
  };
```

### Remote unblocking of luks partition via ssh

Finally since like I explained before, the hetzner auction servers do not have a stable console access, we
need to find a way to unlock the luks partition remotely via ssh before the system boots.

To do so we need to add some configuration to the `boot.initrd` section:


```nix
  boot.kernelParams = [ "ip=dhcp" ];
  boot.initrd = {
    availableKernelModules = [ "e1000e" ];
    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222;
        authorizedKeys = [
          "ssh-rsa <your-ssh-public-key>"
        ];
        hostKeys = [ "/etc/secrets/initrd/ssh_host_rsa_key" ];
        shell = "/bin/cryptsetup-askpass";
      };
    };
  };
```

Let's explain it line by line:
- `boot.kernelParams = [ "ip=dhcp" ];` this will set the kernel parameters to use dhcp to get an ip address
- `boot.initrd.availableKernelModules = [ "e1000e" ];` this will load the kernel module for the network interface.
   **important**: you need to change it to the correct module for your network interface, to do so you can run the following command: `lspci -v | grep -iA8 'network\|ethernet'`
   and check the `Kernel driver in use` line, in my case it was `e1000e`, but it could be different for you:
   ```bash
    $ lspci -v | grep -iA8 'network\|ethernet'
    00:1f.6 Ethernet controller: Intel Corporation Ethernet Connection (2) I219-LM (rev 31)
        Subsystem: Fujitsu Technology Solutions Device 121f
        Flags: bus master, fast devsel, latency 0, IRQ 124
        Memory at ef200000 (32-bit, non-prefetchable) [size=128K]
        Capabilities: <access denied>
        Kernel driver in use: e1000e
        Kernel modules: e1000e
   ```
- the `boot.initrd.network.port` it's where we set the port that the temporary ssh daemon will listen, my suggestion is to use a random not well know port, but for the sake of this guide
  let's keep it simple as `2222`.

- `boot.initrd.network.authorizedKeys` is where we put our ssh public key, so we can ssh into the server and unlock the luks partition.
- `boot.initrd.network.hostKeys` is where we set the path to the ssh host keys that will be used by the temporary ssh daemon, before use it we need to generate them, so let's run the following command:
  ```bash
  $ mkdir -p /mnt//etc/secrets/initrd/
  $ ssh-keygen -t rsa -N "" -f /mnt/etc/secrets/initrd/ssh_host_rsa_key
  Generating public/private rsa key pair.
  Your identification has been saved in /mnt/etc/secrets/initrd/ssh_host_rsa_key
  Your public key has been saved in /mnt/etc/secrets/initrd/ssh_host_rsa_key.pub
  The key fingerprint is:
  [...]
  ```
- `boot.initrd.network.shell` is where we set as shell the `cryptsetup-askpass` command to actally unlock the luks partition.

### Ssh deamon configuration

After fixing the remote unlocking we need to setup our standard ssh daemon, so we can ssh into the server after the luks partition is unlocked:

```nix
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes"; # allow root login via ssh only for the first boot, after that you should disable it
      PasswordAuthentication = true; # allow password authentication for the first boot, you can create a user with an authorized key and disable it
    };
  };
```

As you can read from the comment we are going to make it a bit permissive for the first boot, so we can ssh into the server and check that
everything is working as expected, after that you should disable the root login and password authentication by creating a user with an
authorized key and set both option to the opposite to endure a more secure configuration (there are so many other option that we can set
to make it more secure, I may write a follow up guide about it and all the others good security pratices that we can setup).


### Other basic configuration

Finally to conclude our configuration we can add some basic options to the `configuration.nix` file:

```nix
  networking.hostName = "<myhostname>";
  networking.domain = "<mydomain>";
  networking.networkmanager.enable = true; # you can use something else, it's up to you
  time.timeZone = "Europe/Rome"; # Replace with your timezone
  environment.systemPackages = with pkgs; [
     vim
  ]; # no need to explain :)

  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
  }; # Obv let's enable flakes by default

```

> the `networking.networkmanager.enable` option without any further configuration will enable the NetworkManager service that will use the
dhcp to get an ip address, if you want to use a static ip address you can configure it in the `networking.interfaces` section. For the
sake of this guide I will keep it simple and use dhcp.

### Check the configuration

Before proceeding with the installation, it's a good idea to check the configuration for any misconfiguration:

```nix
$ nix flake check
warning: creating lock file '/mnt/etc/nixos/flake.lock':
• Added input 'disko':
    'github:nix-community/disko/df522e787fdffc4f32ed3e1fca9ed0968a384d62?narHash=sha256-kYL4GCwwznsypvsnA20oyvW8zB/Dvn6K5G/tgMjVMT4%3D' (2025-05-20)
• Added input 'disko/nixpkgs':
    follows 'nixpkgs'
• Added input 'nixpkgs':
    'github:nixos/nixpkgs/f09dede81861f3a83f7f06641ead34f02f37597f?narHash=sha256-92vihpZr6dwEMV6g98M5kHZIttrWahb9iRPBm1atcPk%3D' (2025-05-23)
```

if everything is ok we should see an output like the one above, basically only creating the flake lock, if we have any error in our configuration we are going to see it here with the offending line number and the error message.

### Install the system

Yeah, we are finally ready to install the system, let's run the following command:

```bash
nixos-install --flake .#nixos
```

we are using `.#nixos` to specify the current directory as the flake and the `nixos` system configuration that we defined in the `flake.nix` file.
If you are not in the `/mnt/etc/nixos` directory you can use the full path to the flake and the hostname you set in the **flake** `nixosConfigurations` attribute, like so:

```bash
nixos-install --flake /mnt/etc/nixos#<myhostname>
```

now keep patience, the `nixos-install` command will take a while to complete, it will download all the necessary packages and configure the system.

if everything goes well you should see the following output:

```bash
[1/130/262 built, 319 copied (2141.8/2142.7 MiB), 509.0 MiB DL] building system-path:
installing the boot loader...
setting up /etc...
updating GRUB 2 menu...
installing the GRUB 2 boot loader on /dev/sda...
Installing for i386-pc platform.
Installation finished. No error reported.
setting up /etc...
setting up /etc...
setting root password...
New password:
Retype new password:
passwd: password updated successfully
installation finished!
```

Now we can reboot the server and check if everything is working as expected:

```bash
reboot
```

After the reboot, you should be able to ssh into the server using the temporary ssh daemon that we configured before:

```bash
ssh -p 2222 -l root <your-server-ip>
Last login: Sun May 25 16:09:13 2025 from x.x.x.x
Passphrase for /dev/disk/by-partlabel/disk-main-luks:
```
After entering the passphrase for the luks partition, you should be able to ssh into the server normally (give it a few seconds to start the ssh daemon):

```bash
ssh -p 2222 -l root <your-server-ip>
```

Perfect! now you can start to add (as iac) you new user with the authorized key, disable the root login and password authentication, and setup the rest of your system as you like.
Like I said before, if I will find the time I will write a follow up guide about the best security practices, wireguard vpn, and other useful things that you can do to secure your server and make it more reliable.

## Bonus point: backup your luks header

```bash
cryptsetup luksHeaderBackup /dev/sda3 --header-backup-file header-backup-hetzner
```
