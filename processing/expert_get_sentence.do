<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('expert_get_sentence');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$expertid    = $_SESSION['useridkey'];
	$svccode     = $_SESSION['svccode'];
	$utype       = (int)$_SESSION['utype'];

	$svc_type = (int)$_POST["svc_type"];
	$ProjectName = $_POST['Project'];
	$srcLang     = $_POST["srcLang"];
	$tgtLang     = $_POST["tgtLang"];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$log->trace("********** expert = ".$expertid." **********");
$log->trace(" Project: ".$ProjectName);

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

if ( $svc_type == 1 ) $DB_Table_Name = "MT";
else if ( $svc_type == 2 ) $DB_Table_Name = "STT";
else if ( $svc_type == 3 ) $DB_Table_Name = "VIDEO";
else if ( $svc_type == 4 ) $DB_Table_Name = "S2S";
else if ( $svc_type == 5 ) $DB_Table_Name = "YOUTUBE";

$isOK = 1;
$Response = array();
$SrcRec = array();
$TgtRec = array();
$ResText = "";

$sql = "SELECT count(*) as cnt FROM ".$DB_Table_Name."_PostEdit";
$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";
// if ( $utype == 21 )
// 	$sql = $sql." && expert_id=".$expertid;
$sql = $sql." && svccode=".$svccode;

$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($sql);
	$log->ERROR($ResText);
}
else {
	if ( $row = mysqli_fetch_array($DBQRet) ) {
		if ( (int)$row['cnt'] > 0 ) $isOK = 2;
	}
}

if ( $isOK == 2 ) {
	if ( $svc_type == 1 ) { // TTS
		$sql = "SELECT seq, src_text_one, tgt_text_one FROM ".$DB_Table_Name."_PostEdit";
		$sql = $sql." where flag=0 && projectname = UNHEX('".$ProjectName."')";
		// if ( $utype == 21 )
		// 	$sql = $sql." && expert_id=".$expertid;
		$sql = $sql." && svccode=".$_SESSION['svccode'];
		$sql = $sql." order by seq";
	}
	else {
		$sql = "SELECT SRC.seq, SRC.text_one as src_text_one, TGT.text_one as tgt_text_one";
		$sql = $sql." FROM ".$DB_Table_Name."_PostEdit SRC, ".$DB_Table_Name."_PostEdit TGT";
		$sql = $sql." WHERE SRC.flag=0 && SRC.projectname = UNHEX('".$ProjectName."') && SRC.projectname = TGT.projectname";
		$sql = $sql." && SRC.seq=TGT.seq && SRC.lang='".$srcLang."' && TGT.lang='".$tgtLang."'";
		$sql = $sql." && SRC.svccode=".$svccode;
		// if ( $utype == 21 )
		// 	$sql = $sql." && SRC.expert_id=".$expertid;
		$sql = $sql." order by SRC.seq";
	}

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($sql);
		$log->ERROR($ResText);
	}
}
if ( $isOK == 2 ) {
	while($row = mysqli_fetch_array($DBQRet)) {
		$SrcRec[] = $row['src_text_one'];
		$TgtRec[] = $row['tgt_text_one'];
	}
}
$Response["SrcRec"] = $SrcRec;
$Response["TgtRec"] = $TgtRec;

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( strlen($ResText) > 0 )
	$Response["RText"] = $ResText;
$log->trace("SEND Result : ".json_encode($Response));
print json_encode($Response);
?>