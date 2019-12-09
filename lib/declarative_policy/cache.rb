module DeclarativePolicy
  module Cache
    POLICY_PREFIX = "__policy".freeze
    CALLABLE_CONDITION_PREFIX = "__callable_condition".freeze

    class << self
      def policy_key(user, subject)
        "#{POLICY_PREFIX}/#{user_key(user)}/#{subject_key(subject)}"
      end

      def callable_condition_key(callable_condition)
        keys = [CALLABLE_CONDITION_PREFIX]
        keys << condition_key(callable_condition.condition)
        keys << scope_key(callable_condition.condition.scope, user: callable_condition.context.user, subject: callable_condition.context.subject)
        keys.join("/")
      end

      def subject_key(subject)
        return '<nil>' if subject.nil?
        "#{subject.class.name}-#{id_for(subject)}"
      end

      def user_key(user)
        return '<anonymous>' if user.nil?
        "#{user.class.name}-#{id_for(user)}"
      end

      def id_for(object)
        begin
          object.id
        rescue NoMethodError
          object.object_id
        end
      end

      def condition_key(condition)
        "#{condition.context_key}/#{condition.name}"
      end

      def scope_key(scope, user: nil, subject: nil)
        case scope
        when :normal
          "#{user_key(user)}/#{subject_key(subject)}"
        when :user
          "#{user_key(user)}"
        when :subject
          "#{subject_key(subject)}"
        when :global
          ""
        else raise "Invalid scope"
        end
      end
    end
  end
end
