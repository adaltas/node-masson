# Docker Prepare

Download different Docker packages

    module.exports =
      header: 'Docker'
      if: (options) -> options.prepare
      ssh: null
      handler: (options) ->
        @file.cache
          source: "#{options.source}"
          target: "#{options.cache_dir}/docker-compose"
          location: true
