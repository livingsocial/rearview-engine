require 'spec_helper'

describe Rearview::ResultsHandler do
  let(:job) { create(:job) }
  context 'run' do
    before do
      @job_data = mock
      Rearview::JobData.stubs(:find_or_create_by_job_id).returns(@job_data)
    end
    it 'returns itself' do
      Rearview::JobData.stubs(:find_or_create_by_job_id).returns(stub_everything)
      results_handler = Rearview::ResultsHandler.new(job,{})
      expect(results_handler.run).to be_an_instance_of(Rearview::ResultsHandler)
    end
  end

end


