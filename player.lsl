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
integer DEBUG = TRUE;

// Interval of time (in sec) between 2 wave sample 
// default: 3.0sec - But normally, this value is provided is provided within the notecard
float MUSIC_SAMPLE_INTERVAL = 3.0;

// Player volume - between 0.0 (silent) and 1.0 (loud)
float VOLUME = 6.0;

// Script ID (unique)
integer SCRIPT_ID = 2;

// current UUID in notecard
integer currentSampleID = 0;

// currently choosed song (notecard name)
string  currentSongName = "";

// currently playing
string playing = "";

// list that contain all UUID within notecard
list Musicuuids = [];

// THIS NEED TO BE DOCUMENTED
integer songTrackCnt = 0;
integer lineNumber;
integer curSongOffset = 0;
integer numNotecardLines;

float totalTime;

key DataRequest = NULL_KEY;
key ncLineCountKey;

float nextQueueTime;

// Variables to handle the hover text when loading and playing events
list styleDATA = ["Default!♥", "▱", "▰", "▻", "►", "◅", "◄"];
vector displayColourNormal = <1.0, 1.0, 1.0>;
vector displayColourLoading = <0.8, 1.0, 0.8>;
vector displayColourError = <1.0, 0.2, 0.2>;
integer priorityTag;


// Variable used to skip header in notecard
integer isProcessingHeader = 0;



// ================
// Global functions
// ================


// Headers in notecards cause parsing issue when reading them
integer isHeaderLine(integer lineNb, string data)
{
    if (lineNb == 0) 
    {
        if (isFloat(data) == TRUE) 
        {
            // if the 1st line is float, we are fine
            isProcessingHeader = FALSE;
            return FALSE;
        } else {
            // else, we are dealing with the fucking header
            isProcessingHeader = TRUE;
            return TRUE;
        }
    }

    // if we meet the 1st uuid in a fucking header, we have to skip it
    if (isProcessingHeader == TRUE && isUUID(data) == TRUE) {
        isProcessingHeader = FALSE;
        return TRUE;
    }

    // by default, its fucking header is the source of the problem... 
    // header should have started with comment chars, like // or # 
    return FALSE;
}


// Dirty validate a string containing a float value
// Does not handle scientific notation, or hex floats (!!)
// After all, this is designed for 95% of likely human entered data
integer isFloat(string sin)
{
    sin = llToLower(sin);
    // Avoid run time fail (for lslEditor at least) if string looks remotely like scientific notation 
    if (llSubStringIndex(sin, "e") != -1)       return FALSE;     
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
    list playingList = [ "target", "DISPLAY", "action", "display", "type", "playing", "time", llGetTime(), "totalTime", totalTime, "title", currentSongName ];
    llMessageLinked(LINK_THIS, 0, llList2Json(JSON_OBJECT, playingList), NULL_KEY);
}

Initialize()
{
    Debug("Initialize");
    ForceHoverText("");

    playing = "";
    currentSampleID = 1;
    Debug((string)llGetFreeMemory());
    llMessageLinked(LINK_THIS, 0, llGetScriptName(), "");
}


LoadSong()
{
    ncLineCountKey = llGetNumberOfNotecardLines(currentSongName);
}

PlaySong()
{
    Debug("PlaySong with MUSIC_SAMPLE_INTERVAL=" + (string)MUSIC_SAMPLE_INTERVAL);

    playing = currentSongName;
    currentSampleID = 0;

    Debug("Playing: "+ currentSongName);
    llResetTime();
    //Debug("Musicuuids: "+ llDumpList2String(Musicuuids, ";"));
    totalTime = MUSIC_SAMPLE_INTERVAL * llGetListLength(Musicuuids);
    SendPlayingList();

    llPlaySound(llList2Key(Musicuuids, currentSampleID++), VOLUME);
    nextQueueTime = llGetTime() + MUSIC_SAMPLE_INTERVAL - 1.0;
    llSetTimerEvent(0.2);
    Debug((string)llGetFreeMemory());
}


