
path = require 'path'
nikita = require 'nikita'

# `./bin/ryba pki --dir ./conf/certs check {fqdn}`
module.exports = ({params}, config, callback) ->
  cacert_path = path.resolve params.dir, 'ca.cert.pem'
  shortname = params.fqdn.split('.')[0]
  cert_path = path.resolve params.dir, "#{shortname}.cert.pem"
  {code, stdout, stderr} = await nikita.execute relax: true, """
  if [ ! -f '#{cacert_path}' ]; then >&2 echo -n 'Failed to locate the CA certificate'; exit 1; fi
  if [ ! -f '#{cert_path}' ]; then >&2 echo -n 'Failed to locate the file certificate'; exit 1; fi
  openssl verify -CAfile '#{cacert_path}' '#{cert_path}'
  """
  if code isnt 0
    process.stderr.write '\n' + stderr + '\n\n'
    process.exit code
  else
    process.stdout.write '\n' + "#{shortname}.cert.pem: OK" + '\n\n'
