
# Maven

Currently being written, not yet registered in any config.

## Configuration

    module.exports =
      'configure':
        'masson/commons/maven/configure'
      commands:
        'install': ->
          options = @config.maven
          @call 'masson/commons/maven/install', options
        'prepare': ->
          options = @config.maven
          @call 'masson/commons/maven/prepare', options
