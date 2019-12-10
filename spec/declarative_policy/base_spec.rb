require 'spec_helper'

RSpec.describe DeclarativePolicy::Base do
  context ".condition" do
    let(:member_condition) do
      ProjectPolicy.own_conditions[:member]
    end

    let(:admin_condition) do
      BasePolicy.own_conditions[:admin]
    end

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
end
