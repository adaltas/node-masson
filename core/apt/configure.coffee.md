
# APT Configure

## Source Code

    module.exports = ({options}) ->

## Configuration

      # Updates the package lists
      options.update ?= false
      # Update installed packages
      options.upgrade ?= false
      # Enforce update if upgrade is active
      options.update = true if options.upgrade

## Default Packages

      options.packages ?= {}
