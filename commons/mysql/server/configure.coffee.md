
# Mysql Server Configure

*   `sql_on_install` (array|string)
*   `current_password` (string)
*   `password` (string)
*   `remove_anonymous` (boolean)
*   `disallow_remote_root_login` (boolean)
*   `remove_test_db` (boolean)
*   `reload_privileges` (boolean)
*   `my_cnf` (object)
    Object to be serialized into the "ini" format inside "/etc/my.cnf"

Default configuration:

```
{ "mysql": {
  "server": {
    "sql_on_install": [],
    "current_password": "",
    "password": "",
    "remove_anonymous": true,
    "disallow_remote_root_login": false,
    "remove_test_db": true,
    "reload_privileges": true,
    "my_cnf": {
      "mysqld": {
        "tmpdir": "/tmp/mysql"
      }
    }
  }
}
```

    module.exports = ->
      mysql = @config.mysql ?= {}
      mysql.server ?= {}
      # User SQL
      mysql.server.sql_on_install ?= []
      mysql.server.sql_on_install = [mysql.server.sql_on_install] if typeof mysql.server.sql_on_install is 'string'
      # Secure Installation
      mysql.server.current_password ?= ''
      mysql.server.password ?= ''
      mysql.server.remove_anonymous ?= true
      mysql.server.disallow_remote_root_login ?= false
      mysql.server.remove_test_db ?= true
      mysql.server.reload_privileges ?= true
      # Service Configuration
      mysql.server.my_cnf ?= {}
      mysql.server.my_cnf['mysqld'] ?= {}
      mysql.server.my_cnf['mysqld']['tmpdir'] ?= '/tmp/mysql'
      mysql.server.user ?= name: 'mysql'
      mysql.server.user = name: mysql.server.user if typeof mysql.server.user is 'string'
      mysql.server.group ?= name: 'mysql'
      mysql.server.group = name: mysql.server.group if typeof mysql.server.group is 'string'
