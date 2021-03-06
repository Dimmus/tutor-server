class CourseContent::Models::ExcludedExercise < Tutor::SubSystems::BaseModel

  belongs_to :course, subsystem: :course_profile

  validates :course, presence: true
  validates :exercise_number, presence: true, uniqueness: { scope: :course_profile_course_id }

end
