class AddTodo < ActiveRecord::Migration[5.1]
  def change
    create_table :todos do |t|
      t.text :value
      t.string :key
      t.integer :location_id
    end
    add_column :locations, :state, :string
  end
end
