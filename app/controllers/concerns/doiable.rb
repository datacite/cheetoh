module Doiable
  extend ActiveSupport::Concern

  included do
    include Bolognese::Utils
    include Bolognese::DoiUtils

    UPPER_LIMIT = 1073741823

    STATES = {
      "draft" => "reserved",
      "registered" => "unavailable",
      "findable" => "public"
    }

    def ez_response(response, options={})
      options[:profile] ||= :datacite 
      attributes = response.dig("data", "attributes").to_h

      status = STATES[attributes["state"]] || "public"
      status = [status, attributes["reason"]].join(" | ") if status == "unavailable" && attributes["reason"].present?

      if options[:profile] == :datacite
        metadata = attributes["xml"].present? ? Base64.decode64(attributes["xml"]) : nil
      else
        metadata = get_metadata_by_content_type(doi: attributes["doi"], profile: options[:profile].to_s)
      end
            
      { "success" => "doi:#{attributes["doi"]}",
        "_target" => attributes["url"],
        options[:profile] => metadata,
        "_profile" => options[:profile],
        "_datacenter" => response.dig("data", "relationships", "client", "data", "id").upcase,
        "_export" => "yes",
        "_created" => Time.parse(attributes["created"]).to_i,
        "_updated" => Time.parse(attributes["updated"]).to_i,
        "_status" => status
      }
    end

    def get_metadata_by_content_type(doi: nil, profile: nil)
      profile ||= "datacite"
      accept = SUPPORTED_PROFILES[profile.to_sym]

      url = "#{ENV['API_URL']}/#{doi}"
      response = Maremma.get(url, accept: accept, username: ENV['ADMIN_USERNAME'], password: ENV['ADMIN_PASSWORD'], raw: true)
      return nil unless response.status == 200

      response.body["data"]
    end

    def is_ark?(str)
      str.to_s.starts_with?("ark:")
    end

    def generate_random_doi(str, options={})
      prefix = validate_prefix(str)
      fail IdentifierError, "No valid prefix found" unless prefix.present?

      shoulder = str.split("/", 2)[1].to_s.downcase
      encode_doi(prefix, shoulder: shoulder, number: options[:number])
    end

    def encode_doi(prefix, options={})
      prefix = validate_prefix(prefix)
      return nil unless prefix.present?

      number = options[:number].to_s.scan(/\d+/).join("").to_i
      number = SecureRandom.random_number(UPPER_LIMIT) unless number > 0
      shoulder = options[:shoulder].to_s
      shoulder += "-" if shoulder.present?
      length = 8
      split = 4
      prefix.to_s + "/" + shoulder + Base32::URL.encode(number, split: split, length: length, checksum: true)
    end

    def decode_param(str)
      return nil unless str.present?

      URI.decode(str)
    end
  end

  module ClassMethods
    require "uri"

    def put_doi(doi, options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?
      return OpenStruct.new(body: { "errors" => [{ "title" => "Not a valid HTTP(S) or FTP URL" }] }) unless options[:url].blank? || /\A(http|https|ftp):\/\/[\S]+/.match(options[:url])
      
      xml = options[:data].present? ? ::Base64.strict_encode64(options[:data]) : nil

      # update doi status
      if options[:target_status] == "reserved" || doi.start_with?("10.5072")
        reason = nil
        event = nil
      elsif options[:target_status].to_s.start_with?("unavailable")
        reason = options[:target_status].split("%7C", 2).map(&:strip).last
        event = "hide"
      else
        reason = nil
        event = "publish"
      end

      author = options[:author].to_s.split(";").map { |a| { "name" => a.strip }}
      
      attributes = {
        "url" => options[:url],
        "xml" => xml,
        "author" => author,
        "title" => options[:title],
        "publisher" => options[:publisher],
        "published" => options[:published],
        "resource_type_general" => options[:resource_type_general],
        "source" => "ez",
        "event" => event,
        "reason" => reason }.compact

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

      data["data"]["relationships"]["resource-type"] = { "data"=> { "type"=> "resource-types", "id"=> options[:resource_type_general].underscore.dasherize } } if options[:resource_type_general].present?

      url = "#{ENV['API_URL']}/dois/#{doi}"
      Maremma.put(url, content_type: 'application/vnd.api+json', data: data.to_json, username: options[:username], password: options[:password])
    end

    def post_doi(doi, options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?
      return OpenStruct.new(body: { "errors" => [{ "title" => "Not a valid HTTP(S) or FTP URL" }] }) unless options[:url].blank? || /\A(http|https|ftp):\/\/[\S]+/.match(options[:url])
      
      xml = options[:data].present? ? ::Base64.strict_encode64(options[:data]) : nil

      # update doi status
      if options[:target_status] == "reserved" || doi.start_with?("10.5072") then
        event = nil
      elsif options[:target_status] == "unavailable"
        event = "hide"
      else
        event = "publish"
      end

      author = options[:author].to_s.split(";").map { |a| { "name" => a.strip }}
      
      attributes = {
        "doi" => doi,
        "url" => options[:url],
        "xml" => xml,
        "author" => author,
        "title" => options[:title],
        "publisher" => options[:publisher],
        "published" => options[:published],
        "source" => "ez",
        "event" => event }.compact

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

      data["data"]["relationships"]["resource-type"] = { "data"=> { "type"=> "resource-types", "id"=> options[:resource_type_general].underscore.dasherize } } if options[:resource_type_general].present?

      url = "#{ENV['API_URL']}/dois"
      Maremma.post(url, content_type: 'application/vnd.api+json', data: data.to_json, username: options[:username], password: options[:password])
    end

    def get_doi(doi, options={})
      url = "#{ENV['API_URL']}/dois/#{doi}"
      Maremma.get(url, content_type: 'application/vnd.api+json', username: ENV['ADMIN_USERNAME'], password: ENV['ADMIN_PASSWORD'])
    end

    def delete_doi(doi, options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      url = "#{ENV['API_URL']}/dois/#{doi}"
      Maremma.delete(url, username: options[:username], password: options[:password])
    end

    def get_dois(options={})
      return OpenStruct.new(body: { "errors" => [{ "title" => "Username or password missing" }] }) unless options[:username].present? && options[:password].present?

      url = "#{ENV['API_URL']}/dois/get-dois"
      Maremma.get(url, username: options[:username], password: options[:password])
    end
  end
end