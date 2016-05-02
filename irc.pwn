/*
								    Copyright 2014 XenoN & [MM]PitBull

					Licensed under the Apache License, Version 2.0 (the "License");
					you may not use this file except in compliance with the License.
					You may obtain a copy of the License at

					    		http://www.apache.org/licenses/LICENSE-2.0

					Unless required by applicable law or agreed to in writing, software
					distributed under the License is distributed on an "AS IS" BASIS,
					WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
					See the License for the specific language governing permissions and
					limitations under the License.
*/

#include <a_samp>
#include <irc>
#include <sscanf2>
#include <a_mysql>
#include <SM_controls\defines>
#include <zcmd>

#define BOT_1_ALT_NICK "SM1"
#define BOT_1_NICKNAME "SM1"
#define BOT_1_REALNAME "SMBot"
#define BOT_1_USERNAME "SMBot"

#define BOT_2_ALT_NICK "SM2"
#define BOT_2_NICKNAME "SM2"
#define BOT_2_REALNAME "SMBot"
#define BOT_2_USERNAME "SMBot"

#define BOT_3_ALT_NICK "SM3"
#define BOT_3_NICKNAME "SM3"
#define BOT_3_REALNAME "SMBot"
#define BOT_3_USERNAME "SMBot"

#define BOT_4_ALT_NICK "SM4"
#define BOT_4_NICKNAME "SM4"
#define BOT_4_REALNAME "SMBot"
#define BOT_4_USERNAME "SMBot"

// 									Channel Configurations

#define IRC_SERVER "exnet.fr.irc.tl"
#define IRC_PORT (6667)
#define IRC_CHANNEL "#stadium-madness"
#define MAX_BOTS (4)
#define BOT_PASSWORD "stadium123"

#define IRC_ADMIN "%#stadium-madness"

// 									  MySQL Configurations

#define mysql_fetch_row(%1) mysql_fetch_row_format(%1,"|")

#define function%0(%1) forward%0(%1); public%0(%1)


forward IRC_Text(text[]);
forward IRC_Admin_Text(text[]);

new xBotID[MAX_BOTS], xGroupID, str[128];

public OnFilterScriptInit()
{
	xBotID[0] = IRC_Connect(IRC_SERVER, IRC_PORT, BOT_1_NICKNAME, BOT_1_REALNAME, BOT_1_USERNAME);
	IRC_SetIntData(xBotID[0], E_IRC_CONNECT_DELAY, 10); // SM1
	
	xBotID[1] = IRC_Connect(IRC_SERVER, IRC_PORT, BOT_2_NICKNAME, BOT_2_REALNAME, BOT_2_USERNAME);
	IRC_SetIntData(xBotID[1], E_IRC_CONNECT_DELAY, 15); // SM2
	
	xBotID[2] = IRC_Connect(IRC_SERVER, IRC_PORT, BOT_3_NICKNAME, BOT_3_REALNAME, BOT_3_USERNAME);
	IRC_SetIntData(xBotID[2], E_IRC_CONNECT_DELAY, 20); // SM3
	
	xBotID[3] = IRC_Connect(IRC_SERVER, IRC_PORT, BOT_4_NICKNAME, BOT_4_REALNAME, BOT_4_USERNAME);
	IRC_SetIntData(xBotID[3], E_IRC_CONNECT_DELAY, 25); // SM4 
	
	xGroupID = IRC_CreateGroup();
	
	return true;
}

public OnFilterScriptExit()
{
	IRC_DestroyGroup(xGroupID);
	return true;
}

public OnPlayerConnect(playerid)
{
	return true;
}

