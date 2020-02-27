class CreateMorphemes < ActiveRecord::Migration[6.0]
  def change
    create_table :morphemes do |t|
      t.string :value

      t.timestamps
    end
  end
end
