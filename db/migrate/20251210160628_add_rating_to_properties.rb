class AddRatingToProperties < ActiveRecord::Migration[7.1]
  def change
    add_column :properties, :average_rating, :decimal
    add_column :properties, :total_reviews, :integer
    add_column :properties, :latitude, :decimal
    add_column :properties, :longitude, :decimal
  end
end
