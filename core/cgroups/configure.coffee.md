
# Cgroups Configure

The module accept the following properties:

## Source code

    module.exports = (service) ->
      options = service.options

      options.groups ?= {}
