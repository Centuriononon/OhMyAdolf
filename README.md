# OhMyAdolf 🦃
The project is inspired by the [Wiki-Game](https://en.wikipedia.org/wiki/Wikipedia:Wiki_Game). Users input a Wikipedia URL and, after a brief wait, receive a path from the current URL to a specified destination (we're looking for adolphs here*). 

![Video demo](./demo.gif)
- Please be aware, that it's all in good humor.
----

### Formatting.
Urls are not case-sensitive but are sensitive to spaces. Please use underscores `_` between words in the urls.

### Search.
Please note that the host must be __en.wikipedia.org__ for urls you enter (e.g. `https://en.wikipedia.org/wiki/pokemon`).

The algorithm operates on the breadth-first traversal and depth-first caching. This means that initially the application needs to process enough pages to start finding long-distance paths quickly. If the search takes a long time, it indicates processing a large number of urls (consider network speed and the overall limit of 200 requests per second for the Wikipedia API).

### Stack.
The application is built on __Elixir__, __Phoenix LiveView__, and __Neo4j__ for caching.

---

### Local run.
1. Requirements:
    - Docker, docker-compose, make
2. Preparing:
    - Create file `.env` in the root of the project. 
    - Copy and paste everything from the `.example.env` into `.env`.
3. Run:
```
make up
```

- Stop the application when you leave:
```
make down
``` 

---

### Tests.
- I didn't cover everything with tests, but only what was crucial. You can run tests inside a docker container using the following command:
```
make up/test
```