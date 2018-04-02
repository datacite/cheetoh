require "rails_helper"

describe "random", :type => :api, vcr: true, :order => :defined do
  let(:doi) { "10.5072/0000-03vc" }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_ACCEPT" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  it "create new doi" do
    datacite = File.read(file_fixture('10.5072_tba.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    params = { "datacite" => datacite, "_target" => url }.to_anvl
    prefix = "10.5072"
    body =
    <<~HEREDOC
      {"data":{"id":"10.5072/bc11-cqw1","type":"dois","attributes":{"doi":"10.5072/bc11-cqw1","identifier":"https://handle.test.datacite.org/10.5072/bc11-cqw1","url":"https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/","author":{"type":"Person","id":"https://orcid.org/0000-0003-1419-2405", "name":"Fenner, Martin", "given-name":"Martin","family-name":"Fenner"},"title":"Differences between ORCID and DataCite Metadata","container-title":"DataCite Blog",
      "description":{"type":"Abstract","text":"One of the first tasks for DataCite in the European Commission-funded THOR project, which started in June, was to contribute to a comparison of the ORCID and DataCite metadata standards. Together with ORCID, CERN, the British Library and Dryad we looked..."},
      "resource-type-subtype":"BlogPosting","license":"https://creativecommons.org/licenses/by/4.0","version":1,"related-identifier":[{"type":"CreativeWork","id":"https://doi.org/10.5281/zenodo.30799","relation-type":"References"}],"schema-version":"http://datacite.org/schema/kernel-4","state":"draft", "published":"2015-09-18","registered":null,"updated":"2018-01-18T22:21:27.000Z"},"relationships":{"client":{"meta":{}},"provider":{"meta":{}},"resource-type":{"meta":{}},"media":{"meta":{}}}}}
    HEREDOC

    # stub API responses, as the DOI changes with every request
    stub_request(:get, /app.test.datacite.org/)
      .to_return(status: 404, body: '{"errors":[{"status":"404","title":"The resource you are looking for doesn''t exist."}]}')
    stub_request(:post, /mds.test.datacite.org\/metadata/)
      .to_return(status: 201, body: 'OK (10.5072/BC11-CQW1)')
    stub_request(:put, /mds.test.datacite.org\/doi/)
      .to_return(status: 201, body: 'OK')
    stub_request(:patch, /app.test.datacite.org/)
      .to_return(status: 200, headers: { "Content-Type" => "application/vnd.api+json; charset=utf-8" }, body: body)

    post "/shoulder/doi:#{prefix}", params, headers
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl

    puts response["datacite"]

    doc = Nokogiri::XML(response["datacite"], nil, 'UTF-8', &:noblanks)
    doi = doc.at_css("identifier").content.downcase

    expect(doi).to start_with(prefix)
    expect(response["success"]).to eq("doi:#{doi}")
    expect(response["_target"]).to eq(url)
    expect(response["_status"]).to eq("reserved")
  end
end