public OnPlayerDisconnect(playerid, reason)
{
	new reasonMsg[8];
	switch(reason)
	{
		case 0: reasonMsg = "Timeout";
		case 1: reasonMsg = "Leaving";
		case 2: reasonMsg = "Kicked";
	}
	return true;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	new reasonmsg[32], pName[MAX_PLAYER_NAME], kName[MAX_PLAYER_NAME], msg[100];

	GetPlayerName(playerid, pName, MAX_PLAYER_NAME);
	GetPlayerName(killerid, kName, MAX_PLAYER_NAME);

	if(killerid != INVALID_PLAYER_ID)
	{
	    switch (reason)
	    {
	        case 0: reasonmsg = "Unarmed";
	        case 1: reasonmsg = "Brass Knuckles";
	        case 2: reasonmsg = "Golf Club";
	        case 3: reasonmsg = "Night Stick";
	        case 4: reasonmsg = "Knife";
	        case 5: reasonmsg = "Baseball Bat";
	        case 6: reasonmsg = "Shovel";
	        case 7: reasonmsg = "Pool Cue";
	        case 8: reasonmsg = "Katana";
	        case 9: reasonmsg = "Chainsaw";
	        case 10,11: reasonmsg = "Dildo";
	        case 12,13: reasonmsg = "Vibrator";
	        case 14: reasonmsg = "Flowers";
	        case 15: reasonmsg = "Cane";
	        case 22: reasonmsg = "Pistol";
	        case 23: reasonmsg = "Silenced Pistol";
	        case 24: reasonmsg = "Desert Eagle";
	        case 25: reasonmsg = "Shotgun";
	        case 26: reasonmsg = "Sawn-off Shotgun";
	        case 27: reasonmsg = "Combat Shotgun";
	        case 28: reasonmsg = "MAC-10";
	        case 29: reasonmsg = "MP5";
	        case 30: reasonmsg = "AK-47";
	        case 31: { if (GetPlayerState(killerid) == PLAYER_STATE_DRIVER) { switch (GetVehicleModel(GetPlayerVehicleID(killerid))) { case 447: { reasonmsg = "Sea Sparrow Machine Gun"; }
					default: { reasonmsg = "M4"; } } } else { reasonmsg = "M4"; } }
			case 32: reasonmsg = "TEC-9";
			case 33: reasonmsg = "Rifle";
			case 34: reasonmsg = "Sniper Rifle";
			case 37: reasonmsg = "Fire";
			case 38: { if (GetPlayerState(killerid) == PLAYER_STATE_DRIVER) { switch (GetVehicleModel(GetPlayerVehicleID(killerid))) { case 425: { reasonmsg = "Hunter Machine Gun"; }
					default: { reasonmsg = "Minigun"; } } } else {
					reasonmsg = "Minigun"; } }
			case 41: reasonmsg = "Spraycan";
			case 42: reasonmsg = "Fire Extinguisher";
			case 49: reasonmsg = "Vehicle Collision";
			case 50: { if (GetPlayerState(killerid) == PLAYER_STATE_DRIVER) { switch (GetVehicleModel(GetPlayerVehicleID(killerid))) { case 417, 425, 447, 465, 469, 487, 488, 497, 501, 548, 563: {
					reasonmsg = "Helicopter Blades"; } default: { reasonmsg = "Vehicle Collision"; } } } else { reasonmsg = "Vehicle Collision";
				}
			}
			case 51: { if (GetPlayerState(killerid) == PLAYER_STATE_DRIVER) { switch (GetVehicleModel(GetPlayerVehicleID(killerid))) {
				case 425: reasonmsg = "Hunter Rockets";
				case 432: reasonmsg = "Rhino Turret";
				case 520: reasonmsg = "Hydra Rockets";
				default: reasonmsg = "Explosion";
    					} } else { reasonmsg = "Explosion"; } } default: { reasonmsg = "Unknown"; }
		} format(msg, sizeof(msg), "5%s (id: %d) has killed %s (id: %d). (%s)", kName, killerid, pName, playerid, reasonmsg); } else {
		switch (reason) {
			case 53: format(msg, sizeof(msg), "5%s (id: %d) has died. (Drowned)", pName, playerid);
			case 54: format(msg, sizeof(msg), "5%s (id: %d) has died. (Collision)", pName, playerid);
			default: format(msg, sizeof(msg), "5%s (id: %d) has died.", pName, playerid);
		}
	}
	IRC_GroupSay(xGroupID, IRC_CHANNEL, msg);
	return 1;
}

