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


/* -------------------------------------------------------------------------- */
//
//  The purpose of this script is to provide debuging tools with link_message
//
/* -------------------------------------------------------------------------- */

integer DEBUG = FALSE;
integer listenChannel = 12345;
integer listenHandler;

default
{
    state_entry()
    {
        if (DEBUG == TRUE)
        {
            llMessageLinked(LINK_THIS, 0, llGetScriptName(), "");
            listenHandler = llListen(listenChannel, "", NULL_KEY, "");
        }
    }

    listen(integer channel, string name, key id, string message)
    {
        if (DEBUG == TRUE)
        {
            llOwnerSay("DEBUG HANDLER: listen: " + message);
            llMessageLinked(LINK_THIS, 0, message, llDetectedKey(0));
        }
    }

    link_message(integer sender_num, integer script_id, string message, key id)
    {
        if (DEBUG == FALSE)
        {
            return;
        }

        // avoid sending too much debug message 
        if (script_id == 1)
        {
            llOwnerSay("DEBUG MENU: link_message - sender_num: " + (string)sender_num + " - script_id: " + (string)script_id + " - message: " + message);
        }
        // avoid sending too much debug message 
        if (script_id == 2)
        {
            //llOwnerSay("DEBUG PLAYER: link_message - sender_num: " + (string)sender_num + " - script_id: " + (string)script_id + " - message: " + message);
        }
    }
}
