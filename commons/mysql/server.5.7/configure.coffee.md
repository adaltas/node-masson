
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
      @config.mysql ?= {}
      options = @config.mysql.server ?= {}

## Validation

      throw Error "Required Option: options.password" unless options.password

## Environnment

      options.repo ?= false
      options.current_password ?= ''
      options.root_host ?= '%'
      # Service Configuration
      options.my_cnf ?= {}

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'mysql'
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'mysql'
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.gid ?= options.group.name

## Configuration

      options.my_cnf['mysqld'] ?= {}
      options.my_cnf['mysqld']['port'] ?= '3306'
      options.my_cnf['mysqld']['pid-file'] ?= '/var/run/mysqld/mysqld.pid'
