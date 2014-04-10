
{merge} = require 'mecano/lib/misc'

misc = module.exports =
  flatten: (arr, ret) ->
    ret ?= []
    for i in [0 ... arr.length]
      if Array.isArray arr[i]
        misc.flatten arr[i], ret
      else
        ret.push arr[i]
    ret
  merge: merge