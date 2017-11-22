# BugGuide

Ruby gem for scraping data from [BugGuide.net](https://bugguide.net), an
excellent online community of entomologists sharing information about
terrestrial arthropods in North America. Sadly, BugGuide doesn't have an API, so
this gem is little more than a scraper focusing on their [advanced search
feature](https://bugguide.net/adv_search/bgsearch.php).

# Installation

I haven't posted this to rubygems yet, so you can just clone and install
locally:

```bash
git clone git@github.com:kueda/bugguide.git
cd bugguide
gem build bugguide.gemspec
gem install bugguide-x.x.x.gem
```

And of course bundler makes it pretty easy:

```ruby
gem 'bugguide', git: 'git@github.com:kueda/bugguide.git'
```

# Usage

## Search taxa
```ruby
BugGuide::Taxon.search('Apis mellifera').map(&:name)
["Apis mellifera", "Apis mellifera carnica", "Apis mellifera ligustica", 
  "Apis mellifera mellifera", "Apis mellifera scutellata"] 
```

## Get common names
```ruby
BugGuide::Taxon.search('Apis mellifera').map(&:common_name)
["Western Honey Bee", "Carniolan Honeybee", "Italian Honeybee", 
  "Black Honeybee", "African Honeybee"] 
```

## Get classification
```ruby
BugGuide::Taxon.search('Apis mellifera').first.ancestors.map(&:scientific_name)
["Arthropoda", "Hexapoda", "Insecta", "Hymenoptera", "Aculeata", "Apoidea", 
  "Apidae", "Apinae", "Apini", "Apis"]
BugGuide::Taxon.search('Apis mellifera').first.ancestors.map(&:rank)
["phylum", "subphylum", "class", "order", "no taxon", "no taxon", "family", 
  "subfamily", "tribe", "genus"] 
```

Note that `name` is a verbatim name from BugGuide, while `common_name` and
`scientific_name` represent attempts to parse out those kind of names
specifically. It's also worth keeping in mind that retrieving things like a
classification require an additional request to BugGuide, so if you're doing it
for multiple taxa, maybe cut them some slack and throttle your requests.


## Search photos

Since this gem is just scraping the Advanced Search results, you will get
exceptions if your search returns too many results.

```ruby
taxon = BugGuide::Taxon.search('Epinotia').first
BugGuide::Photo.search(taxon: taxon.id).map(&:thumbnail_url)
```


For more please check out the specs.

# Command line tool

Right now it only generates checklists:

```bash
> bugguide checklist Epinotia -s CA
# choose matching taxon
Found 82 photos of 15 taxa:

TAXON ID   NAME                       PHOTO ID
54501      Epinotia                   854559
185131     Epinotia albangulana       388400
579472     Epinotia albicapitana      579454
262585     Epinotia arctostaphylana   718670
452559     Epinotia castaneana        630199
725616     Epinotia cercocarpana      529759
262473     Epinotia emarginana        718673
378960     Epinotia hopkinsana        710406
241183     Epinotia kasloana          878601
723150     Epinotia nigralbana        546896
917995     Epinotia sagittana         917977
828578     Epinotia signiferana       1001290
472765     Epinotia subplicana        861801
261436     Epinotia subviridis        455558
481897     Epinotia terracoctana      458366
```

```bash
> bugguide checklist Epinotia -s CA -f csv
# choose matching taxon
TAXON ID,NAME,PHOTO ID
54501,Epinotia,854559
185131,Epinotia albangulana,388400
579472,Epinotia albicapitana,579454
262585,Epinotia arctostaphylana,718670
452559,Epinotia castaneana,630199
725616,Epinotia cercocarpana,529759
262473,Epinotia emarginana,718673
378960,Epinotia hopkinsana,710406
241183,Epinotia kasloana,878601
723150,Epinotia nigralbana,546896
917995,Epinotia sagittana,917977
828578,Epinotia signiferana,1001290
472765,Epinotia subplicana,861801
261436,Epinotia subviridis,455558
481897,Epinotia terracoctana,458366
```
