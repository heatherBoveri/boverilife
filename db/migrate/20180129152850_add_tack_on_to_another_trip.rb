class AddTackOnToAnotherTrip < ActiveRecord::Migration[5.1]
  def change
    add_column :trips, :ignore_return_flight, :boolean, default: false
    add_column :trips, :ignore_destination_flight, :boolean, default: false
    add_column :locations, :order, :integer
  end
end
