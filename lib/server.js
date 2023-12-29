import { exec } from "child_process";
import dedent from "dedent";

export default {
  start: function (options, callback) {
    var bin;
    bin = require.resolve("http-server/bin/http-server");
    return exec(
      dedent`set -e
      [ ! -d '${options.directory}' ] && exit 5
      if [ -f ${options.pidfile} ] ; then
        pid=\`cat ${options.pidfile}\`
        kill -0 $pid && exit 3
        # Pid file exists but reference a non running process
        rm -f ${options.pidfile}
      fi
      # Check if port is open
      bash -c "echo > '/dev/tcp/localhost/${options.port}'" && exit 4
      ${bin} '${options.directory}' -p '${options.port}' -d -i >/dev/null 2>&1 &
      echo $! > ${options.pidfile}
      `,
      function (err) {
        var started;
        if (!err) {
          started = true;
        }
        if ((err != null ? err.code : void 0) === 3) {
          err = null;
          started = false;
        }
        return callback(err, started);
      }
    );
  },
  stop: function (options, callback) {
    return exec(
      `set -e
[ ! -f ${options.pidfile} ] && exit 3
pid=\`cat ${options.pidfile}\`
if ! kill -0 $pid ; then
  rm -f ${options.pidfile}
  exit 0
fi
kill $pid
rm -f ${options.pidfile}`,
      function (err) {
        var stopped;
        if (!err) {
          stopped = true;
        }
        if ((err != null ? err.code : void 0) === 3) {
          err = null;
          stopped = false;
        }
        return callback(err, stopped);
      }
    );
  },
  status: function (options, callback) {
    return exec(
      `set -e
[ ! -f ${options.pidfile} ] && exit 1
pid=\`cat ${options.pidfile}\`
( ! kill -0 $pid ) && exit 1
exit 0`,
      function (err, stdout, stderr) {
        return callback(null, !err);
      }
    );
  },
};
