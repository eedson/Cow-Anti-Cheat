/*  [CS:GO] CowAntiCheat Plugin - Burn the cheaters!
 *
 *  Copyright (C) 2018 Eric Edson // ericedson.me // thefraggingcow@gmail.com
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */
 
#pragma semicolon 1

#define PLUGIN_AUTHOR "CodingCow"
#define PLUGIN_VERSION "1.17"
#define REQUIRE_PLUGIN 0
#define JUMP_HISTORY 30
#define SERVER 0

#include <sourcemod>
#include <sdktools>
#include <SteamWorks>
#undef REQUIRE_PLUGIN
#include <sourcebans>
#include <sourcebanspp>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "CowAntiCheat",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

enum BanMethod
{
	SourceModBan,
	SourceBans,
	SourceBansPP
}

BanMethod ban_method = SourceModBan;
EngineVersion game_engine = Engine_Unknown;

bool g_bAngleSet[MAXPLAYERS + 1];
bool g_bAutoBhopEnabled[MAXPLAYERS + 1];
bool g_bShootSpam[MAXPLAYERS + 1];
bool g_bFirstShot[MAXPLAYERS + 1];
bool turnRight[MAXPLAYERS + 1];
bool prev_OnGround[MAXPLAYERS + 1];

int g_iCmdNum[MAXPLAYERS + 1];
int g_iAimbotCount[MAXPLAYERS + 1];
int g_iLastHitGroup[MAXPLAYERS + 1];
int g_iPerfectBhopCount[MAXPLAYERS + 1];
int g_iTicksOnGround[MAXPLAYERS + 1];
int g_iLastJumps[MAXPLAYERS + 1][JUMP_HISTORY];
int g_iLastJumpIndex[MAXPLAYERS + 1];
int g_iJumpsSent[MAXPLAYERS + 1][JUMP_HISTORY];
int g_iJumpsSentIndex[MAXPLAYERS + 1];
int g_iPrev_TicksOnGround[MAXPLAYERS + 1];
int g_iAutoShoot[MAXPLAYERS + 1];
int g_iTriggerBotCount[MAXPLAYERS + 1];
int g_iTicksOnPlayer[MAXPLAYERS + 1];
int g_iPrev_TicksOnPlayer[MAXPLAYERS + 1];
int g_iMacroCount[MAXPLAYERS + 1];
int g_iMacroDetectionCount[MAXPLAYERS + 1];
int g_iWallTrace[MAXPLAYERS + 1];
int g_iStrafeCount[MAXPLAYERS + 1];
int g_iTickCount[MAXPLAYERS + 1];
int prev_mousedx[MAXPLAYERS + 1];
int g_iAHKStrafeDetection[MAXPLAYERS + 1];
int g_iMousedx_Value[MAXPLAYERS + 1];
int g_iMousedxCount[MAXPLAYERS + 1];
int g_iPerfSidemove[MAXPLAYERS + 1];
int prev_buttons[MAXPLAYERS + 1];
int g_iLastShotTick[MAXPLAYERS + 1];

float prev_angles[MAXPLAYERS + 1][3];
float prev_sidemove[MAXPLAYERS + 1];
float g_fJumpStart[MAXPLAYERS + 1];
float g_fDefuseTime[MAXPLAYERS+1];
float g_fJumpPos[MAXPLAYERS + 1];
float g_Sensitivity[MAXPLAYERS + 1];
float g_mYaw[MAXPLAYERS + 1];

/* Game Cvars */
ConVar sv_autobunnyhopping = null;

/* Detection Cvars */
ConVar sm_cac_aimbot = null;
ConVar sm_cac_bhop = null;
ConVar sm_cac_silentstrafe = null;
ConVar sm_cac_triggerbot = null;
ConVar sm_cac_macro = null;
ConVar sm_cac_autoshoot = null;
ConVar sm_cac_instantdefuse = null;
ConVar sm_cac_perfectstrafe = null;
ConVar sm_cac_ahkstrafe = null;
ConVar sm_cac_hourcheck = null;
ConVar sm_cac_hourcheck_value = null;
ConVar sm_cac_profilecheck = null;

/* Detection Thresholds Cvars */
ConVar sm_cac_aimbot_ban_threshold = null;
ConVar sm_cac_bhop_ban_threshold = null;
ConVar sm_cac_silentstrafe_ban_threshold = null;
ConVar sm_cac_triggerbot_ban_threshold = null;
ConVar sm_cac_triggerbot_log_threshold = null;
ConVar sm_cac_macro_log_threshold = null = null;
ConVar sm_cac_autoshoot_log_threshold = null;
ConVar sm_cac_perfectstrafe_ban_threshold = null;
ConVar sm_cac_perfectstrafe_log_threshold = null;
ConVar sm_cac_ahkstrafe_log_threshold = null;

/* Ban Times */
ConVar sm_cac_aimbot_bantime = null;
ConVar sm_cac_bhop_bantime = null;
ConVar sm_cac_silentstrafe_bantime = null;
ConVar sm_cac_triggerbot_bantime = null;
ConVar sm_cac_perfectstrafe_bantime = null;
ConVar sm_cac_instantdefuse_bantime = null;

public void OnPluginStart()
{
	game_engine = GetEngineVersion();

	for (int i = 1; i <= MaxClients; i++)
		SetToDefaults(i);
	
	CreateTimer(0.1, getSettings, _, TIMER_REPEAT);
	
	SetConVars();

	SetHooks();
}

public void SetHooks()
{
	HookEvent("bomb_begindefuse", Event_BombBeginDefuse);
	HookEvent("bomb_defused", Event_BombDefused);
}

