class IssuePolicy < BasePolicy
  delegate :project do
    project
  end

  desc "User is the owner of the issue"
  condition "owner" do
    subject.user == user
  end

  rule { owner }.policy do
    enable :edit_issue
  end

  rule { owner | project.owner }.policy do
    enable :destroy_issue
  end

  rule { global_always_true }.policy do
    prevent :mix_delegate_action
  end

  rule { can?(:edit_issue) }.policy do
    enable :upload_image_from_issue
  end
end
