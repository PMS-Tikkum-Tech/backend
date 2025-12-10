class AddFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :first_name, :string, null: false, default: ''
    add_column :users, :last_name, :string, null: false, default: ''
    add_column :users, :role, :string, null: false, default: 'tenant'
    add_column :users, :active, :boolean, null: false, default: true
    add_column :users, :phone_number, :string

    # Add indexes for performance
    add_index :users, :role
    add_index :users, :active
    add_index :users, [:role, :active]
  end
end
