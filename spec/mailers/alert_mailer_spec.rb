require 'spec_helper'

describe Rearview::AlertMailer do

  let(:result) { {:message => "failure oops bad"} }
  let(:job) { create(:job) }
  let(:mail) { Rearview::AlertMailer.alert_email("foo@foo.com",job,result) }

  context 'subject' do
    it 'contains the job name' do
      expect(mail.subject).to match(/#{job.name}/)
    end
    it 'contains subject tag' do
      expect(mail.subject).to match(/\[Rearview ALERT\]/)
    end
  end

  context 'body' do
    it 'has the alert message' do
      expect(mail.body.encoded).to match(/ALERT: #{result[:message]}/)
    end
    it 'has the monitor name' do
      expect(mail.body.encoded).to match(/Monitor: #{job.name}/)
    end
    it 'has the monitor description' do
      expect(mail.body.encoded).to match(/Description: #{job.description}/)
    end
    it 'has the alerted on date' do
      expect(mail.body.encoded).to match(/Alerted On: .*/)
    end
    it 'has a direct link' do
      expect(mail.body.encoded).to match(%r{Direct Link: http://localhost:3000/rearview/#dash/#{job.app_id}/expand/#{job.id}})
    end
  end

end

