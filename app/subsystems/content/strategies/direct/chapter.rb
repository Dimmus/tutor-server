module Content
  module Strategies
    module Direct
      class Chapter < Entity

        wraps ::Content::Models::Chapter

        exposes :book, :pages, :title, :book_location

        alias_method :entity_book, :book
        def book
          ::Content::Book.new(strategy: entity_book)
        end

        alias_method :entity_pages, :pages
        def pages
          entity_pages.collect do |entity_page|
            ::Content::Page.new(strategy: entity_page)
          end
        end

      end
    end
  end
end