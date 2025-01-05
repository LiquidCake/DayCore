# DayCore
DayCore is a World of Warcraft 1.12 (Vanilla/Turtle WoW) addon that introduces a PvP-friendly semi-hardcore experience by locking a character for a certain amount after it dies.  

Character is blocked only temporarily (by default), and one also requires discipline not to unlock it manually. But such gameplay mode could be an interesting alternative to real hardcore for players that want to add some intensity and immersion to their gameplay, while not having to start all over again each time, want to play with enabled PvP or just to be immune to death caused by lag or bugs.  

After installation, DayCore starts to watch your character and when it dies - addon shows a death screen that blocks controls. After a short delay, an opaque background is shown, and will block the view until the death timer ends (12 hours by default). Then you can play that character normally again.  
Death screen contains (if not disabled) a self-appeal "captcha" text that allows you to unblock a character instantly with zero consequences - this is useful when you died because of non-gameplay reasons like internet issue or just during some open-world PvP.  

Death tracking is (by default) completely disabled while in party (so you can group up with softcore players) and/or in certain "ignored" locations - by default location list contains all battleground location names in EN locale, including Turtle WoW Sunnyglade Valley and Blood Ring. You can extend list by editing `DayCore.lua`.  

![deathscreen](https://github.com/user-attachments/assets/6df42097-d548-416a-99fd-476a6de621a9)

### Commands:  
```
/daycore                      - print info and commands list
/daycore enableinparty        - enable death tracking while in party
/daycore disableinparty       - disable death tracking while in party
/daycore enableappeal         - enable self-appeal on death screen
/daycore disableappeal        - disable self-appeal on death screen
/daycore changeblockhours XXX - set death block hours value (1 - 9999999)
```
Also, you can change some configuration by editing `DayCore.lua` file (see "configuration" section at the top)  

### Installation
As usual - download addon files as zip file, unpack, make sure files are put into a directory named exactly "DayCore"
