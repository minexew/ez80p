
; Complete ez80 opcode list to test disassembler 

; Note: Commented out opcodes will not assemble in ZDS II - 5.1.1
; even though they are listed as valid in the docs.

			org 010000h

.assume ADL = 1

		
;--------------------------------------------------------------------------------------------------------


			adc a,(hl)
			adc.s a,(hl)
			adc.l a,(hl)
			
			adc a,ixl
			adc a,ixh
			adc a,iyl
			adc a,iyh
			
			adc a,(ix+55h)
			adc.s a,(ix+55h)
			adc.l a,(ix+55h)
			
			adc a,(iy+55h)
			adc.s a,(iy+55h)
			adc.l a,(iy+55h)
			
			adc a,0aah
			
			adc a,a
			adc a,b
			adc a,c
			adc a,d
			adc a,e
			adc a,h
			adc a,l
			
			adc hl,bc
			adc hl,de
			adc hl,hl
			adc.s hl,bc
			adc.s hl,de
			adc.s hl,hl
			adc.l hl,bc
			adc.l hl,de
			adc.l hl,hl
			
			adc hl,sp
			adc.s hl,sp
			adc.l hl,sp
			
			add a,(hl)
			add.s a,(hl)
			add.l a,(hl)
			
			add a,ixl
			add a,ixh
			add a,iyl
			add a,iyh
			
			add a,(ix+55h)
			add.s a,(ix+55h)
			add.l a,(ix+55h)
			
			add a,(iy+55h)
			add.s a,(iy+55h)
			add.l a,(iy+55h)
			
			add a,0aah
			
			add a,a
			add a,b
			add a,c
			add a,d
			add a,e
			add a,h
			add a,l
			
			add hl,bc
			add hl,de
			add hl,hl
			add.s hl,bc
			add.s hl,de
			add.s hl,hl
			add.l hl,bc
			add.l hl,de
			add.l hl,hl
			
			add hl,sp
			add.s hl,sp
			add.l hl,sp
			
			add ix,bc
			add ix,de
			add ix,ix
			add.s ix,bc
			add.s ix,de
			add.s ix,ix
			add.l ix,bc
			add.l ix,de
			add.l ix,ix
			
			add iy,bc
			add iy,de
			add iy,iy
			add.s iy,bc
			add.s iy,de
			add.s iy,iy
			add.l iy,bc
			add.l iy,de
			add.l iy,iy
			
			add ix,sp
			add.s ix,sp
			add.l ix,sp
			
			add iy,sp
			add.s iy,sp
			add.l iy,sp
			
			and a,(hl)
			and.s a,(hl)
			and.l a,(hl)
			
			and a,ixl
			and a,ixh
			and a,iyl
			and a,iyh
			
			and a,(ix+55h)
			and.s a,(ix+55h)
			and.l a,(ix+55h)
			
			and a,(iy+55h)
			and.s a,(iy+55h)
			and.l a,(iy+55h)
			
			and a,0aah
			
			and a,a
			and a,b
			and a,c
			and a,d
			and a,e
			and a,h
			and a,l
			
			bit 0,(hl)
			bit.s 0,(hl)
			bit.l 0,(hl)
			bit 1,(hl)
			bit.s 1,(hl)
			bit.l 1,(hl)
			bit 2,(hl)
			bit.s 2,(hl)
			bit.l 2,(hl)
			bit 3,(hl)
			bit.s 3,(hl)
			bit.l 3,(hl)
			bit 4,(hl)
			bit.s 4,(hl)
			bit.l 4,(hl)
			bit 5,(hl)
			bit.s 5,(hl)
			bit.l 5,(hl)
			bit 6,(hl)
			bit.s 6,(hl)
			bit.l 6,(hl)
			bit 7,(hl)
			bit.s 7,(hl)
			bit.l 7,(hl)
			
			bit 0,(ix+55h)
			bit.s 0,(ix+55h)
			bit.l 0,(ix+55h)
			bit 1,(ix+55h)
			bit.s 1,(ix+55h)
			bit.l 1,(ix+55h)
			bit 2,(ix+55h)
			bit.s 2,(ix+55h)
			bit.l 2,(ix+55h)
			bit 3,(ix+55h)
			bit.s 3,(ix+55h)
			bit.l 3,(ix+55h)
			bit 4,(ix+55h)
			bit.s 4,(ix+55h)
			bit.l 4,(ix+55h)
			bit 5,(ix+55h)
			bit.s 5,(ix+55h)
			bit.l 5,(ix+55h)
			bit 6,(ix+55h)
			bit.s 6,(ix+55h)
			bit.l 6,(ix+55h)
			bit 7,(ix+55h)
			bit.s 7,(ix+55h)
			bit.l 7,(ix+55h)
			
			bit 0,(iy+55h)
			bit.s 0,(iy+55h)
			bit.l 0,(iy+55h)
			bit 1,(iy+55h)
			bit.s 1,(iy+55h)
			bit.l 1,(iy+55h)
			bit 2,(iy+55h)
			bit.s 2,(iy+55h)
			bit.l 2,(iy+55h)
			bit 3,(iy+55h)
			bit.s 3,(iy+55h)
			bit.l 3,(iy+55h)
			bit 4,(iy+55h)
			bit.s 4,(iy+55h)
			bit.l 4,(iy+55h)
			bit 5,(iy+55h)
			bit.s 5,(iy+55h)
			bit.l 5,(iy+55h)
			bit 6,(iy+55h)
			bit.s 6,(iy+55h)
			bit.l 6,(iy+55h)
			bit 7,(iy+55h)
			bit.s 7,(iy+55h)
			bit.l 7,(iy+55h)
			
			bit 0,a
			bit 1,a
			bit 2,a
			bit 3,a
			bit 4,a
			bit 5,a
			bit 6,a
			bit 7,a
			
			bit 0,b
			bit 1,b
			bit 2,b
			bit 3,b
			bit 4,b
			bit 5,b
			bit 6,b
			bit 7,b
			
			bit 0,c
			bit 1,c
			bit 2,c
			bit 3,c
			bit 4,c
			bit 5,c
			bit 6,c
			bit 7,c
			
			bit 0,d
			bit 1,d
			bit 2,d
			bit 3,d
			bit 4,d
			bit 5,d
			bit 6,d
			bit 7,d
			
			bit 0,e
			bit 1,e
			bit 2,e
			bit 3,e
			bit 4,e
			bit 5,e
			bit 6,e
			bit 7,e
			
			bit 0,h
			bit 1,h
			bit 2,h
			bit 3,h
			bit 4,h
			bit 5,h
			bit 6,h
			bit 7,h
			
			bit 0,l
			bit 1,l
			bit 2,l
			bit 3,l
			bit 4,l
			bit 5,l
			bit 6,l
			bit 7,l
			
			call nz,123456h
			call z,123456h
			call nc,123456h
			call c,123456h
			call po,123456h
			call pe,123456h
			call p,123456h
			call m,123456h
			
			call.is nz,1234h
			call.is z,1234h
			call.is nc,1234h
			call.is c,1234h
			call.is po,1234h
			call.is pe,1234h
			call.is p,1234h
			call.is m,1234h
			
			call.il nz,123456h
			call.il z,123456h
			call.il nc,123456h
			call.il c,123456h
			call.il po,123456h
			call.il pe,123456h
			call.il p,123456h
			call.il m,123456h
			
			call 123456h
			call.is 1234h
			call.il 123456h
			
			ccf
			
			cp a,(hl)
			cp a,ixl
			cp a,ixh
			cp a,iyl
			cp a,iyh
			
			cp a,(ix+55h)
			cp.s a,(ix+55h)
			cp.l a,(ix+55h)
			
			cp a,(iy+55h)
			cp.s a,(iy+55h)
			cp.l a,(iy+55h)
			
			cp a,0aah
			cp a,a
			cp a,b
			cp a,c
			cp a,d
			cp a,e
			cp a,h
			cp a,l
			
			cpd
			cpdr
			cpi
			cpir
			cpd.s
			cpdr.s
			cpi.s
			cpir.s
			cpd.l
			cpdr.l
			cpi.l
			cpir.l
			
			cpl
						
			daa
			
			dec (hl)
			dec.s (hl)
			dec.l (hl)
			
			dec ixl
			dec ixh
			dec iyl
			dec iyh
			
			dec ix
			dec.s ix
			dec.l ix
			
			dec iy
			dec.s iy
			dec.l iy
			
			dec (ix+55h)
			dec.s (ix+55h)
			dec.l (ix+55h)
			
			dec (iy+55h)
			dec.s (iy+55h)
			dec.l (iy+55h)
			
			dec a
			dec b
			dec c
			dec d
			dec e
			dec h
			dec l
			
			dec bc
			dec.s bc
			dec.l bc
			
			dec de
			dec.s de
			dec.l de
			
			dec hl
			dec.s hl
			dec.l hl
			
			dec sp
			dec.s sp
			dec.l sp
			
