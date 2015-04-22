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
    @los ||= tags.collect{ |tag| LO_REGEX.match(tag).try(:[], 0) }.compact.uniq
  end

  def questions
    @questions ||= content_hash['questions'].collect{ |qq| qq.merge('id' => qq['id'].to_s)}
  end

  def question_formats
    @question_formats ||= questions.collect{ |qq| qq['formats'] }
  end

  def question_answers
    @question_answers ||= questions.collect do |qq|
      qq['answers'].collect{ |aa| aa.merge('id' => aa['id'].to_s) }
    end
  end

  def question_answer_ids
    @question_answer_ids ||= question_answers.collect do |qa|
      qa.collect{ |ans| ans['id'].to_s }
    end
  end

  def correct_question_answers
    @correct_question_answers ||= question_answers.collect do |qa|
      qa.select do |ans|
        (Float(ans['correctness']) rescue 0) >= 1
      end
    end
  end

  def correct_question_answer_ids
    @correct_question_answer_ids ||= correct_question_answers.collect do |cqa|
      cqa.collect{ |ans| ans['id'].to_s }
    end
  end

  def feedback_map
    return @feedback_map unless @feedback_map.nil?

    @feedback_map = {}
    question_answers.each do |qa|
      qa.each { |ans| @feedback_map[ans['id']] = ans['feedback_html'] }
    end
    @feedback_map
  end

  def question_answers_without_correctness
    @question_answers_without_correctness ||= question_answers.collect do |qa|
      qa.collect { |ans| ans.except('correctness', 'feedback_html') }
    end
  end

  def questions_without_correctness
    @questions_without_correctness ||= content_hash['questions'].each_with_index
                                                                .collect do |qq, ii|
      qq.merge('answers' => question_answers_without_correctness[ii])
    end
  end

  def content_without_correctness
    @content_without_correctness ||= content_hash.merge(
      'questions' => questions_without_correctness
    )
  end

end
