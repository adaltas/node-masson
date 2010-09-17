
// Class - Macon - Copyright David Worms <open@adaltas.com> (MIT Licensed)

/**
 * Create a "class" with the given _proto_.
 *
 * Example:
 *
 *   var macon = require('macon');
 *   macon({
 *     'taget 1': function(){
 *       console.log('Target "'+this.target+'" executed');
 *       this.process();
 *     },
 *     'target 2': function(){
 *       var self = this;
 *       this.depends('target 1',function(){
 *         console.log('Target "'+self.target+'" executed');
 *         self.process();
 *       });
 *     }
 *   },'target 2');
 * 
 */

var sys = require('sys'),
	opts = require('opts'),
	EventEmitter = require('events').EventEmitter,
	fs = require('fs'),
	assert = require('assert'),
	spawn = require('child_process').spawn,
	step = require('step');

module.exports = function(conf,target){
	if(!conf[target]) sys.puts('Invalid target '+target);
	var context = function(){
		this.stack = [];
	}
	context.prototype = new EventEmitter;
	context.prototype.depends = function(/*target,arguments...*/){
		var args = Array.prototype.slice.call(arguments);
		var targets = args.shift();
		if(typeof targets == 'string'){
			targets = [targets];
		}
		this.stack.unshift([targets,args.shift(),this.target]);
		run();
	}
	context.prototype.next = function(){
		this.emit('after');
		run();
	}
	var context = new context(/*err,arg1,arg2,...*/);
	var run = function(){
		if(!context.stack.length){
			throw new Error('Invalid call');
		}
		if(context.stack[0][0].length){
			// Call a dependency target
			var target = context.stack[0][0].shift();
			if(!conf[target]){
				context.emit('error');
				context.stack[0][0] = [];
				return run(new Error('Invalid target: '+target));
				// throw new Error('Invalid target '+target);
			}
			context.target = target;
			context.emit('before');
			conf[target].apply(context,[]);
			
			/*
			(function(args){
				this.target = target;
				context.emit('before');
				this.depends = function(a,b){context.depends(a,b)};
				this.next = function(){context.next()};
				conf[target].apply(this,args);
			})(arguments)
			*/
		}else if(context.stack[0][1]){
			// Call a dependency callback
			var s = context.stack.shift();
			context.target = s[2];
			s[1].apply(context,arguments);
			
			/*
			(function(args){
				this.target = s[2];
				this.next = function(){context.next()};
				s[1].apply(this,args);
			})(arguments)
			*/
		}
	}
	process.nextTick(function(){
		context.depends(target);
	});
	return context;
}