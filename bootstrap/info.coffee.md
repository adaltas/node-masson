
# Bootstrap Info

Gather various information relative to the targeted system.

    mecano = require 'mecano'
    module.exports = []
    module.exports.push 'masson/bootstrap/connection'
    module.exports.push 'masson/bootstrap/log'

## Server Info

Expose system information. On execution, the context is enriched with the 
properties "kernel\_name", "nodename", "kernel\_release", "kernel\_version", 
"processor" and "operating_system".

    module.exports.push name: 'Bootstrap # Server Info', required: true, callback: (ctx, next) ->
      mecano.execute
        ssh: ctx.ssh
        cmd: 'uname -snrvmo'
        # too verbose
        # stdout: ctx.log.out
        # stderr: ctx.log.err
      , (err, executed, stdout, stderr) ->
        return next err if err
        # Linux hadoop1 2.6.32-279.el6.x86_64 #1 SMP Fri Jun 22 12:19:21 UTC 2012 x86_64 x86_64 x86_64 GNU/Linux
        match = /(\w+) (\w+) ([^ ]+)/.exec stdout
        ctx.kernel_name = match[1]
        ctx.nodename = match[2]
        ctx.kernel_release = match[3]
        ctx.kernel_version = match[4]
        ctx.processor = match[5]
        ctx.operating_system = match[6]
        next null, ctx.PASS

## CPU Info

Expose cpu information to the propery "cpuinfo" of the context. Parse the 
result of "/proc/cpuinfo".

Here's how to use it inside a module:

```coffee
module.export = name: 'My Module', callback: (ctx) ->
  console.log ctx.cpuinfo
```

It will output:

```json
[
  {"processor":"0","vendor_id":"GenuineIntel","cpu family":"6","model":"58",
  "model name":"Intel(R) Core(TM) i7-3820QM CPU @ 2.70GHz","stepping":"9",
  "cpu MHz":"2798.656","cache size":"6144 KB","physical id":"0","siblings":"2",
  "core id":"0","cpu cores":"2","apicid":"0","initial apicid":"0","fpu":"yes",
  "fpu_exception":"yes","cpuid level":"5","wp":"yes",
  "flags":"fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good pni ssse3 lahf_lm",
  "bogomips":"5597.31","clflush size":"64","cache_alignment":"64",
  "address sizes":"36 bits physical, 48 bits virtual","power management":""}
,
  {"processor":"1","vendor_id":"GenuineIntel","cpu family":"6","model":"58",
  "model name":"Intel(R) Core(TM) i7-3820QM CPU @ 2.70GHz","stepping":"9",
  "cpu MHz":"2798.656","cache size":"6144 KB","physical id":"0","siblings":"2",
  "core id":"1","cpu cores":"2","apicid":"1","initial apicid":"1","fpu":"yes",
  "fpu_exception":"yes","cpuid level":"5","wp":"yes",
  "flags":"fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm constant_tsc rep_good pni ssse3 lahf_lm",
  "bogomips":"5597.31","clflush size":"64","cache_alignment":"64",
  "address sizes":"36 bits physical, 48 bits virtual","power management":""}
]
```

    module.exports.push name: 'Bootstrap # CPU Info', required: true, callback: (ctx, next) ->
      mecano.execute
        ssh: ctx.ssh
        cmd: 'cat /proc/cpuinfo'
        # too verbose
        # stdout: ctx.log.out
        # stderr: ctx.log.err
      , (err, executed, stdout, stderr) ->
        return next err if err
        ctx.cpuinfo = []
        cpu = {}
        for line in stdout.split /\r\n|[\n\r\u0085\u2028\u2029]/g
          line = line.trim()
          if line is ''
            ctx.cpuinfo.push cpu if Object.keys(cpu).length
            cpu = {}
            continue
          [key, value] = line.split ':'
          cpu[key.trim()] = value.trim()
        ctx.cpuinfo.push cpu if Object.keys(cpu).length
        next null, ctx.PASS

## Mem Info

Expose memory information to the propery "meminfo" of the context. Parse the 
result of "/proc/meminfo". All the values are in bytes.

Here's how to use it inside a module:

```coffee
module.export = name: 'My Module', callback: (ctx) ->
  console.log JSON.stringify ctx.meminfo
```

It will output:

```json
{
  "MemTotal":1020180000,"MemFree":804924000,"Buffers":13920000,
  "Cached":132032000,"SwapCached":0,"Active":36640000,"Inactive":125888000,
  "Active(anon)":16580000,"Inactive(anon)":172000,"Active(file)":20060000,
  "Inactive(file)":125716000,"Unevictable":0,"Mlocked":0,"SwapTotal":2064376000,
  "SwapFree":2064376000,"Dirty":756000,"Writeback":0,"AnonPages":16704000,
  "Mapped":8832000,"Shmem":184000,"Slab":33196000,"SReclaimable":10896000,
  "SUnreclaim":22300000,"KernelStack":936000,"PageTables":2932000,
  "NFS_Unstable":0,"Bounce":0,"WritebackTmp":0,"CommitLimit":2574464000,
  "Committed_AS":172028000,"VmallocTotal":34359738367000,"VmallocUsed":24324000,
  "VmallocChunk":34359704568000,"HardwareCorrupted":0,"AnonHugePages":2048000,
  "HugePages_Total":0,"HugePages_Free":0,"HugePages_Rsvd":0,"HugePages_Surp":0,
  "Hugepagesize":2048000,"DirectMap4k":8128000,"DirectMap2M":1040384000}
```

    module.exports.push name: 'Bootstrap # Mem Info', required: true, callback: (ctx, next) ->
      mecano.execute
        ssh: ctx.ssh
        cmd: 'cat /proc/meminfo'
        # too verbose
        # stdout: ctx.log.out
        # stderr: ctx.log.err
      , (err, executed, stdout, stderr) ->
        return next err if err
        ctx.meminfo = {}
        for line in stdout.split /\r\n|[\n\r\u0085\u2028\u2029]/g
          continue if line is ''
          [key, value] = line.split ':'
          [value, unit] = value.trim().split ' '
          value = parseInt value.trim(), 10
          if unit is 'kB'
            value = value * 1000
          else if typeof unit isnt 'undefined'
            return next new Error 'Invalid unit'
          ctx.meminfo[key.trim()] = value
        next null, ctx.PASS






