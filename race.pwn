#include <a_samp>
#include <float>
#include <SM_controls\race>
#include <SM_controls\defines>

#define RACE 1

new Position[MAX_PLAYERS];
new bool:Finished[MAX_PLAYERS];
new Checkpoint[MAX_PLAYERS];
new currentMap,totalFinishes,Timer;

native DisableRemoteVehicleCollisions(playerid, disable);

forward race_SetPosition(playerid,position);
forward race_SetCheckpoint(playerid,cp);
forward race_ResetCP(playerid);
forward race_SubmitCurrentMap(mapid);
forward race_Finish(playerid);
forward race_HasFinished(playerid);
forward race_Init(playerid);
forward race_Exit(playerid);
forward race_UpdatePos();
forward race_UpdateMissionInfo();
forward Float:GetPlayerDistanceToPoint(playerid, Float:X, Float:Y, Float:Z);

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Race Filterscript - LOADED");
	print("--------------------------------------\n");

	//initialize data
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    Position[i] = MAX_PLAYERS;
	    Finished[i] = false;
	    Checkpoint[i] = false;
	}

	totalFinishes = 0;

	Timer = SetTimer("race_UpdatePos",1000,true);
	return 1;
}

public OnFilterScriptExit()
{
	print("\n--------------------------------------");
	print(" Race Filterscript - UNLOADED");
	print("--------------------------------------\n");
	
	KillTimer(Timer);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	Position[playerid] = MAX_PLAYERS;
	Checkpoint[playerid] = 0;
	Finished[playerid] = false;
	DisableRemoteVehicleCollisions(playerid,0);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == RACE)
	{
	    race_ResetCP(playerid);
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == RACE)
	{
		race_Init(playerid);
	}
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == RACE ) {
		Checkpoint[playerid] ++;
		PlayerPlaySound(playerid, 1058, 0.0, 0.0, 10.0);
		switch(currentMap)
		{
			case 1:
			{
				switch(Checkpoint[playerid])
			    {
					case 15: { DisablePlayerRaceCheckpoint(playerid); SetPlayerRaceCheckpoint(playerid, 1, Race1[Checkpoint[playerid]][0],Race1[Checkpoint[playerid]][1],Race1[Checkpoint[playerid]][2], 0,0,0, 10); }
					case 16: { race_Finish(playerid); }
					default: { DisablePlayerRaceCheckpoint(playerid); SetPlayerRaceCheckpoint(playerid, 0, Race1[Checkpoint[playerid]][0],Race1[Checkpoint[playerid]][1],Race1[Checkpoint[playerid]][2], Race1[Checkpoint[playerid]+1][0],Race1[Checkpoint[playerid]+1][1],Race1[Checkpoint[playerid]+1][2], 10);}
			    }
		    }
		    case 2:
		    {
				switch(Checkpoint[playerid])
			    {
					case 16: { DisablePlayerRaceCheckpoint(playerid); SetPlayerRaceCheckpoint(playerid, 0, Race2[Checkpoint[playerid]][0],Race2[Checkpoint[playerid]][1],Race2[Checkpoint[playerid]][2], 0,0,0, 10); }
					case 17: { race_Finish(playerid); }
					default: { DisablePlayerRaceCheckpoint(playerid); SetPlayerRaceCheckpoint(playerid, 0, Race2[Checkpoint[playerid]][0],Race2[Checkpoint[playerid]][1],Race2[Checkpoint[playerid]][2], Race2[Checkpoint[playerid]+1][0],Race2[Checkpoint[playerid]+1][1],Race2[Checkpoint[playerid]+1][2], 10);}
			    }
		    }
		}
    }
	return 1;
}

public OnPlayerUpdate(playerid)
{
	return 1;
}

public race_Init(playerid)
{
	race_ResetCP(playerid);
	SetPlayerInterior(playerid,RaceInterior[currentMap-1]);

	new vehid;
	SetPlayerPos(playerid,2754.8945,-1854.5173,9.6903);
	vehid = CreateVehicle(RaceVeh[currentMap-1],RaceSpawn[currentMap-1][0],RaceSpawn[currentMap-1][1],RaceSpawn[currentMap-1][2],RaceSpawn[currentMap-1][3],-1,-1,-1);

	LinkVehicleToInterior(vehid,RaceInterior[currentMap-1]);
    PutPlayerInVehicle(playerid,vehid,0);
    DisableRemoteVehicleCollisions(playerid,1);

    CallRemoteFunction("GM_SetPlayerVehicle","ii",playerid,vehid);
	
	return 1;
}