lp1			di

			djnz lp1
			
			ei
			
			ex af,af'
			ex de,hl
			ex (sp),hl
			ex.s (sp),hl
			ex.l (sp),hl
			
			ex (sp),ix
			ex.s (sp),ix
			ex.l (sp),ix
			ex (sp),iy
			ex.s (sp),iy
			ex.l (sp),iy
			
			exx
			
			halt
			
			im 0
			
			im 1
			
			im 2
			
			in a,(55h)
			
			in a,(bc)
			in b,(bc)
			in c,(bc)
			in d,(bc)
			in e,(bc)
			in h,(bc)
			in l,(bc)
			
			in0 a,(55h)
			in0 b,(55h)
			in0 c,(55h)
			in0 d,(55h)
			in0 e,(55h)
			in0 h,(55h)
			in0 l,(55h)
			
			inc (hl)
			inc.s (hl)
			inc.l (hl)
			
			inc ixl
			inc ixh
			inc iyl
			inc iyh
			
			inc ix
			inc.s ix
			inc.l ix
			
			inc iy
			inc.s iy
			inc.l iy
			
			inc (ix+55h)
			inc.s (ix+55h)
			inc.l (ix+55h)
			
			inc (iy+55h)
			inc.s (iy+55h)
			inc.l (iy+55h)
			
			inc a
			inc b
			inc c
			inc d
			inc e
			inc h
			inc l
			
			inc bc
			inc.s bc
			inc.l bc
			
			inc de
			inc.s de
			inc.l de
			
			inc hl
			inc.s hl
			inc.l hl
			
			inc sp
			inc.s sp
			inc.l sp
			
			
			ind
			ind2
			ind2r
			indm
			indmr
			indr
			indrx
			ini
			ini2
			ini2r
			inim
			inimr
			inir
			inirx

			ind.s
			ind2.s
			ind2r.s
			indm.s
			indmr.s
			indr.s
			indrx.s
			ini.s
			ini2.s
			ini2r.s
			inim.s
			inimr.s
			inir.s
			inirx.s

			ind.l
			ind2.l
			ind2r.l
			indm.l
			indmr.l
			indr.l
			indrx.l
			ini.l
			ini2.l
			ini2r.l
			inim.l
			inimr.l
			inir.l
			inirx.l

			jp nz,123456h
			jp z,123456h
			jp nc,123456h
			jp c,123456h
			jp po,123456h
			jp pe,123456h
			jp p,123456h
			jp m,123456h

			jp.sis nz,1234h
			jp.sis z,1234h
			jp.sis nc,1234h
			jp.sis c,1234h
			jp.sis po,1234h
			jp.sis pe,1234h
			jp.sis p,1234h
			jp.sis m,1234h

			jp.lil nz,123456h
			jp.lil z,123456h
			jp.lil nc,123456h
			jp.lil c,123456h
			jp.lil po,123456h
			jp.lil pe,123456h
			jp.lil p,123456h
			jp.lil m,123456h

			jp 123456h
			jp.sis 1234h
			jp.lil 123456h
			
			jp (hl)
			jp.s (hl)
			jp.l (hl)
			
			jp (ix)
			jp.s (ix)
			jp.l (ix)
			
			jp (iy)
			jp.s (iy)
			jp.l (iy)
			
