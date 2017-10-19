package aws.iot;

import mqtt.clients.ReactNativePahoClient;

class Mqtt {
	public static  function connect(config:{endpoint:String, clientId:String, region:String, credentials:Credentials}) {
		var url = SigV4Utils.getSignedUrl(config.endpoint, config.region, config.credentials);
		return ReactNativePahoClient.connect({
			uri: url, 
			clientId: config.clientId,
			storage: react.native.api.AsyncStorage,
			useSSL: true,
			timeout: 30000,
			mqttVersion: 4,
		});
	}
}