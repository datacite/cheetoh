require "rails_helper"

describe "/id/show", :type => :api, vcr: true do
  it "show doi and metadata" do
    doi = "10.5438/mcnv-ga6n"

    puts ActionController::HttpAuthentication::Basic.encode_credentials(ENV['MDS_USERNAME'], ENV['MDS_PASSWORD']) + "L"
    puts Base64.strict_encode64("#{ENV['MDS_USERNAME']}:#{ENV['MDS_PASSWORD']}") + "L"
    puts Base64.encode64("#{ENV['MDS_USERNAME']}:#{ENV['MDS_PASSWORD']}").rstrip + "L"

    get "/id/doi:#{doi}"
    expect(last_response.status).to eq(200)
    response = last_response.body
    hsh = response.from_anvl
    expect(hsh["success"]).to eq("doi:10.5438/mcnv-ga6n")
    expect(hsh["_updated"]).to eq("1511347819")
    expect(hsh["_target"]).to eq("https://blog.datacite.org/re3data-webinar-and-datacite-en-avant/")
    expect(hsh["datacite"]).to start_with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<resource xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://datacite.org/schema/kernel-4\"")
    expect(hsh["_profile"]).to eq("datacite")
    expect(hsh["_datacenter"]).to eq("DATACITE.DATACITE")
    expect(hsh["_export"]).to eq("yes")
    expect(hsh["_created"]).to eq("1482162417")
    expect(hsh["_status"]).to eq("public")
  end

  it "bibtex format" do
    doi = "10.5438/mcnv-ga6n"
    params = { "_profile" => "bibtex" }

    get "/id/doi:#{doi}", params
    expect(last_response.status).to eq(200)
    response = last_response.body
    hsh = response.from_anvl
    expect(hsh["success"]).to eq("doi:10.5438/mcnv-ga6n")
    expect(hsh["_updated"]).to eq("1511347819")
    expect(hsh["_target"]).to eq("https://blog.datacite.org/re3data-webinar-and-datacite-en-avant/")
    expect(hsh["datacite"]).to start_with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<resource xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://datacite.org/schema/kernel-4\"")
    expect(hsh["bibtex"]).to start_with("@article{https://doi.org/10.5438/mcnv-ga6n")
    expect(hsh["_profile"]).to eq("bibtex")
    expect(hsh["_datacenter"]).to eq("DATACITE.DATACITE")
    expect(hsh["_export"]).to eq("yes")
    expect(hsh["_created"]).to eq("1482162417")
    expect(hsh["_status"]).to eq("public")
  end

  it "not public" do
    doi = "10.5072/0000-03wd"
    get "/id/doi:#{doi}"
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("error: bad request - no such identifier")
  end

  it "missing valid doi parameter" do
    doi = "20.5072/0000-03vc"
    put "/id/doi:#{doi}"
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("error: bad request - no such identifier")
  end

  it "not found" do
    get "/id/x"
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("error: bad request - no such identifier")
  end
end
