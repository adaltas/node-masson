var any,
  is_object,
  match,
  indexOf = [].indexOf;

const nodes = function (config, cluster, service) {
  var _, node, nodes, ref, ref1, ref2;
  nodes = {};
  ref = config.cluster;
  for (_ in ref) {
    cluster = ref[_];
    ref1 = cluster.services;
    for (_ in ref1) {
      service = ref1[_];
      ref2 = service.nodes;
      for (_ in ref2) {
        node = ref2[_];
        if (nodes[node] == null) {
          nodes[node] = true;
        }
      }
    }
  }
  return Object.keys(nodes);
};

const services = function (config, node) {
  var _, ref, ref1, service, services;
  services = {};
  ref = config.nodes;
  for (_ in ref) {
    node = ref[_];
    ref1 = node.services;
    for (_ in ref1) {
      service = ref1[_];
      services[service] = true;
    }
  }
  return Object.keys(services);
};

const handlers = {
  generic: {
    normalize: function (config) {
      var j, len, ref, value;
      if (config.type == null) {
        config.type = "generic";
      }
      if (!config.values) {
        throw Error('Required Property: "values" not found');
      }
      if (!Array.isArray(config.values)) {
        throw Error('Invalid Property: "values" not an array');
      }
      ref = config.values;
      for (j = 0, len = ref.length; j < len; j++) {
        value = ref[j];
        if (!value.type) {
          throw Error('Required Property: "type"');
        }
        if (!handlers[value.type]) {
          // throw Error "Required Property: match" unless value.match
          throw Error(
            `Unsupported Affinity Type: got ${JSON.stringify(
              value.type
            )}, accepted values are ${JSON.stringify(
              Object.keys(handlers)
            )}`
          );
        }
        handlers[value.type].normalize(value);
      }
      return config;
    },
    resolve: function (config, affinity) {
      var j, len, matchednodes, nodeids, ref, value;
      nodeids = Object.values(config.nodes).map(function (node) {
        return {
          subject: node.id,
        };
      });
      matchednodes = [];
      ref = affinity.values;
      for (j = 0, len = ref.length; j < len; j++) {
        value = ref[j];
        matchednodes.push(
          handlers[value.type].resolve(config, value)
        );
      }
      // matchednodes = flatten matchednodes
      return match[affinity.match || "all"](matchednodes, nodeids);
    },
  },
  tags: {
    normalize: function (config) {
      var j, k, len, len1, ref, ref1, tag, tconfig, value, values;
      if (!config.values) {
        throw Error('Required Property: "values" not found');
      }
      if (!is_object(config.values)) {
        throw Error('Invalid Property: "values", expect an object');
      }
      ref = config.values;
      for (tag in ref) {
        tconfig = ref[tag];
        if (!(is_object(tconfig) || Array.isArray(tconfig))) {
          tconfig = config.values[tag] = {
            values: [tconfig],
          };
        }
        if (Array.isArray(tconfig)) {
          tconfig = config.values[tag] = {
            values: tconfig,
          };
        }
        if (Array.isArray(tconfig.values)) {
          values = tconfig.values;
          tconfig.values = {};
          for (j = 0, len = values.length; j < len; j++) {
            value = values[j];
            if (typeof value !== "string") {
              throw Error(
                `Invalid Property: \"values\", expect a string, got ${value}`
              );
            }
            tconfig.values[value] = true;
          }
        }
        if (Object.keys(tconfig.values).length > 1 && !tconfig.match) {
          // Validation
          throw Error('Required Property: "match", when more than one value');
        }
        ref1 = tconfig.values;
        for (k = 0, len1 = ref1.length; k < len1; k++) {
          value = ref1[k];
          throw Error('Invalid Property: "value", must be true');
        }
      }
      if (Object.keys(config.values).length > 1 && !config.match) {
        // Validation
        throw Error('Required Property: "match", when more than one tag');
      }
      return config;
    },
    resolve: function (config, affinity) {
      var matchednodes, name, nodeids, ref, tag, tests, values;
      // fqdns = Object.values(config.nodes).map( (node) -> node.fqdn)
      matchednodes = [];
      ref = affinity.values;
      for (name in ref) {
        tag = ref[name];
        values = Object.keys(tag.values);
        tests = Object.values(config.nodes).map(function (node, i) {
          var ref1;
          return {
            output: node.id,
            subject:
              (ref1 = config.nodes[node.id].tags) != null
                ? ref1[name]
                : void 0,
          };
        });
        // .filter (node) -> node.subject
        matchednodes.push(match[tag.match || "all"](values, tests));
      }
      nodeids = Object.values(config.nodes).map(function (node) {
        return {
          subject: node.id,
        };
      });
      return match[affinity.match || "all"](matchednodes, nodeids);
    },
  },
  services: {
    normalize: function (config) {
      var j, len, service, services;
      if (!config.values) {
        throw Error('Required Property: "values" not found');
      }
      if (typeof config.values === "string") {
        config.values = [config.values];
      }
      if (Array.isArray(config.values)) {
        services = config.values;
        config.values = {};
        for (j = 0, len = services.length; j < len; j++) {
          service = services[j];
          if (typeof service !== "string") {
            throw Error('Invalid Property: "service" expect a string');
          }
          config.values[service] = true;
        }
      }
      return config;
    },
    resolve: function (config, affinity) {
      return console.log("todo");
    },
  },
  nodes: {
    normalize: function (config) {
      var j, len, node, nodes;
      if (!config.values) {
        throw Error('Required Property: "values" not found');
      }
      if (typeof config.values === "string") {
        config.values = [config.values];
      }
      if (Array.isArray(config.values)) {
        nodes = config.values;
        config.values = {};
        for (j = 0, len = nodes.length; j < len; j++) {
          node = nodes[j];
          if (typeof node !== "string") {
            throw Error('Invalid Property: "node", expect a string');
          }
          config.values[node] = true;
        }
      }
      if (Object.keys(config.values).length > 1 && !config.match) {
        throw Error('Required Property: "match", when more than one values');
      }
      return config;
    },
    resolve: function (config, affinity) {
      var fqdns;
      fqdns = Object.values(config.nodes).map(function (node) {
        return {
          subject: node.fqdn,
        };
      });
      return match[affinity.match || "all"](
        Object.keys(affinity.values),
        fqdns
      );
    },
  },
};

