require 'rails_helper'

RSpec.describe Catalog::Models::Offering, type: :model do
  subject{ FactoryGirl.create :catalog_offering }

  it { is_expected.to validate_presence_of(:salesforce_book_name) }
  it { is_expected.to validate_presence_of(:webview_url) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:description) }
  it { is_expected.to validate_presence_of(:ecosystem) }

  it { is_expected.to validate_uniqueness_of(:salesforce_book_name) }
end
