
module.exports = (config) ->
  config = normalize config
  config = affinity config
  config = enrich config
