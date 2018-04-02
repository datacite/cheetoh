require 'rails_helper'

describe Work, vcr: true do
  context "get_doi" do
    it "doi exists" do
      doi = "10.5438/mcnv-ga6n"
      response = Work.get_doi(doi)
      expect(response.status).to eq(200)
      data = response.body["data"]
      expect(data.dig('attributes', 'url')).to eq("https://blog.datacite.org")
      expect(data.dig('attributes', 'doi')).to eq(doi)
      expect(data.dig('attributes', 'title')).to eq("The Man Who Wrote Pancho Villa: Martín Luis Guzmán And The Politics Of Life Writing")
      expect(data.dig('attributes', 'schema-version')).to eq("http://datacite.org/schema/kernel-3")
      expect(data.dig('attributes', 'state')).to eq("findable")

      doc = Nokogiri::XML(Base64.decode64(data.dig('attributes', 'xml')), nil, 'UTF-8', &:noblanks)
      expect(doc.at_css("identifier").content).to eq(doi.upcase)
    end

    it "doi not found" do
      doi = "10.5072/xyz"
      response = Work.get_doi(doi)
      expect(response.status).to eq(404)
      expect(response.body["errors"]).to eq([{"status"=>404, "title"=>"Not found"}])
    end
  end

  context "get_doi_by_content_type" do
    it "default content_type" do
      doi = "10.5438/mcnv-ga6n"
      response = Work.get_doi_by_content_type(doi: doi)
      expect(response.status).to eq(200)
      data = Maremma.from_xml(response.body["data"]).to_h.fetch("resource", {})
      expect(data.dig("xmlns")).to eq("http://datacite.org/schema/kernel-4")
      expect(data.dig("publisher")).to eq("Zenodo")
      expect(data.dig("titles", "title")).to eq("The Man Who Wrote Pancho Villa: Martín Luis Guzmán And The Politics Of Life Writing")
    end

    it "datacite" do
      doi = "10.5438/mcnv-ga6n"
      response = Work.get_doi_by_content_type(doi: doi, profile: "datacite")
      expect(response.status).to eq(200)
      data = Maremma.from_xml(response.body["data"]).to_h.fetch("resource", {})
      expect(data.dig("xmlns")).to eq("http://datacite.org/schema/kernel-4")
      expect(data.dig("publisher")).to eq("Zenodo")
      expect(data.dig("titles", "title")).to eq("The Man Who Wrote Pancho Villa: Martín Luis Guzmán And The Politics Of Life Writing")
    end

    it "bibtex" do
      doi = "10.5438/mcnv-ga6n"
      response = Work.get_doi_by_content_type(doi: doi, profile: "bibtex")
      expect(response.status).to eq(200)
      data = BibTeX.parse(response.body["data"]).to_a(quotes: '').first
      expect(data[:publisher]).to eq("Zenodo")
      expect(data[:title]).to eq("The Man Who Wrote Pancho Villa: Martín Luis Guzmán And The Politics Of Life Writing")
    end

    it "ris" do
      doi = "10.5438/mcnv-ga6n"
      response = Work.get_doi_by_content_type(doi: doi, profile: "ris")
      expect(response.status).to eq(200)
      data = response.body["data"].split("\r\n")
      expect(data[7]).to eq("PB - Zenodo")
      expect(data[1]).to eq("T1 - The Man Who Wrote Pancho Villa: Martín Luis Guzmán And The Politics Of Life Writing")
    end

    it "schema_org" do
      doi = "10.5438/mcnv-ga6n"
      response = Work.get_doi_by_content_type(doi: doi, profile: "schema_org")
      expect(response.status).to eq(200)
      data = JSON.parse(response.body["data"])
      expect(data.dig("schemaVersion")).to eq("http://datacite.org/schema/kernel-3")
      expect(data.dig("publisher")).to eq("@type"=>"Organization", "name"=>"Zenodo")
      expect(data.dig("name")).to eq("The Man Who Wrote Pancho Villa: Martín Luis Guzmán And The Politics Of Life Writing")
    end

    it "citeproc" do
      doi = "10.5438/mcnv-ga6n"
      response = Work.get_doi_by_content_type(doi: doi, profile: "citeproc")
      expect(response.status).to eq(200)
      data = JSON.parse(response.body["data"])
      expect(data.dig("publisher")).to eq("Zenodo")
      expect(data.dig("title")).to eq("The Man Who Wrote Pancho Villa: Martín Luis Guzmán And The Politics Of Life Writing")
    end

    it "doi not found" do
      doi = "10.5072/xyz"
      response = Work.get_doi_by_content_type(doi: doi)
      expect(response.status).to eq(404)
      expect(response.body["errors"]).to eq([{"status"=>404, "title"=>"Not found"}])
    end
  end

  context "where" do
    it "doi exists" do
      doi = "10.5438/mcnv-ga6n"
      work = Work.where(doi: doi)
      expect(work.hsh["success"]).to eq("doi:10.5438/mcnv-ga6n")
      expect(work.hsh["_datacenter"]).to eq("DATACITE.DATACITE")
      expect(work.hsh["_profile"]).to eq("datacite")
      expect(work.hsh["_status"]).to eq("public")

      data = Maremma.from_xml(work.hsh["datacite"]).to_h.fetch("resource", {})
      expect(data.dig("xmlns")).to eq("http://datacite.org/schema/kernel-4")
      expect(data.dig("publisher")).to eq("Zenodo")
      expect(data.dig("titles", "title")).to eq("The Man Who Wrote Pancho Villa: Martín Luis Guzmán And The Politics Of Life Writing")
    end

    it "doi not found" do
      doi = "10.5072/xyz"
      work = Work.where(doi: doi)
      expect(work).to be_nil
    end
  end
end