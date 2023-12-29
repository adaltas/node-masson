
export default async function({writer}) {
  var err;
  try {
    await this.grpc_start();
    writer.write('Server is started\n');
  } catch (error) {
    err = error;
    writer.write('Error: ' + err.message + '\n');
  }
  return writer.end();
};
