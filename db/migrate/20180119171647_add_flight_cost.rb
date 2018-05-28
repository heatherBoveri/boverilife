class AddFlightCost < ActiveRecord::Migration[5.1]
  def change
    rename_column :trips, :destination_flight_cost, :min_flight_cost
    rename_column :trips, :return_flight_cost, :max_flight_cost
    add_column :trips, :better_with_kids, :boolean
    add_column :trips, :avg_flight_cost, :integer
  end
end
