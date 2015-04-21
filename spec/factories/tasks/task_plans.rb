FactoryGirl.define do
  factory :tasks_task_plan, class: '::Tasks::Models::TaskPlan' do
    transient do
      duration 1.week
      num_tasking_plans 0
      assistant_code_class_name "DummyAssistant"
    end

    association :owner, factory: :entity_course
    settings { {}.to_json }
    opens_at { Time.now }
    due_at { opens_at + duration }
    type "reading"

    after(:build) do |task_plan, evaluator|
      code_class_name_hash = {
        code_class_name: evaluator.assistant_code_class_name
      }
      task_plan.assistant ||= Tasks::Models::Assistant.find_by(code_class_name_hash) || \
                              FactoryGirl.build(:tasks_assistant, code_class_name_hash)

      evaluator.num_tasking_plans.times do
        task_plan.tasking_plans << FactoryGirl.build(:tasks_tasking_plan,
                                                     task_plan: task_plan)
      end
    end
  end
end