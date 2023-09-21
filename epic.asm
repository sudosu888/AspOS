org 0x7C00 ; add 0x7C00 to label address
bits 16	   ; tell the assembler we want 16-bit code.

	mov ax, 0 ; set up segments
	mov ds, ax
	mov es, ax
	mov ss, ax 	; set up the stack
	mov sp, 0x7C00  ; stack grows downwards from 0x7C00

	mov si, startnl
	call print_string

	mov si, welcome
	call print_string

mainloop:
	mov si, prompt
	call print_string

	mov di, buffer
	call get_string

	mov si, buffer
	cmp byte [si], 0 ; blank line?
	je mainloop	 ; yes, ignore it.

	mov si, buffer
	mov di, cmd_hi	 ; hi command
	call strcmp
	jc .helloworld

	mov si, buffer
	mov di, cmd_help ; "help" command
	call strcmp
	jc .help

	mov si, buffer
	mov di, cmd_penis ; the funny "penis" command
	call strcmp
	jc .penis

	mov si, buffer
	mov di, cmd_clear ; clear the terminal
	call strcmp
	jc .clear

	mov si, badcommand
	call print_string
	jmp mainloop

.helloworld:
	mov si, msg_helloworld
	call print_string

	jmp mainloop

.help:
	mov si, msg_help
	call print_string

	jmp mainloop

.penis:
	mov si, msg_penis
	call print_string

	jmp mainloop

.clear:
	mov cl, 0x00		; set starting point for cl
.clsloop:
	mov si, msg_clear
	call print_string
	inc cl			; increment cl

	cmp cl, 0xFF		; keep looping until cl is = to 0xFF
	jne .clsloop

	cmp cl, 0xFF		; once equal, return to the main loop
	jge mainloop

;
; Commands & output
;
startnl db " ", 0x0D, 0x0A, 0
welcome db "Welcome to my OS!", 0x0D, 0x0A, 0
msg_helloworld db "Finally, hello OSDev World!!", 0x0D, 0x0A, 0
badcommand db "Invalid input.", 0x0D, 0x0A, 0
prompt db ">", 0
cmd_hi db "hi", 0
cmd_help db "help", 0
cmd_penis db "penis", 0
cmd_clear db "clear", 0
msg_clear db " ", 0xD, 0xA, 0
msg_penis db "VAGINA", 0xD, 0xA, 0
msg_help db "Commands: hi, help, clear", 0x0D, 0x0A, 0
buffer times 64 db 0

;
; system calls start here
;

print_string:
	lodsb	; grab a byte from si

	or al, al ; logical OR al by itelf
	jz .done  ; If the result is zero, get out.

	mov ah, 0x0E
	int 0x10  ; otherwise, print the character.

	jmp print_string

.done:
	ret

get_string:
	xor cl, cl ; logical XOR cl by itself.

.loop:
	mov ah, 0
	int 0x16 ; wait for keypress

	cmp al, 0x08	; backspace
	je .backspace

	cmp al, 0x0D 	; enter
	je .done	; yep, we're done.

	cmp cl, 0x3F	; Limit input to 63 characters
	je .loop	; Limit to backspace and enter.
	mov ah, 0x0E
	int 0x10	; print out character.

	stosb		; put character in buffer.
	inc cl
	jmp .loop

.backspace:
	cmp cl, 0	; beggining of string?
	je .loop	; yes, ignore the key.

	dec di
	mov byte [di], 0 ; delete character
	dec cl

	mov ah, 0x0E
	mov al, 0x08
	int 0x10	; backspace on the screen.

	mov al, ' '
	int 0x10	; blank out character.

	mov al, 0x08
	int 0x10	; backspace again.

	jmp .loop	; go to the main loop.

.done:
	mov al, 0 	; null terminalor
	stosb

	mov ah, 0x0E
	mov al, 0x0D
	int 0x10
	mov al, 0x0A
	int 0x10	; newline.

	ret

strcmp:
.loop:
	mov al, [si]	; grab a bye from SI
	mov bl, [di]	; grabe a byte from DI
	cmp al, bl	; are they equal?
	jne .notequal	; Nope, we're done!

	cmp al, 0	; are both bytes null?
	je .done	; yep.

	inc di
	inc si
	jmp .loop	; LOOPS!!!!!!

.notequal:
	clc 		; not equal, clear the carry flag.
	ret

.done:
	stc		; equal, set the carry flag.
	ret

	times 510-($-$$) db 0
	dw 0xAA55	; some BIOSes require this for some reason.
