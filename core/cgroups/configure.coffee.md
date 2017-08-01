
# Cgroups Configure

The module accept the following properties:

## Source code

    module.exports = ->
      options = @config.cgroups ?= {}
      options.groups ?= {}
