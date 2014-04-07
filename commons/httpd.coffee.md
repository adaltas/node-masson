---
title: 
layout: module
---

# HTTPD web server

    module.exports = []
    module.exports.push 'masson/bootstrap/'

## Configuration

Configure the HTTPD server.

    module.exports.push (ctx) ->
      ctx.config.httpd ?= {}
      ctx.config.httpd.startup ?= '2,3,5'
      ctx.config.httpd.action ?= 'start'

## Install

Install the HTTPD service and declare it as a startup service.

    module.exports.push name: 'HTTPD # Install', timeout: -1, callback: (ctx, next) ->
      {startup, action} = ctx.config.httpd
      ctx.service
        name: 'httpd'
        startup: startup
        action: action
      , (err, serviced) ->
        next err, if serviced then ctx.OK else ctx.PASS