export default {
  nodes: nodes,
  services: services,
  handlers: handlers,
};

match = {
  // Return any subject which match all the left values
  all: function (values, tests) {
    return tests
      .filter(function (test) {
        var j, len, ok, subject, value;
        ({ subject } = test);
        if (!subject) {
          return false;
        }
        if (typeof subject === "string") {
          subject = [subject];
        }
        ok = true;
        for (j = 0, len = values.length; j < len; j++) {
          value = values[j];
          if (typeof value === "string") {
            value = [value];
          }
          if (!any(value, subject)) {
            ok = false;
          }
        }
        // ok = false unless value in subject
        return ok;
      })
      .map(function (test) {
        return test.output || test.subject;
      });
  },
  // Return any subject which match at least one left values
  any: function (values, tests) {
    return tests
      .filter(function (test) {
        var j, len, subject, value;
        ({ subject } = test);
        if (!subject) {
          return false;
        }
        if (typeof subject === "string") {
          subject = [subject];
        }
        for (j = 0, len = values.length; j < len; j++) {
          value = values[j];
          if (typeof value === "string") {
            value = [value];
          }
          if (any(value, subject)) {
            return true;
          }
        }
        return false;
      })
      .map(function (test) {
        return test.output || test.subject;
      });
  },
  // Return any subject which match no left values
  none: function (values, tests) {
    return tests
      .filter(function (test) {
        var j, len, subject, value;
        ({ subject } = test);
        if (typeof subject === "string") {
          subject = [subject];
        }
        for (j = 0, len = values.length; j < len; j++) {
          value = values[j];
          if (typeof value === "string") {
            value = [value];
          }
          if (any(value, subject)) {
            return false;
          }
        }
        return true;
      })
      .map(function (test) {
        return test.output || test.subject;
      });
  },
};

any = function (a, b) {
  var aa, j, len;
  for (j = 0, len = a.length; j < len; j++) {
    aa = a[j];
    if (indexOf.call(b, aa) >= 0) {
      return true;
    }
  }
  return false;
};

is_object = function (obj) {
  return obj && typeof obj === "object" && !Array.isArray(obj);
};
