require "rails_helper"

describe "invalid", :type => :api, vcr: true, :order => :defined do
  let(:doi) { "10.5438/bc11-cqw10" }
  let(:url) { "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/" }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_ACCEPT" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  it "create new reserved doi" do
    datacite = File.read(file_fixture('missing_creator.xml'))
    params = { "datacite" => datacite, "_target" => url, "_status" => "reserved" }.to_anvl
    put "/id/doi:#{doi}", params, headers

    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5438/bc11-cqw10")
    expect(response["_profile"]).to eq("datacite")
    expect(response["_status"]).to eq("reserved")
    expect(response["_target"]).to eq(url)

    doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
    expect(doc.at_css("identifier").content).to eq("10.5438/BC11-CQW10")
  end

  it "show reserved doi" do
    get "/id/doi:#{doi}"
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5438/bc11-cqw10")
    expect(response["_profile"]).to eq("datacite")
    expect(response["_status"]).to eq("reserved")
    expect(response["_target"]).to eq(url)

    doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
    expect(doc.at_css("identifier").content).to eq("10.5438/BC11-CQW10")
  end

  # it "status public" do
  #   params = { "_status" => "public" }.to_anvl
  #   post "/id/doi:#{doi}", params, headers
  #   expect(last_response.status).to eq(200)
  #   response = last_response.body.from_anvl
  #   expect(response["success"]).to eq("doi:10.5438/bc11-cqw10")
  #   expect(response["_profile"]).to eq("datacite")
  #   #expect(response["_target"]).to eq(url)
  #   expect(response["_status"]).to eq("reserved")
  #
  #   doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
  #   expect(doc.at_css("identifier").content).to eq("10.5438/BC11-CQW10")
  # end

  it "delete doi and metadata" do
    delete "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5438/bc11-cqw10")
    expect(response["_target"]).to eq(url)

    doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
    expect(doc.at_css("identifier").content).to eq("10.5438/BC11-CQW10")
  end
end
