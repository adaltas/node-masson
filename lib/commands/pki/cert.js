
import path from 'path';

import nikita from 'nikita';

// `./bin/ryba pki --dir ./conf/certs cert {fqdn}`
export default async function({params}, config, callback) {
  var cacert_path, cakey_path, caserial_path, cert_path, code, csr_path, key_path, shortname, stderr, stdout, subject;
  cakey_path = path.resolve(params.dir, 'ca.key.pem');
  cacert_path = path.resolve(params.dir, 'ca.cert.pem');
  caserial_path = path.resolve(params.dir, 'ca.seq');
  shortname = params.fqdn.split('.')[0];
  csr_path = path.resolve(params.dir, `${shortname}.cert.csr`);
  key_path = path.resolve(params.dir, `${shortname}.key.pem`);
  cert_path = path.resolve(params.dir, `${shortname}.cert.pem`);
  subject = `/C=FR/O=Adaltas/L=Paris/CN=${params.fqdn}`;
  ({code, stdout, stderr} = (await nikita.execute({
    relax: true
  }, `fqdn='${params.fqdn}'
shortname='${shortname}'
if [ ! -f ${cacert_path} ]; then echo 'Run \`./generate.sh cacert\` first.'; exit 1; fi
# Certificate signing request (CSR) and private key (create "{hostname}.cert.csr" and "{hostname}.key.pem")
openssl req -newkey rsa:2048 -sha256 -nodes -out ${csr_path} -keyout ${key_path} -subj '${subject}'
# to view the CSR: \`openssl req -in {hostname}.cert.csr -noout -text\`
# Sign the CSR (create "hadoop.cert.pem")
openssl x509 -req -sha256 -days 7300 -in ${csr_path} -CA ${cacert_path} -CAkey ${cakey_path} -out ${cert_path} -CAcreateserial -CAserial ${caserial_path}
# Clean up
rm -rf '${csr_path}'`)));
  if (code !== 0) {
    process.stderr.write('\n' + stderr + '\n\n');
    return process.exit(code);
  }
};
