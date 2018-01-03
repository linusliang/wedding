class CreatePictures < ActiveRecord::Migration[5.0]
  def change
    create_table :pictures do |t|
      t.text :url
      t.text :caption
      t.text :pid
      t.text :time_taken
      t.timestamps
    end

    execute <<-SQL
		ALTER TABLE pictures CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin, MODIFY caption VARCHAR(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin
    SQL

  end
end