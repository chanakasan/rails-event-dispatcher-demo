container = DiContainer.new
Injector = InjectorCreator.new(container)

container.register(:event_dispatcher) { EventDispatcher.new }
