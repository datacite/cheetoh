require "rails_helper"

describe "/id/create", :type => :api, vcr: true do
  let(:doi) { "10.5072/0000-03vc" }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_ACCEPT" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  it "missing valid doi parameter" do
    doi = "20.5072/0000-03vc"
    put "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("error: bad request - no such identifier")
  end

  it "missing login credentials" do
    put "/id/doi:#{doi}"
    expect(last_response.status).to eq(401)
    expect(last_response.body).to eq("error: unauthorized")
  end

  it "wrong login credentials" do
    doi = "10.5072/bc11-cqw70"
    headers = ({ "HTTP_ACCEPT" => "text/plain", "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("name", "password") })
    datacite = File.read(file_fixture('10.5072_bc11-cqw7.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "datacite" => datacite, "_target" => url }.to_anvl
    put "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(401)
    expect(last_response.body).to eq("error: unauthorized")
  end

  it "no params" do
    doi = "10.5072/bc11-cqw1"
    put "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(400)
    response = last_response.body.from_anvl
    expect(response["error"]).to eq("A required parameter is missing")
  end

  it "reserved status" do
    doi = "10.5072/bc11-cqw1"
    params = { "_status" => "reserved" }.to_anvl
    put "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(501)
    response = last_response.body.from_anvl
    expect(response["error"]).to eq("A reserved status is not supported by this service")
  end

  it "DOI already exists" do
    datacite = File.read(file_fixture('10.5072_bc11-cqw1.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "datacite" => datacite, "_target" => url }.to_anvl
    doi = "10.5072/bc11-cqw1"
    put "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(400)
    response = last_response.body.from_anvl
    expect(response["error"]).to eq("doi:10.5072/bc11-cqw1 has already been registered")
  end

  it "different doi in datacite xml" do
    datacite = File.read(file_fixture('10.5072_bc11-cqw1.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "datacite" => datacite, "_target" => url }.to_anvl
    doi = "10.5072/bc11-cqw4"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl

    #expect(response["success"]).to eq("doi:10.5072/bc11-cqw4")
    #doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
    #expect(doc.at_css("identifier").content).to eq("10.5072/BC11-CQW4")
  end

  it "create new DOI" do
    datacite = File.read(file_fixture('10.5072_bc11-cqw7.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "datacite" => datacite, "_target" => url }.to_anvl
    doi = "10.5072/bc11-cqw7"
    put "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5072/bc11-cqw7")
    expect(response["datacite"]).to eq(datacite.strip)
    expect(response["_target"]).to eq(url)
  end
end
