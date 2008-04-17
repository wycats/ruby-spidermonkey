require "spidermonkey"
require "readline"
# require "#{File.dirname(__FILE__)}/env/env"

def copy_history
  new_history = []
  until Readline::HISTORY.empty?
    new_history.push(Readline::HISTORY.pop)
  end
  new_history
end

def paste_history(old_history)
  until old_history.empty?
    Readline::HISTORY << old_history.pop
  end
end

class SpiderMonkey::Value
  
  def to_proc
    if typeof == "function"
      proc {|*args| self.call_function("call", self, *args) }
    else
      raise TypeError, "You cannot convert a #{typeof} to a proc"
    end
  end
  
  def method_missing(meth, *args)
    if val = meth.to_s.match(/^(.*)=$/)
      set_property(val[1], *args)
    elsif !args.empty?
      call_function(meth.to_s, *args)
    else
      get_property(meth.to_s)      
    end
  end
  
  alias_method :[], :get_property
  alias_method :[]=, :set_property
  
end

CX = cx = SpiderMonkey::Context.new

global = cx.global

cx.global.function("print") {|x| puts x}

local_binding = binding

ruby_readline = []

loop do
  input = Readline.readline("js> ", true)
  break if input == "exit"
  if input == "ruby"
    js_readline = copy_history
    paste_history(ruby_readline)
    loop do
      input = Readline.readline("rb> ", true)
      break if input == "done"
      exit if input == "exit"
      begin
        puts "=> " + eval(input, local_binding).inspect
      rescue Object => e
        puts e.message
        puts e.backtrace
      end
    end
    ruby_readline = copy_history
    paste_history(js_readline)
    next
  end
  begin
    puts "=> " + cx.eval(input).inspect
  rescue Object => e
    puts e.message
    puts e.backtrace
  end
end