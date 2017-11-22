package aws.iot;

import mqtt.*;
import mqtt.Config;
import mqtt.Client;
import tink.Chunk;

using tink.CoreApi;

typedef Config = {endpoint:String, clientId:String, region:String, credentials:Credentials, topics:Array<String>};

class Mqtt extends BaseClient {
	var client:Client;
	
	public function new(getIotConfig:Void->Promise<Config>, getClient:ConfigGenerator->Client) {
		super(null);
		client = getClient(function() return getIotConfig().next(function(config):mqtt.Config {
			return {
				uri: SigV4Utils.getSignedUrl(config.endpoint, config.region, config.credentials),
				clientId: config.clientId,
				topics: config.topics,
			}
		}));
		client.isConnected.bind(isConnectedState.set);
		client.message.handle(messageTrigger.trigger);
		client.error.handle(errorTrigger.trigger);
	}
	
	override function connect():Promise<Noise> {
		return client.connect();
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