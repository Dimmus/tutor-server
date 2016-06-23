class Api::V1::TaskPlansController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Represents a plan for a Task'
    description <<-EOS
      TaskPlans store information that assistants can use to generate Tasks.
    EOS
  end

  # TODO fix up the use of Tasks::Models throughout

  ###############################################################
  # show
  ###############################################################

  api :GET, '/plans/:id', "Retrieve a TaskPlan"
  description <<-EOS
   ### Example JSON response
   ```json
   {
     "id": 1,
     "type": "reading",
     "opens_at": "2015-03-10T21:29:35.260Z",
     "due_at": "2015-03-17T21:29:35.260Z",
     "settings": {}
   }
   ```
   #{json_schema(Api::V1::TaskPlanRepresenter, include: :readable)}
  EOS
  def show
    plan = Tasks::Models::TaskPlan.preloaded.find(params[:id])
    standard_read(plan, Api::V1::TaskPlanRepresenter)
  end

  ###############################################################
  # post
  ###############################################################

  api :POST, '/courses/:course_id/plans', 'Creates a TaskPlan'
  description <<-EOS
### IReading settings:

<pre class="code">
#{Tasks::Assistants::IReadingAssistant.schema}
</pre>

### Homework settings:

<pre class="code">
#{Tasks::Assistants::HomeworkAssistant.schema}
</pre>

### External assignment settings:

<pre class="code">
#{Tasks::Assistants::ExternalAssignmentAssistant.schema}
</pre>

### Event assignment settings:

