class BuildTaskPlan

  lev_routine express_output: :task_plan

  protected

  def exec(course:, assistant: nil)
    tp = Tasks::Models::TaskPlan.new(owner: course, assistant: assistant)
    outputs[:task_plan] = tp
    transfer_errors_from tp, type: :verbatim
  end

end
