#include <a_samp>
#include <a_mysql>
#include <zcmd>
#include <sscanf2>

#include <SM_controls\defines>
#include <SM_controls\modes>


forward acc_SetLoginData(playerid,aid,admin,vip,xp,money,kills,deaths,hours,minutes,seconds);
forward acc_ShowLoginDialog(playerid,idx);
forward acc_ShowRegisterDialog(playerid);
forward acc_SaveStats();
forward acc_SavePlayerStats(playerid);
forward acc_BanPlayer(targetid,admin[],reason[]);
forward acc_ShowBanDialog(playerid,name[],admin[],reason[],ip[],date[]);
forward KickPlayer(playerid);


forward acc_GetAdmin(playerid);
forward acc_SetAdmin(playerid,lvl);
forward acc_AddScore(playerid,score);

enum pInfo {
	AccID,
	bool:Logged,
	Name[MAX_PLAYER_NAME],
	IP[16],
	Admin,
	Vip,
	XP,
	Money,
	Time_Money_Given,
	Kills,
	Deaths,
	Hours,
	Minutes,
	Seconds,
	bool:PM,
	SMPoints
	/*bool:Radio,
	VipJoinMsg[128],
	bool:PM,*/
}

new Player[MAX_PLAYERS][pInfo];
new str[128], bool:chat;

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Account Filterscript - INITIALIZED ");
	print("--------------------------------------\n");

	//enable the chat
	chat = true;

	return 1;
}

public OnFilterScriptExit()
{
	print("\n--------------------------------------");
	print(" Account Filterscript - UNLOADED! ");
	print("--------------------------------------\n");
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	return 1;
}

public OnPlayerConnect(playerid)
{
	new welcomemsg[128];
	GetPlayerName(playerid,Player[playerid][Name],MAX_PLAYER_NAME);
	GetPlayerIp(playerid, Player[playerid][IP], 16);
	format(welcomemsg,sizeof(welcomemsg),"[CONNECT] %s (%i) has joined the Server.",Player[playerid][Name],playerid);
	SendClientMessageToAll(COLOR_GREY,welcomemsg);
	
	Player[playerid][PM] = true;

	CallRemoteFunction("DB_PlayerBanCheck","i",playerid);

	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	new leavemsg[128];

	acc_SavePlayerStats(playerid);

	Player[playerid][AccID] = -1;
	Player[playerid][Admin] = 0;
	Player[playerid][Vip] = 0;
	Player[playerid][Kills] = 0;
	Player[playerid][Deaths] = 0;
	Player[playerid][Money] = 0;
	Player[playerid][Hours] = 0;
	Player[playerid][Minutes] = 0;
	Player[playerid][Seconds] = 0;

	Player[playerid][Logged] = false;

	format(leavemsg,sizeof(leavemsg),"[DISCONNECT] %s (%i) has left the Server.",Player[playerid][Name],playerid);
	SendClientMessageToAll(COLOR_GREY,leavemsg);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	Player[playerid][Deaths]++;
	if(killerid != INVALID_PLAYER_ID && IsPlayerConnected(killerid))
	{
		Player[killerid][XP]++;
		Player[killerid][Kills]++;
 	}
 /*
	switch(Player[killerid][Kills])
	{
	    case 10: { break; }
	    case 100: { break;}
	    case 1000: { break;}
	}
 */
	return 1;
}

public OnPlayerText(playerid, text[])
{
   	new pText[144];
 	
	 //IRC & ADMIN CHAT KEYS
	if(text[0] == '#') {
		format(pText, sizeof(pText), "0,10%s (%i) says: %s", Player[playerid][Name], playerid, text[1]);
	    CallRemoteFunction("IRC_Text", "s", pText);
	    SendClientMessage(playerid, COLOR_YELLOW, "Your message has been delivered to our IRC channel.");
	    return 0;
	}
	if(text[0] == '@') {
		if(Player[playerid][Admin] > 0) {
			format(pText,sizeof(pText),"[ADMIN] %s (%i): %s", Player[playerid][Name], playerid, text[1]);
			for(new i=0;i<MAX_PLAYERS;i++)
			{
				if(IsPlayerConnected(i) && Player[i][Admin] > 0) SendClientMessage(playerid,COLOR_RED,pText);
			}
			
			format(pText,sizeof(pText),"4[ADMIN] %s(%d): 7%s", Player[playerid][Name], playerid, text[1]);
			CallRemoteFunction("IRC_Admin_Text", "s", pText);
			return 0;
		}
	}
	if(text[0] == '!' || text[0] == ';') {
	    for(new i = 0; i < MAX_PLAYERS; i ++) {
	        if(IsPlayerConnected(i) && GetPlayerTeam(i) == GetPlayerTeam(playerid)) {
	    		format(pText, sizeof(pText), "[TEAM] %s (%i): %s", Player[playerid][Name], playerid, text[1]);
	    		SendClientMessage(playerid, -1, pText);
			}
			return 0;
		}
	}
	
	if(chat)
	{
	 	format(pText, sizeof (pText), "(%d) %s", playerid, text);
	    SendPlayerMessageToAll(playerid, pText);
	   	format(pText, sizeof(pText), "07%s (%i): 2%s", Player[playerid][Name], playerid, text);
		CallRemoteFunction("IRC_Text", "s", pText);
	}
	else
	{
	    SendClientMessage(playerid,COLOR_RED,"The Chat Function has been disabled by an Administrator");
	}
    return 0; // ignore the default text and send the custom one
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	return 1;
}

public OnRconCommand(cmd[])
{
	return 1;
}

public OnPlayerRequestSpawn(playerid)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	return 1;
}

