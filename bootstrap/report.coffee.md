
# Bootstrap Report

    exports = module.exports = []

    exports.push required: true, handler: ->
      report = @config.report ?= {}
      report.writer ?= {}
      report.writer.write ?= (data) ->
        process.stdout.write data
      # report.writer ?= new stream.PassThrough
      # report.writer.pipe process.stdout

    exports.push header: 'Bootstrap # Report Console', required: true, handler: ->
      {writer} = @config.report
      reports = []
      @on 'report', (report) ->
        reports.push report
      @on 'middleware_start', ->
        reports = []
      @on 'middleware_stop', (err) ->
        for report in reports
          line = ''
          line += "#{colors.green.dim report.key}: " if report.key
          line += "#{colors.green report.value}"
          if report.raw or report.default
            compl = " ("
            compl += "#{JSON.stringify report.raw}" if report.raw
            compl += ", " if report.raw and report.default
            compl += "default #{JSON.stringify report.default}" if report.default
            compl += ")"
            line += "#{colors.grey compl}"
          line += " #{colors.grey.dim report.description }" if report.description
          line += "\n"
          writer.write line

# Dependencies

    colors = require 'colors/safe'
    stream = require 'stream'
