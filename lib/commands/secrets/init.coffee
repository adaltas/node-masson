
secrets = require '../../secrets'

module.exports = ({params}, config, callback) ->
  store = secrets params
  store.exists (err, exists) ->
    if exists
      process.stderr.write "Secret store is already initialised at \"#{params.store}\"." + '\n'
    else
      store.init (err) ->
        if err
          process.stderr.write "#{err.message}" + '\n'
        else
          process.stderr.write "Secret store is ready at \"#{params.store}\"." + '\n'
        callback()
