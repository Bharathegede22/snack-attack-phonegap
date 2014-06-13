class DevelopmentMailInterceptor
  def self.delivering_email(message)
    message.subject = "[#{message.to}] #{message.subject}"
    message.to = MAIL_INTERCEPTOR
    message.content_type = "text/html"
  end
end
