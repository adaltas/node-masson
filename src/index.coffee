
params = require './params'
params = params.parse()
params.command ?= 'help'
# Print help
switch params.command
  when 'help' then require('./commands/help')()
  when 'exec' then require('./commands/exec')()
  when 'tree' then require('./commands/tree')()
  else require('./commands/run')()


