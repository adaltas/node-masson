
import path from 'path';
import nikita from 'nikita';
import each from 'each';
import store from 'masson/config/store';
import multimatch from 'masson/utils/multimatch';

import {
  merge
} from 'mixme';

import array_get from 'masson/utils/array_get';

export default function({params}, config) {
  var command, i, key, len, ref, s, tag, value;
  command = params.command.slice(-1)[0];
  ref = params.tags || {};
  for (i = 0, len = ref.length; i < len; i++) {
    tag = ref[i];
    [key, value] = tag.split('=');
    if (!value) {
      throw Error("Invalid usage, expected --tags key=value");
    }
  }
  s = store(config);
  return each(s.nodes(), true, async function(node) {
    var j, len1, log, n, ref1, services;
    ref1 = params.tags || {};
    for (j = 0, len1 = ref1.length; j < len1; j++) {
      tag = ref1[j];
      [key, value] = tag.split('=');
      if (multimatch(node.tags[key] || [], value.split(',')).length === 0) {
        return;
      }
    }
    if (params.nodes && multimatch([node.ip, node.fqdn, node.hostname], params.nodes).length === 0) {
      return;
    }
    // Get filtered services
    // Filtering based on module name
    services = node.services.filter(function(service) {
      return (!params.modules || multimatch(service.module, params.modules).length) && (!params.cluster || multimatch(service.cluster, params.cluster).length);
    // Keep only service with a matching command
    }).filter(function(service) {
      return s.service(service.cluster, service.service).commands[command];
    });
    if (!services.length) {
      return;
    }
    log = {};
    if (log.basedir == null) {
      log.basedir = './log';
    }
    log.basedir = path.resolve(process.cwd(), log.basedir);
    config.nikita.no_ssh = true;
    n = nikita(merge(config.nikita));
    await n.log.cli({
      host: node.fqdn,
      pad: {
        host: 20,
        header: 60
      }
    });
    await n.log.md({
      basename: node.hostname,
      basedir: log.basedir,
      archive: false
    });
    await n.ssh.open({
      $header: 'SSH Open',
      host: node.ip || node.fqdn
    }, node.ssh);
    // Call the plugin of every service, discard filtering
    n.call(function() {
      var instance, k, len2, ref2, results, service;
      ref2 = node.services;
      results = [];
      for (k = 0, len2 = ref2.length; k < len2; k++) {
        service = ref2[k];
        service = s.service(service.cluster, service.service);
        if (!service.plugin) {
          continue;
        }
        instance = array_get(service.instances, function(instance) {
          return instance.node.id === node.id;
        });
        results.push(n.call(service.plugin, merge(instance.options)));
      }
      return results;
    });
    // Call the command of the filtered services
    return n.call(function() {
      var instance, isRoot, k, len2, module, results, service;
      results = [];
      for (k = 0, len2 = services.length; k < len2; k++) {
        service = services[k];
        service = s.service(service.cluster, service.service);
        // Retrieve the service instance associated with this node
        instance = array_get(service.instances, function(instance) {
          return instance.node.id === node.id;
        });
        results.push((function() {
          var l, len3, ref2, results1;
          ref2 = service.commands[command];
          // Call each registered module
          results1 = [];
          for (l = 0, len3 = ref2.length; l < len3; l++) {
            module = ref2[l];
            isRoot = config.nikita.ssh.username === 'root' || !config.nikita.ssh.username;
            results1.push(n.call(module, merge(instance.options, {
              sudo: !isRoot
            })));
          }
          return results1;
        })());
      }
      return results;
    });
  }).catch(function(err) {
    var j, len1, ref1, results;
    if (!err.errors) {
      return process.stderr.write(`\n${err.stack}\n`);
    } else {
      ref1 = err.errors;
      results = [];
      for (j = 0, len1 = ref1.length; j < len1; j++) {
        err = ref1[j];
        results.push(process.stderr.write(`\n${err.stack}\n`));
      }
      return results;
    }
  });
};

// throw err
