require 'cucumber/initializer'
require 'cucumber/core/ast/describes_itself'
require 'cucumber/core/ast/names'
require 'cucumber/core/ast/location'

module Cucumber
  module Core
    module Ast
      # Represents the root node of a parsed feature.
      class Feature #:nodoc:
        include Names
        include HasLocation
        include DescribesItself

        attr_accessor :language
        attr_reader :feature_elements
        attr_reader :comment, :background, :tags, :keyword, :location, :title

        include Cucumber.initializer(:location, :background, :comment, :tags, :keyword, :title, :description, :feature_elements)
        def initialize(*)
          super
          feature_elements.each { |e| e.feature = self }
        end

        attr_reader :gherkin_statement
        def gherkin_statement(statement=nil)
          @gherkin_statement ||= statement
        end

        def step_count
          units.inject(0) { |total, unit| total += unit.step_count }
        end

        def children
          [background] + @feature_elements
        end

        def accept(visitor)
          visitor.visit_feature(self) do
            comment.accept(visitor)
            tags.accept(visitor)
            visitor.visit_feature_name(keyword, indented_name)
            @feature_elements.each do |feature_element|
              feature_element.accept(visitor)
            end
          end
        end

        def indented_name
          indent = ""
          name.split("\n").map do |l|
            s = "#{indent}#{l}"
            indent = "  "
            s
          end.join("\n")
        end

        def source_tags
          @tags.tags
        end

        def source_tag_names
          source_tags.map { |tag| tag.name }
        end

        def accept_hook?(hook)
          @tags.accept_hook?(hook)
        end

        def backtrace_line(step_name, line)
          "#{location.on_line(line)}:in `#{step_name}'"
        end

        def short_name
          first_line = name.split(/\n/)[0]
          if first_line =~ /#{language.keywords('feature')}:(.*)/
            $1.strip
          else
            first_line
          end
        end

        def to_sexp
          sexp = [:feature, file, name]
          comment = @comment.to_sexp
          sexp += [comment] if comment
          tags = @tags.to_sexp
          sexp += tags if tags.any?
          sexp += [@background.to_sexp] if @background
          sexp += @feature_elements.map{|fe| fe.to_sexp}
          sexp
        end

        private

        def description_for_visitors
          :feature
        end

      end
    end
  end
end