public IRC_OnConnect(botid, ip[], port)
{
	IRC_SendRaw(botid, "ns identify " BOT_PASSWORD);
 	IRC_AddToGroup(xGroupID, botid);
	return true;
}

public IRC_OnDisconnect(botid, ip[], port, reason[])
{
	IRC_RemoveFromGroup(xGroupID, botid);
	return true;
}

public IRC_OnConnectAttemptFail(botid, ip[], port, reason[])
{
	printf("*** IRC_OnConnectAttemptFail: Bot ID %d failed to connect to %s:%d (%s)", botid, ip, port, reason);
	return 1;
}

public IRC_OnJoinChannel(botid, channel[])
{
	IRC_Say(botid, channel, "0,10Locating channel <3,1Successful0,10>");
	return true;
}

public IRC_OnLeaveChannel(botid, channel[], message[])
{
	printf("*** IRC_OnLeaveChannel: Bot ID %d left channel %s (%s)", botid, channel, message);
	return true;
}

public IRC_OnInvitedToChannel(botid, channel[], invitinguser[], invitinghost[])
{
	IRC_JoinChannel(botid, channel);
	return true;
}

public IRC_OnKickedFromChannel(botid, channel[], oppeduser[], oppedhost[], message[])
{
	IRC_JoinChannel(botid, channel);
	return true;
}

public IRC_OnReceiveRaw(botid, message[])
{
	new File:file;
	if (!fexist("irc_log.txt"))
	{
		file = fopen("irc_log.txt", io_write);
	}
	else
	{
		file = fopen("irc_log.txt", io_append);
	}
	if (file)
	{
		fwrite(file, message);
		fwrite(file, "\r\n");
		fclose(file);
	}
	return true;
}

//                              	Voiced

IRCCMD:players(botid, channel[], user[], host[], params[])
{
	new players = 0;
	if(!IRC_IsVoice(botid, channel, user)) return _ERROR_(0);

	for(new i = 0; i < GetMaxPlayers(); i ++) { if(IsPlayerConnected(i)) { players ++; } }
	
	format(str, sizeof(str), "0,2Current online players - (%i/%i).", players, GetMaxPlayers());
	IRC_GroupSay(xGroupID, IRC_CHANNEL, str);
	return true;
}

IRCCMD:cmds(botid, channel[], user[], host[], params[])
{
	if(!IRC_IsVoice(botid, channel, user)) return _ERROR_(0);
	ShowCommands(0);
	return true;
}

IRCCMD:m(botid, channel[], user[], host[], params[])
{
	new tempstr[128];
	if(!IRC_IsVoice(botid, channel, user)) return _ERROR_(0);
	if(isnull(params)) return _CMD_("!m [text]");
	format(tempstr, sizeof(tempstr), "2%s (IRC): %s", user, params);
	IRC_GroupSay(xGroupID, IRC_CHANNEL, tempstr);
	format(tempstr, sizeof(tempstr), "%s (IRC): %s", user, params);
	SendClientMessageToAll(-1, tempstr);
	return true;
}

IRCCMD:getid(botid, channel[], user[], host[], params[])
{
	new playerid, pName[MAX_PLAYER_NAME];
	if(!IRC_IsVoice(botid, channel, user)) return _ERROR_(0);
	if(sscanf(params, "u", playerid)) return _CMD_("!getid [name]");
	if(!IsPlayerConnected(playerid)) return _ERROR_(1);
	GetPlayerName(playerid, pName, sizeof(pName));
	format(str, sizeof(str), "7Result: - %s (%i)", pName, playerid);
	IRC_GroupSay(xGroupID, IRC_CHANNEL, str);
	return true;
}

