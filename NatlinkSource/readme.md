# Goal

Create a minimal working version of Natlink a dragonspeak to python API. The immediate goal is to
create a more reliable 32-bit python 3.8 or later for dragon 15+ implementation that is easy to compile, understand and 
contribute to.

 

Later on the python 3 port as well as x64 support may be added. 
# important developer notes

natlink runs as  a COM object hosted in a windows service.

If you are a developer or finding natlink just hangs and you want to debug:
- check that the Dragon Service Properties, Log On tab,  has the Local System Account as the Log on as, 
and "Allow service to interact with the desktop" 
is checked.
- make sure any Command Shell or Power Shell sessions are opened with administrator privileges (i.e. "run as administrator").  
Otherwise the regsvr32 command will fail without any useful error messages.


#Installation Instructions.

IF you are building natlink.pyd locally with Visual studio, the easiest way to have dragon use your natlink.pyd is:
- make sure you have registered natlink already with `natlinkconfig_cli -r` or use the `natlinkconfig` GUI.
- simply copy the natlink.pyd you build (it will be n the debug Folder) to your python Lib/site-packages/natlinkcore folder.  No need to re-register.

# Important

Please avoid  goofing with the Visual Studio settings to customize to your local machine.  It needs to build
without confusion on any workstation. Your Python include header and lib files are found using an environment variable.

There is a DRAGON_15 set in the preprocessor section of Visual Studio.  If that is not set, there is a UNICODE
preprocessor varaible that will have the wrong value during compile and natlink will crash at runtime.

# Developer workflow

See compile instructions below.

You must install natlinkcore with flit or pip or some of the developer workflow will not work.  natlinkcore includes
some command lines and powershell scripts that are required.

Register natlink and get it working.  If you would like to use the command line, in an elevated commmand or powershell run:

