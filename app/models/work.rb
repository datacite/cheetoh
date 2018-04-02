class Work
  include Helpable
  include Updateable
  include Findable

  attr_accessor :doi, :input, :from, :target, :export, :profile, :format, :state, :status, :target_status, :reason, :datacenter, :reason, :created, :updated, :username, :password

  def initialize(doi: nil, input: nil, from: nil, format: nil, **options)
    @doi = doi
    @input = input
    @format = format || from
    @target = options[:target]
    @target_status, @reason = options[:target_status].split("|", 2).map(&:strip) if
      options[:target_status].present?
    @datacenter = options[:datacenter].upcase if options[:datacenter].present?
    @state = options[:state]
    @created = Time.parse(options[:created]).to_i if options[:created].present?
    @updated = Time.parse(options[:updated]).to_i if options[:updated].present?
  end

  STATES = {
    "draft" => "reserved",
    "registered" => "unavailable",
    "findable" => "public"
  }

  def doi_with_protocol
    "doi:#{doi}" if doi.present?
  end

  def target_status=(value)
    @target_status, @reason = value.split("|", 2).map(&:strip) if value.present?
  end

  def status
    s = STATES[state] || "public"
    s = [s, reason].join(" | ") if s == "unavailable" && reason.present?
    s
  end

  def reserved?
    status == "reserved"
  end

  alias_method :_profile, :profile
  alias_method :_status, :status
  alias_method :_datacenter, :datacenter
  alias_method :_target, :target
  alias_method :_created, :created
  alias_method :_updated, :updated

  def _export
    "yes"
  end

  def hsh
    { "success" => doi_with_protocol,
      "_target" => _target,
      format => input,
      "_profile" => format,
      "_datacenter" => _datacenter,
      "_export" => _export,
      "_created" => _created,
      "_updated" => _updated,
      "_status" => _status }
  end
end
