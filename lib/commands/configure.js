
import params from 'masson/params';

import path from 'path';

import util from 'node:util';

import CSON from 'cson';

import string from '@nikitajs/core/utils/string';

import load from 'masson/config/load';

import normalize from 'masson/config/normalize';

import store from 'masson/config/store';

// ./bin/ryba configure -o output_file -p JSON
export default function({params}, config) {
  var print, s;
  // EXAMPLE START
  if (params.output == null) {
    params.output = 'export';
  }
  // params.format ?= 'coffee'
  params.output = path.resolve(process.cwd(), params.output);
  if (typeof params.hosts === 'string') {
    params.hosts = [params.hosts];
  }
  // Print host cfg on path
  print = function(config) {
    var content;
    config = (function() {
      switch (params.format) {
        case 'cson':
          return CSON.stringify(config, null, 2);
        case 'json':
          return JSON.stringify(config, null, 2);
        case 'js':
          return `module.exports = ${JSON.stringify(config, null, 2)}`;
        case 'coffee':
          // adds 2 spaces to the stringified object for CSON indentation before writing it
          content = (string.lines(CSON.stringify(config, null, 2))).join("\n  ");
          return `module.exports =\n  ${content}`;
        default:
          return util.inspect(config, {
            depth: null,
            colors: true
          });
      }
    })();
    return process.stdout.write(config);
  };
  s = store(config);
  if (params.nodes) {
    return print(s.nodes());
  } else if (params.node) {
    return print(s.node(params.node));
  } else if (params.service) {
    if (!params.cluster) {
      throw Error(`Required Option: ${params.cluster}`);
    }
    return print(s.service(params.cluster, params.service));
  } else if (params.cluster) {
    return print(s.cluster(params.cluster));
  } else if (params.cluster_names) {
    return print(s.cluster_names());
  } else if (params.service_names) {
    return print(s.service_names());
  } else {
    return print(config);
  }
};
