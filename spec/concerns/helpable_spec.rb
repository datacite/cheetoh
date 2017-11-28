require 'rails_helper'

describe Work, vcr: true do
  let(:input) { "https://doi.org/10.5061/dryad.17vs2d34/1" }

  subject { Work.new(input: input, from: "datacite") }

  context "validate_prefix" do
    it 'should validate' do
      str = "10.5438"
      expect(subject.validate_prefix(str)).to eq("10.5438")
    end

    it 'should validate with slash' do
      str = "10.5438/"
      expect(subject.validate_prefix(str)).to eq("10.5438")
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
      str = "10.5438"
      expect(subject.generate_random_doi(str).length).to eq(17)
    end

    it 'should generate with seed' do
      str = "10.5438"
      number = 123456
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5438/0003-rj0r")
    end

    it 'should generate with shoulder' do
      str = "10.5438/FK2"
      number = 123456
      expect(subject.generate_random_doi(str, number: number)).to eq("10.5438/FK203rj0r")
    end

    it 'should not generate if not DOI prefix' do
      str = "20.5438"
      expect { subject.generate_random_doi(str) }.to raise_error(IdentifierError, "No valid prefix found")
    end
  end
end
