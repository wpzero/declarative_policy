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
end
