#include <a_samp>
#include <SM_controls\defines>
#include <SM_controls\derby>

#define DERBY 6

new Survivers,DerbySpawnspot,currentMap,Timer;

forward derby_Init(playerid);
forward derby_Exit(playerid);
forward derby_GetSurvivers();
forward derby_SubmitCurrentMap(mapid);
forward derby_UpdateMissionInfo();

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Derby Filterscript - LOADED");
	print("--------------------------------------\n");
	
	Survivers = 0;
	DerbySpawnspot = 0;
	
	Timer = SetTimer("derby_UpdateMissionInfo",1000,true);
	return 1;
}

public OnFilterScriptExit()
{
	print("\n--------------------------------------");
	print(" Derby Filterscript - UNLOADED");
	print("--------------------------------------\n");
	
	KillTimer(Timer);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == DERBY)
	{
		derby_Exit(playerid);
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == DERBY)
	{
	    derby_Init(playerid);
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(CallRemoteFunction("GM_ModeStarted","i",DERBY))
	{
		derby_Exit(playerid);
	}
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == DERBY)
	{
	    SendClientMessage(playerid,COLOR_RED,"You have exited your Vehicle and Died.");
	    CallRemoteFunction("GM_DestroyPlayerVehicle","i",playerid);
	    SetPlayerHealth(playerid,0.0);

		if(CallRemoteFunction("GM_ModeStarted","i",DERBY))
		{
		    derby_Exit(playerid);
		}
	}
	return 1;
}

public derby_Init(playerid)
{
	Survivers++;
	SetPlayerInterior(playerid,DerbyInterior[currentMap-1]);
	SetPlayerPos(playerid,DerbySpawn[currentMap -1][0],DerbySpawn[currentMap -1][0],DerbySpawn[currentMap -1][0]);
	new Float:x,Float:y,Float:z,Float:angle;

	switch(currentMap)
	{
		case 1:
		{
		    x = Derby1Pos[DerbySpawnspot][0],y = Derby1Pos[DerbySpawnspot][1], z = Derby1Pos[DerbySpawnspot][2], angle = Derby1Pos[DerbySpawnspot][3];
			DerbySpawnspot++;
			if(DerbySpawnspot == sizeof(Derby1Pos)) DerbySpawnspot = 0;
		}
		case 2:
		{
		    x = Derby2Pos[DerbySpawnspot][0],y = Derby2Pos[DerbySpawnspot][1], z = Derby2Pos[DerbySpawnspot][2], angle = Derby2Pos[DerbySpawnspot][3];
			DerbySpawnspot++;
			if(DerbySpawnspot == sizeof(Derby2Pos)) DerbySpawnspot = 0;
		}
	}
	new vehid = CreateVehicle(451,x,y,z,angle,-1,-1,-1);
	LinkVehicleToInterior(vehid,DerbyInterior[currentMap-1]);
	PutPlayerInVehicle(playerid,vehid,0);

	CallRemoteFunction("GM_SetPlayerVehicle","ii",playerid,vehid);
	return 1;
}

public derby_Exit(playerid)
{
	CallRemoteFunction("GM_RespawnPlayerToLobby","i",playerid);
	Survivers--;
	if(Survivers < 2 && CallRemoteFunction("GM_ModeStarted","i",DERBY)) CallRemoteFunction("GM_SetTimeLeft","ii",DERBY,1); //Cancel the Mission
	return 1;
}

public derby_GetSurvivers()
{
	return Survivers;
}

public derby_SubmitCurrentMap(mapid)
{
	currentMap = mapid;
	return 1;
}

public derby_UpdateMissionInfo()
{
	new str[32];
	format(str,sizeof(str),"Survivers: %i",Survivers);
	
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    if(IsPlayerConnected(i) && CallRemoteFunction("GM_GetPlayerMode","i",i) == DERBY)
	    {
			CallRemoteFunction("GM_OnReceiveMissionData","is",i,str);
		}
	}
	
	return 1;
}
