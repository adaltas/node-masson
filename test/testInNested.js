/*
         aaa
       /
    aa \
  /      aab
a - ab - aba
  \
    ac - aca - acaa
*/

var sys = require("sys"),
	assert = require("assert"),
	macon = require(__dirname+'/../lib/macon'),
	assertions = [];
	
var m = macon({
	'a': function(){
		this.in(['aa','ab','ac'],function(){
			this.out();
		});
	},
	'aa': function(){
		this.in(['aaa','aab'],function(){
			this.out();
		});
	},
	'aaa': function(){
		this.out();
	},
	'aab': function(){
		this.out();
	},
	'ab': function(){
		this.in('aba',function(){
			this.out();
		});
	},
	'aba': function(){
		this.out();
	},
	'ac': function(){
		this.in(['aca'],function(){
			this.out();
		});
	},
	'aca': function(){
		this.in('acaa',function(){
			this.out();
		});
	},
	'acaa': function(){
		this.out();
	},
	'target 2': function(){
	}
},'a');
m.on('before',function(context){
	assertions.push('before '+context.target);
})
m.on('after',function(context){
	assertions.push('after '+context.target);
})

process.nextTick(function(){
	assert.deepEqual(
		['before a','before aa','before aaa','after aaa','before aab','after aab','after aa','before ab','before aba','after aba','after ab','before ac','before aca','before acaa','after acaa','after aca','after ac','after a'],
		assertions
	);
});