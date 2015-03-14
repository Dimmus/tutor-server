class OpenStax::Exercises::V1::Exercise

  BASE_URL = 'http://exercises.openstax.org/exercises'

  # This Regex finds the LO's within the exercise tags
  LO_REGEX = /[\w-]+-lo[\d]+/

  attr_reader :content

  def initialize(content)
    @content = content || '{}'
  end

  def content_hash
    @content_hash ||= JSON.parse(content)
  end

  def uid
    @uid ||= content_hash['uid']
  end
  alias_method :id, :uid

  def url
    @url ||= "#{BASE_URL}/#{uid}"
  end

  def title
    @title ||= content_hash['title']
  end

  def tags
    @tags ||= content_hash['tags']
  end

  def los
    @los ||= tags.collect{|t| LO_REGEX.match(t).try(:[], 0)}.compact.uniq
  end

  def questions
    @questions ||= content_hash['questions']
                     .collect{ |q| q.merge('id' => q['id'].to_s)}
  end

  def answers
    @answers ||= questions.collect do |q|
      q['answers'].collect{ |a| a.merge('id' => a['id'].to_s) }
    end
  end

  def correct_answer_ids
    @correct_answer_ids ||= answers.collect do |ans|
      ans.select do |a|
        correctness = Float(a['correctness']) rescue 0
        correctness >= 1
      end.first['id']
    end
  end

  def feedback_map
    return @feedback_map unless @feedback_map.nil?

    @feedback_map = {}
    answers.each do |ans|
      ans.each { |a| @feedback_map[a['id']] = a['feedback_html'] }
    end
    @feedback_map
  end

  def feedback_html(answer_id)
    feedback_map[answer_id] || ''
  end

  def answers_without_correctness
    answers.collect do |ans|
      ans.collect { |a| a.except('correctness', 'feedback_html') }
    end
  end

  def questions_without_correctness
    i = -1
    content_hash['questions'].collect do |q|
      i = i + 1
      q.merge('answers' => answers_without_correctness[i])
    end
  end

  def content_without_correctness
    content_hash.merge('questions' => questions_without_correctness)
  end

end
