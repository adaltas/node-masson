
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
  # running = []
  rl = readline.createInterface process.stdin, process.stdout
  rl.setPrompt ''
  rl.on 'SIGINT', process.exit
  hostlength = 20
  for s in config.servers then hostlength = Math.max(hostlength, s.host.length+2)
  params = params.parse()
  multihost = params.hosts?.length isnt 1 and config.servers.length isnt 1
  times = {}
  multihost = true
  run(config, params)
  .on 'context', (ctx) ->
    ctx
    .on 'action_start', () ->
      return unless ctx.action.name?
      times[ctx.config.host] = Date.now()
      return if multihost
      line = ''
      line += "#{pad ctx.config.host, hostlength}"
      line += "#{pad ctx.action.name, 40}"
      line += "#{pad 'STARTED', 20}"
      rl.write line 
    .on 'action_end', (err, status) ->
      return unless ctx.action.name?
      time = Date.now() - times[ctx.config.host]
      line = ''
      line += "#{pad ctx.config.host, hostlength}"
      line += "#{pad ctx.action.name, 40}"
      statusmsg = if err then "\x1b[35m#{ctx.action.label_error || 'ERROR'}\x1b[39m"
      else if status then "\x1b[36m#{ctx.action.label_true || 'MODIFIED'}\x1b[39m"
      else "\x1b[36m#{ctx.action.label_false || 'OK'}\x1b[39m"
      line += "#{pad statusmsg, 20}"
      line += "#{print_time time}"
      # rl.write line
      # rl.write '\n'
      rl.cursor = 0
      rl.line = ''
      rl._refreshLine() unless multihost
      if err or status?
        rl.write line
        rl.write '\n'
    .on 'wait', ->
      return if multihost
      statusmsg = "\x1b[36mWAIT\x1b[39m"
      line = ''
      line += "#{pad ctx.config.host, hostlength}"
      line += "#{pad ctx.action.name, 40}"
      line += "#{pad statusmsg, 20}"
      rl.cursor = 0
      rl.line = ''
      rl._refreshLine()
      rl.write line
    .on 'waited', ->
      return if multihost
      statusmsg = "\x1b[36m#{ctx.STARTED_MSG}\x1b[39m"
      line = ''
      line += "#{pad ctx.config.host, hostlength}"
      line += "#{pad ctx.action.name, 40}"
      line += "#{pad statusmsg, 20}"
      rl.cursor = 0
      rl.line = ''
      rl._refreshLine()
      rl.write line
  .on 'server', (ctx, status) ->
    return unless config.servers.length
    line = ''
    line += "#{pad ctx.config.host, hostlength+40}"
    line += switch status
      when ctx.OK then "\x1b[36m#{ctx.OK_MSG}\x1b[39m"
      when ctx.FAILED then "\x1b[36m#{ctx.FAILED_MSG}\x1b[39m"
      else "INVALID CODE"
    rl.write line
    rl.write '\n'
  .on 'end', ->
    rl.write "\x1b[32mInstallation is finished\x1b[39m\n"
    rl.close()
  .on 'error', (err) ->
    rl.write '\n'
    rl.write "\x1b[31m#{err.stack or err.message}\x1b[39m"
    rl.close()



    