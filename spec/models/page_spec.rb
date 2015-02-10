require 'rails_helper'

RSpec.describe Page, type: :model do
  subject { FactoryGirl.create :page }

  it { is_expected.to belong_to(:resource) }
  it { is_expected.to belong_to(:book) }

  it { is_expected.to validate_presence_of(:resource) }

  it { is_expected.to validate_presence_of(:title) }

  it { is_expected.to validate_presence_of(:cnx_id) }

  it { is_expected.to validate_presence_of(:version) }

  it { is_expected.to validate_uniqueness_of(:resource) }

  it { is_expected.to validate_uniqueness_of(:version).scoped_to(:cnx_id) }
end
