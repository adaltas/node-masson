
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
      'install':
        'masson/commons/docker/install'
      'start':
        'masson/commons/docker/start'
      'status':
        'masson/commons/docker/status'
      'stop':
        'masson/commons/docker/stop'
