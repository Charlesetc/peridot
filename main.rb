
require "./data"
require "./peridot"
require 'pry'

LEFT = '['
RIGHT = ']'


module Parser

  def Parser.parse(s)
    trees(tokenize(s))
  end

  def Parser.tokenize(s)
    
    tokens = []
    chars = s.chars
    current = ""

    rmacros = {
      '"' => lambda {
        while (p = chars.pop) != '"' do
          if not p
            error("end of file when reading string")
          end
          current = p + current
        end
        tokens.unshift(Box.new(current, :string))
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

end

trees = Parser.parse(ARGF.read)

peridot = Peridot.new
peridot.execute(trees)