public OnRconLoginAttempt(ip[], password[], success)
{
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
	    case DIALOG_LOGIN:
		{
	        if(!response) { Kick(playerid); return 1; }
			if(strlen(inputtext) > 5 && strlen(inputtext) < 32)
			{
				CallRemoteFunction("DB_PlayerLogin","is",playerid,inputtext);
			}
			else
			{
			    acc_ShowLoginDialog(playerid,1);
			}
		}
	    case DIALOG_REGISTER:
		{
	        if(!response) { SendClientMessage(playerid,COLOR_YELLOW,"You must register in order to play, so you got kicked!"); Kick(playerid); return 1;}

	        if(strlen(inputtext) <= 5 || strlen(inputtext) >= 32)
			{
			    str = "{FF0000}Error on Registration!\n{FFFFFF}Your password must have at least 5 characters and not more than 32 characters.";
				ShowPlayerDialog(playerid,DIALOG_REGISTER,DIALOG_STYLE_PASSWORD,"User Registration",str,"Register!","Cancel");
			}
			else
			{
				CallRemoteFunction("DB_PlayerRegister","isss",playerid,Player[playerid][Name],Player[playerid][IP],inputtext);

				format(str, sizeof(str), "4%s (%d) is now a Registered User.", Player[playerid][Name], playerid);
				CallRemoteFunction("IRC_Text", "s", str);
			}
	    }
	}
	return 1;
}

/* -- CUSTOM FUNCTIONS -- */
public acc_SetLoginData(playerid,aid,admin,vip,xp,money,kills,deaths,hours,minutes,seconds)
{

	Player[playerid][AccID] = aid;
	Player[playerid][Admin] = admin;
	Player[playerid][Vip] = vip;
	Player[playerid][XP] = xp;
	Player[playerid][Money] = money;
	Player[playerid][Kills] = kills;
	Player[playerid][Deaths] = deaths;

	Player[playerid][Hours] = hours;
	Player[playerid][Minutes] = minutes;
	Player[playerid][Seconds] = seconds;

	Player[playerid][Logged] = true;
	
	GivePlayerMoney(playerid,Player[playerid][Money]);
	SetPlayerScore(playerid,Player[playerid][XP]);
	
	format(str,sizeof(str),"Welcome back, %s!",Player[playerid][Name]);
	SendClientMessage(playerid,COLOR_YELLOW,str);

	return 1;
}

public acc_ShowLoginDialog(playerid,idx)
{
	new text[256];
	if(idx == 0)
	    format(text,sizeof(text),"{FFFFFF}Hello {FF8800}%s\n{FFFFFF}Please enter your password below to Login.",Player[playerid][Name]);
	else
		text = "{FF0000}Wrong Password!\n{FFFFFF}Enter the correct Password or choose another Nickname.";

	ShowPlayerDialog(playerid,DIALOG_LOGIN,DIALOG_STYLE_PASSWORD,"User Login",text,"Login!","Cancel");
	return 1;
}

public acc_ShowRegisterDialog(playerid)
{
	new text[256];
	format(text,sizeof(text),"{FFFFFF}Hello {FF8800}%s\n{FFFFFF}This Username has not been found in our database.\nEnter a password below to Register.",Player[playerid][Name]);
	ShowPlayerDialog(playerid,DIALOG_REGISTER,DIALOG_STYLE_PASSWORD,"User Registration",text,"Register!","Cancel");
	return 1;
}

public acc_SaveStats()
{
	for(new i=0;i<MAX_PLAYERS;i++)
	{
		if(IsPlayerConnected(i)) acc_SavePlayerStats(i);
	}
	return 1;
}

public acc_SavePlayerStats(playerid)
{
	//Store data in DB
	CallRemoteFunction("DB_SavePlayerData","iiiiiiiiiis",Player[playerid][AccID],Player[playerid][Admin],Player[playerid][Vip], Player[playerid][Kills], Player[playerid][Deaths],Player[playerid][Money],Player[playerid][Hours],Player[playerid][Minutes],Player[playerid][Seconds],Player[playerid][XP],Player[playerid][IP]);
	return 1;
}

public acc_BanPlayer(targetid,admin[],reason[])
{
	acc_ShowBanDialog(targetid,Player[targetid][Name],admin,reason,Player[targetid][IP],"NOW");
	CallRemoteFunction("DB_BanPlayer","ssss",Player[targetid][Name],admin,Player[targetid][IP],reason);
	
	SetTimerEx("KickPlayer",2000,false,"i",targetid);
	
	return 1;
}

public acc_ShowBanDialog(playerid,name[],admin[],reason[],ip[],date[])
{
	new banmsg[512];
	
	str = "{FF0000}You have been banned from Stadium-Madness."; strcat(banmsg,str);
	format(str,sizeof(str),"\n{FFFFFF}Name: {FF8800}%s",Player[playerid][Name]); strcat(banmsg,str);
	format(str,sizeof(str),"\n{FFFFFF}Admin: {FF8800}%s",admin); strcat(banmsg,str);
	format(str,sizeof(str),"\n{FFFFFF}Reason: {FF8800}%s",reason); strcat(banmsg,str);
	format(str,sizeof(str),"\n{FFFFFF}IP: {FF8800}%s",ip); strcat(banmsg,str);
	format(str,sizeof(str),"\n{FFFFFF}Date: {FF8800}%s",date); strcat(banmsg,str);
	str = "\n\n{FF8800}If you think this ban has been given unfairly, appeal on our Forums.(http://stadiummadness.esy.es)"; strcat(banmsg,str);
	str = "\n{FF8800}Please also provide a screenshot (F8) of this dialog."; strcat(banmsg,str);

	ShowPlayerDialog(playerid,DIALOG_BAN,DIALOG_STYLE_MSGBOX,"Stadium-Madness BAN",banmsg,"Close","");

	return 1;
}

/* ------------- COMMANDS --------------------*/

//											Player (Level 0)

CMD:changepass(playerid)
{
	if(!Player[playerid][Logged]) return SendClientMessage(playerid,COLOR_RED,"You are not logged in!");
	ShowPlayerDialog(playerid,DIALOG_CHANGEPASS,DIALOG_STYLE_INPUT,"Change Password","Enter your new desired Password.\nMake sure you do not forget or lose it.","Change","Cancel");
	return 1;
}

CMD:cmds(playerid, params[])
{
	new endstr[256];
	str = "{FFFFFF}Player Commands:\n\n"; strcat(endstr,str);
	str = "{FF8800}/help, /rules, /cmds, /admins, /kill\n"; strcat(endstr,str);
	str = "{FF0000}/pm, /givemoney, /stats, /modes, /account\n"; strcat(endstr,str);
	str = "{FF8800}/lobby, /fix, /exit, /shop, /changepass\n"; strcat(endstr,str);
	str = "{FF0000}/buyvip, /vipinfo, /vipcheck"; strcat(endstr,str);

    ShowPlayerDialog(playerid, DIALOG_CMDS, DIALOG_STYLE_MSGBOX, "Commands",endstr , "Close", "");
	return 1;
}

