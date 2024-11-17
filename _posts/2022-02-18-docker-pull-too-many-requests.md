---
layout: post
title: "Docker Pull Too Many Requests"
date: 2022-02-18 09:37 +0530
categories: development
author: themythicalengineer
tags: development docker aws devops linux
comments: false
blogUid: 03d59e7d-1372-40ba-af75-ffab28b44e00
---

![docker-pull-too-many-requests.webp](/assets/images/docker-pull-too-many-requests/docker-pull-too-many-requests.webp)

```bash
[stderr]toomanyrequests: You have reached your pull rate limit.
You may increase the limit by authenticating 
and upgrading: https://www.docker.com/increase-rate-limit
```

What to do if you face Docker rate limit issue when your servers are on fire and you need to do an immediate deployment to a new server to scale up.

A long term solution would be to setup a proxy for Docker hub or a private docker repository.

But the immediate solution would be to copy the Docker image from another server.

Here's how to move a Docker image from one server to another without having to push it to a Docker repository!


### Step 1: Export the image to a file.
Let's say you want to copy `node:13.8-slim` docker image. On the source server check the docker image.
```bash
$ docker image ls
REPOSITORY  TAG         IMAGE ID       CREATED         SIZE
node        13.8-slim   49f182bca73c   24 months ago   166MB
```
Now export this docker image to a file. We will use the `docker save` command
```bash
$ docker save [OPTIONS] IMAGE [IMAGE...]
```
```bash
$ docker save -o ~/node_13_8_slim.tar node
# you might need to change privileges of exported file
# if you used sudo in previous command
$ sudo chmod 777 ~/node_13_8_slim.tar
```

### Step 2: Push the image to S3 bucket or copy it on your local system.

Before pushing the docker image file to S3 bucket, you must make sure that source server has access to S3. You can do that with IAM role or setting up credentials on the server. In this example I'm pushing it to a public S3 bucket from source server.
```bash
$ aws s3 cp node_13_8_slim.tar s3://upload-bucket-temp/docker_images/ --acl public-read
```

Or if you want to copy the image to local system.
```
$ scp source_server:~/node_13_8_slim.tar ~/Desktop/node_13_8_slim.tar
```

### Step 3: Pull the docker image file into destination server.
If you pushed it to S3 bucket. Run these commands on destination server
```bash
$ wget https://upload-bucket-temp/docker_images/node_13_8_slim.tar
```

If you copied into local system. Push the image from local system to destination server
```bash
$ scp ~/Desktop/node_13_8_slim.tar destination_server:~/node_13_8_slim.tar
```

### Step 4: Load the Docker image into destination server
```bash
$ docker load -i ~/node_13_8_slim.tar
```
Check the images list and verify your image is present on the server
```
$ docker image ls
```

This is how you can quickly copy docker images from one server to another.
