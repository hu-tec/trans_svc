<?
define("GOOGLE_ProjectId", "htc-service");

require_once 'inc_common.do';

require_once $Google_SDK.'/vendor/autoload.php';
putenv('GOOGLE_APPLICATION_CREDENTIALS='.$Google_SDK.'/vendor/htc-service-964025509689.json');

use Google\Cloud\Storage\StorageClient;
use Google\Cloud\Speech\V1\SpeechClient;
use Google\Cloud\Speech\V1\RecognitionAudio;
use Google\Cloud\Speech\V1\RecognitionConfig;
use Google\Cloud\Speech\V1\RecognitionConfig\AudioEncoding;

/************************* Speech to Text *********************/
function GOOGLE_SpeechToText( $Audio_File, $Job_Name, $sample_rate, $srcLang, $channels ) {
	$log = Logger::getLogger('GOOGLE_SpeechToText');

	$log->trace("Audio_File=".$Audio_File.", Job_Name=".$Job_Name.", sample_rate:".$sample_rate.", srcLang:".$srcLang.", channels:".$channels);

	$Google_Response = array();
	$Google_Response["isOK"] = 1;

	$GetTranScript = "";
	try {
		$storage = new StorageClient(['projectId' => GOOGLE_ProjectId]);

		// $storage = new StorageClient();
		$file = fopen($Audio_File, 'r');
		$bucket = $storage->bucket('htc-service-bucket');
		$object = $bucket->upload($file, [ 'name' => $Job_Name ]);
		$uri='gs://htc-service-bucket/'.$Job_Name;

		// set string as audio content
		$audio = (new RecognitionAudio())->setUri($uri);

		// set config
		$encoding = AudioEncoding::FLAC;
		$config = (new RecognitionConfig())
			->setEncoding($encoding)
			->setSampleRateHertz($sample_rate)
			->setLanguageCode($srcLang)
			->setAudioChannelCount($channels)
			//->setEnableSeparateRecognitionPerChannel(true)
			->setEnableWordTimeOffsets(true)
			->setEnableAutomaticPunctuation(true);

		// create the speech client
		$client = new SpeechClient();

		//create the asyncronous recognize operation
		$operation = $client->longRunningRecognize($config, $audio);
		$operation->pollUntilComplete();

		if ($operation->operationSucceeded()) {
			$response = $operation->getResult();
			// each result is for a consecutive portion of the audio. iterate
			// through them to get the transcripts for the entire audio file.
			foreach ($response->getResults() as $result) {
				$alternatives = $result->getAlternatives();
				$mostLikely = $alternatives[0];
				$transcript = $mostLikely->getTranscript();
				$confidence = $mostLikely->getConfidence();

				$GetTranScript = $GetTranScript.$transcript;

				$log->trace('Transcript: ' . $transcript);
				$log->trace('Confidence: ' . $confidence);

				// foreach ($mostLikely->getWords() as $wordInfo) {
				// 	$startTime = $wordInfo->getStartTime();
				// 	$endTime = $wordInfo->getEndTime();
				// 	$log->trace('Word:'.$wordInfo->getWord().'(start: '.$startTime->serializeToJsonString().', end: '.$endTime->serializeToJsonString().')');
				// }
			}
			$Google_Response["TranScript"] = $GetTranScript;
		} else {
			// $log->ERROR($operation->getError());
			// $ResText = "오류-".$operation->getError();
			// $isOK = 0;

			$log->ERROR($operation->getError());
			$Google_Response["isOK"] = 0;
			$Google_Response["ErrorMsg"] = "오류-".$operation->getError();
		}
		$client->close();

		$object = $bucket->object($Job_Name);
		$object->delete();
	} catch(Exception $e) {
		$log->ERROR($e);
		$Google_Response["isOK"] =  0;
		$Google_Response["ErrorMsg"] = $e;
	} finally {
	}
	/////////////////////////////////////////////

	$log->trace("STT : Process End -----------");
	return $Google_Response;
}

?>
