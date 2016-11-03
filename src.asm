STACK SEGMENT PARA STACK 'stack'
    DB 100H DUP(?)
STACK ENDS


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

	typeX0MSG db "Please, type x0 here :$"
    err1MSG db 0ah,"Invalid argument$"
    buffer db 256 DUP(?),'$'
    ten dd 10.0
    
	x dd 5.6
	fact dd 1
	minus_one dd -1.0
	plus_one dd 1.0

	previous_stupid_rezult dd 0.0
	stupid_rezult dd 0.0
	factical_accuracy dd 0.0
	required_accuracy dd 0.00001
	num_of_members dd 0

	brainy_rezult dd 0.0

	x_end dd 6.6
	x_step dd 0.1
	num_of_steps dd 0

	one dd 1.0
	u_n dw 0
    count dw 0

	new_line db 0ah,"$"
	atomic_rezult db "For the x = "
	cur_iteration dd 0
	atomic_rezult2 db " e^(-x) with using function = ... and with using stupid method = ... and number of members = ... ",0ah,"$"
DATA ENDS

CODE SEGMENT PARA PUBLIC 'code'
    ASSUME CS: CODE, DS: DATA, SS: STACK
    .386
    START: MOV AX, DATA
    MOV DS, AX
    
	;
	;getting data
	;
	;CALL read_to_st
	;CALL read_to_st


	;
	;counting
	;

	CALL load_stepnum_to_cx
	lp_brainy:
		;init
		mov cur_iteration,esi
		fldz
		fst previous_stupid_rezult
		fst stupid_rezult
		fst factical_accuracy
		;brainy part
		CALL e_to_minus_x
		;end of brainy part
		;
		;begin of stupid part
		push cx
		mov cx, 100
		xor si, si
		lp1:
			push cx
			mov cx, si
			CALL addMember
			pop cx
			inc si

			CALL set_accuracy
			CALL save_previous_stupid_rezult
		loop lp1
		countedMember:
			fild num_of_members
			fld factical_accuracy
			fld stupid_rezult
		;end of stupid part
		CALL move_to_next_x
		
		fld x
    
    		CALL float_number_to_string
    
    		CALL show_float_converted

		CALL show_atomic_rezult
		pop cx
		pop cx
	loop lp_brainy
	
    ;
    MOV AX, 4C00H
    INT 21H

	e_to_minus_x proc
		fld x
		fmul minus_one
		fldl2e
		fmul
		fld st
		frndint
		fsub st(1),st
		fxch st(1)
		f2xm1
		fld1
		fadd
		fscale
		fstp st(1)
		fstp brainy_rezult
		ret
	e_to_minus_x endp

	addMember proc
		mov fact, 1
		cmp cx, 0
		jg cont1
			fld plus_one
			fadd stupid_rezult
			fstp stupid_rezult
			ret
		cont1:
		push cx
		finit
		fld x
		dec cx
		cmp cx, 0
		je cont2
		lp_x_to_n:
			fmul x
		loop lp_x_to_n
		cont2:
		fld1
		pop cx
		push cx
		lp_fact_n:
			fimul fact
			inc fact
		loop lp_fact_n
		pop cx
		push cx
		shr cx, 1
		fxch st(1)
		jnc dont_add_minus_one
			fmul minus_one
		dont_add_minus_one:
		fxch st(1)
		fdivp st(1),st
		fadd stupid_rezult
		fstp stupid_rezult
		pop cx
		ret
	addMember endp

	set_accuracy proc
		push ax
		pushf
		fld stupid_rezult
		fabs
		fld previous_stupid_rezult
		fabs
		fsubp
		fabs
		fld required_accuracy
		fabs
		fcompp
		fstsw ax
		sahf
		jc toNormalEnd

			fld stupid_rezult
			fabs
			fld previous_stupid_rezult
			fabs
			fsubp
			fstp factical_accuracy

			mov num_of_members,esi
			popf
			pop ax
			jmp countedMember
		toNormalEnd:
			popf
			pop ax
			ret
	set_accuracy endp

	save_previous_stupid_rezult proc
		fld stupid_rezult
		fstp previous_stupid_rezult
		ret
	save_previous_stupid_rezult endp

	move_to_next_x proc
		fld x
		fadd x_step
		fstp x
		ret
	move_to_next_x endp

	load_stepnum_to_cx proc
		fld x_end
		fld x
		fsubp
		fld x_step
		fdivp
		frndint
		fistp num_of_steps
		mov ecx, num_of_steps
		ret
	load_stepnum_to_cx endp

	read_to_st proc
		mov ah,0Ah              ;Функция DOS 0Ah - ввод строки в буфер
        mov [buffer],254        ;Запись максимальной длины в первый байт буфера
        mov byte[buffer+1],0    ;Обнуление второго байта (фактической длины)
        mov dx,offset buffer    ;DX = aдрес буфера
        int 21h                 ;Обращение к функции DOS
		mov ah,09h
		mov dx,offset new_line
		int 21h

	cont_1:
		mov cl, buffer[1]       ;length of string to cl
		xor ch, ch
		finit                   ;initialization of soprocessor
		fld ten                 ;10.0 ->st(0)
		fldz                    ;0->st(0), 10 ->st(1)
		lea si,buffer           ;offset buffer -> si
		add si,cx               ;in si - offset to sublast symbol in buffer
		inc si                  ;in si - offset to the last symbol in buffer
		std                     ;d = 1
		xor ax,ax

	m1:                         ;float part
		lodsb                   ;[ds:si] -> al
		cmp al,"."              ;in al dot?
        je  m2                  ;yes
		and al,0fh              ;ASCII->BCD
		mov u_n,ax
		fiadd u_n               ;складываем очередную цифру и значение в стеке сопроцессора
		fdiv st(0),st(1)        ;делим значение в вершине стека на 10
		dec cx                  ;decrement for length of string
		inc count               
		jmp m1

	m2:                         ;int part
		dec cx
		mov si, offset buffer
		add si, 2               ;si -> first symbol of string
		fldz                    ;0->st(0), float part->st(1), 10->st(2)
	m3:
		mov al, [si]            ;symbol from string -> al
		and al, 0Fh             ;ASCII->BCD
		fmul st(0), st(2)       ;st(0)=st(0)*st(2)=st(0)*10
		mov u_n, ax             
		fiadd u_n               ;st(0)+u_n->st(0)
		inc si                  ;next symbol
		loop m3                 ;while there are symbols
		fadd                    ;st(0)+st(1)->st(0) or int part + float part -> st(0)
		ret
	read_to_st endp

	show_atomic_rezult proc
		push dx
		push ax
		mov ah,09h
		mov dx, offset atomic_rezult
		int 21h
		pop ax
		pop dx
		ret
	show_atomic_rezult endp

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