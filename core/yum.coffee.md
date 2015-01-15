
# YUM

Configure YUM for internet and intranet mode. The Epel repository is optionnaly
deployed.

Note, ntp is installed to encure correct date on the server or HTTPS will fail.

    each = require 'each'
    path = require 'path'
    misc = require 'mecano/lib/misc'
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

    exports.push name: 'YUM # Check', callback: (ctx, next) ->
      misc.pidfileStatus ctx.ssh, '/var/run/yum.pid', {}, (err, status) ->
        return next err if err
        switch status
          when 0
            ctx.log 'YUM is running, abort'
            next new Error 'Yum is already running'
          when 1
            ctx.log 'YUM isnt running'
            next null, false
          when 2
            ctx.log "YUM isnt running, removing invalid '/var/run/yum.pid'"
            next null, true

## YUM # Configuration

Read the existing configuration in '/etc/yum.conf', 
merge server configuration and write the content back.

More information about configuring the proxy settings 
is available on [the centos website](http://www.centos.org/docs/5/html/yum/sn-yum-proxy-server.html)

    exports.push name: 'YUM # Configuration', callback: (ctx, next) ->
      ctx.ini
        content: ctx.config.yum.config
        destination: '/etc/yum.conf'
        merge: true
        backup: true
      , next

## YUM # repositories

Upload the YUM repository definitions files present in 
"ctx.config.yum.copy" to the yum repository directory 
in "/etc/yum.repos.d"

    exports.push name: 'YUM # Repositories', timeout: -1, callback: (ctx, next) ->
      {copy, clean} = ctx.config.yum
      return next() unless copy and clean
      modified = false
      basenames = []
      do_upload = ->
        return do_clean() unless copy
        each()
        .files(copy)
        .parallel(1)
        .on 'item', (filename, next) ->
          basename = path.basename filename
          return next() if basename.indexOf('.') is 0
          basenames.push basename
          ctx.log "Upload /etc/yum.repos.d/#{path.basename filename}"
          ctx.upload
            source: filename
            destination: "/etc/yum.repos.d/#{path.basename filename}"
          , (err, uploaded) ->
            return next err if err
            modified = true if uploaded
            next()
        .on 'error', (err) ->
          next err
        .on 'end', ->
          do_clean()
      do_clean = ->
        return do_update() unless clean
        ctx.log "Clean /etc/yum.repos.d/*"
        ctx.fs.readdir '/etc/yum.repos.d', (err, remote_basenames) ->
          return next err if err
          remove_basenames = []
          for rfn in remote_basenames
            continue if rfn.indexOf('.') is 0
            # Add to the stack if remote filename isnt in source
            remove_basenames.push rfn if basenames.indexOf(rfn) is -1
          return do_update() if remove_basenames.length is 0
          each(remove_basenames)
          .on 'item', (filename, next) ->
            ctx.fs.unlink "/etc/yum.repos.d/#{filename}", next
          .on 'error', (err) ->
            next err
          .on 'end', ->
            modified = true
            do_update()
      do_update = ->
        ctx.log 'Clean metadata and update'
        ctx.execute
          cmd: 'yum clean metadata; yum -y update'
          if: modified
        , next
      do_upload()

## Epel

Install the Epel repository. This is by default activated and the repository is
deployed by installing the "epel-release" package. It may also be installed from
an url by defining the "yum.epel_url" property. To disable Epel, simply set the
property "yum.epel" to false.

    exports.push name: 'YUM # Epel', timeout: 100000, callback: (ctx, next) ->
      {epel, epel_url} = ctx.config.yum
      return next() unless epel
      ctx.execute
        cmd: if epel_url
        then "rpm -Uvh #{epel_url}"
        else 'yum install epel-release' 
        not_if_exec: 'yum list installed | grep epel-release'
      , next

    exports.push name: 'YUM # Update', timeout: -1, callback: (ctx, next) ->
      {update} = ctx.config.yum
      return next null, ctx.DISABLED unless update
      ctx.execute
        cmd: 'yum -y update'
      , (err, executed, stdout, stderr) ->
        next err, not /No Packages marked for Update/.test(stdout)

    exports.push name: 'YUM # Packages', timeout: -1, callback: (ctx, next) ->
      services = for name, active of ctx.config.yum.packages
        continue unless active
        name: name
      ctx.service services, next
      # each(packages)
      # .on 'item', (service, active, next) ->
      #   return next() unless active
      #   service = name: service if typeof service is 'string'
      #   ctx.service service, (err, s) ->
      #     serviced += s
      #     next err
      # .on 'both', (err) ->
      #   next err, if serviced then ctx.OK else ctx.PASS




