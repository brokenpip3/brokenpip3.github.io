+++
title = 'Leveraging flake template to initialize and keep in sync a git repository'
date = 2024-03-19T00:12:00+01:00
draft = "false"
toc = "true"
tags = [ "nix", "flake", "templating", "git", "repo", "hack"]
+++

Have you ever found yourself repeatedly duplicating small configuration files from one repository to another? Or manually updating them each time? I have been on the lookout for a method to initialize a repository with a set of predefined files for quite some time.

## Options Considered

I have considered both GitHub templates and [cookiecutter](https://github.com/cookiecutter/cookiecutter), but neither of them really caught my attention:

- GitHub templates can be limited in customization options.
- Cookiecutter templates may require additional dependencies and setup.
- Both solutions may not provide the level of automation desired for efficiently bootstrapping a repository.
- Both solutions will not provide a user-friendly way to keep the template files updated.

I must confess that none of these are real drawbacks, but none of the options gave me the feeling of finding what I was searching for. Surely, there must have been other options on the table that I did not find or consider.

## Another Nix Command Feature

*By the way, this is the first time that I'm discussing nix in this blog, more posts will follow, for the moment I will assume that the reader has a basic understanding of what Nix is.*

I began experimenting with the `nix flake init` command, this command sets up a basic `flake.nix` file allowing you to specify dependencies, configurations, and builds for the project in a reproducible and version manner.

```bash
$ mkdir foobar
$ cd foobar && nix flake init
wrote: /tmp/foobar/flake.nix
$ ls flake.nix
flake.nix
```

When using `nix flake init --template <url or file>`, it initializes a new Nix repository based on a template specified by the user. There are some official templates but you can specify any url or path that will contain a flake template.

## Discovery #1: Initializing All Files

What I've realized is that `nix flake init -t` not only initializes the flake file from the remote repository but also duplicates all the tracked files present in that directory. For example:

```bash
$ nix flake init --template templates#go-hello
wrote: /tmp/foobar/flake.nix
wrote: /tmp/foobar/go.mod
wrote: /tmp/foobar/main.go
```

This is fantastic! I can leverage this feature to efficiently bootstrap new projects with predefined configurations and files.

### How It Works

To make it work in your flake templating, you need to have a `template` section, for example:

```nix
{
  description = "My Flake Template";
  [...]
    templates.base = {
        path = base;
        description = "Basic project configs and files"
    };
  [...]
}
```

Create some (fake) files:

```bash
$ mkdir base
$ touch base/foo
$ touch base/bar
```

and initialize a new repo with that specific template (note the `#base`):

```bash
$ nix flake init --template ../#base
wrote: /tmp/template-test/test/bar
wrote: /tmp/template-test/test/foo
```

### Welcome Text

While browsing the [documentation](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-init.html#template-definitions), I discovered that we can also pass a welcome text in `welcomeText` that will be displayed while initializing the template. And markdown is supported! Let's see one of the default examples:

![rust-example](/images/nix-flake-template/rust-welcome-text-example.png)

Cool!

## Discovery #2: Diffing

While testing this feature, I discovered that not only is it copying all the files in the template, but it is also able to diff and understand if a file was changed:

```bash
$ nix flake init -t ../#rust
wrote: /tmp/barfoo/new/default.nix
wrote: /tmp/barfoo/new/flake.nix
skipping identical file: /nix/store/c65klsmnz9s1lyw5y29ndyv5zq54khhz-source/rust/myconfig
wrote: /tmp/barfoo/new/shell.nix
```

But it's even smarter:

```bash
$ nix flake init -t ../#rust
refusing to overwrite existing file '/tmp/barfoo/new/shell.nix'
please merge it manually with '/nix/store/6c9lkjvyrbph41znd741y1dg58gx2i9h-source/rust/shell.nix'
skipping identical file: /nix/store/6c9lkjvyrbph41znd741y1dg58gx2i9h-source/rust/default.nix
skipping identical file: /nix/store/6c9lkjvyrbph41znd741y1dg58gx2i9h-source/rust/flake.nix
wrote: /tmp/barfoo/new/myconfig
```

If something changed in the source or in the destination, it will refuse to stash your changes by mistake so you can manually check those. Also, it will skip the files that are identical but will write new files that have been created on the template in the meantime.

This is fantastic, I can have my own templates and update them so I can sync my repos if I want to keep the template files in sync with the original template.

## A Repository for Templates

The first thing that I did later was creating a repository with all my templates so I can use each of them based on the specific situation:

```bash
$ nix run nixpkgs#tree -- -L 1 -d templates/
templates/
├── base-with-flake
├── golang-gomod
└── python-poetry

4 directories
```

For instance, I can use it like this:

```bash
$ mkdir my-new-repo
$ cd my-new-repo
$ nix flake init -t github:brokenpip3/my-flake-templates#python-poetry
```

To initialize a python project.

### Dry and Dog Walks

But then an important dilemma: for files like gitignore or editorconfig, do I need to repeat them for each directory?

No, I should have a common directory where I have all the files that are the same across the templates directory and keep them in sync like this:

```bash
$nix run nixpkgs#tree -- -L 1
.
├── common
├── flake.lock
├── flake.nix
├── README.md
└── templates

3 directories, 3 files
```

But how can I keep in sync the common files with all the templates?

#### Attempt #1: Symlink

The first attempt was creating a symlink between the common files and the templates, so I can write a gitignore only once and propagate it for all my templates.

Something like:

```bash
cd templates/python-poetry
ln -s ../../common/.gitignore .
```

However, what I discovered was that the flake template is working so well that indeed it is copying my `.gitignore` or similar common files as.. symbolic links that are broken since they are referring to files that do not exist on my new repo.

#### Attempt #2: recursive template

I was already thinking of a complicated bash script that will run in the repo, check the hash of each source file and compare it with the destination ones if they exist etc etc when I decided to take my dog for a walk. And while I was thinking about something else, I came up with an idea: let's make the common files dir another internal hack flake template and let's update the templates directory with that! Bingo!

So, in the end, this is the final situation:

```bash
$ nix run nixpkgs#tree -- -L 2
.
├── common
│   ├── files
│   ├── flake.nix
│   └── _update.sh
├── flake.lock
├── flake.nix
├── README.md
└── templates
├── base-with-flake
├── golang-gomod
└── python-poetry

7 directories, 5 files
```

So I have my common/files dir with all the common files and then I run the update shell script that will just go into each `templates` directory and run `nix flake init -t ../../common` there, profit!

This is an example output of running the shell script:

```nix
2024-03-19T22:59:54+00:00 - INFO - Updating the files in template templates/python-poetry:
skipping identical file: /nix/store/jsi52p8lpv1fdnf713h2qpn2smmz3vm7-source/common/files/.github/workflows/ci-pre-commit.yaml
wrote: /home/player1/repo/my-flake-templates/templates/python-poetry/.github/workflows
skipping identical file: /nix/store/jsi52p8lpv1fdnf713h2qpn2smmz3vm7-source/common/files/.github/dependabot.yaml
wrote: /home/player1/repo/my-flake-templates/templates/python-poetry/.github
skipping identical file: /nix/store/jsi52p8lpv1fdnf713h2qpn2smmz3vm7-source/common/files/.editorconfig
skipping identical file: /nix/store/jsi52p8lpv1fdnf713h2qpn2smmz3vm7-source/common/files/.envrc
skipping identical file: /nix/store/jsi52p8lpv1fdnf713h2qpn2smmz3vm7-source/common/files/.git-commit-template
skipping identical file: /nix/store/jsi52p8lpv1fdnf713h2qpn2smmz3vm7-source/common/files/.gitignore
skipping identical file: /nix/store/jsi52p8lpv1fdnf713h2qpn2smmz3vm7-source/common/files/.pre-commit-config.yaml
skipping identical file: /nix/store/jsi52p8lpv1fdnf713h2qpn2smmz3vm7-source/common/files/taskfile.yaml
```

I will add a GitHub action that will do it for me or a pre-commit hook to avoid doing it manually all the time and I can keep my templates in sync and by doing that my repos in sync!

## Final version

This is the final version of my brand new tool for initializing and keeping a git repo in sync:

```nix
$ nix flake init --template /home/player1/repo/my-flake-templates#python-poetry
wrote: /tmp/barfoo/new/ciao/.github/workflows/ci-pre-commit.yaml
wrote: /tmp/barfoo/new/ciao/.github/workflows
wrote: /tmp/barfoo/new/ciao/.github/dependabot.yaml
wrote: /tmp/barfoo/new/ciao/.github
wrote: /tmp/barfoo/new/ciao/src/__init__.py
wrote: /tmp/barfoo/new/ciao/src
wrote: /tmp/barfoo/new/ciao/.editorconfig
wrote: /tmp/barfoo/new/ciao/.envrc
wrote: /tmp/barfoo/new/ciao/.git-commit-template
wrote: /tmp/barfoo/new/ciao/.gitignore
wrote: /tmp/barfoo/new/ciao/.pre-commit-config.yaml
wrote: /tmp/barfoo/new/ciao/README.md
wrote: /tmp/barfoo/new/ciao/flake.nix
wrote: /tmp/barfoo/new/ciao/poetry.lock
wrote: /tmp/barfoo/new/ciao/pyproject.toml
wrote: /tmp/barfoo/new/ciao/taskfile.yaml


Python poetry flake template

## Using this Flake

This flake is designed to package applications using poetry2nix. Follow these steps to use this flake:

1. Add the script in the pyproject.toml file of your project:

| [tool.poetry.scripts]
| app = "src.myfile:main"

· src is the source directory of your python files
· myfile it's the file where the main function is
· main name of the main function

2. Run nix develop to set up the development environment with the necessary dependencies.
3. Run poetry install
4. Write you application and add the dependencies each time with poetry add <name>
5. Run nix run or nix build to build and run this application using nix

## More details

· poetry2nix
```

And this is my templates [repository](https://github.com/brokenpip3/my-flake-templates) if you want to take a look.
