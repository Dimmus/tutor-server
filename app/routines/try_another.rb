# Move to task (do iReading) subsystem

class TryAnother

  lev_routine

  protected

  def exec(tasked_exercise:)
    recovery_exercise = tasked_exercise.recovery_tasked_exercise
    fatal_error(:missing_recovery_exercise) if recovery_exercise.nil?

    task_step = tasked_exercise.task_step
    task = task_step.task
    outputs[:task] = task

    recovery_step = TaskStep.new(task: task, number: task_step.number + 1)
    outputs[:recovery_step] = recovery_step
    recovery_step.tasked = recovery_exercise
    tasked_exercise.recovery_tasked_exercise = nil
    task.task_steps << recovery_step
    recovery_step.save!

    transfer_errors_from(recovery_step, type: :verbatim)
  end
end
