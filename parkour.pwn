#include <a_samp>
#include <float>
#include <SM_controls\parkour>
#include <SM_controls\defines>

#define PARKOUR 2

new Position[MAX_PLAYERS];
new bool:Finished[MAX_PLAYERS];
new Checkpoint[MAX_PLAYERS];
new currentMap,totalFinishes = 0,Timer;

forward Float:GetPlayerDistanceToPoint(playerid, Float:X, Float:Y, Float:Z);
forward parkour_Init(playerid);
forward parkour_Exit(playerid);
forward parkour_UpdatePos();
forward parkour_SetPosition(playerid,position);
forward parkour_SetCheckpoint(playerid,cp);
forward parkour_ResetCP(playerid);
forward parkour_SubmitCurrentMap(mapid);
forward parkour_Finish(playerid);
forward parkour_HasFinished(playerid);
forward parkour_UpdateMissionInfo();

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Parkour Filterscript - LOADED");
	print("--------------------------------------\n");

	//initialize data
	for(new i=0;i<MAX_PLAYERS;i++)
	{
	    Position[i] = MAX_PLAYERS;
	    Finished[i] = false;
	    Checkpoint[i] = false;
	}

	totalFinishes = 0;
	Timer = SetTimer("parkour_UpdatePos",1000,true);

	return 1;
}

public OnFilterScriptExit()
{
	print("\n--------------------------------------");
	print(" Parkour Filterscript - UNLOADED");
	print("--------------------------------------\n");
	
	KillTimer(Timer);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	Position[playerid] = MAX_PLAYERS;
	Checkpoint[playerid] = 0;
	Finished[playerid] = false;
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == PARKOUR)
	{
	    parkour_ResetCP(playerid);
	}
	return 1;
}

public OnPlayerSpawn(playerid)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == PARKOUR)
	{
		parkour_Init(playerid);
	}
	return 1;
}

public OnPlayerEnterRaceCheckpoint(playerid)
{
	if(CallRemoteFunction("GM_GetPlayerMode","i",playerid) == PARKOUR ) {
		Checkpoint[playerid] ++;
		new i = Checkpoint[playerid];
		PlayerPlaySound(playerid, 1058, 0.0, 0.0, 10.0);
		switch(currentMap)
		{
			case 1:
			{
				switch(i)
			    {
					case 20: { DisablePlayerRaceCheckpoint(playerid); SetPlayerRaceCheckpoint(playerid, 1, Parkour1[i][0],Parkour1[i][1],Parkour1[i][2], 0,0,0, 10); }
					case 21: { parkour_Finish(playerid); }
					default: { DisablePlayerRaceCheckpoint(playerid); SetPlayerRaceCheckpoint(playerid, 0, Parkour1[i][0],Parkour1[i][1],Parkour1[i][2], Parkour1[i+1][0],Parkour1[i+1][1],Parkour1[i+1][2], 10);}
			    }
		    }
		    case 2:
		    {
				switch(i)
			    {
					case 20: { DisablePlayerRaceCheckpoint(playerid); SetPlayerRaceCheckpoint(playerid, 0, Parkour2[i][0],Parkour2[i][1],Parkour2[i][2], 0,0,0, 10); }
					case 21: { parkour_Finish(playerid); }
					default: { DisablePlayerRaceCheckpoint(playerid); SetPlayerRaceCheckpoint(playerid, 0, Parkour2[i][0],Parkour2[i][1],Parkour2[i][2], Parkour2[i+1][0],Parkour2[i+1][1],Parkour2[i+1][2], 10);}
			    }
		    }
		}
    }
	return 1;
}

public OnPlayerUpdate(playerid)
{
	if(CallRemoteFunction("GetPlayerMode","i",playerid) == PARKOUR) {
		new animlib[32], animname[32];
	    if(GetPlayerAnimationIndex(playerid)) {
	        GetAnimationName(GetPlayerAnimationIndex(playerid), animlib, sizeof(animlib), animname, sizeof(animname));
	        if(strcmp(animlib, "PED", true) != -1) {
         		if(strcmp(animname, "SWIM_TREAD", true) == 0) {
             	   SetPlayerPos(playerid,ParkourSpawn[currentMap-1][0],ParkourSpawn[currentMap-1][1],ParkourSpawn[currentMap-1][2]);
             	   SetPlayerFacingAngle(playerid,ParkourSpawn[currentMap-1][3]);
				   parkour_ResetCP(playerid);
				}
	        }
	    }
	}
	return 1;
}

