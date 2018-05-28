class CreateTrips < ActiveRecord::Migration[5.1]
  def change
    create_table :trips do |t|
      t.integer :year
      t.integer :matt_rating
      t.integer :heather_rating
      t.integer :destination_flight_cost
      t.string :destination_airport
      t.string :return_airport
      t.integer :return_flight_cost
      t.integer :total_hours
      t.integer :travel_hours
      t.string :name
      t.timestamps
    end

    create_table :locations do |t|
      t.string :country, null: false
      t.string :city, null: false
      t.integer :order, null: false, default: 1
      t.integer :cost, null: false, default: 0
      t.integer :days, null: false, default: 1
      t.integer :trip_id, null: false
      t.timestamps
    end
  end
end
