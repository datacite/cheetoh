require 'rails_helper'

describe '/login', type: :api do
  it "login path not supported" do
    get '/login'

    expect(last_response.status).to eq(501)
    expect(last_response.body).to eq("error: one-time login and session cookies not supported by this service")
  end
end
