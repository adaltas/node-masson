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
					sys.print("\033[31m"+error+"\033[0m");
				}
				if(stdout){
					sys.print("\033[32m"+stdout+"\033[0m");
				}
				if(stderr){
					sys.print("\033[31m"+stdout+"\033[0m");
				}
			})
		}
	});
});

