
path = require 'path'
{exec} = require 'child_process'

# `./bin/ryba pki --dir ./conf/certs cacert-view`
module.exports = ({params}, config, callback) ->
  cacert_path = path.resolve params.dir, 'ca.cert.pem'
  exec """
  openssl x509 -in #{cacert_path} -text
  """
  , (err, stdout, stderr) ->
    if err
      process.stderr.write '\n' + stderr + '\n\n'
      process.exit 1
    process.stdout.write '\n' + stdout + '\n\n'
  
