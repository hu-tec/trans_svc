<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('speech_proc_lang_set');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}
if ( !isset( $_SESSION['ProjectName'] ) ) {
	$log->fatal("해당 Project 없음");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$BizType     = $_POST["BizType"];
	$ProjectName = $_POST["projectname"];
	$TgtLang     = $_POST["TgtLang"];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$TableName = "";
if ( $BizType == 2 ) $TableName = "STT";
else if ( $BizType == 3 ) $TableName = "VIDEO";
else if ( $BizType == 4 ) $TableName = "S2S";
else if ( $BizType == 5 ) $TableName = "YOUTUBE";

$log->trace("*************** ".$TableName." Language SET **************");
$log->trace("*** ProjectName=".$ProjectName."Target Lang=".$TgtLang);


$isOK = 1;
$Response = array();

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$sql = "UPDATE ".$TableName."_Job SET tgtLang='".$TgtLang."'";
$sql = $sql." where projectname = UNHEX('".$ProjectName."') and flag=0";
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) $isOK = 0;

if ( $isOK == 1 )
	mysqli_commit($DBCon);
else 
	mysqli_rollback($DBCon);

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( $isOK == 0 ) $log->ERROR($ResText);
if ( strlen($ResText) > 0 ) $Response["RText"] = $ResText;
$log->trace("RES : ".json_encode($Response));

print json_encode($Response);

?>
