#!/bin/bash

post_title="$*"
[ -z "$post_title" ] && printf 'Error: Script needs a post title.\n' && exit 1

repo_dir="$(git rev-parse --show-toplevel)"
post_date="$(date '+%Y-%m-%d %H:%S %z')"
file_date="$(date '+%Y-%m-%d')"
title_slug="$(printf -- "$post_title" | sed -E 's/[^a-zA-Z0-9]+/-/g' | tr "[:upper:]" "[:lower:]")"
post_path="${repo_dir}/_posts/${file_date}-${title_slug}.md"

echo $post_path

[ -e "$post_path" ] && printf 'Error: Post exists already.\n' && exit 2

uuid=$(uuidgen)
blogUid=$(echo $uuid | tr "[:upper:]" "[:lower:]")
# echo $blogUid

tee -a $post_path << END
---
layout: post
title: "${*}"
date: ${post_date}
categories: development
author: themythicalengineer
tags: development
comments: false
blogUid: $blogUid
---

END
