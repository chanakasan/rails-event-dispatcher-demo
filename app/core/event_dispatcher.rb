class EventDispatcher
  def initialize
    @listeners = []
    @history = []
  end

  def dispatch(event)
    validate_event(event)
    @history << event
    call_listeners(event)
  end

  def bind_event(event_klass)
    ed = self
    ->(payload) {
      ed.dispatch(event_klass.new(payload))
      nil
    }
  end

  def add_listener_object(object, methods)
    methods.each do |m|
      add_listener(object.method(m.to_sym))
    end
  end

  def add_listeners(list)
    fail "Argument to add_listeners must be an array" if !list.kind_of?(Array)
    list.map(&method(:add_listener))
  end

  def add_listener(l)
    validate_listener(l)
    @listeners << l
  end

  def call_listeners(event)
    @listeners.each do |l|
      stream = l.call(EventStream.new(event))
      stream.map(&method(:dispatch))
    end
  end

  def validate_listener(l)
    if !l.respond_to?(:call)
      fail "Listener doesn't have a call method : #{l}"
    end
  end

  def validate_event(event)
    if event.kind_of? NullEvent
      return
    end

    if !event.respond_to?(:type) && event.type.is_a?(String) && !event.respond_to?(:payload)
      fail "A listener must return a valid event object or an instance of NullEvent"
    end
  end
end
