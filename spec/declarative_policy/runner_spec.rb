require 'spec_helper'

RSpec.describe DeclarativePolicy::Runner::State do
  let(:state) do
    DeclarativePolicy::Runner::State.new
  end

  it "Return false when default" do
    expect(state.pass?).to be_falsey
  end

  it "Return false after prevent!" do
    state.prevent!
    expect(state.pass?).to be_falsey
  end

  it "Return true with enable! and without prevent!" do
    state.enable!
    expect(state.pass?).to be_truthy
  end

  it "Return false when enable! and prevent!" do
    state.enable!
    state.prevent!
    expect(state.pass?).to be_falsey
  end
end

RSpec.describe DeclarativePolicy::Step do
  let(:rule_dsl) do
    DeclarativePolicy::RuleDsl.new(project_policy_class)
  end

  let(:project) do
    Project.find_by_name "declarative_policy"
  end

  let(:project_policy_class) do
    clone_policy_klass(ProjectPolicy)
  end

  let(:user) do
    User.find_by_name("wp")
  end

  let(:project_policy) do
    project_policy_class.new(user, project)
  end

  before(:each) do
    project_policy_class.instance_eval do
      desc "True condition"
      condition :true1 do
        true
      end

      desc "True condition"
      condition :true2 do
        true
      end

      desc "False condition"
      condition :false1 do
        false
      end

      desc "False condition"
      condition :false2 do
        false
      end

      desc "Manul scope condition"
      condition :manul_scope_condition, manual_score: 100 do
        true
      end

      desc "Global condition"
      condition :global_condition, scope: :global do
        true
      end

      desc "User scope condition"
      condition :user_scope_condition, scope: :user do
        true
      end

      desc "Subject scope condition"
      condition :subject_scope_condition, scope: :subject do
        true
      end
    end
  end

  context "#score" do
    let(:rule) do
      rule_dsl.instance_eval do
        true1 | false1
      end
    end

    context "when action is enable" do
      let(:step) do
        DeclarativePolicy::Step.new(project_policy, :enable, rule)
      end

      it "Just return rule score" do
        expect(step.score).to eq(16 + 16)
      end
    end

    context "when action is prevent" do
      let(:step) do
        DeclarativePolicy::Step.new(project_policy, :prevent, rule)
      end

      it "Score * 7/8" do
        expect(step.score).to eq((16 + 16) * 7.0/8)
      end
    end
  end

  context "#enable?" do
    let(:rule) do
      rule_dsl.instance_eval do
        true1 | false1
      end
    end

    let(:prevent_step) do
      DeclarativePolicy::Step.new(project_policy, :prevent, rule)
    end

    let(:enable_step) do
      DeclarativePolicy::Step.new(project_policy, :enable, rule)
    end

    it "works" do
      expect(prevent_step.enable?).to be_falsey
      expect(enable_step.enable?).to be_truthy
    end
  end

  context "#prevent?" do
    let(:rule) do
      rule_dsl.instance_eval do
        true1 | false1
      end
    end

    let(:prevent_step) do
      DeclarativePolicy::Step.new(project_policy, :prevent, rule)
    end

    let(:enable_step) do
      DeclarativePolicy::Step.new(project_policy, :enable, rule)
    end

    it "works" do
      expect(prevent_step.prevent?).to be_truthy
      expect(enable_step.prevent?).to be_falsey
    end
  end

  context "#flatten" do
    context "Or rule flatten" do
      let(:or_rule) do
        rule_dsl.instance_eval do
          true1 | false1
        end
      end
      let(:or_step) do
        DeclarativePolicy::Step.new(project_policy, :enable, or_rule)
      end

      it "flatten or steps to multiple steps" do
        expect(or_step.flattened([]).count).to eq(2)
      end
    end

    context "Ability rule flatten" do
      before(:each) do
        project_policy_class.instance_eval do
          desc "True condition"
          condition :true1 do
            true
          end

          desc "True condition"
          condition :true2 do
            true
          end

          desc "False condition"
          condition :false1 do
            false
          end

          desc "False condition"
          condition :false2 do
            false
          end

          rule { true1 }.enable :do_first_thing
          rule { true2 }.enable :do_first_thing
        end
      end

      context "When the ability step only contains enable steps" do
        context "when the step is enable step" do
          it "works" do
            ability_rule = rule_dsl.instance_eval do
              can?(:do_first_thing)
            end
            ability_step = DeclarativePolicy::Step.new(project_policy, :enable, ability_rule)
            expect(ability_step.flattened([]).count).to eq(2)
            expect(ability_step.flattened([]).map(&:action)).to match_array([:enable, :enable])
          end
        end

        context "when the step is prevent step" do
          it "works" do
            ability_rule = rule_dsl.instance_eval do
              can?(:do_first_thing)
            end
            ability_step = DeclarativePolicy::Step.new(project_policy, :prevent, ability_rule)
            expect(ability_step.flattened([]).count).to eq(2)
            expect(ability_step.flattened([]).map(&:action)).to match_array([:prevent, :prevent])
          end
        end
      end

      context "When the ability step only contains prevent steps" do
        before(:each) do
          project_policy_class.instance_eval do
            rule { true1 }.enable :do_first_thing
            rule { true2 }.enable :do_first_thing
            rule { true1 }.prevent :do_first_thing
          end
        end

        it "Just return [self]" do
          ability_rule = rule_dsl.instance_eval do
            can?(:do_first_thing)
          end
          ability_step = DeclarativePolicy::Step.new(project_policy, :prevent, ability_rule)
          expect(ability_step.flattened([]).count).to eq(1)
        end
      end
    end
  end

  context "#pass?" do
    let(:rule) do
      rule_dsl.instance_eval do
        true1 | false1
      end
    end

    let(:step) do
      DeclarativePolicy::Step.new(project_policy, :enable, rule)
    end

    it "works" do
      expect(step.pass?).to be_truthy
    end
  end

  context "#enable?" do
    let(:rule) do
      rule_dsl.instance_eval do
        true1 | false1
      end
    end

    let(:enable_step) do
      DeclarativePolicy::Step.new(project_policy, :enable, rule)
    end

    let(:prevent_step) do
      DeclarativePolicy::Step.new(project_policy, :prevent, rule)
    end

    it "works" do
      expect(enable_step.enable?).to be_truthy
      expect(prevent_step.enable?).to be_falsey
    end
  end

  context "#prevent?" do
    let(:rule) do
      rule_dsl.instance_eval do
        true1 | false1
      end
    end

    let(:enable_step) do
      DeclarativePolicy::Step.new(project_policy, :enable, rule)
    end

    let(:prevent_step) do
      DeclarativePolicy::Step.new(project_policy, :prevent, rule)
    end

    it "works" do
      expect(enable_step.prevent?).to be_falsey
      expect(prevent_step.prevent?).to be_truthy
    end
  end

  context "#with_action" do
    let(:rule) do
      rule_dsl.instance_eval do
        true1 | false1
      end
    end

    let(:enable_step) do
      DeclarativePolicy::Step.new(project_policy, :enable, rule)
    end

    it "works" do
      new_step = enable_step.with_action(:prevent)
      expect(new_step.prevent?).to be_truthy
      expect(new_step.rule).to eq(enable_step.rule)
    end
  end

  context "#==" do
    let(:rule) do
      rule_dsl.instance_eval do
        true1 | false1
      end
    end

    let(:step) do
      DeclarativePolicy::Step.new(project_policy, :enable, rule)
    end

    it "works" do
      new_step = step.with_action(step.action)
      expect(new_step == step).to be_truthy
    end
  end
