
module.exports = (array) ->
  o = {}
  for el in array then o[el] = true
  Object.keys o
