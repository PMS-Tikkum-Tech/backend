class CreatePhotos < ActiveRecord::Migration[7.1]
  def change
    create_table :photos do |t|
      t.references :property, null: false, foreign_key: true
      t.string :title
      t.string :description

      t.timestamps
    end
  end
end
