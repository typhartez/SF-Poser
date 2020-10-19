# SF-Poser

Up-to-date version of this readme is here: https://opensimworld.com/sfposer

## WHAT IS SF POSER

SF Poser is a General-Purpose Animation Controller for up to 99 avatars. It can be used to create furniture from scratch and quickly without editing notecards at all. It allows on-the-fly adjustments of poses and change of animations, automatic timers, prop rezzing, NPC rezzing, expressions, and other built-in powerful utilities.
It is compatible with the notecard format of the wonderful PMAC system, which means that it works right away with existing PMAC furniture. 


## SF POSER FEATURE SET


* Fully Automated editing. SF Poser allows you to create new notecards and poses on the fly, and save them without ever creating or editing notecards and without the need to stand up/reset the script
* Animation switching: Clicking the positioning handle allows to experiment with different sets of animations
* Adjust menu: Users can make temporary finetuning to their position on-the-fly in order to perfectly match the pose
* Expressions: emote using a facial expression at any time
* Built in support for LockGuard chains
* Built-in support for RLV
* Built-in support for Rezzing NPCs
* Built-in Object Giver
* Built-in Props rezzer with ability to rez/derez/move objects
* Built-in utilities such as sending chat channel messages, OSSL messages, attachment messages and more
* Configurable via the '.SFconfig' notecard which supports the PMAC configuration options
* Create custom Buttons with a single line in the .SFconfig notecard using powerful Shortcodes (see below)
* OSSL-native script, meaning that you can control up to 9 avatars with a single script, like PMAC. It requires that the owner has enabled OSSL permissions for the same functions that PMAC uses
* Small footprint: A single script for everything. The script uses as little resources as possible, and resets when unused, minimizing memory usage. Loading time is instantaneous
* Link-message and dataserver-API that is compatible with PMAC, with some additions. 
* Permission system for limiting access to menus as in PMAC
* Snappy operation and uncluttered menu dialogs


## QUICKSTART WITH SF POSER

You can get the SFposer package from the opensimworld region: https://opensimworld.com/hop/74730
The package contains an empty SFposer Template.

- Rez the template and add your animations in its contents
- Click on it and select `[Options]`->`New Menu` to create a new Pose menu
- Then click on `[Adjust]`->`New Pose` to create your first pose. The positioning handles should appear
- Touch each handle to select the animation you want to play for each position in the pose
- When done, click `Save Pose` and then `Save Menu`
Congratulations, you just created your first menu card and pose!




### TO CONVERT AN EXISTING PMAC OBJECT

- Remove all the existing scripts from the object
- Drop the `~positioner`, the `~baseAnim` and the `..SFposer` script in the contents of the PMAC object. You will find those inside the SFposer Template object
- That's all!


### TO CONVERT FROM OTHER SYSTEMS (AvSitter/MLP)


There is an online converter system that you can use to convert MLP and AVsitter cards to the SFposer/PMAC format: https://opensimworld.com/tools



## USING SHORTCODES{}


If you want to the built-in features such as Expressions, LockGuard etc, you will need to add shortcodes such as `EXPR{}` , `LG{}` to the *.menu* notecards.
There is a special position in each notecard line to insert your shortcodes. It is the position right after the button label.
It is usually occupied with the string `NO COM` or `-` which mean `no shortcode`. You insert your shortcodes in this place.

```
Dance Together2|NO COM|danceLeft2|...
Dance Together|EXPR{smile;3;smile;4}|danceLeft|...
Dance Together3|SHORTCODE_GOES_HERE|danceLeft3|...
```

In addition , shortcodes can be used to create Buttons that go in the `[Options]` menu. You add the Button lines in the `.SFconfig` notecard as follows:

```
Button=ButtonLabel=SHORTCODE{arg;arg;arg}
```

After editing any notecard, you need to stand up and sit again, to force the script to reload.




## ADDING EXPRESSIONS


SFposer supports facial expressions. For each avatar participating in the pose, you can specify an expression animation to run, and the time it takes to repeat the expression (in seconds -- if you dont want repeats , enter 0). The Expressions Shortcode is:

