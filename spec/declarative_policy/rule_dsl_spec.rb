require 'spec_helper'

RSpec.describe DeclarativePolicy::RuleDsl do
  let(:project_policy_class) do
    ProjectPolicy.clone
  end

  let(:rule_dsl) do
    DeclarativePolicy::RuleDsl.new(project_policy_class)
  end

  context "Rule create" do
    context "Create condition rule" do
      let(:rule) do
        rule_dsl.instance_eval do
          admin
        end
      end

      it "works" do
        expect(rule).to be_a(DeclarativePolicy::Rule::Condition)
        expect(rule.name.to_s).to eq("admin")
      end
    end

    context "Create and rule" do
      let(:rule) do
        rule_dsl.instance_eval do
          admin & member
        end
      end

      it "works" do
        expect(rule).to be_a(DeclarativePolicy::Rule::And)
        expect(rule.rules.count).to eq(2)
      end
    end

    context "Create or rule" do
      let(:rule) do
        rule_dsl.instance_eval do
          admin | member
        end
      end

      it "works" do
        expect(rule).to be_a(DeclarativePolicy::Rule::Or)
        expect(rule.rules.count).to eq(2)
      end
    end

    context "Create negate rule" do
      let(:rule) do
        rule_dsl.instance_eval do
          ~owner
        end
      end

      it "works" do
        expect(rule).to be_a(DeclarativePolicy::Rule::Not)
        expect(rule.rule).to be_a(DeclarativePolicy::Rule::Condition)
      end
    end

    context "create ability rule" do
      let(:rule_dsl) do
        DeclarativePolicy::RuleDsl.new(project_policy_class)
      end

      let(:project) do
        Project.find_by_name "declarative_policy"
      end

      let(:project_policy_class) do
        ProjectPolicy.clone
      end

      let(:user) do
        User.find_by_name("wp")
      end

      let(:project_policy) do
        project_policy_class.new(user, project)
      end
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

        rule { true1 & true2 }.policy do
          enable :true_ability
        end
      end
    end

    it "works" do
      rule = rule_dsl.instance_eval do
        can?(:true_ability)
      end
      expect(rule).to be_a(DeclarativePolicy::Rule::Ability)
    end
  end

  context "Rule pass" do
    let(:project) do
      Project.find_by_name "declarative_policy"
    end

    let(:project_policy_class) do
      ProjectPolicy.clone
    end

    let(:user) do
      User.find_by_name("wp")
    end

    let(:project_policy) do
      project_policy_class.new(user, project)
    end

    before(:each) do
      project_policy_class.instance_eval do
        desc "True conditiion"
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

    context "Condition rule" do
      let(:true_rule) do
        rule_dsl.instance_eval do
          true1
        end
      end

      let(:false_rule) do
        rule_dsl.instance_eval do
          false1
        end
      end

      it "works" do
        expect(true_rule.pass?(project_policy)).to be_truthy
        expect(false_rule.pass?(project_policy)).to be_falsey
      end
    end

    context "And rule" do
      let(:true_rule) do
        rule_dsl.instance_eval do
          true1 & true2
        end
      end

      let(:false_rule) do
        rule_dsl.instance_eval do
          false1 & true2
        end
      end

      it "works" do
        expect(true_rule.pass?(project_policy)).to be_truthy
        expect(false_rule.pass?(project_policy)).to be_falsey
      end
    end

    context "Or rule" do
      let(:false_rule) do
        rule_dsl.instance_eval do
          false1 | false2
        end
      end

      let(:true_rule) do
        rule_dsl.instance_eval do
          false1 | true1
        end
      end

      it "works" do
        expect(true_rule.pass?(project_policy)).to be_truthy
        expect(false_rule.pass?(project_policy)).to be_falsey
      end
    end

    context "Ability rule" do
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

          rule { true1 & true2 }.policy do
            enable :true_ability
          end

          rule { true1 & false1 }.enable :false_ability
        end
      end

      it "works" do
        true_ability_rule = rule_dsl.instance_eval do
          can? :true_ability
        end
        false_ability_rule = rule_dsl.instance_eval do
          can? :false_ability
        end
        expect(true_ability_rule.pass?(project_policy)).to be_truthy
        expect(false_ability_rule.pass?(project_policy)).to be_falsey
      end
    end
  end

  context "Rule Score" do
    let(:project) do
      Project.find_by_name "declarative_policy"
    end

    let(:project_policy_class) do
      ProjectPolicy.clone
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

    context "Condition rule" do
      let(:condition_rule) do
        rule_dsl.instance_eval do
          manul_scope_condition
        end
      end

      it "16 when scope is normal" do
        expect(condition_rule.score(project_policy)).to eq(16)
      end

      it "0 when cached the result" do
        condition_rule.pass?(project_policy)
        expect(condition_rule.score(project_policy)).to eq(0)
      end

      context "2 when scope is global" do
        let(:condition_rule) do
          rule_dsl.instance_eval do
            global_condition
          end
        end

        it "works" do
          expect(condition_rule.score(project_policy)).to eq(2)
        end
      end

      context "8 when scope is user" do
        let(:condition_rule) do
          rule_dsl.instance_eval do
            user_scope_condition
          end
        end

        it "works" do
          expect(condition_rule.score(project_policy)).to eq(8)
        end
      end

      context "8 when scope is subject" do
        let(:condition_rule) do
          rule_dsl.instance_eval do
            subject_scope_condition
          end
        end

        it "works" do
          expect(condition_rule.score(project_policy)).to eq(8)
        end
      end
    end

    context "Or rule" do
      let(:or_rule) do
        rule_dsl.instance_eval do
          false1 | false2
        end
      end

      it "be sum of all rules of the or rule" do
        expect(or_rule.score(project_policy)).to eq(32)
      end
    end

    context "And rule" do
      let(:and_rule) do
        rule_dsl.instance_eval do
          false1 & false2
        end
      end

      it "be sum of all rules of the and rule" do
        expect(and_rule.score(project_policy)).to eq(32)
      end
    end
  end
end
