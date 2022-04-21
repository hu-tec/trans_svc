<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;
//require_once $include_mmsrc;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('doc_proc_file_delete');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

$Response = array();

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$isAll = (int)$_POST["isAll"]; 
	$ProjectName = $_POST["projectname"];
	if ( $isAll == 0 ) $tmp_fname = $_POST["tmp_fname"]; 
} else {
	$log->fatal("비정상 접속");
	exit;
}

$log->trace("*** Begin Delete File:: ProjectName=".$ProjectName." file=".$tmp_fname);

$DelAllFileArray = array();
$isOK = 1;
$RecCnt = 1;
if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

if ( $isAll == 1 ) { // 저장된 파일 삭제
	$sql = "SELECT hex(tmp_fname) as tmp_fname FROM MMS_Job where projectname = UNHEX('".$ProjectName."') and flag=0";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($ResText);
	}	
	if ( $isOK == 1 ) {
		while($row = mysqli_fetch_array($DBQRet)) {
			$DelAllFileArray[] = strtolower($row['tmp_fname']);
		}
	}
}

// DELETE Request (All or Selected)
//$sql = "DELETE FROM MMS_Job where projectname = UNHEX('".$ProjectName."') ";
$sql = "UPDATE MMS_Job SET flag=1 where projectname = UNHEX('".$ProjectName."') and flag=0";
if ( $isAll == 0 ) $sql = $sql." and tmp_fname = UNHEX('".$tmp_fname."')";
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($ResText);
}

// 개별 삭제인 경우 남은 건수 조회
if ( $isOK == 1 && $isAll == 0 ) {
	$sql = "SELECT count(*) as cnt FROM MMS_Job where projectname = UNHEX('".$ProjectName."') and flag=0";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($ResText);
	}
	if ( $isOK == 1 ) {
		$row = mysqli_fetch_array($DBQRet);
		$RecCnt = (int)$row['cnt'];
	}
}

// 전체 삭제 또는 남은 건수가 없으면 Project 삭제
if ( $isOK == 1 && ( $isAll == 1 || $RecCnt==0 ) ) {
	$sql = "UPDATE MMS_Project SET flag=1 where flag=0 and useridkey=".$_SESSION['useridkey']." and svccode=".$_SESSION['svccode'];
	$sql = $sql." and projectname = UNHEX('".$ProjectName."')";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($ResText);
	}
	else {
		unset($_SESSION['ProjectName']);
	}
}

if ( $isOK == 1 ) {
	mysqli_commit($DBCon);
	if ( $isAll == 0 )
		unlink($UpFilePath.$tmp_fname);
	else if ( $isAll == 1 ) {
		for($i = 0; $i < count($DelAllFileArray); $i++){
			unlink($UpFilePath.$DelAllFileArray[$i]);
		}
	}
} 
else {
	$Response["RText"] = $ResText;
	mysqli_rollback($DBCon);
}
mysqli_close($DBCon);

$Response["isOK"] = $isOK;
$log->trace("RES : ".json_encode($Response));

print json_encode($Response);

?>