CMD:exit(playerid)
{
	//DestroyVeh(playerid);
	CallRemoteFunction("GM_ExitMode", "i", playerid);
	return 1;
}

CMD:kill(playerid)
{
	SetPlayerHealth(playerid,0.0);
	return 1;
}

CMD:shop(playerid)
{
	new mode = CallRemoteFunction("GM_GetPlayerMode","i",playerid);
	if(mode == RACE || mode == PARKOUR) return SendClientMessage(playerid,COLOR_RED,"Shop is currently closed");
	ShowPlayerDialog(playerid, DIALOG_SHOP, DIALOG_STYLE_LIST, "{FFFFFF}SHOP","{FF8800}Weapons\n{FF0000}Vehicles\n{FFFFFF}VIP Shop","Select","Close");
	return 1;
}

CMD:lobby(playerid)
{
	cmd_exit(playerid);
	return 1;
}

CMD:givemoney(playerid,params[])
{
	new targetid,amount;

	if(!Player[playerid][Logged]) return SendClientMessage(playerid,COLOR_RED,"You must be logged in to use this command!");
	if(sscanf(params,"ui",targetid,amount)) return SendClientMessage(playerid,COLOR_WHITE,"USAGE: /givemoney [ID/Name] [Amount]");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: Player not connected!");
	if(playerid == targetid) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: You cannot give yourself money!");
	if(Player[playerid][Money] < amount) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: Invalid Amount!");
	if(Player[playerid][Time_Money_Given] > (gettime()-60)) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: You can only use this command once a minute!");

	Player[playerid][Time_Money_Given] = gettime();
	Player[playerid][Money] -= amount; Player[targetid][Money] += amount;
	GivePlayerMoney(playerid,-amount); GivePlayerMoney(targetid,amount);

	format(str,sizeof(str),"%s (%i) has given %s (%i) $%i",Player[playerid][Name],playerid,Player[targetid][Name],targetid,amount);
	SendClientMessageToAll(COLOR_ORANGE,str);

	return 1;
}

CMD:account(playerid)
{
	if(!Player[playerid][Logged]) return SendClientMessage(playerid,COLOR_RED,"You must be logged in to use this command!");

	ShowPlayerDialog(playerid,DIALOG_SETTINGS,DIALOG_STYLE_LIST,"Account Settings","General Settings\nChat Settings\nVIP Settings","Select","Close");
	return 1;
}

CMD:buyvip(playerid)
{
	if(!Player[playerid][Logged]) return SendClientMessage(playerid,COLOR_RED,"You must be logged in to use this command!");
	if(Player[playerid][Vip] > 0) return SendClientMessage(playerid,COLOR_RED,"You already have the VIP status!");

	ShowPlayerDialog(playerid,DIALOG_VIP,DIALOG_STYLE_LIST,"Purchase VIP","{FF8800}BRONZE - 200 SM Points - 1 Week\n\
	{FF0000}SILVER - 500 SM Points - 1 Month\n{FF8800}GOLD - 1000 SM Points - 1 Month","Purchase","Cancel");

	return 1;
}

CMD:vipcheck(playerid)
{
	if(!Player[playerid][Logged]) return SendClientMessage(playerid,COLOR_RED,"You must be logged in to use this command!");
	if(!Player[playerid][Vip]) return SendClientMessage(playerid,COLOR_RED,"You are not a VIP. Use /vipinfo or /buyvip");

	new vName[7];
	switch(Player[playerid][Vip])
	{
	    case 1: vName = "Bronze";
	    case 2: vName = "Silver";
	    case 3: vName = "Gold";
	}
	format(str,sizeof(str),"Your VIP Rank: %s",vName);
	SendClientMessage(playerid,COLOR_ORANGE,str);

	CallRemoteFunction("DB_VipCheck","ii",playerid,Player[playerid][AccID]);

	return 1;
}

/*CMD:radio(playerid)
{
    if(!Player[playerid][Logged]) return SendClientMessage(playerid,COLOR_RED, "You must be logged in to use this command!");
    if(CallRemoteFunction("getMode","i",playerid) != LOBBY) return SendClientMessage(playerid,COLOR_RED, "You're able to use this command in the lobby only");
	if(!Player[playerid][Radio])
	{
          Player[playerid][Radio] = true;
          PlayAudioStreamForPlayer(playerid,"http://charthits-high.rautemusik.fm/listen.pls",0.0,0.0,0.0,0.0,0);
	      SendClientMessage(playerid,COLOR_ORANGE, "[RADIO]You have successfully turned the radio on!");
    }
	else
    {
          Player[playerid][Radio] = false;
          StopAudioStreamForPlayer(playerid);
	      SendClientMessage(playerid,COLOR_ORANGE, "[RADIO]You have successfully turned the radio off!");
	}
	return 1;
}*/

CMD:pm(playerid,params[])
{
	new targetid,msg[150],msgstr[256];
	if(!Player[playerid][Logged]) return SendClientMessage(playerid,COLOR_RED,"You must be logged in to use this command!");
	if(sscanf(params,"uS(No Message)[150]",targetid,msg)) return SendClientMessage(playerid,COLOR_WHITE,"USAGE: /pm [ID/Name] [Message]");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: Player not connected!");
	if(playerid == targetid) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: You cannot send yourself a PM!");
	if(!Player[targetid][PM]) return SendClientMessage(playerid,COLOR_ORANGE,"This Player does not receive Private Messages.");

	//MSG Sender/Recipient
	format(msgstr,sizeof(msgstr),"[PM-SENT]To: %s (%i); %s",Player[targetid][Name],targetid,msg);
	SendClientMessage(playerid,COLOR_YELLOW,msgstr);
	format(msgstr,sizeof(msgstr),"[PM]From: %s (%i); %s",Player[playerid][Name],playerid,msg);
	SendClientMessage(targetid,COLOR_YELLOW,msgstr);

	//Admin NSA Tool
	format(msgstr,sizeof(msgstr),"[PM]From: %s (%i) to %s (%i); %s",Player[playerid][Name],playerid,Player[targetid][Name],targetid,msg);

	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    if(IsPlayerConnected(i) && Player[i][Logged] && Player[i][Admin] > 0) SendClientMessage(i,COLOR_GREY,msgstr);
	}

	//IRC
	format(msgstr,sizeof(msgstr),"14[PM]From: %s (%i) to %s (%i); %s",Player[playerid][Name],playerid,Player[targetid][Name],targetid,msg);
	CallRemoteFunction("IRC_Admin_Text","s",msgstr);
	return 1;
}

