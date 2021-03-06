class ShortCode::Models::ShortCode < Tutor::SubSystems::BaseModel
  validates :uri, presence: true
  validates :code, presence: true, uniqueness: true

  before_validation :generate_code

  ALPHANUMERICS = (0..9).to_a + ('a'..'z').to_a + ('A'..'Z').to_a

  protected

  def generate_code
    if self.code.nil?
      self.code = (0..5).map { ALPHANUMERICS.sample }.join
      while ShortCode::Models::ShortCode.find_by_code(self.code)
        self.code = (0..5).map { ALPHANUMERICS.sample }.join
      end
    end
    true
  end
end
