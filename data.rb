
Lambda = Struct.new(:arguments, :block)
Box = Struct.new(:value, :type)

class Box
  alias :struct_inspect :inspect

  def empty?
    return false 
  end

  def to_s
    return value if type == :string
    struct_inspect
  end
end

class Object

  def box?(type)
    return false if self.class != Box
    self.type == type
  end

end

