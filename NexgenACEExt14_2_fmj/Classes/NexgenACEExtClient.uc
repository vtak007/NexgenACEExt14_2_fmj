/*##################################################################################################
##
##  Nexgen ACE Extension version 2 for IACEv14 (UNOFFICIAL PORT)
##  Original Copyright (C) 2020 Patrick "Sp0ngeb0b" Peltzer
##
##  This is an unofficial recompile target only. No source changes were made from the official
##  "NexgenACEExt version 2 for IACE 12" release - only the package name was changed (see the
##  README.md in this folder) so it can be compiled against IACEv14.u instead of IACEv12.u.
##  If you want an official version for a custom Nexgen/ACE combo, contact the original author
##  first (spongebobut@yahoo.com / www.unrealriders.eu) - see NexgenACEExt's own README FAQ.
##
##  This program is free software; you can redistribute and/or modify
##  it under the terms of the Open Unreal Mod License version 1.1.
##
##  Original contact: spongebobut@yahoo.com | www.unrealriders.eu
##
##################################################################################################*/
class NexgenACEExtClient extends NexgenExtendedClientController;

// References
var NexgenACEExtAdminPanel ACEPanel;   // The ACE Admin Panel
var NexgenACEExtClientConfig ACEClientConfigPanel;
var IACECheck playerCheck;             // The ACE Check actor for this client
var IACEConfigFile ACEConfig;
var ChallengeHUD HUD;
var ChallengeHUD HUDWrapper;

// ACE data for this client
var string playerHWid;
var string playerMAC;

// ACE variables for a specifc client
var string PlayerName;                 // Name of the player that owns this checker
var string PlayerIP;                   // Ip of the player that owns this checker
var string UTCommandLine;              // Commandline of the application
var string UTVersion;                  // UT Client version
var string CPUIdentifier;              // CPU Identifier string
var string CPUMeasuredSpeed;           // CPU Measured speed
var string CPUReportedSpeed;           // CPU Reported speed - trough the commandline
var string OSString;                   // Full OS Version string
var string NICName;                    // Full name of the primary network interface
var string MACHash;                    // MD5 hash of the primary mac address
var string UTDCMacHash;                // UTDC compatible hash of the mac address
var string HWHash;                     // MD5 hash of the hardware ID
var string RenderDeviceClass;          // Class of the renderdevice (eg: OpenGLDrv.OpenGLRenderDevice)
var string RenderDeviceFile;           // DLL file of the renderdevice
var string SoundDeviceClass;           // Class of the sounddevice (eg: OpenAL.OpenALDevice)
var string SoundDeviceFile;            // DLL file of the sounddevice
var bool   bTunnel;                    // Is the user behind a UDP Proxy/Tunnel?
var string RealIP;                     // RealIP of the player (only set if bTunnel == true)
var bool   bWine;                      // Is the client running UT using the Wine Emulator?

const CMD_ACEINFO_PREFIX = "ACEINFO";  // Common ACE info command prefix.
const CMD_ACEINFO_NEW = "ACEN";        // ACE info initiation command.
const CMD_ACEINFO_VAR = "ACEV";        // ACE info variable command.
const CMD_ACEINFO_COMPLETE = "ACEC";   // Command that indicates that the  ACE initialization is complete.

const clientConfigPanelHeight = 160.0; // Panel height for the client config panel. Is reduced for 469 clients.

/***************************************************************************************************
 *
 *  $DESCRIPTION  Replication block.
 *
 **************************************************************************************************/
