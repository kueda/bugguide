#encoding: utf-8
#
# Represents a single taxon on BugGuide
#
# One thing to keep in mind is that this will generally be instantiated from
# search results, so for certain methods, like `ancestry`, it will need to
# perform an additional request to retrieve the relevant data.
#
# Several methods are intended for
# compatability with the DarwinCore SimpleMultimedia extention (http://rs.gbif.org/terms/1.0/Multimedia).
#
class BugGuide::Taxon
  NAME_PATTERN = /[\w\s\-\'\.]+/
  attr_accessor :id, :name, :scientific_name, :common_name, :url

  def initialize(options = {})
    options.each do |k,v|
      send("#{k}=", v)
    end
    self.url ||= "https://bugguide.net/node/view/#{id}"
  end

  def name=(new_name)
    if new_name =~ /subgenus/i
      self.scientific_name ||= new_name.gsub(/subgenus/i, '')[/[^\(]+/, 0]
    elsif matches = new_name.match(/group .*\((#{NAME_PATTERN})\)/i)
      self.scientific_name ||= matches[1]
    elsif matches = new_name.match(/(#{NAME_PATTERN}) \((#{NAME_PATTERN})\)/)
      self.scientific_name ||= matches[1]
      self.common_name ||= matches[2]
    else
      self.scientific_name ||= new_name[/[^\(]+/, 0]
    end
    @name = new_name.strip if new_name
  end

  def scientific_name=(new_name)
    @scientific_name = new_name.strip if new_name
  end

  def common_name=(new_name)
    @common_name = new_name.strip if new_name
  end

  def rank=(new_rank)
    @rank = new_rank.downcase
    @rank = nil if @rank == 'no taxon'
  end

  # Taxonomic rank, e.g. kingdom, phylum, order, etc.
  def rank
    return @rank if @rank
    @rank = taxonomy_html.css('.bgpage-roots a').last['title'].downcase
  end

  # All ancestor taxa of this taxon, or its classification if you prefer that terminology.
  def ancestors
    return @ancestors if @ancestors
    @ancestors = []
    nbsp = Nokogiri::HTML("&nbsp;").text
    @ancestors = taxonomy_html.css('.bgpage-roots a').map do |a|
      next unless a['href'] =~ /node\/view\/\d+\/tree/
      t = BugGuide::Taxon.new(
        id: a['href'].split('/')[-2],
        name: a.text.gsub(nbsp, ' '),
        url: a['href'],
        rank: a['title']
      )
      if name_matches = t.name.match(/(#{NAME_PATTERN})\s+\((#{NAME_PATTERN})\)/)
        t.common_name = name_matches[1]
        t.scientific_name = name_matches[2]
      elsif name_matches = t.name.match(/(#{NAME_PATTERN})\s+\-\s+(#{NAME_PATTERN})/)
        t.common_name = name_matches[2]
        t.scientific_name = name_matches[1]
      end
      next if t.scientific_name == scientific_name
      t
    end.compact
  end

  # HTML source of the taxon's taxonomy page on BugGuide as a Nokogiri document
  def taxonomy_html
    return @taxonomy_html if @taxonomy_html
    open("https://bugguide.net/node/view/#{id}/tree") do |response|
      @taxonomy_html = Nokogiri::HTML(response.read)
    end
  end

  # Search for taxa, returns matching BugGuide::Taxon instances
  def self.search(name, options = {})
    # For reference, https://bugguide.net/adv_search/taxon.php?q=Sphecidae returns
    # 117327||Apoid Wasps (Apoidea)- traditional Sphecidae|2302 135|Sphecidae|Thread-waisted Wasps|2700 
    url = "https://bugguide.net/adv_search/taxon.php?q=#{URI.escape(name)}"
    headers = options[:headers] || {}
    f = open(url)
    taxa = []
    open(url, headers) do |f|
      f.read.split("\n").each do |row|
        row = row.split('|').compact.map(&:strip)
        taxa << BugGuide::Taxon.new(
          id: row[0], 
          name: row[1], 
          scientific_name: row[1], 
          common_name: row[2]
        )
      end
    end
    taxa
  end

  # Find a single BugGuide taxon given its node ID
  def self.find(id)
    taxon = BugGuide::Taxon.new(id: id)
    taxon.name = taxon.taxonomy_html.css('.node-title h1').text
    taxon.scientific_name = taxon.taxonomy_html.css('.node-title i').text
    taxon.common_name = taxon.taxonomy_html.css('.node-title').text.split('-').last
    taxon
  end

  # DarwinCore mapping

  # DarwinCore-compliant taxon ID
  alias_method :taxonID, :id

  # DarwinCore-compliant scientific name
  alias_method :scientificName, :scientific_name

  # DarwinCore-compliant common name
  alias_method :vernacularName, :common_name

  # DarwinCore-compliant rank
  alias_method :taxonRank, :rank

  # DarwinCore-compliant taxonomic classification
  def higherClassification
    ancestors.map(&:scientific_name).join(' | ')
  end

end
