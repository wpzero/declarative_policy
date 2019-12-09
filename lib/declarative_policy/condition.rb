module DeclarativePolicy
  class Condition
    attr_reader :name, :options, :compute, :description, :scope, :context_key, :manual_score

    def initialize(name, options, &compute)
      @name = name
      @compute = compute
      @scope = options.fetch(:scope, :normal)
      @description  = options.delete(:description)
      @context_key = options[:context_key]
      @options = options
      @manual_score = options.fetch(:score, nil)
    end
  end

  class CallableCondition
    attr_reader :condition, :context

    def initialize(context, condition)
      @context = context
      @condition = condition
    end

    def call
      context.instance_eval(&condition.compute)
    end

    def pass?
      context.cache(key) { call }
    end

    def cached?
      context.cached?(key)
    end

    def key
      @key ||= DeclarativePolicy::Cache.callable_condition_key(self)
    end
  end
end
