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
		this.depends(['aa','ab','ac'],function(){
			this.next();
		});
	},
	'aa': function(){
		this.depends(['aaa','aab'],function(){
			this.next();
		});
	},
	'aaa': function(){
		this.next();
	},
	'aab': function(){
		this.next();
	},
	'ab': function(){
		this.depends('aba',function(){
			this.next();
		});
	},
	'aba': function(){
		this.next();
	},
	'ac': function(){
		this.depends(['aca'],function(){
			this.next();
		});
	},
	'aca': function(){
		this.depends('acaa',function(){
			this.next();
		});
	},
	'acaa': function(){
		this.next();
	},
	'target 2': function(){
	}
},'a');
m.on('before',function(){
	assertions.push('before '+this.target);
})
m.on('after',function(){
	assertions.push('after '+this.target);
})

process.nextTick(function(){
	assert.deepEqual(
		['before a','before aa','before aaa','after aaa','before aab','after aab','after aa','before ab','before aba','after aba','after ab','before ac','before aca','before acaa','after acaa','after aca','after ac','after a'],
		assertions
	);
});