public void SetConVars()
{
	if(game_engine == Engine_CSGO)
		sv_autobunnyhopping = FindConVar("sv_autobunnyhopping");
	
	sm_cac_aimbot = CreateConVar("sm_cac_aimbot", "1", "Enable aimbot detection (bans) (1 = Yes, 0 = No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_cac_bhop = CreateConVar("sm_cac_bhop", "1", "Enable bhop detection (bans) (1 = Yes, 0 = No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_cac_silentstrafe = CreateConVar("sm_cac_silentstrafe", "1", "Enable silent-strafe detection (bans) (1 = Yes, 0 = No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_cac_triggerbot = CreateConVar("sm_cac_triggerbot", "1", "Enable triggerbot detection (bans/logs) (1 = Yes, 0 = No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_cac_macro = CreateConVar("sm_cac_macro", "1", "Enable macro detection (logs to admins) (1 = Yes, 0 = No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_cac_autoshoot = CreateConVar("sm_cac_autoshoot", "1", "Enable auto-shoot detection (logs to admins) (1 = Yes, 0 = No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_cac_instantdefuse = CreateConVar("sm_cac_instantdefuse", "1", "Enable instant defuse detection (logs to admins) (1 = Yes, 0 = No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_cac_perfectstrafe = CreateConVar("sm_cac_perfectstrafe", "1", "Enable perfect strafe detection (bans/logs) (1 = Yes, 0 = No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_cac_ahkstrafe = CreateConVar("sm_cac_ahkstrafe", "1", "Enable AHK strafe detection (1 = Yes, 0 = No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_cac_hourcheck = CreateConVar("sm_cac_hourcheck", "0", "Enable hour checker (1 = Yes, 0 = No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_cac_hourcheck_value = CreateConVar("sm_cac_hourcheck_value", "50", "Minimum amount of playtime a user has to have on CS:GO (Default: 50)");
	sm_cac_profilecheck = CreateConVar("sm_cac_profilecheck", "0", "Enable profile checker, this makes it so users need to have a public profile to connect. (1 = Yes, 0 = No)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	sm_cac_aimbot_ban_threshold = CreateConVar("sm_cac_aimbot_ban_threshold", "5", "Threshold for aimbot ban detection (Default: 5)");
	sm_cac_bhop_ban_threshold = CreateConVar("sm_cac_bhop_ban_threshold", "10", "Threshold for bhop ban detection (Default: 10)");
	sm_cac_silentstrafe_ban_threshold = CreateConVar("sm_cac_silentstrafe_ban_threshold", "10", "Threshold for silent-strafe ban detection (Default: 10)");
	sm_cac_triggerbot_ban_threshold = CreateConVar("sm_cac_triggerbot_ban_threshold", "5", "Threshold for triggerbot ban detection (Default: 5)");
	sm_cac_triggerbot_log_threshold = CreateConVar("sm_cac_triggerbot_log_threshold", "3", "Threshold for triggerbot log detection (Default: 3)");
	sm_cac_macro_log_threshold = CreateConVar("sm_cac_macro_log_threshold", "20", "Threshold for macro log detection (Default: 20)");
	sm_cac_autoshoot_log_threshold = CreateConVar("sm_cac_autoshoot_log_threshold", "20", "Threshold for auto-shoot log detection (Default: 20)");
	sm_cac_perfectstrafe_ban_threshold = CreateConVar("sm_cac_perfectstrafe_ban_threshold", "15", "Threshold for perfect strafe ban detection (Default: 15)");
	sm_cac_perfectstrafe_log_threshold = CreateConVar("sm_cac_perfectstrafe_log_threshold", "10", "Threshold for perfect strafe log detection (Default: 10)");
	sm_cac_ahkstrafe_log_threshold = CreateConVar("sm_cac_ahkstrafe_log_threshold", "25", "Threshold for AHK strafe log detection (Default: 25)");
	
	sm_cac_aimbot_bantime = CreateConVar("sm_cac_aimbot_bantime", "0", "Ban time for aimbot detection (Default: 0)");
	sm_cac_bhop_bantime = CreateConVar("sm_cac_bhop_bantime", "10080", "Ban time for bhop detection (Default: 10080)");
	sm_cac_silentstrafe_bantime = CreateConVar("sm_cac_silentstrafe_bantime", "0", "Ban time for silent-strafe detection (Default: 0)");
	sm_cac_triggerbot_bantime = CreateConVar("sm_cac_triggerbot_bantime", "0", "Ban time for triggerbot detection (Default: 0)");
	sm_cac_perfectstrafe_bantime = CreateConVar("sm_cac_perfectstrafe_bantime", "0", "Ban time for perfect strafe detection (Default: 0)");
	sm_cac_instantdefuse_bantime = CreateConVar("sm_cac_instantdefuse_bantime", "0", "Ban time for instant defuse detection (Default: 0)");

	AutoExecConfig(true, "cowanticheat");
}

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int err_max)
{
	MarkNativeAsOptional("SourceBans_BanPlayer");
	MarkNativeAsOptional("SBPP_BanPlayer");
}

public void OnAllPluginsLoaded()
{
	if(LibraryExists("sbpp_main"))
	{
		ban_method = SourceBansPP;

		return;
	}

	if(LibraryExists("sourcebans"))
	{
		ban_method = SourceBans;

		return;
	}	
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "sbpp_main") || StrEqual(name, "sourcebans"))
		ban_method = SourceModBan;
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "sbpp_main"))
	{
		ban_method = SourceBansPP;

		return;
	}

	if(StrEqual(name, "sourcebans"))
		ban_method = SourceBans;
}

public void OnClientPutInServer(int client)
{
	SetToDefaults(client);
	
	if(IsValidClient(client))
	{
		if(sm_cac_profilecheck.BoolValue)
		{
			Handle request = CreateRequest_ProfileStatus(client);
			SteamWorks_SendHTTPRequest(request);
		}
		if(cac_hourcheck.BoolValue)
		{
			Handle request = CreateRequest_TimePlayed(client);
			SteamWorks_SendHTTPRequest(request);
		}
	}
}

/* Command Callbacks */
public Action printVersion(int client, int args)
{
	PrintToChat(client, "[\x02CowAC\x01] Version: %s", PLUGIN_VERSION);
}

public Action getBhop(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_bhopcheck <#userid|name>");
		return Plugin_Handled;
	}
	
	char arg[128];
	GetCmdArg(1, arg, sizeof(arg));
	
	int target = FindTarget(client, arg, true, false);
	
	if(!IsValidClient(target))
	{
		PrintToChat(client, "[\x02CowAC\x01] Not a valid target!");
		return Plugin_Handled;
	}
	
	PrintToChat(client, "[\x02CowAC\x01] See console for output.");
	
	PrintToConsole(client, "--------------------------------------------");
	PrintToConsole(client, "	%N's Detection Logs", target);
	PrintToConsole(client, "--------------------------------------------");
	PrintToConsole(client, "Perfect Jumps: %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i",
	g_iLastJumps[target][0],
	g_iLastJumps[target][1],
	g_iLastJumps[target][2],
	g_iLastJumps[target][3],
	g_iLastJumps[target][4],
	g_iLastJumps[target][5],
	g_iLastJumps[target][6],
	g_iLastJumps[target][7],
	g_iLastJumps[target][8],
	g_iLastJumps[target][9],
	g_iLastJumps[target][10],
	g_iLastJumps[target][11],
	g_iLastJumps[target][12],
	g_iLastJumps[target][13],
	g_iLastJumps[target][14],
	g_iLastJumps[target][15],
	g_iLastJumps[target][16],
	g_iLastJumps[target][17],
	g_iLastJumps[target][18],
	g_iLastJumps[target][19],
	g_iLastJumps[target][20],
	g_iLastJumps[target][21],
	g_iLastJumps[target][22],
	g_iLastJumps[target][23],
	g_iLastJumps[target][24],
	g_iLastJumps[target][25],
	g_iLastJumps[target][26],
	g_iLastJumps[target][27],
	g_iLastJumps[target][28],
	g_iLastJumps[target][29]);
	
	int perf = 0;
	
	for (int i = 0; i < JUMP_HISTORY; i++)
	{
		if(g_iLastJumps[target][i] == 1)
		{
			perf++;
		}
	}
	
	float avgPerf = perf / 30.0;
	
	PrintToConsole(client, "Avg Perfect Jumps: %.2f%", avgPerf * 100);
	
	PrintToConsole(client, "Jump Commands: %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i %i",
	g_iJumpsSent[target][0],
	g_iJumpsSent[target][1],
	g_iJumpsSent[target][2],
	g_iJumpsSent[target][3],
	g_iJumpsSent[target][4],
	g_iJumpsSent[target][5],
	g_iJumpsSent[target][6],
	g_iJumpsSent[target][7],
	g_iJumpsSent[target][8],
	g_iJumpsSent[target][9],
	g_iJumpsSent[target][10],
	g_iJumpsSent[target][11],
	g_iJumpsSent[target][12],
	g_iJumpsSent[target][13],
	g_iJumpsSent[target][14],
	g_iJumpsSent[target][15],
	g_iJumpsSent[target][16],
	g_iJumpsSent[target][17],
	g_iJumpsSent[target][18],
	g_iJumpsSent[target][19],
	g_iJumpsSent[target][20],
	g_iJumpsSent[target][21],
	g_iJumpsSent[target][22],
	g_iJumpsSent[target][23],
	g_iJumpsSent[target][24],
	g_iJumpsSent[target][25],
	g_iJumpsSent[target][26],
	g_iJumpsSent[target][27],
	g_iJumpsSent[target][28],
	g_iJumpsSent[target][29]);
	
	int jumps = 0;
	for (int i = 0; i < JUMP_HISTORY; i++)
	{
		jumps += g_iJumpsSent[target][i];
	}
	
	float avgJumps = jumps / 30.0;
	
	PrintToConsole(client, "Avg Jump Commands: %.2f", avgJumps);
	
	return Plugin_Handled;
}

/* Get Player Settings */
public Action getSettings(Handle timer)
{
	if(game_engine == Engine_CSGO)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				QueryClientConVar(i, "sensitivity", ConVar_QueryClient, i);
				QueryClientConVar(i, "m_yaw", ConVar_QueryClient, i);
				QueryClientConVar(i, "sv_autobunnyhopping", ConVar_QueryClient, i);
			}
		}
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				QueryClientConVar(i, "sensitivity", ConVar_QueryClient, i);
				QueryClientConVar(i, "m_yaw", ConVar_QueryClient, i);
			}
		}
	}
}