```
EXPR{expression1;repeatTime1;expression2;repeatTime2;expression3;repeatTime3 ... and so on for every avatar of the pose}
```

The expressions and repeatTimes can be left empty, but be sure to include the required `;` separators for all avatars in the pose.
For example, the following notecard line defines expressions for the pose *WatchMovie* which is for 3 avatars:

```
WatchMovie|EXPR{laugh_emote;4;open_mouth;3;frown;0}|chair_sit|<0.2112.... [the rest of the pose line]
```

In this case, avatar1 will play the animation `express_laugh_emote` every 4 seconds; avatar2 will play `express_open_mouth` every 3 seconds and avatar3 will play `express_frown` only once.
For brevity, the `express_` part of the animation name is omitted (so you only enter `frown` for animation `express_frown`) . The full list of available expressions is:
`open_mouth`, `surprise_emote`, `tongue_out`, `smile`, `toothsmile`, `wink_emote`, `cry_emote`, `kiss`, `laugh_emote`, `disdain`, `repulsed_emote`, `anger_emote`, `bored_emote`, `sad_emote`, `embarrassed_emote`, `frown`, `shrug_emote`, `afraid_emote`, `worry_emote`



## PROPS REZZING


*Props* are rezzable objects. All props objects must contain the SFposer Prop script so that they can be deleted after use. Click here to get the script

After adding the script to your prop, drop it in the contens of the object and rename it to "MyProp".
Add the following Shortcode to a pose to rez the prop:

```
PROP{MyProp;<1,1,1>;<0,0,0>}  
```

This will rez *MyProp* at position `<1,1,1>` and rotation `<0,0,0>` (in Euler coordinates, radians) relative to the object, when the pose is selected.

Sit and re-sit on the SFposer to reload the notecards, and then select the pose again. The prop should rez in the position `<1,1,1>`. 

Edit the prop to position it to its final position, and then select  `Adjust`->`Edit Pose` -> `Save Pose`. The system will print out the final `PROP{}` shortcode that you should use to correctly position the prop. Edit your *.menu* notecard again and replace the shortcode with the shortcode for the final position . After re-sitting your prop should appear in its correct position. 

Additional shortcodes for props are supported. You can use them to create Buttons that rez/derez props:

* `TOGGLEPROP{MyProp;<1,1,1>;<0,0,0>}`   When the button is pressed, it rezzes the prop, when pressed again, it deletes it.
* `DELPROP{MyProp}`  Deletes the prop

For example, you can  define a rez/unrez button in the `.SFconfig` notecard as follows:

```
Button=Rez/Unrez=TOGGLEPROP{MyProp;<1,1,1>;<1,1,1>}
```

(remember to re-sit in order to reload the card)



**Attachment Props**: You can use our "SFposer attachment prop script" (get it here) to create props that auto-attach to the current user. Use the following procedure:

- Wear your attachment, adjust it to its final position and add the "SFposer Attachment Prop script" inside it. You will find this script at the end of this page
- RESET THE SCRIPTS in the attachment to record its position
- Detach the attachment,  add it in the contents of the SFposer object, and make it full permissions

Add the following line to .SFconfig notecard to create a button  to rez the prop:

```
Button=Attach MyProp=PROP{MyPropName;<0,0,0>;<0,0,0>}
```

After that, re-sit in your SFposer object  and select `[Options]` -> `Attach MyProp`. The prop should request to attach to your avatar.

Note that Attachment props are temporary and cannot be detached by right clicking, instead the user will have to click on them to detach.





## RLV SUPPORT (EXPERIMENTAL)

SFPoser has built-in support for RLV and uses shortcodes to implement it.

Add the following lines to your *.SFconfig* notecard to create an "RLV Capture" and  an "RLV Release" button:

```
Button=RLV Capture=RLVCAPTURE{20}
Button=RLV Release=RLVRELEASE{}
```

The shortcode `RLVCAPTURE{20}` indicates that 20 is the maximum distance  (in meters) within which to search for avatars to capture. `RLVRELEASE{}` does not have any arguments 

For each pose, you can use the `RLV{}` shortcode to send RLV commands from SFposer: 

