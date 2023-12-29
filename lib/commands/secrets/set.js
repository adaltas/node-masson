
import secrets from 'masson/secrets';

import get from 'lodash.get';

export default async function({params}, config) {
  var data, password, password_generated, property, store, store_password, value;
  store = secrets(params);
  if (!(await store.exists())) {
    return process.stderr.write(['Store does not exists, ', 'run the `init` command to initialize it.\n'].join(''));
  }
  ({data} = (await store.get()));
  // Secret already set, need the overwrite option
  [property, password] = params.property;
  password_generated = false;
  value = get(data, property);
  if (value && !params.overwrite) {
    process.stderr.write("Fail to save existing secret, use the \"overwrite\" option." + '\n');
    return callback();
  }
  store_password = async function(password) {
    var err;
    try {
      await store.set(property, password);
      process.stderr.write("Secret store updated." + '\n');
      if (password_generated) {
        return process.stdout.write(password + '\n');
      }
    } catch (error) {
      err = error;
      return process.stderr.write(`${err.message}` + '\n');
    }
  };
  // Provided as argument
  if (password) {
    return store_password(password);
  } else {
    // Provided generated
    if (process.stdin.isTTY) {
      password_generated = true;
      password = store.password();
      return store_password(password);
    } else {
      // Obtained from stdin
      password = '';
      process.stdin.on('data', function(chunk) {
        return password += chunk;
      });
      return process.stdin.on('end', function() {
        return store_password(password);
      });
    }
  }
};
