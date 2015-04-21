class Content::GetPage

  lev_routine express_output: :page

  protected

  def exec(id:)
    page = Content::Models::Page.includes(:book_part).find(id)
    outputs[:page] = OpenStax::Cnx::V1::Page.new(
      id: id, content: page.content, hash: {},
      path: page.path, title: page.title, url: page.url,
      book_part_title: page.book_part.try(:title)
    )
  end

end