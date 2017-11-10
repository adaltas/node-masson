
# SSL

The SSL service is a central place to define and obtain SSL certificates.

Services which require SSL activation are encouraged to leverage this service. It
can also upload the certificates into the host filesystem.

    module.exports =
      deps:
        'java': module: 'masson/commons/java'
      configure:
        'masson/core/ssl/configure'
      commands:
        'install':
          'masson/core/ssl/install'
