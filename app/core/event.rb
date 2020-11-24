class Event
  attr_reader :payload

  def initialize(payload)
    @payload = payload
  end

  def type
    self.class.to_s
  end
end
