module User
  module Strategies
    module Direct
      class AnonymousUser < Entity
        wraps ::User::Models::AnonymousProfile

        exposes :instance, :anonymous, from_class: ::User::Models::AnonymousProfile
        exposes :account, :exchange_read_identifier, :exchange_write_identifier,
                :username, :first_name, :last_name, :full_name, :title, :name, :casual_name

        class << self
          alias_method :entity_instance, :instance
          def instance
            ::User::User.new(strategy: entity_instance)
          end

          alias_method :entity_anonymous, :anonymous
          def anonymous
            ::User::User.new(strategy: entity_anonymous)
          end
        end

        def is_human?
          true
        end

        def is_application?
          false
        end

        def is_anonymous?
          true
        end

        def is_deleted?
          false
        end

        def is_admin?
          false
        end

        def is_content_analyst?
          false
        end
      end
    end
  end
end
