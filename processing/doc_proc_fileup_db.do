<?
setlocale(LC_ALL,'ko_KR.UTF-8');
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;
require_once $include_mmsrc;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('doc_proc_fileup_db');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$srcLang     = $_POST["srcLang"];
	$tgtLang     = $_POST["tgtLang"]; 
}
else  {
	$log->FATAL("비정상 접속");
	exit;
}

$log->trace("*************** File Upload **************");
$log->INFO("*** Begin :: UserSeq=".$_SESSION['useridkey'].", 문서번역 srcLang=".$srcLang.", tgtLang=".$tgtLang);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$Response = array();
$isOK = false;
// project - DB Insert
$useridkey = $_SESSION['useridkey']; 
$svccode = $_SESSION['svccode'];
$ProjectName = exec('uuidgen');
$ProjectName = strtolower(str_replace('-', '', $ProjectName));

/************************ Memsource Login *********************/
if ( isset( $_SESSION['token'] ) ) {
	$log->trace("--- exist Login token ---\n".$_SESSION['token']);
	$isOK = MMSrc_WhoAmI();
}
if ( $isOK == false ) {
	$isOK = MMSrc_Login( 1 );
}
if ( $isOK == true ) {
	$sql = "INSERT INTO MMS_Project (useridkey, svccode, projectname, sdate, srcLang, tgtLang) VALUES (";
	$sql = $sql."$useridkey, $svccode, UNHEX('$ProjectName'), now(), '$srcLang', '$tgtLang')";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);
}

/*************************** FILE List ************************/
for($i = 0; $i < count($_FILES['upfile']['name']) && $isOK==true; $i++){
	$SaveFileName = exec('uuidgen');
	$SaveFileName = strtolower(str_replace('-', '', $SaveFileName));

	$uploadfile = $UpFilePath.$SaveFileName;

	$OriFilePathInfo = pathinfo($_FILES['upfile']['name'][$i]);

	$OriFileName     = $OriFilePathInfo["filename"];
	if (class_exists('Normalizer')) {
		if (Normalizer::isNormalized($OriFileName, Normalizer::FORM_D))
			$OriFileName = Normalizer::normalize($OriFileName, Normalizer::FORM_C);
	}

	$OriFileExt		 = strtolower($OriFilePathInfo["extension"]);
	$log->trace( $_FILES['upfile']['tmp_name'][$i] );
	$log->trace( $uploadfile );
	if( move_uploaded_file($_FILES['upfile']['tmp_name'][$i], $uploadfile) ){ // File Upload
		$log->trace( "파일이 업로드 되었습니다. : ".$uploadfile);
		$log->trace($_FILES['upfile']['name'][$i]." / ".$_FILES['upfile']['size'][$i]." / ".$_FILES['upfile']['type'][$i]);

		$sql = "INSERT INTO MMS_Job (projectname, tmp_fname, sdate, ext_file, ori_fname) VALUES (";
		$sql = $sql."UNHEX('$ProjectName'), UNHEX('$SaveFileName'), now(), '$OriFileExt', '$OriFileName')";
		$log->trace( $sql );
		if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
			$isOK = false;
			$Response["RText"] = "업로드 파일 정보 저장 실패 - 관리자에게 문의 바랍니다.";
		}
	} else {
		$isOK = false;
		$Response["RText"] = "파일 업로드 실패 !! 다시 시도해주세요.";
		$log->info( $Response["RText"] );
	}
}

if ( $isOK == true ) {
	$_SESSION['ProjectName'] = strtolower($ProjectName);
	$Response["RText"] = "파일 업로드 완료";
	mysqli_commit($DBCon);
} 
else 
	mysqli_rollback($DBCon);
mysqli_close($DBCon);

$Response["isOK"] = ($isOK?"1":"0");
print json_encode($Response);

$log->trace("RES : ".json_encode($Response));

?>
