;----------------------------------------------------------------------------------------
; Programmieraufgabe 1: "Auswertung Speicherinhalt"
;----------------------------------------------------------------------------------------
                org 100h            ;Startadresse auf Speicher 100 setzen

;Benoetigte Displayanzeigen:
valueseg:       equ 9eh		        ;Portnummer der 7-Segment-Anzeige fuer die Ausgabe
                                    ;des Wertes, nach welchem gesucht wird

counterseg:     equ 96h		        ;Portnummer der 7-Segment-Anzeige fuer die Ausgabe
                                    ;der Haeufigkeit, des gesuchten Wertes

firstseg:       equ 90h             ;Portnummer der 7-Segment-Anzeige fuer die erste
                                    ;Displaystelle die gecleared werden muss

lastseg:        equ 9eh             ;Portnummer der 7-Segment-Anzeige fuer die letzte
                                    ;Displaystelle die gecleared werden muss

;Benoetigte Adressbereiche:
startadress:    equ 0c000h          ;Startadresse, von welcher aus gesucht wird
endadress: 	equ 0cfffh	            ;Endadresse, bis zu welcher gesucht wird

;Initialisieren Display:
before:         call cleardisplay   ;Aufrufen der Funktion zum Loeschen der
                                    ;7-Segment-Anzeige
;Initialisieren Register
start:          mov ax,0            ;Register AX mit Wert 0 initialisieren
                mov dx,0            ;Register DX mit Wert 0 initialisieren

                in al,0             ;Wert der betoetigten Schalter von Port 0 einlesen

                mov dl,valueseg     ;Hex-Wert der 7-Segment-Anzeige fuer den
                                    ;gesuchten Wert nach Register DL schreiben

                call show2          ;Zweier-Anzeige aufrufen

                mov bx,0            ;Das Register BX, in welchem die Haeufigkeit
                                    ;gespeichert ist, wird mit 0 initialisiert

                mov si,startadress  ;Das Adressregister wird mit dem Wert der
                                    ;Startadresse initialisiert

;Speicherzellen ueberpruefen:
checkdata:      mov cl,[si]         ;Inhalt der aktuellen Speicherzelle laden
                                    ;(direkte Adressierung)

                inc si              ;Wert der Speicherzelle hochzaehlen
                cmp cl,al           ;Pruefen, ob Inhalt gleich der gesuchten Zahl ist

                jne adressrange     ;Bei Ungleichheit zu Adressrange springen

                inc bx              ;Haeufigkeit um eins hochzaehlen
                ;inc si             ;Speicherzelle um eins hochzaehlen

;Adressbereich pruefen:
adressrange:    mov cx,endadress    ;Endadresse in Regitser CX laden

                inc cx              ;Speicheradresse um eine Stelle erhoehen, damit
                                    ;der gesamte Bereich durchsucht wird

                cmp si,cx           ;Vergleichen ob Endadresse erreicht wurde

                jne checkdata       ;Wenn Endadresse noch nicht erreicht, solange
                                    ;weitervergleichen bis Endadresse erreicht wurde

;Ergebnisse ausgeben:
outputdata:     mov ax,bx           ;Trefferhaeufigkeit in Parameterregister AX
                                    ;uebertragen

                mov dl,counterseg   ;Hex-Wert der 7-Segment-Anzeige fuer die
                                    ;Haeufigkeit nach Register DL schreiben

                call show4          ;Vierer-Anzeige aufrufen

                jmp start           ;Wenn Programmdurchlauf beendet,
                                    ;wieder bei Start beginnen

;----------------------------------------------------------------------------------------

