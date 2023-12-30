
# Proxy

Declare proxy related environment variables as well as 
providing configuration properties which other modules may use.

## Configuration

Configuration is declared through the key "proxy" and may 
contains the following properties:

*   `system`
    Should the proxy environment variable be written inside the
    system-wide "/etc/profile.d" directory. Default to false
*   `system_file`
    The path where to place a shell script to export
    proxy environmental variables, default to 
    "phyla_proxy.sh". Unless absolute, the path will 
    be relative to "/etc/profile.d". If false, no
    file will be created.
*   `host`
    The proxy host, not required. The value will determine
    wether or not we use proxying
*   `port`
    The proxy port, not required
*   `username`
    The proxy username, not required
*   `password`
    The proxy password, not required
*   `secure`
    An object with the same `host`, `port`, `username` and
    `password` property but used for secure https proxy. it
    default to the default http settings.

If at least the `host` property is defined, the 
configuration will be enriched with the `http_proxy`, the
`https_proxy`, the `http_proxy_no_auth` and the 
`https_proxy_no_auth` urls properties.

    export default ->
      @config.proxy ?= {}
      @config.proxy.system ?= false
      @config.proxy.system_file ?= "phyla_proxy.sh"
      if @config.proxy.system_file
        @config.proxy.system_file = path.resolve '/etc/profile.d', @config.proxy.system_file
      @config.proxy.host ?= null
      @config.proxy.port ?= null
      @config.proxy.username ?= null
      @config.proxy.password ?= null
      @config.proxy.secure ?= null
      if not @config.proxy.host and (@config.proxy.port or @config.proxy.username or @config.proxy.password)
        throw Error "Invalid proxy configuration"
      toUrl = (scheme, auth) =>
        return null unless @config.proxy.host
        if scheme is 'https' and @config.proxy.secure?.host
          config = @config.proxy.secure
        else
          config = @config.proxy
        {host, port, username, password} = config
        url = "#{scheme}://"
        if auth
          url = "#{url}#{username}" if username
          url = "#{url}:#{password}" if password
          url = "#{url}@" if username
        url = "#{url}#{host}"
        url = "#{url}:#{port}" if port
        url
      @config.proxy.http_proxy = toUrl 'http', true
      @config.proxy.https_proxy = toUrl 'https', true
      @config.proxy.http_proxy_no_auth = toUrl 'http', false
      @config.proxy.https_proxy_no_auth = toUrl 'https', false

## Dependencies

    path = require 'path'