end

RSpec.describe DeclarativePolicy::Runner do
  let(:rule_dsl) do
    DeclarativePolicy::RuleDsl.new(project_policy_class)
  end

  let(:project) do
    Project.find_by_name "declarative_policy"
  end

  let(:project_policy_class) do
    clone_policy_klass(ProjectPolicy)
  end

  let(:user) do
    User.find_by_name("wp")
  end

  let(:project_policy) do
    project_policy_class.new(user, project)
  end

  context "#steps_by_score" do
    context "When steps are [enable<true>, enable<no-execute>, enable<no-execute>, prevent<false>]" do
      it "Only first step and last step are executed" do
        expect do |blk|
          project_policy_class.instance_eval do
            desc "True condition"
            condition :true1, score: 0 do
              blk.to_proc.call
              true
            end

            desc "True condition"
            condition :true2, score: 1 do
              blk.to_proc.call
              true
            end

            desc "False condition"
            condition :false3, score: 3 do
              blk.to_proc.call
              false
            end

            desc "False condition"
            condition :false4, score: 10 do
              blk.to_proc.call
              false
            end
          end

          rule1 = rule_dsl.instance_eval do
            true1
          end
          rule2 = rule_dsl.instance_eval do
            true2
          end
          rule3 = rule_dsl.instance_eval do
            false3
          end
          rule4 = rule_dsl.instance_eval do
            false4
          end

          step1 = DeclarativePolicy::Step.new(project_policy, :enable, rule1)
          step2 = DeclarativePolicy::Step.new(project_policy, :enable, rule2)
          step3 = DeclarativePolicy::Step.new(project_policy, :enable, rule3)
          step4 = DeclarativePolicy::Step.new(project_policy, :prevent, rule4)

          runner = DeclarativePolicy::Runner.new([step1, step2, step3, step4])
          runner.run

          expect(runner.pass?).to be_truthy
        end.to yield_control.twice
      end
    end

    context "When steps are [prevent<no-execute>, prevent<no-execute>, prevent<no-execute>, prevent<no-execute>]" do
      it "No steps are executed" do
        expect do |blk|
          project_policy_class.instance_eval do
            desc "True condition"
            condition :true1, score: 0 do
              blk.to_proc.call
              true
            end

            desc "True condition"
            condition :true2, score: 1 do
              blk.to_proc.call
              true
            end

            desc "False condition"
            condition :false3, score: 3 do
              blk.to_proc.call
              false
            end

            desc "False condition"
            condition :false4, score: 10 do
              blk.to_proc.call
              false
            end
          end

          rule1 = rule_dsl.instance_eval do
            true1
          end
          rule2 = rule_dsl.instance_eval do
            true2
          end
          rule3 = rule_dsl.instance_eval do
            false3
          end
          rule4 = rule_dsl.instance_eval do
            false4
          end

          step1 = DeclarativePolicy::Step.new(project_policy, :prevent, rule1)
          step2 = DeclarativePolicy::Step.new(project_policy, :prevent, rule2)
          step3 = DeclarativePolicy::Step.new(project_policy, :prevent, rule3)
          step4 = DeclarativePolicy::Step.new(project_policy, :prevent, rule4)
          runner = DeclarativePolicy::Runner.new([step1, step2, step3, step4])
          runner.run

          expect(runner.pass?).to be_falsey
          # If not called once, will raise error
          # So will call one time here
          blk.to_proc.call
        end.to yield_control.once
      end
    end

    context "When steps are [prevent<true>, enable<no-execute>, enable<no-execute>, prevent<no-execute>]" do
      it "Only first step will be executed" do
        expect do |blk|
          project_policy_class.instance_eval do
            desc "True condition"
            condition :true1, score: 0 do
              blk.to_proc.call
              true
            end

            desc "True condition"
            condition :true2, score: 1 do
              blk.to_proc.call
              true
            end

            desc "False condition"
            condition :false3, score: 3 do
              blk.to_proc.call
              false
            end

            desc "False condition"
            condition :false4, score: 10 do
              blk.to_proc.call
              false
            end
          end

          rule1 = rule_dsl.instance_eval do
            true1
          end
          rule2 = rule_dsl.instance_eval do
            true2
          end
          rule3 = rule_dsl.instance_eval do
            false3
          end
          rule4 = rule_dsl.instance_eval do
            false4
          end

          step1 = DeclarativePolicy::Step.new(project_policy, :prevent, rule1)
          step2 = DeclarativePolicy::Step.new(project_policy, :enable, rule2)
          step3 = DeclarativePolicy::Step.new(project_policy, :enable, rule3)
          step4 = DeclarativePolicy::Step.new(project_policy, :prevent, rule4)

          runner = DeclarativePolicy::Runner.new([step1, step2, step3, step4])
          runner.run

          expect(runner.pass?).to be_falsey
        end.to yield_control.once
      end
    end
  end

  context "#run" do
    before(:each) do
      project_policy_class.instance_eval do
        desc "True condition"
        condition :true1 do
          true
        end

        desc "True condition"
        condition :true2 do
          true
        end

        desc "False condition"
        condition :false1 do
          false
        end

        desc "False condition"
        condition :false2 do
          false
        end
      end
    end

    context "One prevent step is passed, none enable step is passed" do
      it "False" do
        false_prevent_step = DeclarativePolicy::Step.new(project_policy,
                                                        :prevent,
                                                        rule_dsl.instance_eval {
                                                          false1
                                                        })
        true_prevent_step = DeclarativePolicy::Step.new(project_policy,
                                                        :prevent,
                                                        rule_dsl.instance_eval {
                                                          true1
                                                        })
        false_prevent_step2 = DeclarativePolicy::Step.new(project_policy,
                                                        :prevent,
                                                        rule_dsl.instance_eval {
                                                          false1
                                                        })
        false_enable_step = DeclarativePolicy::Step.new(project_policy,
                                                        :enable,
                                                        rule_dsl.instance_eval {
                                                          false1
                                                        })
        false_enable_step2 = DeclarativePolicy::Step.new(project_policy,
                                                        :enable,
                                                        rule_dsl.instance_eval {
                                                          false2
                                                        })
        runner = DeclarativePolicy::Runner.new([
                                                 false_prevent_step,
                                                 true_prevent_step,
                                                 false_prevent_step2,
                                                 false_enable_step,
                                                 false_enable_step2
                                               ])
        expect(runner.pass?).to be_falsey
      end
    end

    context "One prevent step is passed, one enable step is passed" do
      it "False" do
        false_prevent_step = DeclarativePolicy::Step.new(project_policy,
                                                        :prevent,
                                                        rule_dsl.instance_eval {
                                                          false1
                                                        })
        true_prevent_step = DeclarativePolicy::Step.new(project_policy,
                                                        :prevent,
                                                        rule_dsl.instance_eval {
                                                          true1
                                                        })
        false_prevent_step2 = DeclarativePolicy::Step.new(project_policy,
                                                        :prevent,
                                                        rule_dsl.instance_eval {
                                                          false1
                                                        })
        true_enable_step = DeclarativePolicy::Step.new(project_policy,
                                                        :enable,
                                                        rule_dsl.instance_eval {
                                                          true1
                                                        })
        false_enable_step = DeclarativePolicy::Step.new(project_policy,
                                                        :enable,
                                                        rule_dsl.instance_eval {
                                                          false2
                                                        })
        runner = DeclarativePolicy::Runner.new([
                                                 false_prevent_step,
                                                 true_prevent_step,
                                                 false_prevent_step2,
                                                 true_enable_step,
                                                 false_enable_step
                                               ])
        expect(runner.pass?).to be_falsey
      end
    end

    context "None prevent step is passed, none enable step is passed" do
      it "False" do
        false_prevent_step1 = DeclarativePolicy::Step.new(project_policy,
                                                        :prevent,
                                                        rule_dsl.instance_eval {
                                                          false1
                                                        })
        false_prevent_step2 = DeclarativePolicy::Step.new(project_policy,
                                                        :prevent,
                                                        rule_dsl.instance_eval {
                                                          false1
                                                        })
        false_enable_step1 = DeclarativePolicy::Step.new(project_policy,
                                                        :enable,
                                                        rule_dsl.instance_eval {
                                                          false1
                                                        })
         false_enable_step2 = DeclarativePolicy::Step.new(project_policy,
                                                        :enable,
                                                        rule_dsl.instance_eval {
                                                          false2
                                                        })
        runner = DeclarativePolicy::Runner.new([
                                                 false_prevent_step1,
                                                 false_prevent_step2,
                                                 false_enable_step1,
                                                 false_enable_step2
                                               ])
        expect(runner.pass?).to be_falsey
      end
    end

    context "None prevent step is passed, one enable step is passed" do
      it "True" do
        false_prevent_step1 = DeclarativePolicy::Step.new(project_policy,
                                                        :prevent,
                                                        rule_dsl.instance_eval {
                                                          false1
                                                        })
        false_prevent_step2 = DeclarativePolicy::Step.new(project_policy,
                                                        :prevent,
                                                        rule_dsl.instance_eval {
                                                          false1
                                                        })
        true_enable_step = DeclarativePolicy::Step.new(project_policy,
                                                        :enable,
                                                        rule_dsl.instance_eval {
                                                          true1
                                                        })
         false_enable_step2 = DeclarativePolicy::Step.new(project_policy,
                                                        :enable,
                                                        rule_dsl.instance_eval {
                                                          false2
                                                        })
        runner = DeclarativePolicy::Runner.new([
                                                 false_prevent_step1,
                                                 false_prevent_step2,
                                                 true_enable_step,
                                                 false_enable_step2
                                               ])
        expect(runner.pass?).to be_truthy
      end
    end
  end

  context "#cached?" do
    before(:each) do
      project_policy_class.instance_eval do
        desc "True condition"
        condition :true1 do
          true
        end

        desc "True condition"
        condition :true2 do
          true
        end

        desc "False condition"
        condition :false1 do
          false
        end

        desc "False condition"
        condition :false2 do
          false
        end
      end
    end

    it "work" do
      false_prevent_step = DeclarativePolicy::Step.new(project_policy,
                                                       :prevent,
                                                       rule_dsl.instance_eval {
                                                         false1
                                                       })
      true_prevent_step = DeclarativePolicy::Step.new(project_policy,
                                                      :prevent,
                                                      rule_dsl.instance_eval {
                                                        true1
                                                      })
      false_prevent_step2 = DeclarativePolicy::Step.new(project_policy,
                                                        :prevent,
                                                        rule_dsl.instance_eval {
                                                          false1
                                                        })
      false_enable_step = DeclarativePolicy::Step.new(project_policy,
                                                      :enable,
                                                      rule_dsl.instance_eval {
                                                        false1
                                                      })
      false_enable_step2 = DeclarativePolicy::Step.new(project_policy,
                                                       :enable,
                                                       rule_dsl.instance_eval {
                                                         false2
                                                       })
      runner = DeclarativePolicy::Runner.new([
                                               false_prevent_step,
                                               true_prevent_step,
                                               false_prevent_step2,
                                               false_enable_step,
                                               false_enable_step2
                                             ])
      expect(runner.cached?).to be_falsey
      runner.pass?
      expect(runner.cached?).to be_truthy
    end
  end
end
