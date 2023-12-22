
import path from 'path'
import nikita from 'nikita'

# `./bin/ryba pki --dir ./conf/certs cert-view {fqdn}`
export default ({params}, config, callback) ->
  shortname = params.fqdn.split('.')[0]
  cert_path = path.resolve params.dir, "#{shortname}.cert.pem"
  {code, stdout, stderr} = await nikita.execute relax: true, """
  shortname='#{shortname}'
  openssl x509 -in #{cert_path} -text
  """
  if code isnt 0
    process.stderr.write '\n' + stderr + '\n\n'
    process.exit code
  else
    process.stdout.write '\n' + stdout + '\n\n'
