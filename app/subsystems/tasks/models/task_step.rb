class Tasks::Models::TaskStep < Tutor::SubSystems::BaseModel

  acts_as_paranoid

  sortable_belongs_to :task, -> { with_deleted }, on: :number, inverse_of: :task_steps, touch: true
  belongs_to :tasked, -> { with_deleted }, polymorphic: true, dependent: :destroy,
                                          inverse_of: :task_step, touch: true

  enum group_type: [:default_group, :core_group, :spaced_practice_group,
                    :personalized_group, :recovery_group]

  serialize :related_content, Array
  serialize :labels, Array

  validates :task, presence: true
  validates :tasked, presence: true
  validates :tasked_id, uniqueness: { scope: :tasked_type }
  validates :group_type, presence: true

  delegate :can_be_answered?, :has_correctness?, to: :tasked

  scope :complete,   -> { where{first_completed_at != nil} }
  scope :incomplete, -> { where{first_completed_at == nil} }

  scope :exercises,  -> { where{tasked_type == Tasks::Models::TaskedExercise.name} }

  after_save { task.update_step_counts! }

  def exercise?
    tasked_type == Tasks::Models::TaskedExercise.name
  end

  def placeholder?
    tasked_type == Tasks::Models::TaskedPlaceholder.name
  end

  def is_correct?
    return nil unless has_correctness?
    tasked.is_correct?
  end

  def can_be_recovered?
    related_exercise_ids.any?
  end

  def make_correct!
    raise "Does not have correctness" unless has_correctness?
    tasked.make_correct!
  end

  def make_incorrect!
    raise "Does not have correctness" unless has_correctness?
    tasked.make_incorrect!
  end

  def complete(completion_time: Time.current)
    self.first_completed_at ||= completion_time
    self.last_completed_at = completion_time
    self
  end

  def completed?
    !first_completed_at.nil?
  end

  def feedback_available?
    completed? && task.feedback_available?
  end

  def group_name
    group_type.gsub(/_group\z/, '').gsub('_', ' ')
  end

  def add_related_content(related_content_hash)
    return if related_content_hash.nil?
    self.related_content << related_content_hash
  end

  def add_labels(labels)
    self.labels = [self.labels, labels].flatten.compact.uniq
  end

end
