
export default
  header: 'Docker Prepare'
  if: (options) -> options.prepare
  ssh: false
  handler: (options) ->
    @file.cache
      source: "#{options.source}"
      target: "#{options.cache_dir}/docker-compose"
      location: true
