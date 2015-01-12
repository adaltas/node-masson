
# Bootstrap Report

    exports = module.exports = []

    exports.push required: true, callback: (ctx) ->
      report = ctx.config.report ?= {}
      report.writer ?= {}
      report.writer.write ?= (data) ->
        process.stdout.write data

    exports.push name: 'Bootstrap # Report Console', required: true, callback: (ctx, next) ->
      {writer} = ctx.config.report
      reports = {}
      ctx.report = (k, v) ->
        reports[k] = v
      ctx.on 'action_start', (status) ->
        reports = {}
      ctx.on 'action_end', (err) ->
        for k, v of reports
          writer.write if arguments.length > 1 then "#{k}: #{v}\n" else "#{k}\n"
      next null, ctx.PASS