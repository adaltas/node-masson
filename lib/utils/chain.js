
export default function(obj) {
  obj.chain = function() {
    var chain, fn, i, len, ref;
    chain = {};
    ref = Object.keys(this);
    for (i = 0, len = ref.length; i < len; i++) {
      fn = ref[i];
      (function(fn) {
        if (fn === 'chain' || fn === 'unchain') {
          chain[fn] = obj[fn];
          return;
        }
        return chain[fn] = function() {
          var args;
          args = Array.prototype.slice.call(arguments);
          if (args.length) {
            args.slice(-1)[0].call(null, obj[fn].apply(obj, args.slice(0, -1)));
          }
          return this;
        };
      })(fn);
    }
    return chain;
  };
  obj.unchain = function() {
    return obj;
  };
  return obj;
};
