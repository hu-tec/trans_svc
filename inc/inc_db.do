<?
define("DB_SERVER", "localhost");
define("DB_ID",     "hutechc");
define("DB_PWD",    "hutechc@01");
define("DB_SCHEMA", "HutechC");
/******************************************************************/
function DB_Connect(&$con, &$ErrText) {
	ini_set('display_errors', '0');
	$con = mysqli_connect(DB_SERVER, DB_ID, DB_PWD, DB_SCHEMA);

	mysqli_autocommit($con, FALSE);

	if ( mysqli_connect_errno() ) {
		$ErrText = "DB 연결 실패(관리자 문의) - Error Code : ".mysqli_connect_errno();
		return false;
	}
	return true;
}

/******************************************************************/
function DB_Query($con, $sql, &$Ret, &$ErrText) {
	if( ($Ret = mysqli_query($con, $sql)) == false ) {
		$ErrText = "DB Query 실패 : ".mysqli_error($con);
		return false;
	}
	return true;
}

/******************************************************************/
function DB_RowCount($Ret) {
	$total_rows = mysqli_num_rows($Ret);
	return $total_rows;
}

/******************************************************************/
function JSON_MsgReturn($con) {

	if ( $con != false ) mysqli_close($con);

	$RetArray = array();
	$arr = func_get_args();
	for( $i = 1; $i < func_num_args(); $i+=2 ) {
		$RetArray[ $arr[$i] ] = $arr[$i+1];
	}
	echo(json_encode($RetArray));
	exit;
}

?>
