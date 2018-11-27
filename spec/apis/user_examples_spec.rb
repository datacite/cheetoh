require "rails_helper"

describe "user examples", :type => :api, vcr: true, :order => :defined do
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_CONTENT_TYPE" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  # context "sbd" do
  #   let(:doi) { "10.5072/fk2/sbdtest/501" }

  #   it "create doi" do
  #     str = File.read(file_fixture('10.5072_fk2_sbdtest_501.txt')).from_anvl
  #     params = { "datacite" => str[:datacite], "_target" => str[:_target], "_status" => "reserved" }.to_anvl
  #     doi = "10.5072/fk2/sbdtest/501"
  #     put "/id/doi:#{doi}", params, headers
  #     expect(last_response.status).to eq(200)
  #     response = last_response.body.from_anvl
  #     expect(response["success"]).to eq("doi:10.5072/fk2/sbdtest/501")
  #     expect(response["_target"]).to eq(str[:_target])
  #     expect(response["_status"]).to eq("reserved")

  #     doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
  #     expect(doc.at_css("identifier").content).to eq("10.5072/FK2/SBDTEST/501")
  #   end

  #   it "delete doi" do
  #     doi = "10.5072/fk2/sbdtest/501"
  #     delete "/id/doi:#{doi}", nil, headers
  #     expect(last_response.body).to eq(200)
  #     response = last_response.body.from_anvl
  #     expect(response["success"]).to eq("doi:10.5072/fk2/sbdtest/501")
  #     expect(response["_target"]).to eq("http://data.sbgrid.org/dataset/501")

  #     doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
  #     expect(doc.at_css("identifier").content).to eq("10.5072/FK2/SBDTEST/501")
  #   end
  # end

  context "uva" do
    it "mint doi" do
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

  context "ieee" do
    let(:doi) { "10.5072/3mg5-tm67" }
    it "mint doi" do
      str = File.read(file_fixture('ieee.txt')).from_anvl
      params = str.merge("_number" => "122165076").to_anvl
      doi = "10.5072"
      post "/shoulder/doi:#{doi}", params, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/3mg5-tm67")
      expect(response["_target"]).to eq(str[:_target])
      expect(response["_status"]).to eq("reserved")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5072/3MG5-TM67")
    end

    it "delete minted doi" do
      delete "/id/doi:#{doi}", nil, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/3mg5-tm67")
      expect(response["_target"]).to eq("https://ieee-dataport.org/documents/dataset-nuclei-segmentation-based-tripple-negative-breast-cancer-patients")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.upcase)
    end

    it "create doi" do
      str = File.read(file_fixture('ieee.txt')).from_anvl
      params = str.merge("_number" => "122165076").to_anvl
      put "/id/doi:#{doi}", params, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/3mg5-tm67")
      expect(response["_target"]).to eq(str[:_target])
      expect(response["_status"]).to eq("reserved")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5072/3MG5-TM67")
    end

    it "delete created doi" do
      delete "/id/doi:#{doi}", nil, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/3mg5-tm67")
      expect(response["_target"]).to eq("https://ieee-dataport.org/documents/dataset-nuclei-segmentation-based-tripple-negative-breast-cancer-patients")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.upcase)
    end

    it "mint doi no status" do
      str = File.read(file_fixture('ieee_no_status.txt')).from_anvl
      params = str.merge("_number" => "122165076").to_anvl
      doi = "10.5072"
      post "/shoulder/doi:#{doi}", params, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/3mg5-tm67")
      expect(response["_target"]).to eq(str[:_target])
      expect(response["_status"]).to eq("reserved")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5072/3MG5-TM67")
    end

    it "delete doi no status" do
      delete "/id/doi:#{doi}", nil, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/3mg5-tm67")
      expect(response["_target"]).to eq("https://ieee-dataport.org/documents/dataset-nuclei-segmentation-based-tripple-negative-breast-cancer-patients")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.upcase)
    end
  end

  context "nd" do
    let(:doi) { "10.5438/fk2-3mg5-tm67" }

    it "mint doi" do
      str = File.read(file_fixture('nd.txt')).from_anvl
      params = str.merge("_number" => "122165076").to_anvl
      doi = "10.5438/FK2"
      post "/shoulder/doi:#{doi}", params, headers
      expect(last_response.status).to eq(422)
      response = last_response.body.from_anvl
      expect(response["error"]).to eq("[facet 'enumeration'] the value 'invalidresourcetype' is not an element of the set {'audiovisual', 'collection', 'datapaper', 'dataset', 'event', 'image', 'interactiveresource', 'model', 'physicalobject', 'service', 'software', 'sound', 'text', 'workflow', 'other'}. at line 4, column 0")
    end

    # it "mint doi newlines" do
    #   str = File.read(file_fixture('nd_newlines.txt'))
    #   params = str + "\n_number: 122165076"
    #   doi = "10.23725/FK2"
    #   post "/shoulder/doi:#{doi}", params, headers
    #   expect(last_response.status).to eq(422)
    #   response = last_response.body.from_anvl
    #   expect(response["error"]).to eq("Missing child element(s). expected is ( {http://datacite.org/schema/kernel-4}creator ). at line 4, column 0")
    # end
  end

  context "tamucc" do
    let(:doi) { "10.5072/4h3j-wr25" }
    it "mint doi" do
      str = File.read(file_fixture('tamucc.txt')).from_anvl
      params = str.merge("_number" => "152161176").to_anvl
      doi = "10.5072"
      post "/shoulder/doi:#{doi}", params, headers

      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/4h3j-wr25")
      expect(response["_target"]).to eq(str[:_target])
      expect(response["_status"]).to eq("reserved")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5072/4H3J-WR25")
      expect(doc.at_css("title").content).to eq("Aqueous geochemistry of Louisiana marshes, May 2015 – October 2016")
    end

    it "update doi" do
      str = File.read(file_fixture('tamucc-update.txt')).from_anvl
      params = str.to_anvl
      post "/id/doi:#{doi}", params, headers
      
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/4h3j-wr25")
      expect(response["_target"]).to eq(str[:_target])
      expect(response["_status"]).to eq("reserved")
      expect(last_response.status).to eq(200)

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5072/4H3J-WR25")
      expect(doc.at_css("title").content).to eq("RCYC Focus Groups")
    end

    it "delete doi" do
      doi = "10.5072/4h3j-wr25"
      delete "/id/doi:#{doi}", nil, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.5072/4h3j-wr25")
      expect(response["_target"]).to eq("https://data.gulfresearchinitiative.org/data/R5.x287.000:0002")

      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.5072/4H3J-WR25")
    end
  end
end