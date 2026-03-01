# frozen_string_literal: true

class RemoveAllowedpeopleFromProperties < ActiveRecord::Migration[6.1]
  def change
    remove_index :properties, :allowedpeople if index_exists?(:properties,
                                                               :allowedpeople)
    remove_column :properties, :allowedpeople, :integer if column_exists?(:properties,
                                                                          :allowedpeople)
  end
end
