#include <a_samp>
#include <SM_controls\defines>
#include <SM_controls\maze>

#define MAZE 5

forward maze_SubmitCurrentMap(mapid);
forward maze_Init(playerid);
forward maze_HasFinished(playerid);
forward maze_Exit(playerid);
forward maze_UpdateMissionInfo();

new MazePickup[7][3];
new TeleportPickup[8];
new Room[MAX_PLAYERS];
new bool:Finished[MAX_PLAYERS];
new FinishPickup;
new Finishers,Timer;

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Maze Filterscript - LOADED");
	print("--------------------------------------\n");
	
	for(new i=0;i<7;i++)
	{
	    TeleportPickup[i] = random(3);
	    
	    for(new j=0;j<3;j++)
	    {
	        MazePickup[i][j] = CreatePickup(1318,1,MazePickupPos[i][j][0],MazePickupPos[i][j][1],MazePickupPos[i][j][2],-1);
	    }
	}
	
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    Room[i] = 0;
	    Finished[i] = false;
	}
	
	Finishers = 0;
	FinishPickup = CreatePickup(1318,1,3581.54, 1434.54, 63.66,-1);
	
	Timer = SetTimer("maze_UpdateMissionInfo",1000,true);
	return 1;
}

public OnFilterScriptExit()
{
	print("\n--------------------------------------");
	print(" Maze Filterscript - UNLOADED");
	print("--------------------------------------\n");
	
	KillTimer(Timer);
	
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	maze_Exit(playerid);
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == MAZE)
	{
	    maze_Init(playerid);
	}
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == MAZE)
	{
		Room[playerid] = 0;
	}
	return 1;
}

public OnPlayerPickUpPickup(playerid, pickupid)
{
    if(pickupid == FinishPickup)
    {
        new str[128],name[MAX_PLAYER_NAME];
        Finishers++;
        
        GetPlayerName(playerid,name,sizeof(name));
		format(str,sizeof(str),"[MODE]%s (%d) has finished the Maze as %s.",name,playerid,RankFormat(Finishers));
		//ModeNotification(str,COLOR_ORANGE);

		Finished[playerid] = true;
		CallRemoteFunction("GM_RespawnPlayerToLobby","i",playerid);
    }
    else
    {
        for(new i=0;i<7;i++)
        {
            for(new j=0;j<3;j++)
            {
                if(pickupid == MazePickup[i][j])
                {
                    if(j == TeleportPickup[i])
                    {
                        Room[playerid]++;
                        SendClientMessage(playerid,COLOR_GREEN,"You picked up the right pickup! You passed this chamber!");
					}
					else
					{
                        if(Room[playerid] == 0) SendClientMessage(playerid,COLOR_GREEN,"Wrong pickup!");
						else { Room[playerid]--; SendClientMessage(playerid,COLOR_GREEN,"You picked up the wrong pickup! You got teleported one Room back!"); }
					}
					SetPlayerPos(playerid,MazeSpawn[Room[playerid]][0],MazeSpawn[Room[playerid]][1],MazeSpawn[Room[playerid]][2]);
					SetPlayerFacingAngle(playerid,MazeSpawn[Room[playerid]][3]);
                }
            }
        }

    }
	return 1;
}

public maze_Init(playerid)
{
    SetPlayerInterior(playerid,MazeInterior);
    SetPlayerPos(playerid,MazeSpawn[0][0],MazeSpawn[0][1],MazeSpawn[0][2]);
    SetPlayerFacingAngle(playerid,MazeSpawn[0][3]);
	return 1;
}

public maze_Exit(playerid)
{
	Room[playerid] = 0;
	Finished[playerid] = false;
	
	if(IsPlayerConnected(playerid)) CallRemoteFunction("GM_RespawnPlayerToLobby","i",playerid);
	return 1;
}

public maze_HasFinished(playerid)
{
	return Finished[playerid];
}

public maze_UpdateMissionInfo()
{
	new str[32];
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    if(IsPlayerConnected(i) && CallRemoteFunction("GM_GetPlayerMode","i",i) == MAZE)
	    {
			format(str,sizeof(str),"Room: %i/8",Room[i]);
			CallRemoteFunction("GM_OnReceiveMissionData","is",i,str);
		}
	}
	return 1;
}

public maze_SubmitCurrentMap(mapid)
{
	//currentMap = mapid;
	return 1;
}
RankFormat(rank)
{
	new str[20];
	new ending[10];
	new lastdigit;

	if(rank != 11 && rank != 12 && rank != 13)
	{
		lastdigit = rank - (rank/10) * 10;
		switch(lastdigit)
		{
		    case 1: ending = "st";
		    case 2: ending = "nd";
		    case 3: ending = "rd";
		    default: ending = "th";
		}
	}
	else { ending = "th";}
	format(str,sizeof(str),"%i%s",rank,ending);
	return str;
}
