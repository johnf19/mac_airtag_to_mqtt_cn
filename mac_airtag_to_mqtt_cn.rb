#!/Users/john/.rbenv/versions/3.1.2/bin/ruby
# frozen_string_literal: true

# NOTE: I couldn't figure out a nicer way to get rbenv working in the launchctl plist

require 'rubygems'
require 'bundler/setup'
require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/time'
require 'dotenv/load'
require 'mqtt'
require 'eviltransform'

MQTT_TOPIC_NAME = ENV.fetch('MQTT_TOPIC_NAME')
MQTT_TOPIC = "mac_airtag_to_mqtt_#{MQTT_TOPIC_NAME}".freeze
AIRTAGS_DATA_FILE = "/Users/#{ENV.fetch('MAC_USERNAME')}/Library/Caches/com.apple.findmy.fmipcore/Items.data".freeze

# DEBUG = true
DEBUG = false

loop do
  begin
    port = ENV.fetch('MQTT_PORT', 1883)
    puts "Connecting to MQTT broker at #{ENV.fetch('MQTT_HOST')}:#{port}..."
    client = MQTT::Client.connect(
      host: ENV.fetch('MQTT_HOST'),
      port:,
      username: ENV.fetch('MQTT_USERNAME'),
      password: ENV.fetch('MQTT_PASSWORD'),
      will_topic: "#{MQTT_TOPIC}/status",
      will_payload: 'offline',
      will_qos: 1,
      will_retain: true
    )
    puts 'Connected!'

    client.publish(
      "homeassistant/binary_sensor/#{MQTT_TOPIC}/connectivity/config",
      {
        name: 'Mac Airtag To MQTT',
        uniq_id: "#{MQTT_TOPIC}_connectivity",
        stat_t: "#{MQTT_TOPIC}/status",
        dev_cla: 'connectivity',
        pl_on: 'online',
        pl_off: 'offline',
      }.to_json
    )
    client.publish(
      "#{MQTT_TOPIC}/status",
      'online'
    )

    loop do
      puts "Reading airtags data from #{AIRTAGS_DATA_FILE}..." if DEBUG
      airtags = JSON.parse(File.read(AIRTAGS_DATA_FILE))
      puts "Publishing MQTT messages for #{airtags.count} airtags..." if DEBUG
      airtags.each do |airtag|
        state_topic = "#{MQTT_TOPIC}/#{airtag['identifier']}/state"
        json_attributes_topic = "#{MQTT_TOPIC}/#{airtag['identifier']}/attributes"
        ha_config_topic = "homeassistant/device_tracker/#{MQTT_TOPIC}_#{airtag['identifier']}/config"

        name = airtag['name']
        location = airtag['location'] || {}
        address = airtag['address'] || {}
        lat, lng = Eviltransform.gcj2wgs(location['latitude'].to_f, location['longitude'].to_f) || {}
	puts lat, lng
	#lato = location['latitude']
	#lngo = location['longitude']
	#lat, lng = Eviltransform.gcj2wgs(lato, lngo)
	name = if name.end_with?('Bud')
          "#{ENV.fetch('AIRPODS_NAME')} - #{name}"
        else
          "AirTag - #{name}"
        end

        is_home = address['streetName'] == ENV.fetch('HOME_STREET_NAME') &&
                  address['streetAddress']&.start_with?(ENV.fetch('HOME_STREET_ADDRESS'))

        puts "=> #{ha_config_topic}: #{name}" if DEBUG
        client.publish(
          ha_config_topic,
          {
            state_topic:,
            name:,
            unique_id: "#{MQTT_TOPIC}_#{airtag['identifier']}",
            payload_home: 'home',
            payload_not_home: 'not_home',
            json_attributes_topic:,
          }.to_json
        )

        client.publish(
          state_topic,
          is_home ? 'home' : 'not_home'
        )

        client.publish(
          json_attributes_topic,
          {
            latitude: lat.to_s,
            longitude: lng.to_s,
	    altitude: location['altitude'],
            gps_accuracy: location['horizontalAccuracy'],
            address: address['mapItemFullAddress'],
            device_type: 'Apple AirTag',
          }.to_json
        )
      end

      sleep 60
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
    puts 'Waiting 15 seconds before retrying...'
    sleep 15
  end
end
