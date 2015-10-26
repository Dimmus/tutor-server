class CourseMembership::Strategies::Direct::EnrollmentChange < Entity

  wraps CourseMembership::Models::EnrollmentChange

  exposes :profile, :from_period, :to_period, :status, :pending?, :approved?, :rejected?,
          :requires_enrollee_approval, :enrollee_approved_at

  def user
    ::User::User.new(strategy: profile)
  end

  alias_method :from_period_strategy, :from_period
  def from_period
    strategy = from_period_strategy
    strategy.nil? ? nil : ::CourseMembership::Period.new(strategy: strategy)
  end

  alias_method :to_period_strategy, :to_period
  def to_period
    ::CourseMembership::Period.new(strategy: to_period_strategy)
  end

  alias_method :string_status, :status
  def status
    string_status.to_sym
  end

  def to_model
    repository
  end

end
