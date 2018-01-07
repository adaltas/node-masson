
# Maven Prepare

    module.exports =
      header: 'Maven Prepare'
      if: -> @contexts('masson/commons/maven')[0]?.config.host is @config.host
      ssh: false
      handler: (options) ->
        @file.cache
          source: "#{options.source}"
          location: true
