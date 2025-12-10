class AddFieldsToPhotos < ActiveRecord::Migration[7.1]
  def change
    add_reference :photos, :room, null: false, foreign_key: true
    add_column :photos, :is_featured, :boolean
  end
end
