require "rails_helper"

describe "ezid", vcr: true, :order => :defined do
  let(:ezid_url) { "https://ezid.cdlib.org" }
  let(:doi) { "10.5072/FK2" }
  let(:username) { ENV['EZID_USERNAME'] }
  let(:password) { ENV['EZID_PASSWORD'] }

  it "not found" do
    response = Maremma.get "#{ezid_url}/id/doi:#{doi}1234", accept: "text/plain"
    expect(response.status).to eq(401)
    expect(response.body).to eq("error: unauthorized")
  end

  it "missing login credentials" do
    response = Maremma.post "#{ezid_url}/shoulder/doi:#{doi}", data: "", accept: "text/plain"
    expect(response.status).to eq(401)
    expect(response.body).to eq("error: unauthorized")
  end

  it "unsupported content type" do
    response = Maremma.post "#{ezid_url}/shoulder/doi:#{doi}", data: "", accept: "application/json", username: username, password: password
    expect(response.status).to eq(401)
    expect(response.body).to eq("error: unauthorized")
  end

  it "no data" do
    response = Maremma.post "#{ezid_url}/shoulder/doi:#{doi}", data: "", accept: "text/plain; charset=UTF-8", username: username, password: password
    expect(response.status).to eq(401)
    expect(response.body).to eq("error: you are not authorized to access this resource.")
  end

  it "create new DOI" do
    datacite = File.read(file_fixture('10.5438_bc11-cqw1.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    data = { "datacite" => datacite, "_target" => url }.to_anvl
    response = Maremma.post "#{ezid_url}/shoulder/doi:#{doi}", data: data, accept: "text/plain; charset=UTF-8", username: username, password: password
    expect(response.status).to eq(200)
    response = response.body.from_anvl
    expect(response["success"]).to eq("doi:10.5438/bc11-cqw1")
    expect(response["datacite"]).to eq(datacite)
    expect(response["_target"]).to eq(url)
  end

  it "show doi and metadata" do
    doi = "10.5061/dryad.17vs2d34/1"

    response = Maremma.get "https://ezid.cdlib.org/id/doi:#{doi}", accept: "text/plain; charset=UTF-8", username: username, password: password
    expect(response.status).to eq(200)
    response = response.body
    hsh = response.from_anvl
    expect(hsh["success"]).to eq("doi:10.4124/xz7jtc6tbb.1")
    expect(hsh["_updated"]).to eq("1500649550")
    expect(hsh["_target"]).to eq("https://staging-data.mendeley.com/datasets/xz7jtc6tbb/1")
    expect(hsh["datacite"]).to start_with("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<resource xmlns=\"http://datacite.org/schema/kernel-3\"")
    expect(hsh["_profile"]).to eq("datacite")
    expect(hsh["_datacenter"]).to eq("BL.MENDELEY")
    expect(hsh["_export"]).to eq("yes")
    expect(hsh["_created"]).to eq("1500649550")
    expect(hsh["_status"]).to eq("public")
  end

  it "missing valid doi parameter" do
    doi = "20.5072/0000-03vc"
    response = Maremma.put "#{ezid_url}/id/doi:#{doi}", data: nil, accept: "text/plain; charset=UTF-8", username: username, password: password
    expect(response.status).to eq(404)
    expect(response.body).to eq("error: the resource you are looking for doesn't exist.")
  end

  it "missing login credentials" do
    response = Maremma.put "#{ezid_url}/id/doi:#{doi}", data: nil, accept: "text/plain; charset=UTF-8", username: username, password: password
    expect(response.status).to eq(401)
    expect(response.body).to eq("error: you are not authorized to access this resource.")
  end

  it "no params" do
    response = Maremma.put "#{ezid_url}/id/doi:#{doi}", data: nil, accept: "text/plain; charset=UTF-8", username: username, password: password
    expect(last_response.status).to eq(400)
    response = last_response.body.from_anvl
    expect(response["error"]).to eq("A required parameter is missing")
  end

  it "DOI already exists" do
    datacite = File.read(file_fixture('10.5438_bc11-cqw1.xml'))
    url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
    data = { "datacite" => datacite, "_target" => url }.to_anvl
    doi = "10.5072/FK211cqw1"
    response = Maremma.put "#{ezid_url}/id/doi:#{doi}", data: data, accept: "text/plain", username: username, password: password
    expect(response.status).to eq(400)
    response = response.body.from_anvl
    expect(response["error"]).to eq("doi:10.5438/bc11-cqw1 has already been registered")
  end

  it "different doi in datacite xml" do
    datacite = File.read(file_fixture('10.5438_bc11-cqw1.xml'))
    params = { "datacite" => datacite }.to_anvl
    doi = "10.5072/FK211cqw4"
    response = Maremma.put "#{ezid_url}/id/doi:#{doi}", data: data, accept: "text/plain", username: username, password: password
    expect(response.status).to eq(400)
    response = response.body.from_anvl
    expect(response["error"]).to eq("params doi:10.5438/bc11-cqw4 does not match doi:10.5438/bc11-cqw1 in metadata")
  end

  # it "create new DOI" do
  #   datacite = File.read(file_fixture('10.5438_bc11-cqw6.xml'))
  #   url = "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/"
  #   params = { "datacite" => datacite, "_target" => url }.to_anvl
  #   doi = "10.5438/bc11-cqw6"
  #   put "#{ezid_url}/id/doi:#{doi}", params, headers
  #   expect(last_response.status).to eq(200)
  #   response = last_response.body.from_anvl
  #   expect(response["success"]).to eq("doi:10.5438/bc11-cqw6")
  #   expect(response["datacite"]).to eq(datacite)
  #   expect(response["_target"]).to eq(url)
  # end
end
