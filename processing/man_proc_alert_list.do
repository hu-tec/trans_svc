<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('man_proc_alert_list');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

$SelectedMenu = 0;
if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$useridkey   = $_SESSION['useridkey'];
	$svccode     = $_SESSION['svccode'];
}
else  {
	$log->fatal("비정상 접속");
	exit;
}

$Response = array();
$isOK = 1;

$log->trace("*************** Manager : Alert List Query **************");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

if ( $isOK == 1 ) {
	$sql = "SELECT ";
	$sql = $sql." seq, sdate,";
	$sql = $sql." (SELECT name FROM User WHERE User.useridkey = MBox.useridkey) as user,";
	$sql = $sql." mtype,";
	$sql = $sql." message,";
	$sql = $sql." flag";
	$sql = $sql." FROM MBox";
	$sql = $sql." WHERE svccode=".$svccode;
	$sql = $sql." ORDER BY sdate desc limit 0, 1000";

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($ResText);
	}
}

if ( $isOK == 1 ) {
	$TotRec = array();
	$cnt=1;
	while($row = mysqli_fetch_array($DBQRet)) {
		$OneRec = array();

		$OneRec["seq"]     = $cnt;
		$OneRec["idx"]     = $row['seq'];
		$OneRec["sdate"]   = $row['sdate'];
		$OneRec["user"]    = $row['user'];

		if ( (int)$row['mtype'] == 0 )
			$OneRec["mtype"] = "전체";
		else if ( (int)$row['mtype'] == 1 )
			$OneRec["mtype"] = "사용자";
		else if ( (int)$row['mtype'] == 21 )
			$OneRec["mtype"] = "전문가";

		$OneRec["message"] = nl2br($row['message']);
		$OneRec["flag"]    = $row['flag'];
	
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
