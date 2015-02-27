class CreateContentBooks < ActiveRecord::Migration
  def change
    create_table :content_books do |t|
      t.resource allow_nil: true
      t.references :parent_book
      t.references :entity_book
      t.integer :number, null: false
      t.string :title, null: false

      t.timestamps null: false

      t.resource_index
      t.index [:parent_book_id, :number], unique: true
      t.index :entity_book_id
    end

    add_foreign_key :content_books, :content_books, column: :parent_book_id,
                                                    on_update: :cascade,
                                                    on_delete: :cascade

    add_foreign_key :content_books, :entity_books, on_update: :cascade,
                                                   on_delete: :cascade
  end
end