CMD:accept(playerid)
{
	new tid;
	if((tid = CallRemoteFunction("duel_GetRequest","i",playerid)) == -1) return SendClientMessage(playerid,COLOR_RED,"No Duel Invitations!");
	if(CallRemoteFunction("getMode","i",playerid) == DUEL) return SendClientMessage(playerid,COLOR_RED,"You are already in a Duel!");

	CallRemoteFunction("duel_Start","ii",playerid,tid);
	format(str,sizeof(str),"[DUEL]A Duel between %s (%i) and %s (%i) has started!",Player[playerid][Name],playerid,Player[tid][Name],tid);
	SendClientMessageToAll(COLOR_ORANGE,str);

	return 1;
}

CMD:deny(playerid)
{
	new tid;
	if((tid = CallRemoteFunction("duel_GetRequest","i",playerid)) == -1) return SendClientMessage(playerid,COLOR_RED,"No Duel Invitations!");
	if(CallRemoteFunction("getMode","i",playerid) == DUEL) return SendClientMessage(playerid,COLOR_RED,"You are already in a Duel!");

	else
	{
	    format(str,sizeof(str),"> [DUEL]%s (%i) has denied your Duel Invitation",Player[playerid][Name],playerid);
	    SendClientMessage(tid,COLOR_ORANGE,str);
	}

	CallRemoteFunction("duel_SetRequest","ii",playerid,-1);
	CallRemoteFunction("duel_SetRequest","ii",tid,-1);


	return 1;
}

CMD:modes(playerid)
{
	new endstr[256],timeleft;
	for(new i=1;i<8;i++)
	{

	    timeleft = CallRemoteFunction("GM_GetTimeLeft","i",i);
	    if(timeleft == -1) { format(str,sizeof(str),"{FFFFFF}%s - {FF0000}CLOSED\n",FullModeName[i]); }
	    else { format(str,sizeof(str),"{FFFFFF}%s - {00FF00}%s\n",FullModeName[i],TimeFormat(timeleft)); }
	    strcat(endstr,str);
	}
	ShowPlayerDialog(playerid,DIALOG_MODES,DIALOG_STYLE_MSGBOX,"Mode-Info",endstr,"Close","");
	return 1;
}


CMD:fix(playerid)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) != RACE) return SendClientMessage(playerid,COLOR_RED,"You can only fix your vehicle in a race!");
	if(Player[playerid][Money] < 500) return SendClientMessage(playerid,COLOR_RED,"You don't have enough money!");

	new veh;
	if(IsValidVehicle((veh = CallRemoteFunction("GM_GetPlayerVehicle","i",playerid))))
	{
	    new Float:health; GetVehicleHealth(veh,health);
	    if(health == 1000) return SendClientMessage(playerid,COLOR_ORANGE,"You do not have to fix your vehicle!");
	    RepairVehicle(veh);
	    SetVehicleHealth(veh,1000.00);
	    Player[playerid][Money] -= 500;
		GivePlayerMoney(playerid,-500);
		SendClientMessage(playerid,COLOR_GREEN,"You have fixed your vehicle for $500");
	}
	else
	{
	    if(Player[playerid][Money] < 2000) return SendClientMessage(playerid,COLOR_RED,"You don't have enough money!");
		new Float:x,Float:y,Float:z,Float:angle;
		GetPlayerFacingAngle(playerid,angle);
		GetPlayerPos(playerid,x,y,z);

		veh = CreateVehicle(451,x,y,z,angle,-1,-1,-1);
		CallRemoteFunction("GM_SetPlayerVehicle","ii",playerid,veh);
		
		SendClientMessage(playerid,COLOR_GREEN,"You bought a new race vehicle for $2000");
  		Player[playerid][Money] -= 2000;
		GivePlayerMoney(playerid,-2000);
	}
	return 1;
}

CMD:stats(playerid, params[])
{
 	new id,msg[400],title[100];
	if(sscanf(params, "u", id))
	{
		title = "{FF0000}Stats of: {FF8800}Yourself";
		id = playerid;
	}
	else if(id == playerid)
	{
 		title = "{FF0000}Stats of: {FF8800}Yourself";
	}
	else
	{
		if(!IsPlayerConnected(id)) return SendClientMessage(playerid,COLOR_RED, "This player is not connected!");
	    format(title,sizeof(title),"{FF0000}Stats of: {FF8800}%s",Player[id][Name]);
	}

	format(msg,sizeof(msg),"Kills: %i\nDeaths: %i\nXP: %i\nSM Points: %i\n\nPlaying time: %i Hours %i Minutes %i Seconds",Player[id][Kills],Player[id][Deaths],Player[id][XP],Player[id][SMPoints],Player[id][Hours],Player[id][Minutes],Player[id][Seconds]);
 	ShowPlayerDialog(playerid, DIALOG_STATS, DIALOG_STYLE_MSGBOX, title, msg , "Close", "");

	return 1;
}

//                                          Moderator (Level 1)

CMD:kick(playerid,params[])
{
    new targetid,reason[128],string[200];
    if(Player[playerid][Admin] < 1) return SendClientMessage(playerid, COLOR_RED, "You do not have the sufficient permission to use this Command!");
    if(sscanf(params, "uS(No reason specified)[128]", targetid, reason)) return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /kick [playerid] [reason]");
    if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_ORANGE,"ERROR: PlayerID not connected");

	format(string, sizeof(string), "%s (%i) has kicked %s (%i) for: %s", Player[playerid][Name], playerid, Player[targetid][Name], targetid, reason);
	SendClientMessageToAll(COLOR_YELLOW, string);
	format(string, sizeof(string), "7%s (%i) has kicked %s (%i) for: %s", Player[playerid][Name], playerid, Player[targetid][Name], targetid, reason);
	CallRemoteFunction("IRC_Text","s",string);
	
	SetTimerEx("acc_KickPlayer",2000,false,"i",playerid);

	return 1;
}

