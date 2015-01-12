
    module.exports = []
    module.exports.push 'masson/bootstrap'
    module.exports.push 'masson/core/openldap_server/install'
    # We cant require openldap_client here, since it will deploy 
    # and test a secure connection on a server not yet configured

# OpenLDAP TLS

Note, by default, openldap comes with ldaps support. The default value are:   

*   olcTLSCACertificatePath: /etc/openldap/certs   
*   olcTLSCertificateFile: "OpenLDAP Server"   
*   olcTLSCertificateKeyFile: /etc/openldap/certs/password   

To test if TLS is configured, run `ldapsearch -LLLY EXTERNAL -H ldapi:/// -b cn=config -s base | grep -i tls`

Create a self-signed certificate
--------------------------------

Thanks to [Paul Kehrer ](https://langui.sh/2009/01/18/openssl-self-signed-ca/) 
and [David Robillard](http://itdavid.blogspot.ca/2012/05/howto-centos-6.html) 
for their great articles. This installation procedure wasn't as smooth as I 
would expect so here's a recap.

This is using the [OpenSSL](https://www.openssl.org/) library. Although not 
tested, [Brad Chen](http://www.bradchen.com/blog/2012/08/openldap-tls-issue) 
wrote a comprehensive tutorial on using the 
[Mozilla NSS](https://developer.mozilla.org/en/docs/NSS) tools.

We start by positioning ourself inside a new directory.

```bash
mkdir /tmp/openldap
cd /tmp/openldap
umask 066
```

Generate a privkey.pem file (base64 encoded RSA private key) as well as a 
openldap.hadoop.ca.cer file containing the self-signed Certificate Authority 
(CA) public key with a 3650 day validity 
period. Both will be referenced in our CA configuration. You may leave the 
challenge password blank.    

```bash
openssl req -newkey rsa:2048 -days 3650 -x509 -nodes -out openldap.hadoop.ca.cer
```

Here's the output:

```
Generating a 2048 bit RSA private key
........................+++
...............................................................................+++
writing new private key to 'privkey.pem'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:FR
State or Province Name (full name) [Some-State]:France
Locality Name (eg, city) []:Paris
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Adaltas
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:openldap.hadoop
Email Address []:david@adaltas.com
```

Now prepare a configuration file "myca.conf" and substitute the properties 
"certificate", "database", "private_key", "serial" with their correct values.

```
[ ca ]
default_ca = myca

[ crl_ext ]
# issuerAltName=issuer:copy  #this would copy the issuer name to altname
authorityKeyIdentifier=keyid:always

[ myca ]
new_certs_dir = /tmp
unique_subject = no
certificate = /tmp/openldap/openldap.hadoop.ca.cer
database = /tmp/openldap/certindex
private_key = /tmp/openldap/privkey.pem
serial = /tmp/openldap/serialfile
default_days = 365
default_md = sha1
policy = myca_policy
x509_extensions = myca_extensions

[ myca_policy ]
commonName = supplied
stateOrProvinceName = supplied
countryName = supplied
emailAddress = optional
organizationName = supplied
organizationalUnitName = optional

[ myca_extensions ]
basicConstraints = CA:false
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always
keyUsage = digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
crlDistributionPoints = URI:http://path.to.crl/myca.crl
```

The files "certindex" and "serialfile" referenced by the CA configuration must also be intialized:

```
touch certindex
echo 000a > serialfile
```

We are now ready to create our CSR (certificate signing request) and private 
key, leave the challenge password empty:

```bash
openssl req -newkey rsa:1024 -nodes -out openldap.hadoop.csr -keyout openldap.hadoop.key
```

Here's the output:

```
Generating a 1024 bit RSA private key
....................................................................................................................++++++
..................................................................++++++
writing new private key to 'openldap.hadoop.key'
-----
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:FR
State or Province Name (full name) [Some-State]:France
Locality Name (eg, city) []:Paris
Organization Name (eg, company) [Internet Widgits Pty Ltd]:Adaltas
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []:openldap.hadoop
Email Address []:david@adaltas.com

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
```

We can now issue the certificate:

```bash
openssl ca -batch -config ./myca.conf -notext -in openldap.hadoop.csr -out openldap.hadoop.cer
```

Here's the output:

```
Using configuration from /tmp/openldap/myca.conf
Check that the request matches the signature
Signature ok
The Subject's Distinguished Name is as follows
countryName           :PRINTABLE:'FR'
stateOrProvinceName   :PRINTABLE:'France'
localityName          :PRINTABLE:'Paris'
organizationName      :PRINTABLE:'Adaltas'
commonName            :PRINTABLE:'openldap.hadoop'
emailAddress          :IA5STRING:'david@adaltas.com'
Certificate is to be certified until Feb 28 12:44:54 2015 GMT (365 days)

Write out database with 1 new entries
Data Base Updated
```

The certificate is generated and can be visualized and checked with:

```bash
openssl x509 -noout -text -in openldap.hadoop.cer
openssl verify -CAfile openldap.hadoop.ca.cer openldap.hadoop.cer
```

We are now ready to deploy our certificate. This must be executed on the 
OpenLDAP server. Import the keys if they were generated from a different server.

```bash
chmod 644 openldap.hadoop.cer; chown ldap:ldap openldap.hadoop.cer
mv openldap.hadoop.cer /etc/pki/tls/certs

chmod 400 openldap.hadoop.key; chown ldap:ldap openldap.hadoop.key
mv openldap.hadoop.key /etc/pki/tls/certs

chmod 400 openldap.hadoop.ca.cer; chown ldap:ldap openldap.hadoop.ca.cer
mv openldap.hadoop.ca.cer /etc/pki/tls/certs
```

Update the ldap configuration by editing "/etc/openldap/slapd.d/cn=config.ldif" or running:

```bash
ldapmodify -Y EXTERNAL -H ldapi:/// <<-EOF
dn: cn=config
replace: olcTLSCertificateFile
olcTLSCertificateFile: /etc/pki/tls/certs/openldap.hadoop.cer
-
replace: olcTLSCertificateKeyFile
olcTLSCertificateKeyFile: /etc/pki/tls/certs/openldap.hadoop.key
-
replace: olcTLSCACertificateFile
olcTLSCACertificateFile: /etc/pki/tls/certs/openldap.hadoop.ca.cer
EOF
```

TLS should now be configured:

```bash
sudo ldapsearch -LLLY EXTERNAL -H ldapi:/// -b cn=config -s base | grep -i tls
```

should print

```
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
olcTLSCertificateFile: /etc/pki/tls/certs/openldap.hadoop.cer
olcTLSCertificateKeyFile: /etc/pki/tls/certs/openldap.hadoop.key
olcTLSVerifyClient: never
```

and 

```bash
openssl s_client -connect `hostname`:636 -showcerts -state -CAfile /etc/pki/tls/certs/openldap.hadoop.ca.cer
```

should print

```
CONNECTED(00000003)
SSL_connect:before/connect initialization
SSL_connect:SSLv2/v3 write client hello A
SSL_connect:SSLv3 read server hello A
depth=1 C = FR, ST = France, L = Paris, O = Adaltas, CN = openldap.hadoop, emailAddress = david@adaltas.com
verify return:1
depth=0 CN = openldap.hadoop, ST = France, C = FR, emailAddress = david@adaltas.com, O = Adaltas
verify return:1
SSL_connect:SSLv3 read server certificate A
SSL_connect:SSLv3 read server key exchange A
SSL_connect:SSLv3 read server done A
SSL_connect:SSLv3 write client key exchange A
SSL_connect:SSLv3 write change cipher spec A
SSL_connect:SSLv3 write finished A
SSL_connect:SSLv3 flush data
SSL_connect:SSLv3 read finished A
---
Certificate chain
 0 s:/CN=openldap.hadoop/ST=France/C=FR/emailAddress=david@adaltas.com/O=Adaltas
   i:/C=FR/ST=France/L=Paris/O=Adaltas/CN=openldap.hadoop/emailAddress=david@adaltas.com
-----BEGIN CERTIFICATE-----
MIIDfjCCAmagAwIBAgIBCjANBgkqhkiG9w0BAQUFADB8MQswCQYDVQQGEwJGUjEP
MA0GA1UECBMGRnJhbmNlMQ4wDAYDVQQHEwVQYXJpczEQMA4GA1UEChMHQWRhbHRh
czEYMBYGA1UEAxMPb3BlbmxkYXAuaGFkb29wMSAwHgYJKoZIhvcNAQkBFhFkYXZp
ZEBhZGFsdGFzLmNvbTAeFw0xNDAyMjgxMjQ0NTRaFw0xNTAyMjgxMjQ0NTRaMGwx
GDAWBgNVBAMTD29wZW5sZGFwLmhhZG9vcDEPMA0GA1UECBMGRnJhbmNlMQswCQYD
VQQGEwJGUjEgMB4GCSqGSIb3DQEJARYRZGF2aWRAYWRhbHRhcy5jb20xEDAOBgNV
BAoTB0FkYWx0YXMwgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAO61QNip/1e9
YPuPFSpmmApDkjq4M05+1qzi5imtZHJ2aMxIinBx5RouT/b+3z1sLJWHL4sDSCjh
AXRemTdSf1M5E4sLkJgRxoY+w4/T/spZsYJeLE/svCDEmwbChLv7b+RRW5LNVS0w
XZEcdK7UmRIRqxOz7uz/8PKtBU1WgOXrAgMBAAGjgZ4wgZswCQYDVR0TBAIwADAd
BgNVHQ4EFgQUUH9A9HJWF5mD7ykrHibR4Rb2OocwHwYDVR0jBBgwFoAUirdnZmId
Ak/iEKq8FwAMT1Gqe90wCwYDVR0PBAQDAgWgMBMGA1UdJQQMMAoGCCsGAQUFBwMB
MCwGA1UdHwQlMCMwIaAfoB2GG2h0dHA6Ly9wYXRoLnRvLmNybC9teWNhLmNybDAN
BgkqhkiG9w0BAQUFAAOCAQEAkSsdHAw/MRc5/85hBwwmVKPudxIQQXqzGCm4NSsj
cgZ+o/ni+Wv1qqjC03kpIMRDzSSyH1Kx7c+AwJraZ/X2E+/ja9e1QrEQ8uOQPE+X
XnuOMV1aEKz1iRnlzUNXz5lsVgp9whjdLRdHWT+dzQ6My/BHrP5Ryfxoq06U+Iih
NnBkI0Tt+co+jraZWpdAVLFNdhvR0M7nfhAG3b48E0RXcfB44qUn5tQhV41BZOdh
+yctKMR5+12RBpTrXHFYAByn3HR5vAzxwkR9EtvDJco4S1wmu8kpu/XUV+tyscxg
sE8brtj7R9NerJto3eG6C6ZZmgr9+O08Pg7Du3cjhfWO3Q==
-----END CERTIFICATE-----
 1 s:/C=FR/ST=France/L=Paris/O=Adaltas/CN=openldap.hadoop/emailAddress=david@adaltas.com
   i:/C=FR/ST=France/L=Paris/O=Adaltas/CN=openldap.hadoop/emailAddress=david@adaltas.com
-----BEGIN CERTIFICATE-----
MIIEXjCCA0agAwIBAgIJAI6/j5t7tLsgMA0GCSqGSIb3DQEBBQUAMHwxCzAJBgNV
BAYTAkZSMQ8wDQYDVQQIEwZGcmFuY2UxDjAMBgNVBAcTBVBhcmlzMRAwDgYDVQQK
EwdBZGFsdGFzMRgwFgYDVQQDEw9vcGVubGRhcC5oYWRvb3AxIDAeBgkqhkiG9w0B
CQEWEWRhdmlkQGFkYWx0YXMuY29tMB4XDTE0MDIyODEwMTE0MFoXDTI0MDIyNjEw
MTE0MFowfDELMAkGA1UEBhMCRlIxDzANBgNVBAgTBkZyYW5jZTEOMAwGA1UEBxMF
UGFyaXMxEDAOBgNVBAoTB0FkYWx0YXMxGDAWBgNVBAMTD29wZW5sZGFwLmhhZG9v
cDEgMB4GCSqGSIb3DQEJARYRZGF2aWRAYWRhbHRhcy5jb20wggEiMA0GCSqGSIb3
DQEBAQUAA4IBDwAwggEKAoIBAQDWCxzm/5giT78VZTsTW8a3Scv4BpN5BG6fJZfG
8OMLUWL5+brg+izXzQhnZ+FX+0OO/10cK008VwhgHWyEce3eOhNdrOlPbSX1B02B
nCcFhKX8awcqOnsxnbkWxD0Ogf87foMirajck/WD8c68s9KINmz+CdDHn07K4YN0
PBdwe0Mt4FdIeSVDg/dakbUSAuFX3NOU1o5kpmQbVH9nST72aZcaC/j3tzVEMP3p
S/LkZAMk8lyUFj3vFCmnw6d/CTOL0AjQLrLpN28diWFH6nsOngaqrL0YAiy+F2k5
xKzPPiKjWfv1SJ3/+B9mMQilfX6+K++3mG8rjHCDAj95sH1BAgMBAAGjgeIwgd8w
HQYDVR0OBBYEFIq3Z2ZiHQJP4hCqvBcADE9RqnvdMIGvBgNVHSMEgacwgaSAFIq3
Z2ZiHQJP4hCqvBcADE9RqnvdoYGApH4wfDELMAkGA1UEBhMCRlIxDzANBgNVBAgT
BkZyYW5jZTEOMAwGA1UEBxMFUGFyaXMxEDAOBgNVBAoTB0FkYWx0YXMxGDAWBgNV
BAMTD29wZW5sZGFwLmhhZG9vcDEgMB4GCSqGSIb3DQEJARYRZGF2aWRAYWRhbHRh
cy5jb22CCQCOv4+be7S7IDAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBBQUAA4IB
AQDM0uqSDPLcJSnh0d3O1z/Q+Lthrm27htrtUoaJVzg5W6AT57tnnW0d66bMym9y
+YO4v/BiG9PjdP1uXu+jL3Qn7Cpg8tUABqXhIxSlNDklfNA7fi7ZY4c78sJV20K2
i3w44yA+reFqrja8RxPCplIDT741kcxS2kD9NlwcaMAqlxzZd6767zkg/xbrW1/t
1OWvl0cXNysjalcmAP2kdO6oQAWJRNwowI8j/GqT7fo/F+IVx3sszSx+0HVpfdKI
PWNi+/Pxu9dzxbRkJsXmhxRsSemMQLqsT0LnQ0e6OtpAXf+T8lYZ+K/Dc+B8WkkJ
7o6Ob+tH8SkEkMsO6/qL4UAl
-----END CERTIFICATE-----
---
Server certificate
subject=/CN=openldap.hadoop/ST=France/C=FR/emailAddress=david@adaltas.com/O=Adaltas
issuer=/C=FR/ST=France/L=Paris/O=Adaltas/CN=openldap.hadoop/emailAddress=david@adaltas.com
---
No client certificate CA names sent
---
SSL handshake has read 2391 bytes and written 397 bytes
---
New, TLSv1/SSLv3, Cipher is ECDHE-RSA-AES256-SHA
Server public key is 1024 bit
Secure Renegotiation IS supported
Compression: NONE
Expansion: NONE
SSL-Session:
    Protocol  : TLSv1
    Cipher    : ECDHE-RSA-AES256-SHA
    Session-ID: 1E58B88449A5C6F6EEA34F7EBD6FCE7D7B2D0BCA4B4FEC72C8163E676E77DA6C
    Session-ID-ctx: 
    Master-Key: 1A19B4BF692DAAD1B2919E2A7BF7CC5B9078E6F6C0F6D7ADA94ADD44770D281A605A93B16CF35D32F86CC0028E47638A
    Key-Arg   : None
    Krb5 Principal: None
    PSK identity: None
    PSK identity hint: None
    Start Time: 1393595866
    Timeout   : 300 (sec)
    Verify return code: 0 (ok)
---
```

We will now setup the OpenLDAP client environment. Note, this could be done from openldap client server. Start by editing "/etc/openldap/ldap.conf".

```
BASE            dc=adaltas,dc=com
URI             ldap://openldap.hadoop
TLS_CACERT      /etc/pki/tls/certs/openldap.hadoop.cer
TLS_REQCERT     allow
TIMELIMIT       15
TIMEOUT         20
```

If you are on a different server, place your certificate into "/etc/pki/tls/certs/openldap.hadoop.cer".

You shall now be able to query the ldap server over ldaps.

```
ldapsearch -H ldaps://master3.hadoop:636 -x -D cn=Manager,dc=adaltas,dc=com -w test -b dc=adaltas,dc=com
ldapsearch -Y EXTERNAL -H ldapi:/// -b dc=adaltas,dc=com
```

###

    module.exports.push (ctx) ->
      ctx.config.openldap_server ?= {}

    module.exports.push name: 'OpenLDAP Server # TLS Deploy', callback: (ctx, next) ->
      { tls, tls_ca_cert_file, tls_cert_file, tls_key_file } = ctx.config.openldap_server
      return next null, ctx.DISABLED unless tls
      tls_ca_cert_filename = path.basename tls_ca_cert_file
      tls_cert_filename = path.basename tls_cert_file
      tls_key_filename = path.basename tls_key_file
      modified = false
      do_upload = ->
        ctx.log 'Write certificate files'
        ctx.upload [
          source: tls_ca_cert_file
          local_source: true
          destination: "/etc/pki/tls/certs/#{tls_ca_cert_filename}"
          uid: 'ldap'
          gid: 'ldap'
          mode: '400'
        ,
          source: tls_cert_file
          local_source: true
          destination: "/etc/pki/tls/certs/#{tls_cert_filename}"
          uid: 'ldap'
          gid: 'ldap'
          mode: '400'
        ,
          source: tls_key_file
          local_source: true
          destination: "/etc/pki/tls/certs/#{tls_key_filename}"
          uid: 'ldap'
          gid: 'ldap'
          mode: '400'
        ], (err, written) ->
          return next err if err
          modified = true if written
          do_config()
      do_config = ->
        ctx.log 'Write certificate configuration'
        ctx.write
          destination: '/etc/openldap/slapd.d/cn=config.ldif'
          write: [
            match: /^olcTLSCACertificatePath.*$/mg
            replace: "olcTLSCACertificatePath: /etc/pki/tls/certs/#{tls_ca_cert_filename}"
            # append: 'olcRootPW'
          ,
            match: /^olcTLSCertificateFile.*$/mg
            replace: "olcTLSCertificateFile: /etc/pki/tls/certs/#{tls_cert_filename}"
            # append: 'olcRootPW'
          ,
            match: /^olcTLSCertificateKeyFile.*$/mg
            replace: "olcTLSCertificateKeyFile: /etc/pki/tls/certs/#{tls_key_filename}"
            # append: 'olcTLSCertificateFile'
          ]
        , (err, written) ->
          return next err if err
          modified = true if written
          do_end()
      do_end = ->
        ctx.service
          name: 'openldap-servers'
          srv_name: 'slapd'
          action: 'restart'
          if: modified
        , next
      do_upload()

    module.exports.push name: 'OpenLDAP TLS # Activate LDAPS', callback: (ctx, next) ->
      ctx.write
        match: /^SLAPD_LDAPS.*/mg
        replace: 'SLAPD_LDAPS=yes'
        destination: '/etc/sysconfig/ldap'
      , (err, written) ->
        return next err if err
        ctx.service
          srv_name: 'slapd'
          action: 'restart'
          if: written
        , next

    module.exports.push 'masson/core/openldap_client'

    module.exports.push name: 'OpenLDAP Server # TLS Check', timeout: -1, callback: (ctx, next) ->
      { suffix, root_dn, root_password } = ctx.config.openldap_server
      ctx.execute
        cmd: "ldapsearch -x -H ldaps://#{ctx.config.host} -b #{suffix} -D #{root_dn} -w #{root_password}"
      , next

## Module Dependencies

    path = require 'path'