public race_Exit(playerid)
{
	CallRemoteFunction("GM_RespawnPlayerToLobby","i",playerid);
	CallRemoteFunction("GM_DestroyPlayerVehicle","i",playerid);
	Checkpoint[playerid] = 0;
	DisablePlayerRaceCheckpoint(playerid);
	DisableRemoteVehicleCollisions(playerid,0);
	return 1;
}

public race_UpdatePos()
{
    new firstpos = totalFinishes+1; //first position that can be taken
    new Float:closest_distance,closest_pid,pid[MAX_PLAYERS],count;
    new Float:x,Float:y,Float:z;
    new len = (currentMap == 1)? sizeof(Race1):sizeof(Race2);

    for(new i=len;i>=0;i--)
    {
        count = 0;

        //Get the players who are between the 2 certain CPs
		for(new j=0; j<MAX_PLAYERS;j++)
		{
			pid[j] = 0; //empty the array before re-filling it
	        if(IsPlayerConnected(j) && CallRemoteFunction("GM_GetPlayerMode","i",j) == RACE && Checkpoint[j] == i)
			{
				 pid[count] = j; count++;
		 	}
        }

		//sort by position
        for(new h=0;h<count;h++)
        {
            closest_pid = h;
			switch(currentMap)
			{
			    case 1:	x = Race1[i][0],y = Race1[i][1], z = Race1[i][2];
			    default: x = Race2[i][0],y = Race2[i][1], z = Race2[i][2];
			}
			closest_distance = GetPlayerDistanceToPoint(pid[h],x,y,z);
            for(new k=h+1;k<count;k++)
            {
                new Float:dist = GetPlayerDistanceToPoint(pid[k],x,y,z);
                if(dist < closest_distance)
                {
                    closest_distance = dist;
                    new tmp = pid[closest_pid];
                    pid[closest_pid] = pid[k];
                    pid[k] = tmp;
                }
            }
        }
        for(new l=0;l<count;l++) { Position[pid[l]] = firstpos; firstpos++; }
    }
    
	race_UpdateMissionInfo();
	return 1;
}

public race_ResetCP(playerid)
{
	Checkpoint[playerid] = 0;
 	DisablePlayerRaceCheckpoint(playerid);
 	switch(currentMap)
 	{
		case 1:SetPlayerRaceCheckpoint(playerid, 0, Race1[0][0],Race1[0][1],Race1[0][2], Race1[1][0],Race1[1][1],Race1[1][2], 10);
		case 2:SetPlayerRaceCheckpoint(playerid, 0, Race2[0][0],Race2[0][1],Race2[0][2], Race2[1][0],Race2[1][1],Race2[1][2], 10);
	}
	return 1;
}

public race_SubmitCurrentMap(mapid)
{
	currentMap = mapid;
	return 1;
}

public race_Finish(playerid)
{
	new string[128],name[MAX_PLAYER_NAME];
	GetPlayerName(playerid,name,sizeof(name));
	
	format(string, sizeof(string), "[MODE] %s (%d) has finished the Race as %s.",name,playerid,RankFormat(Position[playerid]));
	SendClientMessageToAll(COLOR_YELLOW,string);

	Finished[playerid] = true;
	totalFinishes++;
	CallRemoteFunction("acc_AddScore","ii",playerid,5);
	race_Exit(playerid);
	
	return 1;
}

public race_HasFinished(playerid)
{
	return Finished[playerid];
}

public race_UpdateMissionInfo()
{
    new pos[20],str[128],lName[MAX_PLAYER_NAME];

	//Get the Leader-Name
	for(new n=0;n<MAX_PLAYERS;n++)
    {
        if(IsPlayerConnected(n) && CallRemoteFunction("GM_GetPlayerMode","i",n) == RACE && Position[n] == 1)
        {
            GetPlayerName(n,lName,sizeof(lName));
        }
    }

	for(new m=0;m<MAX_PLAYERS;m++)
   	{
   	    if(IsPlayerConnected(m) && CallRemoteFunction("GM_GetPlayerMode","i",m) == RACE)
   	    {
        	pos = RankFormat(Position[m]);
			format(str,sizeof(str),"Position: %s~n~Leader: %s",pos,lName);
			CallRemoteFunction("GM_OnReceiveMissionData","is",m,str);
		}
	}
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

public Float:GetPlayerDistanceToPoint(playerid, Float:X, Float:Y, Float:Z)
{
  	new Float:XP,Float:YP,Float:ZP;
  	GetPlayerPos(playerid,XP,YP,ZP);
  	return (XP - X) + (YP - Y) + (ZP - Z);
}
