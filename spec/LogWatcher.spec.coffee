fs = require 'fs'
LogWatcher = require '../lib/LogWatcher'
{runUntil,notyet} = require './util/SpecHelpers'

L = console.log.bind console

describe "LogWatcher", ->
  file = undefined
  fd = undefined

  beforeEach ->
    file = "/tmp/LogWatcher-spec-#{Date.now()}.txt"
    fd = fs.openSync file, 'w'

  afterEach ->
    try fs.closeSync fd
    try fs.unlinkSync file
    file = fd = undefined

  # TODO: backfill...
