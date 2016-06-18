class Tasks::Models::TaskingPlan < Tutor::SubSystems::BaseModel

  acts_as_paranoid

  belongs_to_time_zone :opens_at, :due_at, suffix: :ntz

  belongs_to :task_plan, -> { with_deleted }, inverse_of: :tasking_plans
  belongs_to :target, -> { respond_to?(:with_deleted) ? with_deleted : all }, polymorphic: true

  validates :target, presence: true
  validates :task_plan, presence: true, uniqueness: { scope: [:target_type, :target_id] }

  validates :opens_at_ntz, :due_at_ntz, presence: true, timeliness: { type: :date }
  validates :time_zone, presence: true

  validate :due_at_in_the_future, :due_at_on_or_after_opens_at

  validate :owner_can_task_target

  def past_open?(current_time: Time.current)
    opens_at.nil? || current_time > opens_at
  end

  def past_due?(current_time: Time.current)
    !due_at.nil? && current_time > due_at
  end

  protected

  def due_at_in_the_future
    return if task_plan.try(:is_draft?) ||
              !due_at_ntz_changed? || due_at.nil? || due_at > Time.current
    errors.add(:due_at, 'cannot be set into the past')
    false
  end

  def due_at_on_or_after_opens_at
    return if due_at.nil? || opens_at.nil? || due_at > opens_at
    errors.add(:due_at, 'cannot be before opens_at')
    false
  end

  def owner_can_task_target
    return if task_plan.nil? || target.nil? || \
              TargetAccessPolicy.action_allowed?(:task, task_plan.owner, target)
    errors.add(:target, 'cannot be assigned to')
    false
  end

end
