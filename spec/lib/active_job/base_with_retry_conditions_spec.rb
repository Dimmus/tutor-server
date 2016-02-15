require 'rails_helper'

module ActiveJob
  RSpec.describe BaseWithRetryConditions, type: :lib do
    let!(:job)         { described_class.new }
    let!(:delayed_job) { Delayed::Job.create!(handler: '') }

    before { job.provider_job_id = delayed_job.id }

    context 'exceptions with no argument' do
      [
        ActiveRecord::RecordNotFound,
        Addressable::URI::InvalidURIError,
        ArgumentError,
        Content::MapInvalidError,
        JSON::ParserError,
        NoMethodError,
        NotYetImplemented
      ].each do |exception|
        context exception.name do
          it 'fails the job instantly' do
            expect(job).to receive(:perform) { raise exception }

            expect(delayed_job.failed?).to eq false
            expect{ job.perform_now }.to raise_error exception
            expect(delayed_job.reload.failed?).to eq true
          end

          it 'does not blow up if no job was found' do
            job.provider_job_id = nil
            expect(job).to receive(:perform) { raise exception }

            expect(delayed_job.failed?).to eq false
            expect{ job.perform_now }.to raise_error exception
            expect(delayed_job.reload.failed?).to eq false
          end
        end
      end
    end

    context 'exceptions with arguments' do
      context 'ActiveJob::DeserializationError' do
        let!(:exception) { ActiveJob::DeserializationError }

        it 'fails the job instantly' do
          expect(job).to receive(:perform) { raise exception, OpenStruct.new }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq true
        end

        it 'does not blow up if no job was found' do
          job.provider_job_id = nil
          expect(job).to receive(:perform) { raise exception, OpenStruct.new }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq false
        end
      end

      context 'ActiveRecord::RecordInvalid' do
        let!(:exception) { ActiveRecord::RecordInvalid }

        it 'fails the job instantly' do
          expect(job).to receive(:perform) { raise exception, Entity::Role.new }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq true
        end

        it 'does not blow up if no job was found' do
          job.provider_job_id = nil
          expect(job).to receive(:perform) { raise exception, Entity::Role.new }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq false
        end
      end

      context 'OAuth2::Error' do
        let!(:exception) { OAuth2::Error }

        it 'fails the job instantly if it is a 400 status' do
          expect(job).to receive(:perform) { raise exception, OpenStruct.new(status: 404) }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq true
        end

        it 'does not fail the job instantly if it is a 500 status' do
          expect(job).to receive(:perform) { raise exception, OpenStruct.new(status: 504) }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq false
        end

        it 'does not fail the job instantly if it is an unknown status' do
          expect(job).to receive(:perform) { raise exception, OpenStruct.new(status: 0) }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq false
        end

        it 'does not blow up if no job was found' do
          job.provider_job_id = nil
          expect(job).to receive(:perform) { raise exception, OpenStruct.new(status: 404) }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq false
        end
      end

      context 'OpenStax::HTTPError' do
        let!(:exception) { OpenStax::HTTPError }

        it 'fails the job instantly if it is a 400 status' do
          expect(job).to receive(:perform) { raise exception, '404 Not Found' }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq true
        end

        it 'does not fail the job instantly if it is a 500 status' do
          expect(job).to receive(:perform) { raise exception, '504 Gateway Timeout' }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq false
        end

        it 'does not fail the job instantly if it is an unknown status' do
          expect(job).to receive(:perform) { raise exception, '' }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq false
        end

        it 'does not blow up if no job was found' do
          job.provider_job_id = nil
          expect(job).to receive(:perform) { raise exception, '404 Not Found' }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq false
        end
      end

      context 'OpenURI::HTTPError' do
        let!(:exception) { OpenURI::HTTPError }

        it 'fails the job instantly if it is a 400 status' do
          expect(job).to receive(:perform) { raise exception.new('404 Not Found', OpenStruct.new) }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq true
        end

        it 'does not fail the job instantly if it is a 500 status' do
          expect(job).to receive(:perform) {
            raise exception.new('504 Gateway Timeout', OpenStruct.new)
          }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq false
        end

        it 'does not fail the job instantly if it is an unknown status' do
          expect(job).to receive(:perform) { raise exception.new('', OpenStruct.new) }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq false
        end

        it 'does not blow up if no job was found' do
          job.provider_job_id = nil
          expect(job).to receive(:perform) { raise exception.new('404 Not Found', OpenStruct.new) }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error exception
          expect(delayed_job.reload.failed?).to eq false
        end
      end

      context 'RuntimeError' do
        it 'does not fail the job instantly' do
          expect(job).to receive(:perform) { raise 'Some Error' }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error RuntimeError
          expect(delayed_job.reload.failed?).to eq false
        end

        it 'does not blow up if no job was found' do
          job.provider_job_id = nil
          expect(job).to receive(:perform) { raise 'Some Error' }

          expect(delayed_job.failed?).to eq false
          expect{ job.perform_now }.to raise_error RuntimeError
          expect(delayed_job.reload.failed?).to eq false
        end
      end
    end
  end
end