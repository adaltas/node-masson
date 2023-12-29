
import multimatch from 'masson/utils/multimatch';
import chain from 'masson/utils/chain';
import flatten from 'masson/utils/flatten';
import unique from 'masson/utils/unique';

export default function(config) {
  return chain({
    config: function() {
      return config;
    },
    cluster: function(cluster) {
      return config.clusters[cluster] || null;
    },
    cluster_names: function(match = null) {
      return flatten(Object.keys(config.clusters).map(function(cluster) {
        if (match) {
          return multimatch(cluster, match);
        } else {
          return cluster;
        }
      }));
    },
    service: function(cluster, service) {
      if (arguments.length === 1) {
        [cluster, service] = arguments[0].split(':');
      }
      if (!cluster) {
        throw Error(`Invalid Argument: cluster is required, got ${JSON.stringify(cluster)}`);
      }
      if (!service) {
        throw Error(`Invalid Argument: service is required, got ${JSON.stringify(service)}`);
      }
      cluster = this.cluster(cluster);
      if (!cluster) {
        return null;
      }
      return cluster.services[service] || null;
    },
    service_names: function(match = '*:**') {
      var cmatch, smatch;
      [cmatch, smatch] = match.split(':');
      if (!/:/.test(match)) {
        [smatch, cmatch] = [cmatch, smatch];
      }
      if (!cmatch) {
        cmatch = '*';
      }
      if (!smatch) {
        smatch = '**';
      }
      return flatten(Object.values(config.clusters).map(function(cluster) {
        if (!multimatch(cluster.id, cmatch).length) {
          return [];
        }
        return Object.values(cluster.services).map(function(service) {
          return multimatch(service.id, smatch).map(function(name) {
            return `${cluster.id}:${name}`;
          });
        });
      }));
    },
    service_deps: function(cluster, service) {
      var _, dservice, ref, results;
      ref = service.use;
      results = [];
      for (_ in ref) {
        dservice = ref[_];
        // Find by ID or by name
        results.push(this.service(dservice.id));
      }
      return results;
    },
    nodes: function() {
      return Object.values(config.nodes);
    },
    node: function(node) {
      return config.nodes[node] || null;
    },
    commands: function() {
      return unique(flatten(Object.values(config.clusters).map(function(cluster) {
        return Object.values(cluster.services).map(function(service) {
          return Object.keys(service.commands);
        });
      })));
    }
  });
};
