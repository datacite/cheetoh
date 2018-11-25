require "rails_helper"

describe "delete", :type => :api, vcr: true, :order => :defined do
  let(:doi) { "10.5072/bc11-cqw7" }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_CONTENT_TYPE" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  it "missing valid doi parameter" do
    doi = "20.5072/0000-03vc"
    delete "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("error: bad request - no such identifier")
  end

  it "missing login credentials" do
    delete "/id/doi:#{doi}"
    expect(last_response.status).to eq(401)
    expect(last_response.headers["WWW-Authenticate"]).to eq("Basic realm=\"ez.test.datacite.org\"")
    expect(last_response.body).to eq("HTTP Basic: Access denied.\n")
  end

  it "not a reserved doi" do
    doi = "10.5438/mcnv-ga6n"
    delete "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("error: doi:10.5438/mcnv-ga6n is not a reserved DOI")
  end
end
