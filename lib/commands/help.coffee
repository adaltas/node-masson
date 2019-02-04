
module.exports = (params, config, callback = ->) ->
  process.stdout.write @help params
  callback()
  
