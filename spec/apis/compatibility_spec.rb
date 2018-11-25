require "rails_helper"

describe "ezid compatibility", :type => :api, vcr: true do
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_CONTENT_TYPE" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  context "ark identifiers" do
    it "show ark identifier" do
      get "/id/ark:/99999/fk4test", nil, headers
      expect(last_response.body).to eq("error: ark identifiers are not supported by this service")
      expect(last_response.status).to eq(501)
    end

    it "create ark identifier" do
      put "/id/ark:/99999/fk4test", nil, headers
      expect(last_response.body).to eq("error: ark identifiers are not supported by this service")
      expect(last_response.status).to eq(501)
    end

    it "update ark identifier" do
      post "/id/ark:/99999/fk4test", nil, headers
      expect(last_response.body).to eq("error: ark identifiers are not supported by this service")
      expect(last_response.status).to eq(501)
    end

    it "delete ark identifier" do
      delete "/id/ark:/99999/fk4test", nil, headers
      expect(last_response.body).to eq("error: ark identifiers are not supported by this service")
      expect(last_response.status).to eq(501)
    end
  end

  describe "profiles" do
    it "show erc profile" do
      doi = "10.4124/XZ7JTC6TBB.1"
      params = { "_profile" => "erc" }

      get "/id/doi:#{doi}", params
      expect(last_response.status).to eq(501)
      expect(last_response.body).to eq("error: erc profile not supported by this service")
    end

    it "show dc profile" do
      doi = "10.4124/XZ7JTC6TBB.1"
      params = { "_profile" => "dc" }

      get "/id/doi:#{doi}", params
      expect(last_response.status).to eq(501)
      expect(last_response.body).to eq("error: dc profile not supported by this service")
    end
  end
end
