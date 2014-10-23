---
title: GCC
module: masson/core/gcc
layout: module
---

# GCC

GNU project C and C++ compiler.

    module.exports = []
    module.exports.push 'masson/bootstrap/'
    module.exports.push 'masson/core/yum'

## Install

The package "gcc-c++" is installed.

    module.exports.push name: 'GCC # Install', timeout: -1, callback: (ctx, next) ->
      ctx.service
        name: 'gcc-c++'
      , next
