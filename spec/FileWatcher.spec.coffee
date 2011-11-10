fs = require 'fs'
path = require 'path'
FileWatcher = require '../lib/FileWatcher'
{isWindows,runUntil} = require './util/SpecHelpers'

L = console.log.bind console

describe "FileWatcher", ->

  describe ".watch('BOGUSFILE',cb)", ->
    it "calls cb with error", ->
      runUntil (done)->
        FileWatcher.watch "bOgUsFiLe.bogus", (err)->
          expect(err).toBe "bOgUsFiLe.bogus is NOT a file"
          done()

  describe ".watch(file,cb)", ->
    file = undefined
    received_err = []
    received = []
    receivedPoll_err = []
    receivedPoll = []
    watcher = undefined
    watcherPoll = undefined

    beforeEach ->
      file = path.resolve "#{process.env.TEMP or '/tmp'}/FileWatcher-spec-#{Date.now()}.txt"
      received_err = []
      received = []
      receivedPoll_err = []
      receivedPoll = []
      fs.writeFileSync file, ''
      watcher = FileWatcher.watch file, (err, data)->
        received = received.concat data
        if err?
          received_err = received_err.concat err
      watcherPoll = FileWatcher.watch file, {poll:true}, (err, data)->
        receivedPoll = receivedPoll.concat data
        if err?
          receivedPoll_err = receivedPoll_err.concat err

    afterEach ->
      try watcher?.unwatch()
      try watcherPoll?.unwatch()
      try fs.unlinkSync file
      file = undefined

    it "calls cb with array of lines", ->
      runs ->
        setTimeout (->
          ws = fs.createWriteStream file, flags: 'a'
          ws.end "TEST DATA 1\nTEST DATA 2\n"
        ), 10
      waitsFor -> (received.length >= 2) and (receivedPoll.length >= 2)
      runs ->
        expect(received_err).toEqual []
        expect(received).toEqual [
          "TEST DATA 1"
          "TEST DATA 2"
        ]
        expect(receivedPoll_err).toEqual []
        expect(receivedPoll).toEqual [
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
      waitsFor -> (received.length >= 3) and (receivedPoll.length >= 3)
      runs ->
        expect(received_err).toEqual []
        expect(received).toEqual [
          "TEST DATA 1"
          "TEST DATA 2"
          "TEST DATA 3"
        ]
        expect(receivedPoll_err).toEqual []
        expect(receivedPoll).toEqual [
          "TEST DATA 1"
          "TEST DATA 2"
          "TEST DATA 3"
        ]

    it "assembles lines on newline (Windows line endings), even when received chunks split lines.", ->
      runs =>
        ws = fs.createWriteStream file, flags: 'a'
        @after -> try ws?.writable and ws?.end()

        setTimeout (-> ws.write "TEST DATA 1\r\nTEST D"), 10
        setTimeout (-> ws.write "ATA 2\r\nTEST D"), 50
        setTimeout (-> ws.end "ATA 3\r\n" ), 100
      waitsFor -> (received.length >= 3) and (receivedPoll.length >= 3)
      runs ->
        expect(received_err).toEqual []
        expect(received).toEqual [
          "TEST DATA 1"
          "TEST DATA 2"
          "TEST DATA 3"
        ]
        expect(receivedPoll_err).toEqual []
        expect(receivedPoll).toEqual [
          "TEST DATA 1"
          "TEST DATA 2"
          "TEST DATA 3"
        ]

    it "calls cb with array of lines, when file overwritten [!!! FLAKY: see TODO and https://github.com/joyent/node/issues/1970]", ->
      runs ->
        setTimeout (->
          ws = fs.createWriteStream file, flags: 'a'
          ws.end "TEST DATA 1\nTEST DATA 2\n"
        ), 10

        setTimeout (->
          #TODO:
          # fs.createWriteStream for Windows...
          # fs.writeFileSync for Linux...
          # For some reason, using the wrong one (given your platform)
          # causes double watch events to occur.
          if isWindows()
            ws = fs.createWriteStream file, flags: 'w'
            ws.end "TEST DATA 6\nTEST DATA 7\n"
          else
            fs.writeFileSync file, "TEST DATA 6\nTEST DATA 7\n"
        ), 1000

      waitsFor -> (received.length >= 4) and (receivedPoll.length >= 4)
      runs ->
        expect(received_err).toEqual []
        expect(received).toEqual [
          "TEST DATA 1"
          "TEST DATA 2"
          "TEST DATA 6"
          "TEST DATA 7"
        ]
        expect(receivedPoll_err).toEqual []
        expect(receivedPoll).toEqual [
          "TEST DATA 1"
          "TEST DATA 2"
          "TEST DATA 6"
          "TEST DATA 7"
        ]

    it "stops watching when unwatch() is called right away", ->
      done = false

      runs ->
        watcher?.unwatch()
        watcherPoll?.unwatch()
        setTimeout (->
          ws = fs.createWriteStream file, flags: 'a'
          ws.end "TEST DATA 1\nTEST DATA 2\n"
        ), 10
        setTimeout (-> done = true), 50
      waitsFor -> done
      runs ->
        expect(received_err).toEqual []
        expect(received).toEqual []
        expect(receivedPoll_err).toEqual []
        expect(receivedPoll).toEqual []

    it "stops watching when unwatch() is called", ->
      done = false

      runs ->
        setTimeout (->
          ws = fs.createWriteStream file, flags: 'a'
          ws.end "TEST DATA 1\nTEST DATA 2\n"
        ), 10
        setTimeout (->
          watcher.unwatch()
          watcherPoll.unwatch()
          watcher = undefined
          watcherPoll = undefined
        ), 50
        setTimeout (->
          ws = fs.createWriteStream file, flags: 'w'
          ws.end "TEST DATA 6\nTEST DATA 7\n"
          done = true
        ), 100
      waitsFor -> done
      runs ->
        expect(received_err).toEqual []
        expect(received).toEqual [
          "TEST DATA 1"
          "TEST DATA 2"
        ]
        expect(receivedPoll_err).toEqual []
        expect(receivedPoll).toEqual [
          "TEST DATA 1"
          "TEST DATA 2"
        ]
