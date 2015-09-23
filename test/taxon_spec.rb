#encoding: utf-8
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
    it "should parse scientific name from group name" do
      t = BugGuide::Taxon.new(name: "fusca group subsericea (Formica subsericea)")
      t.scientific_name.must_equal 'Formica subsericea'
    end
    it "should parse names from name with parens and hyphen" do
      t = BugGuide::Taxon.new(name: "Trichocnemis (Big-headed Borers)")
      t.common_name.must_equal 'Big-headed Borers'
      t.scientific_name.must_equal 'Trichocnemis'
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
    it "should return taxa with URLs" do
      t = BugGuide::Taxon.search('ants').first
      t.url.must_match /bugguide\.net.+#{t.id}/
    end
  end

  describe "find" do
    before do
      @taxon = BugGuide::Taxon.find(3080) # Apis mellifera
    end
    it "should load a name" do
      @taxon.name.wont_be_nil
    end
    it "should load a scientific_name" do
      @taxon.scientific_name.must_equal 'Apis mellifera'
    end
    it "should load a common_name" do
      @taxon.common_name.wont_be_nil
    end
    it "should load a rank" do
      @taxon.rank.must_equal 'species'
    end
  end

  describe "ancestors" do
    before do
      @taxon = BugGuide::Taxon.new(id: 185, name: 'Bombyliidae')
    end
    it "should order them from highest to lowest" do
      @taxon.ancestors.first.scientific_name.must_equal "Arthropoda"
      @taxon.ancestors.last.scientific_name.must_equal "Asiloidea"
    end
    it "should consist of Taxon objects" do
      @taxon.ancestors.first.must_be_instance_of BugGuide::Taxon
    end
    it "should return objects with ranks" do
      @taxon.ancestors.first.rank.must_equal 'phylum'
    end
    it "should strip out extraneous stuff from names" do
      names = BugGuide::Taxon.search('Apis mellifera').first.ancestors.map(&:scientific_name)
      names.detect{|n| n =~ /\s-\s/}.must_be_nil
    end
  end

  describe "with DarwinCore compliance" do
    before do
      @taxon = BugGuide::Taxon.new(id: 185, name: 'Bombyliidae')
      @taxon.ancestors
    end

    it "should respond to taxonRank" do
      @taxon.taxonRank.must_equal 'family'
    end

    it "should respond to higherClassification" do
      @taxon.higherClassification.split('|').size.must_be :>, 0
    end
  end
end