here		jr here
			jr z,here
			jr nz,here
			jr c,here
			jr nc,here
			
			ld a,i
			
			ld a,(ix+55h)
			ld.s a,(ix+55h)
			ld.l a,(ix+55h)
			
			ld a,(iy+55h)
			ld.s a,(iy+55h)
			ld.l a,(iy+55h)
			
			ld a,mb
			
			ld a,(123456h)
			ld.sis a,(1234h)
			ld.lil a,(123456h)
			
			ld a,r
			
			ld a,(bc)
			ld.s a,(bc)
			ld.l a,(bc)
			ld a,(de)
			ld.s a,(de)
			ld.l a,(de)
			ld a,(hl)
			ld.s a,(hl)
			ld.l a,(hl)
			
			ld (hl),ix
			ld.s (hl),ix
			ld.l (hl),ix
			ld (hl),iy
			ld.s (hl),iy
			ld.l (hl),iy
			
			ld (hl),0aah
			
			ld (hl),a
			ld (hl),b
			ld (hl),c
			ld (hl),d
			ld (hl),e
			ld (hl),h
			ld (hl),l
			
			ld.s (hl),a
			ld.s (hl),b
			ld.s (hl),c
			ld.s (hl),d
			ld.s (hl),e
			ld.s (hl),h
			ld.s (hl),l
			
			ld.l (hl),a
			ld.l (hl),b
			ld.l (hl),c
			ld.l (hl),d
			ld.l (hl),e
			ld.l (hl),h
			ld.l (hl),l
			
			ld (hl),bc
			ld (hl),de
			ld (hl),hl
			ld.s (hl),bc
			ld.s (hl),de
			ld.s (hl),hl
			ld.l (hl),bc
			ld.l (hl),de
			ld.l (hl),hl
			
			ld i,a
			
			ld ixl,ixl
			ld ixl,ixh
			ld ixh,ixl
			ld ixh,ixh
			
			ld iyl,iyl
			ld iyl,iyh
			ld iyh,iyl
			ld iyh,iyh
			
			ld ixl,55h
			ld ixh,55h
			ld iyl,55h
			ld iyh,55h
			
			ld ixl,a
			ld ixl,b
			ld ixl,c
			ld ixl,d
			ld ixl,e
			ld ixh,a
			ld ixh,b
			ld ixh,c
			ld ixh,d
			ld ixh,e
			
			ld iyl,a
			ld iyl,b
			ld iyl,c
			ld iyl,d
			ld iyl,e
			ld iyh,a
			ld iyh,b
			ld iyh,c
			ld iyh,d
			ld iyh,e
			
			ld ix,(hl)
			ld.s ix,(hl)
			ld.l ix,(hl)
			ld iy,(hl)
			ld.s iy,(hl)
			ld.l iy,(hl)
			
			ld ix,(ix+55h)
			ld.s ix,(ix+55h)
			ld.l ix,(ix+55h)
			ld iy,(ix+55h)
			ld.s iy,(ix+55h)
			ld.l iy,(ix+55h)
			ld ix,(iy+55h)
			ld.s ix,(iy+55h)
			ld.l ix,(iy+55h)
			ld iy,(iy+55h)
			ld.s iy,(iy+55h)
			ld.l iy,(iy+55h)
			
			ld ix,123456h
			ld.sis ix,1234h
			ld.lil ix,123456h
			
			ld iy,123456h
			ld.sis iy,1234h
			ld.lil iy,123456h
			
			ld ix,(123456h)
			ld.sis ix,(1234h)
			ld.lil ix,(123456h)
			
			ld iy,(123456h)
			ld.sis iy,(1234h)
			ld.lil iy,(123456h)
			
			ld (ix+55h),ix
			ld.s (ix+55h),ix
			ld.l (ix+55h),ix
			ld (ix+55h),iy
			ld.s (ix+55h),iy
			ld.l (ix+55h),iy
			
			ld (iy+55h),ix
			ld.s (iy+55h),ix
			ld.l (iy+55h),ix
			ld (iy+55h),iy
			ld.s (iy+55h),iy
			ld.l (iy+55h),iy
			
			ld (ix+55h),12h
			ld.s (ix+55h),12h
			ld.l (ix+55h),12h
			ld (iy+55h),12h
			ld.s (iy+55h),12h
			ld.l (iy+55h),12h
			
			ld (ix+55h),a
			ld.s (ix+55h),a
			ld.l (ix+55h),a
			ld (ix+55h),b
			ld.s (ix+55h),b
			ld.l (ix+55h),b
			ld (ix+55h),c
			ld.s (ix+55h),c
			ld.l (ix+55h),c
			ld (ix+55h),d
			ld.s (ix+55h),d
			ld.l (ix+55h),d
			ld (ix+55h),e
			ld.s (ix+55h),e
			ld.l (ix+55h),e
			ld (ix+55h),h
			ld.s (ix+55h),h
			ld.l (ix+55h),h
			ld (ix+55h),l
			ld.s (ix+55h),l
			ld.l (ix+55h),l
			
			ld (iy+55h),a
			ld.s (iy+55h),a
			ld.l (iy+55h),a
			ld (iy+55h),b
			ld.s (iy+55h),b
			ld.l (iy+55h),b
			ld (iy+55h),c
			ld.s (iy+55h),c
			ld.l (iy+55h),c
			ld (iy+55h),d
			ld.s (iy+55h),d
			ld.l (iy+55h),d
			ld (iy+55h),e
			ld.s (iy+55h),e
			ld.l (iy+55h),e
			ld (iy+55h),h
			ld.s (iy+55h),h
			ld.l (iy+55h),h
			ld (iy+55h),l
			ld.s (iy+55h),l
			ld.l (iy+55h),l
			
			ld (ix+55h),bc
			ld.s (ix+55h),bc
			ld.l (ix+55h),bc
			ld (ix+55h),de
			ld.s (ix+55h),de
			ld.l (ix+55h),de
			ld (ix+55h),hl
			ld.s (ix+55h),hl
			ld.l (ix+55h),hl
			
			ld (iy+55h),bc
			ld.s (iy+55h),bc
			ld.l (iy+55h),bc
			ld (iy+55h),de
			ld.s (iy+55h),de
			ld.l (iy+55h),de
			ld (iy+55h),hl
			ld.s (iy+55h),hl
			ld.l (iy+55h),hl
			
			ld mb,a
			
			ld (123456h),a
			ld.is (1234h),a
			ld.il (123456h),a
			
			ld (123456h),ix
			ld.sis (1234h),ix
			ld.lil (123456h),ix
			ld (123456h),iy
			ld.sis (1234h),iy
			ld.lil (123456h),iy
			
			ld (123456h),bc
			ld.sis (1234h),bc
			ld.lil (123456h),bc
			ld (123456h),de
			ld.sis (1234h),de
			ld.lil (123456h),de
			ld (123456h),hl
			ld.sis (1234h),hl
			ld.lil (123456h),hl
			
			ld (123456h),sp
			ld.sis (1234h),sp
			ld.lil (123456h),sp
			
			ld r,a
			
			ld a,(hl)
			ld b,(hl)
			ld c,(hl)
			ld d,(hl)
			ld e,(hl)
			ld h,(hl)
			ld l,(hl)
			
