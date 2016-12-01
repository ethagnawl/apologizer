require 'dotenv'
require 'telegram/bot'
require 'twilio-ruby'

Dotenv.load

class ApologizerError < StandardError; end

TWILIO_ACCOUNT_SID = ENV.fetch('TWILIO_ACCOUNT_SID') {
  raise ApologizerError.new "TWILIO_ACCOUNT_SID is required."
}

TWILIO_AUTH_TOKEN = ENV.fetch('TWILIO_AUTH_TOKEN') {
  raise ApologizerError.new "TWILIO_AUTH_TOKEN is required."
}

FROM_NUMBER = ENV.fetch('FROM_NUMBER') {
  raise ApologizerError.new "FROM_NUMBER is required."
}

TELEGRAM_TOKEN = ENV.fetch('TELEGRAM_TOKEN') {
  raise ApologizerError.new "TELEGRAM_TOKEN is required."
}

TO_NUMBERS = ENV.fetch('TO_NUMBERS') {
            raise ApologizerError.new "TO_NUMBERS are required."
          }.
          split(/,/).
          each_slice(2).
          inject({}) { |memo, (key, value)|
            memo[key] = value
            memo
          }

def apologize(name:)
  client = Twilio::REST::Client.new TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN
  from = FROM_NUMBER
  to = TO_NUMBERS.fetch(name) {
    raise ApologizerError.new "#{name}'s phone number could not be found."
  }
  url = "http://twimlets.com/echo?Twiml=%3CResponse%3E%3CSay%3ESorry+#{name}.%3C%2FSay%3E%3C%2FResponse%3E"

  client.account.calls.create(
    from: from,
    to: to,
    url: url
  )
end

Telegram::Bot::Client.run(TELEGRAM_TOKEN) do |bot|
  bot.listen do |message|
    begin
      if /^\/apologize to (.+\w)$/ =~ message.text
        apologize name: $1
      else
        raise ApologizerError.new "Unable to match message pattern."
      end
    rescue ApologizerError
      bot.api.send_message(chat_id: message.chat.id,
                           text: "Sorry, I don't know how to respond to that request.")
    end
  end
end
