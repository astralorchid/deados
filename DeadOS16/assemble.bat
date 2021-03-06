cd bin
nasm ../boot.asm -f bin -o boot.bin
nasm ../kernel.asm -f bin -o kernel.bin
nasm ../programs/terminal.asm -f bin -o terminal.bin
nasm ../programs/textedit.asm -f bin -o textedit.bin
nasm ../programs/test.asm -f bin -o test.bin
copy /b boot.bin+kernel.bin+terminal.bin+textedit.bin os.flp
qemu-system-x86_64 -drive format=raw,file=os.flp
cd ..
