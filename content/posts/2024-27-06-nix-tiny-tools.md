+++
title = 'Tiny Nix tools: asdf2nix and home-manager-remote'
date = 2024-07-13T00:04:37+02:00
draft = false
toc = "true"
tags = [ "nix", "flakes", "asdf", "brew", "home-manager"]
+++

> I'm writing this post to push myself to get back into blogging.

Over the past few months, I've created a couple of Nix helpers for personal use that might be useful to others: [`adfs2nix`](https://github.com/brokenpip3/asdf2nix) and [`home-manager-remote`](https://gist.github.com/brokenpip3/a6493440d3b3bfc933a9fdc51509b5e7). I thought it would be nice to write a quick, gentle introduction so others can use, fork, or contribute if they wish.

*This post assumes you already have a basic understanding of Nix and flakes. I plan to write (if I find the time, motivation, and right context) my humble proposal for learning Nix in a practical way—yet another Nix guide that will probably get lost in the depths of the web. But until that day I will assume a lot of concepts.*


## Asdf2nix

### Why?

Over the years, I've seen people at various companies struggle with package management. As an Arch user (at that time), this issue didn't affect me much due to the vast number of packages available in the Arch User Repository ([AUR](https://aur.archlinux.org/packages)) and the ease of creating packages with pacman. However, I've noticed many people using macOS face issues with dependency management, handling multiple versions of the same software (e.g., kubectl, terraform), and the slow updates of `brew`. While `brew` has made it possible to use a Mac professionally in IT, it also has some drawbacks that don't need explaining here.

One tool that has gained popularity is `asdf`, not only for its ability to install software via CLI but also for a unique feature: the ability to lock dependencies of a specific version in a particular path of a repo or a directory on your laptop, using the **`.tools-version`** file. This was a killer feature for many.

I have several concerns about `asdf`, particularly how it manages different versions of the same software and its security. Many plugins come from third-party or obscure random user repos. Additionally, when it installs software, it runs code on your computer that is not audited or security checked.

![really?}](/images/trust-asdf.png "thanks jack for the guidance on this meme")


All of these cons and the same pros are already successfully achieved with **Nix**, right? So, why not create a tool to simplify the process of transitioning from `asdf` to **Nix**?

Enter `asdf2nix`.

### How to use it

This is the same example you can find in the [repo](https://github.com/brokenpip3/asdf2nix) readme, but it's worth mentioning here.

Let's say you have a tool version specified in a repo like this:

```bash
cat .tool-versions
terraform 1.5.2
nodejs 16.15.0
```

Each time you or your team enter this directory, `asdf` will set these software versions for you.

With `asdf2nix`, you have two options: spawn a Nix shell with these software versions for one-time use, or automatically create a flake file that will allow you (in conjunction with direnv) to always use the same software and versions with Nix.

### Shell

It's straightforward: you can run `asdf` inside that directory (or choose the .tool-versions file from another one), and it will open a shell with the specified software/versions:

```shell
$ nix run github:brokenpip3/asdf2nix -- shell
Generating shell from .tool-versions: nix shell nixpkgs/0b9be173860cd1d107169df87f1c7af0d5fac4aa#terraform nixpkgs/7b7fe29819c714bb2209c971452506e78e1d1bbd#nodejs

$ terraform version
Terraform v1.5.2
on linux_amd64
```

### Flake

What if we want to help the team gently migrate to Nix, or better yet, let people use their preferred tools and switch between them as they like?

Let's use the `flake` command:

```bash
$ nix run github:brokenpip3/asdf2nix -- flake

{
  description = "A flake with devshell generated from .tools-version";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    terraform_1_5_2.url = github:NixOS/nixpkgs/0b9be173860cd1d107169df87f1c7af0d5fac4aa;
    nodejs_16_15_0.url = github:NixOS/nixpkgs/7b7fe29819c714bb2209c971452506e78e1d1bbd;
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        terraform = inputs.terraform_1_5_2.legacyPackages.${system}.terraform;
        nodejs = inputs.nodejs_16_15_0.legacyPackages.${system}.nodejs;
      in
        {
          devShells.default = pkgs.mkShell {
            packages = [
              terraform
              nodejs
            ];
          };
        }
    );
}
```

We can save it and add a direnv file that will trigger the flake devshell only in case you have nix installed in the system:

```bash
$ nix run github:brokenpip3/asdf2nix -- flake > flake.nix

$ cat .envrc
has nix && use flake
```

Done! Congrats, you’ve now made it accessible for everyone on your team to try nix with the same well-known `.tools-version` behavior.

### Note on how to run a flake from a repo

In the previous examples, I showed how to run `asdf2nix` from my git repo. However, the first rule of the internet is: **never trust anyone**, so I encourage you to specify the version like this:

```bash
nix run github:brokenpip3/asdf2nix/0.3.1 -- flake
```

Or even better (since the tag can be overwritten), use the Nix CLI built-in feature to run it from a specific commit (which in the following example is also the latest version). After reading my code, you will always be 100% sure you are running a specific point in time of the software you trust:

```bash
nix run github:brokenpip3/asdf2nix/f24848fdeac751989a978b09f61b55752f2c9be9 -- flake
```

## Home-manager-remote

### Why?

For me, the real selling point of Nix was [`home-manager`](https://github.com/nix-community/home-manager) rather than NixOS itself.

[Home-manager](https://github.com/nix-community/home-manager) gives me most of the Nix functionalities on any linux distribution (and macOS, and one day even [natively](https://github.com/NixOS/nix/pull/8901) on windows) and covers 90% of my as-code needs.

However, one thing I miss from NixOS, besides the ability to roll back the entire system, is the ability to build a remote system. If you're not familiar with how it works, you can simply build a remote system described in your flake from the machine where you are running the command, like this:

```bash
nixos-rebuild --target-host vpsuser@foobar.com switch
```

This will build the target system locally, copy the necessary closure, and deploy it via SSH. It's a great way to keep your system updated from a single flake when you need to change some configurations or update your packages.

At the same time, there are multiple systems where I still do not have NixOS installed, either because I can't (e.g., a company laptop running Ubuntu) or because I still need to find the time to rebuild them as code, like my VPS with k8s nodes.

Unfortunately, home-manager lacks this support, which is why I created [this](https://gist.github.com/brokenpip3/a6493440d3b3bfc933a9fdc51509b5e7) simple script (no specific repo at the moment) to add this functionality to home-manager.

### How to Use It

First, you need to have your standalone home-manager configuration in your flake for the machine you want to build, something like:

```nix
homeConfigurations = {
  "myuser@myhost" = home-manager.lib.homeManagerConfiguration {
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    extraSpecialArgs = { inherit inputs outputs rolling; };
    modules = [
      ./modules/home-manager/home.nix
      //other modules here
    ];
  };
  "myuser2@foobar" = home-manager.lib.homeManagerConfiguration {
    //configuration for myuser2@foobar
  };
};

```

As you may know, setting the user, in this example `myuser`, and the host, `myhost`, is necessary for home-manager to recognize automatically which host needs to be built or switched to the new configuration.

You will also need passwordless access to the remote hosts with the classic SSH key login.

Finally, you can use **home-manager-remote**. For instance, to build the target system locally, copy the closure, and switch to the new version via SSH, you can use it like this:

```bash
home-manager-remote.sh <flake_path> [target] [--build-on-target]
```

As mentioned before, the script will:

* Ask you for a target host if it's not passed as an argument.
* Check if the SSH passwordless connectivity to the target host is valid.
* Create a temporary directory on the target host.
* Copy the flake and the repo files to the temp directory.
* Build the target host configuration.
* Copy the closure from the local Nix store to the target machine's store.
* Switch to the new configuration on the target host.
* Clean up the temporary files.
* Expire the target host's home-manager generation to free up some disk space.

Here’s an example output:

```nix
$ helpers/home-manager-remote.sh .
Enter the target host: myuser@myhost
[2024-06-27 23:33:14] myhost[myuser]: Temporary directory '/tmp/JY9932rL' created.
[2024-06-27 23:33:14] myhost[myuser]: Copying git repository...
[2024-06-27 23:33:15] myhost[myuser]: Building locally...
[2024-06-27 23:33:28] myhost[myuser]: Copying the closure...
copying 241 paths...
copying path '/nix/store/0chs9i53rw3bfkmqyalknpgb4b592n48-aws-c-common-0.9.17' to 'ssh://myuser@myhost'...
copying path '/nix/store/05gxcrd0jlqbx3kbhadgag22562sl1j2-aws-c-compression-0.2.18' to 'ssh://myuser@myhost'...
copying path '/nix/store/0354j8bh8qrvynaj4f6mpqwbshcr22kr-nix-2.18.2-man' to 'ssh://myuser@myhost'...
[...]
copying path '/nix/store/0kj0q71w4z5r1xqbdm6fz1sfgkj140va-home-manager-generation' to 'ssh://myuser@myhost'...
[2024-06-27 23:41:08] myhost[myuser]: Switching to the new configuration...
Starting Home Manager activation
Activating checkFilesChanged
Activating checkLinkTargets
Activating writeBoundary
Activating linkGeneration
Cleaning up orphan links from /home/myuser
No change so reusing latest profile generation 39
Creating home file links in /home/myuser
Activating createXdgUserDirectories
Activating installPackages
nix profile remove /nix/store/6d3w4zkmv96m7hacixabz03j80fsqlm1-home-manager-path
removing 'home-manager-path'
removed 1 packages, kept 3 packages
Activating onFilesChange
Activating reloadSystemd

There are 35 unread and relevant news items.
Read them by running the command "home-manager news".

[2024-06-27 23:41:43] myhost[myuser]: Cleaning up temporary files...
[2024-06-27 23:41:44] myhost[myuser]: Running home-manager expire-generations...
Removing generation 38
[2024-06-27 23:41:45] myhost[myuser]: Home-manager remote completed.
```

The script by default will build locally to take advantage of building some of the derivations only once. In my configuration, I use similar settings and packages for all my machines, so it’s very likely that I will already have the right package in the Nix store, ready to be copied to the target host.
If, for any reason, you prefer to build directly on the target host, you can pass the `--build-on-target argument`

I'm not sure if I will be brave enough to try to translate this logic into the upstream home-manager binary, and I’m not sure it will be accepted, but after the summer, I want to take a stab at it and see how it goes :)

## Conclusion

I hope these tiny tools help you in your Nix journey. Feel free to fork, contribute, or reach out with any feedback. Happy nixing!
