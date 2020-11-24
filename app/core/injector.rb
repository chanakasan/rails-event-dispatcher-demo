container = DiContainer.new
Injector = InjectorCreator.new(container)

container.register(:event_dispatcher) { EventDispatcher.new }
container.register_events({
  todos_create_success_event: Main::Events::TodoCreateSuccess
})

