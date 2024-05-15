integer DEBUG = 1;

// main menu options
list mainMenu = ["Access", "---", "Stop Song",
                "Pick Song", "Play Mode", "Loop Mode",
                "Play", "Next Song", "Prev Song"];

// level 2 menu options
list accessMenu = ["PUBLIC", "RESTRICTED"];
list loopMenu = ["LOOP", "DISABLED"];
list playModeMenu = ["SINGLE", "SEQUENTIAL", "RANDOM"];



// player settings and music mode 
integer isPlaying = FALSE;

// Play mode can be: SINGLE / SEQUENTIAL or RANDOM
string playMode = "SEQUENTIAL"; 

// should the song keep playing for ever?
integer loopMode = TRUE;

// Access mode (0 = no  / 1 = yes)
integer isPublic = FALSE;


//
// INTERNAL VARIABLES
//

// menu timeout (to remove listner handler)
float menuTimeout = 30.0;

// ID of the person who touch the menu
key ToucherID;

// ID of the owner of the object
key OwnerID;

// Internal variables
integer dialogChannel;
integer listenHandler;




///
/// Random Integer Generator 
///
integer RandomInteger(integer min, integer max)
{
    return min + (integer)llFrand(max - min + 1);
}

// Simple logger
DebugMsg(string msg)
{
    if (DEBUG)
        llOwnerSay(msg);
}



///
/// MENU HEADER
///



// Generate header for the main menu
string GetMainMenuHeader()
{
    string dialogInfo = "\n";
    dialogInfo += "Play Mode: " + playMode + "\n";
    if (loopMode == TRUE)
    {
        dialogInfo += "Loop Mode: LOOP\n";
    } else {
        dialogInfo += "Loop Mode: DISABLED\n";
    }
    if (isPublic == TRUE)
    {
        dialogInfo += "Access Mode: PUBLIC\n";
    } else {
        dialogInfo += "Access Mode: RESTRICTED\n";
    }
    return dialogInfo;
}

// Generate header for the main menu
string GetAccessMenuHeader()
{
    string dialogInfo = "\n";
    if (loopMode == TRUE)
    {
        dialogInfo += "Current Loop Mode: LOOP\n";
    } else {
        dialogInfo += "Current Loop Mode: DISABLED\n";
    }
    return dialogInfo;
}

// Generate header for the loop menu
string GetLoopMenuHeader()
{
    string dialogInfo = "\n";
    if (isPublic == TRUE)
    {
        dialogInfo += "Current Loop Mode: PUBLIC\n";
    } else {
        dialogInfo += "Current Loop Mode: RESTRICTED\n";
    }
    return dialogInfo;
}

// Generate header for the play mode menu
string GetPlayModeMenuHeader()
{
    return "\nCurrent Play Mode: " + playMode + "\n";
}





// read song list
list ReadSongListNotecards()
{
    integer soundId;
    list listNotecards = [];
    
    integer totalSongs = llGetInventoryNumber(INVENTORY_NOTECARD);
    for (soundId = 0; soundId < totalSongs; soundId++)
    {
        listNotecards += [ llGetInventoryName(INVENTORY_NOTECARD, soundId) ];
    }
    return listNotecards;
}






///
/// DEFAULT
///
default
{
    state_entry()
    {
        OwnerID = llGetOwner();
        
        // make it harder to find the channel
        integer rdm = RandomInteger(100000, 500000);
        dialogChannel = -1 - (integer)("0x" + llGetSubString( (string)llGetKey(), -7, -1) ) + rdm;
    }

    touch_start(integer num_detected)
    {
        // who clicked the menu
        ToucherID = llDetectedKey(0);
        
        if (isPublic == FALSE && ToucherID != OwnerID)
        {
            DebugMsg("isPublic is FALSE");
            return;
        }
            
        // create new menu and listner to capture the choosed item
        string header = GetMainMenuHeader();
        llDialog(ToucherID, header, mainMenu, dialogChannel);
        llSetTimerEvent(menuTimeout);
        listenHandler = llListen(dialogChannel, "", ToucherID, "");
        llOwnerSay("listenHandler = " + (string)listenHandler);
    }

    // Listner when user pick something an item in the menu
    listen(integer channel, string name, key id, string message)
    {
        // Used to remove unecessary listner
        integer removeListner = 1;
        
        //
        // Level 1 - Main Menu
        //
        if (message == "Play")
        {
            isPlaying = TRUE;
            llMessageLinked(LINK_THIS, 0, message, llDetectedKey(0));
        }
        else if (message == "Next Song")
        {
            llMessageLinked(LINK_THIS, 0, message, llDetectedKey(0));
        }
        else if (message == "Prev Song")
        {
            llMessageLinked(LINK_THIS, 0, message, llDetectedKey(0));
        }
        else if (message == "Pick Song")
        {
            //listNotecards = ReadSongListNotecards();
            //llDialog(ToucherID, DirSound, but, dialogChannel);
        }
        else if (message == "Play Mode")
        {
            removeListner = 0;
            string playModeMenuHeader = GetPlayModeMenuHeader();
            llDialog(ToucherID, playModeMenuHeader, playModeMenu, dialogChannel);
        }
        else if (message == "Loop Mode")
        {
            removeListner = 0;
            string loopMenuHeader = GetLoopMenuHeader();
            llDialog(ToucherID, loopMenuHeader, loopMenu, dialogChannel);
        }
        else if (message == "Stop Song")
        {
            isPlaying = FALSE;
            llMessageLinked(LINK_THIS, 0, message, llDetectedKey(0));
        }
        else if (message == "Access")
        {
            removeListner = 0;
            string accessMenuHeader = GetAccessMenuHeader();
            llDialog(ToucherID, accessMenuHeader, accessMenu, dialogChannel);
        }
        
        //
        // level 2 - Access Mode
        //
        if (message == "PUBLIC")
        {
            isPublic = TRUE;
            llSay(0, "Set access mode to PUBLIC");
        }
        else if (message == "RESTRICTED")
        {
            isPublic = FALSE;
            llSay(0, "Set access mode to RESTRICTED");
        }
        
        //
        // level 2 - Loop Mode
        //
        if (message == "LOOP")
        {
            loopMode = TRUE;
            llSay(0, "Set loop mode to LOOP");
        }
        else if (message == "DISABLED")
        {
            loopMode = FALSE;
            llSay(0, "Set loop mode to DISABLED");
        }

        //
        // level 3 - Play Mode
        //
        if (message == "SINGLE" || message == "SEQUENTIAL" || message == "RANDOM")
        {
            playMode = message;
            llSay(0, "Set play mode to " + message);
        }
        
        // Check if we have to remove unecessary listner
        if (listenHandler != 0 && removeListner == 1) 
        {
            llListenRemove(listenHandler);
            listenHandler = 0;
        }
    }
    
    
    timer()
    {
        DebugMsg("timer: " + (string)listenHandler);
        // Check if we have to remove unecessary listner
        if (listenHandler < 0)
        {
            llListenRemove(listenHandler);
            listenHandler = 0;
        }
        llOwnerSay("remove timer");
        llSetTimerEvent(0);
    }
}