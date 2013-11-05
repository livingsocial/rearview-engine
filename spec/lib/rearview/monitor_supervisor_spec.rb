require 'spec_helper'

describe Rearview::MonitorSupervisor do

  let(:job) { create(:job) }

  before do
    Celluloid.shutdown
    Celluloid.boot
    @supervisor = Rearview::MonitorSupervisor.run!
  end

  context "add_tasks" do
    it "creates a new Rearview::MonitorTask actor" do
      expect{ @supervisor.add_tasks([job]) }.not_to raise_error
      expect(Celluloid::Actor[Rearview::MonitorSupervisor.task_sym(job)]).to be_an_instance_of(Rearview::MonitorTask)
    end
    it "handles input gracefully" do
      expect{ @supervisor.add_tasks(nil) }.not_to raise_error
      expect{ @supervisor.add_tasks([]) }.not_to raise_error
    end
  end

  context "remove_tasks" do
    it "removes the Rearview::MonitorTask actor" do
      @supervisor.add_tasks([job])
      task_sym = Rearview::MonitorSupervisor.task_sym(job)
      expect { @supervisor.remove_tasks([job]) }.not_to raise_error
      expect { Celluloid::Actor[task_sym].nil? }.to raise_error(Celluloid::DeadActorError)
    end
    it "handles input gracefully" do
      expect { @supervisor.remove_tasks(nil) }.not_to raise_error
      expect { @supervisor.remove_tasks([]) }.not_to raise_error
    end
    it "doesn't fail if the job is unknown" do
      expect { @supervisor.remove_tasks([job]) }.not_to raise_error
    end
  end

  context "remove_all_tasks" do
    it "removes all Rearview::MonitorTask actors" do
      j1 = create(:job)
      j2 = create(:job)
      @supervisor.add_tasks([j1,j2])
      @supervisor.remove_all_tasks
      task_sym = Rearview::MonitorSupervisor.task_sym(j1)
      expect { Celluloid::Actor[task_sym].nil? }.to raise_error(Celluloid::DeadActorError)
      task_sym = Rearview::MonitorSupervisor.task_sym(j2)
      expect { Celluloid::Actor[task_sym].nil? }.to raise_error(Celluloid::DeadActorError)
    end
  end

end
