---
layout: post
title: "How to restart Mac OS Network from Terminal"
date: 2023-04-23 16:40 +0530
categories: macos
author: themythicalengineer
tags: macos networking script terminal command
comments: false
blogUid: ddba1c41-cbd2-4281-ba8f-ebb8f461dab4
---

![banner](/assets/images/restart-mac-os-network-from-terminal/restart-macos-wifi-using-terminal.webp)

Apparently, Mac OS has some issues with Wi-Fi.
It doesn't work after it wakes up from sleep.

You have to turn wifi on and off to make it work again. 

Usually my terminal is open all the time and I prefer to use keyboard for most of the operations on my setup.

You can use `ifconfig` utility to restart the network
```bash
sudo ifconfig en0 down
sudo ifconfig en0 up
```

But this command requires sudo, and writing long passwords is cumbersome.

Fortunately there's a `networksetup` utility in macos, which can do it without `sudo`.
```bash
networksetup -setairportpower en0 off
networksetup -setairportpower en0 on
```

You can add these commands as alias in `~/.zshrc` or `~/.bashrc` file for faster access.
```bash
alias netoff='networksetup -setairportpower en0 off'
alias neton='networksetup -setairportpower en0 on'
alias netrestart='networksetup -setairportpower en0 off && networksetup -setairportpower en0 on'
```

Remember to source the `.rc` file for accessing the newly defined aliases.
```bash
source ~/.zshrc # If you use zsh as your shell
# OR
source ~/.bashrc # If you use bash as your shell
```

Now you just need to run `netrestart` on your terminal and your wifi will restart.

