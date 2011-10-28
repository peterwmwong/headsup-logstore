fs = require 'fs'
LogWatcher = require '../lib/LogWatcher'
{runUntil,notyet} = require './util/SpecHelpers'

L = console.log.bind console

describe "LogWatcher", ->

  describe ".watch(file,cb)", ->
    file = undefined
    fd = undefined
    received = []
    watcher = undefined

    beforeEach ->
      file = "/tmp/LogWatcher-spec-#{Date.now()}.txt"
      fd = fs.openSync file, 'w'
      received = []
      watcher = LogWatcher.watch file, (err, data)-> received = received.concat data

    afterEach ->
      try watcher?.unwatch()
      try fs.closeSync fd
      try fs.unlinkSync file
      file = fd = undefined

    it "calls cb with array of lines", ->
      runs ->
        setTimeout (->
          ws = fs.createWriteStream file, flags: 'a'
          ws.end "TEST DATA 1\nTEST DATA 2\n"
        ), 100
      waitsFor -> received.length >= 2
      runs -> expect(received).toEqual [
        "TEST DATA 1"
        "TEST DATA 2"
      ]

    it "assembles lines on newline, even when received chunks split lines.", ->
      runs =>
        ws = fs.createWriteStream file, flags: 'a'
        @after -> try ws?.writable and ws?.end()

        setTimeout (-> ws.write "TEST DATA 1\nTEST D"), 10
        setTimeout (-> ws.write "ATA 2\nTEST D"), 50
        setTimeout (-> ws.end "ATA 3\n" ), 100
      waitsFor -> received.length >= 3
      runs -> expect(received).toEqual [
        "TEST DATA 1"
        "TEST DATA 2"
        "TEST DATA 3"
      ]

    it "calls cb with array of lines, when file overwritten", ->
      runs ->
        setTimeout (->
          ws = fs.createWriteStream file, flags: 'a'
          ws.end "TEST DATA 1\nTEST DATA 2\n"
        ), 10
        setTimeout (->
          ws = fs.createWriteStream file, flags: 'w'
          ws.end "TEST DATA 6\nTEST DATA 7\n"
        ), 50
      waitsFor -> received.length >= 4
      runs -> expect(received).toEqual [
        "TEST DATA 1"
        "TEST DATA 2"
        "TEST DATA 6"
        "TEST DATA 7"
      ]

    it "stops watching when returned function (unwatch) is called", ->
      done = false

      runs ->
        setTimeout (->
          ws = fs.createWriteStream file, flags: 'a'
          ws.end "TEST DATA 1\nTEST DATA 2\n"
        ), 10
        setTimeout (->
          watcher.unwatch()
          watcher = undefined
        ), 50
        setTimeout (->
          ws = fs.createWriteStream file, flags: 'w'
          ws.end "TEST DATA 6\nTEST DATA 7\n"
          done = true
        ), 100
      waitsFor -> done
      runs -> expect(received).toEqual [
        "TEST DATA 1"
        "TEST DATA 2"
      ]
