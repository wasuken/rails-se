class CreateTextMorphemes < ActiveRecord::Migration[6.0]
  def change
    create_table :text_morphemes do |t|
      t.integer :morphene_id
      t.integer :text_id

      t.timestamps
    end
  end
end
