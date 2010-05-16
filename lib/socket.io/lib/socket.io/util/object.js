// Based on Mixin.js from MooTools (MIT)
// Copyright (c) 2006-2009 Valerio Proietti, <http://mad4milk.net/>

var clone = this.clone = function(item){
	var ret;
	if (item instanceof Array){
		ret = [];
		for (var i = 0; i < item.length; i++) ret[i] = clone(item[i]);
		return ret;
	} else if (typeof item == 'object') {
		ret = {};
		for (var key in item) ret[key] = clone(item[key]);
		return ret;
	} else {
		return item;
	}
}, 

mergeOne = function(source, key, current){
	if (current instanceof Array){
		source[key] = clone(current);
	} else if (typeof current == 'object'){
		if (typeof source[key] == 'object') object.merge(source[key], current);
		else source[key] = clone(current);
	} else {
		source[key] = current;
	}
	return source;
};

this.merge = function(source, k, v){
	if (typeof k == 'string') return mergeOne(source, k, v);
	for (var i = 1, l = arguments.length; i < l; i++){
		var object = arguments[i];
		for (var key in object) mergeOne(source, key, object[key]);
	}
	return source;
};