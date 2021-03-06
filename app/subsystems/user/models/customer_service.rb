module User
  module Models
    class CustomerService < Tutor::SubSystems::BaseModel
      belongs_to :profile, -> { with_deleted }, inverse_of: :customer_service

      validates :profile, presence: true, uniqueness: true
    end
  end
end
