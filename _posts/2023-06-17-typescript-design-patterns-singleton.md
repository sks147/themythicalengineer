---
layout: post
title: "Typescript Design Patterns: Singleton"
date: 2023-06-17 19:12 +0530
categories: development
author: themythicalengineer
tags: design patterns backend coding typescript nodejs fp-ts
comments: false
blogUid: fff04880-6ca5-4b68-8c5a-7e861f7cd09e
---

![singleton-design-pattern](/assets/images/design-patterns/singleton-design-pattern.webp)

## Notes on Singleton Design Pattern

### Intent
Ensure a class only has one instance, and provide a global point of access to it. 

### Applicability
- **Shared Resources**: If a service requires access to shared resources, such as a database connection pool, you can use the Singleton pattern to ensure that only one instance of the resource is created and shared across the service. This avoids unnecessary resource duplication and provides efficient utilization.
- **Configuration Management**: When you have a configuration object or settings that need to be accessed by multiple components within your microservice, you can use the Singleton pattern to create a single instance of the configuration object. This ensures consistent access to the configuration data throughout the microservice.
- **Stateful Services**: If you needs to maintain state across multiple requests or sessions, the Singleton pattern can be useful. It allows you to encapsulate the state within a single instance, ensuring that all requests or sessions operate on the same state. This can be beneficial for managing user sessions, caching data, or maintaining other types of stateful information.
- **Managing Dependencies**: If your service relies on a third-party service or API that has limitations on the number of concurrent connections, you can use the Singleton pattern to create a single instance that manages the communication with that external service. This can help enforce the constraints and prevent excessive resource consumption.

### Object Oriented Programming
```typescript
class Singleton {
  private static instance: Singleton;
  private data: number;

  private constructor() {
    this.data = Math.random();
  }

  public static getInstance(): Singleton {
    if (!Singleton.instance) {
      Singleton.instance = new Singleton();
    }
    return Singleton.instance;
  }

  public getData(): number {
    return this.data;
  }
}

const instance1 = Singleton.getInstance();
console.log(instance1.getData()); // 0.16152774745058918

const instance2 = Singleton.getInstance();
console.log(instance2.getData()); // 0.16152774745058918

console.log(instance1 === instance2); // true
```

### Functional programming
```typescript
type Singleton = {
  data: number;
};
type ReturnSingleton = () => Singleton

const createSingleton: ReturnSingleton = (() => {
  let instance: Singleton;
  return () => {
    if (!instance) {
      instance = { data: Math.random() };
    }
    return instance;
  };
})();

const instance1 = createSingleton();
console.log(instance1.data); // 0.057502791429981936

const instance2 = createSingleton();
console.log(instance2.data); // 0.057502791429981936

console.log(instance1 === instance2); // true
```

### Functional programming with fp-ts
```typescript
import { IO } from 'fp-ts/lib/IO';

type Singleton = {
  data: number
};

const createSingleton: IO<Singleton> = (() => {
  let instance: Singleton;
  return () => {
    if (!instance) {
      instance = { data: Math.random() };
    }
    return instance;
  };
})();

const instance1 = createSingleton();
console.log(instance1.data); // 0.3522236648406085

const instance2 = createSingleton();
console.log(instance2.data); // 0.3522236648406085

console.log(instance1 === instance2); // true
```

### References:
* [https://refactoring.guru/design-patterns/singleton](https://refactoring.guru/design-patterns/singleton)
* [http://misko.hevery.com/2008/08/25/root-cause-of-singletons/](http://misko.hevery.com/2008/08/25/root-cause-of-singletons/)
* [https://puredanger.github.io/tech.puredanger.com/2007/07/03/pattern-hate-singleton/](https://puredanger.github.io/tech.puredanger.com/2007/07/03/pattern-hate-singleton/)
* [https://sites.google.com/site/steveyegge2/singleton-considered-stupid](https://sites.google.com/site/steveyegge2/singleton-considered-stupid)
