#macro MAINSERVER_IP "localhost"
#macro MAINSERVER_PORT 6810

#macro HOLEPUNCH_ATTEMPT_SPACING 150
#macro TIMEOUT 1200

enum STATE { IDLE, CONNECTING, ATTEMPTING_HOLEPUNCH, CONNECTED, RELAYED }
enum TYPE { SYN, AKCNOWLEDGE, }

function main(username) constructor{
	self.username = username;
	
	socket = network_create_socket(network_socket_udp);
	punch = new puncher();
	
	state = STATE.IDLE;
	
	//basic util
	send = function(buffer){
		var size = buffer_get_size(buffer);
		var prefix = buffer_create(size + 4, buffer_fixed, 1);
		
		buffer_write(prefix, buffer_u32, size);
		buffer_copy(buffer, 0, size, prefix, 4);
		
		network_send_udp_raw(socket, prefix, buffer_get_size(prefix));
		buffer_delete(prefix);
	}
	
		//connection
		tries = 0;
		
		SYN = function(){
			var syn = buffer_create(1, buffer_fixed, 1);
			buffer_write(syn, buffer_u8, TYPE.SYN);
			
			send(syn);
			buffer_delete(syn);	
		}
	
	connect = function(){
		state = STATE.CONNECTING;
		SYN();
	}
	
	findLobby = function(tag = ""){
		var buffer = buffer_create(string_byte_length(tag) + 4, buffer_fixed, 1);
		buffer_write(buffer, buffer_u8, 0x01);
		buffer_write(buffer, buffer_u16, punch.port);
		buffer_write(buffer, buffer_string, tag);
		
		send(buffer);
		buffer_delete(buffer);
		
		console.log("started looking for lobby");
	}
	
	step = function(){
		punch.step();
	}
	
	async = function(){
		var sock = async_load[? "id"];
		
		if (sock == punch.socket){
			punch.onData(async_load[? "buffer"]);
			return;
		}
		
		var type = async_load[? "type"];
			
		switch (type){
		case network_type_non_blocking_connect:
			var success = async_load[? "succeeded"];
			
			state = STATE.CONNECTED;
			
			if (!success){
				state = STATE.IDLE
				error("MS_CU");
			}else{
				findLobby();	
			}
			break;
		case network_type_data:
			var buffers = buffer_parse(async_load[? "buffer"]);
			
			for(var i = 0; i < array_length(buffers); i++){
				var buffer = buffers[i]
				onData(buffer);
				buffer_delete(buffer);
			}
			break;
		}
	}
	
	onData = function(buffer){
		var type = buffer_read(buffer, buffer_u8);
		
		switch (type){
		case 0x00:	//initial handshake
			
			break;
		case 0x01:	//lobby found
			var clients = buffer_read(buffer, buffer_u8);
			var tag = buffer_read(buffer, buffer_string);
			console.log("joined lobby - " + tag);
			
			repeat (clients){
				var ip = buffer_read(buffer, buffer_string);
				var port = buffer_read(buffer, buffer_u16);
				
				punch.add(ip, port);	
			}
			break;
		case 0x02:	// a new client joined the lobby
			var ip = buffer_read(buffer, buffer_string);
			var port = buffer_read(buffer, buffer_u16);
			
			console.log("socket " + ip + ":" + string(port) + " has joined the lobby");
			punch.add(ip, port);
			break;
		case 0x05:	//lobby is full
			console.log("Lobby is full");
			break;
		case 0xFF:
			punch.onData(buffer, true);
			break;
		}
	}
}

