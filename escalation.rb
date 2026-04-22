require 'net/http'
require 'uri'
require 'json'
require 'thread'

module EscalationManager
  @mutex = Mutex.new
  @current_thread = nil

  class << self

    # ------------------------------------------------------
    # Start or reset an escalation timer
    # ------------------------------------------------------
    def schedule_abort(callback_addr)
      @mutex.synchronize do
        if @current_thread&.alive?
          Thread.kill(@current_thread)
        end

        @current_thread = Thread.new do

          sleep(120)

          # When timer ends: execute escalation
          send_escalation(callback_addr)
        end
      end
    end

    def send_escalation(callback_addr)
      uri = URI(callback_addr)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")

      req = Net::HTTP::Put.new(uri)
      req["Content-Type"] = "application/json"
      req.body = { site: "abort" }.to_json

      begin
        response = http.request(req)
        puts "[ESCALATION] PUT sent to #{callback_addr}, status=#{response.code}"
      rescue => e
        puts "[ESCALATION ERROR] #{e.message}"
      end
    end

  end
end
