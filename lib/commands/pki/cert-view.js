
import path from 'path';

import nikita from 'nikita';

// `./bin/ryba pki --dir ./conf/certs cert-view {fqdn}`
export default async function({params}, config, callback) {
  var cert_path, code, shortname, stderr, stdout;
  shortname = params.fqdn.split('.')[0];
  cert_path = path.resolve(params.dir, `${shortname}.cert.pem`);
  ({code, stdout, stderr} = (await nikita.execute({
    relax: true
  }, `shortname='${shortname}'
openssl x509 -in ${cert_path} -text`)));
  if (code !== 0) {
    process.stderr.write('\n' + stderr + '\n\n');
    return process.exit(code);
  } else {
    return process.stdout.write('\n' + stdout + '\n\n');
  }
};
