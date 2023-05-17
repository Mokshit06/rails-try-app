class CreateQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :questions do |t|
      t.string :question, limit: 140
      t.text :content, null: true
      t.text :answer, null: true, limit: 1000
      t.integer :ask_count, default: 1
      t.string :audio_src_url, null: true, limit: 255

      t.timestamps
    end
  end
end
