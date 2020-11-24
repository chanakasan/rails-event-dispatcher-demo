class Main::Listeners::Todos
  def send_new_todo_email(stream)
    stream.of_type(Main::Events::TodoCreateSuccess).map do |event|
      name = event.payload[:name]
      TodosMailer.new_todo(name).deliver_later
      NullEvent.new
    end
  end
end
