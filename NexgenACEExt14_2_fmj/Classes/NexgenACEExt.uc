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
/*##################################################################################################
##  Changelog:
##
##  Version 2:
##  [Changed]  ace_login signal now waits for client's login procedure to complete (fixes bugs in
##             NexgenABM and NexgenPlayerLookup in case of ACE HW information being available
##             before the client is logged in)
##
##################################################################################################*/
class NexgenACEExt extends NexgenExtendedPlugin;

var IACEActor ACEActor;

// ACE config used by us, create local copy
var bool bCheckSpectators;
var string ACEPassword;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Initializes the plugin. Note that if this function returns false the plugin will
 *                be destroyed and is not to be used anywhere.
 *  $RETURN       True if the initialization succeeded, false if it failed.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool initialize() {

  // Let super class initialize.
	if (!super.initialize()) {
		return false;
	}

  // Search for ACE
  foreach AllActors(class'IACEActor',ACEActor) {
    if(ACEActor != none) {
      bCheckSpectators = ACEActor.bCheckSpectators;
      ACEPassword = ACEActor.AdminPass;
      break;
    }
  }
  if(ACEActor == none) return false;

	return true;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when the game is executing it's first tick.
 *
 **************************************************************************************************/
function firstTick() {
  local string args;

  // Signal ACE config.
  class'NexgenUtil'.static.addProperty(args, "ACEVersion",             ACEActor.ACEVersion);
  class'NexgenUtil'.static.addProperty(args, "AdminPass",              ACEActor.AdminPass);
  class'NexgenUtil'.static.addProperty(args, "bAllowCrosshairScaling", ACEActor.bAllowCrosshairScaling);
	class'NexgenUtil'.static.addProperty(args, "bShowLogo",              ACEActor.bShowLogo);
  class'NexgenUtil'.static.addProperty(args, "LogoXPos",               ACEActor.LogoXPos);
	class'NexgenUtil'.static.addProperty(args, "LogoYPos",               ACEActor.LogoYPos);
  class'NexgenUtil'.static.addProperty(args, "bCheckSpectators",       ACEActor.bCheckSpectators);
	control.signalEvent("ace_config", args, true);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a new client has been created. Use this function to setup the new
 *                client with your own extensions (in order to support the plugin).
 *  $PARAM        client  The client that was just created.
 *  $REQUIRE      client != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function clientCreated(NexgenClient client) {
	local NexgenExtendedClientController xClient;

	xClient = NexgenExtendedClientController(client.addController(clientControllerClass, self));
	xClient.dataSyncMgr = dataSyncMgr;
	xClient.xControl = self;
	if( bCheckSpectators || !client.bSpectator) xClient.setTimer(1.0, true);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Called when a client's HWid and MAC Hash is received.
 *  $PARAM        xClient The client whose ACE data is available.
 *  $REQUIRE      xClient != none
 *
 **************************************************************************************************/
function ACEInfoReceived(NexgenACEExtClient xClient) {
  local string args;

	if(xClient == none) return;

  // Signal event.
	class'NexgenUtil'.static.addProperty(args, "client", xClient.client.playerNum);
	class'NexgenUtil'.static.addProperty(args, "HWid",   xClient.playerHWid);
	class'NexgenUtil'.static.addProperty(args, "MAC",    xClient.playerMAC);
	control.signalEvent("ace_login", args, true);
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Hooked into the mutator chain to detect Nexgen actions issued by the clients. If
 *                a Nexgen command is detected it will be parsed and send to the execCommand()
 *                function.
 *  $PARAM        mutateString  Mutator specific string (indicates the action to perform).
 *  $PARAM        sender        Player that has send the message.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function mutate(string mutateString, PlayerPawn sender) {
	local NexgenClient client;
  local NexgenACEExtClient xClient;

  client = control.getClient(sender);
  if(client != None) xClient = NexgenACEExtClient(client.getController(class'NexgenACEExtClient'.default.ctrlID));
  if(xClient == None) return;

  if(Left(Caps(mutateString), 3) == "ACE") {
    xClient.updateACESettings();
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Handles a potential command message.
 *  $PARAM        sender  PlayerPawn that has send the message in question.
 *  $PARAM        msg     Message send by the player, which could be a command.
 *  $REQUIRE      sender != none
 *  $RETURN       True if the specified message is a command, false if not.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function bool handleMsgCommand(PlayerPawn sender, string msg) {
	local string cmd;
	local bool bIsCommand;
  local NexgenClient client;
	local NexgenACEExtClient xClient;

  client = control.getClient(sender);
  if(client != none) xClient = NexgenACEExtClient(client.getController(class'NexgenACEExtClient'.default.ctrlID));

	cmd = class'NexgenUtil'.static.trim(msg);
	bIsCommand = true;
	switch (cmd) {
		case "!ace":
			if (xClient != none && xClient.client.bInitialized) {
				xClient.showACEConfig();
        return true;
			} else client.showMsg("<C00>Command requires initialisation!");
		break;

		// Not a command.
		default: bIsCommand = false;
	}

	return bIsCommand;
}

/***************************************************************************************************
 *
 *  Below are fixed functions for the Empty String TCP bug. Check out this article to read more
 *  about it: http://www.unrealadmin.org/forums/showthread.php?t=31280
 *
 **************************************************************************************************/
/***************************************************************************************************
 *
 *  $DESCRIPTION  Fixed serverside set() function of NexgenSharedDataSyncManager. Uses correct
 *                formatting.
 *
 **************************************************************************************************/
function setFixed(string dataContainerID, string varName, coerce string value, optional int index, optional Object author) {
	local NexgenSharedDataContainer dataContainer;
	local NexgenClient client;
	local NexgenExtendedClientController xClient;
	local string oldValue;
	local string newValue;

  // Get the data container.
	dataContainer = dataSyncMgr.getDataContainer(dataContainerID);
	if (dataContainer == none) return;

	oldValue = dataContainer.getString(varName, index);
	dataContainer.set(varName, value, index);
	newValue = dataContainer.getString(varName, index);

	// Notify clients if variable has changed.
	if (newValue != oldValue) {
		for (client = control.clientList; client != none; client = client.nextClient) {
			xClient = getXClient(client);
			if (xClient != none && xClient.bInitialSyncComplete && dataContainer.mayRead(xClient, varName)) {
				if (dataContainer.isArray(varName)) {
					xClient.sendStr(xClient.CMD_SYNC_PREFIX @ xClient.CMD_UPDATE_VAR
						              @ static.formatCmdArgFixed(dataContainerID)
						              @ static.formatCmdArgFixed(varName)
						              @ index
						              @ static.formatCmdArgFixed(newValue));
				} else {
					xClient.sendStr(xClient.CMD_SYNC_PREFIX @ xClient.CMD_UPDATE_VAR
						              @ static.formatCmdArgFixed(dataContainerID)
						              @ static.formatCmdArgFixed(varName)
						              @ static.formatCmdArgFixed(newValue));
				}
			}
		}
	}

	// Also notify the server side controller of this event.
	if (newValue != oldValue) {
		varChanged(dataContainer, varName, index, author);
	}
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Corrected version of the static formatCmdArg function in NexgenUtil. Empty strings
 *                are formated correctly now (original source of all trouble).
 *
 **************************************************************************************************/
static function string formatCmdArgFixed(coerce string arg) {
	local string result;

	result = arg;

	// Escape argument if necessary.
	if (result == "") {
		result = "\"\"";                      // Fix (originally, arg was assigned instead of result -_-)
	} else {
		result = class'NexgenUtil'.static.replace(result, "\\", "\\\\");
		result = class'NexgenUtil'.static.replace(result, "\"", "\\\"");
		result = class'NexgenUtil'.static.replace(result, chr(0x09), "\\t");
		result = class'NexgenUtil'.static.replace(result, chr(0x0A), "\\n");
		result = class'NexgenUtil'.static.replace(result, chr(0x0D), "\\r");

		if (instr(arg, " ") > 0) {
			result = "\"" $ result $ "\"";
		}
	}

	// Return result.
	return result;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
     versionNum=101
     clientControllerClass=Class'NexgenACEExtClient'
     pluginName="Nexgen ACE Extension"
     pluginAuthor="Sp0ngeb0b"
     pluginVersion="2"
}
