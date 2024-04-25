integer DEBUG = FALSE;
string animName = "lute animation";
float INTERVAL = 3 ;

//float INTERVAL =  llGetNotecardLine/( Name, pota );
float V = 6.0;
integer pota = 0;
integer CHAN = -81412;
integer ASSET = 9;

integer listener;
// integer trackCnt = 0;
// integer LINK_NUMBER = 0;
integer Curl = 0;
integer SoundID = 0;
integer songTrackCnt = 0;
integer lineNumber;
integer curSongOffset = 0;
integer totalSongs = 0;
integer curSongEnd = 8;
integer NotecardLine = 0;
integer numNotecardLines;

float totalTime;

string  DirSound = "";
string  Name = "";
string playing = "";

string NEXT_MSG = "Next >>";
string PREV_MSG = "<< Prev";
string STOP_MSG = "Stop";

list but = [];
list Names = [];
list Musicuuids = [];

key DataRequest = NULL_KEY;
key ncLineCountKey;

float nextQueueTime;


list styleDATA = ["Default!♥", "▱", "▰", "▻", "►", "◅", "◄"];
vector displayColourNormal = <1.0, 1.0, 1.0>;
vector displayColourLoading = <0.8, 1.0, 0.8>;
vector displayColourError = <1.0, 0.2, 0.2>;
integer priorityTag;

integer isDealingWithFuckingHeader = 0;

// ================
// Global functions
// ================

///
/// BEGIN - added by Darleene
///
integer isFuckingHeader(integer lineNb, string data) {

    
    if (lineNb == 0) 
    {
        if (isFloat(data) == TRUE) 
        {
            // if the 1st line is float, we are fine
            isDealingWithFuckingHeader = FALSE;
            return FALSE;
        } else {
            // else, we are dealing with the fucking header
            isDealingWithFuckingHeader = TRUE;
            return TRUE;
        }
    }

    // if we meet the 1st uuid in a fucking header, we have to skip it
    if (isDealingWithFuckingHeader == TRUE && isUUID(data) == TRUE) {
        isDealingWithFuckingHeader = FALSE;
        return TRUE;
    }

    // by default, its fucking header is the source of the problem... 
    // header should have started with comment chars, like // or # 
    return FALSE;
}


// Dirty validate a string containing a float value
// Does not handle scientific notation, or hex floats (!!)
// After all, this is designed for 95% of likely human entered data
integer  isFloat(string sin)
{
    sin = llToLower(sin);
    // Avoid run time fail (for lslEditor at least) if string looks remotely like scientific notation 
    if (llSubStringIndex(sin, "e") != -1)   	return FALSE; 	
    list temp = llParseStringKeepNulls(sin, ["."], [] );
    string subs = llList2String(temp, 0);
    if ( (string) ( (integer) subs) != subs)    return FALSE;
    if ( (temp != []) > 2)                      return FALSE;
    if ( (temp != [])== 2)
    {
	subs = llList2String(temp, 1);    // extract the decimal part
        // must have no sign after DP, so handle first decimal discretely
	string first = llGetSubString(subs, 0, 0);
	if ( (string) ( (integer) first) != first)     return FALSE;  
	if ( (string) ( (integer) subs)  != subs)      return FALSE;
    }
    return TRUE;
}

///
/// END - added by Darleene
///

// Create a progress bar from percentage
string ProgressBar(float percent, integer length)
{    
    string tmp_str;
    integer tmp_i;
    
    // First apply bright icons
    while(tmp_i < (integer)(percent * length)) {
        tmp_str += llList2String(styleDATA, 2);
        tmp_i++;
    }
    
    // Second apply dark icons
    while(tmp_i < length) {
        tmp_str += llList2String(styleDATA, 1);
        tmp_i++;
    }
    
    return tmp_str;
}

