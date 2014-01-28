module Graphite
  class Client
    attr_reader :connection
    # https://github.com/google/google-api-ruby-client/blob/master/lib/google/api_client.rb
    def initialize(options={})
      default_options = {}
      default_options[:ssl] = {
        verify: true,
        ca_file: File.expand_path('../cacerts.pem', __FILE__)
      }
      basic_auth = options.delete(:basic_auth)
      @connection = Faraday.new(default_options.merge(options))
      if basic_auth.present?
        @connection.basic_auth(basic_auth[:user],basic_auth[:password])
      end
    end
    def reachable?
      reachable = false
      begin
        response = connection.get('/render')
        reachable = response.status==200 && response.headers['content-type']=="image/png" && response.headers['content-length'].to_i > 0
      rescue Exception => e
      end
      reachable
    end
  end
end
