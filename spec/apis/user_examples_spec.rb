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
  
  context "ual" do
    let(:doi) { "10.21967/fk2-qscw-y487" }
    
    # see spec/fixtures/files/ual-update.txt#4 
    # datacite.resourcetype: Text/Book
    # This should be valid according to https://ezid.cdlib.org/doc/apidoc.html#profile-datacite
    # 
    # > The general type and, optionally, specific type of the data. The general type must be one of the controlled vocabulary terms defined in the DataCite Metadata Scheme:
    # > ...
    # > Specific types are unconstrained. If a specific type is given, it must be separated from the general type by a forward slash ("/")
    # 
    # It doesn't look like this is being parsed appropriately before being sent on to https://api.test.datacite.org/
    # ```
    # {
    #   "data": {
    #     "attributes": {
    #       "resource_type_general": "Text/Book"
    #     },
    #     "relationships": {
    #       "resource-type": {
    #         "data": {
    #           "type": "resource-types",
    #           "id": "text/book"
    #         }
    #       }
    #     }
    #   }
    # }
    # ```
    # so the response is 422
    # with the error message 'found unpermitted parameter: :resource_type_general'
    # more details in spec/files/vcr_cassettes/user_examples/ual/update_title_change.yml
    it "update title change" do
      str = File.read(file_fixture('ual-update.txt')).from_anvl
      params = str.to_anvl
      post "/id/doi:#{doi}", params, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.21967/fk2-qscw-y487")
      doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq("10.21967/FK2-QSCW-Y487")
      expect(doc.at_css("title").content).to eq("Different Title")
    end
    
    # The following two tests are similar
    # see spec/fixtures/files/ual-remove.txt#2 
    # _export: no
    # https://support.datacite.org/v1.1/reference#modify-doi references Internal Metadata
    # which I assume is https://ezid.cdlib.org/doc/apidoc.html#internal-metadata and includes `_export`
    # From this failing test and https://github.com/datacite/cheetoh/blob/master/app/controllers/dois_controller.rb#L197-L210
    # it looks like _export is not considered
    # more details in spec/files/vcr_cassettes/user_examples/ual/update_for_removal.yml
    it "update for removal" do
      str = File.read(file_fixture('ual-remove.txt')).from_anvl
      params = str.to_anvl
      post "/id/doi:#{doi}", params, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.21967/fk2-qscw-y487")
      expect(response["_status"]).to eq("unavailable | withdrawn")
      expect(response["_export"]).to eq("no")
    end
    
    it "update for being made private" do
      str = File.read(file_fixture('ual-private.txt')).from_anvl
      params = str.to_anvl
      post "/id/doi:#{doi}", params, headers
      expect(last_response.status).to eq(200)
      response = last_response.body.from_anvl
      expect(response["success"]).to eq("doi:10.21967/fk2-qscw-y487")
      expect(response["_target"]).to eq(str[:_target])
      expect(response["_status"]).to eq("unavailable | not publicly released")
      expect(response["_export"]).to eq("no")
    end
    
  end
end