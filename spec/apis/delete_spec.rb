require "rails_helper"

describe "/id/delete", :type => :api, vcr: true do
  let(:doi) { "10.5072/0000-03vc" }
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_ACCEPT" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  it "missing valid doi parameter" do
    doi = "20.5072/0000-03vc"
    put "/id/doi:#{doi}"
    expect(last_response.status).to eq(404)
    expect(last_response.body).to eq("error: the resource you are looking for doesn't exist.")
  end

  it "missing login credentials" do
    delete "/id/doi:#{doi}"
    expect(last_response.status).to eq(401)
    expect(last_response.body).to eq("error: you are not authorized to access this resource.")
  end

  it "show doi and metadata" do
    delete "/id/doi:#{doi}", nil, headers
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq("error: doi:#{doi} is not a reserved DOI")
  end
end