;			ld.s a,(hl)
;			ld.s b,(hl)
;			ld.s c,(hl)
;			ld.s d,(hl)
;			ld.s e,(hl)
;			ld.s h,(hl)
;			ld.s l,(hl)
					
;			ld.l a,(hl)
;			ld.l b,(hl)
;			ld.l c,(hl)
;			ld.l d,(hl)
;			ld.l e,(hl)
;			ld.l h,(hl)
;			ld.l l,(hl)

			ld a,ixl
			ld b,ixl
			ld c,ixl
			ld d,ixl
			ld e,ixl
			ld a,ixh
			ld b,ixh
			ld c,ixh
			ld d,ixh
			ld e,ixh
			
			ld a,iyl
			ld b,iyl
			ld c,iyl
			ld d,iyl
			ld e,iyl
			ld a,iyh
			ld b,iyh
			ld c,iyh
			ld d,iyh
			ld e,iyh
			
			ld a,(ix+55h)
			ld.s a,(ix+55h)
			ld.l a,(ix+55h)
			ld b,(ix+55h)
			ld.s b,(ix+55h)
			ld.l b,(ix+55h)
			ld c,(ix+55h)
			ld.s c,(ix+55h)
			ld.l c,(ix+55h)
			ld d,(ix+55h)
			ld.s d,(ix+55h)
			ld.l d,(ix+55h)
			ld e,(ix+55h)
			ld.s e,(ix+55h)
			ld.l e,(ix+55h)
			ld h,(ix+55h)
			ld.s h,(ix+55h)
			ld.l h,(ix+55h)
			ld l,(ix+55h)
			ld.s l,(ix+55h)
			ld.l l,(ix+55h)
			
			ld a,(iy+55h)
			ld.s a,(iy+55h)
			ld.l a,(iy+55h)
			ld b,(iy+55h)
			ld.s b,(iy+55h)
			ld.l b,(iy+55h)
			ld c,(iy+55h)
			ld.s c,(iy+55h)
			ld.l c,(iy+55h)
			ld d,(iy+55h)
			ld.s d,(iy+55h)
			ld.l d,(iy+55h)
			ld e,(iy+55h)
			ld.s e,(iy+55h)
			ld.l e,(iy+55h)
			ld h,(iy+55h)
			ld.s h,(iy+55h)
			ld.l h,(iy+55h)
			ld l,(iy+55h)
			ld.s l,(iy+55h)
			ld.l l,(iy+55h)
			
			ld a,12h
			ld b,12h
			ld c,12h
			ld d,12h
			ld e,12h
			ld h,12h
			ld l,12h
			
			ld a,b
			ld a,c
			ld a,d
			ld a,e
			ld a,h
			ld a,l
			
			ld b,a
			ld b,c
			ld b,d
			ld b,e
			ld b,h
			ld b,l
			
			ld c,a
			ld c,b
			ld c,d
			ld c,e
			ld c,h
			ld c,l
			
			ld d,a
			ld d,b
			ld d,c
			ld d,e
			ld d,h
			ld d,l
			
			ld e,a
			ld e,b
			ld e,c
			ld e,d
			ld e,h
			ld e,l
			
			ld h,a
			ld h,b
			ld h,c
			ld h,d
			ld h,e
			ld h,l
			
			ld l,a
			ld l,b
			ld l,c
			ld l,d
			ld l,e
			ld l,h
			
			ld bc,(hl)
			ld.s bc,(hl)
			ld.l bc,(hl)
			ld de,(hl)
			ld.s de,(hl)
			ld.l de,(hl)
			ld hl,(hl)
			ld.s hl,(hl)
			ld.l hl,(hl)
			
			ld bc,(ix+55h)
			ld.s bc,(ix+55h)
			ld.l bc,(ix+55h)
			ld de,(ix+55h)
			ld.s de,(ix+55h)
			ld.l de,(ix+55h)
			ld hl,(ix+55h)
			ld.s hl,(ix+55h)
			ld.l hl,(ix+55h)
			
			ld bc,(iy+55h)
			ld.s bc,(iy+55h)
			ld.l bc,(iy+55h)
			ld de,(iy+55h)
			ld.s de,(iy+55h)
			ld.l de,(iy+55h)
			ld hl,(iy+55h)
			ld.s hl,(iy+55h)
			ld.l hl,(iy+55h)

			ld bc,123456h
			ld.sis bc,1234h
			ld.lil bc,123456h
			ld de,123456h
			ld.sis de,1234h
			ld.lil de,123456h
			ld hl,123456h
			ld.sis hl,1234h
			ld.lil hl,123456h
			

			ld bc,(123456h)
			ld.sis bc,(1234h)
			ld.lil bc,(123456h)
			ld de,(123456h)
			ld.sis de,(1234h)
			ld.lil de,(123456h)
			ld hl,(123456h)
			ld.sis hl,(1234h)
			ld.lil hl,(123456h)
			
			ld (bc),a
			ld.s (bc),a
			ld.l (bc),a
			ld (de),a
			ld.s (de),a
			ld.l (de),a
			ld (hl),a
			ld.s (hl),a
			ld.l (hl),a
			
			ld sp,hl
			ld.s sp,hl
			ld.l sp,hl
			
			ld sp,ix
			ld.s sp,ix
			ld.l sp,ix
			ld sp,iy
			ld.s sp,iy
			ld.l sp,iy
			
			ld sp,123456h
			ld.sis sp,1234h
			ld.lil sp,123456h
			
			ld sp,(123456h)
			ld.sis sp,(1234h)
			ld.lil sp,(123456h)
			
			ldd
			ldd.s
			ldd.l
			lddr
			lddr.s
			lddr.l
			ldi
			ldi.s
			ldi.l
			ldir
			ldir.s
			ldir.l
			
			lea ix,ix+55h
			lea.s ix,ix+55h
			lea.l ix,ix+55h
			lea iy,ix+55h
			lea.s iy,ix+55h
			lea.l iy,ix+55h
			
			lea ix,iy+55h
			lea.s ix,iy+55h
			lea.l ix,iy+55h
			lea iy,iy+55h
			lea.s iy,iy+55h
			lea.l iy,iy+55h
			
			lea bc,ix+55h
			lea.s bc,ix+55h
			lea.l bc,ix+55h
			lea de,ix+55h
			lea.s de,ix+55h
			lea.l de,ix+55h
			lea hl,ix+55h
			lea.s hl,ix+55h
			lea.l hl,ix+55h
			
			lea bc,iy+55h
			lea.s bc,iy+55h
			lea.l bc,iy+55h
			lea de,iy+55h
			lea.s de,iy+55h
			lea.l de,iy+55h
			lea hl,iy+55h
			lea.s hl,iy+55h
			lea.l hl,iy+55h
			
			mlt bc
			mlt de
			mlt hl
			mlt sp
			
			neg
			
			nop
			
			or a,(hl)
			or.s a,(hl)
			or.l a,(hl)
			
			or a,ixl
			or a,ixh
			or a,iyl
			or a,iyh
			
			or a,(ix+55h)
			or.s a,(ix+55h)
			or.l a,(ix+55h)
			
			or a,(iy+55h)
			or.s a,(iy+55h)
			or.l a,(iy+55h)
			
			or a,0aah
			
			or a,a
			or a,b
			or a,c
			or a,d
			or a,e
			or a,h
			or a,l
			
			otd2r
			otdm
			otdmr
			otdr
			otdrx
			oti2r
			otim
			otimr
			otir
			otirx
			
			otd2r.s
			otdm.s
			otdmr.s
			otdr.s
			otdrx.s
			oti2r.s
			otim.s
			otimr.s
			otir.s
			otirx.s
			
			otd2r.l
			otdm.l
			otdmr.l
			otdr.l
			otdrx.l
			oti2r.l
			otim.l
			otimr.l
			otir.l
			otirx.l
			
			out (bc),a
			out (bc),b
			out (bc),c
			out (bc),d
			out (bc),e
			out (bc),h
			out (bc),l

			out (12h),a
			
			out0 (12h),a
			out0 (12h),b
			out0 (12h),c
			out0 (12h),d
			out0 (12h),e
			out0 (12h),h
			out0 (12h),l
			
			outd
			outd2
			outi
			outi2
			
			outd.s
			outd2.s
			outi.s
			outi2.s

			outd.l
			outd2.l
			outi.l
			outi2.l

			pea ix+55h
			pea.s ix+55h
			pea.l ix+55h
			
			pea iy+55h
			pea.s iy+55h
			pea.l iy+55h
			
			pop af
			pop.s af
			pop.l af
			pop ix
			pop.s ix
			pop.l ix
			pop iy
			pop.s iy
			pop.l iy
			pop bc
			pop.s bc
			pop.l bc
			pop de
			pop.s de
			pop.l de
			pop hl
			pop.s hl
			pop.l hl
			
			push af
			push.s af
			push.l af
			push ix
			push.s ix
			push.l ix
			push iy
			push.s iy
			push.l iy
			push bc
			push.s bc
			push.l bc
			push de
			push.s de
			push.l de
			push hl
			push.s hl
			push.l hl
			
			
			res 0,(hl)
			res.s 0,(hl)
			res.l 0,(hl)
			res 1,(hl)
			res.s 1,(hl)
			res.l 1,(hl)
			res 2,(hl)
			res.s 2,(hl)
			res.l 2,(hl)
			res 3,(hl)
			res.s 3,(hl)
			res.l 3,(hl)
			res 4,(hl)
			res.s 4,(hl)
			res.l 4,(hl)
			res 5,(hl)
			res.s 5,(hl)
			res.l 5,(hl)
			res 6,(hl)
			res.s 6,(hl)
			res.l 6,(hl)
			res 7,(hl)
			res.s 7,(hl)
			res.l 7,(hl)
			
			res 0,(ix+55h)
			res.s 0,(ix+55h)
			res.l 0,(ix+55h)
			res 1,(ix+55h)
			res.s 1,(ix+55h)
			res.l 1,(ix+55h)
			res 2,(ix+55h)
			res.s 2,(ix+55h)
			res.l 2,(ix+55h)
			res 3,(ix+55h)
			res.s 3,(ix+55h)
			res.l 3,(ix+55h)
			res 4,(ix+55h)
			res.s 4,(ix+55h)
			res.l 4,(ix+55h)
			res 5,(ix+55h)
			res.s 5,(ix+55h)
			res.l 5,(ix+55h)
			res 6,(ix+55h)
			res.s 6,(ix+55h)
			res.l 6,(ix+55h)
			res 7,(ix+55h)
			res.s 7,(ix+55h)
			res.l 7,(ix+55h)
			
			res 0,(iy+55h)
			res.s 0,(iy+55h)
			res.l 0,(iy+55h)
			res 1,(iy+55h)
			res.s 1,(iy+55h)
			res.l 1,(iy+55h)
			res 2,(iy+55h)
			res.s 2,(iy+55h)
			res.l 2,(iy+55h)
			res 3,(iy+55h)
			res.s 3,(iy+55h)
			res.l 3,(iy+55h)
			res 4,(iy+55h)
			res.s 4,(iy+55h)
			res.l 4,(iy+55h)
			res 5,(iy+55h)
			res.s 5,(iy+55h)
			res.l 5,(iy+55h)
			res 6,(iy+55h)
			res.s 6,(iy+55h)
			res.l 6,(iy+55h)
			res 7,(iy+55h)
			res.s 7,(iy+55h)
			res.l 7,(iy+55h)
			
			res 0,a
			res 1,a
			res 2,a
			res 3,a
			res 4,a
			res 5,a
			res 6,a
			res 7,a
			
			res 0,b
			res 1,b
			res 2,b
			res 3,b
			res 4,b
			res 5,b
			res 6,b
			res 7,b
			
			res 0,c
			res 1,c
			res 2,c
			res 3,c
			res 4,c
			res 5,c
			res 6,c
			res 7,c
			
			res 0,d
			res 1,d
			res 2,d
			res 3,d
			res 4,d
			res 5,d
			res 6,d
			res 7,d
			
			res 0,e
			res 1,e
			res 2,e
			res 3,e
			res 4,e
			res 5,e
			res 6,e
			res 7,e
			
			res 0,h
			res 1,h
			res 2,h
			res 3,h
			res 4,h
			res 5,h
			res 6,h
			res 7,h
			
			res 0,l
			res 1,l
			res 2,l
			res 3,l
			res 4,l
			res 5,l
			res 6,l
			res 7,l
			
			
			ret
			ret.lil
				
			ret nz
			ret z
			ret nc
			ret c
			ret po
			ret pe
			ret p
			ret m
						
			ret.lil nz
			ret.lil z
			ret.lil nc
			ret.lil c
			ret.lil po
			ret.lil pe
			ret.lil p
			ret.lil m

			reti
			reti.l
			retn
			retn.l
			
			rl (hl)
			rl.s (hl)
			rl.l (hl)
			rl (ix+55h)
			rl.s (ix+55h)
			rl.l (ix+55h)
			rl (iy+55h)
			rl.s (iy+55h)
			rl.l (iy+55h)
			rl a
			rl b
			rl c
			rl d
			rl e
			rl h
			rl l
			rla
			
			rlc (hl)
			rlc.s (hl)
			rlc.l (hl)
			rlc (ix+55h)
			rlc.s (ix+55h)
			rlc.l (ix+55h)
			rlc (iy+55h)
			rlc.s (iy+55h)
			rlc.l (iy+55h)
			rlc a
			rlc b
			rlc c
			rlc d
			rlc e
			rlc h
			rlc l
			rlca
			
			rld
			
			rr (hl)
			rr.s (hl)
			rr.l (hl)
			rr (ix+55h)
			rr.s (ix+55h)
			rr.l (ix+55h)
			rr (iy+55h)
			rr.s (iy+55h)
			rr.l (iy+55h)
			rr a
			rr b
			rr c
			rr d
			rr e
			rr h
			rr l
			rra
			
			rrc (hl)
			rrc.s (hl)
			rrc.l (hl)
			rrc (ix+55h)
			rrc.s (ix+55h)
			rrc.l (ix+55h)
			rrc (iy+55h)
			rrc.s (iy+55h)
			rrc.l (iy+55h)
			rrc a
			rrc b
			rrc c
			rrc d
			rrc e
			rrc h
			rrc l
			rrca
			
			rrd
			
			rsmix
			
			rst 0
			rst 8
			rst 10h
			rst 18h
			rst 20h
			rst 28h
			rst 30h
			rst 38h
			
			rst.s 0
			rst.s 8
			rst.s 10h
			rst.s 18h
			rst.s 20h
			rst.s 28h
			rst.s 30h
			rst.s 38h
			
			rst.l 0
			rst.l 8
			rst.l 10h
			rst.l 18h
			rst.l 20h
			rst.l 28h
			rst.l 30h
			rst.l 38h
			
			sbc a,(hl)
			sbc.s a,(hl)
			sbc.l a,(hl)
			
			sbc a,ixl
			sbc a,ixh
			sbc a,iyl
			sbc a,iyh
			
			sbc a,(ix+55h)
			sbc.s a,(ix+55h)
			sbc.l a,(ix+55h)
			
			sbc a,(iy+55h)
			sbc.s a,(iy+55h)
			sbc.l a,(iy+55h)
			
			sbc a,0aah
			
			sbc a,a
			sbc a,b
			sbc a,c
			sbc a,d
			sbc a,e
			sbc a,h
			sbc a,l
			
			sbc hl,bc
			sbc hl,de
			sbc hl,hl
			sbc.s hl,bc
			sbc.s hl,de
			sbc.s hl,hl
			sbc.l hl,bc
			sbc.l hl,de
			sbc.l hl,hl
			
			sbc hl,sp
			sbc.s hl,sp
			sbc.l hl,sp

			scf
			
			set 0,(hl)
			set.s 0,(hl)
			set.l 0,(hl)
			set 1,(hl)
			set.s 1,(hl)
			set.l 1,(hl)
			set 2,(hl)
			set.s 2,(hl)
			set.l 2,(hl)
			set 3,(hl)
			set.s 3,(hl)
			set.l 3,(hl)
			set 4,(hl)
			set.s 4,(hl)
			set.l 4,(hl)
			set 5,(hl)
			set.s 5,(hl)
			set.l 5,(hl)
			set 6,(hl)
			set.s 6,(hl)
			set.l 6,(hl)
			set 7,(hl)
			set.s 7,(hl)
			set.l 7,(hl)
			
			set 0,(ix+55h)
			set.s 0,(ix+55h)
			set.l 0,(ix+55h)
			set 1,(ix+55h)
			set.s 1,(ix+55h)
			set.l 1,(ix+55h)
			set 2,(ix+55h)
			set.s 2,(ix+55h)
			set.l 2,(ix+55h)
			set 3,(ix+55h)
			set.s 3,(ix+55h)
			set.l 3,(ix+55h)
			set 4,(ix+55h)
			set.s 4,(ix+55h)
			set.l 4,(ix+55h)
			set 5,(ix+55h)
			set.s 5,(ix+55h)
			set.l 5,(ix+55h)
			set 6,(ix+55h)
			set.s 6,(ix+55h)
			set.l 6,(ix+55h)
			set 7,(ix+55h)
			set.s 7,(ix+55h)
			set.l 7,(ix+55h)
			
			set 0,(iy+55h)
			set.s 0,(iy+55h)
			set.l 0,(iy+55h)
			set 1,(iy+55h)
			set.s 1,(iy+55h)
			set.l 1,(iy+55h)
			set 2,(iy+55h)
			set.s 2,(iy+55h)
			set.l 2,(iy+55h)
			set 3,(iy+55h)
			set.s 3,(iy+55h)
			set.l 3,(iy+55h)
			set 4,(iy+55h)
			set.s 4,(iy+55h)
			set.l 4,(iy+55h)
			set 5,(iy+55h)
			set.s 5,(iy+55h)
			set.l 5,(iy+55h)
			set 6,(iy+55h)
			set.s 6,(iy+55h)
			set.l 6,(iy+55h)
			set 7,(iy+55h)
			set.s 7,(iy+55h)
			set.l 7,(iy+55h)
			
			set 0,a
			set 1,a
			set 2,a
			set 3,a
			set 4,a
			set 5,a
			set 6,a
			set 7,a
			
			set 0,b
			set 1,b
			set 2,b
			set 3,b
			set 4,b
			set 5,b
			set 6,b
			set 7,b
			
			set 0,c
			set 1,c
			set 2,c
			set 3,c
			set 4,c
			set 5,c
			set 6,c
			set 7,c
			
			set 0,d
			set 1,d
			set 2,d
			set 3,d
			set 4,d
			set 5,d
			set 6,d
			set 7,d
			
			set 0,e
			set 1,e
			set 2,e
			set 3,e
			set 4,e
			set 5,e
			set 6,e
			set 7,e
			
			set 0,h
			set 1,h
			set 2,h
			set 3,h
			set 4,h
			set 5,h
			set 6,h
			set 7,h
			
			set 0,l
			set 1,l
			set 2,l
			set 3,l
			set 4,l
			set 5,l
			set 6,l
			set 7,l
			
			sla (hl)
			sla.s (hl)
			sla.l (hl)
			sla (ix+55h)
			sla.s (ix+55h)
			sla.l (ix+55h)
			sla (iy+55h)
			sla.s (iy+55h)
			sla.l (iy+55h)
			sla a
			sla b
			sla c
			sla d
			sla e
			sla h
			sla l
			
			slp
			
			sra (hl)
			sra.s (hl)
			sra.l (hl)
			sra (ix+55h)
			sra.s (ix+55h)
			sra.l (ix+55h)
			sra (iy+55h)
			sra.s (iy+55h)
			sra.l (iy+55h)
			sra a
			sra b
			sra c
			sra d
			sra e
			sra h
			sra l
			
			srl (hl)
			srl.s (hl)
			srl.l (hl)
			srl (ix+55h)
			srl.s (ix+55h)
			srl.l (ix+55h)
			srl (iy+55h)
			srl.s (iy+55h)
			srl.l (iy+55h)
			srl a
			srl b
			srl c
			srl d
			srl e
			srl h
			srl l
			
			stmix
			
			sub a,(hl)
