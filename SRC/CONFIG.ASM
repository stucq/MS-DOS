; CONFIG.ASM: Platform-specific configuration options.
; Disassembled as a part of DOS-RE.
;
; This is included in all DOS kernel code, as it provides helpful macros and
; equates that generalize certain hardware functions between different devices
; that DOS is assembled for.

; Constants; DO NOT change these.

SECTSIZE	EQU	80H		; The size of a single sector.

; Choose ONE disk type to target DOS for.

CSMALL		EQU	0		; Cromemco 4FDC with small disks
CLARGE		EQU	1		; Cromemco 4FDC with large disks
TSING		EQU	0		; Tarbell single-density controller
TDBL		EQU	0		; Tarbell double-density controller

; Generic macros formed from combining these configuration options.

CROMEMCO	EQU	CSMALL+CLARGE	; Cromemco disk
TARBELL		EQU	TSING+TDBL	; Tarbell disk

WD1771		EQU	CROMEMCO+TSING	; WD1771 controller
WD1791		EQU	TDBL		; WD1971 controller

SMALL		EQU	CSMALL		; Small disk
LARGE		EQU	CLARGE+TARBELL	; Large disk

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
