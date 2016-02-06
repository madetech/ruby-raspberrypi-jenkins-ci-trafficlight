require "rubygems"
require "active_support"
require "active_support/core_ext/numeric/time"
require "net/https"
require "uri"
require "json"
require 'retry_block'
require "pi_piper"
require "./config.rb"

class Jenkins
  USERNAME = Config::USERNAME
  PASSWORD = Config::PASSWORD
  MAX_BACKOFF_ELAPSE = 5.minutes.to_i
  JENKINS_JSON_URL = "#{Config::SERVER_URL}/api/json"
  MAX_BACKOFF_ATTEMPTS = 30

  def self.get_api_json
    backoff = lambda do |attempt|
      raise if attempt > MAX_BACKOFF_ATTEMPTS
      sleep_time = [MAX_BACKOFF_ELAPSE, 2**(attempt-1)].min
      sleep sleep_time
    end

    retry_block(:do_not_catch => Interrupt, :fail_callback => backoff) do |attempt|
      uri = URI.parse(JENKINS_JSON_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(USERNAME, PASSWORD)
      response = http.request(request)
      response.body
    end
  end

  def self.get_status_count(jobs, regex)
    count = 0
    jobs.each do |job|
      count+=1 if (job["color"].match(regex))
    end
    count
  end

  def self.failing_count(jobs)
    self.get_status_count(jobs, /yellow|yellow_anime|red|red_anime/)
  end

  def self.building_count(jobs)
    self.get_status_count(jobs, /blue_anime|yellow_anime|red_anime/)
  end

  def self.passing_count(jobs)
    self.get_status_count(jobs, /blue|blue_anime/)
  end

  def self.disabled_count(jobs)
    self.get_status_count(jobs, /grey|disabled/)
  end

  def self.get_metrics
    json = JSON.parse(self.get_api_json)

    {
      :building => self.building_count(json["jobs"]),
      :disabled => self.disabled_count(json["jobs"]),
      :failing => self.failing_count(json["jobs"]),
      :passing => self.passing_count(json["jobs"])
    }
  end
end

class TrafficLight
  def self.get_colours
    jenkins = Jenkins::get_metrics

    {
      :red => (true if jenkins[:failing] > 0),
      :amber => (true if jenkins[:building] > 0),
      :green => (true unless jenkins[:failing] > 0)
    }
  end
end

class RaspberryPi
  SLEEP_TIME = 5.minutes
  BLINK_INTERVAL = 1.second
  NUMBER_OF_FLASHES = SLEEP_TIME / (BLINK_INTERVAL * 2)
  RED_PIN_NUMBER = 1
  AMBER_PIN_NUMBER = 2
  GREEN_PIN_NUMBER = 3

  def self.show_fail(pins)
    pins[:red].on
    pins[:amber].off
    pins[:green].off

    sleep SLEEP_TIME.to_i
  end

  def self.show_fail_building(pins)
    pins[:red].on
    pins[:amber].off
    pins[:green].off

    NUMBER_OF_FLASHES.times do
      pins[:amber].on
      sleep BLINK_INTERVAL.to_i
      pins[:amber].off
      sleep BLINK_INTERVAL.to_i
    end
  end

  def self.show_pass(pins)
    pins[:red].off
    pins[:amber].off
    pins[:green].on

    sleep SLEEP_TIME.to_i
  end

  def self.show_pass_building(pins)
    pins[:red].off
    pins[:amber].off
    pins[:green].on

    NUMBER_OF_FLASHES.times do
      pins[:amber].on
      sleep BLINK_INTERVAL.to_i
      pins[:amber].off
      sleep BLINK_INTERVAL.to_i
    end
  end
end

pins = {
  :red => PiPiper::Pin.new(:pin => RaspberryPi::RED_PIN_NUMBER, :direction => :out),
  :amber => PiPiper::Pin.new(:pin => RaspberryPi::AMBER_PIN_NUMBER, :direction => :out),
  :green => PiPiper::Pin.new(:pin => RaspberryPi::GREEN_PIN_NUMBER, :direction => :out)
}

loop do
  colours = TrafficLight::get_colours

  if colours[:red] and colours[:amber]
    RaspberryPi::show_fail_building(pins)
  elsif colours[:green] and colours[:amber]
    RaspberryPi::show_pass_building(pins)
  elsif colours[:green]
    RaspberryPi::show_pass(pins)
  else
    RaspberryPi::show_fail(pins)
  end
end
