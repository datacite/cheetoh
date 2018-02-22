require "rails_helper"

describe "create", :type => :api, vcr: true, :order => :defined do
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
    expect(last_response.headers["WWW-Authenticate"]).to eq("Basic realm=\"ez.test.datacite.org\"")
    expect(last_response.body).to eq("HTTP Basic: Access denied.\n")
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

  it "create new doi" do
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
    expect(response["_status"]).to eq("reserved")
  end

  it "doi already exists" do
    datacite = File.read(file_fixture('10.5072_bc11-cqw7.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "datacite" => datacite, "_target" => url }.to_anvl
    doi = "10.5072/bc11-cqw7"
    put "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(400)
    response = last_response.body.from_anvl
    expect(response["error"]).to eq("doi:10.5072/bc11-cqw7 has already been registered")
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

  it "change datacite xml" do
    datacite = File.read(file_fixture('10.5072_bc11-cqw7.xml'))
    params = { "datacite" => datacite }.to_anvl
    doi = "10.5072/bc11-cqw7"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5072/bc11-cqw7")
    expect(response["datacite"]).to eq(datacite.strip)
    expect(response["_status"]).to eq("reserved")
  end

  it "delete new doi" do
    datacite = File.read(file_fixture('10.5072_bc11-cqw7.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    doi = "10.5072/bc11-cqw7"
    delete "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5072/bc11-cqw7")
    expect(response["_target"]).to eq(url)

    doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
    expect(doc.at_css("identifier").content.upcase).to eq("10.5072/BC11-CQW7")
  end
end
