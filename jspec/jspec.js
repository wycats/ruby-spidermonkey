jspec = {
	fn_contents: function(fn) {
		return fn.toString().match(/^[^\{]*{((.*\n*)*)}/m)[1];
	},
	TOP_LEVEL: 0, DESCRIBE: 1, IT_SHOULD_PASS: 2, IT_SHOULD_FAIL: 3, 
	FAILURE: 4, DONE_EXAMPLE: 5, DONE_GROUP: 6,
	logger: function(state, message) {
		switch(state) {
			case jspec.TOP_LEVEL:
				console.group(message);
				break;
			case jspec.DESCRIBE:
				console.group(message);
				break;
			case jspec.IT_SHOULD_PASS:
				console.info(message);
				break;
			case jspec.IT_SHOULD_FAIL:
				console.group(message);
				break;
			case jspec.FAILURE:
				console.error(message);
				console.groupEnd();
				break;
			case jspec.DONE_EXAMPLE:
				console.groupEnd();
				break;
			case jspec.DONE_GROUP:
				console.groupEnd();
		}
		
	},
	describe: function(str, desc) {
		jspec.logger(jspec.TOP_LEVEL, str);
		var it = function(str, fn) {
			jspec.logger(jspec.DESCRIBE, str);
			fn();
			jspec.logger(jspec.DONE_EXAMPLE);			
		};
		var Expectation = function(p) { this.expectation = p; };
		Expectation.prototype.to = function(fn_str, to_compare, not) {
		  try {
			  var pass = jspec.matchers[fn_str].matches(this.expectation, to_compare);
				if(not) var pass = !pass;
			} catch(e) {
			  var pass = null;
			}
			var should_string = (jspec.matchers[fn_str].describe && 
			  jspec.matchers[fn_str].describe(this.expectation, to_compare, not)) || 
			  this.toString() + " should " + (not ? "not " : "") + fn_str + " " + to_compare;
			if(pass) {
				jspec.logger(jspec.IT_SHOULD_PASS, should_string + " (PASS)");
			}	else {
				jspec.logger(jspec.IT_SHOULD_FAIL, should_string + (pass == false ? " (FAIL)" : " (ERROR)"));
				jspec.logger(jspec.FAILURE, jspec.matchers[fn_str].failure_message(this.expectation, to_compare, not))
			}
		}
		Expectation.prototype.not_to = function(fn_str, to_compare) { this.to(fn_str, to_compare, true) }
		var expect = function(p) { return new Expectation(p) };
		x = desc.toString()
		var fn_body = this.fn_contents(desc);
		var fn = new Function("it", "expect", fn_body);
		fn.call(this, it, expect);
		jspec.logger(jspec.DONE_GROUP);
	}
}

// Helper for 

jspec.print_object = function(obj) {
  if(obj instanceof Function) {
    return obj.toString().match(/^([^\{]*) {/)[1];
	} else if(obj instanceof Array) {
		return obj.toSource();
	// } else if(obj instanceof HTMLElement) {
	// 	return "<" + obj.tagName + " " + (obj.className != "" ? "class='" + obj.className + "'" : "") + 
	// 		(obj.id != "" ? "id='" + obj.id + "'" : "") + ">";
  } else if(obj) {
    return obj.toString().replace(/\n\s*/g, "");
  }
}

// Matchers begin here

jspec.matchers = {};

jspec.matchers["=="] = {
  describe: function(self, target, not) {
    return jspec.print_object(self) + " should " + (not ? "not " : "") + "equal " + jspec.print_object(target)
  },
	matches: function(self, target) {
		return self == target;
	},
	failure_message: function(self, target, not) {
		if (not)
			return "Expected " + jspec.print_object(self) + " not to equal " + jspec.print_object(target);
		else
			return "Expected " + jspec.print_object(self) + ". Got " + jspec.print_object(target);
	}
}

jspec.matchers["include"] = {
	matches: function(self, target) {
		for(i=0,j=self.length;i<j;i++) {
			if(target == self[i]) return true;
		}
		return false;
	},
	failure_message: function(self, target, not) {
		return "Expected " + jspec.print_object(self) + " " + (not ? "not " : "") + "to include " + target;
	}  
}

jspec.matchers["exist"] = {
  describe: function(self, target, not) {
    return jspec.print_object(self) + " should " + (not ? "not " : "")  + "exist."
  },
  matches: function(self, target) {
    return !!this;
  },
  failure_message: function(self, target, not) {
    return "Expected " + (not ? "not " : "") + "to exist, but was " + jspec.print_object(self);
  }
}

jspec.logger = function(state, message) {
	switch(state) {
		case jspec.TOP_LEVEL:
			console.top_level(message);
			break;
		case jspec.DESCRIBE:
			console.describe(message);
			break;
		case jspec.IT_SHOULD_PASS:
			console.pass(message);
			break;
		case jspec.IT_SHOULD_FAIL:
			console.fail(message);
			break;
		case jspec.FAILURE:
			console.failure(message);
			console.groupEnd();
			break;
		case jspec.DONE_EXAMPLE:
			console.groupEnd();
			break;
		case jspec.DONE_GROUP:
			console.groupEnd();
	}
}

jspec.describe("JSpec", function() {
	it("should support ==", function() {
		expect(1).to("==", 1);
		var arr = [];
		expect(arr).to("==", arr);
		var obj = new Object;
		expect(obj).to("==", obj);
		expect(document).to("==", document);
	});

  it("should support include", function() {
    expect([1,2,3,4,5]).to("include", 3);
    expect([1,2,3,4,5]).not_to("include", 6);
    expect(document.getElementsByTagName("div")).to("include", document.getElementById("hello"))
  });
   
  it("should support exists", function() {
    expect(document).to("exist");
  });
   
  jspec.matchers["have_tag_name"] = {
   	describe: function(self, target, not) {
     	return jspec.print_object(self) + " should " + (not ? "not " : "") + "have " + target + " as its tag name."
   },
   matches: function(self, target) {
     return (self.tagName && self.tagName == target) ? true : false;
   },
   failure_message: function(self, target, not) {
     return "Expected " + jspec.print_object(self) + (not ? " not " : " ") + "to have " + target + " as its tag name," +
       " but was " + self.tagName;
   }
  };
  
  it("should support custom matchers", function() {
   expect(document.getElementById("wrapper")).to("have_tag_name", "DIV");
   expect(document.getElementById("wrapper")).not_to("have_tag_name", "SPAN");
  });
});
