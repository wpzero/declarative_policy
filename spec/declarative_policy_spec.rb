require 'spec_helper'

RSpec.describe DeclarativePolicy do
  let(:declarative_policy_project) do
    Project.find_by_name "declarative_policy"
  end

  let(:wp_user) do
    User.find_by_name "wp"
  end

  it "has a version number" do
    expect(DeclarativePolicy::VERSION).not_to be nil
  end

  it ".policy_for" do
    expect(DeclarativePolicy.policy_for(wp_user, declarative_policy_project)).to be_a(ProjectPolicy)
    expect(DeclarativePolicy.policy_for(wp_user, :global)).to be_a(GlobalPolicy)
  end
end
