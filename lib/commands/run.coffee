
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
    rl = readline.createInterface process.stdin, process.stdout
    rl.setPrompt ''
    rl.on 'SIGINT', process.exit
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
      rl.write "#{styles.final_status_error err.stack?.trim() or err.message}\n"
      process.exit()
    hostlength = 20
    for s in config.servers then hostlength = Math.max(hostlength, s.host.length+2)
    multihost = params.hosts?.length isnt 1 and config.servers.length isnt 1
    times = {}
    multihost = true
    for k, v of config.styles
      styles[k] = if typeof v is 'string' then colors[v] else v
    run params, config
    .on 'context', (ctx) ->
      ctx
      .on 'middleware_skip', () ->
        return unless ctx.middleware.name?
        line = ''
        line += pad "#{styles.fqdn ctx.config.host}", hostlength
        line += pad "#{styles.label ctx.middleware.name}", 40
        line += pad "#{styles.status_skip 'SKIPPED'}", 20
        rl.write line
        rl.write '\n'
      .on 'middleware_start', () ->
        return unless ctx.middleware.name?
        times[ctx.config.host] = Date.now()
        return if multihost
        line = ''
        line += pad "#{styles.fqdn ctx.config.host}", hostlength
        line += pad "#{styles.label ctx.middleware.name}", 40
        line += pad "#{styles.status_start 'WORKING'}", 20
        rl.write line
      .on 'middleware_stop', (err, status) ->
        return unless ctx.middleware.name?
        time = Date.now() - times[ctx.config.host]
        line = ''
        line += pad "#{styles.fqdn ctx.config.host}", hostlength
        line += pad "#{styles.label ctx.middleware.name}", 40
        statusmsg = if err then "#{styles.status_error ctx.middleware.label_error or 'ERROR'}"
        else if typeof status is 'string' then status
        else if status then "#{styles.status_true ctx.middleware.label_true or 'MODIFIED'}"
        else "#{styles.status_false ctx.middleware.label_false or '--'}"
        line += pad "#{statusmsg}", 20
        line += "#{styles.time print_time time}"
        rl.cursor = 0
        rl.line = ''
        rl._refreshLine() unless multihost
        if err or status?
          rl.write line
          rl.write '\n'
      .on 'wait', ->
        return if multihost
        line = ''
        line += pad "#{styles.fqdn ctx.config.host}", hostlength
        line += pad "#{styles.label ctx.middleware.name}", 40
        line += pad "#{styles.status_wait 'WAIT'}", 20
        rl.cursor = 0
        rl.line = ''
        rl._refreshLine()
        rl.write line
      .on 'waited', ->
        return if multihost
        line = ''
        line += pad "#{ctx.config.host}", hostlength
        line += pad "#{ctx.middleware.name}", 40
        line += pad "#{styles.status_start 'WORKING'}", 20
        rl.cursor = 0
        rl.line = ''
        rl._refreshLine()
        rl.write line
    .on 'server', (ctx, err) ->
      return unless config.servers.length
      line = ''
      line += pad "#{ctx.config.host}", hostlength + 40
      line += if err then "#{styles.host_status_error 'FAILURE'}" else "#{styles.host_status_success 'SUCCESS'}"
      rl.write line
      rl.write '\n'
    .on 'end', ->
      rl.write "#{styles.final_status_success 'Installation is finished'}\n"
      rl.close()
    .on 'error', (err) ->
      if err.errors
        rl.write '\n'
        rl.write "#{err.message}\n"
        for err in err.errors
          rl.write "#{styles.final_status_error err.stack?.trim() or err.message}\n"
      else
        rl.write "#{styles.final_status_error err.stack?.trim() or err.message}\n"
      rl.close()
