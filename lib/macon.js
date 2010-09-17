
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
	/*
		Stack elements are structured as
			array of target names
			callback when all targets are executed
			parent context
	*/
	var stack = [],
		masson = this;
	this.__proto__ = EventEmitter.prototype;
	var Context = function(target){
		this.target = target;
	}
	Context.prototype.in = function(/*target,arguments...*/){
		var args = Array.prototype.slice.call(arguments);
		var targets = args.shift();
		var callback = args.shift();
		if(typeof targets == 'string'){
			targets = [targets];
		}
		if(callback){
			stack.unshift([callback,this,[]]);
		}
		targets.reverse().forEach(function(target){
			stack.unshift([target,null,[]]);
		});
		run(this);
	}
	Context.prototype.out = function(parent){
		masson.emit('after',this);
		run(this);
	}
	var run = function(parentContext){
		if(!stack.length){
			return;
			throw new Error('Invalid call');
		}
		var el = stack.shift();
		var callback = el[0],
			context = el[1],
			args = el[2];
		if(typeof callback == 'string'){
			if(!context){
				context = new Context(callback);
			}
			var target = callback;
			callback = conf[target];
			if(!callback){
				// find a callback and send it error
				while(typeof stack[0][0] == 'string'){
					stack.shift();
				}
				masson.emit('error',parentContext);
				stack[0][2] = [new Error('Invalid target: '+target)];
				return run();
			}
			masson.emit('before',context);
		}
		callback.apply(context,args);
	}
	var context = new Context();
	process.nextTick(function(){
		context.in(target);
	});
	return this;
}