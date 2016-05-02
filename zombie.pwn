#include <a_samp>
#include <SM_controls\defines>
#include <SM_controls\zombie>

#define ZOMBIE 7

#define TEAM_HUMAN 2
#define TEAM_ZOMBIE 3

#define HUMAN_SKIN 60
#define ZOMBIE_SKIN 162

forward zombie_Init(playerid,team);
forward zombie_SubmitCurrentMap(mapid);
forward zombie_StartInfection();
forward zombie_SetTeam(playerid,teamid);
forward zombie_UpdateMissionInfo();
forward zombie_Exit(playerid);

new Humans,Zombies,currentMap,Timer;

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Zombie Filterscript - LOADED");
	print("--------------------------------------\n");
	
	Humans = 0;
	Zombies = 0;
	
	Timer = SetTimer("zombie_UpdateMissionInfo",1000,true);
	return 1;
}

public OnFilterScriptExit()
{
	print("\n--------------------------------------");
	print(" Zombie Filterscript - UNLOADED");
	print("--------------------------------------\n");
	
	KillTimer(Timer);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == ZOMBIE)
	{
	    zombie_Init(playerid,GetPlayerTeam(playerid));
	}
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == ZOMBIE)
	{
		zombie_Exit(playerid);
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == ZOMBIE)
    {
        if(GetPlayerTeam(playerid) == TEAM_HUMAN)
		{
		 	Humans--;
	 		Zombies++;

			zombie_SetTeam(playerid,TEAM_ZOMBIE);
	 		if(!Humans) { CallRemoteFunction("GM_SetTimeLeft","ii",ZOMBIE,1); }
 		}
    }
	return 1;
}

public zombie_Init(playerid,team)
{
	switch(team)
	{
	    case TEAM_HUMAN:
	    {
			GivePlayerWeapon(playerid,23,150);
			GivePlayerWeapon(playerid,25,60);
			switch(currentMap)
			{
				case 1: SetPlayerPos(playerid,Zombie1Spawn[0][0],Zombie1Spawn[0][1],Zombie1Spawn[0][2]);
				case 2: SetPlayerPos(playerid,Zombie2Spawn[0][0],Zombie2Spawn[0][1],Zombie2Spawn[0][2]);
			}
	    }
	    default:
	    {
	    	GivePlayerWeapon(playerid,9,1);
	    	switch(currentMap)
			{
				case 1: SetPlayerPos(playerid,Zombie1Spawn[1][0],Zombie1Spawn[1][1],Zombie1Spawn[1][2]);
				case 2: SetPlayerPos(playerid,Zombie2Spawn[1][0],Zombie2Spawn[1][1],Zombie2Spawn[1][2]);
			}
	    }
	}
	
	SetPlayerInterior(playerid,ZombieInterior[currentMap-1]);
	
	return 1;
}

public zombie_Exit(playerid)
{
	switch(GetPlayerTeam(playerid))
	{
	    case TEAM_HUMAN:
	    {
	        Humans--;
	        if(!Humans) CallRemoteFunction("GM_SetTimeLeft","ii",ZOMBIE,1);
	    }
	    default: Zombies--;
	}
	if(IsPlayerConnected(playerid)) CallRemoteFunction("GM_RespawnPlayerToLobby","i",playerid);
	return 1;
}

public zombie_SubmitCurrentMap(mapid)
{
	currentMap = mapid;
	return 1;
}

public zombie_StartInfection()
{
	new count= 0, newzombies, players[MAX_PLAYERS];
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    if(IsPlayerConnected(i) && CallRemoteFunction("GM_GetPlayerMode","i",i) == ZOMBIE)
	    {
	        SendClientMessage(i,COLOR_RED,"[ZOMBIE INFECTION]Some people have been infected with the Virus!");
			players[count] = i;
			count++;
	    }
	}

	if(count == 0) CallRemoteFunction("GM_SetTimeLeft","ii",ZOMBIE,1);
	else
	{
 		if(count <= 3) newzombies = 1;
		else if(count <= 6) newzombies = 2;
		else if(count <= 9) newzombies = 3;
		else if(count <= 12) newzombies = 4;
		else newzombies = 5;

		for(new k=0;k<newzombies;k++)
		{
		    new bool:OK = false;
			while(!OK)
			{
			    new rand = random(count);
			    if(GetPlayerTeam(rand) != TEAM_ZOMBIE)
			    {
					OK = true;
					zombie_SetTeam(players[rand],TEAM_ZOMBIE);
					
			        ResetPlayerWeapons(players[rand]);
			        GivePlayerWeapon(players[rand],9,1);
					
					Humans--;
					Zombies++;
					
					switch(currentMap)
					{
						case 1: SetPlayerPos(players[rand],Zombie1Spawn[1][0],Zombie1Spawn[1][1],Zombie1Spawn[1][2]);
						case 2: SetPlayerPos(players[rand],Zombie2Spawn[1][0],Zombie2Spawn[1][1],Zombie2Spawn[1][2]);
					}
					if(!Humans) CallRemoteFunction("GM_SetTimeLeft","ii",ZOMBIE,1);
			    }
			}
		}
	}
	return 1;
}

public zombie_SetTeam(playerid,teamid)
{
	switch(teamid)
	{
	    case TEAM_HUMAN:
	    {
	        SetPlayerColor(playerid,COLOR_GREEN);
			SetPlayerTeam(playerid,TEAM_HUMAN);
			SetPlayerSkin(playerid,ZOMBIE_SKIN);
		}
		default:
		{
		    SetPlayerColor(playerid,COLOR_RED);
			SetPlayerTeam(playerid,TEAM_ZOMBIE);
			SetPlayerSkin(playerid,HUMAN_SKIN);
		}
	}
	return 1;
}

public zombie_UpdateMissionInfo()
{
	new str[128];
	format(str,sizeof(str),"Humans: %i~n~Zombies: %i",Humans,Zombies);

	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    if(IsPlayerConnected(i) && CallRemoteFunction("GM_GetPlayerMode","i",i) == ZOMBIE)
	    {
			CallRemoteFunction("GM_OnReceiveMissionData","is",i,str);
		}
	}

	return 1;
}
