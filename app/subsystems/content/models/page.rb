class Content::Models::Page < Tutor::SubSystems::BaseModel

  wrapped_by ::Content::Strategies::Direct::Page

  acts_as_resource

  belongs_to :reading_dynamic_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :reading_context_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :homework_core_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :homework_dynamic_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :practice_widget_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :concept_coach_pool, class_name: 'Content::Models::Pool', dependent: :destroy
  belongs_to :all_exercises_pool, class_name: 'Content::Models::Pool', dependent: :destroy

  sortable_belongs_to :chapter, on: :number, inverse_of: :pages
  has_one :book, through: :chapter
  has_one :ecosystem, through: :book

  has_many :exercises, dependent: :destroy, inverse_of: :page

  has_many :page_tags, dependent: :destroy, autosave: true, inverse_of: :page
  has_many :tags, through: :page_tags

  validates :book_location, presence: true
  validates :title, presence: true
  validates :uuid, presence: true
  validates :version, presence: true

  before_validation :cache_fragments, :cache_snap_labs

  delegate :is_intro?, :feature_node, to: :parser

  def cnx_id
    "#{uuid}@#{version}"
  end

  def los
    tags.to_a.select(&:lo?)
  end

  def aplos
    tags.to_a.select(&:aplo?)
  end

  def cnxmods
    tags.to_a.select(&:cnxmod?)
  end

  def fragments
    @fragments ||= begin
      cache_fragments
      frags = super
      frags.nil? ? nil : frags.map{ |yaml| YAML.load(yaml) }
    end
  end

  def snap_labs
    @snap_labs ||= begin
      cache_snap_labs
      sls = super
      sls.nil? ? nil : sls.map do |snap_lab|
        sl = snap_lab.symbolize_keys
        sl.merge(fragments: sl[:fragments].map{ |yaml| YAML.load(yaml) })
      end
    end
  end

  def snap_labs_with_page_id
    snap_labs.map{ |snap_lab| snap_lab.merge(page_id: id) }
  end

  protected

  def parser
    @parser ||= OpenStax::Cnx::V1::Page.new(title: title, content: content)
  end

  def fragment_splitter
    @fragment_splitter ||= OpenStax::Cnx::V1::FragmentSplitter.new(
      chapter.book.reading_processing_instructions
    )
  end

  def cache_fragments
    return unless read_attribute(:fragments).nil?

    self.fragments = fragment_splitter.split_into_fragments(parser.converted_root).map(&:to_yaml)
  end

  def cache_snap_labs
    return unless read_attribute(:snap_labs).nil?

    self.snap_labs = parser.snap_lab_nodes.map do |snap_lab_node|
      {
        id: snap_lab_node.attr('id'),
        title: parser.snap_lab_title(snap_lab_node),
        fragments: fragment_splitter.split_into_fragments(snap_lab_node, 'snap-lab').map(&:to_yaml)
      }
    end
  end

end
