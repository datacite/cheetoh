require 'rails_helper'

describe Work, vcr: true do
  let(:input) { "https://doi.org/10.24354/n296wz12m" }

  subject { Work.new(input: input, from: "datacite") }

  context "validate_prefix" do
    it 'should validate' do
      str = "10.5072"
      expect(subject.validate_prefix(str)).to eq("10.5072")
    end

    it 'should validate with slash' do
      str = "10.5072/"
      expect(subject.validate_prefix(str)).to eq("10.5072")
    end

    it 'should validate with shoulder' do
      str = "10.5072/FK2"
      expect(subject.validate_prefix(str)).to eq("10.5072")
    end

    it 'should not validate if not DOI prefix' do
      str = "20.5072"
      expect(subject.validate_prefix(str)).to be_nil
    end
  end

  context "generate_random_doi" do
    it 'should generate' do
      str = "10.5072"
      expect(subject.generate_random_doi(str).length).to eq(17)
    end

    it 'should generate with seed' do
      str = "10.5072"
      number = 123456
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5072/0003-rj0r")
    end

    it 'should generate with seed checksum asterix' do
      str = "10.5072"
      number = 1234575
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5072/0015-nmf*")
    end

    it 'should generate with seed checksum tilde' do
      str = "10.5072"
      number = 1234576
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5072/0015-nmg~")
    end

    it 'should generate with seed checksum underscore' do
      str = "10.5072"
      number = 1234577
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5072/0015-nmh_")
    end

    it 'should generate with seed checksum caret' do
      str = "10.5072"
      number = 1234578
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5072/0015-nmj^")
    end

    it 'should generate with shoulder' do
      str = "10.5072/FK2"
      number = 123456
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5072/FK203rj0r")
    end

    it 'should not generate if not DOI prefix' do
      str = "20.5438"
      expect { subject.generate_random_doi(str) }.to raise_error(IdentifierError, "No valid prefix found")
    end
  end
end
