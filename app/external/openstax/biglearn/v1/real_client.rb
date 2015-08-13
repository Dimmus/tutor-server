class OpenStax::Biglearn::V1::RealClient

  def initialize(biglearn_configuration)
    @server_url   = biglearn_configuration.server_url
    @client_id    = biglearn_configuration.client_id
    @secret       = biglearn_configuration.secret

    # Make Faraday (used by Oauth2) encode arrays without the [], since Biglearn uses CGI
    connection_opts = { request: { params_encoder: Faraday::FlatParamsEncoder } }

    @oauth_client = OAuth2::Client.new(@client_id, @secret, site: @server_url,
                                                            connection_opts: connection_opts)

    @oauth_token  = @oauth_client.client_credentials.get_token unless @client_id.nil?
  end

  def add_exercises(exercises)
    options = { body: construct_exercises_payload(exercises).to_json }
    response = request(:post, add_exercises_uri, with_content_type_header(options))
    handle_response(response)
  end

  def add_pools(pools)
    pools.each do |pool|
      options = { body: construct_add_pool_payload(pool).to_json }
      response = request(:post, add_pools_uri, with_content_type_header(options))
      handle_response(response)
    end
  end

  def combine_pools(pools)
    options = { body: construct_combine_pool_payload(pools).to_json }
    response = request(:post, add_pools_uri, with_content_type_header(options))
    handle_response(response)
  end

  def get_exchange_read_identifiers_for_roles(roles:)
    users = Role::GetUsersForRoles[roles]
    UserProfile::Models::Profile.where(entity_user: users)
                                .collect{ |p| p.exchange_read_identifier }
  end

  def get_projection_exercises(role:, pools: nil, tag_search: nil,
                               count:, difficulty:, allow_repetitions:)
    query = {
      learner_id: get_exchange_read_identifiers_for_roles(roles: role).first,
      number_of_questions: count,
      allow_repetition: allow_repetitions ? 'true' : 'false'
    }

    unless pools.nil?
      # If we have more than one pool, we must first combine them all into a single pool
      pool = [pools].flatten.size > 1 ? OpenStax::Biglearn::V1.combine_pools(pools) : pools.first

      query = query.merge(pool_id: pool.uuid)
    end

    unless tag_search.nil?
      query = query.merge(tag_query: stringify_tag_search(tag_search))
    end

    response = request(:get, projection_exercises_uri, params: query)

    result = handle_response(response)

    # Return the UIDs
    result["questions"].collect { |q| q["question"] }
  end

  def stringify_tag_search(tag_search)
    case tag_search
    when Hash
      raise IllegalArgument, "too many hash conditions" if tag_search.size != 1
      stringify_tag_search_hash(tag_search.first)
    when String
      '"' + tag_search + '"'
    else
      raise IllegalArgument
    end
  end

  # Return a CLUE value for the specified set of roles and the group of tags.  May return
  # nil if no CLUE is available (e.g. no exercises attached to these tags or confidence too low).
  #
  # Biglearn can actually take multiple sets of tag queries at once and return a CLUE
  # for each; we're not using that capability yet. When we do we'll probably rename the
  # `tags` argument to `tag_sets` or something (or we'll make a first class `TagSearch`
  # citizen inside this module and accept an array of those into this method).
  def get_clue(roles:, tags:)
    raise "Some tags must be specified when getting a CLUE" if tags.blank?
    raise "At least one role must be specified when getting a CLUE" if roles.blank?

    tag_search = stringify_tag_search(:_or => tags)

    query = {
      learners: get_exchange_read_identifiers_for_roles(roles: roles), aggregations: tag_search
    }

    response = request(:get, clue_uri, params: query)

    result = handle_response(response) || {}

    # extract the clue using the knowledge that we have a simplified input (only one
    # tag query, so we can just pull out the appropriate value).  It could be that there's
    # no CLUE to give, in which case we return nil.
    clue           = result['aggregates'].try(:first) || {}
    interpretation = clue['interpretation'] || {}
    confidence     = clue['confidence'] || {}

    {
      value: clue['aggregate'],
      value_interpretation: interpretation['level'],
      confidence_interval: [
        confidence['left'],
        confidence['right']
      ],
      confidence_interval_interpretation: interpretation['confidence'],
      sample_size: confidence['sample_size'],
      sample_size_interpretation: interpretation['threshold']
    }
  end

  private

  def with_content_type_header(options = {})
    options[:headers] ||= {}
    options[:headers].merge!('Content-Type' => 'application/json')
    options
  end

  def request(*args)
    (@oauth_token || @oauth_client).request(*args)
  end

  def add_exercises_uri
    Addressable::URI.join(@server_url, '/facts/questions')
  end

  def add_pools_uri
    Addressable::URI.join(@server_url, '/facts/pools')
  end

  def projection_exercises_uri
    Addressable::URI.join(@server_url, '/projections/questions')
  end

  def clue_uri
    Addressable::URI.join(@server_url, '/knowledge/clue')
  end

  def construct_exercises_payload(exercises)
    { question_tags: [exercises].flatten.collect do |exercise|
      { question_id: exercise.question_id.to_s, version: exercise.version.to_s, tags: exercise.tags }
    end }
  end

  def construct_add_pool_payload(pool)
    { sources: [{ questions: pool.exercises.collect do |exercise|
      { question_id: exercise.question_id.to_s, version: exercise.version.to_s }
    end }] }
  end

  def construct_combine_pools_payload(pools)
    { sources: [{ pools: pools.collect{ |pl| pl.uuid } }] }
  end

  def handle_response(response)
    raise "BiglearnError #{response.status}:\n#{response.body}" if response.status != 200

    JSON.parse(response.body)
  end

  def stringify_tag_search_hash(conditions)
    case conditions[0]
    when :_and
      str = '('
      str += join_tag_searches(conditions[1], 'AND')
      str += ')'
    when :_or
      str = '('
      str += join_tag_searches(conditions[1], 'OR')
      str += ')'
    else
      raise NotYetImplemented, "Unknown boolean symbol #{conditions[0]}"
    end
  end

  def join_tag_searches(tag_searches, op)
    [tag_searches].flatten.collect { |ts| stringify_tag_search(ts) }.join(" #{op} ")
  end

end
