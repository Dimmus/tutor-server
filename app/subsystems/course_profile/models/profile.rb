class CourseProfile::Models::Profile < Tutor::SubSystems::BaseModel
  belongs_to :course, subsystem: :entity

  validates :name, presence: true
  validates :timezone, presence: true,
                       inclusion: { in: ActiveSupport::TimeZone.all.collect(&:name) }

  delegate :name, to: :school,
                  prefix: true,
                  allow_nil: true
end
