---
layout: post
title: Converting Markdown to Epub or Mobi
date: 2021-04-21 22:21 +0530
categories: development
author: themythicalengineer
tags: script productivity deepnote jupyter
comments: false
blogUid: "37f3ca5e-2b3d-4fd8-9c8a-cc71618a83f7"
---

In this blog post, I will show you the process of combining and converting a list of markdown files into kindle supported ebook (.mobi) format. 

In this example I would be converting official documentation of Docker website into an ebook for offline use.

I will use Pandoc to combine and convert the markdown (.md) files into .epub format. Then I will use Calibre to convert it to .mobi format.

![workflow](/assets/images/converting-markdown-to-epub-mobi/workflow.png)

You can follow the steps and modify the linux commands according to your needs.

If you don't have a linux machine, you can use [Deepnote](https://deepnote.com/) platform to run linux commands in jupyter notebook.

<small>Note: If you're running this in Deepnote, you need to append "!" as prefix to each command, so that deepnote can identify it as bash command. If running in linux machine, remove "!" from all commands written below.</small>

Here is a small video tutorial of the working script.
<div class="resp-container">
    <iframe class="resp-iframe" src="https://www.youtube.com/embed/L4hGDPLMPcw" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</div>

<br/>

Steps to be followed:

```bash
# Download Pandoc executable
!wget https://github.com/jgm/pandoc/releases/download/2.11.3.2/pandoc-2.11.3.2-1-amd64.deb
```

```bash
# Install pandoc
!sudo dpkg -i pandoc-2.11.3.2-1-amd64.deb
```

```bash
# Clone Docker CLI documentation github repository
!git clone https://github.com/docker/cli.git
```

```bash
# Verify the list of markdown files and contents of files
!cd cli/docs/reference/commandline && ls -la
```

```bash
# Generate ebook from markdown files, *.md picks up all the files with .md as extension
!cd cli/docs/reference/commandline && pandoc -o docker_cli.epub --metadata title="Docker CLI Docs" *.md
```

```bash
# Move generated file to required location
!mv cli/docs/reference/commandline/docker_cli.epub ~/work/docker_cli.epub
```

```bash
# Install required dependencies for Calibre
!apt update -y
!apt install libgl1-mesa-glx -y
```

```bash
# Download and install calibre command line utility
!wget -q -O- https://download.calibre-ebook.com/linux-installer.sh | sudo sh /dev/stdin
```

```bash
# Convert ebook to kindle supported .mobi format
!ebook-convert docker_cli.epub docker_cli.mobi
```

Now you can transfer generated .mobi file to your kindle device.

There is also a browser extension called [EpubPress](https://epub.press/), which can convert any webpage into a kindle book in a single click. You can use it convert any webpage or blogs to read on Kindle.

Stay tuned for more tips and tricks <3.
