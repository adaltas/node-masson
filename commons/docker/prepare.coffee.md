# Docker Prepare

Download different Docker packages

    module.exports =
      if: -> @contexts('masson/commons/docker')[0]?.config.host is @config.host
      header: 'Docker'
      handler: ->
        @file.cache
          ssh: null
          source: "#{@config.docker.source}"
          target: "#{@config.nikita.cache_dir}/docker-compose"
          location: true
