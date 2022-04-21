<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('user_proc_pointout_list');

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
$sql = "SELECT sdate, amount, status";
$sql = $sql." FROM Point_Withdrawal";
$sql = $sql." WHERE svccode = ".$_SESSION['svccode']." && useridkey = ".$_SESSION['useridkey'];

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
		$OneRec["amount"] = $row['amount'];
		$OneRec["status"] = $row['status'];

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
