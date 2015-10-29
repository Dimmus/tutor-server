module Wrapper

  def self.included(base)
    base.send(:include, TypeVerification)
    base.extend ClassMethods
  end

  def initialize(strategy:)
    @strategy = strategy
  end

  # Returns the strategy
  # For internal use only
  def _strategy
    @strategy
  end

  # Wrappers are equal if the strategies are equal
  def ==(other)
    self.class == other.class && @strategy == other._strategy
  end

  # Hash key equality
  def eql?(other)
    self.class.eql?(other.class) && @strategy.eql?(other._strategy)
  end

  # Hash function
  def hash
    self.class.hash ^ @strategy.hash
  end

  module ClassMethods
    def _define_dynamic_wrapping(name, type)
        define_method(name) do
          verify_and_return @strategy.send(name), klass: type, error: StrategyError
        end
    end

    def wrap_attributes(model, *attributes)
      attributes.map.each do | attr |
        col = model.columns.find{|column| column.name == attr.to_s }
        type = case col.cast_type.type
               when :integer then Integer
               when :string  then String
               when :boolean then :boolean
               else
                 raise "Unable to determine type of attribute #{attr}, sql type was #{col.cast_type.type}"
               end
        _define_dynamic_wrapping(attr.to_sym, type)
      end
    end

    cattr_accessor :strategy_class

    def self.with_strategy_class(strategy_class, &block)
      original_strategy_class = self.strategy_class
      self.strategy_class = strategy_class
      result = yield
      self.strategy_class = original_strategy_class
      result
    end

  end
end
