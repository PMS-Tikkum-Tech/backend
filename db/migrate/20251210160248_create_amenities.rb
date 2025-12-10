class CreateAmenities < ActiveRecord::Migration[7.1]
  def change
    create_table :amenities do |t|
      t.string :name
      t.string :description
      t.string :icon
      t.string :category

      t.timestamps
    end
  end
end
