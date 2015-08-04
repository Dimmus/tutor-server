require "rails_helper"

describe Api::V1::UsersController, :type => :controller, :api => true, :version => :v1 do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create :user_profile }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_1.id }

  let!(:admin)           { FactoryGirl.create :user_profile, :administrator }
  let!(:admin_token)     { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: admin.id }

  let!(:userless_token)  { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: nil }

  describe "#show" do
    context "caller has an authorization token" do
      it "should return an ok (200) code" do
        api_get :show, user_1_token
        expect(response.code).to eq('200')
        payload = JSON.parse(response.body)
        expect(payload).to eq(
          "name" => user_1.name,
          'is_admin' => false,
          'profile_url' => Addressable::URI.join(
            OpenStax::Accounts.configuration.openstax_accounts_url,
            '/profile').to_s
        )
      end

      it 'returns is_admin flag correctly' do
        api_get :show, admin_token
        expect(response.code).to eq('200')
        payload = JSON.parse(response.body)
        expect(payload).to eq(
          "name" => admin.name,
          'is_admin' => true,
          'profile_url' => Addressable::URI.join(
            OpenStax::Accounts.configuration.openstax_accounts_url,
            '/profile').to_s
        )
      end
    end
    context "caller does not have an authorization token" do
      it "should return a forbidden (403) code" do
        api_get :show, nil
        expect(response.code).to eq('403')
      end
    end
    context "caller has an application/client credentials authorization token" do
      it "should return a forbidden (403) code" do
        api_get :show, userless_token
        expect(response.code).to eq('403')
      end
    end
  end

end
