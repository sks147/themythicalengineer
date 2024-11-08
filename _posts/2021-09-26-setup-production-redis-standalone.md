---
layout: post
title: Setup a production Redis standalone server
date: 2021-09-26 16:12 +0530
categories: devops
author: themythicalengineer
tags: aws redis database cache
comments: false
blogUid: "8c76debc-9fd2-46b7-9868-db16c9b7afbe"
---
![redis-standalone-banner](/assets/images/setup-production-redis-standalone/production-ready-redis-standalone.webp)

In this blog post, I'll be explaining the steps you need to perform to have a production-ready Redis standalone setup.
This assumes you have a basic understanding of linux system and some of it's kernel parameters.
All the commands are bash compatible and you can run them directly into any ubuntu system.
These commands can be put in a single bash file and can be used to automate the process as well.
Some commands and kernel parameters may vary based on your linux distribution.


## Prerequisites: Tuning Kernel Parameters

Linux has a Max Processes per user limit. First thing we should do is increase the limits of number of files and number of processes. If the use case is to handle a large number of connections in a high performance environment, you should consider tuning the following kernel parameters

```
nofile - max number of open files
nproc - max number of processes
```

We have to increase `nofile` and `nproc` limits.

We can increase the limits by running these commands in terminal.
```bash
# Increase limits /etc/security/limits.conf 
echo "* soft nofile 1048576" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 1048576" | sudo tee -a /etc/security/limits.conf
echo "* soft nproc 10240" | sudo tee -a /etc/security/limits.conf
echo "* hard nproc 10240" | sudo tee -a /etc/security/limits.conf

# Disable transparent hugepages feature to optimize performance on high load
sudo su
echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
exit

sudo sysctl -w vm.swappiness=0                       # turn off swapping
sudo sysctl -w net.ipv4.tcp_sack=1                   # enable selective acknowledgements
sudo sysctl -w net.ipv4.tcp_window_scaling=1         # scale the network window
sudo sysctl -w net.ipv4.tcp_timestamps=1             # needed for selective acknowledgements
sudo sysctl -w net.ipv4.tcp_congestion_control=cubic # better congestion algorithm
sudo sysctl -w net.ipv4.tcp_syncookies=1             # enable syn cookies
sudo sysctl -w net.ipv4.tcp_tw_recycle=1             # recycle sockets quickly
sudo sysctl -w net.ipv4.tcp_max_syn_backlog=65536    # backlog setting
sudo sysctl -w net.core.somaxconn=65536              # up the number of connections per port
sudo sysctl -w net.core.rmem_max=212992              # up the receive buffer size
sudo sysctl -w net.core.wmem_max=212992              # up the buffer size for all connections

```

Now you should reboot your system or run the following command to reload the config
```bash
# reload sysctl config
sudo sysctl -p
```

## Prerequisites: Software Dependencies and Utilities

```bash
# Install some linux utilities
sudo apt-get update -y
sudo apt-get install -y htop procps lsof rsync dnsutils jq make gcc libc6-dev tcl ruby ruby-dev net-tools

# Install redis client
sudo apt-get install -y redis-tools
sudo gem install redis
```

Since your production systems might have need of a specific redis version. So these scripts can be used as it is if you just change value of your `redis_version` variable.

## Redis Installation

```bash
# Specify any redis version
redis_version=redis-6.2.5

# Install redis server
wget http://download.redis.io/releases/${redis_version}.tar.gz
tar xzf ${redis_version}.tar.gz
cd ${redis_version}

# Compile redis
make

# Test your redis installation
make test
```

```bash
# Create necessary directories and update permissions

sudo mkdir -p /var/log/redis
sudo mkdir -p /var/lib/redis
sudo mkdir -p /etc/redis
sudo chown -R ubuntu:ubuntu /etc/redis
sudo chown -R ubuntu:ubuntu /var/log/redis/
sudo chown -R ubuntu:ubuntu /var/lib/redis/
sudo chown -R ubuntu:ubuntu /var/lib/gems/
```

```bash
# Copy redis server executable to recommended directory for daemonized process
sudo cp ~/${redis_version}/src/redis-server /usr/local/bin/
sudo rm ~/${redis_version}/redis.conf
sudo touch ~/${redis_version}/redis.conf
```

## Redis Configuration

Change the required redis.conf parameters.

```bash
sudo tee -a ~/${redis_version}/redis.conf << END
appendfsync always
appendonly yes
bind 0.0.0.0
daemonize no
dir /var/lib/redis
logfile /var/log/redis/redis-server.log
maxclients 30000
pidfile /var/run/redis/redis-server.pid
requirepass SOME_SECURE_PASSWORD
tcp-backlog 65536
END
```

Rest all parameters will be set as default redis.conf parameters.

```bash
# Copy redis.conf to recommended directory for daemonized process
sudo cp ~/${redis_version}/redis.conf /etc/redis/redis.conf
```

## Running redis as a background service

To run redis as background system service. You can create a systemd redis service
The command below will create a service configuration at `/etc/systemd/system/redis.service`

```bash
# Create a systemd redis service

sudo tee -a /etc/systemd/system/redis.service << END
[Unit]
StartLimitIntervalSec=300
StartLimitBurst=2
Description=Redis
After=syslog.target

[Service]
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
RestartSec=5s
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
END
```

Now you can start the redis in background using systemctl.
```bash
# Start redis as a daemonized process
sudo systemctl daemon-reload
sudo systemctl enable /etc/systemd/system/redis.service
sudo systemctl start redis.service
sudo systemctl status redis.service
```

## Done

Congrats, Now you have a running redis standalone setup which can be used in production environments.
```bash
# Now you can test your commands

redis-cli
127.0.0.1:6379> AUTH SOME_SECURE_PASSWORD
OK
127.0.0.1:6379> GET a
(nil)
127.0.0.1:6379> SET a 1
OK
127.0.0.1:6379> GET a
"1"
127.0.0.1:6379>
```