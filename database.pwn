#include <a_samp>
#include <a_mysql>
#include <float>

#include <SM_controls\defines>

#define MYSQL_USERNAME 	"port_4017"
#define MYSQL_DATABASE 	"port_4017"
#define MYSQL_PASSWORD 	"wqao54g36c"
#define MYSQL_SERVER 	"127.0.0.1"

native WP_Hash(buffer[], len, const str[]);

new mCon, qString[1001];


forward getConnection();

//ACCOUNT-RELATED FUNCTIONS
forward DB_PlayerBanCheck(playerid);
forward DB_SavePlayerData(aid,admin,vip,kills,deaths,money,hours,minutes,seconds,xp,ip[16]);
forward DB_PlayerLogin(playerid,password[]);
forward DB_PlayerRegister(playerid,name[MAX_PLAYER_NAME],ip[16],password[]);
forward DB_BanPlayer(name[],admin[],ip[],reason[]);
forward DB_UnbanID(bid,admin[]);

forward OnUnban(bid,admin[]);
forward OnPlayerBanCheck(playerid);
forward OnPlayerLogin(playerid);
forward FindAccount(playerid);
forward OnFindAccount(playerid);

//COMMAND-RELATED FUNCTIONS
forward DB_VipCheck(playerid,accid);

forward OnVipCheck(playerid,accid);

//IRC-RELATED FUNCTIONS
forward DB_OfflineBan(aid,admin[],reason[]);

forward OnOfflineBan(admin[],reason[]);

//OTHER FUNCTIONS
forward KickPlayer(playerid);


public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" DATABASE FILTERSCRIPT - LOADED!");
	print("--------------------------------------\n");

	//Establish a connection to the MYSQL-Server
	mysql_debug(1);
	mCon = mysql_connect(MYSQL_SERVER, MYSQL_USERNAME, MYSQL_DATABASE, MYSQL_PASSWORD);
	if(mysql_ping(mCon) > 0) { print("MySQL - Database connected!"); }
	else { print("MySQL - Connection failed!"); }

	return 1;
}

public OnFilterScriptExit()
{
	print("\n--------------------------------------");
	print(" DATABASE FILTERSCRIPT - UNLOADED!");
	print("--------------------------------------\n");
	return 1;
}

/* -- CUSTOM FUNCTIONS -- */

/* ---- BEGIN OF ACCOUNT-RELATED FUNCTIONS ---- */

public getConnection() { return mCon; }

public DB_PlayerBanCheck(playerid)
{
	new name[MAX_PLAYER_NAME];
	new ip[16];
	GetPlayerName(playerid,name,sizeof(name));
	GetPlayerIp(playerid,ip,sizeof(ip));

    format(qString, sizeof(qString), "SELECT `Name`, `Admin`, `Reason`, `IP`, `Date` FROM `bans` WHERE `Name` = '%s' OR `IP` = '%s' LIMIT 1", name, ip);
	mysql_function_query(mCon, qString, true, "OnPlayerBanCheck", "i", playerid);
	return 1;
}

public DB_PlayerLogin(playerid,password[])
{
	new hashPass[129],name[MAX_PLAYER_NAME];

	GetPlayerName(playerid,name,sizeof(name));

    mysql_real_escape_string(password, password);

	WP_Hash(hashPass, sizeof(hashPass), password);
	
	format(qString, sizeof(qString), "SELECT * FROM `accounts` WHERE Name = '%s' AND `Password` = '%s' LIMIT 1", name, hashPass);
	mysql_function_query(mCon, qString, true, "OnPlayerLogin", "i", playerid);
	return 1;
}

