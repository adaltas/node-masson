
export default function({writer}) {
  var started;
  started = this.grpc_started();
  writer.write(started ? 'started\n' : 'stopped\n');
  return writer.end();
};
