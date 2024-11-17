---
layout: post
title: Getting Started with Express
date: 2020-08-12 19:27 +0530
categories: development
author: themythicalengineer
tags: backend coding nodejs express
comments: false
blogUid: "79a1dd47-32ef-4d61-8aba-e16b30e11ccf"
---
![express_started](/assets/images/getting-started-with-express/express_started.jpg)

In the [previous blog post][1] I explained basic routing with inbuilt **http** module in Node.js.

In this blog, I will cover the basics of express module. [Express JS][2] is a 3rd party web framework for Node.js which provides small, fast and robust tooling for HTTP servers.

Let’s get right into the code.

## Install express
Since this module is not available by default in Node.js. We have to install it from [npm registry][3]. This is where developers publish their node modules for the world to use.

Open up your terminal in the `demo-project` directory and type
```bash
$ npm install express --save
```

This creates a `node_modules` folder in your root directory and also creates a `package-lock.json` file. This file is a representation of **dependency tree** that is modified by npm commands. This command installs the **express** module and the dependencies that are needed by **express** module inside the `node_modules` directory.

## Install nodemon
This module watches your project directory files and restarts your server if any file is modified. It will help you to test your changes without manually stopping and restarting your server. 

```bash
$ npm install nodemon --save-dev
```

As this module is required only for development and testing purposes, we'll install it as a **dev** dependency. If you have deployed your code on server using environment variable `NODE_ENV=production`, these dependencies will not get installed. 

Instead of using node to execute `index.js` file, we'll use nodemon. If you type the command below in your terminal you'll be able to see that it executes the `index.js` file and it also waits for any modifications in the directory.

```bash
$ ./node_modules/.bin/nodemon index.js
[nodemon] 2.0.4
[nodemon] to restart at any time, enter `rs`
[nodemon] watching path(s): *.*
[nodemon] watching extensions: js,mjs,json
[nodemon] starting `node index.js`
[nodemon] clean exit - waiting for changes before restart
```

You can also add scripts to your package.json file to execute commands from locally installed modules.

Let's create a start script in `package.json` so that we don't have to type the complete command again. Your `package.json` should look like this after all the steps we've done so far.

```js
{
  "name": "demo-project",
  "version": "1.0.0",
  "description": "Getting started with Backend using Node.js",
  "main": "index.js",
  "scripts": {
    "start": "./node_modules/.bin/nodemon index.js"
  },
  "author": "",
  "license": "ISC",
  "dependencies": {
    "express": "^4.17.1"
  },
  "devDependencies": {
    "nodemon": "^2.0.4"
  }
}
```

Now you can use scripts inside your `package.json` using npm. Type this in your terminal and your command will executed.

```
$ npm start
```

## Creating a HTTP server
```js
const express = require('express');

const app = express();

// all accepts any HTTP method
app.all('*', function (req, res) {
    // express handles basic headers and mime-types automatically
    res.send("<h1>Demo page</h1>");
})

app.listen(3000, function () {
    console.log("Listening on port 3000. Go to http://localhost:3000");
});
```

If we use http module, we need to set status codes, headers, write the data and end the response, while in express we just need one send() statement.

If you visit your browser you will see that express added extra header `X-Powered-By` and if you refresh it multiple times status code will be `304 Not Modified` which means express is also handling caching mechanism.
![express_demo](/assets/images/getting-started-with-express/express_demo.png)

Let's add more methods and routes
```js
const express = require('express');

const app = express();

// Application-level middleware to log request method and path
app.use(function(req, res, next) { 
	console.log(req.method, req.path); 
	next();
});

app.get('/', function (req, res) {    
    res.send("<h1>Demo page Get</h1>");
});
app.post('/', function (req, res) {    
    res.send("<h1>Demo page Post</h1>");
});
app.put('/', function (req, res) {    
    res.send("<h1>Demo page Put</h1>");
});
app.delete('/', function (req, res) {    
    res.send("<h1>Demo page Delete</h1>");
});

app.listen(3000, function () {
    console.log("Listening on port 3000. Go to http://localhost:3000");
});
```

Browser's default request method is GET, so we can use `curl` command to test other methods.
```bash
$ curl -X METHOD http://localhost:3000
```
here METHOD can be replaced by GET, PUT, POST, DELETE and various other HTTP methods. You can see the request method and path getting logged when you hit localhost via curl.

**app.use()** function is used to define middlewares in express. 

>Middlewares are functions that have access to the request object (req), the response object (res), and the next middleware function in the application’s request-response cycle. Middlewares are used to implement authentication, error handling, logging etc.

## Serving static files
Let's create a directory named `static` in root directory and an index.html file inside that folder. Also download an image so that you can test if you can serve images in response.
```bash
<html>
<head></head>
<body>
    <h1>Demo page Get</h1>
    <img src="./demo.jpeg">
</body>
</html>
```

Your directory structure should look like this.
```
demo-project
│----index.js
│----package.json
│----package-lock.json
│----node_modules/
│----static
    │----index.html
    │----demo.jpeg
```

Now modify `index.js` to add middleware to serve static files from directory named static. In app.get() callback function send the html file as response.

```bash
const express = require('express');
const path = require('path')

const app = express();

app.use(function (req, res, next) {
    console.log(req.method, req.path);
    next();
});

app.use(express.static(path.join(__dirname, 'static')))

app.get('/demo', function (req, res) {    
    res.sendFile(path.join(__dirname, 'static/index.html'))
});

app.listen(3000, function () {
    console.log("Listening on port 3000. Go to http://localhost:3000");
});
```

Refresh the page in browser and you will be able to see 3 requests logged in the console.

```bash
GET /
GET /demo.jpeg
GET /favicon.ico
```

![express_static](/assets/images/getting-started-with-express/express_static.png)

Please feel free to ask any question in the comment section below.

[1]:	https://themythicalengineer.com/getting-started-with-nodejs-backend-development.html
[2]:	https://expressjs.com/
[3]:	https://www.npmjs.com/package/express