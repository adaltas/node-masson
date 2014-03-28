
module.exports = []

module.exports.push 'wand/test/resources/plan/required_by_ab_begin'

module.exports (ctx, next) ->
  next null, 'b # 1'

