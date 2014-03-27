require 'rest_client'
module Exotel
  class << self
    def send_message(number, body, bookingid)
      exotel_url = "https://#{EXOTEL_SID}:#{EXOTEL_TOKEN}@twilix.exotel.in/v1/Accounts/#{EXOTEL_SID}/Sms/send.json"
      begin
      	resp = RestClient.post exotel_url, 'To' => number,'From' => 'ZOOMCR', 'Body' => body
        resp = JSON.parse(resp)
        apiid = resp['SMSMessage']['Sid']
        Sms.create!(booking_id: bookingid, message: body, phone: number, api_key: apiid)
      rescue Exception => e
        Sms.create(booking_id: bookingid, message: body, phone: number, api_key: apiid)
        ReportMailer.exotel(e, number, bookingid).deliver
      end
    end
  end
end
