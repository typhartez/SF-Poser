//
// SF Poser: an animation controller - Documentation and the latest version are here: https://opensimworld.com/sfposer
//
// (c) 2020 Satyr Aeon. Licensed under CC-BY-SA
//
// Set these variables in the .SFconfig to override:
integer autoTimer = 0;       // 0=off. nonzero=auto timer seconds
integer lockMenus = 0;       // 1= lock menus to owner only
string    defaultMenu = "";  // If left empty, the first menu on the list will be used instead
integer allowRemote =0;       // 0 = only sitting    users, 1 = all other users, 2=only sitting+dataserver 3=all users+dataserver, 4=dataserver only, no menu dialogs!
integer isVerbose =0;

list ncList;
list groups; //names
integer offset;
string curGroup;
integer groupSize;

list poses; //names
list poseData;
string poseShortcodes;
string curPose;

list animAvis; //keys
list animAnims;// inv names
list animPos;
list animRot; 

string mode;
integer channel;
key user = NULL_KEY;

list handleIds;
integer curHandle;
string newMenu;
integer nAnim;
list ncLines;

list invAnims;
string invAnimFilter;

integer listener=-1;
integer listenTs;
integer poseTs;

list addons;
list addonData;
integer animDuration;
list npcList;
list rezList;
list exprList;
list lgList; // lockguard cmds
list rlvList;
list foundList;

//These shortcodes can go either in the .SFconfig file or in the addon (NO COM) field of the menu notecards
runShortcodes(string m, integer myMode) // myMode=1 (button) , myMode=2 (remote)
{
    integer i;
    integer l;
    integer idx;
    string s;
    list lines = llParseStringKeepNulls(m, ["{", "}"], []);
    for (l = 0 ; l < llGetListLength(lines); l+=2)
    {
        string c = l2trim(lines, l);
        list tk = llParseStringKeepNulls(l2trim(lines,l+1), [";"], []);
        
        if (c == "DURATION")// DURATION{60} 
            animDuration = (integer)llList2String(tk, 0);
        else if (c == "GIVE" && user != NULL_KEY) //GIVE{cup of tea}
            llGiveInventory(user, llList2String(tk, 0));
        else if (c == "PROP" || c == "DELPROP" || c == "TOGGLEPROP" ||c == "MSGPROP")    //PROP{fire pit;<x,y,z>;<rotX,rotY,rotZ>} coords relative to root, rotation in euler!
        { 
            idx = llListFindList(rezList, l2trim(tk, 0));
            if (idx>0)
            {
                if (c == "TOGGLEPROP" || c == "DELPROP") 
                {
                    osMessageObject(llList2Key(rezList, idx-1), "DIE"); // kill
                    rezList = [] + llDeleteSubList(rezList, idx-1, idx); 
                }
                else if (c == "MSGPROP") osMessageObject(llList2Key(rezList, idx-1), l2trim(tk, 1) );
                else osSetPrimitiveParams( llList2Key(rezList, idx-1), [PRIM_POSITION,    llGetPos()+llList2Vector(tk, 1)*llGetRot(), PRIM_ROTATION, llEuler2Rot(llList2Vector(tk, 2))*llGetRot()] ); // move
            }
            else if (c == "PROP" || c == "TOGGLEPROP") llRezAtRoot(llList2String(tk, 0), llGetPos()+llList2Vector(tk, 1)*llGetRot(), ZERO_VECTOR, llEuler2Rot(llList2Vector(tk, 2))*llGetRot(), 1);
        }
        else if (c == "MSGATT")
        {  // MSGATT{0;message here;19,4} // 0: pose number,  19,4: relevant attachment points
            key u = llList2Key(animAvis, llList2Integer(tk, 0));
            if    (llKey2Name(u) != "") 
                osMessageAttachments(u, llList2String(tk, 1), llParseString2List(llList2String(tk, 2),[","],[]) , 0); 
        }
        else if (c == "MSGLINK") // MSGLINK(4;Hello link number 4}
            osMessageObject( llGetLinkKey(llList2Integer(tk, 0)), llList2String(tk, 1) );

        else if (c == "SAYCH")    // SAYCH{-21,blabla}
            llSay(llList2Integer(tk, 0), llList2String(tk, 1)); 

        else if (c == "WHISPERCH")    // SAYCH{-21,blabla}
            llWhisper(llList2Integer(tk, 0), llList2String(tk, 1)); 

        else if (c == "LINKMSG") // LINKMSG{-1;99;Hello LINK_SET}  Remember, LINK_SET = -1, LINK_THIS=-4
            llMessageLinked(llList2Integer(tk, 0), llList2Integer(tk, 1), llList2String(tk, 2), llDumpList2String(animAvis,"|") );
            
        else if (c == "EXPR")  // EXPR{expr1;repeat-time1;expr2;repeat2 ....}  
            exprList = tk; 
        else if (c == "ANIM"  || c == "STOPANIM") // ANIM{clap;clap;clap;....} 
        {
            for (idx=0; idx < llGetListLength(animAvis);idx++)
                if (llList2Key(animAvis,idx) != NULL_KEY)
                {
                    if (c == "STOPANIM") osAvatarStopAnimation(llList2Key(animAvis,idx), l2trim(tk, idx ) ) ;
                    else restartAn(llList2Key(animAvis,idx), l2trim(tk, idx) );
                }
        }
        else if (c == "LG") //LG{0;leftwrist gravity 1 ;lefthook}  -- do NOT add the "link" or "unlink" part
        {
             lgList += [llList2Integer(tk, 0), llList2String(tk,1), llList2String(tk, 2)];
             i+= 2;
        }
        else if (c == "RLVCAPTURE") // RLVCAPTURE{10.0} -- 10 == radius
        {
            llSensor("", "", AGENT, llList2Float(tk, 0), PI) ;      
        }
        else if (c == "RLVRELEASE")     //RLVRELEASE{} -- no arguments
        {
            mode = "RlvRelease";
            userListDlg("Release Whom?", rlvList);
        }
        else if (c == "RLV") // RLV{0 $ @addoutfit=n $ @addattach=n $ @remoutfit:skirt=force $ @remattach:stomach=force}
        {
            for (idx=1; idx < llGetListLength(tk); idx++)
                relayRlv( llList2Key(animAvis, llList2Integer(tk, 0) ),     l2trim( tk,  idx) );
        }
        else if (c == "SWITCHTOGROUP" && myMode>0)    switchToGroup(l2trim(tk,0)); // SWITCHTOGROUP{My Group}
        else if (c == "SWITCHTOPOSE" && myMode>0)    switchToPose(l2trim(tk,0));     // SWITCHTOPOSE{My Pose}
        else if (c == "UNSIT" && myMode>0) llUnSit( llList2Key(animAvis, llList2Integer(tk,0) ) ); // UNSIT{0}          
        else  if (c != "")
            say("Shortcode not understood:"+ c);
    }
}


