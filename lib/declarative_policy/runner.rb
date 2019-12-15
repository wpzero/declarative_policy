module DeclarativePolicy
  class Runner
    class State
      def initialize
        @enabled = false
        @prevented = false
      end

      def enable!
        @enabled = true
      end

      def enabled?
        @enabled
      end

      def prevent!
        @prevented = true
      end

      def prevented?
        @prevented
      end

      def pass?
        !prevented? && enabled?
      end
    end

    attr_reader :steps

    def initialize(steps)
      @steps = steps
    end

    def cached?
      !!@state
    end

    def score
      return 0 if cached?
      steps.map(&:score).inject(0, :+)
    end

    def merge_runner(other)
      Runner.new(@steps + other.steps)
    end

    def pass?
      run unless cached?
      @state.pass?
    end

    def run
      @state = State.new
      steps_by_score do |step, score|
        case step.action
        when :enable then
          if !@state.enabled? && step.pass?
            @state.enable!
          end
        when :prevent then
          if !@state.prevented? && step.pass?
            @state.prevent!
          end
        else raise "invalid action #{step.action.inspect}"
        end
      end
      @state
    end

    def steps_by_score
      flatten_steps!
      if @steps.size > 50
        warn "DeclarativePolicy: large number of steps (#{steps.size}), falling back to static sort"
        @steps.map { |s| [s.score, s] }.sort_by { |(score, _)| score }.each do |(score, step)|
          yield step, score
        end
        return
      end

      remaining_steps = Set.new(@steps)
      remaining_enablers, remaining_preventers = remaining_steps.partition(&:enable?).map { |s| Set.new(s) }

      loop do
        if @state.enabled?
          remaining_steps = remaining_preventers
        end
        if (remaining_enablers.empty? && !@state.enabled?) || @state.prevented?
          remaining_steps = []
        end
        return if remaining_steps.empty?

        lowest_score = Float::INFINITY
        next_step = nil

        remaining_steps.each do |step|
          score = step.score

          if score < lowest_score
            next_step = step
            lowest_score = score
          end

          break if lowest_score.zero?
        end

        [remaining_steps, remaining_enablers, remaining_preventers].each do |set|
          set.delete(next_step)
        end

        yield next_step, lowest_score
      end
    end

    def flatten_steps!
      @steps = @steps.flat_map { |s| s.flattened(@steps) }
    end
  end

  class Step
    attr_reader :context, :action, :rule

    def initialize(context, action, rule)
      @context = context
      @action = action
      @rule = rule
    end

    def pass?
      rule.pass?(context)
    end

    def enable?
      @action == :enable
    end

    def prevent?
      @action == :prevent
    end

    def ==(other)
      @context == other.context && @rule == other.rule && @action == other.action
    end

    def score
      case @action
      when :prevent
        @rule.score(@context) * (7.0 / 8)
      when :enable
        @rule.score(@context)
      end
    end

    def with_action(action)
      Step.new(@context, action, @rule)
    end

    def flattened(roots)
      case @rule
      when Rule::Or
        @rule.rules.flat_map { |r| Step.new(@context, @action, r).flattened(roots) }
      when Rule::Ability
        steps = @context.runner(@rule.ability).steps.reject { |s| roots.include?(s) }
        if steps.all?(&:enable?)
          steps.map! { |s| s.with_action(:prevent) } if prevent?
          steps.flat_map { |s| s.flattened(roots) }
        else
          [self]
        end
      else
        [self]
      end
    end
  end
end
