;LZ4 data decompressor for Apple II
;Peter Ferrie (peter.ferrie@gmail.com)
;
;from http://pferrie.host22.com/misc/appleii.htm
;Converted to ATasm by Rob McMullen

;unpacker variables, set in main.s
; src	=	$0 ; source packed data
; dst	=	$2 ; destination unpacked data
; end	=	$4 ; end of source packed data
; count	=	$6 ; temporary variable
; delta	=	$8 ; temporary variable

unpack_lz4 ldy	#0

parsetoken
	jsr	getsrc
	pha
	lsr
	lsr
	lsr
	lsr
	beq	copymatches
	jsr	buildcount
	tax
	jsr	docopy
	lda	src
	cmp	end
	lda	src+1
	sbc	end+1
	bcs	done

copymatches
	jsr	getsrc
	sta	delta
	jsr	getsrc
	sta	delta+1
	pla
	and	#$0f
	jsr	buildcount
	clc
	adc	#4
	tax
	bcc	?1
	inc	count+1
?1	lda	src+1
	pha
	lda	src
	pha
	sec
	lda	dst
	sbc	delta
	sta	src
	lda	dst+1
	sbc	delta+1
	sta	src+1
	jsr	docopy
	pla
	sta	src
	pla
	sta	src+1
	jmp	parsetoken

done
	pla
	rts

docopy
	jsr	getput
	dex
	bne	docopy
	dec	count+1
	bne	docopy
	rts

buildcount
	ldx	#1
	stx	count+1
	cmp	#$0f
	bne	?3
?1	sta	count
	jsr	getsrc
	tax
	clc
	adc	count
	bcc	?2
	inc	count+1
?2	inx
	beq	?1
?3	rts

getput
	jsr	getsrc

putdst
	sta (dst), y
	inc	dst
	beq ?1
	rts
?1	inc	dst+1
	rts

getsrc
	lda (src), y
	inc	src
	beq	?1
	rts
?1	inc	src+1
	rts