```
RLV{avatarNum; @rlvCommand1 ; @rlvCommand2; @rlvCommand3 ... }
```

In the line above, avatarNum is the position of the avatar (0 is the first avatar). You can send as many separate RLV commands you wish with a single `RLV{}` shortcode, but remember to separate them with ';'

RLV support is still experimental so please report any bugs.


## BUILT-IN GIVER

To give an object (e.g. Popcorn) to the user who is currently using the system, simply create a Button in the *.SFconfig* notecard as shown below:

```
Button=Get Popcorn=GIVE{Popcorn}
```

The button "Get Popcorn" will be added to the Main menu's `[Options]` screen. Make sure the Popcorn object is inside the contents of the SFposer object and that it is copyable or else the command will fail silently


## NPC REZZING SUPPORT

You can rez/derez NPCs using the same notecards that PMAC uses. Just add the NPC notecards that you have created for PMAC and reset the object by unsitting and re-sitting. The NPCs submenu is inside the `[Options]` menu. The Name of each appearance notecard should be *.NPC00A  Npc Name*


## LOCKGUARD CHAINS SUPPORT

SFposer supports LockGuard V2 cuffs for chains and ropes. In order to add lockguard settings to a pose, use the `LG{}` Shortcode which should be added as a shortcode in your notecard pose as follows:

```
LG{0;rightwrist;rightHook}
```

This instructs the cuff worn by the avatar sitting at position 0 (the first position) to link to the child prim named *rightHook* and uses the lockguard command `rightwrist` which points to the right wrist cuff. You can use a more elaborate lockguard command instead such as `rightwrist gravity 4 life 1.5 color 1 0 0` but DO NOT INCLUDE the `link` and `unlink` commands. These are added automatically by the system.
You can add multiple `LG{}` Shortcodes for multiple cuffs. An example notecard line is:

```
UseCableMachine| LG{0;rightwrist life 1;righthook} LG{0;leftwrist life 1;lefthook} |cables|<1.3282,1.8789,0.8556>|<0.0001,-0.0002,0,1.>
```

Chains are unlinked automatically when someone stands.


## RUNNING EXTRA ANIMATIONS

You can create a Button that runs a set of animations ON TOP OF the currently playing animations. For example you can create a Button that makes everybody laugh at any time by adding the following line to *.SFconfig* notecard:

```
Button=All Laugh=ANIM{express_laugh;express_laugh;express_laugh}
```

to create a button to stop those animations, use the `STOPANIM` Shortcode instead of `ANIM`:

```
Button=All Laugh=STOPANIM{express_laugh;express_laugh;express_laugh}
```

Note that, unlike `EXPR{}`, you have to specify the full animation name here, and there is no repeat-time since the animations here are not repeatable


## AUTO TIMER DURATION

SFposer supports auto-timer that switches poses every X seconds. The menu option is under `Main`->`[Options]`.
You can specify the default auto timer duration (in seconds) in the *.SFconfig* notecard:
```
autoTimer=60
```
You can override the auto-timer duration for specific animations by using the shortcode `DURATION{50}`, which will set the current animation to last 50 seconds.


## ADVANCED SHORTCODES

Shortcodes like `GIVE{... }`, can be used either via Buttons (shown in the the `[Options]` menu) or by adding them to the pose line in a notecard.  The Shortcode-section of a notecard can contain multiple Shortcodes .For example, if you want a pose to both rez a `PROP{}` and run some animation add the following Shortcodes:

```
PROP{MyProp;<1,0,0>;<0,0,0>} ANIM{clap;clap;clap;clap}
```

The same Shortcodes can be used via a Button. The button is defined in the *.SFconfig* notecard with a single line as follows:

```
Button=MyButtonLabel=PROP{MyProp;<1,0,0>;<0,0,0>} ANIM{clap;clap;clap;clap}
```

This allows great flexibility to create many different types of objects without any effort or using addon scripts. Note that you can add only up to 6 Buttons in the `[Options]` menu

In addition to the Shortcodes described so far, the following Shortcodes are supported:

