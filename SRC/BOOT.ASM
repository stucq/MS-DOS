; BOOT.ASM: The boot routine for DOS.
; Disassembled as a part of DOS-RE.
;
; This is loaded onto track 0, sector 1; it was designed to work with the SCP
; monitor, not the BIOS of the IBM PC or compatible devices. However, it can be
; configured with little effort to work on an IBM PC or a compatible device by
; changing some of the equates here.

%INCLUDE	"CONFIG.ASM"

; Choose (a) where this bootloader is loaded in memory, and (b) where it should
; load the kernel in memory. The defaults are optimized for the SCP monitor, but
; this will work fine with an IBM PC too if these are changed a bit.

KRNLPOS		EQU	400H		; Load the kernel at this address
KRNLSEG		EQU	40H		; Load the kernel at this segment
KRNLSIZE	EQU	33H		; Size of the kernel in sectors
BOOTPOS		EQU	200H		; Where the bootloader is in memory

; Generic macros formed from combining these configuration options.

		%IF	SMALL
MAXSECT		EQU	12H		; Sectors per read (Small disks)
		%ELIF	LARGE
MAXSECT		EQU	1AH		; Sectors per read (Large disks)
		%ENDIF

		%IF	CLARGE
WAITBYTE	EQU	0B1H		; Hardware WAIT command (Large disks)
		%ELIF	CSMALL
WAITBYTE	EQU	0A1H		; Hardware WAIT command (Small disks)
		%ENDIF

		ORG	BOOTPOS

BOOT:		XOR	AX,AX
		MOV	DS,AX
		MOV	ES,AX
		MOV	SS,AX
		MOV	SP,BOOT

		CLD

		MOV	DI,KRNLPOS
		MOV	DX,KRNLSIZE
		MOV	BL,2H

SECT:		MOV	AL,0D0H		; Force Interrupt (Type I)
		OUT	DISK,AL

		AAM

		DB	82H,0FBH	; This usually encodes as 80FB, but we
		DB	MAXSECT+1H	; want 82FB, hence the hack

		JNE	NOSTEP

		MOV	AL,58H		; Step In With Update (Type I)
		CALL	DONECMD
		MOV	BL,1H

NOSTEP:		DB	8AH,0C3H	; This usually encodes as 88D8, but we
					; want 8AC3, hence the hack
		OUT	DISK+2,AL

		%IF	CROMEMCO
		MOV	AL,WAITBYTE	; Enable hardware wait on Cromemco
		OUT	DISK+4,AL
		%ENDIF

		IN	AL,DISK		; Get status
		NOT	AL
		AND	AL,20H
		JZ	OUTCMD
		MOV	AL,4H

OUTCMD:		OR	AL,READCMD
		OUT	DISK,AL		; Read from disk
		MOV	CX,SECTSIZE
		PUSH	DI

READSECT:	IN	AL,DISK+4	; Read from disk
		TEST	AL,DONEBIT	; Check if done reading

		%IF	TARBELL
		JZ	DONE
		%ELIF	CROMEMCO
		JNZ	DONE
		%ENDIF

		IN	AL,DISK+3
		STOSB
		LOOP	READSECT	; Read to the end of the sector

DONE:		POP	DI
		CALL	GETSTAT
		AND	AL,9CH
		JNZ	SECT		; Not done yet...
		ADD	DI,SECTSIZE
		INC	BL
		DEC	DX
		JNZ	SECT		; Not done yet...
		JMP	KRNLSEG:0H	; We're done reading, make the jump!

DONECMD:	OUT	DISK,AL
		AAM

GETSTAT:	IN	AL,DISK+4
		TEST	AL,DONEBIT

		%IF	TARBELL
		JNZ	GETSTAT
		%ELIF	CROMEMCO
		JZ	GETSTAT
		%ENDIF

		IN	AL,DISK
		RET
