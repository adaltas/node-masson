
import server from 'masson/server';

export default function({params}, config) {
  return server.stop({
    pidfile: params.pidfile
  }, function(err, stopped) {
    if (err) {
      console.error('HTTP Server Kill Failed');
      process.exit(1);
    }
    if (stopped) {
      console.log('HTTP Server Stopped');
      return process.exit(0);
    } else {
      console.error('HTTP Server Already Stopped');
      return process.exit(3);
    }
  });
};
