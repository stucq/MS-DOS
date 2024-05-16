; BOOT.ASM
;
; The boot routine for DOS. This is loaded onto track 0, sector 1; it was
; designed to work with the SCP monitor, not the BIOS of the IBM PC. However,
; it can be configured with little effort to work on an IBM PC or compatible
; device by changing some of the equates here.

; Constants; DO NOT change these.

SECTSIZE	EQU	80H		; The size of a single sector.

; Choose ONE disk type to target the boot routine for.

CSMALL		EQU	0		; Cromemco 4FDC with small disks
CLARGE		EQU	1		; Cromemco 4FDC with large disks
TSING		EQU	0		; Tarbell single-density controller
TDBL		EQU	0		; Tarbell double-density controller

; Choose (a) where this bootloader is loaded in memory, and (b) where it should
; load the kernel in memory. The defaults are optimized for the SCP monitor, but
; this will work fine with an IBM PC too if these are changed a bit.

KRNLPOS		EQU	400H		; Load the kernel at this address
KRNLSEG		EQU	40H		; Load the kernel at this segment
KRNLSIZE	EQU	33H		; Size of the kernel in sectors
BOOTPOS		EQU	200H		; Where the bootloader is in memory

; Generic macros formed from combining these configuration options.

CROMEMCO	EQU	CSMALL+CLARGE	; Cromemco disk
TARBELL		EQU	TSING+TDBL	; Tarbell disk

WD1771		EQU	CROMEMCO+TSING	; WD1771 controller
WD1791		EQU	TDBL		; WD1971 controller

SMALL		EQU	CSMALL		; Small disk
LARGE		EQU	CLARGE+TARBELL	; Large disk

		%IF	SMALL
MAXSECT		EQU	12H		; Sectors per track (Small disks)
		%ELIF	LARGE
MAXSECT		EQU	1AH		; Sectors per track (Large disks)
		%ENDIF

		%IF	TARBELL
DONEBIT		EQU	80H		; Mask to check for DONE (Tarbell)
DISK		EQU	78H		; I/O port of the disk (Tarbell)
		%ELIF	CROMEMCO
DONEBIT		EQU	1H		; Mask to check for DONE (Cromemco)
DISK		EQU	30H		; I/O port of the disk (Cromemco)
		%ENDIF

		%IF	WD1771
READCMD		EQU	88H		; Read command (WD1771)
		%ELIF	WD1781
READCMD		EQU	80H		; Read command (WD1791)
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
