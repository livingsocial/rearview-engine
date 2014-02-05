module Rearview
  class ApplicationController < ActionController::Base
    helper Rearview::Engine.helpers
    before_filter :authenticate_user!

    protected

    def underscore_params
      self.params = self.params.inject({}.with_indifferent_access) { |a,(k,v)| a[k.to_s.underscore] = v; a }
    end

    def clean_empty_array_vals(key)
      params[key].reject! { |m| !m.present? } if params[key].present?
    end

  end
end