string CalcTime(integer seconds)
{
    string tmp_str;
    integer tmp_timer_sec;
    integer tmp_timer_min;
    integer tmp_timer_hour;
    // Calculate values
    if(seconds >= 3600) { tmp_timer_hour = llFloor(seconds / 3600); seconds = seconds % 3600; }
    if(seconds >= 60) { tmp_timer_min = llFloor(seconds / 60); seconds = seconds % 60; }
    if(seconds > 0) { tmp_timer_sec = seconds; }
    
    // Only include hours if applicable
    if(tmp_timer_hour) { tmp_str = (string)tmp_timer_hour + ":"; }
    
    // Include minutes
    if(tmp_timer_min < 10) { tmp_str += "0"; }
    tmp_str += (string)tmp_timer_min + ":";
    
    // Include seconds
    if(tmp_timer_sec < 10) { tmp_str += "0"; }
    tmp_str += (string)tmp_timer_sec;
    
    // Finished
    return tmp_str;
}

RenderDisplay(string JSON)
{    
    // play status?
    string type = llJsonGetValue(JSON, [ "type"]);
    
    if(llJsonGetValue(JSON, ["type"]) == "playing")
    {
        // load & errors gets priority
        if(priorityTag < llGetUnixTime())
        {
            // scale progress bar according to title
            integer tmp_pb_length;
            string tmp_title = llJsonGetValue(JSON, ["title"]);
            if(llStringLength(tmp_title) < 12) {
                tmp_pb_length = 6;
            } else { 
                if(llStringLength(tmp_title) > 40) {
                    tmp_pb_length = 20;
                    tmp_title = llGetSubString(llJsonGetValue(JSON, ["title"]), 0, 40);
                } else {
                    tmp_pb_length = (integer)(llStringLength(tmp_title) / 4) * 2;
                }
            }
            
            // calc percentage
            float tmp_percent = (float)llJsonGetValue(JSON, ["time"]) / (float)llJsonGetValue(JSON, ["totalTime"]);
            
            // adjust icons accordingly
            string tmp_str_ico_left;
            string tmp_str_ico_right;
            if(tmp_percent < 0.52) { tmp_str_ico_left = llList2String(styleDATA, 3); } else { tmp_str_ico_left = llList2String(styleDATA, 4); }
            if(tmp_percent < 0.53) { tmp_str_ico_right = llList2String(styleDATA, 5); } else { tmp_str_ico_right = llList2String(styleDATA, 6); }
            
            // build display
            string tmp_str;
            tmp_str = ProgressBar(tmp_percent, tmp_pb_length);
            tmp_str = llInsertString(tmp_str, tmp_pb_length / 2, tmp_str_ico_left + "  " + CalcTime((integer)llJsonGetValue(JSON, ["time"])) + "  ⅼ  " + CalcTime((integer)llJsonGetValue(JSON, ["totalTime"])) + "  " + tmp_str_ico_right);
            tmp_str = tmp_title + "\n" + tmp_str;
            llSetText(tmp_str, displayColourNormal, 1.0);          
        }
    }
    
    // loading status?
    if(llJsonGetValue(JSON, ["type"]) == "loading")
    {
        // reserve priority
        priorityTag = llGetUnixTime(); // + 3;
        
        // build display
        float tmp_percent = (float)llJsonGetValue(JSON, ["current"]) / (float)llJsonGetValue(JSON, ["end"]);
        string tmp_str = ProgressBar(tmp_percent, 10);
        tmp_str = llInsertString(tmp_str, 5, (string)((integer)(tmp_percent * 100)) + "%");
        tmp_str = llJsonGetValue(JSON, ["title"]) + "\n" + tmp_str;
        llSetText(tmp_str, displayColourLoading, 1.0);
    }
    
    // error status?
    if(llJsonGetValue(JSON, ["type"]) == "error")
    {
        // reserve priority
        priorityTag = llGetUnixTime() + 10;
        
        // build display
        llSetText(llJsonGetValue(JSON, ["msg"]), displayColourError, 1.0);
    }
}


ForceHoverText(string errorText)
{
    list errorList = [ "target", "DISPLAY", "action", "display", "type", "error", "msg", errorText ];
    string json = llList2Json(JSON_OBJECT, errorList);
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, errorList), NULL_KEY);
}

SendPlayingList()
{
    list playingList = [ "target", "DISPLAY", "action", "display", "type", "playing", "time", llGetTime(), "totalTime", totalTime, "title", Name ];
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, playingList), NULL_KEY);
}

Initialize()
{
    ForceHoverText("");

    playing = "";
    Curl = 1;
    curSongEnd = 8;
    curSongOffset = 0;

    ReadSongListNotecards();
}

