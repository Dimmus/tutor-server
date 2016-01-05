class CourseContent::AddEcosystemToCourse

  lev_routine express_output: :ecosystem_map

  protected

  def exec(course:, ecosystem:, remove_other_ecosystems: false,
           ecosystem_strategy_class: ::Content::Strategies::Direct::Ecosystem,
           map_strategy_class: ::Content::Strategies::Generated::Map)
    course = Marshal.load(course) if course.is_a?(String)
    ecosystem = Marshal.load(ecosystem) if ecosystem.is_a?(String)
    fatal_error(code: :ecosystem_already_set,
                message: 'The given ecosystem is already active for the given course') \
      if course.reload.ecosystems.first.try(:id) == ecosystem.id

    course.ecosystems.destroy_all if remove_other_ecosystems
    course_ecosystem = CourseContent::Models::CourseEcosystem.create(
      course: course, content_ecosystem_id: ecosystem.id
    )
    course.course_ecosystems << course_ecosystem
    transfer_errors_from(course_ecosystem, {type: :verbatim}, true)

    # Create a mapping from the old course ecosystems to the new one and validate it
    from_ecosystems = course.course_ecosystems.collect do |course_ecosystem|
      strategy = ecosystem_strategy_class.new(course_ecosystem.ecosystem)
      ::Content::Ecosystem.new(strategy: strategy)
    end

    outputs[:ecosystem_map] = ::Content::Map.create!(from_ecosystems: from_ecosystems,
                                                     to_ecosystem: ecosystem,
                                                     strategy_class: map_strategy_class)
  end

end
