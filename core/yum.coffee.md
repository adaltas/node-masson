
# YUM

Configure YUM for internet and intranet mode. The Epel repository is optionnaly
deployed.

Note, ntp is installed to encure correct date on the server or HTTPS will fail.

    exports = module.exports = []
    exports.push 'masson/bootstrap'
    exports.push 'masson/core/profile' # In case yum make use of environmental variables
    exports.push 'masson/core/proxy'
    exports.push 'masson/core/network'
    # exports.push 'masson/core/ntp' # NTP require yum to install its services

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

    module.exports.configure = (ctx) ->
      require('./proxy').configure ctx
      ctx.config.yum ?= {}
      ctx.config.yum.clean ?= false
      ctx.config.yum.copy ?= null
      ctx.config.yum.merge ?= true
      ctx.config.yum.update ?= true
      ctx.config.yum.proxy ?= true
      ctx.config.yum.config ?= {}
      ctx.config.yum.config.main ?= {}
      ctx.config.yum.config.main.keepcache ?= '0'
      ctx.config.yum.packages ?= {}
      ctx.config.yum.packages['yum-plugin-priorities'] ?= true
      ctx.config.yum.packages['man'] ?= true
      ctx.config.yum.packages['ksh'] ?= true
      ctx.config.yum.epel ?= true
      ctx.config.yum.epel_url = 'http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm'
      {http_proxy_no_auth, username, password} = ctx.config.proxy
      if ctx.config.yum.proxy
        ctx.config.yum.config.main.proxy = http_proxy_no_auth
        ctx.config.yum.config.main.proxy_username = username
        ctx.config.yum.config.main.proxy_password = password

    exports.push name: 'YUM # Check', handler: (_, callback) ->
      pidfile_running @options.ssh, '/var/run/yum.pid', (err, running) ->
        return callback err if err
        return callback Error 'Yum is already running' if running
        callback null, false

## YUM # Configuration

Read the existing configuration in '/etc/yum.conf', 
merge server configuration and write the content back.

More information about configuring the proxy settings 
is available on [the centos website](http://www.centos.org/docs/5/html/yum/sn-yum-proxy-server.html)

    exports.push name: 'YUM # Configuration', handler: ->
      @ini
        content: @config.yum.config
        destination: '/etc/yum.conf'
        merge: true
        backup: true

## YUM # repositories

Upload the YUM repository definitions files present in 
"ctx.config.yum.copy" to the yum repository directory 
in "/etc/yum.repos.d"

    exports.push name: 'YUM # Repositories', timeout: -1, handler: (_, callback) ->
      {copy, clean} = @config.yum
      return callback() unless copy
      modified = false
      basenames = []
      do_search = =>
        glob copy, (err, files) =>
          local_files = for file in files
            continue if /^\./.test path.basename file
            file
          @fs.readdir '/etc/yum.repos.d/', (err, files) ->
            remote_files = for file in files
              continue if /^\./.test path.basename file
              "/etc/yum.repos.d/#{file}"
            do_clean local_files, remote_files
      do_clean = (local_files, remote_files) =>
        return do_upload local_files unless clean
        removes = remote_files
        .filter (file) -> # Only keep file not present locally
          not local_files.some (local_file) -> path.basename(file) is path.basename(local_file)
        .map (file) -> # Transform to object
          destination: file
        @remove removes, (err, removed) ->
          return callback err if err
          modified = true if removed
          do_upload local_files
      do_upload = (local_files) =>
        for file in local_files
          @download
            source: file
            destination: "/etc/yum.repos.d/#{path.basename file}"
        @execute
          cmd: 'yum clean metadata; yum -y update'
          if: modified
        @then (err) ->
          callback err, modified
      do_search()

## Epel

Install the Epel repository. This is by default activated and the repository is
deployed by installing the "epel-release" package. It may also be installed from
an url by defining the "yum.epel_url" property. To disable Epel, simply set the
property "yum.epel" to false.

    exports.push
      name: 'YUM # Epel'
      timeout: 100000
      if: -> @config.yum.epel
      handler: ->
        {epel, epel_url} = @config.yum
        @execute
          cmd: if epel_url
          then "rpm -Uvh #{epel_url}"
          else 'yum install epel-release' 
          unless_exec: 'yum list installed | grep epel-release'

    exports.push name: 'YUM # Update', timeout: -1, handler: (_, callback) ->
      {update} = @config.yum
      # We use case-insensitive search because case change between rh 6 and 7
      @execute
        cmd: "yum -y update | grep -i 'no packages marked for update'"
        if: update
      , (err, executed, stdout, stderr) ->
        regex = new RegExp 'no packages marked for update', 'i'
        callback err, executed and not regex.test stdout

    exports.push name: 'YUM # Packages', timeout: -1, handler: ->
      for name, active of @config.yum.packages
        @service
          name: name
          if: active
      

## Dependencies

    glob = require 'glob'
    path = require 'path'
    pidfile_running = require 'mecano/lib/misc/pidfile_running'
