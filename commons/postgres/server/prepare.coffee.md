# PostgreSQL Prepare

Download the PostgreSQL Container

    module.exports =
      header: 'PostgreSQL'
      timeout: -1
      if: -> @contexts('masson/commons/postgres/server')[0]?.config.host is @config.host
      handler: ->
        {postgres} = @config
        @docker.pull
          tag: 'postgres'
          version: postgres.version
        @docker.save
          image: "postgres:#{postgres.version}"
          output: "#{@config.mecano.cache_dir}/postgres.tar"
