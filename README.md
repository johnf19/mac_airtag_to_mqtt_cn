# mac_airtag_to_mqtt
## This is a script that link your airtag(or apple find_my device) to mqtt server, which can futher connect to smart home like Homeassistant. This brench version is suitable to user who lives in China Mainland( or your local map service provider uses gcj02 coordinates).
## 这是一个将您的airtag（或Apple find_my 设备）链接到mqtt 服务器的脚本，该服务器可以进一步连接到Homeassistant 等智能家居。 此分支版本适合居住在中国大陆的用户（或您当地的地图服务提供商使用gcj02坐标）。


Fetches AirTag data from `~/Library/Caches/com.apple.findmy.fmipcore/Items.data`, creates entities in Home Assistant with location data via [MQTT Discovery](https://www.home-assistant.io/integrations/mqtt/#mqtt-discovery).

## Running in the background

You will probably need to adjust the shebang at the top of `mac_airtag_to_mqtt.rb` to point to your Ruby installation. (It was tricky to get rbenv to work with launchd.)

Create launchctl plist at `/Library/LaunchDaemons/com.ndbroadbent.mac_airtag_to_mqtt.plist`:

```
sed -e "s%/path/to/mac_airtag_to_mqtt%$PWD%g" mac_airtag_to_mqtt.plist | sudo tee /Library/LaunchDaemons/com.ndbroadbent.mac_airtag_to_mqtt.plist
```

Then run:

    sudo launchctl load /Library/LaunchDaemons/com.ndbroadbent.mac_airtag_to_mqtt.plist

(To stop you need to run `launchctl unload /Library/LaunchDaemons/com.ndbroadbent.mac_airtag_to_mqtt.plist`)
