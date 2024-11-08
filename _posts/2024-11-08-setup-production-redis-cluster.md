---
layout: post
title: "Setup a Production Redis Cluster"
date: 2024-11-08 08:54 +0530
categories: development
author: themythicalengineer
tags: aws redis database cache cluster
comments: false
blogUid: 4d3737d6-21c4-42e2-93c2-7fa1ee253728
---
![redis-cluster-banner](/assets/images/setup-production-redis-cluster/production-ready-redis-cluster.webp)

In this blog post, I'll explain how to set up a production-ready Redis cluster. We'll create a 6-node cluster with 3 master nodes and 3 replica nodes. This setup provides both high availability and data sharding capabilities.

This guide assumes you have basic knowledge of Linux systems and Redis concepts. All commands are bash-compatible and can be run on Ubuntu systems. You can automate this process by combining these commands into a single bash script.

## Prerequisites: Kernel Parameter Tuning

Just like in our standalone setup, we need to tune kernel parameters for optimal performance. These settings should be applied to all nodes in the cluster.

```bash
# Increase limits /etc/security/limits.conf 
echo "* soft nofile 1048576" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 1048576" | sudo tee -a /etc/security/limits.conf
echo "* soft nproc 10240" | sudo tee -a /etc/security/limits.conf
echo "* hard nproc 10240" | sudo tee -a /etc/security/limits.conf

# Disable transparent hugepages
sudo su
echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
exit

# Optimize network and system settings
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

Install the required utilities on all nodes:

```bash
# Install system utilities
sudo apt-get update -y
sudo apt-get install -y htop procps lsof rsync dnsutils jq make gcc libc6-dev tcl ruby ruby-dev net-tools

# Install redis client
sudo apt-get install -y redis-tools
sudo gem install redis
```

## Redis Installation

Install Redis on all nodes:

```bash
# Specify redis version
redis_version=redis-6.2.14

# Install redis server
wget https://github.com/redis/redis/archive/refs/tags/${redis_version}.tar.gz
tar xzf ${redis_version}.tar.gz
cd ${redis_version}

# Compile Redis
make

# Test the installation
make test
```

Create necessary directories on all nodes:

```bash
# Create directories and set permissions
sudo mkdir -p /var/log/redis
sudo mkdir -p /var/lib/redis
sudo mkdir -p /etc/redis
sudo chown -R ubuntu:ubuntu /etc/redis
sudo chown -R ubuntu:ubuntu /var/log/redis/
sudo chown -R ubuntu:ubuntu /var/lib/redis/
sudo chown -R ubuntu:ubuntu /var/lib/gems/

# Copy redis server executable
sudo cp ~/${redis_version}/src/redis-server /usr/local/bin/
```

## Redis Cluster Configuration

We'll set up 6 Redis instances (3 masters + 3 replicas) across different ports. Here's the configuration for each node:

```bash
# Create base configuration
HOST_IP=$(hostname -I | awk '{print $1}')
sudo tee -a /etc/redis/redis.conf << END
bind ${HOST_IP}
protected-mode no
port 7000
tcp-backlog 65536
timeout 300
tcp-keepalive 300
daemonize no
pidfile /var/run/redis/redis-server.pid
loglevel notice
logfile /var/log/redis/redis-server.log
stop-writes-on-bgsave-error no
dbfilename dump.rdb
dir /var/lib/redis
replica-serve-stale-data no
repl-diskless-sync yes
repl-diskless-sync-delay 1
repl-backlog-size 512mb
repl-backlog-ttl 3600
rename-command KEYS ""
rename-command FLUSHDB ""
rename-command FLUSHALL ""
maxclients 65536
lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes
replica-lazy-flush yes
lazyfree-lazy-user-del yes
lazyfree-lazy-user-flush yes
io-threads 1
disable-thp yes
lua-time-limit 5000
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 15000
cluster-replica-validity-factor 0
cluster-allow-replica-migration no
cluster-require-full-coverage yes
cluster-replica-no-failover no
cluster-allow-reads-when-down no
slowlog-log-slower-than 10000
slowlog-max-len 128
notify-keyspace-events "AE"
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 1gb 1gb 60
client-output-buffer-limit pubsub 1gb 1gb 60
hz 50
dynamic-hz yes
activedefrag yes
jemalloc-bg-thread yes
rdb-save-incremental-fsync yes
jemalloc-bg-thread yes
END
```

> You can modify the above configuration as per your requirements. But this configuration is good for most of the use cases and has been tested in production at very high scale with sufficiently large dataset.

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

Start all Redis service in all 6 instances:
```bash
# Start redis as a daemonized process
sudo systemctl daemon-reload
sudo systemctl enable /etc/systemd/system/redis.service
sudo systemctl start redis.service
sudo systemctl status redis.service
```

## Creating the Cluster

Once all nodes are running, we can create the cluster. Replace the IP addresses with your actual node IPs:

```bash
redis-cli --cluster create \
  192.168.1.10:7000 192.168.1.11:7000 192.168.1.12:7000 \
  192.168.1.13:7000 192.168.1.14:7000 192.168.1.15:7000 \
  --cluster-replicas 1
```

> For the above command to work, you need to have both port 7000 and 17000 open in the security group.

This command will automatically assign replicas to masters and create the cluster.

## Verifying the Cluster

Check the cluster status:

```bash
redis-cli -c -p 7000 CLUSTER INFO
redis-cli -c -p 7000 CLUSTER NODES
```

Test the cluster with some basic commands:

```bash
redis-cli -c -p 7000
127.0.0.1:7000> SET user:1 "John"
-> Redirected to slot [5474] located at 192.168.1.11:7001
OK
127.0.0.1:7001> GET user:1
"John"
```

## Conclusion

You now have a production-ready Redis cluster with 3 master nodes and 3 replica nodes. This setup provides:
- High availability through replication
- Automatic failover
- Data sharding across multiple nodes
- Better scalability compared to standalone setup

Remember to monitor your cluster's health regularly and plan for maintenance windows when needed.


