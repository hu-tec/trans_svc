<?
header("Content-Type: application/json");

require_once 'include.do';
require_once $include_db;

Logger::configure($MMS_Logger_Config);  // FATAL < ERROR < WARN < INFO < DEBUG < TRACE
$log = Logger::getLogger('com_proc_calc_cost');

if ( !isset( $_SESSION['useridkey'] ) ) {
	$log->fatal("로그인없이 접근");
	exit;
}

if ( $_SERVER["REQUEST_METHOD"] == "POST" ) {
	$BizType        = $_POST["BizType"];
	$Trans_Type     = $_POST["Trans_Type"];
	$AI_UType       = $_POST["AI_UType"];
	$Layout         = $_POST["Layout"];
	$Urgent         = $_POST["Urgent"];
	$Trans_Quality  = $_POST["QPremium"];
	$ExpertCategory = $_POST["ExpertCategory"];
}
else {
	$log->fatal("비정상 접속");
	exit;
}

$TableName = "";
if ( $BizType == 0 ) $TableName = "MMS";			//문서번역
else if ( $BizType == 1 ) $TableName = "MT";		//TTS
else if ( $BizType == 2 ) $TableName = "STT";		//STT
else if ( $BizType == 3 ) $TableName = "VIDEO";		//영상
else if ( $BizType == 4 ) $TableName = "S2S";		
else if ( $BizType == 5 ) $TableName = "YOUTUBE";	//유투브

$log->info("[Cost Calc] User:".$_SESSION['useridkey'].", BizType:".$BizType.", DB:".$TableName);
$log->info("[Cost Calc] Trans_Type:".$Trans_Type);
$log->info("[Cost Calc] Layout:".$Layout);
$log->info("[Cost Calc] Urgent:".$Urgent);
$log->info("[Cost Calc] Trans_Quality:".$Trans_Quality);
$log->info("[Cost Calc] ExpertCategory:".$ExpertCategory);

$isOK = 1;
$Response = array();

if ( !DB_Connect($DBCon, $ResText) ) JSON_MsgReturn($DBCon, "isOK", 0, "RText", $ResText);

if ( isset( $_SESSION['ProjectName'] ) ) {
	$ProjectName = $_SESSION['ProjectName'];
}
else {
	if ( $BizType == 0 ) {
		$sql = "SELECT hex(MMS_Project.projectname) as projectname";
		$sql = $sql." FROM MMS_Project";
		$sql = $sql." INNER JOIN MMS_Job";
		$sql = $sql." ON MMS_Project.projectname = MMS_Job.projectname";
		$sql = $sql." where MMS_Project.flag=0 && MMS_Job.flag=0 && MMS_Job.status<3";
		$sql = $sql." && MMS_Project.useridkey=".$_SESSION['useridkey']." && MMS_Project.svccode=".$_SESSION['svccode'];
		$sql = $sql." order by MMS_Project.sdate desc limit 1";
	}
	else {
		$sql = "SELECT hex(projectname) as projectname";
		$sql = $sql." FROM ".$TableName."_Job";
		$sql = $sql." where flag=0 && status<3";
		$sql = $sql." && useridkey=".$_SESSION['useridkey']." && svccode=".$_SESSION['svccode'];
		$sql = $sql." order by sdate desc limit 1";
	}

	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
		$log->ERROR($ResText);
	}
	else {
		if ( $row = mysqli_fetch_array($DBQRet) ) {
			$ProjectName = strtolower($row['projectname']);
			$_SESSION['ProjectName'] = $ProjectName;
			$log->trace( "PRJNAME Get From DB : ".$ProjectName );
		}
	}
}
$log->info("[Cost Calc] Project:".$ProjectName);

if ( $isOK == 1 ) {
	$sql = "SELECT";
	if ( $BizType == 0 ) // DOC
		$sql = $sql." jobid, numofchar as reqvalue, numofword, numoftu";
	else if ( $BizType == 1 ) // TTS
		$sql = $sql." numofchar as reqvalue";
	else
		$sql = $sql." duration as reqvalue";

	$sql = $sql." FROM ".$TableName."_Job";
	$sql = $sql." where projectname = UNHEX('".$ProjectName."') and flag=0";
	$log->trace( $sql );
	if ( !DB_Query($DBCon, $sql, $DBQRet, $ResText) ) {
		$isOK = 0;
	}
}

