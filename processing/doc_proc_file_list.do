<?
header("Content-Type: application/json; charset=UTF-8");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('doc_proc_file_list');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ($_SERVER["REQUEST_METHOD"] == "POST") {
}
else  {
	$log->fatal("비정상 접속");
	exit;
}

$useridkey = $_SESSION['useridkey'];
$svccode   = $_SESSION['svccode'];

$Response = array();
$TotRec = array();
$isOK = 1;
$ProjectName="";

$log->trace("*************** Information Query **************");

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

if ( isset( $_SESSION['ProjectName'] ) ) {
	$ProjectName = $_SESSION['ProjectName'];
}
else {
	$sql = "SELECT hex(MMS_Project.projectname) as projectname";
	$sql = $sql." FROM MMS_Project";
	$sql = $sql." INNER JOIN MMS_Job";
	$sql = $sql." ON MMS_Project.projectname = MMS_Job.projectname";
	$sql = $sql." where MMS_Project.flag=0 && MMS_Job.flag=0 && MMS_Job.status<3";
	$sql = $sql." && MMS_Project.useridkey=".$_SESSION['useridkey']." && MMS_Project.svccode=".$_SESSION['svccode'];
	$sql = $sql." order by MMS_Project.sdate desc limit 1";

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($ResText);
	}
	else {
		if ( $row = mysqli_fetch_array($DBQRet) ) {
			$ProjectName = $row['projectname'];
			$_SESSION['ProjectName'] = strtolower($ProjectName);
			$log->trace( "PRJNAME Get From DB : ".$ProjectName );
		}
		else $isOK = 0;
	}
}

if ( $isOK == 1 ) {
	$log->INFO("*** UserSeq=".$_SESSION['useridkey'].", ProjectName=".$ProjectName);

	// DB Query
	$sql = "SELECT MMS_Job.sdate, hex(MMS_Project.projectname) as projectname, MMS_Project.projectid,";
	$sql = $sql." (SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = MMS_Project.srcLang) as SrcLangText,";
	$sql = $sql." (SELECT LangCode.ko_text FROM LangCode WHERE LangCode.code = MMS_Project.tgtLang) as TgtLangText,";
	$sql = $sql." MMS_Project.srcLang, MMS_Project.tgtLang, MMS_Job.jobid, concat(MMS_Job.ori_fname, '.', MMS_Job.ext_file) as ori_fname,";
	$sql = $sql." hex(MMS_Job.tmp_fname) as tmp_fname, MMS_Job.numofchar, MMS_Job.numofword, MMS_Job.numoftu, MMS_Job.cost, MMS_Job.status,";
	$sql = $sql." MMS_Job.trans_type, MMS_Job.ai_utype, MMS_Job.layout, MMS_Job.qa_premium, MMS_Job.urgent, MMS_Job.expert_category, MMS_Job.prediction_time";
	$sql = $sql." FROM MMS_Project";
	$sql = $sql." INNER JOIN MMS_Job";
	$sql = $sql." ON MMS_Project.projectname = MMS_Job.projectname";
	$sql = $sql." where MMS_Project.flag=0 && MMS_Job.flag=0 && MMS_Job.status<3 && MMS_Project.useridkey=".$_SESSION['useridkey']." && MMS_Project.svccode=".$_SESSION['svccode'];
	$sql = $sql." and MMS_Project.projectname = UNHEX('".$ProjectName."')";

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($ResText);
	}
}

if ( $isOK == 1 ) {
	$cnt=1;
	while($row = mysqli_fetch_array($DBQRet)) {
		$OneRec = array();

		$OneRec["seq"]         = $cnt;

		$OneRec["projectname"] = strtolower($row['projectname']);
		$OneRec["projectid"]   = $row['projectid'];

		$OneRec["srcLang"]     = $row['srcLang'];
		$OneRec["tgtLang"]     = $row['tgtLang'];

		$OneRec["jobid"]       = $row['jobid'];

		$OneRec["ori_fname"]   = $row['ori_fname'];
		if (class_exists('Normalizer')) {
			if (Normalizer::isNormalized($OneRec["ori_fname"], Normalizer::FORM_D))
				$OneRec["ori_fname"]= Normalizer::normalize($OneRec["ori_fname"], Normalizer::FORM_C);
		}	
		
		$OneRec["tmp_fname"]   = strtolower($row['tmp_fname']);

		$OneRec["numofchar"]   = $row['numofchar'];
		$OneRec["numofword"]   = $row['numofword'];

		$OneRec["numoftu"]     = $row['numoftu'];

		$OneRec["cost"]        = $row['cost'];

		$OneRec["status"]      = $row['status'];

		$OneRec["trans_type"]      = $row['trans_type'];
		//$OneRec["ai_utype"]   = $row['ai_utype'];
		$OneRec["layout"]          = $row['layout'];
		$OneRec["trans_quality"]   = $row['qa_premium'];
		$OneRec["urgent"]          = $row['urgent'];
		
		$OneRec["prediction_time"] = $row['prediction_time'];
		$OneRec["expert_category"] = $row['expert_category'];

		$OneRec["exist_file_1"] = 0;
		if( file_exists($DownFilePath.$OneRec["tmp_fname"]) )
			$OneRec["exist_file_1"] = 1;
	
		$OneRec["sdate"]     = $row['sdate'];

		$TotRec[] = $OneRec;
		$cnt++;
		//$log->trace("ONE : \n".json_encode($OneRec));
	}
	
	//$log->trace("TOT : \n".json_encode($TotRec));
}
mysqli_close($DBCon);

$Response["data"] = $TotRec;

$log->trace("RES : \n".json_encode($Response));

print json_encode($Response);
?>
