
module.exports = [
  'wand/test/resources/plan/required_by_ab_begin'
  (ctx, next) ->
    next null, 'a # 1'
  'wand/test/resources/plan/required_by_a_end'
]
