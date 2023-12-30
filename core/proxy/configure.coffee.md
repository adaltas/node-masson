
# Proxy Configuration

Configuration is declared through the key "proxy" and may 
contains the following properties:

*   `system` (boolean|string)
    Should the proxy environment variable be written inside the
    system-wide "/etc/profile.d" directory. Default to false. A string value
    defines the path where to place a shell script to export proxy environmental
    variables, or it will default to "proxy.sh". Unless absolute, the path will 
    be relative to "/etc/profile.d".
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

    export default (service) ->
      options = service.options
      
      options.system ?= "proxy.sh"
      options.system = path.resolve '/etc/profile.d', options.system if options.system
      options.host ?= null
      options.port ?= null
      options.username ?= null
      options.password ?= null
      options.secure ?= null

## Validation

      if not options.host and (options.port or options.username or options.password)
        throw Error "Invalid proxy configuration"

## Utility function

      toUrl = (secure, auth) =>
        opts = if secure then options.secure else options
        scheme = if secure then 'https' else 'http'
        url = "#{scheme}://"
        if auth
          url = "#{url}#{opts.username}" if opts.username
          url = "#{url}:#{opts.password}" if opts.password
          url = "#{url}@" if opts.username
        url = "#{url}#{opts.host}"
        url = "#{url}:#{opts.port}" if opts.port
        url

## URLs

If at least the `host` property is defined, the 
configuration will be enriched with the `http_proxy`, the
`https_proxy`, the `http_proxy_no_auth` and the 
`https_proxy_no_auth` urls properties.

      options.http_proxy = toUrl false, true
      options.https_proxy = toUrl true, true if options.secure
      options.http_proxy_no_auth = toUrl false, false
      options.https_proxy_no_auth = toUrl true, false if options.secure

## Finish

      options

## Dependencies

    path = require 'path'
