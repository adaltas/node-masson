
import path from 'node:path';
import dedent from 'dedent';
import nikita from 'nikita';

export default async function({params, stdout, stderr}) {
  var cacert_path, cakey_path, output, subject;
  cakey_path = path.resolve(params.dir, 'ca.key.pem');
  cacert_path = path.resolve(params.dir, 'ca.cert.pem');
  subject = '/C=FR/O=Adaltas/L=Paris/CN=adaltas.com';
  const {code, stderr:cmdStderr} = await nikita.execute({
    relax: true
  }, dedent`
    if [ ! -d '${params.dir}' ]; then >&2 echo -n 'Output directory does not exist'; exit 1; fi
    if [ -f '${cakey_path}' ]; then >&2 echo -n 'CA Certiticate already exists'; exit 1; fi
    # RSA Private key (create "ca.key.pem")
    openssl genrsa -out '${cakey_path}' 2048
    # Self-signed (with the key previously generated) root CA certificate (create "ca.cert.pem")
    openssl req -x509 -new -sha256 -key '${cakey_path}' -days 7300 -out '${cacert_path}' -subj '${subject}'
  `);
  if (code !== 0) {
    stderr.write('\n' + cmdStderr + '\n\n');
    return process.exit(code);
  } else {
    output = dedent`
      Certificate files generated:
      * Key: "${cakey_path}"
      * Certificate: "${cacert_path}"
      * Subject: "${subject}"
    `;
    return stdout.write('\n' + `${output}` + '\n\n');
  }
};
