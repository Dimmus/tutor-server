require 'rails_helper'

RSpec.describe Api::V1::CoursesController, :type => :controller, :api => true, :version => :v1  do

  let!(:application)     { FactoryGirl.create :doorkeeper_application }
  let!(:user_1)          { FactoryGirl.create :user }
  let!(:user_1_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_1.id }

  let!(:user_2)          { FactoryGirl.create :user }
  let!(:user_2_token)    { FactoryGirl.create :doorkeeper_access_token,
                                              application: application,
                                              resource_owner_id: user_2.id }

  let!(:userless_token)  { FactoryGirl.create :doorkeeper_access_token,
                                              application: application }

  let!(:course) { Entity::CreateCourse.call.outputs.course }

  describe "#readings" do
    it "should work on the happy path" do
      root_book_part = FactoryGirl.create(:content_book_part, :standard_contents_1)
      CourseContent::Api::AddBookToCourse.call(course: course, book: root_book_part.book)

      api_get :readings, user_1_token, parameters: {id: course.id}

      expect(response).to have_http_status(:success)
      expect(response.body_as_hash).to eq([{
        id: 2,
        title: 'unit 1',
        type: 'part',
        children: [
          {
            id: 3,
            title: 'chapter 1',
            type: 'part',
            children: [
              {
                id: 1,
                title: 'first page',
                type: 'page'
              },
              {
                id: 2,
                title: 'second page',
                type: 'page'
              }
            ]
          },
          {
            id: 4,
            title: 'chapter 2',
            type: 'part',
            children: [
              {
                id: 3,
                title: 'third page',
                type: 'page'
              }
            ]
          }
        ]
      }])

    end
  end

  describe "#plans" do
    it "should work on the happy path" do
      task_plan = FactoryGirl.create(:task_plan, owner: course)

      api_get :plans, user_1_token, parameters: {id: course.id}

      expect(response).to have_http_status(:success)
      expect(response.body).to(
        eq({ total_count: 1,
             items: [Api::V1::TaskPlanRepresenter.new(task_plan)] }.to_json)
      )

    end
  end

  describe "tasks" do
    it "temporarily mirrors /api/user/tasks" do
      api_get :tasks, user_1_token, parameters: {id: course.id}
      expect(response.code).to eq('200')
      expect(response.body).to eq({
        total_count: 0,
        items: []
      }.to_json)
    end

    it "returns tasks for a role holder in a certain course" do
      skip "skipped until implement the real /api/courses/123/tasks endpoint with role awareness"
    end
  end

  describe "index" do
    let(:teaching) { Domain::CreateCourse.call.outputs.profile }
    let(:taking) { Domain::CreateCourse.call.outputs.profile }
    let(:roles) { Role::GetUserRoles.call(user_1).outputs.roles }

    before do
      Domain::AddUserAsCourseTeacher.call(course: teaching.course,
                                          user: user_1)
      Domain::AddUserAsCourseStudent.call(course: taking.course,
                                          user: user_1)
    end

    it "returns the roles of the courses the user is a part of" do
      teacher = roles.select(&:teacher?).first
      student = roles.select(&:student?).first

      api_get :index, user_1_token

      expect(response.code).to eq('200')
      expect(response.body).to include({
        name: teaching.name, roles: [{
          type: 'teacher',
          url: "/api/v1/teachers/#{teacher.id}/dashboard"
        }] }.to_json)
      expect(response.body).to include({
        name: taking.name, roles: [{
          type: 'student',
          url: "/api/v1/students/#{student.id}/dashboard"
        }] }.to_json)
    end

    it "returns tasks for a role holder in a certain course" do
      skip "skipped until implement the real /api/courses/123/tasks endpoint with role awareness"
    end
  end

end
