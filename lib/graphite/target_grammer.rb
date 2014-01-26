module Graphite
  module TargetGrammer

    class SyntaxNode < Treetop::Runtime::SyntaxNode
      def text
        self.text_value
      end
    end

    class Target < SyntaxNode
      def path?
        elements[0].kind_of?(Graphite::TargetGrammer::Path)
      end
      def expression?
        elements[0].kind_of?(Graphite::TargetGrammer::Expression)
      end
      def unknown?
        !path? && !expression?
      end
      def color
        unless @color
          e = self.expressions.detect {|e| e.identifier.try(:text) == "color" }
          if e && e.args && e.args.elements
            color_val = e.args.elements.last.detect { |e| e.kind_of?(Graphite::TargetGrammer::StringLiteral)  }
            unless color_val.nil?
              @color = color_val.text
            end
          end
        end
        @color
      end
      def alias
        unless @alias
          e = self.expressions.detect {|e| e.identifier.try(:text) == "alias" }
          if e && e.args && e.args.elements
            alias_val = e.args.elements.last.detect { |e| e.kind_of?(Graphite::TargetGrammer::StringLiteral) }
            unless alias_val.nil?
              @alias = alias_val.text
            end
          end
        end
        @alias
      end
      def metric
        unless @metric
          @metric = if path?
            self.elements[0].text
          else
            path = self.detect { |e| e.kind_of?(Graphite::TargetGrammer::Path) }
            unless path.nil?
              path.text
            end
          end
        end
        @metric
      end
      def functions
        unless @functions
          @functions = self.expressions.map { |e| e.identifier.text }
        end
        @functions
      end
      def expressions
        unless @expressions
          @expressions = self.find_all { |e| e.kind_of?(Graphite::TargetGrammer::Expression) }
        end
        @expressions
      end
      def to_model
        Graphite::Target.new do |model|
          model.alias = self.alias
          model.color = self.color
          model.metric = self.metric
          model.functions = self.functions
        end
      end
    end

    class IntegerLiteral < SyntaxNode
    end

    class StringLiteral < SyntaxNode
      def text
        eval self.text_value
      end
    end

    class FloatLiteral < SyntaxNode
    end

    class Identifier < SyntaxNode
    end

    class Expression < SyntaxNode
    end

    class PathSegment < SyntaxNode
    end

    class Path < SyntaxNode
    end

    class Arg < SyntaxNode
    end

  end
end