/*IRCCMD:pm(botid, channel[], user[], host[], params[])
{
	new playerid, pName[MAX_PLAYER_NAME], message[128];
	if(!IRC_IsVoice(botid, channel, user)) return _ERROR_(0);
	if(sscanf(params, "uS(No message specified)[128]", playerid, message)) return _CMD_("!pm [name] [text]");
	if(!IsPlayerConnected(playerid)) return _ERROR_(1);
	GetPlayerName(playerid, pName, sizeof(pName));
	format(str, sizeof(str), "10Message Delivered to %s (%i) \"%s\".", pName, playerid, message);
	IRC_GroupSay(xGroupID, IRC_CHANNEL, str);
	//CallRemoteFunction("PrivateMsg", "iss", playerid, message, user);
	return true;
}*/

//                              Half Operator

/*IRCCMD:a(botid, channel[], user[], host[], params[])
{
	if(!IRC_IsHalfop(botid, channel, user)) return _ERROR_(0);
	if(isnull(params)) return _CMD_("!a [text]");
	
	format(str, sizeof(str), "4[ADMIN] %s (IRC): 7%s", user, params);
	IRC_GroupSay(xGroupID, IRC_ADMIN, str);
	
	format(str, sizeof(str), "[ADMIN] %s (IRC): %s", user, params);
	CallRemoteFunction("AdminChat", "s", str);
	return true;
}*/

/*IRCCMD:admins(botid, channel[], user[], host[])
{
	if(IRC_IsHalfop(botid, channel, user)) CallRemoteFunction("GetAdminNames", "", "");
	else _ERROR_(0);
	return true;
}*/

/*IRCCMD:acmds(botid, channel[], user[], host[])
{
	if(!IRC_IsHalfop(botid, channel, user)) return _ERROR_(2);
	ShowAdminCommands(0);
	return true;
}*/

//                              Full Operator

/*IRCCMD:nickcheck(botid, channel[], user[], host[], params[])
{
	new pName[MAX_PLAYER_NAME], query[128];
	if(!IRC_IsOp(botid, channel, user)) return _ERROR_(0);
	if(sscanf(params, "s[24]", pName)) return _CMD_("!nickcheck [name]");
	if(QueryContainsForbiddenChar(pName,sizeof(pName))) return _ERROR_(3);
	
	mysql_real_escape_string(pName, pName);
	
	query = "SELECT `aID`, `Name`, `IP` FROM `accounts` WHERE `Name` LIKE '%";
	strcat(query,pName);
	strcat(query,"%' LIMIT 0,15");
	
	//format(query, sizeof(query), "SELECT `aID`, `Name` FROM `accounts` WHERE `Name` LIKE '%%s%'", str2);
	mysql_function_query(mCon, query, false, "OnPlayerNickCheck", "si", pName, 0);
	
	return true;
}
IRCCMD:ipcheck(botid, channel[], user[], host[], params[])
{
	new ip[16], query[128];
	if(!IRC_IsOp(botid, channel, user)) return _ERROR_(0);
	if(sscanf(params, "s[16]", ip)) return _CMD_("!ipcheck [IP]");
	if(QueryContainsForbiddenChar(ip,sizeof(ip))) return _ERROR_(3);
	mysql_real_escape_string(ip, ip);

	query = "SELECT `IP`, `Name` FROM `accounts` WHERE `IP` LIKE '";
	strcat(query,ip);
	strcat(query,"%' LIMIT 0,15");

	mysql_function_query(mCon, query, false, "OnPlayerIPCheck", "si", ip,0);

	return true;
}
*/
IRCCMD:ban(botid, channel[], user[], host[], params[])
{
	if(!IRC_IsOp(botid, channel, user)) return _ERROR_(0);

	new targetid,reason[64],msgstr[150];
	if(sscanf(params, "uS(No reason specified)[64]", targetid,reason)) return _CMD_("!ban [ID/Name]");
	if(!IsPlayerConnected(targetid)) return _ERROR_(1);

	new name[MAX_PLAYER_NAME];
	GetPlayerName(targetid,name,sizeof(name));

	format(msgstr,sizeof(msgstr),"%s (IRC) has banned %s (%i) for: %s",user,name,targetid,reason);
	SendClientMessageToAll(0xFF0000FF,msgstr);
	format(msgstr,sizeof(msgstr),"7%s (IRC) has banned %s (%i) for: %s",user,name,targetid,reason);
	IRC_GroupSay(xGroupID, IRC_CHANNEL, msgstr);
	
	CallRemoteFunction("acc_BanPlayer","iss",targetid,user,reason);
	return true;
}

