module Helpable
  extend ActiveSupport::Concern

  require "bolognese"
  require "cirneco"

  included do
    include Bolognese::DoiUtils
    include Cirneco::Utils

    def draft_doi(options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      data = {
        "data" => {
          "type" => "dois",
          "attributes" => {
            "doi" => options[:doi],
            "event" => options[:event]
          },
          "relationships"=> {
            "client"=>  {
              "data"=> {
                "type"=> "clients",
                "id"=> options[:username]
              }
            }
          }
        }
      }

      api_url = options[:sandbox] ? 'https://api.test.datacite.org' : 'https://api.datacite.org'

      url = "#{api_url}/dois"
      Maremma.post(url, content_type: 'application/vnd.api+json', data: data.to_json, username: options[:username], password: options[:password])
    end

    def update_doi(doi, options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      attributes = {
        "doi" => doi,
        "url" => options[:url],
        "event" => options[:event]
      }.compact
      
      data = {
        "data" => {
          "type" => "dois",
          "attributes" => attributes
        }
      }

      api_url = options[:sandbox] ? 'https://api.test.datacite.org' : 'https://api.datacite.org'

      url = "#{api_url}/dois/#{doi}"
      Maremma.patch(url, content_type: 'application/vnd.api+json', data: data.to_json, username: options[:username], password: options[:password])
    end

    def delete_doi(options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      api_url = options[:sandbox] ? 'https://api.test.datacite.org' : 'https://api.datacite.org'

      url = "#{api_url}/dois/#{doi}"
      Maremma.delete(url, content_type: 'application/vnd.api+json', username: options[:username], password: options[:password])
    end

    def generate_random_doi(str, options={})
      prefix = validate_prefix(str)
      fail IdentifierError, "No valid prefix found" unless prefix.present?

      shoulder = str.split("/", 2)[1].to_s
      number = options[:number].to_s.scan(/\d+/).first.to_i
      encode_doi(prefix, shoulder: shoulder, number: number)
    end

    def is_ark?(str)
      str.to_s.starts_with?("ark:")
    end

    def epoch_to_utc(epoch)
      Time.at(epoch).to_datetime.utc.iso8601
    end
  end
end
