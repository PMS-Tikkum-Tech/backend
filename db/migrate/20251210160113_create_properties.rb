class CreateProperties < ActiveRecord::Migration[7.1]
  def change
    create_table :properties do |t|
      t.string :title
      t.text :description
      t.string :address
      t.string :city
      t.string :province
      t.string :postal_code
      t.string :country
      t.string :property_type
      t.string :accommodation_type
      t.string :status
      t.references :landlord, null: false, foreign_key: true

      t.timestamps
    end
  end
end