StopSong()
{
    Debug("StopSong");

    llStopSound();
    llSetTimerEvent(0.0);

    playing = "";
    Musicuuids = [];
    currentSongName = "";
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




Debug(string msg)
{
    if (DEBUG)
        llOwnerSay("Player - " + msg);
}

default
{
    state_entry()
    {
        llSetSoundQueueing(TRUE);
        Initialize();
        //StartComms();
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }


    dataserver( key id, string data )
    {
        //Debug("dataserver: "+(string)(lineNumber - 1)+" = "+data);

        if (id == ncLineCountKey)
        {
            numNotecardLines = (integer)data;
            MUSIC_SAMPLE_INTERVAL = 0;
            songTrackCnt = 0;
            lineNumber = 0;
            Debug("dataserver - initial read: " + currentSongName);
            DataRequest = llGetNotecardLine(currentSongName, lineNumber++);
            ForceHoverText("");
        }
        else if (id == DataRequest)
        {
            if (data != EOF)
            {
                // Skip header or comment in notecard
                if (isHeaderLine((lineNumber - 1), data)) {
                    DataRequest = llGetNotecardLine(currentSongName, lineNumber++);
                    return;
                }

                list loadingList = [ "target", "DISPLAY", "action", "display", "type", "loading", "current", lineNumber, "end", numNotecardLines, "title", currentSongName ];
                llMessageLinked(LINK_THIS, SCRIPT_ID, llList2Json(JSON_OBJECT, loadingList), NULL_KEY);
            
                if ((songTrackCnt == 0) && (MUSIC_SAMPLE_INTERVAL <= 0.0))
                    MUSIC_SAMPLE_INTERVAL = (float)llStringTrim(data, STRING_TRIM);
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
                DataRequest = llGetNotecardLine( currentSongName, lineNumber++ );
            }
            else
            {
                PlaySong();
                llMessageLinked(LINK_THIS, SCRIPT_ID, "StartPlaying", NULL_KEY);
            }
        }
    }

    timer()
    {
        SendPlayingList();

        if (nextQueueTime <= llGetTime())
        {
            nextQueueTime = llGetTime() + MUSIC_SAMPLE_INTERVAL;

            Debug("timer: start: playing = "+(string)playing+", curTrack="+(string)currentSampleID+", songTrackCnt="+(string)songTrackCnt);

            if ( currentSampleID < songTrackCnt )
            {
                llPlaySound(llList2Key(Musicuuids, currentSampleID), VOLUME);
                if ( ++currentSampleID < songTrackCnt )
                    llPreloadSound( llList2Key(Musicuuids, currentSampleID) );
                else
                    nextQueueTime = llGetTime() + MUSIC_SAMPLE_INTERVAL + 1.0;
            }
            else
            {
                Debug("Finished: "+currentSongName);
                StopSong();
                llMessageLinked(LINK_THIS, SCRIPT_ID, "SongEnded", NULL_KEY);
            }

            Debug("timer end: playing = "+playing+", currentSampleID="+(string)currentSampleID+", songTrackCnt="+(string)songTrackCnt);
        }
    }

    link_message(integer sender, integer scriptId, string msg, key id)
    {
        //Debug("link_message: " + msg);

        if(llJsonGetValue(msg, ["target"]) == "DISPLAY")
        {
            if(llJsonGetValue(msg, ["action"]) == "display") 
            {
                RenderDisplay(msg); 
            }
            return;
        }
        
        if (llSubStringIndex(msg, "PlaySong") != -1)
        {
            StopSong();
            currentSongName = llGetSubString(msg, 9, -1);
            LoadSong();
        }
        else if (msg == "SongEnded")
        {
            StopSong();
        }
        else if (msg == "StopAllSong")
        {
            StopSong();
            llMessageLinked(LINK_THIS, SCRIPT_ID, "StopAllSong", NULL_KEY);
        }

    }
}
