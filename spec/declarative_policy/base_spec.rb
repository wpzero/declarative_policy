require 'spec_helper'

RSpec.describe DeclarativePolicy::Base do
  let(:member_condition) do
    ProjectPolicy.own_conditions[:member]
  end

  let(:declarative_policy_project) do
    Project.find_by_name "declarative_policy"
  end

  let(:admin_condition) do
    BasePolicy.own_conditions[:admin]
  end

  let(:project_owner) do
    User.find_by_name("wp")
  end

  let(:issue_owner) do
    User.find_by_name("zkf")
  end

  let(:policy) do
    DeclarativePolicy.policy_for(project_owner, declarative_policy_project)
  end

  let(:issue) do
    Issue.find_by_name("issue1")
  end

  let(:issue_policy) do
    DeclarativePolicy.policy_for(project_owner, issue)
  end

  let(:project_policy) do
    DeclarativePolicy.policy_for(project_owner, declarative_policy_project)
  end

  context ".condition" do
    it "create the condition and match the right desc" do
      expect(member_condition).to be_a(DeclarativePolicy::Condition)
      expect(member_condition.name).to eq(:member)
      expect(member_condition.scope).to eq(:normal)
      expect(member_condition.description).to eq("User is a member of the project's group")
      expect(member_condition.compute).to be_a(Proc)
      expect(admin_condition.description).to eq("User is admin")
    end
  end

  context ".own_conditions" do
    it "get the class's own conditions" do
      expect(ProjectPolicy.own_conditions.keys).to include(:member, :owner)
    end
  end

  context ".conditions" do
    it "get all the coditions through superclass chain" do
      expect(ProjectPolicy.conditions).to include(:admin, :member, :owner)
    end
  end

  context "#callable_condition" do
    context "execute and return true" do
      it "success" do
        expect(policy.callable_condition(:admin)).to be_a(DeclarativePolicy::CallableCondition)
        expect(policy.callable_condition(:admin).pass?).to be_truthy
      end
    end

    context "execute and return fales" do
      let(:policy) do
        DeclarativePolicy.policy_for(issue_owner, declarative_policy_project)
      end

      it "success" do
        expect(policy.callable_condition(:admin)).to be_a(DeclarativePolicy::CallableCondition)
        expect(policy.callable_condition(:admin).pass?).to be_falsey
      end
    end
  end

  context "AbilityMap" do
    let(:ability_map) do
      DeclarativePolicy::AbilityMap.new
    end

    let(:project_policy_class) do
      clone_policy_klass(ProjectPolicy)
    end

    let(:rule_dsl) do
      DeclarativePolicy::RuleDsl.new(project_policy_class)
    end

    context "#enable" do
      let(:rule) do
        rule_dsl.instance_eval do
          admin | owner
        end
      end

      it "works" do
        ability_map.enable(:destroy_project, rule)
        expect(ability_map.actions(:destroy_project).count).to eq(1)
        expect(ability_map.actions(:destroy_project).first.first).to eq(:enable)
      end
    end

    context "#prevent" do
      let(:rule) do
        rule_dsl.instance_eval do
          !member
        end
      end

      let(:ability) do
        :spec_edit_project
      end

      it "works" do
        ability_map.prevent(ability, rule)
        expect(ability_map.actions(ability).count).to eq(1)
        expect(ability_map.actions(ability).first.first).to eq(:prevent)
      end
    end

    context "#merge" do
      let(:other_ability_map) do
        DeclarativePolicy::AbilityMap.new
      end

      let(:rule1) do
        rule_dsl.instance_eval do
          admin
        end
      end

      let(:rule2) do
        rule_dsl.instance_eval do
          owner
        end
      end

      let(:ability) do
        :spec_destroy_project
      end

      before do
        ability_map.enable(ability, rule1)
        other_ability_map.enable(ability, rule2)
      end

      it "works" do
        merged_ability_map = ability_map.merge(other_ability_map)
        expect(merged_ability_map.actions(ability).count).to eq(2)
      end
    end
  end

  context ".delegate" do
    it "works" do
      expect(IssuePolicy.delegations.values.count).to be > 0
      expect(IssuePolicy.delegations.keys).to include(:project)
    end
  end

  context ".delegate_policies" do
    it "works" do
      expect(issue_policy.delegate_policies.keys).to include(:project)
      expect(issue_policy.delegate_policies[:project]).to be_a(ProjectPolicy)
    end
  end

  context ".delegate_runners" do
    it "Get all delegate runners" do
      delegate_runners = issue_policy.delegate_runners(:edit_project)
      expect(delegate_runners.count).to be > 0
    end
  end

  context ".can?" do
    let(:issue_policy_with_issue_owner) do
      DeclarativePolicy.policy_for(issue_owner, issue)
    end

    context "can delegate to other policy ability" do
      it "Works" do
        expect(issue_policy.can?(:edit_project)).to be_truthy
        expect(issue_policy_with_issue_owner.can?(:edit_project)).to be_falsey
      end
    end

    context "can use policy self's ability setting" do
      it "Works" do
        expect(issue_policy.can?(:edit_issue)).to be_falsey
        expect(issue_policy_with_issue_owner.can?(:edit_issue)).to be_truthy
      end
    end

    context "can mix policy self ability setting and delegate policy ability when the ability name is same" do
      it "Works" do
        expect(project_policy.can?(:mix_delegate_action)).to be_truthy
        expect(issue_policy.can?(:mix_delegate_action)).to be_falsey
      end
    end

    context "delegated condition" do
      it "Works" do
        expect(issue_policy.can?(:destroy_issue)).to be_truthy
        expect(issue_policy_with_issue_owner.can?(:destroy_issue)).to be_truthy
      end
    end

    context "cache" do
      it "Works" do
        expect(issue_policy.can?(:destroy_issue)).to be_truthy
        expect(issue_policy.instance_variable_get(:@__runners)[:destroy_issue]).to be_a(DeclarativePolicy::Runner)
      end
    end

    context "ability rule" do
      it "Works" do
        runner = issue_policy.runner(:upload_image_from_issue)
        expect(runner).to be_a(DeclarativePolicy::Runner)
        expect(runner.steps.count).to eq(1)
        ability_step = runner.steps.first
        expect(ability_step).to be_a(DeclarativePolicy::Step)
        expect(ability_step.rule).to be_a(DeclarativePolicy::Rule::Ability)
        expect(issue_policy.can?(:upload_image_from_issue)).to be_falsey
        expect(issue_policy_with_issue_owner.can?(:upload_image_from_issue)).to be_truthy
       end
    end
  end
end
