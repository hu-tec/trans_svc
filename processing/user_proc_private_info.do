<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('user_proc_private_info');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
}
else  {
	$log->fatal("비정상 접속");
	exit;
}

$useridkey = $_SESSION['useridkey'];
$svccode   = $_SESSION['svccode'];

$Response = array();
$isOK = 1;

$log->trace("*************** User Information Query **************");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$log->INFO("*** UserSeq=".$_SESSION['useridkey']);

$sql = "SELECT userid, name, phone, ifnull(account_name,'') as account_name, ifnull(account_number,'') as account_number,";
$sql = $sql." birthday_yy, birthday_mm, birthday_dd";
$sql = $sql." FROM User";
$sql = $sql." WHERE flag=0 && svccode = ".$_SESSION['svccode']." && useridkey = ".$_SESSION['useridkey'];
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$log->ERROR( $sql );
	$log->ERROR( $ResText );
	$isOK = 0;
}
else {
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		$Response["userid"]  = $row['userid'];
		$Response["name"]    = $row['name'];
		$Response["phone"]   = $row['phone'];
		$Response["account_name"]   = $row['account_name'];
		$Response["account_number"] = $row['account_number'];
		$Response["birthday_yy"] = $row['birthday_yy'];
		$Response["birthday_mm"] = $row['birthday_mm'];
		$Response["birthday_dd"] = $row['birthday_dd'];
	}
	else {
		$log->ERROR( $sql );
		$ResText = "요청 건을 조회할 수 없습니다.";
		$isOK = 0;
	}
}
mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( $isOK == 0 ) $log->ERROR($ResText);
if ( strlen($ResText) > 0 ) $Response["RText"] = $ResText;

$log->trace("RES : \n".json_encode($Response));

print json_encode($Response);
?>
