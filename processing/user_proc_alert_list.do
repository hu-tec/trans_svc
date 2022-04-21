<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('user_proc_alert_list');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

$SelectedMenu = 0;
if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$useridkey = $_SESSION['useridkey'];
	$svccode   = $_SESSION['svccode'];
}
else  {
	$log->fatal("비정상 접속");
	exit;
}

$Response = array();
$isOK = 1;

$log->trace("*************** Manager : Alert List Query **************");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$sql = "SELECT utype FROM User";
$sql = $sql." WHERE flag=0 && useridkey=".$useridkey." && svccode=".$svccode;
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($sql);
	$log->ERROR($ResText);
}
if ( $isOK == 1 ) {
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		$utype = (int)$row['utype'];

		if ( $utype == 1 )
			$MTYPE = "(mtype=0 || mtype=1)";
		else if ( $utype == 21 )
			$MTYPE = "(mtype=0 || mtype=21)";
		else if ( $utype == 99 )
			$MTYPE = "(mtype=0 || mtype=1 || mtype=21)";

	}
	else {
		$isOK = 0;
		$ResText = "사용자를 찾을 수 없습니다.";
	}
}

if ( $isOK == 1 ) {
	$sql = "SELECT ";
	$sql = $sql." seq, sdate, message";
	$sql = $sql." FROM MBox";
	$sql = $sql." WHERE flag=0 && ".$MTYPE." && svccode=".$svccode;
	$sql = $sql." ORDER BY sdate desc limit 0, 1000";

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($sql);
		$log->ERROR($ResText);
	}
}

if ( $isOK == 1 ) {
	$TotRec = array();
	$cnt=1;
	while($row = mysqli_fetch_array($DBQRet)) {
		$OneRec = array();

		$OneRec["seq"]     = $cnt;
		$OneRec["sdate"]   = $row['sdate'];
		$OneRec["message"] = nl2br($row['message']);

		$TotRec[] = $OneRec;
		$cnt++;
		//$log->trace("ONE : \n".json_encode($OneRec));
	}
	
	//$log->trace("TOT : \n".json_encode($TotRec));
	//$Response["iTotalRecords"] = ($cnt-1);
	$Response["data"] = $TotRec;
}
mysqli_close($DBCon);

$log->trace("RES : \n".json_encode($Response));

print json_encode($Response);
?>
