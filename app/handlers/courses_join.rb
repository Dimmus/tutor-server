class CoursesJoin
  lev_handler

  uses_routine AddUserAsCourseTeacher, as: :add_teacher
  uses_routine GetCourseProfile

  protected
  def authorized?; true; end

  def handle
    after_transaction { raise_handled_exceptions! }

    course = find_course_by_join_token
    run(:add_teacher, course: course, user: caller)
  end

  private
  def find_course_by_join_token
    profile = run(:get_course_profile, attrs: {
      teacher_join_token: params[:join_token]
    }).outputs.profile

    Entity::Course.find(profile.course_id)
  end

  def raise_handled_exceptions!
    raise self.class.handled_exceptions[errors.first.code] if errors.any?
  end

  def self.handled_exceptions
    @@handled_exceptions ||= {
      profile_not_found: InvalidTeacherJoinToken,
      user_is_already_teacher_of_course: UserAlreadyCourseTeacher
    }
  end
end

class InvalidTeacherJoinToken < StandardError; end
class UserAlreadyCourseTeacher < StandardError; end