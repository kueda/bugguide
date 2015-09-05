require 'test_helper'

# http://docs.seattlerb.org/minitest/Minitest/Expectations.html
describe BugGuide::Taxon do
  describe "name parsing" do
    it "should set scientific name to name by default" do
      t = BugGuide::Taxon.new(name: 'Trichocnemis spiculatus')
      t.scientific_name.must_equal 'Trichocnemis spiculatus'
    end
    it "should parse scientific name from name with parens" do
      t = BugGuide::Taxon.new(name: "Trichocnemis spiculatus (Ponderous Borer)")
      t.scientific_name.must_equal 'Trichocnemis spiculatus'
    end
    it "should parse common name from name with parens" do
      t = BugGuide::Taxon.new(name: "Trichocnemis spiculatus (Ponderous Borer)")
      t.common_name.must_equal 'Ponderous Borer'
    end
    it "should remove the word 'subgenus' from scientific name" do
      t = BugGuide::Taxon.new(name: 'subgenus Prionus lecontei (Prionus lecontei)')
      t.scientific_name.must_equal 'Prionus lecontei'
    end
    it "should not set a subgenus as the common name" do
      t = BugGuide::Taxon.new(name: 'subgenus Prionus lecontei (Prionus lecontei)')
      t.common_name.wont_equal 'Prionus lecontei'
    end
  end
  describe "search" do
    it "should return BugGuide::Taxon object" do
      BugGuide::Taxon.search('ants').first.must_be_instance_of BugGuide::Taxon
    end
    it "should include an exact match" do
      exact = BugGuide::Taxon.search('ants').detect{|t| t.name == 'Formicidae'}
      exact.wont_be :blank?
    end
  end
end