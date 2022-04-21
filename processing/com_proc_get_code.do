<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('com_proc_get_code');

if ( !isset( $_SESSION['useridkey'] ) ) {
	exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
	$isAll     = $_POST['isAll'];
	$TableName = $_POST['Name'];
}
else  {
	$log->fatal("비정상 접속");
	exit;
}

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

$Response = array();

$log->trace("*************** Code get Query **************");

$isOK = 1;

// DB Query
$sql = "SELECT code, ko_text FROM ".$TableName;
//if ( $isAll == 0 ) 
	$sql = $sql." WHERE flag=0";
if ( $TableName == 'LangCode' )
	$sql = $sql." order by ko_text";
else
	$sql = $sql." order by seq";

$log->trace( $sql );
if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
	$isOK = 0;
	$log->ERROR($ResText);
}

if ( $isOK == 1 ) {
	$TotRec = array();
	while($row = mysqli_fetch_array($DBQRet)) {
		$OneRec = array();
		$OneRec["code"] = $row['code'];
		$OneRec["text"] = $row['ko_text'];
		$TotRec[] = $OneRec;
		//$log->trace("ONE : \n".json_encode($OneRec));
	}
	
	//$log->trace("TOT : \n".json_encode($TotRec));
}
mysqli_close($DBCon);

if ( $isOK == 1 ) {
	$Response["isOK"]     = $isOK;
	$Response["CodeList"] = $TotRec;
	$log->trace("RES : \n".json_encode($Response));
}

print json_encode($Response);

?>
