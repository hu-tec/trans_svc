<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

/*
svccode : 1-번역, 2-
utype : 1-사용자, 21-전문가, 99-관리자
grade : 21-전문가(1:초급, 2:중급, 3:고급)
        99-관리자(1:사이트,  2:전체)
*/

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('login_proc');

if ($_SERVER["REQUEST_METHOD"] == "POST") {
	/* Request parameter */
	$Email = $_POST["Email"]; 
	$PWD   = $_POST["PWD"]; 
}
else  {
	$log->FATAL("비정상 접속");
	exit;
}

$log->trace("*************** User Login **************");
$log->INFO("*** Begin :: Email = ".$Email);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$Response = array();
$Response["point"] = 0;
$isOK = 1;

// Check duplication Email
$sql = "SELECT userid FROM User where flag=0 && userid='".$Email."'";
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$Response["RText"] = $ResText;
	$log->ERROR($ResText);
}
else {
	if ( DB_RowCount($DBQRet) > 0 ) {
		$sql = "SELECT userid, name, phone,useridkey, svccode, utype, grade FROM User where flag=0 && userid='".$Email."' and passwd='".$PWD."'";
		$log->trace( $sql );
		if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
			$isOK = 0;
			$Response["RText"] = $ResText;
			$log->ERROR($ResText);
		}
		if ( DB_RowCount($DBQRet) == 0 ) {
			$Response["RText"] = "패스워드를 확인하여 주시기 바랍니다.";
			$isOK = -1;
		}
		else {
			$row = mysqli_fetch_array($DBQRet);
			$_SESSION['useridkey'] = $row['useridkey'];
			$_SESSION['userid'] = $row['userid'];
			$_SESSION['usernm'] = $row['name'];
			$_SESSION['phone'] = $row['phone'];
			$_SESSION['svccode']   = $row['svccode'];
			$_SESSION['utype']     = $row['utype'];
			$_SESSION['grade']     = $row['grade'];

			$Response["utype"] = $_SESSION['utype'];
			$Response["grade"] = $_SESSION['grade'];
		}
	}
	else {
		$Response["RText"] = "아이디(Email 주소)를 존재하지 않습니다.";
		$isOK = -1;
	}
}

if ( $isOK==1 ) {
	$sql = "SELECT point FROM Point";
	$sql = $sql." where useridkey=".$_SESSION['useridkey']." and svccode=".$_SESSION['svccode']." ORDER BY sdate DESC LIMIT 1";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$Response["RText"] = $ResText;
		$log->ERROR($ResText);
	}
	else {
		if ($row = mysqli_fetch_array($DBQRet)) {
			$_SESSION['point'] = $row['point'];
			$Response["point"] = $_SESSION['point'];
		}
	}
}

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
print json_encode($Response);

$log->trace("RES : ".json_encode($Response));

?>
