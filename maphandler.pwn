#include <a_samp>
#include <streamer>
#include <sscanf2>
#include <SM_controls\defines>
#include <SM_controls\modes>

#define OBJ_MAX 1000

forward maphandler_Start(modeid,mapid);
forward maphandler_End(modeid);

enum objdata { mode, Objects[OBJ_MAX] };
new objData[3][objdata]; //3 Maps loaded at the same time

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Map Handler - LOADED");
	print("--------------------------------------\n");

	for(new i=0;i<sizeof(objData);i++) {
	    objData[i][mode] = -1;
	}

	return 1;
}

public OnFilterScriptExit()
{
	print("\n--------------------------------------");
	print(" Map Handler - UNLOADED");
	print("--------------------------------------\n");
	return 1;
}

public OnPlayerConnect(playerid)
{
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	return 1;
}

public maphandler_Start(modeid,mapid)
{
	new pos = 0,i = 0;
	while(i<3) {
	    if(objData[i][mode] == -1 ) {
			i = 3;
			pos = i;
		    objData[i][mode] = modeid;
		}
	}
	
	
	//CreateDynamicObject(modelid, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz, worldid = -1, interiorid = -1, playerid = -1, Float:streamdistance = STREAMER_OBJECT_SD, Float:drawdistance = STREAMER_OBJECT_DD, STREAMER_TAG_AREA areaid = STREAMER_TAG_AREA -1);
	new str[128],mapname[24];
	format(mapname,sizeof(mapname),"%s%i.txt",FullModeName[modeid],mapid);
	
	new File:handle = fopen(mapname, io_read);
	
	if(handle) {
	    new Float:obj[6],oID,counter;
	    while(fread(handle, str)) {
	        if(!sscanf(str,"p<,>iffffff",oID,obj[0],obj[1],obj[2],obj[3],obj[4],obj[5])) {
	            objData[pos][Objects][counter] = CreateDynamicObject(oID,obj[0],obj[1],obj[2],obj[3],obj[4],obj[5]);
	            counter++;
	        }
	    }
	    fclose(handle);
	}
	else printf("Failed to load %s.",mapname);
	return 1;
}

public maphandler_End(modeid)
{
	new pos = 0,i = 0;
	while(i<3) {
	    if(objData[i][mode] == modeid ) {
			i = 3;
			pos = i;
		    objData[i][mode] = -1;
		}
	}
	
	for(new j=0;j<OBJ_MAX;j++) {
	    if(IsValidDynamicObject(objData[pos][Objects][j])) DestroyDynamicObject(objData[pos][Objects][j]);
	}
	
	return 1;
}
