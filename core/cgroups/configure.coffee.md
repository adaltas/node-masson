
# Cgroups Configure

The module accept the following properties:

## Source code

    module.exports = ->
      @config.cgroups ?= {}
      @config.cgroups.groups ?= {}
