#include <a_samp>
#include <SM_controls\defines>
#include <SM_controls\tdm>

#define TDM 3

forward TDM_ClassSelection(playerid);
forward TDM_SubmitCurrentMap(mapid);
forward TDM_Init(playerid,team);
forward TDM_UpdateMissionInfo();
forward TDM_Exit(playerid);

new currentMap,Timer;
new Kills[2];
new TeamColor[2] = { COLOR_PURPLE, COLOR_BLUE };

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" TDM Filterscript - LOADED");
	print("--------------------------------------\n");
	
	Kills[0] = 0;
	Kills[1] = 0;
	
	Timer = SetTimer("TDM_UpdateMissionInfo",1000,true);
	return 1;
}

public OnFilterScriptExit()
{
	print("\n--------------------------------------");
	print(" TDM Filterscript - UNLOADED");
	print("--------------------------------------\n");
	
	KillTimer(Timer);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == TDM)
	{
	    TDM_Init(playerid,GetPlayerTeam(playerid));
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == TDM && GetPlayerTeam(playerid) != NO_TEAM)
	{
		new oppTeam = (GetPlayerTeam(playerid) == 0)? 1:0;
		Kills[oppTeam]++;
	}
	return 1;
}

public TDM_Init(playerid,team)
{
	GivePlayerWeapon(playerid,24,150);
	GivePlayerWeapon(playerid,31,500);

	SetPlayerInterior(playerid,TDMInterior[currentMap-1]);
	SetPlayerTeam(playerid,team);
	SetPlayerColor(playerid,TeamColor[team]);

	if(GetPlayerTeam(playerid) == 0)
	{
    	SetPlayerSkin(playerid,TDMSkins[currentMap-1][0]);
		SetPlayerPos(playerid,TDMSpawn[currentMap-1][0][0],TDMSpawn[currentMap-1][0][1],TDMSpawn[currentMap-1][0][2]);
	}
	else
	{
		SetPlayerSkin(playerid,TDMSkins[currentMap-1][1]);
		SetPlayerPos(playerid,TDMSpawn[currentMap-1][1][0],TDMSpawn[currentMap-1][1][1],TDMSpawn[currentMap-1][1][2]);
	}
	return 1;
}

public TDM_Exit(playerid)
{
	CallRemoteFunction("GM_RespawnPlayerToLobby","i",playerid);
	return 1;
}

public TDM_ClassSelection(playerid) {
	new str[256];
	format(str,sizeof(str),"{00FF00}%s\n{0000FF}%s",TDMNames[currentMap-1][0],TDMNames[currentMap-1][1]);
	ShowPlayerDialog(playerid, DIALOG_TEAM_SELECTION, DIALOG_STYLE_LIST, "TEAM SELECTION", str , "Join!", "Exit");
	return 1;
}

public TDM_SubmitCurrentMap(mapid)
{
	currentMap = mapid;
	return 1;
}

public TDM_UpdateMissionInfo()
{
	new str[128];
	format(str,sizeof(str),"%s: %i~n~%s: ~%i",TDMNames[currentMap-1][0],Kills[0],TDMNames[currentMap-1][1],Kills[1]);

	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    if(IsPlayerConnected(i) && CallRemoteFunction("GM_GetPlayerMode","i",i) == TDM)
	    {
			CallRemoteFunction("GM_OnReceiveMissionData","is",i,str);
		}
	}

	return 1;
}
