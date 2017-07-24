require 'rails_helper'

describe String do
  describe "Anvl" do
    context "from_anvl" do
      it "convert" do
        str = "_status: public"
        expect(str.from_anvl).to eq("_status"=>"public")
      end

      it "escaped newlines" do
        str = "name: Josiah%0ACarberry"
        expect(str.from_anvl).to eq("name"=>"Josiah\nCarberry")
      end
    end
  end
end
