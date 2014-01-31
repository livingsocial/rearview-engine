module Rearview
  module ApplicationHelper
    def rearview_static_path(segment=nil)
      prefix = if Rails.env.development?
               "/rearview-src"
               else
               "/rearview"
               end
      ( segment.present? ? prefix + segment : prefix )
    end
    def rearview_link_tag(href,options)
      options = options.symbolize_keys
      options[:href] = rearview_static_path(href)
      tag("link",options)
    end
    def rearview_img_tag(source,options)
      options = options.symbolize_keys
      options[:src] = rearview_static_path("/img"+source)
      tag("img", options)
    end
  end
end
