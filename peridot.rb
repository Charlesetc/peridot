
def error(reason)
  print "Error: ", reason
  puts "."
  exit 0
end

def arity(note, tree, expected)
  if expected != tree.length - 1
    error("expected #{expected} argument(s), got #{found} for #{note}")
  end
end

class Peridot

  attr_reader :builtins, :macro_builtins, :scoped_macro_builtins

  def initialize()
    @locals = [{}]

    @macro_builtins = {
      "define" => lambda do |tree|
        arity(:define, tree, 2)
        define tree[1], execute(tree[2])
      end,
      "do" => lambda do |tree|
        tree.shift
        tree.map do |item|
          execute item
        end.last
      end,
    }

    @builtins = {
      "print" => lambda do |args|
        puts args.map { |a| a.to_s }.join(" ")
      end,
    }
  end

  def define(name, value)
    # only call define with a define block.
    # since it's a define block, it starts a
    # new scope, but we want the value to live
    # outside of the define block, so edit
    # the scope before that one.
    @locals[-2][name] = value
    value
  end

  def newscope
    @locals << {}
  end

  def dropscope
    @locals.pop
  end

  def retrieve(name)
    @locals.each do |l|
      v = l[name]
      return v if v
    end
    return nil
  end


  def execute(tree)
    case [tree.class]
    when [String] then
      retrieve(tree) or error("#{tree} not defined")
    when [Proc] then tree
    when [Box] then tree
    when [NilClass] then []
    when [Array] then 

      return tree if tree.empty?

      if tree.first.class == String then
        if btn = macro_builtins[tree.first]
          newscope
          tree = btn.call(tree)
          rv = execute tree
          dropscope
          return rv
        end


        # otherwise a builtin function
        btn = builtins[tree.first]
        tree[0] = btn if btn
      end

      newscope
      tree.map! { |t| execute(t) }
      dropscope

      function = tree.shift

      return [] if function.class == Array

      function.call(tree) or []
    end

  end

end
