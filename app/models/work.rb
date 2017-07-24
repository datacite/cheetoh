class Work < Bolognese::Metadata
  include Helpable

  include Bolognese::DoiUtils
  include Bolognese::Utils
  include Cirneco::Utils
  include Cirneco::Api

  attr_accessor :target, :data, :export, :profile, :format, :status

  def initialize(input: nil, from: nil, format: nil, **options)
    @format = format || from
    @target = options[:target]
    @data = options[:data]

    return super(input: input, from: from, doi: options[:doi], sandbox: ENV['SANDBOX'].present?)
  end

  def upsert(username: nil, password: nil)
    if data.present?
      response = post_metadata(datacite,
                               username: username,
                               password: password,
                               sandbox: ENV['SANDBOX'].present?)

      error_message(response).presence && return
    end

    if target.present?
      response = put_doi(doi, url: target,
                              username: username,
                              password: password,
                              sandbox: ENV['SANDBOX'].present?)

      error_message(response).presence && return
    end

    message = { "success" => doi_with_protocol,
                "_target" => target,
                "datacite" => datacite,
                from => data,
                "_profile" => from }.to_anvl

    [message, 200]
  end

  def error_message(response)
    unless response.body.to_h.fetch("data", "").start_with?("OK")
      [response.body.to_h.fetch("errors", "").inspect, response.status]
    end
  end

  def doi_with_protocol
    "doi:#{doi}" if doi.present?
  end

  def _target
    url
  end

  def _datacenter
    data_center_id
  end

  def _created
    Time.parse(date_registered).to_i
  end

  def _updated
    Time.parse(date_updated).to_i
  end

  alias_method :_profile, :profile

  def _export
    "yes"
  end

  def _status
    "public"
  end

  def hsh
    { "success" => doi_with_protocol,
      "_updated" => _updated,
      "_target" => _target,
      from => send(from.to_sym),
      format => send(format.to_sym),
      "_profile" => format,
      "_datacenter" => _datacenter,
      "_export" => _export,
      "_created" => _created,
      "_status" => _status }
  end
end
