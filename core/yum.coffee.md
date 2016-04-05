
# YUM

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
      require('./proxy').call @
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
      @config.yum.epel ?= true
      @config.yum.epel_url = 'http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm'
      {http_proxy_no_auth, username, password} = @config.proxy
      if @config.yum.proxy
        @config.yum.config.main.proxy = http_proxy_no_auth
        @config.yum.config.main.proxy_username = username
        @config.yum.config.main.proxy_password = password
      'install': [
        'masson/core/profile' # In case yum make use of environmental variables
        'masson/core/proxy'
        'masson/core/network'
        install
      ]

    install = header: 'YUM Install', handler: ->

## Locked

Make sure Yum isnt already running.

      @call header: 'Locked', shy: true, handler: (_, callback) ->
        pidfile_running @options.ssh, '/var/run/yum.pid', (err, running) ->
          err = Error 'Yum is already running' if running
          callback err

## Configuration

Read the existing configuration in '/etc/yum.conf', 
merge server configuration and write the content back.

More information about configuring the proxy settings 
is available on [the centos website](http://www.centos.org/docs/5/html/yum/sn-yum-proxy-server.html)

      @write_ini
        header: 'Configuration'
        content: @config.yum.config
        destination: '/etc/yum.conf'
        merge: true
        backup: true

## repositories

Upload the YUM repository definitions files present in 
"@config.yum.copy" to the yum repository directory 
in "/etc/yum.repos.d"

      @call header: 'Repositories', timeout: -1, handler: (options) ->
        {copy, clean} = @config.yum
        return unless copy
        local_files = null
        remote_files = null
        @call (_, callback) ->
          options.log message: "Searching repositories inside \"/etc/yum.repos.d/\"", level: 'DEBUG', module: 'masson/core/yum'
          glob copy, (err, files) =>
            local_files = for file in files
              continue if /^\./.test path.basename file
              file
            @fs.readdir '/etc/yum.repos.d/', (err, files) =>
              return callback err if err
              options.log "Found #{files.length} repositories", level: 'DEBUG', module: 'masson/core/yum'
              remote_files = for file in files
                continue if /^\./.test path.basename file
                "/etc/yum.repos.d/#{file}"
              callback()
        @call ->
          return unless clean
          options.log "Remove #{remote_files.length} files", level: 'WARN', module: 'masson/core/yum'
          remote_files = remote_files
            .filter (file) -> # Only keep file not present locally
              not local_files.some (local_file) -> path.basename(file) is path.basename(local_file)
            .map (file) -> # Transform to object
              destination: file
          @remove remote_files
        @call (_, callback) ->
          options.log "Upload #{local_files.length} files", level: 'INFO', module: 'masson/core/yum'
          @write (
            source: file
            local_source: true
            destination: "/etc/yum.repos.d/#{path.basename file}"
          ) for file in local_files
          @execute
            cmd: 'yum clean metadata; yum -y update'
            if: @status -1
          @then callback

## YUM Install # Epel

Install the Epel repository. This is by default activated and the repository is
deployed by installing the "epel-release" package. It may also be installed from
an url by defining the "yum.epel_url" property. To disable Epel, simply set the
property "yum.epel" to false.

      @execute
        header: 'Epel'
        timeout: 100000
        if: -> @config.yum.epel
        cmd: if @config.yum.epel_url
        then "rpm -Uvh #{@config.yum.epel_url}"
        else 'yum install epel-release' 
        unless_exec: 'yum list installed | grep epel-release'

## Package Update

      @execute
        header: 'Update'
        timeout: -1
        cmd: "yum -y update"
        if: @config.yum.update
        if_exec: '[[ `yum check-update | egrep "(.i386|.x86_64|.noarch|.src)" | wc -l` > 0 ]]'

## User Packages

      @service (
        header: "Package #{name}"
        timeout: -1
        name: name
        if: active
      ) for name, active of @config.yum.packages

## Dependencies

    glob = require 'glob'
    path = require 'path'
    pidfile_running = require 'mecano/lib/misc/pidfile_running'
