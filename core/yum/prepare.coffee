
export default
  header: 'Yum Prepare'
  if: ({options}) -> options.prepare
  ssh: false
  handler: ({options}) ->
    @file.cache
      if: options.epel.enabled
      header: 'Epel'
      location: true
      md5: options.epel.md5
      sha256: options.epel.sha256
      source: options.epel.url