;Unterprogramm zum Anzeigen der Haeufigkeit
;auf 4 Displaystellen:
show4:                              ;Registerinhalte speichern
                push ax             ;Registerinhalt aus AX in Stack schieben
                                    ;->|entspricht in Anwendung 16 Bit Hexadezimalzahl.
                                    ;->|4 Anzeigen, -> 2x4 / 8 Bit shiften
                                    ;->|da 4 Bit je ein 16er-Komplement sind

                push bx             ;Registerinhalt aus BX in Stack schieben
                                    ;->|entspricht in Anwendung 16 Bit Hexadezimalzahl.
                                    ;->|4 Anzeigen, -> 2x4 / 8 Bit shiften
                                    ;->|da 4 Bit je ein 16er-Komplement sind

                push dx             ;Registerinhalt aus DX in Stack schieben
                                    ;->|DX entspricht der Displaystelle
                                    ;->|auf der 7-Segment-Anzeige

                mov bx,ax           ;Trefferhaeufigkeit (binaer) nach BX verschieben
                and ax,0ff00h       ;AX-> durch UND-Verknuefung sind AX die
                                    ;oberen 8 Bits (1111 1111 0000 0000)

                and bx,0ffh         ;BX-> durch UND-Verknuepfung sind BX die
                                    ;unteren 8 Bits (0000 0000 1111 1111)

                ror al,1            ;AX wird 8 Stellen nach rechts geshiftet,
                ror al,1            ;damit Werte richtig dargestellt werden koennen
                ror al,1            ;xxxx xxxx 0000 0000 -> xxxx xxxx
                ror al,1
                ror al,1            ;->|Da alle Register in Verwendung
                ror al,1            ;->|Wiederholung ROR 8x
                ror al,1
                ror al,1

                call show2          ;Unterprogramm zum Anzeigen auf 2 Displaystellen
                                    ;fuer die oberen 2 Stellen aufrufen

                mov ax,bx           ;Register BX nach AX kopieren um
                                    ;untere 2 Stellen bearbeiten zu koennen

                sub dx,4            ;7-Segmentanzeige um zwei Stellen verringern,
                                    ;um nun die unteren 2 Stellen ausgeben zu koennen

                call show2          ;Unterprogramm zum Anzeigen auf 2 Displaystellen
                                    ;fuer die unteren 2 Stellen aufrufen

                                    ;Registerinhalte wiederherstellen
                pop dx              ;Registerinhalt DX vom Stack holen
                pop bx              ;Registerinhalt BX vom Stack holen
                pop ax              ;Registerinhalt AX vom Stack holen

                ret                 ;Zum Ausgangsprogramm zurueckkehren


;Unterprogramm zum Anzeigen der Haeufigkeit
;auf 2 Displaystellen:
show2:                              ;Registerinhalte speichern
                push ax             ;Registerinhalt aus AX in Stack schieben
                                    ;->|entspricht in Anwendung 8 Bit Hexadezimalzahl
                                    ;->|2 Anzeigen, -> 4 Bit shiften
                                    ;->|da 4 Bit je ein 16er-Komplement sind
                push bx             ;Registerinhalt aus AX in Stack schieben
                                    ;->|entspricht in Anwendung 8 Bit Hexadezimalzahl
                                    ;->|2 Anzeigen, -> 4 Bit shiften
                                    ;->|da 4 Bit je ein 16er-Komplement sind
                push dx             ;Registerinhalt aus DX in Stack schieben
                                    ;->|DX entspricht der Displaystelle
                                    ;->|auf der 7-Segment-Anzeige

                mov bl,al           ;Wert von AL in BL kopieren
                and al,0f0h         ;AX-> durch UND-Verknuepfung sind AX die
                                    ;oberen 4 Bits (1111 0000)
                and bl,0fh          ;BX-> durch UND-Verknuepfung sind BX die
                                    ;unteren 4 Bits (0000 1111)

                ror al,1            ;AL wird 4 Stellen nach rechts geschiftet
                ror al,1            ;->|Da alle Register in Verwendung
                ror al,1            ;->|Wiederholung ROR 4x
                ror al,1
                                    ;damit Werte richtig dargestellt werden koennen
                                    ;xxxx 0000 -> xxxx
                call show1          ;Unterprogramm zum Anzeigen auf einer Displaystelle
                                    ;fuer die obere Stelle aufrufen

                mov al,bl           ;Register BL nach AL kopieren um
                                    ;untere Stellen bearbeiten zu koennen
                sub dx,2            ;7-Segmentanzeige um eine Stellen verringern,
                                    ;um nun die untere Stelle ausgeben zu koennen

                call show1          ;Unterprogramm zum Anzeigen auf einer Displaystelle
                                    ;fuer die untere Stelle aufrufen

                                    ;Registerinhalte wiederherstellen
                pop dx              ;Registerinhalt DX vom Stack holen
                pop bx              ;Registerinhalt BX vom Stack holen
                pop ax              ;Registerinhalt AX vom Stack holen

                ret                 ;Zum Ausgangsprogramm zurueckkehren

