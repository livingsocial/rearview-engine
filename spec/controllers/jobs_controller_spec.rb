require 'spec_helper'

describe Rearview::JobsController do

  before do
    sign_in_as create(:user)
    @routes = Rearview::Engine.routes
    Rearview::MetricsValidator.any_instance.stubs(:validate_each)
  end

  context "GET /jobs" do
    it "renders the index view" do
      get :index, format: :json
      render_template(:index)
    end
  end

  context "GET /jobs/:id" do
    it "renders the show view" do
      job = create(:job)
      get :show, id: job.id, format: :json
      render_template(:show)
    end
  end

  context "GET /jobs/:id/errors" do
    it "renders the errors view" do
      job = create(:job)
      get :errors, id: job.id, format: :json
      render_template(:errors)
    end
  end

  context "GET /jobs/:id/data" do
    it "renders the data view" do
      job = create(:job)
      job_data = create(:job_data,:job=>job)
      get :data, id: job.id, format: :json
      render_template(:data)
    end
    it "returns status 404 if there is no data" do
      job = create(:job)
      get :data, id: job.id, format: :json
      expect(response.status).to eq(404)
    end
  end

  context "POST /jobs" do
    it "renders the create view" do
      job = build(:job)
      Rearview::Job.any_instance.expects(:sync_monitor_service)
      post :create, JsonFactory::Job.create(job)
      render_template(:show)
    end
  end

  context "PUT /jobs/:id" do
    let(:job) { create(:job) }
    before do
      Rearview::Job.any_instance.expects(:sync_monitor_service)
    end
    it "renders the update view" do
      put :update, JsonFactory::Job.update(job)
      render_template(:show)
    end
    it "allows the dashboard to be updated" do
      dashboard = create(:dashboard)
      Rearview::Dashboard.expects(:find).with(dashboard.id).returns(dashboard)
      job_json = JsonFactory::Job.update(job)
      job_json["dashboard_id"] = dashboard.id
      put :update, job_json
    end
  end

  context "DELETE /jobs/:id" do
    let(:job) { create(:job) }
    it "renders the destroy view" do
      job.expects(:unschedule)
      Rearview::Job.expects(:find).with(job.id.to_s).returns(job)
      delete :destroy, id: job.id, format: :json
      render_template(:destroy)
    end
  end

  context "PUT /jobs/:id/reset" do
    it "renders the show view" do
      job = create(:job)
      Rearview::Job.stubs(:find).returns(job)
      job.expects(:reset)
      put :reset, JsonFactory::Job.update(job)
      render_template(:show)
    end
  end

end
