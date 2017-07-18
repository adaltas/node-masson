
# PostgreSQL Server Install

    module.exports = header: 'PostgreSQL Server Install', handler: ->
      {iptables, postgres} = @config
      tmp = postgres.image_dir ?= "/tmp_#{Date.now()}"
      md5 = postgres.md5 ?= true

## IPTables

| Service    | Port | Proto | Parameter |
|------------|------|-------|-----------|
| PostgreSQL | 5432 | tcp   | -         |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: postgres.server.port, protocol: 'tcp', state: 'NEW', comment: "PostgreSQL" }
        ]
        if: iptables.action is 'start'

## Startup Script

      @service.init
        header: 'Startup Script'
        source: "#{__dirname}/resources/postgres-server.j2"
        local: true
        target: "/etc/init.d/postgres-server"
        context: container: postgres.server.container_name

## Package

Install the PostgreSQL database server.

      @system.discover (err, status, os) ->
        @call header: 'Download Container', handler: ->
          exists = false
          @docker.checksum
            image: 'postgres'
            tag: postgres.version
            docker: if os.type in ['redhat','centos'] and os.release[0] is '6'
            then null
            else @config.docker #can not enable tls client verification centos/redhat6
          , (err, status, checksum) ->
            throw err if err
            exists = true if checksum
          @file.download
            unless: -> exists
            binary: true
            md5: true
            source: "#{@config.nikita.cache_dir}/postgres.tar"
            target: "#{tmp}/postgres.tar"
          @docker.load
            header: 'Load Container'
            unless: -> exists
            source: "#{tmp}/postgres.tar"
            docker: if os.type in ['redhat','centos'] and os.release[0] is '6'
            then null
            else @config.docker #can not enable tls client verification centos/redhat6

## Run Container

Run the PostgreSQL server container

        @docker.service
          machine: @config.nikita.machine
          header: 'Run PostgreSQL Container'
          label_true: 'RUNNED'
          force: -> @status(-1)
          image: "postgres:#{postgres.version}"
          env: [
            "POSTGRES_PASSWORD=#{postgres.server.password}"
            "POSTGRES_USER=#{postgres.server.user}"
          ]
          port: "#{postgres.server.port}:5432"
          service: true
          name: postgres.server.container_name
          docker: if os.type in ['redhat','centos'] and os.release[0] is '6'
          then null
          else @config.docker #can not enable tls client verification centos/redhat6