replication {

  reliable if (role != ROLE_SimulatedProxy) // Replicate to client...
    fixCHScaling, ACEInfoFailed, ACEInfoRequested, updateACESettings, showACEConfig;

  reliable if (role == ROLE_SimulatedProxy) // Replicate to server...
    requestACEInfo, requestACEShot;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the NexgenClient has received its initial replication info is has
 *                been initialized. At this point it's safe to use all functions of the client.
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function clientInitialized() {
  if(!client.bSpectator) client.addHUDExtension(spawn(class'NexgenACEExtHud', self));
  setTimer(1.0, true);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Modifies the setup of the Nexgen remote control panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function setupControlPanel() {

  // Spawn ACE Panel
  if (client.hasRight(client.R_Moderate)) {
		ACEPanel = NexgenACEExtAdminPanel(client.mainWindow.mainPanel.addPanel("ACE Admin", class'NexgenACEExtAdminPanel', , "game"));
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Timer function. Called every second.
 *
 **************************************************************************************************/
simulated function Timer() {

  // Server side
  if(Role == ROLE_Authority) {
    // Search for ACE Check Info
    if( (NexgenACEExt(xControl).bCheckSpectators || !client.bSpectator) && playerCheck == none) {
      foreach AllActors(class'IACECheck',playerCheck) {
        if(playerCheck != none && playerCheck.PlayerID == client.player.PlayerReplicationInfo.PlayerID) break;
        else playerCheck = none;
      }
    }

    // Check whether the ACE info is available
    if(playerCheck != none && client.loginComplete && (playerHWid == "" || playerMAC == "")) {
      playerHWid = playerCheck.HWHash;
      playerMAC  = playerCheck.MACHash;

      // It is, notify controller
      if(playerHWid != "" && playerMAC != "") {
        NexgenACEExt(xControl).ACEInfoReceived(self);
      }
    }

    // Fix crosshair scaling
    if(playerHWid != "" && playerMAC != "" && client.bInitialized) {
      fixCHScaling();
      setTimer(0.0, false);
    }
  } else {
    if(ACEConfig == none) {
      foreach client.player.getEntryLevel().AllActors(class'IACEConfigFile', ACEConfig) {
        // Change client config in case of v469
        //if(int(Level.EngineVersion) >= 469) {
        //  class'NexgenACEExtClientConfig'.default.panelHeight = clientConfigPanelHeight - 20.0;
        //} else {
          class'NexgenACEExtClientConfig'.default.panelHeight = clientConfigPanelHeight;
        //}

        // Spawn client config
        client.addPluginClientConfigPanel(class'NexgenACEExtClientConfig');
        ACEClientConfigPanel = NexgenACEExtClientConfig(client.mainWindow.mainPanel.getPanel(class'NexgenACEExtClientConfig'.default.panelIdentifier));
        setTimer(0.0, false);
        break;
      }
    } else if(ACEClientConfigPanel != none) {
      ACEClientConfigPanel.setValues();
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a general event has occurred in the system.
 *  $PARAM        type      The type of event that has occurred.
 *  $PARAM        argument  Optional arguments providing details about the event.
 *
 **************************************************************************************************/
simulated function fixCHScaling() {
  local ChallengeHud Huds;

  foreach AllActors(class'ChallengeHUD', Huds) {
    if(InStr(Huds.Class, "NexgenHUDWrapper") == -1) {
      HUD = Huds;
    } else HUDWrapper = Huds;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called on the server when the Client requests the ACE Info for a specific player.
 *  $PARAM        Num  The playerNum of the target player.
 *
 **************************************************************************************************/
function requestACEInfo(int Num) {
  local IACECheck A;
  local NexgenClient target;
  local string CommandLine;
  local string HWID;

  if(role != ROLE_Authority || !client.hasRight(client.R_Moderate)) return;

  target = control.getClientByNum(Num);
  if(target == none || (target.bSpectator && !NexgenACEExt(xControl).bCheckSpectators) ) {
    ACEInfoFailed();
    return;
  }

  foreach AllActors(class'IACECheck',A) {
    if(A.PlayerID == target.player.PlayerReplicationInfo.PlayerID) break;
    else A = none;
  }
  if(A == none) {
    ACEInfoFailed();
    return;
  } else ACEInfoRequested();

  if (A.UTCommandLine == "") CommandLine = "<none>";
  else CommandLine = A.UTCommandLine;

  if (A.bWine) HWID = "N/A";
  else HWID = A.HWHash;

  // Init command
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_NEW @ class'NexgenACEExt'.static.formatCmdArgFixed(self.class));

  // Variables
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("PlayerName") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.PlayerName));
	sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("PlayerIP") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.PlayerIP));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("UTCommandLine") @ class'NexgenACEExt'.static.formatCmdArgFixed(CommandLine));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("UTVersion") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.UTVersion));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("CPUIdentifier") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.CPUIdentifier));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("CPUMeasuredSpeed") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.CPUMeasuredSpeed));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("CPUReportedSpeed") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.CPUReportedSpeed));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("OSString") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.OSString));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("NICName") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.NICName));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("MACHash") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.MACHash));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("UTDCMacHash") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.UTDCMacHash));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("HWHash") @ class'NexgenACEExt'.static.formatCmdArgFixed(HWID));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("RenderDeviceClass") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.RenderDeviceClass));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("RenderDeviceFile") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.RenderDeviceFile));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("SoundDeviceClass") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.SoundDeviceClass));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("SoundDeviceFile") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.SoundDeviceFile));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("bTunnel") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.bTunnel));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("RealIP") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.RealIP));
  sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_VAR @ class'NexgenACEExt'.static.formatCmdArgFixed("bWine") @ class'NexgenACEExt'.static.formatCmdArgFixed(A.bWine));

	// Complete Command
	sendStr(CMD_ACEINFO_PREFIX @ CMD_ACEINFO_COMPLETE);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called on the server when the Client requests the ACE Info for a specific player.
 *  $PARAM        Num  The playerNum of the target player.
 *
 **************************************************************************************************/
