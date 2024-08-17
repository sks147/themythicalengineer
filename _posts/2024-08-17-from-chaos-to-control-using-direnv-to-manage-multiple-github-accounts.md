---
layout: post
title: "From Chaos to Control: Using Direnv to Manage Multiple GitHub Accounts"
date: 2024-08-17 12:22 +0530
categories: development
author: themythicalengineer
tags: development linux macos productivity terminal
comments: false
blogUid: b7d7918f-cadb-4541-95d0-ba4b9d84ddce
---

### The Big Problem
Imagine you have two GitHub accounts: one for personal use and one for work. You might be working on personal projects from your work laptop, but switching between these projects often requires manually updating your GitHub configuration:

```bash
git config user.name <your-user-name>
git config user.email <your-email>
```

Forgetting to switch these settings can lead to issues, such as accidentally committing company code with your personal GitHub account or exposing your company email in open-source projects. This can create confusion and potential privacy concerns.

### How to manage multiple github accounts in your laptop

Add this to `~/.ssh/config`

```bash
Host *
    addkeystoagent yes
    identitiesonly yes
    include config.d/*

Host github.com
	HostName github.com
	User git
	IdentityFile ~/.ssh/id_ed25519
	IdentitiesOnly yes
```

The line `include config.d/*` imports all the ssh configurations from `config.d` directory  

Add this to `~/.ssh/config.d/personal`

```bash
Host github.com-personal
	HostName github.com
	User git
	IdentityFile ~/.ssh/id_ed25519_personal
	IdentitiesOnly yes
```

This is how your `~/.ssh` directory structure will look like

```bash
themythicalengineer@fedora:~/.ssh$ tree
.
├── config
├── config.d
│   └── personal
├── id_ed25519 # company key
├── id_ed25519.pub
├── id_ed25519_personal # personal key
├── id_ed25519_personal.pub
```

### How to clone repositories for different github accounts using ssh

> To fetch company account repositories

```bash
git clone git@github.com:<company>/<repo-name>.git
```

> To fetch personal account repositories

```bash
git clone git@github.com-personal:<username>/<repo-name>.git
```

Now that we've set up both GitHub accounts, the next step is to seamlessly switch between them.

### Create Separate directories

The first step is to keep your company and personal projects in separate directories.

```bash
themythicalengineer@fedora:~/$ tree
.
├── personal
├── company
```

### Install direnv
Please check [Official instructions](https://direnv.net/docs/installation.html)

### Create direnv configurations in personal and company directories

```bash
cd personal
touch .envrc
touch .gitconfig
direnv allow
```

Allow direnv in this directory

```
direnv allow
```

Add this to `.envrc`

```bash
export GIT_CONFIG_GLOBAL=$(pwd)/.gitconfig
```

Add this to `.gitconfig`
```bash
[user]
    name = <your-personal-github-username>
    email = <your-personal-email>
```

You can set your global Git configuration to use your company username, or you can configure your company-specific settings directly within the project directory.

Whenever you switch to this directory, you'll see the direnv configuration automatically applied.

```bash
direnv: loading ~/personal/.envrc
direnv: export +GIT_CONFIG_GLOBAL
```

When you navigate out of this directory, you'll receive a log indicating that the configuration has reverted to its previous state.

```bash
direnv: unloading
```

Now you never have to manually change your GitHub username when switching between personal and work projects.

Cheers!