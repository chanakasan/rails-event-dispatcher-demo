class TodosMailer < ApplicationMailer
  def new_todo(name)
    recipient = 'admin@example.com'
    subject = 'New Todo'
    body = "Created todo: #{name}"
    mail(to: recipient, subject: subject, body: body)
  end
end
