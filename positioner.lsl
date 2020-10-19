
default
{
    dataserver(key id,string m)
    {
        list tk = llParseStringKeepNulls(m, ["|"], []);
        string cmd = llList2String(tk, 0);
        if (cmd=="DIE") llDie();        
    }

    changed(integer change)
    {
        if (change&CHANGED_REGION_START) llDie();
    }
    
    touch_start(integer n)
    {
        key parentId = (key)llGetObjectDesc();
        if (llKey2Name(parentId) != "") // check it exists
        {
            osMessageObject(parentId, "HANDLE_TOUCH|"+(string)llGetKey());
        }
    }
}