public parkour_Init(playerid)
{
	parkour_ResetCP(playerid);
	
	SetPlayerPos(playerid,ParkourSpawn[currentMap-1][0],ParkourSpawn[currentMap-1][1],ParkourSpawn[currentMap-1][2]);
    SetPlayerFacingAngle(playerid,ParkourSpawn[currentMap-1][3]);
    SetPlayerInterior(playerid,ParkourInterior[currentMap-1]);
	SetPlayerHealth(playerid,1000000000.00);
	SetPlayerColor(playerid,COLOR_WHITE);
	
	return 1;
}

public parkour_Exit(playerid)
{
	CallRemoteFunction("GM_RespawnPlayerToLobby","i",playerid);
	Checkpoint[playerid] = 0;
	DisablePlayerRaceCheckpoint(playerid);
	return 1;
}

public parkour_UpdatePos()
{
    new firstpos = totalFinishes+1; //first position that can be taken
    new Float:closest_distance,closest_pid,pid[MAX_PLAYERS],count;
    new Float:x,Float:y,Float:z;
    new len = (currentMap == 1)? sizeof(Parkour1):sizeof(Parkour2);

    for(new i=len;i>=0;i--)
    {
        count = 0;
        
        //Get the players who are between the 2 certain CPs
		for(new j=0; j<MAX_PLAYERS;j++)
		{
			pid[j] = 0; //empty the array before re-filling it
	        if(IsPlayerConnected(j) && CallRemoteFunction("GM_GetPlayerMode","i",j) == PARKOUR && Checkpoint[j] == i)
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
			    case 1:	x = Parkour1[i][0],y = Parkour1[i][1], z = Parkour1[i][2];
			    default: x = Parkour2[i][0],y = Parkour2[i][1], z = Parkour2[i][2];
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
    
	parkour_UpdateMissionInfo();
    
	return 1;
}


public parkour_ResetCP(playerid)
{
	Checkpoint[playerid] = 0;
 	DisablePlayerRaceCheckpoint(playerid);
 	switch(currentMap)
 	{
		case 1:SetPlayerRaceCheckpoint(playerid, 0, Parkour1[0][0],Parkour1[0][1],Parkour1[0][2], Parkour1[1][0],Parkour1[1][1],Parkour1[1][2], 10);
		case 2:SetPlayerRaceCheckpoint(playerid, 0, Parkour2[0][0],Parkour2[0][1],Parkour2[0][2], Parkour2[1][0],Parkour2[1][1],Parkour2[1][2], 10);
	}
	return 1;
}

public parkour_SubmitCurrentMap(mapid)
{
	currentMap = mapid;
	return 1;
}

public parkour_Finish(playerid)
{
	new string[128],name[MAX_PLAYER_NAME];
	GetPlayerName(playerid,name,sizeof(name));
	
	format(string, sizeof(string), "[MODE] %s (%d) has finished the Parkour as %s.",name,playerid,RankFormat(Position[playerid]));
	SendClientMessageToAll(COLOR_YELLOW,string);

	Finished[playerid] = true;
	totalFinishes++;
	Checkpoint[playerid] = 0;
	
	CallRemoteFunction("acc_AddScore","ii",playerid,5);
	CallRemoteFunction("GM_RespawnPlayerToLobby","i",playerid);
	return 1;
}

public parkour_HasFinished(playerid)
{
	return Finished[playerid];
}

public parkour_UpdateMissionInfo()
{
    new pos[20],str[128],lName[MAX_PLAYER_NAME];

	//Get the Leader-Name
	for(new n=0;n<MAX_PLAYERS;n++)
    {
        if(IsPlayerConnected(n) && CallRemoteFunction("GM_GetPlayerMode","i",n) == PARKOUR && Position[n] == 1)
        {
            GetPlayerName(n,lName,sizeof(lName));
        }
    }

	for(new m=0;m<MAX_PLAYERS;m++)
   	{
   	    if(IsPlayerConnected(m) && CallRemoteFunction("GM_GetPlayerMode","i",m) == PARKOUR)
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
