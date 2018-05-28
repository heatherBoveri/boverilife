class AddTags < ActiveRecord::Migration[5.1]
  def change
    create_table :tags do |t|
      t.string :value, null: false
      t.integer :trip_id, null: false
    end
    remove_column :trips, :better_with_kids
  end
end
