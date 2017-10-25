package aws.iot;

import mqtt.*;
import mqtt.Client;
import mqtt.clients.ReactNativePahoClient;
import tink.Chunk;

using tink.CoreApi;

class Mqtt extends BaseClient {
	var getConfig:Void->Promise<{endpoint:String, clientId:String, region:String, credentials:Credentials, topics:Array<String>}>;
	var client:Client;
	
	public function new(getConfig) {
		super();
		this.getConfig = getConfig;
	}
	
	override function connect():Promise<Noise> {
		if(client != null) return new Error('Already connected');
		
		return getConfig()
			.next(function(config) {
				var url = SigV4Utils.getSignedUrl(config.endpoint, config.region, config.credentials);
				client = new ReactNativePahoClient({
					uri: url, 
					clientId: config.clientId,
					storage: react.native.api.AsyncStorage,
					useSSL: true,
					timeout: 30000,
					mqttVersion: 4,
				});
				client.isConnected.bind(isConnectedState.set);
				client.message.handle(messageTrigger.trigger);
				client.error.handle(errorTrigger.trigger);
				
				for(topic in config.topics) subscribe(topic);
				return client.connect();
			});
	}
	
	override function subscribe(topic:String, ?options:SubscribeOptions):Promise<QoS>
		return whenConnected(function() return client.subscribe(topic, options));
	
	override function unsubscribe(topic:String):Promise<Noise>
		return whenConnected(function() return client.unsubscribe(topic));
	
	override function publish(topic:String, message:Chunk, ?options:PublishOptions):Promise<Noise>
		return whenConnected(function() return client.publish(topic, message, options));
	
	override function close(?force:Bool):Future<Noise>
		return whenConnected(function() return client.close(force));
		
	function whenConnected<T>(f:Void->Future<T>):Future<T>
		return isConnected.nextTime({butNotNow: false}, function(v) return v)
			.flatMap(function(_) return f());
}