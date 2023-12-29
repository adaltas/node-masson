var is_object,
  indexOf = [].indexOf;
import tsort from "tsort";
import { merge, mutate } from "mixme";
import load from "masson/utils/load";
import affinities from "masson/config/affinities";

export default async function (config) {
  var _,
    affinity,
    base,
    cluster,
    cmdname,
    cname,
    command,
    dep,
    deps,
    discover_service,
    dname,
    dservice,
    err,
    found,
    graph,
    i,
    inject,
    instance,
    j,
    k,
    l,
    len,
    len1,
    len10,
    len11,
    len12,
    len2,
    len3,
    len4,
    len5,
    len6,
    len7,
    len8,
    len9,
    m,
    mod,
    n,
    nname,
    node,
    nodeId,
    node_services,
    nodeids,
    noptions,
    o,
    p,
    q,
    r,
    ref,
    ref1,
    ref10,
    ref11,
    ref12,
    ref13,
    ref14,
    ref15,
    ref16,
    ref17,
    ref18,
    ref19,
    ref2,
    ref20,
    ref21,
    ref22,
    ref23,
    ref24,
    ref25,
    ref26,
    ref27,
    ref28,
    ref29,
    ref3,
    ref30,
    ref4,
    ref5,
    ref6,
    ref7,
    ref8,
    ref9,
    s,
    sdep,
    service,
    services,
    sid,
    sname,
    srv,
    t,
    u,
    v,
    values;
  if (config.clusters != null && !is_object(config.clusters)) {
    return Promise.reject(
      Error(
        `Invalid Clusters: expect an object, got ${JSON.stringify(
          config.clusters
        )}`
      )
    );
  }
  if (config.services != null && !is_object(config.services)) {
    return Promise.reject(
      Error(
        `Invalid Services: expect an object, got ${JSON.stringify(
          config.services
        )}`
      )
    );
  }
  if (config.nodes != null && !is_object(config.nodes)) {
    return Promise.reject(
      Error(
        `Invalid Nodes: expect an object, got ${JSON.stringify(config.nodes)}`
      )
    );
  }
  if (config.params == null) {
    config.params = {};
  }
  if (config.clusters == null) {
    config.clusters = {};
  }
  if (config.nodes == null) {
    config.nodes = {};
  }
  discover_service = async function (cname, sname, service) {
    var dcluster,
      did,
      dname,
      dservice,
      externalModDef,
      modulename,
      ref,
      searchname,
      searchservice,
      sids;
    if (service === true) {
      service = config.clusters[cname].services[sname] = {};
    }
    if (service.module == null) {
      service.module = sname;
    }
    // Load service module
    externalModDef = await load(service.module);
    if (!is_object(externalModDef)) {
      return Promise.reject(
        Error(
          `Invalid Service Definition: expect an object for module ${JSON.stringify(
            service.module
          )}, got ${JSON.stringify(typeof externalModDef)}`
        )
      );
    }
    mutate(service, externalModDef);
    // Define auto loaded services
    if (service.deps == null) {
      service.deps = {};
    }
    ref = service.deps;
    for (dname in ref) {
      dservice = ref[dname];
      if (typeof dservice === "string") {
        dservice = service.deps[dname] = {
          module: dservice,
        };
      }
      // Id
      if (dservice.service) {
        [did, dcluster] = dservice.service.split(":").reverse();
      }
      if (dservice.cluster == null) {
        dservice.cluster = dcluster || cluster.id;
      }
      dservice.service = did || null;
      if (!(dservice.service || dservice.module)) {
        // Module
        return Promise.reject(
          Error("Unidentified Dependency: require module or service property")
        );
      }
      // Attempt to set service name by matching module name
      if (!dservice.service) {
        sids = (function () {
          var ref1, results;
          ref1 = config.clusters[dservice.cluster].services;
          results = [];
          for (searchname in ref1) {
            searchservice = ref1[searchname];
            modulename = searchservice.module || searchname;
            if (modulename !== dservice.module) {
              continue;
            }
            results.push(searchservice.id || searchname);
          }
          return results;
        })();
        if (sids.length > 1) {
          return Promise.reject(
            Error(
              `Invalid Service Reference: multiple matches for module ${JSON.stringify(
                dservice.module
              )} in cluster ${JSON.stringify(dservice.cluster)}`
            )
          );
        }
        if (sids.length === 1) {
          dservice.service = sids[0];
        }
      }
      // Auto
      if (
        dservice.auto &&
        !dservice.disabled &&
        !config.clusters[dservice.cluster].services[dservice.service]
      ) {
        if (dservice.service) {
          return Promise.reject(
            Error("Not sure if dservice.service can even exist here")
          );
        }
        dservice.service = dservice.module;
        dservice = {
          id: dservice.service,
          cluster: dservice.cluster,
          module: dservice.module,
        };
        config.clusters[dservice.cluster].services[dservice.id] = dservice;
        await discover_service(dservice.cluster, dservice.id, dservice);
      }
    }
  };
  ref = config.clusters;
  // Initial cluster and service normalization
  for (cname in ref) {
    cluster = ref[cname];
    if (cluster === true) {
      cluster = config.clusters[cname] = {};
    }
    cluster.id = cname;
    if (!is_object(cluster)) {
      return Promise.reject(
        Error(
          `Invalid Cluster: expect an object, got ${JSON.stringify(cluster)}`
        )
      );
    }
    if (cluster.services == null) {
      cluster.services = {};
    }
    ref1 = cluster.services;
    // Load module and extends current service definition
    for (sname in ref1) {
      service = ref1[sname];
      await discover_service(cname, sname, service);
    }
  }
  ref2 = config.clusters;
  // Normalize service
  for (cname in ref2) {
    cluster = ref2[cname];
    ref3 = cluster.services;
    for (sname in ref3) {
      service = ref3[sname];
      service.id = sname;
      service.cluster = cname;
      if (service.affinity == null) {
        service.affinity = [];
      }
      if (is_object(service.affinity)) {
        service.affinity = [service.affinity];
      }
      ref4 = service.affinity;
      for (j = 0, len = ref4.length; j < len; j++) {
        affinity = ref4[j];
        if (affinity.type == null) {
          affinity.type = "generic";
        }
        try {
          if (!affinities.handlers[affinity.type]) {
            return Promise.reject(
              Error(
                `Unsupported Affinity Type: got ${
                  affinity.type
                }, accepted values are ${JSON.stringify(
                  Object.keys(affinities.handlers)
                )}`
              )
            );
          }
          affinities.handlers[affinity.type].normalize(affinity);
        } catch (error) {
          err = error;
          err.message += ` in service ${JSON.stringify(
            sname
          )} of cluster ${JSON.stringify(cname)}`;
          return Promise.reject(err);
        }
      }
      // Normalize commands
      if (service.commands == null) {
        service.commands = {};
      }
      ref5 = service.commands;
      for (cmdname in ref5) {
        command = ref5[cmdname];
        if (!Array.isArray(command)) {
          command = service.commands[cmdname] = [command];
        }
        for (k = 0, len1 = command.length; k < len1; k++) {
          mod = command[k];
          if (
            !(
              (ref6 = typeof mod) === "string" ||
              ref6 === "function" ||
              is_object(mod)
            )
          ) {
            return Promise.reject(
              Error(
                `Invalid Command: accept array, string or function, got ${JSON.stringify(
                  mod
                )} for command ${JSON.stringify(cmdname)}`
              )
            );
          }
        }
      }
      // Default empty node list
      if (service.nodes == null) {
        service.nodes = {};
      }
      service.instances = [];
    }
  }
  ref7 = config.clusters;
  // for snodeid, snode of service.nodes
  //   return Promise.reject Error "Invalid Node Id" if snode.id and snode.id isnt snodeid
  //   snode.id = snodeid
  // Dependencies
  for (cname in ref7) {
    cluster = ref7[cname];
    ref8 = cluster.services;
    for (sname in ref8) {
      service = ref8[sname];
      ref9 = service.deps;
      for (dname in ref9) {
        dservice = ref9[dname];
        // If cluster isnt found, throw an error if required or disable the dependency
        if (!config.clusters[dservice.cluster]) {
          if (dservice.required) {
            return Promise.reject(
              Error(
                `Invalid Cluster Reference: cluster ${JSON.stringify(
                  dservice.cluster
                )} is not defined`
              )
            );
          } else {
            dservice.disabled = true;
            continue;
          }
        }
        if (config.clusters[dservice.cluster].services[dservice.service]) {
          if (dservice.disabled == null) {
            dservice.disabled = false;
          }
        } else {
          if (dservice.required) {
            if (dservice.service) {
              return Promise.reject(
                Error(
                  `Required Dependency: unsatisfied dependency ${JSON.stringify(
                    dname
                  )} in service ${JSON.stringify(
                    [service.cluster, service.id].join(":")
                  )}, service ${JSON.stringify(
                    dservice.service
                  )} in cluster ${JSON.stringify(
                    dservice.cluster
                  )} is not defined`
                )
              );
            } else {
              return Promise.reject(
                Error(
                  `Required Dependency: unsatisfied dependency ${JSON.stringify(
                    dname
                  )} in service ${JSON.stringify(
                    [service.cluster, service.id].join(":")
                  )}, module ${JSON.stringify(
                    dservice.module
                  )} in cluster ${JSON.stringify(
                    dservice.cluster
                  )} is not defined`
                )
              );
            }
          } else {
            if (dservice.disabled == null) {
              dservice.disabled = true;
            }
          }
        }
      }
    }
  }
  ref10 = config.nodes;
  // Normalize nodes
  for (nname in ref10) {
    node = ref10[nname];
    if (node === true) {
      node = config.nodes[nname] = {};
    }
    if (node.id == null) {
      node.id = nname;
    }
    if (node.fqdn == null) {
      node.fqdn = nname;
    }
    if (node.hostname == null) {
      node.hostname = nname.split(".").shift();
    }
    if (node.services == null) {
      node.services = [];
    }
    // Convert services to an array
    if (is_object(node.services)) {
      node.services = (function () {
        var ref11, results;
        ref11 = node.services;
        results = [];
        for (sid in ref11) {
          service = ref11[sid];
          [cname, sname] = sid.split(":");
          results.push({
            cluster: cname,
            service: sname,
            options: service,
          });
        }
        return results;
      })();
    }
    ref11 = node.services;
    // Validate service registration
    for (l = 0, len2 = ref11.length; l < len2; l++) {
      service = ref11[l];
      if (service.service) {
        if (!config.clusters[service.cluster].services[service.service]) {
          return Promise.reject(
            Error(
              `Node Invalid Service: node ${JSON.stringify(
                node.id
              )} references missing service ${JSON.stringify(
                service.service
              )} in cluster ${JSON.stringify(service.cluster)}`
            )
          );
        }
      }
    }
  }
  // Graph ordering
  graph = tsort();
  ref12 = config.clusters;
  for (cname in ref12) {
    cluster = ref12[cname];
    ref13 = cluster.services;
    for (sname in ref13) {
      service = ref13[sname];
      graph.add(`${cname}:${sname}`);
      ref14 = service.deps;
      for (_ in ref14) {
        dservice = ref14[_];
        if (dservice.service === sname) {
          continue;
        }
        if (dservice.disabled) {
          continue;
        }
        graph.add(
          `${dservice.cluster}:${dservice.service}`,
          `${cname}:${sname}`
        );
      }
    }
  }
  services = graph.sort();
  config.graph = services;
  ref15 = services.slice().reverse();
  // Affinity discovery
  for (m = 0, len3 = ref15.length; m < len3; m++) {
    service = ref15[m];
    [cname, sname] = service.split(":");
    service = config.clusters[cname].services[sname];
    if (service.affinity.length) {
      affinity =
        service.affinity.length > 1
          ? {
              type: "generic",
              match: "any",
              values: service.affinity || [],
            }
          : service.affinity[0];
      nodeids = affinities.handlers[affinity.type].resolve(config, affinity);
      ref16 = service.instances;
      for (n = 0, len4 = ref16.length; n < len4; n++) {
        instance = ref16[n];
        if (((ref17 = instance.node.id), indexOf.call(nodeids, ref17) < 0)) {
          return Promise.reject(
            Error(`No Affinity Found: ${instance.node.id}`)
          );
        }
      }
      for (o = 0, len5 = nodeids.length; o < len5; o++) {
        nodeId = nodeids[o];
        service.instances.push({
          id: nodeId,
          cluster: service.cluster,
          service: service.id,
          node: merge(config.nodes[nodeId]),
          options: service.nodes[nodeId] || {},
        });
      }
    }
    ref18 = service.instances;
    // service.nodes[nodeId] ?= {}
    // service.nodes[nodeId].id = nodeId
    // service.nodes[nodeId].cluster = service.cluster
    // service.nodes[nodeId].service = service.id
    // service.nodes[nodeId].node = merge config.nodes[nodeId]
    // service.nodes[nodeId].options ?= {}
    // Enrich service list in nodes
    for (p = 0, len6 = ref18.length; p < len6; p++) {
      instance = ref18[p];
      found = null;
      ref19 = config.nodes[instance.node.id].services;
      for (i = q = 0, len7 = ref19.length; q < len7; i = ++q) {
        srv = ref19[i];
        if (srv.cluster === cname && srv.service === sname) {
          found = i;
          break;
        }
      }
      if (found != null) {
        if (
          (base = config.nodes[instance.node.id].services[found]).module == null
        ) {
          base.module = service.module;
        }
        instance.node.services.push(
          merge(config.nodes[instance.node.id].services[found])
        );
      } else {
        config.nodes[instance.node.id].services.push({
          cluster: cname,
          service: sname,
          module: service.module,
        });
        instance.node.services.push({
          cluster: cname,
          service: sname,
          module: service.module,
        });
      }
    }
    ref20 = service.deps;
    // Enrich affinity for dependencies marked as auto
    for (dname in ref20) {
      dep = ref20[dname];
      if (!dep.auto) {
        continue;
      }
      if (dep.disabled) {
        continue;
      }
      sdep = config.clusters[dep.cluster].services[dep.service];
      values = {};
      ref21 = service.instances;
      for (r = 0, len8 = ref21.length; r < len8; r++) {
        instance = ref21[r];
        values[instance.node.id] = true;
      }
      sdep.affinity.push({
        type: "nodes",
        match: "any",
        values: values,
      });
    }
  }
  ref22 = config.nodes;
  // Re-order node services
  for (nname in ref22) {
    node = ref22[nname];
    node.services.sort(function (a, b) {
      return (
        services.indexOf(`${a.cluster}:${a.service}`) -
        services.indexOf(`${b.cluster}:${b.service}`)
      );
    });
  }
  ref23 = config.clusters;
  // Re-validate required dependency ensuring affinity is compatible with local
  for (cname in ref23) {
    cluster = ref23[cname];
    ref24 = cluster.services;
    for (sname in ref24) {
      service = ref24[sname];
      ref25 = service.deps;
      for (dname in ref25) {
        dep = ref25[dname];
        if (!(dep.local && dep.required)) {
          continue;
        }
        dservice = config.clusters[dep.cluster].services[dep.service];
        ref26 = service.instances;
        for (s = 0, len9 = ref26.length; s < len9; s++) {
          instance = ref26[s];
          if (
            ((ref27 = instance.node.id),
            indexOf.call(
              dservice.instances.map(function (instance) {
                return instance.node.id;
              }),
              ref27
            ) >= 0)
          ) {
            continue;
          }
          return Promise.reject(
            Error(
              `Required Local Dependency: service ${JSON.stringify(
                sname
              )} in cluster ${JSON.stringify(
                cname
              )} require service ${JSON.stringify(
                dep.service
              )} in cluster ${JSON.stringify(
                dep.cluster
              )} to be present on node ${instance.node.id}`
            )
          );
        }
      }
    }
  }
  // Enrich configuration
  for (t = 0, len10 = services.length; t < len10; t++) {
    service = services[t];
    [cname, sname] = service.split(":");
    service = config.clusters[cname].services[sname];
    ref28 = service.instances;
    // Load configuration
    for (u = 0, len11 = ref28.length; u < len11; u++) {
      instance = ref28[u];
      node = config.nodes[instance.node.id];
      // Get options from node
      node_services = node.services.filter(function (srv) {
        return srv.cluster === service.cluster && srv.service === service.id;
      });
      if (node_services.length > 1) {
        return Promise.reject(Error("Should never happen"));
      }
      noptions = node_services.length === 1 ? node_services[0].options : {};
      // Overwrite options from service.nodes
      // if service.nodes[node.id]
      //   options = merge options, service.nodes[node.id].options
      instance.options = merge(
        service.options,
        noptions,
        service.nodes[instance.node.id]
      );
    }
    ref29 = service.instances;
    // Load deps and run configure
    for (v = 0, len12 = ref29.length; v < len12; v++) {
      instance = ref29[v];
      node = config.nodes[instance.node.id];
      deps = {};
      ref30 = service.deps;
      for (dname in ref30) {
        dep = ref30[dname];
        if (dep.disabled) {
          // Handle not satisfied dependency
          continue;
        }
        // Get dependency service
        deps[dname] =
          config.clusters[dep.cluster].services[dep.service].instances;
        if (dep.single) {
          if (deps[dname].length !== 1) {
            return Promise.reject(
              Error(
                `Invalid Option: single only apply to 1 dependencies, found ${deps[dname].length}`
              )
            );
          }
          deps[dname] = deps[dname][0] || null;
        }
        if (dep.local) {
          if (dep.single) {
            deps[dname] = [deps[dname]];
          }
          deps[dname] = deps[dname].filter(function (dep) {
            return dep.id === node.id;
          });
          deps[dname] = deps[dname][0] || null;
        }
      }
      inject = {
        cluster: instance.cluster,
        service: instance.service,
        options: instance.options,
        instances: service.instances,
        node: merge(node),
        deps: deps,
      };
      if (service.configure) {
        try {
          if (typeof service.configure === "string") {
            service.configure = await load(service.configure);
          }
        } catch (error) {
          err = error;
          err.message += ` in service ${JSON.stringify(
            service.id
          )} of cluster ${JSON.stringify(service.cluster)}`;
          return Promise.reject(err);
        }
        if (typeof service.configure !== "function") {
          return Promise.reject(
            Error(
              `Invalid Configuration: not a function, got ${typeof service.configure}`
            )
          );
        }
        service.configure.call(null, inject);
      }
    }
  }
  // newinject = {}
  // for instance in service.instances
  //   continue unless instance.node.id is instance.
  // for k, v of service.nodes[instance.node.id]
  //   continue if k is 'deps'
  //   newinject[k] = v
  // service.instances[instance.node.id] = newinject
  return config;
}

is_object = function (obj) {
  return obj && typeof obj === "object" && !Array.isArray(obj);
};
