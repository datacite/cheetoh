require "rails_helper"

describe "reserved", :type => :api, vcr: true, :order => :defined do
  let(:doi) { "10.5072/bc11-cqw9" }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_ACCEPT" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  it "create new reserved doi" do
    params = { "_status" => "reserved" }.to_anvl
    put "/id/doi:#{doi}", params, headers

    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5072/bc11-cqw9")
    expect(response["_status"]).to eq("reserved")
  end

  it "show reserved doi" do
    get "/id/doi:#{doi}"
    expect(last_response.status).to eq(200)
    response = last_response.body
    hsh = response.from_anvl
    expect(hsh["success"]).to eq("doi:10.5072/bc11-cqw9")
    expect(hsh["_profile"]).to eq("datacite")
    expect(hsh["_status"]).to eq("reserved")
  end

  it "delete doi and metadata" do
    delete "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(200)
    response = last_response.body
    hsh = response.from_anvl
    expect(hsh["success"]).to eq("doi:10.5072/bc11-cqw9")
    expect(hsh["datacite"]).to be_blank
    expect(hsh["_target"]).to be_blank
  end
end
