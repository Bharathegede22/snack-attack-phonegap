class InventoryLogger < Logger
  def format_message(severity, timestamp, progname, msg)
    "#{timestamp.strftime('%d/%m/%y %I:%M %p')} #{severity} #{msg}\n"
  end
end
 
logfile = File.open("#{Rails.root}/log/inventory.log", 'a')  # create log file
logfile.sync = true  # automatically flushes data to file
INVENTORY_LOGGER = InventoryLogger.new(logfile)  # constant accessible anywhere
