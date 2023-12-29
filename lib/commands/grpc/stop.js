
export default async function({writer}) {
  var err;
  try {
    await this.grpc_stop();
    writer.write('Server is stopped\n');
  } catch (error) {
    err = error;
    writer.write('Error: ' + err.message + '\n');
  }
  return writer.end();
};
