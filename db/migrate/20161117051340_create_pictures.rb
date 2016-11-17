class CreatePictures < ActiveRecord::Migration[5.0]
  def change
    create_table :pictures do |t|
      t.text :url
      t.text :caption
      t.text :pid
      t.timestamps
    end
  end
end
