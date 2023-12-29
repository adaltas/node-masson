
import path from 'path';

import nikita from 'nikita';

// `./bin/ryba pki --dir ./conf/certs cacert-view`
export default async function({params, stderr, stdout}) {
  const cacert_path = path.resolve(params.dir, 'ca.cert.pem');
  const {code, stdout: cmdStdout, stderr: cmdStderr} = await nikita.execute({
    relax: true
  }, `openssl x509 -in ${cacert_path} -text`);
  if (code !== 0) {
    stderr.write('\n' + cmdStderr + '\n\n');
    return process.exit(code);
  } else {
    return stdout.write('\n' + cmdStdout + '\n\n');
  }
};
