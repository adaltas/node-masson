
# Mysql Server Configure

*   `current_password` (string)
*   `password` (string)
*   `my_cnf` (object)
    Object to be serialized into the "ini" format inside "/etc/my.cnf"
*   `root_host` (string|boolean)   
    Open root access to all host by default, set to "false" to disable it.

Note, root access is activated by default in order to let other service to 
provision their databases and user access.

## Default configuration

```
{ "mysql": { "server": {
  "current_password": "",
  "password": "{secret}",
  "my_cnf": {
    "mysqld": {
      "port": 3306
    }
  },
  "root_host": "%"
} } }
```

    module.exports = ->
      @config.mysql ?= {}
      options = @config.mysql.server ?= {}
      # Secure Installation
      options.current_password ?= ''
      throw Error "Required Option: options.password" unless options.password
      options.root_host ?= '%'
      # Service Configuration
      options.group ?= name: 'mysql'
      options.group = name: options.group if typeof options.group is 'string'
      options.my_cnf ?= {}
      options.user ?= name: 'mysql'
      options.user = name: options.user if typeof options.user is 'string'
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.gid = options.group.name

## Configuration

      options.my_cnf['mysqld'] ?= {}
      options.my_cnf['mysqld']['port'] ?= '3306'
      options.my_cnf['mysqld']['pid-file'] ?= '/var/run/mysqld/mysqld.pid'

## Repository

      options.repo ?= {}
      # options.repo.url ?= 'http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm'
      options.repo.source ?= null
      options.repo.url = null if options.repo.repo?