* `MSGPROP{MyProp;Hello, prop}` Sends the dataserver message "Hello, prop" to the already-rezzed prop MyProp using osMessageObject()
* `MSGATT{0;Hello, avatar1 attachment;19,4}` Sends the dataserver message "Hello, avatar1 attachment" to the attachments attached on attach points 19 or 4 of the avatar sitting on position 0 of the pose (first position) using `osMessageAttachments()`. You can read more on the documentation of osMessageAttachment online
* `MSGLINK{4;Hello link number 4}` Uses `osMessageObject()` to send the dataserver message "Hello link number 4" to the linked prim at link number 4
* `SAYCH{21;Hello, channel 21}` Uses `llSay()` to say the string "Hello, channel 21" to the local chat channel 21
* `LINKMSG{-1;99;Hello, all prims}` Uses `llMessageLinked(-1,99, "Hello, all prims" , <list-of-avatarIds> )` to send a link message. Remember **LINK_SET = -1**, **LINK_THIS=-4**

Arbitrary Buttons can be also created in the *.SFconfig* notecard that will send a link message when pressed. The syntax is
```
Button=My Button=<arbitrary string>
```
however the arbitrary string must not contain `=` . When pressed, the button will send the link message `llMessageLinked(LINK_THIS, 0, "<arbitrary string>|<currentUserUUID>", "<list-of-UUIDs>")`

By using Shortcodes and their combinations, it is easy to create advanced features such as turning on lights/controlling other objects/showing and hiding attached clothes/rezzing and derezzing additional objects etc. Remember, that you cannot have more than 6 addon/notecard  buttons.


## API COMMANDS

SFposer contains a powerful API system that is compatible with the PMAC API  therefore any scripts written for PMAC should work with SFposer. In addition it sends the message `GLOBAL_USER_SAT` when a user sits on the object.

The commands are sent to scripts in the object via LinkMessages (with number 0). SFposer can understand the `MAIN_REGISTER_MENU_BUTTON` and unregister commands that can be sent either via Link message or via dataserver event.


## OSSL PERMISSIONS

If you already have PMAC in your region, then you have already enabled all the functions that SFposer requires to operate

In case you need to update your .ini files here are some recommended settings

```ini
Allow_osGetNotecard = true
Allow_osMessageObject = true
Allow_osMessageAttachments = ESTATE_OWNER,ESTATE_MANAGER,PARCEL_OWNER
Allow_osAvatarPlayAnimation = ESTATE_OWNER,ESTATE_MANAGER,PARCEL_OWNER
Allow_osAvatarStopAnimation = ESTATE_OWNER,ESTATE_MANAGER,PARCEL_OWNER
Allow_osMakeNotecard = ESTATE_OWNER,ESTATE_MANAGER,PARCEL_OWNER
Allow_osNpcCreate = ESTATE_OWNER,ESTATE_MANAGER,PARCEL_OWNER
Allow_osNpcRemove = ESTATE_OWNER,ESTATE_MANAGER,PARCEL_OWNER
Allow_osNpcSit = ESTATE_OWNER,ESTATE_MANAGER,PARCEL_OWNER
Allow_osSetPrimitiveParams = ESTATE_OWNER,ESTATE_MANAGER,PARCEL_OWNER
```


## SF POSER SYSTEM PARTS:

* The `..SF poser` script
* The `~positioner` handle object
* The `~baseAnim` hip-fix animation
* The `.SFconfig` configuration notecard (optional)


## NOTECARDS FORMAT

SFposer uses the same notecard format as PMAC. Each set of animations (menu) goes in its own notecard which is named with the following convention:

```
.menu0005A Dance Together
```

where

* `.menu` : All pose notecards must begin with .menu
* `00`: Used for ordering of menus. Can be between 00-99
* `05`: Means this menu notecard contains poses for 5 avatars
* `A`: Menu is for use by (A)ll. Can also be (`G`)roup or (`O`)owner
* `Dance Together`: The label shown in the button is "Dance Together"

You do not need to create your own notecards , as they are created for you automatically via the menus.


## NOTES

Despite the name, SF poser is a generic animation controller and is not specific to SatyrFarm, i.e. it can be used for anything.


## LICENSE

(c) 2020 Satyr Aeon . Licensed under Creative Commons CC-BY-SA
