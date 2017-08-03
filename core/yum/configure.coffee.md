
# YUM Configure

Configure YUM for internet and intranet mode. The Epel repository is optionnaly
deployed.

Note, ntp is installed to encure correct date on the server or HTTPS will fail.

## Configuration

*   `clean`   
*   `copy`   
    Deploy the YUM repository definitions files.   
*   `merge`   
*   `proxy`   
    Inject proxy configuration as declared in the proxy 
    action, default is true   
*   `update`   
    Update packages on the system   
*   `packages` (object[string:boolean])   
    List of packages to be installed by YUM. Set the name of the package as a
    key and mark it activate with the value. Default installed packages are
    "yum-plugin-priorities", "man" and "ksh".   

## Example - activate proxy and install the "git" package

```json
{
  "config": {
    "proxy": "http://my.proxy:8080"
  },
  "packages": {
    "git": true
  }
}
```

## Default Configurations

```json
{
  "merge": true,
  "config": {
    "main": {
      "keepcache": "0"
    }
  },
  "proxy": false,
  "source": null,
  "update": true,
  "clean": "CentOS*",
  "epel": {
    "enabled": false,
    "url": "http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm",
    "source": null
  },
  "packages": {
    "yum-plugin-priorities": true,
    "man": true,
    "ksh": true
  }
}
```

## Source Code

    module.exports = ->
      service = migration.call @, service, 'masson/core/yum', ['yum'], require('nikita/lib/misc').merge require('.').use,
        proxy: key: ['proxy']
      options = @config.yum = service.options

## Configuration

      options.fqdn = service.node.fqdn
      options.prepare = service.nodes[0].fqdn is options.fqdn
      options.merge ?= true
      options.config ?= {}
      options.config.main ?= {}
      options.config.main.keepcache ?= '0'

## Proxy Configuration

      options.proxy ?= false
      if service.use.proxy and options.proxy
        options.config.main.proxy ?= service.use.proxy.config.proxy.http_proxy_no_auth
        options.config.main.proxy_username ?= service.use.proxy.config.proxy.username
        options.config.main.proxy_password ?= service.use.proxy.config.proxy.password

## System Repository

      options.source ?= null
      options.update ?= true
      options.clean ?= 'CentOS*'

## Epel Repository

      options.epel ?= {}
      options.epel.enabled ?= false
      if options.epel?.enabled
        options.epel.url ?= 'http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm'
        options.epel.source ?= null
        options.epel.url = null if options.epel.source?

## Default Packages

      options.packages ?= {}
      options.packages['yum-plugin-priorities'] ?= true
      options.packages['man'] ?= true
      options.packages['ksh'] ?= true

## Dependencies

    migration = require '../../lib/migration'
