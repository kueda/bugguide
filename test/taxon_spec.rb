#encoding: utf-8
require 'test_helper'

# http://docs.seattlerb.org/minitest/Minitest/Expectations.html
describe BugGuide::Taxon do

  describe "name parsing" do
    it "should set scientific name to name by default" do
      t = BugGuide::Taxon.new(name: 'Trichocnemis spiculatus')
      _(t.scientific_name).must_equal 'Trichocnemis spiculatus'
    end
    it "should parse scientific name from name with parens" do
      t = BugGuide::Taxon.new(name: "Trichocnemis spiculatus (Ponderous Borer)")
      _(t.scientific_name).must_equal 'Trichocnemis spiculatus'
    end
    it "should parse common name from name with parens" do
      t = BugGuide::Taxon.new(name: "Trichocnemis spiculatus (Ponderous Borer)")
      _(t.common_name).must_equal 'Ponderous Borer'
    end
    it "should parse scientific name from group name" do
      t = BugGuide::Taxon.new(name: "fusca group subsericea (Formica subsericea)")
      _(t.scientific_name).must_equal 'Formica subsericea'
    end
    it "should parse names from name with parens and hyphen" do
      t = BugGuide::Taxon.new(name: "Trichocnemis (Big-headed Borers)")
      _(t.common_name).must_equal 'Big-headed Borers'
      _(t.scientific_name).must_equal 'Trichocnemis'
    end
    it "should remove the word 'subgenus' from scientific name" do
      t = BugGuide::Taxon.new(name: 'subgenus Prionus lecontei (Prionus lecontei)')
      _(t.scientific_name).must_equal 'Prionus lecontei'
    end
    it "should not set a subgenus as the common name" do
      t = BugGuide::Taxon.new(name: 'subgenus Prionus lecontei (Prionus lecontei)')
      _(t.common_name).wont_equal 'Prionus lecontei'
    end
  end

  describe "search" do
    it "should return BugGuide::Taxon object" do
      _(BugGuide::Taxon.search('ants').first).must_be_instance_of BugGuide::Taxon
    end
    it "should include an exact match" do
      exact = BugGuide::Taxon.search('ants').detect{|t| t.name == 'Formicidae'}
      _(exact).wont_be :blank?
    end
    it "should return taxa with URLs" do
      t = BugGuide::Taxon.search('ants').first
      _(t.url).must_match( /bugguide\.net.+#{t.id}/ )
    end
    it "should accept headers" do
      ants = BugGuide::Taxon.search('ants', "User-Agent" => "BugGuide Ruby Gem / #{BugGuide::VERSION}")
      _(ants.detect{|t| t.name == 'Formicidae'}).wont_be :blank?
    end
    it "should URI escape bad queries" do
      results = BugGuide::Taxon.search('Elachista new #2 blk, 3 silvery wht')
      _(results).must_be_empty
    end
  end

  describe "find" do
    before do
      @taxon = BugGuide::Taxon.find(3080) # Apis mellifera
    end
    it "should load a name" do
      _(@taxon.name).wont_be_nil
    end
    it "should load a scientific_name" do
      _(@taxon.scientific_name).must_equal 'Apis mellifera'
    end
    it "should load a common_name" do
      _(@taxon.common_name).wont_be_nil
    end
    it "should load a rank" do
      _(@taxon.rank).must_equal 'species'
    end
  end

  describe "ancestors" do
    before do
      @taxon = BugGuide::Taxon.new(id: 185, name: 'Bombyliidae')
    end
    it "should order them from highest to lowest" do
      _(@taxon.ancestors.first.scientific_name).must_equal "Arthropoda"
      _(@taxon.ancestors.last.scientific_name).must_equal "Asiloidea"
    end
    it "should consist of Taxon objects" do
      _(@taxon.ancestors.first).must_be_instance_of BugGuide::Taxon
    end
    it "should return objects with ranks" do
      _(@taxon.ancestors.first.rank).must_equal 'phylum'
    end
    it "should strip out extraneous stuff from names" do
      names = BugGuide::Taxon.search('Apis mellifera').first.ancestors.map(&:scientific_name)
      _(names.detect{|n| n =~ /\s-\s/}).must_be_nil
    end
  end

  describe "with DarwinCore compliance" do
    before do
      @taxon = BugGuide::Taxon.new(id: 185, name: 'Bombyliidae')
      @taxon.ancestors
    end

    it "should respond to taxonRank" do
      _(@taxon.taxonRank).must_equal 'family'
    end

    it "should respond to higherClassification" do
      _(@taxon.higherClassification.split('|').size).must_be :>, 0
    end
  end
end
