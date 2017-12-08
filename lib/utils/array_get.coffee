
module.exports = (elements, search) ->
  throw Error "Invalid Argument: 1st argument is expected to be an array, got #{JSON.stringify elements}" unless Array.isArray elements
  throw Error "Invalid Argument: 2nd argument is expected to be a a function, got #{JSON.stringify search}" unless typeof search is 'function'
  found = []
  for element in elements
    found.push element if search.call null, element
  throw Error 'Found no element' if found.length is 0
  throw Error 'Found more than one element' if found.length > 1
  found[0]
