
# SSL

The SSL service is a central place to define and obtain SSL certificates.

Services which require SSL activation are encourage to leverage this service. It
can also upload the certificates into the host filesystem.

    module.exports =
      configure:
        'masson/core/ssl/configure'
      commands:
        'install': 'masson/core/ssl/install'
