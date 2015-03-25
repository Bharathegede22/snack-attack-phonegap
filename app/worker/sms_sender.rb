class SmsSender
  include Sidekiq::Worker
  def perform(phone, msg, bookingid,activity = nil)
    Exotel.send_message(phone, msg, bookingid, activity)
  end
end

#TO DO => DEVICE MAILS HAS TO BE SENT VIA SIDEKIQ