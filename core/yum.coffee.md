
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

    exports.push module.exports.configure = (ctx) ->
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

    exports.push name: 'YUM # Check', handler: (ctx, next) ->
      pidfile_running ctx.ssh, '/var/run/yum.pid', (err, running) ->
        return next err if err
        return next new Error 'Yum is already running' if running
        next null, false

## YUM # Configuration

Read the existing configuration in '/etc/yum.conf', 
merge server configuration and write the content back.

More information about configuring the proxy settings 
is available on [the centos website](http://www.centos.org/docs/5/html/yum/sn-yum-proxy-server.html)

    exports.push name: 'YUM # Configuration', handler: (ctx, next) ->
      ctx.ini
        content: ctx.config.yum.config
        destination: '/etc/yum.conf'
        merge: true
        backup: true
      .then next

## YUM # repositories

Upload the YUM repository definitions files present in 
"ctx.config.yum.copy" to the yum repository directory 
in "/etc/yum.repos.d"

    exports.push name: 'YUM # Repositories', timeout: -1, handler: (ctx, next) ->
      {copy, clean} = ctx.config.yum
      return next() unless copy
      modified = false
      basenames = []
      do_search = ->
        glob copy, (err, files) ->
          local_files = for file in files
            continue if /^\./.test path.basename file
            file
          ctx.fs.readdir '/etc/yum.repos.d/', (err, files) ->
            remote_files = for file in files
              continue if /^\./.test path.basename file
              "/etc/yum.repos.d/#{file}"
            do_clean local_files, remote_files
      do_clean = (local_files, remote_files) ->
        return do_upload local_files unless clean
        removes = remote_files
        .filter (file) -> # Only keep file not present locally
          not local_files.some (local_file) -> path.basename(file) is path.basename(local_file)
        .map (file) -> # Transform to object
          destination: file
        # local_filenames = local_files.map (file) -> path.basename file
        # removes = for file in remote_files
        #   continue if path.basename(file) in local_filenames
        #   destination: file
        ctx.remove removes, (err, removed) ->
          return next err if err
          modified = true if removed
          do_upload local_files
      do_upload = (local_files) ->
        uploads = for file in local_files
          source: file
          destination: "/etc/yum.repos.d/#{path.basename file}"
        ctx
        .upload uploads
        .execute
          cmd: 'yum clean metadata; yum -y update'
          if: modified
        .then next
      do_search()

## Epel

Install the Epel repository. This is by default activated and the repository is
deployed by installing the "epel-release" package. It may also be installed from
an url by defining the "yum.epel_url" property. To disable Epel, simply set the
property "yum.epel" to false.

    exports.push name: 'YUM # Epel', timeout: 100000, handler: (ctx, next) ->
      {epel, epel_url} = ctx.config.yum
      return next() unless epel
      ctx.execute
        cmd: if epel_url
        then "rpm -Uvh #{epel_url}"
        else 'yum install epel-release' 
        not_if_exec: 'yum list installed | grep epel-release'
      .then next

    exports.push name: 'YUM # Update', timeout: -1, handler: (ctx, next) ->
      {update} = ctx.config.yum
      ctx.call (_, callback) ->
        ctx.execute
          cmd: 'yum -y update'
          if: update
        , (err, executed, stdout, stderr) ->
          callback err, executed and not /No Packages marked for Update/.test stdout
      .then next

    exports.push name: 'YUM # Packages', timeout: -1, handler: (ctx, next) ->
      services = for name, active of ctx.config.yum.packages
        continue unless active
        name: name
      ctx
      .service services
      .then next

## Dependencies

    glob = require 'glob'
    path = require 'path'
    pidfile_running = require 'mecano/lib/misc/pidfile_running'


