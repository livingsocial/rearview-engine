
module Graphite
  class TargetParser
    class TargetParserError < StandardError
      attr_accessor :parser_details
      def initialize(parser_details)
        @parser_details = parser_details
      end
      def to_s
        "parse failure %{message}" % parser_details
      end
    end
    attr_reader :parser,:tree
    attr_accessor :data
    def initialize(data=nil)
      @data = data
      @parser = TargetGrammerParser.new
    end
    def parse(data=nil)
      if data.present?
        @data = data
      end
      @tree = @parser.parse(@data)
    end
    def parse!(data=nil)
      self.parse(data)
      if error?
        raise TargetParserError.new(error)
      end
      @tree
    end
    def self.parse(data)
      inst = self.new(data)
      inst.parse
      inst
    end
    def error?
      @tree.nil?
    end
    def error
      { message: @parser.failure_reason, line: @parser.failure_line, column: @parser.failure_column }
    end
    def self.grammer
      File.expand_path("lib/graphite/target_grammer.treetop")
    end
  end
end

Treetop.load(Graphite::TargetParser.grammer)

