require 'rails_helper'

describe Work, vcr: true do
  context "to_anvl" do
    let(:input) { File.read(file_fixture('10.5072_bc11-cqw7.xml')) }

    subject { Work.new(doi: "10.5072/bc11-cqw7", input: input, from: "datacite") }

    it 'should convert' do
      lines = subject.hsh.to_anvl.split("\n")
      expect(lines[0]).to eq("success: doi:#{subject.doi}")
      expect(lines[2].anvlunesc).to eq("datacite: #{subject.input}")
      expect(lines[3]).to eq("_profile: datacite")
      expect(lines[5]).to eq("_export: yes")
      expect(lines[8]).to eq("_status: public")
    end
  end

  context "create", vcr: true, :order => :defined do
    let(:input) { File.read(file_fixture('10.5072_bc11-cqw7.xml')) }
    let(:target) { "https://blog.datacite.org/differences-between-orcid-and-datacite-metadata/" }
    let(:username) { ENV['MDS_USERNAME'] }
    let(:password) { ENV['MDS_PASSWORD'] }

    subject { Work.new(doi: "10.5072/bc11-cqw7", input: input, from: "datacite", target: target) }

    it 'should create' do
      message, status = subject.create_record(username: username, password: password)
      expect(status).to eq(200)
      response = message.from_anvl
      expect(response["success"]).to eq("doi:10.5072/bc11-cqw7")
      expect(response["datacite"]).to eq(subject.input)
      expect(response["_target"]).to eq(subject.target)
      expect(response["_status"]).to eq("reserved")
    end

    it 'should update' do
      message, status = subject.update_record(username: username, password: password)
      expect(status).to eq(200)
      response = message.from_anvl
      expect(response["success"]).to eq("doi:10.5072/bc11-cqw7")
      expect(response["datacite"]).to eq(subject.input)
      expect(response["_target"]).to eq(subject.target)
      expect(response["_status"]).to eq("reserved")
    end

    it 'should delete' do
      message, status = subject.delete_record(username: username, password: password)
      expect(status).to eq(200)
      response = message.from_anvl
      expect(response["success"]).to eq("doi:10.5072/bc11-cqw7")
      expect(response["datacite"]).to eq(subject.input)
      expect(response["_target"]).to eq(subject.target)
    end
  end
end
