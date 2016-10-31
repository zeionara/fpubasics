STACK SEGMENT PARA STACK 'stack'
    DB 100H DUP(?)
STACK ENDS
mul10 macro reg

endm

DATA SEGMENT PARA PUBLIC 'data'
    ;<<<<<<<<<<<<<<<<<<<<<<<<float_number_to_string
    cw_buffer dw 0
    minus db 0

    ten dd 10.0
    ascii_m dd 49.0
    
    len_of_int dd 0
    int_buf dd 0
    float_buf dd 0

    int_tmp dd 0
    num_str db 100 DUP (32),"$"
    float_str db 100 DUP (32),"$"
    ;>>>>>>>>>>>>>>>>>>>>>>>>>float_number_to_string
    x dd -339.789
    y dd 1923.763
DATA ENDS

CODE SEGMENT PARA PUBLIC 'code'
    ASSUME CS: CODE, DS: DATA, SS: STACK
    .386
    START: MOV AX, DATA
    MOV DS, AX
    ;
    finit

    fld y
    
    CALL float_number_to_string
    
    CALL show_float_converted
    
    ;
    MOV AX, 4C00H
    INT 21H

    ;
    ;procedures
    ;

    ceil_mode proc
        fstcw cw_buffer
        and cw_buffer,1111001111111111b
        or cw_buffer,1111011111111111b
        fldcw cw_buffer
        ret
    ceil_mode endp

    default_mode proc
        fstcw cw_buffer
        and cw_buffer,1111001111111111b
        fldcw cw_buffer
        ret
    default_mode endp

    revert_str proc
        push eax
        push edx
        xor di,di
        mov si,cx
        dec si
        lp_revert_str:
            mov al,[bx][di]
            mov dl,[bx][si]
            xchg eax,edx
            mov [bx][di],al
            mov [bx][si],dl
            inc di
            dec si
            cmp si,di
            jl exit_lp_revert_str
        loop lp_revert_str
        exit_lp_revert_str:
        pop edx
        pop eax
        ret
    revert_str endp

    int_part_to_str proc
        push si
        push cx
        push dx

        xor si,si
        mov num_str[si],36
        inc si
        mov num_str[si],46
        inc si
        convert_int:
            fild int_buf
            fldz
            fcomp
            fstsw ax
            sahf
                jz int_converted
            fld ten
            fdivp
            fst st(1)
            frndint
            fist int_buf
            fsubp
            fld ten
            fmulp
            fadd ascii_m
            fistp  int_tmp
            mov eax,int_tmp
            mov num_str[si],al
            inc si
        jmp convert_int
        int_converted:
        cmp minus,0
        je cont_without_minus
            mov num_str[si],45
            inc si
        cont_without_minus:
        mov cx,si
        mov bx,offset num_str
        CALL revert_str
        
        pop dx
        pop cx
        pop si
        ret
    int_part_to_str endp

    float_part_to_str proc
        push si
        push bx
        push dx

        xor si,si
        mov float_str[si],36
        inc si
        convert_float:
            fild float_buf
            fldz
            fcomp
            fstsw ax
            sahf
                jz float_converted
            fld ten
            fdivp
            fst st(1)
            frndint
            fist float_buf
            fsubp
            fld ten
            fmulp
            fadd ascii_m
            frndint
            fistp  int_tmp
            mov eax,int_tmp
            mov float_str[si],al
            inc si
        jmp convert_float
        float_converted:
        mov cx,si
        mov bx,offset float_str
        CALL revert_str

        pop dx
        pop cx
        pop si
        ret
    float_part_to_str endp

    take_int_part proc
        push ax

        fldz
        fcomp
        fstsw ax
        sahf
        jc not_minus
            mov minus,1
            fabs
        not_minus:
        fst st(1)       ;take int part to int_buf
        frndint
        fist int_buf

        pop ax
        ret
    take_int_part endp

    take_float_part proc
        push ax
        push cx

        fsubp           ;take float part to float_buf
        mov cx,8
        cont_search:
            fld ten
            fmul
            fst st(1)
            frndint
            fcomp
            fstsw ax
            sahf
            jz store_float
        loop cont_search
        store_float:
        frndint
        fist float_buf

        pop cx
        pop ax
        ret
    take_float_part endp

    float_number_to_string proc
        CALL ceil_mode
        CALL take_int_part
        CALL take_float_part
        CALL int_part_to_str
        CALL float_part_to_str
        CALL default_mode
        ret
    float_number_to_string endp

    show_float_converted proc
        push ax
        push dx

        mov ah,09h
        mov dx,offset num_str
        int 21h
        mov ah,09h
        mov dx,offset float_str
        int 21h

        pop dx
        pop ax
        ret
    show_float_converted endp

CODE ENDS
END START