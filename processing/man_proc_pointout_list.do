<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('man_proc_pointout_list');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

$SelectedMenu = 0;
if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$svccode     = $_SESSION['svccode'];
}
else  {
	$log->fatal("비정상 접속");
	exit;
}

$Response = array();
$isOK = 1;
$UserType = 0;

$log->trace("*************** Manager : User List Query **************");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$sql = "SELECT User.useridkey, Point_Withdrawal.sdate, amount, status,";
$sql = $sql." userid, name, if (birthday_yy=0, '', concat(birthday_yy, '.', birthday_mm, '.', birthday_dd)) as birthday,";
$sql = $sql." phone, utype, account_name, account_number";
$sql = $sql." FROM Point_Withdrawal, User";
$sql = $sql." WHERE Point_Withdrawal.svccode=".$svccode;
$sql = $sql." && Point_Withdrawal.useridkey=User.useridkey";
$sql = $sql." ORDER BY if(status=0, 0, 1), sdate desc limit 0, 1000";
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($ResText);
}

if ( $isOK == 1 ) {
	$TotRec = array();
	$cnt=1;
	while($row = mysqli_fetch_array($DBQRet)) {
		$OneRec = array();

		$OneRec["seq"]            = $cnt;
		$OneRec["sdate"]          = $row['sdate'];
		$OneRec["useridkey"]      = $row['useridkey'];
		$OneRec["userid"]         = $row['userid'];
		$OneRec["name"]           = $row['name'];
		$OneRec["birthday"]       = $row['birthday'];
		$OneRec["phone"]          = $row['phone'];

		if ( (int)$row['utype'] == 1)
			$OneRec["utype"] = "사용자";
		else if ( (int)$row['utype'] == 21)
			$OneRec["utype"] = "전문가";
		else if ( (int)$row['utype'] == 99)
			$OneRec["utype"] = "관리자";

		$OneRec["account_name"]   = $row['account_name'];
		$OneRec["account_number"] = $row['account_number'];
		$OneRec["amount"] = $row['amount'];
		$OneRec["status"] = $row['status'];
	
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
