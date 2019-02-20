require "rails_helper"

describe "status", :type => :api, vcr: true, :order => :defined do
  let(:datacite) { File.read(file_fixture('10.5072_bc11-cqw8.xml')) }
  let(:url) { "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/" }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_CONTENT_TYPE" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  context "test prefix" do
    let(:doi) { "10.5072/bc11-cqw8" }

    it "create status reserved" do
      params = { "datacite" => datacite, "_target" => url, "_status" => "reserved" }.to_anvl
      put "/id/doi:#{doi}", params, headers

      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/bc11-cqw8")
      expect(response["datacite"]).to eq(datacite.strip)
      expect(response["_target"]).to eq(url)
      expect(response["_status"]).to eq("reserved")
    end

    it "status public" do
      params = { "_status" => "public" }.to_anvl
      post "/id/doi:#{doi}", params, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/bc11-cqw8")
      expect(response["datacite"]).to eq(datacite.strip)
      expect(response["_status"]).to eq("reserved")
    end

    it "status unavailable" do
      params = { "_status" => "unavailable | withdrawn by author" }.to_anvl
      post "/id/doi:#{doi}", params, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/bc11-cqw8")
      expect(response["datacite"]).to eq(datacite.strip)
      expect(response["_status"]).to eq("reserved")
    end

    it "delete doi and metadata" do
      delete "/id/doi:#{doi}", nil, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/bc11-cqw8")
      expect(response["datacite"]).to eq(datacite.strip)
      expect(response["_target"]).to eq(url)
    end
  end

  context "normal prefix" do
    let(:doi) { "10.5438/bc11-cqw8" }
    let(:datacite) { File.read(file_fixture('10.5438_bc11-cqw8.xml')) }


    it "status public" do
      params = { "_status" => "public" }.to_anvl
      post "/id/doi:#{doi}", params, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5438/bc11-cqw8")
      #expect(response["_target"]).to eq(url)
      expect(response["_status"]).to eq("public")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5438/BC11-CQW8")
    end

    it "status unavailable" do
      params = { "_status" => "unavailable | withdrawn by author" }.to_anvl
      post "/id/doi:#{doi}", params, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5438/bc11-cqw8")
      #expect(response["_target"]).to eq(url)
      expect(response["_status"]).to eq("unavailable | withdrawn by author")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5438/BC11-CQW8")
    end
  end

  context "status change" do
    let(:doi) { "10.5438/bc11-cqw8" }
    let(:datacite) { File.read(file_fixture('10.5438_bc11-cqw8.xml')) }


    it "status unavailable" do
      params = { "_status" => "ready", "datacite" => datacite }.to_anvl
      params_update = { "_status" => "unavailable | withdrawn by magic", "datacite" => datacite }.to_anvl
      post "/id/doi:#{doi}", params, headers
      post "/id/doi:#{doi}", params_update, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5438/bc11-cqw8")
      #expect(response["_target"]).to eq(url)
      expect(response["_status"]).to eq("unavailable | withdrawn by magic")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5438/BC11-CQW8")
    end

    it "status unavailable with reason" do
      params = { "_status" => "unavailable | withdrawn by author", "datacite" => datacite }.to_anvl
      params_update = { "_status" => "unavailable", "datacite" => datacite }.to_anvl
      post "/id/doi:#{doi}", params, headers
      post "/id/doi:#{doi}", params_update, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5438/bc11-cqw8")
      #expect(response["_target"]).to eq(url)
      expect(response["_status"]).to eq("unavailable")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5438/BC11-CQW8")
    end

  end
end