if ( $BizType == 0 ) { // DOC
	$Unit_Cost_Basic    =  1.4640; // unused
	$Unit_Cost_Standard =  1.4640;
	$Unit_Cost_Deluxe   = 44.8384;
	$Unit_Cost_Premium  = 50.5000;
}
else if ( $BizType == 1 ) { // TTS
	$Unit_Cost_Basic    =  0.8688;
	$Unit_Cost_Standard = 15.4885;
	$Unit_Cost_Deluxe   = 19.2110;
	$Unit_Cost_Premium  = 39.8122;
}
else if ( $BizType == 2 || $BizType == 3 ) { // STT & Video
	$Unit_Cost_Basic    =  1.9200;
	$Unit_Cost_Standard = 42.2473;
	$Unit_Cost_Deluxe   = 43.4953;
	$Unit_Cost_Premium  = 88.1381;
}
else if ( $BizType == 4 ) { // S2S
	$Unit_Cost_Basic    =  4.3392; // unused
	$Unit_Cost_Standard =  4.3392; // unused
	$Unit_Cost_Deluxe   =  4.3392;
	$Unit_Cost_Premium  = 93.4408;
}
else if ( $BizType == 5 ) { // Youtube
	$Unit_Cost_Basic    =  1.4400;
	$Unit_Cost_Standard = 31.3182;
	$Unit_Cost_Deluxe   = 32.4724;
	$Unit_Cost_Premium  = 80.2090;
}
$Check_Time_Trans_Review = 4.1740;
$Check_Time_Human_Trans  = 4.1740;
$Check_Time_Audio_Text   = 2;

