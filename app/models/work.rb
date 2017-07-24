class Work < Bolognese::Metadata
  include Helpable

  include Bolognese::DoiUtils
  include Bolognese::Utils
  include Cirneco::Utils
  include Cirneco::Api

  attr_accessor :target, :data, :export, :status

  def initialize(input: nil, from: nil, format: nil, **options)
    @target = options[:target]
    @data = options[:data]

    return super(input: input, from: from, doi: options[:doi], sandbox: ENV['SANDBOX'].present?)
  end

  def upsert(username: nil, password: nil)
    if data.present?
      response = post_metadata(data,
                               username: username,
                               password: password,
                               sandbox: ENV['SANDBOX'].present?)

      return "error", response.status unless
        response.body.to_h.fetch("data", "").start_with?("OK")
    end

    if target.present?
      response = put_doi(doi, url: target,
                              username: username,
                              password: password,
                              sandbox: ENV['SANDBOX'].present?)

      return "error", response.status unless
        response.body.to_h.fetch("data", "").start_with?("OK")
    end

    message = { "success" => doi_with_protocol,
                "_target" => target,
                "datacite" => data }.to_anvl
    message, status = message, 200
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

  def _profile
    "datacite"
  end

  def _export
    "yes"
  end

  def _status
    "public"
  end

  def hsh
    { "success" => doi_with_protocol,
      "_updated" => self._updated,
      "_target" => self._target,
      "datacite" => self.datacite,
      "_profile" => self._profile,
      "_datacenter" => self._datacenter,
      "_export" => self._export,
      "_created" => self._created,
      "_status" => self._status }
  end
end
