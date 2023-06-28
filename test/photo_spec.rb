require 'test_helper'

describe BugGuide::Photo do

  describe "search" do
    before do
      @user_id_kueda = 17693
      @taxon_id_lepidoptera = 57
      @taxon_id_epinotia = 54501
      @taxon_id_cerambycidae = 171
      @photo_id_kueda_epinotia = 854559
      @photo_id_dwilson_epinotia = 1041479
      @photo_id_kueda_therevidae = 1125058
      @photo_id_kueda_cerambycidae_ct = 785454
      @photo_id_kueda_cerambycidae_ca = 931268
      @photo_id_kueda_chrysomela_immature = 859374
      @photo_id_kueda_promyrmekiaphila_male = 856869
      @photo_id_kueda_anastranglia_female = 645681
    end

    it "should return Photo objects" do
      results = BugGuide::Photo.search(user: @user_id_kueda)
      _(results.first).must_be_instance_of BugGuide::Photo
    end
    it "should if no parameters specified" do
      _(proc { BugGuide::Photo.search }).must_raise BugGuide::NoParametersException
    end
    it "should raise an exception if too many results" do
      _(proc {
        BugGuide::Photo.search(taxon: @taxon_id_lepidoptera)
      }).must_raise BugGuide::TooManyResultsException
    end

    it "should filter by user ID" do
      results = BugGuide::Photo.search(user: @user_id_kueda, taxon: @taxon_id_epinotia)
      _(results.map(&:id)).must_include @photo_id_kueda_epinotia
      _(results.map(&:id)).wont_include @photo_id_dwilson_epinotia
    end
    it "should filter by taxon ID" do
      results = BugGuide::Photo.search(user: @user_id_kueda, taxon: @taxon_id_epinotia)
      _(results.map(&:id)).must_include @photo_id_kueda_epinotia
      _(results.map(&:id)).wont_include @photo_id_kueda_therevidae
    end
    it "should filter by description" do
      results = BugGuide::Photo.search(user: @user_id_kueda, description: "hanging out on a rock near a stream")
      _(results.map(&:id)).must_include @photo_id_kueda_therevidae
      _(results.map(&:id)).wont_include @photo_id_kueda_epinotia
    end
    it "should filter by month" do
      results = BugGuide::Photo.search(user: @user_id_kueda, month: 10)
      _(results.map(&:id)).must_include @photo_id_kueda_epinotia
      _(results.map(&:id)).wont_include @photo_id_kueda_therevidae
    end
    it "should filter by state" do
      results = BugGuide::Photo.search(user: @user_id_kueda, taxon: @taxon_id_cerambycidae, location: 'CA')
      _(results.map(&:id)).must_include @photo_id_kueda_cerambycidae_ca
      _(results.map(&:id)).wont_include @photo_id_kueda_cerambycidae_ct
    end
    it "should filter by multiple states" do
      results = BugGuide::Photo.search(user: @user_id_kueda, taxon: @taxon_id_cerambycidae, location: %w(CA CT))
      _(results.map(&:id)).must_include @photo_id_kueda_cerambycidae_ca
      _(results.map(&:id)).must_include @photo_id_kueda_cerambycidae_ct
    end
    it "should filter by county" do
      results = BugGuide::Photo.search(user: @user_id_kueda, location: 'CA', county: 'Alameda')
      _(results.map(&:id)).must_include @photo_id_kueda_cerambycidae_ca
      _(results.map(&:id)).wont_include @photo_id_kueda_therevidae
    end
    it "should filter by city" do
      results = BugGuide::Photo.search(user: @user_id_kueda, location: 'CA', city_location: 'Knowland Park, Oakland')
      _(results.map(&:id)).must_include @photo_id_kueda_cerambycidae_ca
      _(results.map(&:id)).wont_include @photo_id_kueda_therevidae
    end
    it "should filter by adult" do
      results = BugGuide::Photo.search(user: @user_id_kueda, location: 'CA', adult: true)
      _(results.map(&:id)).must_include @photo_id_kueda_therevidae
      _(results.map(&:id)).wont_include @photo_id_kueda_chrysomela_immature
    end
    it "should filter by immature" do
      results = BugGuide::Photo.search(user: @user_id_kueda, location: 'CA', immature: true)
      _(results.map(&:id)).must_include @photo_id_kueda_chrysomela_immature
      _(results.map(&:id)).wont_include @photo_id_kueda_therevidae
    end
    it "should filter by male" do
      results = BugGuide::Photo.search(user: @user_id_kueda, location: 'CA', male: true)
      _(results.map(&:id)).must_include @photo_id_kueda_promyrmekiaphila_male
      _(results.map(&:id)).wont_include @photo_id_kueda_anastranglia_female
    end
    it "should filter by female" do
      results = BugGuide::Photo.search(user: @user_id_kueda, location: 'CA', female: true)
      _(results.map(&:id)).wont_include @photo_id_kueda_promyrmekiaphila_male
      _(results.map(&:id)).must_include @photo_id_kueda_anastranglia_female
    end
    it "should URI escape bad queries" do
      results = BugGuide::Photo.search(description: 'Elachista new #2 blk, 3 silvery wht')
      _(results).must_be_empty
    end
  end
end
