# DeclarativePolicy

https://docs.gitlab.com/ee/development/policies.html

This gem is extracted from gitlab. Now it is beta version.

In my option, this gem is more flexible and includes performance improvement trick than cancancan or pundit.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'declarative_policy'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install declarative_policy

## Usage

```
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

DeclarativePolicy.policy_for(user, project).can?(:destroy_project)

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wpzero/declarative_policy. This project is intended to be a safe, welcoming space for collaboration.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the DeclarativePolicy project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/declarative_policy/blob/master/CODE_OF_CONDUCT.md).
