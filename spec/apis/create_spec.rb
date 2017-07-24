require "rails_helper"

describe "/id/create", :type => :api, vcr: true do
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
    put "/id/doi:#{doi}"
    expect(last_response.status).to eq(401)
    expect(last_response.body).to eq("error: you are not authorized to access this resource.")
  end
end
