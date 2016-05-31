class CourseMembership::Models::Period < Tutor::SubSystems::BaseModel
  acts_as_paranoid

  unique_token :enrollment_code, mode: :memorable

  wrapped_by CourseMembership::Strategies::Direct::Period

  belongs_to :course, subsystem: :entity

  has_many :teachers, through: :course
  has_many :teacher_roles, through: :teachers, source: :role, class_name: 'Entity::Role'

  has_many :enrollments, dependent: :destroy
  has_many :latest_enrollments, -> { latest }, class_name: '::CourseMembership::Models::Enrollment'

  has_many :enrollment_changes, dependent: :destroy

  has_many :taskings, subsystem: :tasks, dependent: :nullify
  has_many :tasks, through: :taskings

  before_destroy :no_active_students, prepend: true

  validates :course, presence: true
  validates :name, presence: true, uniqueness: { scope: :entity_course_id,
                                                 conditions: -> { where(deleted_at: nil) } }
  validates :enrollment_code, presence: true, uniqueness: true, format: {with: /[a-zA-Z0-9 ]+/}

  include DefaultTimeValidations
  validate :default_times_have_good_values

  default_scope { order(:name) }

  def student_roles(include_inactive_students: false)
    target_enrollments = include_inactive_students ?
                           latest_enrollments.with_deleted : latest_enrollments
    target_enrollments.preload(student: :role).map{ |en| en.student.role }
  end

  def default_open_time
    read_attribute(:default_open_time) || Settings::Db.store[:default_open_time]
  end

  def default_due_time
    read_attribute(:default_due_time) || Settings::Db.store[:default_due_time]
  end

  def enrollment_code_for_url
    enrollment_code.gsub(/ /,'-')
  end

  protected

  def no_active_students
    return unless enrollments.latest.exists?
    errors.add(:students, 'must be moved to another period before this period can be deleted')
    false
  end
end
