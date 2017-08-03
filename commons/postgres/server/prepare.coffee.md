
# PostgreSQL Server Prepare

Download the PostgreSQL Container

    module.exports =
      header: 'PostgreSQL'
      if: -> @contexts('masson/commons/postgres/server')[0]?.config.host is @config.host
      ssh: null
      handler: (options) ->
        @docker.pull
          tag: 'postgres'
          version: options.version
        @docker.save
          image: "postgres:#{options.version}"
          output: "#{options.cache_dir}/postgres.tar"
