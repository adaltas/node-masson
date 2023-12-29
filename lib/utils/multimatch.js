
import {
  minimatch
} from 'minimatch';

export default function(list, patterns, options = {}) {
  var el, i, len, results;
  if (!Array.isArray(list)) {
    list = [list];
  }
  if (!Array.isArray(patterns)) {
    patterns = [patterns];
  }
  results = [];
  for (i = 0, len = list.length; i < len; i++) {
    el = list[i];
    if (!patterns.some(function(pattern) {
      return minimatch(el, pattern, options);
    })) {
      continue;
    }
    results.push(el);
  }
  return results;
};
