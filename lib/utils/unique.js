
export default function(array) {
  var el, i, len, o;
  o = {};
  for (i = 0, len = array.length; i < len; i++) {
    el = array[i];
    o[el] = true;
  }
  return Object.keys(o);
};
