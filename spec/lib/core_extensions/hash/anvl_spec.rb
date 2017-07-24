require 'rails_helper'

describe Hash do
  describe "Anvl" do
    context "to_anvl" do
      it "convert" do
        hsh = { "_status" => "public" }
        expect(hsh.to_anvl).to eq("_status: public")
      end

      it "escape newlines" do
        hsh = { "name" => "Josiah\nCarberry" }
        expect(hsh.to_anvl).to eq("name: Josiah%0ACarberry")
      end
    end
  end
end
