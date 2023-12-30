
export default
  metadata:
    header: 'Network Restart'
  handler: ->
    @system.execute
      cmd: 'service network restart'
