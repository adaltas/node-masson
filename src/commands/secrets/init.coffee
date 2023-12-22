
import secrets from 'masson/secrets/index'

export default ({params}, config) ->
  store = secrets params
  return process.stderr.write [
    'Store already exists, '
    'please remove it before initializing it.\n'
  ].join '' if await store.exists()
  try
    await store.init()
    process.stderr.write "Secret store is ready at \"#{params.store}\"." + '\n'
  catch err
    process.stderr.write "#{err.message}" + '\n'
