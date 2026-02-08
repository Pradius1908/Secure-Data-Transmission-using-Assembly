"# Secure-Data-Transmission-using-Assembly"



HOW TO RUN



1. Open two MSDOS Windows
2. Run following in both MSDOS windows



 	mount c: C:/Users/pradi/Downloads/Packet

 	c:



3\. IF .com files iare empty, ensure you have NASM assembler

   and run these lines of code in cmd:



 	nasm -f bin sender.asm -o sender.com

 	nasm -f bin receiver.asm -o receiver.com


4\. In one window, run sender, in other window run receiver.


5\. ALWAYS RUN RECEIVER FIRST


ADDITIONAL (HOW TO INSTALL NASM)
    - run cmd as admin and run: winget install nasm -i
    - find the location of NASM, copy directory
    - go to environment variables and add to path
    - then run the nasm commands in cmd
 

