
# Bootstrap Report

    exports = module.exports = []

    exports.push required: true, handler: (ctx) ->
      report = ctx.config.report ?= {}
      report.writer ?= {}
      report.writer.write ?= (data) ->
        process.stdout.write data
      # report.writer ?= new stream.PassThrough
      # report.writer.pipe process.stdout

    exports.push name: 'Bootstrap # Report Console', required: true, handler: (ctx, next) ->
      {writer} = ctx.config.report
      reports = []
      ctx.on 'report', (report) ->
        reports.push report
      ctx.on 'middleware_start', ->
        reports = []
      ctx.on 'middleware_stop', (err) ->
      # ctx.on 'end', ->
        for report in reports
          line = ''
          line += "#{colors.green.dim report.key}: " if report.key
          line += "#{colors.green report.value}"
          line += " (default #{JSON.stringify report.default})" if report.default
          line += " #{report.description }" if report.description
          line += "\n"
          writer.write line
          # writer.write "#{colors.grey report.description}\n" 
      #     line = "#{colors.green report.value}\n"
      #     line =+ "#{colors.green.dim report.key}: " if report.key
      #     writer.write line
      #     writer.write "#{colors.grey report.description}\n" if report.description
      # reports = {}
      # ctx.report = (k, v) ->
      #   reports[k] = v
      # ctx.on 'middleware_start', (status) ->
      #   reports = {}
      # ctx.on 'middleware_stop', (err) ->
      #   for k, v of reports
      #     writer.write if arguments.length > 1 then "#{colors.green.dim k}: #{colors.green v}\n" else "#{k}\n"
      next null, ctx.PASS

# Dependencies

    colors = require 'colors/safe'
    stream = require 'stream'
