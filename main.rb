
require "./peridot"

LEFT = '['
RIGHT = ']'

class Parser

  def parse(s)
    trees(tokenize(s))
  end

  def tokenize(s)
    
    tokens = []
    chars = s.chars
    current = ""

    rmacros = {
      '"' => lambda {
        while (p = chars.pop) != '"' do
          current = p + current
        end
        tokens.unshift(current)
        current = ""
      },
      LEFT => lambda {
        tokens.unshift(LEFT)
      },
      RIGHT => lambda {
        tokens.unshift(RIGHT)
      },
      "\n" => lambda {
        tokens.unshift(current)
        current = ""
      },
      " " => lambda {
        tokens.unshift(current)
        current = ""
      },
    }

    while c = chars.pop do
      f = rmacros[c]
      if f
        tokens.unshift(current)
        current = ""
        f.call()
      else
        current = c + current
      end
    end
    if not current.empty?
      tokens.unshift(current)
    end

    tokens.select { |c| not c.empty? }
  end

  def trees(tokens)
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
        stack << Tree.new(args)
      end
    end

    if stack.rindex(LEFT)
      raise "not matching: found extra " + LEFT
    end

    stack

  end

end

class Tree

  def initialize(children)
    @children = children
  end

  def inspect
    LEFT + @children.map{|s| s.inspect}.join(" ") + RIGHT
  end

  def to_s
    LEFT + @children.map{|s| s.to_s}.join(" ") + RIGHT
  end

end

trees = Parser.new.parse(ARGF.read)

Peridot.run(trees)
