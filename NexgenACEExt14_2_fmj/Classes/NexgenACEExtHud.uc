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
class NexgenACEExtHud extends NexgenHUDExtension;

var NexgenACEExtClient xClient;
var int orgCrosshairCount;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Renders the HUD. Called before anything of the game HUD has been drawn. This
 *                function is only called if the Nexgen HUD is enabled.
 *  $PARAM        c  Canvas object that provides the drawing capabilities.
 *  $REQUIRE      c != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
simulated function preRender(Canvas c) {

  if(client != none && xClient  == none) xClient = NexgenACEExtClient(client.getController(class'NexgenACEExtClient'.default.ctrlID));

  // Fix ACE crosshair scaling
  if(xClient != none && xClient.HUD != none && xClient.HUDWrapper != none) {
    if (!client.player.bBehindView && client.player.Weapon != None && Level.LevelAction == LEVACT_None) {
      C.DrawColor = xClient.HUD.WhiteColor;
		  client.player.Weapon.PostRender(C);
		  if(!client.player.Weapon.bOwnsCrossHair) {
        orgCrosshairCount = xClient.HUD.CrosshairCount;
        xClient.HUDWrapper.DrawCrossHair(C, 0,0);
        xClient.HUD.CrosshairCount = -1;
      }
    }
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Renders the extended Nexgen HUD.
 *  $PARAM        c  Canvas object that provides the drawing capabilities.
 *  $REQUIRE      c != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function postRender(Canvas c) {
  if(xClient != none && xClient.HUD != none && xClient.HUDWrapper != none) {
    xClient.HUD.CrosshairCount = orgCrosshairCount;
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
     RemoteRole=ROLE_None
}
