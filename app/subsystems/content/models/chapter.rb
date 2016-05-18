class Content::Models::Chapter < Tutor::SubSystems::BaseModel

  wrapped_by ::Content::Strategies::Direct::Chapter

  serialize :book_location, Array

  belongs_to :all_exercises_pool, class_name: 'Content::Models::Pool', dependent: :destroy

  sortable_belongs_to :book, on: :number, inverse_of: :chapters
  has_one :ecosystem, through: :book

  sortable_has_many :pages, on: :number, dependent: :destroy, autosave: true, inverse_of: :chapter
  has_many :exercises, through: :pages

  validates :book, presence: true
  validates :title, presence: true
  validates :book_location, presence: true

end
