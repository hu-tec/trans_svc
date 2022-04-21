<?
define("GOOGLE_ProjectId", "htc-service");

require_once 'inc_common.do';

require_once $Google_SDK.'/vendor/autoload.php';
putenv('GOOGLE_APPLICATION_CREDENTIALS='.$Google_SDK.'/vendor/htc-service-964025509689.json');

use Google\Cloud\Translate\V3\TranslationServiceClient;
use Google\Cloud\TextToSpeech\V1\AudioConfig;
use Google\Cloud\TextToSpeech\V1\AudioEncoding;
use Google\Cloud\TextToSpeech\V1\SsmlVoiceGender;
use Google\Cloud\TextToSpeech\V1\SynthesisInput;
use Google\Cloud\TextToSpeech\V1\TextToSpeechClient;
use Google\Cloud\TextToSpeech\V1\VoiceSelectionParams;

/************************* Translation *********************/
function GOOGLE_Translate( $Source_Text, $Target_Lang ) {
	$log = Logger::getLogger('GOOGLE_Translate');

	$log->trace("Lang(>".$Target_Lang."), Text:".$Source_Text);

	$Google_Response = array();
	$All_Tgt_Text = "";

	$translationServiceClient = new TranslationServiceClient();
	$formattedParent = $translationServiceClient->locationName(GOOGLE_ProjectId, 'global');
	try {
		$GooResult = $translationServiceClient->translateText( $Source_Text, $Target_Lang, $formattedParent );
		$Cnt = 0;
		foreach ($GooResult->getTranslations() as $translation) {
			$OneResText = $translation->getTranslatedText();
			$OneResText = preg_replace('/&quot;/', '"', $OneResText);
			$OneResText = preg_replace('/&#39;/', '\'', $OneResText);

			if ( $Cnt > 0 ) $All_Tgt_Text = $All_Tgt_Text."\r\n";
			$All_Tgt_Text = $All_Tgt_Text.preg_replace("/\'/","\\'", $OneResText);
			$Cnt++;
		}
		$SrcText = print_r($Source_Text, true);
		$log->trace("Src:[".$SrcText."]");
		$log->trace("Tgt:[".$Target_Lang."][".$All_Tgt_Text."]");
		
		$Google_Response["isOK"] =  1;
		$Google_Response["Target_Text"] = $All_Tgt_Text;
	} catch(Exception $e) {
		$log->ERROR($e);
		$Google_Response["isOK"] =  0;
		$Google_Response["ErrorMsg"] = $e;
	} finally {
		$translationServiceClient->close();
	}

	return $Google_Response;
}

/************************* Detect Language *********************/
function GOOGLE_Detect_Language( $Req_Text ) {
	$log = Logger::getLogger('GOOGLE_Detect_Language');

	$log->trace("Text:".$Req_Text);

	$Google_Response = array();

	$translationServiceClient = new TranslationServiceClient();
	$formattedParent = $translationServiceClient->locationName(GOOGLE_ProjectId, 'global');
	try {
		$response = $translationServiceClient->detectLanguage( $formattedParent, [ 'content' => $Req_Text, 'mimeType' => 'text/plain' ] );
		foreach ($response->getLanguages() as $language) {
			$log->trace('Language code: '.$language->getLanguageCode(). ' Confidence: '.$language->getConfidence());
			$Google_Response["isOK"] =  1;
			$Google_Response["Detect_Lang"] = $language->getLanguageCode();
			break;
		}
	} catch(Exception $e) {
		$log->ERROR($e);
		$Google_Response["isOK"] =  0;
		$Google_Response["ErrorMsg"] = $e;
	} finally {
		$translationServiceClient->close();
	}

	return $Google_Response;
}

/************************* Text To Speech *********************/
function GOOGLE_TextToSpeech( $Req_Lang, $Req_Text, $SaveFile ) {
	$log = Logger::getLogger('GOOGLE_TextToSpeech');

	$log->trace("Lang=".$Req_Lang.", SaveFile=".$SaveFile.", Text:".$Req_Text);

	$Google_Response = array();

	$log->trace("TTS : Lang=".$Req_Lang." SaveFile=".$SaveFile);
	$log->trace("TTS : Text=".$Req_Text);

	$client = new TextToSpeechClient();
	$input_text = (new SynthesisInput())->setText($Req_Text);
	$voice = (new VoiceSelectionParams())->setLanguageCode($Req_Lang)->setSsmlGender(SsmlVoiceGender::FEMALE);
	$audioConfig = (new AudioConfig())->setAudioEncoding(AudioEncoding::MP3);
	try {
		$response = $client->synthesizeSpeech($input_text, $voice, $audioConfig);
		$audioContent = $response->getAudioContent();
		file_put_contents($SaveFile, $audioContent);
	} catch(Exception $e) {
		$log->ERROR($e);
		$Google_Response["isOK"] =  0;
		$Google_Response["ErrorMsg"] = $e;
	} finally {
		$client->close();
	}
	$log->trace("TTS : Process End -----------");

	return $Google_Response;
}

?>
