
import secrets from 'masson/secrets';

import get from 'lodash.get';

import yaml from 'js-yaml';

export default async function({params}, config) {
  var data, err, i, len, property, ref, store, value;
  store = secrets(params);
  if (!(await store.exists())) {
    return process.stderr.write(['Store does not exists, ', 'run the `init` command to initialize it.\n'].join(''));
  }
  ref = params.properties;
  for (i = 0, len = ref.length; i < len; i++) {
    property = ref[i];
    value = (await store.get(property));
    if (!value) {
      process.stderr.write(`Property \"${property}\" does not exist.` + '\n');
      return;
    }
    try {
      data = (await store.unset(property));
      process.stderr.write(`Property \"${property}\" removed.` + '\n');
    } catch (error) {
      err = error;
      process.stderr.write(`${err.message}` + '\n');
      throw err;
    }
  }
};
