require "rails_helper"

describe "user examples", :type => :api, vcr: true, :order => :defined do
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_ACCEPT" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  context "sbd" do
    let(:doi) { "10.5072/fk2/sbdtest/501" }

    it "create doi" do
      str = File.read(file_fixture('10.5072_fk2_sbdtest_501.txt')).from_anvl
      params = { "datacite" => str[:datacite], "_target" => str[:_target], "_status" => "reserved" }.to_anvl
      doi = "10.5072/fk2/sbdtest/501"
      put "/id/doi:#{doi}", params, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/fk2/sbdtest/501")
      expect(response["_target"]).to eq(str[:_target])
      expect(response["_status"]).to eq("reserved")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5072/FK2/SBDTEST/501")
    end

    it "delete doi" do
      doi = "10.5072/fk2/sbdtest/501"
      delete "/id/doi:#{doi}", nil, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/fk2/sbdtest/501")
      expect(response["_target"]).to eq("http://data.sbgrid.org/dataset/501")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5072/FK2/SBDTEST/501")
    end
  end

  context "uva" do
    it "create doi" do
      str = File.read(file_fixture('10.5072_fk2_test.txt')).from_anvl
      params = { "datacite" => str[:datacite], "_target" => str[:_target], "_status" => "reserved", "_number" => "1225646076" }.to_anvl
      doi = "10.5072/fk2"
      post "/shoulder/doi:#{doi}", params, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/fk2-1-4gvq-zw33")
      expect(response["_target"]).to eq(str[:_target])
      expect(response["_status"]).to eq("reserved")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5072/FK2-1-4GVQ-ZW33")
    end

    it "delete doi" do
      doi = "10.5072/fk2-1-4gvq-zw33"
      delete "/id/doi:#{doi}", nil, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/fk2-1-4gvq-zw33")
      expect(response["_target"]).to eq("http://google.com")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5072/FK2-1-4GVQ-ZW33")
    end
  end

  context "dryad" do
    it "create doi" do
      str = File.read(file_fixture('10.5072_DRYAD.B3B0T7S_1.txt')).from_anvl
      params = { "datacite" => str[:datacite], "_target" => str[:_target], "_status" => "reserved" }.to_anvl
      doi = "10.5072/DRYAD.B3B0T7S/1"
      put "/id/doi:#{doi}", params, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/dryad.b3b0t7s/1")
      expect(response["_target"]).to eq(str[:_target])
      expect(response["_status"]).to eq("reserved")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5072/DRYAD.B3B0T7S/1")
    end

    it "delete doi" do
      doi = "10.5072/DRYAD.B3B0T7S/1"
      delete "/id/doi:#{doi}", nil, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/dryad.b3b0t7s/1")
      expect(response["_target"]).to eq("http://ryan-vm.datadryad.org/resource/doi:10.5072/dryad.b3b0t7s/1")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5072/DRYAD.B3B0T7S/1")
    end
  end
end