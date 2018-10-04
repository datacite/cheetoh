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

      it "anvl file" do
        str = File.read(file_fixture('ieee.txt'))
        expect(str.from_anvl["_target"]).to eq("https://ieee-dataport.org/documents/dataset-nuclei-segmentation-based-tripple-negative-breast-cancer-patients")
        expect(str.from_anvl["datacite.resourcetype"]).to eq("Dataset")
      end
    end
  end
end
