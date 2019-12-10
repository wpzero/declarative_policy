module DeclarativePolicy
  class PolicyDsl
    attr_reader :context_class, :rule

    def initialize(context_class, rule)
      @context_class = context_class
      @rule = rule
    end

    def policy(&block)
      instance_eval(&block)
    end

    def enable(*abilities)
      context_class.enable_when(abilities, rule)
    end

    def prevent(*abilities)
      context_class.prevent_when(abilities, rule)
    end
  end
end
