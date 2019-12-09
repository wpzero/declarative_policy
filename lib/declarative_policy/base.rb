module DeclarativePolicy
  class Base
    class << self
      def conditions
        if self == Base
          own_conditions
        else
          superclass.conditions.merge(own_conditions)
        end
      end

      def own_conditions
        @own_conditions ||= {}
      end

      def condition(name, options = {}, &compute)
        name = name.to_sym
        options = last_options!.merge(options)
        options[:context_key] = self.name
        own_conditions[:name] = Condition.new(name, options, &compute)
      end

      def last_options!
        last_options.tap do
          @last_options = nil
        end
      end

      def last_options
        @last_options ||= {}.with_indifferent_access
      end

      def desc(description)
        @last_options[:description] = description
      end
    end

    attr_accessor :user, :subject, :cache

    def initialize(user, subject, opts = {})
      @user = user
      @subject = subject
      @cache = opts[:cache] || {}
    end

    def can?(ability, new_subject = :_self)
      return allowed?(ability) if new_subject == :_self
      policy_for(new_subject).allowed?(ability)
    end

    def allowed?(*abilities)
      # TODO
    end

    def policy_for(other_subject)
      DeclarativePolicy.policy_for(@user, other_subject, cache: @cache)
    end

    def cache(key)
      @cache[key] if cached?(key)
      @cache[key] = yield
    end

    def cached?(key)
      @cache.key?(key)
    end
  end
end