ReadSongListNotecards()
{
    totalSongs = llGetInventoryNumber(INVENTORY_NOTECARD);
    for (SoundID = 0; SoundID < totalSongs; ++SoundID)
    {
        Names += [ llGetInventoryName(INVENTORY_NOTECARD, SoundID) ];
    }
}

curSongs()
{
    if(curSongOffset > 0)
        but = [PREV_MSG];
    else
        but = [" "];

    if(curSongEnd < (totalSongs-1))
        but += [STOP_MSG, NEXT_MSG];
    else
        but += [STOP_MSG, " "];

    integer i;
    DirSound = "\n \n";

    if (curSongOffset >= totalSongs)
    {
        curSongOffset = 0;
        curSongEnd = curSongOffset + (ASSET - 1);
    }

    if (curSongEnd >= totalSongs)
        curSongEnd = totalSongs - 1;

    for (i = curSongOffset; i <= curSongEnd; i++)
    {
        if (SoundID == i)
            DirSound += "*";
        else
            DirSound += " ";
        DirSound += (string) (i + 1) + ") ";
        DirSound += llList2String(Names, i);
        DirSound += "\n";

        but += (string)(i + 1);
    }
}

doNextSet()
{
    curSongOffset += ASSET;
    curSongEnd = curSongOffset + (ASSET - 1);

    if (curSongOffset >= totalSongs)
    {
        curSongOffset = 0;
        curSongEnd = curSongOffset + (ASSET - 1);
    }

    if (curSongEnd >= totalSongs)
        curSongEnd = totalSongs - 1;
}


doPrevSet()
{
    if (curSongOffset > 1 && ((curSongOffset - ASSET) < 1))
        curSongOffset = 0;
    else
        curSongOffset -= ASSET;

    curSongEnd = curSongOffset + (ASSET - 1);

    if (curSongEnd >= totalSongs)
        curSongEnd = totalSongs - 1;

    if (curSongOffset < 0)
    {
        curSongEnd = totalSongs - 1;
        curSongOffset = totalSongs - (ASSET - 1);
    }
}

LoadSong()
{
    Debug("LoadSong");

    Debug( "Loading: "+ Name);

    ncLineCountKey = llGetNumberOfNotecardLines(Name);
}

PlaySong()
{
    Debug("PlaySong with INTERVAL=" + (string)INTERVAL);

    playing = Name;

    Curl = 0;

    Debug("Playing: "+ Name);
    llResetTime();
    totalTime = INTERVAL * llGetListLength(Musicuuids);
    SendPlayingList();

    llPlaySound(llList2Key(Musicuuids, Curl++), V);
    nextQueueTime = llGetTime() + INTERVAL - 1.0;
    llSetTimerEvent(0.2);
}


StopSong()
{
    Debug("StopSong");

    llStopSound();
    llSetTimerEvent(0.0);
    StopAnimation(animName);

    playing = "";

    Musicuuids = [];
    ForceHoverText("");
}

integer isUUID(string s)
{
    integer result = TRUE;
    
    if (llStringLength(s) != 36)
        result = FALSE;
    else
    {
        list temp = llParseStringKeepNulls(s, [ "-" ], []);
        if (llGetListLength(temp) != 5)
            result = FALSE;
    }
    return result;
}

StartAnimation(string anim)
{
    integer invType = llGetInventoryType(anim);
    if ((llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) && (invType == INVENTORY_ANIMATION))
        llStartAnimation(anim);
}

StopAnimation(string anim)
{
    integer invType = llGetInventoryType(anim);
    if ((llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) && (invType == INVENTORY_ANIMATION))
        llStopAnimation(anim);
}

ShowDialog(key avi)
{
    llDialog(avi, DirSound, but, CHAN);
}

StartComms()
{
    if (listener != 0)
        llListenRemove(listener);

    CHAN = llFloor(llFrand(1000000) - 100000);
    listener = llListen(CHAN, "", NULL_KEY, "");
}

Debug(string msg)
{
    if (DEBUG)
        llOwnerSay(msg);
}

