
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
      @config.yum ?= {}
      @config.yum.clean ?= false
      @config.yum.copy ?= null
      @config.yum.merge ?= true
      @config.yum.update ?= true
      @config.yum.proxy ?= true
      @config.yum.config ?= {}
      @config.yum.config.main ?= {}
      @config.yum.config.main.keepcache ?= '0'
      @config.yum.packages ?= {}
      @config.yum.packages['yum-plugin-priorities'] ?= true
      @config.yum.packages['man'] ?= true
      @config.yum.packages['ksh'] ?= true
      {http_proxy_no_auth, username, password} = @config.proxy?
      if @config.yum.proxy
        @config.yum.config.main.proxy = http_proxy_no_auth
        @config.yum.config.main.proxy_username = username
        @config.yum.config.main.proxy_password = password
