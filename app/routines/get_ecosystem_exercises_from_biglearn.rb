# Returns Content::Exercises corresponding to a Biglearn query
class GetEcosystemExercisesFromBiglearn
  lev_routine express_output: :ecosystem_exercises

  MAX_ATTEMPTS = 3

  protected

  def exec(ecosystem:, role:, pools:, count:, difficulty: 0.5, allow_repetitions: true)
    biglearn_pools = pools.collect{ |pl| OpenStax::Biglearn::V1::Pool.new(uuid: pl.uuid) }

    course = role.student.try(:course)
    course_profile = course.try(:profile)

    admin_excluded_pool_uuid = Settings::Exercises.excluded_pool_uuid
    admin_excluded_pool = OpenStax::Biglearn::V1::Pool.new(uuid: admin_excluded_pool_uuid) \
      unless admin_excluded_pool_uuid.nil?

    course_excluded_pool_uuid = course_profile.try(:biglearn_excluded_pool_uuid)
    course_excluded_pool = OpenStax::Biglearn::V1::Pool.new(uuid: course_excluded_pool_uuid) \
      unless course_excluded_pool_uuid.nil?

    pool_exclusions = [{ pool: admin_excluded_pool, ignore_versions: false },
                       { pool: course_excluded_pool, ignore_versions: true }]

    attempts = 0
    begin
      urls = OpenStax::Biglearn::V1.get_projection_exercises(
        role:              role,
        pools:             biglearn_pools,
        pool_exclusions:   pool_exclusions,
        count:             count,
        difficulty:        difficulty,
        allow_repetitions: allow_repetitions
      )
      numbers = urls.map{ |url| url.chomp('/').split('/').last.split('@').first }
    rescue OAuth2::Error => exception
      # Our communication issues turned out to be nginx configuration issues (keepalive_timeout)
      # Still, it's a nice safeguard to have, in case AWS has some trouble,
      # since this Biglearn request may be blocking a student's work
      if (attempts += 1) < MAX_ATTEMPTS
        retry
      else
        admin_excluded_uids = Settings::Exercises.excluded_uids
        course_excluded_numbers = course.excluded_exercises.pluck(:exercise_number)

        pool_exercises = pools.flat_map{ |pl| pl.exercises }
        candidate_exercises = pool_exercises.reject do |ex|
          ex.number.in?(course_excluded_numbers) || ex.uid.in?(admin_excluded_uids)
        end
        numbers = candidate_exercises.map(&:number).uniq.sample(count)

        ExceptionNotifier.notify_exception(
          exception,
          data: {
            error_id: "%06d" % SecureRandom.random_number(10**6),
            message: 'Maximum number of retries exceeded while trying to communicate with Biglearn. Using random local problems instead.',
            attempts: attempts,
            cause: exception
          },
          sections: %w(data request session environment backtrace)
        )
      end
    end

    exercises = ecosystem.exercises_by_numbers(numbers)
    fatal_error(code: :missing_local_exercises,
                message: "Biglearn returned more exercises than were " +
                         "present locally. [pools: #{biglearn_pools.collect{|pl| pl.uuid}}, " +
                         "role: #{role.id}, requested: #{count}, " +
                         "from biglearn: #{numbers.size}, " +
                         "local found: #{exercises.size}] biglearn question ids: #{numbers}") \
      if exercises.size < numbers.size

    outputs[:ecosystem_exercises] = exercises
  end
end
