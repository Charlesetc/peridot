
def error(reason)
  print "Error: ", reason
  puts "."
  exit 0
end

def arity(note, tree, expected)
  if expected != tree.length - 1
    error("expected #{expected} argument(s), got #{tree.length} for #{note}")
  end
end

class Peridot

  attr_reader :builtins, :macro_builtins

  def initialize()
    @locals = [{}]

    @macro_builtins = {
      "define" => lambda do |tree|
        arity(:define, tree, 2)
        name = tree[1]
        value = execute tree[2]

        # this needs a -2 because
        # we want the binding to live
        # outside of the define part
        @locals[-2][name] = value
        value
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

  def newscope
    @locals << {}
  end

  def dropscope
    @locals.pop
  end

  def retrieve(name)
    @locals.reverse.each do |l|
      v = l[name]
      return v if v
    end
    return nil
  end

  def function_apply(tree)
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

    case [function.class]
    when [Array] then []
    when [Lambda] then
      arity("lambda", [function] + tree, function.arguments.length)

      newscope
      function.arguments.each_with_index do |name, i|
        @locals.last[name] = tree[i]
      end
      rv = execute function.block
      dropscope

      return rv
    else
      function.call(tree) or []
    end
  end

  def execute(tree)
    case [tree.class]
    when [String] then retrieve(tree) or error("#{tree} not defined")
    when [Proc] then tree
    when [Box] then tree
    when [NilClass] then []
    when [Lambda] then tree
    when [Array] then function_apply tree
    else
      raise "Undefined! Don't know class #{tree.class} of #{tree}" 
    end
  end

end
