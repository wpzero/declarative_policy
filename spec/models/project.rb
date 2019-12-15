class Project < ActiveRecord::Base
  belongs_to :projectable, polymorphic: true
  has_many :issues
end
