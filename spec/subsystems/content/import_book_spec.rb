require 'rails_helper'
require 'vcr_helper'

RSpec.describe Content::ImportBook, type: :routine, speed: :slow, vcr: VCR_OPTS do

  # Store version differences in this hash
  let!(:cnx_book) { OpenStax::Cnx::V1::Book.new(id: '93e2b09d-261c-4007-a987-0b3062fe154b') }

  # Recursively tests the given book and its children
  def test_book_part(book_part)
    expect(book_part).to be_persisted
    expect(book_part.title).not_to be_blank
    expect(book_part.child_book_parts.to_a + book_part.pages.to_a).not_to be_empty

    book_part.child_book_parts.each do |cbp|
      next if cbp == book_part
      test_book_part(cbp)
    end

    book_part.pages.each do |page|
      expect(page).to be_persisted
      expect(page.title).not_to be_blank
    end
  end

  before(:each)          { OpenStax::Biglearn::V1.use_fake_client }
  let!(:biglearn_client) { OpenStax::Biglearn::V1.fake_client }

  it 'creates a new Book structure and Pages and sets their attributes' do
    result = nil
    expect {
      result = Content::ImportBook.call(cnx_book: cnx_book);
    }.to change{ Content::Models::BookPart.count }.by(2)
    expect(result.errors).to be_empty

    book_part = result.outputs.book_part

    # TODO: Cache TOC and check it here
    test_book_part(book_part)

    expect(biglearn_client.store_exercises_copy).to_not be_empty
  end

  it 'adds a chapter_section signifier according to subcol structure' do
    book_import = Content::ImportBook.call(cnx_book: cnx_book)
    root_book_part = book_import.outputs.book_part

    root_book_part.child_book_parts.each_with_index do |chapter, i|
      expect(chapter.chapter_section).to eq([i + 1])

      page_offset = 1
      chapter.pages.each_with_index do |page, pidx|
        page_offset = 0 if page.is_intro?
        expect(page.chapter_section).to eq([i + 1, pidx + page_offset])
      end
    end
  end

end
