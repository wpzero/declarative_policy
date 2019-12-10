require 'spec_helper'

RSpec.describe DeclarativePolicy do
  let(:declarative_policy_project) do
    Project.find_by_name "declarative_policy"
  end

  let(:wp_user) do
    User.find_by_name "wp"
  end

  let(:sub_class_without_name) do
    Class.new(Project)
  end

  let(:sub_class_with_name) do
    klass = Class.new(Project)
    Object.const_set("SubProject", klass)
    klass
  end

  let(:class_without_policy) do
    klass = Class.new
    Object.const_set("ClassWithoutPolicy", klass)
    klass
  end

  it "has a version number" do
    expect(DeclarativePolicy::VERSION).not_to be nil
  end

  context ".policy_for" do
    context "when subject is not a symbol" do
      it "find policy through subject class name" do
        expect(DeclarativePolicy.policy_for(wp_user, declarative_policy_project)).to be_a(ProjectPolicy)
        expect(declarative_policy_project.class.instance_variable_get(DeclarativePolicy::CLASS_CACHE_IVAR)).to eq(ProjectPolicy)
      end
    end

    context "when subject's class is anonymous and super class has policy" do
      it "find policy through ancestors chain" do
        expect(DeclarativePolicy.policy_for(wp_user, sub_class_without_name.new)).to be_a(ProjectPolicy)
      end
    end

    context "when subject's class has name and super class has policy" do
      it "find policy through ancestors chain" do
        expect(DeclarativePolicy.policy_for(wp_user, sub_class_with_name.new)).to be_a(ProjectPolicy)
      end
    end

    context "when subject is a symbol" do
      it "find policy through symbol name" do
        expect(DeclarativePolicy.policy_for(wp_user, :global)).to be_a(GlobalPolicy)
      end
    end

    context "raise NoPolicyError when can not find policy" do
      it "raise NoPolicyError" do
        expect{DeclarativePolicy.policy_for(wp_user, :custom)}.to raise_error(DeclarativePolicy::NoPolicyError)
        expect{DeclarativePolicy.policy_for(wp_user, class_without_policy.new)}.to raise_error(DeclarativePolicy::NoPolicyError)
      end
    end

    context "declarative_policy_klass setting" do
      it "use declarative_policy_klass setting as policy" do
        klass = Class.new
        class << klass
          def declarative_policy_klass
            ProjectPolicy
          end
        end
        expect(DeclarativePolicy.policy_for(wp_user, klass.new)).to be_a(ProjectPolicy)
      end
    end
  end
end
