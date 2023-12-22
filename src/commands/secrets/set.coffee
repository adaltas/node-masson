
import secrets from 'masson/secrets/index'
import get from 'lodash.get'

export default ({params}, config) ->
  store = secrets params
  return process.stderr.write [
    'Store does not exists, '
    'run the `init` command to initialize it.\n'
  ].join '' unless await store.exists()
  {data} = await store.get()
  # Secret already set, need the overwrite option
  [property, password] = params.property
  password_generated = false
  value = get data, property
  if value and not params.overwrite
    process.stderr.write "Fail to save existing secret, use the \"overwrite\" option." + '\n'
    return callback()
  store_password = (password) ->
    try
      await store.set property, password
      process.stderr.write "Secret store updated." + '\n'
      process.stdout.write password + '\n' if password_generated
    catch err
      process.stderr.write "#{err.message}" + '\n'
  # Provided as argument
  if password
    store_password password
  else
    # Provided generated
    if process.stdin.isTTY
      password_generated = true
      password = store.password()
      store_password password
    # Obtained from stdin
    else
      password = ''
      process.stdin.on 'data', (chunk) ->
        password += chunk
      process.stdin.on 'end', ->
        store_password password
