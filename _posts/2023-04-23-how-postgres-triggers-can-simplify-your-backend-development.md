---
layout: post
title: "How Postgres Triggers Can Simplify Your Backend Development"
date: 2023-04-23 17:59 +0530
categories: development
author: themythicalengineer
tags: development postgres database trigger optimization backend scale backend
comments: false
blogid: cf6b6ea1-4d9d-4a07-8f26-1c5b0a089e29
---

![postgres-triggers-banner](/assets/images/postgres-triggers/postgres-triggers.webp)

In this blog post, we will explore what triggers are, how they work, and how you can use them to simplify your backend service code.

## What Are Postgres Triggers?
A trigger is a specification that the database should automatically execute a particular function in response to certain events. 

These events can include changes to data in a table, such as insertions, updates, or deletions. When an event occurs, the trigger can perform a specified action, such as running a function or updating another table.

## How Do Postgres Triggers Work?
Triggers are associated with a specific table and event, and are defined using SQL commands. When the event occurs, the trigger is activated and executes the specified action. 

For example, you could create a trigger that automatically sets a timestamp column to the current time whenever a row is inserted or updated in a table.

## How Can Triggers Simplify Your Backend Service Code?
By using triggers, you can offload some of the work that would normally be done in your backend service code to the database itself. This can simplify your code. For example, instead of writing complex code to update related tables, you could define triggers that automatically perform these tasks whenever the relevant event occurs.

You should consider the fact that complexity will still be there, but it will be abstracted away inside the database.

---

## Let's take an example to see the utility of triggers.

Let's say we have two database tables `wallet` and `passbook`.

```sql
CREATE TABLE wallet (id BIGINT PRIMARY KEY, amount INTEGER NOT NULL DEFAULT 0)

CREATE TABLE passbook (id BIGINT references wallet(id), txn_id BIGSERIAL PRIMARY KEY, amount INTEGER NOT NULL DEFAULT 0, current_amount INTEGER NOT NULL DEFAULT 0)
```

---

#### Table `wallet` schema

| Column | Type | Constraints |
| --- | --- | --- |
| id | bigint | PRIMARY KEY |
| amount | integer | NOT NULL, DEFAULT 0 |

#### Table `passbook` schema

| Column | Type | Constraints |
| --- | --- | --- |
| id | bigint | FOREIGN KEY (wallet.id) |
| txn_id | bigint | PRIMARY KEY |
| amount | integer | NOT NULL, DEFAULT 0 |
| current_amount | integer | NOT NULL, DEFAULT 0 |


### Use Case:

* The `wallet` table will store the current balance amount, and the `passbook` table will record all transactions with their respective IDs.
* We need to add `amount` to wallet when a passbook record is getting inserted in database, which should be equal to value of `amount` field in passbook record.
* After that operation `current_amount` in the passbook record should be equal to updated `wallet` table `amount` value.

---

## Triggers Implementation

Here's an example of how we can write a PostgreSQL trigger function that adds `amount` to the wallet table when a new passbook record is inserted:

```sql
CREATE FUNCTION update_wallet()
RETURNS TRIGGER AS $$
BEGIN
  -- Get the current wallet balance for the user
  SELECT amount INTO NEW.current_amount FROM wallet WHERE id = NEW.id;

  -- Update the wallet balance with the amount from the passbook record
  UPDATE wallet SET amount = amount + NEW.amount WHERE id = NEW.id;

  -- Set the current amount in the passbook record to the updated wallet balance
  NEW.current_amount = NEW.amount + NEW.current_amount;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

We have to create a trigger on the `passbook` table that calls this function whenever a new record is inserted:

```sql
CREATE TRIGGER update_wallet_trigger
BEFORE INSERT ON passbook
FOR EACH ROW
EXECUTE FUNCTION update_wallet();
```

---

## Application Code:
I'll demonstrate the code using [postgres](https://www.npmjs.com/package/postgres) npm package

### Application Code before triggers:

```javascript
const addMoney = async (transaction, db = sql) => {
	const txn = {
		amount: Math.floor(transaction.amount),
		id: Math.floor(transaction.id),
	};
	await db.begin(async (sql) => {
		const wallet = await getWallet(id, sql); // SQL query (1)
		const current_amount = wallet.amount + txn.amount;
		const updatedWallet = {
			id: Math.floor(id),
			amount: current_amount,
		};
		const passbookRecord = {
			...txn,
			current_amount: current_amount,
		};
		await updateWallet(updatedWallet, sql); // SQL query (2)
		await insertIntoPassbook(passbookRecord, sql); // SQL query (3)
	});
};

// db.begin starts a database transaction
// getWallet : SELECT * from wallet where id=1;
// updateWallet: UPDATE wallet SET amount = current_amount where id=1;
// insertIntoPassbook: INSERT INTO passbook (id, amount, current_amount) VALUES (1, 100, 100);
// txn_id is auto incremented in passbook
```

### Application Code after triggers:

```javascript
const addMoney = async (transaction, db = sql) => {
	const txn = {
		amount: Math.floor(txn.amount),
		id: Math.floor(txn.id),
	};
    //  Wallet updates handled by postgres trigger automatically
	await insertIntoPassbook(txn, db); // SQL query (1)
};
```

As we can see that our lines of code has reduced drastically on the application side.
We are now doing only one SQL query from the application code.

We have to keep in mind that we have just moved the logic inside the database.
Number of operations getting executed inside database is still the same.

```sql 
SELECT amount INTO NEW.current_amount FROM wallet WHERE id = NEW.id;
```
This query is equivalent to calling `getWallet(id, sql)` method

```sql
UPDATE wallet SET amount = amount + NEW.amount WHERE id = NEW.id;
```
This query is equivalent to calling `updateWallet(updatedWallet, sql)` method

---

These are few improvements we can have using triggers:
---

- Extra round trips between client and server are eliminated
    > When a client sends a query to a server, it requires a round trip for sending the query and receiving the response. If you have a series of queries that depend on each other, this can result in multiple round trips between the client and server. By using a trigger, we can encapsulate multiple queries or related operations within a single database function. This allows the entire process to be executed on the server-side, which reduces the number of round trips and the overall latency. In our example case we eliminated `wallet` select(1) query and update(2) query from the client side (backend service).
- Intermediate results that the client does not need do not have to be marshaled or transferred between server and client
    > When a series of queries are executed, there might be intermediate results that the client does not need. If these intermediate results are large, transferring them between the server and client can consume network bandwidth and processing resources on both sides. With triggers, we can keep the processing on the server-side, so only the final result is sent to the client. This can save bandwidth, processing power, and improve overall performance. In our example, we did not need `wallet` table data, so we saved the network bandwidth of transferring payload from database to application server.
- Multiple rounds of query parsing can be avoided
    > Each time a query is sent to the server, the server has to parse the query, plan the execution, and then execute it. Parsing and planning can be computationally expensive operations, especially for complex queries. When using triggers, the related queries are encapsulated within a single database function. This means that the server can parse and plan the queries just once when the trigger is created, rather than repeatedly parsing and planning each time the queries are executed. This can result in significant performance improvements for frequently executed queries or complex operations. Although this overhead can be prevented without triggers as well if you're using Prepared Statements.

Triggers should be used with caution since they can obscure critical logic and create an illusion of automatic processes. While this can be advantageous in certain scenarios, it can also pose a challenge in terms of debugging, testing, and monitoring since they are not readily visible to developers.

As a result, it is important to weigh the benefits and drawbacks of using triggers before implementing them in a database system.