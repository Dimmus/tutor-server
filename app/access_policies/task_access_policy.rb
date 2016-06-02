class TaskAccessPolicy
  def self.action_allowed?(action, requestor, task)
    case action
    when :read
      requestor.is_human? &&
      ((user_is_tasked?(requestor, task) && task.past_open?) || user_is_teacher?(requestor, task))
    when :accept_or_reject_late_work
      requestor.is_human? && !task.deleted? && user_is_teacher?(requestor, task)
    when :hide
      requestor.is_human? && task.deleted? && user_is_tasked?(requestor, task)
    else
      false
    end
  end

  def self.get_entity_course(task)
    course = task.task_plan.try(:owner) ||  # normal course
             task.concept_coach_task.try(:task).try(:taskings).try(:first)
                                    .try(:period).try(:course) # cc course
    course.is_a?(Entity::Course) ? course : nil
  end

  def self.user_is_tasked?(user, task)
    DoesTaskingExist[user: user, task_component: task]
  end

  def self.user_is_teacher?(user, task)
    (course = get_entity_course(task)).present? &&
    UserIsCourseTeacher[user: user, course: course]
  end

end
