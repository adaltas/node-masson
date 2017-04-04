
# Mysql Server Configure

*   `current_password` (string)
*   `password` (string)
*   `my_cnf` (object)
    Object to be serialized into the "ini" format inside "/etc/my.cnf"

Default configuration:

```
{ "mysql": {
  "server": {
    "current_password": "",
    "password": "{secret}",
    "my_cnf": {
      "mysqld": {
        "port": 3306
      }
    }
  }
}
```

    module.exports = ->
      mysql = @config.mysql ?= {}
      mysql.server ?= {}
      # Secure Installation
      mysql.server.current_password ?= ''
      mysql.server.password ?= ''
      # Service Configuration
      mysql.server.my_cnf ?= {}
      mysql.server.user ?= name: 'mysql'
      mysql.server.user = name: mysql.server.user if typeof mysql.server.user is 'string'
      mysql.server.user.home ?= "/var/lib/#{mysql.server.user.name}"
      mysql.server.group ?= name: 'mysql'
      mysql.server.group = name: mysql.server.group if typeof mysql.server.group is 'string'

## Configuration

      mysql.server.my_cnf['mysqld'] ?= {}
      mysql.server.my_cnf['mysqld']['port'] ?= '3306'