loadConfig()
{
    if (llGetInventoryType(".SFconfig") == INVENTORY_NOTECARD)
    {
        integer i;
        list tk = llParseString2List(osGetNotecard(".SFconfig"), ["=", "\n"], []);
        for (i=0; i < llGetListLength(tk) ; i++)
        {
            string c = l2trim(tk,i);
            if ( c == "DefaultGroup") defaultMenu = l2trim(tk, i+1);
            else if ( c== "autoTimer")     autoTimer = llList2Integer(tk, i+1);
            else if ( c== "allowRemote")   allowRemote = llList2Integer(tk, i+1);
            else if ( c == "lockMenus") lockMenus = llList2Integer(tk, i+1);
            else if ( c == "isVerbose") isVerbose = llList2Integer(tk, i+1);            
            else if ( c == "Button" && l2trim(tk,i+1) != "")
            {
                addons += l2trim(tk, i+1);
                addonData += l2trim(tk, i+2);
                i++;
            }
        }
    }
}


restartAn(key id, string an)
{
    osAvatarStopAnimation(id, an);
    osAvatarPlayAnimation(id, an);
}

expressDlg()
{
list exprs = [ "open_mouth", "surprise_emote", "tongue_out","smile", "toothsmile", "wink_emote", "cry_emote","kiss", "laugh_emote","disdain", "repulsed_emote",     "anger_emote", "bored_emote","sad_emote", "embarrassed_emote", "frown","shrug_emote", "afraid_emote", "worry_emote" ];
    dlg("Select expression", llList2List(exprs, offset, offset+10) + ">>");
}

integer countSeated()
{
    integer i=llGetNumberOfPrims();
    integer l=llGetObjectPrimCount(llGetKey());
    return i-l;
}

startListen()
{
    if (listener<0) 
    {
        listener = llListen(channel, "", "", "");
        listenTs = llGetUnixTime();
    }
}

integer fixOffset(integer off, integer maxx)
{
    if (off >= maxx || off <0) return 0;
    return off;
}


userListDlg(string title, list ids)
{
    if (!llGetListLength(ids)) { say("Nobody found"); return; } 
    integer i;
    list o;
    for (i=0; i < llGetListLength(ids) && i < 10; i++) 
        o += (string)(i+1)+" "+llGetSubString( llKey2Name( llList2Key(ids, i) ) , 0, 10);     
    dlg(title, o);
}


swapDlg()
{
    integer i;
    list opts = "CLOSE";
    for (i=offset; i < offset+10 &&     i < llGetListLength(animPos); i++)
    {
        key u = llList2Key(animAvis, i);
        if (u !=user)
        {
            if (u == NULL_KEY) opts += (string)(i+1)+"    (empty)";
            else opts += (string)(i+1)+"  "+llGetSubString(llKey2Name(u), 0, 7);
        }
    }
    if (llGetListLength(animPos) > 10) opts += ">>";
    dlg("Swap with whom?", opts );
}


rezHandles()
{
    if (llGetListLength(handleIds) <groupSize) 
        llRezObject("~positioner", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 1);
    else
    {
        say("Editing pose. Click the handles to change animations"); 
        setHandles();
        llSetTimerEvent(2.0);
    }
}

setHandles()
{
    integer i;
    list handleColors = [<1,.30,1>, <0,0.5,1>, <0,1,0>, <1,1,0>, <0,0,1>, <1,0,0>, <0,1,1>, <1,1,1>, <0,0,0>, <0,1,1> ];
    for (i =0; i < groupSize; i++)
    {
            vector c = llList2Vector(handleColors, i%10);
            osSetPrimitiveParams( llList2Key(handleIds, i), 
                [PRIM_SIZE, <.1, .1, 3>, PRIM_TEXT, (string)(i+1), c, 1.0, PRIM_COLOR, ALL_SIDES, c, 0.5, 
                PRIM_POSITION, llGetPos() + llList2Vector(animPos, i)*llGetRot(), 
                PRIM_ROTATION, llList2Rot(animRot,i)*llGetRot(),
                PRIM_DESC, (string)llGetKey() ]);
    }
}

loadInvAnims()
{
    if (llGetListLength(invAnims) ==0)
    {
        offset=0;
        integer i;
        string sn;
        llSay(0,"Loading animations list ...");
        for (i =0;    i < llGetInventoryNumber(INVENTORY_ANIMATION); i++)
        {
            sn = llGetInventoryName(INVENTORY_ANIMATION, i);
            if ( sn != "~baseAnim" && (invAnimFilter == "" || (llSubStringIndex(sn, invAnimFilter) >=0)))
                invAnims += llGetInventoryName(INVENTORY_ANIMATION, i);
        }
        llSay(0, "done.");
    }
}


invAnimsDlg()
{
    string str ;
    integer i;
    list bts ;
    for (i= 0; i < 9 && (i +offset< llGetListLength(invAnims)) ; i++)
    {
        str += (offset+i)+":"+llList2String(invAnims, i+offset)+"\n";
        bts += (string)(offset+i)+"     "+llGetSubString(llList2String(invAnims, i+offset) , 0, 8);
    }
    mode = "invanims";
    dlg("Anim for pos "+(string)(curHandle + 1)+":\n"+str , ["<<<", "DONE", ">>>"]+ bts );
}


