require 'rails_helper'

RSpec.describe Api::V1::EnrollmentChangesController, type: :controller, api: true, version: :v1 do
  let!(:user)                { FactoryGirl.create :user }

  let!(:user_2)              { FactoryGirl.create :user }

  let!(:course)              do
    FactoryGirl.create(:entity_course).tap do |course|
      course.profile.update_attribute(:is_concept_coach, true)
    end
  end
  let!(:period)              { ::CreatePeriod[course: course] }
  let!(:period_2)            { ::CreatePeriod[course: course] }

  let!(:book)                { FactoryGirl.create :content_book }

  let!(:ecosystem)           do
    model = book.ecosystem
    strategy = ::Content::Strategies::Direct::Ecosystem.new(model)
    ::Content::Ecosystem.new(strategy: strategy)
  end

  let!(:course_ecosystem)    { AddEcosystemToCourse[course: course, ecosystem: ecosystem] }

  context '#create' do
    context 'anonymous user' do
      it 'raises a SecurityTransgression' do
        expect{ api_post :create, nil, raw_post_data: {
          enrollment_code: period.enrollment_code, book_cnx_id: book.cnx_id
        }.to_json }.to raise_error(SecurityTransgression)
      end
    end

    context 'signed in user' do
      before(:each) { controller.sign_in user }

      context 'book_cnx_id given' do
        it 'creates the EnrollmentChange if there are no errors for a new student' do
          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: period.enrollment_code, book_cnx_id: book.cnx_id
          }.to_json }.to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
          expect(response).to have_http_status(:created)
        end

        it 'creates the EnrollmentChange if there are no errors for an existing student' do
          AddUserAsPeriodStudent[user: user, period: period_2]

          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: period.enrollment_code, book_cnx_id: book.cnx_id
          }.to_json }.to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
          expect(response).to have_http_status(:created)
        end

        it 'returns an error if the enrollment code is invalid' do
          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: SecureRandom.hex, book_cnx_id: book.cnx_id
          }.to_json }.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'invalid_enrollment_code'
        end

        it 'returns an error if the enrollment code\'s course is not a CC course' do
          course.profile.update_attribute(:is_concept_coach, false)

          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: period.enrollment_code, book_cnx_id: book.cnx_id
          }.to_json }.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'invalid_enrollment_code'
        end

        it 'returns an error if the book_cnx_id does not match the course\'s book' do
          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: period.enrollment_code, book_cnx_id: SecureRandom.hex
          }.to_json }.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to(
            eq 'enrollment_code_does_not_match_book'
          )
        end

        it 'returns an error if the user is already enrolled in the given period' do
          AddUserAsPeriodStudent[user: user, period: period]

          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: period.enrollment_code, book_cnx_id: book.cnx_id
          }.to_json }.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'already_enrolled'
        end

        it 'returns an error if the user has multiple student roles in the course' do
          AddUserAsCourseTeacher[user: user, course: course]
          AddUserAsPeriodStudent[user: user, period: period]
          AddUserAsPeriodStudent[user: user, period: period_2]

          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: period.enrollment_code, book_cnx_id: book.cnx_id
          }.to_json }.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'multiple_roles'
        end

        it 'returns an error if the user has been dropped from the course' do
          AddUserAsPeriodStudent[user: user, period: period_2].student.inactivate.save!

          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: period.enrollment_code, book_cnx_id: book.cnx_id
          }.to_json }.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'dropped_student'
        end
      end

      context 'book_cnx_id not given' do
        it 'creates the EnrollmentChange if there are no errors for a new student' do
          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: period.enrollment_code
          }.to_json }.to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
          expect(response).to have_http_status(:created)
        end

        it 'creates the EnrollmentChange if there are no errors for an existing student' do
          AddUserAsPeriodStudent[user: user, period: period_2]

          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: period.enrollment_code
          }.to_json }.to change{ CourseMembership::Models::EnrollmentChange.count }.by(1)
          expect(response).to have_http_status(:created)
        end

        it 'returns an error if the enrollment code is invalid' do
          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: SecureRandom.hex
          }.to_json }.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'invalid_enrollment_code'
        end

        it 'returns an error if the enrollment code\'s course is not a CC course' do
          course.profile.update_attribute(:is_concept_coach, false)

          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: period.enrollment_code
          }.to_json }.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'invalid_enrollment_code'
        end

        it 'returns an error if the user is already enrolled in the given period' do
          AddUserAsPeriodStudent[user: user, period: period]

          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: period.enrollment_code
          }.to_json }.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'already_enrolled'
        end

        it 'returns an error if the user has multiple roles in the course' do
          AddUserAsCourseTeacher[user: user, course: course]
          AddUserAsPeriodStudent[user: user, period: period]
          AddUserAsPeriodStudent[user: user, period: period_2]

          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: period.enrollment_code
          }.to_json }.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'multiple_roles'
        end

        it 'returns an error if the user has been dropped from the course' do
          AddUserAsPeriodStudent[user: user, period: period_2].student.inactivate.save!

          expect{ api_post :create, nil, raw_post_data: {
            enrollment_code: period.enrollment_code
          }.to_json }.not_to change{ CourseMembership::Models::EnrollmentChange.count }
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.body_as_hash[:errors].first[:code]).to eq 'dropped_student'
        end
      end
    end
  end

  context '#approve' do
    let!(:enrollment_change) { CourseMembership::CreateEnrollmentChange[
      user: user, period: period, requires_enrollee_approval: true
    ] }

    context 'anonymous user' do
      it 'returns 403 forbidden' do
        expect{ api_put :approve, nil, parameters: { id: enrollment_change.id } }
          .to raise_error(SecurityTransgression)
      end
    end

    context 'unauthorized user' do
      before(:each) { controller.sign_in user_2 }

      it 'returns 403 forbidden' do
        expect{ api_put :approve, nil, parameters: { id: enrollment_change.id } }
          .to raise_error(SecurityTransgression)
      end
    end

    context 'authorized user' do
      before(:each) { controller.sign_in user }

      it 'approves a pending EnrollmentChange request' do
        expect{ api_put :approve, nil, parameters: { id: enrollment_change.id } }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(response).to have_http_status(:ok)
      end

      it 'processes an approved EnrollmentChange request' do
        enrollment_change.to_model.approve_by(user).save!

        expect{ api_put :approve, nil, parameters: { id: enrollment_change.id } }
          .to change{ CourseMembership::Models::Enrollment.count }.by(1)
        expect(response).to have_http_status(:ok)
      end

      it 'returns an error if the EnrollmentChange request has already been rejected' do
        enrollment_change.to_model.status = :rejected
        enrollment_change.to_model.save!

        expect{ api_put :approve, nil, parameters: { id: enrollment_change.id } }
          .not_to change{ CourseMembership::Models::Enrollment.count }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'already_rejected'
      end

      it 'returns an error if the EnrollmentChange request has already been processed' do
        enrollment_change.to_model.status = :processed
        enrollment_change.to_model.save!

        expect{ api_put :approve, nil, parameters: { id: enrollment_change.id } }
          .not_to change{ CourseMembership::Models::Enrollment.count }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body_as_hash[:errors].first[:code]).to eq 'already_processed'
      end
    end
  end
end