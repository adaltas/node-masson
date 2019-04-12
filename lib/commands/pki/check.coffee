
path = require 'path'
{exec} = require 'child_process'

# `./bin/ryba pki --dir ./conf/certs check {fqdn}`
module.exports = ({params}, config, callback) ->
  cacert_path = path.resolve params.dir, 'ca.cert.pem'
  shortname = params.fqdn.split('.')[0]
  cert_path = path.resolve params.dir, "#{shortname}.cert.pem"
  exec """
  if [ ! -f '#{cacert_path}' ]; then >&2 echo -n 'Failed to locate the CA certificate'; exit 1; fi
  if [ ! -f '#{cert_path}' ]; then >&2 echo -n 'Failed to locate the file certificate'; exit 1; fi
  openssl verify -CAfile '#{cacert_path}' '#{cert_path}'
  """
  , (err, stdout, stderr) ->
    if err
      process.stderr.write '\n' + stderr + '\n\n'
      process.exit 1
    process.stdout.write '\n' + "#{shortname}.cert.pem: OK" + '\n\n'
