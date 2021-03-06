module RahyabRails
  class BulkSendJob < ActiveJob::Base
    queue_as :default

    def perform(source_number, cell_numbers, text, user_id)
      source = ServiceNumber.find_by(number: source_number)
      fail "can't fetch service number by #{source_number}" if source.nil?
      api    = RahyabRails::API.new

      cell_numbers.each do |cell_number|

        unless cell_number.nil?
          message = RahyabRails::Message.new(user_id: user_id,
                                             text: text,
                                             destination: cell_number,
                                             service_number: source)

          Rails.logger.info "Send to: #{cell_number}"
          result = api.send_sms(source_number, [cell_number], text)
          Rails.logger.info "Sent: #{result}"

          if !result.nil?
            message.status = :sent

            sleep 2
            delivery = api.get_delivery(result)

            delivery = 'Failed' if delivery.nil?
            message.status = delivery

            Rails.logger.info "Delivery: #{delivery}"
          # batch  = delivery["smsStatusPollResponse"]["batch"]
          # status = batch.subnodes["sms"]["status"]
          # time   = batch.subnodes["sms"]["time"]

          # puts "Batch: #{result}  Status: #{status} Time: #{time}"
          else
            Rails.logger.warn "Send failed to: #{cell_number}"
            message.status = 'Failed to send'
          end
        end
        message.delivered_at = DateTime.now
        message.save
      end
    end
  end
end
