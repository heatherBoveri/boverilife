class AddFacts < ActiveRecord::Migration[5.1]
  def change
    create_table :facts do |t|
      t.binary :value
      t.string :key
      t.integer :location_id
    end
    add_column :locations, :summary, :text
    add_column :locations, :wiki, :binary
  end
end
