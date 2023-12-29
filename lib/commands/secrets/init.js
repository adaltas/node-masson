
import secrets from 'masson/secrets';

export default async function({params}, config) {
  var err, store;
  store = secrets(params);
  if ((await store.exists())) {
    return process.stderr.write(['Store already exists, ', 'please remove it before initializing it.\n'].join(''));
  }
  try {
    await store.init();
    return process.stderr.write(`Secret store is ready at \"${params.store}\".` + '\n');
  } catch (error) {
    err = error;
    return process.stderr.write(`${err.message}` + '\n');
  }
};
