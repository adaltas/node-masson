
import path from 'path';
import util from 'node:util';
import CSON from 'cson';
import string from '@nikitajs/core/utils/string';
import store from 'masson/config/store';

// ./bin/ryba graph -o output_file -p JSON
export default function({params, stdout}, config) {
  if (params.output == null) {
    params.output = 'export';
  }
  params.output = path.resolve(process.cwd(), params.output);
  if (typeof params.hosts === 'string') {
    params.hosts = [params.hosts];
  }
  // Print host cfg on path
  const print = function(config) {
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
    return stdout.write(config);
  };
  const s = store(config);
  if (params.nodes) {
    if (params.format) {
      const output = config.graph.map( service_name => {
        const [cname, sname] = service_name.split(':');
        const service = config.clusters[cname].services[sname];
        return {
          cluster: service.cluster,
          id: service.id,
          module: service.module,
          nodes: service.instances.map(function(instance) {
            return instance.node.id;
          })
        };
      })
      print(output);
    } else {
      const data = []
      for (const service_name of config.graph) {
        const [cname, sname] = service_name.split(':');
        const service = config.clusters[cname].services[sname];
        data.push([`* ${service.cluster}:${service.id}`, service.id !== service.module ? ` (${service.module})` : void 0, '\n'].join(''));
        for (const instance of service.instances) {
          data.push(`  * ${instance.node.id}\n`);
        }
        data.push('\n');
      }
      stdout.write(data.join(''))
    }
  } else {
    print(config.graph);
  }
};