;Unterprogramm zum Anzeigen der Haeufigkeit
;auf einer Displaystelle:
show1:                              ;Registerinhalte speichern
                push ax             ;Registerinhalt aus AX in Stack schieben
                                    ;->|entspricht bei uns 4 Bit Hexadezimalzahl.
                                    ;->|4 Bit sind ein 16er-Komplement

                push dx             ;Registerinhalt aus DX in Stack schieben
                                    ;->|DX entspricht der Displaystelle
                                    ;->|auf der 7-Segment-Anzeige

                push si             ;Registerinhalt aus SI in Stack schieben
                                    ;->|SI entspricht dem Symbol auf der Display Unit

                and ax,0fh	        ;AX-> durch UND-Verknuepfung sind AX nur 4 Bits,
                                    ;damit alle Werte von 0-F ohne Overflow
                                    ;dargestellt werden koennen

                mov si,codetab      ;Startadresse der Tabelle in SI schreiben
                add si,ax           ;SI um Aufgetretene Ziffer erhoehen dh
                                    ;um AX Zeilen wird in der Tabelle hochgezaehlt

                mov al,[si]         ;Richtige Anzeigestelle nach AL kopieren
                                    ;(direkte Adressierung)
                out dx,al           ;Anzeige des Symbolwertes auf der einzelnen
                                    ;Displaystelle

                                    ;Registerinhalte wiederherstellen
                pop si              ;Registerinhalt DX vom Stack holen
                pop dx              ;Registerinhalt DX vom Stack holen
                pop ax              ;Registerinhalt DX vom Stack holen

                ret                 ;Zum Ausgangsprogramm zurueckkehren

;Unterprogramm zum Loeschen der
;7-Segment-Anzeige:
cleardisplay:                       ;Registerinhalte speichern
                push ax             ;Registerinhalt aus AX in Stack schieben
                push dx             ;Registerinhalt aus DX in Stack schieben

                mov al,0            ;Wert Null auf Register AL kopieren
                mov dx,firstseg     ;Wert fuer erstes Segment auf DX

;Einzelne Segmente
;der Anzeige loeschen
clearsegments:  out dx,al           ;Aktuelles Segment loeschen
                add dx,2            ;Auf naechste Segmentstelle erhoehen
                cmp dx,lastseg      ;Vergleichen ob letztes Segment erreicht
                jle clearsegments   ;Wenn kleiner gleich letztes Segment,
                                    ;dann weitere Segmente loeschen

                                    ;Registerinhalte wiederherstellen
                pop dx              ;Registerinhalt DX vom Stack holen
                pop ax              ;Registerinhalt AX vom Stack holen

                ret                 ;Zum Ausgangsprogramm zurueckkehren

;Symboltabelle zum Darstellen hexadezimaler
;Zahlen auf der 7-Segment-Anzeige
codetab:        db 00111111b        ;entspricht Zahl 0
                db 00000110b        ;entspricht Zahl 1
                db 01011011b        ;entspricht Zahl 2
                db 01001111b        ;entspricht Zahl 3
                db 01100110b        ;entspricht Zahl 4
                db 01101101b        ;entspricht Zahl 5
                db 01111101b        ;entspricht Zahl 6
                db 00000111b        ;entspricht Zahl 7
                db 01111111b        ;entspricht Zahl 8
                db 01101111b        ;entspricht Zahl 9
                db 01110111b        ;entspricht Zahl 10 dh. A
                                    ;Achtuung: kleines b, da sonst keine
                                    ;Unterscheidung von 8 und B moeglich
                db 01111100b        ;entspricht Zahl 11 dh. b
                db 00111001b        ;entspricht Zahl 12 dh. C
                db 01011110b        ;entspricht Zahl 13 dh. D
                db 01111001b        ;entspricht Zahl 14 dh. E
                db 01110001b        ;entspricht Zahl 15 dh. F

;----------------------------------------------------------------------------------------