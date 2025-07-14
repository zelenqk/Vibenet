/*
ERROR CODES EXPLANATION

MS - Main server
	CU - connection unsuccessfull
	TM - timed out
	KC - kicked
	BN - banned

PS - Punch socket
	US - Unknown socket (not part of loopback chain)

MC - miscellaneous (only reliable information will be the description variable)


*/


function error(code, description = ""){
	code = string_split(code, "_", true, 1);
	
	var op = code[0]
	code = code[1];
	
	switch (op){
	case "MS":
		mainserver_errors(code, description);
		break;
	case "PS":
		punchsocket_errors(code, description);
		break;
	case "MC":
		
		break;
	default:	//unknown error
		show_message_async("Unknown error with code " + op + " (" + code + ")\n" + description)
		break;
	}
}

function mainserver_errors(code, description){
	switch (code){
	case "CU":
		var err = "Connection to main server was unsuccesfull";
		console.log(err, c_red);
		break;
	}
}

function punchsocket_errors(code, description){
	switch (code){
	case "US":
		console.log("Unknown socket " + string(description) + " is not part of p2p loopback");
		break;
	}
}