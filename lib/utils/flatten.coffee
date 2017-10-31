
flatten = (arr, ret) ->
  ret ?= []
  for i in [0 ... arr.length]
    if Array.isArray arr[i]
      flatten arr[i], ret
    else
      ret.push arr[i]
  ret

module.exports = flatten
