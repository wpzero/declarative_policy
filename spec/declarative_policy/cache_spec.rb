require 'spec_helper'

RSpec.describe DeclarativePolicy::Cache do
  let(:declarative_policy_project) do
    Project.find_by_name "declarative_policy"
  end

  let(:wp_user) do
    User.find_by_name "wp"
  end

  context ".subject_key" do
    it "<nil> when subject is nil" do
      expect(DeclarativePolicy::Cache.subject_key(nil)).to eq("<nil>")
    end

    it "subject class name + subject id when subject is not nil" do
      expect(DeclarativePolicy::Cache.subject_key(declarative_policy_project)).to eq("#{declarative_policy_project.class.name}-#{declarative_policy_project.id}")
    end

    it "get uniq key when subject is symbol" do
      expect(DeclarativePolicy::Cache.subject_key(:sym)).to eq("#{:sym.class.name}-#{:sym.object_id}")
    end
  end

  context ".user_key" do
    it "<anonymous> when user is blank" do
      expect(DeclarativePolicy::Cache.user_key(nil)).to eq("<anonymous>")
    end

    it "user class name + user id when user is not blank" do
      expect(DeclarativePolicy::Cache.user_key(wp_user)).to eq("#{wp_user.class.name}-#{wp_user.id}")
    end
  end

  context ".policy_key" do
    it "prefix + user_key + subject_key" do
      user_key = DeclarativePolicy::Cache.user_key(wp_user)
      subject_key = DeclarativePolicy::Cache.subject_key(declarative_policy_project)
      expect(DeclarativePolicy::Cache.policy_key(wp_user, declarative_policy_project)).to eq("#{DeclarativePolicy::Cache::PREFIX}/#{user_key}/#{subject_key}")
    end
  end
end
