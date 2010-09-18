
var masson = require('masson');

exports['test EventEmitter support'] = function(assert){
	var assertions = [];
	var m = masson({
		'target 1': function(){
			this.out();
		},
		'target 2': function(){
			this.in('target 1',function(){
				this.out();
			});
		}
	},'target 2');
	masson({
		'target 1': function(){
			this.out();
		}
	},'target 1');
	m.on('before',function(context){
		assertions.push('before '+context.target);
	})
	m.on('after',function(context){
		assertions.push('after '+context.target);
	})
	
	process.nextTick(function(){
		assert.deepEqual(
			['before target 2','before target 1','after target 1','after target 2'],
			assertions
		);
	});
};
