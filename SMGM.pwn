#include <a_samp>
#include <sscanf2>
#include <SM_controls\defines>
#include <SM_controls\modes>

#pragma tabsize 0

#define TEAM_HUMAN 2
#define TEAM_ZOMBIE 3

#define LOBBY_INTERIOR 0

forward GM_SetPlayerMode(playerid,mode);
forward GM_GetPlayerMode(playerid);
forward GM_ExitMode(playerid);
forward GM_RespawnPlayerToLobby(id);
forward GM_GetPlayerCount();
forward GM_ModeStarted(modeid);
forward GM_GetTimeLeft(modeid);
forward GM_SetTimeLeft(modeid,time);
forward GM_StartMode(modeid);
forward GM_EndMode(modeid);
forward GM_Cycle();
forward GM_SetPlayerVehicle(playerid,vid);
forward GM_GetPlayerVehicle(playerid);
forward GM_DestroyPlayerVehicle(playerid);
forward GM_OnReceiveMissionData(playerid,text[]);
forward GM_StartMap(modeid);
forward GM_EndMap(modeid);
forward GM_SetPlayerRandomLobbySpawn(playerid);
forward GM_Countdown(modeid,secs);
forward GM_SetPlayerRandomSkin(playerid);
forward GM_NextMode(lastmode);
forward GM_Start(modeid);

enum gmInfo { Name[MAX_PLAYER_NAME],Mode, Team, Skin, Vehicle};
enum mInfo {Map, bool:Started, Time };

new mode_name[][] =
{
		{"Lobby"},{"race"},{"parkour"},{"TDM"},{"DM"},{"maze"},{"derby"},{"zombie"}
};

new ModeInfo[8][mInfo];
new playerinfo[MAX_PLAYERS][gmInfo];

new PICKUP_PARKOUR, PICKUP_ZOMBIE, PICKUP_TDM, PICKUP_DM, PICKUP_DERBY, PICKUP_RACE, PICKUP_MAZE, PICKUP_DUEL;
new MAX_MAPS[8] = { 1,2,1,1,2,1,1,1 };
new MIN_PLAYERS_FOR_MODE[8] = {0,0,0,2,0,0,2,1 };

new Float:LobbySpawn[4][4] = {
	{716.3716,-2686.6104,17.2000,88.6465},
	{611.1452,-2756.1184,23.8459,2.5442},
	{524.6376,-2686.6238,17.1378,273.6193},
	{611.1173,-2582.6028,17.2100,179.1799}
};

main()
{
		print("\n----------------------------------");
		print("             Stadium Madness v B1-002");
		print("             Written by");
		print("             Pit, Sasuke_Uchiha and Ryses");
		print("----------------------------------\n");
}

