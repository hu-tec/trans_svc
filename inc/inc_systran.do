<?
require_once 'inc_common.do';

/************************* Translation *********************/
function SYSTRAN_Translate( $Source_Lang, $Source_Text, $Target_Lang ) {
	$log = Logger::getLogger('SYSTRAN_Translate');

	$log->trace("Lang(".$Source_Lang.">".$Target_Lang."), Text:".$Source_Text);

	$Systran_Response = array();

	//////////////////////////////////////////
	$curl = curl_init();

	curl_setopt_array($curl, array(
		CURLOPT_URL => 'https://api-translate.systran.net/translation/text/translate?key=182493dd-a686-4370-8468-94e0d45a82de&source='.$Source_Lang.'&target='.$Target_Lang,
		CURLOPT_RETURNTRANSFER => true,
		CURLOPT_ENCODING => '',
		CURLOPT_MAXREDIRS => 10,
		CURLOPT_TIMEOUT => 0,
		CURLOPT_FOLLOWLOCATION => true,
		CURLOPT_HTTP_VERSION => CURL_HTTP_VERSION_1_1,
		CURLOPT_CUSTOMREQUEST => 'POST',
		CURLOPT_POSTFIELDS =>'{ "inputs": ["'.$Source_Text.'"] }',
		CURLOPT_HTTPHEADER => array('Content-Type: application/json',),
	));
	$response = curl_exec($curl);
	$status_code = curl_getinfo($curl, CURLINFO_HTTP_CODE);
	$log->trace("status_code: ".$status_code);
	curl_close($curl);
	
	$log->trace("response: ".$response);
/*
{
    "outputs": [
        {"output": "좋은 시간 보내세요."},
        {"output": "만나서 반갑습니다."}]
}
*/
	/////////////////////////////////////////

	if($status_code == 200) {
		$object = json_decode($response);
		//$log->trace("Count: ".count($object->outputs) );
		$Cnt = 0;
		$Target_Text = "";
		foreach ($object->outputs as $outputs) {
			$OneResText = $outputs->output;
			$OneResText = preg_replace('/&quot;/', '"', $OneResText);
			$OneResText = preg_replace('/&#39;/', '\'', $OneResText);

			if ( $Cnt > 0 ) $Target_Text = $Target_Text."\r\n";
			$Target_Text = $Target_Text.preg_replace("/\'/","\\'", $OneResText);
			$Cnt++;
		}

		// $Target_Text = $object->outputs[0]->output;
		// $Target_Text = preg_replace('/&quot;/', '"', $Target_Text);
		// $Target_Text = preg_replace('/&#39;/', '\'', $Target_Text);
		// $Target_Text = preg_replace("/\'/","\\'", $Target_Text);

		$log->trace("src:[".$Source_Lang."][".$Source_Text."]");
		$log->trace("Tgt:[".$Target_Lang."][".$Target_Text."]");
		
		$Systran_Response["isOK"] =  1;
		$Systran_Response["Target_Text"] = $Target_Text;
	} else {
		$log->ERROR($response);
		$Systran_Response["isOK"] =  0;
		$Systran_Response["ErrorCode"] = "ERROR";
		$Systran_Response["ErrorMsg"]  = "지원하지 않음";
	}
	return $Systran_Response;
}
?>
