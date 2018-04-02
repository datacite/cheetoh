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
      api_url = ENV['SANDBOX'].present? ? 'https://app.test.datacite.org' : 'https://app.datacite.org'

      url = "#{api_url}/dois/#{doi}"
      Maremma.get(url, content_type: 'application/vnd.api+json')
    end

    # use raw option to not automatically parse xml or json response
    def get_doi_by_content_type(doi: nil, profile: nil)
      profile ||= "datacite"
      accept = SUPPORTED_PROFILES[profile.to_sym]

      api_url = ENV['SANDBOX'].present? ? 'https://app.test.datacite.org' : 'https://app.datacite.org'

      url = "#{api_url}/#{doi}"
      Maremma.get(url, accept: accept, raw: true)
    end
  end
end