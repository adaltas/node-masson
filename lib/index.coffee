
params = require './params'
params = params.parse()
params.command ?= 'help'
# Print help
params.command ?= 'run'
require("./commands/#{params.command}")()
