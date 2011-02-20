
var masson = require('masson'),
	assert = require('assert');

exports['test invalid target string'] = function(){
	(function(){
	
	var a = []; 
	var m = masson({
		'target 1': function(){
			this.in('unregistered target',function(err){
				if(err){
					a.push(err.message);
				}
				this.out();
			});
		}
	},'target 1');
	
	m.on('error',function(context){
		a.push('Event: '+context.target);
	});
	
	process.nextTick(function(){
		assert.deepEqual(
			['Event: target 1','Invalid target: unregistered target'],
			a
		);
	});
	})()
};