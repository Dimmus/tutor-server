class CoursesController < ApplicationController

  def teach
    handle_with(CoursesTeach, complete: -> { send_to_dashboard })
  end

  def enroll
    handle_with(CoursesEnroll,
                success: -> {},
                failure: -> {
                  case @handler_result.errors.map(&:code).first
                  when :user_is_already_a_course_student
                    send_to_dashboard(notice: "You are already enrolled in this course.")
                  when :enrollment_code_not_found
                    enrollment_code_not_found
                  else
                    raise StandardError, "Student URL enrollment failed: #{@handler_result.errors}"
                  end
                })
  end

  def confirm_enrollment
    handle_with(CoursesConfirmEnrollment,
                success: -> {
                  send_to_dashboard
                },
                failure: -> {
                  case @handler_result.errors.map(&:code).first
                  when :user_is_already_a_course_student
                    send_to_dashboard(notice: "You are already enrolled in this course.")
                  when :enrollment_code_not_found
                    enrollment_code_not_found
                  when :taken
                    flash[:error] = "That school-issued ID is already in use."
                    redirect_to token_enroll_path(params[:enroll][:enrollment_token])
                  else
                    raise StandardError, "Student URL enrollment confirmation failed: #{@handler_result.errors}"
                  end
                })
  end

  private

  def send_to_dashboard(notice: nil)
    course = @handler_result.outputs.course
    redirect_to course_dashboard_path(course), notice: notice
  end

  def enrollment_code_not_found
    render 'static_pages/generic_error',
            locals: {
              heading: 'Invalid enrollment URL',
              body: <<-BODY
                You are trying to enroll in a class as a student, but the URL you used
                is either out of date or does not correspond to an existing course.
                Please contact your instructor for a new enrollment URL.
              BODY
            }
  end

end
