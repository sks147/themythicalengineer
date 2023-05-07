---
layout: post
title: MongoDB Auto Expire Documents using TTL Index
date: 2020-09-20 15:22 +0530
categories: development
author: themythicalengineer
tags: mongodb nodejs backend scaling
comments: true
blogUid: "54e22e16-4fda-44f7-a074-6909c5733114"
---
![mongodb-expire-banner](/assets/images/mongodb-auto-expire-documents/mongodb-expire-banner.jpg)

When running MongoDB at scale, you might need to remove some data when your collection starts overflowing and your database memory reaches the max limit.

Few types of data that need to be cleaned periodically are:
* Logs
* User sessions
* Notifications
* Advertisements for limited time offers and discounts etc.

There are certain ways to tackle this issue.
* Trigger deletion via application events
* Creating cron scripts for deleting old records based on timestamp
* Using a capped collection which limits the number of records that you can store in it.
* Create Time to Live indexes on the collection and let database do it automatically.

In this post, I'll cover implementation using **Time to Live** indexes in detail. I'll also discuss best practices and technical gotchas you should care about while implementing this technique.

## What is a Time to Live Index?
It's nicely explained in the [official documentation](https://docs.mongodb.com/manual/core/index-ttl/). I'll quote the few important lines here.
> 👉 TTL indexes are special **single-field indexes** that MongoDB can use to automatically remove documents from a collection after a certain amount of time or at a specific clock time.