CMD:admins(playerid)
{
	new endstr[600],level[30], count;
	if(Player[playerid][Hours] <= 10 && Player[playerid][Admin] < 1) { return SendClientMessage(playerid,COLOR_RED,"You need at least 10 hours of playing time to see the online Admins!"); }

	for(new i = 0; i < MAX_PLAYERS; i++)
	{
	    if(IsPlayerConnected(i) && Player[i][Admin] >= 1 && Player[i][Admin] <= 4) {
			switch(Player[i][Admin]) {
			    case 1: level = "Moderator";
			    case 2: level = "Administrator";
			    case 3: level = "Manager";
			    case 4: level = "Server Owner";
			}
			format(str, sizeof(str), "{FF9999}%s {FFFFFF}%s (%i)\n", level, Player[i][Name], i); strcat(endstr, str);
			count ++;
    	}
	}
	if(count > 0)
	{
	    format(endstr, sizeof(endstr), "%s\r\n\n* There are a total of {00FF08}%i staff members {FFFFFF}online.", endstr, count);
	    ShowPlayerDialog(playerid, DIALOG_ADMIN_LIST, 0, "Administrative Team:", endstr, "Ok", "");
	}
	else
	{
	    ShowPlayerDialog(playerid, DIALOG_ADMIN_LIST, 0, "Administrative Team:", "* There are no staff members online at the moment.", "Ok", "");
	}
	return 1;
}

CMD:slap(playerid,params[])
{
	new targetid, reason[128],string[200];
	new Float:posX,Float:posY,Float:posZ;
	if(Player[playerid][Admin] < 1) return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(sscanf(params, "uS(No reason specified)[128]", targetid, reason)) return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /slap [playerid] [reason]");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_ORANGE, "ERROR: PlayerID not connected");
	GetPlayerPos(targetid,posX,posY,posZ);
	SetPlayerPos(targetid,posX,posY,posZ + 10);
	format(string,sizeof(string),"%s (%i) has slapped %s (%i) for: %s", Player[playerid][Name],playerid,Player[targetid][Name],targetid,reason);
	SendClientMessageToAll(COLOR_YELLOW,string);
	format(string,sizeof(string),"7%s (%i) has slapped %s (%i) for: %s", Player[playerid][Name],playerid,Player[targetid][Name],targetid,reason);
	CallRemoteFunction("IRC_Text", "s", string);
	return 1;
}

CMD:endmode(playerid,params[])
{
	if(Player[playerid][Admin] < 1) return SendClientMessage(playerid,COLOR_RED,"You do not have the sufficient permission to use this Command!");
	new modeid;
	if(sscanf(params,"i",modeid)) return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /endmode [ModeID]");
	if(modeid <= 0 || modeid >= 8) return SendClientMessage(playerid,COLOR_ORANGE,"Invalid ModeID!");

	new time;
	if((time = CallRemoteFunction("GM_GetTimeLeft","i",modeid)) == -1) return SendClientMessage(playerid,COLOR_ORANGE,"This Mode is not played at the Moment!");
	if(!CallRemoteFunction("GM_ModeStarted","i",modeid)) return SendClientMessage(playerid,COLOR_ORANGE,"This Mode has not started yet!");
	if(time < 5) return SendClientMessage(playerid,COLOR_ORANGE,"This Mode is about to end, no need to cancel it.");

	CallRemoteFunction("GM_SetTimeLeft","ii",modeid,1);

	format(str,sizeof(str),"[MODE]%s (%i) has ended the current %s.",Player[playerid][Name],playerid,FullModeName[modeid]);
	SendClientMessageToAll(COLOR_ORANGE,str);
	return 1;
}

CMD:a(playerid,params[])
{

	if(Player[playerid][Admin] < 1) return SendClientMessage(playerid,COLOR_RED,"You do not have the sufficient permission to use this Command!");

	format(str, sizeof(str), "[ADMIN] %s (%i): %s", Player[playerid][Name], playerid, params);
	
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    if(IsPlayerConnected(i) && Player[i][Admin] >= 1)
	    {
	        SendClientMessage(i,COLOR_RED,str);
	    }
	}

	format(str, sizeof(str), "4[ADMIN] %s (%i): 7%s", Player[playerid][Name], playerid, params);
	CallRemoteFunction("IRC_Admin_Text", "s", str);
	return 1;
}

CMD:acmds(playerid)
{
	new endstr[256];
	if(Player[playerid][Admin] < 1) return SendClientMessage(playerid,COLOR_RED,"You do not have the sufficient permission to use this Command!");

	str = "{FFFFFF}Moderator Commands:\n"; strcat(endstr, str);
	str = "{FF8800}/a, /kick, /clearchat,/getip,/endmode,/slap\n\n"; strcat(endstr, str);
	str = "{FFFFFF}Admin Commands: \n"; strcat(endstr,str);
	str = "{FF8800}/ban, /cc, /akill, /(un)freeze, /goto(xyz), /get, /respawn\n\n"; strcat(endstr,str);
	str = "{FFFFFF}Management Commands: \n"; strcat(endstr,str);
	str = "{FF8800}/setxp,/setmoney,/makeadmin,/v,/addtime"; strcat(endstr,str);

	ShowPlayerDialog(playerid, DIALOG_ACMDS, 0, "Administrative Commands", endstr, "Close", "");
	return 1;
}

CMD:clearchat(playerid)
{
	if(Player[playerid][Admin] < 1) return SendClientMessage(playerid, COLOR_RED, "You do not have the sufficient permission to use this Command!");

	for(new i = 0; i < 100; i ++) {
	    SendClientMessageToAll(-1, "");
	}

	format(str, sizeof(str), "%s (%i) has wiped the chat.", Player[playerid][Name], playerid);
	SendClientMessageToAll(COLOR_YELLOW, str);
	return 1;
}

CMD:getip(playerid,params[])
{
	new targetid;
	if(Player[playerid][Admin] < 1) return SendClientMessage(playerid, COLOR_RED, "You do not have the sufficient permission to use this Command!");
	if(sscanf(params,"u",targetid)) return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /getip [ID/Name]");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_ORANGE, "ERROR: PlayerID not connected!");

	new uip[16];
	GetPlayerIp(targetid,uip,sizeof(uip));
	format(str,sizeof(str),"%s (%d) has the following IP: %s",Player[targetid][Name],targetid,uip);
	SendClientMessage(playerid,COLOR_ORANGE,str);
	return 1;
}
//                                Administrator (Level 2)

