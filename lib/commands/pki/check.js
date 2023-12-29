
import path from 'path';

import nikita from 'nikita';

// `./bin/ryba pki --dir ./conf/certs check {fqdn}`
export default async function({params}, config, callback) {
  var cacert_path, cert_path, code, shortname, stderr, stdout;
  cacert_path = path.resolve(params.dir, 'ca.cert.pem');
  shortname = params.fqdn.split('.')[0];
  cert_path = path.resolve(params.dir, `${shortname}.cert.pem`);
  ({code, stdout, stderr} = (await nikita.execute({
    relax: true
  }, `if [ ! -f '${cacert_path}' ]; then >&2 echo -n 'Failed to locate the CA certificate'; exit 1; fi
if [ ! -f '${cert_path}' ]; then >&2 echo -n 'Failed to locate the file certificate'; exit 1; fi
openssl verify -CAfile '${cacert_path}' '${cert_path}'`)));
  if (code !== 0) {
    process.stderr.write('\n' + stderr + '\n\n');
    return process.exit(code);
  } else {
    return process.stdout.write('\n' + `${shortname}.cert.pem: OK` + '\n\n');
  }
};
