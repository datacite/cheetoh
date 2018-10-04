require "rails_helper"

describe "show", :type => :api, vcr: true do
  it "show doi and metadata" do
    doi = "10.24354/n296wz12m"

    get "/id/doi:#{doi}"
    expect(last_response.status).to eq(200)
    response = last_response.body
    hsh = response.from_anvl
    expect(hsh["success"]).to eq("doi:10.24354/n296wz12m")
    expect(hsh["_updated"]).to eq("1512423789")
    expect(hsh["_target"]).to eq("https://www.datacite.org")
    expect(hsh["datacite"]).to start_with("<?xml version=\"1.0\"?>\n<resource xmlns=\"http://datacite.org/schema/kernel-4\"")
    expect(hsh["_profile"]).to eq("datacite")
    expect(hsh["_datacenter"]).to eq("DATACITE.TEST")
    expect(hsh["_export"]).to eq("yes")
    expect(hsh["_created"]).to eq("1512423789")
    expect(hsh["_status"]).to eq("public")
  end

  it "bibtex format" do
    doi = "10.24354/n296wz12m"
    params = { "_profile" => "bibtex" }

    get "/id/doi:#{doi}", params
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    expect(response["success"]).to eq("doi:10.24354/n296wz12m")
    expect(response["_updated"]).to eq("1512423789")
    expect(response["_target"]).to eq("https://www.datacite.org")
    expect(response["bibtex"]).to start_with("@phdthesis{https://handle.test.datacite.org/10.24354/n296wz12m")
    expect(response["_profile"]).to eq("bibtex")
    expect(response["datacite"]).to be_nil
    expect(response["_datacenter"]).to eq("DATACITE.TEST")
    expect(response["_export"]).to eq("yes")
    expect(response["_created"]).to eq("1512423789")
    expect(response["_status"]).to eq("public")
  end

  it "schema.org format" do
    doi = "10.24354/n296wz12m"
    params = { "_profile" => "schema_org" }

    get "/id/doi:#{doi}", params
    expect(last_response.status).to eq(200)
    response = last_response.body.from_anvl
    output = JSON.parse(response["schema_org"])
    expect(response["success"]).to eq("doi:10.24354/n296wz12m")
    expect(response["_updated"]).to eq("1512423789")
    expect(response["_target"]).to eq("https://www.datacite.org")
    expect(response["_profile"]).to eq("schema_org")
    expect(response["datacite"]).to be_nil
    expect(response["_datacenter"]).to eq("DATACITE.TEST")
    expect(response["_export"]).to eq("yes")
    expect(response["_created"]).to eq("1512423789")
    expect(response["_status"]).to eq("public")

    expect(output["name"]).to eq("DOI Test")
    expect(output["author"]).to eq("@type"=>"Person", "name"=>"Tom Johnson", "givenName"=>"Tom", "familyName"=>"Johnson")
  end

  it "missing valid doi parameter" do
    doi = "20.5072/0000-03vc"
    get "/id/doi:#{doi}"
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("error: bad request - no such identifier")
  end

  it "doi not found" do
    doi = "10.5072/bc11-cqw99"
    get "/id/doi:#{doi}"
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("error: bad request - no such identifier")
  end

  it "not found" do
    get "/id/x"
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("error: bad request - no such identifier")
  end
end
