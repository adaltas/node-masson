
# Maven Prepare

    module.exports =
      header: 'Maven Prepare'
      timeout: -1
      if: -> @contexts('masson/commons/maven')[0]?.config.host is @config.host
      handler: ->
        {maven} = @config
        @file.cache
          ssh: null
          source: "#{maven.source}"
          location: true