public OnGameModeInit()
{
	SetGameModeText("DM|TDM|Race|Parkour|Duel|Derby|Zombie");
	SendRconCommand("loadfs lobby");
	
	UsePlayerPedAnims();

	PICKUP_PARKOUR = CreatePickup(1318, 1,650.1898,-2665.3672,20.1671, -1);
	PICKUP_DUEL = CreatePickup(1318,1,664.2878,-2708.2036,20.1671,-1);
	PICKUP_ZOMBIE = CreatePickup(1318,1,577.6700,-2664.6633,20.2805,-1);
	PICKUP_TDM = CreatePickup(1318,1,592.7289,-2660.9150,20.3869,-1);
	PICKUP_DM = CreatePickup(1318,1,633.8051,-2666.7517,20.1671,-1);
	PICKUP_DERBY = CreatePickup(1318,1,627.0235,-2644.9824,20.2754,-1);
	PICKUP_RACE = CreatePickup(1318,1,597.2184,-2645.1602,20.1859,-1);
	PICKUP_MAZE = CreatePickup(1318,1,578.9706,-2702.7422,17.7218,-1);

	Create3DTextLabel("Parkour", 0x0077CCEE, 650.1898,-2665.3672,21.1671, 30.0, 0);
	Create3DTextLabel("Duel", 0x0077CCEE, 664.2878,-2708.2036,22.1671, 30.0, 0);
	Create3DTextLabel("Zombie", 0x0077CCEE, 577.6700,-2664.6633,21.2805, 30.0, 0);
	Create3DTextLabel("Team-Deathmatch", 0x0077CCEE, 592.7289,-2660.9150,21.3869, 30.0, 0);
	Create3DTextLabel("Deathmatch", 0x0077CCEE, 633.8051,-2666.7517,21.1671, 30.0, 0);
	Create3DTextLabel("Derby", 0x0077CCEE, 627.0235,-2644.9824,21.2754, 30.0, 0);
	Create3DTextLabel("Race", 0x0077CCEE, 597.2184,-2645.1602,21.1859, 30.0, 0);
	Create3DTextLabel("The Maze", 0x0077CCEE, 578.9706,-2702.7422,19.7218, 30.0, 0);

	AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);

	for(new i=1;i<8;i++)
	{
	    ModeInfo[i][Time] = -1; //-1 means inactive
		ModeInfo[i][Map] = 1;
	}
	
	for(new j=0;j<MAX_PLAYERS;j++)
	{
		playerinfo[j][Skin] = -1;
	}
	ModeInfo[TDM][Time] = 500, ModeInfo[DM][Time] = 300, ModeInfo[RACE][Time] = 200;
	ModeInfo[TDM][Started] = true, ModeInfo[DM][Started] = true, ModeInfo[RACE][Started] = true;
	SendRconCommand("loadfs TDM"); SendRconCommand("loadfs DM"); SendRconCommand("loadfs race");
	CallRemoteFunction("TDM_SubmitCurrentMap","i",1); CallRemoteFunction("DM_SubmitCurrentMap","i",1); CallRemoteFunction("race_SubmitCurrentMap","i",1);
	
	
	CallRemoteFunction("StartDM1","");
	CallRemoteFunction("StartTDM1","");
	
	SetTimer("GM_Cycle",1000,true);
	return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	return 1;
}

