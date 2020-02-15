Config { 
    font = "xft:CaskaydiaCove Nerd Font:pixelsize=14",
    additionalFonts = [ "xft:FuraCode Nerd Font:pixelsize=14" ],
    bgColor = "#000000",
    fgColor = "#ffffff",
    position = TopW L 100,
    lowerOnStart = True,
    commands = [
         Run Weather "EGSC" ["-t","<station>: <tempC><fn=1>°</fn>C, <rh>%, <windKmh>km/h","-L","18","-H","25","--normal","green","--high","red","--low","lightblue"] 36000
        ,Run Memory ["-t","<used>M (<cache>M)","-H","12000","-L","4000","-h","red","-l","green","-n","yellow"] 10        
        ,Run DynNetwork [
             "-t"    ,"rx:<rx> | tx:<tx>"
            ,"-H"   ,"1000000"
            ,"-L"   ,"100000"
            ,"-h"   ,"red"
            ,"-l"   ,"green"
            ,"-n"   ,"yellow"
            , "-c"  , " "
            , "-w"  , "7"
            , "-S"  , "True"
            ] 10
        ,Run Date "%Y.%m.%d %H:%M:%S" "date" 10
        ,Run MultiCpu [ "--template" , "<fn=1><autovbar></fn>"
            , "--Low"      , "10"         -- units: %
            , "--High"     , "85"         -- units: %
            , "--low"      , "gray"
            , "--normal"   , "yellow"
            , "--high"     , "red"
        ] 10
        ,Run CoreTemp [ "--template" , "<core0><fn=1>°</fn>C"
            , "--Low"      , "70"        -- units: °C
            , "--High"     , "80"        -- units: °C
            , "--low"      , "green"
            , "--normal"   , "orange"
            , "--high"     , "red"
        ] 50
        ,Run StdinReader
    ],
    sepChar = "%",
    alignSep = "}{",
    template = "%StdinReader% }{ %multicpu% | %coretemp% | %memory% | %dynnetwork% | %EGSC% | <fc=yellow>%date%</fc> "
}