public void ConVar_QueryClient(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
	if(IsValidClient(client))
	{
		if(result == ConVarQuery_Okay)
		{
			if(StrEqual("sensitivity", cvarName))
			{
				g_Sensitivity[client] = StringToFloat(cvarValue);
			}
			else if(StrEqual("m_yaw", cvarName))
			{
				g_mYaw[client] = StringToFloat(cvarValue);
			}
			else if(game_engine == Engine_CSGO && StrEqual("sv_autobunnyhopping", cvarName))
			{
				if(StringToInt(cvarValue) > 0)
					g_bAutoBhopEnabled[client] = true;
				else
					g_bAutoBhopEnabled[client] = false;
			}
		}
	}      
}

public Action Event_BombBeginDefuse(Handle event, const char[] name, bool dontBroadcast )
{
	int client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if(cac_instantdefuse.BoolValue)
    {
        g_fDefuseTime[client] = GetEngineTime();
    }
}

public Action Event_BombDefused(Handle event, const char[] name, bool dontBroadcast )
{
	int client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if(GetEngineTime() - g_fDefuseTime[client] < 3.5 && cac_instantdefuse.BoolValue)
    {
		PrintToChatAll("[\x02CowAC\x01] \x0E%N \x01has been detected for Instant Defuse!", client);
		
		char date[32], log[128], steamid[64];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		FormatTime(date, sizeof(date), "%m/%d/%Y %I:%M:%S", GetTime());
		Format(log, sizeof(log), "[CowAC] %s | BAN | %N (%s) has been detected for Instant Defuse", date, client, steamid);
		CowAC_Log(log);

		BanPlayer(client, sm_cac_instantdefuse_bantime.IntValue, "[CowAC] Instant Defuse Detected.");
    }
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!IsFakeClient(client) && IsValidClient(client) && IsPlayerAlive(client))
	{
		float vOrigin[3], AnglesVec[3], EndPoint[3];
	
		float Distance = 999999.0;
		
		GetClientEyePosition(client,vOrigin);
		GetAngleVectors(fAngles, AnglesVec, NULL_VECTOR, NULL_VECTOR);
		
		EndPoint[0] = vOrigin[0] + (AnglesVec[0]*Distance);
		EndPoint[1] = vOrigin[1] + (AnglesVec[1]*Distance);
		EndPoint[2] = vOrigin[2] + (AnglesVec[2]*Distance);
		
		Handle trace = TR_TraceRayFilterEx(vOrigin, EndPoint, MASK_SHOT, RayType_EndPoint, TraceEntityFilterPlayer, client);
		
		if(sm_cac_aimbot.BoolValue)
			CheckAimbot(client, iButtons, fAngles, trace);
		
		if(game_engine == Engine_CSGO && cac_bhop.BoolValue && !sv_autobunnyhopping.BoolValue && !g_bAutoBhopEnabled[client])
			CheckBhop(client, iButtons);
		
		if(cac_silentstrafe.BoolValue)
			CheckSilentStrafe(client, fVelocity[1]);
		
		if(cac_triggerbot.BoolValue)
			CheckTriggerBot(client, iButtons, trace);
		
		if(cac_macro.BoolValue)
			CheckMacro(client, iButtons);
		
		if(cac_autoshoot.BoolValue)
			CheckAutoShoot(client, iButtons);
			
		if(cac_perfectstrafe.BoolValue)
			CheckPerfectStrafe(client, mouse[0], iButtons);
			
		if(cac_ahkstrafe.BoolValue)
			CheckAHKStrafe(client, mouse[0]);
		
		//CheckWallTrace(client, fAngles);
		
		delete trace;
		
		prev_OnGround[client] = (GetEntityFlags(client) & FL_ONGROUND) == FL_ONGROUND;
		
		prev_angles[client] = fAngles;
		prev_buttons[client] = iButtons;
	}
	else
	{
		for (int f = 0; f < sizeof(prev_angles[]); f++)
			prev_angles[client][f] = 0.0;
			
		g_bAngleSet[client] = false;
	}
	
	g_iCmdNum[client]++;
	
	return Plugin_Continue;
}

