
;; Autoloader
(defun StartupLispLoader ( lFiles / ; Input
    bAppend bIsGood ;--------------; Boolean
    sAllPaths sPath sPathSegment ;-; String
    sLine sCmdCore sCommands sFile ; String
    lPaths1 lPaths2 lReturn ;------; List
    lValidExtensions ;-------------; List
    iChar iLastChar ;--------------; Integer
    fcnLambda ;--------------------; Lambda
    FileID ;-----------------------; File
    ); Local variable declarations
    
    ;; Initializing
    (setq lValidExtensions (list ".lsp" ".vlx"))
    (setq sAllPaths (vlax-get (vlax-get (vlax-get 
        (vlax-get-acad-object) 'Preferences) 'Files) 'SupportPath
    ));setq <- vlax-get
    
    ;; Formatting the string paths
    (setq lPaths1 (vl-string->list sAllPaths))
    (setq sPath "" sPathSegment ";")
    (foreach iChar lPaths1
        (cond
            ;; Condition 1 - Divider symbol
            (   (= iChar 59); ";"
                (setq sPath (strcat sPath sPathSegment))
                (setq sPathSegment ";")
            ); Condition 1
            ;; Condition 2 - New path indicator
            (   (= iChar 58); Colon ":"
                (setq lPaths2 (cons sPath lPaths2))
                (setq sPath (strcat (substr sPathSegment 2) ":"))
                (setq sPathSegment "")
            ); Condition 2
            ;; Condition 3 - New path indicator
            (   (and (= iChar 92)(= iLastChar 92)); Double back slash "\\"
                (setq lPaths2 (cons sPaths lPaths2))
                (setq sPath (strcat (substr sPathSegment 2) "\\"))
                (setq sPathSegment "")
            ); Condition 3
            ;; Else -------- Add chacter to segment
            (   T
                (setq sPathSegment (strcat sPathSegment (chr iChar)))
            ); Else
        );cond
        (setq iLastChar iChar)
    );foreach
    (setq lPaths2 (cons (strcat sPath sPathSegment) lPaths2))
    (setq lPaths2 (cdr (reverse lPaths2)))
    
    ;; Progressive validation and modification
    (cond
        ;; Condition 1 - At least one valid support path is found.
        (   (or (<= (length lPaths2) 0)(null (vl-some 'findfile lPaths2)))
            (setq fcnLambda (function (lambda (sEntry) (strcat "\n" sEntry))))
            (setq lPaths2 (mapcar 'fcnLambda lPaths2))
            (setq sAllPaths (apply 'strcat lPaths2))
            (if (<= (length lPaths2) 0)(setq sAllPaths "\n[No paths were found]"))
            '(nil . (strcat 
                "StartupLispLoader needs at least one valid support path. "
                "The following paths do not exist:\n "
                sAllPaths
            ));list(quote) <- strcat
        ); Condition 1
        ;; Condition 2 - Finding a valid "Statup.lsp" file
        (   (progn
                (setq fcnLambda 
                    (function (lambda ( sEntry )
                        (strcat sEntry "\\startup.lsp")
                    ));function<-lambda
                );setq
                (setq lPaths1 (vl-remove-if-not 'findfile (mapcar 'fcnLambda lPaths2)))
                (<= (length lPaths1) 0)
            );progn
            (setq fcnLambda (function (lambda (sEntry) (strcat "\n" sEntry))))
            (setq lPaths2 (mapcar 'fcnLambda lPaths2))
            (setq sAllPaths (apply 'strcat lPaths2))
            '(nil . (strcat "A \"startup.lsp\" file needs to exist in one of these locations:\n " sAllPaths))
        ); Condition 2
        ;; Condition 3 - Proper input data type
        (   (if (= (type lFiles) 'LIST)(progn
                (setq fcnLambda (function (lambda (sEntry)(/= (type sEntry) 'STR))))
                (vl-some 'fcnLambda lFiles)
            ));if<-progn
            '(nil . "Input variable needs to be a list of one or more string variables.")
        ); Condition 3
        ;; Condition 4 - Valid file type
        (   (progn
                (setq fcnLambda (function (lambda (sEntry) 
                    (not (member (vl-filename-extension sEntry) lValidExtensions))
                )));setq <- function <- lambda
                (vl-some 'fcnLambda lFiles)
            );progn
            (setq fcnLambda (function (lambda (sEntry)(strcat ", " sEntry))))
            '(nil . (strcat 
                "Every input file need to have one of the following extensions: "
                (substr (apply 'fcnLambda lValidExtensions) 2) "."
            ));list(quote) <- strcat
        ); Condition 4
        ;; Condition 5 - File exists
        (   (not (findfile sFile))
            '(nil . "Input file does not exist.")
        ); Condition 5
        ;; Else -------- Updating startup.lsp file
        (   T
            (foreach sPath lPaths1 ;--; startup.lsp files
                (foreach sFile lFiles ; load [these] files
                    ;; Initializing
                    (setq lPaths2 (list))
                    (foreach iChar (vl-string->list sFile)
                        (if (= iChar 92)(setq lPaths2 (cons 92 lPaths2)))
                        (setq lPaths2 (cons iChar lPaths2))
                    );foreach
                    (setq sCommands (vl-list->string (reverse lPaths2)))
                    (setq sCmdCore (strcat "(load \"" sCommands "\")"))
                    
                    ;; Return type
                    (setq lReturn (cond
                        ;; Condition E-1 - Can the file be opened
                        (   (null (setq FileID (open sPath "r")))
                            (cons (cons nil sPath) lReturn)
                        ); Condition E-1
                        ;; Condition E-2 - Checking for existing match
                        (   (progn
                                (setq bAppend T)
                                (while (setq sLine (read-line FileID))
                                    (if (= (vl-string-trim " \t" sLine) sCmdCore)(setq bAppend nil))
                                );while
                                (setq FileID (close FileID))
                                (not bAppend)
                            );progn
                            (cons (cons T sPath) lReturn)
                        ); Condition E-2
                        ;; Else ---- E-E - Append and validate new line
                        (   T
                            (setq sCommands (strcat 
                                "(if (findfile \"" sCommands "\")\n"
                                "\t" sCmdCore "\n"
                                ");if"
                            ));setq<-strcat
                            (setq FileID (open sPath "a"))
                            (write-line (strcat "\n" sCommands) FileID)
                            (setq FileID (close FileID))
                            
                            ;; Verifying append succeeded
                            (setq bIsGood T)
                            (setq FileID (open sPath "r"))
                            (while (setq sLine (read-line FileID))
                                (if (= (vl-string-trim " \t" sLine) sCmdCore)(setq bIsGood nil))
                            );while
                            (setq FileID (close FileID))
                            (cons (cons bIsGood sPath) lReturn)
                        ); Condition E-3
                    ));setq<-cond
                );foreach
            );foreach
            (cons (vl-some 'car lReturn) lReturn)
        ); Else
    );cond
);StartupLispLoader
