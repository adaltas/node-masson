
export default function(elements, search) {
  var element, found, i, len;
  if (!Array.isArray(elements)) {
    throw Error(`Invalid Argument: 1st argument is expected to be an array, got ${JSON.stringify(elements)}`);
  }
  if (typeof search !== 'function') {
    throw Error(`Invalid Argument: 2nd argument is expected to be a a function, got ${JSON.stringify(search)}`);
  }
  found = [];
  for (i = 0, len = elements.length; i < len; i++) {
    element = elements[i];
    if (search.call(null, element)) {
      found.push(element);
    }
  }
  if (found.length === 0) {
    throw Error('Found no element');
  }
  if (found.length > 1) {
    throw Error('Found more than one element');
  }
  return found[0];
};
