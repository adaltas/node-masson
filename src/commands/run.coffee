
readline = require 'readline'

pad = require 'pad'
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
  running = []
  rl = readline.createInterface process.stdin, process.stdout
  rl.setPrompt ''
  process.on 'uncaughtException', (err) ->
    rl.write '\n'
    rl.write err.stack
    rl.close()
  run(config, params)
  .on 'action', (ctx, status) ->
    return if ctx.action.hidden
    status ?= ctx.DISABLED
    hostlength = 20
    for s in config.servers then hostlength = Math.max(hostlength, s.host.length+2)
    time = null
    if status is ctx.STARTED
      running.push [ctx.config.host, ctx.action.name, Date.now()]
    else
      for i in [running.length-1..0]
        if running[i][0] is ctx.config.host and running[i][1] is ctx.action.name
          time = Date.now() - running[i][2]
          running.splice(i, 1)
          break
    line = ''
    line += "#{pad ctx.config.host, hostlength}" if config.servers.length
    line += "#{pad ctx.action.name, 40}"
    statusmsg = switch status
      when ctx.PASS then "\x1b[36m#{ctx.PASS_MSG}\x1b[39m"
      when ctx.OK then "\x1b[36m#{ctx.OK_MSG}\x1b[39m"
      when ctx.FAILED then "\x1b[36m#{ctx.FAILED_MSG}\x1b[39m"
      when ctx.DISABLED then "\x1b[36m#{ctx.DISABLED_MSG}\x1b[39m"
      when ctx.TODO then "\x1b[36m#{ctx.TODO_MSG}\x1b[39m"
      when ctx.PARTIAL then "\x1b[36m#{ctx.PARTIAL_MSG}\x1b[39m"
      when ctx.STOP then "\x1b[35m#{ctx.STOP_MSG}\x1b[39m"
      when ctx.TIMEOUT then "\x1b[35m#{ctx.TIMEOUT_MSG}\x1b[39m"
      when ctx.WARN then "\x1b[33m#{ctx.WARN_MSG}\x1b[39m"
      when ctx.STARTED then "\x1b[36m#{ctx.STARTED_MSG}\x1b[39m"
      else (if typeof status is 'number' then "INVALID CODE" else status)
    line += "#{pad statusmsg, 20}"
    line += "#{print_time time}" if status isnt ctx.STARTED
    if status is ctx.STARTED
      rl.write line
      rl.write '\n' unless params.hosts?.length
    else
      rl.cursor = 0
      rl.line = ''
      rl._refreshLine()
      if status isnt ctx.DISABLED
        rl.write line
        rl.write '\n'
  .on 'end', ->
    rl.write "\x1b[32mInstallation is finished\x1b[39m\n"
    rl.close()
  .on 'error', (err) ->
    print = (err) ->
      rl.write '\n'
      rl.write err.message
      rl.write err.stack
    if err.errors
      for error in err.errors
        print error
    else
      print err
    rl.close()
  .on 'server', (ctx, status) ->
    return unless config.servers.length
    line = ''
    line += "#{pad ctx.config.host, 40}"
    line += switch status
      when ctx.OK then "\x1b[36m#{ctx.OK_MSG}\x1b[39m"
      when ctx.FAILED then "\x1b[36m#{ctx.FAILED_MSG}\x1b[39m"
      else "INVALID CODE"
    # rl.write '\n'
    rl.write line
    rl.write '\n'



    