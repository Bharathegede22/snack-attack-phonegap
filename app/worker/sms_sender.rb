class SmsSender
  include Sidekiq::Worker
  def perform(phone,msg,bookingid)
    Exotel.send_message(phone,msg,bookingid)
  end
end

#TO DO => DEVICE MAILS HAS TO BE SENT VIA SIDEKIQ