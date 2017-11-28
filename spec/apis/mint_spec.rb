require "rails_helper"

describe "/id/mint", :type => :api, vcr: true do
  let(:doi) { "10.5072/0000-03vc" }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_ACCEPT" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  it "missing valid prefix parameter" do
    datacite = File.read(file_fixture('10.5438_bc11-cqw1.xml'))
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
    expect(last_response.body).to eq("error: you are not authorized to access this resource.")
  end

  it "no params" do
    doi = "10.5438"
    post "/shoulder/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(400)
    response = last_response.body.from_anvl
    expect(response["error"]).to eq("A required parameter is missing")
  end

  # we seed with _number to avoid random numbers in tests
  it "create new DOI" do
    datacite = File.read(file_fixture('10.5438_bc11-cqw1.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "datacite" => datacite, "_target" => url, "_number" => "12214907644" }.to_anvl
    doi = "10.5438"
    post "/shoulder/doi:#{doi}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5438/bc11-cqw1")
    expect(response["datacite"]).to eq(datacite)
    expect(response["_target"]).to eq(url)
  end
end
