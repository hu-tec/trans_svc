<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('tts_proc_delete');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

$Response = array();

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$ProjectName = $_POST["projectname"];
} else {
	$log->fatal("비정상 접속");
	exit;
}

$log->trace("*** Begin Delete :: ProjectName=".$ProjectName);

$isOK = 1;
$src_audio = "";
$tgt_audio = "";

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$sql = "SELECT src_audio, tgt_audio FROM MT_Job where projectname = UNHEX('".$ProjectName."') and flag=0";
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($sql);
	$log->ERROR($ResText);
}	
if ( $isOK == 1 ) {
	if ($row = mysqli_fetch_array($DBQRet)) {
		$src_audio = strtolower($row['src_audio']);
		$tgt_audio = strtolower($row['tgt_audio']);
	}
}

if ( $isOK == 1 ) {
	$sql = "UPDATE MT_Job SET flag=1 where projectname = UNHEX('".$ProjectName."') and flag=0";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($sql);
		$log->ERROR($ResText);
	}
}

if ( $isOK == 1 ) {
	mysqli_commit($DBCon);
	if ( strlen($src_audio) > 0 )
		unlink($DownFilePath.$src_audio.".mp3");
	if ( strlen($tgt_audio) > 0 )
		unlink($DownFilePath.$tgt_audio.".mp3");
} 
else {
	$Response["RText"] = $ResText;
	mysqli_rollback($DBCon);
}
mysqli_close($DBCon);

$Response["isOK"] = $isOK;
$log->trace("RES : ".json_encode($Response));

print json_encode($Response);

?>
