class Work < Bolognese::Metadata
  include Helpable

  include Bolognese::DoiUtils
  include Bolognese::Utils
  include Cirneco::Utils
  include Cirneco::Api

  attr_accessor :target, :export, :profile, :format, :status, :target_status, :reason

  def initialize(input: nil, from: nil, format: nil, **options)
    @format = format || from
    @target = options[:target]
    @target_status, @reason = options[:target_status].split("|", 2).map(&:strip) if
      options[:target_status].present?

    return super(input: input, from: from, doi: options[:doi], sandbox: ENV['SANDBOX'].present?)
  end

  STATES = {
    "draft" => "reserved",
    "registered" => "unavailable",
    "findable" => "public"
  }

  def create_record(username: nil, password: nil)
    upsert_record(username: username, password: password, action: "create")
  end

  def update_record(username: nil, password: nil)
    upsert_record(username: username, password: password, action: "update")
  end

  def upsert_record(username: nil, password: nil, action: nil)
    # update doi status
    if target_status == "reserved" || doi.start_with?("10.5072") then
      event = "start"
    elsif target_status == "unavailable"
      event = "hide"
    else
      event = "publish"
    end

    attributes = {
      doi: doi,
      url: target,
      xml: datacite,
      event: event,
      reason: reason,
      action: action,
      username: username,
      password: password,
      sandbox: ENV['SANDBOX'].present? }

    response = upsert_doi(attributes)

    raise CanCan::AccessDenied if response.status == 401
    error_message(response).presence && return

    attributes = response.body.to_h.dig("data", "attributes").to_h
    self.state = attributes.fetch("state", "findable")
    self.url = attributes.fetch("url", nil)
    self.reason = attributes.fetch("reason", nil)

    if target.present? && event == "publish"
      response = put_doi(doi, url: target,
                              username: username,
                              password: password,
                              sandbox: ENV['SANDBOX'].present?)

      raise CanCan::AccessDenied if response.status == 401
      error_message(response).presence && return
    end

    message = { "success" => doi_with_protocol,
                "_status" => status,
                "_target" => target,
                format => send(format.to_sym),
                "_profile" => from }.to_anvl

    [message, 200]
  end

  def error_message(response)
    unless [200, 201, 204].include?(response.status)
      [response.body.to_h.fetch("errors", "").inspect, response.status]
    end
  end

  def delete_record(username: nil, password: nil)
    response = delete_doi(username: username,
                          password: password,
                          sandbox: ENV['SANDBOX'].present?)

    raise CanCan::AccessDenied if response.status == 401
    error_message(response).presence && return

    message = { "success" => doi_with_protocol,
                "_target" => url,
                format => send(format.to_sym),
                "_profile" => from }.to_anvl

    [message, 200]
  end

  def doi_with_protocol
    "doi:#{doi}" if doi.present?
  end

  def status
    s = STATES[state] || "public"
    s = [s, reason].join(" | ") if s == "unavailable" && reason.present?
    s
  end

  def reserved?
    status == "reserved"
  end

  def _target
    url
  end

  def _datacenter
    client_id
  end

  def _created
    Time.parse(date_registered).to_i if date_registered.present?
  end

  def _updated
    Time.parse(date_updated).to_i if date_registered.present?
  end

  alias_method :_profile, :profile
  alias_method :_status, :status

  def _export
    "yes"
  end

  def hsh
    { "success" => doi_with_protocol,
      "_target" => _target,
      format => send(format.to_sym),
      "_profile" => format,
      "_datacenter" => _datacenter,
      "_export" => _export,
      "_created" => _created,
      "_updated" => _updated,
      "_status" => _status }
  end
end
