require "rails_helper"

describe "login", :type => :api do
  let(:username) { ENV['MDS_USERNAME'] }
  let(:password) { ENV['MDS_PASSWORD'] }
  let(:headers) do
    { "HTTP_ACCEPT" => "text/plain",
      "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end

  it "not supported" do
    get "/login", nil, headers
    expect(last_response.status).to eq(501)
    expect(last_response.body).to eq("error: one-time login and session cookies not supported by this service")
  end
end