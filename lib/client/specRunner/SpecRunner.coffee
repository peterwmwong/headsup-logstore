define ['require','./allSpecs'], (require,allSpecs)->
  require allSpecs, (specs...)->
    spec() for spec in specs
    trivialReporter = new jasmine.TrivialReporter()
    jasmineEnv = jasmine.getEnv()
    jasmineEnv.updateInterval = 5000
    jasmineEnv.addReporter trivialReporter
    jasmineEnv.specFilter = (spec)-> trivialReporter.specFilter spec
    jasmineEnv.execute()
