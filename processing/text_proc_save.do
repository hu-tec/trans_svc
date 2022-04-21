<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('text_proc_save');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$SrcLang = $_POST["SrcLang"];
	$TgtLang = $_POST["TgtLang"];
    $TextLen = $_POST["TextLen"];
	$Text    = $_POST["Text"];

	$useridkey   = $_SESSION['useridkey'];
	$svccode     = $_SESSION['svccode'];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$log->trace("********** useridkey=".$useridkey." **********");
$log->trace(" SrcLang : ".$SrcLang." TgtLang : ".$TgtLang);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$isUpdate=0;
$isOK = 1;
$Response = array();

$All_Src_Text = "";
$Cnt = 0;
foreach ($Text as $One) {
    if ( $Cnt > 0 ) $All_Src_Text = $All_Src_Text."\r\n";
    $All_Src_Text = $All_Src_Text.preg_replace("/\'/","\\'", $One);
    $Cnt++;
    $log->trace("One Source Text : [".$One."]");
}
$log->trace("ALL Source Text : [".$All_Src_Text."]");

$sql = "SELECT hex(projectname) as projectname FROM MT_Job";
$sql = $sql." where flag=0 and status<=2";
$sql = $sql." and useridkey=".$_SESSION['useridkey']." and svccode=".$_SESSION['svccode'];
$sql = $sql." order by sdate desc limit 1";
$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($ResText);
}
else {
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		$ProjectName = $row['projectname'];
		$log->trace( "PRJNAME Get From DB : ".$ProjectName );
		$isUpdate = 1;
	}
	else {
		$ProjectName = exec('uuidgen');
		$ProjectName = strtolower(str_replace('-', '', $ProjectName));
		$log->trace( "PRJNAME NEW : ".$ProjectName );
	}
}

if ( $isOK == 1 ) {
    if ( $isUpdate == 0 ) {
        $sql = "INSERT INTO MT_Job (sdate, useridkey, svccode, projectname, srcLang, tgtLang, src_text, tgt_text, numofchar) VALUES (";
        $sql = $sql."now(), $useridkey, $svccode, UNHEX('$ProjectName'), '$SrcLang', '$TgtLang', '$All_Src_Text', '', $TextLen)";
    }
    else {
        $sql = "UPDATE MT_Job SET sdate=now(), cost=0, status=1, trans_type=0, qa_premium=0, urgent=0, expert_category='-', prediction_time=0";
		$sql = $sql." ,srcLang='".$SrcLang."', tgtLang='".$TgtLang."', src_text='".$All_Src_Text."', tgt_text='', numofchar=".$TextLen;
		$sql = $sql." where flag=0 and projectname = UNHEX('".$ProjectName."')";
		$sql = $sql." and useridkey=".$_SESSION['useridkey']." and svccode=".$_SESSION['svccode'];
    }
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);
}

if ( $isOK == 1 ) mysqli_commit($DBCon);
else  mysqli_rollback($DBCon);
mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( $isOK == 1 ) {
    $_SESSION['ProjectName'] = $ProjectName;
}
$log->trace("SEND Result : ".json_encode($Response));
print json_encode($Response);
?>