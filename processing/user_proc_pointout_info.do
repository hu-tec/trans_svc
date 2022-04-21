<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('user_proc_pointout_submit');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
} 
else {
	$log->fatal("비정상 접속");
	exit;
}

$isOK = 1;
$Response = array();

$useridkey = $_SESSION['useridkey'];
$svccode = $_SESSION['svccode'];

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$sql = "SELECT amount";
$sql = $sql." FROM Point_Withdrawal WHERE status=0 and useridkey=".$useridkey." and svccode=".$svccode;
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$log->ERROR( $sql );
	$isOK = 0;
}

if ( $isOK == 1 ) { 
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		$Response["amount"] = (int)$row['amount'];
	}
	else {
		$isOK = 2;
	}
}

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( $isOK == 0 ) $log->ERROR($ResText);
if ( strlen($ResText) > 0 ) $Response["RText"] = $ResText;
$log->trace("RES : ".json_encode($Response));

print json_encode($Response);

?>
