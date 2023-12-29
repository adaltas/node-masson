
import server from 'masson/server';

export default function({params}, config) {
  return server.status({
    pidfile: params.pidfile
  }, function(err, started) {
    if (started) {
      console.error("HTTP Server Started");
      process.exit(0);
    } else {

    }
    console.error("HTTP Server Stopped");
    return process.exit(1);
  });
};
