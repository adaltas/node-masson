# Docker Prepare

Download different Docker packages

    module.exports =
      header: 'Docker Prepare'
      if: (options) -> options.prepare
      ssh: false
      handler: (options) ->
        @file.cache
          source: "#{options.source}"
          target: "#{options.cache_dir}/docker-compose"
          location: true
