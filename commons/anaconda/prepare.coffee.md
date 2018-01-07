# Anaconda Prepare

Download the Anaconda package Container

    module.exports =
      header: 'Anaconda Prepare'
      if: -> @contexts('masson/commons/anaconda')[0]?.config.host is @config.host
      ssh: false
      handler: (options) ->
        @each options.python_version, (config) ->
          version = config.key
          @file.cache
            source: options.source["python#{version}"]
            location: true
