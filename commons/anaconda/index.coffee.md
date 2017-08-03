
# Anaconda

Anaconda is a completely free Python distribution (including for commercial use
and redistribution). It includes more than 300 of the most popular Python packages
for science, math, engineering, and data analysis. See the packages included with
Anaconda and the Anaconda changelog.

    module.exports =
      configure:
        'masson/commons/anaconda/configure'
      commands:
        'install': ->
          options = @config.anaconda
          @call 'masson/commons/anaconda/install', options
        'prepare': ->
          options = @config.anaconda
          @call 'masson/commons/anaconda/prepare', options
