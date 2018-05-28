class AddIgnoreInLifetime < ActiveRecord::Migration[5.1]
  def change
    add_column :trips, :ignore_in_lifetime, :boolean, default: false
  end
end