if ( $isOK == 1 ) {
	$TotalCost = 0;
	$PredictionTime=0;

	while($row = mysqli_fetch_array($DBQRet)) {
		if ( $BizType == 0 ) 
			$JobUid = $row['jobid'];

		$reqvalue = (int)$row['reqvalue'];
		$log->info("[Cost Calc] Saved ReqValue = ".$reqvalue);

		$One_Cost=0;
		$One_Time=0;

		$Page = ceil($reqvalue/650); // 650자/A4
		$OneDay = 60*60*8; // Second

		$One_Time = $reqvalue + 300; // + 5 Min (System default)

		/*************** Cost *******************/
		if ( $Trans_Type == 1 )      $One_Cost = $reqvalue * $Unit_Cost_Basic;
		else if ( $Trans_Type == 2 ) $One_Cost = $reqvalue * $Unit_Cost_Standard;
		else if ( $Trans_Type == 3 ) $One_Cost = $reqvalue * $Unit_Cost_Deluxe;
		else if ( $Trans_Type == 4 ) $One_Cost = $reqvalue * $Unit_Cost_Premium;
		$log->trace("Type : Cost = ".$One_Cost);

		if ( $Layout == 1 ) { // Layout Calculation - Only DOC
			$One_Cost = $One_Cost + $Page * 3000;
			$log->trace("Layout : Cost = ".$One_Cost.", Page = ".$Page);
		}
		if ( $Trans_Quality == 1 ) { // Premium Quality Calculation (30%) )
			$One_Cost = $One_Cost + ceil($One_Cost * 0.3);
			$log->trace("QA Premium : Cost = ".$One_Cost);
		}
		if ( $Urgent == 1 ) { // Urgent Calculation (30%)
			$One_Cost = $One_Cost + ceil($One_Cost * 0.3);
			$log->trace("Urgent : Cost = ".$One_Cost);
		}
		$One_Cost = ceil($One_Cost);

		/*************** Prediction Time ******************* 60*60 : Manager-Expert Communication Max Delay Time */
		if ( $BizType == 0 ) { // DOC
			if ( $Trans_Type == 1 ) {} // unused
			else if ( $Trans_Type == 2 ) {} // Only AI
			else if ( $Trans_Type == 3 ) $One_Time = $One_Time + 60*60 + $reqvalue * $Check_Time_Trans_Review;
			else if ( $Trans_Type == 4 ) $One_Time = $One_Time + 60*60 + $reqvalue * $Check_Time_Human_Trans;
		}
		else if ( $BizType == 1 ) { // TTS
			if ( $Trans_Type == 1 ) {} // // Only AI
			else if ( $Trans_Type == 2 ) {} // Only AI
			else if ( $Trans_Type == 3 ) $One_Time = $One_Time + 60*60 + $reqvalue * $Check_Time_Trans_Review;
			else if ( $Trans_Type == 4 ) $One_Time = $One_Time + 60*60 + $reqvalue * $Check_Time_Human_Trans;
		}
		else if ( $BizType == 2 || $BizType == 3 || $BizType == 5 ) { // STT & Video & YOUTUBE
			if ( $Trans_Type == 1 ) {} // // Only AI
			else if ( $Trans_Type == 2 ) $One_Time = $One_Time + 60*60 + $reqvalue * $Check_Time_Audio_Text;
			else if ( $Trans_Type == 3 ) $One_Time = $One_Time + 60*60 + $reqvalue * $Check_Time_Audio_Text;
			else if ( $Trans_Type == 4 ) $One_Time = $One_Time + 60*60 + $reqvalue * $Check_Time_Audio_Text + $reqvalue * $Check_Time_Trans_Review;
		}
		else if ( $BizType == 4 ) { // S2S
			if ( $Trans_Type == 1 ) {} // unused
			else if ( $Trans_Type == 2 ) {} // unused
			else if ( $Trans_Type == 3 ) $One_Time = $One_Time + 60*60 + $reqvalue * $Check_Time_Audio_Text;
			else if ( $Trans_Type == 4 ) $One_Time = $One_Time + 60*60 + $reqvalue * $Check_Time_Audio_Text + $reqvalue * $Check_Time_Trans_Review;
		}
		$log->trace("Type : Prediction Time = ".$One_Time);

		if ( $Layout == 1 ) { // Layout Calculation - Only DOC
			$One_Time = $One_Time + $Page * 15*60; // + 15 Min/Page
			$log->trace("Layout : Prediction Time = ".$One_Time.", Page = ".$Page);
		}
		if ( $Trans_Quality == 1 ) { // Premium Quality Calculation (30%) )
			$One_Time = $One_Time + ceil($One_Time * 0.3);
			$log->trace("QA Premium : Prediction Time = ".$One_Time);
		}
		if ( $Urgent == 1 ) { // Urgent Calculation (1/2)
			$One_Time = ceil($One_Time/2);
			$log->trace("Urgent : Prediction Time = ".$One_Time);
		}
		$One_Time = ceil($One_Time);

		$log->trace("FINAL : Cost = ".$One_Cost.", Prediction Time = ".$One_Time);
		/******************************************************************************************/
		if ( $BizType == 0 ) // DOC
			$sql = "UPDATE ".$TableName."_Job SET trans_type=".$Trans_Type.", ai_utype=".$AI_UType.", layout=".$Layout;
		else
			$sql = "UPDATE ".$TableName."_Job SET status=2, trans_type=".$Trans_Type;
		$sql = $sql.", qa_premium=".$Trans_Quality.", urgent=".$Urgent.", expert_category='".$ExpertCategory."'";
		$sql = $sql.", cost=".$One_Cost.", prediction_time=".$One_Time;
		$sql = $sql." where projectname = UNHEX('".$ProjectName."') && flag=0";
		if ( $BizType == 0 ) $sql = $sql." && jobid ='".$JobUid."'"; // DOC

		$log->trace( $sql );
		if ( !DB_Query($DBCon, $sql, $DBUpRet, $ResText) ) {
			$isOK = 0;
			break;
		}

		$TotalCost = $TotalCost + $One_Cost;
		$PredictionTime = $PredictionTime + $One_Time;
	}

	$Response["TotalCost"] = $TotalCost;
	$Response["PredictionTime"] = $PredictionTime;
}

if ( $isOK == 1 )
	mysqli_commit($DBCon);
else 
	mysqli_rollback($DBCon);

mysqli_close($DBCon);

$Response["isOK"] = $isOK;
if ( $isOK == 0 ) $log->ERROR($ResText);
if ( strlen($ResText) > 0 ) $Response["RText"] = $ResText;
$log->trace("RES : ".json_encode($Response));

print json_encode($Response);

?>
