class CreateRooms < ActiveRecord::Migration[7.1]
  def change
    create_table :rooms do |t|
      t.string :name
      t.text :description
      t.references :property, null: false, foreign_key: true
      t.decimal :price
      t.decimal :size
      t.integer :capacity
      t.string :status
      t.date :available_from
      t.text :amenities

      t.timestamps
    end
  end
end
