
module FortePayments
  class Error < StandardError
  end

  class Client
    include FortePayments::Client::Address
    include FortePayments::Client::Customer
    include FortePayments::Client::Paymethod
    include FortePayments::Client::Settlement
    include FortePayments::Client::Transaction

    attr_reader :api_key, :secure_key, :account_id, :location_id

    def initialize(options = {})
      @api_key     = options[:api_key] || ENV['FORTE_API_KEY']
      @secure_key  = options[:secure_key] || ENV['FORTE_SECURE_KEY']
      @account_id  = options[:account_id] || ENV['FORTE_ACCOUNT_ID']
      @location_id = options[:location_id] || ENV['FORTE_LOCATION_ID']
      @debug       = options[:debug]
      @live        = (ENV['FORTE_LIVE'] == "" || ENV['FORTE_LIVE'] == nil) ? false : true
      @proxy       = options[:proxy] || ENV['PROXY'] || ENV['proxy']
    end

    def get(path, options={})
      make_request {
        connection.get(base_path + path, options)
      }
    end

    def post(path, req_body)
      make_request {
        connection.post do |req|
          req.url(base_path + path)
          req.body = req_body
        end
      }
    end

    def put(path, options={})
      make_request {
        connection.put(base_path + path, options)
      }
    end

    def delete(path, options = {})
      make_request {
        connection.delete(base_path + path, options)
      }
    end

    private

    def make_request
      response = yield

      if response.success?
        response.body
      else
        message = (response.body && response.body["response"] && response.body["response"]["response_desc"]) ? response.body["response"]["response_desc"] : response.body
        
        raise FortePayments::Error, message
      end
    end

    def base_url
      if @live
        "https://api.forte.net/v2"
      else
        "https://sandbox.forte.net/api/v2"
      end
    end

    def base_path
      base_url + "/accounts/act_#{account_id}/locations/loc_#{location_id}"
    end

    def connection
      connection_options = {
        proxy: @proxy,
        headers: {
          'Accept'                  => 'application/json',
          'X-Forte-Auth-Account-Id' => "act_#{account_id}"
        }
      }

      Faraday.new(connection_options) do |connection|
        connection.basic_auth(api_key, secure_key)
        connection.request  :json
        connection.response :json
        connection.response :logger if @debug
        connection.adapter  Faraday.default_adapter
      end
    end
  end
end
