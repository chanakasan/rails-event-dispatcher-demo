# Event Dispatcher Demo

## Usage

```
git clone <repo>
cd <repo>
bundle install
rails s

visit below page to see the result
http://localhost:3000/api/todos

open mailcatcher to see emails
http://localhost:1080/
```

## A little details

**TL;DR;**

* This is a simple events pub/sub pattern.
* We register events and listeners in the Di Container.
* We use bound event objects to fire events.
* We rely on dependency injection to inject bound events to classes that needs them.
* We react to events from listeners.
* A listener receives all events. So it must select the correct one to react to.


We have a DiContainer class to register dependencies or any value.
We have a Injector class that we can use to auto inject dependencies to any class like below.

```
# app/core/injector.rb

container.register(:db_connection) {|c| Db.new(c[:db_user], c[:db_pass])}
container.register(:db_user) { 'user' }
container.register(:db_pass) { 'pass' }
```

```
# my_class.rb

class MyClass
  include Injector
  use_deps :db_connection

  def get_data
    db_connection.query("select * from something")
  end
end
```

Above `use_deps :db_connection` will fetch the `db_connection` from di container and add it as a instance method on the class.

We have a EventDispatcher class with a dispatch method. But we are not going to use it directly.
Instead we are going to dispatch events using bound event objects like below.

```
# app/core/injector.rb

container.register_events({
  todos_create_success_event: Main::Events::TodoCreateSuccess
})
container.add_listener(Main::Listeners::Todos.new, [:send_new_todo_email])
```

```
TodosController
  include Injector
  use_deps :todos_create_success_event

  def update
    @todo.save
    payload = { name: @todo.name }
    todos_create_success_event(payload)
    render json: todo
  end
end
```

```
# app/modules/main/listeners/todos.rb

class Main::Listeners::Todos
  def send_new_todo_email(stream)
    stream.of_type(Main::Events::TodoCreateSuccess).map do |event|
      name = event.payload[:name]
      TodosMailer.new_todo(name).deliver_later
      NullEvent.new
    end
  end
end
```

Any registered listener will be called per every dispatched event.
A listener receives the event in a EventStream object. Which is just a container object with a `of_type` method.
We can use the `of_type` method like above to select the event we want. A listener must return a Event or a NullEvent.

The main advantage of using this pattern in a Rails app is communication between various parts of the system.
Instead of imperatively calling methods on objects and passing data to other objects.
We can dispatch an event with some data and react to it from a listener.

The DiContainer and Injector are mainly used to facilitate this event dispatching pattern. Registering all the dependencies in the DiContainer is not the idea.
Because this pattern is not about decoupling the dependencies. However the DiContainer and Injector can be used to register and then inject dependencies to any given class.

This pattern was inspired by the redux-observable library. Using this pattern helps us to go in the direction of reactive programming.
Which kind of lets us wire things in a declarative way as opposed to a imperative way.
