class ImportBook

  #
  # NOT CURRENTLY USED
  #   *   *   *   *
  # NOT CURRENTLY USED
  #

  lev_routine

  uses_routine Content::Routines::ImportBookPart,
               as: :import_book_part,
               translations: { outputs: { type: :verbatim } }

  protected

  # Imports and saves a Cnx::Book as an Entity::Book
  # Returns the Book object, Resource object and collection JSON as a hash
  def exec(cnx_book:)
    run(:import_book_part, cnx_book.root_book_part)

    content_book_part.url = outputs[:url]
    content_book_part.content = outputs[:content]

    outputs[:book] = Entity::Book.create!
    content_book_part.book = outputs[:book]
    content_book_part.save
    transfer_errors_from(content_book_part, {type: :verbatim}, true)
  end

end
