
var flatten;

flatten = function(arr, ret) {
  var i, j, ref;
  if (ret == null) {
    ret = [];
  }
  for (i = j = 0, ref = arr.length; (0 <= ref ? j < ref : j > ref); i = 0 <= ref ? ++j : --j) {
    if (Array.isArray(arr[i])) {
      flatten(arr[i], ret);
    } else {
      ret.push(arr[i]);
    }
  }
  return ret;
};

export default flatten;
