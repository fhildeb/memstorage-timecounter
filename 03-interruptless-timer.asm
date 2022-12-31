;----------------------------------------------------------------------------------------
; Programmieraufgabe 1: "Timergesteuerter Zaehler Ohne Interrupt"
;----------------------------------------------------------------------------------------
                   org 100h

;Benoetigte Displayanzeigen:
valueseg:          equ 9eh		        ;Portnummer der 7-Segment-Anzeige fuer die Ausgabe
                                        ;des WerteBereichs der Zeit samt Null

counterseg:        equ 98h	            ;Portnummer der 7-Segment-Anzeige fuer die Ausgabe
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
                                        
millisekunden:     equ 0B7Dh            ;(0.01s mal 5MHz durch 17)
                                        ;2.941



;Initialisierung
before:            call cleardisplay    ;Bisherige Anzeigeinhalte loeschen
                   mov al,2             ;Wecker in Neukonfigurationsmodus versetzen
                   mov [stat],al
                   mov ax,0

start:             mov al,[stat]
                   cmp al,0             ;Bei abgelaufener Zeit in Schleife bleiben
                   jne mainprogramm

IsTimerActive:     in al,0              ;Pruefen, ob Nutzer den Wecker abgeschaltet hat
                   test al,80h
                   jz before            ;Neue Konfiguration erlauben
                   jmp start

mainprogramm:      in al,0              ;Schalterstellung einlesen
                   push ax

                   and al,01111111b     ;Wecker-Ein/Aus-Schalter ignorieren
                   daa                  ;In BCD-Zahl umwandeln
                   mov dx,timeseg       ;Auf linker Displaystelle anzeigen lassen
                   call show2
                   mov dx,valueseg
                   mov al,ah            ;Fuehrende Null anzeigen
                   call show1

                   pop ax
                   test al,80h          ;Test, ob S7 aktiv -> Timerstart?
                   jz start

                   cmp [stat],byte 2    ;Wenn Wecker im Konfigurationsmodus, eingelesene Sekundenzahl einmalig initialisieren
                   jne timerloop

                   call startCounter    ;Wecker neu initialisieren

timerloop:         call counter         ;Hundertstel-Sekunden herunterzeahlen
                   call output          ;Wert auf 7-Segment-Anzeige ausgeben lassen
                   call freetime        ;Zeitverzoegerung von ca. 10ms
                   jmp start

;----------------------------------------------------------------------------------------

;UP zum Initialisieren der Hundertstel- und Sekunden-Variable
;Parameter: AL - Schalterstellung als 8-Bit-Zahl; Rueckgabewerte: keine
;-----------------------------------------
startCounter:      push ax

                   and al,7Fh           ;Aus Eingabe S7 filtern
                   daa                  ;In BCD-Zahl umwandeln
                   mov [seku],al        ;Sekunden mit BCD-Zahl initialisieren
                   mov [husk],byte 0
                   mov [stat],byte 1    ;Timerstatus: aktiv

                   pop ax
                   ret

;UP zum Dekrementieren der Hundertstel-Sekunden
;Parameter: keine; Rueckgabewerte: keine
;--------------------------------------
counter:           push ax

                   mov al,[husk]        ;Hundertstel-Sekunden laden
                   dec al               ;und dekrementieren
                   das

                   cmp al,99h           ;Wenn bei kleiner 0 angekommen
                   jne savehusk

                   call sekundenCounter ;Bei 0 die Sekunden aendern
                   jmp skipsavehusk

savehusk:          mov [husk],al        ;Sonst neuen Sekundenwert abspeichern

skipsavehusk:      pop ax
                   RET


;UP zum Dekrementieren der Sekunden
;Parameter: keine; Rueckgabewerte: Reset der Hundertstel auf 10
;-------------------------------
sekundenCounter:   push ax
                   mov al,[seku]        ;Aktuelle Sekunden laden
                   dec al               ;Um eins dekrementieren
                   das                  ;Hexzahl in BCD-Zahl umwandeln
                   cmp al,99h           ;Test, ob Wecker bei 0 angekommen it
                   je stoptimer

                   mov [seku],al        ;Neuen Wert abspeichern

                   mov al,99h           ;Hundertstel-Sekunden neu initialisieren
                   mov [husk],al

                   jmp skipstoptimer

stoptimer:         mov [stat],byte 0    ;Timer abschalten und keine Werte mehr speichern

skipstoptimer:     pop ax
                   ret

;UP zum Anzeigen der Hundertstel- und Sekunden auf der 7-Segment-Anzeige
;Parameter: keine; Rueckgabewerte: keine
;--------------------------------------
output:            push ax
                   push dx

                   push cx
                                        ;Sekunden-Voreinstellung wird bereits auf 3 Stellen angezeigt
                   mov dx,counterseg    ;An 4. Stelle ein Minus anzeigen
                   mov al,trennseg
                   out dx,al

                   mov al,[seku]        ;Nach dem Minus die Sekunden anzigen
                   mov dx,sekundenseg
                   mov cl,0FFh          ;Punktdarstellung einschalten
                   call show2

                   mov cx,0             ;Punktdarstellung abschalten
                   mov al,ah            ;Fuehrende Null anzeigen
                   mov dx,timerseg
                   call show1

                   mov al,[husk]        ;Nach den Sekunden die Hundertstel-Sekunden zeigen
                   shr al,1             ;Nur die vordere Stelle (Zehntel-Sek.) anzeigen
                   shr al,1
                   shr al,1
                   shr al,1
                   mov dx,firstseg
                   call show1

                   pop cx

                   pop dx
                   pop ax
                   ret

