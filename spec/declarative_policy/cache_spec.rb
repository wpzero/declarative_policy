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
    it "POLICY_PREFIX + user_key + subject_key" do
      user_key = DeclarativePolicy::Cache.user_key(wp_user)
      subject_key = DeclarativePolicy::Cache.subject_key(declarative_policy_project)
      expect(DeclarativePolicy::Cache.policy_key(wp_user, declarative_policy_project)).to eq("#{DeclarativePolicy::Cache::POLICY_PREFIX}/#{user_key}/#{subject_key}")
    end
  end

  context ".callable_condition_key" do
    let(:project) do
      Project.find_by_name("declarative_policy")
    end

    let(:user) do
      User.find_by_name("wp")
    end

    let(:project_policy) do
      ProjectPolicy.new(user, project)
    end

    let(:condition) do
      DeclarativePolicy::Condition.new("admin", description: "User is a admin", context_key: "ProjectPolicy") do
        true
      end
    end

    let(:callable_condition) do
      DeclarativePolicy::CallableCondition.new(project_policy, condition)
    end

    context "when scope is normal" do
      it "uniq key with subject and user info" do
        expect(DeclarativePolicy::Cache.callable_condition_key(callable_condition)).to eq("__callable_condition/ProjectPolicy/admin/User-#{user.id}/Project-#{project.id}")
      end
    end

    context "when scope is user" do
      let(:condition) do
        DeclarativePolicy::Condition.new("admin", description: "User is a admin", context_key: "ProjectPolicy", scope: :user) do
          true
        end
      end

      it "uniq key with user info" do
        expect(DeclarativePolicy::Cache.callable_condition_key(callable_condition)).to eq("__callable_condition/ProjectPolicy/admin/User-#{user.id}")
      end
    end

    context "when scope is subject" do
      let(:condition) do
        DeclarativePolicy::Condition.new("admin", description: "User is a admin", context_key: "ProjectPolicy", scope: :subject) do
          true
        end
      end

      it "uniq key with subject info" do
        expect(DeclarativePolicy::Cache.callable_condition_key(callable_condition)).to eq("__callable_condition/ProjectPolicy/admin/Project-#{project.id}")
      end
    end

    context "when scope is global" do
      let(:condition) do
        DeclarativePolicy::Condition.new("admin", description: "User is a admin", context_key: "ProjectPolicy", scope: :global) do
          true
        end
      end

      it "uniq key with policy name and condition name" do
        expect(DeclarativePolicy::Cache.callable_condition_key(callable_condition)).to eq("__callable_condition/ProjectPolicy/admin/")
      end
    end

    context "when scope is ilegal type" do
      let(:condition) do
        DeclarativePolicy::Condition.new("admin", description: "User is a admin", context_key: "ProjectPolicy", scope: :xx) do
          true
        end
      end

      it "uniq key with policy name and condition name" do
        expect{ DeclarativePolicy::Cache.callable_condition_key(callable_condition) }.to raise_error("Invalid scope")
      end
    end
  end
end
