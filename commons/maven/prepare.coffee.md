
# Maven Prepare

    module.exports =
      header: 'Maven Prepare'
      if: -> @contexts('masson/commons/maven')[0]?.config.host is @config.host
      handler: ->
        {maven} = @config
        @file.cache
          ssh: null
          source: "#{maven.source}"
          location: true
