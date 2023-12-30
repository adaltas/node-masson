
# APT Configure

## Source Code

    export default ({options}) ->

## Configuration

      # Updates the package lists
      options.update ?= false
      # Update installed packages
      options.upgrade ?= false
      # Enforce update if upgrade is active
      options.update = true if options.upgrade

## Default Packages

      options.packages ?= {}