public OnPlayerConnect(playerid)
{
	GetPlayerName(playerid, playerinfo[playerid][Name], MAX_PLAYER_NAME);
	GM_SetPlayerMode(playerid,LOBBY);

	new str[15];
	for(new i=1;i<8;i++)
	{
	    if(ModeInfo[i][Started])
	    {
	        format(str,sizeof(str),"Start%s%i",mode_name[i],ModeInfo[i][Map]);
	        CallRemoteFunction(str,"i",playerid);
	    }
	}
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	new str[15];
	playerinfo[playerid][Skin] = -1;

	for(new i=1;i<8;i++)
	{
	    if(ModeInfo[i][Started])
	    {
	        format(str,sizeof(str),"End%s%i",mode_name[i],ModeInfo[i][Map]);
	        CallRemoteFunction(str,"i",playerid);
	    }
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(playerinfo[playerid][Mode] != TDM && playerinfo[playerid][Mode] != ZOMBIE)
	{
	    if(playerinfo[playerid][Skin] == -1) GM_SetPlayerRandomSkin(playerid);
		else SetPlayerSkin(playerid,playerinfo[playerid][Skin]);
	}
	if(playerinfo[playerid][Mode] != LOBBY && playerinfo[playerid][Mode] != DUEL)
	{
		if(!ModeInfo[playerinfo[playerid][Mode]][Map]) TogglePlayerControllable(playerid,0);
	}
	if(playerinfo[playerid][Mode] == LOBBY)
	{
	    GM_SetPlayerRandomLobbySpawn(playerid);
	}
	return true;
}

public OnVehicleDeath(vehicleid, killerid)
{
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    if(vehicleid == playerinfo[i][Vehicle]) playerinfo[i][Vehicle] = -1;
	}
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
   switch(dialogid)
   {
        case DIALOG_TEAM_SELECTION:
        {
           if(response)
           {
	     	 	new msg[200];
       	 		format(msg, sizeof(msg), "[MODE]%s (%d) has joined the Team-Deathmatch.", playerinfo[playerid][Name],playerid);
              	SendClientMessageToAll(COLOR_YELLOW,msg);
              	format(msg, sizeof(msg), "7%s (%d) has joined the Team-Deathmatch.", playerinfo[playerid][Name],playerid);
              	CallRemoteFunction("IRC_Text","s",msg);

				CallRemoteFunction("TDM_Init","ii",playerid,listitem);
              	GM_SetPlayerMode(playerid,TDM);
			  	//CallRemoteFunction("StopRadio","i",playerid);
          }
     	}
     	case DIALOG_DUEL:
     	{
     	    if(response)
     	    {
     	        new targetid;
     	        if(sscanf(inputtext,"i",targetid)) return SendClientMessage(playerid,COLOR_RED,"ERROR: Please enter a correct ID!");
     	        if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid,COLOR_ORANGE,"ERROR: PlayerID not connected!");
     	        if(playerid == targetid) return SendClientMessage(playerid,COLOR_ORANGE,"You cannot fight against yourself!");
				if(CallRemoteFunction("duel_GetRequest","i",playerid)) return SendClientMessage(playerid,COLOR_ORANGE,"You have already invited somebody for a Duel!");
				if(CallRemoteFunction("duel_GetRequest","i",targetid)) return SendClientMessage(playerid,COLOR_ORANGE,"PlayerID already has a Duel Invitation!");
				
				new str[128],name[MAX_PLAYER_NAME];
				GetPlayerName(playerid,name,sizeof(name));
				format(str,sizeof(str),"[DUEL]%s (%i) has invited you to a Duel! (/accept | /deny)",name,playerid);
				SendClientMessage(targetid,COLOR_ORANGE,str);

				CallRemoteFunction("duel_SetRequest","ii",playerid,targetid);
     	    }
     	}
   }
   return 1;
}
public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
	new str[128];
	GetPlayerName(playerid, playerinfo[playerid][Name], MAX_PLAYER_NAME);

	if(pickupid == PICKUP_PARKOUR) {
 		if(ModeInfo[PARKOUR][Time] == -1) return SendClientMessage(playerid,COLOR_RED,"* [PARKOUR]This Arena is currently locked!");
 		if(CallRemoteFunction("parkour_HasFinished","i",playerid)) return SendClientMessage(playerid,COLOR_RED,"* [PARKOUR]You have already finished this round!");
 		format(str, sizeof(str), "[MODE] %s (%d) has joined the Parkour.", playerinfo[playerid][Name], playerid);
		//ModeNotification(str,COLOR_YELLOW);
		SendClientMessageToAll(COLOR_YELLOW,str);
		format(str, sizeof(str), "7%s (%d) has joined the Parkour.", playerinfo[playerid][Name], playerid);
		CallRemoteFunction("IRC_Text", "s", str);

		GM_SetPlayerMode(playerid,PARKOUR);
		//CallRemoteFunction("StopRadio","i",playerid);
		CallRemoteFunction("parkour_Init","i",playerid);

		if(!ModeInfo[PARKOUR][Started]) TogglePlayerControllable(playerid,0);
   	}
	else if(pickupid == PICKUP_DUEL) {
		if(CallRemoteFunction("duel_GetRequest","i",playerid) != -1) return SendClientMessage(playerid,COLOR_RED,"You currently have an ongoing Invitation!");
		if(CallRemoteFunction("duel_DuelOngoing","")) return SendClientMessage(playerid,COLOR_ORANGE,"There is already an ongoing Duel!");
		SetPlayerPos(playerid,665.0386,-2715.9941,20.5286);
		ShowPlayerDialog(playerid,DIALOG_DUEL,DIALOG_STYLE_INPUT,"Start A Duel","Enter the PlayerID you wish to duel against!","Start","Cancel");
	}
 	else if(pickupid == PICKUP_ZOMBIE) {
 	    if(ModeInfo[ZOMBIE][Time] == -1) return SendClientMessage(playerid,COLOR_RED,"* [ZOMBIE]This Arena is currently locked!");

 		format(str, sizeof(str), "[MODE] %s (%d) has joined the Zombie Mode.", playerinfo[playerid][Name], playerid);
	    //ModeNotification(str,COLOR_YELLOW);
	    SendClientMessageToAll(COLOR_YELLOW,str);
		format(str, sizeof(str), "7%s (%d) has joined the Zombie Mode.", playerinfo[playerid][Name], playerid);
		CallRemoteFunction("IRC_Text", "s", str);

		//CallRemoteFunction("StopRadio","i",playerid);
		GM_SetPlayerMode(playerid,ZOMBIE);
		new team = (ModeInfo[ZOMBIE][Started])?(TEAM_ZOMBIE):(TEAM_HUMAN);

		CallRemoteFunction("zombie_SetTeam","ii",playerid,team);
		CallRemoteFunction("zombie_Init","ii",playerid,team);

		if(!ModeInfo[ZOMBIE][Started]) TogglePlayerControllable(playerid,0);
  	}
	else if(pickupid == PICKUP_TDM) {
		if(ModeInfo[TDM][Time] == -1) return SendClientMessage(playerid,COLOR_RED,"* [TDM]This Arena is currently locked!");
		CallRemoteFunction("TDM_ClassSelection","i",playerid);
 		if(!ModeInfo[TDM][Started]) TogglePlayerControllable(playerid,0);
 	}
	else if(pickupid == PICKUP_DM)
	{
		if(ModeInfo[DM][Time] == -1) return SendClientMessage(playerid,COLOR_RED,"* [DM]This Arena is currently locked!");
		
		if(!ModeInfo[DM][Started]) TogglePlayerControllable(playerid,0);
		format(str, sizeof(str), "[MODE] %s (%d) has joined the Deathmatch.", playerinfo[playerid][Name], playerid);
		//ModeNotification(str,COLOR_YELLOW);
		SendClientMessageToAll(COLOR_YELLOW,str);
		format(str, sizeof(str), "7%s (%d) has joined the Deathmatch.", playerinfo[playerid][Name], playerid);
		CallRemoteFunction("IRC_Text","s", str);
		//CallRemoteFunction("StopRadio","i",playerid);

		GM_SetPlayerMode(playerid,DM);
	    CallRemoteFunction("DM_Init","i",playerid);
	}
  	else if(pickupid == PICKUP_DERBY) {
  		if(ModeInfo[DERBY][Time] == -1) return SendClientMessage(playerid,COLOR_RED,"* [DERBY]This Arena is currently locked!");
		if(ModeInfo[DERBY][Started]) return SendClientMessage(playerid,COLOR_RED,"[DERBY]There is already a Derby ongoing, please wait for the next round!");

		format(str, sizeof(str), "[MODE] %s (%d) has joined the Derby.", playerinfo[playerid][Name], playerid);
		//ModeNotification(str,COLOR_YELLOW);
		SendClientMessageToAll(COLOR_YELLOW,str);
		format(str, sizeof(str), "7%s (%d) has joined the Derby.", playerinfo[playerid][Name], playerid);
		CallRemoteFunction("IRC_Text","s", str);
		
		//CallRemoteFunction("StopRadio","i",playerid);
		GM_SetPlayerMode(playerid,DERBY);
		CallRemoteFunction("derby_Init","i",playerid);
		
		TogglePlayerControllable(playerid,0);
		
	}
    else if(pickupid == PICKUP_RACE) {
        if(ModeInfo[RACE][Time] == -1) return SendClientMessage(playerid,COLOR_RED,"* [RACE]This Arena is currently locked!");
		if(CallRemoteFunction("race_HasFinished","i",playerid)) return SendClientMessage(playerid,COLOR_RED,"* [RACE]You have already finished this round!");

  		if(!ModeInfo[RACE][Started]) TogglePlayerControllable(playerid,0);
		format(str, sizeof(str), "[MODE] %s (%d) has joined the Race.", playerinfo[playerid][Name], playerid);
		//ModeNotification(str,COLOR_YELLOW);
		SendClientMessageToAll(COLOR_YELLOW,str);
		format(str, sizeof(str), "7%s (%d) has joined the Race.", playerinfo[playerid][Name], playerid);
		CallRemoteFunction("IRC_Text","s", str);
		
	    //CallRemoteFunction("StopRadio","i",playerid);
	    GM_SetPlayerMode(playerid,RACE);
	    CallRemoteFunction("race_Init","i",playerid);
	}
    else if(pickupid == PICKUP_MAZE) {
        if(ModeInfo[MAZE][Time] == -1) return SendClientMessage(playerid,COLOR_RED,"* [MAZE]This Arena is currently locked!");
	    if(CallRemoteFunction("maze_HasFinished","i",playerid)) return SendClientMessage(playerid,COLOR_RED,"[MAZE]You have already finished this round!");
	   
	    GM_SetPlayerMode(playerid,MAZE);
	    CallRemoteFunction("maze_Init","i",playerid);
	    
	    //CallRemoteFunction("StopRadio","i",playerid);
	    if(!ModeInfo[MAZE][Started]) TogglePlayerControllable(playerid,0);
	    
	    format(str, sizeof(str), "[MODE] %s (%d) has joined the Maze.", playerinfo[playerid][Name], playerid);
		//ModeNotification(str,COLOR_YELLOW);
		SendClientMessageToAll(COLOR_YELLOW,str);
		format(str, sizeof(str), "7%s (%d) has joined the Maze.", playerinfo[playerid][Name], playerid);
		CallRemoteFunction("IRC_Text","s", str);
	   
    }
	return 1;
}

