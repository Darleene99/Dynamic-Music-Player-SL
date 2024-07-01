/**
MIT License

Copyright (c) 2024 - Darleene99 and co...

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

// Turn on or off debug message
integer DEBUG = FALSE;

// Script ID (unique)
integer SCRIPT_ID = 1;

// main menu options
list mainMenu = ["Access", "Stop Song", "Cancel",
                "Pick Song", "Play Mode", "Loop Mode",
                "Play", "Next Song", "Prev Song"];

// level 2 menu options
list accessMenu = ["PUBLIC", "RESTRICTED"];
list loopMenu = ["LOOP", "DISABLED"];
list playModeMenu = ["SINGLE", "SEQUENTIAL", "RANDOM"];



// player settings and music mode 
integer isPlaying = FALSE;

// is the player loading a song at the moment?
integer isLoading = FALSE;

// Is the menu and player ready to play song
integer isReady = FALSE;

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


// List of string with notecards names (alias, the songs list)
list listNotecards = [];


// Current song ID in the listNotecards
integer currentSongId = 0;
string currentSongName = "";


// Maximum button per page menu
integer MAX_BUTTON = 9;

// Additionnally, the menu has a paginator. 
// So we need to keep track of current offeset, total song, etc...
integer curSongOffset = 0;
integer totalSongs = 0;
integer curSongEnd = 8;

// Paginator item (last row for the buttons)
string NEXT_MSG = "Next >>";
string PREV_MSG = "<< Prev";
string STOP_MSG = "Stop";


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
        llOwnerSay("Menu - " + msg);
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



//
// SONG LIST MENU FUNCTIONS
//

doNextSet()
{
    curSongOffset += MAX_BUTTON;
    curSongEnd = curSongOffset + (MAX_BUTTON - 1);

    if (curSongOffset >= totalSongs)
    {
        curSongOffset = 0;
        curSongEnd = curSongOffset + (MAX_BUTTON - 1);
    }

    if (curSongEnd >= totalSongs)
        curSongEnd = totalSongs - 1;
}


doPrevSet()
{
    if (curSongOffset > 1 && ((curSongOffset - MAX_BUTTON) < 1))
        curSongOffset = 0;
    else
        curSongOffset -= MAX_BUTTON;

    curSongEnd = curSongOffset + (MAX_BUTTON - 1);

    if (curSongEnd >= totalSongs)
        curSongEnd = totalSongs - 1;

    if (curSongOffset < 0)
    {
        curSongEnd = totalSongs - 1;
        curSongOffset = totalSongs - (MAX_BUTTON - 1);
    }
}

showDialogSongPicker()
{
    //
    // SONG LIST MENU VARIABLES
    //
    // Menu is composed of 2 parts:
    //  - The text that is display (upper to the button)
    //  - The button that the user can click
    //
    list chooseSongMenuButtons = generateSongMenuButtons();
    string chooseSongMenuDisplay = generateSongMenuDisplay();

    llDialog(ToucherID, chooseSongMenuDisplay, chooseSongMenuButtons, dialogChannel);
}


// Generate text that is display (upper to the button)
string generateSongMenuDisplay()
{
    string chooseSongMenuDisplay = "";
    integer i;
    chooseSongMenuDisplay = "\n \n";

    // Generate song list to be displayed
    for (i = curSongOffset; i <= curSongEnd; i++)
    {
        // add an asterix to the currently playing song
        if (currentSongId == i)
            chooseSongMenuDisplay += "*";
        else
            chooseSongMenuDisplay += " ";
        chooseSongMenuDisplay += (string) (i + 1) + ") ";
        chooseSongMenuDisplay += llList2String(listNotecards, i);
        chooseSongMenuDisplay += "\n";
    }

    return chooseSongMenuDisplay;
}



//  Generate the buttons that the user can click
list generateSongMenuButtons()
{
    list chooseSongMenuButtons = [];

    // determine if the prev or next button should be displayed
    if(curSongOffset > 0)
        chooseSongMenuButtons = [PREV_MSG];
    else
        chooseSongMenuButtons = [" "];

    if(curSongEnd < (totalSongs-1))
        chooseSongMenuButtons += [STOP_MSG, NEXT_MSG];
    else
        chooseSongMenuButtons += [STOP_MSG, " "];

    integer i;

    // define current offset for the paginator
    if (curSongOffset >= totalSongs)
    {
        curSongOffset = 0;
        curSongEnd = curSongOffset + (MAX_BUTTON - 1);
    }

    if (curSongEnd >= totalSongs)
        curSongEnd = totalSongs - 1;

    // Generate the list of buttons to display
    for (i = curSongOffset; i <= curSongEnd; i++)
    {
        chooseSongMenuButtons += (string)(i + 1);
    }
    return chooseSongMenuButtons;
}



StopAllSong()
{
    // reset the basic variable
    isPlaying = FALSE;
    currentSongName = "";
    currentSongId = 0;

    // Send the stop command to the player
    llMessageLinked(LINK_THIS, SCRIPT_ID, "StopAllSong", ToucherID);

    // i must slow down the script because SL is slow when you call 2 functions...
    llSleep(0.2);
}



PlaySong()
{
    // Avoid error when people click to fast next and prev
    if (isLoading == TRUE)
    {
        llSay(0, "(PlaySong) Song is loading. Please wait...");
        return;
    }

    currentSongName = llList2String(listNotecards, currentSongId);
    if (currentSongName == "")
    {
        llOwnerSay("Oh snap... current song name is empty for ID " + (string)currentSongId);
    }
    //DebugMsg("PlaySong - currentSongName: " + (string)currentSongName);
    //DebugMsg("PlaySong - currentSongId: " + (string)currentSongId);
    llMessageLinked(LINK_THIS, SCRIPT_ID, "PlaySong " + currentSongName, ToucherID);

    isLoading = TRUE;
    isPlaying = TRUE;

}


PlayNext()
{
    //DebugMsg("PlayNext - totalSongs = " + (string)totalSongs);
    //DebugMsg("PlayNext - currentSongId = " + (string)currentSongId);
    if (currentSongId == totalSongs-1)
    {
        currentSongId = 0;
    } 
    else 
    {
        currentSongId++;
    }
    PlaySong();
}

PlayPrev()
{
    //DebugMsg("PlayPrev - totalSongs = " + (string)totalSongs);
    //DebugMsg("PlayPrev - currentSongId = " + (string)currentSongId);
    if (currentSongId == 1)
    {
        currentSongId = totalSongs;
    }
    else if (currentSongId != 0)
    {
        currentSongId--;
    }
    PlaySong();
}


// read song list
ReadSongListNotecards()
{
    //DebugMsg("Trigger ReadSongListNotecards");
    totalSongs = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer i; 
    for (i = 0; i < totalSongs; i++)
    {
        listNotecards += [ llGetInventoryName(INVENTORY_NOTECARD, i) ];
    }
    isReady = TRUE;
}



Initialize()
{
    DebugMsg("Initialize");
    OwnerID = llGetOwner();
    currentSongId = 0;
    curSongEnd = 8;
    curSongOffset = 0;
    isPlaying = FALSE;
    isLoading = FALSE;
    isReady = FALSE;

    // make it harder to find the channel for the dialog menu
    integer rdm = RandomInteger(100000, 500000);

    // set a dialog channel
    dialogChannel = -1 - (integer)("0x" + llGetSubString( (string)llGetKey(), -7, -1) ) + rdm;     

    llOwnerSay((string)llGetFreeMemory());
    llMessageLinked(LINK_THIS, 0, llGetScriptName(), "");

    ReadSongListNotecards();
}



///
/// DEFAULT
///
default
{
    state_entry()
    {
        Initialize(); 
    }

    on_rez(integer start_param)
    {
        Initialize(); 
    }

    touch_start(integer num_detected)
    {
        // who clicked the menu
        ToucherID = llDetectedKey(0);
        
        if (isPublic == FALSE && ToucherID != OwnerID)
        {
            llSay(0, "Access denied");
            return;
        }

        // Avoid error when people click to fast next and prev
        if (isReady == FALSE)
        {
            llSay(0, "Player is initializing. Please wait...");
            return;
        }

        // Avoid error when people click to fast next and prev
        if (isLoading == TRUE)
        {
            llSay(0, "(Touch) Song is loading. Please wait...");
            return;
        }

        // create listen handler
        listenHandler = llListen(dialogChannel, "", ToucherID, "");

        // timeout for menu (to close llListen event)
        llSetTimerEvent(menuTimeout);

        // create new menu and listner to capture the choosed item
        string header = GetMainMenuHeader();
        llDialog(ToucherID, header, mainMenu, dialogChannel);
        DebugMsg("touch_start - listenHandler = " + (string)listenHandler);
    }

    changed(integer change)
    {
        DebugMsg("changed");
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
        else if (change & CHANGED_OWNER)
        {
            llResetScript();
        }
        else if (change & CHANGED_INVENTORY)
        {
            ReadSongListNotecards();
        }
    }

    // Listner when user pick something an item in the menu
    listen(integer channel, string name, key id, string message)
    {
        // Used to remove unecessary listner
        integer extendTimer = 0;
        key avatarId = llDetectedKey(0);

        DebugMsg("listen = " + message);

        //
        // Level 1 - Main Menu
        //
        if (message == "Cancel")
        {
            return;
        }
        else if (message == "Play")
        {
            PlaySong();
        }
        else if (message == "Next Song")
        {
            PlayNext();
        }
        else if (message == "Prev Song")
        {
            PlayPrev();
        }
        else if (message == "Pick Song")
        {
            extendTimer = 1;
            showDialogSongPicker();
        }
        else if (message == "Play Mode")
        {
            extendTimer = 1;
            string playModeMenuHeader = GetPlayModeMenuHeader();
            llDialog(ToucherID, playModeMenuHeader, playModeMenu, dialogChannel);
        }
        else if (message == "Loop Mode")
        {
            extendTimer = 1;
            string loopMenuHeader = GetLoopMenuHeader();
            llDialog(ToucherID, loopMenuHeader, loopMenu, dialogChannel);
        }
        else if (message == "Stop Song")
        {
            StopAllSong();
        }
        else if (message == "Access")
        {
            extendTimer = 1;
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
        // level 2 - Play Mode
        //
        if (message == "SINGLE" || message == "SEQUENTIAL" || message == "RANDOM")
        {
            playMode = message;
            llSay(0, "Set play mode to " + message);
        }

       //
        // level 2 - Single song Mode
        //
        if (message == "Next >>")
        {
            extendTimer = 1;
            doNextSet();
            showDialogSongPicker();
        }
        else if (message == "<< Prev")
        {
            extendTimer = 1;
            doPrevSet();
            showDialogSongPicker();
        }
        else if (message == "Stop")
        {
            StopAllSong();
        }
        else if ((integer)message > 0 && (integer)message < 256)
        {
            DebugMsg("elseif integer: " + (string)((integer)message));
            currentSongId = (integer)message - 1;
            PlaySong();
        }

        if (extendTimer == 1) 
        {
            // add more time before closing the listener
            llSetTimerEvent(menuTimeout);
        }
    }
    
    
    timer()
    {
        // Check if we have to remove unecessary listner
        if (listenHandler != 0)
        {
            DebugMsg("llListenRemove - listenHandler: " + (string)listenHandler);
            llListenRemove(listenHandler);
            listenHandler = 0;
        }
        
        DebugMsg("remove timer");
        llSetTimerEvent(0.0);
    }


    link_message(integer sender, integer scriptId, string msg, key id)
    {
        // player sent message to inform the song was loaded and has started to play
        if (msg == "StartPlaying")
        {
            isLoading = FALSE;
            return;
        }

        // Manage sequential and random mode
        if (msg == "SongEnded")
        {
            isPlaying = FALSE;
            if (playMode != "SINGLE")
            {
                if (playMode == "SEQUENTIAL")
                {
                    PlayNext();
                }
                else if (playMode == "RANDOM")
                {
                    // Random mode (note sure it will work... need to test the max value)
                    currentSongId = RandomInteger(0, totalSongs);
                    llSleep(0.2); // slow down baby
                    PlaySong();
                }
            }
        }
    }
}
