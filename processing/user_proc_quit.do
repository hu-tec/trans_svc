<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('user_proc_quit');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$useridkey = $_SESSION['useridkey'];
	$svccode   = $_SESSION['svccode'];

	$ChkPWD    = $_POST["ChkPWD"];
	$Quit_Ment = $_POST["Quit_Ment"];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$ResText = "";
$log->trace("********** useridkey = ".$useridkey." **********");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$isOK = 2;
$Response = array();
$userid = "";

$sql = "SELECT userid";
$sql = $sql." FROM User";
$sql = $sql." WHERE flag=0 && svccode = ".$svccode." && useridkey = ".$useridkey." && passwd='".$ChkPWD."'";
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$log->ERROR( $sql );
	$log->ERROR( $ResText );
	$isOK = 0;
}

if ( $isOK == 2 ) {
	if( ($row = mysqli_fetch_array($DBQRet)) ) {
		$userid = $row['userid'];
	}
	if ( strlen($userid) < 1 ) {
		$isOK = 1;
		$ResText = "확인용 비밀번호를 정확히 입력하여 주시기 바랍니다.";
		$log->ERROR("Userkey=".$useridkey." 비밀번호 틀림 CheckPWD=[".$ChkPWD."]");
	}
}

////////////////////////////////////////////////////////////
if ( $isOK == 2 ) {
	$Quit_Ment = preg_replace("/\'/","\\'", $Quit_Ment);

	$sql = "UPDATE User SET flag=1, ";
	$sql = $sql."quit_ment='".$Quit_Ment."'";
	$sql = $sql." WHERE flag=0 && svccode=".$svccode." && useridkey=".$useridkey;

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR( $sql );
		$log->ERROR($ResText);
	}
}
////////////////////////////////////////////////////////////

if ( $isOK == 2 ) mysqli_commit($DBCon);
else  mysqli_rollback($DBCon);

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( strlen($ResText) > 0 )
	$Response["RText"] = $ResText;

$log->trace("SEND Result : ".json_encode($Response));
print json_encode($Response);
?>
