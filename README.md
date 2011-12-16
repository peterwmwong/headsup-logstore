headsup-logstore: Log parsing, storage and publishing
=====================================================

<img width="916px" src="https://github.com/peterwmwong/headsup-logstore/raw/master/doc/screenshot01.png" border="0"/>


Getting Started with Single-Server-Standalone Setup (No Redis Server)
---------------------------------------------------------------------

### [Install node.js (>= v0.6.0) and NPM](https://github.com/joyent/node/wiki/Installation)

### Get the code

    > git clone git://github.com/peterwmwong/headsup-logstore.git
    > cd headsup-logstore

### Get dependencies

    > make deps

### Run

    > node_modules/.bin/coffee lib/server/LogWatcherService.coffee {Path to serverlog.txt}

### To the browser!

    http://{HOST}:8888/index.html?source={HOST}:8888

Yes, I know it looks silly. Well so do you. :)
    


Getting Started (Developing)
----------------------------

### [Install node.js (>= v0.6.0) and NPM](https://github.com/joyent/node/wiki/Installation)

### Linux only: [Install redis](http://redis.io/download)

- **Make sure to add redis/src to PATH, so redis-server is a command.**

### Get the code

    > git clone git://github.com/peterwmwong/headsup-logstore.git
    > cd headsup-logstore

### Run specs

#### Linux

    > make spec

#### Windows

Currently, redis does not support Windows.
An external test redis server must be used by the specs.

    > set TEST_REDIS_HOST=<Host of redis server>
    > set TEST_REDIS_PORT=<Port of redis server>
    > node_modules\.bin\jasmine-node.cmd --coffee spec\

### Debugging specs

[Node cli debugger](http://nodejs.org/docs/v0.5.10/api/debugger.html)

    > node debug node_modules\jasmine-node\lib\jasmine-node\cli.js --coffee spec\LogStore.spec.coffee

[node-inspector](https://github.com/dannycoates/node-inspector)

    > npm install node-inspector
    > node-inspector &
    > node --debug node_modules\jasmine-node\lib\jasmine-node\cli.js --coffee spec\LogStore.spec.coffee


Credit
------

* [CoffeeScript](http://jashkenas.github.com/coffee-script/) - Better than JavaScript
* [Node](http://nodejs.org/) - Awesome <EOM>
* [Node Redis](https://github.com/mranney/node_redis) - Redis client for Node.js
* [npm](http://npmjs.org/) - Node Package Manager
* [Jasmine](http://pivotal.github.com/jasmine/) - BDD for JavaScript
* [Jasmine-Node](http://jquery.com/) - Jasmine Node.js integration
* [Redis](http://redis.io/) - Key-Value Store
