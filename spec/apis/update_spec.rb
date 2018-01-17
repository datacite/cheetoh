require "rails_helper"

describe "update", :type => :api, vcr: true, :order => :defined do
  let(:doi) { "10.5072/0000-03vc" }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_ACCEPT" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  it "missing valid doi parameter" do
    doi = "20.5072/0000-03vc"
    post "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("error: bad request - no such identifier")
  end

  it "missing login credentials" do
    post "/id/doi:#{doi}"
    expect(last_response.status).to eq(401)
    expect(last_response.headers["WWW-Authenticate"]).to eq("Basic realm=\"ez.test.datacite.org\"")
    expect(last_response.body).to eq("HTTP Basic: Access denied.\n")
  end

  it "wrong login credentials" do
    headers = ({ "HTTP_ACCEPT" => "text/plain", "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("name", "password") })
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "_target" => url }.to_anvl
    doi = "10.5072/bc11-cqw1"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(401)
    expect(last_response.body).to eq("error: unauthorized")
  end

  it "nothing to update" do
    doi = "10.5072/bc11-cqw1"
    post "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(400)
    response = last_response.body.from_anvl
    expect(response["error"]).to eq("A required parameter is missing")
  end

  it "different doi in datacite xml" do
    datacite = File.read(file_fixture('10.5072_bc11-cqw1.xml'))
    params = { "datacite" => datacite }.to_anvl
    doi = "10.5072/bc11-cqw3"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl

    #expect(response["success"]).to eq("doi:10.5072/bc11-cqw3")
    #doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
    #expect(doc.at_css("identifier").content).to eq("10.5072/BC11-CQW3")
  end

  it "change redirect url and datacite xml" do
    datacite = File.read(file_fixture('10.5072_bc11-cqw1.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "datacite" => datacite, "_target" => url }.to_anvl
    doi = "10.5072/bc11-cqw1"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5072/bc11-cqw1")
    expect(response["datacite"]).to eq(datacite.strip)
    expect(response["_target"]).to eq(url)
    expect(response["_status"]).to eq("reserved")
  end

  it "change redirect url" do
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "_target" => url }.to_anvl
    doi = "10.5072/bc11-cqw1"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5072/bc11-cqw1")
    expect(response["_target"]).to eq(url)
    expect(response["_status"]).to eq("reserved")
  end

  it "change datacite xml" do
    datacite = File.read(file_fixture('10.5072_bc11-cqw1.xml'))
    params = { "datacite" => datacite }.to_anvl
    doi = "10.5072/bc11-cqw1"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5072/bc11-cqw1")
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

  it "status draft" do
    datacite = File.read(file_fixture('10.5072_bc11-cqw1.xml'))
    params = { "_status" => "public" }.to_anvl
    doi = "10.5072/bc11-cqw1"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5072/bc11-cqw1")
    expect(response["datacite"]).to eq(datacite.strip)
    expect(response["_status"]).to eq("reserved")
  end

  it "change using schema.org" do
    schema_org = File.read(file_fixture('schema_org.json'))
    params = { "schema_org" => schema_org, "_profile" => "schema_org" }.to_anvl
    doi = "10.5072/bc11-cqw7"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    input = JSON.parse(schema_org)
    output = JSON.parse(response["schema_org"])
    expect(response["success"]).to eq("doi:10.5072/bc11-cqw7")
    expect(response["_status"]).to eq("reserved")
    expect(output["author"]).to eq(input["author"])
    expect(response["datacite"]).to be_nil
  end
end
