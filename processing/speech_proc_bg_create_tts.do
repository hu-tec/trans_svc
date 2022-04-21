<?
require_once 'include.do';
require_once $include_db;
require_once $include_google;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('speech_proc_bg_create_tts');  // call by expert_save_text.do

$ProjectName = $argv[2];

$isOK = 1;
$JobName="";
$srcLang = "";
$tgtLang = "";
$src_text = "";
$tgt_text = "";

if ( !DB_Connect($DBCon, $ResText) ) {
	$log->ERROR("DB Connect FAIL");
	exit;
}

$log->trace( "BEGIN >>>> PRJNAME : ".$ProjectName);

$sql = "SELECT HEX(job_name) as job_name, srcLang, tgtLang, src_text, tgt_text";
$sql = $sql." FROM S2S_Job";
$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";

$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($sql);
	$log->ERROR($ResText);
}
else {
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		$JobName = strtolower($row['job_name']);
		$srcLang = $row['srcLang'];
		$tgtLang = $row['tgtLang'];
		$src_text = $row['src_text'];
		$tgt_text = $row['tgt_text'];

		$log->trace("BEGIN >>>> PRJNAME :".$ProjectName. " JobName:".$JobName." srcLang:".$srcLang. " tgtLang:".$tgtLang." trans_type=".$trans_type." status=".$status);
		$log->trace("src_text : ".$src_text);
		$log->trace("tgt_text : ".$tgt_text);
	}
	else {
		$isOK = 0;
		$log->trace( "Not Found Record - Project : ".$ProjectName);
	}
}

//////////////// Text To Speech ////////////////////////////////
if ( $isOK == 1 ) {
	$log->trace(" Lang: ".$tgtLang." :: Text : ".$tgt_text);
	$RLink = $DownFilePath.$JobName.".mp3";

	//////////////// Make TTS ///////////////////
	GOOGLE_TextToSpeech( $tgtLang, $tgt_text, $RLink );
	////////////////////////////////////////////////////////////
	$log->trace(" Lang: ".$tgtLang." :: Create Audio File : ".$RLink);
}
mysqli_close($DBCon);

$log->trace( "END >>>> PRJNAME : ".$ProjectName. " srcLang: ".$srcLang. " tgtLang: ".$tgtLang );

?>
