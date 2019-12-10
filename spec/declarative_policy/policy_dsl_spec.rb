require 'spec_helper'

RSpec.describe DeclarativePolicy::PolicyDsl do
  let(:rule_dsl) do
    DeclarativePolicy::RuleDsl.new(project_policy)
  end

  let(:rule) do
    rule_dsl.instance_eval do
      admin
    end
  end

  let(:policy_dsl) do
    DeclarativePolicy::PolicyDsl.new(project_policy, rule)
  end

  let(:ability) do
    :spec_ability
  end

  context do
    let(:project_policy) do
      ProjectPolicy.clone
    end

    it "enable successfully" do
      policy_dsl.enable(ability)
      expect(project_policy.own_ability_map.actions(ability).count).to eq (1)
      expect(project_policy.own_ability_map.actions(ability).first.first).to eq(:enable)
    end
  end

  context do
    let(:project_policy) do
      ProjectPolicy.clone
    end

    it "disable successfully" do
      policy_dsl.prevent(ability)
      expect(project_policy.own_ability_map.actions(ability).count).to eq (1)
      expect(project_policy.own_ability_map.actions(ability).first.first).to eq(:prevent)
    end
  end
end
