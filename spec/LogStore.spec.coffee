LogStore = require '../lib/LogStore'
LogPublisher = require '../lib/LogPublisher'
{createServer} = require './util/redis-remote'
{notyet,mocklog,runUntil,toHash} = require './util/SpecHelpers'
redis = require 'redis'

L = console.log.bind console

describe "LogStore", ->
  ls = null
  db = null
  dbmgr = null
  curdbid = 0

  beforeEach ->
    if not dbmgr?
      runUntil (done)->
        createServer ((err,mock)->
          dbmgr = mock
          db = redis.createClient dbmgr.port
          ls = new LogStore host:'127.0.0.1', port: dbmgr.port
          done()
        ), 100
    else
      db.select ++curdbid
      ls = new LogStore host:'127.0.0.1', port: dbmgr.port, dbid: curdbid

  afterEach -> ls.end()

  describe ".end()", ->
    it "closes connection, get() sends error to callbacks", ->
      runUntil (done)->
        ls.end()
        ls.get {}, (e)->
          expect(e).toBe "Connection closed"
          done()

  describe ".on 'log', callback=({server,date,category,codeSource,clientInfo:{ip,id,siteid,userid}})->", ->
    it 'when log, calls callback', ->
      ls2 = new LogStore host: '127.0.0.1', port:dbmgr.port, dbid: curdbid
      ls3 = new LogStore host: '127.0.0.1', port:dbmgr.port, dbid: curdbid
      lp = new LogPublisher host: '127.0.0.1', port:dbmgr.port, dbid: curdbid
      @after ->
        ls2.end()
        ls3.end()
        lp.end()

      l = mocklog()
      logsReceived = 0
      for lsx in [ls,ls2,ls3]
        lsx.on 'log', (log)->
          expect(log).toEqual l
          ++logsReceived

      runs -> lp.log l
      waitsFor -> logsReceived >= 3

  ###
  describe ".get()", ->
    DEFAULT_COUNT = 25

    describe ".get()", ->
      it "returns last #{DEFAULT_COUNT} log entries", ->

      it "returns last X log entries, if X < #{DEFAULT_COUNT}", notyet

    describe ".get limit: {server:''}", ->
      it "returns nothing, when server is null, undefined, bogus", notyet
      it "returns last #{DEFAULT_COUNT} log entries, from specified server", notyet

    describe ".get limit: {clientip:''}", ->
      it "returns nothing, when clientip is null, undefined, bogus", notyet
      it "returns last #{DEFAULT_COUNT} log entries, from specified clientip", notyet

    describe ".get start: id", ->
      it 'returns nothing when id is null', notyet
      it 'returns nothing when id is undefined', notyet
      it 'returns nothing when id is negative', notyet
      it 'returns nothing when id is greater then last id', notyet
  ###

  it 'TEST TEARDOWN', ->
    db.end()
    dbmgr.stop()
    ls.end()
    runUntil (done)-> setTimeout done, 100