public void CheckAimbot(int client, int buttons, float angles[3], Handle trace)
{
	// Prevent incredibly high sensitivity from causing detections
	if(FloatAbs(g_Sensitivity[client] * g_mYaw[client]) > 0.6)
	{
		return;
	}
	
	if(!g_bAngleSet[client])
	{
		g_bAngleSet[client] = true;
	}
	
	float delta = NormalizeAngle(angles[1] - prev_angles[client][1]);

	if (TR_DidHit(trace))
	{
		int target = TR_GetEntityIndex(trace);
		
		if ((target > 0) && (target <= MaxClients) && GetClientTeam(target) != GetClientTeam(client) && IsPlayerAlive(target) && IsPlayerAlive(client))
		{
			if(delta > 15.0 || delta < -15.0)
			{
				int hitgroup = TR_GetHitGroup(trace);
				
				if(buttons & IN_ATTACK && hitgroup == g_iLastHitGroup[client])
				{
					g_iAimbotCount[client]++;
				}
				else
				{
					g_iAimbotCount[client] = 0;
				}
				
				g_iLastHitGroup[client] = hitgroup;
			}
		}
	}
  	
  	if(g_iAimbotCount[client] >= sm_cac_aimbot_ban_threshold.IntValue)
  	{
  		PrintToChatAll("[\x02CowAC\x01] \x0E%N \x01has been detected for Aimbot!", client);
  		
  		char date[32], log[128], steamid[64];
  		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		FormatTime(date, sizeof(date), "%m/%d/%Y %I:%M:%S", GetTime());
		Format(log, sizeof(log), "[CowAC] %s | BAN | %N (%s) has been detected for Aimbot (%i)", date, client, steamid, g_iAimbotCount[client]);
		CowAC_Log(log);
  		
  		BanPlayer(client, sm_cac_aimbot_bantime.IntValue, "[CowAC] Aimbot Detected.");  		
  		g_iAimbotCount[client] = 0;
 	}
}

