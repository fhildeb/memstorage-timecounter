;----------------------------------------------------------------------------------------
; Programmieraufgabe 1: "Timergesteuerter Zaehler Ohne Interrupt"
;----------------------------------------------------------------------------------------
                   org 100h

;Benoetigte Displayanzeigen:
valueseg:          equ 9eh		;Portnummer der 7-Segment-Anzeige fuer die Ausgabe
                                        ;des WerteBereichs der Zeit samt Null

counterseg:        equ 98h	        ;Portnummer der 7-Segment-Anzeige fuer die Ausgabe
                                        ;der Haeufigkeit, des gesuchten Wertes

firstseg:          equ 90h              ;Portnummer der 7-Segment-Anzeige fuer die erste
                                        ;Displaystelle die gecleared werden muss

lastseg:           equ 9eh              ;Portnummer der 7-Segment-Anzeige fuer die letzte
                                        ;Displaystelle die gecleared werden muss

sekundenseg:       equ 94h              ;Portnummer der 7-Segment-Anzeige fuer die
                                        ;Stelle des Uebergangs von Sekunden zu MS

timerseg:          equ 96h              ;Portnummer der 7-Segment-Anzeige fuer den Timer
                                        ;der Herunterzaehlt mit Sekunden.MS

timeseg:           equ 9ch              ;Portnummer der 7-Segment-Anzeige fuer die Ausgabe
                                        ;der Zeit

trennseg:          equ 01000000b        ;Portnummer der 7-Segment-Anzeige fuer den Trennstrich
                                        ;zwischen Value und Timer

millisekunden:     equ 18432            ;zeitkonstante fuer 10-ms-interrupt
isrmodus:          equ 01110110b        ;steuerwort: binaerzaehler, mode3, low+hi, timer1

init:              cli
                   call clrdsp          ;bisherige anzeigeinhalte loeschen
                   mov al,2             ;wecker auf neukonfigurationsmodus setzen
                   mov [stat],al
                   mov ax,0

start:             ;initialisierung
                   call ivtabinit       ;vektortabelle
                   call picinit         ;interruptcontrollers
                   call pitinit         ;zeitgeberschaltkreises

;hauptprogramm
;-------------
hintergrund:       cli			;interrupts sperren

;***** programm                         ; schalter einlesen und auswerten

start_prog:        mov al,[stat]
                   cmp al,0             ;bei abgelaufener zeit in schleife halten
                   jne durchlauf
neustartcheck:     cli                  ;bei abgelaufener zeit interrupts sperren
                   in al,0              ;schalterstellung einlesen und pruefen, ob s7 noch aktiviert ist
                   test al,80h
                   jz init              ;neue konfiguration ermoeglichen
                   jmp start_prog       ;sonst dauerhaft eee-0000 anzeigen

durchlauf:         in al,0              ;schalterstellung einlesen
                   push ax

                   and al,01111111b
                   daa                  ;in bcd-zahl umwandeln
                   mov dx,timeseg           ;auf linker displaystelle anzeigen lassen
                   call show2
                   mov dx,9eh
                   mov al,ah            ;fuehrende null anzeigen
                   call show1

                   pop ax
                   test al,80h          ;test, ob s7 aktiv -> timerstart?
                   jz hintergrund
                   sti			;interrupts freigeben

                   cmp [stat],byte 2    ;wenn wecker im konfigurationsmodus, eingelesene sekundenzahl einmalig initialisieren
                   jne start_prog

weckerstart:       call startcounter    ;zeit neu initialisieren
                   jmp start_prog


;up zum initialisieren der hundertstel- und sekunden-variable
;parameter: al - schalterstellung als 8-bit-zahl; rueckgabewerte: keine
;-----------------------------------------
startcounter:      push ax

                   and al,7fh           ;aus eingabe s7 filtern
                   daa                  ;in bcd-zahl umwandeln
                   mov [seku],al        ;sekunden mit dieser bcd-zahl initialisieren
                   mov [husk],byte 0
                   mov [stat],byte 1    ;timer einschalten, freie konfiguration stoppen

                   pop ax
                   ret

;interruptserviceroutine
;-----------------------
isr8:   push ax             ;register retten

;***** isr-programm
        call zaehler        ; zeit (eine einheit weiter)
        call anzeige        ; anzeige auf display

isrret: mov al,20h
        out 0c0h,al         ;pic wieder freigeben

        pop ax              ;register wiederherstellen
        iret


;up zum dekrementieren der hundertstel-sekunden
;parameter: keine; rueckgabewerte: keine
;--------------------------------------
zaehler:           push ax

                   mov al,[husk]        ;hundertstel-sekunden laden
                   dec al               ;und dekrementieren
                   das

                   cmp al,99h            ;wenn bei kleiner 0 angekommen
                   jne husesichern

                   call sekundencounter ;bei 0 die sekunden aendern
                   jmp return

husesichern:       mov [husk],al        ;sonst neuen sekundenwert abspeichern

return:            pop ax
                   ret

;up zum dekrementieren der sekunden
;parameter: keine; rueckgabewerte: reset der hundertstel auf 10
;-------------------------------
sekundencounter:   push ax
                   mov al,[seku]        ;sekunden laden
                   dec al               ;um eins dekrementieren
                   das                  ;hexzahl in bcd-zahl umwandeln
                   cmp al,99h           ;test, ob wecker bei 0 angekommen it
                   je weckerstopp

                   mov [seku],al        ;neuen wert abspeichern

                   mov al,99h           ;hundertstel-sekunden neu initialisieren
                   mov [husk],al

                   jmp return3

