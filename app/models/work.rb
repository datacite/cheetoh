class Work < Bolognese::Metadata
  include Helpable

  include Bolognese::DoiUtils
  include Bolognese::Utils
  include Cirneco::Utils
  include Cirneco::Api

  attr_reader :username, :password

  def initialize(input: nil, from: nil, format: nil, **options)
    return super(input: input, from: from, sandbox: ENV['SANDBOX'].present?)
  end

  def upsert(username: nil, password: nil, url: nil, data: nil)
    if data.present?
      response = post_metadata(datacite,
                               username: username,
                               password: password,
                               sandbox: ENV['SANDBOX'].present?)
    end

    if url.present?
      response = put_doi(doi, url: url,
                              username: username,
                              password: password,
                              sandbox: ENV['SANDBOX'].present?)
    end

    if response.body.to_h.fetch("data", "").start_with?("OK")
      message = { "success" => doi_with_protocol,
                  "datacite" => datacite }.to_anvl
      message, status = message, response.status
    else
      message, status = "error", response.status
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
