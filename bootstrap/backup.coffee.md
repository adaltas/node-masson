
# Backup


    module.exports = []
    module.exports.push require './mecano'

## Mecano.backup Wrap
    
    module.exports.push (ctx) -> 
      return unless ctx.config.backup
      ctx.backup = ((backup) -> (options, callback) -> 
      	backup (misc.merge ctx.config.backup, options), callback
      )(ctx.backup)

## Module Dependencies

    misc = require 'mecano/lib/misc'
    