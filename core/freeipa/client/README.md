
# FreeIPA Client

FreeIPA Client package, to use with FreeIPA Server.

# Configuration

Follows [production deployment configuration](https://www.freeipa.org/page/Deployment_Recommendations)

Options:

* `ssl.cert` (string, optional, "/etc/ipa/cert.pem")   
  Path where to store the certificate.
* `ssl.enabled` (boolean, optional, false)   
  Enable certificate generation and tracking.
* `ssl.key` (string, optional, "/etc/ipa/key.pem")   
  Path where to store the private key.
* `ssl.subject` (string|object, optional, "CN=<fqdn>")   
  Requested subject name.
* `ssl.subject.CN` (string, optional, "<fqdn>")   
  Common name.
* `ssl.subject.O` (string, optional)   
  Organisation name.
* `ssl.principal` (string, optional, "HTTP/<fqdn>")   
  Requested principal name.

## Example setting a custom organization name

```json
{ "ssl":
  "enabled": true
  "subject": {
    "O": "AU.ADALTAS.CLOUD"
} }
```

## Notes

Renewable tickets is per default disallowed in the most linux distributions. This can be done per:

```bash
kadmin.local: modprinc -maxrenewlife 7day krbtgt/YOUR_REALM
kadmin.local: modprinc -maxrenewlife 7day +allow_renewable hue/FQRN
```
