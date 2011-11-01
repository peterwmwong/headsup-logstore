headsup-logstore: Log parsing, storage and publishing
=====================================================


Getting Started
---------------

### [Install node.js and NPM](https://github.com/joyent/node/wiki/Installation)

### Linux only: [Install redis](http://redis.io/download)

- **Make sure to add redis/src to PATH, so redis-server is a command.**

### Get the code

    > git://github.com/peterwmwong/headsup-logstore.git
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
