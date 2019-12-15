class ProjectPolicy < BasePolicy
  desc "User is the owner of the project"
  condition "owner" do
    subject.projectable == user
  end

  desc "User is a member of the project's group"
  condition "member" do
    user &&
      subject.projectable.is_a?(Group) &&
      subject.projectable.users.where(id: user.id).exist?
  end

  rule { owner }.policy do
    enable :destroy_project
    enable :edit_project
  end

  rule { global_always_true }.policy do
    enable :mix_delegate_action
  end
end
