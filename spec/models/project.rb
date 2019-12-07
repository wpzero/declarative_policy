class Project < ActiveRecord::Base
  belongs_to :projectable, polymorphic: true
end
