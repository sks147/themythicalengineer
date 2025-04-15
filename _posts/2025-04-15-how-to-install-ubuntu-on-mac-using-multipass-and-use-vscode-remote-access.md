---
layout: post
title: "How to Install Ubuntu on Mac Using Multipass and Use VSCode Remote Access"
date: 2025-04-15 05:48 +0530
categories: development
author: themythicalengineer
tags: macos ubuntu multipass vscode remote-development
comments: false
blogUid: bff1a5d0-7186-4217-abe9-fd1bf4e92225
---

Ever got stuck with working on some older projects which won't compile on mac, but they run well on your ubuntu server?

Well, you can now run ubuntu on your mac and use vscode to remote access it.

In this post, I'll show you how to setup ubuntu on your mac using multipass and use vscode to remote access it.

---

### **Why Multipass?**  
Multipass simplifies Ubuntu VM management with a CLI-driven workflow. It’s optimized for macOS, uses minimal resources. Pair it with VSCode’s Remote SSH extension, and you get a native development environment for Linux projects without dual-boot.
If you want to dual boot on silicon mac, you can try Fedora Asahi Linux.

---

### **Prerequisites**  
- macOS 12.3 or newer (Intel or Apple Silicon)  
- VSCode with the [Remote SSH extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh)  

---

### **Step 1: Install Multipass**  
Open Terminal and install Multipass:  
```bash
wget https://github.com/canonical/multipass/releases/download/v1.15.1/multipass-1.15.1+mac-Darwin.pkg

open multipass-1.15.1+mac-Darwin.pkg
```
Follow the manual installation steps.

Verify the installation:  
```bash  
multipass version
```

---

### **Step 2: Launch an Ubuntu Instance**  
Create a VM named `primary` (adjust CPU, RAM, and disk as needed):  
You can also use the multipass GUI to launch the instance and mount your local directory to the instance as well.

```bash
multipass launch --name primary 20.04 --cpus 4 --memory 4G --disk 30G

# OR If you want to mount your local directory to the instance use
multipass launch --name primary 20.04 --cpus 4 --memory 4G --disk 30G --mount /local/path:/instance/path
```
Wait for the VM to initialize. Once done, check its status:  
```bash  
multipass list
```

---

### **Step 3: Set Up SSH Access**  
#### **Retrieve the VM’s IP Address**  
```bash  
multipass info primary  
```
Note the IPv4 address (e.g., `192.168.64.2`).  

#### **Generate SSH Keys**  
On your Mac, generate a key pair if you haven’t already:  
```bash  
ssh-keygen -t rsa -b 4096
chmod 600 ~/.ssh/id_rsa
```
Copy the public key to the VM:  
```bash  
multipass transfer ~/.ssh/id_rsa.pub ubuntu-vm:/home/ubuntu/.ssh/authorized_keys

# OR
# You can manually copy the public key content in the authorized_keys file in ubuntu vm
```

#### **Configure SSH on the VM**  
Access the VM’s shell:  
```bash  
multipass shell primary  
```
Update the SSH configuration to enforce key-based authentication:  
```bash  
sudo vim /etc/ssh/sshd_config  
```
Ensure these lines are uncommented and set:  
```bash  
PubkeyAuthentication yes  
PasswordAuthentication no  
```
Restart the SSH service:  
```bash  
sudo systemctl restart ssh  
```
Exit the VM:  
```bash  
exit  
```

---

### **Step 4: Connect VSCode to the VM**  
#### **Configure SSH on macOS**  
Add this entry to `~/.ssh/config`:  
```bash  
Host ubuntuvm  
    HostName 192.168.64.2  # Replace with your VM’s IP  
    User ubuntu  
    IdentityFile ~/.ssh/id_rsa  
    ServerAliveInterval 120  
```

#### **Connect via VSCode**  
1. Open VSCode, press `Cmd+Shift+P`, and select **Remote-SSH: Connect to Host**.  
2. Choose `ubuntuvm` from the list.  
3. VSCode will connect and set up the remote environment.  

---

### **Troubleshooting**  
- **VM Not Starting**: Check the Multipass daemon:  
  ```bash  
  sudo launchctl list | grep multipass  
  ```
- **SSH Connection Refused**: Verify the VM’s IP hasn’t changed using `multipass info`.  
- **Permission Issues**: Ensure private key permissions are strict:  
  ```bash  
  chmod 600 ~/.ssh/id_rsa  
  ```

### **To terminate instance**
```bash
multipass delete <instance-name>
```

### **Change instance configuration**
```bash
multipass stop primary
multipass set local.primary.cpus=6
multipass set local.primary.disk=60G
multipass set local.primary.memory=8G
```
---

You now have a fully functional Ubuntu VM on your Mac. If you are working on some legacy projects, I would recommend choosing the oldest ubuntu version available.



