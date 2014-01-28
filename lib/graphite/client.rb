module Graphite
  class Client
    extend Forwardable
    attr_reader :connection
    def_delegators :@connection, :get, :post
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
    def render(params={})
      connection.get('/render',params)
    end
    def find_metric(metric)
      connection.get('/metrics/find',{ query: metric })
    end
    def metric_exists?(metric)
      exists = false
      response = find_metric(metric)
      # Does this need to handle redirects?
      if response.status == 200 && response.headers['content-type']=='application/json'
        json = JSON.parse(response.body)
        exists = true unless json.empty?
      end
      exists
    end
    def reachable?
      reachable = false
      begin
        response = connection.get('/render')
        reachable = response.status==200 && response.headers['content-type']=='image/png' && response.headers['content-length'].to_i > 0
      rescue Exception => e
      end
      reachable
    end
  end
end
