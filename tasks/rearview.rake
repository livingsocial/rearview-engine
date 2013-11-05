namespace :rearview do
  namespace :ui do
    desc "Run require optimizer"
    task :build do
      file_name = "public/rearview-src/js/app.build.js"
      system("r.js -o #{file_name}")
    end
  end
end
