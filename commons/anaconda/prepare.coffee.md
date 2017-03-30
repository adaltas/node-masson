# Anaconda Prepare

Download the Anaconda package Container

    module.exports =
      header: 'Anaconda Prepare'
      timeout: -1
      if: -> @contexts('masson/commons/anaconda')[0]?.config.host is @config.host
      handler: ->
        {anaconda} = @config
        @each anaconda.python_version, (options) ->
          version = options.key
          @file.cache
            source: anaconda.source["python#{version}"]
            location: true
