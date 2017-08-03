# Docker Prepare

Download different Docker packages

    module.exports =
      if: -> @contexts('masson/commons/docker')[0]?.config.host is @config.host
      header: 'Docker'
      ssh: null
      handler: (options) ->
        @file.cache
          source: "#{options.source}"
          target: "#{options.cache_dir}/docker-compose"
          location: true
