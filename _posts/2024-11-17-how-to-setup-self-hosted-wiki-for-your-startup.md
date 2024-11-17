---
layout: post
title: "How to setup self hosted wiki for your startup"
date: 2024-11-17 10:52 +0530
categories: development
author: themythicalengineer
tags: wiki documentation postgres elasticsearch docker startup aws ec2
comments: false
blogUid: 8e0e38a6-0abe-4e85-a75a-096ca8ffd4ff
---

![wiki_js_banner](/assets/images/setup-self-hosted-wiki/wiki_js.webp)

When it comes to setting up a wiki for your startup, you've probably looked at popular options like Confluence and Notion. While these tools are feature-rich, there's one major drawback: they can get expensive really fast.

Most of these services charge per user per month (typically around $5), and even with enterprise negotiations, the costs can add up quickly as your team grows. Sure, they offer advanced features and granular access controls, but let's be honest - most startups don't need all those fancy features.

This is where self-hosted solutions shine. Your costs stay fixed regardless of how many employees join your company. After running a self-hosted wiki in production for over 3 years, I can confidently recommend [Wiki.js](https://js.wiki/) as an excellent alternative to paid softwares.

## Why Wiki.js?

Setting up Wiki.js is surprisingly simple - you can have it running in minutes using Docker Compose. The basic setup (Wiki.js + PostgreSQL) is quite lightweight and can run smoothly on a modest server with:
- 4GB RAM
- 2 vCPU

If you want better search capabilities, you can add Elasticsearch as well, but you'll need to increase the resources to atleast:
- 8GB RAM
- 2 vCPU

In our case, we've grown to over **1,000 pages** and nearly **400 users**, and our setup is still going strong. The only maintenance I've had to do was adding Elasticsearch for improved search functionality.

![elasticsearch_setup](/assets/images/setup-self-hosted-wiki/elasticsearch_setup.webp)

## Cost Comparison

Let's talk numbers. Here's what you might pay running this on AWS EC2:

| Instance Type | vCPU | RAM (GiB) | On-Demand ($/hr) | Monthly On-Demand | Reserved 1-year ($/hr) | Monthly Reserved |
|--------------|------|-----------|----------------------|-------------------|----------------------------|-----------------|
| t4g.medium | 2 | 4 | $0.0224 | $16.35 | $0.0142 | $10.37 |
| t4g.large | 2 | 8 | $0.0448 | $32.70 | $0.0283 | $20.66 |

To put this in perspective: if you had **400** users on a typical paid wiki platform charging $5 per user, you'd be looking at a **$2,000+ monthly bill**.

With a self-hosted solution, you will be paying less than **$33/month** even with the larger instance!

If you do need to scale up later, you can take small maintenance downtime to increase the instance size, or you can split the elasticsearch to a different instance.

## Making It Production-Ready

To transform this into a production-ready setup, I recommend implementing the following things:

1. Set up a custom domain like `wiki.yourcompany.com`
2. Configure DNS and a Load Balancer to handle traffic
3. Implement [SSO with Google](https://docs.requarks.io/auth/google)
4. Restrict self-registration to your company domain (e.g., yourcompany.com)
5. Set up hourly AMI backups of your EC2 instance

## The Setup

Here's the Docker Compose file you can use to do the complete setup:

```yaml:docker-compose.yml
services:
  db:
    image: postgres:16.4
    expose:
      - 5432
    ports:
      - 5432:5432
    restart: unless-stopped
    volumes:
      - db-data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: wiki
      POSTGRES_PASSWORD: pass # Change this to a strong password
      POSTGRES_USER: root

  wiki:
    image: requarks/wiki:2.5
    depends_on:
      - db
    environment:
      DB_TYPE: postgres
      DB_HOST: db
      DB_PORT: 5432
      DB_USER: root
      DB_PASS: pass # Change this to a strong password
      DB_NAME: wiki
    restart: unless-stopped
    ports:
      - "80:3000"

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.23
    container_name: elasticsearch
    restart: unless-stopped
    ports:
      - 127.0.0.1:9200:9200
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - xpack.security.http.ssl.enabled=false
      - xpack.license.self_generated.type=basic

volumes:
  db-data:
```