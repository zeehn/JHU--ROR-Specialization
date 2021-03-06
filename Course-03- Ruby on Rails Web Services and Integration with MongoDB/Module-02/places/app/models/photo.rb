class Photo 
  attr_accessor :id, :location
  attr_writer :contents


  def initialize(hash=nil)
    @id = hash[:_id].to_s unless hash.nil?
    @location = Point.new(hash[:metadata][:location]) unless hash.nil?
    @place = hash[:metadata][:place] unless hash.nil?
  end

  def self.mongo_client
    Mongoid::Clients.default
  end

  def persisted?
    !@id.nil?
  end

  def save
    if !persisted?
      gps = EXIFR::JPEG.new(@contents).gps
      location = Point.new(lng: gps.longitude, lat: gps.latitude)
      @contents.rewind
      description = {}
      description[:metadata] = {location: location.to_hash}
      description[:content_type] = "image/jpeg"
      @location = Point.new(location.to_hash)
      grid_file = Mongo::Grid::File.new(@contents.read, description)
      @id = Place.mongo_client.database.fs.insert_one(grid_file).to_s
    else
      doc = Photo.mongo_client.database.fs.find({_id: BSON::ObjectId.from_string(@id)}).first
      doc[:metadata][:place] = @place
      doc[:metadata][:location] = @location.to_hash
      Photo.mongo_client.database.fs.find({_id: BSON::ObjectId.from_string(@id)}).update_one(doc)
    end
  end

  def self.all(offset=0,limit=0)
    mongo_client.database.fs.find.skip(offset).limit(limit).map {|doc| Photo.new(doc)}
  end


  def self.find(id)
    doc = mongo_client.database.fs.find({_id: BSON::ObjectId.from_string(id)}).first
    Photo.new(doc) unless doc.nil?
  end

  def contents
    photo = Photo.mongo_client.database.fs.find_one({:_id=>BSON::ObjectId.from_string(@id)})

    if photo
      buffer = ""
      photo.chunks.reduce([]) do |x,chunk|
        buffer << chunk.data.data
      end
      return buffer
    end
  end

  def destroy
    Photo.mongo_client.database.fs.find({:_id=>BSON::ObjectId.from_string(@id)}).delete_one
  end

  def find_nearest_place_id(max_meters)
    options = { 'geometry.geolocation' => { :$near => @location.to_hash }}
    Place.collection.find(options).limit(1).projection({_id: true}).first[:_id]
  end

  def place
    Place.find(@place.to_s) unless @place.nil?
  end

  def place= object
    @place = object
    @place = BSON::ObjectId.from_string(object) if object.is_a? String
    @place = BSON::ObjectId.from_string(object.id) if object.respond_to? :id
  end

  def self.find_photos_for_place(place_id)
    if place_id.is_a?(BSON::ObjectId)
      new_id = place_id
    elsif place_id.is_a?(String)
      new_id = BSON::ObjectId.from_string(place_id.to_s)
    end
  	Photo.mongo_client.database.fs.find(:'metadata.place' => new_id)
  end
end