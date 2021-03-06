class ImportSalesforceCourses

  # This is intentionally not a routine so that a blow up when importing one
  # course doesn't roll back other successfully imported courses.

  LOGGER_PREFIX = self.name

  def self.call(include_real_salesforce_data: nil)
    new.call(include_real_salesforce_data: include_real_salesforce_data)
  end

  def call(include_real_salesforce_data: nil)
    @include_real_salesforce_data_preference = include_real_salesforce_data

    log { "Starting#{' (test data only)' if !include_real_salesforce_data?}." }

    num_failures = 0
    num_successes = 0

    candidate_sf_records.each do |candidate|
      ImportSalesforceCourse[candidate: candidate, log_prefix: LOGGER_PREFIX]

      num_failures += 1  if candidate.error.present?
      num_successes += 1 if candidate.error.blank?

      candidate.save_if_changed
    end

    log {
      "Finished. #{num_failures + num_successes} candidate record(s); " +
      "#{num_successes} success(es) and #{num_failures} failure(s)."
    }

    OpenStruct.new(num_failures: num_failures, num_successes: num_successes)
  end

  def include_real_salesforce_data?
    # The "include real" parameter to this routine is used if set; if not set,
    # fall back to the GlobalSettings value.  If that not set, don't import real.
    # In any event, only ever include real data if the secret setting say it is
    # allowed (JP doesn't trust admins, and wants this failsafe secret to let us
    # only use real SF data in the real real production site).

    (@include_real_salesforce_data_preference.present? ?
      @include_real_salesforce_data_preference :
      Settings::Salesforce.import_real_salesforce_courses) &&
    Rails.application.secrets['salesforce']['allow_use_of_real_data']
  end

  def candidate_sf_records
    [candidate_class_size_records, candidate_os_ancillary_records].flatten
  end

  def candidate_class_size_records
    search_criteria = {
      concept_coach_approved: true,
      course_id: nil,
      term_year: candidate_term_years_array
    }

    search_criteria[:school] = 'Denver University' if !include_real_salesforce_data?

    Salesforce::Remote::ClassSize.where(search_criteria).to_a
  end

  def candidate_os_ancillary_records
    search_criteria = {
      status: Salesforce::Remote::OsAncillary::STATUS_APPROVED,
      course_id: nil,
      term_year: candidate_term_years_array
    }

    search_criteria[:school] = 'Denver University' if !include_real_salesforce_data?

    Salesforce::Remote::OsAncillary.where(search_criteria).to_a
  end

  def candidate_term_years_array
    array = (Settings::Salesforce.term_years_to_import || '').split(',').map(&:strip)

    # An empty array means for us to not import anything (we are going to explicitly
    # opt in to various TermYears).  Salesforce explodes for an empty array, and an
    # array with a blank entry could catch SF objects that don't have a TermYear
    # populated (not what we want); so use a bogus string to exclude any matches
    array.empty? ? ['exclude all'] : array
  end

  def log(&block)
    Rails.logger.info { "[#{LOGGER_PREFIX}] #{block.call}" }
  end

end
