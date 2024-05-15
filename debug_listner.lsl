default
{
    state_entry()
    {
        llMessageLinked(LINK_THIS, 0, llGetScriptName(), "");
    }

    link_message(integer sender_num, integer num, string message, key id)
    {
        llOwnerSay("sender_num = " + (string)sender_num);
    }
}