> 👉 A background thread in [mongod](https://docs.mongodb.com/manual/reference/program/mongod/#bin.mongod) reads the values in the index and removes expired documents from the collection.

## How do I implement it?
Let's say you want to get the record deleted after 1 day of its creation.
```bash
#create a new record
> db.notifications.insert({"createdAt": new Date(), "text": "Test Notification", "user_id": 1234})
{
  "_id": ObjectId("5f5ce5f166fc42c137815c9b"),
  "createdAt": ISODate("2020-09-12T15:14:57.806Z"),
  "text": "Test Notification",
  "user_id": 1234
}
```
To achieve this using TTL indexes you can do this:
```bash
> db.notifications.createIndex({"createdAt":1}, {expireAfterSeconds:86400})
{
  "createdCollectionAutomatically": false,
  "numIndexesBefore": 1,
  "numIndexesAfter": 2,
  "ok": 1,
  "$clusterTime": {
    "clusterTime": Timestamp(1599923870, 2),
    "signature": {
      "hash": BinData(0, "A5uE8V6MQf04wNlrmIxaWuRVnQo="),
      "keyId": NumberLong("6848960729458933762")
    }
  },
  "operationTime": Timestamp(1599923870, 2)
}
```

You can verify if the index is created properly by running `getIndexes` command
```bash
> db.notifications.getIndexes()
[
  {
    "v": 2,
    "key": {
      "_id": 1
    },
    "name": "_id_",
    "ns": "themythicalengineer.notifications"
  },
  {
    "v": 2,
    "key": {
      "createdAt": 1
    },
    "name": "createdAt_1",
    "ns": "themythicalengineer.notifications",
    "expireAfterSeconds": 86400
  }
]
```

You can see that an index with `expireAfterSeconds` parameter is created.
**_id** field is always indexed by default. 

Let's take a look at important points that should be taken care of, for successful implementation in a production environment.

## The Seven Commandments of Implementation:

1. TTL indexes are a single-field indexes. You cannot create a compound index with `expireAfterSeconds` option. Creating TTL index using two or more fields will throw an error.

    ```bash
    > db.notifications.createIndex({"createdAt":1,"text":1}, {expireAfterSeconds:86400})
    {
      "operationTime": Timestamp(1599925286, 1),
      "ok": 0,
      "errmsg": "TTL indexes are single-field indexes, compound indexes do not support TTL. Index spec: { key: { createdAt: 1.0, text: 1.0 }, name: \"createdAt_1_text_1\", expireAfterSeconds: 86400.0 }",
      "code": 67,
      "codeName": "CannotCreateIndex",
      "$clusterTime": {
          "clusterTime": Timestamp(1599925286, 1),
          "signature": {
          "hash": BinData(0, "mCmm0gKiYCSNIpYEggT3LloGKdw="),
          "keyId": NumberLong("6848960729458933762")
          }
      }
    }
    ```

2. The `_id` field does not support TTL indexes. Indexed field should contain value of [ISODate (YYYY-MM-DD HH:MM.SS.millis)](https://docs.mongodb.com/manual/reference/glossary/#term-bson-types) format or an Array which contains dates.
You will be able to create a ttl index on field which doesn't have a ISODate format, but it will not expire.

    ```bash
    # creating index on _id field
    > db.notifications.createIndex({"_id":1,}, {expireAfterSeconds:86400})
    {
      "operationTime": Timestamp(1599925396, 1),
      "ok": 0,
      "errmsg": "The field 'expireAfterSeconds' is not valid for an _id index specification. Specification: { ns: \"5f1118e130ef1b0c1b6271f2_themythicalengineer.notifications\", v: 2, key: { _id: 1.0 }, name: \"_id_1\", expireAfterSeconds: 86400.0 }",
      "code": 197,
      "codeName": "InvalidIndexSpecificationOption",
      "$clusterTime": {
        "clusterTime": Timestamp(1599925396, 1),
        "signature": {
          "hash": BinData(0, "bBhDRiEDafDblhodBTb8NZXVRs0="),
          "keyId": NumberLong("6848960729458933762")
        }
      }
    }
    ```

    ```bash
    # able to create index but it won't expire, as text field does not hold a value of ISODate format
    > db.notifications.createIndex({"text":1,}, {expireAfterSeconds:86400})
    {
      "createdCollectionAutomatically": false,
      "numIndexesBefore": 1,
      "numIndexesAfter": 2,
      "ok": 1,
      "$clusterTime": {
        "clusterTime": Timestamp(1599925696, 2),
        "signature": {
          "hash": BinData(0, "yOPV7m5w8mRKQvAIMcJJ36HYvOw="),
          "keyId": NumberLong("6848960729458933762")
        }
      },
      "operationTime": Timestamp(1599925696, 2)
    }
    ```

3. You should not create a TTL index on a capped collection. `mongod` background process cannot remove documents from a capped collection and will throw an error.

    > 👉 The biggest drawback of capped collections is that you cannot anticipate how large they really need to be. If your application scales up and you receive very large number of documents, you will start to lose important data.

4. You cannot use `createIndex()` to change the value of `expireAfterSeconds` of an existing index. You need to use collMod database command to modify the `expireAfterSeconds` value. Or you can just drop the index and recreate it.

    ```bash
    > db.runCommand({collMod:'notifications', index:{name:'createdAt_1',expireAfterSeconds:60}})
    {
      "expireAfterSeconds_old": 86400,
      "expireAfterSeconds_new": 60,
      "ok": 1,
      "$clusterTime": {
        "clusterTime": Timestamp(1599927916, 1),
        "signature": {
          "hash": BinData(0, "+XZKfn8QVM2wZxHIhLlfXSf+nik="),
          "keyId": NumberLong("6848960729458933762")
        }
      },
      "operationTime": Timestamp(1599927916, 1)
    }
    ```

5. On replica set members, the TTL background thread only deletes documents when a member is in state `primary`. The TTL background thread is idle when a member is in state secondary. Secondary members replicate deletion operations from the primary.

6. The background task that removes expired documents runs every 60 seconds. The TTL index does not guarantee that expired data will be deleted immediately. Duration of removal operation depends on workload hitting your mongod. Expired data may exist beyond the 60 second period between runs of the TTL monitor.

7. If  collection is large, it will take a long time to create an index. Better purge data first, then create index on smaller collection, or create TTL index when creating the collection.

## Best Practices?
There are two ways to implement TTL indexes.
1. Delete after a certain amount of time.
2. Delete at specific clock time.

If you want to keep your system flexible, choose the second option.

### So what can be the issue in first option?
Let's say you intially decided to keep the records for a month before deletion, you'll create a ttl index with `expireAfterSeconds = 30*86400`.

```bash
db.collection('notifications').createIndex({"createdAt": 1}, {epireAfterSeconds: 2592000})
```

But, your company policy changes or the scale of your application increases and you want the records to be deleted in 15 days now. You might have to either drop and recreate the index or run `collMod` command to modify the ttl value.

> Building indexes during time periods where the target collection is under heavy write load can result in reduced write performance and longer index builds.

If the indexes are being built in background, it can affect the read/write efficiency. When you want to modify your index, you might need to have a maintenance period allocated to complete the index build operation. This can lead to some **downtime** in your application.

---

Choosing the second option can let you do the modifications without any downtime. You can easily configure the expiry time using environment variables.

```bash
db.collection('notifications').createIndex({"expireAt": 1}, {epireAfterSeconds: 0})
```
As you can see that `expireAfterSeconds` is set to `0` here, which means record will expire at the value set to `expireAt` field by the application. 

You can use modify your logic anytime to set the value of `expireAt` field without any downtime.