public DB_PlayerRegister(playerid,name[MAX_PLAYER_NAME],ip[16],password[])
{
	new hashPass[129];

	mysql_real_escape_string(password, password);

    WP_Hash(hashPass, sizeof(hashPass), password);

	format(qString, sizeof(qString), "INSERT INTO `accounts` \
	(`Name`,`Password`,`IP`,`RegDate`,`LastPlayed`,`Admin`,`Vip`,`XP`,`Money`,`Kills`,`Deaths`,`Hours`,`Minutes`,`Seconds`) VALUES \
	('%s','%s','%s',NOW(),NOW(),'0','0','0','0','0','0','0','0','0')", name, hashPass, ip);
	mysql_function_query(mCon, qString, false, "","");

	SendClientMessage(playerid,COLOR_LIGHT_BLUE,"You have successfully registered an Account!.");
	CallRemoteFunction("acc_ShowLoginDialog","ii",playerid,0);

	return 1;
}

public DB_SavePlayerData(aid,admin,vip,kills,deaths,money,hours,minutes,seconds,xp,ip[16])
{
	format(qString,sizeof(qString),"UPDATE `accounts` SET `IP` = '%s', `LastPlayed` = NOW(), `Admin` = '%i', `Vip` = '%i', `Kills` = '%i', `Deaths` = '%i', `Money` = '%i', `Hours` = '%i', `Minutes` = '%i', `Seconds` = '%i', `XP` = '%i' WHERE `aID` = '%i'",ip,admin,vip,kills,deaths,money,hours,minutes,seconds,xp,aid);
	
	mysql_function_query(mCon,qString,false,"","");

	return 1;
}

public DB_BanPlayer(name[],admin[],ip[],reason[])
{
	format(qString,sizeof(qString),"INSERT INTO `bans` (`Name`,`Admin`,`IP`,`Date`,`Reason`) VALUES \
	('%s','%s','%s',NOW(),'%s')",name,admin,ip,reason);
	
	mysql_function_query(mCon,qString,false,"","");
	return 1;
}

public DB_UnbanID(bid,admin[])
{
	format(qString,sizeof(qString),"SELECT `Name` FROM `bans` WHERE `banID` = '%i'",bid);
	mysql_function_query(mCon,qString,true,"OnUnban","is",bid,admin);

	format(qString,sizeof(qString),"DELETE FROM `bans` WHERE `banID` = '%i'", bid);
	mysql_function_query(mCon,qString,false,"","");
	
	return 1;
}

public FindAccount(playerid)
{
	new name[MAX_PLAYER_NAME];

	GetPlayerName(playerid,name,MAX_PLAYER_NAME);

	format(qString,sizeof(qString),"SELECT aID FROM `accounts` WHERE `Name` = '%s' LIMIT 1",name);
	mysql_function_query(mCon,qString,true,"OnFindAccount","i",playerid);

	return 1;
}

/* ---- ACCOUNTS - THREADED QUERIES ----*/

public OnPlayerBanCheck(playerid)
{
	new rows,fields;
	cache_get_data(rows,fields,mCon);
	if(rows > 0)
	{
		new name[MAX_PLAYER_NAME],admin[MAX_PLAYER_NAME],reason[64],ip[16],date[128];
		
		cache_get_row(0,0,name,mCon);
		cache_get_row(0,1,admin,mCon);
		cache_get_row(0,2,reason,mCon);
		cache_get_row(0,3,ip,mCon);
		cache_get_row(0,4,date,mCon);
		
		CallRemoteFunction("acc_ShowBanDialog","isssss",playerid,name,admin,reason,ip,date);
	    
	    SetTimerEx("KickPlayer",2000,false,"i",playerid);
	}
	else
	{
	    FindAccount(playerid);
	}
	return 1;
}

public OnFindAccount(playerid)
{
	new rows,fields;
	cache_get_data(rows,fields,mCon);

	if(rows) { CallRemoteFunction("acc_ShowLoginDialog","ii",playerid,0);  }
	else { CallRemoteFunction("acc_ShowRegisterDialog","i",playerid); }

	return 1;
}

