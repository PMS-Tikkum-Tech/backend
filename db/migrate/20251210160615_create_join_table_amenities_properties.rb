class CreateJoinTableAmenitiesProperties < ActiveRecord::Migration[7.1]
  def change
    create_join_table :amenities, :properties do |t|
      # t.index [:amenity_id, :property_id]
      # t.index [:property_id, :amenity_id]
    end
  end
end
