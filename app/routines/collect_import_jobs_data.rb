class CollectImportJobsData
  lev_routine express_output: :import_jobs_data

  protected

  def exec(state:)
    data = []
    jobbas = Jobba.where(state: state).to_a
    jobbas_with_course_ecosystem = jobbas.select{ |j| j.try(:data).try(:[], "course_ecosystem") }
    course_ids = jobbas_with_course_ecosystem.map{|job| job.data["course_id"]}


    course_names_by_id = course_ids.blank? ?
      {} : CourseProfile::Models::Course.where(id: course_ids).pluck(:id, :name).to_h
    jobbas_with_course_ecosystem.each do |job|
      course_id = job.data["course_id"]
      course_name = course_names_by_id[course_id]
      data << { id: job.id, state_name: job.state.name,
                course_ecosystem: job.data["course_ecosystem"], course_name: course_name }
    end

    outputs[:import_jobs_data] = data
  end
end
