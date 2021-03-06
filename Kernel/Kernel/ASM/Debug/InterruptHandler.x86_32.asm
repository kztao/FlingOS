﻿; - - - - - - - - - - - - - - - - - - - LICENSE - - - - - - - - - - - - - - - -  ;
;
;    Fling OS - The educational operating system
;    Copyright (C) 2015 Edward Nutting
;
;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 2 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http:;www.gnu.org/licenses/>.
;
;  Project owner: 
;		Email: edwardnutting@outlook.com
;		For paper mail address, please contact via email for details.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  ;

BITS 32

SECTION .text

GLOBAL BasicDebug_RegistersESP:data
GLOBAL BasicDebug_CallerEBP:data
GLOBAL BasicDebug_CallerEIP:data
GLOBAL BasicDebug_CallerESP:data
GLOBAL BasicDebug_Enabled:data
GLOBAL BasicDebug_BreakIsInt1:data
GLOBAL BasicDebug_ReadAttempts:data

GLOBAL BasicDebug_InterruptHandler:function

EXTERN BasicDebug_ClearInt1TrapFlag
EXTERN BasicDebug_Execute

; BEGIN - BasicDebug_InterruptHandler

BasicDebug_RegistersESP dd 0
BasicDebug_CallerEBP dd 0
BasicDebug_CallerEIP dd 0
BasicDebug_CallerESP dd 0
BasicDebug_Enabled dd 0
BasicDebug_BreakIsInt1 dd 0
BasicDebug_ReadAttempts dd 1024 ; X = { X attempts (X != 0), Infinite attempts (X == 0) }

BasicDebug_InterruptHandler:

; Push all the general purpose register values
pushad

mov dword eax, [BasicDebug_Enabled]
cmp eax, 0
jz BasicDebug_InterruptHandler_End

; Store the value of esp so we can get the register values later
mov [BasicDebug_RegistersESP], esp
; Store the value of ebp (which is still the same as the method that was executing
; when the interrupt occurred) so we can look at arguments / locals values
mov [BasicDebug_CallerEBP], ebp

; Set ebp to esp
mov ebp, esp
; Go back past the push all to get to the interrupt data
add ebp, 32

; The last argument on stack is the return address
; For INT1, the "return address" is the EIP of the instruction that has just executed
; For INT3, the "return address" is the EIP of the instruction that will execute next
mov ebx, [ebp+0]

; So we work out whether this is an INT1 or INT3
; Debug Register 6, bit 14 indicates, if set, that it was INT1
; Get the DR6 value
mov eax, dr6
; Clear all but the bit we are interested in
and eax, 0x4000
; See if bit 14 is set
cmp eax, 0x4000
; If it is:
jne BasicDebug_InterruptHandler__End
mov dword [BasicDebug_BreakIsInt1], 1
BasicDebug_InterruptHandler__End:


; Now store the EIP value
mov [BasicDebug_CallerEIP], ebx

; Go back past EFLAGS, CS and EIP on the stack (pushed before the interrupt handler was called)
add ebp, 12
; Store caller ESP
mov [BasicDebug_CallerESP], ebp

mov eax, [BasicDebug_BreakIsInt1]
cmp eax, 1
jne BasicDebug_InterruptHandler_SkipInt1Stuff
; We need to clear the INT1 TF
; And reset the debug register
; Reload DR6
mov eax, dr6
; Clear the Int1 flag
and eax, 0xBFFF
; Reset DR6 by moving new value in
mov dr6, eax
; Clear the Int1 TF
call BasicDebug_ClearInt1TrapFlag
BasicDebug_InterruptHandler_SkipInt1Stuff:

; Call the main execute method
call BasicDebug_Execute

BasicDebug_InterruptHandler_End:

; Pop all the registers info - i.e. restore the execution state and stack
popad

IRet
; END - BasicDebug_InterruptHandler