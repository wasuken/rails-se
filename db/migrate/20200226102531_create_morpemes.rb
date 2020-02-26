class CreateMorpemes < ActiveRecord::Migration[6.0]
  def change
    create_table :morpemes do |t|
      t.string :value

      t.timestamps
    end
  end
end
