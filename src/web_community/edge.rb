class Edge
  attr_accessor :id, :from_node, :to_node

  def initialize(from, to)
    @from_node = from
    @to_node = to
  end
end
