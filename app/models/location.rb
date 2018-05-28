class Location < ApplicationRecord
  belongs_to :trip

  default_scope { order(order: 'asc') }

  has_one :image, autosave: true, dependent: :destroy
  has_many :facts, autosave: true, dependent: :destroy
  has_many :todos, autosave: true, dependent: :destroy
  serialize :wiki

  validate :no_duplicate_images

  def total_cost
    cost * days
  end

  def name
    state.present? ? "#{city}, #{state}, #{country}" : "#{city}, #{country}"
  end

  private

  def no_duplicate_images
    images = Image.where(location_id: id)
    # errors.add(:locations, "There are duplicate images #{images.to_s}") if images.count > 1
  end
end
