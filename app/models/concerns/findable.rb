module Findable
  extend ActiveSupport::Concern

  require "bolognese"

  module ClassMethods
    include Bolognese::DoiUtils

    def where(doi: nil, profile: nil)
      profile ||= "datacite"
      response = get_doi(doi)
      return nil unless response.status == 200

      data = response.body["data"]
      target = data.dig('attributes', 'url')
      datacenter = data.dig('relationships', 'client', 'data', 'id')
      state = data.dig('attributes', 'state')
      created = data.dig('attributes', 'registered')
      updated = data.dig('attributes', 'updated')

      response = get_doi_by_content_type(doi: doi, profile: profile)
      return nil unless response.status == 200

      input = response.body["data"]

      Work.new(input: input,
               from: profile,
               doi: doi,
               target: target,
               datacenter: datacenter,
               state: state,
               created: created,
               updated: updated)
    end

    def get_doi(doi)
      url = "#{ENV['API_URL']}/dois/#{doi}"
      Maremma.get(url, content_type: 'application/vnd.api+json', username: ENV['ADMIN_USERNAME'], password: ENV['ADMIN_PASSWORD'])
    end

    # use raw option to not automatically parse xml or json response
    def get_doi_by_content_type(doi: nil, profile: nil)
      profile ||= "datacite"
      accept = SUPPORTED_PROFILES[profile.to_sym]

      url = "#{ENV['API_URL']}/#{doi}"
      Maremma.get(url, accept: accept, username: ENV['ADMIN_USERNAME'], password: ENV['ADMIN_PASSWORD'], raw: true)
    end

    def api_url
      Rails.env.production? ? 'https://api.datacite.org' : 'https://api.test.datacite.org' 
    end
  end
end