;			sub.s a,(hl)
;			sub.l a,(hl)
			
			sub a,ixl
			sub a,ixh
			sub a,iyl
			sub a,iyh
			
			sub a,(ix+55h)
;			sub.s a,(ix+55h)
;			sub.l a,(ix+55h)
			
			sub a,(iy+55h)
;			sub.s a,(iy+55h)
			sub.l a,(iy+55h)
			
			sub a,0aah
			
			sub a,a
			sub a,b
			sub a,c
			sub a,d
			sub a,e
			sub a,h
			sub a,l

			tst a,(hl)
			tst.s a,(hl)
			tst.l a,(hl)
			
			tst a,0aah
			
			tst a,a
			tst a,b
			tst a,c
			tst a,d
			tst a,e
			tst a,h
			tst a,l

			tstio 0aah
			
			xor a,(hl)
			xor.s a,(hl)
			xor.l a,(hl)
			
			xor a,ixl
			xor a,ixh
			xor a,iyl
			xor a,iyh
			
			xor a,(ix+55h)
			xor.s a,(ix+55h)
			xor.l a,(ix+55h)
			
			xor a,(iy+55h)
			xor.s a,(iy+55h)
			xor.l a,(iy+55h)
			
			xor a,0aah
			
			xor a,a
			xor a,b
			xor a,c
			xor a,d
			xor a,e
			xor a,h
			xor a,l
			
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			nop
			
			
;-----------------------------------------------------------------------------------------------------------------
