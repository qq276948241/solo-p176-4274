class CreateTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :tokens do |t|
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.string :description

      t.timestamps
    end
    add_index :tokens, :token, unique: true
    add_index :tokens, :expires_at
  end
end
