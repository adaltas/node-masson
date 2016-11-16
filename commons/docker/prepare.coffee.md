# Docker Prepare

Download different Docker packages

    module.exports =
      timeout: -1
      if: -> @contexts('masson/commons/docker')[0]?.config.host is @config.host
      handler: ->
        @cache
          ssh: null
          source: "#{@config.docker.source}"
          target: "#{@config.mecano.cache_dir}/docker-compose"
          location: true