weckerstopp:       mov [stat],byte 0    ;timer abschalten und keine werte speichern
                   cli                  ;interrupts nicht mehr zulassen

return3:           pop ax
                   ret

;up zum anzeigen der hundertstel- und sekunden auf der 7-segment-anzeige
;parameter: keine; rueckgabewerte: keine
;-------------------------------
anzeige:           push ax
                   push dx

                   push cx

                   mov dx,counterseg          ;an 4. stelle ein minus anzeigen
                   mov al,trennseg
                   out dx,al

                   mov al,[seku]       ;nach dem minus die sekunden anzigen
                   mov dx,sekundenseg
                   mov cl,0ffh
                   call show2

                   mov cx,0
                   mov al,ah           ;fuehrende null anzeigen
                   mov dx,timerseg
                   call show1

                   mov al,[husk]       ;nach den sekunden die hundertstel-sekunden zeigen
                   shr al,1            ;nur erste stelle (zehntel-sek.) anzeigen
                   shr al,1
                   shr al,1
                   shr al,1
                   mov dx,firstseg
                   call show1

                   pop cx

                   pop dx
                   pop ax
                   ret


;interruptcontroller initialisieren
;-------------------------------
picinit: push ax
         in al,0c2h       ;lesen des int.-maskenregisters des pic
         and al,11111110b
         out 0c2h,al
         pop ax
         ret

;zeitgeber initialisieren: interrupt alle 10 ms
;-------------------------------


pitinit: push ax
         mov al,isrmodus
         out 0a6h,al      ;timer programmieren
         mov ax,millisekunden
         out 0a2h,al      ;low-teil der zeitkonstante laden
         mov al,ah
         out 0a2h,al      ;hi-teil der zeitkonstante laden
         pop ax
         ret

;vektortabelle initialisieren (interrupt 8)
;-------------------------------
ivtabinit:
;adresse der isr in der interrupt-vektor-tabelle
;auf vektor 8 eintragen
	mov ax,isr8	;adresse isr in vektortabelle eintragen
	mov [0020h],ax
	mov ax,0
	mov [0020h+2],ax  ;segmentadresse eintragen
        ret


;unterprogramm fuer 2-stellige hexzahlausgabe
;parameter: al - anzuzeigende 8-bit-zahl, dx - nummer der 7-segment-anzeige, cl - option zum anzeigen eines punkts; rueckgabewerte: keine
;-------------------------------
show2:          push ax            ;registerinhalte retten
                push dx
                push bx

                push cx

                mov cx,0
                mov bl,al          ;wert von al in bl kopieren
                and bl,0fh         ;in bl letzte 4 bit bearbeiten
                and al,0f0h        ;in al vordere 4 bit bearbeiten

                ror al,1           ;al rotieren, bis wert in letzten 4 bit
                ror al,1
                ror al,1
                ror al,1
                call show1        ;fuer anzeige up aufrufen

                pop cx
                mov al,bl          ;zweite stelle bearbeiten
                dec dx             ;anzeigestelle um 2 vermindern
                dec dx

                call show1        ;fuer weitere anzeige up aufrufen

                pop bx             ;urspruengliche werte wiederherstellen
                pop dx
                pop ax
                ret                ;zum hauptprogramm springen

;unterprogramm fuer 1-stellige hexzahlausgabe
;parameter: al - anzuzeigende 4-bit-zahl in 3-0, dx - nummer der 7-segment-anzeige, cl - option zum anzeigen eines punktes; rueckgabewerte: keine
;-------------------------------
show1:          push ax            ;registerinhalte retten
                push dx
                push si

                and ax,0fh         ;nur letzte 4 bit fuer anzeige erlauben (keine bereichsueberschreitung der codetabelle)
                mov si,codetab     ;startadresse uebernehmen
                add si,ax          ;mit ziffer addieren
                mov al,[si]        ;passende anzeigestellung laden

                cmp cl,0ffh        ;bei bedarf einen punkt anzeigen
                jne a1sanzeige
                or al,80h
a1sanzeige:     out dx,al          ;anzeige auf passender 7-segment-anzeige

                pop si             ;wiederherstellen der registerinhalte
                pop dx
                pop ax
                ret                ;sprung zum hauptprogramm

;unterprogramm zum loeschen aller 7-segment-anzeigen
;parameter: keine; rueckgabewerte: keine
;-------------------------------
clrdsp:         push ax
                push dx            ;anzeige loeschen
startclr:       mov al,0
                mov dx,90h
clrdisplay:     out dx,al
                add dx,2
                cmp dx,9eh
                jle clrdisplay
                pop dx
                pop ax
                ret

;codetabelle fuer 7-segment-anzeige
;-------------------------------
codetab: db 00111111b ;0
         db 00000110b ;1
         db 01011011b ;2
         db 01001111b ;3
         db 01100110b ;4
         db 01101101b ;5
         db 01111101b ;6
         db 00000111b ;7
         db 01111111b ;8
         db 01101111b ;9
         db 01110111b ;a
         db 01111100b ;b
         db 00111001b ;c
         db 01011110b ;d
         db 01111001b ;e
         db 01110001b ;f
         
;-------------------------------
husk db 0    ;hundertstel
seku db 0    ;sekunden
stat db 0    ;statusvariable, 
             ;0 bedeutet keine ausfuehrung isr
             ;1 ausfuehrung isr
             ;2 neukonfiguration





