# 63+ NOPs intro

These are the sources for the 63+ NOPs intro, programmed by MUNIA, presented at the Democrunch 2023.


## Compile

Compiling should be done with Kick Assembler. After this, first crunch the binary with exomizer

```./cruncher/exomizer sfx sys -x 1 -o release/63p_nops.prg ./bin/63p_nops.prg```

then create the d64 

```c1541 -format "63+ nops intro,23" d64 release/63+NOPS.d64 -attach "release/63+NOPS.d64" -write ./release/63p_nops.prg "63+ nops/[munia]"```

 

