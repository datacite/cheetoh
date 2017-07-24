module Helpable
  extend ActiveSupport::Concern

  require "bolognese"
  require "cirneco"
  require "maremma"

  included do
    def generate_random_doi(str)
      prefix = validate_prefix(str)
      fail IdentifierError, "No valid prefix found" unless prefix.present?

      shoulder = str.split("/", 2).last
      encode_doi(prefix, shoulder: shoulder)
    end

    def epoch_to_utc(epoch)
      Time.at(epoch).to_datetime.utc.iso8601
    end

  end
end
