module DeclarativePolicy
  module Cache
    PREFIX = "__policy".freeze

    class << self
      def policy_key(user, subject)
        "#{PREFIX}/#{user_key(user)}/#{subject_key(subject)}"
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
    end
  end
end
