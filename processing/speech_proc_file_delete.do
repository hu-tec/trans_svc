<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('speech_proc_file_delete');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

$Response = array();

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$BizType     = $_POST["BizType"];
	$ProjectName = strtolower($_POST["projectname"]);
	$Job_name    = strtolower($_POST["job_name"]); 
} else {
	$log->fatal("비정상 접속");
	exit;
}

$TableName = "";
if ( $BizType == 2 ) $TableName = "STT";
else if ( $BizType == 3 ) $TableName = "VIDEO";
else if ( $BizType == 4 ) $TableName = "S2S";
else if ( $BizType == 5 ) $TableName = "YOUTUBE";

$log->trace("*************** ".$TableName." Delete **************");
$log->trace("*** Begin Delete File:: ProjectName=".$ProjectName);

$isOK = 1;
$RecCnt = 1;
if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$sql = "UPDATE ".$TableName."_Job SET flag=1 where projectname = UNHEX('".$ProjectName."') and flag=0";
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($ResText);
}

if ( $isOK == 1 ) {
	mysqli_commit($DBCon);
	unlink($UpFilePath.$ProjectName);
	if ( $BizType != 5 )  unlink($UpFilePath.$Job_name); //YOUTUBE 아닌 경우
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
