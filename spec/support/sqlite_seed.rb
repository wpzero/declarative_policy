module Support
  module SqliteSeed
    class << self
      def seed_db
        user1 = User.create(name: "wp", email: "wpcreep@gmail.com")
        user2 = User.create(name: "zkf", email: "zkf@gmail.com")
        user3 = User.create(name: "wxj", email: "wxj@gmail.com")
        group1 = Group.create(name: "wptech")
        group1.users << user1
        group1.users << user2
        project1 = Project.new(name: "declarative_policy", projectable: user1)
        project1.save
        project2 = Project.new(name: "btxl", projectable: group1)
        project2.save
      end

      def setup_db
        ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')
        ActiveRecord::Schema.define(version: 1) do
          create_table :projects do |t|
            t.column :name, :string
            t.column :projectable_type, :string
            t.column :projectable_id, :integer
          end

          create_table :users do |t|
            t.column :name, :string
            t.column :email, :string
          end

          create_table :groups do |t|
            t.column :name, :string
          end

          create_table :user_groups do |t|
            t.column :user_id, :integer
            t.column :group_id, :integer
          end
        end
      end
    end
  end
end
