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

  let(:wp) do
    User.find_by_name("wp")
  end

  let(:zkf) do
    User.find_by_name("zkf")
  end

  let(:policy) do
    DeclarativePolicy.policy_for(wp, declarative_policy_project)
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
        DeclarativePolicy.policy_for(zkf, declarative_policy_project)
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
      ProjectPolicy.clone
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
end
