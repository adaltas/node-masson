
export default ({writer}) ->
  try
    await @grpc_start()
    writer.write 'Server is started\n'
  catch err
    writer.write 'Error: ' + err.message + '\n'
  writer.end()
  