/*-------------------------------------------------------   CYCLE   ---------------------------------------------------*/
public GM_Cycle()
{
	for(new i=1;i<8;i++)
	{
	    if(ModeInfo[i][Time] > 0 && ModeInfo[i][Started])
	    {
	        ModeInfo[i][Time]--;
	    }
 		else if(ModeInfo[i][Time] == 0)
        {
            GM_EndMap(i);
            GM_EndMode(i);
            GM_NextMode(i);
            
            ModeInfo[i][Time] = -1;
            new str[200];
            format(str,sizeof(str),"[MODE]The current %s has ended! Players are respawning in the Lobby.",FullModeName[i]);
            //ModeNotification(str,-1);
            SendClientMessageToAll(COLOR_WHITE,str);
        }
	}

	return true;
}
/*-------------------------------------------------------   MAP (UN)LOADING   ---------------------------------------------------*/

public GM_StartMap(modeid)
{
	CallRemoteFunction("maphandler_Start","ii",modeid,ModeInfo[modeid][Map]);
	return 1;
}

public GM_EndMap(modeid)
{
	CallRemoteFunction("maphandler_End","i",modeid);
	
	//define next map
	ModeInfo[modeid][Map] = (ModeInfo[modeid][Map] == MAX_MAPS[modeid])? (1) : (ModeInfo[modeid][Map]+1);
	
	return 1;
}

