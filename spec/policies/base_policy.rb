class BasePolicy < DeclarativePolicy::Base
  desc "User is admin"
  condition "admin", scope: :user do
    user && user.name == "wp"
  end
end
