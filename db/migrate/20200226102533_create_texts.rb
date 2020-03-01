class CreateTexts < ActiveRecord::Migration[6.0]
  def change
    create_table :texts do |t|
      t.string :contents
      t.string :url
      t.string :title
      t.string :contents_hash

      t.timestamps
    end
    add_index :texts, :contents_hash, unique: true
  end
end
