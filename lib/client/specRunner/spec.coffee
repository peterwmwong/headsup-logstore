define
  load: (name, req, load, config)->
    
    # Load Spec
    req ["#{name}Spec"], (Spec)-> load ->
      ctxPostfix = 0

      describe name, ->
        specRequire = null
        ctx = null

        beforeEach ->
          # Create a new require context for each spec describe/it
          specRequire = require.config
            context: ctxName = "specs#{ctxPostfix++}"
            baseUrl: '/src/'
          ctx = window.require.s.contexts[ctxName]

        afterEach ->
          # Remove all modules loaded from context
          $("[data-requirecontext='#{ctx.contextName}']").remove()

        # Run Spec
        Spec do->
          
          mockModules: (map)->
            for k,v of map
              ctx.defined[k] = v
              ctx.specified[k] = ctx.loaded[k] = true

          loadModule: (cb)->
            module = undefined
            runs -> specRequire [name], (mod)-> module = mod
            waitsFor (-> module isnt undefined), "'#{name}' Module to load", 1000
            runs -> cb module
            