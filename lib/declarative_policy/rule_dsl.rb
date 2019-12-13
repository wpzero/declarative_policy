module DeclarativePolicy
  module Rule
    class Base
      def self.make(*args)
        new(*args).simplify
      end

      def pass?(context)
        raise 'abstract'
      end

      # true, false, or :none
      # :none represent no cache
      def cached_pass?(context)
        raise 'abstract'
      end

      def score(context)
        raise 'abstract'
      end

      def simplify
        self
      end

      # convenience combination methods
      def or(other)
        Or.make([self, other])
      end

      def and(other)
        And.make([self, other])
      end

      def negate
        Not.make(self)
      end

      alias_method :|, :or
      alias_method :&, :and
      alias_method :~@, :negate
    end

    class Condition < Base
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def score(context)
        context.callable_condition(@name).score
      end

      def pass?(context)
        context.callable_condition(@name).pass?
      end

      def cached_pass?(context)
        return :none unless context.callable_condition(@name).cached?
        context.callable_condition(@name).pass?
      end
    end

    class Ability < Base
      attr_reader :ability

      def initialize(ability)
        @ability = ability
      end

      def score(context)
        context.runner(ability).score
      end

      def pass?(context)
        context.runner(ability).pass?
      end

      def cached_pass?(context)
        return context.runner(ability).pass? if context.runner(ability).cached?
        :none
      end
    end

    class And < Base
      attr_reader :rules

      def initialize(rules)
        @rules = rules
      end

      def simplify
        simplified_rules = @rules.flat_map do |rule|
          simplified = rule.simplify
          case simplified
          when And then simplified.rules
          else [simplified]
          end
        end
        And.new(simplified_rules)
      end

      def score(context)
        return 0 unless cached_pass?(context) == :none
        @rules.map { |r| r.score(context) }.sum
      end

      def pass?(context)
        cached = cached_pass?(context)
        return cached if cached != :none
        @rules.all? { |r| r.pass?(context) }
      end

      def cached_pass?(context)
        @rules.each do |rule|
          result = rule.cached_pass?(context)
          return result if [:none, false].include?(result)
        end
        true
      end
    end

    class Or < Base
      attr_reader :rules

      def initialize(rules)
        @rules = rules
      end

      def pass?(context)
        cached = cached_pass?(context)
        return cached if cached != :none
        @rules.any? { |r| r.pass?(context) }
      end

      def simplify
        simplified_rules = @rules.flat_map do |rule|
          simplified = rule.simplify
          case simplified
          when Or then simplified.rules
          else [simplified]
          end
        end

        Or.new(simplified_rules)
      end

      def cached_pass?(context)
        @rules.each do |rule|
          result = rule.cached_pass?(context)
          return result if [:none, true].include?(result)
        end
        false
      end

      def score(context)
        return 0 unless cached_pass?(context) == :none
        @rules.map { |r| r.score(context) }.sum
      end
    end

    class Not < Base
      attr_reader :rule

      def initialize(rule)
        @rule = rule
      end

      def simplify
        case @rule
        when And then Or.new(@rule.rules.map(&:negate)).simplify
        when Or then And.new(@rule.rules.map(&:negate)).simplify
        when Not then @rule.rule.simplify
        else Not.new(@rule.simplify)
        end
      end

      def score(context)
        return 0 unless cached_pass?(context) == :none
        @rule.score
      end

      def pass?(context)
        cached = cached_pass?(context)
        return cached if cached_pass?(context) != :none
        !rule.pass?
      end

      def cached_pass?(context)
        rule.cached_pass?
      end
    end
  end


  class RuleDsl
    def initialize(context_class)
      @context_class = context_class
    end

    def can?(ability)
      Rule::Ability.new(ability)
    end

    def all?(*rules)
      Rule::And.make(rules)
    end

    def any?(*rules)
      Rule::Or.make(rules)
    end

    def none?(*rules)
      ~Rule::Or.new(rules)
    end

    def cond(condition)
      Rule::Condition.new(condition)
    end

    def method_missing(msg, *args)
      return super unless args.empty? && !block_given?
      cond(msg.to_sym)
    end
  end
end
