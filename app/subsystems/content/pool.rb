module Content
  class Pool

    include Wrapper

    def uuid
      verify_and_return @strategy.uuid, klass: ::Content::Uuid
    end

    def pool_type
      verify_and_return @strategy.pool_type, klass: Symbol
    end

    def exercise_ids
      verify_and_return @strategy.exercise_ids, klass: Integer
    end

    def exercises
      verify_and_return @strategy.exercises, klass: ::Content::Exercise
    end

  end
end