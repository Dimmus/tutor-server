module User
  module Models
    class Administrator < Tutor::SubSystems::BaseModel
      belongs_to :profile, -> { with_deleted }, inverse_of: :administrator

      validates :profile, presence: true, uniqueness: true
    end
  end
end
