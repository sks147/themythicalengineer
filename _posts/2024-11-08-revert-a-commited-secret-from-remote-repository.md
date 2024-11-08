---
layout: post
title: "Revert a commited secret from remote repository"
date: 2024-11-08 10:41 +0530
categories: development
author: themythicalengineer
tags: development git github bitbucket
comments: false
blogUid: 27a3d4fa-9e1c-4998-99e1-e55f714322f4
---

To remove the last commit that contains a secret from your remote repository (GitHub, Bitbucket, etc.) and push again, you can follow these steps:

1. First, remove the last commit locally while keeping the changes:

```bash
git reset --soft HEAD~1

```

This command will undo the last commit but keep the changes in your working directory.

2. Now, remove the secret from your files and stage the changes:

```bash
# Edit the file to remove the secret
git add .

```

3. Commit the changes without the secret:

```bash
git commit -m "Removed sensitive information"

```

4. Force push to the remote repository:

```bash
git push origin +main

```

The `+` before the branch name in the push command forces the push, overwriting the remote history.

Replace `main` with your branch name if it's different.
