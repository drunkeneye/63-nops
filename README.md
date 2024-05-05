# create d64

# pack with exomizer 
rm release/*
./cruncher/exomizer sfx sys -x 1 -o release/63p_nops.prg ./bin/63p_nops.prg

# then create d64 
c1541 -format "63+ nops intro,23" d64 release/63+NOPS.d64 -attach "release/63+NOPS.d64" -write ./release/63p_nops.prg "63+ nops/[munia]"
zip -j release/Intro8k_munia_63+nops.zip ./release/63+NOPS.d64 ./release/63p_nops.prg ./info.txt



# copy over

aydin@lemon:~/Downloads/opencbm/OpenCBM-master$ d64copy -@xu1541 -d 0 -v -v -v ~/dropbox/c64/sources/bin/RELEASE.d64
./exomizer sfx sys  -x 1  -o compressed.prg  ./63p_nops.prg 


# pack 

Digitally delivered entries (no data carrier) should be submitted in ZIP archive with filename in the following template Compo_GroupOrNickname_EntryTitle.zip. Archive should contain info.txt file, with the same information.

in ./release

zip Intro8k_munia_63+nops.zip ./63+NOPS.d64 ./ ./info.txt


## OLD 

/Applications/VICE/VICE.app/Contents/Resources/bin/c1541 -format "20,23" d64 ./release/precrunch.d64 -attach ./release/precrunch.d64 -write ./bin/63p_nops.prg "m"  -write  "./cruncher/ikaricru.v9.3_dd" cruncher

     insert precrunch.d64
     load"cr*",8,1
     use m, n, $5000, $37 for start/01, use speed 4 (?=read some other info=best compression?)
     save d64 from emulator menu

/Applications/VICE/VICE.app/Contents/Resources/bin/c1541  -attach ./release/aftercrunch.d64 -read n "./release/crunched_intro"

/Applications/VICE/VICE.app/Contents/Resources/bin/c1541 -format "MUNIA" d64 release/RELEASE.d64 -attach release/RELEASE.d64 -write ./release/crunched_into" "63+ nops/[munia]"



