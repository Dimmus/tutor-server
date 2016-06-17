module Api::V1

  # Represents the information that a user should be able to view about their profile
  class BootstrapDataRepresenter < ::Roar::Decorator

    include ::Roar::JSON

    property :user,
             extend: Api::V1::UserRepresenter,
             readable: true,
             writeable: false,
             getter: ->(*) { self }

    property :base_accounts_url,
             readable: true,
             writeable: false,
             getter: ->(*) { OpenStax::Accounts.configuration.openstax_accounts_url }

    property :accounts_profile_url,
             readable: true,
             writeable: false,
             getter: ->(*) {
               OpenStax::Utilities.generate_url(
                 OpenStax::Accounts.configuration.openstax_accounts_url, "profile"
               )
             }

    property :tutor_notices_url,
             readable: true,
             writeable: false,
             getter: ->(user_options:, **) { user_options[:tutor_notices_url] }

    property :flash,
             readable: true,
             writeable: false,
             getter: ->(user_options:, **) { user_options[:flash] },
             schema: {
               required: false,
               description: "A hash of messages the backend would like the frontend to show. " +
                            "Inner keys include `success`, `notice`, `alert`, `error` and point " +
                            "to the message.  These keys can be interpreted as referring to " +
                            "Bootstrap `success`, `info`, `warning`, and `danger` alert stylings."
             }

    property :courses,
             extend: Api::V1::CoursesRepresenter,
             readable: true,
             writeable: false,
             getter: ->(*) {
               CollectCourseInfo[
                 user: self,
                 with: [:roles, :periods, :ecosystem, :ecosystem_book, :students]
               ]
             }
  end
end