public OnPlayerLogin(playerid)
{
	new rows,fields;
	cache_get_data(rows,fields,mCon);

	if(rows == 1)
	{
		new admin[2],vip[2],kills[7],deaths[7],xp[11],money[11],aid[6],hours[5],minutes[3],seconds[3];

		cache_get_row(0,0,aid,mCon);
		cache_get_row(0,6,admin,mCon);
		cache_get_row(0,7,vip,mCon);
		cache_get_row(0,8,xp,mCon);
		cache_get_row(0,9,money,mCon);
		cache_get_row(0,10,kills,mCon);
		cache_get_row(0,11,deaths,mCon);
		cache_get_row(0,12,hours,mCon);
		cache_get_row(0,13,minutes,mCon);
		cache_get_row(0,14,seconds,mCon);
		
		CallRemoteFunction("acc_SetLoginData","iiiiiiiiiii",playerid,strval(aid),strval(admin),strval(vip),strval(xp),strval(money),strval(kills),strval(deaths),strval(hours),strval(minutes),strval(seconds));
 	}

 	else
 	{
 	    CallRemoteFunction("acc_ShowLoginDialog","ii",playerid,1);
 	}

	return 1;
}

public OnUnban(bid,admin[])
{
	new rows,fields,name[MAX_PLAYER_NAME],str[128];
	
	cache_get_data(rows,fields,mCon);
	
	if(rows)
	    cache_get_row(0,0,name,mCon);
	else
	    name = "NULL";
	
	format(str,sizeof(str),"%s has unbanned %s (BanID: %i)",admin,name,bid);
	SendClientMessageToAll(COLOR_RED,str);
	
	format(str,sizeof(str),"7%s has unbanned %s (BanID: %i)",admin,name,bid);
	CallRemoteFunction("IRC_Text","s",str);
	
	return 1;
}
/* ---- END OF ACCOUNT-RELATED FUNCTIONS ---- */
/* ---- BEGIN OF IRC-RELATED FUNCTIONS ---- */
public DB_OfflineBan(aid,admin[],reason[])
{
	format(qString,sizeof(qString),"SELECT `Name`, `IP` FROM `accounts` WHERE `aID` = '%i'",aid);
	mysql_function_query(mCon,qString,true,"OnOfflineBan","ss",admin,reason);
	return 1;
}

public OnOfflineBan(admin[],reason[])
{
	new rows,fields;
	cache_get_data(rows,fields,mCon);
	
	if(rows)
	{
		new name[MAX_PLAYER_NAME],ip[16],msgstr[150];
		cache_get_row(0,0,name,mCon);
		cache_get_row(0,1,ip,mCon);
		
		DB_BanPlayer(name,admin,ip,reason);
		
		format(msgstr,sizeof(msgstr),"%s (IRC) has offline-banned %s for: %s",admin,name,reason);
		SendClientMessageToAll(0xFF0000FF,msgstr);
		format(msgstr,sizeof(msgstr),"7%s (IRC) has offline-banned %s for: %s",admin,name,reason);
		CallRemoteFunction("IRC_Text","s",msgstr);
	}
	else
	{
	    CallRemoteFunction("IRC_Text","s","7ERROR: This Account does not exist!");
	}
	
	return 1;
}
/* ---- END OF IRC-RELATED FUNCTIONS ---- */
/* ---- BEGIN OF COMMAND-RELATED FUNCTIONS ---- */
public DB_VipCheck(playerid,accid)
{
    format(qString,sizeof(qString),"SELECT `exp_year`, `exp_month`, `exp_day` FROM `vips` WHERE `aID` = %i",accid);
	mysql_function_query(mCon,qString,true,"OnVipCheck","ii",playerid,accid);
	return 1;
}

public OnVipCheck(playerid,accid)
{
	new rows,fields;
	cache_get_data(rows,fields,mCon);

	if(rows)
	{
	    new expDay[3],expMonth[3],expYear[5],str[64];

		cache_get_row(0,0,expYear,mCon);
		cache_get_row(0,1,expMonth,mCon);
		cache_get_row(0,2,expDay,mCon);

		format(str,sizeof(str),"VIP Expiry Date: %i/%i/%i",expMonth,expDay,expYear);
	    SendClientMessage(playerid,COLOR_ORANGE,str);
	}
	
	return 1;
}
/* ---- END OF COMMAND-RELATED FUNCTIONS ---- */

public KickPlayer(playerid) { Kick(playerid); return 1; }