public void CheckBhop(int client, int buttons)
{
	if(GetEntityFlags(client) & FL_ONGROUND)
	{
		g_iTicksOnGround[client]++;
	}
	else
	{
		g_iTicksOnGround[client] = 0;
	}
	
	if(g_iTicksOnGround[client] <= 20 && GetEntityFlags(client) & FL_ONGROUND && buttons & IN_JUMP && !(prev_buttons[client] & IN_JUMP))
	{
		g_iLastJumps[client][g_iLastJumpIndex[client]] = g_iTicksOnGround[client];
		
		g_iLastJumpIndex[client]++;
	}
	
	if(g_iLastJumpIndex[client] == 30)
			g_iLastJumpIndex[client] = 0;
	
	if((g_iTicksOnGround[client] == 1 || g_iTicksOnGround[client] == g_iPrev_TicksOnGround[client]) && GetEntityFlags(client) & FL_ONGROUND && buttons & IN_JUMP && !(prev_buttons[client] & IN_JUMP))
	{
		g_iPerfectBhopCount[client]++;
		
		g_iPrev_TicksOnGround[client] = g_iTicksOnGround[client];
	}
	else if(g_iTicksOnGround[client] >= g_iPrev_TicksOnGround[client] && GetEntityFlags(client) & FL_ONGROUND)
	{
		g_iPerfectBhopCount[client] = 0;
	}
	
	if(g_iPerfectBhopCount[client] >= sm_cac_bhop_ban_threshold.IntValue)
	{
		PrintToChatAll("[\x02CowAC\x01] \x0E%N \x01has been detected for Bhop Assist!", client);
		
		char date[32], log[128], steamid[64];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		FormatTime(date, sizeof(date), "%m/%d/%Y %I:%M:%S", GetTime());
		Format(log, sizeof(log), "[CowAC] %s | BAN | %N (%s) has been detected for Bhop Assist (%i)", date, client, steamid, g_iPerfectBhopCount[client]);
		CowAC_Log(log);
		
		BanPlayer(client, sm_cac_bhop_bantime.IntValue, "[CowAC] Bhop Assist Detected.");		
		g_iPerfectBhopCount[client] = 0;
	}
}

public void CheckSilentStrafe(int client, float sidemove)
{
	if(sidemove > 0 && prev_sidemove[client] < 0)
	{
		g_iPerfSidemove[client]++;
		
		if(g_iCmdNum[client] % 50 == 1)
			CheckSidemoveCount(client);
	}
	else if(sidemove < 0 && prev_sidemove[client] > 0)
	{
		g_iPerfSidemove[client]++;
		
		if(g_iCmdNum[client] % 50 == 1)
			CheckSidemoveCount(client);
	}
	else
	{	
		g_iPerfSidemove[client] = 0;
	}
	
	prev_sidemove[client] = sidemove;
}

public void CheckSidemoveCount(int client)
{
	if(g_iPerfSidemove[client] >= sm_cac_silentstrafe_ban_threshold.IntValue)
	{
		PrintToChatAll("[\x02CowAC\x01] \x0E%N \x01has been detected for Silent-Strafe!", client);
		
		char date[32], log[128], steamid[64];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		FormatTime(date, sizeof(date), "%m/%d/%Y %I:%M:%S", GetTime());
		Format(log, sizeof(log), "[CowAC] %s | BAN | %N (%s) has been detected for Silent-Strafe (%i)", date, client, steamid, g_iPerfSidemove[client]);
		CowAC_Log(log);

		BanPlayer(client, sm_cac_silentstrafe_bantime.IntValue, "[CowAC] Silent-Strafe Detected.");
	}
			
	g_iPerfSidemove[client] = 0;
}

public void CheckTriggerBot(int client, int buttons, Handle trace)
{
	if (TR_DidHit(trace))
	{
		int target = TR_GetEntityIndex(trace);
		
		if (target > 0 && target <= MaxClients && GetClientTeam(target) != GetClientTeam(client) && IsPlayerAlive(target) && IsPlayerAlive(client) && !g_bShootSpam[client])
		{
			g_iTicksOnPlayer[client]++;
			
			if(buttons & IN_ATTACK && !(prev_buttons[client] & IN_ATTACK) && g_iTicksOnPlayer[client] == g_iPrev_TicksOnPlayer[client])
			{
				g_iTriggerBotCount[client]++;
			}
			else if(buttons & IN_ATTACK && prev_buttons[client] & IN_ATTACK && g_iTicksOnPlayer[client] == 1)
			{
				if(g_iTriggerBotCount[client] >= sm_cac_triggerbot_log_threshold.IntValue)
				{
					char message[128];
					Format(message, sizeof(message), "[\x02CowAC\x01] \x0E%N \x01detected for \x10%i\x01 tick perfect shots.", client, g_iTriggerBotCount[client]);
					PrintToAdmins(message);
					
					char date[32], log[128], steamid[64];
					GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
					FormatTime(date, sizeof(date), "%m/%d/%Y %I:%M:%S", GetTime());
					Format(log, sizeof(log), "[CowAC] %s | LOG | %N (%s) has been detected for %i 1 tick perfect shots", date, client, steamid, g_iTriggerBotCount[client]);
					CowAC_Log(log);
				}
				
				g_iTriggerBotCount[client] = 0;
			}
			else if(!(buttons & IN_ATTACK) && !(prev_buttons[client] & IN_ATTACK) && g_iTicksOnPlayer[client] >= g_iPrev_TicksOnPlayer[client])
			{
				if(g_iTriggerBotCount[client] >= sm_cac_triggerbot_log_threshold.IntValue)
				{
					char message[128];
					Format(message, sizeof(message), "[\x02CowAC\x01] \x0E%N \x01detected for \x10%i\x01 tick perfect shots.", client, g_iTriggerBotCount[client]);
					PrintToAdmins(message);
					
					char date[32], log[128], steamid[64];
					GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
					FormatTime(date, sizeof(date), "%m/%d/%Y %I:%M:%S", GetTime());
					Format(log, sizeof(log), "[CowAC] %s | LOG | %N (%s) has been detected for %i 1 tick perfect shots", date, client, steamid, g_iTriggerBotCount[client]);
					CowAC_Log(log);
				}
				
				g_iTriggerBotCount[client] = 0;
			}
		}
		else
		{
			if(g_iTicksOnPlayer[client] > 0)
				g_iPrev_TicksOnPlayer[client] = g_iTicksOnPlayer[client];
			
			g_iTicksOnPlayer[client] = 0;
		}
	}
	else
	{
		if(g_iTicksOnPlayer[client] > 0)
			g_iPrev_TicksOnPlayer[client] = g_iTicksOnPlayer[client];

		g_iTicksOnPlayer[client] = 0;
	}
  	
  	if(g_iTriggerBotCount[client] >= sm_cac_triggerbot_ban_threshold.IntValue)
  	{
  		PrintToChatAll("[\x02CowAC\x01] \x0E%N \x01has been detected for TriggerBot / Smooth Aimbot!", client);
  		
  		char date[32], log[128], steamid[64];
  		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		FormatTime(date, sizeof(date), "%m/%d/%Y %I:%M:%S", GetTime());
		Format(log, sizeof(log), "[CowAC] %s | BAN | %N (%s) has been detected for TriggerBot / Smooth Aimbot (%i)", date, client, steamid, g_iTriggerBotCount[client]);
		CowAC_Log(log);

		BanPlayer(client, sm_cac_triggerbot_bantime.IntValue, "[CowAC] TriggerBot / Smooth Aimbot Detected.");      	
  		g_iTriggerBotCount[client] = 0;
 	}
}

