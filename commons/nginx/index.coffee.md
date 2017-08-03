
# NGINX Web Server

NGINX is a free, open-source, high-performance HTTP server and reverse proxy, as
well as an IMAP/POP3 proxy server. NGINX is known for its high performance,
stability, rich feature set, simple configuration, and low resource consumption.


    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
      configure:
        'masson/commons/nginx/configure'
      commands:
        'install': ->
          options = @config.nginx
          @call 'masson/commons/nginx/install', options
          @call 'masson/commons/nginx/start', options
        'start':
          'masson/commons/nginx/start'
        'status':
          'masson/commons/nginx/status'
        'stop':
          'masson/commons/nginx/stop'