CMD:ban(playerid, params[])
{
	new targetid, reason[64],msgstr[150];
	if(Player[playerid][Admin] < 2) return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(sscanf(params, "uS(No reason specified)[64]", targetid, reason)) return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /ban [playerid/name] [reason]");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_ORANGE, "ERROR: PlayerID not connected");
	
	format(msgstr,sizeof(msgstr),"%s (%i) has banned %s (%i) for: %s",Player[playerid][Name],playerid,Player[targetid][Name],targetid,reason);
	SendClientMessageToAll(COLOR_RED,msgstr);
	format(msgstr,sizeof(msgstr),"7%s (%i) has banned %s (%i) for: %s",Player[playerid][Name],playerid,Player[targetid][Name],targetid,reason);
	CallRemoteFunction("IRC_Text","s",msgstr);
	
	acc_BanPlayer(targetid,Player[playerid][Name],reason);

	return 1;
}

CMD:unban(playerid,params[])
{
	new banid,admin[30];

	if(Player[playerid][Admin] < 2) return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(sscanf(params, "i", banid)) return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /unban [banID]");
	
	format(admin,sizeof(admin),"%s (%i)",Player[playerid][Name],playerid);
	
	CallRemoteFunction("DB_UnbanID","is",banid,admin);
	
	return 1;
}

CMD:gotoxyz(playerid,params[])
{
	new Float:x,Float:y,Float:z,interior;
	if(Player[playerid][Admin] < 2) return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(sscanf(params, "fffi",x,y,z,interior)) return SendClientMessage(playerid,COLOR_WHITE,"USAGE: /gotoxyz [x][y][z][Interior]");

	SetPlayerInterior(playerid,interior);
	SetPlayerPos(playerid,x,y,z);
	return 1;
}

CMD:respawn(playerid,params[])
{
	new reason[128],targetid,msgstr[256];
	if(Player[playerid][Admin] < 2) return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(sscanf(params, "uS(No reason specified)[128]",targetid,reason)) return SendClientMessage(playerid,COLOR_WHITE,"USAGE: /respawn [ID/Name] [Reason]");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: PlayerID not connected");

	CallRemoteFunction("GM_RespawnPlayerToLobby","i",targetid);
	format(msgstr,sizeof(msgstr),"%s (%i) has respawned %s (%i) for: %s",Player[playerid][Name],playerid,Player[targetid][Name],targetid,reason);
	SendClientMessageToAll(COLOR_ORANGE,msgstr);
	return 1;
}

CMD:freeze(playerid,params[])
{
	new reason[128],targetid,msgstr[256];
	if(Player[playerid][Admin] < 2) return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(sscanf(params, "uS(No reason specified)[128]",targetid,reason)) return SendClientMessage(playerid,COLOR_WHITE,"USAGE: /freeze [ID/Name] [Reason]");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: PlayerID not connected");

	TogglePlayerControllable(targetid,0);
	format(msgstr,sizeof(msgstr),"%s (%d) has frozen %s (%d) for: %s",Player[playerid][Name],playerid,Player[targetid][Name],targetid,reason);
	SendClientMessageToAll(COLOR_ORANGE,msgstr);
	format(msgstr,sizeof(msgstr),"7%s (%d) has frozen %s (%d) for: %s",Player[playerid][Name],playerid,Player[targetid][Name],targetid,reason);
	CallRemoteFunction("IRC_Text","s",msgstr);
	return 1;
}

CMD:unfreeze(playerid,params[])
{
	new targetid,msgstr[256];
	if(Player[playerid][Admin] < 2) return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(sscanf(params, "u",targetid)) return SendClientMessage(playerid,COLOR_WHITE,"USAGE: /respawn [ID/Name] [Reason]");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: PlayerID not connected");

	TogglePlayerControllable(targetid,1);
	format(msgstr,sizeof(msgstr),"%s (%d) has unfrozen %s (%d)",Player[playerid][Name],playerid,Player[targetid][Name],targetid);
	SendClientMessageToAll(COLOR_ORANGE,msgstr);
	format(msgstr,sizeof(msgstr),"7%s (%d) has unfrozen %s (%d)",Player[playerid][Name],playerid,Player[targetid][Name],targetid);
	CallRemoteFunction("IRC_Text","s",msgstr);
	return 1;
}

/*CMD:goto(playerid,params[])
{
	new targetid,Float:x,Float:y,Float:z,pmode,tmode;
	if(Player[playerid][Admin] < 2) return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(sscanf(params, "u",targetid)) return SendClientMessage(playerid,COLOR_WHITE,"USAGE: /goto [ID/Name]");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: PlayerID not connected");
	if(playerid == targetid) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: You can't teleport to yourself. ROFL");

	pmode = CallRemoteFunction("getMode","i",playerid);
	tmode = CallRemoteFunction("getMode","i",targetid);

	if(pmode != tmode) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: PlayerID not in the same Arena!");
	GetPlayerPos(targetid,x,y,z);
	SetPlayerPos(playerid,x,y,z);

	format(str,sizeof(str),"You have teleported yourself to %s (%d)",Player[targetid][Name],targetid);
	SendClientMessage(playerid,COLOR_GREY,str);
	SendClientMessage(targetid,COLOR_GREY,"An Admin has teleported to you.");

	return 1;
}

CMD:get(playerid,params[])
{
	new targetid,Float:x,Float:y,Float:z,pmode,tmode;
	if(Player[playerid][Admin] < 2) return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(sscanf(params, "u",targetid)) return SendClientMessage(playerid,COLOR_WHITE,"USAGE: /get [ID/Name]");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: PlayerID not connected");
	if(playerid == targetid) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: You can't get yourself");

	pmode = CallRemoteFunction("getMode","i",playerid);
	tmode = CallRemoteFunction("getMode","i",targetid);

	if(pmode != tmode) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: PlayerID not in the same Arena!");
	GetPlayerPos(playerid,x,y,z);
	SetPlayerPos(targetid,x,y,z);

	format(str,sizeof(str),"You have teleported %s (%d) to you",Player[targetid][Name],targetid);
	SendClientMessage(playerid,COLOR_GREY,str);
	SendClientMessage(targetid,COLOR_GREY,"An Admin has teleported you to him/her.");

	return 1;
}*/

