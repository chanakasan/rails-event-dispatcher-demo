class DiContainer
  MissingItemError = Class.new(StandardError)
  NoBlockGivenError = Class.new(StandardError)
  DuplicateItemError = Class.new(StandardError)
  EnvironmentVariableNotFound = Class.new(StandardError)

  def initialize
    @items = {}
    @cache = {}
  end

  # Register a item named +name+.  The +block+ will be used to
  # create the item on demand.  It is recommended that symbols be
  # used as the name of a item.
  def register(name, &block)
    if @items[name]
      fail DuplicateItemError, "Duplicate Item Name '#{name}'"
    end
    if !block_given?
      fail NoBlockGivenError, "No block given to register '#{name}'"
    end
    @items[name] = block
  end

  # Lookup a item from ENV variables;
  def register_env(name)
    if value = ENV[name.to_s.upcase]
      register(name) { value }
    else
      raise EnvironmentVariableNotFound, "Could not find an ENV variable named #{name.to_s.upcase}"
    end
  end

  # Lookup a item by name.  Throw an exception if no item is
  # found.
  def [](name)
    @cache[name] ||= item_block(name).call(self)
  end

  # Return the block that creates the named item.  Throw an
  # exception if no item creation block of the given name can be
  # found.
  def item_block(name)
    @items[name] || fail(MissingItemError, "Unknown Item '#{name}'")
  end

  # Resets the cached items
  def clear_cache!
    @cache = {}
  end

  def register_events(events)
    ed = self[:event_dispatcher]
    events.each do |name, klass|
      self.register(name.to_sym) {
        ed.bind_event(klass)
      }
    end
  end

  def add_listener(klass, methods)
    ed = self[:event_dispatcher]
    ed.add_listener_object(klass, methods)
  end
end
