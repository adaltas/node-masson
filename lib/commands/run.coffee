
readline = require 'readline'

colors = require 'colors/safe'
pad = require 'pad/lib/colors'
params = require '../params'
config = require '../config'
run = require '../run'

print_time = (time) ->
  if time > 1000*60
    "#{time / 1000}m"
  if time > 1000
    "#{time / 1000}s"
  else
    "#{time}ms"

module.exports = ->
  params = params.parse()
  config params.config, (err, config) ->
    # Open readline
    rl = null
    init = ->
      return unless process.stdout.isTTY
      rl = readline.createInterface process.stdin, process.stdout
      rl.setPrompt ''
      rl.on 'SIGINT', process.exit
    write = (msg) ->
      unless rl
      then process.stdout.write msg
      else rl.write msg
    refresh = ->
      return unless rl
      rl.cursor = 0
      rl.line = ''
      rl._refreshLine()
    close = ->
      return unless rl
      rl.close()
    # Set styles
    styles =
      fqdn: colors.cyan.dim
      label: colors.cyan.dim
      status_start: colors.cyan
      status_true: colors.cyan
      status_false: colors.cyan
      status_skip: colors.yellow
      status_wait: colors.cyan
      status_error: colors.magenta
      time: colors.cyan.dim
      host_status_error: colors.red
      host_status_success: colors.blue
      final_status_error: colors.red
      final_status_success: colors.blue
    if err
      write "#{styles.final_status_error err.stack?.trim() or err.message}\n"
      process.exit()
    hostlength = 20
    for s in config.nodes then hostlength = Math.max(hostlength, (s.shortname or s.host).length+2)
    multihost = params.hosts?.length isnt 1 and config.nodes.length isnt 1
    times = {}
    multihost = true
    init()
    for k, v of config.styles
      styles[k] = if typeof v is 'string' then colors[v] else v
    run params, config
    .on 'context', (ctx) ->
      ctx
      .on 'middleware_skip', (middleware) ->
        return unless middleware.header?
        line = ''
        line += pad "#{styles.fqdn ctx.config.shortname or ctx.config.host}", hostlength
        line += pad "#{styles.label middleware.header}", 40
        line += pad "#{styles.status_skip 'SKIPPED'}", 20
        write line+'\n'
      .on 'middleware_start', (middleware) ->
        return unless middleware.header?
        times[ctx.config.shortname or ctx.config.host] = Date.now()
        return if multihost
        line = ''
        line += pad "#{styles.fqdn ctx.config.shortname or ctx.config.host}", hostlength
        line += pad "#{styles.label middleware.header}", 40
        line += pad "#{styles.status_start 'WORKING'}", 20
        write line
      .on 'middleware_stop', (middleware, err, status) ->
        return unless middleware.header?
        time = Date.now() - times[ctx.config.shortname or ctx.config.host]
        line = ''
        line += pad "#{styles.fqdn ctx.config.shortname or ctx.config.host}", hostlength
        line += pad "#{styles.label middleware.header}", 40
        statusmsg = if err then "#{styles.status_error middleware.label_error or 'ERROR'}"
        else if typeof status is 'string' then status
        else if status then "#{styles.status_true middleware.label_true or 'MODIFIED'}"
        else "#{styles.status_false middleware.label_false or '--'}"
        line += pad "#{statusmsg}", 20
        line += "#{styles.time print_time time}"
        refresh() if multihost
        if err or status?
          write line + '\n'
      .on 'wait', (middleware) ->
        return if multihost
        line = ''
        line += pad "#{styles.fqdn ctx.config.shortname or ctx.config.host}", hostlength
        line += pad "#{styles.label middleware.header}", 40
        line += pad "#{styles.status_wait 'WAIT'}", 20
        refresh()
        write line
      .on 'waited', (middleware) ->
        return if multihost
        line = ''
        line += pad "#{ctx.config.shortname or ctx.config.host}", hostlength
        line += pad "#{middleware.header}", 40
        line += pad "#{styles.status_start 'WORKING'}", 20
        refresh()
        write line
    .on 'server', (ctx, err) ->
      return unless config.servers.length
      line = ''
      line += pad "#{ctx.config.shortname or ctx.config.host}", hostlength + 40
      line += if err then "#{styles.host_status_error 'FAILURE'}" else "#{styles.host_status_success 'SUCCESS'}"
      write line+'\n'
    .on 'end', ->
      write "#{styles.final_status_success 'Installation is finished'}\n"
      close()
    .on 'error', (err) ->
      if err.errors
        write '\n'+"#{err.message}\n"
        for err in err.errors
          write "#{styles.final_status_error err.stack?.trim() or err.message}\n"
      else
        write "#{styles.final_status_error err.stack?.trim() or err.message}\n"
      close()
