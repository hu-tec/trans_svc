<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('man_proc_expert_set');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$SVCType = (int)$_POST["SVCType"];
	$ProjectName = $_POST["ProjectName"];
	$JobName = $_POST["JobName"];
	$expert  = $_POST["expert"];
	$log->trace( $SVCType . " : " . $ProjectName . " : " . $JobName . " : " . $expert );
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$isOK = 1;
$Response = array();

$TableName = "";
if ( $SVCType == 0 ) $TableName = "MMS";
else if ( $SVCType == 1 ) $TableName = "MT";
else if ( $SVCType == 2 ) $TableName = "STT";
else if ( $SVCType == 3 ) $TableName = "VIDEO";
else if ( $SVCType == 4 ) $TableName = "S2S";
else if ( $SVCType == 5 ) $TableName = "YOUTUBE";

$log->trace("***** ".$TableName." Job : Expert Set ********");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$sql = "UPDATE ".$TableName."_Job SET status=51, expert_id=".$expert;
if ( $SVCType == 0 ) 
	$sql = $sql." where tmp_fname = UNHEX('".$JobName."') and flag=0";
else 
	$sql = $sql." where projectname = UNHEX('".$ProjectName."') and flag=0";

$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) )
	$isOK = 0;


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
