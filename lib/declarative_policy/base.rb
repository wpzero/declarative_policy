module DeclarativePolicy
  class AbilityMap
    attr_reader :map

    def initialize(map = {})
      @map = map
    end

    def merge(other)
      conflict_proc = proc { |key, my_val, other_val| (my_val + other_val).uniq }
      AbilityMap.new(@map.merge(other.map, &conflict_proc))
    end

    def actions(key)
      @map[key] ||= []
    end

    def enable(key, rule)
      actions(key) << [:enable, rule]
    end

    def prevent(key, rule)
      actions(key) << [:prevent, rule]
    end
  end

  class Base
    class << self
      def own_ability_map
        @own_ability_map ||= AbilityMap.new
      end

      def ability_map
        if self == Base
          own_ability_map
        else
          superclass.ability_map.merge(own_ability_map)
        end
      end

      def configuration_for(ability)
        ability_map.actions(ability)
      end

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
        own_conditions[name] = Condition.new(name, options, &compute)
      end

      def last_options!
        last_options.tap do
          @last_options = nil
        end
      end

      def last_options
        @last_options ||= {}
      end

      def desc(description)
        last_options[:description] = description
      end

      def rule(&block)
        rule = RuleDsl.new(self).instance_eval(&block)
        PolicyDsl.new(self, rule)
      end

      def enable_when(abilities, rule)
        abilities.each do |ability|
          own_ability_map.enable(ability, rule)
        end
      end

      def prevent_when(abilities, rule)
        abilities.each do |ability|
          own_ability_map.prevent(ability, rule)
        end
      end

      def delegations
        if self == Base
          own_delegations
        else
          superclass.delegations.merge(own_delegations)
        end
      end

      def own_delegations
        @own_delegations ||= {}
      end

      def delegate(name = nil, &blk)
        if name.nil?
          @delegate_name_counter ||= 0
          @delegate_name_counter += 1
          name = :"anonymous_#{@delegate_name_counter}"
        end

        name = name.to_sym

        if blk.nil?
          blk = proc { @subject.__send__(name) }
        end

        own_delegations[name] = blk
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
      abilities.all? { |a| runner(a).pass? }
    end

    def runner(ability)
      ability = ability.to_sym
      @__runners ||= {}
      @__runners[ability] ||= begin
                                own_runner = Runner.new(own_steps(ability))
                                delegate_runners(ability).inject(own_runner, &:merge_runner)
                              end
    end

    def own_steps(ability)
      self.class.configuration_for(ability).map do |(action, rule)|
        Step.new(self, action, rule)
      end
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

    def callable_condition(name)
      name = name.to_sym
      @_callable_conditions ||= {}
      @_callable_conditions[name] ||=
        begin
          raise "invalid condition #{name}" unless self.class.conditions.key?(name)
          CallableCondition.new(self, self.class.conditions[name])
        end
    end

    def delegate_policies
      @delegated_policies ||= self.class.delegations.transform_values do |blk|
        new_subject = subject.instance_eval(&blk)
        next if new_subject.nil?
        policy_for(new_subject)
      end
    end

    def delegate_runners(ability)
      delegate_policies.values.compact.map do |p|
        p.runner(ability)
      end
    end

    desc "Always true"
    condition :global_always_true do
      true
    end

    desc "Always false"
    condition :global_always_false do
      false
    end
  end
end
