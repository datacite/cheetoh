module Helpable
  extend ActiveSupport::Concern

  require "bolognese"
  require "cirneco"

  included do
    include Bolognese::DoiUtils
    include Cirneco::Utils

    def upsert_doi(options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      xml = options[:xml].present? ? Base64.strict_encode64(options[:xml]) : nil

      attributes = {
        "doi" => doi,
        "url" => options[:url],
        "xml" => xml,
        "event" => options[:event],
        "reason" => options[:reason]
      }.compact

      attributes.except!("doi") if options[:action] == "update"

      data = {
        "data" => {
          "type" => "dois",
          "attributes" => attributes,
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

      api_url = options[:sandbox] ? 'https://app.test.datacite.org' : 'https://app.datacite.org'

      if options[:action] == "create"
        url = "#{api_url}/dois"
        Maremma.post(url, content_type: 'application/vnd.api+json', data: data.to_json, username: options[:username], password: options[:password])
      else
        url = "#{api_url}/dois/#{doi}"
        Maremma.put(url, content_type: 'application/vnd.api+json', data: data.to_json, username: options[:username], password: options[:password])
      end
    end

    def delete_doi(options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      api_url = options[:sandbox] ? 'https://app.test.datacite.org' : 'https://app.datacite.org'

      url = "#{api_url}/dois/#{doi}"
      Maremma.delete(url, content_type: 'application/vnd.api+json', username: options[:username], password: options[:password])
    end

    def generate_random_doi(str, options={})
      prefix = validate_prefix(str)
      fail IdentifierError, "No valid prefix found" unless prefix.present?

      shoulder = str.split("/", 2)[1].to_s
      encode_doi(prefix, shoulder: shoulder, number: options[:number])
    end

    def is_ark?(str)
      str.to_s.starts_with?("ark:")
    end

    def epoch_to_utc(epoch)
      Time.at(epoch).to_datetime.utc.iso8601
    end
  end
end
