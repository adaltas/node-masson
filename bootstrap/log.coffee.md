
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
      log.basedir ?= './log'
      log.fqdn_reversed = @config.host.split('.').reverse().join('.')
      log.filename_stdout ?= '{{shortname}}.stdout.log'
      log.filename_stderr ?= '{{shortname}}.stderr.log'
      # Rendering
      log.basedir = mustache.render log.basedir, @config
      log.filename_stdout = mustache.render log.filename_stdout, @config
      log.filename_stderr = mustache.render log.filename_stderr, @config

    exports.push header: 'Bootstrap # Log', required: true, handler: (options, next) ->
      {disabled, basedir, filename_stdout, filename_stderr} = @config.log
      if disabled
        return next()
      @mkdir
        destination: "#{basedir}"
      , (err, created) ->
        return next err if err
        # Add log interface
        out = fs.createWriteStream path.resolve basedir, filename_stdout
        csvout = fs.createWriteStream (path.resolve basedir, filename_stdout)+'.csv'
        err = fs.createWriteStream path.resolve basedir, filename_stderr
        stdouting = stderring = false
        @on 'text', (log) ->
          # todo: no longer workign after implementing log objects in mecano
          # out.write "[#{log.level} #{log.time}]"
          out.write "#{log.message}"
          out.write " (#{log.level}, writen by #{log.module})" if log.module
          out.write "\n"
          csvout.write "#{log.type},#{log.level},#{JSON.stringify log.message},\n"
        @on 'header', (log) ->
          csvout.write "#{log.type},,,#{log.header}\n"
          out.write "\n#{'#'.repeat log.header_depth} #{log.message}\n\n"
        @on 'stdin', (log) ->
          if log.message.indexOf('\n') is -1
          then out.write "\nRunning Command: `#{log.message}`\n\n"
          else out.write "\n```stdin\n#{log.message}\n```\n\n"
          stdining = !!log.message
        @on 'stdout', (log) ->
          out.write '\n```stdout\n' unless stdouting
          out.write log.message if log.message
          out.write '```\n\n' unless log.message
          stdouting = !!log.message
        @on 'stderr', (log) ->
          out.write '\n```stderr\n' unless stderring
          out.write log.message if log.message
          out.write '```\n\n' unless log.message
          stderring = !!log.message
        # @options.log = @log = log = (msg) ->
        #   log.out.write "#{msg}\n"
        # @options.stdout = log.out = fs.createWriteStream path.resolve basedir, filename_stdout
        # @options.stderr = log.err = fs.createWriteStream path.resolve basedir, filename_stderr
        options.stdout = out
        options.stderr = err
        close = ->
          setTimeout ->
            out.close()
            # log.err.close()
          , 100
        # @on 'middleware_start', (status) ->
        #   date = (new Date).toISOString()
        #   name = @middleware.name || @middleware.id
        #   msg = "\n#{name}\n#{pad date.length+name.length, '', '-'}\n"
        #   log.out.write msg
        #   log.out.write ">>> START #{date}\n"
        #   log.err.write msg
        # @on 'middleware_stop', (err, status) ->
        #   log.out.write ">>> END #{(new Date).toISOString()}\n"
        @on 'end', ->
          out.write '\nFINISHED WITH SUCCESS\n'
          close()
        @on 'error', (err) ->
          out.write 'FINISHED WITH ERROR\n'
          print = (err) ->
            out.write err.stack or err.message + '\n'
          unless err.errors
            print err
          else if err.errors
            out.write err.message + '\n'
            for error in err.errors then print error
          close()
        next null, false
