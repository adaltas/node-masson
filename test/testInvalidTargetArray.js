
var masson = require('masson'),
	assert = require('assert');

exports['test invalid target array'] = function(){
	var assertions = [];
	var m = masson({
		'target 1': function(){
			this.in(['unregistered target 1','unregistered target 2'],function(err){
				if(err){
					assertions.push(err.message);
				}
				this.out();
			});
		}
	},'target 1');
	
	m.on('error',function(context){
		assertions.push('error: '+context.target);
	});
	
	process.nextTick(function(){
		assert.deepEqual(
			['error: target 1','Invalid target: unregistered target 1'],
			assertions
		);
	});
};