/*-------------------------------------------------------   NEXT MODE   ---------------------------------------------------*/

public GM_NextMode(lastmode)
{
	new newmode = (lastmode == 7)? (1):(lastmode+1);
	new bool:OK = false;
	
	while(!OK && newmode != lastmode)
	{
		if(ModeInfo[newmode][Time] == -1 && !ModeInfo[newmode][Started] && GM_GetPlayerCount() > MIN_PLAYERS_FOR_MODE[newmode]) OK = true;
		else { newmode = (newmode == 7)? (1):(newmode+1); }
	}
	
	SetTimerEx("GM_StartMode",10000,false,"i",newmode);
	SetTimerEx("GM_StartMap",7000,false,"i",newmode);
	
	return true;
}

public GM_StartMode(modeid)
{
	ModeInfo[modeid][Time] = 300;
	new str[200];
	format(str,sizeof(str),"[MODE]A new %s will start in 45 Seconds!",FullModeName[modeid]);
	//ModeNotification(str,-1);
	SendClientMessageToAll(COLOR_WHITE,str);

	new modestr[32];
	format(modestr,sizeof(modestr),"loadfs %s",mode_name[modeid]);
	SendRconCommand(modestr);
	format(modestr,sizeof(modestr),"%s_SubmitCurrentMap",mode_name[modeid]);
	CallRemoteFunction(modestr,"i",ModeInfo[modeid][Map]);


	SetTimerEx("GM_Countdown",42000,false,"ii",modeid,3);
	SetTimerEx("GM_Countdown",43000,false,"ii",modeid,2);
	SetTimerEx("GM_Countdown",44000,false,"ii",modeid,1);
	SetTimerEx("GM_Start",45000,false,"i",modeid);

	return true;
}

