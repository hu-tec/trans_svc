<?
setlocale(LC_ALL,'ko_KR.UTF-8');
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('speech_proc_fileup_db');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$BizType = $_POST["BizType"];
	$srcLang = $_POST["srcLang"];
	$TgtLang = $_POST["TgtLang"];
}
else  {
	$log->FATAL("비정상 접속");
	exit;
}

$TableName = "";
if ( $BizType == 2 ) $TableName = "STT";
else if ( $BizType == 3 ) $TableName = "VIDEO";
else if ( $BizType == 4 ) $TableName = "S2S";
else if ( $BizType == 5 ) $TableName = "YOUTUBE";

$log->trace("*************** BizType : ".$BizType.", ".$TableName." File Upload **************");
$log->INFO("*** Begin :: UserSeq=".$_SESSION['useridkey'].", srcLang=".$srcLang);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);


$Response = array();
$ResText="";
$isOK = 1;

// project - DB Insert
$useridkey = $_SESSION['useridkey']; 
$svccode = $_SESSION['svccode'];
$ProjectName = exec('uuidgen');
$ProjectName = strtolower(str_replace('-', '', $ProjectName));

$log->trace( 'File Count : '.count($_FILES['upfile']['name']) );

/*************************** FILE List ************************/
for($i = 0; $i < count($_FILES['upfile']['name']) && $isOK==1; $i++){
	// $SaveFileName = exec('uuidgen');
	// $SaveFileName = strtolower(str_replace('-', '', $SaveFileName));

	// $uploadfile = $UpFilePath.$SaveFileName;
	$uploadfile = $UpFilePath.$ProjectName;

	$OriFilePathInfo = pathinfo($_FILES['upfile']['name'][$i]);

	$OriFileName     = $OriFilePathInfo["filename"];
	if (class_exists('Normalizer')) {
		if (Normalizer::isNormalized($OriFileName, Normalizer::FORM_D))
			$OriFileName = Normalizer::normalize($OriFileName, Normalizer::FORM_C);
	}
	$OriFileName = $OriFileName.".".$OriFilePathInfo["extension"];

	$log->trace( $OriFileName );
	$log->trace( $_FILES['upfile']['tmp_name'][$i] );
	$log->trace( $uploadfile );

	if( move_uploaded_file($_FILES['upfile']['tmp_name'][$i], $uploadfile) ){ // File Upload
		$log->trace( "파일이 업로드 되었습니다. : ".$uploadfile);
		$log->trace($_FILES['upfile']['name'][$i]." / ".$_FILES['upfile']['size'][$i]." / ".$_FILES['upfile']['type'][$i]);

		$sql = "INSERT INTO ".$TableName."_Job (sdate, useridkey, svccode, projectname, ori_fname, srcLang, tgtLang) VALUES (";
		$sql = $sql."now(), $useridkey, $svccode, UNHEX('$ProjectName'), '$OriFileName', '$srcLang', '$TgtLang')";
		$log->trace( $sql );
		if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) $isOK = 0;
			//$Response["RText"] = "업로드 파일 정보 저장 실패 - 관리자에게 문의 바랍니다.";
	} else {
		$isOK = 0;
		$ResText = "파일 업로드 실패 !! 다시 시도해주세요.";
	}
}

if ( $isOK == 1 ) {
	$_SESSION['ProjectName'] = strtolower($ProjectName);
	$ResText = "파일 업로드 완료";
	mysqli_commit($DBCon);
} 
else 
	mysqli_rollback($DBCon);
mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( strlen($ResText)>0 ) {
	$Response["RText"] = $ResText;
	$log->trace( $ResText );
}

print json_encode($Response);

$log->trace("RES : ".json_encode($Response));

if ( $isOK == 1 ) {
	$log->trace("CAll Begin speech_proc_bg_analysis");
	shell_exec('php speech_proc_bg_analysis.do '.$BizType.' '.$ProjectName.' > /dev/null 2>/dev/null &'); 
	$log->trace("CAll End speech_proc_bg_analysis");
}

?>
