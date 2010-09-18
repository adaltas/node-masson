
// Class - Masson - Copyright David Worms <open@adaltas.com> (MIT Licensed)

var sys = require('sys'),
	opts = require('opts'),
	EventEmitter = require('events').EventEmitter,
	fs = require('fs'),
	assert = require('assert'),
	spawn = require('child_process').spawn,
	step = require('step');

var Masson = function(c,target,args){
	/*
		Stack elements are structured as
			target name or callback function
			context object in case of a callback
			arguments
	*/
	var conf = {},
		stack = [],
		self = this;
	if(c instanceof Array){
		var confAsObject = {};
		c.forEach(function(el){
			conf[el.target||el.name] = [el.in||el.depends||null,el.callback];
		});
	}else{
		for(var k in c){
			conf[k] = [null,c[k]];
		}
	}
	delete c;
	var Context = function(target){
		this.target = target;
	}
	Context.prototype.in = function(/*target,arguments...*/){
		var args = Array.prototype.slice.call(arguments);
		var targets,
			params,
			callback;
		if(args.length===1){
			targets = args.shift();
			params = [];
			callback = null;
		}else if(args.length===2){
			targets = args.shift();
			params = [];
			callback = args.shift();
		}else if(args.length===3){
			targets = args.shift();
			params = args.shift();
			callback = args.shift();
		}
		if(typeof targets == 'string'){
			targets = [targets];
		}
		if(callback){
			stack.unshift([callback,this,[null].concat(params)]);
		}
		targets.reverse().forEach(function(target){
			stack.unshift([target,null,params]);
		});
		run(this);
	}
	Context.prototype.out = function(){
		var args = Array.prototype.slice.call(arguments);
		for(var i=0;i<stack.length;i++){
			if(typeof stack[i][0] == 'function'){
				stack[i][2].push(args);
				break;
			}
		}
		self.emit('after',this,args);
		run(this);
	}
	var run = function(parentContext){
		if(!stack.length){
			return;
		}
		var el = stack.shift();
		var callback = el[0],
			context = el[1],
			args = el[2];
		if(typeof callback == 'string'){
			context = new Context(callback);
			var target = callback;
			var targetConf = conf[target];
			if(!targetConf){
				// find a callback and send it error
				while(typeof stack[0][0] == 'string'){
					stack.shift();
				}
				self.emit('error',parentContext);
				stack[0][2] = [new Error('Invalid target: '+target)];
				return run();
			}
			if(targetConf[0]){
				// dependencies
				var pre = targetConf[0];
				targetConf[0] = null;
				stack.unshift(el);
				return context.in(pre);
			}
			callback = targetConf[1];
			self.emit('before',context);
		}
		callback.apply(context,args);
	}

	this.run = function(target,args){
		process.nextTick(function(){
			(new Context()).in(target,args||[],null);
		});
		return this;
	};
	if(target){
		this.run(target,args);
	}
}

Masson.prototype.__proto__ = EventEmitter.prototype;

module.exports = function(configuration,target,args){
	return new Masson(configuration,target,args);
}