public void CheckMacro(int client, int buttons)
{
	float vec[3];
	GetClientAbsOrigin(client, vec);
	
	if(buttons & IN_JUMP && !(prev_buttons[client] & IN_JUMP) && !(GetEntityFlags(client) & FL_ONGROUND) && !(GetEntityFlags(client) & FL_INWATER) && vec[2] > g_fJumpStart[client])
	{
		g_iMacroCount[client]++;
	}
	else if(GetEntityFlags(client) & FL_ONGROUND)
	{
		if(g_iMacroCount[client] >= sm_cac_macro_log_threshold.IntValue)
		{
			char message[128];
			Format(message, sizeof(message), "[\x02CowAC\x01] \x0E%N \x01has been detected for Macro / Hyperscroll (\x04%i\x01)!", client, g_iMacroCount[client]);
			PrintToAdmins(message);
			
			char date[32], log[128], steamid[64];
			GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
			FormatTime(date, sizeof(date), "%m/%d/%Y %I:%M:%S", GetTime());
			Format(log, sizeof(log), "[CowAC] %s | LOG | %N (%s) has been detected for Macro / Hyperscroll (%i)", date, client, steamid, g_iMacroCount[client]);
			CowAC_Log(log);
			
			g_iMacroDetectionCount[client]++;
			
			if(g_iMacroDetectionCount[client] >= 10)
			{
				KickClient(client, "[CowAC] Turn off Bhop Assistance!");
				g_iMacroDetectionCount[client] = 0;
			}
		}
		
		if(g_iMacroCount[client] > 0)
		{	
			g_iJumpsSent[client][g_iJumpsSentIndex[client]] = g_iMacroCount[client];
			g_iJumpsSentIndex[client]++;
			
			if(g_iJumpsSentIndex[client] == 30)
				g_iJumpsSentIndex[client] = 0;
		}
			
		g_iMacroCount[client] = 0;
		
		g_fJumpStart[client] = vec[2];
	}
}

public void CheckAutoShoot(int client, int buttons)
{	
	if(buttons & IN_ATTACK && !(prev_buttons[client] & IN_ATTACK))
	{
		if(g_bFirstShot[client])
		{	
			g_bFirstShot[client] = false;
			
			g_iLastShotTick[client] = g_iCmdNum[client];
		}
		else if(g_iCmdNum[client] - g_iLastShotTick[client] <= 10 && !g_bFirstShot[client])
		{
			g_bShootSpam[client] = true;
			g_iAutoShoot[client]++;
			g_iLastShotTick[client] = g_iCmdNum[client];
		}
		else
		{
			if(g_iAutoShoot[client] >= sm_cac_autoshoot_log_threshold.IntValue)
			{
				char message[128];
				Format(message, sizeof(message), "[\x02CowAC\x01] \x0E%N \x01has been detected for AutoShoot Script (\x04%i\x01)!", client, g_iAutoShoot[client]);
				PrintToAdmins(message);
				
				char date[32], log[128], steamid[64];
				GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
				FormatTime(date, sizeof(date), "%m/%d/%Y %I:%M:%S", GetTime());
				Format(log, sizeof(log), "[CowAC] %s | LOG | %N (%s) has been detected for AutoShoot Script (%i)", date, client, steamid, g_iAutoShoot[client]);
				CowAC_Log(log);
			}
			
			g_iAutoShoot[client] = 0;
			g_bShootSpam[client] = false;
			g_bFirstShot[client] = true;
		}
	}
}

public void CheckWallTrace(int client, float angles[3])
{
	float vOrigin[3], AnglesVec[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, AnglesVec);
	    
	Handle trace = TR_TraceRayFilterEx(vOrigin, AnglesVec, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, client);
	
	if (TR_DidHit(trace))
	{
		int target = TR_GetEntityIndex(trace);
		
		if ((target > 0) && (target <= MaxClients) && GetClientTeam(target) != GetClientTeam(client) && IsPlayerAlive(target) && IsPlayerAlive(client))
		{
			g_iWallTrace[client]++;
		}
		else
		{
			g_iWallTrace[client] = 0;
		}
	}
	else
	{
		g_iWallTrace[client] = 0;
	}
	delete trace;
	
	float tickrate = 1.0 / GetTickInterval();
	
	if(g_iWallTrace[client] >= RoundToZero(tickrate))
	{
		PrintToChatAll("[\x02CowAC\x01] \x0E%N \x01detected for WallTracing.", client);
		g_iWallTrace[client] = 0;
	}
}

