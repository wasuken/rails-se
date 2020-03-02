class CreateTextMorphemes < ActiveRecord::Migration[6.0]
  def change
    create_table :text_morphemes do |t|
      t.integer :morpheme_id
      t.integer :text_id
      t.float :tf
      t.float :idf
      t.float :score

      t.timestamps
    end
  end
end
