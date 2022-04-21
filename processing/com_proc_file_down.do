<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;
//require_once $include_mmsrc;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('com_proc_file_down');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
	/* Request parameter */
	$tmpFileName = $_POST["tmpFileName"];
	$oriFileName = $_POST["oriFileName"];
	$isResult    = $_POST["isResult"];
	if (class_exists('Normalizer')) {
		if (Normalizer::isNormalized($oriFileName, Normalizer::FORM_D))
			$oriFileName = Normalizer::normalize($oriFileName, Normalizer::FORM_C);
	}

	$Prefix = "result_";
	$DNPath = $DownFilePath;
	if ( (int)$isResult == 0 ) {
		$Prefix = "original_";
		$DNPath = $UpFilePath;
	}
}
else  {
	$log->FATAL("비정상 접속");
	exit;
}

$log->trace("*************** File Download Begin **************");
$log->INFO("*** Begin :: oriFileName = ".$oriFileName.", tmpFileName=".$tmpFileName);

$Response = array();
$isOK = 1;

$downloadFile = $DNPath.$tmpFileName;
if( file_exists($downloadFile) ) {
	ob_end_clean();
	$RealFile = $downloadFile;
	$UserFile = $Prefix.$oriFileName;

	$log->info("UserFile=[".$UserFile."] Size=[".filesize("$RealFile")."] RealFile=[".$RealFile."]");

	header("Set-Cookie: FDownOk=1; path=/");
	if(preg_match("/msie/i", $_SERVER['HTTP_USER_AGENT']) && preg_match("/5\.5/", $_SERVER['HTTP_USER_AGENT'])) {
		header("content-length: ".filesize("$RealFile"));
		header("content-transfer-encoding: binary");
		header("Content-Type: application/octet-stream"); 
		header('Content-Disposition: attachment; filename="'.$UserFile.'"');
		header("Cache-Control: cache, must-revalidate"); 

		$log->trace("Browser A Type");
	} else {
		header("Content-Type: application/octet-stream"); 
		header("content-transfer-encoding: binary");
		header("content-length: ".filesize("$RealFile"));
		header('Content-Disposition: attachment; filename="'.$UserFile.'"');
		header("content-description: Generated File");

		$log->trace("Browser B Type");
	}
	header("pragma: no-cache");
	header("expires: 0");

	flush();
	readfile($RealFile);
	flush();
	
	// ob_end_flush();
	// ob_end_clean();
	session_write_close();
}
else {
	$isOK = 0;
	$Response["RText"] = "파일이 찾을 수 없습니다. - 관리자 문의";
	$Response["isOK"] = $isOK;
	print json_encode($Response);
	$log->ERROR( $Response["RText"] );
}
$log->trace("*************** File Download End **************");
?>
