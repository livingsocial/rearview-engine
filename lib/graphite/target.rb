module Graphite
  class Target
    attr_accessor :color,:alias,:metric,:functions
    def initialize
      yield self if block_given?
    end
  end
end

