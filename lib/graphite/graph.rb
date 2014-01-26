module Graphite
  class Graph
    attr_accessor :targets,:params
    def initialize
      @targets = []
      @params = {}
    end
    def method_missing(sym)
      if @params.has_key?(sym.to_s)
        @params[sym.to_s]
      else
        super
      end
    end
    def self.from_url(url)
      graph = self.new
      uri = URI(url)
      url_params = CGI.parse(uri.query)
      target_parser = Graphite::TargetParser.new
      url_params.delete("target").each do |t|
        target_parser.parse!(t)
        graph.targets << target_parser.tree.to_model
      end
      url_params.keys.inject(graph.params) { |acc,key|
        acc[key] = if url_params[key].present? && url_params[key].size==1
                     url_params[key].first
                   else
                     url_params[key]
                   end
        acc
      }
      graph
    end
  end
end
