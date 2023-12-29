
import server from 'masson/server';

export default function({params}, config) {
  return server.start({
    directory: params.directory,
    pidfile: params.pidfile,
    port: params.port
  }, function(err, started) {
    if (err) {
      switch (err.code) {
        case 4:
          console.error(`Port ${params.port} already used`);
          process.exit(4);
          break;
        case 5:
          console.error(`Directory ${params.directory} does not exists`);
          process.exit(5);
          break;
        default:
          console.log(`Unkown Error, exit code is ${err.code}`);
          process.exit(1);
      }
    }
    if (started) {
      console.log('HTTP Server Started');
      return process.exit(0);
    } else {
      console.error('HTTP Server Already Running');
      return process.exit(3);
    }
  });
};
