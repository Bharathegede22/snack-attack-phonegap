module ExceptionNotifier
  class << self
    def notify_exception_temp(exception, options={})
    	ActiveRecord::Base.connection.execute("UNLOCK TABLES")
    	notify_exception_orig(exception, options={})
    end
    alias_method :notify_exception_orig, :notify_exception
		alias_method :notify_exception, :notify_exception_temp
  end
end
