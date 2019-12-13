require 'spec_helper'

RSpec.describe DeclarativePolicy::PolicyDsl do
  let(:rule_dsl) do
    DeclarativePolicy::RuleDsl.new(project_policy_class)
  end

  let(:rule) do
    rule_dsl.instance_eval do
      admin
    end
  end

  let(:ability) do
    :spec_ability
  end


  context do
    let(:project_policy_class) do
      clone_policy_klass(ProjectPolicy)
    end

    let(:policy_dsl) do
      DeclarativePolicy::PolicyDsl.new(project_policy_class, rule)
    end

    it "enable successfully" do
      expect {
        policy_dsl.enable(ability)
      }.to change{ project_policy_class.own_ability_map.actions(ability).count }.by(1)
      expect(project_policy_class.own_ability_map.actions(ability).last.first).to eq(:enable)
    end
  end

  context do
    let(:project_policy_class) do
      clone_policy_klass(ProjectPolicy)
    end

    let(:policy_dsl) do
      DeclarativePolicy::PolicyDsl.new(project_policy_class, rule)
    end

    it "disable successfully" do
      expect {
        policy_dsl.prevent(ability)
      }.to change { project_policy_class.own_ability_map.actions(ability).count }.by(1)
      expect(project_policy_class.own_ability_map.actions(ability).last.first).to eq(:prevent)
    end
  end
end
