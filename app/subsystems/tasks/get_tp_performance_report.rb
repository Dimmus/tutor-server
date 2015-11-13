module Tasks
  class GetTpPerformanceReport
    include PerformanceReportMethods

    lev_routine express_output: :performance_report

    protected

    def exec(course:)
      taskings = get_taskings(course)

      outputs[:performance_report] = course.periods.collect do |period|
        tasking_plans = sort_tasking_plans(taskings, course, period)
        task_plan_indices = tasking_plans.each_with_index
                                         .each_with_object({}) { |(tasking_plan, index), hash|
                                           hash[tasking_plan.task_plan] = index
                                         }
        role_taskings = taskings.to_a.group_by(&:role)
        sorted_student_data = role_taskings.sort_by { |student_role, _|
                                student_role.profile.account.last_name.downcase
        }
        task_plan_results = Hash.new{|h, key|h[key] = []}

        student_data = sorted_student_data.collect do |student_role, student_taskings|
                         # skip if student is no longer in the current period
                         next if student_role.student.period != period

                         # Populate the student_tasks array but leave empty spaces (nils)
                         # for assignments the student hasn't done
                         student_tasks = Array.new(tasking_plans.size)
                         student_taskings.each do |tg|
                           index = task_plan_indices[tg.task.task.task_plan]
                           # skip if task not assigned to current period
                           # could be individual, like practice widget,
                           # or assigned to a different period
                           next if index.nil?
                           student_tasks[index] = tg.task.task
                         end

                         # gather the task into the results for use in calculating header stats
                         student_tasks.each do | task |
                           next unless task
                           task_plan_results[task.task_plan] << task
                         end

                         {
                           name: student_role.name,
                           first_name: student_role.first_name,
                           last_name: student_role.last_name,
                           student_identifier: student_role.student.student_identifier,
                           role: student_role.id,
                           data: get_student_data(student_tasks)
                         }
                       end.compact

        Hashie::Mash.new({
          period: period,
          data_headings: get_data_headings(tasking_plans, task_plan_results),
          students: student_data
        })
      end
    end

    def sort_tasking_plans(taskings, course, period)
      taskings.flat_map { |tg|
        tg.task.task.task_plan.tasking_plans.select do |tp|
          tp.target == period  || tp.target == course
        end
      }.uniq.sort { |a, b|
        [b.due_at, b.created_at] <=> [a.due_at, a.created_at]
      }
    end

    def get_taskings(course)
      task_types = Models::Task.task_types.values_at(:reading, :homework, :external)
      # Return reading, homework and external tasks for a student
      course.taskings.preload(task: {task: {task_plan: {tasking_plans: :target} }},
                              role: [{student: {enrollments: :period}},
                                     {profile: :account}])
                     .joins(task: :task)
                     .where(task: {task: {task_type: task_types}})
    end

    def get_data_headings(tasking_plans, task_plan_results)
      tasking_plans.map do |tasking_plan|
        task_plan = tasking_plan.task_plan
        {
          title: task_plan.title,
          plan_id: task_plan.id,
          type: task_plan.type,
          due_at: tasking_plan.due_at,
          average: average(task_plan_results[task_plan])
        }
      end
    end
  end
end