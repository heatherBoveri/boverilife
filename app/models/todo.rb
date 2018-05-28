class Todo < ApplicationRecord
  default_scope { order('key ASC') }

  belongs_to :location
end
