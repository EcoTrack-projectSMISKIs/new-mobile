

http://192.168.4.1/cm?cmnd=Backlog%20MqttHost%20broker_ip;MqttPort%206888;MqttUser%20user;MqttPassword%20pass;Topic%20topic



// URL TO SEND (SENDS SSID, PASSWORD, MQTT DEETS, THEN SAVES THE DATA AND PLUG RESTARTS) - TO BE USED IN ACTUAL
http://192.168.4.1/cm?cmnd=Backlog%20SSID1%20Yeyen%3BPassword1%20yen22222%3BMqttHost%20gerbil.rmq.cloudamqp.com%3BMqttPort%201883%3BMqttUser%20sxqdvjuz:sxqdvjuz%3BMqttPassword%20u4t_ov_GAu68cqPLJEH4ikfr5oihXzeh%3BTopic%20ecotrack/plug%3BSaveData%201%3BRestart%201


http://192.168.4.1/cm?cmnd=Backlog%20SSID1%20Yeyen%3BPassword1%20yen22222%3BSaveData%201%3BRestart%201


// URL TO SEND (SENDS SSID, PASSWORD, MQTT DEETS, THEN SAVES THE DATA)
http://192.168.4.1/cm?cmnd=Backlog%20SSID1%20Yeyen%3BPassword1%20yen22222%3BMqttHost%20gerbil.rmq.cloudamqp.com%3BMqttPort%201883%3BMqttUser%20sxqdvjuz:sxqdvjuz%3BMqttPassword%20u4t_ov_GAu68cqPLJEH4ikfr5oihXzeh%3BTopic%20ecotrack/plug%3BSaveData%201


// URL TO SEND (MQTT DEETS)
http://192.168.4.1/cm?cmnd=Backlog%20MqttHost%20gerbil.rmq.cloudamqp.com%3BMqttPort%201883%3BMqttUser%20sxqdvjuz:sxqdvjuz%3BMqttPassword%20u4t_ov_GAu68cqPLJEH4ikfr5oihXzeh%3BTopic%20ecotrack/plug


// RULE 1 (AFTER SENDING WIFI CREDS AND MQTT DEETS, PLUG IP SHOULD BE SENT TO DB AND DATA WILL BE SAVED): 
http://192.168.4.1/cm?cmnd=Rule1%20ON%20Wifi#Connected%20DO%20WebSend%20https://ecotrack-kcab.onrender.com/addFromDevice/%ip%/6809b239dccf6d94dcea2bfd20ENDON


// ENABLE RULE
http://192.168.4.1/cm?cmnd=Rule1%20ON



// SEND WIFI CREDS AND RULE 1, SAVES AND RESTARTS
http://192.168.4.1/cm?cmnd=Backlog%20SSID1%20Yeyen;Password1%20yen22222;Rule1%20ON%20Wifi%23Connected%20DO%20WebSend%20https%3A%2F%2Fecotrack-kcab.onrender.com%2FaddFromDevice%2F%25ip%25%2F6809b239dccf6d94dcea2bfd20%20ENDON;Rule1%20ON;Save;Restart%201



/ SEND WIFI CREDS, MDNS TURNED ON, SAVES AND RESTARTS
http://192.168.4.1/cm?cmnd=Backlog%20SSID1%20Yeyen;Password1%20yen22222;Rule1%20ON%20Wifi#Connected%20DO%20mDNS%201%20ENDON;Rule1%20ON;Save;Restart%201

// NEED IN THE APPLICATION
- STORE PREVIOUS WIFI
- SEND WIFI SSID AND PASS TO PLUG
- MQTT DETAILS
- RULE TO TURN ON MDNS
- RECONNECT TO PREVIOUS WIFI AUTOMATICALLY

- SCAN IP ADDRESS OF PLUG USING MDNS AND FETCH IT
- AFTER FETCHING IP ADDRESS, TURN OFF MDNS by making an HTTP call to the plug to disable mDNS: http://<plug-ip>/cm?cmnd=mDNS%200



// NEW FLOW 
- STORE PREVIOUS WIFI
- SEND WIFI SSID AND PASS TO PLUG
- SEND MQTT DETAILS
- RECONNECT TO PREVIOUS WIFI AUTOMATICALLY
- SCAN IP ADDRESS OF PLUG USING IP subnet scanning for Tasmota devices AND FETCH IT
