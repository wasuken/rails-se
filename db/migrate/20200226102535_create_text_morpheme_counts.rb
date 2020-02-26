class CreateTextMorphemeCounts < ActiveRecord::Migration[6.0]
  def change
    create_table :text_morpheme_counts do |t|
      t.integer :text_id
      t.integer :count

      t.timestamps
    end
  end
end
