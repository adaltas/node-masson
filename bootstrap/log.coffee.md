
# Bootstrap Log

Gather system information.

TODO: look at https://github.com/trentm/node-bunyan

    fs = require 'fs'
    pad = require 'pad'
    path = require 'path'
    mustache = require 'mustache'
    mecano = require 'mecano'
    exports = module.exports = []
    exports.push 'masson/bootstrap/mecano'

## Configure

*   `basedir`   
    Directory where log files will be stored, default to "./logs".   
*   `filename_stdout`   
    Name of the file to redirect stdout, default to "{{shortname}}.stdout.log".   
*   `filename_stderr`   
    Name of the file to redirect stderr, default to "{{shortname}}.stderr.log".   

All properties are optional and are integrated with the moustache templating
engine. All properties from the configuration are exposed to moustache with the
additionnal "logs.fqdn_reversed" property used in the default filename to
preserve alphanumerical ordering of files.

    exports.push required: true, callback: (ctx) ->
      logs = ctx.config.logs ?= {}
      logs.basedir ?= './logs'
      logs.fqdn_reversed = ctx.config.host.split('.').reverse().join('.')
      logs.filename_stdout ?= '{{shortname}}.stdout.log'
      logs.filename_stderr ?= '{{shortname}}.stderr.log'
      # Rendering
      logs.basedir = mustache.render logs.basedir, ctx.config
      logs.filename_stdout = mustache.render logs.filename_stdout, ctx.config
      logs.filename_stderr = mustache.render logs.filename_stderr, ctx.config

    exports.push name: 'Bootstrap # Log', required: true, callback: (ctx, next) ->
      {basedir, filename_stdout, filename_stderr} = ctx.config.logs
      mecano.mkdir
        destination: "#{basedir}"
      , (err, created) ->
        return next err if err
        # Add log interface
        ctx.log = log = (msg) ->
          log.out.write "#{msg}\n"
        log.out = fs.createWriteStream path.resolve basedir, filename_stdout
        log.err = fs.createWriteStream path.resolve basedir, filename_stderr
        close = ->
          setTimeout ->
            log.out.close()
            log.err.close()
          , 100
        ctx.on 'action_start', (status) ->
          date = (new Date).toISOString()
          name = ctx.action.name || ctx.action.id
          msg = "\n#{name}\n#{pad date.length+name.length, '', '-'}\n"
          log.out.write msg
          log.out.write ">>> START #{date}\n"
          log.err.write msg
        ctx.on 'action_end', (err, status) ->
          log.out.write ">>> END #{(new Date).toISOString()}\n"
        ctx.on 'end', ->
          log.out.write '\nFINISHED WITH SUCCESS\n'
          close()
        ctx.on 'error', (err) ->
          log.out.write 'FINISHED WITH ERROR\n'
          print = (err) ->
            log.err.write err.stack or err.message + '\n'
          unless err.errors
            print err
          else if err.errors
            log.err.write err.message + '\n'
            for error in err.errors then print error
          close()
        next null, ctx.PASS



