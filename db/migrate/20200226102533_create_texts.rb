class CreateTexts < ActiveRecord::Migration[6.0]
  def change
    create_table :texts do |t|
      t.string :filepath
      t.string :contents

      t.timestamps
    end
  end
end
