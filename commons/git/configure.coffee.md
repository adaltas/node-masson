
# Git Configure

*   `properties`
    Git configuration shared by all users and the global 
    configuration file.
*   `global`
    The configation properties used to generate 
    the global configuration file in "/etc/gitconfig" or `null`
    if no global configuration file should be created, default
    to `null`.
*   `merge`
    Whether or not to merge the 'git.config' content 
    with the one present on the server. Declared 
    configuration preveils over the already existing 
    one on the server.
*   `proxy`
    Inject proxy configuration as declared in the 
    proxy action, default is true

Configuration example:

This exemple will create a global configuration file 
in "/etc/gitconfig" and a user configuration file for 
user "a_user". It defines its own proxy configuration, disregarding
any settings from the proxy action.

```json
{
  "git": {
    "merge": true,
    "global": {
      "user": { "name": 'default user', email: "default_user@domain.com" }
    },
    "users": {
      "a_user": {
        "user": { "name": 'a user', email: "a_user@domain.com" }
        "http": {
          "proxy": "http://some.proxy:9823"
        }
      }
    }
  }
}
```

    module.exports = handler: ->
      {proxy} = @config
      @config.git ?= {}
      @config.git.merge ?= true
      @config.git.properties ?= {}
      @config.git.proxy ?= true
      @config.git.global ?= false
      @config.git.global = {} if @config.git.global is true
      @config.git.properties.http ?= {}
      @config.git.properties.http.proxy ?= proxy?.http_proxy if @config.git.proxy
