module FortePayments
  class Error < StandardError
  end

  class Client
    include FortePayments::Client::Address
    include FortePayments::Client::Customer
    include FortePayments::Client::Paymethod
    include FortePayments::Client::Settlement
    include FortePayments::Client::Transaction

    attr_reader :api_key
    attr_reader :secure_key
    attr_reader :organization_id
    attr_reader :location_id

    def initialize(options={})
      @live        = options[:mode] == :production || (ENV['FORTE_LIVE'] && ENV['FORTE_LIVE'] != '')
      @api_key     = options[:api_key] || ENV['FORTE_API_KEY']
      @secure_key  = options[:secure_key] || ENV['FORTE_SECURE_KEY']
      @organization_id = options[:organization_id] || ENV['FORTE_ORGANIZATION_ID']
      @location_id = options[:location_id] || ENV['FORTE_LOCATION_ID']
      @proxy       = options[:proxy] || ENV['PROXY'] || ENV['proxy']
      @debug       = options[:debug]
    end

    def get(path, options={})
      make_request {
        connection.get(base_path(options) + path, options)
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

    def delete(path, options={})
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
        raise FortePayments::Error, 'Unknown error' if response.body.nil?
        raise FortePayments::Error, response.body.dig('response', 'response_desc') || response.body
      end
    rescue Faraday::ParsingError
      raise FortePayments::Error, 'Unable to parse response'
    end

    def base_url
      @live ? "https://api.forte.net/v3" : "https://sandbox.forte.net/api/v3"
    end

    def base_path(options = {})
      omit_location = options.delete(:omit_location)
      if omit_location
        base_url + "/organizations/org_#{organization_id}"
      else
        base_url + "/organizations/org_#{organization_id}/locations/loc_#{location_id}"
      end

    end

    def connection
      connection_options = {
        proxy: @proxy,
        headers: {
          accept: 'application/json',
          x_forte_auth_organization_id: "org_#{organization_id}"
        }
      }

      Faraday.new(connection_options) do |connection|
        connection.basic_auth(api_key, secure_key)
        connection.request  :json
        connection.response :json
        connection.response :logger, nil, { bodies: true } if @debug
        connection.adapter  Faraday.default_adapter
      end
    end
  end
end
