partname = $(notdir $(shell pwd))

GENOPTS=--console_debugger=1 --fullscreen=1 demo.adf
COMPOPTS=--warp_mode=0
WARPOPTS=--warp_mode=1

default: A500-WARP

clean:
		rm -f build/demo.exe

prereqs:
	./precalcs.sh

demo:	clean prereqs
	vc -O0 -nocase -notmpfile -nostdlib -align -phxass -o ./build/demo.exe gerp.asm
	./tools/cranker-0.66_linux -f ./build/demo.exe -o ./build/demo-cranked.exe
	exe2adf -i ./build/demo-cranked.exe -a ./demo.adf 	

A500-MAX: 	demo
	fs-uae --amiga_model=A500 --kickstart_file=./build/rom/kick13.rom $(COMPOPTS) uae_cpu_speed=max $(GENOPTS)

A500-COMP:	demo
	fs-uae --amiga_model=A500 --kickstart_file=./build/rom/kick13.rom $(COMPOPTS) $(GENOPTS)

A500-WARP:	demo
	fs-uae --amiga_model=A500 --kickstart_file=./build/rom/kick13.rom $(WARPOPTS) $(GENOPTS)

A500-WINDOW:	demo
	fs-uae --amiga_model=A500 --kickstart_file=./build/rom/kick13.rom $(COMPOPTS)

A1200-COMP:	demo
	fs-uae --amiga_model=A1200 --kickstart_file=./build/rom/kick30.rom $(COMPOPTS) $(GENOPTS)

A1200-WARP:	demo
	fs-uae --amiga_model=A1200 --kickstart_file=./build/rom/kick30.rom $(WARPOPTS) $(GENOPTS)

A1200-FAST:	demo
	fs-uae --amiga_model=A1200 --kickstart_file=./build/rom/kick30.rom $(WARPOPTS) --fast_memory=4096 $(GENOPTS)

