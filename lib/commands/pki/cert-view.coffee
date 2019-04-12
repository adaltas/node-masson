
path = require 'path'
{exec} = require 'child_process'

# `./bin/ryba pki --dir ./conf/certs cert-view {fqdn}`
module.exports = ({params}, config, callback) ->
  shortname = params.fqdn.split('.')[0]
  cert_path = path.resolve params.dir, "#{shortname}.cert.pem"
  exec """
  shortname='#{shortname}'
  openssl x509 -in #{cert_path} -text
  """
  , (err, stdout, stderr) ->
    if err
      process.stderr.write '\n' + stderr + '\n\n'
      process.exit 1
    process.stdout.write '\n' + stdout + '\n\n'
