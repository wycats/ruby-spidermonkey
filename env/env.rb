require 'spidermonkey'
require 'rubygems'
require 'hpricot'
require 'xml/libxml'
require 'delegate'

class SpiderMonkey::Context
  
  def eval_file(file)
    text = File.read(file)
    begin
      self.eval(text)
    rescue SpiderMonkey::EvalError => e
      puts "An error has occured in #{file} on line #{e.lineno}"
      puts e.message
    end
  end
  
end

module JavaScript
  class Console

    def initialize
      @level = 0
    end

    def print_level
      print "  " * @level
    end
    
    def top_level(msg)
      puts msg
    end

    def describe(msg)
      @level += 1
      print_level
      puts msg
    end
    
    def pass(msg)
      print_level
      puts "* #{msg}"
    end
    
    def fail(msg)
      print_level
      puts "X #{msg}"
      @level += 1
    end
    
    def failure(msg)
      print_level
      puts "E #{msg}"
      # @level -= 1
    end
    
    def groupEnd(*args)
      @level -= 1
    end
  end
end
  
require 'rubygems'
require 'hpricot'

class String
  # "FooBar".snake_case #=> "foo_bar"
  def snake_case
    gsub(/\B[A-Z]/, '_\&').downcase
  end

  # "foo_bar".camel_case #=> "FooBar"
  def camel_case
    split('_').map{|e| e.capitalize}.join
  end
end

class XML::Node::Set
  def array_like?() true end
end

module HtmlDom
  module Events
    def events
      @events ||= Hash.new {|h,k| h[k] = []}
    end

    def addEventListener(type, fn, *args)
      events[type] << fn
    end
    
    def removeEventListener(type, fn, *args)
      events[type].delete(fn)
    end
    
    def dispatchEvent(event, *args)
      events[event["type"]].each {|e| e.call_function("call", self, event)}
    end
  end
end

class XML::Node
  include HtmlDom::Events
    
  def getElementById(theId)
    find("//*[@id='#{theId}']").set[0]
  end
    
  def getElementsByTagName(name)
    find("//#{name}").set
  end
  
  def tagName
    name.upcase
  end
  
  def nodeType() node_type end
  def nodeValue
    case node_type
    when 3, 4, 7, 8 then content  # TEXT_NODE, CDATA_SECTION, PROCESSING_INSTRUCTION_NODE, COMMENT_NODE
    else nil
    end
  end
  
  alias_method :old_brackets, :[]
  alias_method :set_old_brackets, :[]=
  
  def key?(key)
    @props ||= {}
    !!@props[key] || (!self.methods.include?(key) && !self.methods.include?(key.to_sym))
  end
  
  def [](key) @props ||= {}; @props[key] || "" end
  def []=(key, value) @props ||= {}; @props[key] = value || "" end

  def getAttribute(key) self[key] end
  def setAttribute(key, value) self[key] = value end
  def removeAttribute(key) self[key] = nil end

  def id() self["id"] || "" end
  def id=(theId) self["id"] = theId || "" end

  def className() self["class"] || "" end
  def className=(name) self["class"] = name || "" end 
  
  def cloneNode(deep = true) copy(deep) end
  def nodeName() tagName end
  def ownerDocument() doc.root end
  def documentElement() doc.root end

  def parentNode() parent end
  def nextSibling() next_sibling end
  def previousSibling() prev end
  def childNodes
    x = []
    self.each_child {|c| x << c }
    x
  end
  def firstChild() childNodes[0] end
  def lastChild() childNodes[-1] end
    
  def appendChild(node)
    if child then last.next = node
    else child = node end
  end

  def insertBefore(node) prev = node end
  def removeChild(node) node.remove! if childNodes.include?(node) end
  
  def toString
    if node_type == 1
      "<#{tagName}#{" id=#{self["id"]}" unless self["id"].empty?}#{" class=#{className}" unless className.empty?}>"
    else
      "\"#{nodeValue}\""
    end
  end
  
  def outerHTML() to_s end
  def innerHTML() childNodes.to_s end
  
  def innerHTML=(html) 
    node = XML::Parser.string(html).parse.root; 
    children.remove!; 
    child_add(node) 
  end
  
  def textContent() content end
  def textContent=(content) content = content end
  
  def disabled() (this["disabled"] != "false") && !!this["disabled"] end

  def body() find("//body").set[0] end  
    
end

class DOMDocument
  def self.create(text)
    XML::Parser.string(Hpricot(text).to_s).parse.root
  end  
end


THREADS = []

CX = cx = SpiderMonkey::Context.new
JS_NULL = cx.eval("null")
cx.set_property("console", JavaScript::Console.new)
cx.set_property("window", cx.global)
cx.set_property("HTMLElement", XML::Node)
cx.set_property("DOMDocument", DOMDocument)
cx.global.function("print") {|x| puts x}
cx.global.function("setTimeout") {|f,t| Thread.new { sleep(t / 1000.0); f.call_function } }
cx.global.function("setInterval") {|f,t| THREADS.push(Thread.new { loop { sleep(t / 1000.0); f.call_function } }); THREADS.size - 1 }
cx.global.function("clearInterval") {|i| THREADS[i].kill }

cx.eval_file(File.dirname(__FILE__) + "/env.js")

# require 'ruby-debug'
# debugger

# cx.eval_file(File.dirname(__FILE__) + "/jspec.js")