default
{
    state_entry()
    {
        llSetSoundQueueing(TRUE);
        llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION);

        Initialize();
        StartComms();
    }

    changed(integer change)
    {
        Debug("changed");

        if (change & CHANGED_OWNER)
            llResetScript();
        else
        {
            if (change & CHANGED_INVENTORY)
                ReadSongListNotecards();
            if (change & (CHANGED_REGION | CHANGED_REGION_START))
                StartComms();
        }
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }

    dataserver( key id, string data )
    {
        Debug("dataserver: "+(string)(lineNumber - 1)+" = "+data);

        if (id == ncLineCountKey)
        {
            numNotecardLines = (integer)data;
            INTERVAL = 0;
            songTrackCnt = 0;
            lineNumber = 0;
            DataRequest = llGetNotecardLine(Name, lineNumber++);
            ForceHoverText("");
        }
        else if (id == DataRequest)
        {
            if (data != EOF)
            {

                /// BEGIN - added by Darleene
                if (isFuckingHeader((lineNumber - 1), data)) {
                    DataRequest = llGetNotecardLine(Name, lineNumber++);
                    return;
                }
                /// END - added by Darleene

                list loadingList = [ "target", "DISPLAY", "action", "display", "type", "loading", "current", lineNumber, "end", numNotecardLines, "title", Name ];
                llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, loadingList), NULL_KEY);
            
                if ((songTrackCnt == 0) && (INTERVAL <= 0.0))
                    INTERVAL = (float)llStringTrim(data, STRING_TRIM);
                else
                {
                    data = llStringTrim( data, STRING_TRIM );

                    list dataParts = llParseString2List(data, ["|"], [""]);
                    if (isUUID(llList2String(dataParts, 0)))
                    {
                        Musicuuids += llList2String(dataParts, 0);
                        songTrackCnt += 1;
                    }
                }
                DataRequest = llGetNotecardLine( Name, lineNumber++ );
            }
            else
                PlaySong();
        }
    }

    touch_start(integer touchNumber)
    {
        integer freeMem = llGetFreeMemory();
        llOwnerSay("freeMem = " + (string)freeMem);

        Debug("touch_start");
/// BEGIN -- added by Darleene
        // this fix tiny bug: not everything load properly when someoneone push a lot of notecards too quickly in the object...
        ReadSongListNotecards();
/// END -- added by darleene

        curSongs();
        StartAnimation(animName);

        ShowDialog(llDetectedKey(0));
    }

    listen(integer CHAN, string name, key id, string message)
    {
        Debug("listen: "+message);

        list words = llParseString2List(message, ["="], []);
        string testFind = llList2String(words, 0);
        if (testFind == "Next >>")
        {
            doNextSet();
            curSongs();

            ShowDialog(id);
        }
        else if (testFind == "<< Prev")
        {
            doPrevSet();
            curSongs();

            ShowDialog(id);
        }
        else if (testFind == "Stop")
            StopSong();
        else if ((integer)message > 0 && (integer)message < 256)
        {
            SoundID = (integer)message - 1;
            Name = llList2String(Names, SoundID);

            StopSong();

            LoadSong();
        }
    }


    timer()
    {
        SendPlayingList();

        if (nextQueueTime <= llGetTime())
        {
            nextQueueTime = llGetTime() + INTERVAL;

            Debug("timer: start: playing = "+(string)playing+", curTrack="+(string)Curl+", songTrackCnt="+(string)songTrackCnt);

            if ( Curl < songTrackCnt )
            {
                llPlaySound(llList2Key(Musicuuids, Curl), V);
                if ( ++Curl < songTrackCnt )
                    llPreloadSound( llList2Key(Musicuuids, Curl) );
                else
                    nextQueueTime = llGetTime() + INTERVAL + 1.0;
            }
            else
            {
                Debug("Finished: "+Name);
                StopSong();
            }

            Debug("timer end: playing = "+playing+", Curl="+(string)Curl+", songTrackCnt="+(string)songTrackCnt);
        }
    }
    link_message(integer sender, integer num, string msg, key id)
    {
        if(llJsonGetValue(msg, ["target"]) == "DISPLAY")
        {
            if(llJsonGetValue(msg, ["action"]) == "display") 
                RenderDisplay(msg); 
        }
    }
}
