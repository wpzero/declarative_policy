require 'spec_helper'

RSpec.describe DeclarativePolicy::RuleDsl do
  let(:project_policy) do
    ProjectPolicy
  end

  let(:rule_dsl) do
    DeclarativePolicy::RuleDsl.new(project_policy)
  end

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
end
