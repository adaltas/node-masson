
# Mysql Server Configure

* `password` (string)   
* `my_cnf` (object)   
  Object to be serialized into the "ini" format inside "/etc/my.cnf".
* `repo` (boolean)   
  Download the "mysql57-community-release-el7" package to register the repository, disabled by default. 
* `root_host` (string|boolean)   
  Open root access to all host by default, set to "false" to disable it.

Note, root access is activated by default in order to let other service to 
provision their databases and user access.

## Default configuration

```
{ "mysql": { "server": {
  "password": "{required}",
  "root_host": "%"
  "my_cnf": {
    "mysqld": {
      "port": 3306
    }
  },
  "repo": false,
  "root_host": "%"
} } }
```

    module.exports = ->
      mysql = @config.mysql ?= {}
      mysql.server ?= {}

## Environnment

      mysql.server.repo ?= false
      mysql.server.current_password ?= ''
      throw Error "Required Option: mysql.server.password" unless mysql.server.password
      mysql.server.root_host ?= '%'
      # Service Configuration
      mysql.server.my_cnf ?= {}

## Identities

      mysql.server.user ?= name: 'mysql'
      mysql.server.user = name: mysql.server.user if typeof mysql.server.user is 'string'
      mysql.server.user.home ?= "/var/lib/#{mysql.server.user.name}"
      mysql.server.group ?= name: 'mysql'
      mysql.server.group = name: mysql.server.group if typeof mysql.server.group is 'string'

## Configuration

      mysql.server.my_cnf['mysqld'] ?= {}
      mysql.server.my_cnf['mysqld']['port'] ?= '3306'
      mysql.server.my_cnf['mysqld']['pid-file'] ?= '/var/run/mysqld/mysqld.pid'
