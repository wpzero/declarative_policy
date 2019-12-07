module DeclarativePolicy
  class Base
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
  end
end
