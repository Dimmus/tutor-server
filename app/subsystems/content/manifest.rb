module Content
  class Manifest

    class Book

      include Wrapper

      def archive_url
        verify_and_return @strategy.archive_url, klass: String, error: StrategyError,
                                                 allow_nil: true
      end

      def cnx_id
        verify_and_return @strategy.cnx_id, klass: String, error: StrategyError
      end

      def exercise_ids
        verify_and_return @strategy.exercise_ids, klass: String, error: StrategyError,
                                                  allow_nil: true
      end

      def valid?
        !!@strategy.valid?
      end

      def update_version!
        verify_and_return @strategy.update_version!, klass: self.class, error: StrategyError
      end

      def unlock_exercises!
        verify_and_return @strategy.unlock_exercises!, klass: self.class, error: StrategyError
      end

    end

    include Wrapper

    def self.from_yaml(yaml, strategy_class: ::Content::Strategies::Generated::Manifest)
      yaml = verify_and_return yaml, klass: String
      strategy = verify_and_return strategy_class.from_yaml(yaml), klass: strategy_class,
                                                                   error: StrategyError
      new(strategy: strategy)
    end

    def to_yaml
      verify_and_return @strategy.to_yaml, klass: String, error: StrategyError
    end

    def title
      verify_and_return @strategy.title, klass: String, error: StrategyError
    end

    def books
      verify_and_return @strategy.books, klass: ::Content::Manifest::Book, error: StrategyError
    end

    def valid?
      !!@strategy.valid?
    end

    def update_book!
      verify_and_return @strategy.update_book!, klass: self.class, error: StrategyError
    end

    def unlock_exercises!
      verify_and_return @strategy.unlock_exercises!, klass: self.class, error: StrategyError
    end

  end
end