function requestACEShot(int Num) {
  local IACECheck A;
  local NexgenClient target;

  if(role != ROLE_Authority || !client.hasRight(client.R_Moderate)) return;

  target = control.getClientByNum(Num);
  if(target == none) client.showMsg("<C00>Screenshot failed!");
  else if(target.bSpectator && !NexgenACEExt(xControl).bCheckSpectators) client.showMsg("<C00>Spectators are not checked by ACE!");
  else if(NexgenACEExt(xControl).ACEPassword == "") client.showMsg("<C00>You need to set an ACE AdminPass to take screenshots!");
  else client.clientCommand("mutate ACE SShot "$target.player.PlayerReplicationInfo.PlayerID$ " " $NexgenACEExt(xControl).ACEPassword);
}

simulated function ACEInfoFailed()    { if(ACEPanel != none) ACEPanel.ACEInfoFailed();    }
simulated function ACEInfoRequested() { if(ACEPanel != none) ACEPanel.ACEInfoRequested(); }

simulated function updateACESettings() {
  setTimer(0.5, false);
}

simulated function showACEConfig() {
  if(ACEClientConfigPanel != none) {
    client.showPanel(class'NexgenACEExtClientConfig'.default.panelIdentifier);
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a string was received from the other machine.
 *  $PARAM        str  The string that was send by the other machine.
 *
 **************************************************************************************************/
simulated function recvStr(string str) {
	local string cmd;
	local string args[10];
	local int argCount;

	super.recvStr(str);

	// Check controller role.
	if (role != ROLE_Authority) {
		// Commands accepted by client.
		if (class'NexgenUtil'.static.parseCmd(str, cmd, args, argCount, CMD_ACEINFO_PREFIX)) {
			switch (cmd) {
				case CMD_ACEINFO_NEW:       exec_ACEINFO_NEW(args, argCount); break;
				case CMD_ACEINFO_VAR:       exec_ACEINFO_VAR(args, argCount); break;
				case CMD_ACEINFO_COMPLETE:  exec_ACEINFO_COMPLETE(args, argCount); break;
			}
		}
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Executes a INIT_CONTAINER command.
 *  $PARAM        args      The arguments given for the command.
 *  $PARAM        argCount  Number of arguments available for the command.
 *
 **************************************************************************************************/
simulated function exec_ACEINFO_NEW(string args[10], int argCount) {
  if(!client.hasRight(client.R_Moderate)) return;

  // Clear results
  PlayerName = "";
  PlayerIP = "";
  UTCommandLine = "";
  UTVersion = "";
  CPUIdentifier = "";
  CPUMeasuredSpeed = "";
  CPUReportedSpeed = "";
  OSString = "";
  NICName = "";
  MACHash = "";
  UTDCMacHash = "";
  HWHash = "";
  RenderDeviceClass = "";
  RenderDeviceFile = "";
  SoundDeviceClass = "";
  SoundDeviceFile = "";
  bTunnel = false;
  RealIP = "";
  bWine = false;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Executes a INIT_VAR command.
 *  $PARAM        args      The arguments given for the command.
 *  $PARAM        argCount  Number of arguments available for the command.
 *
 **************************************************************************************************/
simulated function exec_ACEINFO_VAR(string args[10], int argCount) {
  if(!client.hasRight(client.R_Moderate)) return;
  switch(args[0]) {
    case "PlayerName":        PlayerName        = args[1]; break;
    case "PlayerIP":          PlayerIP          = args[1]; break;
    case "UTCommandLine":     UTCommandLine     = args[1]; break;
    case "UTVersion":         UTVersion         = args[1]; break;
    case "CPUIdentifier":     CPUIdentifier     = args[1]; break;
    case "CPUMeasuredSpeed":  CPUMeasuredSpeed  = args[1]; break;
    case "CPUReportedSpeed":  CPUReportedSpeed  = args[1]; break;
    case "OSString":          OSString          = args[1]; break;
    case "NICName":           NICName           = args[1]; break;
    case "MACHash":           MACHash           = args[1]; break;
    case "UTDCMacHash":       UTDCMacHash       = args[1]; break;
    case "HWHash":            HWHash            = args[1]; break;
    case "RenderDeviceClass": RenderDeviceClass = args[1]; break;
    case "RenderDeviceFile":  RenderDeviceFile  = args[1]; break;
    case "SoundDeviceClass":  SoundDeviceClass  = args[1]; break;
    case "SoundDeviceFile":   SoundDeviceFile   = args[1]; break;
    case "bTunnel":           bTunnel           = bool(args[1]); break;
    case "RealIP":            RealIP            = args[1]; break;
    case "bWine":             bWine             = bool(args[1]); break;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Executes a INIT_COMPLETE command.
 *  $PARAM        args      The arguments given for the command.
 *  $PARAM        argCount  Number of arguments available for the command.
 *
 **************************************************************************************************/
simulated function exec_ACEINFO_COMPLETE(string args[10], int argCount) {
  if(!client.hasRight(client.R_Moderate)) return;

  // Notify GUI
  ACEPanel.ACEInfoReceived();
}

/***************************************************************************************************
 *
 *  Below are fixed functions for the Empty String TCP bug. Check out this article to read more
 *  about it: http://www.unrealadmin.org/forums/showthread.php?t=31280
 *
 **************************************************************************************************/
/***************************************************************************************************
 *
 *  $DESCRIPTION  Fixed version of the setVar function in NexgenExtendedClientController.
 *                Empty strings are now formated correctly before beeing sent to the server.
 *
 **************************************************************************************************/
simulated function setVar(string dataContainerID, string varName, coerce string value, optional int index) {
	local NexgenSharedDataContainer dataContainer;
	local string oldValue;
	local string newValue;

	// Get data container.
	dataContainer = dataSyncMgr.getDataContainer(dataContainerID);

	// Check if variable can be updated.
	if (dataContainer == none || !dataContainer.mayWrite(self, varName)) return;

	// Update variable value.
	oldValue = dataContainer.getString(varName, index);
	dataContainer.set(varName, value, index);
	newValue = dataContainer.getString(varName, index);

	// Send new value to server.
	if (newValue != oldValue) {
		if (dataContainer.isArray(varName)) {
			sendStr(CMD_SYNC_PREFIX @ CMD_UPDATE_VAR
			        @ class'NexgenACEExt'.static.formatCmdArgFixed(dataContainerID)
			        @ class'NexgenACEExt'.static.formatCmdArgFixed(varName)
			        @ index
			        @ class'NexgenACEExt'.static.formatCmdArgFixed(newValue));
		} else {
			sendStr(CMD_SYNC_PREFIX @ CMD_UPDATE_VAR
			        @ class'NexgenACEExt'.static.formatCmdArgFixed(dataContainerID)
			        @ class'NexgenACEExt'.static.formatCmdArgFixed(varName)
			        @ class'NexgenACEExt'.static.formatCmdArgFixed(newValue));
		}
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Corrected version of the exec_UPDATE_VAR function in NexgenExtendedClientController.
 *                Due to the invalid format function, empty strings weren't sent correctly and were
 *                therefore not identifiable for the other machine (server). This caused the var index
 *                being erroneously recognized as the new var value on the server.
 *                Since the serverside set() function in NexgenSharedDataSyncManager also uses the
 *                invalid format functions, I implemented a fixed function in NexgenACEExt. The
 *                client side set() function can still be called safely without problems.
 *
 **************************************************************************************************/
simulated function exec_UPDATE_VAR(string args[10], int argCount) {
	local int varIndex;
	local string varName;
	local string varValue;
	local NexgenSharedDataContainer container;
	local int index;

	// Get arguments.
	if (argCount == 3) {
		varName = args[1];
		varValue = args[2];
	} else if (argCount == 4) {
		varName = args[1];
		varIndex = int(args[2]);
		varValue = args[3];
	} else {
		return;
	}

	if (role == ROLE_Authority) {
  	// Server side, call fixed set() function
  	NexgenACEExt(xControl).setFixed(args[0], varName, varValue, varIndex, self);
  } else {

    // Client Side
    dataSyncMgr.set(args[0], varName, varValue, varIndex, self);

    container = dataSyncMgr.getDataContainer(args[0]);

		// Signal event to client controllers.
		for (index = 0; index < client.clientCtrlCount; index++) {
			if (NexgenExtendedClientController(client.clientCtrl[index]) != none) {
				NexgenExtendedClientController(client.clientCtrl[index]).varChanged(container, varName, varIndex);
			}
		}

		// Signal event to GUI.
		client.mainWindow.mainPanel.varChanged(container, varName, varIndex);
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
     ctrlID="NexgenACEExtClient"
}
