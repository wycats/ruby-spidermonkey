window.load = function(file) {
	var text = File.read(file);
	eval(text);
};

window.navigator = {
	get userAgent(){
		return "Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.3) Gecko/20070309 Firefox/2.0.0.3";
	}
};

window.__defineSetter__("location", function(url) {
	var text = File.read(url);
	window.document = text;
});

window.__defineSetter__("document", function(text) {
	window.__document__ = DOMDocument.create(text);
});

window.__defineGetter__("document", function() {
	return window.__document__;
});

load("env/jquery.js")
window.location = "env/html.html"