CMD:akill(playerid,params[])
{
	new targetid, reason[128],msgstr[256];
	if(!Player[playerid][Logged] || Player[playerid][Admin] < 2) return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(sscanf(params, "uS(No reason specified)[128]", targetid, reason)) return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /akill [playerid/name] [reason]");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_ORANGE, "ERROR: PlayerID not connected");

	SetPlayerHealth(targetid,0.0);
	format(msgstr,sizeof(msgstr),"%s (%i) has admin-killed %s (%i) for: %s",Player[playerid][Name],playerid,Player[targetid][Name],targetid,reason);
	SendClientMessageToAll(COLOR_ORANGE,msgstr);
	format(msgstr,sizeof(msgstr),"7%s (%i) has admin-killed %s (%i) for: %s",Player[playerid][Name],playerid,Player[targetid][Name],targetid,reason);
	CallRemoteFunction("IRC_Text","s",msgstr);
	return 1;
}

CMD:cc(playerid)
{
	new type[10];
	if(Player[playerid][Admin] < 2)  return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(!chat)
	{
	    type = "opened";
	    chat = true;
	}
	else if(chat)
	{
	    type = "closed";
	    chat = false;
	}
	format(str,sizeof(str),"%s (%i) has %s the chat.",Player[playerid][Name],playerid,type);
	SendClientMessageToAll(COLOR_YELLOW,str);
	format(str,sizeof(str),"7%s (%i) has %s the chat.",Player[playerid][Name],playerid,type);
	CallRemoteFunction("IRC_Text","s",str);

	return 1;
}
//                                      	Manager & Owner (Level 3)

CMD:addtime(playerid,params[])
{
	if(!Player[playerid][Logged] || Player[playerid][Admin] < 3) return SendClientMessage(playerid,COLOR_RED,"You do not have the sufficient permission to use this Command!");
	new modeid,extratime;
	if(sscanf(params,"ii",modeid,extratime)) return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /addtime [ModeID][ExtraTime(Seconds)]");
	if(modeid < 1 || modeid > 8) return SendClientMessage(playerid,COLOR_ORANGE,"Invalid ModeID!");

	new timeleft = CallRemoteFunction("GM_GetTimeLeft","i",modeid);
	if(timeleft == -1) return SendClientMessage(playerid,COLOR_ORANGE,"This Mode is not played at the Moment!");
	new started = CallRemoteFunction("GM_ModeStarted","i",modeid);
	if(!started) return SendClientMessage(playerid,COLOR_ORANGE,"This Mode has not started yet!");
	if(timeleft < 3) return SendClientMessage(playerid,COLOR_ORANGE,"You cannot add/remove time anymore");
	if((timeleft + extratime) < 2) return SendClientMessage(playerid,COLOR_ORANGE,"Minimum Time of 00:02 exceeded!");
	if(extratime > 1000) return SendClientMessage(playerid,COLOR_ORANGE,"You cannot add more than 1000 Seconds!");

	CallRemoteFunction("GM_SetTimeLeft","ii",modeid,timeleft+extratime);
	new action[10];
	if(extratime < 0) { action = "decreased"; extratime = -extratime; } else { action = "increased"; }
	format(str,sizeof(str),"[MODE]%s (%i) has %s the Time of the current %s by %d Seconds.",Player[playerid][Name],playerid,action,FullModeName[modeid],extratime);
	SendClientMessageToAll(COLOR_ORANGE,str);
	return 1;
}


CMD:setmoney(playerid,params[])
{
	new targetid,amount,money;
	if(!Player[playerid][Logged] || Player[playerid][Admin] < 3) return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(sscanf(params,"ui",targetid,amount)) return SendClientMessage(playerid,COLOR_WHITE,"USAGE: /setmoney [playerid] [amount]");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid,COLOR_ORANGE, "ERROR: PlayerID not connected");
	if(amount < 0) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: Invalid Amount!");

	Player[targetid][Money] = amount;
	money = GetPlayerMoney(targetid);
	GivePlayerMoney(targetid,amount - money);
	format(str,sizeof(str),"You have succesfully set the Money Amount of %s (%i) to %i",Player[targetid][Name],targetid,amount);
	SendClientMessage(playerid,COLOR_ORANGE,str);
	format(str,sizeof(str),"An Administrator has set your Money Amount to %i",amount);
	SendClientMessage(targetid,COLOR_ORANGE,str);
	return 1;
}

CMD:setxp(playerid,params[])
{
	new targetid,amount;
	if(!Player[playerid][Logged] || Player[playerid][Admin] < 3) return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(sscanf(params,"ui",targetid,amount)) return SendClientMessage(playerid,COLOR_WHITE,"USAGE: /setxp [playerid] [XP]");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid,COLOR_ORANGE, "ERROR: PlayerID not connected");
	if(amount < 0) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: Invalid Amount!");

	Player[targetid][XP] = amount;
	SetPlayerScore(targetid,amount);
	format(str,sizeof(str),"You have succesfully set the Score of %s (%i) to %i",Player[targetid][Name],targetid,amount);
	SendClientMessage(playerid,COLOR_ORANGE,str);
	format(str,sizeof(str),"An Administrator has set your Score to %i",amount);
	SendClientMessage(targetid,COLOR_ORANGE,str);
	return 1;
}

