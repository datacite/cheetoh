require "rails_helper"

describe "regular prefix", :type => :api, vcr: true, :order => :defined do
  let(:doi) { "10.5438/bc11-cqw8" }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_CONTENT_TYPE" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  it "create new reserved doi normal prefix" do
    datacite = File.read(file_fixture('10.5072_bc11-cqw8.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "datacite" => datacite, "_target" => url, "_status" => "reserved" }.to_anvl
    put "/id/doi:#{doi}", params, headers

    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5438/bc11-cqw8")
    expect(response["_target"]).to eq(url)
    expect(response["_status"]).to eq("reserved")
    expect(last_response.status).to eq(200)

    doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
    expect(doc.at_css("identifier").content).to eq("10.5438/BC11-CQW8")
  end

  it "wrong login credentials delete" do
    headers = ({ "HTTP_ACCEPT" => "text/plain", "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("name", "password") })
    delete "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("error: doi:#{doi} is not a reserved DOI")
  end

  it "wrong login credentials post" do
    headers = ({ "HTTP_ACCEPT" => "text/plain", "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials("name", "password") })
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "_target" => url }.to_anvl
    post "/id/doi:#{doi}", params, headers
    expect(last_response.status).to eq(401)
    expect(last_response.body).to eq("error: unauthorized")
  end
end