public GM_EndMode(modeid)
{
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    if(IsPlayerConnected(i) && playerinfo[i][Mode] == modeid)
	    {
	         TogglePlayerControllable(i,0);
			 ResetPlayerWeapons(i);
			 DisablePlayerRaceCheckpoint(i);
   		     GameTextForPlayer(i, "~r~Please wait...", 2000, 5);
   		     
   		     //TODO: Rewards
   		     
			 SetTimerEx("GM_RespawnPlayerToLobby",5000,false,"i",i);
	    }
	}
	
	new modestr[32];
	format(modestr,sizeof(modestr),"unloadfs %s",mode_name[modeid]);
	SendRconCommand(modestr);

	ModeInfo[modeid][Started] = false;

	return true;
}

public GM_Start(modeid)
{
	ModeInfo[modeid][Started] = true;
	for(new i=0;i<MAX_PLAYERS;i++)
	{
		if(IsPlayerConnected(i) && playerinfo[i][Mode] == modeid)
		{
			 TogglePlayerControllable(i,1);
			 GameTextForPlayer(i,"GO!",800,5);
			 PlayerPlaySound(i,1057,0.0,0.0,10.0);
	 	}
	}
	new str[64];
	format(str,sizeof(str),"[MODE]A new %s has just started!",FullModeName[modeid]);
	//ModeNotification(str,-1);
	SendClientMessageToAll(COLOR_WHITE,str);

	switch(modeid)
	{
	    case DERBY: if(CallRemoteFunction("derby_GetSurvivers","") < 2) ModeInfo[DERBY][Time] = 1;
	    case ZOMBIE: CallRemoteFunction("zombie_StartInfection","");
	}

	return true;
}

public GM_Countdown(modeid,secs)
{
	new seconds[3]; format(seconds,sizeof(seconds),"%i",secs);
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    if(IsPlayerConnected(i) && playerinfo[i][Mode] == modeid)
	    {
			PlayerPlaySound(i, 1056, 0.0, 0.0, 10.0);
			GameTextForPlayer(i,seconds,800,5);
	    }
	}
	return true;
}

/*-------------------------------------------------------   INFO UPDATE   ---------------------------------------------------*/
public GM_OnReceiveMissionData(playerid,text[])
{
	new str[256];
    format(str,sizeof(str),"time left: %s~n~%s",TimeFormat(ModeInfo[playerinfo[playerid][Mode]][Time]),text);
	CallRemoteFunction("textdraw_Update","is",playerid,str);
	return 1;
}
/*-------------------------------------------------------   RESPAWN   ---------------------------------------------------*/
public GM_RespawnPlayerToLobby(id)
{
	TogglePlayerControllable(id,1);
	GM_SetPlayerMode(id,LOBBY);
	ResetPlayerWeapons(id);
	SetPlayerHealth(id,100.00);
	GM_SetPlayerRandomLobbySpawn(id);
	if(playerinfo[id][Skin] == -1) GM_SetPlayerRandomSkin(id);
	else SetPlayerSkin(id,playerinfo[id][Skin]);
	CallRemoteFunction("textdraw_Update","is",id,"Lobby~n~no mode info!");
	return 1;
}
public GM_SetPlayerRandomSkin(playerid) {
	new rand = random(299) + 1; //excluding skin 0
	SetPlayerSkin(playerid, rand);
	return true;
}

public GM_SetPlayerRandomLobbySpawn(playerid)
{
	new rand = random(sizeof(LobbySpawn));
	SetPlayerPos(playerid,LobbySpawn[rand][0],LobbySpawn[rand][1],LobbySpawn[rand][2]);
	SetPlayerFacingAngle(playerid,LobbySpawn[rand][3]);
	SetPlayerInterior(playerid,LOBBY_INTERIOR);
	return true;
}

