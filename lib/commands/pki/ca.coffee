
path = require 'path'
{exec} = require 'child_process'

module.exports = ({params}, config, callback) ->
  cakey_path = path.resolve params.dir, 'ca.key.pem'
  cacert_path = path.resolve params.dir, 'ca.cert.pem'
  subject = '/C=FR/O=Adaltas/L=Paris/CN=adaltas.com'
  exec """
  if [ ! -d '#{params.dir}' ]; then >&2 echo -n 'Output directory does not exist'; exit 1; fi
  if [ -f '#{cakey_path}' ]; then >&2 echo -n 'CA Certiticate already exists'; exit 1; fi
  # RSA Private key (create "ca.key.pem")
  openssl genrsa -out '#{cakey_path}' 2048
  # Self-signed (with the key previously generated) root CA certificate (create "ca.cert.pem")
  openssl req -x509 -new -sha256 -key '#{cakey_path}' -days 7300 -out '#{cacert_path}' -subj '#{subject}'
  """
  , (err, stdout, stderr) ->
    if err
      process.stderr.write '\n' + stderr + '\n\n'
      process.exit 1
    output = """
    Certificate files generated:
    * Key: "#{cakey_path}"
    * Certificate: "#{cacert_path}"
    * Subject: "#{subject}"
    """
    process.stdout.write '\n' + "#{output}" + '\n\n'
    callback err