public void CheckPerfectStrafe(int client, int mousedx, int buttons)
{
	if(mousedx > 0 && turnRight[client])
	{
		if(!(prev_buttons[client] & IN_MOVERIGHT) && buttons & IN_MOVERIGHT && !(buttons & IN_MOVELEFT))
		{
			g_iStrafeCount[client]++;
			
			CheckPerfCount(client);
		}
		else
		{
			if(g_iStrafeCount[client] >= sm_cac_perfectstrafe_log_threshold.IntValue)
			{
				char message[128];
				Format(message, sizeof(message), "[\x02CowAC\x01] \x0E%N \x01detected for \x10%i\x01 Consistant Perfect Strafes.", client, g_iStrafeCount[client]);
				PrintToAdmins(message);
				
				char date[32], log[128], steamid[64];
				GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
				FormatTime(date, sizeof(date), "%m/%d/%Y %I:%M:%S", GetTime());
				Format(log, sizeof(log), "[CowAC] %s | LOG | %N (%s) has been detected for Consistant Perfect Strafes (%i)", date, client, steamid, g_iStrafeCount[client]);
				CowAC_Log(log);
			}
			
			g_iStrafeCount[client] = 0;
		}
		
		turnRight[client] = false;
	}
	else if(mousedx < 0 && !turnRight[client])
	{
		if(!(prev_buttons[client] & IN_MOVELEFT) && buttons & IN_MOVELEFT && !(buttons & IN_MOVERIGHT))
		{
			g_iStrafeCount[client]++;
			
			CheckPerfCount(client);
		}
		else
		{
			if(g_iStrafeCount[client] >= sm_cac_perfectstrafe_log_threshold.IntValue)
			{
				char message[128];
				Format(message, sizeof(message), "[\x02CowAC\x01] \x0E%N \x01detected for \x10%i\x01 Consistant Perfect Strafes.", client, g_iStrafeCount[client]);
				PrintToAdmins(message);
				
				char date[32], log[128], steamid[64];
				GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
				FormatTime(date, sizeof(date), "%m/%d/%Y %I:%M:%S", GetTime());
				Format(log, sizeof(log), "[CowAC] %s | LOG | %N (%s) has been detected for Consistant Perfect Strafes (%i)", date, client, steamid, g_iStrafeCount[client]);
				CowAC_Log(log);
			}
			
			g_iStrafeCount[client] = 0;
		}
		
		turnRight[client] = true;
	}
}

public void CheckPerfCount(int client)
{
	if(g_iStrafeCount[client] >= sm_cac_perfectstrafe_ban_threshold.IntValue)
	{
		PrintToChatAll("[\x02CowAC\x01] \x0E%N \x01has been detected for Consistant Perfect Strafes (%i)!", client, g_iStrafeCount[client]);
		
		char date[32], log[128], steamid[64];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		FormatTime(date, sizeof(date), "%m/%d/%Y %I:%M:%S", GetTime());
		Format(log, sizeof(log), "[CowAC] %s | BAN | %N (%s) has been detected for Consistant Perfect Strafes (%i)", date, client, steamid, g_iStrafeCount[client]);
		CowAC_Log(log);
		
		BanPlayer(client, sm_cac_perfectstrafe_bantime.IntValue, "[CowAC] Consistant Perfect Strafes Detected.");
		g_iStrafeCount[client] = 0;
	}
}

public void CheckAHKStrafe(int client, int mouse)
{
	float vec[3];
	GetClientAbsOrigin(client, vec);
	
	if(prev_OnGround[client] && !(GetEntityFlags(client) & FL_ONGROUND))
	{
		g_fJumpPos[client] = vec[2];
	}
	
	if(!(GetEntityFlags(client) & FL_ONGROUND))
	{
		if((mouse >= 10 || mouse <= -10) && g_fJumpPos[client] < vec[2])
		{
			if(mouse == g_iMousedx_Value[client] || mouse == g_iMousedx_Value[client] * -1)
			{
				g_iMousedxCount[client]++;
			}
			else
			{
				g_iMousedx_Value[client] = mouse;
				g_iMousedxCount[client] = 0;
			}
				
			if(g_iMousedxCount[client] >= sm_cac_ahkstrafe_log_threshold.IntValue)
			{
				g_iMousedxCount[client] = 0;
				g_iAHKStrafeDetection[client]++;
				
				if(g_iAHKStrafeDetection[client] >= 10)
				{
					char message[128];
					Format(message, sizeof(message), "[\x02CowAC\x01] \x0E%N \x01detected for AHK Strafe (%i Infractions)", client, g_iAHKStrafeDetection[client]);
					PrintToAdmins(message);
					
					char date[32], log[128], steamid[64];
					GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
					FormatTime(date, sizeof(date), "%m/%d/%Y %I:%M:%S", GetTime());
					Format(log, sizeof(log), "[CowAC] %s | LOG | %N (%s) has been detected for AHK Strafe (%i Infractions)", date, client, steamid, g_iAHKStrafeDetection[client]);
					CowAC_Log(log);
					g_iAHKStrafeDetection[client] = 0;
				}
			}
		}
	}
}

Handle CreateRequest_TimePlayed(int client)
{
	char request_url[256];
	Format(request_url, sizeof(request_url), "http://www.cowanticheat.com/CheckTime.php");
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, request_url);
	
	char steamid[64];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "steamid", steamid);
	SteamWorks_SetHTTPRequestContextValue(request, client);
	SteamWorks_SetHTTPCallbacks(request, TimePlayed_OnHTTPResponse);
	return request;
}

