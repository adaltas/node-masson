
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

Examples

```json
{
  "yum": {
    "config": {
      "proxy": null
    },
    "copy": "#{__dirname}/offline/*.repo"
  }
}
```

    module.exports = ->
      options = @config.yum ?= {}
      options.clean ?= false
      options.copy ?= null
      options.merge ?= true
      options.update ?= true
      options.proxy ?= true
      options.config ?= {}
      options.config.main ?= {}
      options.config.main.keepcache ?= '0'
      options.packages ?= {}
      options.packages['yum-plugin-priorities'] ?= true
      options.packages['man'] ?= true
      options.packages['ksh'] ?= true
      {http_proxy_no_auth, username, password} = @config.proxy?
      if options.proxy
        options.config.main.proxy = http_proxy_no_auth
        options.config.main.proxy_username = username
        options.config.main.proxy_password = password
      options.epel ?= {}
      options.epel.enabled ?= false
      if options.epel.enabled
        options.epel.source ?= null
        options.epel.url ?= 'http://download.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-9.noarch.rpm' unless options.epel.source?
        options.epel.url = null if options.source? and options.url?