adjustDlg()
{
    list adjustOptions = ["CLOSE","SYNC", "QUIT", "X-", "Y-", "Z-", "X+", "Y+", "Z+" , "EXPRESSION"];
    
    if (llGetOwner() == user) adjustOptions += ["EDIT POSE", "NEW POSE"];
    mode = "adjust";
    dlg("Adjust your position temporarily", adjustOptions);
}

loadNCs(integer doNpcs)
{
    integer i;
    ncList = [];
    if (doNpcs) npcList = [];
    string gn;
    for (i=0; i < llGetInventoryNumber(INVENTORY_NOTECARD); i++)
    {
        string nc = llGetInventoryName(INVENTORY_NOTECARD, i);
        if (llGetSubString( nc, 0, 4) == ".menu")
        {
            integer gs;
            string prm;
            if (llGetSubString(nc, 9,9) == " ") // "old" format
            {
                gs = (integer)llGetSubString(nc, 7,7);
                prm = llGetSubString(nc, 8,8);
            }
            else
            {
                gs = (integer)llGetSubString(nc, 7,8);
                prm = llGetSubString(nc, 9,9);
            }
            gn = llStringTrim(llGetSubString(nc, 10, -1), STRING_TRIM);
            if (gn != "") ncList += [gn, prm, gs, nc];
        }
        else if (doNpcs && llGetSubString( nc, 0, 3) == ".NPC")
            npcList += [llGetSubString(nc, 8,-1), nc, NULL_KEY];
    }
}


killNpcs()
{
    integer i;
    for (i=0; i< llGetListLength(npcList); i+=3)
        if (llList2Key(npcList,i+2) != NULL_KEY) osNpcRemove(llList2Key(npcList,i+2)); 
    npcList = [];
}

killRezzed()
{
    integer i;
    for (i=0; i< llGetListLength(rezList); i+=2) if (llKey2Name(llList2Key(rezList,i)) != "") osMessageObject(llList2Key(rezList,i), "DIE");
    rezList = [];
}


string l2trim(list l, integer i) 
{ 
    return llStringTrim( llList2String(l, i), STRING_TRIM); 
} 

relayRlv(key id, string m)
{
    if (llKey2Name(id)    != "" && m != "")
        llSay(-1812221819, llGetObjectName()+","+ (string)id + "," +m );
}

rlvRelease(key u)
{
    relayRlv( u , "@unsit=y");
    relayRlv( u , "!release");
}

loadPoses(string nc)
{
    integer i;
    poses = [];
    poseData = [];
    list lines = llParseStringKeepNulls(osGetNotecard(nc), ["\n"], []);
    for (i=0; i < llGetListLength(lines); i++)
    {
        string ln = llList2String(lines, i);
        integer idx = llSubStringIndex(ln, "|"); 
        if (idx>0)
        {
            string sn = llStringTrim( llGetSubString(ln, 0, idx-1), STRING_TRIM);
            if    (sn !="")
            {
                poses += sn;
                poseData += llGetSubString(ln, idx+1, -1);
            }
        }
    }
    poses = [] + poses;
    poseData = [] + poseData;
}

switchToGroup(string gName)
{
    integer i = llListFindList(ncList, gName);
    if ( i<0 || (llList2Integer(ncList, i+2) <    countSeated()) || (llList2Integer(ncList, i+2) <1)) 
    {
        say("ERROR: Menu "+gName+" is for "+(string)llList2Integer(ncList, i+2)+" users");
    }
    else if (llList2String(ncList, i+1) =="G" && llSameGroup(user)==FALSE) say("You are not in the group");
    else if (llList2String(ncList, i+1) =="O" && user != llGetOwner()) say("Owner only");
    else
    {
        curGroup = gName;
        groupSize = llList2Integer(ncList, i+2);
        list avOld = animAvis;
        animAvis = [];
        integer n;
        for (n =0; n < llGetListLength(avOld); n++)
            if (llList2Key(avOld,n) != NULL_KEY)
                animAvis += llList2Key(avOld, n);
                
        while (llGetListLength(animAvis) < groupSize ) 
        {
            animAvis += NULL_KEY;
            n++;
        }
        loadPoses(llList2String(ncList, i+3));
    }
}



stopAnims()
{
    integer total=llGetNumberOfPrims();
    integer i;
    for (i = llGetObjectPrimCount(llGetKey()); i < total; i++)
    {
        key u = llGetLinkKey(i+1);
        integer idx = llListFindList( animAvis, u);
        if (idx>=0)
        {
            osAvatarStopAnimation(u, llList2String(animAnims, idx) );
        }
    }
}


killAnims(key u)
{
    list ans =llGetAnimationList(u);
    integer i;
    for (i = llGetListLength(ans); i>=0 ; i--) osAvatarStopAnimation(u, llList2Key(ans,i));     
}



startAnims()
{
    integer total=llGetNumberOfPrims();
    integer i;
    for (i = llGetObjectPrimCount(llGetKey()); i < total; i++)
    {
        key u = llGetLinkKey(i+1);
        integer idx = llListFindList( animAvis, u);
        if (idx>=0)
        {
           vector pos = llList2Vector(animPos, idx);
           rotation rot = llList2Rot(animRot, idx);
           osAvatarPlayAnimation(u, llList2String(animAnims, idx) );
           llSetLinkPrimitiveParamsFast(i+1, [PRIM_ROT_LOCAL, rot, PRIM_POS_LOCAL, ( pos + <0.0, 0.0, 0.4> )]);
        }
    }
    hook("GLOBAL_ANIMATION_SYNCH_CALLED", 1);
}



