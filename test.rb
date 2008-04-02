#!/bin/env ruby
require 'test/unit'
require './spidermonkey'
p SpiderMonkey::LIB_VERSION
class SpiderMonkeyTest < Test::Unit::TestCase
	def setup
		$stdout.flush
		GC.start
	end
	def teardown
		GC.start
	end

	def test_newvalue
		assert_kind_of( SpiderMonkey::Value, 
		                SpiderMonkey::evalget( "1" ) );
	  assert_raise( SpiderMonkey::Error ){ 
		  SpiderMonkey::Value.new
		}
	  assert_raise( TypeError ){ 
		  SpiderMonkey::eval( 1 )
		}
	  assert_raise( TypeError ){ 
		  SpiderMonkey::eval( ArgumentError )
		}
	end

	def test_03_context
		cont = SpiderMonkey::Context.new
	  assert_equal 1, cont.evaluate(%! x=1 !)
	  assert_equal 1, cont.evaluate(%! x !)
		cont2 = SpiderMonkey::Context.new
	  assert_equal 2, cont2.evaluate(%! x=2 !)
	  assert_equal 1, cont.evaluate(%! x !)
	  assert_equal 2, cont2.evaluate(%! x !)
	end

  def test_1_evalate
	  assert_nothing_thrown {|| SpiderMonkey::evaluate(%! 1 !) }
		assert_raise( SpiderMonkey::EvalError ){|| 
			SpiderMonkey::evaluate(%! fdsa"d !) 
		}

		rberror = nil
		begin
			SpiderMonkey::evaluate(%! fdsa"d !)
		rescue SpiderMonkey::EvalError=>e
			rberror = e
		end
		assert_equal 1, e.lineno, "lineno"
		assert_match /SyntaxError/, e.message   , "message"
		assert_equal 138, e.error_number, "error_number"
	end

	def test_convertvalue
	  cx = SpiderMonkey::Context.new
		assert_equal nil, cx.evaluate(%! null !), "convert null"
		assert_equal 1, cx.evaluate(%! 1 !), "convert 1"
		assert_equal 2, cx.evaluate(%! 2 !), "convert 2"
		assert cx.evaluate(%! void(0) !).nil?, "undefined"
		assert !cx.evaluate(%! 1/0 !).finite?, "1/0"
		assert_equal [], cx.evaluate(%! [] !), "convert empty array"
		assert_equal [1], cx.evaluate(%! [1] !), "convert array"
		assert_equal "1", cx.evaluate(%! "1" !), "convert string 1"
		assert_equal "a", cx.evaluate(%! "a" !), "convert string a"
		assert_equal 1.2 , cx.evaluate(%! 1.2 !), "convert float value"
		assert_equal ({ "a" =>1  }), cx.evaluate(%! x={a:1} !), "convert object"
		assert_equal ({ "a" =>1 , "b"=>"c" }), cx.evaluate(%! x={a:1, b:"c"} !), "convert object 2"
		assert_equal "ge", cx.evaluate(<<-JS),"func"
			function x(){
			  return "ge";
			}
			x();
		JS
	end
	def test_convertvalue2
	  cx = SpiderMonkey::Context.new
	  assert_equal "ge", cx.evaluate(<<-JS),"object new"
			function x(){
			  function method(){
				  return "ge";
				}
				this.m = method;
			}
			y = new x();
			y.m();
		JS
	end

	def test_evaluate
	  cx = SpiderMonkey::Context.new
	  assert_equal 1, cx.evaluate(%! 1 !), "convert 1"
	  assert_equal 2, cx.evaluate(%! 1+1 !)
	  assert_equal "11", cx.evaluate(%! "1"+"1" !)
	  assert_equal Math::PI, cx.evaluate(%! Math.PI !)
	end

	def test_10_context
		cx = SpiderMonkey::Context.new
		assert_kind_of( SpiderMonkey::Value, cx.global )
		assert_kind_of( SpiderMonkey::Value, 
		                cx.evalget( "1" ) );
	end

	def test_value_to
	  cx = SpiderMonkey::Context.new
	  var = cx.evalget( "1" );
		assert_equal 1, var.to_i
		assert_equal "1", var.to_s
		assert_equal 1.0, var.to_f
		assert_equal true, var.to_bool
		assert_equal false, cx.evalget( "0").to_bool
		assert_equal nil.to_a, cx.evalget("null").to_a
		assert_equal ({"a"=>"hoge"}.to_a), cx.evalget("x={a:'hoge'}").to_a
	end
	def test_value_to_h
	  cx = SpiderMonkey::Context.new
		assert_equal( { 0 => 1 , 1 => 2 }, cx.evalget( "[1,2]" ).to_h)
		assert_equal( { }, cx.evalget( "null" ).to_h)
	end

	def test_value_between_contexts
		cx2 = SpiderMonkey::Context.new
		proc{
			cx = SpiderMonkey::Context.new
			x= cx.evalget( "[1,2]" )
			assert_equal 2, x.get_property("length")
			assert_raise(NoMethodError){||  x.length }
			cx2.set_property( "hoge",x );
		}.call
		GC.start
		assert_equal 2, cx2.eval( "hoge.length" );
	end
	def test_value_typeof
	  cx = SpiderMonkey::Context.new
	  assert_equal "number", cx.evalget( "1" ).typeof
	  assert_equal "string", cx.evalget( "'1'" ).typeof
	  assert_equal "undefined", cx.evalget( "void(0)" ).typeof
	  assert_equal "object", cx.evalget( "null" ).typeof
	  assert_equal "object", cx.evalget( "({})" ).typeof
	  assert_equal "object", cx.evalget( "[]" ).typeof
	  assert_equal "object", cx.evalget( "new Date()" ).typeof
	  assert_equal "boolean", cx.evalget( "true" ).typeof
	end

	def test_value_set_property
	  cx = SpiderMonkey::Context.new
	  x = cx.eval("x={}")
		x.set_property("prop", 1)
		assert_equal 1, cx.evaluate("x.prop");
		cx.evaluate("x.prop=2");
		assert_equal 2, x.get_property("prop")
	end

	def test_deffunc
		cx = SpiderMonkey::Context.new
	  x = cx.eval("x={jsfunc:function(){return 3}}")
		assert_equal "function", cx.evaluate("typeof( x.jsfunc)") 
		count = 0;
		assert_equal 3, cx.evaluate("x.jsfunc()") 
		x.function( "func1" ){|*arg|
			count += 1;
			assert_equal 1, arg[0]
			assert true, "block called"
			1
		}
		assert_equal 0, count, "function not called yet"
		assert_equal 1, cx.evaluate("x.func1(1)")
		assert_equal 1, count, "function called"
		
		x.function( "func2" ){|*arg|
			arg[0] + 1
		}
		assert_equal 3, cx.evaluate("x.func2(2)")
		
		assert_equal "[object RubyFunction]", cx.evaluate('""+ x.func1')
		assert_raise(SpiderMonkey::EvalError){
			cx.eval(' y=x.func1; y.apply("hoge",1);')
		}
	end
	def test_function_type
		cx = SpiderMonkey::Context.new
	  x = cx.eval("x={jsfunc:function(){return 3}}")
		x.function( "func1" ){|*arg| nil }
		assert_equal "function", cx.evaluate("typeof( x.jsfunc)") 
		assert_equal "function", cx.evaluate("typeof x.func1"), "function defined and type is function"
	end

	class TESTException < StandardError
	end
	
	def test_deffunc_exception
		cx = SpiderMonkey::Context.new
	  x = cx.eval("x={}")
		pr = x.function( "func1" ){|*arg|
			raise TESTException.new("test")
		}
		assert_raise( TESTException ){
			pr.call();
		}
		assert_raise( TESTException ){
			cx.eval("x.func1()")
		}
		assert_raise( TESTException ){
			x.call_function("func1")
		}
		assert_nothing_thrown {
			cx.eval(" try{ x.func1(); }catch(e){} ")
		}
		assert_equal "test", cx.eval(" try{ x.func1(); }catch(e){e.toString()} ")
		assert_equal TESTException, cx.eval(" y=null; try{ x.func1(); }catch(e){ y=e.class; } y")
		
	end

	def test_call_function
	  cx = SpiderMonkey::Context.new
	  x = cx.eval("x={no_args:function(){return 'no args'}, fun1:function(a){return a+1;} }")
		assert_equal 'no args', x.call_function("no_args")
		assert_equal 2, x.call_function( "fun1", 1 )
	end

	class Hoge
		attr_reader :args
		def para;  1; end
		def add1(a); a.to_i + 1; end;
		def add2(*a); @args = a; end;
	end
	def test_set_property
		hoge = Hoge.new
		cx = SpiderMonkey::Context.new
		cx.set_property( "hoge", hoge );
		assert_equal 1, cx.evaluate( %! hoge.para ! ) , "no need arguments method is property"
		assert_equal 2, cx.evaluate( %! hoge.add1( 1 ) ! );
		
		cx.set_property( "Time", Time );
		script ='Time.at(100).strftime("%Y/%m/%d")'
		assert_equal eval(script), cx.eval( script ), script 

		cx.set_property( "RubyMath", Math );
		assert_equal Math::PI ,cx.eval("RubyMath.PI") 

		assert_equal "object", cx.evaluate( %! typeof hoge ! );
		#begin
		#	assert_equal 1, cx.eval("hoge.para()")
		#	flunk "para is not function"
		#rescue SpiderMonkey::EvalError => e
		#	assert_match /TypeError/, e.message
		#end
	end
	
	class Hoge2
		attr_reader :args
		def para;  1; end
		def add1(a); a.to_i + 1; end;
		def add2(*a); @args = a; a.size end;
	end
	def test_property_and_method
		hoge = Hoge2.new
		cx = SpiderMonkey::Context.new
		cx.set_property( "hoge", hoge );
    assert_equal 1, cx.eval("hoge.para")
	end

	def test_class_set_property
		cx = SpiderMonkey::Context.new
		dog = Struct.new("Dog", :name, :age)
		x=dog.new
		x.name="hoge"
		assert_equal 'hoge', x.name
		cx.set_property( "x", x );
    assert_equal "hoge", cx.evaluate("x.name")
		assert_equal 'fuga', cx.eval("x.name='fuga'")
		assert_equal 'fuga', x.name
		assert_equal "undefined", cx.evalget("x.name2").typeof
		assert_raise(NameError){|| cx.eval("x.name2='fuga'") }
		assert_equal nil, cx.eval("x.name2")
		
		assert_raise(NoMethodError){|| x.name2 }
	end

	def test_contextversion
		cx = SpiderMonkey::Context.new
		assert_equal "default", cx.version
		cx.version = "1.5";
		assert_equal "1.5", cx.version
		assert_raise( SpiderMonkey::Error ){
			cx.version = "xxx1.0";
		}
	end

	def test_get_properties
		cx = SpiderMonkey::Context.new
		x = cx.eval("({a:1,b:2})");
		assert_equal ["a","b"], x.get_properties.sort
		y = cx.eval("[1,2]");
		assert_equal ["0","1"], y.get_properties
	end

	def test_gc
		cx = SpiderMonkey::Context.new
		x = cx.eval("[1]");
		assert_equal 1, x.get_property("length");
		y = cx.eval("[1,2]");
		cx.gc
		assert_equal 1, x.get_property("length");
	end

	def test_gc_check_1
		@gccheckval=nil
		proc{
			cx = SpiderMonkey::Context.new
			@gccheckval = cx.eval("x=[1]");
			assert_instance_of SpiderMonkey::Value, @gccheckval
			cx = nil;
		}.call
		GC.start
		assert_instance_of SpiderMonkey::Value, @gccheckval
		@gccheckval=nil
	end

	def test_same_jsval_is_same
		cx = SpiderMonkey::Context.new
		a = cx.evalget("1")
		x = cx.eval("x=[1]")
		assert_instance_of SpiderMonkey::Value, x
		y = cx.eval("x")
		assert_instance_of SpiderMonkey::Value, y
		assert_equal x,y
		q = cx.eval("{a:0}")
		assert_not_equal q,x
		z = cx.eval("z=[1]")
		cx.eval("z.push(1)")
		zc = cx.eval("z")
		assert_equal z,zc
		assert_not_equal x,z
		cx.gc
		b = cx.evalget("1")
		assert_equal a,b
	end

	def test_same_rubyval_is_same
		cx = SpiderMonkey::Context.new
		test = "hoge"
		cx.set_property("x", test)
		cx.set_property("y", test)
		assert_equal true, cx.eval("x==y")
		assert_equal true, cx.eval("x===y")
	end
	def test_same_rubyval_is_same2
		cx = SpiderMonkey::Context.new
	  z = cx.eval("z={}")
		z.function("hoge"){|x,y|
			x==y
		}
		assert_equal true, cx.eval("z.hoge(z,z)")
		assert_equal false, cx.eval("z.hoge(z,{})")
	end

	def test_set_function_by_code
		return # TODO: not yet implement
		cx = SpiderMonkey::Context.new
	  x = cx.eval("x={}")
		pr = x.function( "func1" , "a,b", "return a+b" )
		assert_equal "function",x.get_property("func1").typeof
		assert_equal 3, x.call_function("func1",1,2)
	end

	def test_each_hash
		cx = SpiderMonkey::Context.new
	  x = cx.eval("x={a:1, b:2}")
		r = []
		x.each{|a| r << a }
		assert_equal [1,2], r
		r2 = []
		for i in x
			r2 << i
		end
		assert_equal [1,2], r2
	end

	def test_each_prototype
		cx = SpiderMonkey::Context.new
	  z = cx.eval <<-JS
			Y=function(){ this.p1="Y"; }
			Z=function(){ this.p2="Z"; }
			Z.prototype = new Y;
			z = new Z;
		JS
		re = cx.eval <<-JS
			re = [];
			var i;
			for(i in z){ re.push(z[i]) }
			re
		JS
		r=[]
		z.each{|v| r<<v }
		assert_equal re.to_ruby.sort, r.sort
		assert_raise(TESTException){
			z.each{|v| raise TESTException, "test"}
		}
	end

	def test_each_other
		cx = SpiderMonkey::Context.new
	  x = cx.evalget("12")
		r = []
		x.each{|a| r << a }
		assert_equal [], r

		return # TODO: not yet implement
	  x = cx.evalget("'abc'")
		r = []
		assert_equal 'string', x.typeof
		x.each{|a| r << a }
		assert_equal ["a","b","c"], r
	end

	def test_each_array
		cx = SpiderMonkey::Context.new
	  x = cx.eval("[1,2]")
		r = []
		x.each{|a|
			r << a
		}
		assert_equal [1,2], r

		r = []
		for i in x
			r << i
		end
		assert_equal [1,2], r
	end

end


