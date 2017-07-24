require "rails_helper"

describe "ezid compatibility", :type => :api, vcr: true do
  context "ark identifiers" do
    it "show ark identifier" do
      get "/id/ark:/99999/fk4test"
      expect(last_response.status).to eq(501)
      expect(last_response.body).to eq("error: ark identifiers are not supported by this service")
    end

    it "create ark identifier" do
      put "/id/ark:/99999/fk4test"
      expect(last_response.status).to eq(501)
      expect(last_response.body).to eq("error: ark identifiers are not supported by this service")
    end

    it "update ark identifier" do
      post "/id/ark:/99999/fk4test"
      expect(last_response.status).to eq(501)
      expect(last_response.body).to eq("error: ark identifiers are not supported by this service")
    end

    it "delete ark identifier" do
      delete "/id/ark:/99999/fk4test"
      expect(last_response.status).to eq(501)
      expect(last_response.body).to eq("error: ark identifiers are not supported by this service")
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
