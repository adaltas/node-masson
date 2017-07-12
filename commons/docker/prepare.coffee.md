# Docker Prepare

Download different Docker packages

    module.exports =
      if: -> @contexts('masson/commons/docker')[0]?.config.host is @config.host
      header: 'Docker'
      handler: (options) ->
        @file.cache
          ssh: null
          source: "#{options.source}"
          target: "#{@config.nikita.cache_dir}/docker-compose"
          location: true
