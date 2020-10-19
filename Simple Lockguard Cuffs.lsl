/****
  Simple lockguard cuff listener
  Wear your attachment and drop this script in it
  Name your object something like "Right Cuff" 
  And change its description to match the attachment point, e.g. set the description to "rightwrist" if it goes to the right wrist. 
  Add the attachment in your object and make it copyable
 
  To create a button to give the cuffs, add  this line in .SFconfig:
  Button=Get Cuff=GIVE{Right Cuff}
  
  To add chains to a pose use the LG{} shortcode:
  LG{0;rightwrist;rightHook}
  
  This will connect rightwrist to the child prim named "rightHook" for the avatar at position 0 (first position)

****/ 






/// Edit your particles here 
chains(key tgt) 
{
    integer linear =1; ///  linear=0: loose rope/chain    linear=1: tense (e.g. rope)
    
    list ps;
    if (linear)
    {
        ps += [
          PSYS_PART_START_COLOR, <.1,.1,.1>,  
            PSYS_PART_START_SCALE, <0.05, 0.3, FALSE>,
            PSYS_SRC_TEXTURE, TEXTURE_BLANK, 
            PSYS_SRC_ACCEL, < 00.00, 00.00, 0>,
            PSYS_PART_FLAGS,  PSYS_PART_TARGET_LINEAR_MASK | PSYS_PART_RIBBON_MASK
            ];
    }
    else 
    {
        ps += [
            PSYS_PART_START_COLOR, <.700,.500,.100>,  
            PSYS_PART_START_SCALE, <0.05, 0.2, FALSE>,
            PSYS_SRC_TEXTURE, TEXTURE_BLANK, //"12a256ff-626c-437e-9863-b2f12fccf11b", 
            PSYS_SRC_ACCEL, < 00.00, 00.00, 0>,
            PSYS_PART_FLAGS,  PSYS_PART_TARGET_POS_MASK | PSYS_PART_RIBBON_MASK
        ];
    }
    
    
    ps += [
    PSYS_PART_START_ALPHA, (float) 1.0,       
    PSYS_SRC_BURST_RATE,         (float) 0.03,
    PSYS_PART_MAX_AGE,           (float)  1.0,
    PSYS_SRC_MAX_AGE,            (float)  0.00,

    PSYS_SRC_PATTERN, (integer) 1,
    PSYS_SRC_TARGET_KEY,  tgt,
    PSYS_SRC_BURST_PART_COUNT, (integer)  1
    ];
    llParticleSystem(ps );

}


integer CHAINS_CHANNEL=-9119 ;
string myName;


default
{
    on_rez(integer n)
    {
        llResetScript();
    }
    
    state_entry()
    {
        llListen(CHAINS_CHANNEL, "", "","");
        llParticleSystem([]);
    }
    
    listen(integer n, string nam, key id, string m)
    { 
        list tk = llParseString2List(m, [" "], []);
        if (llList2String(tk, 0) == "lockguard"  && (llList2String(tk, 2) == llGetObjectDesc() || llList2String(tk, 2) == "ALL") )
        {
            key u = llList2Key(tk, 1);
            if (u != llGetOwner()) return;
            
            key tgt  = llList2Key(tk, 4);
            if (llList2String(tk, 3) == "link")
            {

               chains(tgt);
            }
            else
            {
                llParticleSystem([]);
            }
        }

    }
}
