require "rails_helper"

describe "mint", :type => :api, vcr: true, :order => :defined do
  let(:doi) { "10.5072/0000-03vc" }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_ACCEPT" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  it "missing valid prefix parameter" do
    datacite = File.read(file_fixture('10.5072_3mfp-6m52.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "datacite" => datacite, "_target" => url }.to_anvl
    doi = "20.5072/abc"
    post "/shoulder/doi:#{doi}", params, headers
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("error: No valid prefix found")
  end

  it "missing login credentials" do
    post "/shoulder/doi:#{doi}"
    expect(last_response.status).to eq(401)
    expect(last_response.headers["WWW-Authenticate"]).to eq("Basic realm=\"ez.test.datacite.org\"")
    expect(last_response.body).to eq("HTTP Basic: Access denied.\n")
  end

  it "wrong login credentials" do
    headers = ({ "HTTP_ACCEPT" => "text/plain", "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("name", "password") })
    datacite = File.read(file_fixture('10.5072_tba.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "datacite" => datacite, "_target" => url, "_number" => "122149076" }.to_anvl
    doi = "10.5072"
    post "/shoulder/doi:#{doi}", params, headers
    expect(last_response.status).to eq(401)
    expect(last_response.body).to eq("error: unauthorized")
  end

  it "no params" do
    doi = "10.5072"
    post "/shoulder/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(400)
    response = last_response.body.from_anvl
    expect(response["error"]).to eq("no _profile provided")
  end

  # we seed with _number to avoid random numbers in tests
  it "create new doi" do
    datacite = File.read(file_fixture('10.5072_tba.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "datacite" => datacite, "_target" => url, "_number" => "122149076" }.to_anvl
    doi = "10.5072"
    post "/shoulder/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5072/3mfp-6m52")
    expect(response["_target"]).to eq(url)
    expect(response["_status"]).to eq("reserved")

    doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
    expect(doc.at_css("identifier").content).to eq("10.5072/3MFP-6M52")
  end

  it "nothing to update" do
    doi = "10.5072/3mfp-6m52"
    post "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(400)
    response = last_response.body.from_anvl
    expect(response["error"]).to eq("No _profile, _target or _status provided")
  end

  it "change redirect url and datacite xml" do
    datacite = File.read(file_fixture('10.5072_3mfp-6m52.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "datacite" => datacite, "_target" => url }.to_anvl
    doi = "10.5072/3mfp-6m52"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5072/3mfp-6m52")
    expect(response["datacite"]).to eq(datacite.strip)
    expect(response["_target"]).to eq(url)
    expect(response["_status"]).to eq("reserved")
  end

  it "change redirect url" do
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "_target" => url }.to_anvl
    doi = "10.5072/3mfp-6m52"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5072/3mfp-6m52")
    expect(response["_target"]).to eq(url)
    expect(response["_status"]).to eq("reserved")
  end

  it "change datacite xml" do
    datacite = File.read(file_fixture('10.5072_3mfp-6m52.xml'))
    params = { "datacite" => datacite }.to_anvl
    doi = "10.5072/3mfp-6m52"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5072/3mfp-6m52")
    expect(response["datacite"]).to eq(datacite.strip)
    expect(response["_status"]).to eq("reserved")
  end

  # it "status unavailable" do
  #   datacite = File.read(file_fixture('10.5072_bc11-cqw1.xml'))
  #   params = { "_status" => "unavailable" }.to_anvl
  #   doi = "10.5072/bc11-cqw1"
  #   post "/id/doi:#{doi}", params, headers
  #   expect(last_response.status).to eq(200)
  #   response = last_response.body.from_anvl
  #   expect(response["success"]).to eq("doi:10.5072/bc11-cqw1")
  #   expect(response["datacite"]).to eq(datacite.strip)
  #   expect(response["_status"]).to eq("unavailable")
  # end

  # it "status reserved" do
  #   datacite = File.read(file_fixture('10.5072_3mfp-6m52.xml'))
  #   params = { "_status" => "public" }.to_anvl
  #   doi = "10.5072/3mfp-6m52"
  #   post "/id/doi:#{doi}", params, headers
  #   expect(last_response.status).to eq(200)
  #   response = last_response.body.from_anvl
  #   expect(response["success"]).to eq("doi:10.5072/3mfp-6m52")
  #   expect(response["datacite"]).to eq(datacite.strip)
  #   expect(response["_status"]).to eq("reserved")
  # end

  it "delete new doi" do
    datacite = File.read(file_fixture('10.5072_tba.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    doi = "10.5072/3mfp-6m52"
    delete "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5072/3mfp-6m52")
    expect(response["_target"]).to eq(url)

    doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
    expect(doc.at_css("identifier").content).to eq("10.5072/3MFP-6M52")
  end

  it "create new reserved doi" do
    params = { "_status" => "reserved", "_number" => "122149076" }.to_anvl
    doi = "10.5072"
    post "/shoulder/doi:#{doi}", params, headers

    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5072/3mfp-6m52")
    expect(response["_status"]).to eq("reserved")
  end

  it "delete reserved doi" do
    doi = "10.5072/3mfp-6m52"
    delete "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(200)
    response = last_response.body
    hsh = response.from_anvl
    expect(hsh["success"]).to eq("doi:10.5072/3mfp-6m52")
  end
end
