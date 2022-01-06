
path = require 'path'
nikita = require 'nikita'

# `./bin/ryba pki --dir ./conf/certs cacert-view`
module.exports = ({params}, config, callback) ->
  cacert_path = path.resolve params.dir, 'ca.cert.pem'
  {code, stdout, stderr} = await nikita.execute relax: true, """
  openssl x509 -in #{cacert_path} -text
  """
  if code isnt 0
    process.stderr.write '\n' + stderr + '\n\n'
    process.exit code
  else
    process.stdout.write '\n' + stdout + '\n\n'
  