IRCCMD:unbanid(botid,channel[], user[], host[], params[])
{
	if(!IRC_IsOp(botid,channel,user)) return _ERROR_(0);

	new banid,admin[30];
	if(sscanf(params,"i",banid)) return _CMD_("!unbanid [BanID]");
	
	format(admin,sizeof(admin),"%s (IRC)",user);
	
	CallRemoteFunction("DB_UnbanID","is",banid,admin);
	return 1;
}

IRCCMD:oban(botid, channel[], user[], host[], params[])
{
	if(!IRC_IsOp(botid,channel,user)) return _ERROR_(0);
	new accid,reason[64];
	if(sscanf(params,"iS(No reason specified)[64]",accid,reason)) return _CMD_("!oban [AccID] [Reason]");
	
	CallRemoteFunction("DB_OfflineBan","iss",accid,user,reason);

	return 1;
}
/*
IRCCMD:bancheck(botid, channel[], user[], host[], params[])
{
    if(!IRC_IsOp(botid,channel,user)) return _ERROR_(0);
	new pName[MAX_PLAYER_NAME];
	if(sscanf(params,"s[24]",pName)) return _CMD_("!bancheck [Username]");
	new query[128];
	query = "SELECT * FROM `bans` WHERE `Name` LIKE '%";
	strcat(query,pName); strcat(query,"%' LIMIT 1");

	mysql_function_query(mCon,query,false,"OnPlayerIRCBanCheck","s",pName);

	return true;
}*/
//                              Super Operator

//                                  Owner

IRCCMD:makeadmin(botid, channel[], user[], host[],params[])
{
        new pName[MAX_PLAYER_NAME], level, id, string[150], lvl[30], status[10];

        if(!IRC_IsOwner(botid, channel, user)) return _ERROR_(0);
        if(sscanf(params,"ui",id,level)) return _CMD_("!makeadmin [Name/ID] [Level]");
        if(!IsPlayerConnected(id)) return _ERROR_(1);
        if(level > 3 || level < 0) return IRC_GroupSay(xGroupID, IRC_CHANNEL,"0,4Invalid Level! (0-3)");

        GetPlayerName(id, pName, sizeof(pName));

        if(level > CallRemoteFunction("acc_GetAdmin", "i", id)) { status = "promoted"; }
        else { status = "demoted"; }
        switch(level)
        {
                case 0: lvl = "a Registered User";
                case 1: lvl = "a Moderator";
                case 2: lvl = "an Administrator";
                case 3: lvl = "a Manager";
        }
        format(string,sizeof(string),"%s (IRC) has %s %s (%d) to %s", user, status, pName, id, lvl);
        SendClientMessageToAll(0xFF8800AA, string);
        format(string,sizeof(string),"7%s (IRC) has %s %s (%d) to %s", user, status, pName, id, lvl);
        IRC_GroupSay(xGroupID, IRC_CHANNEL,string);
        
        CallRemoteFunction("acc_SetAdmin","ii",id,level);
        
        return true;
}

IRCCMD:savestats(botid, channel[], user[], host[], params[])
{
	if(!IRC_IsOwner(botid, channel, user)) return _ERROR_(0);
	CallRemoteFunction("acc_SaveStats", "");
	IRC_GroupSay(xGroupID, IRC_ADMIN, "4 -- STATS SAVED! -- ");
	return true;
}

