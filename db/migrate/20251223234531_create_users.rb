class CreateUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :first_name, null: false
      t.string :last_name
      t.string :phone

      # Role: 0 = owner, 1 = admin
      t.integer :role, default: 0, null: false
      t.boolean :active, default: true, null: false

      # JWT refresh token
      t.string :refresh_token
      t.datetime :refresh_token_expires_at

      t.timestamps null: false
    end

    add_index :users, :email, unique: true
    add_index :users, :refresh_token, unique: true
  end
end
