<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('man_proc_user_list');

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


if ( $isOK == 1 ) {
	$sql = "SELECT ";
	$sql = $sql." sdate,";
	$sql = $sql." useridkey,";
	$sql = $sql." userid,";
	$sql = $sql." name,";
	$sql = $sql." phone,";
	$sql = $sql." utype,";
	$sql = $sql." grade,";
	$sql = $sql." account_name,";
	$sql = $sql." account_number,";
	$sql = $sql." birthday_yy,";
	$sql = $sql." birthday_mm,";
	$sql = $sql." birthday_dd,";
	$sql = $sql." quit_ment,";
	$sql = $sql." flag";
	$sql = $sql." FROM User";
	$sql = $sql." WHERE svccode=".$svccode;
	// Add Condition
	////////////////
	if ( isset( $_POST['StartDate'] ) ) $sql = $sql." && DATE(sdate) >= '".$_POST['StartDate']."'";
	if ( isset( $_POST['EndDate'] ) )   $sql = $sql." && DATE(sdate) <= '".$_POST['EndDate']."'";
	if ( isset( $_POST['utype'] ) )     $sql = $sql." && utype = ".$_POST['utype'];
	////////////////
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

		$OneRec["seq"]            = $cnt;
		$OneRec["sdate"]          = $row['sdate'];
		$OneRec["useridkey"]      = $row['useridkey'];
		$OneRec["userid"]         = $row['userid'];
		$OneRec["name"]           = $row['name'];
		$OneRec["phone"]          = $row['phone'];

		if ( (int)$row['utype'] == 1)
			$OneRec["utype"] = "사용자";
		else if ( (int)$row['utype'] == 21)
			$OneRec["utype"] = "전문가";
		else if ( (int)$row['utype'] == 99)
			$OneRec["utype"] = "관리자";

		$OneRec["grade"]          = $row['grade'];
		$OneRec["account_name"]   = $row['account_name'];
		$OneRec["account_number"] = $row['account_number'];
		$OneRec["birthday_yy"]    = $row['birthday_yy'];
		$OneRec["birthday_mm"]    = $row['birthday_mm'];
		$OneRec["birthday_dd"]    = $row['birthday_dd'];
		$OneRec["quit_ment"]      = $row['quit_ment'];
		$OneRec["flag"]           = $row['flag'];
	
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
