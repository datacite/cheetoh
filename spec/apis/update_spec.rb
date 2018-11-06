require "rails_helper"

describe "update", :type => :api, vcr: true, :order => :defined do
  let(:doi) { "10.5072/0000-03vc" }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_ACCEPT" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end
  context "missing" do
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
  end

  context "status change" do
    it "adds reason correctly" do
      datacite = File.read(file_fixture('10.5072_bc11-cqw7.xml'))
      url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
      params = { "datacite" => datacite, "_target" => url, "_status" => "unavailable | withdrawn by author" }.to_anvl
      params_update = { "_status" => "unavailable | withdrawn by pulisher" }.to_anvl
      doi = "10.5072/bc11-cqw7"
      put "/id/doi:#{doi}", params, headers

      post "/id/doi:#{doi}", params_update, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response.fetch("_status")).to eq("unavailable | withdrawn by pulisher")
    end
  end

end
