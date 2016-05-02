#include <a_samp>
#include <SM_controls\defines>

new PlayerText:InfoBar[MAX_PLAYERS];
new PlayerText:BackgroundBar[MAX_PLAYERS];

forward textdraw_Update(playerid,text[]);

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Textdraw Filterscript - LOADED! ");
	print("--------------------------------------\n");
	return 1;
}

public OnFilterScriptExit()
{
	print("\n--------------------------------------");
	print(" Textdraw Filterscript - UNLOADED! ");
	print("--------------------------------------\n");
	return 1;
}

public OnPlayerConnect(playerid)
{
 	InfoBar[playerid] = CreatePlayerTextDraw(playerid, 485.500000, 380.0, "welcome!");
    PlayerTextDrawLetterSize(playerid, InfoBar[playerid], 0.25, 1.55);
    PlayerTextDrawAlignment(playerid, InfoBar[playerid], 1);
    PlayerTextDrawColor(playerid, InfoBar[playerid], -16776961);
    PlayerTextDrawSetShadow(playerid, InfoBar[playerid], 0);
    PlayerTextDrawSetOutline(playerid, InfoBar[playerid], 0);
    PlayerTextDrawBackgroundColor(playerid, InfoBar[playerid], 51);
    PlayerTextDrawFont(playerid, InfoBar[playerid], 2);
    PlayerTextDrawSetProportional(playerid, InfoBar[playerid], 1);
    PlayerTextDrawShow(playerid,InfoBar[playerid]);

	BackgroundBar[playerid] = CreatePlayerTextDraw(playerid,629.000000, 380.0, "usebox~n~test");
	PlayerTextDrawLetterSize(playerid,BackgroundBar[playerid], 0.000000, 2.216666);
	PlayerTextDrawTextSize(playerid,BackgroundBar[playerid], 478.000000, 0.000000);
	PlayerTextDrawAlignment(playerid,BackgroundBar[playerid], 1);
	PlayerTextDrawColor(playerid,BackgroundBar[playerid], -1);
	PlayerTextDrawUseBox(playerid,BackgroundBar[playerid], true);
	PlayerTextDrawBoxColor(playerid,BackgroundBar[playerid], 255);
	PlayerTextDrawSetShadow(playerid,BackgroundBar[playerid], 0);
	PlayerTextDrawSetOutline(playerid,BackgroundBar[playerid], 0);
	PlayerTextDrawBackgroundColor(playerid,BackgroundBar[playerid], -1);
	PlayerTextDrawFont(playerid,BackgroundBar[playerid], 0);
	PlayerTextDrawShow(playerid,BackgroundBar[playerid]);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    PlayerTextDrawDestroy(playerid, InfoBar[playerid]);
    PlayerTextDrawDestroy(playerid, BackgroundBar[playerid]);
	return 1;
}

public textdraw_Update(playerid,text[])
{
    PlayerTextDrawSetString(playerid,InfoBar[playerid], text);
    PlayerTextDrawShow(playerid, InfoBar[playerid]);
	return 1;
}
