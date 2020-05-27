class Point
  attr_accessor :latitude, :longitude

  def initialize(hash)
    if hash[:type] and hash[:type] == 'Point'
      @longitude = hash[:coordinates].first
      @latitude = hash[:coordinates].last
    else
      @latitude = hash[:lat]
      @longitude = hash[:lng]
    end 
  end

  def to_hash
    { type: 'Point', coordinates: [@longitude, @latitude] }
  end
end