
# Docker

Docker allows you to package an application with all of its dependencies into a
standardized unit for software development. Docker containers wrap up a piece of
software in a complete filesystem that contains everything it needs to run:
code, runtime, system tools, system libraries – anything you can install on a
server. This guarantees that it will always run the same, regardless of the
environment it is running in. 

    module.exports = ->
      'configure':
        'masson/commons/docker/configure'
      'install': handler: ->
        @call 'masson/commons/docker/install', @config.docker
        @call 'masson/commons/docker/stop', if: -> @status -1
        @call 'masson/commons/docker/start'
      'start':
        'masson/commons/docker/start'
      'status':
        'masson/commons/docker/status'
      'stop':
        'masson/commons/docker/stop'
