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
class NexgenACEExtClientConfig extends NexgenPanel;

var NexgenACEExtClient xClient;
var IACEConfigFile ACEConfig;

var UWindowCheckbox perfModeInp;
var UWindowCheckbox soundFixInp;
var UWindowComboControl timingModeList;
var NexgenEditControl timingModeEdit;
var UWindowComboControl scalingList;
var NexgenEditControl scalingEdit;
var UWindowComboControl demoList;
var NexgenEditControl xOffsetEdit, yOffsetEdit;

var bool bSetValuesCalled;

/***************************************************************************************************
 *
 *  $DESCRIPTION  Creates the contents of the panel.
 *  $OVERRIDE
 *
 **************************************************************************************************/
function setContent() {
  local int region;

	// Retrieve client controller interface.
	xClient = NexgenACEExtClient(client.getController(class'NexgenACEExtClient'.default.ctrlID));
  ACEConfig = xClient.ACEConfig;

	// Create layout & add components.
  setAcceptsFocus();
	createPanelRootRegion();
	splitRegionH(12);
	addLabel("ACE Settings", true, TA_Center);
	splitRegionH(1, defaultComponentDist);
	addComponent(class'NexgenDummyComponent');

  //if(int(client.player.Level.EngineVersion) < 469) {
    splitRegionH(20, defaultComponentDist);
    soundFixInp = addCheckBox(TA_Left, "Activate Sound Fix", true);
  //}
  splitRegionH(20, defaultComponentDist);
  perfModeInp = addCheckBox(TA_Left, "Activate High Performance Mode (framerate stabilization, only for high end pcs)", true);
  splitRegionH(20, defaultComponentDist);
  splitRegionV(376, defaultComponentDist);
  region = currRegion++;
  addLabel("Timing Mode (change in case of performance problems, not recommended)", true, TA_Left);
  splitRegionV(104, defaultComponentDist);
  timingModeList = addListCombo();
  timingModeEdit = addEditBox();

  selectRegion(region);
  selectRegion(splitRegionH(20, defaultComponentDist));
  splitRegionV(376, defaultComponentDist);
  region = currRegion++;
  addLabel("Crosshair Scale (Auto scales dynamically with resolution, fixed does not)", true, TA_Left);
  splitRegionV(92, defaultComponentDist);
  scalingList = addListCombo();
  scalingEdit = addEditBox();

  selectRegion(region);
  selectRegion(splitRegionH(20, defaultComponentDist));
  splitRegionV(376, defaultComponentDist);
  region = currRegion++;
  addLabel("Display demo recording status", true, TA_Left);
  demoList = addListCombo();

  selectRegion(region);
  selectRegion(splitRegionH(20, defaultComponentDist));
  splitRegionV(376, defaultComponentDist);
  region = currRegion++;
  addLabel("Demo recording status offset", true, TA_Left);
  splitRegionV(16, defaultComponentDist);
  addLabel("X:", true, TA_Right);
  splitRegionV(40, defaultComponentDist);
  xOffsetEdit = addEditBox();
  splitRegionV(16, defaultComponentDist);
  addLabel("Y:", true, TA_Right);
  splitRegionV(40, defaultComponentDist);
  yOffsetEdit = addEditBox();

	// Configure components.
	perfModeInp.register(self);
	if(soundFixInp != none) soundFixInp.register(self);
  timingModeList.register(self);
  timingModeList.addItem("Default Mode", "0");
  timingModeList.addItem("Compatibility Mode", "1");
  timingModeList.addItem("Custom Mode", "2");
  timingModeEdit.register(self);
  timingModeEdit.setMaxLength(1);
  timingModeEdit.setNumericOnly(true);
  scalingList.register(self);
  scalingList.addItem("Auto", "0");
  scalingList.addItem("Fixed", "1");
  scalingEdit.register(self);
  scalingEdit.setMaxLength(3);
  scalingEdit.setNumericOnly(true);
  scalingEdit.setNumericFloat(true);
  demoList.register(self);
  demoList.addItem("Always (filename format)", "0");
  demoList.addItem("Always (yes/no format)", "1");
  demoList.addItem("When recording (filename format)", "2");
  demoList.addItem("When recording (yes/no format)", "3");
  demoList.addItem("Never", "3");
  xOffsetEdit.register(self);
  xOffsetEdit.setNumericOnly(true);
  xOffsetEdit.setMaxLength(4);
  yOffsetEdit.register(self);
  yOffsetEdit.setNumericOnly(true);
  yOffsetEdit.setMaxLength(4);
  setValues();
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Notifies the dialog of an event (caused by user interaction with the interface).
 *  $PARAM        control    The control object where the event was triggered.
 *  $PARAM        eventType  Identifier for the type of event that has occurred.
 *  $REQUIRE      control != none
 *  $OVERRIDE
 *
 **************************************************************************************************/
function notify(UWindowDialogControl control, byte eventType) {
  local int index, timingMode;

	super.notify(control, eventType);

  if (eventType == DE_Click && control == perfModeInp) {
    ACEConfig.SetConfigVariable("bForceHighPerf", CVAR_BOOL, string(perfModeInp.bChecked));
    ACEConfig.WriteConfig(".");
    client.showMsg("<C07>Changes will take effect after a reconnect.");
  } else if (soundFixInp != none && eventType == DE_Click && control == soundFixInp) {
    client.player.consoleCommand("mutate ACE SFToggle");
  } else if(control == timingModeList && eventType == DE_Change && !bSetValuesCalled) {
    index = timingModeList.getSelectedIndex();

    if(index < 2) {
      if(index == 1 ) timingMode = 5;
      ACEConfig.SetConfigVariable("TimingMode", CVAR_Int, string(timingMode));
      ACEConfig.WriteConfig(".");
      setValues();
      client.showMsg("<C07>Changes will take effect after a reconnect.");
    } else {
      timingModeEdit.setDisabled(false);
    }
  } else if(control == timingModeEdit && eventType == DE_EnterPressed) {
    ACEConfig.SetConfigVariable("TimingMode", CVAR_Int, timingModeEdit.getValue());
    ACEConfig.WriteConfig(".");
    setValues();
    client.showMsg("<C07>Changes will take effect after a reconnect.");
  } else if(control == scalingList && eventType == DE_Change && !bSetValuesCalled) {
    if(scalingList.getSelectedIndex() == 0) {
      client.player.consoleCommand("mutate ACE CrosshairScale auto");
    } else {
      scalingEdit.setDisabled(false);
    }
  } else if(control == scalingEdit && eventType == DE_EnterPressed) {
    client.player.consoleCommand("mutate ACE CrosshairScale "$scalingEdit.getValue());
  } else if(control == demoList && eventType == DE_Change && !bSetValuesCalled) {
    client.player.consoleCommand("mutate ACE SetDemoStatus "$demoList.getSelectedIndex());
  } else if( (control == xOffsetEdit || control == yOffsetEdit) && eventType == DE_EnterPressed) {
    ACEConfig.SetConfigVariable("DemoStatusXOffset", CVAR_INT, xOffsetEdit.getValue());
    ACEConfig.SetConfigVariable("DemoStatusYOffset", CVAR_INT, yOffsetEdit.getValue());
    ACEConfig.WriteConfig(".");
    client.showMsg("<C07>Changes will take effect after a reconnect.");
  }
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Sets the values of all input components.
 *
 **************************************************************************************************/
function setValues() {
  local int timingMode;
  local float scaling;

  bSetValuesCalled = true;
	perfModeInp.bChecked = bool(ACEConfig.QueryConfigVariable("bForceHighPerf", ACEConfig.ConfigVariableType.CVAR_BOOL, false));
  if(soundFixInp != none) soundFixInp.bChecked = !bool(ACEConfig.QueryConfigVariable("bDisableSoundFix", ACEConfig.ConfigVariableType.CVAR_BOOL, false));

  timingMode = int(ACEConfig.QueryConfigVariable("TimingMode", ACEConfig.ConfigVariableType.CVAR_INT, false));
  timingModeEdit.setValue(string(timingMode));
  switch timingMode {
    case 0:
      timingModeList.setSelectedIndex(0);
      timingModeEdit.setValue("0");
      timingModeEdit.setDisabled(true);
      break;
    case 5:
      timingModeList.setSelectedIndex(1);
      timingModeEdit.setValue("1");
      timingModeEdit.setDisabled(true);
      break;
    default:
      timingModeList.setSelectedIndex(2);
      timingModeEdit.setDisabled(false);
      break;
  }

  scaling = float(ACEConfig.QueryConfigVariable("CrosshairScale", ACEConfig.ConfigVariableType.CVAR_FLOAT, false));
  scalingEdit.setValue(Left(string(scaling), 3));
  if(scaling == -1.0) {
    scalingList.setSelectedIndex(0);
    scalingEdit.setValue("1.0");
    scalingEdit.setDisabled(true);
  } else {
    scalingList.setSelectedIndex(1);
    scalingEdit.setDisabled(false);
  }

  demoList.setSelectedIndex(int(ACEConfig.QueryConfigVariable("DemoStatusMode", ACEConfig.ConfigVariableType.CVAR_INT, false)));

  xOffsetEdit.setValue(ACEConfig.QueryConfigVariable("DemoStatusXOffset", ACEConfig.ConfigVariableType.CVAR_INT, false));
  yOffsetEdit.setValue(ACEConfig.QueryConfigVariable("DemoStatusYOffset", ACEConfig.ConfigVariableType.CVAR_INT, false));

  bSetValuesCalled = false;
}

/***************************************************************************************************
 *
 *  $DESCRIPTION  Default properties block.
 *
 **************************************************************************************************/
defaultproperties
{
     panelIdentifier="NexgenACEExtClientConfig"
}
