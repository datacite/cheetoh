require "rails_helper"

describe "ezid compatibility", :type => :api, vcr: true do
  it "show ark identifier" do
    get "/id/ark:/99999/fk4test"
    expect(last_response.status).to eq(501)
    expect(last_response.body).to eq("error: ark identifiers are not supported by this service")
  end

  it "create ark identifier" do
    put "/id/ark:/99999/fk4test"
    expect(last_response.status).to eq(501)
    expect(last_response.body).to eq("error: ark identifiers are not supported by this service")
  end

  it "update ark identifier" do
    post "/id/ark:/99999/fk4test"
    expect(last_response.status).to eq(501)
    expect(last_response.body).to eq("error: ark identifiers are not supported by this service")
  end

  it "delete ark identifier" do
    delete "/id/ark:/99999/fk4test"
    expect(last_response.status).to eq(501)
    expect(last_response.body).to eq("error: ark identifiers are not supported by this service")
  end
end