public int TimePlayed_OnHTTPResponse(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client)
{
	if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		delete request;
		return;
	}

	int iBufferSize;
	SteamWorks_GetHTTPResponseBodySize(request, iBufferSize);
	
	char[] sBody = new char[iBufferSize];
	SteamWorks_GetHTTPResponseBodyData(request, sBody, iBufferSize);
	
	int time = StringToInt(sBody, 10) / 60 / 60;
	
	if(time <= 0)
	{
		KickClient(client, "[CowAC] Please connect with a public steam profile.");
	}
	else if(time < sm_cac_hourcheck_value.IntValue)
	{
		KickClient(client, "[CowAC] You do not meet the minimum hour requirement to play here! (%i/%i)", time, sm_cac_hourcheck_value.IntValue);
	}
	
	delete request;
}

Handle CreateRequest_ProfileStatus(int client)
{
	char request_url[256];
	Format(request_url, sizeof(request_url), "http://www.cowanticheat.com/CheckProfile.php");
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, request_url);
	
	char steamid[64];
	GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
	
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "steamid", steamid);
	SteamWorks_SetHTTPRequestContextValue(request, client);
	SteamWorks_SetHTTPCallbacks(request, ProfileStatus_OnHTTPResponse);
	return request;
}

public int ProfileStatus_OnHTTPResponse(Handle request, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, int client)
{
	if (!bRequestSuccessful || eStatusCode != k_EHTTPStatusCode200OK)
	{
		delete request;
		return;
	}

	int iBufferSize;
	SteamWorks_GetHTTPResponseBodySize(request, iBufferSize);
	
	char[] sBody = new char[iBufferSize];
	SteamWorks_GetHTTPResponseBodyData(request, sBody, iBufferSize);
	
	int profile = StringToInt(sBody, 10) / 60 / 60;
	
	if(profile < 3)
	{
		KickClient(client, "[CowAC] Please connect with a public steam profile.");
	}
	
	delete request;
}

public bool TraceEntityFilterPlayer(int entity, int mask, any data)
{
    return data != entity;
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	return entity == 0 ? false : entity != data && 0 < entity <= MaxClients;

	/*if(entity == 0)
		return false;
	else
    	return entity != data && 0 < entity <= MaxClients;*/
}  

public void SetToDefaults(int client)
{
	g_iCmdNum[client] = 0;
	g_iAimbotCount[client] = 0;
	g_iLastHitGroup[client] = 0;
	for (int f = 0; f < sizeof(prev_angles[]); f++)
		prev_angles[client][f] = 0.0;
	g_bAngleSet[client] = false;
	g_iPerfectBhopCount[client] = 0;
	g_bAutoBhopEnabled[client] = false;
	g_iTicksOnGround[client] = 0;
	g_iPrev_TicksOnGround[client] = 0;
	prev_sidemove[client] = 0.0;
	g_iPerfSidemove[client] = 0;
	prev_buttons[client] = 0;
	g_bShootSpam[client] = false;
	g_iLastShotTick[client] = 0;
	g_bFirstShot[client] = true;
	g_iAutoShoot[client] = 0;
	g_iTriggerBotCount[client] = 0;
	g_iTicksOnPlayer[client] = 0;
	g_iPrev_TicksOnPlayer[client] = 1;
	g_iMacroCount[client] = 0;
	g_iMacroDetectionCount[client] = 0;
	g_fJumpStart[client] = 0.0;
	g_fDefuseTime[client] = 0.0;
	g_Sensitivity[client] = 0.0;
	g_mYaw[client] = 0.0;
	g_iWallTrace[client] = 0;
	g_iStrafeCount[client] = 0;
	turnRight[client] = true;
	g_iTickCount[client] = 0;
	prev_mousedx[client] = 0;
	g_iAHKStrafeDetection[client] = 0;
	g_iMousedx_Value[client] = 0;
	g_iMousedxCount[client] = 0;
	g_fJumpPos[client] = 0.0;
	prev_OnGround[client] = true;
	
	for (int i = 0; i < JUMP_HISTORY; i++)
	{
		g_iLastJumps[client][i] = 0;
		g_iJumpsSent[client][i] = 0;
	}
	g_iLastJumpIndex[client] = 0;
	g_iJumpsSentIndex[client] = 0;
}

/* Stocks */
public void PrintToAdmins(const char[] message)
{
    for (int i = 1; i <= MaxClients; i++) 
    {
        if (IsValidClient(i))
        {
            if (CheckCommandAccess(i, "cowac_print_override", ADMFLAG_GENERIC))
            {
                PrintToChat(i, message); 
            }
            else
            {
                PrintToCow(i, message);
            }
        }
    }
}

public void PrintToCow(int client, const char[] message) 
{
	char steamid[64];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	
	if(StrEqual(steamid, "STEAM_1:1:240063362"))
	{
		PrintToChat(client, message);
	}
}

public void CowAC_Log(char[] message)
{
	Handle logFile = OpenFile("addons/sourcemod/logs/CowAC_Log.txt", "a");
	WriteFileLine(logFile, message);
	delete logFile;
}

bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}

public float NormalizeAngle(float angle)
{
	float newAngle = angle;

	while (newAngle <= -180.0)
		newAngle += 360.0;
	
	while (newAngle > 180.0) 
		newAngle -= 360.0;
	
	return newAngle;
}

public float GetClientVelocity(int client, bool UseX, bool UseY, bool UseZ)
{
    float vVel[3];
   
    if(UseX)
    {
        vVel[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
    }
   
    if(UseY)
    {
        vVel[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
    }
   
    if(UseZ)
    {
        vVel[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");
    }
   
    return GetVectorLength(vVel);
}

void BanPlayer(int client, int time, const char[] reason)
{
	switch(ban_method)
	{
		case default, SourceModBan:
		{
			BanClient(client, time, BANFLAG_AUTO, reason);
		}

		case SourceBans:
		{
			SourceBans_BanPlayer(SERVER, client, time, reason);
		}

		case SourceBansPP: 
		{
			SBPP_BanPlayer(SERVER, client, time, reason);
		}
	}
}
