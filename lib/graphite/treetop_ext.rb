
class Treetop::Runtime::SyntaxNode
  include Enumerable
  def each(&block)
    self.elements.each { |e| each_recursive(e,&block) }
  end
  def each_recursive(node,&block)
    yield node
    unless node.terminal?
      node.elements.each { |e| each_recursive(e,&block) }
    end
  end
end

