
params = require './params'
params = params.parse()
params.command ?= 'help'
# Print help
params.command ?= 'run'
switch params.command
  when 'help' then require('./commands/help')()
  when 'exec' then require('./commands/exec')()
  when 'server' then require('./commands/server')()
  when 'tree' then require('./commands/tree')()
  when 'init' then require('./commands/init')()
  when 'configure' then require('./commands/configure')()
  else require('./commands/run')()
