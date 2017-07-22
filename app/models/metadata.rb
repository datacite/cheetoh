class Metadata < Bolognese::Metadata
  include Helpable
  include Anvlable

  def initialize(input: nil, from: nil, format: nil)
    return super(input: input, from: from)
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
end
