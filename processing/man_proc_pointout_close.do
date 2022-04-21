<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('man_proc_pointout_close');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$useridkey = $_POST['UIdx'];
} 
else {
	$log->fatal("비정상 접속");
	exit;
}

$isOK = 1;
$Response = array();

$svccode = $_SESSION['svccode'];

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$sql = "UPDATE Point_Withdrawal SET status=2";
$sql = $sql." where status=0 and useridkey=".$useridkey." and svccode=".$svccode;
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) {
	$log->ERROR( $sql );
	$ResText = "출금 완료 정보를 저장하지 못하였습니다.";
	$isOK = 0;
}

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