/*-------------------------------------------------------   CHANGE MODE/TEAM   ---------------------------------------------------*/
public GM_ExitMode(playerid)
{
	if(playerinfo[playerid][Mode] == LOBBY) return SendClientMessage(playerid,COLOR_RED,"You are already in the Lobby");

	else if(ModeInfo[playerinfo[playerid][Mode]][Time] != -1)
	{
		new str[20];
		format(str,sizeof(str),"%s_Exit",mode_name[playerinfo[playerid][Mode]]);
	    CallRemoteFunction(str,"i",playerid);
	    
        SendClientMessage(playerid,COLOR_GREEN,"You left your current game and returned to the Lobby");
 	}
	else if(playerinfo[playerid][Mode] == DUEL) return SendClientMessage(playerid,COLOR_RED,"You cannot leave a Duel!");

	return 1;
}

/*-------------------------------------------------------   OTHER STUFF   ---------------------------------------------------*/

/*function //ModeNotification(text[],color)
{
	for(new i=0;i<MAX_PLAYERS;i++)
	{
		if(IsPlayerConnected(i) && CallRemoteFunction("Get//ModeNotification","i",i))
		{
		    SendClientMessage(i,color,text);
		}
	}
	return 1;
}*/

TimeFormat(seconds)
{
	new str[10];
	if(seconds > 0)
	{
		new mins,secs,strmin[5],strsec[5];
		mins = seconds/60;
		secs = seconds - (60*mins);

		if(mins < 10) { format(strmin,sizeof(strmin),"0%i",mins); }
		else { format(strmin,sizeof(strmin),"%i",mins); }

		if(secs < 10) { format(strsec,sizeof(strsec),"0%i",secs); }
		else { format(strsec,sizeof(strsec),"%i",secs); }

		format(str,sizeof(str),"%s:%s",strmin,strsec);
	}
	else str = "00:00";

	return str;
}

/* ------------------------------- CROSS-SCRIPTING -----------------------------*/
public GM_SetPlayerMode(playerid, mode) {
	if(mode >= 0 && mode <= 8)
	{
		playerinfo[playerid][Mode] = mode;
		//SetPlayerVirtualWorld(playerid, mode);
	}
	switch(mode) {
	    case LOBBY: {
		    SetPlayerColor(playerid, COLOR_ORANGE);
		 	SetPlayerTeam(playerid, NO_TEAM);
		}
	    case RACE: {
			SetPlayerColor(playerid, COLOR_YELLOW);
			SetPlayerTeam(playerid,NO_TEAM);
		}
	    case PARKOUR: {
			SetPlayerColor(playerid, COLOR_YELLOW);
			SetPlayerTeam(playerid,NO_TEAM);
		}
	    case DM: {
			SetPlayerColor(playerid,COLOR_LIGHT_BLUE);
			SetPlayerTeam(playerid,NO_TEAM);
		}
	    case DUEL: {
			SetPlayerColor(playerid,COLOR_WHITE);
  			SetPlayerTeam(playerid,NO_TEAM);
		}
	    case MAZE: {
			SetPlayerColor(playerid,COLOR_YELLOW);
			SetPlayerTeam(playerid,NO_TEAM);
		}
	    case DERBY: {
	        SetPlayerColor(playerid,COLOR_GREY);
     		SetPlayerTeam(playerid,NO_TEAM);
		}
	}
	return true;
}

public GM_GetPlayerMode(playerid)
{
	return playerinfo[playerid][Mode];
}

public GM_GetPlayerCount()
{
	new count = 0;
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    if(IsPlayerConnected(i)) count++;
	}
	return count;
}

public GM_ModeStarted(modeid)
{
	return ModeInfo[modeid][Started];
}

public GM_GetTimeLeft(modeid)
{
	return ModeInfo[modeid][Time];
}

public GM_SetTimeLeft(modeid,time)
{
	if(time >= 1) ModeInfo[modeid][Time] = time;
	return 1;
}

public GM_SetPlayerVehicle(playerid,vid)
{
	GM_DestroyPlayerVehicle(playerid);
	playerinfo[playerid][Vehicle] = vid;
	return 1;
}

public GM_GetPlayerVehicle(playerid)
{
	return playerinfo[playerid][Vehicle];
}

public GM_DestroyPlayerVehicle(playerid)
{
	if(IsValidVehicle(playerinfo[playerid][Vehicle])) DestroyVehicle(playerinfo[playerid][Vehicle]);
	playerinfo[playerid][Vehicle] = -1;
}
