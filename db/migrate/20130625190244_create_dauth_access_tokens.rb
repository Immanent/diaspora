class CreateDauthAccessTokens < ActiveRecord::Migration
  def change
    create_table :dauth_access_tokens do |t|
      t.string :refresh_token
      t.string :token
      t.string :secret

      t.timestamps
    end
  end
end