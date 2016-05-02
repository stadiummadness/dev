#include <a_samp>
#include <SM_controls\defines>
#include <SM_controls\dm>

#define DM 4

new Kills[MAX_PLAYERS];
new Leader,MaxKills,currentMap,Timer;

forward DM_Init(playerid);
forward DM_SubmitCurrentMap(mapid);
forward DM_Exit(playerid);
forward DM_UpdateMissionInfo();

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" DM Filterscript - LOADED");
	print("--------------------------------------\n");
	
	//initialize data
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    Kills[i] = 0;
	}
	
	Leader = -1;
	MaxKills = 0;
	
	Timer = SetTimer("DM_UpdateMissionInfo",1000,true);
	return 1;
}

public OnFilterScriptExit()
{
	print("\n--------------------------------------");
	print(" DM Filterscript - UNLOADED");
	print("--------------------------------------\n");
	
	KillTimer(Timer);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == DM)
	{
		DM_Exit(playerid);
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == DM)
	{
	    DM_Init(playerid);
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == DM)
	{
		if(killerid != INVALID_PLAYER_ID) Kills[killerid]++;
		if(Kills[killerid] > MaxKills)
		{
	    	Leader = killerid, MaxKills = Kills[killerid];
		}
		else if(Kills[killerid] == MaxKills)
		{
			Leader = -1;
		}
	}
	return 1;
}

public DM_Init(playerid)
{
	new rand;
	SetPlayerInterior(playerid,DMInterior[currentMap-1]);

	switch(currentMap)
	{
		case 1:
		{
		    rand = random(sizeof(DM1Spawn));
		  	SetPlayerPos(playerid, DM1Spawn[rand][0], DM1Spawn[rand][1], DM1Spawn[rand][2]);
	    }
	    case 2:
		{
		    rand = random(sizeof(DM2Spawn));
		    SetPlayerPos(playerid,DM2Spawn[rand][0],DM2Spawn[rand][1],DM2Spawn[rand][2]);
		}
	}
	GivePlayerWeapon(playerid, 24, 50);
	GivePlayerWeapon(playerid, 31, 250);

	return 1;
}

public DM_SubmitCurrentMap(mapid)
{
	currentMap = mapid;
	return 1;
}

public DM_Exit(playerid)
{
	if(playerid == Leader || Kills[playerid] == MaxKills)
	{
		Leader = -1;
		MaxKills = -1;
		for(new i=0;i<MAX_PLAYERS;i++)
		{
		    if(IsPlayerConnected(i) && i != playerid && CallRemoteFunction("GM_GetPlayerMode","i",i) == DM)
		    {
				if(Kills[i] > MaxKills)
				{
					Leader = i;
					MaxKills = Kills[i];
				}
				else if(Kills[i] == MaxKills)
				{
				    Leader = -1;
				}
		    }
		}
	}
	Kills[playerid] = 0;
	CallRemoteFunction("GM_RespawnPlayerToLobby","i",playerid);
	return 1;
}

public DM_UpdateMissionInfo()
{
	new str[128],leaderinfo[32];
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    if(IsPlayerConnected(i) && CallRemoteFunction("GM_GetPlayerMode","i",i) == DM)
	    {
			if(Leader == -1) leaderinfo = "Draw";
			else {
		 		GetPlayerName(Leader,leaderinfo,sizeof(leaderinfo));
		 		format(leaderinfo,sizeof(leaderinfo),"%s (%i Kills)",leaderinfo,MaxKills);
			}
			
			format(str,sizeof(str),"Kills: %i~n~Leader: %s",Kills[i],leaderinfo);
			CallRemoteFunction("GM_OnReceiveMissionData","is",i,str);
		}
	}
	return 1;
}
