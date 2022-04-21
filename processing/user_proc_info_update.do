<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('user_proc_info_update');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$useridkey = $_SESSION['useridkey'];
	$svccode   = $_SESSION['svccode'];

	$ChkPWD     = $_POST["ChkPWD"];
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
$YY = 0;
$MM = 0;
$DD = 0;


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
	$UpdateCnt=0;
	if ( isset( $_POST['Birthday'] ) ) {
		$strTok = explode('-', $_POST['Birthday']);
		$YY = (int)$strTok[0];
		$MM = (int)$strTok[1];
		$DD = (int)$strTok[2];
	}

	$sql = "UPDATE User SET ";
	if ( isset( $_POST['Birthday'] ) ) {
		if ( $UpdateCnt>0 ) $sql = $sql.", ";
		$sql = $sql."birthday_yy=".$YY.", birthday_mm=".$MM.", birthday_dd=".$DD;
		$UpdateCnt = 1;
	}
	if ( isset( $_POST['Phone'] ) ) {
		if ( $UpdateCnt>0 ) $sql = $sql.", ";
		$sql = $sql."Phone='".$_POST['Phone']."'";
		$UpdateCnt = 1;
	}
	if ( isset( $_POST['ACC_Name'] ) ) {
		if ( $UpdateCnt>0 ) $sql = $sql.", ";
		$sql = $sql."account_name='".$_POST['ACC_Name']."'";
		$UpdateCnt = 1;
	}
	if ( isset( $_POST['ACC_Number'] ) ) {
		if ( $UpdateCnt>0 ) $sql = $sql.", ";
		$sql = $sql."account_number='".$_POST['ACC_Number']."'";
		$UpdateCnt = 1;
	}
	if ( isset( $_POST['NEW_PWD'] ) ) {
		if ( $UpdateCnt>0 ) $sql = $sql.", ";
		$sql = $sql."passwd='".$_POST['NEW_PWD']."'";
		$UpdateCnt = 1;
	}
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
