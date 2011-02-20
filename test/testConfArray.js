
var masson = require('masson'),
	assert = require('assert');

exports['test configuration as array'] = function(){
	var assertions = [];
	var m = masson([{
		target: 'target a',
		depends: ['target aa','target ab'],
		callback: function(){
			this.out();
		}
	},{
		target: 'target aa',
		depends: 'target aaa',
		callback: function(){
			this.out();
		}
	},{
		target: 'target aaa',
		callback: function(){
			this.out();
		}
	},{
		target: 'target ab',
		callback: function(){
			this.out();
		}
	}],'target a');
	
	m.on('before',function(context){
		assertions.push('before '+context.target);
	})
	m.on('after',function(context){
		assertions.push('after '+context.target);
	})
	
	process.nextTick(function(){
		assert.deepEqual(
			['before target aaa','after target aaa','before target aa','after target aa','before target ab','after target ab','before target a','after target a'],
			assertions
		);
	});
};
