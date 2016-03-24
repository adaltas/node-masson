
# CURL

CURL is a tool to transfer data from or to a server, using one of the supported 
protocols (DICT, FILE, FTP, FTPS, GOPHER, HTTP, HTTPS, IMAP, IMAPS, LDAP, 
LDAPS, POP3, POP3S, RTMP, RTSP, SCP, SFTP, SMTP, SMTPS, TELNET and TFTP). The 
command is designed to work without user interaction. 

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/users'
    exports.push 'masson/core/yum'
    exports.push 'masson/core/proxy'

## Configuration

*   `curl.merge`   
    Wether or not to merge the configuration with the one already present on
    the remote '~/.curlrc' files. Declared configuration 
    preveils over the already existing one on the server.   
*   `curl.proxy`   
    Inject proxy configuration as declared in the proxy 
    action, default is true.   
*   `curl.users`   
    Create a config file for all users defined inside the 
    "masson/core/users" module, default is true.   
*   `curl.config`   
    The configuration object to be serialize in the remote git configuration
    files, see the `curl.noproxy` and `curl.proxy` for default values.   
*   `curl.config.noproxy` (array, string)   
    Comma-separated list of hosts which do not use a proxy, if one is 
    specified. The only wildcard is a single * character, which matches all 
    hosts, and effectively disables the proxy.
*   `curl.config.proxy`   
    URL of the proxy to be used if any, use the proxy module when not provided, 
    default to "proxy.http_proxy"
*   `curl.check` (string)   
    URL to validate the connection, default to "http://www.apache.org"   
*   `curl.check_match` (regexp)   
    Regular Expression to validate the content return by the `curl.check` URL, 
    default to /Welcome to The Apache Software Foundation/   

```json
{
  "proxy": {
    "host": "130.98.36.106",
    "port": 48254
  },
  users: [
    {username: 'nfs', system: true}
    {username: 'me', password: 'me123', home: true, shell: true}
  ]
  "curl": {
    "config": "noproxy": ["localhost", "127.0.0.1", ".hadoop"]
  }
}
```

    exports.configure = (ctx) ->
      require('./users').configure ctx
      require('./proxy').configure ctx
      ctx.config.curl ?= {}
      {curl} = ctx.config
      curl.merge ?= true
      curl.users ?= true
      curl.proxy ?= true
      curl.config ?= {}
      curl.check ?= 'http://www.apache.org'
      curl.check_match ?= /Welcome to The Apache Software Foundation/
      # Satitize config
      curl.config.noproxy = curl.config.noproxy.join ',' if Array.isArray curl.config.noproxy
      curl.config.proxy = ctx.config.proxy.http_proxy if curl.proxy

## User Configuration

Deploy the "~/.curlrc" file to each users. Set the property `curl.users` to 
false to disable this action to run. For the configuration file to be uploaded, 
the user must have a `user.home` property.

    exports.push
      header: 'Curl # User Configuration'
      if: -> @config.curl.users
      handler: ->
        {merge, config} = @config.curl
        for user in ctx.config.users then do (user) =>
          @write_ini
            content: config
            destination: "#{user.home}/.curlrc"
            uid: user.username
            gid: null
            merge: merge
            if: user.home

## Install

Install the "curl" package. Note, on some plateform like CentOS, `curl` is 
already installed.

    exports.push header: 'Curl # Install', timeout: -1, handler: ->
      # On centOS, curl is already here
      @service name: 'curl'

## Check

Check a remote call. This action is commonly activated to validate the Internet
connection.

    exports.push
      header: 'Curl # Connection Check'
      if: -> @config.curl.check
      handler: ->
        {check, check_match, config} = @config.curl
        @execute
          cmd: "curl -s #{check}"
          stdout: null
        , (err, executed, stdout, stderr) ->
          throw err if err
          throw new Error "#{if config.proxy then 'Proxy' else 'Connection'} not active" unless check_match.test stdout
