module ExceptionNotification
	class Rack
		def initialize_temp(app,options = {})
			ActiveRecord::Base.connection.execute("UNLOCK TABLES")
			initialize_orig(app,options = {})
		end
		alias_method :initialize_orig, :initialize
		alias_method :initialize, :initialize_temp
	end
end