
module.exports = ({writer}) ->
  started = @grpc_started()
  writer.write if started then 'started\n' else 'stopped\n'
  writer.end()
  
