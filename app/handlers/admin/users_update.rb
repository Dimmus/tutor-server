class Admin::UsersUpdate
  ALLOWED_ATTRIBUTES = ['username', 'first_name', 'last_name', 'full_name', 'title']

  lev_handler

  uses_routine User::SetAdministratorState, as: :set_administrator
  uses_routine User::SetCustomerServiceState, as: :set_customer_service
  uses_routine User::SetContentAnalystState, as: :set_content_analyst

  paramify :user do
    attribute :username, type: String
    attribute :first_name, type: String
    attribute :last_name, type: String
    attribute :full_name, type: String
    attribute :title, type: String
    attribute :administrator, type: boolean
    attribute :customer_service, type: boolean
    attribute :content_analyst, type: boolean
  end

  protected

  def authorized?
    true
  end

  # The :profile option is required
  def handle
    user = options[:user]
    outputs[:user] = user
    account = user.account
    outputs[:account] = account

    # Validate the account but do not call save
    # Use update_columns to prevent save callbacks that would send updates to Accounts
    account.assign_attributes(user_params.attributes.slice(*ALLOWED_ATTRIBUTES))
    account.valid?
    transfer_errors_from account, {type: :verbatim}, true
    account.update_columns(user_params.attributes.slice(*ALLOWED_ATTRIBUTES))

    run(:set_administrator, user: user, administrator: user_params.administrator)
    run(:set_customer_service, user: user, customer_service: user_params.customer_service)
    run(:set_content_analyst, user: user, content_analyst: user_params.content_analyst)
  end
end