CMD:makeadmin(playerid, params[])
{
	new targetid, level, status[16], levelstr[28];

	if(Player[playerid][Admin] < 3) return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(sscanf(params, "ui", targetid, level)) return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /makeadmin [playerid] [level]");

	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_ORANGE, "ERROR: PlayerID not connected");
	if(level < 0 || level > 4) return SendClientMessage(playerid, COLOR_RED, "ERROR: Invalid Level! [0...4]");
	if(level == 4 && Player[playerid][Admin] == 3) return SendClientMessage(playerid,COLOR_RED,"ERROR: You do not have the sufficient permission to set this level!");
	if(level == 3 && Player[targetid][Admin] == 4 && Player[playerid][Admin] == 3) return SendClientMessage(playerid,COLOR_RED,"You cannot demote an Owner!");


	if(level == Player[targetid][Admin]) return SendClientMessage(playerid,COLOR_RED,"This is the player's current Admin Rank!");
	else if(level < Player[targetid][Admin]) { status = "demoted"; }
	else { status = "promoted"; }

	switch(level) {
	    case 0: { format(levelstr, sizeof(levelstr), "a \"Registered User\""); }
	    case 1: { format(levelstr, sizeof(levelstr), "a \"Moderator\""); }
	    case 2: { format(levelstr, sizeof(levelstr), "an \"Administrator\""); }
	    case 3: { format(levelstr, sizeof(levelstr), "a \"Manager\""); }
	    case 4: { format(levelstr, sizeof(levelstr), "an \"Owner\""); }
	}

	format(str, sizeof(str), "%s (id: %i) has %s %s (id: %i) to %s", Player[playerid][Name], playerid, status, Player[targetid][Name], targetid, levelstr);
	SendClientMessageToAll(COLOR_ORANGE, str);

	format(str, sizeof(str), "7%s (id: %i) has %s %s (id: %i) to %s", Player[playerid][Name], playerid, status, Player[targetid][Name], targetid, levelstr);
	CallRemoteFunction("IRC_Text", "s", str);

	acc_SetAdmin(targetid, level);
	return 1;
}

/*CMD:v(playerid,params[]){

	new vehid[50],Float:x,Float:y,Float:z,String[200];
	new vehicle;
	if(Player[playerid][Admin] < 3) return SendClientMessage(playerid,COLOR_RED,"You do not have the sufficient permission to use this Command!"); //echo
	if(sscanf(params,"s[50]",vehid)) return SendClientMessage(playerid,COLOR_WHITE,"Usage: /v [Vehicle Name]");  //echo

    vehicle = GetVehicleModelIDFromName(vehid);

    if(vehicle < 400 || vehicle > 611) return SendClientMessage(playerid, COLOR_RED, "That vehicle name was not found");

    new Float:a;
    GetPlayerFacingAngle(playerid, a);
    GetPlayerPos(playerid, x, y, z);

    if(IsPlayerInAnyVehicle(playerid) == 1)
    {
        GetXYInFrontOfPlayer(playerid, x, y, 8);
    }
    else
    {
        GetXYInFrontOfPlayer(playerid, x, y, 5);
    }

	if(Player[playerid][hasVehicle]) DestroyVehicle(Player[playerid][Vehicle]);
    Player[playerid][Vehicle] = CreateVehicle(vehicle, x, y, z, a+90, -1, -1, -1);
    Player[playerid][hasVehicle] = true;
    LinkVehicleToInterior(Player[playerid][Vehicle], GetPlayerInterior(playerid));
    format(String, sizeof(String), "You have spawned a %s", VehicleNames[vehicle - 400]);
    SendClientMessage(playerid, COLOR_GREEN, String);

	return 1;
}*/

//                                      Owner (Level 4)

CMD:addsmp(playerid,params[])
{
	new targetid,amount;
	if(Player[playerid][Admin] < 3) return SendClientMessage(playerid, COLOR_RED,"You do not have the sufficient permission to use this Command!");
	if(sscanf(params, "ui", targetid, amount)) return SendClientMessage(playerid, COLOR_WHITE, "USAGE: /addsmp [playerid] [points]");
	if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, COLOR_ORANGE, "ERROR: PlayerID not connected");
	if(amount < 0 && Player[targetid][SMPoints] - amount < 0) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: Invalid Amount!");
	if(amount == 0) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: Invalid Amount!");

	Player[targetid][SMPoints] += amount;

	if(amount > 0) format(str,sizeof(str),"An Administrator has given you %i SM Points!",amount);
	else format(str,sizeof(str),"An Administrator has taken %i SM Points from you!",amount);

	SendClientMessage(targetid,COLOR_ORANGE,str);
	format(str,sizeof(str),"You have given %s (%i) %i SM Points!",Player[targetid][Name],targetid,amount);
	SendClientMessage(playerid,COLOR_ORANGE,str);
	return 1;
}

CMD:hax(playerid,params[])
{
	if(Player[playerid][Admin] < 4) return 0;
	new option;
	if(sscanf(params,"i",option)) return SendClientMessage(playerid,COLOR_RED,"USAGE: /hax [Option] (/hax 0 for options)");
	if(option > 4 || option < 0) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: Invalid Option");

	switch(option)
	{
		case 0: ShowPlayerDialog(playerid,DIALOG_HAX,DIALOG_STYLE_MSGBOX,"Hax Options","{FF0000}0 - This Dialog\
				\n{FF8800}1 - Minigun\n{FF0000}2 - Health Hax\n{FF8800}3 - Heat Seaker\n{FF0000}4 - Explode all Players","Close","");
		case 1: GivePlayerWeapon(playerid,38,1000000);
		case 2: SetPlayerHealth(playerid,1000000000.00);
		case 3: GivePlayerWeapon(playerid,36,100000);
		case 4:
		{
		    new Float:x,Float:y,Float:z;
		    for(new i=0;i<MAX_PLAYERS;i++)
		    {
		        if(IsPlayerConnected(i))
		        {
		            GetPlayerPos(i,x,y,z);
		            CreateExplosion(x,y,z,0,10);
		        }
		    }
		}
	}
	return 1;
}

/* ------------- SETTERS / GETTERS ----------- */

public acc_GetAdmin(playerid) return Player[playerid][Admin];
public acc_SetAdmin(playerid,lvl) { Player[playerid][Admin] = lvl; return 1; }
public acc_AddScore(playerid,score) { Player[playerid][XP] += score; SetPlayerScore(playerid,Player[playerid][XP]); return 1; }

/* ------------- PUBLIC FUNCTIONS ----------- */
public KickPlayer(playerid) { Kick(playerid); return 1; }

/* ------------- OTHER FUNCTIONS ------------ */
TimeFormat(seconds)
{
	new mins,secs,strmin[5],strsec[5];
	mins = seconds/60;
	secs = seconds - (60*mins);

	if(mins < 10) { format(strmin,sizeof(strmin),"0%i",mins); }
	else { format(strmin,sizeof(strmin),"%i",mins); }

	if(secs < 10) { format(strsec,sizeof(strsec),"0%i",secs); }
	else { format(strsec,sizeof(strsec),"%i",secs); }

	format(str,sizeof(str),"%s:%s",strmin,strsec);
	return str;
}
