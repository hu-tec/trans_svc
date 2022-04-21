<?
setlocale(LC_ALL,'ko_KR.UTF-8');
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('expert_doc_result_upload');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$JobName     = $_POST["JobName"];
}
else  {
	$log->FATAL("비정상 접속");
	exit;
}

$log->trace("*************** DOC Result File Upload **************");
$log->INFO("*** Begin :: UserSeq=".$_SESSION['useridkey'].", 문서번역 JobName=".$JobName);

$Response = array();
$isOK = 1;

/*************************** FILE List ************************/
$uploadfile = $DownFilePath.$JobName;

$log->trace( $_FILES['upfile']['tmp_name'][0] );
$log->trace( $uploadfile );

if( move_uploaded_file($_FILES['upfile']['tmp_name'][0], $uploadfile) ){ // File Upload
	$log->trace( "파일이 업로드 되었습니다. : ".$uploadfile);
	$log->trace($_FILES['upfile']['name'][0]." / ".$_FILES['upfile']['size'][0]." / ".$_FILES['upfile']['type'][0]);
} else {
	$isOK = 0;
	$Response["RText"] = "파일 업로드 실패 !! 다시 시도해주세요.";
	$log->info( $Response["RText"] );
}

$Response["isOK"] = $isOK;
print json_encode($Response);

$log->trace("RES : ".json_encode($Response));

?>
