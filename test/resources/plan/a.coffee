
module.exports = []

module.exports.push 'wand/test/resources/plan/required_by_ab_begin'

module.exports.push (ctx, next) ->
  next null, 'a # 1'

module.exports.push 'wand/test/resources/plan/required_by_a_end'

