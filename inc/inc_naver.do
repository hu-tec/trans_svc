<?
require_once 'inc_common.do';

/************************* Translation *********************/
function NAVER_Translate( $Source_Lang, $Source_Text, $Target_Lang ) {
	$log = Logger::getLogger('NAVER_Translate');

	$log->trace("Lang(".$Source_Lang.">".$Target_Lang."), Text:".$Source_Text);

	$Naver_Response = array();

	$postvars = "honorific=true&source=".$Source_Lang."&target=".$Target_Lang."&text=".urlencode($Source_Text);
	$ch = curl_init();
	curl_setopt($ch, CURLOPT_URL, "https://naveropenapi.apigw.ntruss.com/nmt/v1/translation");
	curl_setopt($ch, CURLOPT_POST, true);
	curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
	curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
	curl_setopt($ch,CURLOPT_POSTFIELDS, $postvars);

	$headers = array();
	$headers[] = "X-NCP-APIGW-API-KEY-ID: ui56lob5zl";
	$headers[] = "X-NCP-APIGW-API-KEY: RwOpdAgra0pTm7Z0vqfDGY23vvcLhxrUYpt3C2NW";
	curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

	$response = curl_exec($ch);
	$status_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
	$log->trace("status_code: ".$status_code);
	curl_close ($ch);

	if($status_code == 200) {
		$object = json_decode($response);
		$Target_Text = $object->message->result->translatedText;
		$Target_Text = preg_replace('/&quot;/', '"', $Target_Text);
		$Target_Text = preg_replace('/&#39;/', '\'', $Target_Text);
		$Target_Text = preg_replace("/\'/","\\'", $Target_Text);

		$log->trace("src:[".$Source_Lang."][".$Source_Text."]");
		$log->trace("Tgt:[".$Target_Lang."][".$Target_Text."]");
		
		$Naver_Response["isOK"] =  1;
		$Naver_Response["Target_Text"] = $Target_Text;
	} else {
		$log->ERROR($response);
		$object = json_decode($response);
		$Naver_Response["isOK"] =  0;
		$Naver_Response["ErrorCode"] = $object->errorCode; // N2MT02-지원하지 않는 source 언어, N2MT04-지원하지 않는 target 언어
		$Naver_Response["ErrorMsg"]  = $object->errorMessage;
	}
	return $Naver_Response;
}
?>
