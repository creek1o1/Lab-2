.section .note.GNU-stack,"",@progbits   # mark stack non-executable

    .section .bss
    .globl ram
ram:
    .space 256              # shared memory; result stored at ram[0x50]

    .section .text
    .globl hammingcmp

# -------------------------------------------------------
# void hammingcmp(char *string1, char *string2)
#
#   %rdi = string1
#   %rsi = string2
#
# Algorithm:
#   For each byte index i up to min(len1, len2):
#       diff = string1[i] XOR string2[i]
#       hamming += popcount(diff)
#   Store result as a byte at ram[0x50]
# -------------------------------------------------------
hammingcmp:
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15

    movq    %rdi, %r12          # r12 = string1
    movq    %rsi, %r13          # r13 = string2

    # ── find length of string1 ──────────────────────────
    xorq    %rcx, %rcx
.len1_loop:
    movzbq  (%r12,%rcx), %rax   # load byte string1[i]
    cmpb    $0, %al             # null terminator?
    je      .len1_done
    cmpb    $10, %al            # newline? (fgets keeps it)
    je      .len1_done
    incq    %rcx
    jmp     .len1_loop
.len1_done:
    movq    %rcx, %r14          # r14 = len1

    # ── find length of string2 ──────────────────────────
    xorq    %rcx, %rcx
.len2_loop:
    movzbq  (%r13,%rcx), %rax
    cmpb    $0, %al
    je      .len2_done
    cmpb    $10, %al
    je      .len2_done
    incq    %rcx
    jmp     .len2_loop
.len2_done:
    movq    %rcx, %r15          # r15 = len2

    # ── min_len = min(len1, len2) ────────────────────────
    movq    %r14, %rbx
    cmpq    %r15, %rbx
    jle     .min_done
    movq    %r15, %rbx          # rbx = min_len
.min_done:

    # ── main loop ────────────────────────────────────────
    xorq    %r8, %r8            # r8  = index i
    xorq    %r9, %r9            # r9  = hamming total

.hamming_loop:
    cmpq    %rbx, %r8
    jge     .hamming_done

    movzbq  (%r12,%r8), %rax    # byte from string1
    movzbq  (%r13,%r8), %rcx    # byte from string2
    xorb    %cl, %al            # diff = s1[i] XOR s2[i]

    # ── popcount of %al ──────────────────────────────────
    xorq    %r10, %r10          # r10 = bit count for this byte
    movzbq  %al, %rdx           # work copy in rdx
.popcount_loop:
    testq   %rdx, %rdx
    jz      .popcount_done
    movq    %rdx, %rcx
    andq    $1, %rcx            # isolate lowest bit
    addq    %rcx, %r10
    shrq    $1, %rdx
    jmp     .popcount_loop
.popcount_done:

    addq    %r10, %r9           # accumulate
    incq    %r8
    jmp     .hamming_loop

.hamming_done:
    # ── store result at ram[0x50] ─────────────────────────
    movb    %r9b, ram+0x50(%rip)

    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    ret