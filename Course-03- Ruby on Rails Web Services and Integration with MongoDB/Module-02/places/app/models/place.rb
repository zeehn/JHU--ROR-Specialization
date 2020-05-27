class Place
  include ActiveModel::Model
  attr_accessor :id, :formatted_address, :location, :address_components

  def initialize(hash)
    @id = hash[:_id].to_s
    @address_components = []
    if !hash[:address_components].nil?
      address_components = hash[:address_components]
      address_components.each { |add| @address_components << AddressComponent.new(add) }
    end
    @formatted_address = hash[:formatted_address]
    @location = Point.new(hash[:geometry][:geolocation])
  end

  def self.mongo_client
    Mongoid::Clients.default
  end

  def self.collection
    self.mongo_client[:places]
  end

  def self.load_all(input)
    places = JSON.parse(input.read)
    collection.insert_many(places)
  end

  def self.find_by_short_name(input)
    collection.find({ 'address_components.short_name': input })
  end

  def self.to_places(input)
    places = []
    input.each do |doc| 
      places << Place.new(doc)
    end
    places
  end

  def self.find(id)
    place = collection.find(_id: BSON::ObjectId.from_string(id)).first
    if !place.nil?
      Place.new(place)
    end
  end

  def self.all(offset=0, limit=nil) 
    if !limit.nil?
      docs = collection.find.skip(offset).limit(limit)
    else
      docs = collection.find.skip(offset)
    end

    docs.map do |doc|
      Place.new(doc)
    end
  end

  def destroy
    self.class.collection.find(_id: BSON::ObjectId.from_string(@id)).delete_one
  end

  def self.get_address_components(sort=nil, offset=nil, limit=nil)
    docs_collection = [
      { :$unwind => "$address_components"},
      { :$project => {address_components: true, formatted_address: true, geometry: {geolocation: true }}}
    ]

    docs_collection << { :$sort => sort} unless sort.nil?
    docs_collection << { :$skip => offset} unless offset.nil?
    docs_collection << { :$limit => limit} unless limit.nil?

    collection.find.aggregate docs_collection
  end

  def self.get_country_names
    collection.find.aggregate([
      { :$project => { _id: false, address_components: { long_name: true, types: true }}},
      { :$unwind => "$address_components" },
      { :$unwind => "$address_components.types" },
      { :$match => { "address_components.types" => "country" }},
      { :$group => { :_id => "$address_components.long_name"}}
    ]).to_a.map do |doc|
      doc[:_id]
    end
  end

  def self.find_ids_by_country_code(country_code)
    collection.find.aggregate([
      { :$unwind => "$address_components" },
      { :$match => {
        "address_components.short_name" => country_code,
        "address_components.types" => "country"
        }
      },
      { :$group => { _id: "$_id"}},
      { :$project => { _id: true }}
    ]).to_a.map do |doc| 
      doc[:_id].to_s
    end
  end

  def self.create_indexes 
    collection.indexes.create_one("geometry.geolocation" => Mongo::Index::GEO2DSPHERE)
  end

  def self.remove_indexes 
    collection.indexes.drop_one("geometry.geolocation_2dsphere")
  end

  def self.near(point, max_meters=0)
    collection.find('geometry.geolocation' => { :$near => { :$geometry => point.to_hash, :$maxDistance => max_meters }})
  end

  def near(max_meters = 0)
    Place.to_places(Place.near(@location.to_hash, max_meters))
  end

  def photos(offset=0, limit=0)
    photos = Photo.find_photos_for_place(@id).skip(offset).limit(limit)
    photos.map do |photo| 
      Photo.new(photo)
    end
  end
end