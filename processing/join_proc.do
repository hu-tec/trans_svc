<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('join_proc');

if ($_SERVER["REQUEST_METHOD"] == "POST") {
	/* Request parameter */
	$Email = $_POST["Email"]; 
	$PWD   = $_POST["PWD"]; 
	$UName = $_POST["UName"];
	$Phone = $_POST["Phone"]; 
	$Type  = $_POST["Type"]; 
}
else  {
	$log->FATAL("비정상 접속");
	exit;
}

$log->trace("*************** User Join **************");
$log->INFO("*** Begin :: Email = ".$Email.", UName=".$UName.", Phone=".$Phone);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$Response = array();
$isOK = 1;

// Check duplication Email
$sql = "SELECT userid FROM User where userid='".$Email."'";
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$Response["RText"] = $ResText;
	$log->ERROR($ResText);
}
else {
	if ( DB_RowCount($DBQRet) > 0 ) {
		$Response["RText"] = "이미 입력하신 아이디(Email 주소)로 회원가입 되어 있거나 가입한 적이 있습니다.";
		$log->info("Email Duplication  : ".$Response["RText"] );
		$isOK = -1;
	}
}

if ( $isOK == 1 ) {
	$sql = "INSERT INTO User (userid, passwd, name, phone, sdate, svccode, utype, grade) VALUES (";
	$sql = $sql."'$Email', '$PWD', '$UName', '$Phone', now(), 1, '$Type', 1)";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$Response["RText"] = $ResText;
		$log->ERROR($ResText);
	}
}

if ( $isOK == 1 ) {
	mysqli_commit($DBCon);
}
else  mysqli_rollback($DBCon);
mysqli_close($DBCon);

$Response["isOK"] = $isOK;
print json_encode($Response);

$log->trace("RES : ".json_encode($Response));

?>
