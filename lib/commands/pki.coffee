
path = require 'path'
{exec} = require 'child_process'

module.exports = (params, config, callback) ->
  module.exports[params.action] params, config, callback

module.exports['ca'] = (params, config, callback) ->
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
  """, (err, stdout, stderr) ->
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

# `./bin/ryba pki --dir ./conf/certs check {fqdn}`
module.exports['check'] = (params, config, callback) ->
  cacert_path = path.resolve params.dir, 'ca.cert.pem'
  shortname = params.fqdn.split('.')[0]
  cert_path = path.resolve params.dir, "#{shortname}.cert.pem"
  exec """
  if [ ! -f '#{cacert_path}' ]; then >&2 echo -n 'Failed to locate the CA certificate'; exit 1; fi
  if [ ! -f '#{cert_path}' ]; then >&2 echo -n 'Failed to locate the file certificate'; exit 1; fi
  openssl verify -CAfile '#{cacert_path}' '#{cert_path}'
  """, (err, stdout, stderr) ->
    if err
      process.stderr.write '\n' + stderr + '\n\n'
      process.exit 1
    process.stdout.write '\n' + "#{shortname}.cert.pem: OK" + '\n\n'

# `./bin/ryba pki --dir ./conf/certs cert {fqdn}`
module.exports['cert'] = (params, config, callback) ->
  cakey_path = path.resolve params.dir, 'ca.key.pem'
  cacert_path = path.resolve params.dir, 'ca.cert.pem'
  caserial_path = path.resolve params.dir, 'ca.seq'
  shortname = params.fqdn.split('.')[0]
  csr_path = path.resolve params.dir, "#{shortname}.cert.csr"
  key_path = path.resolve params.dir, "#{shortname}.key.pem"
  cert_path = path.resolve params.dir, "#{shortname}.cert.pem"
  subject = "/C=FR/O=Adaltas/L=Paris/CN=#{params.fqdn}"
  exec """
  fqdn='#{params.fqdn}'
  shortname='#{shortname}'
  if [ ! -f #{cacert_path} ]; then echo 'Run `./generate.sh cacert` first.'; exit 1; fi
  # Certificate signing request (CSR) and private key (create "{hostname}.cert.csr" and "{hostname}.key.pem")
  openssl req -newkey rsa:2048 -sha256 -nodes -out #{csr_path} -keyout #{key_path} -subj '#{subject}'
  # to view the CSR: `openssl req -in {hostname}.cert.csr -noout -text`
  # Sign the CSR (create "hadoop.cert.pem")
  openssl x509 -req -sha256 -days 7300 -in #{csr_path} -CA #{cacert_path} -CAkey #{cakey_path} -out #{cert_path} -CAcreateserial -CAserial #{caserial_path}
  # Clean up
  rm -rf '#{csr_path}'
  """, (err, stdout, stderr) ->
    if err
      process.stderr.write '\n' + stderr + '\n\n'
      process.exit 1

# `./bin/ryba pki --dir ./conf/certs cert-view {fqdn}`
module.exports['cert-view'] = (params, config, callback) ->
  shortname = params.fqdn.split('.')[0]
  cert_path = path.resolve params.dir, "#{shortname}.cert.pem"
  exec """
  shortname='#{shortname}'
  openssl x509 -in #{cert_path} -text
  """, (err, stdout, stderr) ->
    if err
      process.stderr.write '\n' + stderr + '\n\n'
      process.exit 1
    process.stdout.write '\n' + stdout + '\n\n'

# `./bin/ryba pki --dir ./conf/certs cacert-view`
module.exports['cacert-view'] = (params, config, callback) ->
  cacert_path = path.resolve params.dir, 'ca.cert.pem'
  exec """
  openssl x509 -in #{cacert_path} -text
  """, (err, stdout, stderr) ->
    if err
      process.stderr.write '\n' + stderr + '\n\n'
      process.exit 1
    process.stdout.write '\n' + stdout + '\n\n'
  
