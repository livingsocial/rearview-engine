# Tasks made available to engine host..

namespace :rearview do

  namespace :config do
    desc "Verify configuration"
    task :verify => [:environment] do
      puts "using \"#{Rails.env}\" configuration:\n#{Rearview.config.dump}"
      print "validating..."
      if Rearview.config.valid?
        puts "PASSED"
      else
        puts "FAILED"
        puts Rearview.config.errors.full_messages.join("\n")
      end
    end
  end

  desc "Setup Rearview"
  task :setup => [:environment,"db:create","db:migrate","db:seed"] do
    Kernel.system("bin/rails generate rearview:install")
  end

end
