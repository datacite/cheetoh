require "rails_helper"

describe "/id/update", :type => :api, vcr: true do
  let(:doi) { "10.5438/0000-03vc" }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_ACCEPT" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  it "missing valid doi parameter" do
    doi = "20.5072/0000-03vc"
    put "/id/doi:#{doi}"
    expect(last_response.status).to eq(404)
    expect(last_response.body).to eq("error: the resource you are looking for doesn't exist.")
  end

  it "missing login credentials" do
    post "/id/doi:#{doi}"
    expect(last_response.status).to eq(401)
    expect(last_response.body).to eq("error: unauthorized")
  end

  it "nothing to update" do
    doi = "10.5438/bc11-cqw1"
    post "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(400)
    response = last_response.body.from_anvl
    expect(response["error"]).to eq("A required parameter is missing")
  end

  it "different doi in datacite xml" do
    datacite = File.read(file_fixture('10.5438_bc11-cqw1.xml'))
    params = { "datacite" => datacite }.to_anvl
    doi = "10.5438/bc11-cqw3"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(400)
    response = last_response.body.from_anvl
    expect(response["error"]).to eq("params doi:10.5438/bc11-cqw3 does not match doi:10.5438/bc11-cqw1 in metadata")
  end

  it "change redirect url and datacite xml" do
    datacite = File.read(file_fixture('10.5438_bc11-cqw1.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "datacite" => datacite, "_target" => url }.to_anvl
    doi = "10.5438/bc11-cqw1"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5438/bc11-cqw1")
    expect(response["datacite"]).to eq(datacite)
    expect(response["_target"]).to eq(url)
  end

  it "change redirect url" do
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "_target" => url }.to_anvl
    doi = "10.5438/bc11-cqw1"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5438/bc11-cqw1")
    expect(response["_target"]).to eq(url)
  end

  it "change datacite xml" do
    datacite = File.read(file_fixture('10.5438_bc11-cqw1.xml'))
    params = { "datacite" => datacite }.to_anvl
    doi = "10.5438/bc11-cqw1"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5438/bc11-cqw1")
    expect(response["datacite"]).to eq(datacite)
  end

  it "change using citeproc" do
    schema_org = File.read(file_fixture('schema_org.json'))
    params = { "schema_org" => schema_org, "_profile" => "schema_org" }.to_anvl
    doi = "10.5438/4k3m-nyvg"
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5438/4k3m-nyvg")
    expect(response["schema_org"]).to eq(schema_org)
    expect(response["datacite"]).to start_with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<resource")
  end
end
