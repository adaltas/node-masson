
# MySQL client installation

    export default header: 'MySQL Client Install', handler: (options) ->

## Yum Repositories

Upload the YUM repository definitions files present in 
"options.copy" to the yum repository directory 
in "/etc/yum.repos.d"

      @call header: 'Repo', ->
        @tools.repo
          if: options.repo?
          header: 'Repo'
          source: options.repo.source
          update: options.repo.update
          target: '/etc/yum.repos.d/mysql.repo'
          clean: 'mysql*'
        @service.install
          name: 'mysql-community-release'
          unless: options.repo?
          if_exec: 'yum info mysql-community-release'

## Package

Install the Mysql client.

      @service.install 'mysql'

## Connector

Install the Mysql JDBC driver.

      @service
        header: 'Connector'
        name: 'mysql-connector-java'