IRCCMD:restart(botid, channel[], user[], host[], params[])
{
	if(!IRC_IsOwner(botid, channel, user)) return _ERROR_(0);
	CallRemoteFunction("acc_SaveStats", "");
	IRC_GroupSay(xGroupID, IRC_ADMIN, "4 -- STATS SAVED! -- ");

	SendRconCommand("gmx");
	return true;
}

//                                Functions

/*function OnPlayerIRCBanCheck(syntax[])
{
	mysql_store_result(mCon);
	if(mysql_num_rows(mCon))
	{
	    new BanID,uName[MAX_PLAYER_NAME],aName[MAX_PLAYER_NAME],ip[16],date[128],reason[128],string[128],result[128];
	    mysql_fetch_row(result);
	   	format(string, sizeof(string), "0,10Ban Result for: %s", syntax);
		IRC_GroupSay(xGroupID,IRC_CHANNEL, string);
		sscanf(result,"p<|>is[24]s[24]s[16]s[128]s[128]",BanID,uName,aName,ip,date,reason);
	    new resultline[6][64];
	    format(resultline[0],128,"0,10Name: %s",uName);
	    format(resultline[1],128,"0,10Banned By: %s",aName);
	    format(resultline[2],128,"0,10Reason: %s",reason);
	    format(resultline[3],128,"0,10Date: %s",date);
	    format(resultline[4],128,"0,10BanID: %i",BanID);
	    format(resultline[5],128,"0,10IP on Ban: %s",ip);
	    for(new i=0;i<6;i++)
	    {
	        IRC_GroupSay(xGroupID,IRC_CHANNEL, resultline[i]);
	    }
	}
	else { mysql_free_result(mCon); return _ERROR_(2); }
	
	mysql_free_result(mCon);
	return true;
}

function OnPlayerNickCheck(syntax[],type) {
	new string[128];
	new AccID,ip[16],pName[MAX_PLAYER_NAME],result[128];
	mysql_store_result(mCon);
	
	if(type == 0)
	{
	    new len = mysql_num_rows(mCon);
	    if(len > 0)
	    {
	        format(string, sizeof(string), "0,10Results for: \"%s\"", syntax);
			IRC_GroupSay(xGroupID, IRC_CHANNEL, string);
			
			for(new i=0;i<len;i++) { NickCheckQuery(syntax,i); }
			
			if(len == 15) IRC_GroupSay(xGroupID, IRC_CHANNEL, "0,10* RESULTS LIMITED TO 15. *");
	    }
	    else _ERROR_(2);
	}
	
	else if(type == 1)
	{
	    mysql_fetch_row(result);
	    sscanf(result,"p<|>is[24]s[16]",AccID,pName,ip);
	    format(string,sizeof(string),"0,10AccID: %i - %s (%s)",AccID,pName,ip);
	    IRC_GroupSay(xGroupID, IRC_CHANNEL, string);
	}
	
	mysql_free_result(mCon);
	return true;
}

function NickCheckQuery(searchstr[],pos)
{
	new query[128],end[15];
    query = "SELECT `aID`, `Name`, `IP` FROM `accounts` WHERE `Name` LIKE '%";
	format(end,sizeof(end),"%i,1",pos);

	strcat(query,searchstr); strcat(query,"%' LIMIT "); strcat(query,end);
	
	mysql_function_query(mCon, query, false, "OnPlayerNickCheck", "si", searchstr, 1);
	
	return 1;
}

function IPCheckQuery(searchstr[],pos)
{
	new query[128],end[20];

	format(query,sizeof(query),"SELECT `IP`,`Name` FROM `accounts` WHERE `IP` LIKE '%s",searchstr);
	format(end,sizeof(end),"' LIMIT %i,1",pos);
	strcat(query,"%"); strcat(query,end);

	mysql_function_query(mCon, query, false, "OnPlayerIPCheck", "si", searchstr, 1);

	return 1;
}

function OnPlayerIPCheck(syntax[],type) {
	new result[128], pName[MAX_PLAYER_NAME], ip[16], string[128];
	mysql_store_result(mCon);

	if(type == 0)
	{
	    new len = mysql_num_rows(mCon);
	    if(len > 0)
	    {
	        format(string, sizeof(string), "0,10Results for: %s", syntax);
			IRC_GroupSay(xGroupID, IRC_CHANNEL, string);

			for(new i=0;i<len;i++) { IPCheckQuery(syntax,i); }

			if(len == 15) IRC_GroupSay(xGroupID, IRC_CHANNEL, "0,10* RESULTS LIMITED TO 15. *");
	    }
	    else _ERROR_(2);
	}
	else if(type == 1)
	{
	    mysql_fetch_row(result);
	    sscanf(result,"p<|>s[16]s[24]",ip,pName);
	    format(string,sizeof(string),"0,10%s - %s",pName,ip);
	    IRC_GroupSay(xGroupID, IRC_CHANNEL, string);
	}

	mysql_free_result(mCon);
	return true;
}

TimeStamp() {

	new year, month, day; 	  getdate(year, month, day);
	new hour, minute, second; gettime(hour, minute, second);
	new z[128];

	new month2[15];
	switch(month) {
	    case 1:  month2 = "January"; case 2:  month2 = "February"; case 3:  month2 = "March";
	    case 4:  month2 = "April"; case 5:  month2 = "May"; case 6:  month2 = "June";
	    case 7:  month2 = "July"; case 8:  month2 = "August"; case 9:  month2 = "September";
	    case 10: month2 = "October"; case 11: month2 = "November"; case 12: month2 = "December";
	}

	new end[3];
	if(day == 11 || day == 12 || day == 13) { end = "th"; }
	else if(day - (day / 10) * 10 == 1) { end = "st"; }
	else if(day - (day / 10) * 10 == 2) { end = "nd"; }
    else if(day - (day / 10) * 10 == 3) { end = "rd"; }
    else { end = "th"; }
	format(z, sizeof(z), "%s %i%s, %i on %02d:%02d:%02d", month2, day, end, year, hour, minute, second);
	return z;
}*/

