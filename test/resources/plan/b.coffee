
module.exports = [
  'wand/test/resources/plan/required_by_ab_begin'
  (ctx, next) ->
    next null, 'b # 1'
]
