; FASM syntax

org 100h

; =============================================================================
; Installer
; =============================================================================

; Command line parsing

; Enable/disable the flags `mod_XXX_flag` according to the command line options
; Also, the mod is only installed if the .COM is run with the /ikwid (“I
; know what I'm doing”) option

start:
    ; Check for command line params
    mov si, 81h
    mov cl, [80h]
    test cl, cl
    jz no_install  ; BL=0: no parameters, so /ikwid cannot be present --> abort

    xor bl, bl

search_loop:
    test cl, cl
    jz done_search
    cmp byte [si], '/'
    jne .next_char

.check_t:
    ; Check for /t
    cmp cl, 2
    jl .next_char
    cmp byte [si+1], 't'
    jne .check_c
    ; Ensure /t is followed by space or end of command line
    cmp cl, 2
    je .t_ok
    cmp byte [si+2], ' '
    jne .check_c
.t_ok:
    mov byte [mod_tracks_flag], 1
    jmp .next_char

.check_c:
    ; Check for /c
    cmp cl, 2
    jl .next_char
    cmp byte [si+1], 'c'
    jne .check_o
    ; Ensure /c is followed by space or end of command line
    cmp cl, 2
    je .c_ok
    cmp byte [si+2], ' '
    jne .check_o
.c_ok:
    mov byte [mod_cars_flag], 1
    jmp .next_char

.check_o:
    ; Check for /o
    cmp cl, 2
    jl .next_char
    cmp byte [si+1], 'o'
    jne .check_ikwid
    ; Ensure /o is followed by space or end of command line
    cmp cl, 2
    je .o_ok
    cmp byte [si+2], ' '
    jne .check_ikwid
.o_ok:
    mov byte [mod_opponents_flag], 1
    jmp .next_char

.check_ikwid:
    ; Check for /ikwid (needs 6 chars: /ikwid)
    cmp cl, 6
    jl .next_char
    cmp byte [si+1], 'i'
    jne .next_char
    cmp byte [si+2], 'k'
    jne .next_char
    cmp byte [si+3], 'w'
    jne .next_char
    cmp byte [si+4], 'i'
    jne .next_char
    cmp byte [si+5], 'd'
    jne .next_char
    ; Ensure /ikwid is followed by space or end of command line
    cmp cl, 6
    je .ikwid_ok
    cmp byte [si+6], ' '
    jne .next_char
.ikwid_ok:
    mov bl, 1
    jmp .next_char

.next_char:
    inc si
    dec cl
    jmp search_loop

done_search:
    ; Proceed only if /ikwid was found
    test bl, bl
    jnz do_install

no_install:
    mov dx, bad_param_msg
    mov ah, 09h
    int 21h
    mov ax, 4c01h  ; exit with error code 1
    int 21h

do_install:
    ; Hook the TSR handler to int 10 (video)
    mov ax, 3510h
    int 21h
    mov [original_int10_offset], bx
    mov [original_int10_segment], es

    mov ax, 2510h
    mov dx, handler
    int 21h

    mov dx, resident_end
    int 27h

; =============================================================================
; Patcher (TSR part)
; =============================================================================

handler:
    inc word [cs:call_count]
    cmp word [cs:call_count], 2
    jne call_real_int10

    ; ========================================
    ; Start
    ; ========================================
    push ds
    push ax
    push bx
    push cx
    push dx
    push si
    push di

    ; Load DS with this handler's segment.
    ; ES (unchanged) contains GPC's data segment
    push cs
    pop ds

    ; ========================================
    ; Rev meter needle (disabled, just for reference)
    ; ========================================
    ; mov si, rpm_meter 
    ; mov cx, rpm_meter_end - rpm_meter 
    ; mov di, 58A6h
    ; rep movsb

    ; ========================================
    ; Filenames
    ; ========================================
    
    mov si, f1title_filename
    mov cx, f1title_filename_end - f1title_filename
    mov di, 8E44h
    rep movsb

    mov si, dsititle_filename
    mov cx, dsititle_filename_end - dsititle_filename
    mov di, 8E3Ah
    rep movsb

    ; Keep separate hi-score files to accommodate all combinations
    ; of classical and new cars and tracks
    mov al, [mod_tracks_flag]
    shl al, 1
    add al, [mod_cars_flag]
    add al, '0'
    mov byte [scores_filename + 6], al

    mov si, scores_filename 
    mov cx, scores_filename_end - scores_filename
    mov di, 9030h
    rep movsb

    mov si, scores_filename
    mov cx, scores_filename_end - scores_filename
    mov di, 92FAh
    rep movsb

    ; Not modded (maybe in future)

    ;mov si, f1select_filename
    ;mov cx, f1select_filename_end - f1select_filename
    ;mov di, 8FBCh
    ;rep movsb

    ;mov si, hiscore_filename
    ;mov cx, hiscore_filename_end - hiscore_filename
    ;mov di, 93C8h
    ;rep movsb
    
    ; ========================================
    ; Tracks
    ; ========================================
mod_tracks:
    mov al, [mod_tracks_flag]
    test al, al
    jz mod_cars

    ; Filenames

    mov si, moebius_filename
    mov cx, moebius_filename_end - moebius_filename
    mov di, 8F6Eh
    rep movsb

    mov si, baku_filename
    mov cx, baku_filename_end - baku_filename
    mov di, 8F80h
    rep movsb

    mov si, spa_filename
    mov cx, spa_filename_end - spa_filename
    mov di, 8F90h
    rep movsb

    mov si, f1selec3_filename 
    mov cx, f1selec3_filename_end - f1selec3_filename
    mov di, 8FB2h
    rep movsb

    mov si, status_filename 
    mov cx, status_filename_end - status_filename
    mov di, 908Ah
    rep movsb

    mov si, status_filename 
    mov cx, status_filename_end - status_filename
    mov di, 914Ah
    rep movsb

    mov si, status_filename 
    mov cx, status_filename_end - status_filename
    mov di, 9254h
    rep movsb

    mov si, status_filename 
    mov cx, status_filename_end - status_filename
    mov di, 93D6h
    rep movsb

    ; Minimaps

    mov si, moebius_minimap
    mov cx, moebius_minimap_end - moebius_minimap
    mov di, 149Ah
    rep movsb

    ; put the Bakı minimap at 1000h, since its original buffer (1704h) is not
    ; big enough after the track extension
    mov word [es:1304h], 1000h

    mov si, baku_minimap
    mov cx, baku_minimap_end - baku_minimap
    mov di, 1000h ; 1704h
    rep movsb

    mov si, spa_minimap
    mov cx, spa_minimap_end - spa_minimap
    mov di, 19BAh
    rep movsb

    ; Layouts

    mov si, moebius_track
    mov cx, moebius_track_end - moebius_track
    mov di, 279Dh
    rep movsb

    mov word [es:1F3Ah], 373Dh  ; extend Bakı lap length by 164 segments. Was 3699h

    mov si, baku_track
    mov cx, baku_track_end - baku_track
    mov di, 31F9h
    rep movsb

    mov word [es:1F42h], 464Ah  ; reduce Spa lap length by 56 segments. Was 4682h

    mov si, spa_track
    mov cx, spa_track_end - spa_track
    mov di, 3F12h
    rep movsb

    ; Opponent speeds
    
    ; put the Bakı opponent speed at 1704h, since its original buffer (3777h) is not
    ; big enough after the track extension. Note: 1704h is the buffer left free
    ; by the relocation of the minimap
    mov word [es:1F52h], 1704h

    mov si, moebius_opp_speed 
    mov cx, moebius_opp_speed_end - moebius_opp_speed
    mov di, 2B87h
    rep movsb

    mov si, baku_opp_speed
    mov cx, baku_opp_speed_end - baku_opp_speed
    mov di, 1704h
    rep movsb

    mov si, spa_opp_speed
    mov cx, spa_opp_speed_end - spa_opp_speed
    mov di, 46ABh
    rep movsb

    ; Qualification times

    mov word [es:12E0h],  437 ; Möbius: Base qualif. time = 0:43.7 (was 660 == 1:06.0)
    mov word [es:12E2h],    6 ; Möbius: Average gap between qualif. times = 0.6 (was 8 == 0.8)

    mov word [es:12E8h],  728 ; Bakı: Base qualif. time = 1:12.8 (was 770 == 1:10.0)
    mov word [es:12EAh],   11 ; Bakı: Average gap between qualif. times = 1.1 (was 10 == 1.0)

    mov word [es:12F0h], 1049 ; Spa: Base qualif. time = 1:44.9 (was 1000 == 1:40.0)
    mov word [es:12F2h],   14 ; Spa: Average gap between qualif. times = 1.4 (was 12 == 1.2)

    ; ========================================
    ; Cars
    ; ========================================
mod_cars:
    mov al, [mod_cars_flag]
    test al, al
    jz mod_opponents

    ; Car names
    
    mov si, car_names
    mov cx, car_names_end - car_names
    mov di, 031Ch
    rep movsb

    ; Car selection carousel

    mov si, carsel_filename
    mov cx, carsel_filename_end - carsel_filename
    mov di, 8884h
    rep movsb

    mov si, carsel_filename
    mov cx, carsel_filename_end - carsel_filename
    mov di, 8FAAh
    rep movsb
    
    ; Pit sprites

    mov si, pitstuff_filename
    mov cx, pitstuff_filename_end - pitstuff_filename
    mov di, 93DEh
    rep movsb
    
    ; Cockpits

    mov si, car1_filename
    mov cx, car1_filename_end - car1_filename
    mov di, 00B8h
    rep movsb

    mov si, car1_filename
    mov cx, car1_filename_end - car1_filename
    mov di, 0340h
    rep movsb

    mov si, car2_filename
    mov cx, car2_filename_end - car2_filename
    mov di, 00C1h
    rep movsb

    mov si, car2_filename
    mov cx, car2_filename_end - car2_filename
    mov di, 0345h
    rep movsb

    mov si, car3_filename
    mov cx, car3_filename_end - car3_filename
    mov di, 00CAh
    rep movsb

    mov si, car3_filename
    mov cx, car3_filename_end - car3_filename
    mov di, 034Ah
    rep movsb

    ; Engine, transmission and tyre parameters
    
    mov si, engines
    mov cx, engines_end - engines
    mov di, 75F2h
    rep movsb
    
    ; ========================================
    ; Opponents
    ; ========================================
mod_opponents:
    mov al, [mod_opponents_flag]
    test al, al
    jz deinit
    
    ; Glyph manipulation

    ; The competition features “Niño Matador, so nicknamed because he is the
    ; son of “El Matador”, a celebrated rally driver. But GPC does not have a
    ; n-with-tilde. Not a big problem: let's create it by copying four
    ; scanlines of the glyph 'n' into the 'tilde' glyph. Then GPC will print a
    ; 'ñ' whenever we use the tilde. 

    ; The scanlines for each char are stored at (78B2 + 8*charcode). charcode
    ; is the ascii code, except for a dozen or so special characters appended
    ; after #127

    mov cx, 4      ; 4 scanlines     
    xor si, si              
glyph_loop:
    mov bx,7C24h  ; source glyph. 'n' starts at 7C22, copy from scanlines 2-5
    mov al, [es:bx+si] 
    mov bx,7CA5h  ; target glyph. '~' starts at 7CA2, copy into scanlines 3-6
    or [es:bx + si], al
    inc si
    loop glyph_loop

    ; Driver names
    
    mov si, driver_1
    mov cx, driver_2 - driver_1
    mov di, 180h
    rep movsb

    mov si, driver_2
    mov cx, driver_3 - driver_2
    mov di, 19Ch
    rep movsb

    mov si, driver_3
    mov cx, driver_4 - driver_3
    mov di, 1B8h
    rep movsb

    mov si, driver_4
    mov cx, driver_5 - driver_4
    mov di, 1D4h
    rep movsb

    mov si, driver_5
    mov cx, driver_6 - driver_5
    mov di, 1F0h
    rep movsb

    mov si, driver_6
    mov cx, driver_7 - driver_6
    mov di, 20Ch
    rep movsb

    mov si, driver_7
    mov cx, driver_8 - driver_7
    mov di, 228h
    rep movsb

    mov si, driver_8
    mov cx, driver_9 - driver_8
    mov di, 244h
    rep movsb

    mov si, driver_9
    mov cx, car_numbers - driver_9
    mov di, 260h
    rep movsb

    ; Car numbers
    
    mov si, car_numbers
    mov cx, 2h
    mov di, 178h
    rep movsb

    repeat 8
        mov cx, 2h
        add di, 1Ah
        rep movsb
    end repeat

    ; Car number sprites

    mov si, xtrackc_filename
    mov cx, xtrackc_filename_end - xtrackc_filename
    mov di, 8776h
    rep movsb
    mov si, xtrackc_filename
    mov cx, xtrackc_filename_end - xtrackc_filename
    mov di, 9134h
    rep movsb
    mov si, xtrackc_filename
    mov cx, xtrackc_filename_end - xtrackc_filename
    mov di, 93F0h
    rep movsb

    ; Opponent skills: increase reference speed

    define speed_boost 20

    mov cx, 8  ; # tracks
    mov si, 0  ; track counter
    mov bx, 1F4Ch  ; array of ptrs to the arrays of ref. speeds

skills_track_loop:
    mov di, [es:bx + si]   ; array of ref. speeds for this track

skills_elem_loop:
    mov al, [es:di]

    ; Track end check
    cmp al, 08h
    je skills_next_track

    add al, speed_boost

    ; Overflow check: saturate to 0xFE
    cmp al, speed_boost
    ja @f
    mov al, 0FEh
@@: ; end overflow check

    mov [es:di], al
    inc di
    jmp skills_elem_loop

skills_next_track:
    add si, 2
    loop skills_track_loop

    ; Opponent skills:
    ; decrease qualification times
    ; increase gap between qualif. times
    mov cx, 8  ; # tracks
    mov si, 0  ; track counter
    mov bx, 12DCh  ; array of ptrs to the arrays of ref. speeds

skills_quali_loop:
    mov ax, [es:bx + si]  ; load the qualif. time for this track.
    mov dx, ax            ; reduce it by 1/32 + 1/64 (about 4.7%)
    shr dx, 5
    sub ax, dx
    shr dx, 1
    sub ax, dx
    mov [es:bx + si], ax  ; store the reduced qualif. time

    add si, 2
    mov ax, [es:bx + si]  ; load the gap between opponents
    add ax, 3             ; add .3 seconds
    mov [es:bx + si], ax  ; store the increased gap

    add si, 2
    loop skills_quali_loop

    ; ========================================
    ; The end
    ; ========================================
deinit:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop ds

call_real_int10:
    push word [cs:original_int10_segment]
    push word [cs:original_int10_offset]
    retf

marker db "===== DATA ====="

original_int10_offset dw 0
original_int10_segment dw 0
call_count dw 0

mod_tracks_flag db 0
mod_cars_flag db 0
mod_opponents_flag db 0

;rpm_meter:
;    times 16 db 0CCh, 0CCh
;rpm_meter_end:

f1title_filename:
    db "DML-TIT"
f1title_filename_end:

dsititle_filename:
    db "DML-DSI", 0, 0
dsititle_filename_end:

scores_filename:
    ; @ is a placeholder, to be replaced with a digit according to the modding
    ; options for cars and tracks.
    ; E.g. "classic cars, new tracks" gets a different hi-score file than
    ; "new cars, classic tracks"
    db "DML-SC@"
scores_filename_end:

; =============================================================================
; Opponents
; =============================================================================
driver_1:
    db "Franz Hermann"
driver_2:
    db "Kim Leonardo"
driver_3:
    db "Carl St-Mleux"
driver_4:
    db "Aussie Priast"
driver_5:
    db "Lord Blimey", 0
driver_6:
    db "Ni~o Matador"
driver_7:
    db "Sir Arbalestier"
driver_8:
    db "Asnee Smylin"
driver_9:
    db "Goro Inamoto"

car_numbers:
    db "1 "
    db "12"
    db "16"
    db "81"
    db "63"
    db "55"
    db "44"
    db "23"
    db "22"

xtrackc_filename:
    db "DML-XTC"
xtrackc_filename_end:

; =============================================================================
; Tracks
; =============================================================================
moebius_filename:
    db "Moebius"
moebius_filename_end:

baku_filename:
    db "Azeri", 0, 0    ; Siccome è azero, dobbiamo aggiungere uno zero (a lame Italian joke, don't bother)
baku_filename_end:

spa_filename:
    db "Belgian", 0
spa_filename_end:

f1selec3_filename:
    db "DML-F1S3"
f1selec3_filename_end:

;f1select_filename:
;    db "DML-F1ST"
;f1select_filename_end:

;hiscore_filename:
;    db "DML-HISC"
;hiscore_filename_end:

status_filename:
    db "DML-ST"
status_filename_end:

moebius_minimap:
    ; python3 minimap--convert-coords.py mobius-minimap-skimmed.txt
    db 18h, 08h, 1Bh, 09h, 1Eh, 0Ah, 21h, 0Bh, 24h, 0Ch, 26h, 0Dh, 28h, 0Fh, 2Bh, 10h
    db 2Ch, 12h, 2Eh, 14h, 30h, 15h, 33h, 16h, 35h, 18h, 37h, 19h, 3Ah, 1Ah, 3Ch, 1Bh
    db 3Fh, 1Ch, 43h, 1Ch, 45h, 1Bh, 48h, 1Ah, 4Ah, 19h, 4Ch, 17h, 4Eh, 15h, 4Fh, 13h
    db 4Fh, 0Fh, 4Eh, 0Dh, 4Bh, 0Bh, 49h, 09h, 47h, 08h, 43h, 08h, 41h, 07h, 3Eh, 08h
    db 3Bh, 09h, 38h, 09h, 35h, 0Ah, 33h, 0Bh, 31h, 0Dh, 2Fh, 0Fh, 2Eh, 11h, 2Bh, 12h
    db 29h, 13h, 27h, 15h, 25h, 17h, 23h, 18h, 20h, 19h, 1Eh, 1Ah, 1Bh, 1Bh, 18h, 1Ch
    db 15h, 1Ch, 12h, 1Bh, 10h, 1Ah, 0Dh, 19h, 0Bh, 16h, 09h, 15h, 09h, 11h, 0Ah, 0Fh
    db 0Bh, 0Ch, 0Eh, 0Bh, 10h, 09h, 13h, 08h, 16h, 08h, 1Ah, 08h, 1Dh, 09h, 1Fh, 0Ah
    db 22h, 0Ch, 25h, 0Ch, 27h, 0Eh, 2Ah, 0Fh, 2Bh, 11h, 2Dh, 13h, 2Fh, 14h, 31h, 16h
    db 34h, 17h, 36h, 18h, 38h, 1Ah, 3Bh, 1Ah, 3Eh, 1Bh, 41h, 1Ch, 43h, 1Bh, 46h, 1Ah
    db 49h, 1Ah, 4Bh, 18h, 4Dh, 16h, 4Eh, 14h, 4Fh, 11h, 4Fh, 0Eh, 4Dh, 0Ch, 4Ah, 0Ah
    db 48h, 09h, 45h, 08h, 42h, 08h, 3Fh, 07h, 3Ch, 08h, 3Ah, 09h, 37h, 0Ah, 34h, 0Ah
    db 32h, 0Ch, 30h, 0Eh, 2Fh, 10h, 2Ch, 11h, 2Ah, 12h, 28h, 14h, 26h, 16h, 24h, 17h
    db 21h, 18h, 20h, 1Ah, 1Ch, 1Ah, 19h, 1Bh, 17h, 1Ch, 13h, 1Ch, 11h, 1Bh, 0Eh, 1Ah
    db 0Bh, 18h, 0Ah, 16h, 09h, 13h, 09h, 10h, 0Bh, 0Eh, 0Dh, 0Ch, 0Fh, 0Ah, 12h, 09h
    db 14h, 08h, 18h, 08h, 1Ah, 08h, 1Dh, 09h, 1Fh, 0Ah, 22h, 0Ch, 25h, 0Dh, 27h, 0Eh
    db 2Ah, 0Fh, 2Bh, 11h, 2Dh, 13h, 30h, 14h, 31h, 16h, 34h, 17h, 36h, 18h, 38h, 1Ah
moebius_minimap_end:

baku_minimap:
    db 46h, 11h, 47h, 11h, 48h, 11h, 49h, 11h, 4Ah, 11h, 4Bh, 11h, 4Dh, 11h, 4Fh, 11h
    db 51h, 11h, 53h, 11h, 54h, 11h, 55h, 11h, 55h, 10h, 55h, 0Fh, 55h, 0Eh, 55h, 0Dh
    db 55h, 0Ch, 55h, 0Bh, 55h, 0Ah, 55h, 09h, 55h, 08h, 54h, 08h, 53h, 08h, 52h, 08h
    db 50h, 08h, 4Eh, 08h, 4Dh, 08h, 4Ch, 08h, 4Ah, 08h, 48h, 08h, 46h, 08h, 44h, 08h
    db 42h, 08h, 40h, 08h, 3Eh, 08h, 3Ch, 08h, 3Ah, 08h, 38h, 08h, 37h, 08h, 36h, 08h
    db 36h, 09h, 36h, 0Ah, 36h, 0Bh, 36h, 0Ch, 36h, 0Dh, 36h, 0Dh, 36h, 0Eh, 35h, 0Eh
    db 33h, 0Eh, 31h, 0Eh, 30h, 0Eh, 2Fh, 0Eh, 2Dh, 0Eh, 2Bh, 0Eh, 2Ah, 0Eh, 29h, 0Eh
    db 28h, 0Eh, 27h, 0Eh, 27h, 0Fh, 27h, 10h, 27h, 11h, 26h, 11h, 25h, 11h, 24h, 11h
    db 23h, 11h, 22h, 12h, 21h, 12h, 20h, 12h, 1Fh, 13h, 1Eh, 13h, 1Dh, 13h, 1Dh, 12h
    db 1Dh, 11h, 1Dh, 10h, 1Dh, 0Fh, 1Dh, 0Eh, 1Dh, 0Eh, 1Ch, 0Eh, 1Bh, 0Eh, 1Bh, 0Eh
    db 1Bh, 0Dh, 1Bh, 0Ch, 1Ah, 0Ch, 1Ah, 0Ch, 19h, 0Ch, 19h, 0Ch, 19h, 0Bh, 19h, 0Ah
    db 19h, 09h, 18h, 09h, 17h, 09h, 16h, 09h, 15h, 09h, 13h, 09h, 11h, 09h, 0Fh, 09h
    db 0Eh, 09h, 0Dh, 09h, 0Bh, 09h, 0Ah, 0Ah, 09h, 0Ah, 08h, 0Bh, 08h, 0Ch, 07h, 0Dh
    db 06h, 0Dh, 05h, 0Eh, 04h, 10h, 03h, 11h, 03h, 13h, 03h, 14h, 02h, 15h, 02h, 15h
    db 02h, 17h, 03h, 18h, 04h, 19h, 05h, 1Ah, 06h, 1Bh, 07h, 1Ch, 08h, 1Ch, 09h, 1Dh
    db 09h, 1Eh, 0Ah, 1Eh, 0Bh, 1Eh, 0Ch, 1Eh, 0Dh, 1Dh, 0Eh, 1Ch, 0Fh, 1Bh, 11h, 1Ah
    db 12h, 1Ah, 14h, 1Ah, 16h, 1Ah, 18h, 19h, 1Ah, 19h, 1Bh, 18h, 1Ch, 17h, 1Dh, 16h
    db 1Eh, 15h, 1Fh, 15h, 20h, 15h, 22h, 14h, 24h, 14h, 26h, 13h, 28h, 12h, 2Ah, 12h
    db 2Bh, 11h, 2Dh, 11h, 2Eh, 11h, 2Fh, 11h, 30h, 11h, 31h, 11h, 32h, 11h, 33h, 11h
    db 34h, 11h, 35h, 11h, 36h, 11h, 37h, 11h, 38h, 11h, 39h, 11h, 3Ah, 11h, 3Bh, 11h
    db 3Ch, 11h, 3Dh, 11h, 3Eh, 11h, 3Fh, 11h, 40h, 11h, 41h, 11h, 42h, 11h, 43h, 11h
    db 44h, 11h, 45h, 11h
baku_minimap_end:

spa_minimap:
    db 12h, 17h, 12h, 18h, 11h, 18h, 10h, 18h, 10h, 18h, 0Fh, 19h, 0Eh, 1Ah, 0Ch, 1Ah
    db 0Bh, 1Bh, 0Ah, 1Ch, 09h, 1Ch, 08h, 1Ch, 07h, 1Dh, 05h, 1Eh, 04h, 1Fh, 03h, 1Fh
    db 02h, 1Fh, 02h, 1Dh, 03h, 1Ch, 03h, 1Bh, 03h, 1Ah, 04h, 1Ah, 04h, 19h, 05h, 19h
    db 05h, 18h, 06h, 18h, 06h, 17h, 07h, 17h, 07h, 16h, 08h, 16h, 09h, 16h, 09h, 15h
    db 0Ah, 15h, 0Bh, 15h, 0Bh, 14h, 0Ch, 14h, 0Ch, 13h, 0Dh, 13h, 0Dh, 12h, 0Dh, 11h
    db 0Eh, 11h, 0Eh, 10h, 0Fh, 10h, 10h, 10h, 11h, 10h, 12h, 10h, 13h, 10h, 13h, 0Fh
    db 15h, 0Fh, 15h, 0Eh, 16h, 0Eh, 17h, 0Dh, 18h, 0Dh, 19h, 0Ch, 1Bh, 0Bh, 1Dh, 0Bh
    db 1Eh, 0Bh, 1Fh, 0Ah, 21h, 0Ah, 22h, 0Ah, 23h, 09h, 24h, 09h, 26h, 09h, 28h, 08h
    db 2Ah, 08h, 2Ch, 07h, 2Eh, 07h, 30h, 06h, 32h, 06h, 34h, 05h, 36h, 05h, 38h, 04h
    db 3Ah, 04h, 3Ch, 03h, 3Eh, 03h, 40h, 02h, 42h, 02h, 44h, 02h, 46h, 02h, 47h, 03h
    db 48h, 04h, 48h, 05h, 49h, 05h, 4Ah, 04h, 4Bh, 04h, 4Ch, 03h, 4Dh, 03h, 4Eh, 03h
    db 4Fh, 03h, 50h, 04h, 50h, 05h, 51h, 05h, 51h, 06h, 52h, 07h, 53h, 07h, 53h, 08h
    db 54h, 08h, 55h, 09h, 55h, 0Ah, 55h, 0Bh, 55h, 0Ch, 54h, 0Dh, 53h, 0Dh, 52h, 0Dh
    db 52h, 0Ch, 51h, 0Ch, 50h, 0Bh, 50h, 0Ah, 4Fh, 09h, 4Eh, 08h, 4Dh, 07h, 4Ch, 07h
    db 4Bh, 07h, 4Ah, 08h, 48h, 08h, 47h, 09h, 46h, 09h, 44h, 09h, 43h, 0Ah, 42h, 0Ah
    db 41h, 0Ah, 3Fh, 0Ah, 3Eh, 0Bh, 3Dh, 0Bh, 3Ch, 0Bh, 3Ah, 0Bh, 39h, 0Ch, 38h, 0Ch
    db 37h, 0Ch, 37h, 0Dh, 36h, 0Dh, 36h, 0Eh, 36h, 0Fh, 36h, 10h, 37h, 10h, 37h, 11h
    db 38h, 11h, 38h, 12h, 3Ah, 12h, 3Ch, 12h, 3Eh, 13h, 40h, 13h, 42h, 14h, 44h, 14h
    db 46h, 15h, 48h, 15h, 49h, 15h, 4Ah, 15h, 4Bh, 16h, 4Bh, 17h, 4Bh, 18h, 4Ah, 19h
    db 4Ah, 1Ah, 49h, 1Bh, 4Bh, 1Bh, 4Ch, 1Bh, 4Dh, 1Ch, 4Eh, 1Ch, 4Fh, 1Dh, 50h, 1Dh
    db 51h, 1Dh, 52h, 1Dh, 52h, 1Eh, 52h, 1Fh, 51h, 1Fh, 51h, 21h, 50h, 21h, 50h, 22h
    db 4Fh, 22h, 4Eh, 22h, 4Dh, 22h, 4Ch, 22h, 4Bh, 22h, 4Ah, 22h, 49h, 21h, 48h, 21h
    db 47h, 21h, 46h, 21h, 45h, 20h, 44h, 20h, 43h, 1Fh, 42h, 1Fh, 41h, 1Eh, 40h, 1Eh
    db 3Fh, 1Dh, 3Eh, 1Ch, 3Dh, 1Ch, 3Ch, 1Bh, 3Ch, 1Ah, 3Bh, 19h, 3Ah, 19h, 39h, 18h
    db 38h, 18h, 37h, 16h, 36h, 16h, 35h, 16h, 34h, 16h, 33h, 15h, 32h, 15h, 30h, 15h
    db 2Fh, 14h, 2Eh, 14h, 2Dh, 14h, 2Ch, 14h, 2Bh, 14h, 2Ah, 15h, 29h, 15h, 28h, 15h
    db 27h, 15h, 26h, 16h, 25h, 16h, 24h, 16h, 23h, 17h, 22h, 17h, 21h, 18h, 20h, 18h
    db 1Eh, 18h, 1Dh, 18h, 1Ch, 19h, 1Bh, 19h, 19h, 19h, 18h, 1Ah, 17h, 1Ah, 15h, 1Ah
    db 14h, 1Ah, 14h, 19h, 14h, 19h, 15h, 18h, 15h, 17h, 15h, 17h, 14h, 17h, 13h, 17h
    db 12h, 17h, 12h, 18h, 11h, 18h, 10h, 18h, 10h, 18h, 0Fh, 19h, 0Eh, 1Ah, 0Ch, 1Ah
spa_minimap_end:

moebius_opp_speed:
    ; Be quick, for your opponents will be
    times 120 db 234
moebius_opp_speed_end:

baku_opp_speed:
    db 186, 186, 186, 186, 186, 186, 186, 186, 161, 140, 120, 100, 105, 110, 115
    db 120, 125, 130, 135, 125, 125, 130, 135, 140, 145, 150, 155, 160, 165, 170
    db 175, 175, 175, 175, 175, 175, 175, 175, 150, 125, 128, 131, 134, 137, 137
    db 122, 117, 122, 125, 128, 131, 134, 137, 140, 143, 146, 136, 126, 126, 129
    db 132, 135, 138, 141, 144, 147, 150, 140, 120, 100,  80,  83,  86,  89,  92
    db  95,  98,  98,  98,  98,  98,  98,  98,  98,  98, 102, 105, 108, 111, 114
    db 117, 120, 123, 126, 129, 132, 135, 135, 135, 135, 135, 138, 141, 144, 147
    db 150, 153, 156, 156, 156, 156, 156, 156, 156, 159, 159, 159, 159, 139, 129
    db 119, 109, 112, 117, 122, 127, 132, 137, 142, 147, 150, 150, 153, 153, 156
    db 156, 159, 159, 162, 162, 165, 165, 165, 165, 165, 168, 168, 168, 171, 171
    db 171, 174, 174, 174, 177, 177, 177, 180, 180, 180, 183, 183, 183, 186, 186
    db 186, 186, 186, 186, 186, 186, 186, 186, 186, 186
baku_opp_speed_end:

spa_opp_speed:
    db 118, 130, 137, 140, 143, 146, 149, 152, 155, 158, 161, 164, 167, 170, 165
    db 130,  85,  85,  92,  99, 106, 113, 120, 127, 134, 141, 148, 155, 162, 165
    db 163, 171, 171, 171, 171, 171, 141, 121, 124, 127, 130, 130, 130, 130, 130
    db 125, 130, 115, 115, 120, 125, 130, 135, 138, 141, 144, 147, 150, 153, 156
    db 154, 162, 165, 168, 171, 174, 177, 180, 180, 180, 180, 180, 180, 170, 155
    db 135, 125, 110,  95,  95,  95,  95,  95,  95,  95,  95,  95,  95, 100, 105
    db 105, 115, 120, 125, 130, 130, 120, 110, 110, 110, 110, 110, 110, 110, 110
    db 108, 116, 119, 127, 130, 130, 130, 130, 130, 130, 130, 130, 133, 136, 139
    db 137, 145, 148, 148, 148, 148, 148, 148, 148, 148, 148, 148, 148, 148, 148
    db 143, 148, 148, 151, 154, 157, 160, 160, 160, 160, 160, 160, 160, 145, 125
    db 100, 100, 100, 100, 100, 100, 100, 103, 106, 109, 112, 100, 100, 100, 105
    db 105, 115, 120, 125, 128, 131, 134, 137, 140, 143, 146, 149, 152, 155, 158
    db 156, 164, 167, 170, 173, 176, 176, 176, 176, 176, 176, 172, 172, 172, 172
    db 167, 175, 178, 181, 184, 187, 187, 187, 187, 187, 187, 187, 187, 187, 187
    db 182, 187, 187, 187, 187, 187, 187, 187, 187, 187, 182, 177, 170, 140, 100
    db  70,  70,  70,  70,  82,  94, 106
spa_opp_speed_end:

moebius_track:
    ; 1002 total pieces: 961 end-to-end plus 41 pcs of collation overlap.
    ; Each piece ~= 3.8 m, as the segments are run in 37.6 s @ 218 mph (3664 m / 961)

    times   8 db 33h  ;  
    times  16 db 2Dh  ;  100 sign on L
    times   9 db 04h  ;  slight R
    times   1 db 31h  ;  start/finish
    times   6 db 32h  ;  checkered floor

    times  64 db 19h  ;  Euklidkurve (L)

    times   1 db 37h  ;  box start
    times  64 db 36h  ;  s | box entrance
    times  16 db 3Bh  ;  t | box horz stripe
    times  16 db 39h  ;  r | pit
    times   1 db 37h  ;  a | box start (!)
    times  16 db 3Bh  ;  i | box horz stripe
    times  16 db 39h  ;  g | pit
    times  16 db 3Bh  ;  h | box horz stripe
    times  64 db 36h  ;  t | box away (surprise!)

    times   8 db 03h  ;  Alkuinkurve (R)
    times   8 db 12h  ;  .

    times  96 db 33h  ;  fog tunnel

    times  28 db 07h  ;  Albertus-Magnus-Kurve (R)
    times  28 db 1Ah  ;  saving zone (slight L)

    times   1 db 2Fh  ;  150 sign on L
    times   1 db 30h  ;  150 sign on R
    times  16 db 07h  ;  René-Gateaux-Kurve (R)
    times   1 db 2Dh  ;  . | 100 sign on L
    times   1 db 2Eh  ;  . | 100 sign on R
    times  16 db 07h  ;  . | slight R
    times   1 db 2Bh  ;  . | 50 sign on L
    times   1 db 2Ch  ;  . | 50 sign on R
    times   8 db 17h  ;  slight L
    times   8 db 1Ah  ;  .
    times   1 db 31h  ;  fake finish. B-side starts
    times   6 db 32h  ;  checkered floor
    times  24 db 17h  ;  slight L
    times  16 db 18h  ;  .
    times  16 db 18h  ;  .
    times   1 db 31h  ;  fake finish, to confuse the unprepared
    times   6 db 32h  ;  checkered floor

    times   5 db 0ah  ;  Stefan-Banach-Kurve (R)
    times  38 db 04h  ;  .

    times   6 db 31h  ;  "finish" tunnel
    times   7 db 32h  ;  checkered floor
    times   1 db 31h  ;  . 
    times   7 db 32h  ;  . 
    times   1 db 31h  ;  . 
    times   7 db 32h  ;  . 
    times   1 db 31h  ;  . 
    times   7 db 32h  ;  . 
    times   1 db 31h  ;  . 
    times   7 db 32h  ;  . 
    times   1 db 31h  ;  . 
    times   7 db 32h  ;  . 
    times   1 db 31h  ;  . 
    times   4 db 1Ch  ;  slight L
    times   5 db 00h  ;  straight
    times   1 db 2Bh  ;  50 sign on L
    times   1 db 2Ch  ;  50 sign on R

    times  91 db 34h  ;  dark tunnel
    times  48 db 35h  ;  glass tunnel

    times  16 db 1ah  ;  Heinz-Rutishauser-Kurve (L)
    times   1 db 2Fh  ;  . | 150 sign on L
    times   1 db 2Ch  ;  . | 50 sign on R
    times   8 db 23h  ;  . | 
    times   8 db 04h  ;  saving zone (slight R)

    times   1 db 2Bh  ;  50 sign on L
    times   1 db 2Eh  ;  100 sign on R
    times   8 db 04h  ;  slight R
    times   1 db 2Dh  ;  100 sign on L
    times   1 db 30h  ;  100 sign on R
    times   1 db 2Dh  ;  (etc)
    times   1 db 30h  ;  .
    times   1 db 2Dh  ;  .
    times   1 db 30h  ;  .
    times   1 db 2Dh  ;  .
    times   1 db 30h  ;  .
    times   1 db 2Dh  ;  .
    times   1 db 30h  ;  .
    times   1 db 2Dh  ;  .
    times   1 db 30h  ;  .
    times   1 db 2Dh  ;  .
    times   1 db 30h  ;  .
    times   1 db 2Dh  ;  .
    times   1 db 30h  ;  .
    times   1 db 2Dh  ;  .
    times   1 db 30h  ;  .
    times   1 db 2Dh  ;  .
    times   1 db 30h  ;  .

    times  12 db 20h  ;  Mario-Fiorentini-Kurve (L)

    times  32 db 33h  ;  fog tunnel

    ; Collation: repeat track start.
    times  8 db 33h  ;  
    times 16 db 2Dh  ;  100 sign on L
    times  9 db 04h  ;  slight R
    times  1 db 31h  ;  start/finish
    times  6 db 32h  ;  checkered floor

    times  1 db 0FFh ;  END
moebius_track_end:

baku_track:
    ; GPC lap length: 1348 segments end-to-end + 41 collation overlap

    ; Real-life lap length: 6003 m (2019 circuit centreline length)
    ; but only ~60% of segments are straight
    ; so 1 segment ~= 7.4 m
    ; (quite scaled down, real GPC scale is 3.8 m if we trust
    ; the speedometer, 5 m if we trust the 150-100-50 signs)

    ; Street names courtesy of OpenStreetMap

    times  33 db 00h  ;  starting grid (Neftçilar proskekti)

    times   1 db 31h  ; start/finish
    times   6 db 32h  ; checkered floor
    times  44 db 00h  ; start to (1) (Neftçilar proskekti)
    times  16 db 24h  ; (1)
    times  58 db 00h  ; (1) to (2) (Puşkin küçəsi)
    times  16 db 24h  ; (2)
    times 144 db 00h  ; (2) to (3) (Xaqani küçəsi)
    times  16 db 24h  ; (3)
    times  42 db 00h  ; (3) to (4) (Bülbül prospekti)
    times  16 db 0Eh  ; (4)
    times  32 db 00h  ; (4) to halfway (5) (Zərifə Əliyeva küçəsi)
    times   6 db 1bh  ; slight bend
    times  24 db 00h  ; halfway (5) to (5) (Zərifə Əliyeva küçəsi)
    times  16 db 22h  ; (5)
    times  12 db 00h  ; (5) to (6) (Zərifə Əliyeva küçəsi)
    times  16 db 0Dh  ; (6)
    times  55 db 00h  ; (6) to (7) (Neftçilar proskekti)
    times  16 db 12h  ; (7)
    times  29 db 00h  ; (7) to (8) (Əziz Əliyev küçəsi)
    times  23 db 29h  ; (8)
    times  25 db 09h  ; (9)
    times  19 db 18h  ; (10)
    times  19 db 10h  ; (11)
    times  12 db 00h  ; (11) to (12) (Əziz Əliyev küçəsi)
    times  16 db 24h  ; (12) 
    times  68 db 00h  ; (12) to (13) (İstiqlaliyyət küçəsi)
    times  14 db 24h  ; (13)
    times  40 db 00h  ; (13) to (14) (İstiqlaliyyət küçəsi)
    times  10 db 21h  ; (14)
    times  41 db 00h  ; (14) to (15) (İstiqlaliyyət küçəsi)
    times  10 db 22h  ; (15)
    times  56 db 00h  ; (15) to (16) (Niyazi küçəsi)
    times  16 db 24h  ; (16)
    times  32 db 00h  ; (16) to (17)  (Neftçilar proskekti)
    times   8 db 04h  ; (17)
    times  47 db 00h  ; (17) to (18)  (Neftçilar proskekti)
    times  10 db 1Ch  ; (18)
    times  24 db 00h  ; (18) to (19)  (Neftçilar proskekti)
    times   8 db 0Ah  ; (19)
    times  53 db 00h  ; (19) to (20)  (Neftçilar proskekti)
    times   8 db 04h  ; (20)
    times   1 db 00h  ; (20) to box entry (Neftçilar proskekti)
    times   1 db 37h  ; box start entrance
    times  64 db 36h  ; box entrance
    times   4 db 3Bh  ; box horz stripe
    times  16 db 39h  ; box active zone
    times   4 db 3Bh  ; box horz stripe
    times   1 db 38h  ; box start exit
    times  64 db 3Ah  ; box exit
    times  36 db 00h  ; to starting grid (Neftçilar proskekti)

    ; Collation: repeat track start.
    times  33 db 00h  ; starting grid (Neftçilar proskekti)
    times   1 db 31h  ; start/finish
    times   6 db 32h  ; checkered floor
    times   1 db 0FFh ; END
baku_track_end:

spa_track:
    ; Differently form Bakı, the scaling of this should be correct
    ; Scale: 1 piece ~= 1 mm in file
    ; https://upload.wikimedia.org/wikipedia/commons/5/54/Spa-Francorchamps_of_Belgium.svg
    ; 1843 pieces, plus 41 pcs overlap

    times  33 db 00h  ; starting grid

    times   1 db 31h  ; start/finish
    times   6 db 32h  ; checkered floor

    times  54 db 00h  ; Start -> (1)
    times   1 db 2Dh  ; 100 L
    times   9 db 00h  ; Start -> (1)
    times   1 db 2Bh  ; 50 L
    times   9 db 00h  ; Start -> (1)

    times  26 db 11h  ; (1) Source

    times  50 db 00h  ; (1) -> (2)
    times  50 db 02h  ; (2)

    times  50 db 00h  ; (2) -> (3)

    times  17 db 23h  ; (3) Eau Rouge
    times  65 db 07h  ; (4) Eau Rouge
    times  24 db 1Ch  ; (5) Eau Rouge

    times  80 db 00h  ; (5) -> (6)
    times  30 db 02h  ; (6)
    times  86 db 00h  ; (6) -> (7) Kemmel
    times   1 db 2Fh  ; 150 L
    times   1 db 30h  ; 150 R
    times   8 db 00h  ; (6) -> (7) Kemmel
    times   1 db 2Dh  ; 100 L
    times   1 db 2Eh  ; 100 R
    times   8 db 00h  ; (6) -> (7) Kemmel
    times   1 db 2Bh  ; 50 L
    times   1 db 2Ch  ; 50 R
    times   8 db 00h  ; (6) -> (7) Kemmel

    times  20 db 0Eh  ; (7) Les Combes
    times  10 db 00h  ; (7) -> (8) Les Combes
    times  20 db 24h  ; (8) Les Combes
    times  25 db 00h  ; (8) -> (9) Les Combes
    times  24 db 0Ch  ; (9) Les Combes

    times  60 db 00h  ; (9) -> (10)
    times  60 db 0Ah  ; (10) Bruxelles

    times  40 db 00h  ; (10) -> (11)
    times  20 db 22h  ; (11)

    times  45 db 00h  ; (11) -> (12)
    times  25 db 02h  ; (11) -> (12)
    times  10 db 00h  ; (11) -> (12)
    times   1 db 2Fh  ; 150 L
    times   1 db 30h  ; 150 R
    times   8 db 00h  ; (11) -> (12)
    times   1 db 2Dh  ; 100 L
    times   1 db 2Eh  ; 100 R
    times   8 db 00h  ; (11) -> (12)
    times   1 db 2Bh  ; 50 L
    times   1 db 2Ch  ; 50 R
    times   8 db 00h  ; (11) -> (12)

    times  35 db 1Ch  ; (12) Pouhon
    times  10 db 17h  ; (12) Pouhon
    times  15 db 19h  ; (12) Pouhon
    times  10 db 17h  ; (12) Pouhon
    times  35 db 1Ah  ; (12) Pouhon

    times  40 db 00h  ; (12) -> (13)
    times   1 db 30h  ; 150 R
    times   9 db 00h  ; (12) -> (13)
    times   1 db 2Eh  ; 100 R
    times   9 db 00h  ; (12) -> (13)
    times   1 db 2Ch  ; 50 R
    times   9 db 00h  ; (12) -> (13)

    times  20 db 11h  ; (13)
    times  10 db 00h  ; (13) -> (14)
    times  25 db 21h  ; (14)
    times  35 db 00h  ; (14) -> (15)
    times  25 db 0Dh  ; (15) Campus

    times  15 db 00h  ; (15) -> (16)
    times   9 db 00h  ; (15) -> (16)
    times   1 db 2Dh  ; 100 L
    times   9 db 00h  ; (15) -> (16)
    times   1 db 2Bh  ; 50 L

    times  35 db 06h  ; (16) Stavelot

    times  10 db 00h  ; (16) -> Courbe Paul Frère
    times  45 db 02h  ; Courbe Paul Frère I
    times  23 db 00h  ; Courbe Paul Frère I -> II
    times  07 db 02h  ; Courbe Paul Frère II
    times  31 db 04h  ; Courbe Paul Frère II

    times  45 db 00h  ; (16) -> (17)
    times  60 db 18h  ; (17) Blanchimont

    times  30 db 00h  ; (17) -> (18)
    times   6 db 18h  ; (18) Angle adjustment
    times  30 db 1Ch  ; (18)

    times  60 db 00h  ; (18) -> (19)
    times  20 db 04h  ; (18) -> (19)
    times  20 db 00h  ; (18) -> (19)
    times   1 db 2Fh  ; 150 L
    times   1 db 30h  ; 150 R
    times   8 db 00h  ; (11) -> (12)
    times   1 db 2Dh  ; 100 L
    times   1 db 2Eh  ; 100 R
    times   8 db 00h  ; (11) -> (12)
    times   1 db 2Ch  ; 50 R
    times   9 db 00h  ; (11) -> (12)

    times  22 db 13h  ; (19) Chicane
    times  13 db 00h  ; (19) -> (20)
    times  24 db 29h  ; (20) Chicane

    ; Collation: repeat track start
    times  33 db 00h  ; starting grid
    times   1 db 31h  ; start/finish
    times   6 db 32h  ; checkered floor
    times   1 db 0FFh ; END

    times  61 db 0FFh  ; padding
spa_track_end:

; =============================================================================
; Cars
; =============================================================================
car_names:
    db "Rivella", 0, 0, 0
    db "AnglGerm", 0, 0
    db "Martini", 0, 0, 0
car_names_end:

car1_filename:
    db "dcr1"
car1_filename_end:
car2_filename:
    db "dcr2"
car2_filename_end:
car3_filename:
    db "dcr3"
car3_filename_end:

carsel_filename:
    db "DMLCSEL", 0
carsel_filename_end:

pitstuff_filename:
    db "DML-PIT", 0
pitstuff_filename_end:

engines:  ; use gpc-vehicle-edit to generate
    db 0x05, 0x00, 0x9A, 0x29, 0xE0, 0x2E, 0x64, 0x00, 0xD8, 0x03, 0xD8, 0x03, 0xC0, 0x07, 0xC0, 0x07
    db 0x0C, 0x03, 0x0C, 0x03, 0x90, 0x1A, 0x00, 0x00, 0x2C, 0x7E, 0xA8, 0x61, 0x20, 0x4E, 0xAC, 0x3F
    db 0x3D, 0x37, 0x00, 0x00, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x37, 0x41, 0x46
    db 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B
    db 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x4B, 0x50, 0x50, 0x50, 0x50, 0x50
    db 0x50, 0x50, 0x55, 0x55, 0x55, 0x55, 0x5A, 0x5A, 0x5A, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F, 0x5F
    db 0x5F, 0x5F, 0x5F, 0x60, 0x60, 0x60, 0x60, 0x60, 0x61, 0x61, 0x61, 0x61, 0x61, 0x61, 0x61, 0x62
    db 0x61, 0x60, 0x5D, 0x5B, 0x58, 0x55, 0x52, 0x4E, 0x4B, 0x4A, 0x46, 0x41, 0x3D, 0x3B, 0x37, 0x37
    db 0x32, 0x2D, 0x28, 0x46, 0x46, 0x46, 0x46, 0x46, 0x46, 0x46, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00
    db 0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x50, 0x2D, 0xD4, 0x30, 0x78, 0x00, 0x3E, 0x03, 0x3E, 0x03
    db 0xDC, 0x05, 0xDC, 0x05, 0xBC, 0x02, 0xBC, 0x02, 0xDC, 0x1E, 0x00, 0x00, 0xA0, 0x8C, 0x60, 0x6D
    db 0xD8, 0x59, 0x38, 0x4A, 0xB8, 0x3D, 0x20, 0x35, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28
    db 0x28, 0x2D, 0x2D, 0x2D, 0x32, 0x32, 0x32, 0x32, 0x32, 0x32, 0x32, 0x32, 0x37, 0x37, 0x37, 0x37
    db 0x37, 0x37, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x3C, 0x41, 0x41, 0x41, 0x41
    db 0x41, 0x41, 0x41, 0x41, 0x46, 0x46, 0x46, 0x49, 0x4B, 0x4E, 0x50, 0x50, 0x50, 0x50, 0x50, 0x50
    db 0x50, 0x50, 0x50, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x5A, 0x5C, 0x5E, 0x5F
    db 0x61, 0x63, 0x65, 0x68, 0x6B, 0x6E, 0x6F, 0x71, 0x73, 0x74, 0x74, 0x75, 0x74, 0x73, 0x73, 0x72
    db 0x71, 0x70, 0x6F, 0x6E, 0x6D, 0x66, 0x5A, 0x50, 0x46, 0x46, 0x46, 0x46, 0x46, 0x46, 0x46, 0x46
    db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x06, 0x00, 0x3C, 0x28, 0xE0, 0x2E, 0x32, 0x00
    db 0x9A, 0x02, 0x5E, 0x01, 0xAA, 0x05, 0x46, 0x05, 0x58, 0x02, 0x90, 0x01, 0x4C, 0x1D, 0x00, 0x00
    db 0x00, 0x8E, 0x00, 0x6F, 0x00, 0x5B, 0xF4, 0x4B, 0x8D, 0x3E, 0x00, 0x33, 0x28, 0x28, 0x28, 0x28
    db 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x28, 0x2D, 0x2D, 0x32, 0x32, 0x32, 0x32, 0x32
    db 0x32, 0x32, 0x32, 0x32, 0x32, 0x37, 0x37, 0x37, 0x37, 0x37, 0x37, 0x37, 0x37, 0x37, 0x37, 0x3C
    db 0x3C, 0x41, 0x41, 0x41, 0x41, 0x41, 0x46, 0x46, 0x46, 0x46, 0x48, 0x4A, 0x4E, 0x4E, 0x50, 0x50
    db 0x52, 0x52, 0x54, 0x54, 0x55, 0x56, 0x57, 0x57, 0x57, 0x57, 0x57, 0x57, 0x57, 0x58, 0x58, 0x5D
    db 0x5D, 0x5D, 0x58, 0x52, 0x55, 0x57, 0x5A, 0x59, 0x5C, 0x5C, 0x5A, 0x59, 0x53, 0x55, 0x53, 0x52
    db 0x50, 0x4E, 0x49, 0x43, 0x3C, 0x32, 0x32, 0x32, 0x32, 0x32, 0x32, 0x4B, 0x46, 0x46, 0x46, 0x46
    db 0x46, 0x46, 0x46, 0x46, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
engines_end:

resident_end:

bad_param_msg db "Launch GPEGA2.BAT to play$", 0