updatePositions()
{
    integer total=llGetNumberOfPrims();
    integer i;
    for (i = llGetObjectPrimCount(llGetKey()); i < total; i++)
    {
        key u = llGetLinkKey(i+1);
        integer idx = llListFindList( animAvis, u);
        if (idx>=0)
        {
           vector pos = llList2Vector(animPos, idx);
           rotation rot = llList2Rot(animRot, idx);
           llSetLinkPrimitiveParamsFast(i+1, [PRIM_POS_LOCAL, ( pos + <0.0, 0.0, 0.4> ), PRIM_ROT_LOCAL, rot]);
        }
    }

}



setPose( string pose)
{

    integer i;
    curPose = pose;
    exprList =[];
    if (curPose != "")
    {
        integer idx = llListFindList(poses, pose);
        if ( idx >=0)
        {
            list tk = llParseStringKeepNulls (llList2String(poseData, idx), ["|"], []);
            animAnims = [];
            animPos = [];
            animRot = [];
            animDuration = autoTimer;
            poseShortcodes = llList2String(tk, 0); // shortcode line
            if (llSubStringIndex(poseShortcodes, "{")>1) runShortcodes(poseShortcodes, 0);

            // fill with empty if needed
            for (i=1; i < groupSize*3 ; i+=3) 
            {
                animAnims += llList2String(tk, i);
                animPos += (vector)llList2String(tk, i+1);
                animRot += (rotation)llList2String(tk, i+2);
            }
        }
   }
}


setLG(integer isOn, key specificUser)
{
    integer i; 
    integer idx;
    for (i=0; i < llGetListLength(lgList); i+=3)
    {
        for (idx=2; idx <= llGetNumberOfPrims(); idx++)
                    if (llGetLinkName(idx) == llList2String(lgList, i+2) && (specificUser == NULL_KEY  || (specificUser ==    llList2Key(animAvis, llList2Integer(lgList,i))))  )
                    {
                        if (isOn) llWhisper(-9119, "lockguard "+(string)llList2Key(animAvis, llList2Integer(lgList,i) ) +" " + llList2String(lgList, i+1) + " link " + (string)llGetLinkKey(idx));
                        else   llWhisper(-9119, "lockguard "+(string)llList2Key(animAvis, llList2Integer(lgList,i) ) +" " + llList2String(lgList, i+1) + " unlink " + (string)llGetLinkKey(idx));
                    }
    }
    if    (!isOn && specificUser == NULL_KEY) lgList = [];
}


switchToPose(string m)
{
    
    if (llGetListLength(lgList)>0) setLG(0, NULL_KEY);
    if (llGetListLength(rezList)>0) killRezzed();
    stopAnims();
    setPose(m);

    if (curPose != "")
    {
        startAnims();
        setLG(1, NULL_KEY);
        poseTs = llGetUnixTime();
        llSetTimerEvent(1);
    }
    hook("GLOBAL_NEXT_AN|"+poseShortcodes, 1);                    
}

switchUser(key u)
{
    integer i;
    groups = [];
    offset =0;
    if (user != u)
    {
        user = u;  
        for (i =0; i < llGetListLength(ncList); i+= 4)
        {      
            if (!(    (llList2String(ncList, i+1) == "G" && llSameGroup(user)==FALSE)     ||     ((llList2String(ncList, i+1) =="O" && user != llGetOwner())) ))
                groups += l2trim(ncList, i);
        }
        hook("GLOBAL_NEW_USER_ASSUMED_CONTROL|"+(string)u, 1);
    }
}



showMenu()
{
    if (llGetListLength(handleIds) )
    {
        editMenu();
        return;
    }
    
    list opts;
    if ( curGroup != "" && mode != "forcegroups")
    {
        mode = "poses";
        opts = ["[MAIN]", "[ADJUST]", "[SWAP]"] + llList2List(poses, offset, offset+7);
        if (llGetListLength(poses )> 8) opts += "[>>]";
        dlg( "MAIN > "+curGroup+ "["+(string)groupSize+"]  > "+curPose+"\nChange Pose:", opts);
    }
    else
    {
        mode = "groups";
        opts = "[OPTIONS]" + llList2List(groups, offset, offset+9);
        if (llGetListLength(groups)> 10) opts += "[>>]";
        string t= "Select Animations Set:";
        if (llGetListLength(addons)>0) t += "\n(Add-on commands have been added to the options menu)";
        dlg(t, opts);
    } 
}

say(string str)
{
    llRegionSayTo(user, 0, str);
}


editOff()
{
    mode = "";
    integer i;
    for (i=0; i < llGetListLength(handleIds); i++)
        osMessageObject(llList2Key(handleIds, i), "DIE");
    handleIds = [];
}

editMenu()
{
    dlg("Editing "+curGroup+ " > "+curPose + ".\nClick the handles to select animation. Move the handles to edit positions. Click Save Pose after each pose. When done, click Save Menu. Click Edit Off to abort."
        , [ "EDIT OFF", "SAVE MENU", "-", "<PREV", "SAVE POSE", "NEXT>", "FILTER ANIMS", "POSE NAME"]);
}

dlg(string title, list btns)
{
    startListen();
    llDialog(user, title, btns, channel);
}


hook(string s, integer addpos)
{
    if (addpos) llMessageLinked(LINK_THIS, 0, s, llDumpList2String(animAvis,"|"));
    else llMessageLinked(LINK_THIS, 0, s, NULL_KEY);
}


handleApi(string s)
{
    list tk = llParseStringKeepNulls(s, ["|"], []);
    integer idx;
    string cmd = llList2String(tk, 0);
    if (cmd =="MAIN_RESUME_MAIN_DIALOG") showMenu();
    else if (cmd =="MAIN_REGISTER_MENU_BUTTON")
    {
        if (llGetListLength(addons)>5) { llSay(0, "Can't have more than 6 addon buttons"); } 
        
        idx =llListFindList(addons, llList2String(tk, 1));
        if (idx <0) { addons += llList2String(tk, 1); addonData += llList2String(tk, 2); } 
        else { addonData = [] + llListReplaceList(addonData, llList2String(tk, 2), idx, idx); } 
    }
    else if (cmd == "MAIN_UNREGISTER_MENU_BUTTON")
    {
        idx =llListFindList(addons, llList2String(tk,1));
        if (idx>=0) 
        {
            addonData = [] + llDeleteSubList(addonData, idx, idx); 
            addons = [] + llDeleteSubList(addons, idx, idx); 
        }
    }
    else runShortcodes(s, 2);
}

