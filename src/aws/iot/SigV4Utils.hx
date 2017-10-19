package aws.iot;

import haxe.io.Bytes;
import haxe.crypto.*;

using StringTools;
using DateTools;

class SigV4Utils {
	public static function getSignatureKey(key:String, date:String, region:String, service:String) {
		var hmac = new Hmac(SHA256);
		var kDate = hmac.make(Bytes.ofString('AWS4${key}'), Bytes.ofString(date));
		var kRegion = hmac.make(kDate,  Bytes.ofString(region));
		var kService = hmac.make(kRegion,  Bytes.ofString(service));
		var kCredentials = hmac.make(kService,  Bytes.ofString('aws4_request'));
		return kCredentials;
	};

	/**
	 *  Used to sign the IoT endpoint URL to establish a MQTT websocket.
	 *  @param {string} host - Our AWS IoT endpoint.
	 *  @param {string} region - Our AWS region (us-east-1).
	 *  @param {object} credentials - Current user's stored AWS.config.credentials object.
	*/
	public static function getSignedUrl(host:String, region:String, credentials:Credentials) {
		var timezoneOffset = new Date(1970,0,1,0,0,0).getTime();
		var datetime = Date.now().delta(timezoneOffset).format('%Y%m%dT%H%M%SZ');
		var date = datetime.substr(0, 8);

		var method = 'GET';
		var protocol = 'wss';
		var uri = '/mqtt';
		var service = 'iotdevicegateway';
		var algorithm = 'AWS4-HMAC-SHA256';

		var credentialScope = '${date}/${region}/${service}/aws4_request';
		var canonicalQuerystring = 'X-Amz-Algorithm=${algorithm}';
		var credentialsURI = '${credentials.accessKeyId}/${credentialScope}'.urlEncode();
		canonicalQuerystring += '&X-Amz-Credential=${credentialsURI}';
		canonicalQuerystring += '&X-Amz-Date=${datetime}';
		canonicalQuerystring += '&X-Amz-SignedHeaders=host';

		var canonicalHeaders = 'host:${host}\n';
		var payloadHash = Sha256.encode('');

		var canonicalRequest = method + '\n' + uri + '\n' + canonicalQuerystring + '\n' + canonicalHeaders + '\nhost\n' + payloadHash;

		var stringToSign = '${algorithm}\n${datetime}\n${credentialScope}\n${Sha256.encode(canonicalRequest)}';
		var signingKey = SigV4Utils.getSignatureKey(credentials.secretAccessKey, date, region, service);
		var signature = new Hmac(SHA256).make(signingKey, Bytes.ofString(stringToSign)).toHex();

		canonicalQuerystring += '&X-Amz-Signature=${signature}';
		if (credentials.sessionToken != null) {
			canonicalQuerystring += '&X-Amz-Security-Token=${credentials.sessionToken.urlEncode()}';
		}

		var requestUrl = '${protocol}://${host}${uri}?${canonicalQuerystring}';
		return requestUrl;
	};
}

// TODO: test
// http://docs.aws.amazon.com/general/latest/gr/signature-v4-test-suite.html