<pre class="code">
#{Tasks::Assistants::EventAssistant.schema}
</pre>

    #{json_schema(Api::V1::TaskPlanRepresenter, include: :writeable)}
  EOS
  def create
    # Modified standard_create code
    Tasks::Models::TaskPlan.transaction do
      course = Entity::Course.find(params[:course_id])
      task_plan = BuildTaskPlan[course: course]
      consume!(task_plan, represent_with: Api::V1::TaskPlanRepresenter)
      task_plan.assistant = Tasks::GetAssistant[course: course, task_plan: task_plan]

      raise(IllegalState,
        "No assistant for task plan of type #{task_plan.type}"
      ) if task_plan.assistant.nil?

      OSU::AccessPolicy.require_action_allowed!(:create, current_api_user, task_plan)
      uuid = distribute_or_update_tasks(task_plan)

      if task_plan.errors.empty?
        ShortCode::Create[task_plan.to_global_id.to_s]

        respond_with task_plan, represent_with: Api::V1::TaskPlanRepresenter,
                                status: uuid.nil? ? :ok : :accepted,
                                location: nil
      else
        render_api_errors(task_plan.errors)
      end
    end
  end

  ###############################################################
  # update
  ###############################################################

  api :PUT, '/plans/:id', 'Updates the specified TaskPlan'
  description <<-EOS
    #{json_schema(Api::V1::TaskPlanRepresenter, include: :writeable)}
  EOS
  def update
    Tasks::Models::TaskPlan.transaction do
      # Modified standard_update code
      task_plan = Tasks::Models::TaskPlan.preloaded.lock.find(params[:id])
      OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, task_plan)
      course = task_plan.owner

      update_task_plan!(task_plan)
      OSU::AccessPolicy.require_action_allowed!(:update, current_api_user, task_plan)
      uuid = distribute_or_update_tasks(task_plan)

      if task_plan.errors.empty?
        # http://stackoverflow.com/a/27413178
        respond_with task_plan, represent_with: Api::V1::TaskPlanRepresenter,
                                responder: ResponderWithPutPatchDeleteContent,
                                status: uuid.nil? ? :ok : :accepted
      else
        render_api_errors(task_plan.errors)
      end
    end
  end

  ###############################################################
  # stats
  ###############################################################

  api :GET, '/plans/:id/stats', "Retrieve a TaskPlan along with its statistics"
  description <<-EOS
    ### Example JSON response
    <pre class='code'>
    {
        "id": 2543,
        "type": "reading",
        "stats": {
            "course": {
                "mean_grade_percent": 50,
                "total_count": 2,
                "complete_count": 0,
                "partially_complete_count": 2,
                "current_pages": [
                    {
                        "id": 1125,
                        "number": 1,
                        "title": "Force",
                        "student_count": 2,
                        "correct_count": 1,
                        "incorrect_count": 1
                    }
                ],
                "spaced_pages": [
                    {
                        "id": 0,
                        "number": 0,
                        "title": "",
                        "student_count": 0,
                        "correct_count": 0,
                        "incorrect_count": 0
                    }
                ]
            },
            "periods": []
        }
    }
    </pre>
    #{json_schema(Api::V1::TaskPlanWithStatsRepresenter, include: :readable)}
  EOS
  def stats
    plan = Tasks::Models::TaskPlan.preloaded.find(params[:id])
    standard_read(plan, Api::V1::TaskPlanWithStatsRepresenter)
  end

  ###############################################################
  # review
  ###############################################################

  api :GET, '/plans/:id/review', "Retrieve a TaskPlan along with its detailed statistics"
  description <<-EOS
    ### Example JSON response
    <pre class='code'>
    {
        "id": 2543,
        "type": "reading",
        "stats": {
            "course": {
                "mean_grade_percent": 50,
                "total_count": 2,
                "complete_count": 0,
                "partially_complete_count": 2,
                "current_pages": [
                    {
                        "id": 1125,
                        "number": 1,
                        "title": "Force",
                        "student_count": 2,
                        "correct_count": 1,
                        "incorrect_count": 1,
                        "exercises": [
                            {
                                "content": {
                                    "uid": "1@1",
                                    "number": 1,
                                    "version": 1,
                                    "first_published_at": "2015-04-22T19:30:19.187Z",
                                    "last_published_at": "2015-04-22T19:30:19.187Z",
                                    "editors": [],
                                    "authors": [
                                        {
                                            "user_id": 1
                                        }
                                    ],
                                    "copyright_holders": [
                                        {
                                            "user_id": 2
                                        }
                                    ],
                                    "derived_from": [],
                                    "attachments": [],
                                    "tags": [
                                        "k12phys-ch04-s01-lo01",
                                        "k12phys-ch04-ex001",
                                        "os-practice-concepts",
                                        "inbook-yes",
                                        "dok1",
                                        "time-short",
                                        "display-free-response"
                                    ],
                                    "stimulus_html": "",
                                    "questions": [
                                        {
                                            "id": 464,
                                            "stimulus_html": "",
                                            "stem_html": "What is kinematics?",
                                            "answers": [
                                                {
                                                    "id": 1683,
                                                    "content_html": "Kinematics is the study of atomic structure",
                                                    "correctness": "0.0",
                                                    "feedback_html": "Are you sure that the study of atomic structures is a part of kinematics?",
                                                    "selected_count": 1
                                                },
                                                {
                                                    "id": 1682,
                                                    "content_html": "Kinematics is the study of dimensions",
                                                    "correctness": "0.0",
                                                    "feedback_html": "Is it correct to say that dimensional analysis is done in kinematics?",
                                                    "selected_count": 0
                                                },
                                                {
                                                    "id": 1681,
                                                    "content_html": "Kinematics is the study of cause of motion",
                                                    "correctness": "0.0",
                                                    "feedback_html": "Do you think cause of motion is studied under kinematics? What about the study of force and its effect on a body. Is that kinematics?",
                                                    "selected_count": 0
                                                },
                                                {
                                                    "id": 1680,
                                                    "content_html": "Kinematics is the study of motion",
                                                    "correctness": "1.0",
                                                    "feedback_html": "Correct! Motion of a body is studied under kinematics",
                                                    "selected_count": 1
                                                }
                                            ],
                                            "hints": [],
                                            "formats": [
                                                "multiple-choice",
                                                "free-response"
                                            ],
                                            "combo_choices": []
                                        }
                                    ]
                                },
                                "answered_count": 2
                            }
                        ]
                    }
                ],
                "spaced_pages": [
                    {
                        "id": 0,
                        "number": 0,
                        "title": "",
                        "student_count": 0,
                        "correct_count": 0,
                        "incorrect_count": 0,
                        "exercises": []
                    }
                ]
            },
            "periods": []
        }
    }
    </pre>
    #{json_schema(Api::V1::TaskPlanWithDetailedStatsRepresenter, include: :readable)}
  EOS
  def review
    plan = Tasks::Models::TaskPlan.preloaded.find(params[:id])
    standard_read(plan, Api::V1::TaskPlanWithDetailedStatsRepresenter)
  end

  ###############################################################
  # destroy
  ###############################################################

  api :DELETE, '/plans/:id', 'Withdraws the specified TaskPlan'
  description <<-EOS
    Withdraws a task_plan from the teacher's course.

    Possible error code: task_plan_is_already_deleted

    #{json_schema(Api::V1::TaskPlanRepresenter, include: :readable)}
  EOS
  def destroy
    task_plan = Tasks::Models::TaskPlan.preloaded.with_deleted.find_by(id: params[:id])
    # Some Task models have touch: true, so delay_touching is useful here
    ActiveRecord::Base.delay_touching { standard_destroy(task_plan, Api::V1::TaskPlanRepresenter) }
  end

  api :PUT, '/plans/:id/restore', 'Restores the specified TaskPlan'
  description <<-EOS
    Restores a task_plan to the teacher's course.

    Possible error code: task_plan_is_not_deleted

    #{json_schema(Api::V1::TaskPlanRepresenter, include: :readable)}
  EOS
  def restore
    task_plan = Tasks::Models::TaskPlan.preloaded.with_deleted.find_by(id: params[:id])
    # Paranoia restore triggers .touch several times and some Task models have touch: true,
    # so delay_touching is useful here
    ActiveRecord::Base.delay_touching { standard_restore(task_plan, Api::V1::TaskPlanRepresenter) }
  end

  protected

  def update_task_plan!(task_plan)
    # If no tasks are open, just call Roar's consume! like usual
    return consume!(task_plan, represent_with: Api::V1::TaskPlanRepresenter) \
      unless task_plan.tasks_past_open?

    # Store current open dates for each TaskingPlan that is already open in the TaskPlan
    opens_at_ntzs = Hash.new{ |hash, key| hash[key] = {} }
    open_tasking_plans = task_plan.tasking_plans.select(&:past_open?)
    open_tasking_plans.each do |tp|
      opens_at_ntzs[tp.target_type][tp.target_id] = tp.opens_at_ntz
    end

    # Call Roar's consume! but force the TaskingPlans that were already open
    # to the old open date in order to prevent their open dates from changing
    consume!(task_plan, represent_with: Api::V1::TaskPlanRepresenter).tap do |result|
      task_plan.tasking_plans.each do |tp|
        tp.update_attribute(:opens_at_ntz, opens_at_ntzs[tp.target_type][tp.target_id]) \
          if opens_at_ntzs[tp.target_type].has_key?(tp.target_id)
      end
    end
  end

  # Distributes or updates distributed tasks for the given task_plan
  # Returns the job uuid, if any, or nil if the request was completed inline
  def distribute_or_update_tasks(task_plan)
    task_plan.publish_last_requested_at = Time.current \
      unless task_plan.tasks_past_open? || task_plan.is_draft?
    task_plan.save
    return unless task_plan.errors.empty?

    if task_plan.tasks_past_open?
      # Tasks already open: propagate updates
      PropagateTaskPlanUpdates.call(task_plan: task_plan)
      nil
    elsif !task_plan.is_draft?
      # Publish requested or already published but tasks not open: trigger publish
      uuid = DistributeTasks.perform_later(task_plan)
      task_plan.update_attribute(:publish_job_uuid, uuid)
      uuid
    end
  end

end
