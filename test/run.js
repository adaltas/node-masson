#!/usr/bin/env node

var sys = require('sys'),
	fs = require('fs'),
	exec = require('child_process').exec,
	nc = require('ncurses');

fs.readdir(__dirname,function(err,files){
	files.forEach(function(file){
		if(file.substr(0,4)=='test'){
			exec('node '+file, function(error, stdout, stderr){
				sys.puts('Running '+file);
				if (error !== null) {
					sys.puts("\033[31m"+error+"\033[0m");
				}else if(stderr){
					sys.puts("\033[31m"+stdout+"\033[0m");
				}else if(stdout){
					sys.puts("\033[32m"+stdout+"\033[0m");
				}else{
					sys.puts("\033[32m"+'ok'+"\033[0m");
				}
			})
		}
	});
});

