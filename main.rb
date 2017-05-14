
require "./data"
require "./peridot"
require 'pry'

LEFT = '['
RIGHT = ']'


module Parser

  def Parser.read(s)
    lambdas(trees(tokenize(s)))
  end

  def Parser.tokenize(s)
    
    tokens = []
    chars = s.chars
    current = ""

    rmacros = {
      '"' => lambda {
        while (p = chars.shift) != '"' do
          if not p
            error("end of file when reading string")
          end
          current += p
        end
        tokens << Box.new(current, :string)
        current = ""
      },
      LEFT => lambda {
        tokens << LEFT
      },
      RIGHT => lambda {
        tokens << RIGHT
      },
      "\n" => lambda {
        tokens << current
        current = ""
      },
      " " => lambda {
        tokens << current
        current = ""
      },
      "#" => lambda {
        while (p = chars.shift) and p != "\n"
        end
      }
    }

    while c = chars.shift do
      f = rmacros[c]
      if f
        tokens << current
        current = ""
        f.call()
      else
        current += c
      end
    end
    if not current.empty?
      tokens << current
    end

    tokens.select { |c| not c.empty? }
  end

  def Parser.trees(tokens)
    stack = []

    tokens.each do |tok|
      stack << tok
      if tok == RIGHT
        i = stack.rindex(LEFT)
        if not i
          raise "not matching: found extra " + RIGHT
        end
        args = stack.last(stack.length - i)
        args.shift ; args.pop # parentheses
        stack = stack.first(i)
        stack << args
      end
    end

    if stack.rindex(LEFT)
      raise "not matching: found extra " + LEFT
    end

    ["do"] + stack
  end

  def Parser.lambdas(trees)
    newtrees = []

    while not trees.empty? do
      tree = trees.shift

      if tree.class == Array
        tree = lambdas(tree)
      end

      if tree == ":"

        arguments = trees.take_while { |x| x.class != Array }
        trees.shift(arguments.length)
        block = trees.shift # get that array too

        tree = Lambda.new(arguments, block)
      end

      newtrees << tree
    end

    newtrees
  end

end

peridot = Peridot.new

# Kind of repl
# loop do
#   trees = Parser.read(readline.chomp)
#   peridot.execute(trees)
# end

# non-repl version:
trees = Parser.read(ARGF.read)

peridot = Peridot.new
peridot.execute(trees)
