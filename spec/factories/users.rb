FactoryGirl.define do
  factory :user, class: 'User::User' do
    skip_create

    transient do
      username { SecureRandom.hex.to_s }
      full_name { [first_name, last_name].join(' ') }
      first_name { SecureRandom.hex.to_s }
      last_name { SecureRandom.hex.to_s }
      skip_terms_agreement { false }
      exchange_write_identifier { SecureRandom.hex.to_s }
      exchange_read_identifier { SecureRandom.hex.to_s }

      profile { create(:user_profile,
                       first_name: first_name,
                       last_name: last_name,
                       full_name: full_name,
                       username: username,
                       skip_terms_agreement: skip_terms_agreement,
                       exchange_read_identifier: exchange_read_identifier,
                       exchange_write_identifier: exchange_write_identifier) }
      strategy { User::Strategies::Direct::User.new(profile) }
    end

    initialize_with { new(strategy: strategy) }

    trait :administrator do
      after(:build) do |user|
        user.to_model.administrator = build(:user_administrator, profile: user.to_model)
      end
    end

    trait :content_analyst do
      after(:build) do |user|
        user.to_model.content_analyst = build(:user_content_analyst,
                                              profile: user.to_model)
      end
    end

    trait :customer_service do
      after(:build) do |user|
        user.to_model.customer_service = build(:user_customer_service,
                                               profile: user.to_model)
      end
    end
  end
end
