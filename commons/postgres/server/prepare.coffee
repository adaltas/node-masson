
export default
  header: 'PostgreSQL'
  if: -> @contexts('masson/commons/postgres/server')[0]?.config.host is @config.host
  ssh: false
  handler: (options) ->
    @docker.pull
      tag: 'postgresql'
      version: options.version
    @docker.save
      image: "postgres:#{options.version}"
      output: "#{options.cache_dir}/postgres.tar"
