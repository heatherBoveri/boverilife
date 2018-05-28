class Fact < ApplicationRecord
  default_scope { order('key ASC') }

  belongs_to :location

  serialize :value
end
