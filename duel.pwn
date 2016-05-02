#include <a_samp>
#include <float>
#include <SM_controls\defines>

#define DUEL 8
#define DUEL_INTERIOR 0

new DuelRequest[MAX_PLAYERS]; //will store the ID
new DuelKills[MAX_PLAYERS];
new bool:Duel;

new Float:Spawn[2][4] = {{590.5732,-2699.1548,30.8829,131.0906},{572.1360,-2716.6851,30.8829,314.2254}};

forward duel_DuelOngoing();
forward duel_Exit(playerid);
forward duel_GetRequest(playerid);
forward duel_SetRequest(id1,id2);
forward duel_UpdateMissionInfo(playerid);
forward duel_Spawn(playerid);
forward duel_Start(id1,id2);

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" DUEL Filterscript - LOADED");
	print("--------------------------------------\n");
	
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    DuelRequest[i] = -1;
	    DuelKills[i] = -1;
	}
	
	Duel = false;
	
	return 1;
}

public OnFilterScriptExit()
{
	print("\n--------------------------------------");
	print(" DUEL Filterscript - UNLOADED");
	print("--------------------------------------\n");
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == DUEL)
	{
		duel_Exit(playerid);
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == DUEL)
	{
	    duel_Spawn(playerid);
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == DUEL)
	{
        DuelKills[killerid]++;
        SetPlayerHealth(killerid,100.00);
        
		if(DuelKills[killerid] == 5)
		{
		    CallRemoteFunction("GM_RespawnPlayerToLobby","i",killerid);
		    CallRemoteFunction("GM_RespawnPlayerToLobby","i",playerid);

			duel_Exit(playerid);
			
			new name[MAX_PLAYER_NAME],name2[MAX_PLAYER_NAME],str[128];
			GetPlayerName(killerid,name,sizeof(name));
			GetPlayerName(playerid,name2,sizeof(name2));

			format(str,sizeof(str),"[DUEL]%s (%i) has won a Duel against %s (%i)",name,killerid,name2,playerid);
		    SendClientMessageToAll(COLOR_ORANGE,str);
		}
		else
		{
		    duel_UpdateMissionInfo(playerid);
		    duel_UpdateMissionInfo(killerid);
		}
	}
	return 1;
}

public duel_Spawn(playerid)
{
	new rand = random(sizeof(Spawn));
	SetPlayerPos(playerid,Spawn[rand][0],Spawn[rand][1],Spawn[rand][2]);
	SetPlayerFacingAngle(playerid,Spawn[rand][3]);
	
	SetPlayerInterior(playerid,DUEL_INTERIOR);
	GivePlayerWeapon(playerid,24,600);
	GivePlayerWeapon(playerid,31,5000);
	
	return 1;
}
public duel_Start(id1,id2)
{
	duel_Spawn(id1);
	duel_Spawn(id2);
	CallRemoteFunction("GM_SetPlayerMode","ii",id1,DUEL);
	CallRemoteFunction("GM_SetPlayerMode","ii",id2,DUEL);

	DuelKills[id1] = 0;
	DuelKills[id2] = 0;
	Duel = true;
	return 1;
}
public duel_DuelOngoing()
{
	return Duel;
}

public duel_Exit(playerid)
{
	new targetid;
	if((targetid = DuelRequest[playerid]) != INVALID_PLAYER_ID)
	{
	    DuelKills[targetid] = 0;
	    DuelKills[playerid] = 0;
	    DuelRequest[targetid] = -1;
	    DuelRequest[playerid] = -1;
        Duel = false;
	    //CallRemoteFunction("GM_RespawnPlayerToLobby","i",playerid);
	    if(CallRemoteFunction("GM_GetPlayerMode","i",targetid) == DUEL)
			CallRemoteFunction("GM_RespawnPlayerToLobby","i",targetid);
	}
	
	return 1;
}

public duel_GetRequest(playerid)
{
	return DuelRequest[playerid];
}

public duel_SetRequest(id1,id2)
{
	if(id1 != INVALID_PLAYER_ID && id2 != INVALID_PLAYER_ID)
	{
		DuelRequest[id1] = id2;
		DuelRequest[id2] = id1;
	}
	return 1;
}

public duel_UpdateMissionInfo(playerid)
{
	new name[MAX_PLAYER_NAME],str[128];

	GetPlayerName(DuelRequest[playerid],name,sizeof(name));

	format(str,sizeof(str),"You: %i~n~%s: %i",DuelKills[playerid],name,DuelKills[DuelRequest[playerid]]);
    CallRemoteFunction("textdraw_Update","is",playerid,str);
}
