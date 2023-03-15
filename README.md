# Startup-Autolisp-Loader

This code was written in VSCode with DraftSight 2023 SP1 as the cad application. Newer versions and different cad applications may result in the code to not work as intended. 

This file is designed to populate the "startup.lsp" file for any cad program through AutoLisp. If an issue occurs while running the code, then the code is designed to navigate the developer to the location where the root of the problem is located. 

Setup instructions:
1) Download the "Startup Autolisp Loader.lsp" file.
2) Load the file into the cad application.
3) Call the AutoLisp script as '(StartupLispLoader (list "Path1\\Name1.lsp" "Path2\\Name2.lsp" ...))'.
4) The program will return a list variable. A "nil" indicates an error and "T" indicates either complete or partial success. In the case of a parial success, then more than one "startup.lsp" was found, but only some of them allowed for writing privileges. 
5) A list is returned with success/fail, fail number, and description / details of results.

Error Codes: Cad application fault
1) The first issue that is detected is if the folder paths to the startup.lsp file are valid. If this fails, then dive into the options to find the relevant support paths, run '(getenv "CADSUP")' or "(vlax-get (vlax-get (vlax-get (vlax-get-acad-object) 'Preferences) 'Files) 'SupportPath)" or "(vla-get-SupportPath (vla-get-Files (vla-get-Preferences (vlax-get-acad-object))))" to see the file paths. Modify the application to view valid directories.
2) None of the directories have a "startup.lsp" file. Create a file in one of the directories to clear this error. WARNING: If the file is not writable when the script is called, then an Output Error will trigger either a parital success condition or complete failure.

Error Codes: Developer input
3) An invalid variable type was supplied in the input. Either the file names are not a string type variable or the group of files are not in a list type variable. Both trigger the same error message.
4) Checks the extension of each of the supplied files with the list built into the code. See "lValidExtensions" variable at the start of the code if an extension needs to be added. If a single match fails, then the error is triggered. 
5) Checks the existance of each of the supplied directories and files. If a single file does not exist, then a general error is thrown. 

Error Codes: Output Errors
6) At least one of the "startup.lsp" files was write protected, and at least one file was writable.
7) All of the "startup.lsp" files were write protected.

Error Code Zero:
0) No errors occured. Every "startup.lsp" file was modified.

This code does NOT maintain the "startup.lsp" file. A simple check for the existance of the supplied file is used prior to trying to load the file. 
