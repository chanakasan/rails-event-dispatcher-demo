class EventStream
  def initialize(event)
    @event = event
  end

  def of_type(klass)
    if @event.type == klass.to_s
      [@event]
    else
      []
    end
  end
end
