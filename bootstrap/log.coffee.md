
# Bootstrap Log

Gather system information.

TODO: look at https://github.com/trentm/node-bunyan

## Configure

*   `basedir` (string)   
    Directory where log files will be stored, default to "./log".   
*   `archive` (boolean)   
    In archive mode, logs will be saved in command/date subdir, with symlink
    'latest' for quick access. Default to "false".   
*   `disabled` (boolean)   
    Disable any log reporting, default to "false".   
*   `filename` (string)   
    Name of the file, default to "{{shortname}}.log".   

All properties are optional and are integrated with the moustache templating
engine. All properties from the configuration are exposed to moustache with the
additionnal "logs.fqdn_reversed" property used in the default filename to
preserve alphanumerical ordering of files.

    module.exports = ->
      log = @config.log ?= {}
      log.disabled ?= false
      log.basedir ?= './log'
      log.archive ?= false
      log.rotate ?= false
      rotate_size = if log.rotate is true then 10 else log.rotate
      now = @config.runinfo?.date or new Date
      command = @params.command
      dateformat = "#{now.getFullYear()}-#{('0'+now.getMonth()).slice -2}-#{('0'+now.getDate()).slice -2}"
      dateformat += " #{('0'+now.getHours()).slice -2}-#{('0'+now.getMinutes()).slice -2}-#{('0'+now.getSeconds()).slice -2}"
      cmddir = path.join log.basedir, command if log.archive
      log.basedir = path.join cmddir, dateformat if log.archive
      log.fqdn_reversed = @config.host.split('.').reverse().join('.')
      log.filename ?= "{{shortname}}.log"
      # Rendering
      log.basedir = mustache.render log.basedir, @config
      log.filename = mustache.render log.filename, @config
      # Elastic Search
      log.elasticsearch ?= {}
      log.elasticsearch.enable ?= false
      log.elasticsearch.url ?= 'http://localhost:9200'
      log.elasticsearch.index ?= "masson"
      log.elasticsearch.type ?= command

      @call unless: @config.log.disabled, header: 'Bootstrap Log # Text', required: true, irreversible: true, handler: ->
        {basedir, filename, archive} = @config.log
        @call header: 'Prepare Log dir', handler: ->
          @call 
            if: not @contexts().length or @contexts()[0].config.host is @config.host
            handler: ->
              @call 
                if: log.rotate
              , ->
                  list = []
                  count = 0
                  @call handler: (_,callback) ->
                    fs.readdir cmddir, (err, files) =>
                      throw err if err
                      list = files
                      return callback null, (files.length > rotate_size )
                  @call -> 
                    @each list, (options, callback) ->
                      @remove   
                        if: -> (list.length-count) > rotate_size
                        target: path.join cmddir, options.key
                      @call
                        if: -> @status -1
                        handler: -> count = count+1
                      @then callback
              @mkdir basedir
              @call
                if: archive
                handler: ->
                  logdir = path.join basedir, '../../' # creates relative symlink <log>/latest -> <log>/<command>/<date>
                  logdirlatest = path.join basedir, '../' # creates relative symlink <log>/<command>/latest -> <log>/<command>/<date>
                  @link 
                    source: path.relative logdir, path.resolve basedir
                    target: path.join logdir, 'latest'
                  @link 
                    source: path.relative logdirlatest, path.resolve basedir
                    target: path.join logdirlatest, 'latest'
            # Avoid a race condition by waiting that the first node finish to
            # create log dir
          @wait_execute cmd: "[ -d '#{basedir}' ]"
        @call ->
          out = fs.createWriteStream path.resolve basedir, filename
          stdouting = 0
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
          @on 'diff', (log) ->
            out.write '\n```diff\n#{log.message}```\n\n' unless log.message
          @on 'stdout_stream', (log) ->
            # return if log.message is null and stdouting is 0
            if log.message is null
            then stdouting = 0
            else stdouting++
            out.write '\n```stdout\n' if stdouting is 1
            out.write log.message if stdouting > 0
            out.write '```\n\n' if stdouting is 0
          @on 'stderr', (log) ->
            out.write "\n```stderr\n#{log.message}```\n\n"
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

      @call header: 'Bootstrap Log # CSV', required: true, irreversible: true, handler: ->
        {disabled, basedir, filename} = @config.log
        return if disabled
        @mkdir "#{basedir}"
        @call ->
          out = fs.createWriteStream (path.resolve basedir, filename+'.csv')
          @on 'diff', (log) ->
            out.write "#{log.type},#{log.level},#{JSON.stringify log.message},\n"
          @on 'header', (log) ->
            out.write "#{log.type},,,#{log.header}\n"
          @on 'stdin', (log) ->
            out.write "#{log.type},#{log.level},#{JSON.stringify log.message},\n"
          @on 'stdout', (log) ->
            out.write "#{log.type},#{log.level},#{JSON.stringify log.message},\n"
          @on 'stderr', (log) ->
            out.write "#{log.type},#{log.level},#{JSON.stringify log.message},\n"
          @on 'text', (log) ->
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

      @call header: 'Bootstrap Log # Elastic Search', required: true, irreversible: true, handler: ->
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
