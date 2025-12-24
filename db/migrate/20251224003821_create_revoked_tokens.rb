class CreateRevokedTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :revoked_tokens do |t|
      t.string :jti, null: false
      t.references :user, null: false, foreign_key: true
      t.datetime :exp, null: false

      t.timestamps null: false
    end

    add_index :revoked_tokens, :jti, unique: true
    add_index :revoked_tokens, :exp
  end
end
