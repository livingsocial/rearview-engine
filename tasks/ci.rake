namespace :ci do
  desc 'Run as travis before_script'
  task :before do
    ENV['RAILS_ENV'] = "test"
    Rake::Task['db:create'].invoke
  end
end
