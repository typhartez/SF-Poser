//  
//  Use this script to rez a prop that will automatically request to attach to the user (for example: a dumbbell)
//
//  Wear your attachment and add this script inside it. Adjust it to its final position
//  RESET THE SCRIPTS in the attachment to record its position
//  Detach the attachment, add it in the contents of the SFposer object, and make it full permissions
//
//  Add this line to .SFconfig notecard to create a button to rez the attachment prop:
//  Button=Attach MyProp=PROP{MyPropName;<0,0,0>;<0,0,0>}
//
//  Note: Attachment props cannot be detached by right clicking, instead the user will have to click on them to detach.
//


integer point = 0;
rotation myRot;
vector myPos;


key myUser = NULL_KEY;
default
{
    state_entry()
    {
        myRot = llGetLocalRot();
        myPos = llGetLocalPos();
        point = llGetAttached();
        llOwnerSay("Current position saved.");
    }
    
    attach(key id)
    {
        if (myUser == id)
        {
            llSetLocalRot(myRot);
            llSetPos(myPos);
        }
    }
    
    touch_start(integer n)
    {
        if (myUser == llDetectedKey(0))
            llRequestPermissions(myUser, PERMISSION_ATTACH);
    }
    
    run_time_permissions(integer p)
    {
        if (p&PERMISSION_ATTACH)
        {
            if (llGetAttached() >0) llDetachFromAvatar();
            else
            {
                llAttachToAvatarTemp((integer)point);
                llRegionSayTo(myUser, 0, "Touch me to detach");
            }
        }
    }
    
    dataserver(key id, string m)
    {
        if (llGetAttached() <=0 && m =="DIE") llDie(); 
        else if (llGetSubString(m,0, 6) == "SFUSER|")
        {
            myUser = (key)llGetSubString(m, 7, -1);
            llRequestPermissions(myUser, PERMISSION_ATTACH);            
        }
    }
    
    changed(integer change)
    {
        if (change & CHANGED_REGION_START) llDie();
    }
    
}
