require 'rails_helper'

RSpec.describe CustomerService::StudentsController do
  let(:customer_service) { FactoryGirl.create(:user, :customer_service) }

  before                 { controller.sign_in(customer_service) }

  describe 'GET #index' do
    let(:course)     { FactoryGirl.create :course_profile_course, name: 'Physics' }
    let(:course_2)   { FactoryGirl.create :course_profile_course }

    let(:periods)    do
      [
        FactoryGirl.create(:course_membership_period, course: course),
        FactoryGirl.create(:course_membership_period, course: course)
      ]
    end
    let(:periods_2)  { [FactoryGirl.create(:course_membership_period, course: course_2)] }

    let(:user_1)     { FactoryGirl.create(:user, first_name: 'Benjamin', last_name: 'Franklin') }
    let(:user_2)     { FactoryGirl.create(:user, first_name: 'Nikola', last_name: 'Tesla') }
    let(:user_3)     { FactoryGirl.create(:user, first_name: 'Freja', last_name: 'Asgard') }
    let(:user_4)     { FactoryGirl.create(:user, first_name: 'Oliver', last_name: 'Wilde') }

    let!(:student_1) {
      AddUserAsPeriodStudent.call(user: user_1, period: periods[0]).outputs.student
    }
    let!(:student_2) {
      AddUserAsPeriodStudent.call(user: user_2, period: periods[0]).outputs.student
    }
    let!(:student_3) {
      AddUserAsPeriodStudent.call(user: user_3, period: periods[1]).outputs.student
    }
    let!(:student_4) {
      AddUserAsPeriodStudent.call(user: user_4, period: periods_2[0]).outputs.student
    }

    it 'returns all the students in a course' do
      get :index, course_id: course.id
      expect(assigns[:course].name).to eq 'Physics'
      expect(assigns[:students]).to eq([
        {
          'id' => student_1.id,
          'username' => user_1.username,
          'first_name' => user_1.first_name,
          'last_name' => user_1.last_name,
          'name' => user_1.name,
          'entity_role_id' => student_1.entity_role_id,
          'course_membership_period_id' => student_1.period.id,
          'student_identifier' => student_1.student_identifier,
          'deleted?' => false
        },
        {
          'id' => student_3.id,
          'username' => user_3.username,
          'first_name' => user_3.first_name,
          'last_name' => user_3.last_name,
          'name' => user_3.name,
          'entity_role_id' => student_3.entity_role_id,
          'course_membership_period_id' => student_3.period.id,
          'student_identifier' => student_3.student_identifier,
          'deleted?' => false
        },
        {
          'id' => student_2.id,
          'username' => user_2.username,
          'first_name' => user_2.first_name,
          'last_name' => user_2.last_name,
          'name' => user_2.name,
          'entity_role_id' => student_2.entity_role_id,
          'course_membership_period_id' => student_2.period.id,
          'student_identifier' => student_2.student_identifier,
          'deleted?' => false
        }
      ])
    end

    it 'works even if a student has a nil username' do
      user_2.account.update_attribute :username, nil

      get :index, course_id: course.id
      expect(assigns[:course].name).to eq 'Physics'
      expect(assigns[:students]).to eq([
        {
          'id' => student_1.id,
          'username' => user_1.username,
          'first_name' => user_1.first_name,
          'last_name' => user_1.last_name,
          'name' => user_1.name,
          'entity_role_id' => student_1.entity_role_id,
          'course_membership_period_id' => student_1.period.id,
          'student_identifier' => student_1.student_identifier,
          'deleted?' => false
        },
        {
          'id' => student_3.id,
          'username' => user_3.username,
          'first_name' => user_3.first_name,
          'last_name' => user_3.last_name,
          'name' => user_3.name,
          'entity_role_id' => student_3.entity_role_id,
          'course_membership_period_id' => student_3.period.id,
          'student_identifier' => student_3.student_identifier,
          'deleted?' => false
        },
        {
          'id' => student_2.id,
          'username' => nil,
          'first_name' => user_2.first_name,
          'last_name' => user_2.last_name,
          'name' => user_2.name,
          'entity_role_id' => student_2.entity_role_id,
          'course_membership_period_id' => student_2.period.id,
          'student_identifier' => student_2.student_identifier,
          'deleted?' => false
        }
      ])
    end
  end
end