;Unterprogramm zum Ausbremsen fuer ca. 100ms
;Parameter: keine; Rueckgabewerte: keine
;--------------------------------------
freetime:          push cx

                   mov cx,millisekunden

schl:              loop schl

                   pop cx
                   ret


husk:              db 0                 ;Hundertstel
seku:              db 0                 ;Sekunden
stat:              db 0                 ;Statusvariable:
                                        ;0 bedeutet Zaehler aus,
                                        ;1 bedeutet Zaehler ein,
                                        ;2 bedeutet Neukonfiguration

;Unterprogramm fuer 2-stellige Hexzahlausgabe
;Parameter: AL - Anzuzeigende 8-Bit-Zahl, DX - Nummer der 7-Segment-Anzeige, CL - Option zum Anzeigen eines Punkts; Rueckgabewerte: keine
;-------------------------------
show2:             push ax              ;Registerinhalte retten
                   PUSH dx
                   push bx

                   push cx

                   mov cx,0
                   mov bl,al            ;Wert von AL in BL kopieren
                   and bl,0Fh           ;In BL letzte 4 Bit bearbeiten
                   and al,0F0h          ;In AL vordere 4 Bit bearbeiten

                   ror al,1             ;AL rotieren, bis Wert in letzten 4 Bit
                   ror al,1
                   ror al,1
                   ror al,1
                   call show1           ;Fuer Anzeige UP aufrufen

                   pop cx
                   mov al,bl            ;Zweite Stelle bearbeiten
                   dec dx               ;Anzeigestelle um 2 vermindern
                   dec dx

                   call show1           ;Fuer weitere Anzeige UP aufrufen

                   pop bx               ;Urspruengliche Werte wiederherstellen
                   pop dx
                   pop ax
                   ret                  ;Zum Hauptprogramm springen

;Unterprogramm fuer 1-stellige Hexzahlausgabe
;Parameter: AL - Anzuzeigende 4-Bit-Zahl in 3-0, DX - Nummer der 7-Segment-Anzeige, CL - Option zum Anzeigen eines Punktes; Rueckgabewerte: keine
;-------------------------------
show1:             push ax              ;Registerinhalte retten
                   push dx
                   push si

                   and ax,0Fh           ;Nur letzte 4 Bit fuer Anzeige erlauben (keine Bereichsueberschreitung der Codetabelle)
                   mov si,codetab       ;Startadresse uebernehmen
                   add si,ax            ;Mit Ziffer addieren
                   mov al,[si]          ;Passende Anzeigestellung laden

                   cmp cl,0FFh          ;Bei Bedarf einen Punkt anzeigen
                   jne a1sAnzeige
                   or al,80h
a1sAnzeige:        out dx,al            ;Anzeige auf passender 7-Segment-Anzeige

                   pop si               ;Wiederherstellen der Registerinhalte
                   pop dx
                   pop ax
                   ret                  ;Sprung zum Hauptprogramm

;Unterprogramm zum Loeschen aller 7-Segment-Anzeigen
;Parameter: keine; Rueckgabewerte: keine
;---------------------------------------------------------
;Unterprogramm zum Loeschen der
;7-Segment-Anzeige:
cleardisplay:                           ;Registerinhalte speichern
                   push ax              ;Registerinhalt aus AX in Stack schieben
                   push dx              ;Registerinhalt aus DX in Stack schieben

                   mov al,0             ;Wert Null auf Register AL kopieren
                   mov dx,firstseg      ;Wert fuer erstes Segment auf DX

;Einzelne Segmente
;der Anzeige loeschen
clearsegments:     out dx,al            ;Aktuelles Segment loeschen
                   add dx,2             ;Auf naechste Segmentstelle erhoehen
                   cmp dx,lastseg       ;Vergleichen ob letztes Segment erreicht
                   jle clearsegments    ;Wenn kleiner gleich letztes Segment,
                                        ;dann weitere Segmente loeschen

                                        ;Registerinhalte wiederherstellen
                   pop dx               ;Registerinhalt DX vom Stack holen
                   pop ax               ;Registerinhalt AX vom Stack holen

                   ret                  ;Zum Ausgangsprogramm zurueckkehren


;Symboltabelle zum Darstellen hexadezimaler
;Zahlen auf der 7-Segment-Anzeige
codetab:           db 00111111b         ;entspricht Zahl 0
                   db 00000110b         ;entspricht Zahl 1
                   db 01011011b         ;entspricht Zahl 2
                   db 01001111b         ;entspricht Zahl 3
                   db 01100110b         ;entspricht Zahl 4
                   db 01101101b         ;entspricht Zahl 5
                   db 01111101b         ;entspricht Zahl 6
                   db 00000111b         ;entspricht Zahl 7
                   db 01111111b         ;entspricht Zahl 8
                   db 01101111b         ;entspricht Zahl 9
                   db 01110111b         ;entspricht Zahl 10 dh. A
                                        ;Achtuung: kleines b, da sonst keine
                                        ;Unterscheidung von 8 und B moeglich
                   db 01111100b         ;entspricht Zahl 11 dh. b
                   db 00111001b         ;entspricht Zahl 12 dh. C
                   db 01011110b         ;entspricht Zahl 13 dh. D
                   db 01111001b         ;entspricht Zahl 14 dh. E
                   db 01110001b         ;entspricht Zahl 15 dh. F

;----------------------------------------------------------------------------------------