function puncher() constructor{
	msocket = other.socket;

	var psock = create_socket(network_socket_udp);
	socket = psock.socket;
	port = psock.port;
	
	connections = {
		"sockets": {},
		"list": [],
	}
	connectionsN = 0;
	
	add = function(ip, port){
		ip = string_replace_all(ip, "::ffff:", "");
		var socket = ip + " / " + string(port);
		var con = new connection(ip, port);
		
		connections.sockets[$ socket] = con;
		connections.list[array_length(connections.list)] = con;
	}
	
	send = function(buffer, socket){
		var con = connections.list[socket];
		if (con == -1){
			error("PS_US", socket);
			return;
		}
		
		var size = buffer_get_size(buffer);
		
		switch (con.state){
		case STATE.CONNECTED:
			network_send_udp(self.socket, con.ip, con.port, buffer, size);
			break;
		case STATE.RELAYED:
			var prefix = buffer_create(7 + size, buffer_fixed, 1);
			
			buffer_write(prefix, buffer_u8, 0xFF);
			buffer_write(prefix, buffer_u8, 1);
			buffer_write(prefix, buffer_u8, socket);
			buffer_write(prefix, buffer_u32, size);
			
			buffer_copy(buffer, 0, size, prefix, 7);
			
			client.send(prefix);
			buffer_delete(prefix);
			break;
		}
	}
	
	broadcast = function(buffer){
		var size = buffer_get_size(buffer);
		var relay = [];
		
		for(var i = 0; i < array_length(connections.list); i++){
			var con = connections.list[i];
			
			if (con != -1){
				if (con.state == STATE.CONNECTED){
					network_send_udp(self.socket, con.ip, con.port, buffer, size);
				}else{
					array_push(relay, i);
				}
			}
		}
		
		if (array_length(relay) <= 0) return;
		
		//relay to clients who are behind a symetric nat
		var relayN = array_length(relay);
		var prefix = buffer_create(2 + size + relayN, buffer_fixed, 1);
		
		buffer_write(prefix, buffer_u8, 0xFF);	//relay opcode
		buffer_write(prefix, buffer_u8, relayN);	//amount of clients to be relayed to
		
		for(var i = 0; i < relayN; i++){
			buffer_write(prefix, buffer_u8, relay[i]);	//client to relay to
		}
		
		buffer_copy(buffer, 0, size, prefix, 2 + relayN);	//packet itself
		
		client.send(prefix)
		buffer_delete(prefix);	//free memory
	}
	
	step = function(){
		for(var i = 0; i < array_length(connections.list); i++){
			var con = connections.list[i];
			con.step();
		}
	}
	
	onData = function(buffer, relay = false){
		var type = buffer_read(buffer, buffer_u8);
		
		switch (type){
		case 0x00:
			var ip = async_load[? "ip"];
			var port = async_load[? "port"];
			var sock = ip + " / " + string(port);
			console.log("Hole punch success (" + sock + ") Attempting to establish connection")
			
			var ping =	buffer_create(1, buffer_fixed, 1);
						buffer_write(ping, buffer_u8, 0x01);
						network_send_udp(self.socket, ip, port, ping, 1);
						buffer_delete(ping);
			break;
		case 0x01:
			var ip = async_load[? "ip"];
			var port = async_load[? "port"];
			var sock = ip + " / " + string(port);
			console.log("Client " + sock + " successfully established connection!");
			
			var con = connections.sockets[$ sock];
			if (con != undefined and con != -1){
				con.state = STATE.CONNECTED;
				timeout = current_time + TIMEOUT;
			}
			break;
		case 0x02:
			oTextbox.messages.add(buffer_read(buffer, buffer_string) + (relay ? " (relayed)" : "(direct)"));
			break;
		}
	}
}

function connection(ip, port) constructor{
	self.ip = ip;
	self.port = port;
	
	socket = other.socket;
	state = STATE.IDLE;
	
	holepunchAttempts = 20;
	timeout = current_time;
	
	connect = function(){
		state = STATE.ATTEMPTING_HOLEPUNCH;
		
		var buffer = buffer_create(1, buffer_fixed, 1);
			buffer_write(buffer, buffer_u8, 0x00);	//simply ping the udp(p2p) client he will check the ip and port on his side to determine holepunch success
			network_send_udp(socket, ip, port, buffer, 1);
			buffer_delete(buffer);
		
		holepunchAttempts--;
		timeout = (current_time + HOLEPUNCH_ATTEMPT_SPACING);
	};
	
	connect();
	
	step = function(){
		if (timeout <= current_time){
			switch (state){
			case STATE.ATTEMPTING_HOLEPUNCH:
				connect();
					
				if (holepunchAttempts <= 0){
					state = STATE.RELAYED;
				}
				break;
			}
		}
	}
	
}

//UTIL
function buffer_parse(buffer){
	var size = buffer_get_size(buffer);
	var buffers = [];
	var i = 0;
	
	while (buffer_tell(buffer) < size){
		var length = buffer_read(buffer, buffer_u32);
		var parsed = buffer_create(length, buffer_fixed, 1);
		buffers[i++] = parsed;
		
		buffer_copy(buffer, buffer_tell(buffer), length, parsed, 0);
		buffer_seek(buffer, buffer_seek_relative, length);
	}
	
	buffer_delete(buffer);
	return buffers;
}

function prefix_buffer(buffer){
	var size = buffer_get_size(buffer);
	var prefix = buffer_create(size + 4, buffer_fixed, 1);
	
	buffer_write(prefix, buffer_u32, size);
	buffer_copy(buffer, 0, size, prefix, 4);
	
	return prefix;
}

function create_socket(type){
	var port = 6810;
	var socket = network_create_socket_ext(type, port);

	while (socket < 0){
		port = (port + 1) % 0xFFFF;
		socket = network_create_socket_ext(type, port);
	}

	return {socket: socket, port: port};
}