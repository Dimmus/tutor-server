class Admin::UsersCreate
  ALLOWED_ATTRIBUTES = ['username', 'password', 'first_name', 'last_name',
                        'full_name', 'title', 'email']

  lev_handler

  uses_routine User::CreateUser, translations: { outputs: { type: :verbatim } }, as: :create_user
  uses_routine User::SetAdministratorState, as: :set_administrator
  uses_routine User::SetCustomerServiceState, as: :set_customer_service
  uses_routine User::SetContentAnalystState, as: :set_content_analyst

  paramify :user do
    attribute :username, type: String
    attribute :password, type: String
    attribute :first_name, type: String
    attribute :last_name, type: String
    attribute :full_name, type: String
    attribute :title, type: String
    attribute :email, type: String
    attribute :administrator, type: boolean
    attribute :customer_service, type: boolean
    attribute :content_analyst, type: boolean

    validates :username, presence: true
    validates :password, presence: true
    validates :first_name, presence: true
    validates :last_name, presence: true
  end

  protected

  def authorized?
    true
  end

  def handle
    run(:create_user, **user_params.attributes.slice(*ALLOWED_ATTRIBUTES).symbolize_keys)

    user = outputs[:user]
    run(:set_administrator, user: user, administrator: user_params.administrator)
    run(:set_customer_service, user: user, customer_service: user_params.customer_service)
    run(:set_content_analyst, user: user, content_analyst: user_params.content_analyst)
  end
end
