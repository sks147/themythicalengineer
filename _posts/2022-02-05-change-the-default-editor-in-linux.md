---
layout: post
title: "Change the default editor in Linux"
date: 2022-02-05 09:43 +0530
categories: devops
author: themythicalengineer
tags: development linux ubuntu server
comments: false
blogUid: a8087444-427b-4b5e-9734-264111fb3d84
---

![change-the-default-editor-in-linux](/assets/images/change-the-default-editor-in-linux/change-the-default-editor-in-linux.webp)

You can change the default command-line text editor on a ubuntu server used by various programs, such as `crontab`.
For example, many servers are configured to use `nano` as the default text editor.
However, if you like `vim` more than `nano`, you may want to use it as the default editor instead.

There are multiple ways to do it.

---

### Method #1 : Use the select-editor command
`select-editor` command lists the available editors on a system and interactively prompts the user to select one.
```bash
$ select-editor

Select an editor.  To change later, run 'select-editor'.
  1. /bin/nano        <---- easiest
  2. /usr/bin/vim.basic
  3. /usr/bin/vim.tiny
  4. /bin/ed

Choose 1-4 [1]:
```

Type `3` and press `Enter`. Now your default editor is vim.

---

### Method #2: Set default editor in `.bashrc` file.
Find the path to your preferred editor.
```bash
$ which vim
/usr/bin/vim
```

Add this line to your `.bashrc`
```bash
export EDITOR="/usr/bin/vim"
```
and run 

```
source ~/.bashrc
```
Your default editor will be set to vim.
This method should work for most of the linux distributions available.