function QueryContainsForbiddenChar(qstr[],len)
{
	for(new i=0;i<len;i++)
	{
	    if(qstr[i] == '%' || qstr[i] == '#' || qstr[i] == '-') return 1;
	}
	return 0;
}

function ShowCommands(rows) {
	switch(rows) {
		case 0: IRC_GroupSay(xGroupID, IRC_CHANNEL, "0,2Stadium-Madness Voiced Commands:");
		case 1: IRC_GroupSay(xGroupID, IRC_CHANNEL, "0,2!cmds - !players - !m - !getid  ");
		case 2: IRC_GroupSay(xGroupID, IRC_CHANNEL, "0,2!pm                             ");
	}
	
	rows ++;
	SetTimerEx("ShowCommands", 500, false, "i", rows);
	return true;
}

function _ERROR_(type) {
	switch(type) {
	    case 0: IRC_GroupSay(xGroupID, IRC_CHANNEL, "7You don't have sufficient requirements to use this command!");
	    case 1: IRC_GroupSay(xGroupID, IRC_CHANNEL, "4Player not connected!");
	    case 2: IRC_GroupSay(xGroupID, IRC_CHANNEL, "0,10No results!");
	    case 3: IRC_GroupSay(xGroupID, IRC_CHANNEL, "4Error: Request contains illegal characters!");
	}
	return true;
}

function _CMD_(syntax[]) {
	new cmdstr[50];
	format(cmdstr, sizeof(cmdstr), "7Correct syntax: %s", syntax);
	IRC_GroupSay(xGroupID, IRC_CHANNEL, cmdstr); return true;
}

/* ---------------- CROSS-SCRIPTING ---------------*/

public IRC_Admin_Text(text[]) { IRC_GroupSay(xGroupID, IRC_ADMIN, text); return 1; }
public IRC_Text(text[]) { IRC_GroupSay(xGroupID, IRC_CHANNEL, text); return 1; }


