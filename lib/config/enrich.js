
export default function(config) {
  var _, cluster, cname, node, ref, results, service, sname;
  ref = config.clusters;
  // Enrich configuration
  results = [];
  for (cname in ref) {
    cluster = ref[cname];
    results.push((function() {
      var ref1, results1;
      ref1 = cluster.services;
      results1 = [];
      for (sname in ref1) {
        service = ref1[sname];
        // Load configuration
        if (service.configure) {
          if (typeof service.configure === 'string') {
            service.configure = load(service.configure);
          }
          if (typeof service.configure !== 'function') {
            throw Error(`Invalid Configuration: not a function, got ${typeof service.configure}`);
          }
        }
        results1.push((function() {
          var ref2, results2;
          ref2 = config.nodes;
          results2 = [];
          for (_ in ref2) {
            node = ref2[_];
            results2.push(service.configure.call(null, {
              use: service.deps,
              options: service.config,
              node: node
            }));
          }
          return results2;
        })());
      }
      return results1;
    })());
  }
  return results;
};