default
{
    state_entry()
    {
        mode ="init";
        if (llGetLinkNumber() > 1) 
        {
            llSay(0, llGetScriptName()+" must be placed in the root prim!");
            return;
        }
        
        if (llGetInventoryType("~positioner") != INVENTORY_OBJECT || llGetInventoryType("~baseAnim") != INVENTORY_ANIMATION)
        {
            llSay(0, "You must add the animation '~baseAnim' and the object '~positioner' (copyable) to this object");
        }
                    
        
        channel = -1 - (integer)("0x" + llGetSubString( (string) llGetKey(), -6, -1) )-393;
        llSitTarget( <0,0, 0.001>, ZERO_ROTATION);
        loadConfig();
        loadNCs(1);
        if (defaultMenu != "")
            curGroup = defaultMenu;
        else 
            curGroup = llList2String(ncList,0);

        if (curGroup !="")
        {
            switchToGroup(curGroup);
            if (isVerbose) llSay(0, "Ready.");
        }
        else
        {
            llSay(0, "No menus found. Select Options->New Menu to create menus");
        }
        hook("GLOBAL_SYSTEM_RESET", 0);
    }
    
    changed(integer c)
    {
        if (c & CHANGED_LINK)
        {
            integer total=llGetNumberOfPrims();
            integer l=llGetObjectPrimCount(llGetKey());
            list seated = [];
            llSleep(.2);
            
            
            for ( ; l < total; l++)
            {
                key u = llGetLinkKey(l+1);
                seated += [u];
                integer idx = llListFindList(animAvis, [u]);
                if (idx ==-1)
                {
                    idx = llListFindList(animAvis, [NULL_KEY]);
                    if (idx == -1)
                    {
                        llSay(0, "No more than "+(string)groupSize+" users can sit.");
                        llUnSit(u);
                        return;
                    }
                    else
                    {

                        animAvis = [] + llListReplaceList(animAvis, [u], idx, idx); // seated
                        killAnims(u);
                        osAvatarPlayAnimation(u, "~baseAnim");
                        
                        if (mode == "init")
                        {
                            curPose = llList2String(poses, 0);
                            if (curPose != "") 
                            {
                               hook("GLOBAL_START_USING", 1);
                               switchToPose(curPose);
                            }
                            mode = "postinit";
                        }

                        hook("GLOBAL_USER_SAT|"+(string)idx+"|"+(string)u, 1);
                    }
                }
            }
            
  
            
            for (l=0; l < llGetListLength(animAvis); l++)
            {
                key u = llList2Key(animAvis, l);
                if (u != NULL_KEY && llListFindList(seated, [u]) < 0)
                {
                    // u Unsat
                    setLG(0, u);
                    osAvatarStopAnimation(u, llList2String(animAnims, l));
                    osAvatarStopAnimation(u, "~baseAnim");
                    animAvis = [] + llListReplaceList(animAvis, [NULL_KEY], l, l);
                    //killAnims(u);
                    hook("GLOBAL_USER_STOOD|"+(string)l+"|"+(string)u, 1);
                }
            }

            stopAnims();
            startAnims();

            if (llGetListLength(seated)==0) 
            {
                editOff();
                setLG(0, NULL_KEY);
                hook("GLOBAL_SYSTEM_GOING_DORMANT", 0);
                killNpcs();
                killRezzed();
                for (l=0; l < llGetListLength(rlvList); l++) rlvRelease( llList2Key(rlvList, l) );
                llResetScript();
            }


            
        }
        else if (c&CHANGED_INVENTORY)
        {
            invAnims =[];
        }
    }
    
    
    touch_start(integer d)
    {
        if ( (
           (allowRemote == 1 || allowRemote == 3)  || ((allowRemote ==0 || allowRemote ==2)     &&     (llListFindList(animAvis, llDetectedKey(0)) >= 0) ) 
         ) == FALSE ) return;

        if (lockMenus>0 && (llDetectedKey(0) != llGetOwner()) )
        {
            llRegionSayTo( llDetectedKey(0), 0, "Menu is locked by owner");
            return;
        }
        
        if (user == NULL_KEY)
        {
            switchUser(llDetectedKey(0));
        }
        else if (llDetectedKey(0) != user)
        {
            startListen();
            llDialog(llDetectedKey(0), "Take control from "+llKey2Name(user)+"?",  ["TAKE CONTROL", "CLOSE"], channel);
            return;
        }
        
        showMenu();
    }
    
    listen(integer c, string n, key id, string m)
    {
        
        if (m == "CLOSE" || m == "-")
        {
        }
        else if (m == "BACK")
        {
            mode = "forcegroups";
            showMenu();
        }
        else if ( m == "DBG" )
        {
            llOwnerSay(llList2CSV(animAvis));

            integer total=llGetNumberOfPrims();
            integer i;
            for (i = llGetObjectPrimCount(llGetKey()); i < total; i++)
            {
                key u = llGetLinkKey(i+1);
                list ans =llGetAnimationList(u);
                llOwnerSay(llKey2Name(u) + ":"+llList2CSV(ans));
            }
        }
        else if (m == "[MAIN]")
        {
            offset=0;
            mode = "forcegroups";
            showMenu();
        }
        else if (m == "[OPTIONS]")
        {
            mode = "options";
            list o = ["BACK", "QUIT","AUTO"];
            if (id == llGetOwner())
            {
                if (lockMenus) o += "UNLOCK MENU";
                else o += "LOCK MENU";
                o += [ "NEW MENU"];

            }
            if (llGetListLength(npcList)) o += "NPCs";
            else o += "-";
            o += addons;
            dlg("Options", o);
        }
        else if (m == "[ADJUST]")
        {
            mode = "adjust";
            adjustDlg();
        }
        else if (m == "SYNC")
        {
           stopAnims();
           startAnims();
           showMenu();
        }
        else if (m == "QUIT")
        {
            editOff();
            integer i;
            while (     llGetNumberOfPrims() > llGetObjectPrimCount(llGetKey()) )
                llUnSit( llGetLinkKey( llGetObjectPrimCount(llGetKey()) +1 ) );
        }
        else if (m == "[SWAP]")
        {
            if (groupSize <2) return;
            if (groupSize ==2)
            {
                key u1 = llList2Key(animAvis,0);
                key u2 = llList2Key(animAvis,1);
                stopAnims();
                animAvis = [] + llListReplaceList(animAvis, [u2, u1], 0, 1);
                startAnims();
                showMenu();
            }
            else
            {
                mode = "SelectSwap";
                offset=0;
                swapDlg();
                return;
            }
        }
        else if (m == "TAKE CONTROL")
        {
            switchUser(id);
            showMenu();
        }
        else if (m == "EDIT POSE")
        {
            if (curGroup != "" && curPose != "")
            {
                autoTimer=0;
                mode = "editing";
                rezHandles();
                hook("GLOBAL_NOTICE_ENTERING_EDIT_MODE", 1);
                editMenu();
            }
        }
        else if (m == "LOCK MENU" )
        {
            lockMenus = 1;
            say("Locked");
        }
        else if (m == "UNLOCK MENU")
        {
            lockMenus =0;
            say("Unlocked");
        }
        else if (m == "EDIT OFF")
        {
            editOff();
            hook("GLOBAL_NOTICE_LEAVING_EDIT_MODE",1);
        }
        else if (m == "SAVE POSE")
        {
            integer i;
            integer idx = llListFindList(poses, curPose);
            if (idx >=0)
            {
                string an;
                string str = poseShortcodes;
                if (str == "") str = "NOCODE";
                for (i=0; i < llGetListLength(animAnims); i++)
                {
                    an = l2trim(animAnims,i);
                    if (an =="") an ="NOANIM";
                    str += "|"+an+"|"+(string)llList2Vector(animPos,i)+"|"+(string)llList2Rot(animRot,i);
                }
                poseData = [] + llListReplaceList(poseData, [str], idx, idx);
                
                if (llGetListLength(rezList))
                {
                    str ="";
                    for (i=0; i< llGetListLength(rezList); i+=2)
                    {
                        list ll = llGetObjectDetails(llList2Key(rezList,i),     [OBJECT_POS, OBJECT_ROT]);
                        str +=    "\nPROP{"+llList2String(rezList, i+1)+";"
                            + (string) ( (llList2Vector(ll,0)-llGetPos())/llGetRot() ) 
                            + ";"+(string)(llRot2Euler( llList2Rot(ll, 1) / llGetRot() )  )
                            + "}";
                    }
                    say("To rez props in current positions use the command strings:"+str);
                }                 
                hook("GLOBAL_EDIT_PERSIST_CHANGES",1);
                hook("GLOBAL_STORE_ADDON_NOTICE",1);           
            }
            editMenu();
        }
        else if (m == "<PREV" || m == "NEXT>")
        {
            if (!llGetListLength(handleIds)) return;
            integer idx = llListFindList(poses, curPose);
            if (m == "<PREV") 
            {
                if (--idx<0) idx =0;
            }
            else if (m == "NEXT>") 
            {
                if (++idx>=llGetListLength(poses) ) idx =0;
            }
            stopAnims();
            setPose(llList2String(poses, idx));
            startAnims();
            setHandles();
            editMenu();
        }
        else if (m == "FILTER ANIMS")
        {
            llTextBox(llGetOwner(), "Enter a filter below. Only the animations containing that string will be listed when you click the handles. Leave empty for no filter", channel);
            mode = "WaitAnimFilter";
        }
        else if (m == "SAVE MENU")
        {
            string str;
            integer i;
            for (i=0; i < llGetListLength(poses); i++)
                str += llList2String(poses, i)+"|"+llList2String(poseData,i)+"\n";
            
            integer idx = llListFindList(ncList, curGroup);
            if (idx>=0)
            {
                string nc = llList2String(ncList, idx+3);
                llRemoveInventory(nc);
                llSleep(.3);
                osMakeNotecard(nc, str); 
                say(nc+" saved");
                hook("GLOBAL_EDIT_STORE_TO_CARD|"+nc,1);
            }
            editMenu();
        }
        else if (m == "NEW MENU")
        {
            newMenu = "";
            llTextBox(llGetOwner(), "Enter name for new menu.\nAfter creating it, select Adjust->New Pose to create poses", channel);
            mode = "NewMenuName";
        } 
        else if (m == "NEW POSE")
        {
            newMenu = "";
            llTextBox(llGetOwner(), "Enter new pose name to add to menu '"+curGroup+"':", channel);
            mode = "NewPoseName";
        }
        else if (m == "POSE NAME")
        {
            llTextBox(llGetOwner(), "Rename pose '"+curPose +"' to:", channel);
            mode = "RenamePose";
        }
        else if (m == "AUTO")
        {
            mode = "AutoTimer";
            dlg("Auto timer is set to: "+(string)autoTimer+" sec. Set auto timer:", ["AUTO OFF","120","90","60","20", "300"]);
        }
        else if (m == "AUTO OFF")
        {
            autoTimer =0;
        }
        else if (m == "EXPRESSION")
        {
            offset=0;
            mode = "SelectExpress";
            expressDlg();
        }
        else if (m == "NPCs") 
        {
            dlg("NPCs menu", [ "ADD NPC", "DEL NPC", "DEL ALL"]);
        }
        else if (m == "ADD NPC" || m=="DEL NPC" || m == "<<-" || m =="->>" || m == "DEL ALL")
        {
            if (m == "<<-") offset -= 9;
            else if (m == "->>") offset += 9;
            else if (m == "DEL ALL")
            {
                killNpcs(); 
                return;
            }
            else 
            {
                mode = m;
                offset=0;
            }
            
            if (offset <0 || offset > llGetListLength(npcList)*3) offset=0;

            integer i;
            list opt;
            for (i=0; i<llGetListLength(npcList); i+= 3)
                if (llGetSubString(llList2String(npcList, i+1),6,6) == "A" || (llGetSubString(llList2String(npcList, i+1),6,6) == "G" &&llSameGroup(user)) || llGetOwner() == user)
                    opt += llList2String(npcList,i);
           opt = llList2List(opt, offset, offset+8);
           dlg("Select NPC", ["<<-", "-", "->>"] + opt); 
        }
        else if (mode == "groups")
        {
            if (m == "[>>]")
            {
                offset=fixOffset(offset+10, llGetListLength(groups));
                mode = "forcegroups";
            }
            else if (llListFindList(groups, m) >=0)
            {
                if (curGroup != m)
                    switchToGroup(m);
            }
            showMenu();                
        }
        else if (mode == "poses")
        {
            if (m == "[>>]")
                offset=fixOffset(offset+8, llGetListLength(poses));
            else if (llListFindList(poses, m) >=0)
                switchToPose(m);
            showMenu();
        }     
        else if (mode == "ADD NPC" || mode == "DEL NPC")
        {
            integer i =llListFindList(npcList, m);
            if (i<0) return;
            if (mode == "ADD NPC")
            {
                list nm = llParseStringKeepNulls(m,[" "], []);
                key nu = osNpcCreate( llList2String(nm,0), llList2String(nm,1), llGetPos()+<0,0,2>, llList2String(npcList, i+1), 8|OS_NPC_SENSE_AS_AGENT);
                osNpcSit(nu, llGetKey() , OS_NPC_SIT_NOW);
                npcList = [] + llListReplaceList(npcList,  nu, i+2, i+2);
            }
            else
            {
                osNpcRemove(llList2Key(npcList, i+2));
                npcList = [] + llListReplaceList(npcList,  [NULL_KEY], i+2, i+2);
            }
        }
        else if (mode == "SelectExpress")
        {
            if (m ==">>") offset = fixOffset(offset+11, 19);
            else
            {
                restartAn(user, "express_"+m);
            }
            expressDlg();
        }     
        else if (mode == "AutoTimer")
        {
            autoTimer = (integer)m;
            say("Auto timer set to "+m+" seconds");
            poseTs = llGetUnixTime();
            llSetTimerEvent(1);
        }
        else if (mode == "RenamePose")
        {
            m = llStringTrim(m, STRING_TRIM);
            integer idx = llListFindList(poses, m);
            if (idx>=0 || m == "" || curPose == "")
            {
                say("Pose name exists or empty. Aborted");
                return;
            }
            
            idx = llListFindList(poses, curPose);
            if (idx>=0)
            {
                curPose = m;
                poses = [] + llListReplaceList(poses, curPose, idx, idx);
            }
            showMenu();
        }
        else if (mode == "RlvCapture")
        {
            key u  = llList2Key( foundList, ((integer)llGetSubString(m, 0, 0)) -1  );
            if (llKey2Name(u) != "" && llListFindList(rlvList, [u]) < 0) 
            {
                say( "Capturing " + llKey2Name( u) ) ;
                relayRlv(u , "@sit:"+ (string)llGetKey() + "=force");
                rlvList += u;
            }
        }
        else if (mode == "RlvRelease")
        {
            integer idx = ((integer)llGetSubString(m, 0, 0)) -1;
            if (idx >=0 && llKey2Name( llList2Key(rlvList, idx) )  != ""  )
            {
                say("Releasing    " +llKey2Name( llList2Key(rlvList, idx)     ) )  ;
                rlvRelease(llList2Key(rlvList, idx) );
                rlvList = [] + llDeleteSubList(rlvList, idx, idx);
            }
        }
        else if (mode == "WaitAnimFilter")
        {
            invAnimFilter = llStringTrim(m, STRING_TRIM);
            invAnims = [];
        }
        else if (mode == "NewPoseName")
        {
           mode = "";
            m = llStringTrim( llGetSubString(m, 0, 20), STRING_TRIM);
            if (m != "")
            {
                if (llListFindList(poses, m)>=0)
                {
                   say("Pose with name "+m+" already exists. Aborting");
                   return;
                }
                stopAnims();
                poses += m;
                if (curPose != "" && llListFindList(poses, curPose)+1>=0)
                    poseData += llList2String( poseData, llListFindList(poses, curPose) ); // Copy last pose
                else
                    poseData += "";
                say("New pose "+m+" added. Select Adjust->Edit Pose to edit it. Click the handles to select animation");
                setPose(m);
                showMenu();
            }
        }
        else if (mode == "NewMenuName")
        {
            newMenu= llStringTrim( llGetSubString(m, 0, 16), STRING_TRIM);
            if (newMenu !="")
            {
                mode = "NewMenuSize";
                llTextBox(user, "How many avatars for this menu?\nPlease enter a number from 1 to 99", channel);
                return;
            }
        }
        else if (mode == "NewMenuSize")
        {
            integer nn = (integer)m;
            if (nn <1 || nn > 99) { say("Number must be from 1 to 99"); mode = ""; return; } 
            string nc;
            if (nn < 10) nc = ".menu000"+(string)nn+"A "+newMenu;
            else nc = ".menu00"+(string)nn+"A "+newMenu;
            if (llGetInventoryType(nc) == INVENTORY_NOTECARD) { say("Notecard "+nc + " already exists, aborting!"); mode = ""; return; } 
            osMakeNotecard(nc, "");
            llSleep(.5);
            say("Created menu notecard "+nc+". Select Adjust->New Pose to create poses");
            stopAnims();
            curPose = "";
            loadNCs(0);
            switchUser(id);
            switchToGroup(newMenu);
        }
        else if (mode == "invanims")
        {
            if (m == ">>>")
                offset += 9;
            else if (m == "<<<")
                offset-= 9;
            else if (m == "DONE")
            {
                showMenu(); 
                return;
            }
            else
            {
                m = llList2String(invAnims, (integer)(llGetSubString(m, 0, 2)));
                if (llGetInventoryType(m) != INVENTORY_ANIMATION) return;
                stopAnims();
                animAnims = llListReplaceList(animAnims, [m], curHandle, curHandle);
                startAnims();              
            }
            offset = fixOffset(offset, llGetListLength(invAnims));
            invAnimsDlg();
        }
        else if (mode =="SelectSwap")
        {
            if (m == ">>") 
            {
                offset = fixOffset(offset + 10, llGetListLength(animAvis)-1);
                swapDlg();
            }
            else
            {
                integer i2 = (integer)llGetSubString(m, 0,1) -1;
                if (i2>=0 && i2 < groupSize)
                {
                    integer idx = llListFindList(animAvis, [user]);
                    if (idx >=0)
                    {
                        key o = llList2Key(animAvis, i2);
                        stopAnims();
                        animAvis = llListReplaceList(animAvis, o, idx, idx);
                        animAvis = [] + llListReplaceList(animAvis, user, i2, i2);
                        startAnims();
                    }
                    showMenu();
                }
            }
        }
        else if (mode == "adjust")
        {  
            vector v ;
            if (m == "X+") v.x+=0.03;          else if (m == "X-") v.x-=0.03;
            else if (m == "Y+") v.y+=0.03;      else if (m == "Y-") v.y-=0.03;
            else if (m == "Z+") v.z+=0.03;      else if (m == "Z-") v.z-=0.03;
            
            integer idx = llListFindList(animAvis, user);
            if (idx>=0)
            {
                v =     llList2Vector(animPos, idx) + v;
                animPos = llListReplaceList(animPos, v, idx, idx);
                updatePositions();
            }
            adjustDlg();
        }
        else if (mode == "options")
        {
            mode = "";
            integer idx = llListFindList(addons, m);
            if (idx<0) return;
            string d = llList2String(addonData, idx);
            if (llSubStringIndex(d, "{") >1) runShortcodes(d, 1);
            else hook( d +"|"+user, 1);
        }
        else
        {
            hook("UNKNOWN|"+m+"|"+(string)id,1);
        }
    }

    timer()
    {
        integer idx;
        if (llGetListLength(handleIds))
        {
            llSetTimerEvent(0);
            for (idx =0;idx < llGetListLength(animPos); idx++)
            {
                list p = llGetObjectDetails(llList2Key(handleIds, idx), [OBJECT_POS, OBJECT_ROT]);
                vector     v = (llList2Vector(p,0) - llGetPos()) / llGetRot();
                rotation r = llList2Rot(p, 1)/llGetRot();
                animPos = [] + llListReplaceList(animPos, v, idx,idx);
                animRot = [] + llListReplaceList(animRot, r, idx,idx);
            }
            updatePositions();
            llSetTimerEvent(0.3);
            return;
        }

        if (llGetListLength(exprList)>0)
        {
            llSetTimerEvent(0);
            integer ts = llGetUnixTime();
            for (idx=0; idx <groupSize; idx++)
            {
                if (llList2Key(animAvis, idx) != NULL_KEY && l2trim(exprList,idx*2) != "" )
                {
                   if (llList2Integer(exprList, idx*2+1)  == 0)
                   {
                        restartAn(llList2Key(animAvis, idx), "express_"+l2trim(exprList,idx*2));
                        exprList = [] + llListReplaceList(exprList, [99999], idx*2+1, idx*2+1);
                   }
                   else if (  ((ts - poseTs) % llList2Integer(exprList, idx*2+1)) ==0)                       
                        restartAn(llList2Key(animAvis, idx), "express_"+l2trim(exprList,idx*2));
                }
            }
            llSetTimerEvent(1);
        }
        else if (autoTimer>0)
            llSetTimerEvent(animDuration);
        else 
            llSetTimerEvent(300);

        if (autoTimer>0)
        {
            if ( (llGetUnixTime() - poseTs) > animDuration)
            {
                idx = llListFindList(poses, curPose) +1;
                if (idx >= llGetListLength(poses)) idx=0;
                string np = llList2String(poses, idx);
                if (np != "") switchToPose(np);
            }
        }

        if ( listener>0 &&    (llGetUnixTime() - listenTs) > 200)
        {
            llListenRemove(listener);
            listener = -1;
        }
        
        if (listener <0 && autoTimer <=0 && llGetListLength(exprList)<=0) llSetTimerEvent(0);

    }

    on_rez(integer n)
    {
        llResetScript();
    }

    object_rez(key id)
    {
        if (mode == "editing")
        {
            handleIds += [id]; 
            rezHandles();
            return;
        }
        else
        {
            rezList += [id];
            rezList += llKey2Name(id);
            osMessageObject(id, "SFUSER|"+(string)user);
        }
    }

    sensor( integer t)
    {
        foundList =[];
        integer i;
        for (i=0; i < t && llGetListLength(foundList) < 10; i++) 
            if ( llListFindList(rlvList, llDetectedKey(i)) <0 &&  osIsNpc(llDetectedKey(i)) == FALSE) 
                foundList += llDetectedKey(i);
        mode = "RlvCapture";
        userListDlg("Capture Whom?", foundList);
    }

    no_sensor()     { say("Nobody found."); }

    dataserver(key id, string m)
    {
        if (llGetOwnerKey(id) == llGetOwner() && llSubStringIndex(m, "HANDLE_TOUCH") ==0 )
        {
            list tk = llParseStringKeepNulls(m, ["|"], []);
            integer idx = llListFindList(handleIds, llList2String(tk, 1));
            if (idx <0) return;
            curHandle = idx;
            loadInvAnims();
            invAnimsDlg();
        }
        else if (allowRemote >=2 && allowRemote <= 4) 
        {
            if (user != llGetOwnerKey(id)) switchUser(llGetOwnerKey(id));
            handleApi(m);
        }
    }

    link_message(integer l, integer f, string m, key k)
    {
        if (f == -1) handleApi(m+"|"+(string)k);
    }
}

