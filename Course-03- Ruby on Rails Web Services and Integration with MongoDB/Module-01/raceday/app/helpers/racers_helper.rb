module RacersHelper
  def toRacer(racer)
    racer.is_a?(Racer) ? racer : Racer.new(racer)
  end
end
