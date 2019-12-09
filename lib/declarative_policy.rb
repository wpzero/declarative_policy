require "declarative_policy/version"
require "declarative_policy/cache"
require "declarative_policy/base"

module DeclarativePolicy
  class NoPolicyError < StandardError; end
  class Error < StandardError; end
  CLASS_CACHE_MUTEX = Mutex.new
  CLASS_CACHE_IVAR = :@__DeclarativePolicy_CLASS_CACHE

  class << self
    def policy_for(user, subject, opts = {})
      cache = opts[:cache] || {}
      key = Cache.policy_key(user, subject)
      cache[key] ||= klass_for(subject).new(user, subject, opts)
    end

    def klass_for(subject)
      return symbol_to_klass(subject) if subject.is_a?(Symbol)
      klass_for_klass(subject.class)
    end

    def symbol_to_klass(symbol)
      begin
        policy_class = "#{symbol.to_s.camelize}Policy".constantize
        return policy_class if policy_class < Base
      rescue NameError
        raise NoPolicyError, "No Policy for #{symbol}"
      end
    end

    def klass_for_klass(klass)
      if !klass.instance_variable_defined?(CLASS_CACHE_IVAR)
        CLASS_CACHE_MUTEX.synchronize do
          break if klass.instance_variable_defined?(CLASS_CACHE_IVAR)
          policy_class = compute_klass_for_klass(klass)
          raise NoPolicyError, "No Policy for #{klass}" if policy_class.nil?
          klass.instance_variable_set(CLASS_CACHE_IVAR, policy_class)
        end
      end
      klass.instance_variable_get(CLASS_CACHE_IVAR)
    end

    def compute_klass_for_klass(klass)
      klass.ancestors.each do |ancestor_klass|
        # Can use declarative_policy_klass to set the policy type
        return ancestor_klass.declarative_policy_klass if ancestor_klass.respond_to?(:declarative_policy_klass) && ancestor_klass.declarative_policy_klass < Base
        next unless ancestor_klass.name
        begin
          policy_class = "#{ancestor_klass.name}Policy".constantize
          return policy_class if policy_class < Base
        rescue NameError
          nil
        end
      end
      nil
    end
  end
end
