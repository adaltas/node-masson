
import secrets from 'masson/secrets';

import get from 'lodash.get';

import yaml from 'js-yaml';

import util from 'node:util';

export default async function({params}, config) {
  var err, i, len, output, property, ref, results, store;
  store = secrets(params);
  if (!(await store.exists())) {
    return process.stderr.write(['Store does not exists, ', 'run the `init` command to initialize it.\n'].join(''));
  }
  secrets = (await store.get());
  ref = params.properties;
  results = [];
  for (i = 0, len = ref.length; i < len; i++) {
    property = ref[i];
    try {
      secrets = get(secrets, property);
      if (!secrets) {
        results.push(process.stderr.write("Property does not exists" + '\n'));
      } else {
        if (typeof secrets === 'string') {
          results.push(process.stdout.write(`${secrets}` + '\n'));
        } else {
          output = (function() {
            switch (params.format) {
              case 'json':
                return JSON.stringify(secrets);
              case 'prettyjson':
                return util.inspect(secrets, {
                  colors: process.stdout.isTTY,
                  depth: 2e308
                });
              case 'yaml':
                return yaml.dump(secrets);
            }
          })();
          results.push(process.stdout.write(`${output}` + '\n'));
        }
      }
    } catch (error) {
      err = error;
      results.push(process.stderr.write(`${err.message}` + '\n'));
    }
  }
  return results;
};
