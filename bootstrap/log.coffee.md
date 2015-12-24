
# Bootstrap Log

Gather system information.

TODO: look at https://github.com/trentm/node-bunyan

    exports = module.exports = []

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

    exports.configure = (ctx) ->
      log = @config.log ?= {}
      log.disabled ?= false
      log.prefix ?= false
      log.prefix = "#{Date.now()}" if log.prefix is true
      log.basedir ?= './log'
      log.fqdn_reversed = @config.host.split('.').reverse().join('.')
      filename = if log.prefix then "#{log.prefix}-{{shortname}}" else '{{shortname}}'
      log.filename_stdout ?= "#{filename}.stdout.log"
      # Rendering
      log.basedir = mustache.render log.basedir, @config
      log.filename_stdout = mustache.render log.filename_stdout, @config
      # log.filename_stderr = mustache.render log.filename_stderr, @config
      # Elastic Search
      log.elasticsearch ?= {}
      log.elasticsearch.enable ?= false
      log.elasticsearch.url ?= 'http://localhost:9200'
      log.elasticsearch.index ?= "ryba"
      log.elasticsearch.type ?= "install"

    exports.push header: 'Bootstrap Log # Text', required: true, handler: ->
      {disabled, basedir, filename_stdout} = @config.log
      return if disabled
      @mkdir
        destination: "#{basedir}"
      @call ->
        out = fs.createWriteStream path.resolve basedir, filename_stdout
        stdouting = stderring = false
        @on 'text', (log) ->
          out.write "#{log.message}"
          out.write " (#{log.level}, written by #{log.module})" if log.module
          out.write "\n"
        @on 'header', (log) ->
          out.write "\n#{'#'.repeat log.header_depth} #{log.message}\n\n"
        @on 'stdin', (log) ->
          if log.message.indexOf('\n') is -1
          then out.write "\nRunning Command: `#{log.message}`\n\n"
          else out.write "\n```stdin\n#{log.message}\n```\n\n"
          stdining = log.message isnt null
        @on 'stdout', (log) ->
          out.write '\n```stdout\n' unless stdouting
          out.write log.message if log.message
          out.write '```\n\n' unless log.message
          stdouting = log.message isnt null
        @on 'stderr', (log) ->
          out.write '\n```stderr\n' unless stderring
          out.write log.message if log.message
          out.write '```\n\n' unless log.message
          stderring = log.message isnt null
        close = ->
          setTimeout (-> out.close()), 100
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
    
    exports.push header: 'Bootstrap Log # CSV', required: true, handler: ->
      {disabled, basedir, filename_stdout} = @config.log
      return if disabled
      @mkdir
        destination: "#{basedir}"
      @call ->
        {basedir, filename_stdout} = @config.log
        out = fs.createWriteStream (path.resolve basedir, filename_stdout)+'.csv'
        @on 'text', (log) ->
          out.write "#{log.type},#{log.level},#{JSON.stringify log.message},\n"
        @on 'header', (log) ->
          out.write "#{log.type},,,#{log.header}\n"
        @on 'stdin', (log) ->
          out.write "#{log.type},#{log.level},#{JSON.stringify log.message},\n"
        @on 'stdout', (log) ->
          out.write "#{log.type},#{log.level},#{JSON.stringify log.message},\n"
        @on 'stderr', (log) ->
          out.write "#{log.type},#{log.level},#{JSON.stringify log.message},\n"
        close = ->
          setTimeout (-> out.close()), 100
        @on 'end', ->
          out.write "lifecycle,INFO,Finished with success,\n"
          close()
        @on 'error', (err) ->
          out.write "lifecycle,ERROR,Finished with error,\n"
          print = (err) ->
            out.write "lifecycle,ERROR,#{err.stack or err.message},\n"
          unless err.errors
          then print err
          else if err.errors then for error in err.errors then print error
          close()

## Elastic Search

Forward log into Elastic Search. Errors will be silently ignored. Index may be
removed with the command `curl -XDELETE 'http://localhost:9200/ryba/'`.

    exports.push header: 'Bootstrap Log # Elastic Search', required: true, handler: ->
      {elasticsearch} = @config.log
      return unless elasticsearch.enable
      @call (_, callback) ->
        url = "#{elasticsearch.url}/#{elasticsearch.index}"
        request url: url, method: 'HEAD', (err, response, body) ->
          return callback null if err
          return callback() if response.statusCode is 200
          json =
            settings: refresh_interval: '1s'
            mappings: install: properties:
              time:
                type: 'date'
                format: 'epoch_millis'
          request url: url, method: 'PUT', json: json, (err, response, body) ->
            callback null, response.code is 200
      @call ->
        put = (log) ->
          url = "#{elasticsearch.url}/#{elasticsearch.index}/#{elasticsearch.type}"
          log.message = log.message.toString() if Buffer.isBuffer log.message
          request url: url, method: 'POST', json: log, (err, response, body) -> # Elastic Search doesnt have to be started
        @on 'text', (log) ->
          put log
        @on 'header', (log) ->
          put log
        @on 'stdin', (log) ->
          put log
        @on 'stdout', (log) ->
          put log
        @on 'stderr', (log) ->
          put log
        @on 'end', ->
          put type: 'lifecycle', level: 'INFO', message: 'Finished with success'
        @on 'error', (err) ->
          put type: 'lifecycle', level: 'ERROR', message: 'Finished with error'
          print = (err) ->
            put type: 'lifecycle', level: 'ERROR', message: err.stack or err.message
          unless err.errors
          then print err
          else if err.errors then for error in err.errors then print error      

## Dependencies

    fs = require 'fs'
    path = require 'path'
    mustache = require 'mustache'
    request = require 'request'