`natlinkconfig_cli -r'.  Or run the GUI `natlinkconfig` from an elevated shell or as adminstrator from
Windows Explorer.   These programs will bein your Python   Scripts folder.


Once you compile the binaries will be in Debug/natlink.pyd (it is a DLL with a .pyd extension) and the debug symbols in Debug/natlink.pdb.

You do not need to reregister these binaries.  Just overwrite the binaries in your Python Lib/site-packages/natlinkcore.

The easiest way to do that is to start a Power Shell, and navigate to the folder where you checked natlink out of
git.  That folder is the parent of natlinksource, src, and has a few powershell scripts.  Keep that 
powershell open.  

An easy way to do this is to right click on "natlink" in the Solution Explorer and select "Open in Terminal".
It should open a Developer Powershell in natlinksource.  `cd ..` to move up one folder.

```
PS C:\Users\dougr\OneDrive\doug\codingprojects\dt\natlinkkb100\natlink> .\cpnatlink.ps1
Natlink binary C:\Users\dougr\OneDrive\doug\codingprojects\dt\natlinkkb100\natlink\NatlinkSource\Debug\natlink.pyd
copied natlink.dll and natlink.pyd to c:\python38-32\Lib\site-packages\natlinkcore
PS C:\Users\dougr\OneDrive\doug\codingprojects\dt\natlinkkb100\natlink>
```

You must exit Dragon before running cpnatlink or you will get  errors.

 


# Compile instructions

** Create a user environment variable "Natlink_Python" pointing to where you installed Python for natlink. If you have installed 
natlink already with pip, you can run pye_prefix to get the location if you don't know it:
```...\natlink> pye_prefix
c:\python38-32
```


Currently only tested on windows 
- Install VisulStudio 2022 or later and ensure that you are also installing C++ support (Desktop Develpment with C++).  You can 
no longer use VisualStudio 2019.  During debugging the project was upgraded as bugs were suspected in VS 2019 (erroneously.).  

- Install python 3.8 **32  bit build** on your computer, **for all users**.  it is a good idea to install it 
   at c:\python38-32 rather than in c:\Program files (x86)\ to reduce the directory navigation requirements.  
   Be sure the C:\Python38-32 and C:\Python38-32\Scripts
   are in your system path - either with the correct options at install time or edit the system path yourself.
 
 
- upgrade pip right away as  a good practice
- `pip install --upgrade pip`

Currently there are no package prequisites for building natlink.
 
 
Clone the natlink project with git to your computer if you haven't already.


 
The visual studio solution project file natlink.vxproj.  

  **At this time python virtualenvs are not supported for natlink building or deployment**
 

Double click on it natlink.vxproj with Visual Studio 2022.  

You should be able to build natlink.pyd.
It will appear in a   Debug subfolder.  See the workflow section above for how to 
use it as your natlink.pyd.

IF you want to include it in a package for others to use,  rename it natlink_VV_Verxx.pyd as is the 
convention in src/natlinkcore/PYD.  

 
# Program flow


The compiled library natlink.pyd/natlink.dll is registered with natspeak as a COM-Server support module.
 This causes our library to be loaded through the COM-Interface whenever Dragon started.
 During the initialization of the library a Python interpreter it started which in turn loads the natlink python modules.
 All of this only starts python process to actually talk to dragons natspeak we need to go back into the library. 
 Dragon itself provides a COM-Server which we can call from the C++ libary. 
 These calls are wrapped into a Python/C API by the same library that just started the python process. 
 So the python process pulls back into that very same library to talk to natspeak.
 
 **TODO** Currently I am not sure how callbacks when a grammar is recognised by natspeak are handled.
 
 ### Support module registration
 
 the natlink class id is  `dd990001-bb89-11d2-b031-0060088dc929`.  


Note, natlinkconfigfunctions/natlinkconfigfunctions_cli do the registration as documented below:

 First we need to register our COM-Server with the windows registry. To do pass the dll/pyd to `regsvr32`. 
 Windows will associate the Natlink classid    
 which will set the ``HKEY_LOCAL_MACHINE\SOFTWARE\Classes\WOW6432Node\CLSID\{clsid}\InprocServer32``for x64 systems.
 
 Then we need to inform dragon of the new module by modifying the appropriate ini files. 
 
 this is done via the natlinkconfig_cli command or the natllinkconfig gui.   
  ```
[.Natlink]
App Support GUID={class id}
```
 to `C:\ProgramData\Nuance\NaturallySpeaking15\nsapps.ini` which also gives the module the identifier `.Natlink`
 
 We can then activate/deactivate our support Module by either adding or removing `.Natlink=Default` it from the 
 `[Global Clients]:` section of :  `C:\ProgramData\Nuance\NaturallySpeaking15\nssystem.ini`
 As far as I can tell the value to the `.Natlink` key is irrelevant.
 
 **TODO** figure out where the registration currently/previously takes place. I currently assume that it is 
 in``confignatlinkvocolaunimacro/natlinkconfigfunctions.py`` line 1045: ``registerNatlinkPyd()``
 
 ### COM-Server implementation

``CDgnAppSupport.cpp``  (used to be in ``appsupp.h/appsupp.cpp``)

Apparently we do not have access to the IDL (interface definition language) files. 

Indentation is important in the .reg file! I also remove my comments now .dll should work.

These files seem to implement the support interface defined in ``COM/dspeech.h``.

**TODO** The whole interface definition is littered with typdef. So I should go through and try to understand which methods are actually defined and what they do.
 
 ### DLL initialization and python Interpreter 
 ### COM-Python Wrapper

this section needs updating/correcting.
  
 The python natlink module is added to ``HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Python\PythonCore\2.7\PythonPath``
 as a Key/Subentry(?). This allows the sys module loader to find natlinkmain module.
 
 As this library is loaded as support-module the working directory during runtime is that of the dragon system and
 not the location of the library. Thus our python-module that we want to load from the library has to be
 found through the `sys.path`.