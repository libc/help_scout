require "helpscout/version"

module Helpscout
  class Client
    attr_accessor :last_response

    def initialize(api_key)
      if api_key.nil?
        raise ArgumentError "API key is required"
      end

      @api_key = api_key
    end

    def post(path, options = {})
      options[:body] = options[:body].to_json if options[:body]

      request(:post, path, options)
    end

    def put(path, options = {})
      options[:body] = options[:body].to_json if options[:body]

      request(:put, path, options)
    end

    def get(path, options = {})
      request(:get, path, options)
    end

    def search(path, query, page_id = 1, items = [])
      options = { query: { page: page_id, query: "(#{query})" } }

      result = get(path, options)
      if result.present?
        next_page_id = page_id + 1
        result["items"] += items
        if next_page_id > result["pages"]
          return result["items"]
        else
          search(path, query, next_page_id, result["items"])
        end
      end
    end

    # Public: Create HS conversation
    #
    # data - hash with data
    #
    # More info: http://developer.helpscout.net/help-desk-api/conversations/create/
    #
    # Returns conversation id from HS
    def create_conversation(data)
      post("conversations", { body: data })

      conversation_uri = last_response.headers["location"]
      conversation_uri.match(/(\d+)\.json$/)[1].to_i
    end

    # Public: Get HS conversation data
    #
    # id - integer conversation id
    #
    # More info: http://developer.helpscout.net/help-desk-api/objects/conversation/
    #
    # Returns hash from HS with conversation data
    def get_conversation(id)
      get("conversations/#{id}")
    end

    # http://developer.helpscout.net/help-desk-api/conversations/update/
    def update_conversation(id, data)
      put("conversations/#{id}", { body: data })
    end

    def get_conversation(id)
      get("conversations/#{id}")
    end

    def get_customer_from_conversation(conversation)
      customer_id = conversation["item"]["customer"]["id"]
      get("customers/#{customer_id}")
    end

    # http://developer.helpscout.net/help-desk-api/search/conversations/
    def search_conversations(query)
      search("search/conversations", query)
    end

    protected

    def request(method, path, options)
      uri = URI("https://api.helpscout.net/v1/#{path}.json")

      # The password can be anything, it's not used, see:
      # http://developer.helpscout.net/help-desk-api/
      options.reverse_merge!({
        basic_auth: {
          username: @api_key, password: 'X'
        },
        headers: {
          'Content-Type' => 'application/json'
        }
      })

      @last_response = HTTParty.send(method, uri, options)
      @last_response.parsed_response
    end
  end
end