---
layout: post
title: "How to install Cursor AI IDE on Fedora Asahi Linux Arm64"
date: 2024-11-09 14:15 +0530
categories: development
author: themythicalengineer
tags: development
comments: false
blogUid: ed7db928-7522-4a83-8ab9-9ad513c723d2
---
![cursor_ai_fedora_asahi_linux_banner](/assets/images/cursor-ai-ide-on-fedora-asahi-linux/cursor_ai_fedora.webp)

[Cursor AI IDE](https://www.cursor.com/) is a powerful AI-powered IDE that can help you write code faster and more efficiently.

I recently install Fedora Asahi Linux on my Macbook M1.
Cursor AI IDE is not currently officially available for Linux Arm64 architecture.
Thankfully, someone has created a build for Linux Arm64 architecture.

You can follow the steps below to install Cursor AI IDE on Fedora Asahi Linux.

Step 1: Download latest release AppImage from [here](https://github.com/coder/cursor-arm)

```bash
mkdir -p ~/Applications
cd ~/Applications
wget https://github.com/coder/cursor-arm/releases/download/v0.42.2/cursor_0.42.2_linux_arm64.AppImage
```

Step 2: Make the AppImage executable

```bash
chmod +x cursor_0.42.2_linux_arm64.AppImage
```

Step 3: Download cursor logo from [here](https://avatars.githubusercontent.com/u/126759922?v=4)

```bash
cd ~/Applications
wget https://avatars.githubusercontent.com/u/126759922?v=4 -O cursor.png
```

Step 4. Create desktop entry

```bash
mkdir -p ~/.local/share/applications
touch ~/.local/share/applications/cursor.desktop
```

Step 4. Add details to the desktop entry

```bash
# Replace Exec and Icon path with your own.
tee -a ~/.local/share/applications/cursor.desktop<<EOF
[Desktop Entry]
Name=Cursor
Comment=Cursor
Exec=/home/themythicalengineer/Applications/cursor_0.42.2_linux_arm64.AppImage
Icon=/home/themythicalengineer/Applications/cursor.png
Type=Application
Categories=Utility;
Terminal=false
EOF
```

Step 5: Make the desktop entry executable

```bash
chmod +x ~/.local/share/applications/cursor.desktop
```

Now you should be able to see Cursor AI IDE in your applications menu.

These steps should work on any Linux distribution that supports AppImage.