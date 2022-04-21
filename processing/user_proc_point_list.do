<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('user_proc_point_list');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$MIdx = (int)$_POST['MIdx'];
	$isSearch = (int)$_POST['isSearch'];
}
else  {
	$log->fatal("비정상 접속");
	exit;
}

$useridkey = $_SESSION['useridkey'];
$svccode   = $_SESSION['svccode'];

$Response = array();
$TotRec = array();
$isOK = 1;

$log->trace("*************** Information Query **************");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$log->INFO("*** UserSeq=".$_SESSION['useridkey']);

/////////////////// DB Query /////////////////// 
$sql = "SELECT sdate, point, before_point, amount, use_case FROM Point";
$sql = $sql." WHERE svccode = ".$_SESSION['svccode']." && useridkey = ".$_SESSION['useridkey'];

if ( $MIdx == 1 ) $sql = $sql." && amount > 0";
else if ( $MIdx == 2 ) $sql = $sql." && amount < 0";

if ( $isSearch == 1 ) {
	if ( isset( $_POST['StartDate'] ) )  $sql = $sql." && DATE(sdate) >= '".$_POST['StartDate']."'";
	if ( isset( $_POST['EndDate'] ) )  $sql = $sql." && DATE(sdate) <= '".$_POST['EndDate']."'";
}
$sql = $sql." ORDER BY sdate desc limit 0, 1000";

$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($ResText);
}
////////////////////////////////////////////////

if ( $isOK == 1 ) {
	$cnt=1;
	while($row = mysqli_fetch_array($DBQRet)) {
		$OneRec = array();

		$OneRec["seq"]    = $cnt;
		$OneRec["sdate"]  = $row['sdate'];

		if ( (int)$row['use_case'] == 0 ) {
			if ( (int)$row['amount'] > 0 ) $OneRec["type"] = "충전";
			else                      $OneRec["type"] = "서비스 이용";
		}
		else {
			if ( (int)$row['amount'] > 0 ) $OneRec["type"] = "출금취소";
			else                      $OneRec["type"] = "출금요청";
		}

		$OneRec["amount"] = $row['amount'];
		$OneRec["point"]  = $row['point'];

		$TotRec[] = $OneRec;
		$cnt++;
		//$log->trace("ONE : \n".json_encode($OneRec));
	}
	
	//$log->trace("TOT : \n".json_encode($TotRec));
}
mysqli_close($DBCon);

$Response["data"] = $TotRec;

$log->trace("RES : \n".json_encode($Response));

$log->trace("MIdx : ".$MIdx);
$log->trace("isSearch : ".$isSearch);
if ( isset( $_POST['StartDate'] ) ) $log->trace("StartDate : ".$_POST['StartDate']);
if ( isset( $_POST['EndDate'] ) ) $log->trace("EndDate : ".$_POST['EndDate']);

print json_encode($Response);
?>
