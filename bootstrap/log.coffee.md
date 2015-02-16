
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

*   `basedir` (string)   
    Directory where log files will be stored, default to "./log".   
*   `disabled` (boolean)   
    Disabled any log reporting, default to "true".   
*   `filename_stdout` (string)   
    Name of the file to redirect stdout, default to "{{shortname}}.stdout.log".   
*   `filename_stderr` (string)   
    Name of the file to redirect stderr, default to "{{shortname}}.stderr.log".   

All properties are optional and are integrated with the moustache templating
engine. All properties from the configuration are exposed to moustache with the
additionnal "logs.fqdn_reversed" property used in the default filename to
preserve alphanumerical ordering of files.

    exports.push required: true, handler: (ctx) ->
      log = ctx.config.log ?= {}
      log.disabled ?= false
      log.basedir ?= './log'
      log.fqdn_reversed = ctx.config.host.split('.').reverse().join('.')
      log.filename_stdout ?= '{{shortname}}.stdout.log'
      log.filename_stderr ?= '{{shortname}}.stderr.log'
      # Rendering
      log.basedir = mustache.render log.basedir, ctx.config
      log.filename_stdout = mustache.render log.filename_stdout, ctx.config
      log.filename_stderr = mustache.render log.filename_stderr, ctx.config

    exports.push name: 'Bootstrap # Log', required: true, handler: (ctx, next) ->
      {disabled, basedir, filename_stdout, filename_stderr} = ctx.config.log
      if disabled
        ctx.log = -> # Dummy function
        return next()
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
        ctx.on 'middleware_start', (status) ->
          date = (new Date).toISOString()
          name = ctx.middleware.name || ctx.middleware.id
          msg = "\n#{name}\n#{pad date.length+name.length, '', '-'}\n"
          log.out.write msg
          log.out.write ">>> START #{date}\n"
          log.err.write msg
        ctx.on 'middleware_stop', (err, status) ->
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



