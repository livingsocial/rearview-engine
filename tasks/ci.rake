namespace :ci do
  desc 'Run as travis before_script'
  task :before do
    # db = { 'test' => {
      # 'adapter' => 'mysql',
      # 'database' => 'rearview_ruby_test',
      # 'username' => 'travis',
      # 'password' => nil,
      # 'host' => 'localhost'
    # } }
    # File.open('spec/dummy/config/database.yml','w') {|f| f.write db.to_yaml }
    ENV['RAILS_ENV'] = "test"
    Rake::Task['db:create'].invoke
  end
end
