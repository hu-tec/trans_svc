<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('com_proc_point_charge');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$PointChargeAmount = $_POST['PointChargeAmount'];
} 
else {
	$log->fatal("비정상 접속");
	exit;
}

$isOK = 1;
$Response = array();

$useridkey = $_SESSION['useridkey'];
$svccode = $_SESSION['svccode'];
$Current_point = 0; 
$remain_point = 0;

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

if ( $isOK == 1 ) {
	$sql = "SELECT point";
	$sql = $sql." FROM Point WHERE useridkey=".$useridkey." and svccode=".$svccode." ORDER BY sdate DESC LIMIT 1";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$log->ERROR( $sql );
		$isOK = 0;
	}
}
if ( $isOK == 1 ) { 
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		$Current_point = (int)$row['point'];
	}
}

if ( $isOK == 1 ) {
	$remain_point = $PointChargeAmount + $Current_point;
	$Response["point"] = $remain_point;

	$sql = "INSERT INTO Point (useridkey, svccode, sdate, point, before_point, amount) VALUES (";
	$sql = $sql.$useridkey.", ".$svccode.", now(), ".$remain_point.", ".$Current_point.", ".$PointChargeAmount.")";

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) {
		$log->ERROR( $sql );
		$ResText = "포인트 정보를 저장하지 못하였습니다.";
		$isOK = 0;
	}
}

if ( $isOK == 1 ) {
	mysqli_commit($DBCon);
	$_SESSION["point"] = $remain_point;
}
else
	mysqli_rollback($DBCon);

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( $isOK == 0 ) $log->ERROR($ResText);
if ( strlen($ResText) > 0 ) $Response["RText"] = $ResText;
$log->trace("RES : ".json_encode($Response));

print json_encode($Response);

?>
