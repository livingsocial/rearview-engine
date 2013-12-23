require 'rails/generators/base'

module Rearview
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("../../templates", __FILE__)

      desc "Creates a Rearview initializer."

      def copy_initializer
        template "rearview.rb", "config/initializers/rearview.rb"
      end

      def show_readme
        readme "README.md" if behavior == :invoke
      end
    end
  end
end

