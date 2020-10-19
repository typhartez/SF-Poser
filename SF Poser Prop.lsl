//
// Drop this script inside a prop, change its name (to e.g. MyProp). Take it into inventory and place it inside the sfposer object
// To rez the prop in a pose, add this shortcode to the notecard line:
//
// PROP{MyProp; <0,0,1>; <0,0,0>}
//
// When selecting the pose, the prop will rezz. Click "Adjust->edit pose" and move the prop to its final position. 
// Then click on "Save pose". SFposer will print the final POSE{} code that you should use to rez it in its final position. 
//

default
{
    dataserver(key id, string m)
    {
        if (m == "DIE") llDie();
    }
    changed(integer change)
    {
        if (change & CHANGED_REGION_START) llDie();
    }
    
}

