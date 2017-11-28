require 'rails_helper'

describe Work, vcr: true do
  let(:input) { "https://doi.org/10.5061/dryad.17vs2d34/1" }

  subject { Work.new(input: input, from: "datacite") }

  context "to_anvl" do
    it 'should convert' do
      lines = subject.hsh.to_anvl.split("\n")
      expect(lines[0]).to eq("success: doi:#{subject.doi}")
      expect(lines[1]).to eq("_updated: #{subject._updated}")
      expect(lines[2]).to eq("_target: #{subject.url}")
      expect(lines[3].anvlunesc).to eq("datacite: #{subject.datacite}")
      expect(lines[4]).to eq("_profile: datacite")
      expect(lines[5]).to eq("_datacenter: #{subject.client_id}")
      expect(lines[6]).to eq("_export: yes")
      expect(lines[7]).to eq("_created: #{subject._created}")
      expect(lines[8]).to eq("_status: public")
    end
  end
end
