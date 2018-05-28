class AddImage < ActiveRecord::Migration[5.1]
  def change
    create_table :images do |t|
      t.string :src
      t.string :link
      t.integer :location_id
    end
  end
end
