
export default ({writer}) ->
  try
    await @grpc_stop()
    writer.write 'Server is stopped\n'
  catch err
    writer.write 'Error: ' + err.message + '\n'
  writer.end()
  
