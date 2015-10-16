
# Bootstrap Log

Gather system information.

TODO: look at https://github.com/trentm/node-bunyan

    fs = require 'fs'
    pad = require 'pad'
    path = require 'path'
    mustache = require 'mustache'
    mecano = require 'mecano'
    exports = module.exports = []
    # exports.push 'masson/bootstrap/mecano'

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

    exports.push required: true, handler: ->
      log = @config.log ?= {}
      log.disabled ?= false
      log.prefix ?= false
      log.prefix = "#{Date.now()}" if log.prefix is true
      log.basedir ?= './log'
      log.fqdn_reversed = @config.host.split('.').reverse().join('.')
      filename = if log.prefix then "#{log.prefix}-{{shortname}}" else '{{shortname}}'
      log.filename_stdout ?= "#{filename}.stdout.log"
      log.filename_stderr ?= "#{filename}.stderr.log"
      # Rendering
      log.basedir = mustache.render log.basedir, @config
      log.filename_stdout = mustache.render log.filename_stdout, @config
      log.filename_stderr = mustache.render log.filename_stderr, @config

    exports.push name: 'Bootstrap # Log', required: true, handler: (_, next) ->
      {disabled, basedir, filename_stdout, filename_stderr} = @config.log
      if disabled
        @log = -> # Dummy function
        return next()
      @mkdir
        destination: "#{basedir}"
      , (err, created) ->
        return next err if err
        # Add log interface
        @options.log = @log = log = (msg) ->
          log.out.write "#{msg}\n"
        @options.stdout = log.out = fs.createWriteStream path.resolve basedir, filename_stdout
        @options.stderr = log.err = fs.createWriteStream path.resolve basedir, filename_stderr
        close = ->
          setTimeout ->
            log.out.close()
            log.err.close()
          , 100
        @on 'middleware_start', (status) ->
          date = (new Date).toISOString()
          name = @middleware.name || @middleware.id
          msg = "\n#{name}\n#{pad date.length+name.length, '', '-'}\n"
          log.out.write msg
          log.out.write ">>> START #{date}\n"
          log.err.write msg
        @on 'middleware_stop', (err, status) ->
          log.out.write ">>> END #{(new Date).toISOString()}\n"
        @on 'end', ->
          log.out.write '\nFINISHED WITH SUCCESS\n'
          close()
        @on 'error', (err) ->
          log.out.write 'FINISHED WITH ERROR\n'
          print = (err) ->
            log.err.write err.stack or err.message + '\n'
          unless err.errors
            print err
          else if err.errors
            log.err.write err.message + '\n'
            for error in err.errors then print error
          close()
        next null, false
