class Work < Bolognese::Metadata
  include Helpable

  include Bolognese::DoiUtils
  include Bolognese::Utils
  include Cirneco::Utils
  include Cirneco::Api

  attr_accessor :target, :data, :export, :profile, :format, :status, :target_status

  def initialize(input: nil, from: nil, format: nil, **options)
    @format = format || from
    @target = options[:target]
    @target_status = options[:target_status]
    @data = options[:data].presence || "update"

    return super(input: input, from: from, doi: options[:doi], sandbox: ENV['SANDBOX'].present?)
  end

  STATES = {
    "draft" => "reserved",
    "registered" => "unavailable",
    "findable" => "public"
  }

  def upsert(username: nil, password: nil)
    if data == "update"
      response = post_metadata(datacite,
                               username: username,
                               password: password,
                               sandbox: ENV['SANDBOX'].present?)

      raise CanCan::AccessDenied if response.status == 401
      error_message(response).presence && return
    end

    if target.present?
      response = put_doi(doi, url: target,
                              username: username,
                              password: password,
                              sandbox: ENV['SANDBOX'].present?)

      raise CanCan::AccessDenied if response.status == 401
      error_message(response).presence && return
    end

    # update doi status
    if target_status == "reserved" then
      event = "start"
    elsif target_status == "unavailable" then
      event = "register"
    else
      event = "publish"
    end

    response = update_doi(doi, event: event,
                               url: target,
                               username: username,
                               password: password,
                               sandbox: ENV['SANDBOX'].present?)

    raise CanCan::AccessDenied if response.status == 401

    attributes = response.body.to_h.dig("data", "attributes").to_h
    self.state = attributes.fetch("state", "findable")
    self.url = attributes.fetch("url", nil)

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

  def delete(username: nil, password: nil)
    response = delete_doi(username: username,
                          password: password,
                          sandbox: ENV['SANDBOX'].present?)

    raise CanCan::AccessDenied if response.status == 401
    error_message(response).presence && return

    message = { "success" => doi_with_protocol,
                "_status" => status,
                "_target" => url,
                format => send(format.to_sym),
                "_profile" => from }.to_anvl

    [message, 200]
  end

  def draft(username: nil, password: nil)
    response = draft_doi(doi: doi,
                         event: "start",
                         username: username,
                         password: password,
                         sandbox: ENV['SANDBOX'].present?)

    raise CanCan::AccessDenied if response.status == 401
    error_message(response).presence && return

    self.state = "draft"

    message = { "success" => doi_with_protocol,
                "_status" => status,
                "_profile" => from }.to_anvl

    [message, 200]
  end

  def doi_with_protocol
    "doi:#{doi}" if doi.present?
  end

  def status
    STATES[state] || "public"
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
