class Main::Listeners::Todos
  def send_new_todo_email(stream)
    stream.of_type(Main::Events::TodoCreateSuccess).map do
      # do something
    end
  end
end
