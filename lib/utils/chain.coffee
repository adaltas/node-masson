
module.exports = (obj) ->
  obj.chain = ->
    chain = {}
    for fn in Object.keys(@) then do (fn) ->
      if fn in ['chain', 'unchain']
        chain[fn] = obj[fn]
        return
      chain[fn] = ->
        args = Array.prototype.slice.call arguments
        args[-1..-1][0].call null, obj[fn].apply obj, args[0..-2] if args.length
        @
    chain
  obj.unchain = ->
    obj
  obj
