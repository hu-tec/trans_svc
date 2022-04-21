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
$point = $_SESSION['point'];

$remain_point = $point;
$Response["point"] = $remain_point;

$PointOut = 0;

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
		$PointOut = (int)$row['amount'];
	}
	else {
		$isOK = 0;
		$ResText = "취소할 내용을 조회할 수 없습니다.";
	}
}

if ( $isOK == 1 ) {
	$sql = "UPDATE Point_Withdrawal SET status=1";
	$sql = $sql." where status=0 and useridkey=".$useridkey." and svccode=".$svccode;
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) {
		$log->ERROR( $sql );
		$ResText = "출금 취소 정보를 저장하지 못하였습니다.";
		$isOK = 0;
	}
}

if ( $isOK == 1 ) {
	// Point 복구
	$remain_point = $point + $PointOut;
	$Response["point"] = $remain_point;
	$MCost = $PointOut;

	$sql = "INSERT INTO Point (useridkey, svccode, sdate, point, before_point, amount, use_case) VALUES (";
	$sql = $sql.$useridkey.", ".$svccode.", now(), ".$remain_point.", ".$point.", ".$MCost.", 2)";

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
