
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9b013103          	ld	sp,-1616(sp) # 800089b0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	00e70713          	addi	a4,a4,14 # 80009060 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	32c78793          	addi	a5,a5,812 # 80006390 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de278793          	addi	a5,a5,-542 # 80000e90 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	8d8080e7          	jalr	-1832(ra) # 80002a04 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	790080e7          	jalr	1936(ra) # 800008cc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	01450513          	addi	a0,a0,20 # 800111a0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a52080e7          	jalr	-1454(ra) # 80000be6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	00448493          	addi	s1,s1,4 # 800111a0 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	09290913          	addi	s2,s2,146 # 80011238 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c11                	li	s8,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5cfd                	li	s9,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4d29                	li	s10,10
  while(n > 0){
    800001b4:	07405963          	blez	s4,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71563          	bne	a4,a5,800001ea <consoleread+0x86>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	856080e7          	jalr	-1962(ra) # 80001a1a <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	2781                	sext.w	a5,a5
    800001d0:	e7b5                	bnez	a5,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85ce                	mv	a1,s3
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	18a080e7          	jalr	394(ra) # 80002360 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70fe3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d9b          	sext.w	s11,a4
    if(c == C('D')){  // end-of-file
    80000200:	078d8663          	beq	s11,s8,8000026c <consoleread+0x108>
    cbuf = c;
    80000204:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f8f40613          	addi	a2,s0,-113
    8000020e:	85d6                	mv	a1,s5
    80000210:	855a                	mv	a0,s6
    80000212:	00002097          	auipc	ra,0x2
    80000216:	79c080e7          	jalr	1948(ra) # 800029ae <either_copyout>
    8000021a:	01950663          	beq	a0,s9,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a85                	addi	s5,s5,1
    --n;
    80000220:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000222:	f9ad99e3          	bne	s11,s10,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	f7a50513          	addi	a0,a0,-134 # 800111a0 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a6c080e7          	jalr	-1428(ra) # 80000c9a <release>

  return target - n;
    80000236:	414b853b          	subw	a0,s7,s4
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	f6450513          	addi	a0,a0,-156 # 800111a0 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a56080e7          	jalr	-1450(ra) # 80000c9a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70e6                	ld	ra,120(sp)
    80000250:	7446                	ld	s0,112(sp)
    80000252:	74a6                	ld	s1,104(sp)
    80000254:	7906                	ld	s2,96(sp)
    80000256:	69e6                	ld	s3,88(sp)
    80000258:	6a46                	ld	s4,80(sp)
    8000025a:	6aa6                	ld	s5,72(sp)
    8000025c:	6b06                	ld	s6,64(sp)
    8000025e:	7be2                	ld	s7,56(sp)
    80000260:	7c42                	ld	s8,48(sp)
    80000262:	7ca2                	ld	s9,40(sp)
    80000264:	7d02                	ld	s10,32(sp)
    80000266:	6de2                	ld	s11,24(sp)
    80000268:	6109                	addi	sp,sp,128
    8000026a:	8082                	ret
      if(n < target){
    8000026c:	000a071b          	sext.w	a4,s4
    80000270:	fb777be3          	bgeu	a4,s7,80000226 <consoleread+0xc2>
        cons.r--;
    80000274:	00011717          	auipc	a4,0x11
    80000278:	fcf72223          	sw	a5,-60(a4) # 80011238 <cons+0x98>
    8000027c:	b76d                	j	80000226 <consoleread+0xc2>

000000008000027e <consputc>:
{
    8000027e:	1141                	addi	sp,sp,-16
    80000280:	e406                	sd	ra,8(sp)
    80000282:	e022                	sd	s0,0(sp)
    80000284:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000286:	10000793          	li	a5,256
    8000028a:	00f50a63          	beq	a0,a5,8000029e <consputc+0x20>
    uartputc_sync(c);
    8000028e:	00000097          	auipc	ra,0x0
    80000292:	564080e7          	jalr	1380(ra) # 800007f2 <uartputc_sync>
}
    80000296:	60a2                	ld	ra,8(sp)
    80000298:	6402                	ld	s0,0(sp)
    8000029a:	0141                	addi	sp,sp,16
    8000029c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029e:	4521                	li	a0,8
    800002a0:	00000097          	auipc	ra,0x0
    800002a4:	552080e7          	jalr	1362(ra) # 800007f2 <uartputc_sync>
    800002a8:	02000513          	li	a0,32
    800002ac:	00000097          	auipc	ra,0x0
    800002b0:	546080e7          	jalr	1350(ra) # 800007f2 <uartputc_sync>
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	53c080e7          	jalr	1340(ra) # 800007f2 <uartputc_sync>
    800002be:	bfe1                	j	80000296 <consputc+0x18>

00000000800002c0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c0:	1101                	addi	sp,sp,-32
    800002c2:	ec06                	sd	ra,24(sp)
    800002c4:	e822                	sd	s0,16(sp)
    800002c6:	e426                	sd	s1,8(sp)
    800002c8:	e04a                	sd	s2,0(sp)
    800002ca:	1000                	addi	s0,sp,32
    800002cc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002ce:	00011517          	auipc	a0,0x11
    800002d2:	ed250513          	addi	a0,a0,-302 # 800111a0 <cons>
    800002d6:	00001097          	auipc	ra,0x1
    800002da:	910080e7          	jalr	-1776(ra) # 80000be6 <acquire>

  switch(c){
    800002de:	47d5                	li	a5,21
    800002e0:	0af48663          	beq	s1,a5,8000038c <consoleintr+0xcc>
    800002e4:	0297ca63          	blt	a5,s1,80000318 <consoleintr+0x58>
    800002e8:	47a1                	li	a5,8
    800002ea:	0ef48763          	beq	s1,a5,800003d8 <consoleintr+0x118>
    800002ee:	47c1                	li	a5,16
    800002f0:	10f49a63          	bne	s1,a5,80000404 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f4:	00002097          	auipc	ra,0x2
    800002f8:	766080e7          	jalr	1894(ra) # 80002a5a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fc:	00011517          	auipc	a0,0x11
    80000300:	ea450513          	addi	a0,a0,-348 # 800111a0 <cons>
    80000304:	00001097          	auipc	ra,0x1
    80000308:	996080e7          	jalr	-1642(ra) # 80000c9a <release>
}
    8000030c:	60e2                	ld	ra,24(sp)
    8000030e:	6442                	ld	s0,16(sp)
    80000310:	64a2                	ld	s1,8(sp)
    80000312:	6902                	ld	s2,0(sp)
    80000314:	6105                	addi	sp,sp,32
    80000316:	8082                	ret
  switch(c){
    80000318:	07f00793          	li	a5,127
    8000031c:	0af48e63          	beq	s1,a5,800003d8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000320:	00011717          	auipc	a4,0x11
    80000324:	e8070713          	addi	a4,a4,-384 # 800111a0 <cons>
    80000328:	0a072783          	lw	a5,160(a4)
    8000032c:	09872703          	lw	a4,152(a4)
    80000330:	9f99                	subw	a5,a5,a4
    80000332:	07f00713          	li	a4,127
    80000336:	fcf763e3          	bltu	a4,a5,800002fc <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033a:	47b5                	li	a5,13
    8000033c:	0cf48763          	beq	s1,a5,8000040a <consoleintr+0x14a>
      consputc(c);
    80000340:	8526                	mv	a0,s1
    80000342:	00000097          	auipc	ra,0x0
    80000346:	f3c080e7          	jalr	-196(ra) # 8000027e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000034a:	00011797          	auipc	a5,0x11
    8000034e:	e5678793          	addi	a5,a5,-426 # 800111a0 <cons>
    80000352:	0a07a703          	lw	a4,160(a5)
    80000356:	0017069b          	addiw	a3,a4,1
    8000035a:	0006861b          	sext.w	a2,a3
    8000035e:	0ad7a023          	sw	a3,160(a5)
    80000362:	07f77713          	andi	a4,a4,127
    80000366:	97ba                	add	a5,a5,a4
    80000368:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036c:	47a9                	li	a5,10
    8000036e:	0cf48563          	beq	s1,a5,80000438 <consoleintr+0x178>
    80000372:	4791                	li	a5,4
    80000374:	0cf48263          	beq	s1,a5,80000438 <consoleintr+0x178>
    80000378:	00011797          	auipc	a5,0x11
    8000037c:	ec07a783          	lw	a5,-320(a5) # 80011238 <cons+0x98>
    80000380:	0807879b          	addiw	a5,a5,128
    80000384:	f6f61ce3          	bne	a2,a5,800002fc <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000388:	863e                	mv	a2,a5
    8000038a:	a07d                	j	80000438 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038c:	00011717          	auipc	a4,0x11
    80000390:	e1470713          	addi	a4,a4,-492 # 800111a0 <cons>
    80000394:	0a072783          	lw	a5,160(a4)
    80000398:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039c:	00011497          	auipc	s1,0x11
    800003a0:	e0448493          	addi	s1,s1,-508 # 800111a0 <cons>
    while(cons.e != cons.w &&
    800003a4:	4929                	li	s2,10
    800003a6:	f4f70be3          	beq	a4,a5,800002fc <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003aa:	37fd                	addiw	a5,a5,-1
    800003ac:	07f7f713          	andi	a4,a5,127
    800003b0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b2:	01874703          	lbu	a4,24(a4)
    800003b6:	f52703e3          	beq	a4,s2,800002fc <consoleintr+0x3c>
      cons.e--;
    800003ba:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003be:	10000513          	li	a0,256
    800003c2:	00000097          	auipc	ra,0x0
    800003c6:	ebc080e7          	jalr	-324(ra) # 8000027e <consputc>
    while(cons.e != cons.w &&
    800003ca:	0a04a783          	lw	a5,160(s1)
    800003ce:	09c4a703          	lw	a4,156(s1)
    800003d2:	fcf71ce3          	bne	a4,a5,800003aa <consoleintr+0xea>
    800003d6:	b71d                	j	800002fc <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d8:	00011717          	auipc	a4,0x11
    800003dc:	dc870713          	addi	a4,a4,-568 # 800111a0 <cons>
    800003e0:	0a072783          	lw	a5,160(a4)
    800003e4:	09c72703          	lw	a4,156(a4)
    800003e8:	f0f70ae3          	beq	a4,a5,800002fc <consoleintr+0x3c>
      cons.e--;
    800003ec:	37fd                	addiw	a5,a5,-1
    800003ee:	00011717          	auipc	a4,0x11
    800003f2:	e4f72923          	sw	a5,-430(a4) # 80011240 <cons+0xa0>
      consputc(BACKSPACE);
    800003f6:	10000513          	li	a0,256
    800003fa:	00000097          	auipc	ra,0x0
    800003fe:	e84080e7          	jalr	-380(ra) # 8000027e <consputc>
    80000402:	bded                	j	800002fc <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000404:	ee048ce3          	beqz	s1,800002fc <consoleintr+0x3c>
    80000408:	bf21                	j	80000320 <consoleintr+0x60>
      consputc(c);
    8000040a:	4529                	li	a0,10
    8000040c:	00000097          	auipc	ra,0x0
    80000410:	e72080e7          	jalr	-398(ra) # 8000027e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000414:	00011797          	auipc	a5,0x11
    80000418:	d8c78793          	addi	a5,a5,-628 # 800111a0 <cons>
    8000041c:	0a07a703          	lw	a4,160(a5)
    80000420:	0017069b          	addiw	a3,a4,1
    80000424:	0006861b          	sext.w	a2,a3
    80000428:	0ad7a023          	sw	a3,160(a5)
    8000042c:	07f77713          	andi	a4,a4,127
    80000430:	97ba                	add	a5,a5,a4
    80000432:	4729                	li	a4,10
    80000434:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000438:	00011797          	auipc	a5,0x11
    8000043c:	e0c7a223          	sw	a2,-508(a5) # 8001123c <cons+0x9c>
        wakeup(&cons.r);
    80000440:	00011517          	auipc	a0,0x11
    80000444:	df850513          	addi	a0,a0,-520 # 80011238 <cons+0x98>
    80000448:	00002097          	auipc	ra,0x2
    8000044c:	120080e7          	jalr	288(ra) # 80002568 <wakeup>
    80000450:	b575                	j	800002fc <consoleintr+0x3c>

0000000080000452 <consoleinit>:

void
consoleinit(void)
{
    80000452:	1141                	addi	sp,sp,-16
    80000454:	e406                	sd	ra,8(sp)
    80000456:	e022                	sd	s0,0(sp)
    80000458:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045a:	00008597          	auipc	a1,0x8
    8000045e:	bb658593          	addi	a1,a1,-1098 # 80008010 <etext+0x10>
    80000462:	00011517          	auipc	a0,0x11
    80000466:	d3e50513          	addi	a0,a0,-706 # 800111a0 <cons>
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	6ec080e7          	jalr	1772(ra) # 80000b56 <initlock>

  uartinit();
    80000472:	00000097          	auipc	ra,0x0
    80000476:	330080e7          	jalr	816(ra) # 800007a2 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047a:	00021797          	auipc	a5,0x21
    8000047e:	6be78793          	addi	a5,a5,1726 # 80021b38 <devsw>
    80000482:	00000717          	auipc	a4,0x0
    80000486:	ce270713          	addi	a4,a4,-798 # 80000164 <consoleread>
    8000048a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048c:	00000717          	auipc	a4,0x0
    80000490:	c7670713          	addi	a4,a4,-906 # 80000102 <consolewrite>
    80000494:	ef98                	sd	a4,24(a5)
}
    80000496:	60a2                	ld	ra,8(sp)
    80000498:	6402                	ld	s0,0(sp)
    8000049a:	0141                	addi	sp,sp,16
    8000049c:	8082                	ret

000000008000049e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049e:	7179                	addi	sp,sp,-48
    800004a0:	f406                	sd	ra,40(sp)
    800004a2:	f022                	sd	s0,32(sp)
    800004a4:	ec26                	sd	s1,24(sp)
    800004a6:	e84a                	sd	s2,16(sp)
    800004a8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004aa:	c219                	beqz	a2,800004b0 <printint+0x12>
    800004ac:	08054663          	bltz	a0,80000538 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b0:	2501                	sext.w	a0,a0
    800004b2:	4881                	li	a7,0
    800004b4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004ba:	2581                	sext.w	a1,a1
    800004bc:	00008617          	auipc	a2,0x8
    800004c0:	b8460613          	addi	a2,a2,-1148 # 80008040 <digits>
    800004c4:	883a                	mv	a6,a4
    800004c6:	2705                	addiw	a4,a4,1
    800004c8:	02b577bb          	remuw	a5,a0,a1
    800004cc:	1782                	slli	a5,a5,0x20
    800004ce:	9381                	srli	a5,a5,0x20
    800004d0:	97b2                	add	a5,a5,a2
    800004d2:	0007c783          	lbu	a5,0(a5)
    800004d6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004da:	0005079b          	sext.w	a5,a0
    800004de:	02b5553b          	divuw	a0,a0,a1
    800004e2:	0685                	addi	a3,a3,1
    800004e4:	feb7f0e3          	bgeu	a5,a1,800004c4 <printint+0x26>

  if(sign)
    800004e8:	00088b63          	beqz	a7,800004fe <printint+0x60>
    buf[i++] = '-';
    800004ec:	fe040793          	addi	a5,s0,-32
    800004f0:	973e                	add	a4,a4,a5
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x8e>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d60080e7          	jalr	-672(ra) # 8000027e <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7c>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf9d                	j	800004b4 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	d007aa23          	sw	zero,-748(a5) # 80011260 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	e3a50513          	addi	a0,a0,-454 # 800083a8 <digits+0x368>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00009717          	auipc	a4,0x9
    80000584:	a8f72023          	sw	a5,-1408(a4) # 80009000 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00011d97          	auipc	s11,0x11
    800005c0:	ca4dad83          	lw	s11,-860(s11) # 80011260 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	16050263          	beqz	a0,8000073c <printf+0x1b2>
    800005dc:	4481                	li	s1,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b13          	li	s6,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b97          	auipc	s7,0x8
    800005ec:	a58b8b93          	addi	s7,s7,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00011517          	auipc	a0,0x11
    800005fe:	c4e50513          	addi	a0,a0,-946 # 80011248 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5e4080e7          	jalr	1508(ra) # 80000be6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c62080e7          	jalr	-926(ra) # 8000027e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2485                	addiw	s1,s1,1
    80000626:	009a07b3          	add	a5,s4,s1
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050763          	beqz	a0,8000073c <printf+0x1b2>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2485                	addiw	s1,s1,1
    80000638:	009a07b3          	add	a5,s4,s1
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000644:	cfe5                	beqz	a5,8000073c <printf+0x1b2>
    switch(c){
    80000646:	05678a63          	beq	a5,s6,8000069a <printf+0x110>
    8000064a:	02fb7663          	bgeu	s6,a5,80000676 <printf+0xec>
    8000064e:	09978963          	beq	a5,s9,800006e0 <printf+0x156>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79863          	bne	a5,a4,80000726 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e32080e7          	jalr	-462(ra) # 8000049e <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	0b578263          	beq	a5,s5,8000071a <printf+0x190>
    8000067a:	0b879663          	bne	a5,s8,80000726 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0e080e7          	jalr	-498(ra) # 8000049e <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bd0080e7          	jalr	-1072(ra) # 8000027e <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc4080e7          	jalr	-1084(ra) # 8000027e <consputc>
    800006c2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c9d793          	srli	a5,s3,0x3c
    800006c8:	97de                	add	a5,a5,s7
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bb0080e7          	jalr	-1104(ra) # 8000027e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0992                	slli	s3,s3,0x4
    800006d8:	397d                	addiw	s2,s2,-1
    800006da:	fe0915e3          	bnez	s2,800006c4 <printf+0x13a>
    800006de:	b799                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e0:	f8843783          	ld	a5,-120(s0)
    800006e4:	00878713          	addi	a4,a5,8
    800006e8:	f8e43423          	sd	a4,-120(s0)
    800006ec:	0007b903          	ld	s2,0(a5)
    800006f0:	00090e63          	beqz	s2,8000070c <printf+0x182>
      for(; *s; s++)
    800006f4:	00094503          	lbu	a0,0(s2)
    800006f8:	d515                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006fa:	00000097          	auipc	ra,0x0
    800006fe:	b84080e7          	jalr	-1148(ra) # 8000027e <consputc>
      for(; *s; s++)
    80000702:	0905                	addi	s2,s2,1
    80000704:	00094503          	lbu	a0,0(s2)
    80000708:	f96d                	bnez	a0,800006fa <printf+0x170>
    8000070a:	bf29                	j	80000624 <printf+0x9a>
        s = "(null)";
    8000070c:	00008917          	auipc	s2,0x8
    80000710:	91490913          	addi	s2,s2,-1772 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000714:	02800513          	li	a0,40
    80000718:	b7cd                	j	800006fa <printf+0x170>
      consputc('%');
    8000071a:	8556                	mv	a0,s5
    8000071c:	00000097          	auipc	ra,0x0
    80000720:	b62080e7          	jalr	-1182(ra) # 8000027e <consputc>
      break;
    80000724:	b701                	j	80000624 <printf+0x9a>
      consputc('%');
    80000726:	8556                	mv	a0,s5
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b56080e7          	jalr	-1194(ra) # 8000027e <consputc>
      consputc(c);
    80000730:	854a                	mv	a0,s2
    80000732:	00000097          	auipc	ra,0x0
    80000736:	b4c080e7          	jalr	-1204(ra) # 8000027e <consputc>
      break;
    8000073a:	b5ed                	j	80000624 <printf+0x9a>
  if(locking)
    8000073c:	020d9163          	bnez	s11,8000075e <printf+0x1d4>
}
    80000740:	70e6                	ld	ra,120(sp)
    80000742:	7446                	ld	s0,112(sp)
    80000744:	74a6                	ld	s1,104(sp)
    80000746:	7906                	ld	s2,96(sp)
    80000748:	69e6                	ld	s3,88(sp)
    8000074a:	6a46                	ld	s4,80(sp)
    8000074c:	6aa6                	ld	s5,72(sp)
    8000074e:	6b06                	ld	s6,64(sp)
    80000750:	7be2                	ld	s7,56(sp)
    80000752:	7c42                	ld	s8,48(sp)
    80000754:	7ca2                	ld	s9,40(sp)
    80000756:	7d02                	ld	s10,32(sp)
    80000758:	6de2                	ld	s11,24(sp)
    8000075a:	6129                	addi	sp,sp,192
    8000075c:	8082                	ret
    release(&pr.lock);
    8000075e:	00011517          	auipc	a0,0x11
    80000762:	aea50513          	addi	a0,a0,-1302 # 80011248 <pr>
    80000766:	00000097          	auipc	ra,0x0
    8000076a:	534080e7          	jalr	1332(ra) # 80000c9a <release>
}
    8000076e:	bfc9                	j	80000740 <printf+0x1b6>

0000000080000770 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000770:	1101                	addi	sp,sp,-32
    80000772:	ec06                	sd	ra,24(sp)
    80000774:	e822                	sd	s0,16(sp)
    80000776:	e426                	sd	s1,8(sp)
    80000778:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077a:	00011497          	auipc	s1,0x11
    8000077e:	ace48493          	addi	s1,s1,-1330 # 80011248 <pr>
    80000782:	00008597          	auipc	a1,0x8
    80000786:	8b658593          	addi	a1,a1,-1866 # 80008038 <etext+0x38>
    8000078a:	8526                	mv	a0,s1
    8000078c:	00000097          	auipc	ra,0x0
    80000790:	3ca080e7          	jalr	970(ra) # 80000b56 <initlock>
  pr.locking = 1;
    80000794:	4785                	li	a5,1
    80000796:	cc9c                	sw	a5,24(s1)
}
    80000798:	60e2                	ld	ra,24(sp)
    8000079a:	6442                	ld	s0,16(sp)
    8000079c:	64a2                	ld	s1,8(sp)
    8000079e:	6105                	addi	sp,sp,32
    800007a0:	8082                	ret

00000000800007a2 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a2:	1141                	addi	sp,sp,-16
    800007a4:	e406                	sd	ra,8(sp)
    800007a6:	e022                	sd	s0,0(sp)
    800007a8:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007aa:	100007b7          	lui	a5,0x10000
    800007ae:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b2:	f8000713          	li	a4,-128
    800007b6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ba:	470d                	li	a4,3
    800007bc:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c8:	469d                	li	a3,7
    800007ca:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007ce:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d2:	00008597          	auipc	a1,0x8
    800007d6:	88658593          	addi	a1,a1,-1914 # 80008058 <digits+0x18>
    800007da:	00011517          	auipc	a0,0x11
    800007de:	a8e50513          	addi	a0,a0,-1394 # 80011268 <uart_tx_lock>
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	374080e7          	jalr	884(ra) # 80000b56 <initlock>
}
    800007ea:	60a2                	ld	ra,8(sp)
    800007ec:	6402                	ld	s0,0(sp)
    800007ee:	0141                	addi	sp,sp,16
    800007f0:	8082                	ret

00000000800007f2 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f2:	1101                	addi	sp,sp,-32
    800007f4:	ec06                	sd	ra,24(sp)
    800007f6:	e822                	sd	s0,16(sp)
    800007f8:	e426                	sd	s1,8(sp)
    800007fa:	1000                	addi	s0,sp,32
    800007fc:	84aa                	mv	s1,a0
  push_off();
    800007fe:	00000097          	auipc	ra,0x0
    80000802:	39c080e7          	jalr	924(ra) # 80000b9a <push_off>

  if(panicked){
    80000806:	00008797          	auipc	a5,0x8
    8000080a:	7fa7a783          	lw	a5,2042(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000812:	c391                	beqz	a5,80000816 <uartputc_sync+0x24>
    for(;;)
    80000814:	a001                	j	80000814 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081a:	0ff7f793          	andi	a5,a5,255
    8000081e:	0207f793          	andi	a5,a5,32
    80000822:	dbf5                	beqz	a5,80000816 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000824:	0ff4f793          	andi	a5,s1,255
    80000828:	10000737          	lui	a4,0x10000
    8000082c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000830:	00000097          	auipc	ra,0x0
    80000834:	40a080e7          	jalr	1034(ra) # 80000c3a <pop_off>
}
    80000838:	60e2                	ld	ra,24(sp)
    8000083a:	6442                	ld	s0,16(sp)
    8000083c:	64a2                	ld	s1,8(sp)
    8000083e:	6105                	addi	sp,sp,32
    80000840:	8082                	ret

0000000080000842 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000842:	00008717          	auipc	a4,0x8
    80000846:	7c673703          	ld	a4,1990(a4) # 80009008 <uart_tx_r>
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7c67b783          	ld	a5,1990(a5) # 80009010 <uart_tx_w>
    80000852:	06e78c63          	beq	a5,a4,800008ca <uartstart+0x88>
{
    80000856:	7139                	addi	sp,sp,-64
    80000858:	fc06                	sd	ra,56(sp)
    8000085a:	f822                	sd	s0,48(sp)
    8000085c:	f426                	sd	s1,40(sp)
    8000085e:	f04a                	sd	s2,32(sp)
    80000860:	ec4e                	sd	s3,24(sp)
    80000862:	e852                	sd	s4,16(sp)
    80000864:	e456                	sd	s5,8(sp)
    80000866:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000868:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086c:	00011a17          	auipc	s4,0x11
    80000870:	9fca0a13          	addi	s4,s4,-1540 # 80011268 <uart_tx_lock>
    uart_tx_r += 1;
    80000874:	00008497          	auipc	s1,0x8
    80000878:	79448493          	addi	s1,s1,1940 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087c:	00008997          	auipc	s3,0x8
    80000880:	79498993          	addi	s3,s3,1940 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000884:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000888:	0ff7f793          	andi	a5,a5,255
    8000088c:	0207f793          	andi	a5,a5,32
    80000890:	c785                	beqz	a5,800008b8 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000892:	01f77793          	andi	a5,a4,31
    80000896:	97d2                	add	a5,a5,s4
    80000898:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089c:	0705                	addi	a4,a4,1
    8000089e:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	cc6080e7          	jalr	-826(ra) # 80002568 <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	6098                	ld	a4,0(s1)
    800008b0:	0009b783          	ld	a5,0(s3)
    800008b4:	fce798e3          	bne	a5,a4,80000884 <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008de:	00011517          	auipc	a0,0x11
    800008e2:	98a50513          	addi	a0,a0,-1654 # 80011268 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	300080e7          	jalr	768(ra) # 80000be6 <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	7127a783          	lw	a5,1810(a5) # 80009000 <panicked>
    800008f6:	c391                	beqz	a5,800008fa <uartputc+0x2e>
    for(;;)
    800008f8:	a001                	j	800008f8 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fa:	00008797          	auipc	a5,0x8
    800008fe:	7167b783          	ld	a5,1814(a5) # 80009010 <uart_tx_w>
    80000902:	00008717          	auipc	a4,0x8
    80000906:	70673703          	ld	a4,1798(a4) # 80009008 <uart_tx_r>
    8000090a:	02070713          	addi	a4,a4,32
    8000090e:	02f71b63          	bne	a4,a5,80000944 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000912:	00011a17          	auipc	s4,0x11
    80000916:	956a0a13          	addi	s4,s4,-1706 # 80011268 <uart_tx_lock>
    8000091a:	00008497          	auipc	s1,0x8
    8000091e:	6ee48493          	addi	s1,s1,1774 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00008917          	auipc	s2,0x8
    80000926:	6ee90913          	addi	s2,s2,1774 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000092a:	85d2                	mv	a1,s4
    8000092c:	8526                	mv	a0,s1
    8000092e:	00002097          	auipc	ra,0x2
    80000932:	a32080e7          	jalr	-1486(ra) # 80002360 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000936:	00093783          	ld	a5,0(s2)
    8000093a:	6098                	ld	a4,0(s1)
    8000093c:	02070713          	addi	a4,a4,32
    80000940:	fef705e3          	beq	a4,a5,8000092a <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000944:	00011497          	auipc	s1,0x11
    80000948:	92448493          	addi	s1,s1,-1756 # 80011268 <uart_tx_lock>
    8000094c:	01f7f713          	andi	a4,a5,31
    80000950:	9726                	add	a4,a4,s1
    80000952:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000956:	0785                	addi	a5,a5,1
    80000958:	00008717          	auipc	a4,0x8
    8000095c:	6af73c23          	sd	a5,1720(a4) # 80009010 <uart_tx_w>
      uartstart();
    80000960:	00000097          	auipc	ra,0x0
    80000964:	ee2080e7          	jalr	-286(ra) # 80000842 <uartstart>
      release(&uart_tx_lock);
    80000968:	8526                	mv	a0,s1
    8000096a:	00000097          	auipc	ra,0x0
    8000096e:	330080e7          	jalr	816(ra) # 80000c9a <release>
}
    80000972:	70a2                	ld	ra,40(sp)
    80000974:	7402                	ld	s0,32(sp)
    80000976:	64e2                	ld	s1,24(sp)
    80000978:	6942                	ld	s2,16(sp)
    8000097a:	69a2                	ld	s3,8(sp)
    8000097c:	6a02                	ld	s4,0(sp)
    8000097e:	6145                	addi	sp,sp,48
    80000980:	8082                	ret

0000000080000982 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000982:	1141                	addi	sp,sp,-16
    80000984:	e422                	sd	s0,8(sp)
    80000986:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000988:	100007b7          	lui	a5,0x10000
    8000098c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000990:	8b85                	andi	a5,a5,1
    80000992:	cb91                	beqz	a5,800009a6 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000994:	100007b7          	lui	a5,0x10000
    80000998:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a0:	6422                	ld	s0,8(sp)
    800009a2:	0141                	addi	sp,sp,16
    800009a4:	8082                	ret
    return -1;
    800009a6:	557d                	li	a0,-1
    800009a8:	bfe5                	j	800009a0 <uartgetc+0x1e>

00000000800009aa <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009aa:	1101                	addi	sp,sp,-32
    800009ac:	ec06                	sd	ra,24(sp)
    800009ae:	e822                	sd	s0,16(sp)
    800009b0:	e426                	sd	s1,8(sp)
    800009b2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b4:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b6:	00000097          	auipc	ra,0x0
    800009ba:	fcc080e7          	jalr	-52(ra) # 80000982 <uartgetc>
    if(c == -1)
    800009be:	00950763          	beq	a0,s1,800009cc <uartintr+0x22>
      break;
    consoleintr(c);
    800009c2:	00000097          	auipc	ra,0x0
    800009c6:	8fe080e7          	jalr	-1794(ra) # 800002c0 <consoleintr>
  while(1){
    800009ca:	b7f5                	j	800009b6 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009cc:	00011497          	auipc	s1,0x11
    800009d0:	89c48493          	addi	s1,s1,-1892 # 80011268 <uart_tx_lock>
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	210080e7          	jalr	528(ra) # 80000be6 <acquire>
  uartstart();
    800009de:	00000097          	auipc	ra,0x0
    800009e2:	e64080e7          	jalr	-412(ra) # 80000842 <uartstart>
  release(&uart_tx_lock);
    800009e6:	8526                	mv	a0,s1
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	2b2080e7          	jalr	690(ra) # 80000c9a <release>
}
    800009f0:	60e2                	ld	ra,24(sp)
    800009f2:	6442                	ld	s0,16(sp)
    800009f4:	64a2                	ld	s1,8(sp)
    800009f6:	6105                	addi	sp,sp,32
    800009f8:	8082                	ret

00000000800009fa <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fa:	1101                	addi	sp,sp,-32
    800009fc:	ec06                	sd	ra,24(sp)
    800009fe:	e822                	sd	s0,16(sp)
    80000a00:	e426                	sd	s1,8(sp)
    80000a02:	e04a                	sd	s2,0(sp)
    80000a04:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a06:	03451793          	slli	a5,a0,0x34
    80000a0a:	ebb9                	bnez	a5,80000a60 <kfree+0x66>
    80000a0c:	84aa                	mv	s1,a0
    80000a0e:	00025797          	auipc	a5,0x25
    80000a12:	5f278793          	addi	a5,a5,1522 # 80026000 <end>
    80000a16:	04f56563          	bltu	a0,a5,80000a60 <kfree+0x66>
    80000a1a:	47c5                	li	a5,17
    80000a1c:	07ee                	slli	a5,a5,0x1b
    80000a1e:	04f57163          	bgeu	a0,a5,80000a60 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a22:	6605                	lui	a2,0x1
    80000a24:	4585                	li	a1,1
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	2bc080e7          	jalr	700(ra) # 80000ce2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2e:	00011917          	auipc	s2,0x11
    80000a32:	87290913          	addi	s2,s2,-1934 # 800112a0 <kmem>
    80000a36:	854a                	mv	a0,s2
    80000a38:	00000097          	auipc	ra,0x0
    80000a3c:	1ae080e7          	jalr	430(ra) # 80000be6 <acquire>
  r->next = kmem.freelist;
    80000a40:	01893783          	ld	a5,24(s2)
    80000a44:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a46:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4a:	854a                	mv	a0,s2
    80000a4c:	00000097          	auipc	ra,0x0
    80000a50:	24e080e7          	jalr	590(ra) # 80000c9a <release>
}
    80000a54:	60e2                	ld	ra,24(sp)
    80000a56:	6442                	ld	s0,16(sp)
    80000a58:	64a2                	ld	s1,8(sp)
    80000a5a:	6902                	ld	s2,0(sp)
    80000a5c:	6105                	addi	sp,sp,32
    80000a5e:	8082                	ret
    panic("kfree");
    80000a60:	00007517          	auipc	a0,0x7
    80000a64:	60050513          	addi	a0,a0,1536 # 80008060 <digits+0x20>
    80000a68:	00000097          	auipc	ra,0x0
    80000a6c:	ad8080e7          	jalr	-1320(ra) # 80000540 <panic>

0000000080000a70 <freerange>:
{
    80000a70:	7179                	addi	sp,sp,-48
    80000a72:	f406                	sd	ra,40(sp)
    80000a74:	f022                	sd	s0,32(sp)
    80000a76:	ec26                	sd	s1,24(sp)
    80000a78:	e84a                	sd	s2,16(sp)
    80000a7a:	e44e                	sd	s3,8(sp)
    80000a7c:	e052                	sd	s4,0(sp)
    80000a7e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a80:	6785                	lui	a5,0x1
    80000a82:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a86:	94aa                	add	s1,s1,a0
    80000a88:	757d                	lui	a0,0xfffff
    80000a8a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8c:	94be                	add	s1,s1,a5
    80000a8e:	0095ee63          	bltu	a1,s1,80000aaa <freerange+0x3a>
    80000a92:	892e                	mv	s2,a1
    kfree(p);
    80000a94:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a96:	6985                	lui	s3,0x1
    kfree(p);
    80000a98:	01448533          	add	a0,s1,s4
    80000a9c:	00000097          	auipc	ra,0x0
    80000aa0:	f5e080e7          	jalr	-162(ra) # 800009fa <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa4:	94ce                	add	s1,s1,s3
    80000aa6:	fe9979e3          	bgeu	s2,s1,80000a98 <freerange+0x28>
}
    80000aaa:	70a2                	ld	ra,40(sp)
    80000aac:	7402                	ld	s0,32(sp)
    80000aae:	64e2                	ld	s1,24(sp)
    80000ab0:	6942                	ld	s2,16(sp)
    80000ab2:	69a2                	ld	s3,8(sp)
    80000ab4:	6a02                	ld	s4,0(sp)
    80000ab6:	6145                	addi	sp,sp,48
    80000ab8:	8082                	ret

0000000080000aba <kinit>:
{
    80000aba:	1141                	addi	sp,sp,-16
    80000abc:	e406                	sd	ra,8(sp)
    80000abe:	e022                	sd	s0,0(sp)
    80000ac0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac2:	00007597          	auipc	a1,0x7
    80000ac6:	5a658593          	addi	a1,a1,1446 # 80008068 <digits+0x28>
    80000aca:	00010517          	auipc	a0,0x10
    80000ace:	7d650513          	addi	a0,a0,2006 # 800112a0 <kmem>
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	084080e7          	jalr	132(ra) # 80000b56 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ada:	45c5                	li	a1,17
    80000adc:	05ee                	slli	a1,a1,0x1b
    80000ade:	00025517          	auipc	a0,0x25
    80000ae2:	52250513          	addi	a0,a0,1314 # 80026000 <end>
    80000ae6:	00000097          	auipc	ra,0x0
    80000aea:	f8a080e7          	jalr	-118(ra) # 80000a70 <freerange>
}
    80000aee:	60a2                	ld	ra,8(sp)
    80000af0:	6402                	ld	s0,0(sp)
    80000af2:	0141                	addi	sp,sp,16
    80000af4:	8082                	ret

0000000080000af6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af6:	1101                	addi	sp,sp,-32
    80000af8:	ec06                	sd	ra,24(sp)
    80000afa:	e822                	sd	s0,16(sp)
    80000afc:	e426                	sd	s1,8(sp)
    80000afe:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b00:	00010497          	auipc	s1,0x10
    80000b04:	7a048493          	addi	s1,s1,1952 # 800112a0 <kmem>
    80000b08:	8526                	mv	a0,s1
    80000b0a:	00000097          	auipc	ra,0x0
    80000b0e:	0dc080e7          	jalr	220(ra) # 80000be6 <acquire>
  r = kmem.freelist;
    80000b12:	6c84                	ld	s1,24(s1)
  if(r)
    80000b14:	c885                	beqz	s1,80000b44 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b16:	609c                	ld	a5,0(s1)
    80000b18:	00010517          	auipc	a0,0x10
    80000b1c:	78850513          	addi	a0,a0,1928 # 800112a0 <kmem>
    80000b20:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b22:	00000097          	auipc	ra,0x0
    80000b26:	178080e7          	jalr	376(ra) # 80000c9a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2a:	6605                	lui	a2,0x1
    80000b2c:	4595                	li	a1,5
    80000b2e:	8526                	mv	a0,s1
    80000b30:	00000097          	auipc	ra,0x0
    80000b34:	1b2080e7          	jalr	434(ra) # 80000ce2 <memset>
  return (void*)r;
}
    80000b38:	8526                	mv	a0,s1
    80000b3a:	60e2                	ld	ra,24(sp)
    80000b3c:	6442                	ld	s0,16(sp)
    80000b3e:	64a2                	ld	s1,8(sp)
    80000b40:	6105                	addi	sp,sp,32
    80000b42:	8082                	ret
  release(&kmem.lock);
    80000b44:	00010517          	auipc	a0,0x10
    80000b48:	75c50513          	addi	a0,a0,1884 # 800112a0 <kmem>
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	14e080e7          	jalr	334(ra) # 80000c9a <release>
  if(r)
    80000b54:	b7d5                	j	80000b38 <kalloc+0x42>

0000000080000b56 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b56:	1141                	addi	sp,sp,-16
    80000b58:	e422                	sd	s0,8(sp)
    80000b5a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b62:	00053823          	sd	zero,16(a0)
}
    80000b66:	6422                	ld	s0,8(sp)
    80000b68:	0141                	addi	sp,sp,16
    80000b6a:	8082                	ret

0000000080000b6c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6c:	411c                	lw	a5,0(a0)
    80000b6e:	e399                	bnez	a5,80000b74 <holding+0x8>
    80000b70:	4501                	li	a0,0
  return r;
}
    80000b72:	8082                	ret
{
    80000b74:	1101                	addi	sp,sp,-32
    80000b76:	ec06                	sd	ra,24(sp)
    80000b78:	e822                	sd	s0,16(sp)
    80000b7a:	e426                	sd	s1,8(sp)
    80000b7c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7e:	6904                	ld	s1,16(a0)
    80000b80:	00001097          	auipc	ra,0x1
    80000b84:	e7e080e7          	jalr	-386(ra) # 800019fe <mycpu>
    80000b88:	40a48533          	sub	a0,s1,a0
    80000b8c:	00153513          	seqz	a0,a0
}
    80000b90:	60e2                	ld	ra,24(sp)
    80000b92:	6442                	ld	s0,16(sp)
    80000b94:	64a2                	ld	s1,8(sp)
    80000b96:	6105                	addi	sp,sp,32
    80000b98:	8082                	ret

0000000080000b9a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9a:	1101                	addi	sp,sp,-32
    80000b9c:	ec06                	sd	ra,24(sp)
    80000b9e:	e822                	sd	s0,16(sp)
    80000ba0:	e426                	sd	s1,8(sp)
    80000ba2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba4:	100024f3          	csrr	s1,sstatus
    80000ba8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bac:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bae:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb2:	00001097          	auipc	ra,0x1
    80000bb6:	e4c080e7          	jalr	-436(ra) # 800019fe <mycpu>
    80000bba:	5d3c                	lw	a5,120(a0)
    80000bbc:	cf89                	beqz	a5,80000bd6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbe:	00001097          	auipc	ra,0x1
    80000bc2:	e40080e7          	jalr	-448(ra) # 800019fe <mycpu>
    80000bc6:	5d3c                	lw	a5,120(a0)
    80000bc8:	2785                	addiw	a5,a5,1
    80000bca:	dd3c                	sw	a5,120(a0)
}
    80000bcc:	60e2                	ld	ra,24(sp)
    80000bce:	6442                	ld	s0,16(sp)
    80000bd0:	64a2                	ld	s1,8(sp)
    80000bd2:	6105                	addi	sp,sp,32
    80000bd4:	8082                	ret
    mycpu()->intena = old;
    80000bd6:	00001097          	auipc	ra,0x1
    80000bda:	e28080e7          	jalr	-472(ra) # 800019fe <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bde:	8085                	srli	s1,s1,0x1
    80000be0:	8885                	andi	s1,s1,1
    80000be2:	dd64                	sw	s1,124(a0)
    80000be4:	bfe9                	j	80000bbe <push_off+0x24>

0000000080000be6 <acquire>:
{
    80000be6:	1101                	addi	sp,sp,-32
    80000be8:	ec06                	sd	ra,24(sp)
    80000bea:	e822                	sd	s0,16(sp)
    80000bec:	e426                	sd	s1,8(sp)
    80000bee:	1000                	addi	s0,sp,32
    80000bf0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf2:	00000097          	auipc	ra,0x0
    80000bf6:	fa8080e7          	jalr	-88(ra) # 80000b9a <push_off>
  if(holding(lk))
    80000bfa:	8526                	mv	a0,s1
    80000bfc:	00000097          	auipc	ra,0x0
    80000c00:	f70080e7          	jalr	-144(ra) # 80000b6c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c04:	4705                	li	a4,1
  if(holding(lk))
    80000c06:	e115                	bnez	a0,80000c2a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	87ba                	mv	a5,a4
    80000c0a:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0e:	2781                	sext.w	a5,a5
    80000c10:	ffe5                	bnez	a5,80000c08 <acquire+0x22>
  __sync_synchronize();
    80000c12:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c16:	00001097          	auipc	ra,0x1
    80000c1a:	de8080e7          	jalr	-536(ra) # 800019fe <mycpu>
    80000c1e:	e888                	sd	a0,16(s1)
}
    80000c20:	60e2                	ld	ra,24(sp)
    80000c22:	6442                	ld	s0,16(sp)
    80000c24:	64a2                	ld	s1,8(sp)
    80000c26:	6105                	addi	sp,sp,32
    80000c28:	8082                	ret
    panic("acquire");
    80000c2a:	00007517          	auipc	a0,0x7
    80000c2e:	44650513          	addi	a0,a0,1094 # 80008070 <digits+0x30>
    80000c32:	00000097          	auipc	ra,0x0
    80000c36:	90e080e7          	jalr	-1778(ra) # 80000540 <panic>

0000000080000c3a <pop_off>:

void
pop_off(void)
{
    80000c3a:	1141                	addi	sp,sp,-16
    80000c3c:	e406                	sd	ra,8(sp)
    80000c3e:	e022                	sd	s0,0(sp)
    80000c40:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c42:	00001097          	auipc	ra,0x1
    80000c46:	dbc080e7          	jalr	-580(ra) # 800019fe <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c50:	e78d                	bnez	a5,80000c7a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c52:	5d3c                	lw	a5,120(a0)
    80000c54:	02f05b63          	blez	a5,80000c8a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c58:	37fd                	addiw	a5,a5,-1
    80000c5a:	0007871b          	sext.w	a4,a5
    80000c5e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c60:	eb09                	bnez	a4,80000c72 <pop_off+0x38>
    80000c62:	5d7c                	lw	a5,124(a0)
    80000c64:	c799                	beqz	a5,80000c72 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c66:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c72:	60a2                	ld	ra,8(sp)
    80000c74:	6402                	ld	s0,0(sp)
    80000c76:	0141                	addi	sp,sp,16
    80000c78:	8082                	ret
    panic("pop_off - interruptible");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	3fe50513          	addi	a0,a0,1022 # 80008078 <digits+0x38>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>
    panic("pop_off");
    80000c8a:	00007517          	auipc	a0,0x7
    80000c8e:	40650513          	addi	a0,a0,1030 # 80008090 <digits+0x50>
    80000c92:	00000097          	auipc	ra,0x0
    80000c96:	8ae080e7          	jalr	-1874(ra) # 80000540 <panic>

0000000080000c9a <release>:
{
    80000c9a:	1101                	addi	sp,sp,-32
    80000c9c:	ec06                	sd	ra,24(sp)
    80000c9e:	e822                	sd	s0,16(sp)
    80000ca0:	e426                	sd	s1,8(sp)
    80000ca2:	1000                	addi	s0,sp,32
    80000ca4:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca6:	00000097          	auipc	ra,0x0
    80000caa:	ec6080e7          	jalr	-314(ra) # 80000b6c <holding>
    80000cae:	c115                	beqz	a0,80000cd2 <release+0x38>
  lk->cpu = 0;
    80000cb0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb8:	0f50000f          	fence	iorw,ow
    80000cbc:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc0:	00000097          	auipc	ra,0x0
    80000cc4:	f7a080e7          	jalr	-134(ra) # 80000c3a <pop_off>
}
    80000cc8:	60e2                	ld	ra,24(sp)
    80000cca:	6442                	ld	s0,16(sp)
    80000ccc:	64a2                	ld	s1,8(sp)
    80000cce:	6105                	addi	sp,sp,32
    80000cd0:	8082                	ret
    panic("release");
    80000cd2:	00007517          	auipc	a0,0x7
    80000cd6:	3c650513          	addi	a0,a0,966 # 80008098 <digits+0x58>
    80000cda:	00000097          	auipc	ra,0x0
    80000cde:	866080e7          	jalr	-1946(ra) # 80000540 <panic>

0000000080000ce2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce2:	1141                	addi	sp,sp,-16
    80000ce4:	e422                	sd	s0,8(sp)
    80000ce6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce8:	ce09                	beqz	a2,80000d02 <memset+0x20>
    80000cea:	87aa                	mv	a5,a0
    80000cec:	fff6071b          	addiw	a4,a2,-1
    80000cf0:	1702                	slli	a4,a4,0x20
    80000cf2:	9301                	srli	a4,a4,0x20
    80000cf4:	0705                	addi	a4,a4,1
    80000cf6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfc:	0785                	addi	a5,a5,1
    80000cfe:	fee79de3          	bne	a5,a4,80000cf8 <memset+0x16>
  }
  return dst;
}
    80000d02:	6422                	ld	s0,8(sp)
    80000d04:	0141                	addi	sp,sp,16
    80000d06:	8082                	ret

0000000080000d08 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d08:	1141                	addi	sp,sp,-16
    80000d0a:	e422                	sd	s0,8(sp)
    80000d0c:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0e:	ca05                	beqz	a2,80000d3e <memcmp+0x36>
    80000d10:	fff6069b          	addiw	a3,a2,-1
    80000d14:	1682                	slli	a3,a3,0x20
    80000d16:	9281                	srli	a3,a3,0x20
    80000d18:	0685                	addi	a3,a3,1
    80000d1a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1c:	00054783          	lbu	a5,0(a0)
    80000d20:	0005c703          	lbu	a4,0(a1)
    80000d24:	00e79863          	bne	a5,a4,80000d34 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d28:	0505                	addi	a0,a0,1
    80000d2a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2c:	fed518e3          	bne	a0,a3,80000d1c <memcmp+0x14>
  }

  return 0;
    80000d30:	4501                	li	a0,0
    80000d32:	a019                	j	80000d38 <memcmp+0x30>
      return *s1 - *s2;
    80000d34:	40e7853b          	subw	a0,a5,a4
}
    80000d38:	6422                	ld	s0,8(sp)
    80000d3a:	0141                	addi	sp,sp,16
    80000d3c:	8082                	ret
  return 0;
    80000d3e:	4501                	li	a0,0
    80000d40:	bfe5                	j	80000d38 <memcmp+0x30>

0000000080000d42 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d42:	1141                	addi	sp,sp,-16
    80000d44:	e422                	sd	s0,8(sp)
    80000d46:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d48:	ca0d                	beqz	a2,80000d7a <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4a:	00a5f963          	bgeu	a1,a0,80000d5c <memmove+0x1a>
    80000d4e:	02061693          	slli	a3,a2,0x20
    80000d52:	9281                	srli	a3,a3,0x20
    80000d54:	00d58733          	add	a4,a1,a3
    80000d58:	02e56463          	bltu	a0,a4,80000d80 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5c:	fff6079b          	addiw	a5,a2,-1
    80000d60:	1782                	slli	a5,a5,0x20
    80000d62:	9381                	srli	a5,a5,0x20
    80000d64:	0785                	addi	a5,a5,1
    80000d66:	97ae                	add	a5,a5,a1
    80000d68:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6a:	0585                	addi	a1,a1,1
    80000d6c:	0705                	addi	a4,a4,1
    80000d6e:	fff5c683          	lbu	a3,-1(a1)
    80000d72:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d76:	fef59ae3          	bne	a1,a5,80000d6a <memmove+0x28>

  return dst;
}
    80000d7a:	6422                	ld	s0,8(sp)
    80000d7c:	0141                	addi	sp,sp,16
    80000d7e:	8082                	ret
    d += n;
    80000d80:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d82:	fff6079b          	addiw	a5,a2,-1
    80000d86:	1782                	slli	a5,a5,0x20
    80000d88:	9381                	srli	a5,a5,0x20
    80000d8a:	fff7c793          	not	a5,a5
    80000d8e:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d90:	177d                	addi	a4,a4,-1
    80000d92:	16fd                	addi	a3,a3,-1
    80000d94:	00074603          	lbu	a2,0(a4)
    80000d98:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9c:	fef71ae3          	bne	a4,a5,80000d90 <memmove+0x4e>
    80000da0:	bfe9                	j	80000d7a <memmove+0x38>

0000000080000da2 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e406                	sd	ra,8(sp)
    80000da6:	e022                	sd	s0,0(sp)
    80000da8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000daa:	00000097          	auipc	ra,0x0
    80000dae:	f98080e7          	jalr	-104(ra) # 80000d42 <memmove>
}
    80000db2:	60a2                	ld	ra,8(sp)
    80000db4:	6402                	ld	s0,0(sp)
    80000db6:	0141                	addi	sp,sp,16
    80000db8:	8082                	ret

0000000080000dba <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dba:	1141                	addi	sp,sp,-16
    80000dbc:	e422                	sd	s0,8(sp)
    80000dbe:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc0:	ce11                	beqz	a2,80000ddc <strncmp+0x22>
    80000dc2:	00054783          	lbu	a5,0(a0)
    80000dc6:	cf89                	beqz	a5,80000de0 <strncmp+0x26>
    80000dc8:	0005c703          	lbu	a4,0(a1)
    80000dcc:	00f71a63          	bne	a4,a5,80000de0 <strncmp+0x26>
    n--, p++, q++;
    80000dd0:	367d                	addiw	a2,a2,-1
    80000dd2:	0505                	addi	a0,a0,1
    80000dd4:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd6:	f675                	bnez	a2,80000dc2 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd8:	4501                	li	a0,0
    80000dda:	a809                	j	80000dec <strncmp+0x32>
    80000ddc:	4501                	li	a0,0
    80000dde:	a039                	j	80000dec <strncmp+0x32>
  if(n == 0)
    80000de0:	ca09                	beqz	a2,80000df2 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de2:	00054503          	lbu	a0,0(a0)
    80000de6:	0005c783          	lbu	a5,0(a1)
    80000dea:	9d1d                	subw	a0,a0,a5
}
    80000dec:	6422                	ld	s0,8(sp)
    80000dee:	0141                	addi	sp,sp,16
    80000df0:	8082                	ret
    return 0;
    80000df2:	4501                	li	a0,0
    80000df4:	bfe5                	j	80000dec <strncmp+0x32>

0000000080000df6 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df6:	1141                	addi	sp,sp,-16
    80000df8:	e422                	sd	s0,8(sp)
    80000dfa:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfc:	872a                	mv	a4,a0
    80000dfe:	8832                	mv	a6,a2
    80000e00:	367d                	addiw	a2,a2,-1
    80000e02:	01005963          	blez	a6,80000e14 <strncpy+0x1e>
    80000e06:	0705                	addi	a4,a4,1
    80000e08:	0005c783          	lbu	a5,0(a1)
    80000e0c:	fef70fa3          	sb	a5,-1(a4)
    80000e10:	0585                	addi	a1,a1,1
    80000e12:	f7f5                	bnez	a5,80000dfe <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e14:	00c05d63          	blez	a2,80000e2e <strncpy+0x38>
    80000e18:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1a:	0685                	addi	a3,a3,1
    80000e1c:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e20:	fff6c793          	not	a5,a3
    80000e24:	9fb9                	addw	a5,a5,a4
    80000e26:	010787bb          	addw	a5,a5,a6
    80000e2a:	fef048e3          	bgtz	a5,80000e1a <strncpy+0x24>
  return os;
}
    80000e2e:	6422                	ld	s0,8(sp)
    80000e30:	0141                	addi	sp,sp,16
    80000e32:	8082                	ret

0000000080000e34 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e34:	1141                	addi	sp,sp,-16
    80000e36:	e422                	sd	s0,8(sp)
    80000e38:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3a:	02c05363          	blez	a2,80000e60 <safestrcpy+0x2c>
    80000e3e:	fff6069b          	addiw	a3,a2,-1
    80000e42:	1682                	slli	a3,a3,0x20
    80000e44:	9281                	srli	a3,a3,0x20
    80000e46:	96ae                	add	a3,a3,a1
    80000e48:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4a:	00d58963          	beq	a1,a3,80000e5c <safestrcpy+0x28>
    80000e4e:	0585                	addi	a1,a1,1
    80000e50:	0785                	addi	a5,a5,1
    80000e52:	fff5c703          	lbu	a4,-1(a1)
    80000e56:	fee78fa3          	sb	a4,-1(a5)
    80000e5a:	fb65                	bnez	a4,80000e4a <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5c:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e60:	6422                	ld	s0,8(sp)
    80000e62:	0141                	addi	sp,sp,16
    80000e64:	8082                	ret

0000000080000e66 <strlen>:

int
strlen(const char *s)
{
    80000e66:	1141                	addi	sp,sp,-16
    80000e68:	e422                	sd	s0,8(sp)
    80000e6a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6c:	00054783          	lbu	a5,0(a0)
    80000e70:	cf91                	beqz	a5,80000e8c <strlen+0x26>
    80000e72:	0505                	addi	a0,a0,1
    80000e74:	87aa                	mv	a5,a0
    80000e76:	4685                	li	a3,1
    80000e78:	9e89                	subw	a3,a3,a0
    80000e7a:	00f6853b          	addw	a0,a3,a5
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff7c703          	lbu	a4,-1(a5)
    80000e84:	fb7d                	bnez	a4,80000e7a <strlen+0x14>
    ;
  return n;
}
    80000e86:	6422                	ld	s0,8(sp)
    80000e88:	0141                	addi	sp,sp,16
    80000e8a:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8c:	4501                	li	a0,0
    80000e8e:	bfe5                	j	80000e86 <strlen+0x20>

0000000080000e90 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e90:	1141                	addi	sp,sp,-16
    80000e92:	e406                	sd	ra,8(sp)
    80000e94:	e022                	sd	s0,0(sp)
    80000e96:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e98:	00001097          	auipc	ra,0x1
    80000e9c:	b56080e7          	jalr	-1194(ra) # 800019ee <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea0:	00008717          	auipc	a4,0x8
    80000ea4:	17870713          	addi	a4,a4,376 # 80009018 <started>
  if(cpuid() == 0){
    80000ea8:	c139                	beqz	a0,80000eee <main+0x5e>
    while(started == 0)
    80000eaa:	431c                	lw	a5,0(a4)
    80000eac:	2781                	sext.w	a5,a5
    80000eae:	dff5                	beqz	a5,80000eaa <main+0x1a>
      ;
    __sync_synchronize();
    80000eb0:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb4:	00001097          	auipc	ra,0x1
    80000eb8:	b3a080e7          	jalr	-1222(ra) # 800019ee <cpuid>
    80000ebc:	85aa                	mv	a1,a0
    80000ebe:	00007517          	auipc	a0,0x7
    80000ec2:	1fa50513          	addi	a0,a0,506 # 800080b8 <digits+0x78>
    80000ec6:	fffff097          	auipc	ra,0xfffff
    80000eca:	6c4080e7          	jalr	1732(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000ece:	00000097          	auipc	ra,0x0
    80000ed2:	0d8080e7          	jalr	216(ra) # 80000fa6 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed6:	00002097          	auipc	ra,0x2
    80000eda:	f52080e7          	jalr	-174(ra) # 80002e28 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ede:	00005097          	auipc	ra,0x5
    80000ee2:	4f2080e7          	jalr	1266(ra) # 800063d0 <plicinithart>
  }

  scheduler();        
    80000ee6:	00001097          	auipc	ra,0x1
    80000eea:	0ce080e7          	jalr	206(ra) # 80001fb4 <scheduler>
    consoleinit();
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	564080e7          	jalr	1380(ra) # 80000452 <consoleinit>
    printfinit();
    80000ef6:	00000097          	auipc	ra,0x0
    80000efa:	87a080e7          	jalr	-1926(ra) # 80000770 <printfinit>
    printf("\n");
    80000efe:	00007517          	auipc	a0,0x7
    80000f02:	4aa50513          	addi	a0,a0,1194 # 800083a8 <digits+0x368>
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	684080e7          	jalr	1668(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000f0e:	00007517          	auipc	a0,0x7
    80000f12:	19250513          	addi	a0,a0,402 # 800080a0 <digits+0x60>
    80000f16:	fffff097          	auipc	ra,0xfffff
    80000f1a:	674080e7          	jalr	1652(ra) # 8000058a <printf>
    printf("\n");
    80000f1e:	00007517          	auipc	a0,0x7
    80000f22:	48a50513          	addi	a0,a0,1162 # 800083a8 <digits+0x368>
    80000f26:	fffff097          	auipc	ra,0xfffff
    80000f2a:	664080e7          	jalr	1636(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f2e:	00000097          	auipc	ra,0x0
    80000f32:	b8c080e7          	jalr	-1140(ra) # 80000aba <kinit>
    kvminit();       // create kernel page table
    80000f36:	00000097          	auipc	ra,0x0
    80000f3a:	322080e7          	jalr	802(ra) # 80001258 <kvminit>
    kvminithart();   // turn on paging
    80000f3e:	00000097          	auipc	ra,0x0
    80000f42:	068080e7          	jalr	104(ra) # 80000fa6 <kvminithart>
    procinit();      // process table
    80000f46:	00001097          	auipc	ra,0x1
    80000f4a:	990080e7          	jalr	-1648(ra) # 800018d6 <procinit>
    trapinit();      // trap vectors
    80000f4e:	00002097          	auipc	ra,0x2
    80000f52:	eb2080e7          	jalr	-334(ra) # 80002e00 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	ed2080e7          	jalr	-302(ra) # 80002e28 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5e:	00005097          	auipc	ra,0x5
    80000f62:	45c080e7          	jalr	1116(ra) # 800063ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f66:	00005097          	auipc	ra,0x5
    80000f6a:	46a080e7          	jalr	1130(ra) # 800063d0 <plicinithart>
    binit();         // buffer cache
    80000f6e:	00002097          	auipc	ra,0x2
    80000f72:	64c080e7          	jalr	1612(ra) # 800035ba <binit>
    iinit();         // inode table
    80000f76:	00003097          	auipc	ra,0x3
    80000f7a:	cdc080e7          	jalr	-804(ra) # 80003c52 <iinit>
    fileinit();      // file table
    80000f7e:	00004097          	auipc	ra,0x4
    80000f82:	c86080e7          	jalr	-890(ra) # 80004c04 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f86:	00005097          	auipc	ra,0x5
    80000f8a:	56c080e7          	jalr	1388(ra) # 800064f2 <virtio_disk_init>
    userinit();      // first user process
    80000f8e:	00001097          	auipc	ra,0x1
    80000f92:	d6e080e7          	jalr	-658(ra) # 80001cfc <userinit>
    __sync_synchronize();
    80000f96:	0ff0000f          	fence
    started = 1;
    80000f9a:	4785                	li	a5,1
    80000f9c:	00008717          	auipc	a4,0x8
    80000fa0:	06f72e23          	sw	a5,124(a4) # 80009018 <started>
    80000fa4:	b789                	j	80000ee6 <main+0x56>

0000000080000fa6 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa6:	1141                	addi	sp,sp,-16
    80000fa8:	e422                	sd	s0,8(sp)
    80000faa:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fac:	00008797          	auipc	a5,0x8
    80000fb0:	0747b783          	ld	a5,116(a5) # 80009020 <kernel_pagetable>
    80000fb4:	83b1                	srli	a5,a5,0xc
    80000fb6:	577d                	li	a4,-1
    80000fb8:	177e                	slli	a4,a4,0x3f
    80000fba:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fbc:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fc0:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc4:	6422                	ld	s0,8(sp)
    80000fc6:	0141                	addi	sp,sp,16
    80000fc8:	8082                	ret

0000000080000fca <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fca:	7139                	addi	sp,sp,-64
    80000fcc:	fc06                	sd	ra,56(sp)
    80000fce:	f822                	sd	s0,48(sp)
    80000fd0:	f426                	sd	s1,40(sp)
    80000fd2:	f04a                	sd	s2,32(sp)
    80000fd4:	ec4e                	sd	s3,24(sp)
    80000fd6:	e852                	sd	s4,16(sp)
    80000fd8:	e456                	sd	s5,8(sp)
    80000fda:	e05a                	sd	s6,0(sp)
    80000fdc:	0080                	addi	s0,sp,64
    80000fde:	84aa                	mv	s1,a0
    80000fe0:	89ae                	mv	s3,a1
    80000fe2:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe4:	57fd                	li	a5,-1
    80000fe6:	83e9                	srli	a5,a5,0x1a
    80000fe8:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fea:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fec:	04b7f263          	bgeu	a5,a1,80001030 <walk+0x66>
    panic("walk");
    80000ff0:	00007517          	auipc	a0,0x7
    80000ff4:	0e050513          	addi	a0,a0,224 # 800080d0 <digits+0x90>
    80000ff8:	fffff097          	auipc	ra,0xfffff
    80000ffc:	548080e7          	jalr	1352(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001000:	060a8663          	beqz	s5,8000106c <walk+0xa2>
    80001004:	00000097          	auipc	ra,0x0
    80001008:	af2080e7          	jalr	-1294(ra) # 80000af6 <kalloc>
    8000100c:	84aa                	mv	s1,a0
    8000100e:	c529                	beqz	a0,80001058 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001010:	6605                	lui	a2,0x1
    80001012:	4581                	li	a1,0
    80001014:	00000097          	auipc	ra,0x0
    80001018:	cce080e7          	jalr	-818(ra) # 80000ce2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101c:	00c4d793          	srli	a5,s1,0xc
    80001020:	07aa                	slli	a5,a5,0xa
    80001022:	0017e793          	ori	a5,a5,1
    80001026:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000102a:	3a5d                	addiw	s4,s4,-9
    8000102c:	036a0063          	beq	s4,s6,8000104c <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001030:	0149d933          	srl	s2,s3,s4
    80001034:	1ff97913          	andi	s2,s2,511
    80001038:	090e                	slli	s2,s2,0x3
    8000103a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103c:	00093483          	ld	s1,0(s2)
    80001040:	0014f793          	andi	a5,s1,1
    80001044:	dfd5                	beqz	a5,80001000 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001046:	80a9                	srli	s1,s1,0xa
    80001048:	04b2                	slli	s1,s1,0xc
    8000104a:	b7c5                	j	8000102a <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104c:	00c9d513          	srli	a0,s3,0xc
    80001050:	1ff57513          	andi	a0,a0,511
    80001054:	050e                	slli	a0,a0,0x3
    80001056:	9526                	add	a0,a0,s1
}
    80001058:	70e2                	ld	ra,56(sp)
    8000105a:	7442                	ld	s0,48(sp)
    8000105c:	74a2                	ld	s1,40(sp)
    8000105e:	7902                	ld	s2,32(sp)
    80001060:	69e2                	ld	s3,24(sp)
    80001062:	6a42                	ld	s4,16(sp)
    80001064:	6aa2                	ld	s5,8(sp)
    80001066:	6b02                	ld	s6,0(sp)
    80001068:	6121                	addi	sp,sp,64
    8000106a:	8082                	ret
        return 0;
    8000106c:	4501                	li	a0,0
    8000106e:	b7ed                	j	80001058 <walk+0x8e>

0000000080001070 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001070:	57fd                	li	a5,-1
    80001072:	83e9                	srli	a5,a5,0x1a
    80001074:	00b7f463          	bgeu	a5,a1,8000107c <walkaddr+0xc>
    return 0;
    80001078:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000107a:	8082                	ret
{
    8000107c:	1141                	addi	sp,sp,-16
    8000107e:	e406                	sd	ra,8(sp)
    80001080:	e022                	sd	s0,0(sp)
    80001082:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001084:	4601                	li	a2,0
    80001086:	00000097          	auipc	ra,0x0
    8000108a:	f44080e7          	jalr	-188(ra) # 80000fca <walk>
  if(pte == 0)
    8000108e:	c105                	beqz	a0,800010ae <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001090:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001092:	0117f693          	andi	a3,a5,17
    80001096:	4745                	li	a4,17
    return 0;
    80001098:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000109a:	00e68663          	beq	a3,a4,800010a6 <walkaddr+0x36>
}
    8000109e:	60a2                	ld	ra,8(sp)
    800010a0:	6402                	ld	s0,0(sp)
    800010a2:	0141                	addi	sp,sp,16
    800010a4:	8082                	ret
  pa = PTE2PA(*pte);
    800010a6:	00a7d513          	srli	a0,a5,0xa
    800010aa:	0532                	slli	a0,a0,0xc
  return pa;
    800010ac:	bfcd                	j	8000109e <walkaddr+0x2e>
    return 0;
    800010ae:	4501                	li	a0,0
    800010b0:	b7fd                	j	8000109e <walkaddr+0x2e>

00000000800010b2 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b2:	715d                	addi	sp,sp,-80
    800010b4:	e486                	sd	ra,72(sp)
    800010b6:	e0a2                	sd	s0,64(sp)
    800010b8:	fc26                	sd	s1,56(sp)
    800010ba:	f84a                	sd	s2,48(sp)
    800010bc:	f44e                	sd	s3,40(sp)
    800010be:	f052                	sd	s4,32(sp)
    800010c0:	ec56                	sd	s5,24(sp)
    800010c2:	e85a                	sd	s6,16(sp)
    800010c4:	e45e                	sd	s7,8(sp)
    800010c6:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c8:	c205                	beqz	a2,800010e8 <mappages+0x36>
    800010ca:	8aaa                	mv	s5,a0
    800010cc:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ce:	77fd                	lui	a5,0xfffff
    800010d0:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d4:	15fd                	addi	a1,a1,-1
    800010d6:	00c589b3          	add	s3,a1,a2
    800010da:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010de:	8952                	mv	s2,s4
    800010e0:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e4:	6b85                	lui	s7,0x1
    800010e6:	a015                	j	8000110a <mappages+0x58>
    panic("mappages: size");
    800010e8:	00007517          	auipc	a0,0x7
    800010ec:	ff050513          	addi	a0,a0,-16 # 800080d8 <digits+0x98>
    800010f0:	fffff097          	auipc	ra,0xfffff
    800010f4:	450080e7          	jalr	1104(ra) # 80000540 <panic>
      panic("mappages: remap");
    800010f8:	00007517          	auipc	a0,0x7
    800010fc:	ff050513          	addi	a0,a0,-16 # 800080e8 <digits+0xa8>
    80001100:	fffff097          	auipc	ra,0xfffff
    80001104:	440080e7          	jalr	1088(ra) # 80000540 <panic>
    a += PGSIZE;
    80001108:	995e                	add	s2,s2,s7
  for(;;){
    8000110a:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110e:	4605                	li	a2,1
    80001110:	85ca                	mv	a1,s2
    80001112:	8556                	mv	a0,s5
    80001114:	00000097          	auipc	ra,0x0
    80001118:	eb6080e7          	jalr	-330(ra) # 80000fca <walk>
    8000111c:	cd19                	beqz	a0,8000113a <mappages+0x88>
    if(*pte & PTE_V)
    8000111e:	611c                	ld	a5,0(a0)
    80001120:	8b85                	andi	a5,a5,1
    80001122:	fbf9                	bnez	a5,800010f8 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001124:	80b1                	srli	s1,s1,0xc
    80001126:	04aa                	slli	s1,s1,0xa
    80001128:	0164e4b3          	or	s1,s1,s6
    8000112c:	0014e493          	ori	s1,s1,1
    80001130:	e104                	sd	s1,0(a0)
    if(a == last)
    80001132:	fd391be3          	bne	s2,s3,80001108 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001136:	4501                	li	a0,0
    80001138:	a011                	j	8000113c <mappages+0x8a>
      return -1;
    8000113a:	557d                	li	a0,-1
}
    8000113c:	60a6                	ld	ra,72(sp)
    8000113e:	6406                	ld	s0,64(sp)
    80001140:	74e2                	ld	s1,56(sp)
    80001142:	7942                	ld	s2,48(sp)
    80001144:	79a2                	ld	s3,40(sp)
    80001146:	7a02                	ld	s4,32(sp)
    80001148:	6ae2                	ld	s5,24(sp)
    8000114a:	6b42                	ld	s6,16(sp)
    8000114c:	6ba2                	ld	s7,8(sp)
    8000114e:	6161                	addi	sp,sp,80
    80001150:	8082                	ret

0000000080001152 <kvmmap>:
{
    80001152:	1141                	addi	sp,sp,-16
    80001154:	e406                	sd	ra,8(sp)
    80001156:	e022                	sd	s0,0(sp)
    80001158:	0800                	addi	s0,sp,16
    8000115a:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115c:	86b2                	mv	a3,a2
    8000115e:	863e                	mv	a2,a5
    80001160:	00000097          	auipc	ra,0x0
    80001164:	f52080e7          	jalr	-174(ra) # 800010b2 <mappages>
    80001168:	e509                	bnez	a0,80001172 <kvmmap+0x20>
}
    8000116a:	60a2                	ld	ra,8(sp)
    8000116c:	6402                	ld	s0,0(sp)
    8000116e:	0141                	addi	sp,sp,16
    80001170:	8082                	ret
    panic("kvmmap");
    80001172:	00007517          	auipc	a0,0x7
    80001176:	f8650513          	addi	a0,a0,-122 # 800080f8 <digits+0xb8>
    8000117a:	fffff097          	auipc	ra,0xfffff
    8000117e:	3c6080e7          	jalr	966(ra) # 80000540 <panic>

0000000080001182 <kvmmake>:
{
    80001182:	1101                	addi	sp,sp,-32
    80001184:	ec06                	sd	ra,24(sp)
    80001186:	e822                	sd	s0,16(sp)
    80001188:	e426                	sd	s1,8(sp)
    8000118a:	e04a                	sd	s2,0(sp)
    8000118c:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118e:	00000097          	auipc	ra,0x0
    80001192:	968080e7          	jalr	-1688(ra) # 80000af6 <kalloc>
    80001196:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001198:	6605                	lui	a2,0x1
    8000119a:	4581                	li	a1,0
    8000119c:	00000097          	auipc	ra,0x0
    800011a0:	b46080e7          	jalr	-1210(ra) # 80000ce2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a4:	4719                	li	a4,6
    800011a6:	6685                	lui	a3,0x1
    800011a8:	10000637          	lui	a2,0x10000
    800011ac:	100005b7          	lui	a1,0x10000
    800011b0:	8526                	mv	a0,s1
    800011b2:	00000097          	auipc	ra,0x0
    800011b6:	fa0080e7          	jalr	-96(ra) # 80001152 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011ba:	4719                	li	a4,6
    800011bc:	6685                	lui	a3,0x1
    800011be:	10001637          	lui	a2,0x10001
    800011c2:	100015b7          	lui	a1,0x10001
    800011c6:	8526                	mv	a0,s1
    800011c8:	00000097          	auipc	ra,0x0
    800011cc:	f8a080e7          	jalr	-118(ra) # 80001152 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d0:	4719                	li	a4,6
    800011d2:	004006b7          	lui	a3,0x400
    800011d6:	0c000637          	lui	a2,0xc000
    800011da:	0c0005b7          	lui	a1,0xc000
    800011de:	8526                	mv	a0,s1
    800011e0:	00000097          	auipc	ra,0x0
    800011e4:	f72080e7          	jalr	-142(ra) # 80001152 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e8:	00007917          	auipc	s2,0x7
    800011ec:	e1890913          	addi	s2,s2,-488 # 80008000 <etext>
    800011f0:	4729                	li	a4,10
    800011f2:	80007697          	auipc	a3,0x80007
    800011f6:	e0e68693          	addi	a3,a3,-498 # 8000 <_entry-0x7fff8000>
    800011fa:	4605                	li	a2,1
    800011fc:	067e                	slli	a2,a2,0x1f
    800011fe:	85b2                	mv	a1,a2
    80001200:	8526                	mv	a0,s1
    80001202:	00000097          	auipc	ra,0x0
    80001206:	f50080e7          	jalr	-176(ra) # 80001152 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000120a:	4719                	li	a4,6
    8000120c:	46c5                	li	a3,17
    8000120e:	06ee                	slli	a3,a3,0x1b
    80001210:	412686b3          	sub	a3,a3,s2
    80001214:	864a                	mv	a2,s2
    80001216:	85ca                	mv	a1,s2
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f38080e7          	jalr	-200(ra) # 80001152 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001222:	4729                	li	a4,10
    80001224:	6685                	lui	a3,0x1
    80001226:	00006617          	auipc	a2,0x6
    8000122a:	dda60613          	addi	a2,a2,-550 # 80007000 <_trampoline>
    8000122e:	040005b7          	lui	a1,0x4000
    80001232:	15fd                	addi	a1,a1,-1
    80001234:	05b2                	slli	a1,a1,0xc
    80001236:	8526                	mv	a0,s1
    80001238:	00000097          	auipc	ra,0x0
    8000123c:	f1a080e7          	jalr	-230(ra) # 80001152 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001240:	8526                	mv	a0,s1
    80001242:	00000097          	auipc	ra,0x0
    80001246:	5fe080e7          	jalr	1534(ra) # 80001840 <proc_mapstacks>
}
    8000124a:	8526                	mv	a0,s1
    8000124c:	60e2                	ld	ra,24(sp)
    8000124e:	6442                	ld	s0,16(sp)
    80001250:	64a2                	ld	s1,8(sp)
    80001252:	6902                	ld	s2,0(sp)
    80001254:	6105                	addi	sp,sp,32
    80001256:	8082                	ret

0000000080001258 <kvminit>:
{
    80001258:	1141                	addi	sp,sp,-16
    8000125a:	e406                	sd	ra,8(sp)
    8000125c:	e022                	sd	s0,0(sp)
    8000125e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001260:	00000097          	auipc	ra,0x0
    80001264:	f22080e7          	jalr	-222(ra) # 80001182 <kvmmake>
    80001268:	00008797          	auipc	a5,0x8
    8000126c:	daa7bc23          	sd	a0,-584(a5) # 80009020 <kernel_pagetable>
}
    80001270:	60a2                	ld	ra,8(sp)
    80001272:	6402                	ld	s0,0(sp)
    80001274:	0141                	addi	sp,sp,16
    80001276:	8082                	ret

0000000080001278 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001278:	715d                	addi	sp,sp,-80
    8000127a:	e486                	sd	ra,72(sp)
    8000127c:	e0a2                	sd	s0,64(sp)
    8000127e:	fc26                	sd	s1,56(sp)
    80001280:	f84a                	sd	s2,48(sp)
    80001282:	f44e                	sd	s3,40(sp)
    80001284:	f052                	sd	s4,32(sp)
    80001286:	ec56                	sd	s5,24(sp)
    80001288:	e85a                	sd	s6,16(sp)
    8000128a:	e45e                	sd	s7,8(sp)
    8000128c:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128e:	03459793          	slli	a5,a1,0x34
    80001292:	e795                	bnez	a5,800012be <uvmunmap+0x46>
    80001294:	8a2a                	mv	s4,a0
    80001296:	892e                	mv	s2,a1
    80001298:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000129a:	0632                	slli	a2,a2,0xc
    8000129c:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a0:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	6b05                	lui	s6,0x1
    800012a4:	0735e863          	bltu	a1,s3,80001314 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a8:	60a6                	ld	ra,72(sp)
    800012aa:	6406                	ld	s0,64(sp)
    800012ac:	74e2                	ld	s1,56(sp)
    800012ae:	7942                	ld	s2,48(sp)
    800012b0:	79a2                	ld	s3,40(sp)
    800012b2:	7a02                	ld	s4,32(sp)
    800012b4:	6ae2                	ld	s5,24(sp)
    800012b6:	6b42                	ld	s6,16(sp)
    800012b8:	6ba2                	ld	s7,8(sp)
    800012ba:	6161                	addi	sp,sp,80
    800012bc:	8082                	ret
    panic("uvmunmap: not aligned");
    800012be:	00007517          	auipc	a0,0x7
    800012c2:	e4250513          	addi	a0,a0,-446 # 80008100 <digits+0xc0>
    800012c6:	fffff097          	auipc	ra,0xfffff
    800012ca:	27a080e7          	jalr	634(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ce:	00007517          	auipc	a0,0x7
    800012d2:	e4a50513          	addi	a0,a0,-438 # 80008118 <digits+0xd8>
    800012d6:	fffff097          	auipc	ra,0xfffff
    800012da:	26a080e7          	jalr	618(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012de:	00007517          	auipc	a0,0x7
    800012e2:	e4a50513          	addi	a0,a0,-438 # 80008128 <digits+0xe8>
    800012e6:	fffff097          	auipc	ra,0xfffff
    800012ea:	25a080e7          	jalr	602(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012ee:	00007517          	auipc	a0,0x7
    800012f2:	e5250513          	addi	a0,a0,-430 # 80008140 <digits+0x100>
    800012f6:	fffff097          	auipc	ra,0xfffff
    800012fa:	24a080e7          	jalr	586(ra) # 80000540 <panic>
      uint64 pa = PTE2PA(*pte);
    800012fe:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001300:	0532                	slli	a0,a0,0xc
    80001302:	fffff097          	auipc	ra,0xfffff
    80001306:	6f8080e7          	jalr	1784(ra) # 800009fa <kfree>
    *pte = 0;
    8000130a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130e:	995a                	add	s2,s2,s6
    80001310:	f9397ce3          	bgeu	s2,s3,800012a8 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001314:	4601                	li	a2,0
    80001316:	85ca                	mv	a1,s2
    80001318:	8552                	mv	a0,s4
    8000131a:	00000097          	auipc	ra,0x0
    8000131e:	cb0080e7          	jalr	-848(ra) # 80000fca <walk>
    80001322:	84aa                	mv	s1,a0
    80001324:	d54d                	beqz	a0,800012ce <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001326:	6108                	ld	a0,0(a0)
    80001328:	00157793          	andi	a5,a0,1
    8000132c:	dbcd                	beqz	a5,800012de <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132e:	3ff57793          	andi	a5,a0,1023
    80001332:	fb778ee3          	beq	a5,s7,800012ee <uvmunmap+0x76>
    if(do_free){
    80001336:	fc0a8ae3          	beqz	s5,8000130a <uvmunmap+0x92>
    8000133a:	b7d1                	j	800012fe <uvmunmap+0x86>

000000008000133c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133c:	1101                	addi	sp,sp,-32
    8000133e:	ec06                	sd	ra,24(sp)
    80001340:	e822                	sd	s0,16(sp)
    80001342:	e426                	sd	s1,8(sp)
    80001344:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001346:	fffff097          	auipc	ra,0xfffff
    8000134a:	7b0080e7          	jalr	1968(ra) # 80000af6 <kalloc>
    8000134e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001350:	c519                	beqz	a0,8000135e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001352:	6605                	lui	a2,0x1
    80001354:	4581                	li	a1,0
    80001356:	00000097          	auipc	ra,0x0
    8000135a:	98c080e7          	jalr	-1652(ra) # 80000ce2 <memset>
  return pagetable;
}
    8000135e:	8526                	mv	a0,s1
    80001360:	60e2                	ld	ra,24(sp)
    80001362:	6442                	ld	s0,16(sp)
    80001364:	64a2                	ld	s1,8(sp)
    80001366:	6105                	addi	sp,sp,32
    80001368:	8082                	ret

000000008000136a <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000136a:	7179                	addi	sp,sp,-48
    8000136c:	f406                	sd	ra,40(sp)
    8000136e:	f022                	sd	s0,32(sp)
    80001370:	ec26                	sd	s1,24(sp)
    80001372:	e84a                	sd	s2,16(sp)
    80001374:	e44e                	sd	s3,8(sp)
    80001376:	e052                	sd	s4,0(sp)
    80001378:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000137a:	6785                	lui	a5,0x1
    8000137c:	04f67863          	bgeu	a2,a5,800013cc <uvminit+0x62>
    80001380:	8a2a                	mv	s4,a0
    80001382:	89ae                	mv	s3,a1
    80001384:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001386:	fffff097          	auipc	ra,0xfffff
    8000138a:	770080e7          	jalr	1904(ra) # 80000af6 <kalloc>
    8000138e:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001390:	6605                	lui	a2,0x1
    80001392:	4581                	li	a1,0
    80001394:	00000097          	auipc	ra,0x0
    80001398:	94e080e7          	jalr	-1714(ra) # 80000ce2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139c:	4779                	li	a4,30
    8000139e:	86ca                	mv	a3,s2
    800013a0:	6605                	lui	a2,0x1
    800013a2:	4581                	li	a1,0
    800013a4:	8552                	mv	a0,s4
    800013a6:	00000097          	auipc	ra,0x0
    800013aa:	d0c080e7          	jalr	-756(ra) # 800010b2 <mappages>
  memmove(mem, src, sz);
    800013ae:	8626                	mv	a2,s1
    800013b0:	85ce                	mv	a1,s3
    800013b2:	854a                	mv	a0,s2
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	98e080e7          	jalr	-1650(ra) # 80000d42 <memmove>
}
    800013bc:	70a2                	ld	ra,40(sp)
    800013be:	7402                	ld	s0,32(sp)
    800013c0:	64e2                	ld	s1,24(sp)
    800013c2:	6942                	ld	s2,16(sp)
    800013c4:	69a2                	ld	s3,8(sp)
    800013c6:	6a02                	ld	s4,0(sp)
    800013c8:	6145                	addi	sp,sp,48
    800013ca:	8082                	ret
    panic("inituvm: more than a page");
    800013cc:	00007517          	auipc	a0,0x7
    800013d0:	d8c50513          	addi	a0,a0,-628 # 80008158 <digits+0x118>
    800013d4:	fffff097          	auipc	ra,0xfffff
    800013d8:	16c080e7          	jalr	364(ra) # 80000540 <panic>

00000000800013dc <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013dc:	1101                	addi	sp,sp,-32
    800013de:	ec06                	sd	ra,24(sp)
    800013e0:	e822                	sd	s0,16(sp)
    800013e2:	e426                	sd	s1,8(sp)
    800013e4:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e6:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e8:	00b67d63          	bgeu	a2,a1,80001402 <uvmdealloc+0x26>
    800013ec:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ee:	6785                	lui	a5,0x1
    800013f0:	17fd                	addi	a5,a5,-1
    800013f2:	00f60733          	add	a4,a2,a5
    800013f6:	767d                	lui	a2,0xfffff
    800013f8:	8f71                	and	a4,a4,a2
    800013fa:	97ae                	add	a5,a5,a1
    800013fc:	8ff1                	and	a5,a5,a2
    800013fe:	00f76863          	bltu	a4,a5,8000140e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001402:	8526                	mv	a0,s1
    80001404:	60e2                	ld	ra,24(sp)
    80001406:	6442                	ld	s0,16(sp)
    80001408:	64a2                	ld	s1,8(sp)
    8000140a:	6105                	addi	sp,sp,32
    8000140c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140e:	8f99                	sub	a5,a5,a4
    80001410:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001412:	4685                	li	a3,1
    80001414:	0007861b          	sext.w	a2,a5
    80001418:	85ba                	mv	a1,a4
    8000141a:	00000097          	auipc	ra,0x0
    8000141e:	e5e080e7          	jalr	-418(ra) # 80001278 <uvmunmap>
    80001422:	b7c5                	j	80001402 <uvmdealloc+0x26>

0000000080001424 <uvmalloc>:
  if(newsz < oldsz)
    80001424:	0ab66163          	bltu	a2,a1,800014c6 <uvmalloc+0xa2>
{
    80001428:	7139                	addi	sp,sp,-64
    8000142a:	fc06                	sd	ra,56(sp)
    8000142c:	f822                	sd	s0,48(sp)
    8000142e:	f426                	sd	s1,40(sp)
    80001430:	f04a                	sd	s2,32(sp)
    80001432:	ec4e                	sd	s3,24(sp)
    80001434:	e852                	sd	s4,16(sp)
    80001436:	e456                	sd	s5,8(sp)
    80001438:	0080                	addi	s0,sp,64
    8000143a:	8aaa                	mv	s5,a0
    8000143c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143e:	6985                	lui	s3,0x1
    80001440:	19fd                	addi	s3,s3,-1
    80001442:	95ce                	add	a1,a1,s3
    80001444:	79fd                	lui	s3,0xfffff
    80001446:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000144a:	08c9f063          	bgeu	s3,a2,800014ca <uvmalloc+0xa6>
    8000144e:	894e                	mv	s2,s3
    mem = kalloc();
    80001450:	fffff097          	auipc	ra,0xfffff
    80001454:	6a6080e7          	jalr	1702(ra) # 80000af6 <kalloc>
    80001458:	84aa                	mv	s1,a0
    if(mem == 0){
    8000145a:	c51d                	beqz	a0,80001488 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145c:	6605                	lui	a2,0x1
    8000145e:	4581                	li	a1,0
    80001460:	00000097          	auipc	ra,0x0
    80001464:	882080e7          	jalr	-1918(ra) # 80000ce2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001468:	4779                	li	a4,30
    8000146a:	86a6                	mv	a3,s1
    8000146c:	6605                	lui	a2,0x1
    8000146e:	85ca                	mv	a1,s2
    80001470:	8556                	mv	a0,s5
    80001472:	00000097          	auipc	ra,0x0
    80001476:	c40080e7          	jalr	-960(ra) # 800010b2 <mappages>
    8000147a:	e905                	bnez	a0,800014aa <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147c:	6785                	lui	a5,0x1
    8000147e:	993e                	add	s2,s2,a5
    80001480:	fd4968e3          	bltu	s2,s4,80001450 <uvmalloc+0x2c>
  return newsz;
    80001484:	8552                	mv	a0,s4
    80001486:	a809                	j	80001498 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001488:	864e                	mv	a2,s3
    8000148a:	85ca                	mv	a1,s2
    8000148c:	8556                	mv	a0,s5
    8000148e:	00000097          	auipc	ra,0x0
    80001492:	f4e080e7          	jalr	-178(ra) # 800013dc <uvmdealloc>
      return 0;
    80001496:	4501                	li	a0,0
}
    80001498:	70e2                	ld	ra,56(sp)
    8000149a:	7442                	ld	s0,48(sp)
    8000149c:	74a2                	ld	s1,40(sp)
    8000149e:	7902                	ld	s2,32(sp)
    800014a0:	69e2                	ld	s3,24(sp)
    800014a2:	6a42                	ld	s4,16(sp)
    800014a4:	6aa2                	ld	s5,8(sp)
    800014a6:	6121                	addi	sp,sp,64
    800014a8:	8082                	ret
      kfree(mem);
    800014aa:	8526                	mv	a0,s1
    800014ac:	fffff097          	auipc	ra,0xfffff
    800014b0:	54e080e7          	jalr	1358(ra) # 800009fa <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b4:	864e                	mv	a2,s3
    800014b6:	85ca                	mv	a1,s2
    800014b8:	8556                	mv	a0,s5
    800014ba:	00000097          	auipc	ra,0x0
    800014be:	f22080e7          	jalr	-222(ra) # 800013dc <uvmdealloc>
      return 0;
    800014c2:	4501                	li	a0,0
    800014c4:	bfd1                	j	80001498 <uvmalloc+0x74>
    return oldsz;
    800014c6:	852e                	mv	a0,a1
}
    800014c8:	8082                	ret
  return newsz;
    800014ca:	8532                	mv	a0,a2
    800014cc:	b7f1                	j	80001498 <uvmalloc+0x74>

00000000800014ce <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014ce:	7179                	addi	sp,sp,-48
    800014d0:	f406                	sd	ra,40(sp)
    800014d2:	f022                	sd	s0,32(sp)
    800014d4:	ec26                	sd	s1,24(sp)
    800014d6:	e84a                	sd	s2,16(sp)
    800014d8:	e44e                	sd	s3,8(sp)
    800014da:	e052                	sd	s4,0(sp)
    800014dc:	1800                	addi	s0,sp,48
    800014de:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014e0:	84aa                	mv	s1,a0
    800014e2:	6905                	lui	s2,0x1
    800014e4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e6:	4985                	li	s3,1
    800014e8:	a821                	j	80001500 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014ea:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ec:	0532                	slli	a0,a0,0xc
    800014ee:	00000097          	auipc	ra,0x0
    800014f2:	fe0080e7          	jalr	-32(ra) # 800014ce <freewalk>
      pagetable[i] = 0;
    800014f6:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014fa:	04a1                	addi	s1,s1,8
    800014fc:	03248163          	beq	s1,s2,8000151e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001500:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001502:	00f57793          	andi	a5,a0,15
    80001506:	ff3782e3          	beq	a5,s3,800014ea <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000150a:	8905                	andi	a0,a0,1
    8000150c:	d57d                	beqz	a0,800014fa <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150e:	00007517          	auipc	a0,0x7
    80001512:	c6a50513          	addi	a0,a0,-918 # 80008178 <digits+0x138>
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	02a080e7          	jalr	42(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    8000151e:	8552                	mv	a0,s4
    80001520:	fffff097          	auipc	ra,0xfffff
    80001524:	4da080e7          	jalr	1242(ra) # 800009fa <kfree>
}
    80001528:	70a2                	ld	ra,40(sp)
    8000152a:	7402                	ld	s0,32(sp)
    8000152c:	64e2                	ld	s1,24(sp)
    8000152e:	6942                	ld	s2,16(sp)
    80001530:	69a2                	ld	s3,8(sp)
    80001532:	6a02                	ld	s4,0(sp)
    80001534:	6145                	addi	sp,sp,48
    80001536:	8082                	ret

0000000080001538 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001538:	1101                	addi	sp,sp,-32
    8000153a:	ec06                	sd	ra,24(sp)
    8000153c:	e822                	sd	s0,16(sp)
    8000153e:	e426                	sd	s1,8(sp)
    80001540:	1000                	addi	s0,sp,32
    80001542:	84aa                	mv	s1,a0
  if(sz > 0)
    80001544:	e999                	bnez	a1,8000155a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001546:	8526                	mv	a0,s1
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	f86080e7          	jalr	-122(ra) # 800014ce <freewalk>
}
    80001550:	60e2                	ld	ra,24(sp)
    80001552:	6442                	ld	s0,16(sp)
    80001554:	64a2                	ld	s1,8(sp)
    80001556:	6105                	addi	sp,sp,32
    80001558:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000155a:	6605                	lui	a2,0x1
    8000155c:	167d                	addi	a2,a2,-1
    8000155e:	962e                	add	a2,a2,a1
    80001560:	4685                	li	a3,1
    80001562:	8231                	srli	a2,a2,0xc
    80001564:	4581                	li	a1,0
    80001566:	00000097          	auipc	ra,0x0
    8000156a:	d12080e7          	jalr	-750(ra) # 80001278 <uvmunmap>
    8000156e:	bfe1                	j	80001546 <uvmfree+0xe>

0000000080001570 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001570:	c679                	beqz	a2,8000163e <uvmcopy+0xce>
{
    80001572:	715d                	addi	sp,sp,-80
    80001574:	e486                	sd	ra,72(sp)
    80001576:	e0a2                	sd	s0,64(sp)
    80001578:	fc26                	sd	s1,56(sp)
    8000157a:	f84a                	sd	s2,48(sp)
    8000157c:	f44e                	sd	s3,40(sp)
    8000157e:	f052                	sd	s4,32(sp)
    80001580:	ec56                	sd	s5,24(sp)
    80001582:	e85a                	sd	s6,16(sp)
    80001584:	e45e                	sd	s7,8(sp)
    80001586:	0880                	addi	s0,sp,80
    80001588:	8b2a                	mv	s6,a0
    8000158a:	8aae                	mv	s5,a1
    8000158c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001590:	4601                	li	a2,0
    80001592:	85ce                	mv	a1,s3
    80001594:	855a                	mv	a0,s6
    80001596:	00000097          	auipc	ra,0x0
    8000159a:	a34080e7          	jalr	-1484(ra) # 80000fca <walk>
    8000159e:	c531                	beqz	a0,800015ea <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015a0:	6118                	ld	a4,0(a0)
    800015a2:	00177793          	andi	a5,a4,1
    800015a6:	cbb1                	beqz	a5,800015fa <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a8:	00a75593          	srli	a1,a4,0xa
    800015ac:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015b0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b4:	fffff097          	auipc	ra,0xfffff
    800015b8:	542080e7          	jalr	1346(ra) # 80000af6 <kalloc>
    800015bc:	892a                	mv	s2,a0
    800015be:	c939                	beqz	a0,80001614 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015c0:	6605                	lui	a2,0x1
    800015c2:	85de                	mv	a1,s7
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	77e080e7          	jalr	1918(ra) # 80000d42 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015cc:	8726                	mv	a4,s1
    800015ce:	86ca                	mv	a3,s2
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85ce                	mv	a1,s3
    800015d4:	8556                	mv	a0,s5
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	adc080e7          	jalr	-1316(ra) # 800010b2 <mappages>
    800015de:	e515                	bnez	a0,8000160a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015e0:	6785                	lui	a5,0x1
    800015e2:	99be                	add	s3,s3,a5
    800015e4:	fb49e6e3          	bltu	s3,s4,80001590 <uvmcopy+0x20>
    800015e8:	a081                	j	80001628 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015ea:	00007517          	auipc	a0,0x7
    800015ee:	b9e50513          	addi	a0,a0,-1122 # 80008188 <digits+0x148>
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	f4e080e7          	jalr	-178(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	bae50513          	addi	a0,a0,-1106 # 800081a8 <digits+0x168>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f3e080e7          	jalr	-194(ra) # 80000540 <panic>
      kfree(mem);
    8000160a:	854a                	mv	a0,s2
    8000160c:	fffff097          	auipc	ra,0xfffff
    80001610:	3ee080e7          	jalr	1006(ra) # 800009fa <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001614:	4685                	li	a3,1
    80001616:	00c9d613          	srli	a2,s3,0xc
    8000161a:	4581                	li	a1,0
    8000161c:	8556                	mv	a0,s5
    8000161e:	00000097          	auipc	ra,0x0
    80001622:	c5a080e7          	jalr	-934(ra) # 80001278 <uvmunmap>
  return -1;
    80001626:	557d                	li	a0,-1
}
    80001628:	60a6                	ld	ra,72(sp)
    8000162a:	6406                	ld	s0,64(sp)
    8000162c:	74e2                	ld	s1,56(sp)
    8000162e:	7942                	ld	s2,48(sp)
    80001630:	79a2                	ld	s3,40(sp)
    80001632:	7a02                	ld	s4,32(sp)
    80001634:	6ae2                	ld	s5,24(sp)
    80001636:	6b42                	ld	s6,16(sp)
    80001638:	6ba2                	ld	s7,8(sp)
    8000163a:	6161                	addi	sp,sp,80
    8000163c:	8082                	ret
  return 0;
    8000163e:	4501                	li	a0,0
}
    80001640:	8082                	ret

0000000080001642 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001642:	1141                	addi	sp,sp,-16
    80001644:	e406                	sd	ra,8(sp)
    80001646:	e022                	sd	s0,0(sp)
    80001648:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000164a:	4601                	li	a2,0
    8000164c:	00000097          	auipc	ra,0x0
    80001650:	97e080e7          	jalr	-1666(ra) # 80000fca <walk>
  if(pte == 0)
    80001654:	c901                	beqz	a0,80001664 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001656:	611c                	ld	a5,0(a0)
    80001658:	9bbd                	andi	a5,a5,-17
    8000165a:	e11c                	sd	a5,0(a0)
}
    8000165c:	60a2                	ld	ra,8(sp)
    8000165e:	6402                	ld	s0,0(sp)
    80001660:	0141                	addi	sp,sp,16
    80001662:	8082                	ret
    panic("uvmclear");
    80001664:	00007517          	auipc	a0,0x7
    80001668:	b6450513          	addi	a0,a0,-1180 # 800081c8 <digits+0x188>
    8000166c:	fffff097          	auipc	ra,0xfffff
    80001670:	ed4080e7          	jalr	-300(ra) # 80000540 <panic>

0000000080001674 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001674:	c6bd                	beqz	a3,800016e2 <copyout+0x6e>
{
    80001676:	715d                	addi	sp,sp,-80
    80001678:	e486                	sd	ra,72(sp)
    8000167a:	e0a2                	sd	s0,64(sp)
    8000167c:	fc26                	sd	s1,56(sp)
    8000167e:	f84a                	sd	s2,48(sp)
    80001680:	f44e                	sd	s3,40(sp)
    80001682:	f052                	sd	s4,32(sp)
    80001684:	ec56                	sd	s5,24(sp)
    80001686:	e85a                	sd	s6,16(sp)
    80001688:	e45e                	sd	s7,8(sp)
    8000168a:	e062                	sd	s8,0(sp)
    8000168c:	0880                	addi	s0,sp,80
    8000168e:	8b2a                	mv	s6,a0
    80001690:	8c2e                	mv	s8,a1
    80001692:	8a32                	mv	s4,a2
    80001694:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001696:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001698:	6a85                	lui	s5,0x1
    8000169a:	a015                	j	800016be <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169c:	9562                	add	a0,a0,s8
    8000169e:	0004861b          	sext.w	a2,s1
    800016a2:	85d2                	mv	a1,s4
    800016a4:	41250533          	sub	a0,a0,s2
    800016a8:	fffff097          	auipc	ra,0xfffff
    800016ac:	69a080e7          	jalr	1690(ra) # 80000d42 <memmove>

    len -= n;
    800016b0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ba:	02098263          	beqz	s3,800016de <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016be:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c2:	85ca                	mv	a1,s2
    800016c4:	855a                	mv	a0,s6
    800016c6:	00000097          	auipc	ra,0x0
    800016ca:	9aa080e7          	jalr	-1622(ra) # 80001070 <walkaddr>
    if(pa0 == 0)
    800016ce:	cd01                	beqz	a0,800016e6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016d0:	418904b3          	sub	s1,s2,s8
    800016d4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d6:	fc99f3e3          	bgeu	s3,s1,8000169c <copyout+0x28>
    800016da:	84ce                	mv	s1,s3
    800016dc:	b7c1                	j	8000169c <copyout+0x28>
  }
  return 0;
    800016de:	4501                	li	a0,0
    800016e0:	a021                	j	800016e8 <copyout+0x74>
    800016e2:	4501                	li	a0,0
}
    800016e4:	8082                	ret
      return -1;
    800016e6:	557d                	li	a0,-1
}
    800016e8:	60a6                	ld	ra,72(sp)
    800016ea:	6406                	ld	s0,64(sp)
    800016ec:	74e2                	ld	s1,56(sp)
    800016ee:	7942                	ld	s2,48(sp)
    800016f0:	79a2                	ld	s3,40(sp)
    800016f2:	7a02                	ld	s4,32(sp)
    800016f4:	6ae2                	ld	s5,24(sp)
    800016f6:	6b42                	ld	s6,16(sp)
    800016f8:	6ba2                	ld	s7,8(sp)
    800016fa:	6c02                	ld	s8,0(sp)
    800016fc:	6161                	addi	sp,sp,80
    800016fe:	8082                	ret

0000000080001700 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001700:	c6bd                	beqz	a3,8000176e <copyin+0x6e>
{
    80001702:	715d                	addi	sp,sp,-80
    80001704:	e486                	sd	ra,72(sp)
    80001706:	e0a2                	sd	s0,64(sp)
    80001708:	fc26                	sd	s1,56(sp)
    8000170a:	f84a                	sd	s2,48(sp)
    8000170c:	f44e                	sd	s3,40(sp)
    8000170e:	f052                	sd	s4,32(sp)
    80001710:	ec56                	sd	s5,24(sp)
    80001712:	e85a                	sd	s6,16(sp)
    80001714:	e45e                	sd	s7,8(sp)
    80001716:	e062                	sd	s8,0(sp)
    80001718:	0880                	addi	s0,sp,80
    8000171a:	8b2a                	mv	s6,a0
    8000171c:	8a2e                	mv	s4,a1
    8000171e:	8c32                	mv	s8,a2
    80001720:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001722:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001724:	6a85                	lui	s5,0x1
    80001726:	a015                	j	8000174a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001728:	9562                	add	a0,a0,s8
    8000172a:	0004861b          	sext.w	a2,s1
    8000172e:	412505b3          	sub	a1,a0,s2
    80001732:	8552                	mv	a0,s4
    80001734:	fffff097          	auipc	ra,0xfffff
    80001738:	60e080e7          	jalr	1550(ra) # 80000d42 <memmove>

    len -= n;
    8000173c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001740:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001742:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001746:	02098263          	beqz	s3,8000176a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000174a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174e:	85ca                	mv	a1,s2
    80001750:	855a                	mv	a0,s6
    80001752:	00000097          	auipc	ra,0x0
    80001756:	91e080e7          	jalr	-1762(ra) # 80001070 <walkaddr>
    if(pa0 == 0)
    8000175a:	cd01                	beqz	a0,80001772 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175c:	418904b3          	sub	s1,s2,s8
    80001760:	94d6                	add	s1,s1,s5
    if(n > len)
    80001762:	fc99f3e3          	bgeu	s3,s1,80001728 <copyin+0x28>
    80001766:	84ce                	mv	s1,s3
    80001768:	b7c1                	j	80001728 <copyin+0x28>
  }
  return 0;
    8000176a:	4501                	li	a0,0
    8000176c:	a021                	j	80001774 <copyin+0x74>
    8000176e:	4501                	li	a0,0
}
    80001770:	8082                	ret
      return -1;
    80001772:	557d                	li	a0,-1
}
    80001774:	60a6                	ld	ra,72(sp)
    80001776:	6406                	ld	s0,64(sp)
    80001778:	74e2                	ld	s1,56(sp)
    8000177a:	7942                	ld	s2,48(sp)
    8000177c:	79a2                	ld	s3,40(sp)
    8000177e:	7a02                	ld	s4,32(sp)
    80001780:	6ae2                	ld	s5,24(sp)
    80001782:	6b42                	ld	s6,16(sp)
    80001784:	6ba2                	ld	s7,8(sp)
    80001786:	6c02                	ld	s8,0(sp)
    80001788:	6161                	addi	sp,sp,80
    8000178a:	8082                	ret

000000008000178c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178c:	c6c5                	beqz	a3,80001834 <copyinstr+0xa8>
{
    8000178e:	715d                	addi	sp,sp,-80
    80001790:	e486                	sd	ra,72(sp)
    80001792:	e0a2                	sd	s0,64(sp)
    80001794:	fc26                	sd	s1,56(sp)
    80001796:	f84a                	sd	s2,48(sp)
    80001798:	f44e                	sd	s3,40(sp)
    8000179a:	f052                	sd	s4,32(sp)
    8000179c:	ec56                	sd	s5,24(sp)
    8000179e:	e85a                	sd	s6,16(sp)
    800017a0:	e45e                	sd	s7,8(sp)
    800017a2:	0880                	addi	s0,sp,80
    800017a4:	8a2a                	mv	s4,a0
    800017a6:	8b2e                	mv	s6,a1
    800017a8:	8bb2                	mv	s7,a2
    800017aa:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017ac:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ae:	6985                	lui	s3,0x1
    800017b0:	a035                	j	800017dc <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b8:	0017b793          	seqz	a5,a5
    800017bc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017c0:	60a6                	ld	ra,72(sp)
    800017c2:	6406                	ld	s0,64(sp)
    800017c4:	74e2                	ld	s1,56(sp)
    800017c6:	7942                	ld	s2,48(sp)
    800017c8:	79a2                	ld	s3,40(sp)
    800017ca:	7a02                	ld	s4,32(sp)
    800017cc:	6ae2                	ld	s5,24(sp)
    800017ce:	6b42                	ld	s6,16(sp)
    800017d0:	6ba2                	ld	s7,8(sp)
    800017d2:	6161                	addi	sp,sp,80
    800017d4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017da:	c8a9                	beqz	s1,8000182c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017dc:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017e0:	85ca                	mv	a1,s2
    800017e2:	8552                	mv	a0,s4
    800017e4:	00000097          	auipc	ra,0x0
    800017e8:	88c080e7          	jalr	-1908(ra) # 80001070 <walkaddr>
    if(pa0 == 0)
    800017ec:	c131                	beqz	a0,80001830 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ee:	41790833          	sub	a6,s2,s7
    800017f2:	984e                	add	a6,a6,s3
    if(n > max)
    800017f4:	0104f363          	bgeu	s1,a6,800017fa <copyinstr+0x6e>
    800017f8:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017fa:	955e                	add	a0,a0,s7
    800017fc:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001800:	fc080be3          	beqz	a6,800017d6 <copyinstr+0x4a>
    80001804:	985a                	add	a6,a6,s6
    80001806:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001808:	41650633          	sub	a2,a0,s6
    8000180c:	14fd                	addi	s1,s1,-1
    8000180e:	9b26                	add	s6,s6,s1
    80001810:	00f60733          	add	a4,a2,a5
    80001814:	00074703          	lbu	a4,0(a4)
    80001818:	df49                	beqz	a4,800017b2 <copyinstr+0x26>
        *dst = *p;
    8000181a:	00e78023          	sb	a4,0(a5)
      --max;
    8000181e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001822:	0785                	addi	a5,a5,1
    while(n > 0){
    80001824:	ff0796e3          	bne	a5,a6,80001810 <copyinstr+0x84>
      dst++;
    80001828:	8b42                	mv	s6,a6
    8000182a:	b775                	j	800017d6 <copyinstr+0x4a>
    8000182c:	4781                	li	a5,0
    8000182e:	b769                	j	800017b8 <copyinstr+0x2c>
      return -1;
    80001830:	557d                	li	a0,-1
    80001832:	b779                	j	800017c0 <copyinstr+0x34>
  int got_null = 0;
    80001834:	4781                	li	a5,0
  if(got_null){
    80001836:	0017b793          	seqz	a5,a5
    8000183a:	40f00533          	neg	a0,a5
}
    8000183e:	8082                	ret

0000000080001840 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001840:	7139                	addi	sp,sp,-64
    80001842:	fc06                	sd	ra,56(sp)
    80001844:	f822                	sd	s0,48(sp)
    80001846:	f426                	sd	s1,40(sp)
    80001848:	f04a                	sd	s2,32(sp)
    8000184a:	ec4e                	sd	s3,24(sp)
    8000184c:	e852                	sd	s4,16(sp)
    8000184e:	e456                	sd	s5,8(sp)
    80001850:	e05a                	sd	s6,0(sp)
    80001852:	0080                	addi	s0,sp,64
    80001854:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001856:	00010497          	auipc	s1,0x10
    8000185a:	e9a48493          	addi	s1,s1,-358 # 800116f0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000185e:	8b26                	mv	s6,s1
    80001860:	00006a97          	auipc	s5,0x6
    80001864:	7a0a8a93          	addi	s5,s5,1952 # 80008000 <etext>
    80001868:	04000937          	lui	s2,0x4000
    8000186c:	197d                	addi	s2,s2,-1
    8000186e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001870:	00016a17          	auipc	s4,0x16
    80001874:	080a0a13          	addi	s4,s4,128 # 800178f0 <tickslock>
    char *pa = kalloc();
    80001878:	fffff097          	auipc	ra,0xfffff
    8000187c:	27e080e7          	jalr	638(ra) # 80000af6 <kalloc>
    80001880:	862a                	mv	a2,a0
    if(pa == 0)
    80001882:	c131                	beqz	a0,800018c6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001884:	416485b3          	sub	a1,s1,s6
    80001888:	858d                	srai	a1,a1,0x3
    8000188a:	000ab783          	ld	a5,0(s5)
    8000188e:	02f585b3          	mul	a1,a1,a5
    80001892:	2585                	addiw	a1,a1,1
    80001894:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001898:	4719                	li	a4,6
    8000189a:	6685                	lui	a3,0x1
    8000189c:	40b905b3          	sub	a1,s2,a1
    800018a0:	854e                	mv	a0,s3
    800018a2:	00000097          	auipc	ra,0x0
    800018a6:	8b0080e7          	jalr	-1872(ra) # 80001152 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018aa:	18848493          	addi	s1,s1,392
    800018ae:	fd4495e3          	bne	s1,s4,80001878 <proc_mapstacks+0x38>
  }
}
    800018b2:	70e2                	ld	ra,56(sp)
    800018b4:	7442                	ld	s0,48(sp)
    800018b6:	74a2                	ld	s1,40(sp)
    800018b8:	7902                	ld	s2,32(sp)
    800018ba:	69e2                	ld	s3,24(sp)
    800018bc:	6a42                	ld	s4,16(sp)
    800018be:	6aa2                	ld	s5,8(sp)
    800018c0:	6b02                	ld	s6,0(sp)
    800018c2:	6121                	addi	sp,sp,64
    800018c4:	8082                	ret
      panic("kalloc");
    800018c6:	00007517          	auipc	a0,0x7
    800018ca:	91250513          	addi	a0,a0,-1774 # 800081d8 <digits+0x198>
    800018ce:	fffff097          	auipc	ra,0xfffff
    800018d2:	c72080e7          	jalr	-910(ra) # 80000540 <panic>

00000000800018d6 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800018d6:	7139                	addi	sp,sp,-64
    800018d8:	fc06                	sd	ra,56(sp)
    800018da:	f822                	sd	s0,48(sp)
    800018dc:	f426                	sd	s1,40(sp)
    800018de:	f04a                	sd	s2,32(sp)
    800018e0:	ec4e                	sd	s3,24(sp)
    800018e2:	e852                	sd	s4,16(sp)
    800018e4:	e456                	sd	s5,8(sp)
    800018e6:	e05a                	sd	s6,0(sp)
    800018e8:	0080                	addi	s0,sp,64
  struct proc *p;

  sleeping_processes_mean = 0;
    800018ea:	00007797          	auipc	a5,0x7
    800018ee:	7607a323          	sw	zero,1894(a5) # 80009050 <sleeping_processes_mean>
  running_processes_mean = 0;
    800018f2:	00007797          	auipc	a5,0x7
    800018f6:	7407ad23          	sw	zero,1882(a5) # 8000904c <running_processes_mean>
  runnable_processes_mean = 0;
    800018fa:	00007797          	auipc	a5,0x7
    800018fe:	7407a723          	sw	zero,1870(a5) # 80009048 <runnable_processes_mean>
  process_count = 1;
    80001902:	4785                	li	a5,1
    80001904:	00007717          	auipc	a4,0x7
    80001908:	74f72023          	sw	a5,1856(a4) # 80009044 <process_count>
  program_time = 0;
    8000190c:	00007797          	auipc	a5,0x7
    80001910:	7207aa23          	sw	zero,1844(a5) # 80009040 <program_time>
  cpu_utilization = 0;
    80001914:	00007797          	auipc	a5,0x7
    80001918:	7207a423          	sw	zero,1832(a5) # 8000903c <cpu_utilization>
  start_time = 0;
    8000191c:	00007497          	auipc	s1,0x7
    80001920:	71c48493          	addi	s1,s1,1820 # 80009038 <start_time>
    80001924:	0004a023          	sw	zero,0(s1)


  acquire(&tickslock);
    80001928:	00016517          	auipc	a0,0x16
    8000192c:	fc850513          	addi	a0,a0,-56 # 800178f0 <tickslock>
    80001930:	fffff097          	auipc	ra,0xfffff
    80001934:	2b6080e7          	jalr	694(ra) # 80000be6 <acquire>
  start_time = ticks;
    80001938:	00007797          	auipc	a5,0x7
    8000193c:	71c7a783          	lw	a5,1820(a5) # 80009054 <ticks>
    80001940:	c09c                	sw	a5,0(s1)
  release(&tickslock);
    80001942:	00016517          	auipc	a0,0x16
    80001946:	fae50513          	addi	a0,a0,-82 # 800178f0 <tickslock>
    8000194a:	fffff097          	auipc	ra,0xfffff
    8000194e:	350080e7          	jalr	848(ra) # 80000c9a <release>

  initlock(&pid_lock, "nextpid");
    80001952:	00007597          	auipc	a1,0x7
    80001956:	88e58593          	addi	a1,a1,-1906 # 800081e0 <digits+0x1a0>
    8000195a:	00010517          	auipc	a0,0x10
    8000195e:	96650513          	addi	a0,a0,-1690 # 800112c0 <pid_lock>
    80001962:	fffff097          	auipc	ra,0xfffff
    80001966:	1f4080e7          	jalr	500(ra) # 80000b56 <initlock>
  initlock(&wait_lock, "wait_lock");
    8000196a:	00007597          	auipc	a1,0x7
    8000196e:	87e58593          	addi	a1,a1,-1922 # 800081e8 <digits+0x1a8>
    80001972:	00010517          	auipc	a0,0x10
    80001976:	96650513          	addi	a0,a0,-1690 # 800112d8 <wait_lock>
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	1dc080e7          	jalr	476(ra) # 80000b56 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001982:	00010497          	auipc	s1,0x10
    80001986:	d6e48493          	addi	s1,s1,-658 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    8000198a:	00007b17          	auipc	s6,0x7
    8000198e:	86eb0b13          	addi	s6,s6,-1938 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    80001992:	8aa6                	mv	s5,s1
    80001994:	00006a17          	auipc	s4,0x6
    80001998:	66ca0a13          	addi	s4,s4,1644 # 80008000 <etext>
    8000199c:	04000937          	lui	s2,0x4000
    800019a0:	197d                	addi	s2,s2,-1
    800019a2:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a4:	00016997          	auipc	s3,0x16
    800019a8:	f4c98993          	addi	s3,s3,-180 # 800178f0 <tickslock>
      initlock(&p->lock, "proc");
    800019ac:	85da                	mv	a1,s6
    800019ae:	8526                	mv	a0,s1
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	1a6080e7          	jalr	422(ra) # 80000b56 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019b8:	415487b3          	sub	a5,s1,s5
    800019bc:	878d                	srai	a5,a5,0x3
    800019be:	000a3703          	ld	a4,0(s4)
    800019c2:	02e787b3          	mul	a5,a5,a4
    800019c6:	2785                	addiw	a5,a5,1
    800019c8:	00d7979b          	slliw	a5,a5,0xd
    800019cc:	40f907b3          	sub	a5,s2,a5
    800019d0:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019d2:	18848493          	addi	s1,s1,392
    800019d6:	fd349be3          	bne	s1,s3,800019ac <procinit+0xd6>
  }
}
    800019da:	70e2                	ld	ra,56(sp)
    800019dc:	7442                	ld	s0,48(sp)
    800019de:	74a2                	ld	s1,40(sp)
    800019e0:	7902                	ld	s2,32(sp)
    800019e2:	69e2                	ld	s3,24(sp)
    800019e4:	6a42                	ld	s4,16(sp)
    800019e6:	6aa2                	ld	s5,8(sp)
    800019e8:	6b02                	ld	s6,0(sp)
    800019ea:	6121                	addi	sp,sp,64
    800019ec:	8082                	ret

00000000800019ee <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019ee:	1141                	addi	sp,sp,-16
    800019f0:	e422                	sd	s0,8(sp)
    800019f2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019f4:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019f6:	2501                	sext.w	a0,a0
    800019f8:	6422                	ld	s0,8(sp)
    800019fa:	0141                	addi	sp,sp,16
    800019fc:	8082                	ret

00000000800019fe <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e422                	sd	s0,8(sp)
    80001a02:	0800                	addi	s0,sp,16
    80001a04:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a06:	2781                	sext.w	a5,a5
    80001a08:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a0a:	00010517          	auipc	a0,0x10
    80001a0e:	8e650513          	addi	a0,a0,-1818 # 800112f0 <cpus>
    80001a12:	953e                	add	a0,a0,a5
    80001a14:	6422                	ld	s0,8(sp)
    80001a16:	0141                	addi	sp,sp,16
    80001a18:	8082                	ret

0000000080001a1a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a1a:	1101                	addi	sp,sp,-32
    80001a1c:	ec06                	sd	ra,24(sp)
    80001a1e:	e822                	sd	s0,16(sp)
    80001a20:	e426                	sd	s1,8(sp)
    80001a22:	1000                	addi	s0,sp,32
  push_off();
    80001a24:	fffff097          	auipc	ra,0xfffff
    80001a28:	176080e7          	jalr	374(ra) # 80000b9a <push_off>
    80001a2c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a2e:	2781                	sext.w	a5,a5
    80001a30:	079e                	slli	a5,a5,0x7
    80001a32:	00010717          	auipc	a4,0x10
    80001a36:	88e70713          	addi	a4,a4,-1906 # 800112c0 <pid_lock>
    80001a3a:	97ba                	add	a5,a5,a4
    80001a3c:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a3e:	fffff097          	auipc	ra,0xfffff
    80001a42:	1fc080e7          	jalr	508(ra) # 80000c3a <pop_off>
  return p;
}
    80001a46:	8526                	mv	a0,s1
    80001a48:	60e2                	ld	ra,24(sp)
    80001a4a:	6442                	ld	s0,16(sp)
    80001a4c:	64a2                	ld	s1,8(sp)
    80001a4e:	6105                	addi	sp,sp,32
    80001a50:	8082                	ret

0000000080001a52 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a52:	1141                	addi	sp,sp,-16
    80001a54:	e406                	sd	ra,8(sp)
    80001a56:	e022                	sd	s0,0(sp)
    80001a58:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a5a:	00000097          	auipc	ra,0x0
    80001a5e:	fc0080e7          	jalr	-64(ra) # 80001a1a <myproc>
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	238080e7          	jalr	568(ra) # 80000c9a <release>

  if (first) {
    80001a6a:	00007797          	auipc	a5,0x7
    80001a6e:	ef67a783          	lw	a5,-266(a5) # 80008960 <first.1706>
    80001a72:	eb89                	bnez	a5,80001a84 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a74:	00001097          	auipc	ra,0x1
    80001a78:	3cc080e7          	jalr	972(ra) # 80002e40 <usertrapret>
}
    80001a7c:	60a2                	ld	ra,8(sp)
    80001a7e:	6402                	ld	s0,0(sp)
    80001a80:	0141                	addi	sp,sp,16
    80001a82:	8082                	ret
    first = 0;
    80001a84:	00007797          	auipc	a5,0x7
    80001a88:	ec07ae23          	sw	zero,-292(a5) # 80008960 <first.1706>
    fsinit(ROOTDEV);
    80001a8c:	4505                	li	a0,1
    80001a8e:	00002097          	auipc	ra,0x2
    80001a92:	144080e7          	jalr	324(ra) # 80003bd2 <fsinit>
    80001a96:	bff9                	j	80001a74 <forkret+0x22>

0000000080001a98 <allocpid>:
allocpid() {
    80001a98:	1101                	addi	sp,sp,-32
    80001a9a:	ec06                	sd	ra,24(sp)
    80001a9c:	e822                	sd	s0,16(sp)
    80001a9e:	e426                	sd	s1,8(sp)
    80001aa0:	e04a                	sd	s2,0(sp)
    80001aa2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aa4:	00010917          	auipc	s2,0x10
    80001aa8:	81c90913          	addi	s2,s2,-2020 # 800112c0 <pid_lock>
    80001aac:	854a                	mv	a0,s2
    80001aae:	fffff097          	auipc	ra,0xfffff
    80001ab2:	138080e7          	jalr	312(ra) # 80000be6 <acquire>
  pid = nextpid;
    80001ab6:	00007797          	auipc	a5,0x7
    80001aba:	eae78793          	addi	a5,a5,-338 # 80008964 <nextpid>
    80001abe:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ac0:	0014871b          	addiw	a4,s1,1
    80001ac4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ac6:	854a                	mv	a0,s2
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	1d2080e7          	jalr	466(ra) # 80000c9a <release>
}
    80001ad0:	8526                	mv	a0,s1
    80001ad2:	60e2                	ld	ra,24(sp)
    80001ad4:	6442                	ld	s0,16(sp)
    80001ad6:	64a2                	ld	s1,8(sp)
    80001ad8:	6902                	ld	s2,0(sp)
    80001ada:	6105                	addi	sp,sp,32
    80001adc:	8082                	ret

0000000080001ade <proc_pagetable>:
{
    80001ade:	1101                	addi	sp,sp,-32
    80001ae0:	ec06                	sd	ra,24(sp)
    80001ae2:	e822                	sd	s0,16(sp)
    80001ae4:	e426                	sd	s1,8(sp)
    80001ae6:	e04a                	sd	s2,0(sp)
    80001ae8:	1000                	addi	s0,sp,32
    80001aea:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001aec:	00000097          	auipc	ra,0x0
    80001af0:	850080e7          	jalr	-1968(ra) # 8000133c <uvmcreate>
    80001af4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001af6:	c121                	beqz	a0,80001b36 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001af8:	4729                	li	a4,10
    80001afa:	00005697          	auipc	a3,0x5
    80001afe:	50668693          	addi	a3,a3,1286 # 80007000 <_trampoline>
    80001b02:	6605                	lui	a2,0x1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	fffff097          	auipc	ra,0xfffff
    80001b10:	5a6080e7          	jalr	1446(ra) # 800010b2 <mappages>
    80001b14:	02054863          	bltz	a0,80001b44 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b18:	4719                	li	a4,6
    80001b1a:	05893683          	ld	a3,88(s2)
    80001b1e:	6605                	lui	a2,0x1
    80001b20:	020005b7          	lui	a1,0x2000
    80001b24:	15fd                	addi	a1,a1,-1
    80001b26:	05b6                	slli	a1,a1,0xd
    80001b28:	8526                	mv	a0,s1
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	588080e7          	jalr	1416(ra) # 800010b2 <mappages>
    80001b32:	02054163          	bltz	a0,80001b54 <proc_pagetable+0x76>
}
    80001b36:	8526                	mv	a0,s1
    80001b38:	60e2                	ld	ra,24(sp)
    80001b3a:	6442                	ld	s0,16(sp)
    80001b3c:	64a2                	ld	s1,8(sp)
    80001b3e:	6902                	ld	s2,0(sp)
    80001b40:	6105                	addi	sp,sp,32
    80001b42:	8082                	ret
    uvmfree(pagetable, 0);
    80001b44:	4581                	li	a1,0
    80001b46:	8526                	mv	a0,s1
    80001b48:	00000097          	auipc	ra,0x0
    80001b4c:	9f0080e7          	jalr	-1552(ra) # 80001538 <uvmfree>
    return 0;
    80001b50:	4481                	li	s1,0
    80001b52:	b7d5                	j	80001b36 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b54:	4681                	li	a3,0
    80001b56:	4605                	li	a2,1
    80001b58:	040005b7          	lui	a1,0x4000
    80001b5c:	15fd                	addi	a1,a1,-1
    80001b5e:	05b2                	slli	a1,a1,0xc
    80001b60:	8526                	mv	a0,s1
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	716080e7          	jalr	1814(ra) # 80001278 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b6a:	4581                	li	a1,0
    80001b6c:	8526                	mv	a0,s1
    80001b6e:	00000097          	auipc	ra,0x0
    80001b72:	9ca080e7          	jalr	-1590(ra) # 80001538 <uvmfree>
    return 0;
    80001b76:	4481                	li	s1,0
    80001b78:	bf7d                	j	80001b36 <proc_pagetable+0x58>

0000000080001b7a <proc_freepagetable>:
{
    80001b7a:	1101                	addi	sp,sp,-32
    80001b7c:	ec06                	sd	ra,24(sp)
    80001b7e:	e822                	sd	s0,16(sp)
    80001b80:	e426                	sd	s1,8(sp)
    80001b82:	e04a                	sd	s2,0(sp)
    80001b84:	1000                	addi	s0,sp,32
    80001b86:	84aa                	mv	s1,a0
    80001b88:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b8a:	4681                	li	a3,0
    80001b8c:	4605                	li	a2,1
    80001b8e:	040005b7          	lui	a1,0x4000
    80001b92:	15fd                	addi	a1,a1,-1
    80001b94:	05b2                	slli	a1,a1,0xc
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	6e2080e7          	jalr	1762(ra) # 80001278 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b9e:	4681                	li	a3,0
    80001ba0:	4605                	li	a2,1
    80001ba2:	020005b7          	lui	a1,0x2000
    80001ba6:	15fd                	addi	a1,a1,-1
    80001ba8:	05b6                	slli	a1,a1,0xd
    80001baa:	8526                	mv	a0,s1
    80001bac:	fffff097          	auipc	ra,0xfffff
    80001bb0:	6cc080e7          	jalr	1740(ra) # 80001278 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bb4:	85ca                	mv	a1,s2
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	00000097          	auipc	ra,0x0
    80001bbc:	980080e7          	jalr	-1664(ra) # 80001538 <uvmfree>
}
    80001bc0:	60e2                	ld	ra,24(sp)
    80001bc2:	6442                	ld	s0,16(sp)
    80001bc4:	64a2                	ld	s1,8(sp)
    80001bc6:	6902                	ld	s2,0(sp)
    80001bc8:	6105                	addi	sp,sp,32
    80001bca:	8082                	ret

0000000080001bcc <freeproc>:
{
    80001bcc:	1101                	addi	sp,sp,-32
    80001bce:	ec06                	sd	ra,24(sp)
    80001bd0:	e822                	sd	s0,16(sp)
    80001bd2:	e426                	sd	s1,8(sp)
    80001bd4:	1000                	addi	s0,sp,32
    80001bd6:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bd8:	6d28                	ld	a0,88(a0)
    80001bda:	c509                	beqz	a0,80001be4 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	e1e080e7          	jalr	-482(ra) # 800009fa <kfree>
  p->trapframe = 0;
    80001be4:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001be8:	68a8                	ld	a0,80(s1)
    80001bea:	c511                	beqz	a0,80001bf6 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bec:	64ac                	ld	a1,72(s1)
    80001bee:	00000097          	auipc	ra,0x0
    80001bf2:	f8c080e7          	jalr	-116(ra) # 80001b7a <proc_freepagetable>
  p->pagetable = 0;
    80001bf6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bfa:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bfe:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c02:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c06:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c0a:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c0e:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c12:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c16:	0004ac23          	sw	zero,24(s1)
}
    80001c1a:	60e2                	ld	ra,24(sp)
    80001c1c:	6442                	ld	s0,16(sp)
    80001c1e:	64a2                	ld	s1,8(sp)
    80001c20:	6105                	addi	sp,sp,32
    80001c22:	8082                	ret

0000000080001c24 <allocproc>:
{
    80001c24:	1101                	addi	sp,sp,-32
    80001c26:	ec06                	sd	ra,24(sp)
    80001c28:	e822                	sd	s0,16(sp)
    80001c2a:	e426                	sd	s1,8(sp)
    80001c2c:	e04a                	sd	s2,0(sp)
    80001c2e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c30:	00010497          	auipc	s1,0x10
    80001c34:	ac048493          	addi	s1,s1,-1344 # 800116f0 <proc>
    80001c38:	00016917          	auipc	s2,0x16
    80001c3c:	cb890913          	addi	s2,s2,-840 # 800178f0 <tickslock>
    acquire(&p->lock);
    80001c40:	8526                	mv	a0,s1
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	fa4080e7          	jalr	-92(ra) # 80000be6 <acquire>
    if(p->state == UNUSED) {
    80001c4a:	4c9c                	lw	a5,24(s1)
    80001c4c:	2781                	sext.w	a5,a5
    80001c4e:	cf81                	beqz	a5,80001c66 <allocproc+0x42>
      release(&p->lock);
    80001c50:	8526                	mv	a0,s1
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	048080e7          	jalr	72(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c5a:	18848493          	addi	s1,s1,392
    80001c5e:	ff2491e3          	bne	s1,s2,80001c40 <allocproc+0x1c>
  return 0;
    80001c62:	4481                	li	s1,0
    80001c64:	a8a9                	j	80001cbe <allocproc+0x9a>
  p->pid = allocpid();
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	e32080e7          	jalr	-462(ra) # 80001a98 <allocpid>
    80001c6e:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c70:	4785                	li	a5,1
    80001c72:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	e82080e7          	jalr	-382(ra) # 80000af6 <kalloc>
    80001c7c:	892a                	mv	s2,a0
    80001c7e:	eca8                	sd	a0,88(s1)
    80001c80:	c531                	beqz	a0,80001ccc <allocproc+0xa8>
  p->pagetable = proc_pagetable(p);
    80001c82:	8526                	mv	a0,s1
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	e5a080e7          	jalr	-422(ra) # 80001ade <proc_pagetable>
    80001c8c:	892a                	mv	s2,a0
    80001c8e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c90:	c931                	beqz	a0,80001ce4 <allocproc+0xc0>
  memset(&p->context, 0, sizeof(p->context));
    80001c92:	07000613          	li	a2,112
    80001c96:	4581                	li	a1,0
    80001c98:	06048513          	addi	a0,s1,96
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	046080e7          	jalr	70(ra) # 80000ce2 <memset>
  p->context.ra = (uint64)forkret;
    80001ca4:	00000797          	auipc	a5,0x0
    80001ca8:	dae78793          	addi	a5,a5,-594 # 80001a52 <forkret>
    80001cac:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cae:	60bc                	ld	a5,64(s1)
    80001cb0:	6705                	lui	a4,0x1
    80001cb2:	97ba                	add	a5,a5,a4
    80001cb4:	f4bc                	sd	a5,104(s1)
  p->mean_ticks = 0;
    80001cb6:	1604a423          	sw	zero,360(s1)
  p->last_ticks = 0;
    80001cba:	1604a623          	sw	zero,364(s1)
}
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	60e2                	ld	ra,24(sp)
    80001cc2:	6442                	ld	s0,16(sp)
    80001cc4:	64a2                	ld	s1,8(sp)
    80001cc6:	6902                	ld	s2,0(sp)
    80001cc8:	6105                	addi	sp,sp,32
    80001cca:	8082                	ret
    freeproc(p);
    80001ccc:	8526                	mv	a0,s1
    80001cce:	00000097          	auipc	ra,0x0
    80001cd2:	efe080e7          	jalr	-258(ra) # 80001bcc <freeproc>
    release(&p->lock);
    80001cd6:	8526                	mv	a0,s1
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	fc2080e7          	jalr	-62(ra) # 80000c9a <release>
    return 0;
    80001ce0:	84ca                	mv	s1,s2
    80001ce2:	bff1                	j	80001cbe <allocproc+0x9a>
    freeproc(p);
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	00000097          	auipc	ra,0x0
    80001cea:	ee6080e7          	jalr	-282(ra) # 80001bcc <freeproc>
    release(&p->lock);
    80001cee:	8526                	mv	a0,s1
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	faa080e7          	jalr	-86(ra) # 80000c9a <release>
    return 0;
    80001cf8:	84ca                	mv	s1,s2
    80001cfa:	b7d1                	j	80001cbe <allocproc+0x9a>

0000000080001cfc <userinit>:
{
    80001cfc:	1101                	addi	sp,sp,-32
    80001cfe:	ec06                	sd	ra,24(sp)
    80001d00:	e822                	sd	s0,16(sp)
    80001d02:	e426                	sd	s1,8(sp)
    80001d04:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d06:	00000097          	auipc	ra,0x0
    80001d0a:	f1e080e7          	jalr	-226(ra) # 80001c24 <allocproc>
    80001d0e:	84aa                	mv	s1,a0
  initproc = p;
    80001d10:	00007797          	auipc	a5,0x7
    80001d14:	32a7b023          	sd	a0,800(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d18:	03400613          	li	a2,52
    80001d1c:	00007597          	auipc	a1,0x7
    80001d20:	c5458593          	addi	a1,a1,-940 # 80008970 <initcode>
    80001d24:	6928                	ld	a0,80(a0)
    80001d26:	fffff097          	auipc	ra,0xfffff
    80001d2a:	644080e7          	jalr	1604(ra) # 8000136a <uvminit>
  p->sz = PGSIZE;
    80001d2e:	6785                	lui	a5,0x1
    80001d30:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d32:	6cb8                	ld	a4,88(s1)
    80001d34:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d38:	6cb8                	ld	a4,88(s1)
    80001d3a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d3c:	4641                	li	a2,16
    80001d3e:	00006597          	auipc	a1,0x6
    80001d42:	4c258593          	addi	a1,a1,1218 # 80008200 <digits+0x1c0>
    80001d46:	15848513          	addi	a0,s1,344
    80001d4a:	fffff097          	auipc	ra,0xfffff
    80001d4e:	0ea080e7          	jalr	234(ra) # 80000e34 <safestrcpy>
  p->cwd = namei("/");
    80001d52:	00006517          	auipc	a0,0x6
    80001d56:	4be50513          	addi	a0,a0,1214 # 80008210 <digits+0x1d0>
    80001d5a:	00003097          	auipc	ra,0x3
    80001d5e:	8a6080e7          	jalr	-1882(ra) # 80004600 <namei>
    80001d62:	14a4b823          	sd	a0,336(s1)
  p->runnable_time = 0;
    80001d66:	1604ae23          	sw	zero,380(s1)
  p->running_time = 0;
    80001d6a:	1604ac23          	sw	zero,376(s1)
  p -> sleeping_time = 0;
    80001d6e:	1604aa23          	sw	zero,372(s1)
  acquire(&tickslock);
    80001d72:	00016517          	auipc	a0,0x16
    80001d76:	b7e50513          	addi	a0,a0,-1154 # 800178f0 <tickslock>
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	e6c080e7          	jalr	-404(ra) # 80000be6 <acquire>
  p->last_update_time = ticks;
    80001d82:	00007797          	auipc	a5,0x7
    80001d86:	2d27a783          	lw	a5,722(a5) # 80009054 <ticks>
    80001d8a:	18f4a023          	sw	a5,384(s1)
  release(&tickslock);
    80001d8e:	00016517          	auipc	a0,0x16
    80001d92:	b6250513          	addi	a0,a0,-1182 # 800178f0 <tickslock>
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	f04080e7          	jalr	-252(ra) # 80000c9a <release>
  p->state = RUNNABLE;
    80001d9e:	478d                	li	a5,3
    80001da0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001da2:	8526                	mv	a0,s1
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	ef6080e7          	jalr	-266(ra) # 80000c9a <release>
}
    80001dac:	60e2                	ld	ra,24(sp)
    80001dae:	6442                	ld	s0,16(sp)
    80001db0:	64a2                	ld	s1,8(sp)
    80001db2:	6105                	addi	sp,sp,32
    80001db4:	8082                	ret

0000000080001db6 <growproc>:
{
    80001db6:	1101                	addi	sp,sp,-32
    80001db8:	ec06                	sd	ra,24(sp)
    80001dba:	e822                	sd	s0,16(sp)
    80001dbc:	e426                	sd	s1,8(sp)
    80001dbe:	e04a                	sd	s2,0(sp)
    80001dc0:	1000                	addi	s0,sp,32
    80001dc2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dc4:	00000097          	auipc	ra,0x0
    80001dc8:	c56080e7          	jalr	-938(ra) # 80001a1a <myproc>
    80001dcc:	892a                	mv	s2,a0
  sz = p->sz;
    80001dce:	652c                	ld	a1,72(a0)
    80001dd0:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001dd4:	00904f63          	bgtz	s1,80001df2 <growproc+0x3c>
  } else if(n < 0){
    80001dd8:	0204cc63          	bltz	s1,80001e10 <growproc+0x5a>
  p->sz = sz;
    80001ddc:	1602                	slli	a2,a2,0x20
    80001dde:	9201                	srli	a2,a2,0x20
    80001de0:	04c93423          	sd	a2,72(s2)
  return 0;
    80001de4:	4501                	li	a0,0
}
    80001de6:	60e2                	ld	ra,24(sp)
    80001de8:	6442                	ld	s0,16(sp)
    80001dea:	64a2                	ld	s1,8(sp)
    80001dec:	6902                	ld	s2,0(sp)
    80001dee:	6105                	addi	sp,sp,32
    80001df0:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001df2:	9e25                	addw	a2,a2,s1
    80001df4:	1602                	slli	a2,a2,0x20
    80001df6:	9201                	srli	a2,a2,0x20
    80001df8:	1582                	slli	a1,a1,0x20
    80001dfa:	9181                	srli	a1,a1,0x20
    80001dfc:	6928                	ld	a0,80(a0)
    80001dfe:	fffff097          	auipc	ra,0xfffff
    80001e02:	626080e7          	jalr	1574(ra) # 80001424 <uvmalloc>
    80001e06:	0005061b          	sext.w	a2,a0
    80001e0a:	fa69                	bnez	a2,80001ddc <growproc+0x26>
      return -1;
    80001e0c:	557d                	li	a0,-1
    80001e0e:	bfe1                	j	80001de6 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e10:	9e25                	addw	a2,a2,s1
    80001e12:	1602                	slli	a2,a2,0x20
    80001e14:	9201                	srli	a2,a2,0x20
    80001e16:	1582                	slli	a1,a1,0x20
    80001e18:	9181                	srli	a1,a1,0x20
    80001e1a:	6928                	ld	a0,80(a0)
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	5c0080e7          	jalr	1472(ra) # 800013dc <uvmdealloc>
    80001e24:	0005061b          	sext.w	a2,a0
    80001e28:	bf55                	j	80001ddc <growproc+0x26>

0000000080001e2a <fork>:
{
    80001e2a:	7179                	addi	sp,sp,-48
    80001e2c:	f406                	sd	ra,40(sp)
    80001e2e:	f022                	sd	s0,32(sp)
    80001e30:	ec26                	sd	s1,24(sp)
    80001e32:	e84a                	sd	s2,16(sp)
    80001e34:	e44e                	sd	s3,8(sp)
    80001e36:	e052                	sd	s4,0(sp)
    80001e38:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e3a:	00000097          	auipc	ra,0x0
    80001e3e:	be0080e7          	jalr	-1056(ra) # 80001a1a <myproc>
    80001e42:	89aa                	mv	s3,a0
  process_count++;
    80001e44:	00007717          	auipc	a4,0x7
    80001e48:	20070713          	addi	a4,a4,512 # 80009044 <process_count>
    80001e4c:	431c                	lw	a5,0(a4)
    80001e4e:	2785                	addiw	a5,a5,1
    80001e50:	c31c                	sw	a5,0(a4)
  if((np = allocproc()) == 0){
    80001e52:	00000097          	auipc	ra,0x0
    80001e56:	dd2080e7          	jalr	-558(ra) # 80001c24 <allocproc>
    80001e5a:	14050b63          	beqz	a0,80001fb0 <fork+0x186>
    80001e5e:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e60:	0489b603          	ld	a2,72(s3)
    80001e64:	692c                	ld	a1,80(a0)
    80001e66:	0509b503          	ld	a0,80(s3)
    80001e6a:	fffff097          	auipc	ra,0xfffff
    80001e6e:	706080e7          	jalr	1798(ra) # 80001570 <uvmcopy>
    80001e72:	04054663          	bltz	a0,80001ebe <fork+0x94>
  np->sz = p->sz;
    80001e76:	0489b783          	ld	a5,72(s3)
    80001e7a:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    80001e7e:	0589b683          	ld	a3,88(s3)
    80001e82:	87b6                	mv	a5,a3
    80001e84:	05893703          	ld	a4,88(s2)
    80001e88:	12068693          	addi	a3,a3,288
    80001e8c:	0007b803          	ld	a6,0(a5)
    80001e90:	6788                	ld	a0,8(a5)
    80001e92:	6b8c                	ld	a1,16(a5)
    80001e94:	6f90                	ld	a2,24(a5)
    80001e96:	01073023          	sd	a6,0(a4)
    80001e9a:	e708                	sd	a0,8(a4)
    80001e9c:	eb0c                	sd	a1,16(a4)
    80001e9e:	ef10                	sd	a2,24(a4)
    80001ea0:	02078793          	addi	a5,a5,32
    80001ea4:	02070713          	addi	a4,a4,32
    80001ea8:	fed792e3          	bne	a5,a3,80001e8c <fork+0x62>
  np->trapframe->a0 = 0;
    80001eac:	05893783          	ld	a5,88(s2)
    80001eb0:	0607b823          	sd	zero,112(a5)
    80001eb4:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001eb8:	15000a13          	li	s4,336
    80001ebc:	a03d                	j	80001eea <fork+0xc0>
    freeproc(np);
    80001ebe:	854a                	mv	a0,s2
    80001ec0:	00000097          	auipc	ra,0x0
    80001ec4:	d0c080e7          	jalr	-756(ra) # 80001bcc <freeproc>
    release(&np->lock);
    80001ec8:	854a                	mv	a0,s2
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	dd0080e7          	jalr	-560(ra) # 80000c9a <release>
    return -1;
    80001ed2:	5a7d                	li	s4,-1
    80001ed4:	a0e9                	j	80001f9e <fork+0x174>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ed6:	00003097          	auipc	ra,0x3
    80001eda:	dc0080e7          	jalr	-576(ra) # 80004c96 <filedup>
    80001ede:	009907b3          	add	a5,s2,s1
    80001ee2:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ee4:	04a1                	addi	s1,s1,8
    80001ee6:	01448763          	beq	s1,s4,80001ef4 <fork+0xca>
    if(p->ofile[i])
    80001eea:	009987b3          	add	a5,s3,s1
    80001eee:	6388                	ld	a0,0(a5)
    80001ef0:	f17d                	bnez	a0,80001ed6 <fork+0xac>
    80001ef2:	bfcd                	j	80001ee4 <fork+0xba>
  np->cwd = idup(p->cwd);
    80001ef4:	1509b503          	ld	a0,336(s3)
    80001ef8:	00002097          	auipc	ra,0x2
    80001efc:	f14080e7          	jalr	-236(ra) # 80003e0c <idup>
    80001f00:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f04:	4641                	li	a2,16
    80001f06:	15898593          	addi	a1,s3,344
    80001f0a:	15890513          	addi	a0,s2,344
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	f26080e7          	jalr	-218(ra) # 80000e34 <safestrcpy>
  pid = np->pid;
    80001f16:	03092a03          	lw	s4,48(s2)
  np->last_ticks = 0;
    80001f1a:	16092623          	sw	zero,364(s2)
  np->mean_ticks = 0;
    80001f1e:	16092423          	sw	zero,360(s2)
  release(&np->lock);
    80001f22:	854a                	mv	a0,s2
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	d76080e7          	jalr	-650(ra) # 80000c9a <release>
  acquire(&wait_lock);
    80001f2c:	0000f497          	auipc	s1,0xf
    80001f30:	3ac48493          	addi	s1,s1,940 # 800112d8 <wait_lock>
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	cb0080e7          	jalr	-848(ra) # 80000be6 <acquire>
  np->parent = p;
    80001f3e:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    80001f42:	8526                	mv	a0,s1
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	d56080e7          	jalr	-682(ra) # 80000c9a <release>
  acquire(&np->lock);
    80001f4c:	854a                	mv	a0,s2
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	c98080e7          	jalr	-872(ra) # 80000be6 <acquire>
  np->runnable_time = 0;
    80001f56:	16092e23          	sw	zero,380(s2)
  np->running_time = 0;
    80001f5a:	16092c23          	sw	zero,376(s2)
  np -> sleeping_time = 0;
    80001f5e:	16092a23          	sw	zero,372(s2)
  acquire(&tickslock);
    80001f62:	00016517          	auipc	a0,0x16
    80001f66:	98e50513          	addi	a0,a0,-1650 # 800178f0 <tickslock>
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	c7c080e7          	jalr	-900(ra) # 80000be6 <acquire>
  np->last_update_time = ticks;
    80001f72:	00007797          	auipc	a5,0x7
    80001f76:	0e27a783          	lw	a5,226(a5) # 80009054 <ticks>
    80001f7a:	18f92023          	sw	a5,384(s2)
  release(&tickslock);
    80001f7e:	00016517          	auipc	a0,0x16
    80001f82:	97250513          	addi	a0,a0,-1678 # 800178f0 <tickslock>
    80001f86:	fffff097          	auipc	ra,0xfffff
    80001f8a:	d14080e7          	jalr	-748(ra) # 80000c9a <release>
  np->state = RUNNABLE;
    80001f8e:	478d                	li	a5,3
    80001f90:	00f92c23          	sw	a5,24(s2)
  release(&np->lock);
    80001f94:	854a                	mv	a0,s2
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	d04080e7          	jalr	-764(ra) # 80000c9a <release>
}
    80001f9e:	8552                	mv	a0,s4
    80001fa0:	70a2                	ld	ra,40(sp)
    80001fa2:	7402                	ld	s0,32(sp)
    80001fa4:	64e2                	ld	s1,24(sp)
    80001fa6:	6942                	ld	s2,16(sp)
    80001fa8:	69a2                	ld	s3,8(sp)
    80001faa:	6a02                	ld	s4,0(sp)
    80001fac:	6145                	addi	sp,sp,48
    80001fae:	8082                	ret
    return -1;
    80001fb0:	5a7d                	li	s4,-1
    80001fb2:	b7f5                	j	80001f9e <fork+0x174>

0000000080001fb4 <scheduler>:
{
    80001fb4:	7159                	addi	sp,sp,-112
    80001fb6:	f486                	sd	ra,104(sp)
    80001fb8:	f0a2                	sd	s0,96(sp)
    80001fba:	eca6                	sd	s1,88(sp)
    80001fbc:	e8ca                	sd	s2,80(sp)
    80001fbe:	e4ce                	sd	s3,72(sp)
    80001fc0:	e0d2                	sd	s4,64(sp)
    80001fc2:	fc56                	sd	s5,56(sp)
    80001fc4:	f85a                	sd	s6,48(sp)
    80001fc6:	f45e                	sd	s7,40(sp)
    80001fc8:	f062                	sd	s8,32(sp)
    80001fca:	ec66                	sd	s9,24(sp)
    80001fcc:	e86a                	sd	s10,16(sp)
    80001fce:	e46e                	sd	s11,8(sp)
    80001fd0:	1880                	addi	s0,sp,112
    80001fd2:	8792                	mv	a5,tp
  int id = r_tp();
    80001fd4:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fd6:	00779d93          	slli	s11,a5,0x7
    80001fda:	0000f717          	auipc	a4,0xf
    80001fde:	2e670713          	addi	a4,a4,742 # 800112c0 <pid_lock>
    80001fe2:	976e                	add	a4,a4,s11
    80001fe4:	02073823          	sd	zero,48(a4)
         swtch(&c->context, &hp->context);
    80001fe8:	0000f717          	auipc	a4,0xf
    80001fec:	31070713          	addi	a4,a4,784 # 800112f8 <cpus+0x8>
    80001ff0:	9dba                	add	s11,s11,a4
    while(paused)
    80001ff2:	00007c97          	auipc	s9,0x7
    80001ff6:	03ac8c93          	addi	s9,s9,58 # 8000902c <paused>
      acquire(&tickslock);
    80001ffa:	00016b17          	auipc	s6,0x16
    80001ffe:	8f6b0b13          	addi	s6,s6,-1802 # 800178f0 <tickslock>
      if(ticks >= pause_interval)
    80002002:	00007b97          	auipc	s7,0x7
    80002006:	052b8b93          	addi	s7,s7,82 # 80009054 <ticks>
         c->proc = hp;
    8000200a:	079e                	slli	a5,a5,0x7
    8000200c:	0000fc17          	auipc	s8,0xf
    80002010:	2b4c0c13          	addi	s8,s8,692 # 800112c0 <pid_lock>
    80002014:	9c3e                	add	s8,s8,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002016:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000201a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000201e:	10079073          	csrw	sstatus,a5
    while(paused)
    80002022:	000ca783          	lw	a5,0(s9)
    80002026:	2781                	sext.w	a5,a5
    80002028:	c3b9                	beqz	a5,8000206e <scheduler+0xba>
      if(ticks >= pause_interval)
    8000202a:	00007497          	auipc	s1,0x7
    8000202e:	ffe48493          	addi	s1,s1,-2 # 80009028 <pause_interval>
    80002032:	a811                	j	80002046 <scheduler+0x92>
      release(&tickslock);
    80002034:	855a                	mv	a0,s6
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	c64080e7          	jalr	-924(ra) # 80000c9a <release>
    while(paused)
    8000203e:	000ca783          	lw	a5,0(s9)
    80002042:	2781                	sext.w	a5,a5
    80002044:	c78d                	beqz	a5,8000206e <scheduler+0xba>
      acquire(&tickslock);
    80002046:	855a                	mv	a0,s6
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	b9e080e7          	jalr	-1122(ra) # 80000be6 <acquire>
      if(ticks >= pause_interval)
    80002050:	409c                	lw	a5,0(s1)
    80002052:	2781                	sext.w	a5,a5
    80002054:	000ba703          	lw	a4,0(s7)
    80002058:	fcf76ee3          	bltu	a4,a5,80002034 <scheduler+0x80>
        paused ^= paused;
    8000205c:	000ca703          	lw	a4,0(s9)
    80002060:	000ca783          	lw	a5,0(s9)
    80002064:	8fb9                	xor	a5,a5,a4
    80002066:	2781                	sext.w	a5,a5
    80002068:	00fca023          	sw	a5,0(s9)
    8000206c:	b7e1                	j	80002034 <scheduler+0x80>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000206e:	0000f917          	auipc	s2,0xf
    80002072:	68290913          	addi	s2,s2,1666 # 800116f0 <proc>
      if(p->state == RUNNABLE) 
    80002076:	4a8d                	li	s5,3
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    80002078:	00016a17          	auipc	s4,0x16
    8000207c:	878a0a13          	addi	s4,s4,-1928 # 800178f0 <tickslock>
          if(hp->state == RUNNING){
    80002080:	4d11                	li	s10,4
    80002082:	a229                	j	8000218c <scheduler+0x1d8>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    80002084:	18890493          	addi	s1,s2,392
    80002088:	0544f363          	bgeu	s1,s4,800020ce <scheduler+0x11a>
    8000208c:	89ca                	mv	s3,s2
    8000208e:	a811                	j	800020a2 <scheduler+0xee>
            release(&c->lock);
    80002090:	8526                	mv	a0,s1
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	c08080e7          	jalr	-1016(ra) # 80000c9a <release>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    8000209a:	18848493          	addi	s1,s1,392
    8000209e:	0344f963          	bgeu	s1,s4,800020d0 <scheduler+0x11c>
           acquire(&c->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	b42080e7          	jalr	-1214(ra) # 80000be6 <acquire>
           if((c->state == RUNNABLE) && (c->mean_ticks < hp->mean_ticks))
    800020ac:	4c9c                	lw	a5,24(s1)
    800020ae:	2781                	sext.w	a5,a5
    800020b0:	ff5790e3          	bne	a5,s5,80002090 <scheduler+0xdc>
    800020b4:	1684a703          	lw	a4,360(s1)
    800020b8:	1689a783          	lw	a5,360(s3)
    800020bc:	fcf77ae3          	bgeu	a4,a5,80002090 <scheduler+0xdc>
             release(&hp->lock);
    800020c0:	854e                	mv	a0,s3
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	bd8080e7          	jalr	-1064(ra) # 80000c9a <release>
             hp = c;
    800020ca:	89a6                	mv	s3,s1
    800020cc:	b7f9                	j	8000209a <scheduler+0xe6>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    800020ce:	89ca                	mv	s3,s2
          acquire(&tickslock);
    800020d0:	855a                	mv	a0,s6
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	b14080e7          	jalr	-1260(ra) # 80000be6 <acquire>
          int diff = ticks - hp->last_update_time;
    800020da:	000ba483          	lw	s1,0(s7)
    800020de:	1809a783          	lw	a5,384(s3)
    800020e2:	9c9d                	subw	s1,s1,a5
          release(&tickslock);
    800020e4:	855a                	mv	a0,s6
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	bb4080e7          	jalr	-1100(ra) # 80000c9a <release>
          if(hp->state == RUNNABLE){
    800020ee:	0189a783          	lw	a5,24(s3)
    800020f2:	2781                	sext.w	a5,a5
    800020f4:	0b578c63          	beq	a5,s5,800021ac <scheduler+0x1f8>
          if(hp->state == RUNNING){
    800020f8:	0189a783          	lw	a5,24(s3)
    800020fc:	2781                	sext.w	a5,a5
    800020fe:	0ba78d63          	beq	a5,s10,800021b8 <scheduler+0x204>
          if(hp->state == SLEEPING){
    80002102:	0189a783          	lw	a5,24(s3)
    80002106:	2781                	sext.w	a5,a5
    80002108:	4709                	li	a4,2
    8000210a:	0ae78d63          	beq	a5,a4,800021c4 <scheduler+0x210>
         hp->state = RUNNING;
    8000210e:	4791                	li	a5,4
    80002110:	00f9ac23          	sw	a5,24(s3)
         c->proc = hp;
    80002114:	033c3823          	sd	s3,48(s8)
         acquire(&tickslock);
    80002118:	855a                	mv	a0,s6
    8000211a:	fffff097          	auipc	ra,0xfffff
    8000211e:	acc080e7          	jalr	-1332(ra) # 80000be6 <acquire>
         burst = ticks;
    80002122:	000ba483          	lw	s1,0(s7)
         release(&tickslock);
    80002126:	855a                	mv	a0,s6
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	b72080e7          	jalr	-1166(ra) # 80000c9a <release>
         swtch(&c->context, &hp->context);
    80002130:	06098593          	addi	a1,s3,96
    80002134:	856e                	mv	a0,s11
    80002136:	00001097          	auipc	ra,0x1
    8000213a:	c60080e7          	jalr	-928(ra) # 80002d96 <swtch>
         acquire(&tickslock);
    8000213e:	855a                	mv	a0,s6
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	aa6080e7          	jalr	-1370(ra) # 80000be6 <acquire>
         burst = ticks - burst;
    80002148:	000ba703          	lw	a4,0(s7)
    8000214c:	409704bb          	subw	s1,a4,s1
         release(&tickslock);
    80002150:	855a                	mv	a0,s6
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	b48080e7          	jalr	-1208(ra) # 80000c9a <release>
         hp->last_ticks = burst;
    8000215a:	1699a623          	sw	s1,364(s3)
         hp->mean_ticks = ((10 - rate) * hp->mean_ticks + burst * rate) / 10;
    8000215e:	1689a783          	lw	a5,360(s3)
    80002162:	0097873b          	addw	a4,a5,s1
    80002166:	0027179b          	slliw	a5,a4,0x2
    8000216a:	9fb9                	addw	a5,a5,a4
    8000216c:	4729                	li	a4,10
    8000216e:	02e7d7bb          	divuw	a5,a5,a4
    80002172:	16f9a423          	sw	a5,360(s3)
         c->proc = 0;
    80002176:	020c3823          	sd	zero,48(s8)
         release(&hp->lock);
    8000217a:	854e                	mv	a0,s3
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	b1e080e7          	jalr	-1250(ra) # 80000c9a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002184:	18890913          	addi	s2,s2,392
    80002188:	e94907e3          	beq	s2,s4,80002016 <scheduler+0x62>
      acquire(&p->lock);
    8000218c:	854a                	mv	a0,s2
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	a58080e7          	jalr	-1448(ra) # 80000be6 <acquire>
      if(p->state == RUNNABLE) 
    80002196:	01892783          	lw	a5,24(s2)
    8000219a:	2781                	sext.w	a5,a5
    8000219c:	ef5784e3          	beq	a5,s5,80002084 <scheduler+0xd0>
        release(&p->lock);
    800021a0:	854a                	mv	a0,s2
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	af8080e7          	jalr	-1288(ra) # 80000c9a <release>
    800021aa:	bfe9                	j	80002184 <scheduler+0x1d0>
            hp->runnable_time += diff;
    800021ac:	17c9a783          	lw	a5,380(s3)
    800021b0:	9fa5                	addw	a5,a5,s1
    800021b2:	16f9ae23          	sw	a5,380(s3)
    800021b6:	b789                	j	800020f8 <scheduler+0x144>
            hp->running_time += diff;
    800021b8:	1789a783          	lw	a5,376(s3)
    800021bc:	9fa5                	addw	a5,a5,s1
    800021be:	16f9ac23          	sw	a5,376(s3)
    800021c2:	b781                	j	80002102 <scheduler+0x14e>
            hp->sleeping_time += diff;
    800021c4:	1749a783          	lw	a5,372(s3)
    800021c8:	9cbd                	addw	s1,s1,a5
    800021ca:	1699aa23          	sw	s1,372(s3)
    800021ce:	b781                	j	8000210e <scheduler+0x15a>

00000000800021d0 <sched>:
{
    800021d0:	7179                	addi	sp,sp,-48
    800021d2:	f406                	sd	ra,40(sp)
    800021d4:	f022                	sd	s0,32(sp)
    800021d6:	ec26                	sd	s1,24(sp)
    800021d8:	e84a                	sd	s2,16(sp)
    800021da:	e44e                	sd	s3,8(sp)
    800021dc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021de:	00000097          	auipc	ra,0x0
    800021e2:	83c080e7          	jalr	-1988(ra) # 80001a1a <myproc>
    800021e6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	984080e7          	jalr	-1660(ra) # 80000b6c <holding>
    800021f0:	cd25                	beqz	a0,80002268 <sched+0x98>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021f2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021f4:	2781                	sext.w	a5,a5
    800021f6:	079e                	slli	a5,a5,0x7
    800021f8:	0000f717          	auipc	a4,0xf
    800021fc:	0c870713          	addi	a4,a4,200 # 800112c0 <pid_lock>
    80002200:	97ba                	add	a5,a5,a4
    80002202:	0a87a703          	lw	a4,168(a5)
    80002206:	4785                	li	a5,1
    80002208:	06f71863          	bne	a4,a5,80002278 <sched+0xa8>
  if(p->state == RUNNING)
    8000220c:	4c9c                	lw	a5,24(s1)
    8000220e:	2781                	sext.w	a5,a5
    80002210:	4711                	li	a4,4
    80002212:	06e78b63          	beq	a5,a4,80002288 <sched+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002216:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000221a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000221c:	efb5                	bnez	a5,80002298 <sched+0xc8>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000221e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002220:	0000f917          	auipc	s2,0xf
    80002224:	0a090913          	addi	s2,s2,160 # 800112c0 <pid_lock>
    80002228:	2781                	sext.w	a5,a5
    8000222a:	079e                	slli	a5,a5,0x7
    8000222c:	97ca                	add	a5,a5,s2
    8000222e:	0ac7a983          	lw	s3,172(a5)
    80002232:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002234:	2781                	sext.w	a5,a5
    80002236:	079e                	slli	a5,a5,0x7
    80002238:	0000f597          	auipc	a1,0xf
    8000223c:	0c058593          	addi	a1,a1,192 # 800112f8 <cpus+0x8>
    80002240:	95be                	add	a1,a1,a5
    80002242:	06048513          	addi	a0,s1,96
    80002246:	00001097          	auipc	ra,0x1
    8000224a:	b50080e7          	jalr	-1200(ra) # 80002d96 <swtch>
    8000224e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002250:	2781                	sext.w	a5,a5
    80002252:	079e                	slli	a5,a5,0x7
    80002254:	97ca                	add	a5,a5,s2
    80002256:	0b37a623          	sw	s3,172(a5)
}
    8000225a:	70a2                	ld	ra,40(sp)
    8000225c:	7402                	ld	s0,32(sp)
    8000225e:	64e2                	ld	s1,24(sp)
    80002260:	6942                	ld	s2,16(sp)
    80002262:	69a2                	ld	s3,8(sp)
    80002264:	6145                	addi	sp,sp,48
    80002266:	8082                	ret
    panic("sched p->lock");
    80002268:	00006517          	auipc	a0,0x6
    8000226c:	fb050513          	addi	a0,a0,-80 # 80008218 <digits+0x1d8>
    80002270:	ffffe097          	auipc	ra,0xffffe
    80002274:	2d0080e7          	jalr	720(ra) # 80000540 <panic>
    panic("sched locks");
    80002278:	00006517          	auipc	a0,0x6
    8000227c:	fb050513          	addi	a0,a0,-80 # 80008228 <digits+0x1e8>
    80002280:	ffffe097          	auipc	ra,0xffffe
    80002284:	2c0080e7          	jalr	704(ra) # 80000540 <panic>
    panic("sched running");
    80002288:	00006517          	auipc	a0,0x6
    8000228c:	fb050513          	addi	a0,a0,-80 # 80008238 <digits+0x1f8>
    80002290:	ffffe097          	auipc	ra,0xffffe
    80002294:	2b0080e7          	jalr	688(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002298:	00006517          	auipc	a0,0x6
    8000229c:	fb050513          	addi	a0,a0,-80 # 80008248 <digits+0x208>
    800022a0:	ffffe097          	auipc	ra,0xffffe
    800022a4:	2a0080e7          	jalr	672(ra) # 80000540 <panic>

00000000800022a8 <yield>:
{
    800022a8:	1101                	addi	sp,sp,-32
    800022aa:	ec06                	sd	ra,24(sp)
    800022ac:	e822                	sd	s0,16(sp)
    800022ae:	e426                	sd	s1,8(sp)
    800022b0:	e04a                	sd	s2,0(sp)
    800022b2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	766080e7          	jalr	1894(ra) # 80001a1a <myproc>
    800022bc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	928080e7          	jalr	-1752(ra) # 80000be6 <acquire>
  acquire(&tickslock);
    800022c6:	00015517          	auipc	a0,0x15
    800022ca:	62a50513          	addi	a0,a0,1578 # 800178f0 <tickslock>
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	918080e7          	jalr	-1768(ra) # 80000be6 <acquire>
  int diff = ticks - p->last_update_time;
    800022d6:	1804a783          	lw	a5,384(s1)
    800022da:	00007917          	auipc	s2,0x7
    800022de:	d7a92903          	lw	s2,-646(s2) # 80009054 <ticks>
    800022e2:	40f9093b          	subw	s2,s2,a5
  release(&tickslock);
    800022e6:	00015517          	auipc	a0,0x15
    800022ea:	60a50513          	addi	a0,a0,1546 # 800178f0 <tickslock>
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	9ac080e7          	jalr	-1620(ra) # 80000c9a <release>
  if(p->state == RUNNABLE){
    800022f6:	4c9c                	lw	a5,24(s1)
    800022f8:	2781                	sext.w	a5,a5
    800022fa:	470d                	li	a4,3
    800022fc:	02e78d63          	beq	a5,a4,80002336 <yield+0x8e>
  if(p->state == RUNNING){
    80002300:	4c9c                	lw	a5,24(s1)
    80002302:	2781                	sext.w	a5,a5
    80002304:	4711                	li	a4,4
    80002306:	02e78f63          	beq	a5,a4,80002344 <yield+0x9c>
  if(p->state == SLEEPING){
    8000230a:	4c9c                	lw	a5,24(s1)
    8000230c:	2781                	sext.w	a5,a5
    8000230e:	4709                	li	a4,2
    80002310:	04e78163          	beq	a5,a4,80002352 <yield+0xaa>
  p->state = RUNNABLE;
    80002314:	478d                	li	a5,3
    80002316:	cc9c                	sw	a5,24(s1)
  sched();
    80002318:	00000097          	auipc	ra,0x0
    8000231c:	eb8080e7          	jalr	-328(ra) # 800021d0 <sched>
  release(&p->lock);
    80002320:	8526                	mv	a0,s1
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	978080e7          	jalr	-1672(ra) # 80000c9a <release>
}
    8000232a:	60e2                	ld	ra,24(sp)
    8000232c:	6442                	ld	s0,16(sp)
    8000232e:	64a2                	ld	s1,8(sp)
    80002330:	6902                	ld	s2,0(sp)
    80002332:	6105                	addi	sp,sp,32
    80002334:	8082                	ret
    p->runnable_time += diff;
    80002336:	17c4a783          	lw	a5,380(s1)
    8000233a:	012787bb          	addw	a5,a5,s2
    8000233e:	16f4ae23          	sw	a5,380(s1)
    80002342:	bf7d                	j	80002300 <yield+0x58>
    p->running_time += diff;
    80002344:	1784a783          	lw	a5,376(s1)
    80002348:	012787bb          	addw	a5,a5,s2
    8000234c:	16f4ac23          	sw	a5,376(s1)
    80002350:	bf6d                	j	8000230a <yield+0x62>
    p->sleeping_time += diff;
    80002352:	1744a783          	lw	a5,372(s1)
    80002356:	0127893b          	addw	s2,a5,s2
    8000235a:	1724aa23          	sw	s2,372(s1)
    8000235e:	bf5d                	j	80002314 <yield+0x6c>

0000000080002360 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002360:	7179                	addi	sp,sp,-48
    80002362:	f406                	sd	ra,40(sp)
    80002364:	f022                	sd	s0,32(sp)
    80002366:	ec26                	sd	s1,24(sp)
    80002368:	e84a                	sd	s2,16(sp)
    8000236a:	e44e                	sd	s3,8(sp)
    8000236c:	1800                	addi	s0,sp,48
    8000236e:	89aa                	mv	s3,a0
    80002370:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	6a8080e7          	jalr	1704(ra) # 80001a1a <myproc>
    8000237a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	86a080e7          	jalr	-1942(ra) # 80000be6 <acquire>
  release(lk);
    80002384:	854a                	mv	a0,s2
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	914080e7          	jalr	-1772(ra) # 80000c9a <release>

  // Go to sleep.
  p->chan = chan;
    8000238e:	0334b023          	sd	s3,32(s1)

  //calc thicks passed
  acquire(&tickslock);
    80002392:	00015517          	auipc	a0,0x15
    80002396:	55e50513          	addi	a0,a0,1374 # 800178f0 <tickslock>
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	84c080e7          	jalr	-1972(ra) # 80000be6 <acquire>
  int diff = ticks - p->last_update_time;
    800023a2:	1804a783          	lw	a5,384(s1)
    800023a6:	00007997          	auipc	s3,0x7
    800023aa:	cae9a983          	lw	s3,-850(s3) # 80009054 <ticks>
    800023ae:	40f989bb          	subw	s3,s3,a5
  release(&tickslock);
    800023b2:	00015517          	auipc	a0,0x15
    800023b6:	53e50513          	addi	a0,a0,1342 # 800178f0 <tickslock>
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	8e0080e7          	jalr	-1824(ra) # 80000c9a <release>

  if(p->state == RUNNABLE){
    800023c2:	4c9c                	lw	a5,24(s1)
    800023c4:	2781                	sext.w	a5,a5
    800023c6:	470d                	li	a4,3
    800023c8:	04e78563          	beq	a5,a4,80002412 <sleep+0xb2>
    p->runnable_time += diff;
  }
  if(p->state == RUNNING){
    800023cc:	4c9c                	lw	a5,24(s1)
    800023ce:	2781                	sext.w	a5,a5
    800023d0:	4711                	li	a4,4
    800023d2:	04e78763          	beq	a5,a4,80002420 <sleep+0xc0>
    p->running_time += diff;
  }
  if(p->state == SLEEPING){
    800023d6:	4c9c                	lw	a5,24(s1)
    800023d8:	2781                	sext.w	a5,a5
    800023da:	4709                	li	a4,2
    800023dc:	04e78963          	beq	a5,a4,8000242e <sleep+0xce>
    p->sleeping_time += diff;
  }

  p->state = SLEEPING;
    800023e0:	4789                	li	a5,2
    800023e2:	cc9c                	sw	a5,24(s1)

  sched();
    800023e4:	00000097          	auipc	ra,0x0
    800023e8:	dec080e7          	jalr	-532(ra) # 800021d0 <sched>

  // Tidy up.
  p->chan = 0;
    800023ec:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8a8080e7          	jalr	-1880(ra) # 80000c9a <release>
  acquire(lk);
    800023fa:	854a                	mv	a0,s2
    800023fc:	ffffe097          	auipc	ra,0xffffe
    80002400:	7ea080e7          	jalr	2026(ra) # 80000be6 <acquire>
}
    80002404:	70a2                	ld	ra,40(sp)
    80002406:	7402                	ld	s0,32(sp)
    80002408:	64e2                	ld	s1,24(sp)
    8000240a:	6942                	ld	s2,16(sp)
    8000240c:	69a2                	ld	s3,8(sp)
    8000240e:	6145                	addi	sp,sp,48
    80002410:	8082                	ret
    p->runnable_time += diff;
    80002412:	17c4a783          	lw	a5,380(s1)
    80002416:	013787bb          	addw	a5,a5,s3
    8000241a:	16f4ae23          	sw	a5,380(s1)
    8000241e:	b77d                	j	800023cc <sleep+0x6c>
    p->running_time += diff;
    80002420:	1784a783          	lw	a5,376(s1)
    80002424:	013787bb          	addw	a5,a5,s3
    80002428:	16f4ac23          	sw	a5,376(s1)
    8000242c:	b76d                	j	800023d6 <sleep+0x76>
    p->sleeping_time += diff;
    8000242e:	1744a783          	lw	a5,372(s1)
    80002432:	013789bb          	addw	s3,a5,s3
    80002436:	1734aa23          	sw	s3,372(s1)
    8000243a:	b75d                	j	800023e0 <sleep+0x80>

000000008000243c <wait>:
{
    8000243c:	715d                	addi	sp,sp,-80
    8000243e:	e486                	sd	ra,72(sp)
    80002440:	e0a2                	sd	s0,64(sp)
    80002442:	fc26                	sd	s1,56(sp)
    80002444:	f84a                	sd	s2,48(sp)
    80002446:	f44e                	sd	s3,40(sp)
    80002448:	f052                	sd	s4,32(sp)
    8000244a:	ec56                	sd	s5,24(sp)
    8000244c:	e85a                	sd	s6,16(sp)
    8000244e:	e45e                	sd	s7,8(sp)
    80002450:	e062                	sd	s8,0(sp)
    80002452:	0880                	addi	s0,sp,80
    80002454:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	5c4080e7          	jalr	1476(ra) # 80001a1a <myproc>
    8000245e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002460:	0000f517          	auipc	a0,0xf
    80002464:	e7850513          	addi	a0,a0,-392 # 800112d8 <wait_lock>
    80002468:	ffffe097          	auipc	ra,0xffffe
    8000246c:	77e080e7          	jalr	1918(ra) # 80000be6 <acquire>
    havekids = 0;
    80002470:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002472:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002474:	00015997          	auipc	s3,0x15
    80002478:	47c98993          	addi	s3,s3,1148 # 800178f0 <tickslock>
        havekids = 1;
    8000247c:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000247e:	0000fc17          	auipc	s8,0xf
    80002482:	e5ac0c13          	addi	s8,s8,-422 # 800112d8 <wait_lock>
    havekids = 0;
    80002486:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002488:	0000f497          	auipc	s1,0xf
    8000248c:	26848493          	addi	s1,s1,616 # 800116f0 <proc>
    80002490:	a0bd                	j	800024fe <wait+0xc2>
          pid = np->pid;
    80002492:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002496:	000b0e63          	beqz	s6,800024b2 <wait+0x76>
    8000249a:	4691                	li	a3,4
    8000249c:	02c48613          	addi	a2,s1,44
    800024a0:	85da                	mv	a1,s6
    800024a2:	05093503          	ld	a0,80(s2)
    800024a6:	fffff097          	auipc	ra,0xfffff
    800024aa:	1ce080e7          	jalr	462(ra) # 80001674 <copyout>
    800024ae:	02054563          	bltz	a0,800024d8 <wait+0x9c>
          freeproc(np);
    800024b2:	8526                	mv	a0,s1
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	718080e7          	jalr	1816(ra) # 80001bcc <freeproc>
          release(&np->lock);
    800024bc:	8526                	mv	a0,s1
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	7dc080e7          	jalr	2012(ra) # 80000c9a <release>
          release(&wait_lock);
    800024c6:	0000f517          	auipc	a0,0xf
    800024ca:	e1250513          	addi	a0,a0,-494 # 800112d8 <wait_lock>
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	7cc080e7          	jalr	1996(ra) # 80000c9a <release>
          return pid;
    800024d6:	a0ad                	j	80002540 <wait+0x104>
            release(&np->lock);
    800024d8:	8526                	mv	a0,s1
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	7c0080e7          	jalr	1984(ra) # 80000c9a <release>
            release(&wait_lock);
    800024e2:	0000f517          	auipc	a0,0xf
    800024e6:	df650513          	addi	a0,a0,-522 # 800112d8 <wait_lock>
    800024ea:	ffffe097          	auipc	ra,0xffffe
    800024ee:	7b0080e7          	jalr	1968(ra) # 80000c9a <release>
            return -1;
    800024f2:	59fd                	li	s3,-1
    800024f4:	a0b1                	j	80002540 <wait+0x104>
    for(np = proc; np < &proc[NPROC]; np++){
    800024f6:	18848493          	addi	s1,s1,392
    800024fa:	03348563          	beq	s1,s3,80002524 <wait+0xe8>
      if(np->parent == p){
    800024fe:	7c9c                	ld	a5,56(s1)
    80002500:	ff279be3          	bne	a5,s2,800024f6 <wait+0xba>
        acquire(&np->lock);
    80002504:	8526                	mv	a0,s1
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	6e0080e7          	jalr	1760(ra) # 80000be6 <acquire>
        if(np->state == ZOMBIE){
    8000250e:	4c9c                	lw	a5,24(s1)
    80002510:	2781                	sext.w	a5,a5
    80002512:	f94780e3          	beq	a5,s4,80002492 <wait+0x56>
        release(&np->lock);
    80002516:	8526                	mv	a0,s1
    80002518:	ffffe097          	auipc	ra,0xffffe
    8000251c:	782080e7          	jalr	1922(ra) # 80000c9a <release>
        havekids = 1;
    80002520:	8756                	mv	a4,s5
    80002522:	bfd1                	j	800024f6 <wait+0xba>
    if(!havekids || p->killed){
    80002524:	c709                	beqz	a4,8000252e <wait+0xf2>
    80002526:	02892783          	lw	a5,40(s2)
    8000252a:	2781                	sext.w	a5,a5
    8000252c:	c79d                	beqz	a5,8000255a <wait+0x11e>
      release(&wait_lock);
    8000252e:	0000f517          	auipc	a0,0xf
    80002532:	daa50513          	addi	a0,a0,-598 # 800112d8 <wait_lock>
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	764080e7          	jalr	1892(ra) # 80000c9a <release>
      return -1;
    8000253e:	59fd                	li	s3,-1
}
    80002540:	854e                	mv	a0,s3
    80002542:	60a6                	ld	ra,72(sp)
    80002544:	6406                	ld	s0,64(sp)
    80002546:	74e2                	ld	s1,56(sp)
    80002548:	7942                	ld	s2,48(sp)
    8000254a:	79a2                	ld	s3,40(sp)
    8000254c:	7a02                	ld	s4,32(sp)
    8000254e:	6ae2                	ld	s5,24(sp)
    80002550:	6b42                	ld	s6,16(sp)
    80002552:	6ba2                	ld	s7,8(sp)
    80002554:	6c02                	ld	s8,0(sp)
    80002556:	6161                	addi	sp,sp,80
    80002558:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000255a:	85e2                	mv	a1,s8
    8000255c:	854a                	mv	a0,s2
    8000255e:	00000097          	auipc	ra,0x0
    80002562:	e02080e7          	jalr	-510(ra) # 80002360 <sleep>
    havekids = 0;
    80002566:	b705                	j	80002486 <wait+0x4a>

0000000080002568 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002568:	7159                	addi	sp,sp,-112
    8000256a:	f486                	sd	ra,104(sp)
    8000256c:	f0a2                	sd	s0,96(sp)
    8000256e:	eca6                	sd	s1,88(sp)
    80002570:	e8ca                	sd	s2,80(sp)
    80002572:	e4ce                	sd	s3,72(sp)
    80002574:	e0d2                	sd	s4,64(sp)
    80002576:	fc56                	sd	s5,56(sp)
    80002578:	f85a                	sd	s6,48(sp)
    8000257a:	f45e                	sd	s7,40(sp)
    8000257c:	f062                	sd	s8,32(sp)
    8000257e:	ec66                	sd	s9,24(sp)
    80002580:	e86a                	sd	s10,16(sp)
    80002582:	e46e                	sd	s11,8(sp)
    80002584:	1880                	addi	s0,sp,112
    80002586:	8aaa                	mv	s5,a0
  struct proc *p, *mp = myproc();
    80002588:	fffff097          	auipc	ra,0xfffff
    8000258c:	492080e7          	jalr	1170(ra) # 80001a1a <myproc>
    80002590:	892a                	mv	s2,a0

  for(p = proc; p < &proc[NPROC]; p++) {
    80002592:	0000f497          	auipc	s1,0xf
    80002596:	15e48493          	addi	s1,s1,350 # 800116f0 <proc>
    if(p != mp){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000259a:	4a09                	li	s4,2
        //calc thicks passed
        acquire(&tickslock);
    8000259c:	00015b17          	auipc	s6,0x15
    800025a0:	354b0b13          	addi	s6,s6,852 # 800178f0 <tickslock>
        int diff = ticks - p->last_update_time;
    800025a4:	00007d17          	auipc	s10,0x7
    800025a8:	ab0d0d13          	addi	s10,s10,-1360 # 80009054 <ticks>
        release(&tickslock);

        if(p->state == RUNNABLE){
    800025ac:	4c8d                	li	s9,3
          p->runnable_time += diff;
        }
        if(p->state == RUNNING){
    800025ae:	4c11                	li	s8,4
          p->running_time += diff;
        }
        if(p->state == SLEEPING){
          p->sleeping_time += diff;
        }
        p->state = RUNNABLE;
    800025b0:	4b8d                	li	s7,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800025b2:	00015997          	auipc	s3,0x15
    800025b6:	33e98993          	addi	s3,s3,830 # 800178f0 <tickslock>
    800025ba:	a815                	j	800025ee <wakeup+0x86>
          p->runnable_time += diff;
    800025bc:	17c4a783          	lw	a5,380(s1)
    800025c0:	01b787bb          	addw	a5,a5,s11
    800025c4:	16f4ae23          	sw	a5,380(s1)
    800025c8:	a0ad                	j	80002632 <wakeup+0xca>
          p->running_time += diff;
    800025ca:	1784a783          	lw	a5,376(s1)
    800025ce:	01b787bb          	addw	a5,a5,s11
    800025d2:	16f4ac23          	sw	a5,376(s1)
    800025d6:	a095                	j	8000263a <wakeup+0xd2>
        p->state = RUNNABLE;
    800025d8:	0174ac23          	sw	s7,24(s1)
        acquire(&tickslock);
        p->last_runable_time = ticks;
        release(&tickslock);
        #endif
      }
      release(&p->lock);
    800025dc:	8526                	mv	a0,s1
    800025de:	ffffe097          	auipc	ra,0xffffe
    800025e2:	6bc080e7          	jalr	1724(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800025e6:	18848493          	addi	s1,s1,392
    800025ea:	07348363          	beq	s1,s3,80002650 <wakeup+0xe8>
    if(p != mp){
    800025ee:	fe990ce3          	beq	s2,s1,800025e6 <wakeup+0x7e>
      acquire(&p->lock);
    800025f2:	8526                	mv	a0,s1
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	5f2080e7          	jalr	1522(ra) # 80000be6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800025fc:	4c9c                	lw	a5,24(s1)
    800025fe:	2781                	sext.w	a5,a5
    80002600:	fd479ee3          	bne	a5,s4,800025dc <wakeup+0x74>
    80002604:	709c                	ld	a5,32(s1)
    80002606:	fd579be3          	bne	a5,s5,800025dc <wakeup+0x74>
        acquire(&tickslock);
    8000260a:	855a                	mv	a0,s6
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	5da080e7          	jalr	1498(ra) # 80000be6 <acquire>
        int diff = ticks - p->last_update_time;
    80002614:	000d2d83          	lw	s11,0(s10)
    80002618:	1804a783          	lw	a5,384(s1)
    8000261c:	40fd8dbb          	subw	s11,s11,a5
        release(&tickslock);
    80002620:	855a                	mv	a0,s6
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	678080e7          	jalr	1656(ra) # 80000c9a <release>
        if(p->state == RUNNABLE){
    8000262a:	4c9c                	lw	a5,24(s1)
    8000262c:	2781                	sext.w	a5,a5
    8000262e:	f99787e3          	beq	a5,s9,800025bc <wakeup+0x54>
        if(p->state == RUNNING){
    80002632:	4c9c                	lw	a5,24(s1)
    80002634:	2781                	sext.w	a5,a5
    80002636:	f9878ae3          	beq	a5,s8,800025ca <wakeup+0x62>
        if(p->state == SLEEPING){
    8000263a:	4c9c                	lw	a5,24(s1)
    8000263c:	2781                	sext.w	a5,a5
    8000263e:	f9479de3          	bne	a5,s4,800025d8 <wakeup+0x70>
          p->sleeping_time += diff;
    80002642:	1744a783          	lw	a5,372(s1)
    80002646:	01b78dbb          	addw	s11,a5,s11
    8000264a:	17b4aa23          	sw	s11,372(s1)
    8000264e:	b769                	j	800025d8 <wakeup+0x70>
    }
  }
}
    80002650:	70a6                	ld	ra,104(sp)
    80002652:	7406                	ld	s0,96(sp)
    80002654:	64e6                	ld	s1,88(sp)
    80002656:	6946                	ld	s2,80(sp)
    80002658:	69a6                	ld	s3,72(sp)
    8000265a:	6a06                	ld	s4,64(sp)
    8000265c:	7ae2                	ld	s5,56(sp)
    8000265e:	7b42                	ld	s6,48(sp)
    80002660:	7ba2                	ld	s7,40(sp)
    80002662:	7c02                	ld	s8,32(sp)
    80002664:	6ce2                	ld	s9,24(sp)
    80002666:	6d42                	ld	s10,16(sp)
    80002668:	6da2                	ld	s11,8(sp)
    8000266a:	6165                	addi	sp,sp,112
    8000266c:	8082                	ret

000000008000266e <reparent>:
{
    8000266e:	7179                	addi	sp,sp,-48
    80002670:	f406                	sd	ra,40(sp)
    80002672:	f022                	sd	s0,32(sp)
    80002674:	ec26                	sd	s1,24(sp)
    80002676:	e84a                	sd	s2,16(sp)
    80002678:	e44e                	sd	s3,8(sp)
    8000267a:	e052                	sd	s4,0(sp)
    8000267c:	1800                	addi	s0,sp,48
    8000267e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002680:	0000f497          	auipc	s1,0xf
    80002684:	07048493          	addi	s1,s1,112 # 800116f0 <proc>
      pp->parent = initproc;
    80002688:	00007a17          	auipc	s4,0x7
    8000268c:	9a8a0a13          	addi	s4,s4,-1624 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002690:	00015997          	auipc	s3,0x15
    80002694:	26098993          	addi	s3,s3,608 # 800178f0 <tickslock>
    80002698:	a029                	j	800026a2 <reparent+0x34>
    8000269a:	18848493          	addi	s1,s1,392
    8000269e:	01348d63          	beq	s1,s3,800026b8 <reparent+0x4a>
    if(pp->parent == p){
    800026a2:	7c9c                	ld	a5,56(s1)
    800026a4:	ff279be3          	bne	a5,s2,8000269a <reparent+0x2c>
      pp->parent = initproc;
    800026a8:	000a3503          	ld	a0,0(s4)
    800026ac:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800026ae:	00000097          	auipc	ra,0x0
    800026b2:	eba080e7          	jalr	-326(ra) # 80002568 <wakeup>
    800026b6:	b7d5                	j	8000269a <reparent+0x2c>
}
    800026b8:	70a2                	ld	ra,40(sp)
    800026ba:	7402                	ld	s0,32(sp)
    800026bc:	64e2                	ld	s1,24(sp)
    800026be:	6942                	ld	s2,16(sp)
    800026c0:	69a2                	ld	s3,8(sp)
    800026c2:	6a02                	ld	s4,0(sp)
    800026c4:	6145                	addi	sp,sp,48
    800026c6:	8082                	ret

00000000800026c8 <exit>:
{
    800026c8:	7179                	addi	sp,sp,-48
    800026ca:	f406                	sd	ra,40(sp)
    800026cc:	f022                	sd	s0,32(sp)
    800026ce:	ec26                	sd	s1,24(sp)
    800026d0:	e84a                	sd	s2,16(sp)
    800026d2:	e44e                	sd	s3,8(sp)
    800026d4:	e052                	sd	s4,0(sp)
    800026d6:	1800                	addi	s0,sp,48
    800026d8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026da:	fffff097          	auipc	ra,0xfffff
    800026de:	340080e7          	jalr	832(ra) # 80001a1a <myproc>
    800026e2:	892a                	mv	s2,a0
  if(p == initproc)
    800026e4:	00007797          	auipc	a5,0x7
    800026e8:	94c7b783          	ld	a5,-1716(a5) # 80009030 <initproc>
    800026ec:	0d050493          	addi	s1,a0,208
    800026f0:	15050993          	addi	s3,a0,336
    800026f4:	02a79363          	bne	a5,a0,8000271a <exit+0x52>
    panic("init exiting");
    800026f8:	00006517          	auipc	a0,0x6
    800026fc:	b6850513          	addi	a0,a0,-1176 # 80008260 <digits+0x220>
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	e40080e7          	jalr	-448(ra) # 80000540 <panic>
      fileclose(f);
    80002708:	00002097          	auipc	ra,0x2
    8000270c:	5e0080e7          	jalr	1504(ra) # 80004ce8 <fileclose>
      p->ofile[fd] = 0;
    80002710:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002714:	04a1                	addi	s1,s1,8
    80002716:	01348563          	beq	s1,s3,80002720 <exit+0x58>
    if(p->ofile[fd]){
    8000271a:	6088                	ld	a0,0(s1)
    8000271c:	f575                	bnez	a0,80002708 <exit+0x40>
    8000271e:	bfdd                	j	80002714 <exit+0x4c>
  begin_op();
    80002720:	00002097          	auipc	ra,0x2
    80002724:	0fc080e7          	jalr	252(ra) # 8000481c <begin_op>
  iput(p->cwd);
    80002728:	15093503          	ld	a0,336(s2)
    8000272c:	00002097          	auipc	ra,0x2
    80002730:	8d8080e7          	jalr	-1832(ra) # 80004004 <iput>
  end_op();
    80002734:	00002097          	auipc	ra,0x2
    80002738:	168080e7          	jalr	360(ra) # 8000489c <end_op>
  p->cwd = 0;
    8000273c:	14093823          	sd	zero,336(s2)
  acquire(&wait_lock);
    80002740:	0000f517          	auipc	a0,0xf
    80002744:	b9850513          	addi	a0,a0,-1128 # 800112d8 <wait_lock>
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	49e080e7          	jalr	1182(ra) # 80000be6 <acquire>
  reparent(p);
    80002750:	854a                	mv	a0,s2
    80002752:	00000097          	auipc	ra,0x0
    80002756:	f1c080e7          	jalr	-228(ra) # 8000266e <reparent>
  wakeup(p->parent);
    8000275a:	03893503          	ld	a0,56(s2)
    8000275e:	00000097          	auipc	ra,0x0
    80002762:	e0a080e7          	jalr	-502(ra) # 80002568 <wakeup>
  acquire(&p->lock);
    80002766:	854a                	mv	a0,s2
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	47e080e7          	jalr	1150(ra) # 80000be6 <acquire>
  p->xstate = status;
    80002770:	03492623          	sw	s4,44(s2)
  acquire(&tickslock);
    80002774:	00015517          	auipc	a0,0x15
    80002778:	17c50513          	addi	a0,a0,380 # 800178f0 <tickslock>
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	46a080e7          	jalr	1130(ra) # 80000be6 <acquire>
  int diff = ticks - p->last_update_time;
    80002784:	18092783          	lw	a5,384(s2)
    80002788:	00007497          	auipc	s1,0x7
    8000278c:	8cc4a483          	lw	s1,-1844(s1) # 80009054 <ticks>
    80002790:	9c9d                	subw	s1,s1,a5
  release(&tickslock);
    80002792:	00015517          	auipc	a0,0x15
    80002796:	15e50513          	addi	a0,a0,350 # 800178f0 <tickslock>
    8000279a:	ffffe097          	auipc	ra,0xffffe
    8000279e:	500080e7          	jalr	1280(ra) # 80000c9a <release>
  if(p->state == RUNNABLE){
    800027a2:	01892783          	lw	a5,24(s2)
    800027a6:	2781                	sext.w	a5,a5
    800027a8:	470d                	li	a4,3
    800027aa:	0ee78a63          	beq	a5,a4,8000289e <exit+0x1d6>
  if(p->state == RUNNING){
    800027ae:	01892783          	lw	a5,24(s2)
    800027b2:	2781                	sext.w	a5,a5
    800027b4:	4711                	li	a4,4
    800027b6:	0ee78a63          	beq	a5,a4,800028aa <exit+0x1e2>
  if(p->state == SLEEPING){
    800027ba:	01892783          	lw	a5,24(s2)
    800027be:	2781                	sext.w	a5,a5
    800027c0:	4709                	li	a4,2
    800027c2:	0ee78a63          	beq	a5,a4,800028b6 <exit+0x1ee>
  p->state = ZOMBIE;
    800027c6:	4795                	li	a5,5
    800027c8:	00f92c23          	sw	a5,24(s2)
  running_processes_mean = ((running_processes_mean * (process_count - 1)) + p->running_time) / process_count;
    800027cc:	00007697          	auipc	a3,0x7
    800027d0:	8786a683          	lw	a3,-1928(a3) # 80009044 <process_count>
    800027d4:	fff6861b          	addiw	a2,a3,-1
    800027d8:	17892583          	lw	a1,376(s2)
    800027dc:	00007797          	auipc	a5,0x7
    800027e0:	87078793          	addi	a5,a5,-1936 # 8000904c <running_processes_mean>
    800027e4:	4398                	lw	a4,0(a5)
    800027e6:	02c7073b          	mulw	a4,a4,a2
    800027ea:	9f2d                	addw	a4,a4,a1
    800027ec:	02d7573b          	divuw	a4,a4,a3
    800027f0:	c398                	sw	a4,0(a5)
  runnable_processes_mean = ((runnable_processes_mean * (process_count - 1)) + p->runnable_time) / process_count;
    800027f2:	00007797          	auipc	a5,0x7
    800027f6:	85678793          	addi	a5,a5,-1962 # 80009048 <runnable_processes_mean>
    800027fa:	4398                	lw	a4,0(a5)
    800027fc:	02c7073b          	mulw	a4,a4,a2
    80002800:	17c92503          	lw	a0,380(s2)
    80002804:	9f29                	addw	a4,a4,a0
    80002806:	02d7573b          	divuw	a4,a4,a3
    8000280a:	c398                	sw	a4,0(a5)
  sleeping_processes_mean = ((sleeping_processes_mean * (process_count - 1)) + p->sleeping_time) / process_count;
    8000280c:	00007717          	auipc	a4,0x7
    80002810:	84470713          	addi	a4,a4,-1980 # 80009050 <sleeping_processes_mean>
    80002814:	431c                	lw	a5,0(a4)
    80002816:	02c787bb          	mulw	a5,a5,a2
    8000281a:	17492603          	lw	a2,372(s2)
    8000281e:	9fb1                	addw	a5,a5,a2
    80002820:	02d7d7bb          	divuw	a5,a5,a3
    80002824:	c31c                	sw	a5,0(a4)
  program_time += p->running_time;
    80002826:	00007497          	auipc	s1,0x7
    8000282a:	81a48493          	addi	s1,s1,-2022 # 80009040 <program_time>
    8000282e:	409c                	lw	a5,0(s1)
    80002830:	9fad                	addw	a5,a5,a1
    80002832:	c09c                	sw	a5,0(s1)
  acquire(&tickslock);
    80002834:	00015517          	auipc	a0,0x15
    80002838:	0bc50513          	addi	a0,a0,188 # 800178f0 <tickslock>
    8000283c:	ffffe097          	auipc	ra,0xffffe
    80002840:	3aa080e7          	jalr	938(ra) # 80000be6 <acquire>
  cpu_utilization = program_time / (ticks - start_time);
    80002844:	00007797          	auipc	a5,0x7
    80002848:	8107a783          	lw	a5,-2032(a5) # 80009054 <ticks>
    8000284c:	00006717          	auipc	a4,0x6
    80002850:	7ec72703          	lw	a4,2028(a4) # 80009038 <start_time>
    80002854:	40e7873b          	subw	a4,a5,a4
    80002858:	409c                	lw	a5,0(s1)
    8000285a:	02e7d7bb          	divuw	a5,a5,a4
    8000285e:	00006717          	auipc	a4,0x6
    80002862:	7cf72f23          	sw	a5,2014(a4) # 8000903c <cpu_utilization>
  release(&tickslock);
    80002866:	00015517          	auipc	a0,0x15
    8000286a:	08a50513          	addi	a0,a0,138 # 800178f0 <tickslock>
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	42c080e7          	jalr	1068(ra) # 80000c9a <release>
  release(&wait_lock);
    80002876:	0000f517          	auipc	a0,0xf
    8000287a:	a6250513          	addi	a0,a0,-1438 # 800112d8 <wait_lock>
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	41c080e7          	jalr	1052(ra) # 80000c9a <release>
  sched();
    80002886:	00000097          	auipc	ra,0x0
    8000288a:	94a080e7          	jalr	-1718(ra) # 800021d0 <sched>
  panic("zombie exit");
    8000288e:	00006517          	auipc	a0,0x6
    80002892:	9e250513          	addi	a0,a0,-1566 # 80008270 <digits+0x230>
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	caa080e7          	jalr	-854(ra) # 80000540 <panic>
    p->runnable_time += diff;
    8000289e:	17c92783          	lw	a5,380(s2)
    800028a2:	9fa5                	addw	a5,a5,s1
    800028a4:	16f92e23          	sw	a5,380(s2)
    800028a8:	b719                	j	800027ae <exit+0xe6>
    p->running_time += diff;
    800028aa:	17892783          	lw	a5,376(s2)
    800028ae:	9fa5                	addw	a5,a5,s1
    800028b0:	16f92c23          	sw	a5,376(s2)
    800028b4:	b719                	j	800027ba <exit+0xf2>
    p->sleeping_time += diff;
    800028b6:	17492783          	lw	a5,372(s2)
    800028ba:	9cbd                	addw	s1,s1,a5
    800028bc:	16992a23          	sw	s1,372(s2)
    800028c0:	b719                	j	800027c6 <exit+0xfe>

00000000800028c2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800028c2:	7179                	addi	sp,sp,-48
    800028c4:	f406                	sd	ra,40(sp)
    800028c6:	f022                	sd	s0,32(sp)
    800028c8:	ec26                	sd	s1,24(sp)
    800028ca:	e84a                	sd	s2,16(sp)
    800028cc:	e44e                	sd	s3,8(sp)
    800028ce:	1800                	addi	s0,sp,48
    800028d0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800028d2:	0000f497          	auipc	s1,0xf
    800028d6:	e1e48493          	addi	s1,s1,-482 # 800116f0 <proc>
    800028da:	00015997          	auipc	s3,0x15
    800028de:	01698993          	addi	s3,s3,22 # 800178f0 <tickslock>
    acquire(&p->lock);
    800028e2:	8526                	mv	a0,s1
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	302080e7          	jalr	770(ra) # 80000be6 <acquire>
    if(p->pid == pid){
    800028ec:	589c                	lw	a5,48(s1)
    800028ee:	01278d63          	beq	a5,s2,80002908 <kill+0x46>
        #endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800028f2:	8526                	mv	a0,s1
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	3a6080e7          	jalr	934(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800028fc:	18848493          	addi	s1,s1,392
    80002900:	ff3491e3          	bne	s1,s3,800028e2 <kill+0x20>
  }
  return -1;
    80002904:	557d                	li	a0,-1
    80002906:	a831                	j	80002922 <kill+0x60>
      p->killed = 1;
    80002908:	4785                	li	a5,1
    8000290a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000290c:	4c9c                	lw	a5,24(s1)
    8000290e:	2781                	sext.w	a5,a5
    80002910:	4709                	li	a4,2
    80002912:	00e78f63          	beq	a5,a4,80002930 <kill+0x6e>
      release(&p->lock);
    80002916:	8526                	mv	a0,s1
    80002918:	ffffe097          	auipc	ra,0xffffe
    8000291c:	382080e7          	jalr	898(ra) # 80000c9a <release>
      return 0;
    80002920:	4501                	li	a0,0
}
    80002922:	70a2                	ld	ra,40(sp)
    80002924:	7402                	ld	s0,32(sp)
    80002926:	64e2                	ld	s1,24(sp)
    80002928:	6942                	ld	s2,16(sp)
    8000292a:	69a2                	ld	s3,8(sp)
    8000292c:	6145                	addi	sp,sp,48
    8000292e:	8082                	ret
        acquire(&tickslock);
    80002930:	00015517          	auipc	a0,0x15
    80002934:	fc050513          	addi	a0,a0,-64 # 800178f0 <tickslock>
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	2ae080e7          	jalr	686(ra) # 80000be6 <acquire>
        int diff = ticks - p->last_update_time;
    80002940:	1804a783          	lw	a5,384(s1)
    80002944:	00006717          	auipc	a4,0x6
    80002948:	71072703          	lw	a4,1808(a4) # 80009054 <ticks>
    8000294c:	40f7093b          	subw	s2,a4,a5
        release(&tickslock);
    80002950:	00015517          	auipc	a0,0x15
    80002954:	fa050513          	addi	a0,a0,-96 # 800178f0 <tickslock>
    80002958:	ffffe097          	auipc	ra,0xffffe
    8000295c:	342080e7          	jalr	834(ra) # 80000c9a <release>
        if(p->state == RUNNABLE){
    80002960:	4c9c                	lw	a5,24(s1)
    80002962:	2781                	sext.w	a5,a5
    80002964:	470d                	li	a4,3
    80002966:	00e78f63          	beq	a5,a4,80002984 <kill+0xc2>
        if(p->state == RUNNING){
    8000296a:	4c9c                	lw	a5,24(s1)
    8000296c:	2781                	sext.w	a5,a5
    8000296e:	4711                	li	a4,4
    80002970:	02e78163          	beq	a5,a4,80002992 <kill+0xd0>
        if(p->state == SLEEPING){
    80002974:	4c9c                	lw	a5,24(s1)
    80002976:	2781                	sext.w	a5,a5
    80002978:	4709                	li	a4,2
    8000297a:	02e78363          	beq	a5,a4,800029a0 <kill+0xde>
        p->state = RUNNABLE;
    8000297e:	478d                	li	a5,3
    80002980:	cc9c                	sw	a5,24(s1)
    80002982:	bf51                	j	80002916 <kill+0x54>
          p->runnable_time += diff;
    80002984:	17c4a783          	lw	a5,380(s1)
    80002988:	012787bb          	addw	a5,a5,s2
    8000298c:	16f4ae23          	sw	a5,380(s1)
    80002990:	bfe9                	j	8000296a <kill+0xa8>
          p->running_time += diff;
    80002992:	1784a783          	lw	a5,376(s1)
    80002996:	012787bb          	addw	a5,a5,s2
    8000299a:	16f4ac23          	sw	a5,376(s1)
    8000299e:	bfd9                	j	80002974 <kill+0xb2>
          p->sleeping_time += diff;
    800029a0:	1744a783          	lw	a5,372(s1)
    800029a4:	012787bb          	addw	a5,a5,s2
    800029a8:	16f4aa23          	sw	a5,372(s1)
    800029ac:	bfc9                	j	8000297e <kill+0xbc>

00000000800029ae <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029ae:	7179                	addi	sp,sp,-48
    800029b0:	f406                	sd	ra,40(sp)
    800029b2:	f022                	sd	s0,32(sp)
    800029b4:	ec26                	sd	s1,24(sp)
    800029b6:	e84a                	sd	s2,16(sp)
    800029b8:	e44e                	sd	s3,8(sp)
    800029ba:	e052                	sd	s4,0(sp)
    800029bc:	1800                	addi	s0,sp,48
    800029be:	84aa                	mv	s1,a0
    800029c0:	892e                	mv	s2,a1
    800029c2:	89b2                	mv	s3,a2
    800029c4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029c6:	fffff097          	auipc	ra,0xfffff
    800029ca:	054080e7          	jalr	84(ra) # 80001a1a <myproc>
  if(user_dst){
    800029ce:	c08d                	beqz	s1,800029f0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800029d0:	86d2                	mv	a3,s4
    800029d2:	864e                	mv	a2,s3
    800029d4:	85ca                	mv	a1,s2
    800029d6:	6928                	ld	a0,80(a0)
    800029d8:	fffff097          	auipc	ra,0xfffff
    800029dc:	c9c080e7          	jalr	-868(ra) # 80001674 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029e0:	70a2                	ld	ra,40(sp)
    800029e2:	7402                	ld	s0,32(sp)
    800029e4:	64e2                	ld	s1,24(sp)
    800029e6:	6942                	ld	s2,16(sp)
    800029e8:	69a2                	ld	s3,8(sp)
    800029ea:	6a02                	ld	s4,0(sp)
    800029ec:	6145                	addi	sp,sp,48
    800029ee:	8082                	ret
    memmove((char *)dst, src, len);
    800029f0:	000a061b          	sext.w	a2,s4
    800029f4:	85ce                	mv	a1,s3
    800029f6:	854a                	mv	a0,s2
    800029f8:	ffffe097          	auipc	ra,0xffffe
    800029fc:	34a080e7          	jalr	842(ra) # 80000d42 <memmove>
    return 0;
    80002a00:	8526                	mv	a0,s1
    80002a02:	bff9                	j	800029e0 <either_copyout+0x32>

0000000080002a04 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a04:	7179                	addi	sp,sp,-48
    80002a06:	f406                	sd	ra,40(sp)
    80002a08:	f022                	sd	s0,32(sp)
    80002a0a:	ec26                	sd	s1,24(sp)
    80002a0c:	e84a                	sd	s2,16(sp)
    80002a0e:	e44e                	sd	s3,8(sp)
    80002a10:	e052                	sd	s4,0(sp)
    80002a12:	1800                	addi	s0,sp,48
    80002a14:	892a                	mv	s2,a0
    80002a16:	84ae                	mv	s1,a1
    80002a18:	89b2                	mv	s3,a2
    80002a1a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a1c:	fffff097          	auipc	ra,0xfffff
    80002a20:	ffe080e7          	jalr	-2(ra) # 80001a1a <myproc>
  if(user_src){
    80002a24:	c08d                	beqz	s1,80002a46 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002a26:	86d2                	mv	a3,s4
    80002a28:	864e                	mv	a2,s3
    80002a2a:	85ca                	mv	a1,s2
    80002a2c:	6928                	ld	a0,80(a0)
    80002a2e:	fffff097          	auipc	ra,0xfffff
    80002a32:	cd2080e7          	jalr	-814(ra) # 80001700 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002a36:	70a2                	ld	ra,40(sp)
    80002a38:	7402                	ld	s0,32(sp)
    80002a3a:	64e2                	ld	s1,24(sp)
    80002a3c:	6942                	ld	s2,16(sp)
    80002a3e:	69a2                	ld	s3,8(sp)
    80002a40:	6a02                	ld	s4,0(sp)
    80002a42:	6145                	addi	sp,sp,48
    80002a44:	8082                	ret
    memmove(dst, (char*)src, len);
    80002a46:	000a061b          	sext.w	a2,s4
    80002a4a:	85ce                	mv	a1,s3
    80002a4c:	854a                	mv	a0,s2
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	2f4080e7          	jalr	756(ra) # 80000d42 <memmove>
    return 0;
    80002a56:	8526                	mv	a0,s1
    80002a58:	bff9                	j	80002a36 <either_copyin+0x32>

0000000080002a5a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002a5a:	715d                	addi	sp,sp,-80
    80002a5c:	e486                	sd	ra,72(sp)
    80002a5e:	e0a2                	sd	s0,64(sp)
    80002a60:	fc26                	sd	s1,56(sp)
    80002a62:	f84a                	sd	s2,48(sp)
    80002a64:	f44e                	sd	s3,40(sp)
    80002a66:	f052                	sd	s4,32(sp)
    80002a68:	ec56                	sd	s5,24(sp)
    80002a6a:	e85a                	sd	s6,16(sp)
    80002a6c:	e45e                	sd	s7,8(sp)
    80002a6e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002a70:	00006517          	auipc	a0,0x6
    80002a74:	93850513          	addi	a0,a0,-1736 # 800083a8 <digits+0x368>
    80002a78:	ffffe097          	auipc	ra,0xffffe
    80002a7c:	b12080e7          	jalr	-1262(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a80:	0000f497          	auipc	s1,0xf
    80002a84:	c7048493          	addi	s1,s1,-912 # 800116f0 <proc>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a88:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002a8a:	00005917          	auipc	s2,0x5
    80002a8e:	7f690913          	addi	s2,s2,2038 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002a92:	00005a97          	auipc	s5,0x5
    80002a96:	7f6a8a93          	addi	s5,s5,2038 # 80008288 <digits+0x248>
    printf("\n");
    80002a9a:	00006a17          	auipc	s4,0x6
    80002a9e:	90ea0a13          	addi	s4,s4,-1778 # 800083a8 <digits+0x368>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aa2:	00006b97          	auipc	s7,0x6
    80002aa6:	94eb8b93          	addi	s7,s7,-1714 # 800083f0 <states.1747>
  for(p = proc; p < &proc[NPROC]; p++){
    80002aaa:	00015997          	auipc	s3,0x15
    80002aae:	e4698993          	addi	s3,s3,-442 # 800178f0 <tickslock>
    80002ab2:	a015                	j	80002ad6 <procdump+0x7c>
    printf("%d %s %s", p->pid, state, p->name);
    80002ab4:	15848693          	addi	a3,s1,344
    80002ab8:	588c                	lw	a1,48(s1)
    80002aba:	8556                	mv	a0,s5
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	ace080e7          	jalr	-1330(ra) # 8000058a <printf>
    printf("\n");
    80002ac4:	8552                	mv	a0,s4
    80002ac6:	ffffe097          	auipc	ra,0xffffe
    80002aca:	ac4080e7          	jalr	-1340(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002ace:	18848493          	addi	s1,s1,392
    80002ad2:	03348963          	beq	s1,s3,80002b04 <procdump+0xaa>
    if(p->state == UNUSED)
    80002ad6:	4c9c                	lw	a5,24(s1)
    80002ad8:	2781                	sext.w	a5,a5
    80002ada:	dbf5                	beqz	a5,80002ace <procdump+0x74>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002adc:	4c9c                	lw	a5,24(s1)
    80002ade:	4c9c                	lw	a5,24(s1)
    80002ae0:	2781                	sext.w	a5,a5
      state = "???";
    80002ae2:	864a                	mv	a2,s2
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ae4:	fcfb68e3          	bltu	s6,a5,80002ab4 <procdump+0x5a>
    80002ae8:	4c9c                	lw	a5,24(s1)
    80002aea:	1782                	slli	a5,a5,0x20
    80002aec:	9381                	srli	a5,a5,0x20
    80002aee:	078e                	slli	a5,a5,0x3
    80002af0:	97de                	add	a5,a5,s7
    80002af2:	639c                	ld	a5,0(a5)
    80002af4:	d3e1                	beqz	a5,80002ab4 <procdump+0x5a>
      state = states[p->state];
    80002af6:	4c9c                	lw	a5,24(s1)
    80002af8:	1782                	slli	a5,a5,0x20
    80002afa:	9381                	srli	a5,a5,0x20
    80002afc:	078e                	slli	a5,a5,0x3
    80002afe:	97de                	add	a5,a5,s7
    80002b00:	6390                	ld	a2,0(a5)
    80002b02:	bf4d                	j	80002ab4 <procdump+0x5a>
  }
}
    80002b04:	60a6                	ld	ra,72(sp)
    80002b06:	6406                	ld	s0,64(sp)
    80002b08:	74e2                	ld	s1,56(sp)
    80002b0a:	7942                	ld	s2,48(sp)
    80002b0c:	79a2                	ld	s3,40(sp)
    80002b0e:	7a02                	ld	s4,32(sp)
    80002b10:	6ae2                	ld	s5,24(sp)
    80002b12:	6b42                	ld	s6,16(sp)
    80002b14:	6ba2                	ld	s7,8(sp)
    80002b16:	6161                	addi	sp,sp,80
    80002b18:	8082                	ret

0000000080002b1a <pause_system>:

int
pause_system(const int seconds)
{
    80002b1a:	1101                	addi	sp,sp,-32
    80002b1c:	ec06                	sd	ra,24(sp)
    80002b1e:	e822                	sd	s0,16(sp)
    80002b20:	e426                	sd	s1,8(sp)
    80002b22:	e04a                	sd	s2,0(sp)
    80002b24:	1000                	addi	s0,sp,32
    80002b26:	892a                	mv	s2,a0
  while(paused)
    80002b28:	00006797          	auipc	a5,0x6
    80002b2c:	5047a783          	lw	a5,1284(a5) # 8000902c <paused>
    80002b30:	cf81                	beqz	a5,80002b48 <pause_system+0x2e>
    80002b32:	00006497          	auipc	s1,0x6
    80002b36:	4fa48493          	addi	s1,s1,1274 # 8000902c <paused>
    yield();
    80002b3a:	fffff097          	auipc	ra,0xfffff
    80002b3e:	76e080e7          	jalr	1902(ra) # 800022a8 <yield>
  while(paused)
    80002b42:	409c                	lw	a5,0(s1)
    80002b44:	2781                	sext.w	a5,a5
    80002b46:	fbf5                	bnez	a5,80002b3a <pause_system+0x20>

  // print for debug
  struct proc* p = myproc();
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	ed2080e7          	jalr	-302(ra) # 80001a1a <myproc>
  if(p->killed)
    80002b50:	5504                	lw	s1,40(a0)
    80002b52:	2481                	sext.w	s1,s1
    80002b54:	e0c1                	bnez	s1,80002bd4 <pause_system+0xba>
  {
    printf("Pronc: %s, number: %d died during pause_sytem execution\n", p->name, p->pid);
    return -1;  
  }

  printf("Proc: %s, number: %d pause system\n", p->name, p->pid);
    80002b56:	5910                	lw	a2,48(a0)
    80002b58:	15850593          	addi	a1,a0,344
    80002b5c:	00005517          	auipc	a0,0x5
    80002b60:	77c50513          	addi	a0,a0,1916 # 800082d8 <digits+0x298>
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	a26080e7          	jalr	-1498(ra) # 8000058a <printf>

  paused |= 1;
    80002b6c:	00006797          	auipc	a5,0x6
    80002b70:	4c07a783          	lw	a5,1216(a5) # 8000902c <paused>
    80002b74:	0017e793          	ori	a5,a5,1
    80002b78:	00006717          	auipc	a4,0x6
    80002b7c:	4af72a23          	sw	a5,1204(a4) # 8000902c <paused>
  acquire(&tickslock);
    80002b80:	00015517          	auipc	a0,0x15
    80002b84:	d7050513          	addi	a0,a0,-656 # 800178f0 <tickslock>
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	05e080e7          	jalr	94(ra) # 80000be6 <acquire>
  pause_interval = ticks + (seconds * 10);
    80002b90:	0029179b          	slliw	a5,s2,0x2
    80002b94:	012787bb          	addw	a5,a5,s2
    80002b98:	0017979b          	slliw	a5,a5,0x1
    80002b9c:	00006717          	auipc	a4,0x6
    80002ba0:	4b872703          	lw	a4,1208(a4) # 80009054 <ticks>
    80002ba4:	9fb9                	addw	a5,a5,a4
    80002ba6:	00006717          	auipc	a4,0x6
    80002baa:	48f72123          	sw	a5,1154(a4) # 80009028 <pause_interval>
  release(&tickslock);
    80002bae:	00015517          	auipc	a0,0x15
    80002bb2:	d4250513          	addi	a0,a0,-702 # 800178f0 <tickslock>
    80002bb6:	ffffe097          	auipc	ra,0xffffe
    80002bba:	0e4080e7          	jalr	228(ra) # 80000c9a <release>

  yield();
    80002bbe:	fffff097          	auipc	ra,0xfffff
    80002bc2:	6ea080e7          	jalr	1770(ra) # 800022a8 <yield>
  return 0;
}
    80002bc6:	8526                	mv	a0,s1
    80002bc8:	60e2                	ld	ra,24(sp)
    80002bca:	6442                	ld	s0,16(sp)
    80002bcc:	64a2                	ld	s1,8(sp)
    80002bce:	6902                	ld	s2,0(sp)
    80002bd0:	6105                	addi	sp,sp,32
    80002bd2:	8082                	ret
    printf("Pronc: %s, number: %d died during pause_sytem execution\n", p->name, p->pid);
    80002bd4:	5910                	lw	a2,48(a0)
    80002bd6:	15850593          	addi	a1,a0,344
    80002bda:	00005517          	auipc	a0,0x5
    80002bde:	6be50513          	addi	a0,a0,1726 # 80008298 <digits+0x258>
    80002be2:	ffffe097          	auipc	ra,0xffffe
    80002be6:	9a8080e7          	jalr	-1624(ra) # 8000058a <printf>
    return -1;  
    80002bea:	54fd                	li	s1,-1
    80002bec:	bfe9                	j	80002bc6 <pause_system+0xac>

0000000080002bee <kill_system>:

#define INIT_SH_PROC 2
int 
kill_system(void)
{
    80002bee:	7159                	addi	sp,sp,-112
    80002bf0:	f486                	sd	ra,104(sp)
    80002bf2:	f0a2                	sd	s0,96(sp)
    80002bf4:	eca6                	sd	s1,88(sp)
    80002bf6:	e8ca                	sd	s2,80(sp)
    80002bf8:	e4ce                	sd	s3,72(sp)
    80002bfa:	e0d2                	sd	s4,64(sp)
    80002bfc:	fc56                	sd	s5,56(sp)
    80002bfe:	f85a                	sd	s6,48(sp)
    80002c00:	f45e                	sd	s7,40(sp)
    80002c02:	f062                	sd	s8,32(sp)
    80002c04:	ec66                	sd	s9,24(sp)
    80002c06:	e86a                	sd	s10,16(sp)
    80002c08:	e46e                	sd	s11,8(sp)
    80002c0a:	1880                	addi	s0,sp,112

  struct proc* p;
  // Below parameters are used for debug.
  struct proc* mp = myproc();
    80002c0c:	fffff097          	auipc	ra,0xfffff
    80002c10:	e0e080e7          	jalr	-498(ra) # 80001a1a <myproc>
  int pid = mp->pid;
    80002c14:	03052b83          	lw	s7,48(a0)
  const char* name = mp->name;
    80002c18:	15850a93          	addi	s5,a0,344


  /* 
  * Set killed flag for all process besides init & sh.
  */
  for(p = proc; p < &proc[NPROC]; p++)
    80002c1c:	0000f497          	auipc	s1,0xf
    80002c20:	ad448493          	addi	s1,s1,-1324 # 800116f0 <proc>
  {
      acquire(&p->lock);
      if(p->pid > INIT_SH_PROC && p->state && !p->killed)
    80002c24:	4909                	li	s2,2
      {
        printf("Proc: %s number: %d KILL proc: %s number: %d\n",name, pid, p->name, p->pid);
    80002c26:	00005b17          	auipc	s6,0x5
    80002c2a:	6dab0b13          	addi	s6,s6,1754 # 80008300 <digits+0x2c0>
        p->killed |= 1;
        if(p->state == SLEEPING){
          //calc thicks passed
          //calc thicks passed
          acquire(&tickslock);
    80002c2e:	00015c17          	auipc	s8,0x15
    80002c32:	cc2c0c13          	addi	s8,s8,-830 # 800178f0 <tickslock>
          int diff = ticks - p->last_update_time;
    80002c36:	00006d17          	auipc	s10,0x6
    80002c3a:	41ed0d13          	addi	s10,s10,1054 # 80009054 <ticks>
          release(&tickslock);
          p->sleeping_time += diff;
          //update means...
          p->state = RUNNABLE;
    80002c3e:	4c8d                	li	s9,3
  for(p = proc; p < &proc[NPROC]; p++)
    80002c40:	00015a17          	auipc	s4,0x15
    80002c44:	cb0a0a13          	addi	s4,s4,-848 # 800178f0 <tickslock>
    80002c48:	a811                	j	80002c5c <kill_system+0x6e>
        }
      }
      release(&p->lock);
    80002c4a:	8526                	mv	a0,s1
    80002c4c:	ffffe097          	auipc	ra,0xffffe
    80002c50:	04e080e7          	jalr	78(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++)
    80002c54:	18848493          	addi	s1,s1,392
    80002c58:	07448b63          	beq	s1,s4,80002cce <kill_system+0xe0>
      acquire(&p->lock);
    80002c5c:	8526                	mv	a0,s1
    80002c5e:	ffffe097          	auipc	ra,0xffffe
    80002c62:	f88080e7          	jalr	-120(ra) # 80000be6 <acquire>
      if(p->pid > INIT_SH_PROC && p->state && !p->killed)
    80002c66:	5898                	lw	a4,48(s1)
    80002c68:	fee951e3          	bge	s2,a4,80002c4a <kill_system+0x5c>
    80002c6c:	4c9c                	lw	a5,24(s1)
    80002c6e:	2781                	sext.w	a5,a5
    80002c70:	dfe9                	beqz	a5,80002c4a <kill_system+0x5c>
    80002c72:	549c                	lw	a5,40(s1)
    80002c74:	2781                	sext.w	a5,a5
    80002c76:	fbf1                	bnez	a5,80002c4a <kill_system+0x5c>
        printf("Proc: %s number: %d KILL proc: %s number: %d\n",name, pid, p->name, p->pid);
    80002c78:	15848693          	addi	a3,s1,344
    80002c7c:	865e                	mv	a2,s7
    80002c7e:	85d6                	mv	a1,s5
    80002c80:	855a                	mv	a0,s6
    80002c82:	ffffe097          	auipc	ra,0xffffe
    80002c86:	908080e7          	jalr	-1784(ra) # 8000058a <printf>
        p->killed |= 1;
    80002c8a:	549c                	lw	a5,40(s1)
    80002c8c:	2781                	sext.w	a5,a5
    80002c8e:	0017e793          	ori	a5,a5,1
    80002c92:	d49c                	sw	a5,40(s1)
        if(p->state == SLEEPING){
    80002c94:	4c9c                	lw	a5,24(s1)
    80002c96:	2781                	sext.w	a5,a5
    80002c98:	fb2799e3          	bne	a5,s2,80002c4a <kill_system+0x5c>
          acquire(&tickslock);
    80002c9c:	8562                	mv	a0,s8
    80002c9e:	ffffe097          	auipc	ra,0xffffe
    80002ca2:	f48080e7          	jalr	-184(ra) # 80000be6 <acquire>
          int diff = ticks - p->last_update_time;
    80002ca6:	000d2d83          	lw	s11,0(s10)
    80002caa:	1804a983          	lw	s3,384(s1)
          release(&tickslock);
    80002cae:	8562                	mv	a0,s8
    80002cb0:	ffffe097          	auipc	ra,0xffffe
    80002cb4:	fea080e7          	jalr	-22(ra) # 80000c9a <release>
          p->sleeping_time += diff;
    80002cb8:	1744a783          	lw	a5,372(s1)
    80002cbc:	01b787bb          	addw	a5,a5,s11
    80002cc0:	413787bb          	subw	a5,a5,s3
    80002cc4:	16f4aa23          	sw	a5,372(s1)
          p->state = RUNNABLE;
    80002cc8:	0194ac23          	sw	s9,24(s1)
    80002ccc:	bfbd                	j	80002c4a <kill_system+0x5c>
  }
  return 0;
} 
    80002cce:	4501                	li	a0,0
    80002cd0:	70a6                	ld	ra,104(sp)
    80002cd2:	7406                	ld	s0,96(sp)
    80002cd4:	64e6                	ld	s1,88(sp)
    80002cd6:	6946                	ld	s2,80(sp)
    80002cd8:	69a6                	ld	s3,72(sp)
    80002cda:	6a06                	ld	s4,64(sp)
    80002cdc:	7ae2                	ld	s5,56(sp)
    80002cde:	7b42                	ld	s6,48(sp)
    80002ce0:	7ba2                	ld	s7,40(sp)
    80002ce2:	7c02                	ld	s8,32(sp)
    80002ce4:	6ce2                	ld	s9,24(sp)
    80002ce6:	6d42                	ld	s10,16(sp)
    80002ce8:	6da2                	ld	s11,8(sp)
    80002cea:	6165                	addi	sp,sp,112
    80002cec:	8082                	ret

0000000080002cee <print_stats>:

void
print_stats(void){
    80002cee:	1141                	addi	sp,sp,-16
    80002cf0:	e406                	sd	ra,8(sp)
    80002cf2:	e022                	sd	s0,0(sp)
    80002cf4:	0800                	addi	s0,sp,16
  printf("_______________________\n");
    80002cf6:	00005517          	auipc	a0,0x5
    80002cfa:	63a50513          	addi	a0,a0,1594 # 80008330 <digits+0x2f0>
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	88c080e7          	jalr	-1908(ra) # 8000058a <printf>
  printf("running time mean: %d\n", running_processes_mean);
    80002d06:	00006597          	auipc	a1,0x6
    80002d0a:	3465a583          	lw	a1,838(a1) # 8000904c <running_processes_mean>
    80002d0e:	00005517          	auipc	a0,0x5
    80002d12:	64250513          	addi	a0,a0,1602 # 80008350 <digits+0x310>
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	874080e7          	jalr	-1932(ra) # 8000058a <printf>
  printf("runnable time mean: %d\n", runnable_processes_mean);
    80002d1e:	00006597          	auipc	a1,0x6
    80002d22:	32a5a583          	lw	a1,810(a1) # 80009048 <runnable_processes_mean>
    80002d26:	00005517          	auipc	a0,0x5
    80002d2a:	64250513          	addi	a0,a0,1602 # 80008368 <digits+0x328>
    80002d2e:	ffffe097          	auipc	ra,0xffffe
    80002d32:	85c080e7          	jalr	-1956(ra) # 8000058a <printf>
  printf("sleeping time mean: %d\n", sleeping_processes_mean);
    80002d36:	00006597          	auipc	a1,0x6
    80002d3a:	31a5a583          	lw	a1,794(a1) # 80009050 <sleeping_processes_mean>
    80002d3e:	00005517          	auipc	a0,0x5
    80002d42:	64250513          	addi	a0,a0,1602 # 80008380 <digits+0x340>
    80002d46:	ffffe097          	auipc	ra,0xffffe
    80002d4a:	844080e7          	jalr	-1980(ra) # 8000058a <printf>
  printf("program time: %d\n", program_time);
    80002d4e:	00006597          	auipc	a1,0x6
    80002d52:	2f25a583          	lw	a1,754(a1) # 80009040 <program_time>
    80002d56:	00005517          	auipc	a0,0x5
    80002d5a:	64250513          	addi	a0,a0,1602 # 80008398 <digits+0x358>
    80002d5e:	ffffe097          	auipc	ra,0xffffe
    80002d62:	82c080e7          	jalr	-2004(ra) # 8000058a <printf>
  printf("cpu utilization: %d\n", cpu_utilization);
    80002d66:	00006597          	auipc	a1,0x6
    80002d6a:	2d65a583          	lw	a1,726(a1) # 8000903c <cpu_utilization>
    80002d6e:	00005517          	auipc	a0,0x5
    80002d72:	64250513          	addi	a0,a0,1602 # 800083b0 <digits+0x370>
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	814080e7          	jalr	-2028(ra) # 8000058a <printf>
  printf("_______________________\n");
    80002d7e:	00005517          	auipc	a0,0x5
    80002d82:	5b250513          	addi	a0,a0,1458 # 80008330 <digits+0x2f0>
    80002d86:	ffffe097          	auipc	ra,0xffffe
    80002d8a:	804080e7          	jalr	-2044(ra) # 8000058a <printf>
    80002d8e:	60a2                	ld	ra,8(sp)
    80002d90:	6402                	ld	s0,0(sp)
    80002d92:	0141                	addi	sp,sp,16
    80002d94:	8082                	ret

0000000080002d96 <swtch>:
    80002d96:	00153023          	sd	ra,0(a0)
    80002d9a:	00253423          	sd	sp,8(a0)
    80002d9e:	e900                	sd	s0,16(a0)
    80002da0:	ed04                	sd	s1,24(a0)
    80002da2:	03253023          	sd	s2,32(a0)
    80002da6:	03353423          	sd	s3,40(a0)
    80002daa:	03453823          	sd	s4,48(a0)
    80002dae:	03553c23          	sd	s5,56(a0)
    80002db2:	05653023          	sd	s6,64(a0)
    80002db6:	05753423          	sd	s7,72(a0)
    80002dba:	05853823          	sd	s8,80(a0)
    80002dbe:	05953c23          	sd	s9,88(a0)
    80002dc2:	07a53023          	sd	s10,96(a0)
    80002dc6:	07b53423          	sd	s11,104(a0)
    80002dca:	0005b083          	ld	ra,0(a1)
    80002dce:	0085b103          	ld	sp,8(a1)
    80002dd2:	6980                	ld	s0,16(a1)
    80002dd4:	6d84                	ld	s1,24(a1)
    80002dd6:	0205b903          	ld	s2,32(a1)
    80002dda:	0285b983          	ld	s3,40(a1)
    80002dde:	0305ba03          	ld	s4,48(a1)
    80002de2:	0385ba83          	ld	s5,56(a1)
    80002de6:	0405bb03          	ld	s6,64(a1)
    80002dea:	0485bb83          	ld	s7,72(a1)
    80002dee:	0505bc03          	ld	s8,80(a1)
    80002df2:	0585bc83          	ld	s9,88(a1)
    80002df6:	0605bd03          	ld	s10,96(a1)
    80002dfa:	0685bd83          	ld	s11,104(a1)
    80002dfe:	8082                	ret

0000000080002e00 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002e00:	1141                	addi	sp,sp,-16
    80002e02:	e406                	sd	ra,8(sp)
    80002e04:	e022                	sd	s0,0(sp)
    80002e06:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002e08:	00005597          	auipc	a1,0x5
    80002e0c:	61858593          	addi	a1,a1,1560 # 80008420 <states.1747+0x30>
    80002e10:	00015517          	auipc	a0,0x15
    80002e14:	ae050513          	addi	a0,a0,-1312 # 800178f0 <tickslock>
    80002e18:	ffffe097          	auipc	ra,0xffffe
    80002e1c:	d3e080e7          	jalr	-706(ra) # 80000b56 <initlock>
}
    80002e20:	60a2                	ld	ra,8(sp)
    80002e22:	6402                	ld	s0,0(sp)
    80002e24:	0141                	addi	sp,sp,16
    80002e26:	8082                	ret

0000000080002e28 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002e28:	1141                	addi	sp,sp,-16
    80002e2a:	e422                	sd	s0,8(sp)
    80002e2c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e2e:	00003797          	auipc	a5,0x3
    80002e32:	4d278793          	addi	a5,a5,1234 # 80006300 <kernelvec>
    80002e36:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002e3a:	6422                	ld	s0,8(sp)
    80002e3c:	0141                	addi	sp,sp,16
    80002e3e:	8082                	ret

0000000080002e40 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002e40:	1141                	addi	sp,sp,-16
    80002e42:	e406                	sd	ra,8(sp)
    80002e44:	e022                	sd	s0,0(sp)
    80002e46:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	bd2080e7          	jalr	-1070(ra) # 80001a1a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e50:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002e54:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e56:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002e5a:	00004617          	auipc	a2,0x4
    80002e5e:	1a660613          	addi	a2,a2,422 # 80007000 <_trampoline>
    80002e62:	00004697          	auipc	a3,0x4
    80002e66:	19e68693          	addi	a3,a3,414 # 80007000 <_trampoline>
    80002e6a:	8e91                	sub	a3,a3,a2
    80002e6c:	040007b7          	lui	a5,0x4000
    80002e70:	17fd                	addi	a5,a5,-1
    80002e72:	07b2                	slli	a5,a5,0xc
    80002e74:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e76:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002e7a:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002e7c:	180026f3          	csrr	a3,satp
    80002e80:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002e82:	6d38                	ld	a4,88(a0)
    80002e84:	6134                	ld	a3,64(a0)
    80002e86:	6585                	lui	a1,0x1
    80002e88:	96ae                	add	a3,a3,a1
    80002e8a:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002e8c:	6d38                	ld	a4,88(a0)
    80002e8e:	00000697          	auipc	a3,0x0
    80002e92:	13868693          	addi	a3,a3,312 # 80002fc6 <usertrap>
    80002e96:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002e98:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002e9a:	8692                	mv	a3,tp
    80002e9c:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e9e:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ea2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ea6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eaa:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002eae:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002eb0:	6f18                	ld	a4,24(a4)
    80002eb2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002eb6:	692c                	ld	a1,80(a0)
    80002eb8:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002eba:	00004717          	auipc	a4,0x4
    80002ebe:	1d670713          	addi	a4,a4,470 # 80007090 <userret>
    80002ec2:	8f11                	sub	a4,a4,a2
    80002ec4:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002ec6:	577d                	li	a4,-1
    80002ec8:	177e                	slli	a4,a4,0x3f
    80002eca:	8dd9                	or	a1,a1,a4
    80002ecc:	02000537          	lui	a0,0x2000
    80002ed0:	157d                	addi	a0,a0,-1
    80002ed2:	0536                	slli	a0,a0,0xd
    80002ed4:	9782                	jalr	a5
}
    80002ed6:	60a2                	ld	ra,8(sp)
    80002ed8:	6402                	ld	s0,0(sp)
    80002eda:	0141                	addi	sp,sp,16
    80002edc:	8082                	ret

0000000080002ede <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002ede:	1101                	addi	sp,sp,-32
    80002ee0:	ec06                	sd	ra,24(sp)
    80002ee2:	e822                	sd	s0,16(sp)
    80002ee4:	e426                	sd	s1,8(sp)
    80002ee6:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ee8:	00015497          	auipc	s1,0x15
    80002eec:	a0848493          	addi	s1,s1,-1528 # 800178f0 <tickslock>
    80002ef0:	8526                	mv	a0,s1
    80002ef2:	ffffe097          	auipc	ra,0xffffe
    80002ef6:	cf4080e7          	jalr	-780(ra) # 80000be6 <acquire>
  ticks++;
    80002efa:	00006517          	auipc	a0,0x6
    80002efe:	15a50513          	addi	a0,a0,346 # 80009054 <ticks>
    80002f02:	411c                	lw	a5,0(a0)
    80002f04:	2785                	addiw	a5,a5,1
    80002f06:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	660080e7          	jalr	1632(ra) # 80002568 <wakeup>
  release(&tickslock);
    80002f10:	8526                	mv	a0,s1
    80002f12:	ffffe097          	auipc	ra,0xffffe
    80002f16:	d88080e7          	jalr	-632(ra) # 80000c9a <release>
}
    80002f1a:	60e2                	ld	ra,24(sp)
    80002f1c:	6442                	ld	s0,16(sp)
    80002f1e:	64a2                	ld	s1,8(sp)
    80002f20:	6105                	addi	sp,sp,32
    80002f22:	8082                	ret

0000000080002f24 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002f24:	1101                	addi	sp,sp,-32
    80002f26:	ec06                	sd	ra,24(sp)
    80002f28:	e822                	sd	s0,16(sp)
    80002f2a:	e426                	sd	s1,8(sp)
    80002f2c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f2e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002f32:	00074d63          	bltz	a4,80002f4c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002f36:	57fd                	li	a5,-1
    80002f38:	17fe                	slli	a5,a5,0x3f
    80002f3a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002f3c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002f3e:	06f70363          	beq	a4,a5,80002fa4 <devintr+0x80>
  }
}
    80002f42:	60e2                	ld	ra,24(sp)
    80002f44:	6442                	ld	s0,16(sp)
    80002f46:	64a2                	ld	s1,8(sp)
    80002f48:	6105                	addi	sp,sp,32
    80002f4a:	8082                	ret
     (scause & 0xff) == 9){
    80002f4c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002f50:	46a5                	li	a3,9
    80002f52:	fed792e3          	bne	a5,a3,80002f36 <devintr+0x12>
    int irq = plic_claim();
    80002f56:	00003097          	auipc	ra,0x3
    80002f5a:	4b2080e7          	jalr	1202(ra) # 80006408 <plic_claim>
    80002f5e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002f60:	47a9                	li	a5,10
    80002f62:	02f50763          	beq	a0,a5,80002f90 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002f66:	4785                	li	a5,1
    80002f68:	02f50963          	beq	a0,a5,80002f9a <devintr+0x76>
    return 1;
    80002f6c:	4505                	li	a0,1
    } else if(irq){
    80002f6e:	d8f1                	beqz	s1,80002f42 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002f70:	85a6                	mv	a1,s1
    80002f72:	00005517          	auipc	a0,0x5
    80002f76:	4b650513          	addi	a0,a0,1206 # 80008428 <states.1747+0x38>
    80002f7a:	ffffd097          	auipc	ra,0xffffd
    80002f7e:	610080e7          	jalr	1552(ra) # 8000058a <printf>
      plic_complete(irq);
    80002f82:	8526                	mv	a0,s1
    80002f84:	00003097          	auipc	ra,0x3
    80002f88:	4a8080e7          	jalr	1192(ra) # 8000642c <plic_complete>
    return 1;
    80002f8c:	4505                	li	a0,1
    80002f8e:	bf55                	j	80002f42 <devintr+0x1e>
      uartintr();
    80002f90:	ffffe097          	auipc	ra,0xffffe
    80002f94:	a1a080e7          	jalr	-1510(ra) # 800009aa <uartintr>
    80002f98:	b7ed                	j	80002f82 <devintr+0x5e>
      virtio_disk_intr();
    80002f9a:	00004097          	auipc	ra,0x4
    80002f9e:	972080e7          	jalr	-1678(ra) # 8000690c <virtio_disk_intr>
    80002fa2:	b7c5                	j	80002f82 <devintr+0x5e>
    if(cpuid() == 0){
    80002fa4:	fffff097          	auipc	ra,0xfffff
    80002fa8:	a4a080e7          	jalr	-1462(ra) # 800019ee <cpuid>
    80002fac:	c901                	beqz	a0,80002fbc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002fae:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002fb2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002fb4:	14479073          	csrw	sip,a5
    return 2;
    80002fb8:	4509                	li	a0,2
    80002fba:	b761                	j	80002f42 <devintr+0x1e>
      clockintr();
    80002fbc:	00000097          	auipc	ra,0x0
    80002fc0:	f22080e7          	jalr	-222(ra) # 80002ede <clockintr>
    80002fc4:	b7ed                	j	80002fae <devintr+0x8a>

0000000080002fc6 <usertrap>:
{
    80002fc6:	1101                	addi	sp,sp,-32
    80002fc8:	ec06                	sd	ra,24(sp)
    80002fca:	e822                	sd	s0,16(sp)
    80002fcc:	e426                	sd	s1,8(sp)
    80002fce:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fd0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002fd4:	1007f793          	andi	a5,a5,256
    80002fd8:	e3b5                	bnez	a5,8000303c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fda:	00003797          	auipc	a5,0x3
    80002fde:	32678793          	addi	a5,a5,806 # 80006300 <kernelvec>
    80002fe2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002fe6:	fffff097          	auipc	ra,0xfffff
    80002fea:	a34080e7          	jalr	-1484(ra) # 80001a1a <myproc>
    80002fee:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ff0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ff2:	14102773          	csrr	a4,sepc
    80002ff6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ff8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ffc:	47a1                	li	a5,8
    80002ffe:	04f71d63          	bne	a4,a5,80003058 <usertrap+0x92>
    if(p->killed)
    80003002:	551c                	lw	a5,40(a0)
    80003004:	2781                	sext.w	a5,a5
    80003006:	e3b9                	bnez	a5,8000304c <usertrap+0x86>
    p->trapframe->epc += 4;
    80003008:	6cb8                	ld	a4,88(s1)
    8000300a:	6f1c                	ld	a5,24(a4)
    8000300c:	0791                	addi	a5,a5,4
    8000300e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003010:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003014:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003018:	10079073          	csrw	sstatus,a5
    syscall();
    8000301c:	00000097          	auipc	ra,0x0
    80003020:	2ca080e7          	jalr	714(ra) # 800032e6 <syscall>
  if(p->killed)
    80003024:	549c                	lw	a5,40(s1)
    80003026:	2781                	sext.w	a5,a5
    80003028:	e7bd                	bnez	a5,80003096 <usertrap+0xd0>
  usertrapret();
    8000302a:	00000097          	auipc	ra,0x0
    8000302e:	e16080e7          	jalr	-490(ra) # 80002e40 <usertrapret>
}
    80003032:	60e2                	ld	ra,24(sp)
    80003034:	6442                	ld	s0,16(sp)
    80003036:	64a2                	ld	s1,8(sp)
    80003038:	6105                	addi	sp,sp,32
    8000303a:	8082                	ret
    panic("usertrap: not from user mode");
    8000303c:	00005517          	auipc	a0,0x5
    80003040:	40c50513          	addi	a0,a0,1036 # 80008448 <states.1747+0x58>
    80003044:	ffffd097          	auipc	ra,0xffffd
    80003048:	4fc080e7          	jalr	1276(ra) # 80000540 <panic>
      exit(-1);
    8000304c:	557d                	li	a0,-1
    8000304e:	fffff097          	auipc	ra,0xfffff
    80003052:	67a080e7          	jalr	1658(ra) # 800026c8 <exit>
    80003056:	bf4d                	j	80003008 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80003058:	00000097          	auipc	ra,0x0
    8000305c:	ecc080e7          	jalr	-308(ra) # 80002f24 <devintr>
    80003060:	f171                	bnez	a0,80003024 <usertrap+0x5e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003062:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003066:	5890                	lw	a2,48(s1)
    80003068:	00005517          	auipc	a0,0x5
    8000306c:	40050513          	addi	a0,a0,1024 # 80008468 <states.1747+0x78>
    80003070:	ffffd097          	auipc	ra,0xffffd
    80003074:	51a080e7          	jalr	1306(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003078:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000307c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003080:	00005517          	auipc	a0,0x5
    80003084:	41850513          	addi	a0,a0,1048 # 80008498 <states.1747+0xa8>
    80003088:	ffffd097          	auipc	ra,0xffffd
    8000308c:	502080e7          	jalr	1282(ra) # 8000058a <printf>
    p->killed = 1;
    80003090:	4785                	li	a5,1
    80003092:	d49c                	sw	a5,40(s1)
    80003094:	bf41                	j	80003024 <usertrap+0x5e>
    exit(-1);
    80003096:	557d                	li	a0,-1
    80003098:	fffff097          	auipc	ra,0xfffff
    8000309c:	630080e7          	jalr	1584(ra) # 800026c8 <exit>
    800030a0:	b769                	j	8000302a <usertrap+0x64>

00000000800030a2 <kerneltrap>:
{
    800030a2:	7179                	addi	sp,sp,-48
    800030a4:	f406                	sd	ra,40(sp)
    800030a6:	f022                	sd	s0,32(sp)
    800030a8:	ec26                	sd	s1,24(sp)
    800030aa:	e84a                	sd	s2,16(sp)
    800030ac:	e44e                	sd	s3,8(sp)
    800030ae:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800030b0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030b4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800030b8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800030bc:	1004f793          	andi	a5,s1,256
    800030c0:	cb85                	beqz	a5,800030f0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030c2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800030c6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800030c8:	ef85                	bnez	a5,80003100 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800030ca:	00000097          	auipc	ra,0x0
    800030ce:	e5a080e7          	jalr	-422(ra) # 80002f24 <devintr>
    800030d2:	cd1d                	beqz	a0,80003110 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800030d4:	4789                	li	a5,2
    800030d6:	06f50a63          	beq	a0,a5,8000314a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800030da:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030de:	10049073          	csrw	sstatus,s1
}
    800030e2:	70a2                	ld	ra,40(sp)
    800030e4:	7402                	ld	s0,32(sp)
    800030e6:	64e2                	ld	s1,24(sp)
    800030e8:	6942                	ld	s2,16(sp)
    800030ea:	69a2                	ld	s3,8(sp)
    800030ec:	6145                	addi	sp,sp,48
    800030ee:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800030f0:	00005517          	auipc	a0,0x5
    800030f4:	3c850513          	addi	a0,a0,968 # 800084b8 <states.1747+0xc8>
    800030f8:	ffffd097          	auipc	ra,0xffffd
    800030fc:	448080e7          	jalr	1096(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80003100:	00005517          	auipc	a0,0x5
    80003104:	3e050513          	addi	a0,a0,992 # 800084e0 <states.1747+0xf0>
    80003108:	ffffd097          	auipc	ra,0xffffd
    8000310c:	438080e7          	jalr	1080(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80003110:	85ce                	mv	a1,s3
    80003112:	00005517          	auipc	a0,0x5
    80003116:	3ee50513          	addi	a0,a0,1006 # 80008500 <states.1747+0x110>
    8000311a:	ffffd097          	auipc	ra,0xffffd
    8000311e:	470080e7          	jalr	1136(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003122:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003126:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000312a:	00005517          	auipc	a0,0x5
    8000312e:	3e650513          	addi	a0,a0,998 # 80008510 <states.1747+0x120>
    80003132:	ffffd097          	auipc	ra,0xffffd
    80003136:	458080e7          	jalr	1112(ra) # 8000058a <printf>
    panic("kerneltrap");
    8000313a:	00005517          	auipc	a0,0x5
    8000313e:	3ee50513          	addi	a0,a0,1006 # 80008528 <states.1747+0x138>
    80003142:	ffffd097          	auipc	ra,0xffffd
    80003146:	3fe080e7          	jalr	1022(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000314a:	fffff097          	auipc	ra,0xfffff
    8000314e:	8d0080e7          	jalr	-1840(ra) # 80001a1a <myproc>
    80003152:	d541                	beqz	a0,800030da <kerneltrap+0x38>
    80003154:	fffff097          	auipc	ra,0xfffff
    80003158:	8c6080e7          	jalr	-1850(ra) # 80001a1a <myproc>
    8000315c:	4d1c                	lw	a5,24(a0)
    8000315e:	2781                	sext.w	a5,a5
    80003160:	4711                	li	a4,4
    80003162:	f6e79ce3          	bne	a5,a4,800030da <kerneltrap+0x38>
    yield();
    80003166:	fffff097          	auipc	ra,0xfffff
    8000316a:	142080e7          	jalr	322(ra) # 800022a8 <yield>
    8000316e:	b7b5                	j	800030da <kerneltrap+0x38>

0000000080003170 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003170:	1101                	addi	sp,sp,-32
    80003172:	ec06                	sd	ra,24(sp)
    80003174:	e822                	sd	s0,16(sp)
    80003176:	e426                	sd	s1,8(sp)
    80003178:	1000                	addi	s0,sp,32
    8000317a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000317c:	fffff097          	auipc	ra,0xfffff
    80003180:	89e080e7          	jalr	-1890(ra) # 80001a1a <myproc>
  switch (n) {
    80003184:	4795                	li	a5,5
    80003186:	0497e163          	bltu	a5,s1,800031c8 <argraw+0x58>
    8000318a:	048a                	slli	s1,s1,0x2
    8000318c:	00005717          	auipc	a4,0x5
    80003190:	3d470713          	addi	a4,a4,980 # 80008560 <states.1747+0x170>
    80003194:	94ba                	add	s1,s1,a4
    80003196:	409c                	lw	a5,0(s1)
    80003198:	97ba                	add	a5,a5,a4
    8000319a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000319c:	6d3c                	ld	a5,88(a0)
    8000319e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800031a0:	60e2                	ld	ra,24(sp)
    800031a2:	6442                	ld	s0,16(sp)
    800031a4:	64a2                	ld	s1,8(sp)
    800031a6:	6105                	addi	sp,sp,32
    800031a8:	8082                	ret
    return p->trapframe->a1;
    800031aa:	6d3c                	ld	a5,88(a0)
    800031ac:	7fa8                	ld	a0,120(a5)
    800031ae:	bfcd                	j	800031a0 <argraw+0x30>
    return p->trapframe->a2;
    800031b0:	6d3c                	ld	a5,88(a0)
    800031b2:	63c8                	ld	a0,128(a5)
    800031b4:	b7f5                	j	800031a0 <argraw+0x30>
    return p->trapframe->a3;
    800031b6:	6d3c                	ld	a5,88(a0)
    800031b8:	67c8                	ld	a0,136(a5)
    800031ba:	b7dd                	j	800031a0 <argraw+0x30>
    return p->trapframe->a4;
    800031bc:	6d3c                	ld	a5,88(a0)
    800031be:	6bc8                	ld	a0,144(a5)
    800031c0:	b7c5                	j	800031a0 <argraw+0x30>
    return p->trapframe->a5;
    800031c2:	6d3c                	ld	a5,88(a0)
    800031c4:	6fc8                	ld	a0,152(a5)
    800031c6:	bfe9                	j	800031a0 <argraw+0x30>
  panic("argraw");
    800031c8:	00005517          	auipc	a0,0x5
    800031cc:	37050513          	addi	a0,a0,880 # 80008538 <states.1747+0x148>
    800031d0:	ffffd097          	auipc	ra,0xffffd
    800031d4:	370080e7          	jalr	880(ra) # 80000540 <panic>

00000000800031d8 <fetchaddr>:
{
    800031d8:	1101                	addi	sp,sp,-32
    800031da:	ec06                	sd	ra,24(sp)
    800031dc:	e822                	sd	s0,16(sp)
    800031de:	e426                	sd	s1,8(sp)
    800031e0:	e04a                	sd	s2,0(sp)
    800031e2:	1000                	addi	s0,sp,32
    800031e4:	84aa                	mv	s1,a0
    800031e6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800031e8:	fffff097          	auipc	ra,0xfffff
    800031ec:	832080e7          	jalr	-1998(ra) # 80001a1a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800031f0:	653c                	ld	a5,72(a0)
    800031f2:	02f4f863          	bgeu	s1,a5,80003222 <fetchaddr+0x4a>
    800031f6:	00848713          	addi	a4,s1,8
    800031fa:	02e7e663          	bltu	a5,a4,80003226 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800031fe:	46a1                	li	a3,8
    80003200:	8626                	mv	a2,s1
    80003202:	85ca                	mv	a1,s2
    80003204:	6928                	ld	a0,80(a0)
    80003206:	ffffe097          	auipc	ra,0xffffe
    8000320a:	4fa080e7          	jalr	1274(ra) # 80001700 <copyin>
    8000320e:	00a03533          	snez	a0,a0
    80003212:	40a00533          	neg	a0,a0
}
    80003216:	60e2                	ld	ra,24(sp)
    80003218:	6442                	ld	s0,16(sp)
    8000321a:	64a2                	ld	s1,8(sp)
    8000321c:	6902                	ld	s2,0(sp)
    8000321e:	6105                	addi	sp,sp,32
    80003220:	8082                	ret
    return -1;
    80003222:	557d                	li	a0,-1
    80003224:	bfcd                	j	80003216 <fetchaddr+0x3e>
    80003226:	557d                	li	a0,-1
    80003228:	b7fd                	j	80003216 <fetchaddr+0x3e>

000000008000322a <fetchstr>:
{
    8000322a:	7179                	addi	sp,sp,-48
    8000322c:	f406                	sd	ra,40(sp)
    8000322e:	f022                	sd	s0,32(sp)
    80003230:	ec26                	sd	s1,24(sp)
    80003232:	e84a                	sd	s2,16(sp)
    80003234:	e44e                	sd	s3,8(sp)
    80003236:	1800                	addi	s0,sp,48
    80003238:	892a                	mv	s2,a0
    8000323a:	84ae                	mv	s1,a1
    8000323c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	7dc080e7          	jalr	2012(ra) # 80001a1a <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003246:	86ce                	mv	a3,s3
    80003248:	864a                	mv	a2,s2
    8000324a:	85a6                	mv	a1,s1
    8000324c:	6928                	ld	a0,80(a0)
    8000324e:	ffffe097          	auipc	ra,0xffffe
    80003252:	53e080e7          	jalr	1342(ra) # 8000178c <copyinstr>
  if(err < 0)
    80003256:	00054763          	bltz	a0,80003264 <fetchstr+0x3a>
  return strlen(buf);
    8000325a:	8526                	mv	a0,s1
    8000325c:	ffffe097          	auipc	ra,0xffffe
    80003260:	c0a080e7          	jalr	-1014(ra) # 80000e66 <strlen>
}
    80003264:	70a2                	ld	ra,40(sp)
    80003266:	7402                	ld	s0,32(sp)
    80003268:	64e2                	ld	s1,24(sp)
    8000326a:	6942                	ld	s2,16(sp)
    8000326c:	69a2                	ld	s3,8(sp)
    8000326e:	6145                	addi	sp,sp,48
    80003270:	8082                	ret

0000000080003272 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003272:	1101                	addi	sp,sp,-32
    80003274:	ec06                	sd	ra,24(sp)
    80003276:	e822                	sd	s0,16(sp)
    80003278:	e426                	sd	s1,8(sp)
    8000327a:	1000                	addi	s0,sp,32
    8000327c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000327e:	00000097          	auipc	ra,0x0
    80003282:	ef2080e7          	jalr	-270(ra) # 80003170 <argraw>
    80003286:	c088                	sw	a0,0(s1)
  return 0;
}
    80003288:	4501                	li	a0,0
    8000328a:	60e2                	ld	ra,24(sp)
    8000328c:	6442                	ld	s0,16(sp)
    8000328e:	64a2                	ld	s1,8(sp)
    80003290:	6105                	addi	sp,sp,32
    80003292:	8082                	ret

0000000080003294 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003294:	1101                	addi	sp,sp,-32
    80003296:	ec06                	sd	ra,24(sp)
    80003298:	e822                	sd	s0,16(sp)
    8000329a:	e426                	sd	s1,8(sp)
    8000329c:	1000                	addi	s0,sp,32
    8000329e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800032a0:	00000097          	auipc	ra,0x0
    800032a4:	ed0080e7          	jalr	-304(ra) # 80003170 <argraw>
    800032a8:	e088                	sd	a0,0(s1)
  return 0;
}
    800032aa:	4501                	li	a0,0
    800032ac:	60e2                	ld	ra,24(sp)
    800032ae:	6442                	ld	s0,16(sp)
    800032b0:	64a2                	ld	s1,8(sp)
    800032b2:	6105                	addi	sp,sp,32
    800032b4:	8082                	ret

00000000800032b6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800032b6:	1101                	addi	sp,sp,-32
    800032b8:	ec06                	sd	ra,24(sp)
    800032ba:	e822                	sd	s0,16(sp)
    800032bc:	e426                	sd	s1,8(sp)
    800032be:	e04a                	sd	s2,0(sp)
    800032c0:	1000                	addi	s0,sp,32
    800032c2:	84ae                	mv	s1,a1
    800032c4:	8932                	mv	s2,a2
  *ip = argraw(n);
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	eaa080e7          	jalr	-342(ra) # 80003170 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800032ce:	864a                	mv	a2,s2
    800032d0:	85a6                	mv	a1,s1
    800032d2:	00000097          	auipc	ra,0x0
    800032d6:	f58080e7          	jalr	-168(ra) # 8000322a <fetchstr>
}
    800032da:	60e2                	ld	ra,24(sp)
    800032dc:	6442                	ld	s0,16(sp)
    800032de:	64a2                	ld	s1,8(sp)
    800032e0:	6902                	ld	s2,0(sp)
    800032e2:	6105                	addi	sp,sp,32
    800032e4:	8082                	ret

00000000800032e6 <syscall>:
};


void
syscall(void)
{
    800032e6:	1101                	addi	sp,sp,-32
    800032e8:	ec06                	sd	ra,24(sp)
    800032ea:	e822                	sd	s0,16(sp)
    800032ec:	e426                	sd	s1,8(sp)
    800032ee:	e04a                	sd	s2,0(sp)
    800032f0:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800032f2:	ffffe097          	auipc	ra,0xffffe
    800032f6:	728080e7          	jalr	1832(ra) # 80001a1a <myproc>
    800032fa:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800032fc:	05853903          	ld	s2,88(a0)
    80003300:	0a893783          	ld	a5,168(s2)
    80003304:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003308:	37fd                	addiw	a5,a5,-1
    8000330a:	475d                	li	a4,23
    8000330c:	00f76f63          	bltu	a4,a5,8000332a <syscall+0x44>
    80003310:	00369713          	slli	a4,a3,0x3
    80003314:	00005797          	auipc	a5,0x5
    80003318:	26478793          	addi	a5,a5,612 # 80008578 <syscalls>
    8000331c:	97ba                	add	a5,a5,a4
    8000331e:	639c                	ld	a5,0(a5)
    80003320:	c789                	beqz	a5,8000332a <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80003322:	9782                	jalr	a5
    80003324:	06a93823          	sd	a0,112(s2)
    80003328:	a839                	j	80003346 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000332a:	15848613          	addi	a2,s1,344
    8000332e:	588c                	lw	a1,48(s1)
    80003330:	00005517          	auipc	a0,0x5
    80003334:	21050513          	addi	a0,a0,528 # 80008540 <states.1747+0x150>
    80003338:	ffffd097          	auipc	ra,0xffffd
    8000333c:	252080e7          	jalr	594(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003340:	6cbc                	ld	a5,88(s1)
    80003342:	577d                	li	a4,-1
    80003344:	fbb8                	sd	a4,112(a5)
  }
}
    80003346:	60e2                	ld	ra,24(sp)
    80003348:	6442                	ld	s0,16(sp)
    8000334a:	64a2                	ld	s1,8(sp)
    8000334c:	6902                	ld	s2,0(sp)
    8000334e:	6105                	addi	sp,sp,32
    80003350:	8082                	ret

0000000080003352 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003352:	1101                	addi	sp,sp,-32
    80003354:	ec06                	sd	ra,24(sp)
    80003356:	e822                	sd	s0,16(sp)
    80003358:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000335a:	fec40593          	addi	a1,s0,-20
    8000335e:	4501                	li	a0,0
    80003360:	00000097          	auipc	ra,0x0
    80003364:	f12080e7          	jalr	-238(ra) # 80003272 <argint>
    return -1;
    80003368:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000336a:	00054963          	bltz	a0,8000337c <sys_exit+0x2a>
  exit(n);
    8000336e:	fec42503          	lw	a0,-20(s0)
    80003372:	fffff097          	auipc	ra,0xfffff
    80003376:	356080e7          	jalr	854(ra) # 800026c8 <exit>
  return 0;  // not reached
    8000337a:	4781                	li	a5,0
}
    8000337c:	853e                	mv	a0,a5
    8000337e:	60e2                	ld	ra,24(sp)
    80003380:	6442                	ld	s0,16(sp)
    80003382:	6105                	addi	sp,sp,32
    80003384:	8082                	ret

0000000080003386 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003386:	1141                	addi	sp,sp,-16
    80003388:	e406                	sd	ra,8(sp)
    8000338a:	e022                	sd	s0,0(sp)
    8000338c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	68c080e7          	jalr	1676(ra) # 80001a1a <myproc>
}
    80003396:	5908                	lw	a0,48(a0)
    80003398:	60a2                	ld	ra,8(sp)
    8000339a:	6402                	ld	s0,0(sp)
    8000339c:	0141                	addi	sp,sp,16
    8000339e:	8082                	ret

00000000800033a0 <sys_fork>:

uint64
sys_fork(void)
{
    800033a0:	1141                	addi	sp,sp,-16
    800033a2:	e406                	sd	ra,8(sp)
    800033a4:	e022                	sd	s0,0(sp)
    800033a6:	0800                	addi	s0,sp,16
  return fork();
    800033a8:	fffff097          	auipc	ra,0xfffff
    800033ac:	a82080e7          	jalr	-1406(ra) # 80001e2a <fork>
}
    800033b0:	60a2                	ld	ra,8(sp)
    800033b2:	6402                	ld	s0,0(sp)
    800033b4:	0141                	addi	sp,sp,16
    800033b6:	8082                	ret

00000000800033b8 <sys_wait>:

uint64
sys_wait(void)
{
    800033b8:	1101                	addi	sp,sp,-32
    800033ba:	ec06                	sd	ra,24(sp)
    800033bc:	e822                	sd	s0,16(sp)
    800033be:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800033c0:	fe840593          	addi	a1,s0,-24
    800033c4:	4501                	li	a0,0
    800033c6:	00000097          	auipc	ra,0x0
    800033ca:	ece080e7          	jalr	-306(ra) # 80003294 <argaddr>
    800033ce:	87aa                	mv	a5,a0
    return -1;
    800033d0:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800033d2:	0007c863          	bltz	a5,800033e2 <sys_wait+0x2a>
  return wait(p);
    800033d6:	fe843503          	ld	a0,-24(s0)
    800033da:	fffff097          	auipc	ra,0xfffff
    800033de:	062080e7          	jalr	98(ra) # 8000243c <wait>
}
    800033e2:	60e2                	ld	ra,24(sp)
    800033e4:	6442                	ld	s0,16(sp)
    800033e6:	6105                	addi	sp,sp,32
    800033e8:	8082                	ret

00000000800033ea <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800033ea:	7179                	addi	sp,sp,-48
    800033ec:	f406                	sd	ra,40(sp)
    800033ee:	f022                	sd	s0,32(sp)
    800033f0:	ec26                	sd	s1,24(sp)
    800033f2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800033f4:	fdc40593          	addi	a1,s0,-36
    800033f8:	4501                	li	a0,0
    800033fa:	00000097          	auipc	ra,0x0
    800033fe:	e78080e7          	jalr	-392(ra) # 80003272 <argint>
    80003402:	87aa                	mv	a5,a0
    return -1;
    80003404:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003406:	0207c063          	bltz	a5,80003426 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    8000340a:	ffffe097          	auipc	ra,0xffffe
    8000340e:	610080e7          	jalr	1552(ra) # 80001a1a <myproc>
    80003412:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003414:	fdc42503          	lw	a0,-36(s0)
    80003418:	fffff097          	auipc	ra,0xfffff
    8000341c:	99e080e7          	jalr	-1634(ra) # 80001db6 <growproc>
    80003420:	00054863          	bltz	a0,80003430 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003424:	8526                	mv	a0,s1
}
    80003426:	70a2                	ld	ra,40(sp)
    80003428:	7402                	ld	s0,32(sp)
    8000342a:	64e2                	ld	s1,24(sp)
    8000342c:	6145                	addi	sp,sp,48
    8000342e:	8082                	ret
    return -1;
    80003430:	557d                	li	a0,-1
    80003432:	bfd5                	j	80003426 <sys_sbrk+0x3c>

0000000080003434 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003434:	7139                	addi	sp,sp,-64
    80003436:	fc06                	sd	ra,56(sp)
    80003438:	f822                	sd	s0,48(sp)
    8000343a:	f426                	sd	s1,40(sp)
    8000343c:	f04a                	sd	s2,32(sp)
    8000343e:	ec4e                	sd	s3,24(sp)
    80003440:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003442:	fcc40593          	addi	a1,s0,-52
    80003446:	4501                	li	a0,0
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	e2a080e7          	jalr	-470(ra) # 80003272 <argint>
    return -1;
    80003450:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003452:	06054663          	bltz	a0,800034be <sys_sleep+0x8a>
  acquire(&tickslock);
    80003456:	00014517          	auipc	a0,0x14
    8000345a:	49a50513          	addi	a0,a0,1178 # 800178f0 <tickslock>
    8000345e:	ffffd097          	auipc	ra,0xffffd
    80003462:	788080e7          	jalr	1928(ra) # 80000be6 <acquire>
  ticks0 = ticks;
    80003466:	00006917          	auipc	s2,0x6
    8000346a:	bee92903          	lw	s2,-1042(s2) # 80009054 <ticks>
  while(ticks - ticks0 < n){
    8000346e:	fcc42783          	lw	a5,-52(s0)
    80003472:	cf8d                	beqz	a5,800034ac <sys_sleep+0x78>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003474:	00014997          	auipc	s3,0x14
    80003478:	47c98993          	addi	s3,s3,1148 # 800178f0 <tickslock>
    8000347c:	00006497          	auipc	s1,0x6
    80003480:	bd848493          	addi	s1,s1,-1064 # 80009054 <ticks>
    if(myproc()->killed){
    80003484:	ffffe097          	auipc	ra,0xffffe
    80003488:	596080e7          	jalr	1430(ra) # 80001a1a <myproc>
    8000348c:	551c                	lw	a5,40(a0)
    8000348e:	2781                	sext.w	a5,a5
    80003490:	ef9d                	bnez	a5,800034ce <sys_sleep+0x9a>
    sleep(&ticks, &tickslock);
    80003492:	85ce                	mv	a1,s3
    80003494:	8526                	mv	a0,s1
    80003496:	fffff097          	auipc	ra,0xfffff
    8000349a:	eca080e7          	jalr	-310(ra) # 80002360 <sleep>
  while(ticks - ticks0 < n){
    8000349e:	409c                	lw	a5,0(s1)
    800034a0:	412787bb          	subw	a5,a5,s2
    800034a4:	fcc42703          	lw	a4,-52(s0)
    800034a8:	fce7eee3          	bltu	a5,a4,80003484 <sys_sleep+0x50>
  }
  release(&tickslock);
    800034ac:	00014517          	auipc	a0,0x14
    800034b0:	44450513          	addi	a0,a0,1092 # 800178f0 <tickslock>
    800034b4:	ffffd097          	auipc	ra,0xffffd
    800034b8:	7e6080e7          	jalr	2022(ra) # 80000c9a <release>
  return 0;
    800034bc:	4781                	li	a5,0
}
    800034be:	853e                	mv	a0,a5
    800034c0:	70e2                	ld	ra,56(sp)
    800034c2:	7442                	ld	s0,48(sp)
    800034c4:	74a2                	ld	s1,40(sp)
    800034c6:	7902                	ld	s2,32(sp)
    800034c8:	69e2                	ld	s3,24(sp)
    800034ca:	6121                	addi	sp,sp,64
    800034cc:	8082                	ret
      release(&tickslock);
    800034ce:	00014517          	auipc	a0,0x14
    800034d2:	42250513          	addi	a0,a0,1058 # 800178f0 <tickslock>
    800034d6:	ffffd097          	auipc	ra,0xffffd
    800034da:	7c4080e7          	jalr	1988(ra) # 80000c9a <release>
      return -1;
    800034de:	57fd                	li	a5,-1
    800034e0:	bff9                	j	800034be <sys_sleep+0x8a>

00000000800034e2 <sys_kill>:

uint64
sys_kill(void)
{
    800034e2:	1101                	addi	sp,sp,-32
    800034e4:	ec06                	sd	ra,24(sp)
    800034e6:	e822                	sd	s0,16(sp)
    800034e8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800034ea:	fec40593          	addi	a1,s0,-20
    800034ee:	4501                	li	a0,0
    800034f0:	00000097          	auipc	ra,0x0
    800034f4:	d82080e7          	jalr	-638(ra) # 80003272 <argint>
    800034f8:	87aa                	mv	a5,a0
    return -1;
    800034fa:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800034fc:	0007c863          	bltz	a5,8000350c <sys_kill+0x2a>
  return kill(pid);
    80003500:	fec42503          	lw	a0,-20(s0)
    80003504:	fffff097          	auipc	ra,0xfffff
    80003508:	3be080e7          	jalr	958(ra) # 800028c2 <kill>
}
    8000350c:	60e2                	ld	ra,24(sp)
    8000350e:	6442                	ld	s0,16(sp)
    80003510:	6105                	addi	sp,sp,32
    80003512:	8082                	ret

0000000080003514 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003514:	1101                	addi	sp,sp,-32
    80003516:	ec06                	sd	ra,24(sp)
    80003518:	e822                	sd	s0,16(sp)
    8000351a:	e426                	sd	s1,8(sp)
    8000351c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000351e:	00014517          	auipc	a0,0x14
    80003522:	3d250513          	addi	a0,a0,978 # 800178f0 <tickslock>
    80003526:	ffffd097          	auipc	ra,0xffffd
    8000352a:	6c0080e7          	jalr	1728(ra) # 80000be6 <acquire>
  xticks = ticks;
    8000352e:	00006497          	auipc	s1,0x6
    80003532:	b264a483          	lw	s1,-1242(s1) # 80009054 <ticks>
  release(&tickslock);
    80003536:	00014517          	auipc	a0,0x14
    8000353a:	3ba50513          	addi	a0,a0,954 # 800178f0 <tickslock>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	75c080e7          	jalr	1884(ra) # 80000c9a <release>
  return xticks;
}
    80003546:	02049513          	slli	a0,s1,0x20
    8000354a:	9101                	srli	a0,a0,0x20
    8000354c:	60e2                	ld	ra,24(sp)
    8000354e:	6442                	ld	s0,16(sp)
    80003550:	64a2                	ld	s1,8(sp)
    80003552:	6105                	addi	sp,sp,32
    80003554:	8082                	ret

0000000080003556 <sys_pause_system>:

uint64
sys_pause_system(void)
{
    80003556:	1101                	addi	sp,sp,-32
    80003558:	ec06                	sd	ra,24(sp)
    8000355a:	e822                	sd	s0,16(sp)
    8000355c:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    8000355e:	fec40593          	addi	a1,s0,-20
    80003562:	4501                	li	a0,0
    80003564:	00000097          	auipc	ra,0x0
    80003568:	d0e080e7          	jalr	-754(ra) # 80003272 <argint>
    8000356c:	87aa                	mv	a5,a0
    return -1;
    8000356e:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    80003570:	0007c863          	bltz	a5,80003580 <sys_pause_system+0x2a>
  return pause_system(seconds);
    80003574:	fec42503          	lw	a0,-20(s0)
    80003578:	fffff097          	auipc	ra,0xfffff
    8000357c:	5a2080e7          	jalr	1442(ra) # 80002b1a <pause_system>
}
    80003580:	60e2                	ld	ra,24(sp)
    80003582:	6442                	ld	s0,16(sp)
    80003584:	6105                	addi	sp,sp,32
    80003586:	8082                	ret

0000000080003588 <sys_kill_system>:


uint64
sys_kill_system(void)
{
    80003588:	1141                	addi	sp,sp,-16
    8000358a:	e406                	sd	ra,8(sp)
    8000358c:	e022                	sd	s0,0(sp)
    8000358e:	0800                	addi	s0,sp,16
  return kill_system();
    80003590:	fffff097          	auipc	ra,0xfffff
    80003594:	65e080e7          	jalr	1630(ra) # 80002bee <kill_system>
}
    80003598:	60a2                	ld	ra,8(sp)
    8000359a:	6402                	ld	s0,0(sp)
    8000359c:	0141                	addi	sp,sp,16
    8000359e:	8082                	ret

00000000800035a0 <sys_print_stats>:

uint64
sys_print_stats(void){
    800035a0:	1141                	addi	sp,sp,-16
    800035a2:	e406                	sd	ra,8(sp)
    800035a4:	e022                	sd	s0,0(sp)
    800035a6:	0800                	addi	s0,sp,16
  print_stats();
    800035a8:	fffff097          	auipc	ra,0xfffff
    800035ac:	746080e7          	jalr	1862(ra) # 80002cee <print_stats>
  return 0;
}
    800035b0:	4501                	li	a0,0
    800035b2:	60a2                	ld	ra,8(sp)
    800035b4:	6402                	ld	s0,0(sp)
    800035b6:	0141                	addi	sp,sp,16
    800035b8:	8082                	ret

00000000800035ba <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800035ba:	7179                	addi	sp,sp,-48
    800035bc:	f406                	sd	ra,40(sp)
    800035be:	f022                	sd	s0,32(sp)
    800035c0:	ec26                	sd	s1,24(sp)
    800035c2:	e84a                	sd	s2,16(sp)
    800035c4:	e44e                	sd	s3,8(sp)
    800035c6:	e052                	sd	s4,0(sp)
    800035c8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800035ca:	00005597          	auipc	a1,0x5
    800035ce:	07658593          	addi	a1,a1,118 # 80008640 <syscalls+0xc8>
    800035d2:	00014517          	auipc	a0,0x14
    800035d6:	33650513          	addi	a0,a0,822 # 80017908 <bcache>
    800035da:	ffffd097          	auipc	ra,0xffffd
    800035de:	57c080e7          	jalr	1404(ra) # 80000b56 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800035e2:	0001c797          	auipc	a5,0x1c
    800035e6:	32678793          	addi	a5,a5,806 # 8001f908 <bcache+0x8000>
    800035ea:	0001c717          	auipc	a4,0x1c
    800035ee:	58670713          	addi	a4,a4,1414 # 8001fb70 <bcache+0x8268>
    800035f2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800035f6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035fa:	00014497          	auipc	s1,0x14
    800035fe:	32648493          	addi	s1,s1,806 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    80003602:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003604:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003606:	00005a17          	auipc	s4,0x5
    8000360a:	042a0a13          	addi	s4,s4,66 # 80008648 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000360e:	2b893783          	ld	a5,696(s2)
    80003612:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003614:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003618:	85d2                	mv	a1,s4
    8000361a:	01048513          	addi	a0,s1,16
    8000361e:	00001097          	auipc	ra,0x1
    80003622:	4bc080e7          	jalr	1212(ra) # 80004ada <initsleeplock>
    bcache.head.next->prev = b;
    80003626:	2b893783          	ld	a5,696(s2)
    8000362a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000362c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003630:	45848493          	addi	s1,s1,1112
    80003634:	fd349de3          	bne	s1,s3,8000360e <binit+0x54>
  }
}
    80003638:	70a2                	ld	ra,40(sp)
    8000363a:	7402                	ld	s0,32(sp)
    8000363c:	64e2                	ld	s1,24(sp)
    8000363e:	6942                	ld	s2,16(sp)
    80003640:	69a2                	ld	s3,8(sp)
    80003642:	6a02                	ld	s4,0(sp)
    80003644:	6145                	addi	sp,sp,48
    80003646:	8082                	ret

0000000080003648 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003648:	7179                	addi	sp,sp,-48
    8000364a:	f406                	sd	ra,40(sp)
    8000364c:	f022                	sd	s0,32(sp)
    8000364e:	ec26                	sd	s1,24(sp)
    80003650:	e84a                	sd	s2,16(sp)
    80003652:	e44e                	sd	s3,8(sp)
    80003654:	1800                	addi	s0,sp,48
    80003656:	89aa                	mv	s3,a0
    80003658:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000365a:	00014517          	auipc	a0,0x14
    8000365e:	2ae50513          	addi	a0,a0,686 # 80017908 <bcache>
    80003662:	ffffd097          	auipc	ra,0xffffd
    80003666:	584080e7          	jalr	1412(ra) # 80000be6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000366a:	0001c497          	auipc	s1,0x1c
    8000366e:	5564b483          	ld	s1,1366(s1) # 8001fbc0 <bcache+0x82b8>
    80003672:	0001c797          	auipc	a5,0x1c
    80003676:	4fe78793          	addi	a5,a5,1278 # 8001fb70 <bcache+0x8268>
    8000367a:	02f48f63          	beq	s1,a5,800036b8 <bread+0x70>
    8000367e:	873e                	mv	a4,a5
    80003680:	a021                	j	80003688 <bread+0x40>
    80003682:	68a4                	ld	s1,80(s1)
    80003684:	02e48a63          	beq	s1,a4,800036b8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003688:	449c                	lw	a5,8(s1)
    8000368a:	ff379ce3          	bne	a5,s3,80003682 <bread+0x3a>
    8000368e:	44dc                	lw	a5,12(s1)
    80003690:	ff2799e3          	bne	a5,s2,80003682 <bread+0x3a>
      b->refcnt++;
    80003694:	40bc                	lw	a5,64(s1)
    80003696:	2785                	addiw	a5,a5,1
    80003698:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000369a:	00014517          	auipc	a0,0x14
    8000369e:	26e50513          	addi	a0,a0,622 # 80017908 <bcache>
    800036a2:	ffffd097          	auipc	ra,0xffffd
    800036a6:	5f8080e7          	jalr	1528(ra) # 80000c9a <release>
      acquiresleep(&b->lock);
    800036aa:	01048513          	addi	a0,s1,16
    800036ae:	00001097          	auipc	ra,0x1
    800036b2:	466080e7          	jalr	1126(ra) # 80004b14 <acquiresleep>
      return b;
    800036b6:	a8b9                	j	80003714 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036b8:	0001c497          	auipc	s1,0x1c
    800036bc:	5004b483          	ld	s1,1280(s1) # 8001fbb8 <bcache+0x82b0>
    800036c0:	0001c797          	auipc	a5,0x1c
    800036c4:	4b078793          	addi	a5,a5,1200 # 8001fb70 <bcache+0x8268>
    800036c8:	00f48863          	beq	s1,a5,800036d8 <bread+0x90>
    800036cc:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800036ce:	40bc                	lw	a5,64(s1)
    800036d0:	cf81                	beqz	a5,800036e8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800036d2:	64a4                	ld	s1,72(s1)
    800036d4:	fee49de3          	bne	s1,a4,800036ce <bread+0x86>
  panic("bget: no buffers");
    800036d8:	00005517          	auipc	a0,0x5
    800036dc:	f7850513          	addi	a0,a0,-136 # 80008650 <syscalls+0xd8>
    800036e0:	ffffd097          	auipc	ra,0xffffd
    800036e4:	e60080e7          	jalr	-416(ra) # 80000540 <panic>
      b->dev = dev;
    800036e8:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800036ec:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800036f0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800036f4:	4785                	li	a5,1
    800036f6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800036f8:	00014517          	auipc	a0,0x14
    800036fc:	21050513          	addi	a0,a0,528 # 80017908 <bcache>
    80003700:	ffffd097          	auipc	ra,0xffffd
    80003704:	59a080e7          	jalr	1434(ra) # 80000c9a <release>
      acquiresleep(&b->lock);
    80003708:	01048513          	addi	a0,s1,16
    8000370c:	00001097          	auipc	ra,0x1
    80003710:	408080e7          	jalr	1032(ra) # 80004b14 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003714:	409c                	lw	a5,0(s1)
    80003716:	cb89                	beqz	a5,80003728 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003718:	8526                	mv	a0,s1
    8000371a:	70a2                	ld	ra,40(sp)
    8000371c:	7402                	ld	s0,32(sp)
    8000371e:	64e2                	ld	s1,24(sp)
    80003720:	6942                	ld	s2,16(sp)
    80003722:	69a2                	ld	s3,8(sp)
    80003724:	6145                	addi	sp,sp,48
    80003726:	8082                	ret
    virtio_disk_rw(b, 0);
    80003728:	4581                	li	a1,0
    8000372a:	8526                	mv	a0,s1
    8000372c:	00003097          	auipc	ra,0x3
    80003730:	f0a080e7          	jalr	-246(ra) # 80006636 <virtio_disk_rw>
    b->valid = 1;
    80003734:	4785                	li	a5,1
    80003736:	c09c                	sw	a5,0(s1)
  return b;
    80003738:	b7c5                	j	80003718 <bread+0xd0>

000000008000373a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000373a:	1101                	addi	sp,sp,-32
    8000373c:	ec06                	sd	ra,24(sp)
    8000373e:	e822                	sd	s0,16(sp)
    80003740:	e426                	sd	s1,8(sp)
    80003742:	1000                	addi	s0,sp,32
    80003744:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003746:	0541                	addi	a0,a0,16
    80003748:	00001097          	auipc	ra,0x1
    8000374c:	466080e7          	jalr	1126(ra) # 80004bae <holdingsleep>
    80003750:	cd01                	beqz	a0,80003768 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003752:	4585                	li	a1,1
    80003754:	8526                	mv	a0,s1
    80003756:	00003097          	auipc	ra,0x3
    8000375a:	ee0080e7          	jalr	-288(ra) # 80006636 <virtio_disk_rw>
}
    8000375e:	60e2                	ld	ra,24(sp)
    80003760:	6442                	ld	s0,16(sp)
    80003762:	64a2                	ld	s1,8(sp)
    80003764:	6105                	addi	sp,sp,32
    80003766:	8082                	ret
    panic("bwrite");
    80003768:	00005517          	auipc	a0,0x5
    8000376c:	f0050513          	addi	a0,a0,-256 # 80008668 <syscalls+0xf0>
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	dd0080e7          	jalr	-560(ra) # 80000540 <panic>

0000000080003778 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003778:	1101                	addi	sp,sp,-32
    8000377a:	ec06                	sd	ra,24(sp)
    8000377c:	e822                	sd	s0,16(sp)
    8000377e:	e426                	sd	s1,8(sp)
    80003780:	e04a                	sd	s2,0(sp)
    80003782:	1000                	addi	s0,sp,32
    80003784:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003786:	01050913          	addi	s2,a0,16
    8000378a:	854a                	mv	a0,s2
    8000378c:	00001097          	auipc	ra,0x1
    80003790:	422080e7          	jalr	1058(ra) # 80004bae <holdingsleep>
    80003794:	c92d                	beqz	a0,80003806 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003796:	854a                	mv	a0,s2
    80003798:	00001097          	auipc	ra,0x1
    8000379c:	3d2080e7          	jalr	978(ra) # 80004b6a <releasesleep>

  acquire(&bcache.lock);
    800037a0:	00014517          	auipc	a0,0x14
    800037a4:	16850513          	addi	a0,a0,360 # 80017908 <bcache>
    800037a8:	ffffd097          	auipc	ra,0xffffd
    800037ac:	43e080e7          	jalr	1086(ra) # 80000be6 <acquire>
  b->refcnt--;
    800037b0:	40bc                	lw	a5,64(s1)
    800037b2:	37fd                	addiw	a5,a5,-1
    800037b4:	0007871b          	sext.w	a4,a5
    800037b8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800037ba:	eb05                	bnez	a4,800037ea <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800037bc:	68bc                	ld	a5,80(s1)
    800037be:	64b8                	ld	a4,72(s1)
    800037c0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800037c2:	64bc                	ld	a5,72(s1)
    800037c4:	68b8                	ld	a4,80(s1)
    800037c6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800037c8:	0001c797          	auipc	a5,0x1c
    800037cc:	14078793          	addi	a5,a5,320 # 8001f908 <bcache+0x8000>
    800037d0:	2b87b703          	ld	a4,696(a5)
    800037d4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800037d6:	0001c717          	auipc	a4,0x1c
    800037da:	39a70713          	addi	a4,a4,922 # 8001fb70 <bcache+0x8268>
    800037de:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800037e0:	2b87b703          	ld	a4,696(a5)
    800037e4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800037e6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800037ea:	00014517          	auipc	a0,0x14
    800037ee:	11e50513          	addi	a0,a0,286 # 80017908 <bcache>
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	4a8080e7          	jalr	1192(ra) # 80000c9a <release>
}
    800037fa:	60e2                	ld	ra,24(sp)
    800037fc:	6442                	ld	s0,16(sp)
    800037fe:	64a2                	ld	s1,8(sp)
    80003800:	6902                	ld	s2,0(sp)
    80003802:	6105                	addi	sp,sp,32
    80003804:	8082                	ret
    panic("brelse");
    80003806:	00005517          	auipc	a0,0x5
    8000380a:	e6a50513          	addi	a0,a0,-406 # 80008670 <syscalls+0xf8>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	d32080e7          	jalr	-718(ra) # 80000540 <panic>

0000000080003816 <bpin>:

void
bpin(struct buf *b) {
    80003816:	1101                	addi	sp,sp,-32
    80003818:	ec06                	sd	ra,24(sp)
    8000381a:	e822                	sd	s0,16(sp)
    8000381c:	e426                	sd	s1,8(sp)
    8000381e:	1000                	addi	s0,sp,32
    80003820:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003822:	00014517          	auipc	a0,0x14
    80003826:	0e650513          	addi	a0,a0,230 # 80017908 <bcache>
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	3bc080e7          	jalr	956(ra) # 80000be6 <acquire>
  b->refcnt++;
    80003832:	40bc                	lw	a5,64(s1)
    80003834:	2785                	addiw	a5,a5,1
    80003836:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003838:	00014517          	auipc	a0,0x14
    8000383c:	0d050513          	addi	a0,a0,208 # 80017908 <bcache>
    80003840:	ffffd097          	auipc	ra,0xffffd
    80003844:	45a080e7          	jalr	1114(ra) # 80000c9a <release>
}
    80003848:	60e2                	ld	ra,24(sp)
    8000384a:	6442                	ld	s0,16(sp)
    8000384c:	64a2                	ld	s1,8(sp)
    8000384e:	6105                	addi	sp,sp,32
    80003850:	8082                	ret

0000000080003852 <bunpin>:

void
bunpin(struct buf *b) {
    80003852:	1101                	addi	sp,sp,-32
    80003854:	ec06                	sd	ra,24(sp)
    80003856:	e822                	sd	s0,16(sp)
    80003858:	e426                	sd	s1,8(sp)
    8000385a:	1000                	addi	s0,sp,32
    8000385c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000385e:	00014517          	auipc	a0,0x14
    80003862:	0aa50513          	addi	a0,a0,170 # 80017908 <bcache>
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	380080e7          	jalr	896(ra) # 80000be6 <acquire>
  b->refcnt--;
    8000386e:	40bc                	lw	a5,64(s1)
    80003870:	37fd                	addiw	a5,a5,-1
    80003872:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003874:	00014517          	auipc	a0,0x14
    80003878:	09450513          	addi	a0,a0,148 # 80017908 <bcache>
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	41e080e7          	jalr	1054(ra) # 80000c9a <release>
}
    80003884:	60e2                	ld	ra,24(sp)
    80003886:	6442                	ld	s0,16(sp)
    80003888:	64a2                	ld	s1,8(sp)
    8000388a:	6105                	addi	sp,sp,32
    8000388c:	8082                	ret

000000008000388e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000388e:	1101                	addi	sp,sp,-32
    80003890:	ec06                	sd	ra,24(sp)
    80003892:	e822                	sd	s0,16(sp)
    80003894:	e426                	sd	s1,8(sp)
    80003896:	e04a                	sd	s2,0(sp)
    80003898:	1000                	addi	s0,sp,32
    8000389a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000389c:	00d5d59b          	srliw	a1,a1,0xd
    800038a0:	0001c797          	auipc	a5,0x1c
    800038a4:	7447a783          	lw	a5,1860(a5) # 8001ffe4 <sb+0x1c>
    800038a8:	9dbd                	addw	a1,a1,a5
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	d9e080e7          	jalr	-610(ra) # 80003648 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800038b2:	0074f713          	andi	a4,s1,7
    800038b6:	4785                	li	a5,1
    800038b8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800038bc:	14ce                	slli	s1,s1,0x33
    800038be:	90d9                	srli	s1,s1,0x36
    800038c0:	00950733          	add	a4,a0,s1
    800038c4:	05874703          	lbu	a4,88(a4)
    800038c8:	00e7f6b3          	and	a3,a5,a4
    800038cc:	c69d                	beqz	a3,800038fa <bfree+0x6c>
    800038ce:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800038d0:	94aa                	add	s1,s1,a0
    800038d2:	fff7c793          	not	a5,a5
    800038d6:	8ff9                	and	a5,a5,a4
    800038d8:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800038dc:	00001097          	auipc	ra,0x1
    800038e0:	118080e7          	jalr	280(ra) # 800049f4 <log_write>
  brelse(bp);
    800038e4:	854a                	mv	a0,s2
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	e92080e7          	jalr	-366(ra) # 80003778 <brelse>
}
    800038ee:	60e2                	ld	ra,24(sp)
    800038f0:	6442                	ld	s0,16(sp)
    800038f2:	64a2                	ld	s1,8(sp)
    800038f4:	6902                	ld	s2,0(sp)
    800038f6:	6105                	addi	sp,sp,32
    800038f8:	8082                	ret
    panic("freeing free block");
    800038fa:	00005517          	auipc	a0,0x5
    800038fe:	d7e50513          	addi	a0,a0,-642 # 80008678 <syscalls+0x100>
    80003902:	ffffd097          	auipc	ra,0xffffd
    80003906:	c3e080e7          	jalr	-962(ra) # 80000540 <panic>

000000008000390a <balloc>:
{
    8000390a:	711d                	addi	sp,sp,-96
    8000390c:	ec86                	sd	ra,88(sp)
    8000390e:	e8a2                	sd	s0,80(sp)
    80003910:	e4a6                	sd	s1,72(sp)
    80003912:	e0ca                	sd	s2,64(sp)
    80003914:	fc4e                	sd	s3,56(sp)
    80003916:	f852                	sd	s4,48(sp)
    80003918:	f456                	sd	s5,40(sp)
    8000391a:	f05a                	sd	s6,32(sp)
    8000391c:	ec5e                	sd	s7,24(sp)
    8000391e:	e862                	sd	s8,16(sp)
    80003920:	e466                	sd	s9,8(sp)
    80003922:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003924:	0001c797          	auipc	a5,0x1c
    80003928:	6a87a783          	lw	a5,1704(a5) # 8001ffcc <sb+0x4>
    8000392c:	cbd1                	beqz	a5,800039c0 <balloc+0xb6>
    8000392e:	8baa                	mv	s7,a0
    80003930:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003932:	0001cb17          	auipc	s6,0x1c
    80003936:	696b0b13          	addi	s6,s6,1686 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000393a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000393c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000393e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003940:	6c89                	lui	s9,0x2
    80003942:	a831                	j	8000395e <balloc+0x54>
    brelse(bp);
    80003944:	854a                	mv	a0,s2
    80003946:	00000097          	auipc	ra,0x0
    8000394a:	e32080e7          	jalr	-462(ra) # 80003778 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000394e:	015c87bb          	addw	a5,s9,s5
    80003952:	00078a9b          	sext.w	s5,a5
    80003956:	004b2703          	lw	a4,4(s6)
    8000395a:	06eaf363          	bgeu	s5,a4,800039c0 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000395e:	41fad79b          	sraiw	a5,s5,0x1f
    80003962:	0137d79b          	srliw	a5,a5,0x13
    80003966:	015787bb          	addw	a5,a5,s5
    8000396a:	40d7d79b          	sraiw	a5,a5,0xd
    8000396e:	01cb2583          	lw	a1,28(s6)
    80003972:	9dbd                	addw	a1,a1,a5
    80003974:	855e                	mv	a0,s7
    80003976:	00000097          	auipc	ra,0x0
    8000397a:	cd2080e7          	jalr	-814(ra) # 80003648 <bread>
    8000397e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003980:	004b2503          	lw	a0,4(s6)
    80003984:	000a849b          	sext.w	s1,s5
    80003988:	8662                	mv	a2,s8
    8000398a:	faa4fde3          	bgeu	s1,a0,80003944 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000398e:	41f6579b          	sraiw	a5,a2,0x1f
    80003992:	01d7d69b          	srliw	a3,a5,0x1d
    80003996:	00c6873b          	addw	a4,a3,a2
    8000399a:	00777793          	andi	a5,a4,7
    8000399e:	9f95                	subw	a5,a5,a3
    800039a0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800039a4:	4037571b          	sraiw	a4,a4,0x3
    800039a8:	00e906b3          	add	a3,s2,a4
    800039ac:	0586c683          	lbu	a3,88(a3)
    800039b0:	00d7f5b3          	and	a1,a5,a3
    800039b4:	cd91                	beqz	a1,800039d0 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039b6:	2605                	addiw	a2,a2,1
    800039b8:	2485                	addiw	s1,s1,1
    800039ba:	fd4618e3          	bne	a2,s4,8000398a <balloc+0x80>
    800039be:	b759                	j	80003944 <balloc+0x3a>
  panic("balloc: out of blocks");
    800039c0:	00005517          	auipc	a0,0x5
    800039c4:	cd050513          	addi	a0,a0,-816 # 80008690 <syscalls+0x118>
    800039c8:	ffffd097          	auipc	ra,0xffffd
    800039cc:	b78080e7          	jalr	-1160(ra) # 80000540 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800039d0:	974a                	add	a4,a4,s2
    800039d2:	8fd5                	or	a5,a5,a3
    800039d4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800039d8:	854a                	mv	a0,s2
    800039da:	00001097          	auipc	ra,0x1
    800039de:	01a080e7          	jalr	26(ra) # 800049f4 <log_write>
        brelse(bp);
    800039e2:	854a                	mv	a0,s2
    800039e4:	00000097          	auipc	ra,0x0
    800039e8:	d94080e7          	jalr	-620(ra) # 80003778 <brelse>
  bp = bread(dev, bno);
    800039ec:	85a6                	mv	a1,s1
    800039ee:	855e                	mv	a0,s7
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	c58080e7          	jalr	-936(ra) # 80003648 <bread>
    800039f8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800039fa:	40000613          	li	a2,1024
    800039fe:	4581                	li	a1,0
    80003a00:	05850513          	addi	a0,a0,88
    80003a04:	ffffd097          	auipc	ra,0xffffd
    80003a08:	2de080e7          	jalr	734(ra) # 80000ce2 <memset>
  log_write(bp);
    80003a0c:	854a                	mv	a0,s2
    80003a0e:	00001097          	auipc	ra,0x1
    80003a12:	fe6080e7          	jalr	-26(ra) # 800049f4 <log_write>
  brelse(bp);
    80003a16:	854a                	mv	a0,s2
    80003a18:	00000097          	auipc	ra,0x0
    80003a1c:	d60080e7          	jalr	-672(ra) # 80003778 <brelse>
}
    80003a20:	8526                	mv	a0,s1
    80003a22:	60e6                	ld	ra,88(sp)
    80003a24:	6446                	ld	s0,80(sp)
    80003a26:	64a6                	ld	s1,72(sp)
    80003a28:	6906                	ld	s2,64(sp)
    80003a2a:	79e2                	ld	s3,56(sp)
    80003a2c:	7a42                	ld	s4,48(sp)
    80003a2e:	7aa2                	ld	s5,40(sp)
    80003a30:	7b02                	ld	s6,32(sp)
    80003a32:	6be2                	ld	s7,24(sp)
    80003a34:	6c42                	ld	s8,16(sp)
    80003a36:	6ca2                	ld	s9,8(sp)
    80003a38:	6125                	addi	sp,sp,96
    80003a3a:	8082                	ret

0000000080003a3c <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003a3c:	7179                	addi	sp,sp,-48
    80003a3e:	f406                	sd	ra,40(sp)
    80003a40:	f022                	sd	s0,32(sp)
    80003a42:	ec26                	sd	s1,24(sp)
    80003a44:	e84a                	sd	s2,16(sp)
    80003a46:	e44e                	sd	s3,8(sp)
    80003a48:	e052                	sd	s4,0(sp)
    80003a4a:	1800                	addi	s0,sp,48
    80003a4c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003a4e:	47ad                	li	a5,11
    80003a50:	04b7fe63          	bgeu	a5,a1,80003aac <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003a54:	ff45849b          	addiw	s1,a1,-12
    80003a58:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a5c:	0ff00793          	li	a5,255
    80003a60:	0ae7e363          	bltu	a5,a4,80003b06 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003a64:	08052583          	lw	a1,128(a0)
    80003a68:	c5ad                	beqz	a1,80003ad2 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003a6a:	00092503          	lw	a0,0(s2)
    80003a6e:	00000097          	auipc	ra,0x0
    80003a72:	bda080e7          	jalr	-1062(ra) # 80003648 <bread>
    80003a76:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a78:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a7c:	02049593          	slli	a1,s1,0x20
    80003a80:	9181                	srli	a1,a1,0x20
    80003a82:	058a                	slli	a1,a1,0x2
    80003a84:	00b784b3          	add	s1,a5,a1
    80003a88:	0004a983          	lw	s3,0(s1)
    80003a8c:	04098d63          	beqz	s3,80003ae6 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003a90:	8552                	mv	a0,s4
    80003a92:	00000097          	auipc	ra,0x0
    80003a96:	ce6080e7          	jalr	-794(ra) # 80003778 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a9a:	854e                	mv	a0,s3
    80003a9c:	70a2                	ld	ra,40(sp)
    80003a9e:	7402                	ld	s0,32(sp)
    80003aa0:	64e2                	ld	s1,24(sp)
    80003aa2:	6942                	ld	s2,16(sp)
    80003aa4:	69a2                	ld	s3,8(sp)
    80003aa6:	6a02                	ld	s4,0(sp)
    80003aa8:	6145                	addi	sp,sp,48
    80003aaa:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003aac:	02059493          	slli	s1,a1,0x20
    80003ab0:	9081                	srli	s1,s1,0x20
    80003ab2:	048a                	slli	s1,s1,0x2
    80003ab4:	94aa                	add	s1,s1,a0
    80003ab6:	0504a983          	lw	s3,80(s1)
    80003aba:	fe0990e3          	bnez	s3,80003a9a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003abe:	4108                	lw	a0,0(a0)
    80003ac0:	00000097          	auipc	ra,0x0
    80003ac4:	e4a080e7          	jalr	-438(ra) # 8000390a <balloc>
    80003ac8:	0005099b          	sext.w	s3,a0
    80003acc:	0534a823          	sw	s3,80(s1)
    80003ad0:	b7e9                	j	80003a9a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003ad2:	4108                	lw	a0,0(a0)
    80003ad4:	00000097          	auipc	ra,0x0
    80003ad8:	e36080e7          	jalr	-458(ra) # 8000390a <balloc>
    80003adc:	0005059b          	sext.w	a1,a0
    80003ae0:	08b92023          	sw	a1,128(s2)
    80003ae4:	b759                	j	80003a6a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003ae6:	00092503          	lw	a0,0(s2)
    80003aea:	00000097          	auipc	ra,0x0
    80003aee:	e20080e7          	jalr	-480(ra) # 8000390a <balloc>
    80003af2:	0005099b          	sext.w	s3,a0
    80003af6:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003afa:	8552                	mv	a0,s4
    80003afc:	00001097          	auipc	ra,0x1
    80003b00:	ef8080e7          	jalr	-264(ra) # 800049f4 <log_write>
    80003b04:	b771                	j	80003a90 <bmap+0x54>
  panic("bmap: out of range");
    80003b06:	00005517          	auipc	a0,0x5
    80003b0a:	ba250513          	addi	a0,a0,-1118 # 800086a8 <syscalls+0x130>
    80003b0e:	ffffd097          	auipc	ra,0xffffd
    80003b12:	a32080e7          	jalr	-1486(ra) # 80000540 <panic>

0000000080003b16 <iget>:
{
    80003b16:	7179                	addi	sp,sp,-48
    80003b18:	f406                	sd	ra,40(sp)
    80003b1a:	f022                	sd	s0,32(sp)
    80003b1c:	ec26                	sd	s1,24(sp)
    80003b1e:	e84a                	sd	s2,16(sp)
    80003b20:	e44e                	sd	s3,8(sp)
    80003b22:	e052                	sd	s4,0(sp)
    80003b24:	1800                	addi	s0,sp,48
    80003b26:	89aa                	mv	s3,a0
    80003b28:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003b2a:	0001c517          	auipc	a0,0x1c
    80003b2e:	4be50513          	addi	a0,a0,1214 # 8001ffe8 <itable>
    80003b32:	ffffd097          	auipc	ra,0xffffd
    80003b36:	0b4080e7          	jalr	180(ra) # 80000be6 <acquire>
  empty = 0;
    80003b3a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b3c:	0001c497          	auipc	s1,0x1c
    80003b40:	4c448493          	addi	s1,s1,1220 # 80020000 <itable+0x18>
    80003b44:	0001e697          	auipc	a3,0x1e
    80003b48:	f4c68693          	addi	a3,a3,-180 # 80021a90 <log>
    80003b4c:	a039                	j	80003b5a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b4e:	02090b63          	beqz	s2,80003b84 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003b52:	08848493          	addi	s1,s1,136
    80003b56:	02d48a63          	beq	s1,a3,80003b8a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003b5a:	449c                	lw	a5,8(s1)
    80003b5c:	fef059e3          	blez	a5,80003b4e <iget+0x38>
    80003b60:	4098                	lw	a4,0(s1)
    80003b62:	ff3716e3          	bne	a4,s3,80003b4e <iget+0x38>
    80003b66:	40d8                	lw	a4,4(s1)
    80003b68:	ff4713e3          	bne	a4,s4,80003b4e <iget+0x38>
      ip->ref++;
    80003b6c:	2785                	addiw	a5,a5,1
    80003b6e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b70:	0001c517          	auipc	a0,0x1c
    80003b74:	47850513          	addi	a0,a0,1144 # 8001ffe8 <itable>
    80003b78:	ffffd097          	auipc	ra,0xffffd
    80003b7c:	122080e7          	jalr	290(ra) # 80000c9a <release>
      return ip;
    80003b80:	8926                	mv	s2,s1
    80003b82:	a03d                	j	80003bb0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b84:	f7f9                	bnez	a5,80003b52 <iget+0x3c>
    80003b86:	8926                	mv	s2,s1
    80003b88:	b7e9                	j	80003b52 <iget+0x3c>
  if(empty == 0)
    80003b8a:	02090c63          	beqz	s2,80003bc2 <iget+0xac>
  ip->dev = dev;
    80003b8e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b92:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b96:	4785                	li	a5,1
    80003b98:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b9c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003ba0:	0001c517          	auipc	a0,0x1c
    80003ba4:	44850513          	addi	a0,a0,1096 # 8001ffe8 <itable>
    80003ba8:	ffffd097          	auipc	ra,0xffffd
    80003bac:	0f2080e7          	jalr	242(ra) # 80000c9a <release>
}
    80003bb0:	854a                	mv	a0,s2
    80003bb2:	70a2                	ld	ra,40(sp)
    80003bb4:	7402                	ld	s0,32(sp)
    80003bb6:	64e2                	ld	s1,24(sp)
    80003bb8:	6942                	ld	s2,16(sp)
    80003bba:	69a2                	ld	s3,8(sp)
    80003bbc:	6a02                	ld	s4,0(sp)
    80003bbe:	6145                	addi	sp,sp,48
    80003bc0:	8082                	ret
    panic("iget: no inodes");
    80003bc2:	00005517          	auipc	a0,0x5
    80003bc6:	afe50513          	addi	a0,a0,-1282 # 800086c0 <syscalls+0x148>
    80003bca:	ffffd097          	auipc	ra,0xffffd
    80003bce:	976080e7          	jalr	-1674(ra) # 80000540 <panic>

0000000080003bd2 <fsinit>:
fsinit(int dev) {
    80003bd2:	7179                	addi	sp,sp,-48
    80003bd4:	f406                	sd	ra,40(sp)
    80003bd6:	f022                	sd	s0,32(sp)
    80003bd8:	ec26                	sd	s1,24(sp)
    80003bda:	e84a                	sd	s2,16(sp)
    80003bdc:	e44e                	sd	s3,8(sp)
    80003bde:	1800                	addi	s0,sp,48
    80003be0:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003be2:	4585                	li	a1,1
    80003be4:	00000097          	auipc	ra,0x0
    80003be8:	a64080e7          	jalr	-1436(ra) # 80003648 <bread>
    80003bec:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003bee:	0001c997          	auipc	s3,0x1c
    80003bf2:	3da98993          	addi	s3,s3,986 # 8001ffc8 <sb>
    80003bf6:	02000613          	li	a2,32
    80003bfa:	05850593          	addi	a1,a0,88
    80003bfe:	854e                	mv	a0,s3
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	142080e7          	jalr	322(ra) # 80000d42 <memmove>
  brelse(bp);
    80003c08:	8526                	mv	a0,s1
    80003c0a:	00000097          	auipc	ra,0x0
    80003c0e:	b6e080e7          	jalr	-1170(ra) # 80003778 <brelse>
  if(sb.magic != FSMAGIC)
    80003c12:	0009a703          	lw	a4,0(s3)
    80003c16:	102037b7          	lui	a5,0x10203
    80003c1a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003c1e:	02f71263          	bne	a4,a5,80003c42 <fsinit+0x70>
  initlog(dev, &sb);
    80003c22:	0001c597          	auipc	a1,0x1c
    80003c26:	3a658593          	addi	a1,a1,934 # 8001ffc8 <sb>
    80003c2a:	854a                	mv	a0,s2
    80003c2c:	00001097          	auipc	ra,0x1
    80003c30:	b4c080e7          	jalr	-1204(ra) # 80004778 <initlog>
}
    80003c34:	70a2                	ld	ra,40(sp)
    80003c36:	7402                	ld	s0,32(sp)
    80003c38:	64e2                	ld	s1,24(sp)
    80003c3a:	6942                	ld	s2,16(sp)
    80003c3c:	69a2                	ld	s3,8(sp)
    80003c3e:	6145                	addi	sp,sp,48
    80003c40:	8082                	ret
    panic("invalid file system");
    80003c42:	00005517          	auipc	a0,0x5
    80003c46:	a8e50513          	addi	a0,a0,-1394 # 800086d0 <syscalls+0x158>
    80003c4a:	ffffd097          	auipc	ra,0xffffd
    80003c4e:	8f6080e7          	jalr	-1802(ra) # 80000540 <panic>

0000000080003c52 <iinit>:
{
    80003c52:	7179                	addi	sp,sp,-48
    80003c54:	f406                	sd	ra,40(sp)
    80003c56:	f022                	sd	s0,32(sp)
    80003c58:	ec26                	sd	s1,24(sp)
    80003c5a:	e84a                	sd	s2,16(sp)
    80003c5c:	e44e                	sd	s3,8(sp)
    80003c5e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c60:	00005597          	auipc	a1,0x5
    80003c64:	a8858593          	addi	a1,a1,-1400 # 800086e8 <syscalls+0x170>
    80003c68:	0001c517          	auipc	a0,0x1c
    80003c6c:	38050513          	addi	a0,a0,896 # 8001ffe8 <itable>
    80003c70:	ffffd097          	auipc	ra,0xffffd
    80003c74:	ee6080e7          	jalr	-282(ra) # 80000b56 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c78:	0001c497          	auipc	s1,0x1c
    80003c7c:	39848493          	addi	s1,s1,920 # 80020010 <itable+0x28>
    80003c80:	0001e997          	auipc	s3,0x1e
    80003c84:	e2098993          	addi	s3,s3,-480 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c88:	00005917          	auipc	s2,0x5
    80003c8c:	a6890913          	addi	s2,s2,-1432 # 800086f0 <syscalls+0x178>
    80003c90:	85ca                	mv	a1,s2
    80003c92:	8526                	mv	a0,s1
    80003c94:	00001097          	auipc	ra,0x1
    80003c98:	e46080e7          	jalr	-442(ra) # 80004ada <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c9c:	08848493          	addi	s1,s1,136
    80003ca0:	ff3498e3          	bne	s1,s3,80003c90 <iinit+0x3e>
}
    80003ca4:	70a2                	ld	ra,40(sp)
    80003ca6:	7402                	ld	s0,32(sp)
    80003ca8:	64e2                	ld	s1,24(sp)
    80003caa:	6942                	ld	s2,16(sp)
    80003cac:	69a2                	ld	s3,8(sp)
    80003cae:	6145                	addi	sp,sp,48
    80003cb0:	8082                	ret

0000000080003cb2 <ialloc>:
{
    80003cb2:	715d                	addi	sp,sp,-80
    80003cb4:	e486                	sd	ra,72(sp)
    80003cb6:	e0a2                	sd	s0,64(sp)
    80003cb8:	fc26                	sd	s1,56(sp)
    80003cba:	f84a                	sd	s2,48(sp)
    80003cbc:	f44e                	sd	s3,40(sp)
    80003cbe:	f052                	sd	s4,32(sp)
    80003cc0:	ec56                	sd	s5,24(sp)
    80003cc2:	e85a                	sd	s6,16(sp)
    80003cc4:	e45e                	sd	s7,8(sp)
    80003cc6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cc8:	0001c717          	auipc	a4,0x1c
    80003ccc:	30c72703          	lw	a4,780(a4) # 8001ffd4 <sb+0xc>
    80003cd0:	4785                	li	a5,1
    80003cd2:	04e7fa63          	bgeu	a5,a4,80003d26 <ialloc+0x74>
    80003cd6:	8aaa                	mv	s5,a0
    80003cd8:	8bae                	mv	s7,a1
    80003cda:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003cdc:	0001ca17          	auipc	s4,0x1c
    80003ce0:	2eca0a13          	addi	s4,s4,748 # 8001ffc8 <sb>
    80003ce4:	00048b1b          	sext.w	s6,s1
    80003ce8:	0044d593          	srli	a1,s1,0x4
    80003cec:	018a2783          	lw	a5,24(s4)
    80003cf0:	9dbd                	addw	a1,a1,a5
    80003cf2:	8556                	mv	a0,s5
    80003cf4:	00000097          	auipc	ra,0x0
    80003cf8:	954080e7          	jalr	-1708(ra) # 80003648 <bread>
    80003cfc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003cfe:	05850993          	addi	s3,a0,88
    80003d02:	00f4f793          	andi	a5,s1,15
    80003d06:	079a                	slli	a5,a5,0x6
    80003d08:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003d0a:	00099783          	lh	a5,0(s3)
    80003d0e:	c785                	beqz	a5,80003d36 <ialloc+0x84>
    brelse(bp);
    80003d10:	00000097          	auipc	ra,0x0
    80003d14:	a68080e7          	jalr	-1432(ra) # 80003778 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003d18:	0485                	addi	s1,s1,1
    80003d1a:	00ca2703          	lw	a4,12(s4)
    80003d1e:	0004879b          	sext.w	a5,s1
    80003d22:	fce7e1e3          	bltu	a5,a4,80003ce4 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003d26:	00005517          	auipc	a0,0x5
    80003d2a:	9d250513          	addi	a0,a0,-1582 # 800086f8 <syscalls+0x180>
    80003d2e:	ffffd097          	auipc	ra,0xffffd
    80003d32:	812080e7          	jalr	-2030(ra) # 80000540 <panic>
      memset(dip, 0, sizeof(*dip));
    80003d36:	04000613          	li	a2,64
    80003d3a:	4581                	li	a1,0
    80003d3c:	854e                	mv	a0,s3
    80003d3e:	ffffd097          	auipc	ra,0xffffd
    80003d42:	fa4080e7          	jalr	-92(ra) # 80000ce2 <memset>
      dip->type = type;
    80003d46:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003d4a:	854a                	mv	a0,s2
    80003d4c:	00001097          	auipc	ra,0x1
    80003d50:	ca8080e7          	jalr	-856(ra) # 800049f4 <log_write>
      brelse(bp);
    80003d54:	854a                	mv	a0,s2
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	a22080e7          	jalr	-1502(ra) # 80003778 <brelse>
      return iget(dev, inum);
    80003d5e:	85da                	mv	a1,s6
    80003d60:	8556                	mv	a0,s5
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	db4080e7          	jalr	-588(ra) # 80003b16 <iget>
}
    80003d6a:	60a6                	ld	ra,72(sp)
    80003d6c:	6406                	ld	s0,64(sp)
    80003d6e:	74e2                	ld	s1,56(sp)
    80003d70:	7942                	ld	s2,48(sp)
    80003d72:	79a2                	ld	s3,40(sp)
    80003d74:	7a02                	ld	s4,32(sp)
    80003d76:	6ae2                	ld	s5,24(sp)
    80003d78:	6b42                	ld	s6,16(sp)
    80003d7a:	6ba2                	ld	s7,8(sp)
    80003d7c:	6161                	addi	sp,sp,80
    80003d7e:	8082                	ret

0000000080003d80 <iupdate>:
{
    80003d80:	1101                	addi	sp,sp,-32
    80003d82:	ec06                	sd	ra,24(sp)
    80003d84:	e822                	sd	s0,16(sp)
    80003d86:	e426                	sd	s1,8(sp)
    80003d88:	e04a                	sd	s2,0(sp)
    80003d8a:	1000                	addi	s0,sp,32
    80003d8c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d8e:	415c                	lw	a5,4(a0)
    80003d90:	0047d79b          	srliw	a5,a5,0x4
    80003d94:	0001c597          	auipc	a1,0x1c
    80003d98:	24c5a583          	lw	a1,588(a1) # 8001ffe0 <sb+0x18>
    80003d9c:	9dbd                	addw	a1,a1,a5
    80003d9e:	4108                	lw	a0,0(a0)
    80003da0:	00000097          	auipc	ra,0x0
    80003da4:	8a8080e7          	jalr	-1880(ra) # 80003648 <bread>
    80003da8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003daa:	05850793          	addi	a5,a0,88
    80003dae:	40c8                	lw	a0,4(s1)
    80003db0:	893d                	andi	a0,a0,15
    80003db2:	051a                	slli	a0,a0,0x6
    80003db4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003db6:	04449703          	lh	a4,68(s1)
    80003dba:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003dbe:	04649703          	lh	a4,70(s1)
    80003dc2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003dc6:	04849703          	lh	a4,72(s1)
    80003dca:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003dce:	04a49703          	lh	a4,74(s1)
    80003dd2:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003dd6:	44f8                	lw	a4,76(s1)
    80003dd8:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003dda:	03400613          	li	a2,52
    80003dde:	05048593          	addi	a1,s1,80
    80003de2:	0531                	addi	a0,a0,12
    80003de4:	ffffd097          	auipc	ra,0xffffd
    80003de8:	f5e080e7          	jalr	-162(ra) # 80000d42 <memmove>
  log_write(bp);
    80003dec:	854a                	mv	a0,s2
    80003dee:	00001097          	auipc	ra,0x1
    80003df2:	c06080e7          	jalr	-1018(ra) # 800049f4 <log_write>
  brelse(bp);
    80003df6:	854a                	mv	a0,s2
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	980080e7          	jalr	-1664(ra) # 80003778 <brelse>
}
    80003e00:	60e2                	ld	ra,24(sp)
    80003e02:	6442                	ld	s0,16(sp)
    80003e04:	64a2                	ld	s1,8(sp)
    80003e06:	6902                	ld	s2,0(sp)
    80003e08:	6105                	addi	sp,sp,32
    80003e0a:	8082                	ret

0000000080003e0c <idup>:
{
    80003e0c:	1101                	addi	sp,sp,-32
    80003e0e:	ec06                	sd	ra,24(sp)
    80003e10:	e822                	sd	s0,16(sp)
    80003e12:	e426                	sd	s1,8(sp)
    80003e14:	1000                	addi	s0,sp,32
    80003e16:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e18:	0001c517          	auipc	a0,0x1c
    80003e1c:	1d050513          	addi	a0,a0,464 # 8001ffe8 <itable>
    80003e20:	ffffd097          	auipc	ra,0xffffd
    80003e24:	dc6080e7          	jalr	-570(ra) # 80000be6 <acquire>
  ip->ref++;
    80003e28:	449c                	lw	a5,8(s1)
    80003e2a:	2785                	addiw	a5,a5,1
    80003e2c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e2e:	0001c517          	auipc	a0,0x1c
    80003e32:	1ba50513          	addi	a0,a0,442 # 8001ffe8 <itable>
    80003e36:	ffffd097          	auipc	ra,0xffffd
    80003e3a:	e64080e7          	jalr	-412(ra) # 80000c9a <release>
}
    80003e3e:	8526                	mv	a0,s1
    80003e40:	60e2                	ld	ra,24(sp)
    80003e42:	6442                	ld	s0,16(sp)
    80003e44:	64a2                	ld	s1,8(sp)
    80003e46:	6105                	addi	sp,sp,32
    80003e48:	8082                	ret

0000000080003e4a <ilock>:
{
    80003e4a:	1101                	addi	sp,sp,-32
    80003e4c:	ec06                	sd	ra,24(sp)
    80003e4e:	e822                	sd	s0,16(sp)
    80003e50:	e426                	sd	s1,8(sp)
    80003e52:	e04a                	sd	s2,0(sp)
    80003e54:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003e56:	c115                	beqz	a0,80003e7a <ilock+0x30>
    80003e58:	84aa                	mv	s1,a0
    80003e5a:	451c                	lw	a5,8(a0)
    80003e5c:	00f05f63          	blez	a5,80003e7a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e60:	0541                	addi	a0,a0,16
    80003e62:	00001097          	auipc	ra,0x1
    80003e66:	cb2080e7          	jalr	-846(ra) # 80004b14 <acquiresleep>
  if(ip->valid == 0){
    80003e6a:	40bc                	lw	a5,64(s1)
    80003e6c:	cf99                	beqz	a5,80003e8a <ilock+0x40>
}
    80003e6e:	60e2                	ld	ra,24(sp)
    80003e70:	6442                	ld	s0,16(sp)
    80003e72:	64a2                	ld	s1,8(sp)
    80003e74:	6902                	ld	s2,0(sp)
    80003e76:	6105                	addi	sp,sp,32
    80003e78:	8082                	ret
    panic("ilock");
    80003e7a:	00005517          	auipc	a0,0x5
    80003e7e:	89650513          	addi	a0,a0,-1898 # 80008710 <syscalls+0x198>
    80003e82:	ffffc097          	auipc	ra,0xffffc
    80003e86:	6be080e7          	jalr	1726(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e8a:	40dc                	lw	a5,4(s1)
    80003e8c:	0047d79b          	srliw	a5,a5,0x4
    80003e90:	0001c597          	auipc	a1,0x1c
    80003e94:	1505a583          	lw	a1,336(a1) # 8001ffe0 <sb+0x18>
    80003e98:	9dbd                	addw	a1,a1,a5
    80003e9a:	4088                	lw	a0,0(s1)
    80003e9c:	fffff097          	auipc	ra,0xfffff
    80003ea0:	7ac080e7          	jalr	1964(ra) # 80003648 <bread>
    80003ea4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ea6:	05850593          	addi	a1,a0,88
    80003eaa:	40dc                	lw	a5,4(s1)
    80003eac:	8bbd                	andi	a5,a5,15
    80003eae:	079a                	slli	a5,a5,0x6
    80003eb0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003eb2:	00059783          	lh	a5,0(a1)
    80003eb6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003eba:	00259783          	lh	a5,2(a1)
    80003ebe:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003ec2:	00459783          	lh	a5,4(a1)
    80003ec6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003eca:	00659783          	lh	a5,6(a1)
    80003ece:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ed2:	459c                	lw	a5,8(a1)
    80003ed4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ed6:	03400613          	li	a2,52
    80003eda:	05b1                	addi	a1,a1,12
    80003edc:	05048513          	addi	a0,s1,80
    80003ee0:	ffffd097          	auipc	ra,0xffffd
    80003ee4:	e62080e7          	jalr	-414(ra) # 80000d42 <memmove>
    brelse(bp);
    80003ee8:	854a                	mv	a0,s2
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	88e080e7          	jalr	-1906(ra) # 80003778 <brelse>
    ip->valid = 1;
    80003ef2:	4785                	li	a5,1
    80003ef4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ef6:	04449783          	lh	a5,68(s1)
    80003efa:	fbb5                	bnez	a5,80003e6e <ilock+0x24>
      panic("ilock: no type");
    80003efc:	00005517          	auipc	a0,0x5
    80003f00:	81c50513          	addi	a0,a0,-2020 # 80008718 <syscalls+0x1a0>
    80003f04:	ffffc097          	auipc	ra,0xffffc
    80003f08:	63c080e7          	jalr	1596(ra) # 80000540 <panic>

0000000080003f0c <iunlock>:
{
    80003f0c:	1101                	addi	sp,sp,-32
    80003f0e:	ec06                	sd	ra,24(sp)
    80003f10:	e822                	sd	s0,16(sp)
    80003f12:	e426                	sd	s1,8(sp)
    80003f14:	e04a                	sd	s2,0(sp)
    80003f16:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003f18:	c905                	beqz	a0,80003f48 <iunlock+0x3c>
    80003f1a:	84aa                	mv	s1,a0
    80003f1c:	01050913          	addi	s2,a0,16
    80003f20:	854a                	mv	a0,s2
    80003f22:	00001097          	auipc	ra,0x1
    80003f26:	c8c080e7          	jalr	-884(ra) # 80004bae <holdingsleep>
    80003f2a:	cd19                	beqz	a0,80003f48 <iunlock+0x3c>
    80003f2c:	449c                	lw	a5,8(s1)
    80003f2e:	00f05d63          	blez	a5,80003f48 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003f32:	854a                	mv	a0,s2
    80003f34:	00001097          	auipc	ra,0x1
    80003f38:	c36080e7          	jalr	-970(ra) # 80004b6a <releasesleep>
}
    80003f3c:	60e2                	ld	ra,24(sp)
    80003f3e:	6442                	ld	s0,16(sp)
    80003f40:	64a2                	ld	s1,8(sp)
    80003f42:	6902                	ld	s2,0(sp)
    80003f44:	6105                	addi	sp,sp,32
    80003f46:	8082                	ret
    panic("iunlock");
    80003f48:	00004517          	auipc	a0,0x4
    80003f4c:	7e050513          	addi	a0,a0,2016 # 80008728 <syscalls+0x1b0>
    80003f50:	ffffc097          	auipc	ra,0xffffc
    80003f54:	5f0080e7          	jalr	1520(ra) # 80000540 <panic>

0000000080003f58 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003f58:	7179                	addi	sp,sp,-48
    80003f5a:	f406                	sd	ra,40(sp)
    80003f5c:	f022                	sd	s0,32(sp)
    80003f5e:	ec26                	sd	s1,24(sp)
    80003f60:	e84a                	sd	s2,16(sp)
    80003f62:	e44e                	sd	s3,8(sp)
    80003f64:	e052                	sd	s4,0(sp)
    80003f66:	1800                	addi	s0,sp,48
    80003f68:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f6a:	05050493          	addi	s1,a0,80
    80003f6e:	08050913          	addi	s2,a0,128
    80003f72:	a021                	j	80003f7a <itrunc+0x22>
    80003f74:	0491                	addi	s1,s1,4
    80003f76:	01248d63          	beq	s1,s2,80003f90 <itrunc+0x38>
    if(ip->addrs[i]){
    80003f7a:	408c                	lw	a1,0(s1)
    80003f7c:	dde5                	beqz	a1,80003f74 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f7e:	0009a503          	lw	a0,0(s3)
    80003f82:	00000097          	auipc	ra,0x0
    80003f86:	90c080e7          	jalr	-1780(ra) # 8000388e <bfree>
      ip->addrs[i] = 0;
    80003f8a:	0004a023          	sw	zero,0(s1)
    80003f8e:	b7dd                	j	80003f74 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f90:	0809a583          	lw	a1,128(s3)
    80003f94:	e185                	bnez	a1,80003fb4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f96:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f9a:	854e                	mv	a0,s3
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	de4080e7          	jalr	-540(ra) # 80003d80 <iupdate>
}
    80003fa4:	70a2                	ld	ra,40(sp)
    80003fa6:	7402                	ld	s0,32(sp)
    80003fa8:	64e2                	ld	s1,24(sp)
    80003faa:	6942                	ld	s2,16(sp)
    80003fac:	69a2                	ld	s3,8(sp)
    80003fae:	6a02                	ld	s4,0(sp)
    80003fb0:	6145                	addi	sp,sp,48
    80003fb2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003fb4:	0009a503          	lw	a0,0(s3)
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	690080e7          	jalr	1680(ra) # 80003648 <bread>
    80003fc0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003fc2:	05850493          	addi	s1,a0,88
    80003fc6:	45850913          	addi	s2,a0,1112
    80003fca:	a811                	j	80003fde <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003fcc:	0009a503          	lw	a0,0(s3)
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	8be080e7          	jalr	-1858(ra) # 8000388e <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003fd8:	0491                	addi	s1,s1,4
    80003fda:	01248563          	beq	s1,s2,80003fe4 <itrunc+0x8c>
      if(a[j])
    80003fde:	408c                	lw	a1,0(s1)
    80003fe0:	dde5                	beqz	a1,80003fd8 <itrunc+0x80>
    80003fe2:	b7ed                	j	80003fcc <itrunc+0x74>
    brelse(bp);
    80003fe4:	8552                	mv	a0,s4
    80003fe6:	fffff097          	auipc	ra,0xfffff
    80003fea:	792080e7          	jalr	1938(ra) # 80003778 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003fee:	0809a583          	lw	a1,128(s3)
    80003ff2:	0009a503          	lw	a0,0(s3)
    80003ff6:	00000097          	auipc	ra,0x0
    80003ffa:	898080e7          	jalr	-1896(ra) # 8000388e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ffe:	0809a023          	sw	zero,128(s3)
    80004002:	bf51                	j	80003f96 <itrunc+0x3e>

0000000080004004 <iput>:
{
    80004004:	1101                	addi	sp,sp,-32
    80004006:	ec06                	sd	ra,24(sp)
    80004008:	e822                	sd	s0,16(sp)
    8000400a:	e426                	sd	s1,8(sp)
    8000400c:	e04a                	sd	s2,0(sp)
    8000400e:	1000                	addi	s0,sp,32
    80004010:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004012:	0001c517          	auipc	a0,0x1c
    80004016:	fd650513          	addi	a0,a0,-42 # 8001ffe8 <itable>
    8000401a:	ffffd097          	auipc	ra,0xffffd
    8000401e:	bcc080e7          	jalr	-1076(ra) # 80000be6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004022:	4498                	lw	a4,8(s1)
    80004024:	4785                	li	a5,1
    80004026:	02f70363          	beq	a4,a5,8000404c <iput+0x48>
  ip->ref--;
    8000402a:	449c                	lw	a5,8(s1)
    8000402c:	37fd                	addiw	a5,a5,-1
    8000402e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004030:	0001c517          	auipc	a0,0x1c
    80004034:	fb850513          	addi	a0,a0,-72 # 8001ffe8 <itable>
    80004038:	ffffd097          	auipc	ra,0xffffd
    8000403c:	c62080e7          	jalr	-926(ra) # 80000c9a <release>
}
    80004040:	60e2                	ld	ra,24(sp)
    80004042:	6442                	ld	s0,16(sp)
    80004044:	64a2                	ld	s1,8(sp)
    80004046:	6902                	ld	s2,0(sp)
    80004048:	6105                	addi	sp,sp,32
    8000404a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000404c:	40bc                	lw	a5,64(s1)
    8000404e:	dff1                	beqz	a5,8000402a <iput+0x26>
    80004050:	04a49783          	lh	a5,74(s1)
    80004054:	fbf9                	bnez	a5,8000402a <iput+0x26>
    acquiresleep(&ip->lock);
    80004056:	01048913          	addi	s2,s1,16
    8000405a:	854a                	mv	a0,s2
    8000405c:	00001097          	auipc	ra,0x1
    80004060:	ab8080e7          	jalr	-1352(ra) # 80004b14 <acquiresleep>
    release(&itable.lock);
    80004064:	0001c517          	auipc	a0,0x1c
    80004068:	f8450513          	addi	a0,a0,-124 # 8001ffe8 <itable>
    8000406c:	ffffd097          	auipc	ra,0xffffd
    80004070:	c2e080e7          	jalr	-978(ra) # 80000c9a <release>
    itrunc(ip);
    80004074:	8526                	mv	a0,s1
    80004076:	00000097          	auipc	ra,0x0
    8000407a:	ee2080e7          	jalr	-286(ra) # 80003f58 <itrunc>
    ip->type = 0;
    8000407e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004082:	8526                	mv	a0,s1
    80004084:	00000097          	auipc	ra,0x0
    80004088:	cfc080e7          	jalr	-772(ra) # 80003d80 <iupdate>
    ip->valid = 0;
    8000408c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004090:	854a                	mv	a0,s2
    80004092:	00001097          	auipc	ra,0x1
    80004096:	ad8080e7          	jalr	-1320(ra) # 80004b6a <releasesleep>
    acquire(&itable.lock);
    8000409a:	0001c517          	auipc	a0,0x1c
    8000409e:	f4e50513          	addi	a0,a0,-178 # 8001ffe8 <itable>
    800040a2:	ffffd097          	auipc	ra,0xffffd
    800040a6:	b44080e7          	jalr	-1212(ra) # 80000be6 <acquire>
    800040aa:	b741                	j	8000402a <iput+0x26>

00000000800040ac <iunlockput>:
{
    800040ac:	1101                	addi	sp,sp,-32
    800040ae:	ec06                	sd	ra,24(sp)
    800040b0:	e822                	sd	s0,16(sp)
    800040b2:	e426                	sd	s1,8(sp)
    800040b4:	1000                	addi	s0,sp,32
    800040b6:	84aa                	mv	s1,a0
  iunlock(ip);
    800040b8:	00000097          	auipc	ra,0x0
    800040bc:	e54080e7          	jalr	-428(ra) # 80003f0c <iunlock>
  iput(ip);
    800040c0:	8526                	mv	a0,s1
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	f42080e7          	jalr	-190(ra) # 80004004 <iput>
}
    800040ca:	60e2                	ld	ra,24(sp)
    800040cc:	6442                	ld	s0,16(sp)
    800040ce:	64a2                	ld	s1,8(sp)
    800040d0:	6105                	addi	sp,sp,32
    800040d2:	8082                	ret

00000000800040d4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800040d4:	1141                	addi	sp,sp,-16
    800040d6:	e422                	sd	s0,8(sp)
    800040d8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800040da:	411c                	lw	a5,0(a0)
    800040dc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800040de:	415c                	lw	a5,4(a0)
    800040e0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800040e2:	04451783          	lh	a5,68(a0)
    800040e6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800040ea:	04a51783          	lh	a5,74(a0)
    800040ee:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800040f2:	04c56783          	lwu	a5,76(a0)
    800040f6:	e99c                	sd	a5,16(a1)
}
    800040f8:	6422                	ld	s0,8(sp)
    800040fa:	0141                	addi	sp,sp,16
    800040fc:	8082                	ret

00000000800040fe <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040fe:	457c                	lw	a5,76(a0)
    80004100:	0ed7e963          	bltu	a5,a3,800041f2 <readi+0xf4>
{
    80004104:	7159                	addi	sp,sp,-112
    80004106:	f486                	sd	ra,104(sp)
    80004108:	f0a2                	sd	s0,96(sp)
    8000410a:	eca6                	sd	s1,88(sp)
    8000410c:	e8ca                	sd	s2,80(sp)
    8000410e:	e4ce                	sd	s3,72(sp)
    80004110:	e0d2                	sd	s4,64(sp)
    80004112:	fc56                	sd	s5,56(sp)
    80004114:	f85a                	sd	s6,48(sp)
    80004116:	f45e                	sd	s7,40(sp)
    80004118:	f062                	sd	s8,32(sp)
    8000411a:	ec66                	sd	s9,24(sp)
    8000411c:	e86a                	sd	s10,16(sp)
    8000411e:	e46e                	sd	s11,8(sp)
    80004120:	1880                	addi	s0,sp,112
    80004122:	8baa                	mv	s7,a0
    80004124:	8c2e                	mv	s8,a1
    80004126:	8ab2                	mv	s5,a2
    80004128:	84b6                	mv	s1,a3
    8000412a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000412c:	9f35                	addw	a4,a4,a3
    return 0;
    8000412e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004130:	0ad76063          	bltu	a4,a3,800041d0 <readi+0xd2>
  if(off + n > ip->size)
    80004134:	00e7f463          	bgeu	a5,a4,8000413c <readi+0x3e>
    n = ip->size - off;
    80004138:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000413c:	0a0b0963          	beqz	s6,800041ee <readi+0xf0>
    80004140:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004142:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004146:	5cfd                	li	s9,-1
    80004148:	a82d                	j	80004182 <readi+0x84>
    8000414a:	020a1d93          	slli	s11,s4,0x20
    8000414e:	020ddd93          	srli	s11,s11,0x20
    80004152:	05890613          	addi	a2,s2,88
    80004156:	86ee                	mv	a3,s11
    80004158:	963a                	add	a2,a2,a4
    8000415a:	85d6                	mv	a1,s5
    8000415c:	8562                	mv	a0,s8
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	850080e7          	jalr	-1968(ra) # 800029ae <either_copyout>
    80004166:	05950d63          	beq	a0,s9,800041c0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000416a:	854a                	mv	a0,s2
    8000416c:	fffff097          	auipc	ra,0xfffff
    80004170:	60c080e7          	jalr	1548(ra) # 80003778 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004174:	013a09bb          	addw	s3,s4,s3
    80004178:	009a04bb          	addw	s1,s4,s1
    8000417c:	9aee                	add	s5,s5,s11
    8000417e:	0569f763          	bgeu	s3,s6,800041cc <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004182:	000ba903          	lw	s2,0(s7)
    80004186:	00a4d59b          	srliw	a1,s1,0xa
    8000418a:	855e                	mv	a0,s7
    8000418c:	00000097          	auipc	ra,0x0
    80004190:	8b0080e7          	jalr	-1872(ra) # 80003a3c <bmap>
    80004194:	0005059b          	sext.w	a1,a0
    80004198:	854a                	mv	a0,s2
    8000419a:	fffff097          	auipc	ra,0xfffff
    8000419e:	4ae080e7          	jalr	1198(ra) # 80003648 <bread>
    800041a2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800041a4:	3ff4f713          	andi	a4,s1,1023
    800041a8:	40ed07bb          	subw	a5,s10,a4
    800041ac:	413b06bb          	subw	a3,s6,s3
    800041b0:	8a3e                	mv	s4,a5
    800041b2:	2781                	sext.w	a5,a5
    800041b4:	0006861b          	sext.w	a2,a3
    800041b8:	f8f679e3          	bgeu	a2,a5,8000414a <readi+0x4c>
    800041bc:	8a36                	mv	s4,a3
    800041be:	b771                	j	8000414a <readi+0x4c>
      brelse(bp);
    800041c0:	854a                	mv	a0,s2
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	5b6080e7          	jalr	1462(ra) # 80003778 <brelse>
      tot = -1;
    800041ca:	59fd                	li	s3,-1
  }
  return tot;
    800041cc:	0009851b          	sext.w	a0,s3
}
    800041d0:	70a6                	ld	ra,104(sp)
    800041d2:	7406                	ld	s0,96(sp)
    800041d4:	64e6                	ld	s1,88(sp)
    800041d6:	6946                	ld	s2,80(sp)
    800041d8:	69a6                	ld	s3,72(sp)
    800041da:	6a06                	ld	s4,64(sp)
    800041dc:	7ae2                	ld	s5,56(sp)
    800041de:	7b42                	ld	s6,48(sp)
    800041e0:	7ba2                	ld	s7,40(sp)
    800041e2:	7c02                	ld	s8,32(sp)
    800041e4:	6ce2                	ld	s9,24(sp)
    800041e6:	6d42                	ld	s10,16(sp)
    800041e8:	6da2                	ld	s11,8(sp)
    800041ea:	6165                	addi	sp,sp,112
    800041ec:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800041ee:	89da                	mv	s3,s6
    800041f0:	bff1                	j	800041cc <readi+0xce>
    return 0;
    800041f2:	4501                	li	a0,0
}
    800041f4:	8082                	ret

00000000800041f6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800041f6:	457c                	lw	a5,76(a0)
    800041f8:	10d7e863          	bltu	a5,a3,80004308 <writei+0x112>
{
    800041fc:	7159                	addi	sp,sp,-112
    800041fe:	f486                	sd	ra,104(sp)
    80004200:	f0a2                	sd	s0,96(sp)
    80004202:	eca6                	sd	s1,88(sp)
    80004204:	e8ca                	sd	s2,80(sp)
    80004206:	e4ce                	sd	s3,72(sp)
    80004208:	e0d2                	sd	s4,64(sp)
    8000420a:	fc56                	sd	s5,56(sp)
    8000420c:	f85a                	sd	s6,48(sp)
    8000420e:	f45e                	sd	s7,40(sp)
    80004210:	f062                	sd	s8,32(sp)
    80004212:	ec66                	sd	s9,24(sp)
    80004214:	e86a                	sd	s10,16(sp)
    80004216:	e46e                	sd	s11,8(sp)
    80004218:	1880                	addi	s0,sp,112
    8000421a:	8b2a                	mv	s6,a0
    8000421c:	8c2e                	mv	s8,a1
    8000421e:	8ab2                	mv	s5,a2
    80004220:	8936                	mv	s2,a3
    80004222:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004224:	00e687bb          	addw	a5,a3,a4
    80004228:	0ed7e263          	bltu	a5,a3,8000430c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000422c:	00043737          	lui	a4,0x43
    80004230:	0ef76063          	bltu	a4,a5,80004310 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004234:	0c0b8863          	beqz	s7,80004304 <writei+0x10e>
    80004238:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000423a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000423e:	5cfd                	li	s9,-1
    80004240:	a091                	j	80004284 <writei+0x8e>
    80004242:	02099d93          	slli	s11,s3,0x20
    80004246:	020ddd93          	srli	s11,s11,0x20
    8000424a:	05848513          	addi	a0,s1,88
    8000424e:	86ee                	mv	a3,s11
    80004250:	8656                	mv	a2,s5
    80004252:	85e2                	mv	a1,s8
    80004254:	953a                	add	a0,a0,a4
    80004256:	ffffe097          	auipc	ra,0xffffe
    8000425a:	7ae080e7          	jalr	1966(ra) # 80002a04 <either_copyin>
    8000425e:	07950263          	beq	a0,s9,800042c2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004262:	8526                	mv	a0,s1
    80004264:	00000097          	auipc	ra,0x0
    80004268:	790080e7          	jalr	1936(ra) # 800049f4 <log_write>
    brelse(bp);
    8000426c:	8526                	mv	a0,s1
    8000426e:	fffff097          	auipc	ra,0xfffff
    80004272:	50a080e7          	jalr	1290(ra) # 80003778 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004276:	01498a3b          	addw	s4,s3,s4
    8000427a:	0129893b          	addw	s2,s3,s2
    8000427e:	9aee                	add	s5,s5,s11
    80004280:	057a7663          	bgeu	s4,s7,800042cc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004284:	000b2483          	lw	s1,0(s6)
    80004288:	00a9559b          	srliw	a1,s2,0xa
    8000428c:	855a                	mv	a0,s6
    8000428e:	fffff097          	auipc	ra,0xfffff
    80004292:	7ae080e7          	jalr	1966(ra) # 80003a3c <bmap>
    80004296:	0005059b          	sext.w	a1,a0
    8000429a:	8526                	mv	a0,s1
    8000429c:	fffff097          	auipc	ra,0xfffff
    800042a0:	3ac080e7          	jalr	940(ra) # 80003648 <bread>
    800042a4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800042a6:	3ff97713          	andi	a4,s2,1023
    800042aa:	40ed07bb          	subw	a5,s10,a4
    800042ae:	414b86bb          	subw	a3,s7,s4
    800042b2:	89be                	mv	s3,a5
    800042b4:	2781                	sext.w	a5,a5
    800042b6:	0006861b          	sext.w	a2,a3
    800042ba:	f8f674e3          	bgeu	a2,a5,80004242 <writei+0x4c>
    800042be:	89b6                	mv	s3,a3
    800042c0:	b749                	j	80004242 <writei+0x4c>
      brelse(bp);
    800042c2:	8526                	mv	a0,s1
    800042c4:	fffff097          	auipc	ra,0xfffff
    800042c8:	4b4080e7          	jalr	1204(ra) # 80003778 <brelse>
  }

  if(off > ip->size)
    800042cc:	04cb2783          	lw	a5,76(s6)
    800042d0:	0127f463          	bgeu	a5,s2,800042d8 <writei+0xe2>
    ip->size = off;
    800042d4:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800042d8:	855a                	mv	a0,s6
    800042da:	00000097          	auipc	ra,0x0
    800042de:	aa6080e7          	jalr	-1370(ra) # 80003d80 <iupdate>

  return tot;
    800042e2:	000a051b          	sext.w	a0,s4
}
    800042e6:	70a6                	ld	ra,104(sp)
    800042e8:	7406                	ld	s0,96(sp)
    800042ea:	64e6                	ld	s1,88(sp)
    800042ec:	6946                	ld	s2,80(sp)
    800042ee:	69a6                	ld	s3,72(sp)
    800042f0:	6a06                	ld	s4,64(sp)
    800042f2:	7ae2                	ld	s5,56(sp)
    800042f4:	7b42                	ld	s6,48(sp)
    800042f6:	7ba2                	ld	s7,40(sp)
    800042f8:	7c02                	ld	s8,32(sp)
    800042fa:	6ce2                	ld	s9,24(sp)
    800042fc:	6d42                	ld	s10,16(sp)
    800042fe:	6da2                	ld	s11,8(sp)
    80004300:	6165                	addi	sp,sp,112
    80004302:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004304:	8a5e                	mv	s4,s7
    80004306:	bfc9                	j	800042d8 <writei+0xe2>
    return -1;
    80004308:	557d                	li	a0,-1
}
    8000430a:	8082                	ret
    return -1;
    8000430c:	557d                	li	a0,-1
    8000430e:	bfe1                	j	800042e6 <writei+0xf0>
    return -1;
    80004310:	557d                	li	a0,-1
    80004312:	bfd1                	j	800042e6 <writei+0xf0>

0000000080004314 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004314:	1141                	addi	sp,sp,-16
    80004316:	e406                	sd	ra,8(sp)
    80004318:	e022                	sd	s0,0(sp)
    8000431a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000431c:	4639                	li	a2,14
    8000431e:	ffffd097          	auipc	ra,0xffffd
    80004322:	a9c080e7          	jalr	-1380(ra) # 80000dba <strncmp>
}
    80004326:	60a2                	ld	ra,8(sp)
    80004328:	6402                	ld	s0,0(sp)
    8000432a:	0141                	addi	sp,sp,16
    8000432c:	8082                	ret

000000008000432e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000432e:	7139                	addi	sp,sp,-64
    80004330:	fc06                	sd	ra,56(sp)
    80004332:	f822                	sd	s0,48(sp)
    80004334:	f426                	sd	s1,40(sp)
    80004336:	f04a                	sd	s2,32(sp)
    80004338:	ec4e                	sd	s3,24(sp)
    8000433a:	e852                	sd	s4,16(sp)
    8000433c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000433e:	04451703          	lh	a4,68(a0)
    80004342:	4785                	li	a5,1
    80004344:	00f71a63          	bne	a4,a5,80004358 <dirlookup+0x2a>
    80004348:	892a                	mv	s2,a0
    8000434a:	89ae                	mv	s3,a1
    8000434c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000434e:	457c                	lw	a5,76(a0)
    80004350:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004352:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004354:	e79d                	bnez	a5,80004382 <dirlookup+0x54>
    80004356:	a8a5                	j	800043ce <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004358:	00004517          	auipc	a0,0x4
    8000435c:	3d850513          	addi	a0,a0,984 # 80008730 <syscalls+0x1b8>
    80004360:	ffffc097          	auipc	ra,0xffffc
    80004364:	1e0080e7          	jalr	480(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004368:	00004517          	auipc	a0,0x4
    8000436c:	3e050513          	addi	a0,a0,992 # 80008748 <syscalls+0x1d0>
    80004370:	ffffc097          	auipc	ra,0xffffc
    80004374:	1d0080e7          	jalr	464(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004378:	24c1                	addiw	s1,s1,16
    8000437a:	04c92783          	lw	a5,76(s2)
    8000437e:	04f4f763          	bgeu	s1,a5,800043cc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004382:	4741                	li	a4,16
    80004384:	86a6                	mv	a3,s1
    80004386:	fc040613          	addi	a2,s0,-64
    8000438a:	4581                	li	a1,0
    8000438c:	854a                	mv	a0,s2
    8000438e:	00000097          	auipc	ra,0x0
    80004392:	d70080e7          	jalr	-656(ra) # 800040fe <readi>
    80004396:	47c1                	li	a5,16
    80004398:	fcf518e3          	bne	a0,a5,80004368 <dirlookup+0x3a>
    if(de.inum == 0)
    8000439c:	fc045783          	lhu	a5,-64(s0)
    800043a0:	dfe1                	beqz	a5,80004378 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800043a2:	fc240593          	addi	a1,s0,-62
    800043a6:	854e                	mv	a0,s3
    800043a8:	00000097          	auipc	ra,0x0
    800043ac:	f6c080e7          	jalr	-148(ra) # 80004314 <namecmp>
    800043b0:	f561                	bnez	a0,80004378 <dirlookup+0x4a>
      if(poff)
    800043b2:	000a0463          	beqz	s4,800043ba <dirlookup+0x8c>
        *poff = off;
    800043b6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800043ba:	fc045583          	lhu	a1,-64(s0)
    800043be:	00092503          	lw	a0,0(s2)
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	754080e7          	jalr	1876(ra) # 80003b16 <iget>
    800043ca:	a011                	j	800043ce <dirlookup+0xa0>
  return 0;
    800043cc:	4501                	li	a0,0
}
    800043ce:	70e2                	ld	ra,56(sp)
    800043d0:	7442                	ld	s0,48(sp)
    800043d2:	74a2                	ld	s1,40(sp)
    800043d4:	7902                	ld	s2,32(sp)
    800043d6:	69e2                	ld	s3,24(sp)
    800043d8:	6a42                	ld	s4,16(sp)
    800043da:	6121                	addi	sp,sp,64
    800043dc:	8082                	ret

00000000800043de <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800043de:	711d                	addi	sp,sp,-96
    800043e0:	ec86                	sd	ra,88(sp)
    800043e2:	e8a2                	sd	s0,80(sp)
    800043e4:	e4a6                	sd	s1,72(sp)
    800043e6:	e0ca                	sd	s2,64(sp)
    800043e8:	fc4e                	sd	s3,56(sp)
    800043ea:	f852                	sd	s4,48(sp)
    800043ec:	f456                	sd	s5,40(sp)
    800043ee:	f05a                	sd	s6,32(sp)
    800043f0:	ec5e                	sd	s7,24(sp)
    800043f2:	e862                	sd	s8,16(sp)
    800043f4:	e466                	sd	s9,8(sp)
    800043f6:	1080                	addi	s0,sp,96
    800043f8:	84aa                	mv	s1,a0
    800043fa:	8b2e                	mv	s6,a1
    800043fc:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800043fe:	00054703          	lbu	a4,0(a0)
    80004402:	02f00793          	li	a5,47
    80004406:	02f70363          	beq	a4,a5,8000442c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	610080e7          	jalr	1552(ra) # 80001a1a <myproc>
    80004412:	15053503          	ld	a0,336(a0)
    80004416:	00000097          	auipc	ra,0x0
    8000441a:	9f6080e7          	jalr	-1546(ra) # 80003e0c <idup>
    8000441e:	89aa                	mv	s3,a0
  while(*path == '/')
    80004420:	02f00913          	li	s2,47
  len = path - s;
    80004424:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80004426:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004428:	4c05                	li	s8,1
    8000442a:	a865                	j	800044e2 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000442c:	4585                	li	a1,1
    8000442e:	4505                	li	a0,1
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	6e6080e7          	jalr	1766(ra) # 80003b16 <iget>
    80004438:	89aa                	mv	s3,a0
    8000443a:	b7dd                	j	80004420 <namex+0x42>
      iunlockput(ip);
    8000443c:	854e                	mv	a0,s3
    8000443e:	00000097          	auipc	ra,0x0
    80004442:	c6e080e7          	jalr	-914(ra) # 800040ac <iunlockput>
      return 0;
    80004446:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004448:	854e                	mv	a0,s3
    8000444a:	60e6                	ld	ra,88(sp)
    8000444c:	6446                	ld	s0,80(sp)
    8000444e:	64a6                	ld	s1,72(sp)
    80004450:	6906                	ld	s2,64(sp)
    80004452:	79e2                	ld	s3,56(sp)
    80004454:	7a42                	ld	s4,48(sp)
    80004456:	7aa2                	ld	s5,40(sp)
    80004458:	7b02                	ld	s6,32(sp)
    8000445a:	6be2                	ld	s7,24(sp)
    8000445c:	6c42                	ld	s8,16(sp)
    8000445e:	6ca2                	ld	s9,8(sp)
    80004460:	6125                	addi	sp,sp,96
    80004462:	8082                	ret
      iunlock(ip);
    80004464:	854e                	mv	a0,s3
    80004466:	00000097          	auipc	ra,0x0
    8000446a:	aa6080e7          	jalr	-1370(ra) # 80003f0c <iunlock>
      return ip;
    8000446e:	bfe9                	j	80004448 <namex+0x6a>
      iunlockput(ip);
    80004470:	854e                	mv	a0,s3
    80004472:	00000097          	auipc	ra,0x0
    80004476:	c3a080e7          	jalr	-966(ra) # 800040ac <iunlockput>
      return 0;
    8000447a:	89d2                	mv	s3,s4
    8000447c:	b7f1                	j	80004448 <namex+0x6a>
  len = path - s;
    8000447e:	40b48633          	sub	a2,s1,a1
    80004482:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004486:	094cd463          	bge	s9,s4,8000450e <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000448a:	4639                	li	a2,14
    8000448c:	8556                	mv	a0,s5
    8000448e:	ffffd097          	auipc	ra,0xffffd
    80004492:	8b4080e7          	jalr	-1868(ra) # 80000d42 <memmove>
  while(*path == '/')
    80004496:	0004c783          	lbu	a5,0(s1)
    8000449a:	01279763          	bne	a5,s2,800044a8 <namex+0xca>
    path++;
    8000449e:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044a0:	0004c783          	lbu	a5,0(s1)
    800044a4:	ff278de3          	beq	a5,s2,8000449e <namex+0xc0>
    ilock(ip);
    800044a8:	854e                	mv	a0,s3
    800044aa:	00000097          	auipc	ra,0x0
    800044ae:	9a0080e7          	jalr	-1632(ra) # 80003e4a <ilock>
    if(ip->type != T_DIR){
    800044b2:	04499783          	lh	a5,68(s3)
    800044b6:	f98793e3          	bne	a5,s8,8000443c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800044ba:	000b0563          	beqz	s6,800044c4 <namex+0xe6>
    800044be:	0004c783          	lbu	a5,0(s1)
    800044c2:	d3cd                	beqz	a5,80004464 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800044c4:	865e                	mv	a2,s7
    800044c6:	85d6                	mv	a1,s5
    800044c8:	854e                	mv	a0,s3
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	e64080e7          	jalr	-412(ra) # 8000432e <dirlookup>
    800044d2:	8a2a                	mv	s4,a0
    800044d4:	dd51                	beqz	a0,80004470 <namex+0x92>
    iunlockput(ip);
    800044d6:	854e                	mv	a0,s3
    800044d8:	00000097          	auipc	ra,0x0
    800044dc:	bd4080e7          	jalr	-1068(ra) # 800040ac <iunlockput>
    ip = next;
    800044e0:	89d2                	mv	s3,s4
  while(*path == '/')
    800044e2:	0004c783          	lbu	a5,0(s1)
    800044e6:	05279763          	bne	a5,s2,80004534 <namex+0x156>
    path++;
    800044ea:	0485                	addi	s1,s1,1
  while(*path == '/')
    800044ec:	0004c783          	lbu	a5,0(s1)
    800044f0:	ff278de3          	beq	a5,s2,800044ea <namex+0x10c>
  if(*path == 0)
    800044f4:	c79d                	beqz	a5,80004522 <namex+0x144>
    path++;
    800044f6:	85a6                	mv	a1,s1
  len = path - s;
    800044f8:	8a5e                	mv	s4,s7
    800044fa:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800044fc:	01278963          	beq	a5,s2,8000450e <namex+0x130>
    80004500:	dfbd                	beqz	a5,8000447e <namex+0xa0>
    path++;
    80004502:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004504:	0004c783          	lbu	a5,0(s1)
    80004508:	ff279ce3          	bne	a5,s2,80004500 <namex+0x122>
    8000450c:	bf8d                	j	8000447e <namex+0xa0>
    memmove(name, s, len);
    8000450e:	2601                	sext.w	a2,a2
    80004510:	8556                	mv	a0,s5
    80004512:	ffffd097          	auipc	ra,0xffffd
    80004516:	830080e7          	jalr	-2000(ra) # 80000d42 <memmove>
    name[len] = 0;
    8000451a:	9a56                	add	s4,s4,s5
    8000451c:	000a0023          	sb	zero,0(s4)
    80004520:	bf9d                	j	80004496 <namex+0xb8>
  if(nameiparent){
    80004522:	f20b03e3          	beqz	s6,80004448 <namex+0x6a>
    iput(ip);
    80004526:	854e                	mv	a0,s3
    80004528:	00000097          	auipc	ra,0x0
    8000452c:	adc080e7          	jalr	-1316(ra) # 80004004 <iput>
    return 0;
    80004530:	4981                	li	s3,0
    80004532:	bf19                	j	80004448 <namex+0x6a>
  if(*path == 0)
    80004534:	d7fd                	beqz	a5,80004522 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004536:	0004c783          	lbu	a5,0(s1)
    8000453a:	85a6                	mv	a1,s1
    8000453c:	b7d1                	j	80004500 <namex+0x122>

000000008000453e <dirlink>:
{
    8000453e:	7139                	addi	sp,sp,-64
    80004540:	fc06                	sd	ra,56(sp)
    80004542:	f822                	sd	s0,48(sp)
    80004544:	f426                	sd	s1,40(sp)
    80004546:	f04a                	sd	s2,32(sp)
    80004548:	ec4e                	sd	s3,24(sp)
    8000454a:	e852                	sd	s4,16(sp)
    8000454c:	0080                	addi	s0,sp,64
    8000454e:	892a                	mv	s2,a0
    80004550:	8a2e                	mv	s4,a1
    80004552:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004554:	4601                	li	a2,0
    80004556:	00000097          	auipc	ra,0x0
    8000455a:	dd8080e7          	jalr	-552(ra) # 8000432e <dirlookup>
    8000455e:	e93d                	bnez	a0,800045d4 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004560:	04c92483          	lw	s1,76(s2)
    80004564:	c49d                	beqz	s1,80004592 <dirlink+0x54>
    80004566:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004568:	4741                	li	a4,16
    8000456a:	86a6                	mv	a3,s1
    8000456c:	fc040613          	addi	a2,s0,-64
    80004570:	4581                	li	a1,0
    80004572:	854a                	mv	a0,s2
    80004574:	00000097          	auipc	ra,0x0
    80004578:	b8a080e7          	jalr	-1142(ra) # 800040fe <readi>
    8000457c:	47c1                	li	a5,16
    8000457e:	06f51163          	bne	a0,a5,800045e0 <dirlink+0xa2>
    if(de.inum == 0)
    80004582:	fc045783          	lhu	a5,-64(s0)
    80004586:	c791                	beqz	a5,80004592 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004588:	24c1                	addiw	s1,s1,16
    8000458a:	04c92783          	lw	a5,76(s2)
    8000458e:	fcf4ede3          	bltu	s1,a5,80004568 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004592:	4639                	li	a2,14
    80004594:	85d2                	mv	a1,s4
    80004596:	fc240513          	addi	a0,s0,-62
    8000459a:	ffffd097          	auipc	ra,0xffffd
    8000459e:	85c080e7          	jalr	-1956(ra) # 80000df6 <strncpy>
  de.inum = inum;
    800045a2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045a6:	4741                	li	a4,16
    800045a8:	86a6                	mv	a3,s1
    800045aa:	fc040613          	addi	a2,s0,-64
    800045ae:	4581                	li	a1,0
    800045b0:	854a                	mv	a0,s2
    800045b2:	00000097          	auipc	ra,0x0
    800045b6:	c44080e7          	jalr	-956(ra) # 800041f6 <writei>
    800045ba:	872a                	mv	a4,a0
    800045bc:	47c1                	li	a5,16
  return 0;
    800045be:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800045c0:	02f71863          	bne	a4,a5,800045f0 <dirlink+0xb2>
}
    800045c4:	70e2                	ld	ra,56(sp)
    800045c6:	7442                	ld	s0,48(sp)
    800045c8:	74a2                	ld	s1,40(sp)
    800045ca:	7902                	ld	s2,32(sp)
    800045cc:	69e2                	ld	s3,24(sp)
    800045ce:	6a42                	ld	s4,16(sp)
    800045d0:	6121                	addi	sp,sp,64
    800045d2:	8082                	ret
    iput(ip);
    800045d4:	00000097          	auipc	ra,0x0
    800045d8:	a30080e7          	jalr	-1488(ra) # 80004004 <iput>
    return -1;
    800045dc:	557d                	li	a0,-1
    800045de:	b7dd                	j	800045c4 <dirlink+0x86>
      panic("dirlink read");
    800045e0:	00004517          	auipc	a0,0x4
    800045e4:	17850513          	addi	a0,a0,376 # 80008758 <syscalls+0x1e0>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	f58080e7          	jalr	-168(ra) # 80000540 <panic>
    panic("dirlink");
    800045f0:	00004517          	auipc	a0,0x4
    800045f4:	27850513          	addi	a0,a0,632 # 80008868 <syscalls+0x2f0>
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	f48080e7          	jalr	-184(ra) # 80000540 <panic>

0000000080004600 <namei>:

struct inode*
namei(char *path)
{
    80004600:	1101                	addi	sp,sp,-32
    80004602:	ec06                	sd	ra,24(sp)
    80004604:	e822                	sd	s0,16(sp)
    80004606:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004608:	fe040613          	addi	a2,s0,-32
    8000460c:	4581                	li	a1,0
    8000460e:	00000097          	auipc	ra,0x0
    80004612:	dd0080e7          	jalr	-560(ra) # 800043de <namex>
}
    80004616:	60e2                	ld	ra,24(sp)
    80004618:	6442                	ld	s0,16(sp)
    8000461a:	6105                	addi	sp,sp,32
    8000461c:	8082                	ret

000000008000461e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000461e:	1141                	addi	sp,sp,-16
    80004620:	e406                	sd	ra,8(sp)
    80004622:	e022                	sd	s0,0(sp)
    80004624:	0800                	addi	s0,sp,16
    80004626:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004628:	4585                	li	a1,1
    8000462a:	00000097          	auipc	ra,0x0
    8000462e:	db4080e7          	jalr	-588(ra) # 800043de <namex>
}
    80004632:	60a2                	ld	ra,8(sp)
    80004634:	6402                	ld	s0,0(sp)
    80004636:	0141                	addi	sp,sp,16
    80004638:	8082                	ret

000000008000463a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000463a:	1101                	addi	sp,sp,-32
    8000463c:	ec06                	sd	ra,24(sp)
    8000463e:	e822                	sd	s0,16(sp)
    80004640:	e426                	sd	s1,8(sp)
    80004642:	e04a                	sd	s2,0(sp)
    80004644:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004646:	0001d917          	auipc	s2,0x1d
    8000464a:	44a90913          	addi	s2,s2,1098 # 80021a90 <log>
    8000464e:	01892583          	lw	a1,24(s2)
    80004652:	02892503          	lw	a0,40(s2)
    80004656:	fffff097          	auipc	ra,0xfffff
    8000465a:	ff2080e7          	jalr	-14(ra) # 80003648 <bread>
    8000465e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004660:	02c92683          	lw	a3,44(s2)
    80004664:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004666:	02d05763          	blez	a3,80004694 <write_head+0x5a>
    8000466a:	0001d797          	auipc	a5,0x1d
    8000466e:	45678793          	addi	a5,a5,1110 # 80021ac0 <log+0x30>
    80004672:	05c50713          	addi	a4,a0,92
    80004676:	36fd                	addiw	a3,a3,-1
    80004678:	1682                	slli	a3,a3,0x20
    8000467a:	9281                	srli	a3,a3,0x20
    8000467c:	068a                	slli	a3,a3,0x2
    8000467e:	0001d617          	auipc	a2,0x1d
    80004682:	44660613          	addi	a2,a2,1094 # 80021ac4 <log+0x34>
    80004686:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004688:	4390                	lw	a2,0(a5)
    8000468a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000468c:	0791                	addi	a5,a5,4
    8000468e:	0711                	addi	a4,a4,4
    80004690:	fed79ce3          	bne	a5,a3,80004688 <write_head+0x4e>
  }
  bwrite(buf);
    80004694:	8526                	mv	a0,s1
    80004696:	fffff097          	auipc	ra,0xfffff
    8000469a:	0a4080e7          	jalr	164(ra) # 8000373a <bwrite>
  brelse(buf);
    8000469e:	8526                	mv	a0,s1
    800046a0:	fffff097          	auipc	ra,0xfffff
    800046a4:	0d8080e7          	jalr	216(ra) # 80003778 <brelse>
}
    800046a8:	60e2                	ld	ra,24(sp)
    800046aa:	6442                	ld	s0,16(sp)
    800046ac:	64a2                	ld	s1,8(sp)
    800046ae:	6902                	ld	s2,0(sp)
    800046b0:	6105                	addi	sp,sp,32
    800046b2:	8082                	ret

00000000800046b4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800046b4:	0001d797          	auipc	a5,0x1d
    800046b8:	4087a783          	lw	a5,1032(a5) # 80021abc <log+0x2c>
    800046bc:	0af05d63          	blez	a5,80004776 <install_trans+0xc2>
{
    800046c0:	7139                	addi	sp,sp,-64
    800046c2:	fc06                	sd	ra,56(sp)
    800046c4:	f822                	sd	s0,48(sp)
    800046c6:	f426                	sd	s1,40(sp)
    800046c8:	f04a                	sd	s2,32(sp)
    800046ca:	ec4e                	sd	s3,24(sp)
    800046cc:	e852                	sd	s4,16(sp)
    800046ce:	e456                	sd	s5,8(sp)
    800046d0:	e05a                	sd	s6,0(sp)
    800046d2:	0080                	addi	s0,sp,64
    800046d4:	8b2a                	mv	s6,a0
    800046d6:	0001da97          	auipc	s5,0x1d
    800046da:	3eaa8a93          	addi	s5,s5,1002 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800046de:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800046e0:	0001d997          	auipc	s3,0x1d
    800046e4:	3b098993          	addi	s3,s3,944 # 80021a90 <log>
    800046e8:	a035                	j	80004714 <install_trans+0x60>
      bunpin(dbuf);
    800046ea:	8526                	mv	a0,s1
    800046ec:	fffff097          	auipc	ra,0xfffff
    800046f0:	166080e7          	jalr	358(ra) # 80003852 <bunpin>
    brelse(lbuf);
    800046f4:	854a                	mv	a0,s2
    800046f6:	fffff097          	auipc	ra,0xfffff
    800046fa:	082080e7          	jalr	130(ra) # 80003778 <brelse>
    brelse(dbuf);
    800046fe:	8526                	mv	a0,s1
    80004700:	fffff097          	auipc	ra,0xfffff
    80004704:	078080e7          	jalr	120(ra) # 80003778 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004708:	2a05                	addiw	s4,s4,1
    8000470a:	0a91                	addi	s5,s5,4
    8000470c:	02c9a783          	lw	a5,44(s3)
    80004710:	04fa5963          	bge	s4,a5,80004762 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004714:	0189a583          	lw	a1,24(s3)
    80004718:	014585bb          	addw	a1,a1,s4
    8000471c:	2585                	addiw	a1,a1,1
    8000471e:	0289a503          	lw	a0,40(s3)
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	f26080e7          	jalr	-218(ra) # 80003648 <bread>
    8000472a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000472c:	000aa583          	lw	a1,0(s5)
    80004730:	0289a503          	lw	a0,40(s3)
    80004734:	fffff097          	auipc	ra,0xfffff
    80004738:	f14080e7          	jalr	-236(ra) # 80003648 <bread>
    8000473c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000473e:	40000613          	li	a2,1024
    80004742:	05890593          	addi	a1,s2,88
    80004746:	05850513          	addi	a0,a0,88
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	5f8080e7          	jalr	1528(ra) # 80000d42 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004752:	8526                	mv	a0,s1
    80004754:	fffff097          	auipc	ra,0xfffff
    80004758:	fe6080e7          	jalr	-26(ra) # 8000373a <bwrite>
    if(recovering == 0)
    8000475c:	f80b1ce3          	bnez	s6,800046f4 <install_trans+0x40>
    80004760:	b769                	j	800046ea <install_trans+0x36>
}
    80004762:	70e2                	ld	ra,56(sp)
    80004764:	7442                	ld	s0,48(sp)
    80004766:	74a2                	ld	s1,40(sp)
    80004768:	7902                	ld	s2,32(sp)
    8000476a:	69e2                	ld	s3,24(sp)
    8000476c:	6a42                	ld	s4,16(sp)
    8000476e:	6aa2                	ld	s5,8(sp)
    80004770:	6b02                	ld	s6,0(sp)
    80004772:	6121                	addi	sp,sp,64
    80004774:	8082                	ret
    80004776:	8082                	ret

0000000080004778 <initlog>:
{
    80004778:	7179                	addi	sp,sp,-48
    8000477a:	f406                	sd	ra,40(sp)
    8000477c:	f022                	sd	s0,32(sp)
    8000477e:	ec26                	sd	s1,24(sp)
    80004780:	e84a                	sd	s2,16(sp)
    80004782:	e44e                	sd	s3,8(sp)
    80004784:	1800                	addi	s0,sp,48
    80004786:	892a                	mv	s2,a0
    80004788:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000478a:	0001d497          	auipc	s1,0x1d
    8000478e:	30648493          	addi	s1,s1,774 # 80021a90 <log>
    80004792:	00004597          	auipc	a1,0x4
    80004796:	fd658593          	addi	a1,a1,-42 # 80008768 <syscalls+0x1f0>
    8000479a:	8526                	mv	a0,s1
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	3ba080e7          	jalr	954(ra) # 80000b56 <initlock>
  log.start = sb->logstart;
    800047a4:	0149a583          	lw	a1,20(s3)
    800047a8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800047aa:	0109a783          	lw	a5,16(s3)
    800047ae:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800047b0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800047b4:	854a                	mv	a0,s2
    800047b6:	fffff097          	auipc	ra,0xfffff
    800047ba:	e92080e7          	jalr	-366(ra) # 80003648 <bread>
  log.lh.n = lh->n;
    800047be:	4d3c                	lw	a5,88(a0)
    800047c0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800047c2:	02f05563          	blez	a5,800047ec <initlog+0x74>
    800047c6:	05c50713          	addi	a4,a0,92
    800047ca:	0001d697          	auipc	a3,0x1d
    800047ce:	2f668693          	addi	a3,a3,758 # 80021ac0 <log+0x30>
    800047d2:	37fd                	addiw	a5,a5,-1
    800047d4:	1782                	slli	a5,a5,0x20
    800047d6:	9381                	srli	a5,a5,0x20
    800047d8:	078a                	slli	a5,a5,0x2
    800047da:	06050613          	addi	a2,a0,96
    800047de:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800047e0:	4310                	lw	a2,0(a4)
    800047e2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800047e4:	0711                	addi	a4,a4,4
    800047e6:	0691                	addi	a3,a3,4
    800047e8:	fef71ce3          	bne	a4,a5,800047e0 <initlog+0x68>
  brelse(buf);
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	f8c080e7          	jalr	-116(ra) # 80003778 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800047f4:	4505                	li	a0,1
    800047f6:	00000097          	auipc	ra,0x0
    800047fa:	ebe080e7          	jalr	-322(ra) # 800046b4 <install_trans>
  log.lh.n = 0;
    800047fe:	0001d797          	auipc	a5,0x1d
    80004802:	2a07af23          	sw	zero,702(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    80004806:	00000097          	auipc	ra,0x0
    8000480a:	e34080e7          	jalr	-460(ra) # 8000463a <write_head>
}
    8000480e:	70a2                	ld	ra,40(sp)
    80004810:	7402                	ld	s0,32(sp)
    80004812:	64e2                	ld	s1,24(sp)
    80004814:	6942                	ld	s2,16(sp)
    80004816:	69a2                	ld	s3,8(sp)
    80004818:	6145                	addi	sp,sp,48
    8000481a:	8082                	ret

000000008000481c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000481c:	1101                	addi	sp,sp,-32
    8000481e:	ec06                	sd	ra,24(sp)
    80004820:	e822                	sd	s0,16(sp)
    80004822:	e426                	sd	s1,8(sp)
    80004824:	e04a                	sd	s2,0(sp)
    80004826:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004828:	0001d517          	auipc	a0,0x1d
    8000482c:	26850513          	addi	a0,a0,616 # 80021a90 <log>
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	3b6080e7          	jalr	950(ra) # 80000be6 <acquire>
  while(1){
    if(log.committing){
    80004838:	0001d497          	auipc	s1,0x1d
    8000483c:	25848493          	addi	s1,s1,600 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004840:	4979                	li	s2,30
    80004842:	a039                	j	80004850 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004844:	85a6                	mv	a1,s1
    80004846:	8526                	mv	a0,s1
    80004848:	ffffe097          	auipc	ra,0xffffe
    8000484c:	b18080e7          	jalr	-1256(ra) # 80002360 <sleep>
    if(log.committing){
    80004850:	50dc                	lw	a5,36(s1)
    80004852:	fbed                	bnez	a5,80004844 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004854:	509c                	lw	a5,32(s1)
    80004856:	0017871b          	addiw	a4,a5,1
    8000485a:	0007069b          	sext.w	a3,a4
    8000485e:	0027179b          	slliw	a5,a4,0x2
    80004862:	9fb9                	addw	a5,a5,a4
    80004864:	0017979b          	slliw	a5,a5,0x1
    80004868:	54d8                	lw	a4,44(s1)
    8000486a:	9fb9                	addw	a5,a5,a4
    8000486c:	00f95963          	bge	s2,a5,8000487e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004870:	85a6                	mv	a1,s1
    80004872:	8526                	mv	a0,s1
    80004874:	ffffe097          	auipc	ra,0xffffe
    80004878:	aec080e7          	jalr	-1300(ra) # 80002360 <sleep>
    8000487c:	bfd1                	j	80004850 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000487e:	0001d517          	auipc	a0,0x1d
    80004882:	21250513          	addi	a0,a0,530 # 80021a90 <log>
    80004886:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004888:	ffffc097          	auipc	ra,0xffffc
    8000488c:	412080e7          	jalr	1042(ra) # 80000c9a <release>
      break;
    }
  }
}
    80004890:	60e2                	ld	ra,24(sp)
    80004892:	6442                	ld	s0,16(sp)
    80004894:	64a2                	ld	s1,8(sp)
    80004896:	6902                	ld	s2,0(sp)
    80004898:	6105                	addi	sp,sp,32
    8000489a:	8082                	ret

000000008000489c <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000489c:	7139                	addi	sp,sp,-64
    8000489e:	fc06                	sd	ra,56(sp)
    800048a0:	f822                	sd	s0,48(sp)
    800048a2:	f426                	sd	s1,40(sp)
    800048a4:	f04a                	sd	s2,32(sp)
    800048a6:	ec4e                	sd	s3,24(sp)
    800048a8:	e852                	sd	s4,16(sp)
    800048aa:	e456                	sd	s5,8(sp)
    800048ac:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800048ae:	0001d497          	auipc	s1,0x1d
    800048b2:	1e248493          	addi	s1,s1,482 # 80021a90 <log>
    800048b6:	8526                	mv	a0,s1
    800048b8:	ffffc097          	auipc	ra,0xffffc
    800048bc:	32e080e7          	jalr	814(ra) # 80000be6 <acquire>
  log.outstanding -= 1;
    800048c0:	509c                	lw	a5,32(s1)
    800048c2:	37fd                	addiw	a5,a5,-1
    800048c4:	0007891b          	sext.w	s2,a5
    800048c8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800048ca:	50dc                	lw	a5,36(s1)
    800048cc:	efb9                	bnez	a5,8000492a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800048ce:	06091663          	bnez	s2,8000493a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800048d2:	0001d497          	auipc	s1,0x1d
    800048d6:	1be48493          	addi	s1,s1,446 # 80021a90 <log>
    800048da:	4785                	li	a5,1
    800048dc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800048de:	8526                	mv	a0,s1
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	3ba080e7          	jalr	954(ra) # 80000c9a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800048e8:	54dc                	lw	a5,44(s1)
    800048ea:	06f04763          	bgtz	a5,80004958 <end_op+0xbc>
    acquire(&log.lock);
    800048ee:	0001d497          	auipc	s1,0x1d
    800048f2:	1a248493          	addi	s1,s1,418 # 80021a90 <log>
    800048f6:	8526                	mv	a0,s1
    800048f8:	ffffc097          	auipc	ra,0xffffc
    800048fc:	2ee080e7          	jalr	750(ra) # 80000be6 <acquire>
    log.committing = 0;
    80004900:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004904:	8526                	mv	a0,s1
    80004906:	ffffe097          	auipc	ra,0xffffe
    8000490a:	c62080e7          	jalr	-926(ra) # 80002568 <wakeup>
    release(&log.lock);
    8000490e:	8526                	mv	a0,s1
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	38a080e7          	jalr	906(ra) # 80000c9a <release>
}
    80004918:	70e2                	ld	ra,56(sp)
    8000491a:	7442                	ld	s0,48(sp)
    8000491c:	74a2                	ld	s1,40(sp)
    8000491e:	7902                	ld	s2,32(sp)
    80004920:	69e2                	ld	s3,24(sp)
    80004922:	6a42                	ld	s4,16(sp)
    80004924:	6aa2                	ld	s5,8(sp)
    80004926:	6121                	addi	sp,sp,64
    80004928:	8082                	ret
    panic("log.committing");
    8000492a:	00004517          	auipc	a0,0x4
    8000492e:	e4650513          	addi	a0,a0,-442 # 80008770 <syscalls+0x1f8>
    80004932:	ffffc097          	auipc	ra,0xffffc
    80004936:	c0e080e7          	jalr	-1010(ra) # 80000540 <panic>
    wakeup(&log);
    8000493a:	0001d497          	auipc	s1,0x1d
    8000493e:	15648493          	addi	s1,s1,342 # 80021a90 <log>
    80004942:	8526                	mv	a0,s1
    80004944:	ffffe097          	auipc	ra,0xffffe
    80004948:	c24080e7          	jalr	-988(ra) # 80002568 <wakeup>
  release(&log.lock);
    8000494c:	8526                	mv	a0,s1
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	34c080e7          	jalr	844(ra) # 80000c9a <release>
  if(do_commit){
    80004956:	b7c9                	j	80004918 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004958:	0001da97          	auipc	s5,0x1d
    8000495c:	168a8a93          	addi	s5,s5,360 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004960:	0001da17          	auipc	s4,0x1d
    80004964:	130a0a13          	addi	s4,s4,304 # 80021a90 <log>
    80004968:	018a2583          	lw	a1,24(s4)
    8000496c:	012585bb          	addw	a1,a1,s2
    80004970:	2585                	addiw	a1,a1,1
    80004972:	028a2503          	lw	a0,40(s4)
    80004976:	fffff097          	auipc	ra,0xfffff
    8000497a:	cd2080e7          	jalr	-814(ra) # 80003648 <bread>
    8000497e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004980:	000aa583          	lw	a1,0(s5)
    80004984:	028a2503          	lw	a0,40(s4)
    80004988:	fffff097          	auipc	ra,0xfffff
    8000498c:	cc0080e7          	jalr	-832(ra) # 80003648 <bread>
    80004990:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004992:	40000613          	li	a2,1024
    80004996:	05850593          	addi	a1,a0,88
    8000499a:	05848513          	addi	a0,s1,88
    8000499e:	ffffc097          	auipc	ra,0xffffc
    800049a2:	3a4080e7          	jalr	932(ra) # 80000d42 <memmove>
    bwrite(to);  // write the log
    800049a6:	8526                	mv	a0,s1
    800049a8:	fffff097          	auipc	ra,0xfffff
    800049ac:	d92080e7          	jalr	-622(ra) # 8000373a <bwrite>
    brelse(from);
    800049b0:	854e                	mv	a0,s3
    800049b2:	fffff097          	auipc	ra,0xfffff
    800049b6:	dc6080e7          	jalr	-570(ra) # 80003778 <brelse>
    brelse(to);
    800049ba:	8526                	mv	a0,s1
    800049bc:	fffff097          	auipc	ra,0xfffff
    800049c0:	dbc080e7          	jalr	-580(ra) # 80003778 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049c4:	2905                	addiw	s2,s2,1
    800049c6:	0a91                	addi	s5,s5,4
    800049c8:	02ca2783          	lw	a5,44(s4)
    800049cc:	f8f94ee3          	blt	s2,a5,80004968 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800049d0:	00000097          	auipc	ra,0x0
    800049d4:	c6a080e7          	jalr	-918(ra) # 8000463a <write_head>
    install_trans(0); // Now install writes to home locations
    800049d8:	4501                	li	a0,0
    800049da:	00000097          	auipc	ra,0x0
    800049de:	cda080e7          	jalr	-806(ra) # 800046b4 <install_trans>
    log.lh.n = 0;
    800049e2:	0001d797          	auipc	a5,0x1d
    800049e6:	0c07ad23          	sw	zero,218(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800049ea:	00000097          	auipc	ra,0x0
    800049ee:	c50080e7          	jalr	-944(ra) # 8000463a <write_head>
    800049f2:	bdf5                	j	800048ee <end_op+0x52>

00000000800049f4 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800049f4:	1101                	addi	sp,sp,-32
    800049f6:	ec06                	sd	ra,24(sp)
    800049f8:	e822                	sd	s0,16(sp)
    800049fa:	e426                	sd	s1,8(sp)
    800049fc:	e04a                	sd	s2,0(sp)
    800049fe:	1000                	addi	s0,sp,32
    80004a00:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004a02:	0001d917          	auipc	s2,0x1d
    80004a06:	08e90913          	addi	s2,s2,142 # 80021a90 <log>
    80004a0a:	854a                	mv	a0,s2
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	1da080e7          	jalr	474(ra) # 80000be6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004a14:	02c92603          	lw	a2,44(s2)
    80004a18:	47f5                	li	a5,29
    80004a1a:	06c7c563          	blt	a5,a2,80004a84 <log_write+0x90>
    80004a1e:	0001d797          	auipc	a5,0x1d
    80004a22:	08e7a783          	lw	a5,142(a5) # 80021aac <log+0x1c>
    80004a26:	37fd                	addiw	a5,a5,-1
    80004a28:	04f65e63          	bge	a2,a5,80004a84 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004a2c:	0001d797          	auipc	a5,0x1d
    80004a30:	0847a783          	lw	a5,132(a5) # 80021ab0 <log+0x20>
    80004a34:	06f05063          	blez	a5,80004a94 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004a38:	4781                	li	a5,0
    80004a3a:	06c05563          	blez	a2,80004aa4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a3e:	44cc                	lw	a1,12(s1)
    80004a40:	0001d717          	auipc	a4,0x1d
    80004a44:	08070713          	addi	a4,a4,128 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004a48:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004a4a:	4314                	lw	a3,0(a4)
    80004a4c:	04b68c63          	beq	a3,a1,80004aa4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004a50:	2785                	addiw	a5,a5,1
    80004a52:	0711                	addi	a4,a4,4
    80004a54:	fef61be3          	bne	a2,a5,80004a4a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004a58:	0621                	addi	a2,a2,8
    80004a5a:	060a                	slli	a2,a2,0x2
    80004a5c:	0001d797          	auipc	a5,0x1d
    80004a60:	03478793          	addi	a5,a5,52 # 80021a90 <log>
    80004a64:	963e                	add	a2,a2,a5
    80004a66:	44dc                	lw	a5,12(s1)
    80004a68:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004a6a:	8526                	mv	a0,s1
    80004a6c:	fffff097          	auipc	ra,0xfffff
    80004a70:	daa080e7          	jalr	-598(ra) # 80003816 <bpin>
    log.lh.n++;
    80004a74:	0001d717          	auipc	a4,0x1d
    80004a78:	01c70713          	addi	a4,a4,28 # 80021a90 <log>
    80004a7c:	575c                	lw	a5,44(a4)
    80004a7e:	2785                	addiw	a5,a5,1
    80004a80:	d75c                	sw	a5,44(a4)
    80004a82:	a835                	j	80004abe <log_write+0xca>
    panic("too big a transaction");
    80004a84:	00004517          	auipc	a0,0x4
    80004a88:	cfc50513          	addi	a0,a0,-772 # 80008780 <syscalls+0x208>
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	ab4080e7          	jalr	-1356(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004a94:	00004517          	auipc	a0,0x4
    80004a98:	d0450513          	addi	a0,a0,-764 # 80008798 <syscalls+0x220>
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	aa4080e7          	jalr	-1372(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004aa4:	00878713          	addi	a4,a5,8
    80004aa8:	00271693          	slli	a3,a4,0x2
    80004aac:	0001d717          	auipc	a4,0x1d
    80004ab0:	fe470713          	addi	a4,a4,-28 # 80021a90 <log>
    80004ab4:	9736                	add	a4,a4,a3
    80004ab6:	44d4                	lw	a3,12(s1)
    80004ab8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004aba:	faf608e3          	beq	a2,a5,80004a6a <log_write+0x76>
  }
  release(&log.lock);
    80004abe:	0001d517          	auipc	a0,0x1d
    80004ac2:	fd250513          	addi	a0,a0,-46 # 80021a90 <log>
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	1d4080e7          	jalr	468(ra) # 80000c9a <release>
}
    80004ace:	60e2                	ld	ra,24(sp)
    80004ad0:	6442                	ld	s0,16(sp)
    80004ad2:	64a2                	ld	s1,8(sp)
    80004ad4:	6902                	ld	s2,0(sp)
    80004ad6:	6105                	addi	sp,sp,32
    80004ad8:	8082                	ret

0000000080004ada <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004ada:	1101                	addi	sp,sp,-32
    80004adc:	ec06                	sd	ra,24(sp)
    80004ade:	e822                	sd	s0,16(sp)
    80004ae0:	e426                	sd	s1,8(sp)
    80004ae2:	e04a                	sd	s2,0(sp)
    80004ae4:	1000                	addi	s0,sp,32
    80004ae6:	84aa                	mv	s1,a0
    80004ae8:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004aea:	00004597          	auipc	a1,0x4
    80004aee:	cce58593          	addi	a1,a1,-818 # 800087b8 <syscalls+0x240>
    80004af2:	0521                	addi	a0,a0,8
    80004af4:	ffffc097          	auipc	ra,0xffffc
    80004af8:	062080e7          	jalr	98(ra) # 80000b56 <initlock>
  lk->name = name;
    80004afc:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004b00:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b04:	0204a423          	sw	zero,40(s1)
}
    80004b08:	60e2                	ld	ra,24(sp)
    80004b0a:	6442                	ld	s0,16(sp)
    80004b0c:	64a2                	ld	s1,8(sp)
    80004b0e:	6902                	ld	s2,0(sp)
    80004b10:	6105                	addi	sp,sp,32
    80004b12:	8082                	ret

0000000080004b14 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004b14:	1101                	addi	sp,sp,-32
    80004b16:	ec06                	sd	ra,24(sp)
    80004b18:	e822                	sd	s0,16(sp)
    80004b1a:	e426                	sd	s1,8(sp)
    80004b1c:	e04a                	sd	s2,0(sp)
    80004b1e:	1000                	addi	s0,sp,32
    80004b20:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b22:	00850913          	addi	s2,a0,8
    80004b26:	854a                	mv	a0,s2
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	0be080e7          	jalr	190(ra) # 80000be6 <acquire>
  while (lk->locked) {
    80004b30:	409c                	lw	a5,0(s1)
    80004b32:	cb89                	beqz	a5,80004b44 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004b34:	85ca                	mv	a1,s2
    80004b36:	8526                	mv	a0,s1
    80004b38:	ffffe097          	auipc	ra,0xffffe
    80004b3c:	828080e7          	jalr	-2008(ra) # 80002360 <sleep>
  while (lk->locked) {
    80004b40:	409c                	lw	a5,0(s1)
    80004b42:	fbed                	bnez	a5,80004b34 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004b44:	4785                	li	a5,1
    80004b46:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004b48:	ffffd097          	auipc	ra,0xffffd
    80004b4c:	ed2080e7          	jalr	-302(ra) # 80001a1a <myproc>
    80004b50:	591c                	lw	a5,48(a0)
    80004b52:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004b54:	854a                	mv	a0,s2
    80004b56:	ffffc097          	auipc	ra,0xffffc
    80004b5a:	144080e7          	jalr	324(ra) # 80000c9a <release>
}
    80004b5e:	60e2                	ld	ra,24(sp)
    80004b60:	6442                	ld	s0,16(sp)
    80004b62:	64a2                	ld	s1,8(sp)
    80004b64:	6902                	ld	s2,0(sp)
    80004b66:	6105                	addi	sp,sp,32
    80004b68:	8082                	ret

0000000080004b6a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004b6a:	1101                	addi	sp,sp,-32
    80004b6c:	ec06                	sd	ra,24(sp)
    80004b6e:	e822                	sd	s0,16(sp)
    80004b70:	e426                	sd	s1,8(sp)
    80004b72:	e04a                	sd	s2,0(sp)
    80004b74:	1000                	addi	s0,sp,32
    80004b76:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004b78:	00850913          	addi	s2,a0,8
    80004b7c:	854a                	mv	a0,s2
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	068080e7          	jalr	104(ra) # 80000be6 <acquire>
  lk->locked = 0;
    80004b86:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004b8a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004b8e:	8526                	mv	a0,s1
    80004b90:	ffffe097          	auipc	ra,0xffffe
    80004b94:	9d8080e7          	jalr	-1576(ra) # 80002568 <wakeup>
  release(&lk->lk);
    80004b98:	854a                	mv	a0,s2
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	100080e7          	jalr	256(ra) # 80000c9a <release>
}
    80004ba2:	60e2                	ld	ra,24(sp)
    80004ba4:	6442                	ld	s0,16(sp)
    80004ba6:	64a2                	ld	s1,8(sp)
    80004ba8:	6902                	ld	s2,0(sp)
    80004baa:	6105                	addi	sp,sp,32
    80004bac:	8082                	ret

0000000080004bae <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004bae:	7179                	addi	sp,sp,-48
    80004bb0:	f406                	sd	ra,40(sp)
    80004bb2:	f022                	sd	s0,32(sp)
    80004bb4:	ec26                	sd	s1,24(sp)
    80004bb6:	e84a                	sd	s2,16(sp)
    80004bb8:	e44e                	sd	s3,8(sp)
    80004bba:	1800                	addi	s0,sp,48
    80004bbc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004bbe:	00850913          	addi	s2,a0,8
    80004bc2:	854a                	mv	a0,s2
    80004bc4:	ffffc097          	auipc	ra,0xffffc
    80004bc8:	022080e7          	jalr	34(ra) # 80000be6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bcc:	409c                	lw	a5,0(s1)
    80004bce:	ef99                	bnez	a5,80004bec <holdingsleep+0x3e>
    80004bd0:	4481                	li	s1,0
  release(&lk->lk);
    80004bd2:	854a                	mv	a0,s2
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	0c6080e7          	jalr	198(ra) # 80000c9a <release>
  return r;
}
    80004bdc:	8526                	mv	a0,s1
    80004bde:	70a2                	ld	ra,40(sp)
    80004be0:	7402                	ld	s0,32(sp)
    80004be2:	64e2                	ld	s1,24(sp)
    80004be4:	6942                	ld	s2,16(sp)
    80004be6:	69a2                	ld	s3,8(sp)
    80004be8:	6145                	addi	sp,sp,48
    80004bea:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004bec:	0284a983          	lw	s3,40(s1)
    80004bf0:	ffffd097          	auipc	ra,0xffffd
    80004bf4:	e2a080e7          	jalr	-470(ra) # 80001a1a <myproc>
    80004bf8:	5904                	lw	s1,48(a0)
    80004bfa:	413484b3          	sub	s1,s1,s3
    80004bfe:	0014b493          	seqz	s1,s1
    80004c02:	bfc1                	j	80004bd2 <holdingsleep+0x24>

0000000080004c04 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004c04:	1141                	addi	sp,sp,-16
    80004c06:	e406                	sd	ra,8(sp)
    80004c08:	e022                	sd	s0,0(sp)
    80004c0a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004c0c:	00004597          	auipc	a1,0x4
    80004c10:	bbc58593          	addi	a1,a1,-1092 # 800087c8 <syscalls+0x250>
    80004c14:	0001d517          	auipc	a0,0x1d
    80004c18:	fc450513          	addi	a0,a0,-60 # 80021bd8 <ftable>
    80004c1c:	ffffc097          	auipc	ra,0xffffc
    80004c20:	f3a080e7          	jalr	-198(ra) # 80000b56 <initlock>
}
    80004c24:	60a2                	ld	ra,8(sp)
    80004c26:	6402                	ld	s0,0(sp)
    80004c28:	0141                	addi	sp,sp,16
    80004c2a:	8082                	ret

0000000080004c2c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004c2c:	1101                	addi	sp,sp,-32
    80004c2e:	ec06                	sd	ra,24(sp)
    80004c30:	e822                	sd	s0,16(sp)
    80004c32:	e426                	sd	s1,8(sp)
    80004c34:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004c36:	0001d517          	auipc	a0,0x1d
    80004c3a:	fa250513          	addi	a0,a0,-94 # 80021bd8 <ftable>
    80004c3e:	ffffc097          	auipc	ra,0xffffc
    80004c42:	fa8080e7          	jalr	-88(ra) # 80000be6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c46:	0001d497          	auipc	s1,0x1d
    80004c4a:	faa48493          	addi	s1,s1,-86 # 80021bf0 <ftable+0x18>
    80004c4e:	0001e717          	auipc	a4,0x1e
    80004c52:	f4270713          	addi	a4,a4,-190 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    80004c56:	40dc                	lw	a5,4(s1)
    80004c58:	cf99                	beqz	a5,80004c76 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004c5a:	02848493          	addi	s1,s1,40
    80004c5e:	fee49ce3          	bne	s1,a4,80004c56 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004c62:	0001d517          	auipc	a0,0x1d
    80004c66:	f7650513          	addi	a0,a0,-138 # 80021bd8 <ftable>
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	030080e7          	jalr	48(ra) # 80000c9a <release>
  return 0;
    80004c72:	4481                	li	s1,0
    80004c74:	a819                	j	80004c8a <filealloc+0x5e>
      f->ref = 1;
    80004c76:	4785                	li	a5,1
    80004c78:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004c7a:	0001d517          	auipc	a0,0x1d
    80004c7e:	f5e50513          	addi	a0,a0,-162 # 80021bd8 <ftable>
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	018080e7          	jalr	24(ra) # 80000c9a <release>
}
    80004c8a:	8526                	mv	a0,s1
    80004c8c:	60e2                	ld	ra,24(sp)
    80004c8e:	6442                	ld	s0,16(sp)
    80004c90:	64a2                	ld	s1,8(sp)
    80004c92:	6105                	addi	sp,sp,32
    80004c94:	8082                	ret

0000000080004c96 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c96:	1101                	addi	sp,sp,-32
    80004c98:	ec06                	sd	ra,24(sp)
    80004c9a:	e822                	sd	s0,16(sp)
    80004c9c:	e426                	sd	s1,8(sp)
    80004c9e:	1000                	addi	s0,sp,32
    80004ca0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004ca2:	0001d517          	auipc	a0,0x1d
    80004ca6:	f3650513          	addi	a0,a0,-202 # 80021bd8 <ftable>
    80004caa:	ffffc097          	auipc	ra,0xffffc
    80004cae:	f3c080e7          	jalr	-196(ra) # 80000be6 <acquire>
  if(f->ref < 1)
    80004cb2:	40dc                	lw	a5,4(s1)
    80004cb4:	02f05263          	blez	a5,80004cd8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004cb8:	2785                	addiw	a5,a5,1
    80004cba:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004cbc:	0001d517          	auipc	a0,0x1d
    80004cc0:	f1c50513          	addi	a0,a0,-228 # 80021bd8 <ftable>
    80004cc4:	ffffc097          	auipc	ra,0xffffc
    80004cc8:	fd6080e7          	jalr	-42(ra) # 80000c9a <release>
  return f;
}
    80004ccc:	8526                	mv	a0,s1
    80004cce:	60e2                	ld	ra,24(sp)
    80004cd0:	6442                	ld	s0,16(sp)
    80004cd2:	64a2                	ld	s1,8(sp)
    80004cd4:	6105                	addi	sp,sp,32
    80004cd6:	8082                	ret
    panic("filedup");
    80004cd8:	00004517          	auipc	a0,0x4
    80004cdc:	af850513          	addi	a0,a0,-1288 # 800087d0 <syscalls+0x258>
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	860080e7          	jalr	-1952(ra) # 80000540 <panic>

0000000080004ce8 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004ce8:	7139                	addi	sp,sp,-64
    80004cea:	fc06                	sd	ra,56(sp)
    80004cec:	f822                	sd	s0,48(sp)
    80004cee:	f426                	sd	s1,40(sp)
    80004cf0:	f04a                	sd	s2,32(sp)
    80004cf2:	ec4e                	sd	s3,24(sp)
    80004cf4:	e852                	sd	s4,16(sp)
    80004cf6:	e456                	sd	s5,8(sp)
    80004cf8:	0080                	addi	s0,sp,64
    80004cfa:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004cfc:	0001d517          	auipc	a0,0x1d
    80004d00:	edc50513          	addi	a0,a0,-292 # 80021bd8 <ftable>
    80004d04:	ffffc097          	auipc	ra,0xffffc
    80004d08:	ee2080e7          	jalr	-286(ra) # 80000be6 <acquire>
  if(f->ref < 1)
    80004d0c:	40dc                	lw	a5,4(s1)
    80004d0e:	06f05163          	blez	a5,80004d70 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004d12:	37fd                	addiw	a5,a5,-1
    80004d14:	0007871b          	sext.w	a4,a5
    80004d18:	c0dc                	sw	a5,4(s1)
    80004d1a:	06e04363          	bgtz	a4,80004d80 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004d1e:	0004a903          	lw	s2,0(s1)
    80004d22:	0094ca83          	lbu	s5,9(s1)
    80004d26:	0104ba03          	ld	s4,16(s1)
    80004d2a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004d2e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004d32:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004d36:	0001d517          	auipc	a0,0x1d
    80004d3a:	ea250513          	addi	a0,a0,-350 # 80021bd8 <ftable>
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	f5c080e7          	jalr	-164(ra) # 80000c9a <release>

  if(ff.type == FD_PIPE){
    80004d46:	4785                	li	a5,1
    80004d48:	04f90d63          	beq	s2,a5,80004da2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004d4c:	3979                	addiw	s2,s2,-2
    80004d4e:	4785                	li	a5,1
    80004d50:	0527e063          	bltu	a5,s2,80004d90 <fileclose+0xa8>
    begin_op();
    80004d54:	00000097          	auipc	ra,0x0
    80004d58:	ac8080e7          	jalr	-1336(ra) # 8000481c <begin_op>
    iput(ff.ip);
    80004d5c:	854e                	mv	a0,s3
    80004d5e:	fffff097          	auipc	ra,0xfffff
    80004d62:	2a6080e7          	jalr	678(ra) # 80004004 <iput>
    end_op();
    80004d66:	00000097          	auipc	ra,0x0
    80004d6a:	b36080e7          	jalr	-1226(ra) # 8000489c <end_op>
    80004d6e:	a00d                	j	80004d90 <fileclose+0xa8>
    panic("fileclose");
    80004d70:	00004517          	auipc	a0,0x4
    80004d74:	a6850513          	addi	a0,a0,-1432 # 800087d8 <syscalls+0x260>
    80004d78:	ffffb097          	auipc	ra,0xffffb
    80004d7c:	7c8080e7          	jalr	1992(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004d80:	0001d517          	auipc	a0,0x1d
    80004d84:	e5850513          	addi	a0,a0,-424 # 80021bd8 <ftable>
    80004d88:	ffffc097          	auipc	ra,0xffffc
    80004d8c:	f12080e7          	jalr	-238(ra) # 80000c9a <release>
  }
}
    80004d90:	70e2                	ld	ra,56(sp)
    80004d92:	7442                	ld	s0,48(sp)
    80004d94:	74a2                	ld	s1,40(sp)
    80004d96:	7902                	ld	s2,32(sp)
    80004d98:	69e2                	ld	s3,24(sp)
    80004d9a:	6a42                	ld	s4,16(sp)
    80004d9c:	6aa2                	ld	s5,8(sp)
    80004d9e:	6121                	addi	sp,sp,64
    80004da0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004da2:	85d6                	mv	a1,s5
    80004da4:	8552                	mv	a0,s4
    80004da6:	00000097          	auipc	ra,0x0
    80004daa:	34c080e7          	jalr	844(ra) # 800050f2 <pipeclose>
    80004dae:	b7cd                	j	80004d90 <fileclose+0xa8>

0000000080004db0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004db0:	715d                	addi	sp,sp,-80
    80004db2:	e486                	sd	ra,72(sp)
    80004db4:	e0a2                	sd	s0,64(sp)
    80004db6:	fc26                	sd	s1,56(sp)
    80004db8:	f84a                	sd	s2,48(sp)
    80004dba:	f44e                	sd	s3,40(sp)
    80004dbc:	0880                	addi	s0,sp,80
    80004dbe:	84aa                	mv	s1,a0
    80004dc0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004dc2:	ffffd097          	auipc	ra,0xffffd
    80004dc6:	c58080e7          	jalr	-936(ra) # 80001a1a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004dca:	409c                	lw	a5,0(s1)
    80004dcc:	37f9                	addiw	a5,a5,-2
    80004dce:	4705                	li	a4,1
    80004dd0:	04f76763          	bltu	a4,a5,80004e1e <filestat+0x6e>
    80004dd4:	892a                	mv	s2,a0
    ilock(f->ip);
    80004dd6:	6c88                	ld	a0,24(s1)
    80004dd8:	fffff097          	auipc	ra,0xfffff
    80004ddc:	072080e7          	jalr	114(ra) # 80003e4a <ilock>
    stati(f->ip, &st);
    80004de0:	fb840593          	addi	a1,s0,-72
    80004de4:	6c88                	ld	a0,24(s1)
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	2ee080e7          	jalr	750(ra) # 800040d4 <stati>
    iunlock(f->ip);
    80004dee:	6c88                	ld	a0,24(s1)
    80004df0:	fffff097          	auipc	ra,0xfffff
    80004df4:	11c080e7          	jalr	284(ra) # 80003f0c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004df8:	46e1                	li	a3,24
    80004dfa:	fb840613          	addi	a2,s0,-72
    80004dfe:	85ce                	mv	a1,s3
    80004e00:	05093503          	ld	a0,80(s2)
    80004e04:	ffffd097          	auipc	ra,0xffffd
    80004e08:	870080e7          	jalr	-1936(ra) # 80001674 <copyout>
    80004e0c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004e10:	60a6                	ld	ra,72(sp)
    80004e12:	6406                	ld	s0,64(sp)
    80004e14:	74e2                	ld	s1,56(sp)
    80004e16:	7942                	ld	s2,48(sp)
    80004e18:	79a2                	ld	s3,40(sp)
    80004e1a:	6161                	addi	sp,sp,80
    80004e1c:	8082                	ret
  return -1;
    80004e1e:	557d                	li	a0,-1
    80004e20:	bfc5                	j	80004e10 <filestat+0x60>

0000000080004e22 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004e22:	7179                	addi	sp,sp,-48
    80004e24:	f406                	sd	ra,40(sp)
    80004e26:	f022                	sd	s0,32(sp)
    80004e28:	ec26                	sd	s1,24(sp)
    80004e2a:	e84a                	sd	s2,16(sp)
    80004e2c:	e44e                	sd	s3,8(sp)
    80004e2e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004e30:	00854783          	lbu	a5,8(a0)
    80004e34:	c3d5                	beqz	a5,80004ed8 <fileread+0xb6>
    80004e36:	84aa                	mv	s1,a0
    80004e38:	89ae                	mv	s3,a1
    80004e3a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e3c:	411c                	lw	a5,0(a0)
    80004e3e:	4705                	li	a4,1
    80004e40:	04e78963          	beq	a5,a4,80004e92 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e44:	470d                	li	a4,3
    80004e46:	04e78d63          	beq	a5,a4,80004ea0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e4a:	4709                	li	a4,2
    80004e4c:	06e79e63          	bne	a5,a4,80004ec8 <fileread+0xa6>
    ilock(f->ip);
    80004e50:	6d08                	ld	a0,24(a0)
    80004e52:	fffff097          	auipc	ra,0xfffff
    80004e56:	ff8080e7          	jalr	-8(ra) # 80003e4a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004e5a:	874a                	mv	a4,s2
    80004e5c:	5094                	lw	a3,32(s1)
    80004e5e:	864e                	mv	a2,s3
    80004e60:	4585                	li	a1,1
    80004e62:	6c88                	ld	a0,24(s1)
    80004e64:	fffff097          	auipc	ra,0xfffff
    80004e68:	29a080e7          	jalr	666(ra) # 800040fe <readi>
    80004e6c:	892a                	mv	s2,a0
    80004e6e:	00a05563          	blez	a0,80004e78 <fileread+0x56>
      f->off += r;
    80004e72:	509c                	lw	a5,32(s1)
    80004e74:	9fa9                	addw	a5,a5,a0
    80004e76:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004e78:	6c88                	ld	a0,24(s1)
    80004e7a:	fffff097          	auipc	ra,0xfffff
    80004e7e:	092080e7          	jalr	146(ra) # 80003f0c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004e82:	854a                	mv	a0,s2
    80004e84:	70a2                	ld	ra,40(sp)
    80004e86:	7402                	ld	s0,32(sp)
    80004e88:	64e2                	ld	s1,24(sp)
    80004e8a:	6942                	ld	s2,16(sp)
    80004e8c:	69a2                	ld	s3,8(sp)
    80004e8e:	6145                	addi	sp,sp,48
    80004e90:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004e92:	6908                	ld	a0,16(a0)
    80004e94:	00000097          	auipc	ra,0x0
    80004e98:	3ca080e7          	jalr	970(ra) # 8000525e <piperead>
    80004e9c:	892a                	mv	s2,a0
    80004e9e:	b7d5                	j	80004e82 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004ea0:	02451783          	lh	a5,36(a0)
    80004ea4:	03079693          	slli	a3,a5,0x30
    80004ea8:	92c1                	srli	a3,a3,0x30
    80004eaa:	4725                	li	a4,9
    80004eac:	02d76863          	bltu	a4,a3,80004edc <fileread+0xba>
    80004eb0:	0792                	slli	a5,a5,0x4
    80004eb2:	0001d717          	auipc	a4,0x1d
    80004eb6:	c8670713          	addi	a4,a4,-890 # 80021b38 <devsw>
    80004eba:	97ba                	add	a5,a5,a4
    80004ebc:	639c                	ld	a5,0(a5)
    80004ebe:	c38d                	beqz	a5,80004ee0 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004ec0:	4505                	li	a0,1
    80004ec2:	9782                	jalr	a5
    80004ec4:	892a                	mv	s2,a0
    80004ec6:	bf75                	j	80004e82 <fileread+0x60>
    panic("fileread");
    80004ec8:	00004517          	auipc	a0,0x4
    80004ecc:	92050513          	addi	a0,a0,-1760 # 800087e8 <syscalls+0x270>
    80004ed0:	ffffb097          	auipc	ra,0xffffb
    80004ed4:	670080e7          	jalr	1648(ra) # 80000540 <panic>
    return -1;
    80004ed8:	597d                	li	s2,-1
    80004eda:	b765                	j	80004e82 <fileread+0x60>
      return -1;
    80004edc:	597d                	li	s2,-1
    80004ede:	b755                	j	80004e82 <fileread+0x60>
    80004ee0:	597d                	li	s2,-1
    80004ee2:	b745                	j	80004e82 <fileread+0x60>

0000000080004ee4 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ee4:	715d                	addi	sp,sp,-80
    80004ee6:	e486                	sd	ra,72(sp)
    80004ee8:	e0a2                	sd	s0,64(sp)
    80004eea:	fc26                	sd	s1,56(sp)
    80004eec:	f84a                	sd	s2,48(sp)
    80004eee:	f44e                	sd	s3,40(sp)
    80004ef0:	f052                	sd	s4,32(sp)
    80004ef2:	ec56                	sd	s5,24(sp)
    80004ef4:	e85a                	sd	s6,16(sp)
    80004ef6:	e45e                	sd	s7,8(sp)
    80004ef8:	e062                	sd	s8,0(sp)
    80004efa:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004efc:	00954783          	lbu	a5,9(a0)
    80004f00:	10078663          	beqz	a5,8000500c <filewrite+0x128>
    80004f04:	892a                	mv	s2,a0
    80004f06:	8aae                	mv	s5,a1
    80004f08:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004f0a:	411c                	lw	a5,0(a0)
    80004f0c:	4705                	li	a4,1
    80004f0e:	02e78263          	beq	a5,a4,80004f32 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004f12:	470d                	li	a4,3
    80004f14:	02e78663          	beq	a5,a4,80004f40 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004f18:	4709                	li	a4,2
    80004f1a:	0ee79163          	bne	a5,a4,80004ffc <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004f1e:	0ac05d63          	blez	a2,80004fd8 <filewrite+0xf4>
    int i = 0;
    80004f22:	4981                	li	s3,0
    80004f24:	6b05                	lui	s6,0x1
    80004f26:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004f2a:	6b85                	lui	s7,0x1
    80004f2c:	c00b8b9b          	addiw	s7,s7,-1024
    80004f30:	a861                	j	80004fc8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004f32:	6908                	ld	a0,16(a0)
    80004f34:	00000097          	auipc	ra,0x0
    80004f38:	22e080e7          	jalr	558(ra) # 80005162 <pipewrite>
    80004f3c:	8a2a                	mv	s4,a0
    80004f3e:	a045                	j	80004fde <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004f40:	02451783          	lh	a5,36(a0)
    80004f44:	03079693          	slli	a3,a5,0x30
    80004f48:	92c1                	srli	a3,a3,0x30
    80004f4a:	4725                	li	a4,9
    80004f4c:	0cd76263          	bltu	a4,a3,80005010 <filewrite+0x12c>
    80004f50:	0792                	slli	a5,a5,0x4
    80004f52:	0001d717          	auipc	a4,0x1d
    80004f56:	be670713          	addi	a4,a4,-1050 # 80021b38 <devsw>
    80004f5a:	97ba                	add	a5,a5,a4
    80004f5c:	679c                	ld	a5,8(a5)
    80004f5e:	cbdd                	beqz	a5,80005014 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004f60:	4505                	li	a0,1
    80004f62:	9782                	jalr	a5
    80004f64:	8a2a                	mv	s4,a0
    80004f66:	a8a5                	j	80004fde <filewrite+0xfa>
    80004f68:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004f6c:	00000097          	auipc	ra,0x0
    80004f70:	8b0080e7          	jalr	-1872(ra) # 8000481c <begin_op>
      ilock(f->ip);
    80004f74:	01893503          	ld	a0,24(s2)
    80004f78:	fffff097          	auipc	ra,0xfffff
    80004f7c:	ed2080e7          	jalr	-302(ra) # 80003e4a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004f80:	8762                	mv	a4,s8
    80004f82:	02092683          	lw	a3,32(s2)
    80004f86:	01598633          	add	a2,s3,s5
    80004f8a:	4585                	li	a1,1
    80004f8c:	01893503          	ld	a0,24(s2)
    80004f90:	fffff097          	auipc	ra,0xfffff
    80004f94:	266080e7          	jalr	614(ra) # 800041f6 <writei>
    80004f98:	84aa                	mv	s1,a0
    80004f9a:	00a05763          	blez	a0,80004fa8 <filewrite+0xc4>
        f->off += r;
    80004f9e:	02092783          	lw	a5,32(s2)
    80004fa2:	9fa9                	addw	a5,a5,a0
    80004fa4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004fa8:	01893503          	ld	a0,24(s2)
    80004fac:	fffff097          	auipc	ra,0xfffff
    80004fb0:	f60080e7          	jalr	-160(ra) # 80003f0c <iunlock>
      end_op();
    80004fb4:	00000097          	auipc	ra,0x0
    80004fb8:	8e8080e7          	jalr	-1816(ra) # 8000489c <end_op>

      if(r != n1){
    80004fbc:	009c1f63          	bne	s8,s1,80004fda <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004fc0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004fc4:	0149db63          	bge	s3,s4,80004fda <filewrite+0xf6>
      int n1 = n - i;
    80004fc8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004fcc:	84be                	mv	s1,a5
    80004fce:	2781                	sext.w	a5,a5
    80004fd0:	f8fb5ce3          	bge	s6,a5,80004f68 <filewrite+0x84>
    80004fd4:	84de                	mv	s1,s7
    80004fd6:	bf49                	j	80004f68 <filewrite+0x84>
    int i = 0;
    80004fd8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004fda:	013a1f63          	bne	s4,s3,80004ff8 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004fde:	8552                	mv	a0,s4
    80004fe0:	60a6                	ld	ra,72(sp)
    80004fe2:	6406                	ld	s0,64(sp)
    80004fe4:	74e2                	ld	s1,56(sp)
    80004fe6:	7942                	ld	s2,48(sp)
    80004fe8:	79a2                	ld	s3,40(sp)
    80004fea:	7a02                	ld	s4,32(sp)
    80004fec:	6ae2                	ld	s5,24(sp)
    80004fee:	6b42                	ld	s6,16(sp)
    80004ff0:	6ba2                	ld	s7,8(sp)
    80004ff2:	6c02                	ld	s8,0(sp)
    80004ff4:	6161                	addi	sp,sp,80
    80004ff6:	8082                	ret
    ret = (i == n ? n : -1);
    80004ff8:	5a7d                	li	s4,-1
    80004ffa:	b7d5                	j	80004fde <filewrite+0xfa>
    panic("filewrite");
    80004ffc:	00003517          	auipc	a0,0x3
    80005000:	7fc50513          	addi	a0,a0,2044 # 800087f8 <syscalls+0x280>
    80005004:	ffffb097          	auipc	ra,0xffffb
    80005008:	53c080e7          	jalr	1340(ra) # 80000540 <panic>
    return -1;
    8000500c:	5a7d                	li	s4,-1
    8000500e:	bfc1                	j	80004fde <filewrite+0xfa>
      return -1;
    80005010:	5a7d                	li	s4,-1
    80005012:	b7f1                	j	80004fde <filewrite+0xfa>
    80005014:	5a7d                	li	s4,-1
    80005016:	b7e1                	j	80004fde <filewrite+0xfa>

0000000080005018 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005018:	7179                	addi	sp,sp,-48
    8000501a:	f406                	sd	ra,40(sp)
    8000501c:	f022                	sd	s0,32(sp)
    8000501e:	ec26                	sd	s1,24(sp)
    80005020:	e84a                	sd	s2,16(sp)
    80005022:	e44e                	sd	s3,8(sp)
    80005024:	e052                	sd	s4,0(sp)
    80005026:	1800                	addi	s0,sp,48
    80005028:	84aa                	mv	s1,a0
    8000502a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000502c:	0005b023          	sd	zero,0(a1)
    80005030:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005034:	00000097          	auipc	ra,0x0
    80005038:	bf8080e7          	jalr	-1032(ra) # 80004c2c <filealloc>
    8000503c:	e088                	sd	a0,0(s1)
    8000503e:	c551                	beqz	a0,800050ca <pipealloc+0xb2>
    80005040:	00000097          	auipc	ra,0x0
    80005044:	bec080e7          	jalr	-1044(ra) # 80004c2c <filealloc>
    80005048:	00aa3023          	sd	a0,0(s4)
    8000504c:	c92d                	beqz	a0,800050be <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000504e:	ffffc097          	auipc	ra,0xffffc
    80005052:	aa8080e7          	jalr	-1368(ra) # 80000af6 <kalloc>
    80005056:	892a                	mv	s2,a0
    80005058:	c125                	beqz	a0,800050b8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000505a:	4985                	li	s3,1
    8000505c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005060:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005064:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005068:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000506c:	00003597          	auipc	a1,0x3
    80005070:	79c58593          	addi	a1,a1,1948 # 80008808 <syscalls+0x290>
    80005074:	ffffc097          	auipc	ra,0xffffc
    80005078:	ae2080e7          	jalr	-1310(ra) # 80000b56 <initlock>
  (*f0)->type = FD_PIPE;
    8000507c:	609c                	ld	a5,0(s1)
    8000507e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005082:	609c                	ld	a5,0(s1)
    80005084:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005088:	609c                	ld	a5,0(s1)
    8000508a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000508e:	609c                	ld	a5,0(s1)
    80005090:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005094:	000a3783          	ld	a5,0(s4)
    80005098:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000509c:	000a3783          	ld	a5,0(s4)
    800050a0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800050a4:	000a3783          	ld	a5,0(s4)
    800050a8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800050ac:	000a3783          	ld	a5,0(s4)
    800050b0:	0127b823          	sd	s2,16(a5)
  return 0;
    800050b4:	4501                	li	a0,0
    800050b6:	a025                	j	800050de <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800050b8:	6088                	ld	a0,0(s1)
    800050ba:	e501                	bnez	a0,800050c2 <pipealloc+0xaa>
    800050bc:	a039                	j	800050ca <pipealloc+0xb2>
    800050be:	6088                	ld	a0,0(s1)
    800050c0:	c51d                	beqz	a0,800050ee <pipealloc+0xd6>
    fileclose(*f0);
    800050c2:	00000097          	auipc	ra,0x0
    800050c6:	c26080e7          	jalr	-986(ra) # 80004ce8 <fileclose>
  if(*f1)
    800050ca:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800050ce:	557d                	li	a0,-1
  if(*f1)
    800050d0:	c799                	beqz	a5,800050de <pipealloc+0xc6>
    fileclose(*f1);
    800050d2:	853e                	mv	a0,a5
    800050d4:	00000097          	auipc	ra,0x0
    800050d8:	c14080e7          	jalr	-1004(ra) # 80004ce8 <fileclose>
  return -1;
    800050dc:	557d                	li	a0,-1
}
    800050de:	70a2                	ld	ra,40(sp)
    800050e0:	7402                	ld	s0,32(sp)
    800050e2:	64e2                	ld	s1,24(sp)
    800050e4:	6942                	ld	s2,16(sp)
    800050e6:	69a2                	ld	s3,8(sp)
    800050e8:	6a02                	ld	s4,0(sp)
    800050ea:	6145                	addi	sp,sp,48
    800050ec:	8082                	ret
  return -1;
    800050ee:	557d                	li	a0,-1
    800050f0:	b7fd                	j	800050de <pipealloc+0xc6>

00000000800050f2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800050f2:	1101                	addi	sp,sp,-32
    800050f4:	ec06                	sd	ra,24(sp)
    800050f6:	e822                	sd	s0,16(sp)
    800050f8:	e426                	sd	s1,8(sp)
    800050fa:	e04a                	sd	s2,0(sp)
    800050fc:	1000                	addi	s0,sp,32
    800050fe:	84aa                	mv	s1,a0
    80005100:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80005102:	ffffc097          	auipc	ra,0xffffc
    80005106:	ae4080e7          	jalr	-1308(ra) # 80000be6 <acquire>
  if(writable){
    8000510a:	02090d63          	beqz	s2,80005144 <pipeclose+0x52>
    pi->writeopen = 0;
    8000510e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005112:	21848513          	addi	a0,s1,536
    80005116:	ffffd097          	auipc	ra,0xffffd
    8000511a:	452080e7          	jalr	1106(ra) # 80002568 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000511e:	2204b783          	ld	a5,544(s1)
    80005122:	eb95                	bnez	a5,80005156 <pipeclose+0x64>
    release(&pi->lock);
    80005124:	8526                	mv	a0,s1
    80005126:	ffffc097          	auipc	ra,0xffffc
    8000512a:	b74080e7          	jalr	-1164(ra) # 80000c9a <release>
    kfree((char*)pi);
    8000512e:	8526                	mv	a0,s1
    80005130:	ffffc097          	auipc	ra,0xffffc
    80005134:	8ca080e7          	jalr	-1846(ra) # 800009fa <kfree>
  } else
    release(&pi->lock);
}
    80005138:	60e2                	ld	ra,24(sp)
    8000513a:	6442                	ld	s0,16(sp)
    8000513c:	64a2                	ld	s1,8(sp)
    8000513e:	6902                	ld	s2,0(sp)
    80005140:	6105                	addi	sp,sp,32
    80005142:	8082                	ret
    pi->readopen = 0;
    80005144:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005148:	21c48513          	addi	a0,s1,540
    8000514c:	ffffd097          	auipc	ra,0xffffd
    80005150:	41c080e7          	jalr	1052(ra) # 80002568 <wakeup>
    80005154:	b7e9                	j	8000511e <pipeclose+0x2c>
    release(&pi->lock);
    80005156:	8526                	mv	a0,s1
    80005158:	ffffc097          	auipc	ra,0xffffc
    8000515c:	b42080e7          	jalr	-1214(ra) # 80000c9a <release>
}
    80005160:	bfe1                	j	80005138 <pipeclose+0x46>

0000000080005162 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005162:	7159                	addi	sp,sp,-112
    80005164:	f486                	sd	ra,104(sp)
    80005166:	f0a2                	sd	s0,96(sp)
    80005168:	eca6                	sd	s1,88(sp)
    8000516a:	e8ca                	sd	s2,80(sp)
    8000516c:	e4ce                	sd	s3,72(sp)
    8000516e:	e0d2                	sd	s4,64(sp)
    80005170:	fc56                	sd	s5,56(sp)
    80005172:	f85a                	sd	s6,48(sp)
    80005174:	f45e                	sd	s7,40(sp)
    80005176:	f062                	sd	s8,32(sp)
    80005178:	ec66                	sd	s9,24(sp)
    8000517a:	1880                	addi	s0,sp,112
    8000517c:	84aa                	mv	s1,a0
    8000517e:	8aae                	mv	s5,a1
    80005180:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005182:	ffffd097          	auipc	ra,0xffffd
    80005186:	898080e7          	jalr	-1896(ra) # 80001a1a <myproc>
    8000518a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000518c:	8526                	mv	a0,s1
    8000518e:	ffffc097          	auipc	ra,0xffffc
    80005192:	a58080e7          	jalr	-1448(ra) # 80000be6 <acquire>
  while(i < n){
    80005196:	0d405263          	blez	s4,8000525a <pipewrite+0xf8>
    8000519a:	8ba6                	mv	s7,s1
  int i = 0;
    8000519c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000519e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800051a0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800051a4:	21c48c13          	addi	s8,s1,540
    800051a8:	a08d                	j	8000520a <pipewrite+0xa8>
      release(&pi->lock);
    800051aa:	8526                	mv	a0,s1
    800051ac:	ffffc097          	auipc	ra,0xffffc
    800051b0:	aee080e7          	jalr	-1298(ra) # 80000c9a <release>
      return -1;
    800051b4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800051b6:	854a                	mv	a0,s2
    800051b8:	70a6                	ld	ra,104(sp)
    800051ba:	7406                	ld	s0,96(sp)
    800051bc:	64e6                	ld	s1,88(sp)
    800051be:	6946                	ld	s2,80(sp)
    800051c0:	69a6                	ld	s3,72(sp)
    800051c2:	6a06                	ld	s4,64(sp)
    800051c4:	7ae2                	ld	s5,56(sp)
    800051c6:	7b42                	ld	s6,48(sp)
    800051c8:	7ba2                	ld	s7,40(sp)
    800051ca:	7c02                	ld	s8,32(sp)
    800051cc:	6ce2                	ld	s9,24(sp)
    800051ce:	6165                	addi	sp,sp,112
    800051d0:	8082                	ret
      wakeup(&pi->nread);
    800051d2:	8566                	mv	a0,s9
    800051d4:	ffffd097          	auipc	ra,0xffffd
    800051d8:	394080e7          	jalr	916(ra) # 80002568 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800051dc:	85de                	mv	a1,s7
    800051de:	8562                	mv	a0,s8
    800051e0:	ffffd097          	auipc	ra,0xffffd
    800051e4:	180080e7          	jalr	384(ra) # 80002360 <sleep>
    800051e8:	a839                	j	80005206 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800051ea:	21c4a783          	lw	a5,540(s1)
    800051ee:	0017871b          	addiw	a4,a5,1
    800051f2:	20e4ae23          	sw	a4,540(s1)
    800051f6:	1ff7f793          	andi	a5,a5,511
    800051fa:	97a6                	add	a5,a5,s1
    800051fc:	f9f44703          	lbu	a4,-97(s0)
    80005200:	00e78c23          	sb	a4,24(a5)
      i++;
    80005204:	2905                	addiw	s2,s2,1
  while(i < n){
    80005206:	03495e63          	bge	s2,s4,80005242 <pipewrite+0xe0>
    if(pi->readopen == 0 || pr->killed){
    8000520a:	2204a783          	lw	a5,544(s1)
    8000520e:	dfd1                	beqz	a5,800051aa <pipewrite+0x48>
    80005210:	0289a783          	lw	a5,40(s3)
    80005214:	2781                	sext.w	a5,a5
    80005216:	fbd1                	bnez	a5,800051aa <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005218:	2184a783          	lw	a5,536(s1)
    8000521c:	21c4a703          	lw	a4,540(s1)
    80005220:	2007879b          	addiw	a5,a5,512
    80005224:	faf707e3          	beq	a4,a5,800051d2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005228:	4685                	li	a3,1
    8000522a:	01590633          	add	a2,s2,s5
    8000522e:	f9f40593          	addi	a1,s0,-97
    80005232:	0509b503          	ld	a0,80(s3)
    80005236:	ffffc097          	auipc	ra,0xffffc
    8000523a:	4ca080e7          	jalr	1226(ra) # 80001700 <copyin>
    8000523e:	fb6516e3          	bne	a0,s6,800051ea <pipewrite+0x88>
  wakeup(&pi->nread);
    80005242:	21848513          	addi	a0,s1,536
    80005246:	ffffd097          	auipc	ra,0xffffd
    8000524a:	322080e7          	jalr	802(ra) # 80002568 <wakeup>
  release(&pi->lock);
    8000524e:	8526                	mv	a0,s1
    80005250:	ffffc097          	auipc	ra,0xffffc
    80005254:	a4a080e7          	jalr	-1462(ra) # 80000c9a <release>
  return i;
    80005258:	bfb9                	j	800051b6 <pipewrite+0x54>
  int i = 0;
    8000525a:	4901                	li	s2,0
    8000525c:	b7dd                	j	80005242 <pipewrite+0xe0>

000000008000525e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000525e:	715d                	addi	sp,sp,-80
    80005260:	e486                	sd	ra,72(sp)
    80005262:	e0a2                	sd	s0,64(sp)
    80005264:	fc26                	sd	s1,56(sp)
    80005266:	f84a                	sd	s2,48(sp)
    80005268:	f44e                	sd	s3,40(sp)
    8000526a:	f052                	sd	s4,32(sp)
    8000526c:	ec56                	sd	s5,24(sp)
    8000526e:	e85a                	sd	s6,16(sp)
    80005270:	0880                	addi	s0,sp,80
    80005272:	84aa                	mv	s1,a0
    80005274:	892e                	mv	s2,a1
    80005276:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005278:	ffffc097          	auipc	ra,0xffffc
    8000527c:	7a2080e7          	jalr	1954(ra) # 80001a1a <myproc>
    80005280:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005282:	8b26                	mv	s6,s1
    80005284:	8526                	mv	a0,s1
    80005286:	ffffc097          	auipc	ra,0xffffc
    8000528a:	960080e7          	jalr	-1696(ra) # 80000be6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000528e:	2184a703          	lw	a4,536(s1)
    80005292:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005296:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000529a:	02f71563          	bne	a4,a5,800052c4 <piperead+0x66>
    8000529e:	2244a783          	lw	a5,548(s1)
    800052a2:	c38d                	beqz	a5,800052c4 <piperead+0x66>
    if(pr->killed){
    800052a4:	028a2783          	lw	a5,40(s4)
    800052a8:	2781                	sext.w	a5,a5
    800052aa:	ebc1                	bnez	a5,8000533a <piperead+0xdc>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800052ac:	85da                	mv	a1,s6
    800052ae:	854e                	mv	a0,s3
    800052b0:	ffffd097          	auipc	ra,0xffffd
    800052b4:	0b0080e7          	jalr	176(ra) # 80002360 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800052b8:	2184a703          	lw	a4,536(s1)
    800052bc:	21c4a783          	lw	a5,540(s1)
    800052c0:	fcf70fe3          	beq	a4,a5,8000529e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800052c4:	09505263          	blez	s5,80005348 <piperead+0xea>
    800052c8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052ca:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800052cc:	2184a783          	lw	a5,536(s1)
    800052d0:	21c4a703          	lw	a4,540(s1)
    800052d4:	02f70d63          	beq	a4,a5,8000530e <piperead+0xb0>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800052d8:	0017871b          	addiw	a4,a5,1
    800052dc:	20e4ac23          	sw	a4,536(s1)
    800052e0:	1ff7f793          	andi	a5,a5,511
    800052e4:	97a6                	add	a5,a5,s1
    800052e6:	0187c783          	lbu	a5,24(a5)
    800052ea:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800052ee:	4685                	li	a3,1
    800052f0:	fbf40613          	addi	a2,s0,-65
    800052f4:	85ca                	mv	a1,s2
    800052f6:	050a3503          	ld	a0,80(s4)
    800052fa:	ffffc097          	auipc	ra,0xffffc
    800052fe:	37a080e7          	jalr	890(ra) # 80001674 <copyout>
    80005302:	01650663          	beq	a0,s6,8000530e <piperead+0xb0>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005306:	2985                	addiw	s3,s3,1
    80005308:	0905                	addi	s2,s2,1
    8000530a:	fd3a91e3          	bne	s5,s3,800052cc <piperead+0x6e>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000530e:	21c48513          	addi	a0,s1,540
    80005312:	ffffd097          	auipc	ra,0xffffd
    80005316:	256080e7          	jalr	598(ra) # 80002568 <wakeup>
  release(&pi->lock);
    8000531a:	8526                	mv	a0,s1
    8000531c:	ffffc097          	auipc	ra,0xffffc
    80005320:	97e080e7          	jalr	-1666(ra) # 80000c9a <release>
  return i;
}
    80005324:	854e                	mv	a0,s3
    80005326:	60a6                	ld	ra,72(sp)
    80005328:	6406                	ld	s0,64(sp)
    8000532a:	74e2                	ld	s1,56(sp)
    8000532c:	7942                	ld	s2,48(sp)
    8000532e:	79a2                	ld	s3,40(sp)
    80005330:	7a02                	ld	s4,32(sp)
    80005332:	6ae2                	ld	s5,24(sp)
    80005334:	6b42                	ld	s6,16(sp)
    80005336:	6161                	addi	sp,sp,80
    80005338:	8082                	ret
      release(&pi->lock);
    8000533a:	8526                	mv	a0,s1
    8000533c:	ffffc097          	auipc	ra,0xffffc
    80005340:	95e080e7          	jalr	-1698(ra) # 80000c9a <release>
      return -1;
    80005344:	59fd                	li	s3,-1
    80005346:	bff9                	j	80005324 <piperead+0xc6>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005348:	4981                	li	s3,0
    8000534a:	b7d1                	j	8000530e <piperead+0xb0>

000000008000534c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000534c:	df010113          	addi	sp,sp,-528
    80005350:	20113423          	sd	ra,520(sp)
    80005354:	20813023          	sd	s0,512(sp)
    80005358:	ffa6                	sd	s1,504(sp)
    8000535a:	fbca                	sd	s2,496(sp)
    8000535c:	f7ce                	sd	s3,488(sp)
    8000535e:	f3d2                	sd	s4,480(sp)
    80005360:	efd6                	sd	s5,472(sp)
    80005362:	ebda                	sd	s6,464(sp)
    80005364:	e7de                	sd	s7,456(sp)
    80005366:	e3e2                	sd	s8,448(sp)
    80005368:	ff66                	sd	s9,440(sp)
    8000536a:	fb6a                	sd	s10,432(sp)
    8000536c:	f76e                	sd	s11,424(sp)
    8000536e:	0c00                	addi	s0,sp,528
    80005370:	84aa                	mv	s1,a0
    80005372:	dea43c23          	sd	a0,-520(s0)
    80005376:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000537a:	ffffc097          	auipc	ra,0xffffc
    8000537e:	6a0080e7          	jalr	1696(ra) # 80001a1a <myproc>
    80005382:	892a                	mv	s2,a0

  begin_op();
    80005384:	fffff097          	auipc	ra,0xfffff
    80005388:	498080e7          	jalr	1176(ra) # 8000481c <begin_op>

  if((ip = namei(path)) == 0){
    8000538c:	8526                	mv	a0,s1
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	272080e7          	jalr	626(ra) # 80004600 <namei>
    80005396:	c92d                	beqz	a0,80005408 <exec+0xbc>
    80005398:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	ab0080e7          	jalr	-1360(ra) # 80003e4a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800053a2:	04000713          	li	a4,64
    800053a6:	4681                	li	a3,0
    800053a8:	e5040613          	addi	a2,s0,-432
    800053ac:	4581                	li	a1,0
    800053ae:	8526                	mv	a0,s1
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	d4e080e7          	jalr	-690(ra) # 800040fe <readi>
    800053b8:	04000793          	li	a5,64
    800053bc:	00f51a63          	bne	a0,a5,800053d0 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800053c0:	e5042703          	lw	a4,-432(s0)
    800053c4:	464c47b7          	lui	a5,0x464c4
    800053c8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800053cc:	04f70463          	beq	a4,a5,80005414 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800053d0:	8526                	mv	a0,s1
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	cda080e7          	jalr	-806(ra) # 800040ac <iunlockput>
    end_op();
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	4c2080e7          	jalr	1218(ra) # 8000489c <end_op>
  }
  return -1;
    800053e2:	557d                	li	a0,-1
}
    800053e4:	20813083          	ld	ra,520(sp)
    800053e8:	20013403          	ld	s0,512(sp)
    800053ec:	74fe                	ld	s1,504(sp)
    800053ee:	795e                	ld	s2,496(sp)
    800053f0:	79be                	ld	s3,488(sp)
    800053f2:	7a1e                	ld	s4,480(sp)
    800053f4:	6afe                	ld	s5,472(sp)
    800053f6:	6b5e                	ld	s6,464(sp)
    800053f8:	6bbe                	ld	s7,456(sp)
    800053fa:	6c1e                	ld	s8,448(sp)
    800053fc:	7cfa                	ld	s9,440(sp)
    800053fe:	7d5a                	ld	s10,432(sp)
    80005400:	7dba                	ld	s11,424(sp)
    80005402:	21010113          	addi	sp,sp,528
    80005406:	8082                	ret
    end_op();
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	494080e7          	jalr	1172(ra) # 8000489c <end_op>
    return -1;
    80005410:	557d                	li	a0,-1
    80005412:	bfc9                	j	800053e4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005414:	854a                	mv	a0,s2
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	6c8080e7          	jalr	1736(ra) # 80001ade <proc_pagetable>
    8000541e:	8baa                	mv	s7,a0
    80005420:	d945                	beqz	a0,800053d0 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005422:	e7042983          	lw	s3,-400(s0)
    80005426:	e8845783          	lhu	a5,-376(s0)
    8000542a:	c7ad                	beqz	a5,80005494 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000542c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000542e:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005430:	6c85                	lui	s9,0x1
    80005432:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005436:	def43823          	sd	a5,-528(s0)
    8000543a:	a42d                	j	80005664 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000543c:	00003517          	auipc	a0,0x3
    80005440:	3d450513          	addi	a0,a0,980 # 80008810 <syscalls+0x298>
    80005444:	ffffb097          	auipc	ra,0xffffb
    80005448:	0fc080e7          	jalr	252(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000544c:	8756                	mv	a4,s5
    8000544e:	012d86bb          	addw	a3,s11,s2
    80005452:	4581                	li	a1,0
    80005454:	8526                	mv	a0,s1
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	ca8080e7          	jalr	-856(ra) # 800040fe <readi>
    8000545e:	2501                	sext.w	a0,a0
    80005460:	1aaa9963          	bne	s5,a0,80005612 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005464:	6785                	lui	a5,0x1
    80005466:	0127893b          	addw	s2,a5,s2
    8000546a:	77fd                	lui	a5,0xfffff
    8000546c:	01478a3b          	addw	s4,a5,s4
    80005470:	1f897163          	bgeu	s2,s8,80005652 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005474:	02091593          	slli	a1,s2,0x20
    80005478:	9181                	srli	a1,a1,0x20
    8000547a:	95ea                	add	a1,a1,s10
    8000547c:	855e                	mv	a0,s7
    8000547e:	ffffc097          	auipc	ra,0xffffc
    80005482:	bf2080e7          	jalr	-1038(ra) # 80001070 <walkaddr>
    80005486:	862a                	mv	a2,a0
    if(pa == 0)
    80005488:	d955                	beqz	a0,8000543c <exec+0xf0>
      n = PGSIZE;
    8000548a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000548c:	fd9a70e3          	bgeu	s4,s9,8000544c <exec+0x100>
      n = sz - i;
    80005490:	8ad2                	mv	s5,s4
    80005492:	bf6d                	j	8000544c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005494:	4901                	li	s2,0
  iunlockput(ip);
    80005496:	8526                	mv	a0,s1
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	c14080e7          	jalr	-1004(ra) # 800040ac <iunlockput>
  end_op();
    800054a0:	fffff097          	auipc	ra,0xfffff
    800054a4:	3fc080e7          	jalr	1020(ra) # 8000489c <end_op>
  p = myproc();
    800054a8:	ffffc097          	auipc	ra,0xffffc
    800054ac:	572080e7          	jalr	1394(ra) # 80001a1a <myproc>
    800054b0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800054b2:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800054b6:	6785                	lui	a5,0x1
    800054b8:	17fd                	addi	a5,a5,-1
    800054ba:	993e                	add	s2,s2,a5
    800054bc:	757d                	lui	a0,0xfffff
    800054be:	00a977b3          	and	a5,s2,a0
    800054c2:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054c6:	6609                	lui	a2,0x2
    800054c8:	963e                	add	a2,a2,a5
    800054ca:	85be                	mv	a1,a5
    800054cc:	855e                	mv	a0,s7
    800054ce:	ffffc097          	auipc	ra,0xffffc
    800054d2:	f56080e7          	jalr	-170(ra) # 80001424 <uvmalloc>
    800054d6:	8b2a                	mv	s6,a0
  ip = 0;
    800054d8:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800054da:	12050c63          	beqz	a0,80005612 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054de:	75f9                	lui	a1,0xffffe
    800054e0:	95aa                	add	a1,a1,a0
    800054e2:	855e                	mv	a0,s7
    800054e4:	ffffc097          	auipc	ra,0xffffc
    800054e8:	15e080e7          	jalr	350(ra) # 80001642 <uvmclear>
  stackbase = sp - PGSIZE;
    800054ec:	7c7d                	lui	s8,0xfffff
    800054ee:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800054f0:	e0043783          	ld	a5,-512(s0)
    800054f4:	6388                	ld	a0,0(a5)
    800054f6:	c535                	beqz	a0,80005562 <exec+0x216>
    800054f8:	e9040993          	addi	s3,s0,-368
    800054fc:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005500:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005502:	ffffc097          	auipc	ra,0xffffc
    80005506:	964080e7          	jalr	-1692(ra) # 80000e66 <strlen>
    8000550a:	2505                	addiw	a0,a0,1
    8000550c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005510:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005514:	13896363          	bltu	s2,s8,8000563a <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005518:	e0043d83          	ld	s11,-512(s0)
    8000551c:	000dba03          	ld	s4,0(s11)
    80005520:	8552                	mv	a0,s4
    80005522:	ffffc097          	auipc	ra,0xffffc
    80005526:	944080e7          	jalr	-1724(ra) # 80000e66 <strlen>
    8000552a:	0015069b          	addiw	a3,a0,1
    8000552e:	8652                	mv	a2,s4
    80005530:	85ca                	mv	a1,s2
    80005532:	855e                	mv	a0,s7
    80005534:	ffffc097          	auipc	ra,0xffffc
    80005538:	140080e7          	jalr	320(ra) # 80001674 <copyout>
    8000553c:	10054363          	bltz	a0,80005642 <exec+0x2f6>
    ustack[argc] = sp;
    80005540:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005544:	0485                	addi	s1,s1,1
    80005546:	008d8793          	addi	a5,s11,8
    8000554a:	e0f43023          	sd	a5,-512(s0)
    8000554e:	008db503          	ld	a0,8(s11)
    80005552:	c911                	beqz	a0,80005566 <exec+0x21a>
    if(argc >= MAXARG)
    80005554:	09a1                	addi	s3,s3,8
    80005556:	fb3c96e3          	bne	s9,s3,80005502 <exec+0x1b6>
  sz = sz1;
    8000555a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000555e:	4481                	li	s1,0
    80005560:	a84d                	j	80005612 <exec+0x2c6>
  sp = sz;
    80005562:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005564:	4481                	li	s1,0
  ustack[argc] = 0;
    80005566:	00349793          	slli	a5,s1,0x3
    8000556a:	f9040713          	addi	a4,s0,-112
    8000556e:	97ba                	add	a5,a5,a4
    80005570:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005574:	00148693          	addi	a3,s1,1
    80005578:	068e                	slli	a3,a3,0x3
    8000557a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000557e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005582:	01897663          	bgeu	s2,s8,8000558e <exec+0x242>
  sz = sz1;
    80005586:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000558a:	4481                	li	s1,0
    8000558c:	a059                	j	80005612 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000558e:	e9040613          	addi	a2,s0,-368
    80005592:	85ca                	mv	a1,s2
    80005594:	855e                	mv	a0,s7
    80005596:	ffffc097          	auipc	ra,0xffffc
    8000559a:	0de080e7          	jalr	222(ra) # 80001674 <copyout>
    8000559e:	0a054663          	bltz	a0,8000564a <exec+0x2fe>
  p->trapframe->a1 = sp;
    800055a2:	058ab783          	ld	a5,88(s5)
    800055a6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800055aa:	df843783          	ld	a5,-520(s0)
    800055ae:	0007c703          	lbu	a4,0(a5)
    800055b2:	cf11                	beqz	a4,800055ce <exec+0x282>
    800055b4:	0785                	addi	a5,a5,1
    if(*s == '/')
    800055b6:	02f00693          	li	a3,47
    800055ba:	a039                	j	800055c8 <exec+0x27c>
      last = s+1;
    800055bc:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800055c0:	0785                	addi	a5,a5,1
    800055c2:	fff7c703          	lbu	a4,-1(a5)
    800055c6:	c701                	beqz	a4,800055ce <exec+0x282>
    if(*s == '/')
    800055c8:	fed71ce3          	bne	a4,a3,800055c0 <exec+0x274>
    800055cc:	bfc5                	j	800055bc <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800055ce:	4641                	li	a2,16
    800055d0:	df843583          	ld	a1,-520(s0)
    800055d4:	158a8513          	addi	a0,s5,344
    800055d8:	ffffc097          	auipc	ra,0xffffc
    800055dc:	85c080e7          	jalr	-1956(ra) # 80000e34 <safestrcpy>
  oldpagetable = p->pagetable;
    800055e0:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800055e4:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800055e8:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055ec:	058ab783          	ld	a5,88(s5)
    800055f0:	e6843703          	ld	a4,-408(s0)
    800055f4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055f6:	058ab783          	ld	a5,88(s5)
    800055fa:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055fe:	85ea                	mv	a1,s10
    80005600:	ffffc097          	auipc	ra,0xffffc
    80005604:	57a080e7          	jalr	1402(ra) # 80001b7a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005608:	0004851b          	sext.w	a0,s1
    8000560c:	bbe1                	j	800053e4 <exec+0x98>
    8000560e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005612:	e0843583          	ld	a1,-504(s0)
    80005616:	855e                	mv	a0,s7
    80005618:	ffffc097          	auipc	ra,0xffffc
    8000561c:	562080e7          	jalr	1378(ra) # 80001b7a <proc_freepagetable>
  if(ip){
    80005620:	da0498e3          	bnez	s1,800053d0 <exec+0x84>
  return -1;
    80005624:	557d                	li	a0,-1
    80005626:	bb7d                	j	800053e4 <exec+0x98>
    80005628:	e1243423          	sd	s2,-504(s0)
    8000562c:	b7dd                	j	80005612 <exec+0x2c6>
    8000562e:	e1243423          	sd	s2,-504(s0)
    80005632:	b7c5                	j	80005612 <exec+0x2c6>
    80005634:	e1243423          	sd	s2,-504(s0)
    80005638:	bfe9                	j	80005612 <exec+0x2c6>
  sz = sz1;
    8000563a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000563e:	4481                	li	s1,0
    80005640:	bfc9                	j	80005612 <exec+0x2c6>
  sz = sz1;
    80005642:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005646:	4481                	li	s1,0
    80005648:	b7e9                	j	80005612 <exec+0x2c6>
  sz = sz1;
    8000564a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000564e:	4481                	li	s1,0
    80005650:	b7c9                	j	80005612 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005652:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005656:	2b05                	addiw	s6,s6,1
    80005658:	0389899b          	addiw	s3,s3,56
    8000565c:	e8845783          	lhu	a5,-376(s0)
    80005660:	e2fb5be3          	bge	s6,a5,80005496 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005664:	2981                	sext.w	s3,s3
    80005666:	03800713          	li	a4,56
    8000566a:	86ce                	mv	a3,s3
    8000566c:	e1840613          	addi	a2,s0,-488
    80005670:	4581                	li	a1,0
    80005672:	8526                	mv	a0,s1
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	a8a080e7          	jalr	-1398(ra) # 800040fe <readi>
    8000567c:	03800793          	li	a5,56
    80005680:	f8f517e3          	bne	a0,a5,8000560e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005684:	e1842783          	lw	a5,-488(s0)
    80005688:	4705                	li	a4,1
    8000568a:	fce796e3          	bne	a5,a4,80005656 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000568e:	e4043603          	ld	a2,-448(s0)
    80005692:	e3843783          	ld	a5,-456(s0)
    80005696:	f8f669e3          	bltu	a2,a5,80005628 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000569a:	e2843783          	ld	a5,-472(s0)
    8000569e:	963e                	add	a2,a2,a5
    800056a0:	f8f667e3          	bltu	a2,a5,8000562e <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800056a4:	85ca                	mv	a1,s2
    800056a6:	855e                	mv	a0,s7
    800056a8:	ffffc097          	auipc	ra,0xffffc
    800056ac:	d7c080e7          	jalr	-644(ra) # 80001424 <uvmalloc>
    800056b0:	e0a43423          	sd	a0,-504(s0)
    800056b4:	d141                	beqz	a0,80005634 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800056b6:	e2843d03          	ld	s10,-472(s0)
    800056ba:	df043783          	ld	a5,-528(s0)
    800056be:	00fd77b3          	and	a5,s10,a5
    800056c2:	fba1                	bnez	a5,80005612 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800056c4:	e2042d83          	lw	s11,-480(s0)
    800056c8:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800056cc:	f80c03e3          	beqz	s8,80005652 <exec+0x306>
    800056d0:	8a62                	mv	s4,s8
    800056d2:	4901                	li	s2,0
    800056d4:	b345                	j	80005474 <exec+0x128>

00000000800056d6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800056d6:	7179                	addi	sp,sp,-48
    800056d8:	f406                	sd	ra,40(sp)
    800056da:	f022                	sd	s0,32(sp)
    800056dc:	ec26                	sd	s1,24(sp)
    800056de:	e84a                	sd	s2,16(sp)
    800056e0:	1800                	addi	s0,sp,48
    800056e2:	892e                	mv	s2,a1
    800056e4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800056e6:	fdc40593          	addi	a1,s0,-36
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	b88080e7          	jalr	-1144(ra) # 80003272 <argint>
    800056f2:	04054063          	bltz	a0,80005732 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800056f6:	fdc42703          	lw	a4,-36(s0)
    800056fa:	47bd                	li	a5,15
    800056fc:	02e7ed63          	bltu	a5,a4,80005736 <argfd+0x60>
    80005700:	ffffc097          	auipc	ra,0xffffc
    80005704:	31a080e7          	jalr	794(ra) # 80001a1a <myproc>
    80005708:	fdc42703          	lw	a4,-36(s0)
    8000570c:	01a70793          	addi	a5,a4,26
    80005710:	078e                	slli	a5,a5,0x3
    80005712:	953e                	add	a0,a0,a5
    80005714:	611c                	ld	a5,0(a0)
    80005716:	c395                	beqz	a5,8000573a <argfd+0x64>
    return -1;
  if(pfd)
    80005718:	00090463          	beqz	s2,80005720 <argfd+0x4a>
    *pfd = fd;
    8000571c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005720:	4501                	li	a0,0
  if(pf)
    80005722:	c091                	beqz	s1,80005726 <argfd+0x50>
    *pf = f;
    80005724:	e09c                	sd	a5,0(s1)
}
    80005726:	70a2                	ld	ra,40(sp)
    80005728:	7402                	ld	s0,32(sp)
    8000572a:	64e2                	ld	s1,24(sp)
    8000572c:	6942                	ld	s2,16(sp)
    8000572e:	6145                	addi	sp,sp,48
    80005730:	8082                	ret
    return -1;
    80005732:	557d                	li	a0,-1
    80005734:	bfcd                	j	80005726 <argfd+0x50>
    return -1;
    80005736:	557d                	li	a0,-1
    80005738:	b7fd                	j	80005726 <argfd+0x50>
    8000573a:	557d                	li	a0,-1
    8000573c:	b7ed                	j	80005726 <argfd+0x50>

000000008000573e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000573e:	1101                	addi	sp,sp,-32
    80005740:	ec06                	sd	ra,24(sp)
    80005742:	e822                	sd	s0,16(sp)
    80005744:	e426                	sd	s1,8(sp)
    80005746:	1000                	addi	s0,sp,32
    80005748:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000574a:	ffffc097          	auipc	ra,0xffffc
    8000574e:	2d0080e7          	jalr	720(ra) # 80001a1a <myproc>
    80005752:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005754:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005758:	4501                	li	a0,0
    8000575a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000575c:	6398                	ld	a4,0(a5)
    8000575e:	cb19                	beqz	a4,80005774 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005760:	2505                	addiw	a0,a0,1
    80005762:	07a1                	addi	a5,a5,8
    80005764:	fed51ce3          	bne	a0,a3,8000575c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005768:	557d                	li	a0,-1
}
    8000576a:	60e2                	ld	ra,24(sp)
    8000576c:	6442                	ld	s0,16(sp)
    8000576e:	64a2                	ld	s1,8(sp)
    80005770:	6105                	addi	sp,sp,32
    80005772:	8082                	ret
      p->ofile[fd] = f;
    80005774:	01a50793          	addi	a5,a0,26
    80005778:	078e                	slli	a5,a5,0x3
    8000577a:	963e                	add	a2,a2,a5
    8000577c:	e204                	sd	s1,0(a2)
      return fd;
    8000577e:	b7f5                	j	8000576a <fdalloc+0x2c>

0000000080005780 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005780:	715d                	addi	sp,sp,-80
    80005782:	e486                	sd	ra,72(sp)
    80005784:	e0a2                	sd	s0,64(sp)
    80005786:	fc26                	sd	s1,56(sp)
    80005788:	f84a                	sd	s2,48(sp)
    8000578a:	f44e                	sd	s3,40(sp)
    8000578c:	f052                	sd	s4,32(sp)
    8000578e:	ec56                	sd	s5,24(sp)
    80005790:	0880                	addi	s0,sp,80
    80005792:	89ae                	mv	s3,a1
    80005794:	8ab2                	mv	s5,a2
    80005796:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005798:	fb040593          	addi	a1,s0,-80
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	e82080e7          	jalr	-382(ra) # 8000461e <nameiparent>
    800057a4:	892a                	mv	s2,a0
    800057a6:	12050f63          	beqz	a0,800058e4 <create+0x164>
    return 0;

  ilock(dp);
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	6a0080e7          	jalr	1696(ra) # 80003e4a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800057b2:	4601                	li	a2,0
    800057b4:	fb040593          	addi	a1,s0,-80
    800057b8:	854a                	mv	a0,s2
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	b74080e7          	jalr	-1164(ra) # 8000432e <dirlookup>
    800057c2:	84aa                	mv	s1,a0
    800057c4:	c921                	beqz	a0,80005814 <create+0x94>
    iunlockput(dp);
    800057c6:	854a                	mv	a0,s2
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	8e4080e7          	jalr	-1820(ra) # 800040ac <iunlockput>
    ilock(ip);
    800057d0:	8526                	mv	a0,s1
    800057d2:	ffffe097          	auipc	ra,0xffffe
    800057d6:	678080e7          	jalr	1656(ra) # 80003e4a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800057da:	2981                	sext.w	s3,s3
    800057dc:	4789                	li	a5,2
    800057de:	02f99463          	bne	s3,a5,80005806 <create+0x86>
    800057e2:	0444d783          	lhu	a5,68(s1)
    800057e6:	37f9                	addiw	a5,a5,-2
    800057e8:	17c2                	slli	a5,a5,0x30
    800057ea:	93c1                	srli	a5,a5,0x30
    800057ec:	4705                	li	a4,1
    800057ee:	00f76c63          	bltu	a4,a5,80005806 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800057f2:	8526                	mv	a0,s1
    800057f4:	60a6                	ld	ra,72(sp)
    800057f6:	6406                	ld	s0,64(sp)
    800057f8:	74e2                	ld	s1,56(sp)
    800057fa:	7942                	ld	s2,48(sp)
    800057fc:	79a2                	ld	s3,40(sp)
    800057fe:	7a02                	ld	s4,32(sp)
    80005800:	6ae2                	ld	s5,24(sp)
    80005802:	6161                	addi	sp,sp,80
    80005804:	8082                	ret
    iunlockput(ip);
    80005806:	8526                	mv	a0,s1
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	8a4080e7          	jalr	-1884(ra) # 800040ac <iunlockput>
    return 0;
    80005810:	4481                	li	s1,0
    80005812:	b7c5                	j	800057f2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005814:	85ce                	mv	a1,s3
    80005816:	00092503          	lw	a0,0(s2)
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	498080e7          	jalr	1176(ra) # 80003cb2 <ialloc>
    80005822:	84aa                	mv	s1,a0
    80005824:	c529                	beqz	a0,8000586e <create+0xee>
  ilock(ip);
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	624080e7          	jalr	1572(ra) # 80003e4a <ilock>
  ip->major = major;
    8000582e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005832:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005836:	4785                	li	a5,1
    80005838:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000583c:	8526                	mv	a0,s1
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	542080e7          	jalr	1346(ra) # 80003d80 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005846:	2981                	sext.w	s3,s3
    80005848:	4785                	li	a5,1
    8000584a:	02f98a63          	beq	s3,a5,8000587e <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000584e:	40d0                	lw	a2,4(s1)
    80005850:	fb040593          	addi	a1,s0,-80
    80005854:	854a                	mv	a0,s2
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	ce8080e7          	jalr	-792(ra) # 8000453e <dirlink>
    8000585e:	06054b63          	bltz	a0,800058d4 <create+0x154>
  iunlockput(dp);
    80005862:	854a                	mv	a0,s2
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	848080e7          	jalr	-1976(ra) # 800040ac <iunlockput>
  return ip;
    8000586c:	b759                	j	800057f2 <create+0x72>
    panic("create: ialloc");
    8000586e:	00003517          	auipc	a0,0x3
    80005872:	fc250513          	addi	a0,a0,-62 # 80008830 <syscalls+0x2b8>
    80005876:	ffffb097          	auipc	ra,0xffffb
    8000587a:	cca080e7          	jalr	-822(ra) # 80000540 <panic>
    dp->nlink++;  // for ".."
    8000587e:	04a95783          	lhu	a5,74(s2)
    80005882:	2785                	addiw	a5,a5,1
    80005884:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005888:	854a                	mv	a0,s2
    8000588a:	ffffe097          	auipc	ra,0xffffe
    8000588e:	4f6080e7          	jalr	1270(ra) # 80003d80 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005892:	40d0                	lw	a2,4(s1)
    80005894:	00003597          	auipc	a1,0x3
    80005898:	fac58593          	addi	a1,a1,-84 # 80008840 <syscalls+0x2c8>
    8000589c:	8526                	mv	a0,s1
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	ca0080e7          	jalr	-864(ra) # 8000453e <dirlink>
    800058a6:	00054f63          	bltz	a0,800058c4 <create+0x144>
    800058aa:	00492603          	lw	a2,4(s2)
    800058ae:	00003597          	auipc	a1,0x3
    800058b2:	f9a58593          	addi	a1,a1,-102 # 80008848 <syscalls+0x2d0>
    800058b6:	8526                	mv	a0,s1
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	c86080e7          	jalr	-890(ra) # 8000453e <dirlink>
    800058c0:	f80557e3          	bgez	a0,8000584e <create+0xce>
      panic("create dots");
    800058c4:	00003517          	auipc	a0,0x3
    800058c8:	f8c50513          	addi	a0,a0,-116 # 80008850 <syscalls+0x2d8>
    800058cc:	ffffb097          	auipc	ra,0xffffb
    800058d0:	c74080e7          	jalr	-908(ra) # 80000540 <panic>
    panic("create: dirlink");
    800058d4:	00003517          	auipc	a0,0x3
    800058d8:	f8c50513          	addi	a0,a0,-116 # 80008860 <syscalls+0x2e8>
    800058dc:	ffffb097          	auipc	ra,0xffffb
    800058e0:	c64080e7          	jalr	-924(ra) # 80000540 <panic>
    return 0;
    800058e4:	84aa                	mv	s1,a0
    800058e6:	b731                	j	800057f2 <create+0x72>

00000000800058e8 <sys_dup>:
{
    800058e8:	7179                	addi	sp,sp,-48
    800058ea:	f406                	sd	ra,40(sp)
    800058ec:	f022                	sd	s0,32(sp)
    800058ee:	ec26                	sd	s1,24(sp)
    800058f0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058f2:	fd840613          	addi	a2,s0,-40
    800058f6:	4581                	li	a1,0
    800058f8:	4501                	li	a0,0
    800058fa:	00000097          	auipc	ra,0x0
    800058fe:	ddc080e7          	jalr	-548(ra) # 800056d6 <argfd>
    return -1;
    80005902:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005904:	02054363          	bltz	a0,8000592a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005908:	fd843503          	ld	a0,-40(s0)
    8000590c:	00000097          	auipc	ra,0x0
    80005910:	e32080e7          	jalr	-462(ra) # 8000573e <fdalloc>
    80005914:	84aa                	mv	s1,a0
    return -1;
    80005916:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005918:	00054963          	bltz	a0,8000592a <sys_dup+0x42>
  filedup(f);
    8000591c:	fd843503          	ld	a0,-40(s0)
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	376080e7          	jalr	886(ra) # 80004c96 <filedup>
  return fd;
    80005928:	87a6                	mv	a5,s1
}
    8000592a:	853e                	mv	a0,a5
    8000592c:	70a2                	ld	ra,40(sp)
    8000592e:	7402                	ld	s0,32(sp)
    80005930:	64e2                	ld	s1,24(sp)
    80005932:	6145                	addi	sp,sp,48
    80005934:	8082                	ret

0000000080005936 <sys_read>:
{
    80005936:	7179                	addi	sp,sp,-48
    80005938:	f406                	sd	ra,40(sp)
    8000593a:	f022                	sd	s0,32(sp)
    8000593c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000593e:	fe840613          	addi	a2,s0,-24
    80005942:	4581                	li	a1,0
    80005944:	4501                	li	a0,0
    80005946:	00000097          	auipc	ra,0x0
    8000594a:	d90080e7          	jalr	-624(ra) # 800056d6 <argfd>
    return -1;
    8000594e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005950:	04054163          	bltz	a0,80005992 <sys_read+0x5c>
    80005954:	fe440593          	addi	a1,s0,-28
    80005958:	4509                	li	a0,2
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	918080e7          	jalr	-1768(ra) # 80003272 <argint>
    return -1;
    80005962:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005964:	02054763          	bltz	a0,80005992 <sys_read+0x5c>
    80005968:	fd840593          	addi	a1,s0,-40
    8000596c:	4505                	li	a0,1
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	926080e7          	jalr	-1754(ra) # 80003294 <argaddr>
    return -1;
    80005976:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005978:	00054d63          	bltz	a0,80005992 <sys_read+0x5c>
  return fileread(f, p, n);
    8000597c:	fe442603          	lw	a2,-28(s0)
    80005980:	fd843583          	ld	a1,-40(s0)
    80005984:	fe843503          	ld	a0,-24(s0)
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	49a080e7          	jalr	1178(ra) # 80004e22 <fileread>
    80005990:	87aa                	mv	a5,a0
}
    80005992:	853e                	mv	a0,a5
    80005994:	70a2                	ld	ra,40(sp)
    80005996:	7402                	ld	s0,32(sp)
    80005998:	6145                	addi	sp,sp,48
    8000599a:	8082                	ret

000000008000599c <sys_write>:
{
    8000599c:	7179                	addi	sp,sp,-48
    8000599e:	f406                	sd	ra,40(sp)
    800059a0:	f022                	sd	s0,32(sp)
    800059a2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059a4:	fe840613          	addi	a2,s0,-24
    800059a8:	4581                	li	a1,0
    800059aa:	4501                	li	a0,0
    800059ac:	00000097          	auipc	ra,0x0
    800059b0:	d2a080e7          	jalr	-726(ra) # 800056d6 <argfd>
    return -1;
    800059b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059b6:	04054163          	bltz	a0,800059f8 <sys_write+0x5c>
    800059ba:	fe440593          	addi	a1,s0,-28
    800059be:	4509                	li	a0,2
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	8b2080e7          	jalr	-1870(ra) # 80003272 <argint>
    return -1;
    800059c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059ca:	02054763          	bltz	a0,800059f8 <sys_write+0x5c>
    800059ce:	fd840593          	addi	a1,s0,-40
    800059d2:	4505                	li	a0,1
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	8c0080e7          	jalr	-1856(ra) # 80003294 <argaddr>
    return -1;
    800059dc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800059de:	00054d63          	bltz	a0,800059f8 <sys_write+0x5c>
  return filewrite(f, p, n);
    800059e2:	fe442603          	lw	a2,-28(s0)
    800059e6:	fd843583          	ld	a1,-40(s0)
    800059ea:	fe843503          	ld	a0,-24(s0)
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	4f6080e7          	jalr	1270(ra) # 80004ee4 <filewrite>
    800059f6:	87aa                	mv	a5,a0
}
    800059f8:	853e                	mv	a0,a5
    800059fa:	70a2                	ld	ra,40(sp)
    800059fc:	7402                	ld	s0,32(sp)
    800059fe:	6145                	addi	sp,sp,48
    80005a00:	8082                	ret

0000000080005a02 <sys_close>:
{
    80005a02:	1101                	addi	sp,sp,-32
    80005a04:	ec06                	sd	ra,24(sp)
    80005a06:	e822                	sd	s0,16(sp)
    80005a08:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005a0a:	fe040613          	addi	a2,s0,-32
    80005a0e:	fec40593          	addi	a1,s0,-20
    80005a12:	4501                	li	a0,0
    80005a14:	00000097          	auipc	ra,0x0
    80005a18:	cc2080e7          	jalr	-830(ra) # 800056d6 <argfd>
    return -1;
    80005a1c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005a1e:	02054463          	bltz	a0,80005a46 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005a22:	ffffc097          	auipc	ra,0xffffc
    80005a26:	ff8080e7          	jalr	-8(ra) # 80001a1a <myproc>
    80005a2a:	fec42783          	lw	a5,-20(s0)
    80005a2e:	07e9                	addi	a5,a5,26
    80005a30:	078e                	slli	a5,a5,0x3
    80005a32:	97aa                	add	a5,a5,a0
    80005a34:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005a38:	fe043503          	ld	a0,-32(s0)
    80005a3c:	fffff097          	auipc	ra,0xfffff
    80005a40:	2ac080e7          	jalr	684(ra) # 80004ce8 <fileclose>
  return 0;
    80005a44:	4781                	li	a5,0
}
    80005a46:	853e                	mv	a0,a5
    80005a48:	60e2                	ld	ra,24(sp)
    80005a4a:	6442                	ld	s0,16(sp)
    80005a4c:	6105                	addi	sp,sp,32
    80005a4e:	8082                	ret

0000000080005a50 <sys_fstat>:
{
    80005a50:	1101                	addi	sp,sp,-32
    80005a52:	ec06                	sd	ra,24(sp)
    80005a54:	e822                	sd	s0,16(sp)
    80005a56:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a58:	fe840613          	addi	a2,s0,-24
    80005a5c:	4581                	li	a1,0
    80005a5e:	4501                	li	a0,0
    80005a60:	00000097          	auipc	ra,0x0
    80005a64:	c76080e7          	jalr	-906(ra) # 800056d6 <argfd>
    return -1;
    80005a68:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a6a:	02054563          	bltz	a0,80005a94 <sys_fstat+0x44>
    80005a6e:	fe040593          	addi	a1,s0,-32
    80005a72:	4505                	li	a0,1
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	820080e7          	jalr	-2016(ra) # 80003294 <argaddr>
    return -1;
    80005a7c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005a7e:	00054b63          	bltz	a0,80005a94 <sys_fstat+0x44>
  return filestat(f, st);
    80005a82:	fe043583          	ld	a1,-32(s0)
    80005a86:	fe843503          	ld	a0,-24(s0)
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	326080e7          	jalr	806(ra) # 80004db0 <filestat>
    80005a92:	87aa                	mv	a5,a0
}
    80005a94:	853e                	mv	a0,a5
    80005a96:	60e2                	ld	ra,24(sp)
    80005a98:	6442                	ld	s0,16(sp)
    80005a9a:	6105                	addi	sp,sp,32
    80005a9c:	8082                	ret

0000000080005a9e <sys_link>:
{
    80005a9e:	7169                	addi	sp,sp,-304
    80005aa0:	f606                	sd	ra,296(sp)
    80005aa2:	f222                	sd	s0,288(sp)
    80005aa4:	ee26                	sd	s1,280(sp)
    80005aa6:	ea4a                	sd	s2,272(sp)
    80005aa8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005aaa:	08000613          	li	a2,128
    80005aae:	ed040593          	addi	a1,s0,-304
    80005ab2:	4501                	li	a0,0
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	802080e7          	jalr	-2046(ra) # 800032b6 <argstr>
    return -1;
    80005abc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005abe:	10054e63          	bltz	a0,80005bda <sys_link+0x13c>
    80005ac2:	08000613          	li	a2,128
    80005ac6:	f5040593          	addi	a1,s0,-176
    80005aca:	4505                	li	a0,1
    80005acc:	ffffd097          	auipc	ra,0xffffd
    80005ad0:	7ea080e7          	jalr	2026(ra) # 800032b6 <argstr>
    return -1;
    80005ad4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005ad6:	10054263          	bltz	a0,80005bda <sys_link+0x13c>
  begin_op();
    80005ada:	fffff097          	auipc	ra,0xfffff
    80005ade:	d42080e7          	jalr	-702(ra) # 8000481c <begin_op>
  if((ip = namei(old)) == 0){
    80005ae2:	ed040513          	addi	a0,s0,-304
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	b1a080e7          	jalr	-1254(ra) # 80004600 <namei>
    80005aee:	84aa                	mv	s1,a0
    80005af0:	c551                	beqz	a0,80005b7c <sys_link+0xde>
  ilock(ip);
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	358080e7          	jalr	856(ra) # 80003e4a <ilock>
  if(ip->type == T_DIR){
    80005afa:	04449703          	lh	a4,68(s1)
    80005afe:	4785                	li	a5,1
    80005b00:	08f70463          	beq	a4,a5,80005b88 <sys_link+0xea>
  ip->nlink++;
    80005b04:	04a4d783          	lhu	a5,74(s1)
    80005b08:	2785                	addiw	a5,a5,1
    80005b0a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b0e:	8526                	mv	a0,s1
    80005b10:	ffffe097          	auipc	ra,0xffffe
    80005b14:	270080e7          	jalr	624(ra) # 80003d80 <iupdate>
  iunlock(ip);
    80005b18:	8526                	mv	a0,s1
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	3f2080e7          	jalr	1010(ra) # 80003f0c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005b22:	fd040593          	addi	a1,s0,-48
    80005b26:	f5040513          	addi	a0,s0,-176
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	af4080e7          	jalr	-1292(ra) # 8000461e <nameiparent>
    80005b32:	892a                	mv	s2,a0
    80005b34:	c935                	beqz	a0,80005ba8 <sys_link+0x10a>
  ilock(dp);
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	314080e7          	jalr	788(ra) # 80003e4a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005b3e:	00092703          	lw	a4,0(s2)
    80005b42:	409c                	lw	a5,0(s1)
    80005b44:	04f71d63          	bne	a4,a5,80005b9e <sys_link+0x100>
    80005b48:	40d0                	lw	a2,4(s1)
    80005b4a:	fd040593          	addi	a1,s0,-48
    80005b4e:	854a                	mv	a0,s2
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	9ee080e7          	jalr	-1554(ra) # 8000453e <dirlink>
    80005b58:	04054363          	bltz	a0,80005b9e <sys_link+0x100>
  iunlockput(dp);
    80005b5c:	854a                	mv	a0,s2
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	54e080e7          	jalr	1358(ra) # 800040ac <iunlockput>
  iput(ip);
    80005b66:	8526                	mv	a0,s1
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	49c080e7          	jalr	1180(ra) # 80004004 <iput>
  end_op();
    80005b70:	fffff097          	auipc	ra,0xfffff
    80005b74:	d2c080e7          	jalr	-724(ra) # 8000489c <end_op>
  return 0;
    80005b78:	4781                	li	a5,0
    80005b7a:	a085                	j	80005bda <sys_link+0x13c>
    end_op();
    80005b7c:	fffff097          	auipc	ra,0xfffff
    80005b80:	d20080e7          	jalr	-736(ra) # 8000489c <end_op>
    return -1;
    80005b84:	57fd                	li	a5,-1
    80005b86:	a891                	j	80005bda <sys_link+0x13c>
    iunlockput(ip);
    80005b88:	8526                	mv	a0,s1
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	522080e7          	jalr	1314(ra) # 800040ac <iunlockput>
    end_op();
    80005b92:	fffff097          	auipc	ra,0xfffff
    80005b96:	d0a080e7          	jalr	-758(ra) # 8000489c <end_op>
    return -1;
    80005b9a:	57fd                	li	a5,-1
    80005b9c:	a83d                	j	80005bda <sys_link+0x13c>
    iunlockput(dp);
    80005b9e:	854a                	mv	a0,s2
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	50c080e7          	jalr	1292(ra) # 800040ac <iunlockput>
  ilock(ip);
    80005ba8:	8526                	mv	a0,s1
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	2a0080e7          	jalr	672(ra) # 80003e4a <ilock>
  ip->nlink--;
    80005bb2:	04a4d783          	lhu	a5,74(s1)
    80005bb6:	37fd                	addiw	a5,a5,-1
    80005bb8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005bbc:	8526                	mv	a0,s1
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	1c2080e7          	jalr	450(ra) # 80003d80 <iupdate>
  iunlockput(ip);
    80005bc6:	8526                	mv	a0,s1
    80005bc8:	ffffe097          	auipc	ra,0xffffe
    80005bcc:	4e4080e7          	jalr	1252(ra) # 800040ac <iunlockput>
  end_op();
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	ccc080e7          	jalr	-820(ra) # 8000489c <end_op>
  return -1;
    80005bd8:	57fd                	li	a5,-1
}
    80005bda:	853e                	mv	a0,a5
    80005bdc:	70b2                	ld	ra,296(sp)
    80005bde:	7412                	ld	s0,288(sp)
    80005be0:	64f2                	ld	s1,280(sp)
    80005be2:	6952                	ld	s2,272(sp)
    80005be4:	6155                	addi	sp,sp,304
    80005be6:	8082                	ret

0000000080005be8 <sys_unlink>:
{
    80005be8:	7151                	addi	sp,sp,-240
    80005bea:	f586                	sd	ra,232(sp)
    80005bec:	f1a2                	sd	s0,224(sp)
    80005bee:	eda6                	sd	s1,216(sp)
    80005bf0:	e9ca                	sd	s2,208(sp)
    80005bf2:	e5ce                	sd	s3,200(sp)
    80005bf4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005bf6:	08000613          	li	a2,128
    80005bfa:	f3040593          	addi	a1,s0,-208
    80005bfe:	4501                	li	a0,0
    80005c00:	ffffd097          	auipc	ra,0xffffd
    80005c04:	6b6080e7          	jalr	1718(ra) # 800032b6 <argstr>
    80005c08:	18054163          	bltz	a0,80005d8a <sys_unlink+0x1a2>
  begin_op();
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	c10080e7          	jalr	-1008(ra) # 8000481c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005c14:	fb040593          	addi	a1,s0,-80
    80005c18:	f3040513          	addi	a0,s0,-208
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	a02080e7          	jalr	-1534(ra) # 8000461e <nameiparent>
    80005c24:	84aa                	mv	s1,a0
    80005c26:	c979                	beqz	a0,80005cfc <sys_unlink+0x114>
  ilock(dp);
    80005c28:	ffffe097          	auipc	ra,0xffffe
    80005c2c:	222080e7          	jalr	546(ra) # 80003e4a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005c30:	00003597          	auipc	a1,0x3
    80005c34:	c1058593          	addi	a1,a1,-1008 # 80008840 <syscalls+0x2c8>
    80005c38:	fb040513          	addi	a0,s0,-80
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	6d8080e7          	jalr	1752(ra) # 80004314 <namecmp>
    80005c44:	14050a63          	beqz	a0,80005d98 <sys_unlink+0x1b0>
    80005c48:	00003597          	auipc	a1,0x3
    80005c4c:	c0058593          	addi	a1,a1,-1024 # 80008848 <syscalls+0x2d0>
    80005c50:	fb040513          	addi	a0,s0,-80
    80005c54:	ffffe097          	auipc	ra,0xffffe
    80005c58:	6c0080e7          	jalr	1728(ra) # 80004314 <namecmp>
    80005c5c:	12050e63          	beqz	a0,80005d98 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005c60:	f2c40613          	addi	a2,s0,-212
    80005c64:	fb040593          	addi	a1,s0,-80
    80005c68:	8526                	mv	a0,s1
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	6c4080e7          	jalr	1732(ra) # 8000432e <dirlookup>
    80005c72:	892a                	mv	s2,a0
    80005c74:	12050263          	beqz	a0,80005d98 <sys_unlink+0x1b0>
  ilock(ip);
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	1d2080e7          	jalr	466(ra) # 80003e4a <ilock>
  if(ip->nlink < 1)
    80005c80:	04a91783          	lh	a5,74(s2)
    80005c84:	08f05263          	blez	a5,80005d08 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c88:	04491703          	lh	a4,68(s2)
    80005c8c:	4785                	li	a5,1
    80005c8e:	08f70563          	beq	a4,a5,80005d18 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c92:	4641                	li	a2,16
    80005c94:	4581                	li	a1,0
    80005c96:	fc040513          	addi	a0,s0,-64
    80005c9a:	ffffb097          	auipc	ra,0xffffb
    80005c9e:	048080e7          	jalr	72(ra) # 80000ce2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ca2:	4741                	li	a4,16
    80005ca4:	f2c42683          	lw	a3,-212(s0)
    80005ca8:	fc040613          	addi	a2,s0,-64
    80005cac:	4581                	li	a1,0
    80005cae:	8526                	mv	a0,s1
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	546080e7          	jalr	1350(ra) # 800041f6 <writei>
    80005cb8:	47c1                	li	a5,16
    80005cba:	0af51563          	bne	a0,a5,80005d64 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005cbe:	04491703          	lh	a4,68(s2)
    80005cc2:	4785                	li	a5,1
    80005cc4:	0af70863          	beq	a4,a5,80005d74 <sys_unlink+0x18c>
  iunlockput(dp);
    80005cc8:	8526                	mv	a0,s1
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	3e2080e7          	jalr	994(ra) # 800040ac <iunlockput>
  ip->nlink--;
    80005cd2:	04a95783          	lhu	a5,74(s2)
    80005cd6:	37fd                	addiw	a5,a5,-1
    80005cd8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005cdc:	854a                	mv	a0,s2
    80005cde:	ffffe097          	auipc	ra,0xffffe
    80005ce2:	0a2080e7          	jalr	162(ra) # 80003d80 <iupdate>
  iunlockput(ip);
    80005ce6:	854a                	mv	a0,s2
    80005ce8:	ffffe097          	auipc	ra,0xffffe
    80005cec:	3c4080e7          	jalr	964(ra) # 800040ac <iunlockput>
  end_op();
    80005cf0:	fffff097          	auipc	ra,0xfffff
    80005cf4:	bac080e7          	jalr	-1108(ra) # 8000489c <end_op>
  return 0;
    80005cf8:	4501                	li	a0,0
    80005cfa:	a84d                	j	80005dac <sys_unlink+0x1c4>
    end_op();
    80005cfc:	fffff097          	auipc	ra,0xfffff
    80005d00:	ba0080e7          	jalr	-1120(ra) # 8000489c <end_op>
    return -1;
    80005d04:	557d                	li	a0,-1
    80005d06:	a05d                	j	80005dac <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005d08:	00003517          	auipc	a0,0x3
    80005d0c:	b6850513          	addi	a0,a0,-1176 # 80008870 <syscalls+0x2f8>
    80005d10:	ffffb097          	auipc	ra,0xffffb
    80005d14:	830080e7          	jalr	-2000(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d18:	04c92703          	lw	a4,76(s2)
    80005d1c:	02000793          	li	a5,32
    80005d20:	f6e7f9e3          	bgeu	a5,a4,80005c92 <sys_unlink+0xaa>
    80005d24:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005d28:	4741                	li	a4,16
    80005d2a:	86ce                	mv	a3,s3
    80005d2c:	f1840613          	addi	a2,s0,-232
    80005d30:	4581                	li	a1,0
    80005d32:	854a                	mv	a0,s2
    80005d34:	ffffe097          	auipc	ra,0xffffe
    80005d38:	3ca080e7          	jalr	970(ra) # 800040fe <readi>
    80005d3c:	47c1                	li	a5,16
    80005d3e:	00f51b63          	bne	a0,a5,80005d54 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005d42:	f1845783          	lhu	a5,-232(s0)
    80005d46:	e7a1                	bnez	a5,80005d8e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005d48:	29c1                	addiw	s3,s3,16
    80005d4a:	04c92783          	lw	a5,76(s2)
    80005d4e:	fcf9ede3          	bltu	s3,a5,80005d28 <sys_unlink+0x140>
    80005d52:	b781                	j	80005c92 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005d54:	00003517          	auipc	a0,0x3
    80005d58:	b3450513          	addi	a0,a0,-1228 # 80008888 <syscalls+0x310>
    80005d5c:	ffffa097          	auipc	ra,0xffffa
    80005d60:	7e4080e7          	jalr	2020(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005d64:	00003517          	auipc	a0,0x3
    80005d68:	b3c50513          	addi	a0,a0,-1220 # 800088a0 <syscalls+0x328>
    80005d6c:	ffffa097          	auipc	ra,0xffffa
    80005d70:	7d4080e7          	jalr	2004(ra) # 80000540 <panic>
    dp->nlink--;
    80005d74:	04a4d783          	lhu	a5,74(s1)
    80005d78:	37fd                	addiw	a5,a5,-1
    80005d7a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d7e:	8526                	mv	a0,s1
    80005d80:	ffffe097          	auipc	ra,0xffffe
    80005d84:	000080e7          	jalr	ra # 80003d80 <iupdate>
    80005d88:	b781                	j	80005cc8 <sys_unlink+0xe0>
    return -1;
    80005d8a:	557d                	li	a0,-1
    80005d8c:	a005                	j	80005dac <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d8e:	854a                	mv	a0,s2
    80005d90:	ffffe097          	auipc	ra,0xffffe
    80005d94:	31c080e7          	jalr	796(ra) # 800040ac <iunlockput>
  iunlockput(dp);
    80005d98:	8526                	mv	a0,s1
    80005d9a:	ffffe097          	auipc	ra,0xffffe
    80005d9e:	312080e7          	jalr	786(ra) # 800040ac <iunlockput>
  end_op();
    80005da2:	fffff097          	auipc	ra,0xfffff
    80005da6:	afa080e7          	jalr	-1286(ra) # 8000489c <end_op>
  return -1;
    80005daa:	557d                	li	a0,-1
}
    80005dac:	70ae                	ld	ra,232(sp)
    80005dae:	740e                	ld	s0,224(sp)
    80005db0:	64ee                	ld	s1,216(sp)
    80005db2:	694e                	ld	s2,208(sp)
    80005db4:	69ae                	ld	s3,200(sp)
    80005db6:	616d                	addi	sp,sp,240
    80005db8:	8082                	ret

0000000080005dba <sys_open>:

uint64
sys_open(void)
{
    80005dba:	7131                	addi	sp,sp,-192
    80005dbc:	fd06                	sd	ra,184(sp)
    80005dbe:	f922                	sd	s0,176(sp)
    80005dc0:	f526                	sd	s1,168(sp)
    80005dc2:	f14a                	sd	s2,160(sp)
    80005dc4:	ed4e                	sd	s3,152(sp)
    80005dc6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005dc8:	08000613          	li	a2,128
    80005dcc:	f5040593          	addi	a1,s0,-176
    80005dd0:	4501                	li	a0,0
    80005dd2:	ffffd097          	auipc	ra,0xffffd
    80005dd6:	4e4080e7          	jalr	1252(ra) # 800032b6 <argstr>
    return -1;
    80005dda:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005ddc:	0c054163          	bltz	a0,80005e9e <sys_open+0xe4>
    80005de0:	f4c40593          	addi	a1,s0,-180
    80005de4:	4505                	li	a0,1
    80005de6:	ffffd097          	auipc	ra,0xffffd
    80005dea:	48c080e7          	jalr	1164(ra) # 80003272 <argint>
    80005dee:	0a054863          	bltz	a0,80005e9e <sys_open+0xe4>

  begin_op();
    80005df2:	fffff097          	auipc	ra,0xfffff
    80005df6:	a2a080e7          	jalr	-1494(ra) # 8000481c <begin_op>

  if(omode & O_CREATE){
    80005dfa:	f4c42783          	lw	a5,-180(s0)
    80005dfe:	2007f793          	andi	a5,a5,512
    80005e02:	cbdd                	beqz	a5,80005eb8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005e04:	4681                	li	a3,0
    80005e06:	4601                	li	a2,0
    80005e08:	4589                	li	a1,2
    80005e0a:	f5040513          	addi	a0,s0,-176
    80005e0e:	00000097          	auipc	ra,0x0
    80005e12:	972080e7          	jalr	-1678(ra) # 80005780 <create>
    80005e16:	892a                	mv	s2,a0
    if(ip == 0){
    80005e18:	c959                	beqz	a0,80005eae <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005e1a:	04491703          	lh	a4,68(s2)
    80005e1e:	478d                	li	a5,3
    80005e20:	00f71763          	bne	a4,a5,80005e2e <sys_open+0x74>
    80005e24:	04695703          	lhu	a4,70(s2)
    80005e28:	47a5                	li	a5,9
    80005e2a:	0ce7ec63          	bltu	a5,a4,80005f02 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005e2e:	fffff097          	auipc	ra,0xfffff
    80005e32:	dfe080e7          	jalr	-514(ra) # 80004c2c <filealloc>
    80005e36:	89aa                	mv	s3,a0
    80005e38:	10050263          	beqz	a0,80005f3c <sys_open+0x182>
    80005e3c:	00000097          	auipc	ra,0x0
    80005e40:	902080e7          	jalr	-1790(ra) # 8000573e <fdalloc>
    80005e44:	84aa                	mv	s1,a0
    80005e46:	0e054663          	bltz	a0,80005f32 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005e4a:	04491703          	lh	a4,68(s2)
    80005e4e:	478d                	li	a5,3
    80005e50:	0cf70463          	beq	a4,a5,80005f18 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005e54:	4789                	li	a5,2
    80005e56:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005e5a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005e5e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005e62:	f4c42783          	lw	a5,-180(s0)
    80005e66:	0017c713          	xori	a4,a5,1
    80005e6a:	8b05                	andi	a4,a4,1
    80005e6c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e70:	0037f713          	andi	a4,a5,3
    80005e74:	00e03733          	snez	a4,a4
    80005e78:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e7c:	4007f793          	andi	a5,a5,1024
    80005e80:	c791                	beqz	a5,80005e8c <sys_open+0xd2>
    80005e82:	04491703          	lh	a4,68(s2)
    80005e86:	4789                	li	a5,2
    80005e88:	08f70f63          	beq	a4,a5,80005f26 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e8c:	854a                	mv	a0,s2
    80005e8e:	ffffe097          	auipc	ra,0xffffe
    80005e92:	07e080e7          	jalr	126(ra) # 80003f0c <iunlock>
  end_op();
    80005e96:	fffff097          	auipc	ra,0xfffff
    80005e9a:	a06080e7          	jalr	-1530(ra) # 8000489c <end_op>

  return fd;
}
    80005e9e:	8526                	mv	a0,s1
    80005ea0:	70ea                	ld	ra,184(sp)
    80005ea2:	744a                	ld	s0,176(sp)
    80005ea4:	74aa                	ld	s1,168(sp)
    80005ea6:	790a                	ld	s2,160(sp)
    80005ea8:	69ea                	ld	s3,152(sp)
    80005eaa:	6129                	addi	sp,sp,192
    80005eac:	8082                	ret
      end_op();
    80005eae:	fffff097          	auipc	ra,0xfffff
    80005eb2:	9ee080e7          	jalr	-1554(ra) # 8000489c <end_op>
      return -1;
    80005eb6:	b7e5                	j	80005e9e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005eb8:	f5040513          	addi	a0,s0,-176
    80005ebc:	ffffe097          	auipc	ra,0xffffe
    80005ec0:	744080e7          	jalr	1860(ra) # 80004600 <namei>
    80005ec4:	892a                	mv	s2,a0
    80005ec6:	c905                	beqz	a0,80005ef6 <sys_open+0x13c>
    ilock(ip);
    80005ec8:	ffffe097          	auipc	ra,0xffffe
    80005ecc:	f82080e7          	jalr	-126(ra) # 80003e4a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ed0:	04491703          	lh	a4,68(s2)
    80005ed4:	4785                	li	a5,1
    80005ed6:	f4f712e3          	bne	a4,a5,80005e1a <sys_open+0x60>
    80005eda:	f4c42783          	lw	a5,-180(s0)
    80005ede:	dba1                	beqz	a5,80005e2e <sys_open+0x74>
      iunlockput(ip);
    80005ee0:	854a                	mv	a0,s2
    80005ee2:	ffffe097          	auipc	ra,0xffffe
    80005ee6:	1ca080e7          	jalr	458(ra) # 800040ac <iunlockput>
      end_op();
    80005eea:	fffff097          	auipc	ra,0xfffff
    80005eee:	9b2080e7          	jalr	-1614(ra) # 8000489c <end_op>
      return -1;
    80005ef2:	54fd                	li	s1,-1
    80005ef4:	b76d                	j	80005e9e <sys_open+0xe4>
      end_op();
    80005ef6:	fffff097          	auipc	ra,0xfffff
    80005efa:	9a6080e7          	jalr	-1626(ra) # 8000489c <end_op>
      return -1;
    80005efe:	54fd                	li	s1,-1
    80005f00:	bf79                	j	80005e9e <sys_open+0xe4>
    iunlockput(ip);
    80005f02:	854a                	mv	a0,s2
    80005f04:	ffffe097          	auipc	ra,0xffffe
    80005f08:	1a8080e7          	jalr	424(ra) # 800040ac <iunlockput>
    end_op();
    80005f0c:	fffff097          	auipc	ra,0xfffff
    80005f10:	990080e7          	jalr	-1648(ra) # 8000489c <end_op>
    return -1;
    80005f14:	54fd                	li	s1,-1
    80005f16:	b761                	j	80005e9e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005f18:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005f1c:	04691783          	lh	a5,70(s2)
    80005f20:	02f99223          	sh	a5,36(s3)
    80005f24:	bf2d                	j	80005e5e <sys_open+0xa4>
    itrunc(ip);
    80005f26:	854a                	mv	a0,s2
    80005f28:	ffffe097          	auipc	ra,0xffffe
    80005f2c:	030080e7          	jalr	48(ra) # 80003f58 <itrunc>
    80005f30:	bfb1                	j	80005e8c <sys_open+0xd2>
      fileclose(f);
    80005f32:	854e                	mv	a0,s3
    80005f34:	fffff097          	auipc	ra,0xfffff
    80005f38:	db4080e7          	jalr	-588(ra) # 80004ce8 <fileclose>
    iunlockput(ip);
    80005f3c:	854a                	mv	a0,s2
    80005f3e:	ffffe097          	auipc	ra,0xffffe
    80005f42:	16e080e7          	jalr	366(ra) # 800040ac <iunlockput>
    end_op();
    80005f46:	fffff097          	auipc	ra,0xfffff
    80005f4a:	956080e7          	jalr	-1706(ra) # 8000489c <end_op>
    return -1;
    80005f4e:	54fd                	li	s1,-1
    80005f50:	b7b9                	j	80005e9e <sys_open+0xe4>

0000000080005f52 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005f52:	7175                	addi	sp,sp,-144
    80005f54:	e506                	sd	ra,136(sp)
    80005f56:	e122                	sd	s0,128(sp)
    80005f58:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005f5a:	fffff097          	auipc	ra,0xfffff
    80005f5e:	8c2080e7          	jalr	-1854(ra) # 8000481c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f62:	08000613          	li	a2,128
    80005f66:	f7040593          	addi	a1,s0,-144
    80005f6a:	4501                	li	a0,0
    80005f6c:	ffffd097          	auipc	ra,0xffffd
    80005f70:	34a080e7          	jalr	842(ra) # 800032b6 <argstr>
    80005f74:	02054963          	bltz	a0,80005fa6 <sys_mkdir+0x54>
    80005f78:	4681                	li	a3,0
    80005f7a:	4601                	li	a2,0
    80005f7c:	4585                	li	a1,1
    80005f7e:	f7040513          	addi	a0,s0,-144
    80005f82:	fffff097          	auipc	ra,0xfffff
    80005f86:	7fe080e7          	jalr	2046(ra) # 80005780 <create>
    80005f8a:	cd11                	beqz	a0,80005fa6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f8c:	ffffe097          	auipc	ra,0xffffe
    80005f90:	120080e7          	jalr	288(ra) # 800040ac <iunlockput>
  end_op();
    80005f94:	fffff097          	auipc	ra,0xfffff
    80005f98:	908080e7          	jalr	-1784(ra) # 8000489c <end_op>
  return 0;
    80005f9c:	4501                	li	a0,0
}
    80005f9e:	60aa                	ld	ra,136(sp)
    80005fa0:	640a                	ld	s0,128(sp)
    80005fa2:	6149                	addi	sp,sp,144
    80005fa4:	8082                	ret
    end_op();
    80005fa6:	fffff097          	auipc	ra,0xfffff
    80005faa:	8f6080e7          	jalr	-1802(ra) # 8000489c <end_op>
    return -1;
    80005fae:	557d                	li	a0,-1
    80005fb0:	b7fd                	j	80005f9e <sys_mkdir+0x4c>

0000000080005fb2 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005fb2:	7135                	addi	sp,sp,-160
    80005fb4:	ed06                	sd	ra,152(sp)
    80005fb6:	e922                	sd	s0,144(sp)
    80005fb8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005fba:	fffff097          	auipc	ra,0xfffff
    80005fbe:	862080e7          	jalr	-1950(ra) # 8000481c <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fc2:	08000613          	li	a2,128
    80005fc6:	f7040593          	addi	a1,s0,-144
    80005fca:	4501                	li	a0,0
    80005fcc:	ffffd097          	auipc	ra,0xffffd
    80005fd0:	2ea080e7          	jalr	746(ra) # 800032b6 <argstr>
    80005fd4:	04054a63          	bltz	a0,80006028 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005fd8:	f6c40593          	addi	a1,s0,-148
    80005fdc:	4505                	li	a0,1
    80005fde:	ffffd097          	auipc	ra,0xffffd
    80005fe2:	294080e7          	jalr	660(ra) # 80003272 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fe6:	04054163          	bltz	a0,80006028 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005fea:	f6840593          	addi	a1,s0,-152
    80005fee:	4509                	li	a0,2
    80005ff0:	ffffd097          	auipc	ra,0xffffd
    80005ff4:	282080e7          	jalr	642(ra) # 80003272 <argint>
     argint(1, &major) < 0 ||
    80005ff8:	02054863          	bltz	a0,80006028 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ffc:	f6841683          	lh	a3,-152(s0)
    80006000:	f6c41603          	lh	a2,-148(s0)
    80006004:	458d                	li	a1,3
    80006006:	f7040513          	addi	a0,s0,-144
    8000600a:	fffff097          	auipc	ra,0xfffff
    8000600e:	776080e7          	jalr	1910(ra) # 80005780 <create>
     argint(2, &minor) < 0 ||
    80006012:	c919                	beqz	a0,80006028 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006014:	ffffe097          	auipc	ra,0xffffe
    80006018:	098080e7          	jalr	152(ra) # 800040ac <iunlockput>
  end_op();
    8000601c:	fffff097          	auipc	ra,0xfffff
    80006020:	880080e7          	jalr	-1920(ra) # 8000489c <end_op>
  return 0;
    80006024:	4501                	li	a0,0
    80006026:	a031                	j	80006032 <sys_mknod+0x80>
    end_op();
    80006028:	fffff097          	auipc	ra,0xfffff
    8000602c:	874080e7          	jalr	-1932(ra) # 8000489c <end_op>
    return -1;
    80006030:	557d                	li	a0,-1
}
    80006032:	60ea                	ld	ra,152(sp)
    80006034:	644a                	ld	s0,144(sp)
    80006036:	610d                	addi	sp,sp,160
    80006038:	8082                	ret

000000008000603a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000603a:	7135                	addi	sp,sp,-160
    8000603c:	ed06                	sd	ra,152(sp)
    8000603e:	e922                	sd	s0,144(sp)
    80006040:	e526                	sd	s1,136(sp)
    80006042:	e14a                	sd	s2,128(sp)
    80006044:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006046:	ffffc097          	auipc	ra,0xffffc
    8000604a:	9d4080e7          	jalr	-1580(ra) # 80001a1a <myproc>
    8000604e:	892a                	mv	s2,a0
  
  begin_op();
    80006050:	ffffe097          	auipc	ra,0xffffe
    80006054:	7cc080e7          	jalr	1996(ra) # 8000481c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006058:	08000613          	li	a2,128
    8000605c:	f6040593          	addi	a1,s0,-160
    80006060:	4501                	li	a0,0
    80006062:	ffffd097          	auipc	ra,0xffffd
    80006066:	254080e7          	jalr	596(ra) # 800032b6 <argstr>
    8000606a:	04054b63          	bltz	a0,800060c0 <sys_chdir+0x86>
    8000606e:	f6040513          	addi	a0,s0,-160
    80006072:	ffffe097          	auipc	ra,0xffffe
    80006076:	58e080e7          	jalr	1422(ra) # 80004600 <namei>
    8000607a:	84aa                	mv	s1,a0
    8000607c:	c131                	beqz	a0,800060c0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000607e:	ffffe097          	auipc	ra,0xffffe
    80006082:	dcc080e7          	jalr	-564(ra) # 80003e4a <ilock>
  if(ip->type != T_DIR){
    80006086:	04449703          	lh	a4,68(s1)
    8000608a:	4785                	li	a5,1
    8000608c:	04f71063          	bne	a4,a5,800060cc <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006090:	8526                	mv	a0,s1
    80006092:	ffffe097          	auipc	ra,0xffffe
    80006096:	e7a080e7          	jalr	-390(ra) # 80003f0c <iunlock>
  iput(p->cwd);
    8000609a:	15093503          	ld	a0,336(s2)
    8000609e:	ffffe097          	auipc	ra,0xffffe
    800060a2:	f66080e7          	jalr	-154(ra) # 80004004 <iput>
  end_op();
    800060a6:	ffffe097          	auipc	ra,0xffffe
    800060aa:	7f6080e7          	jalr	2038(ra) # 8000489c <end_op>
  p->cwd = ip;
    800060ae:	14993823          	sd	s1,336(s2)
  return 0;
    800060b2:	4501                	li	a0,0
}
    800060b4:	60ea                	ld	ra,152(sp)
    800060b6:	644a                	ld	s0,144(sp)
    800060b8:	64aa                	ld	s1,136(sp)
    800060ba:	690a                	ld	s2,128(sp)
    800060bc:	610d                	addi	sp,sp,160
    800060be:	8082                	ret
    end_op();
    800060c0:	ffffe097          	auipc	ra,0xffffe
    800060c4:	7dc080e7          	jalr	2012(ra) # 8000489c <end_op>
    return -1;
    800060c8:	557d                	li	a0,-1
    800060ca:	b7ed                	j	800060b4 <sys_chdir+0x7a>
    iunlockput(ip);
    800060cc:	8526                	mv	a0,s1
    800060ce:	ffffe097          	auipc	ra,0xffffe
    800060d2:	fde080e7          	jalr	-34(ra) # 800040ac <iunlockput>
    end_op();
    800060d6:	ffffe097          	auipc	ra,0xffffe
    800060da:	7c6080e7          	jalr	1990(ra) # 8000489c <end_op>
    return -1;
    800060de:	557d                	li	a0,-1
    800060e0:	bfd1                	j	800060b4 <sys_chdir+0x7a>

00000000800060e2 <sys_exec>:

uint64
sys_exec(void)
{
    800060e2:	7145                	addi	sp,sp,-464
    800060e4:	e786                	sd	ra,456(sp)
    800060e6:	e3a2                	sd	s0,448(sp)
    800060e8:	ff26                	sd	s1,440(sp)
    800060ea:	fb4a                	sd	s2,432(sp)
    800060ec:	f74e                	sd	s3,424(sp)
    800060ee:	f352                	sd	s4,416(sp)
    800060f0:	ef56                	sd	s5,408(sp)
    800060f2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    800060f4:	08000613          	li	a2,128
    800060f8:	f4040593          	addi	a1,s0,-192
    800060fc:	4501                	li	a0,0
    800060fe:	ffffd097          	auipc	ra,0xffffd
    80006102:	1b8080e7          	jalr	440(ra) # 800032b6 <argstr>
    return -1;
    80006106:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006108:	0c054a63          	bltz	a0,800061dc <sys_exec+0xfa>
    8000610c:	e3840593          	addi	a1,s0,-456
    80006110:	4505                	li	a0,1
    80006112:	ffffd097          	auipc	ra,0xffffd
    80006116:	182080e7          	jalr	386(ra) # 80003294 <argaddr>
    8000611a:	0c054163          	bltz	a0,800061dc <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000611e:	10000613          	li	a2,256
    80006122:	4581                	li	a1,0
    80006124:	e4040513          	addi	a0,s0,-448
    80006128:	ffffb097          	auipc	ra,0xffffb
    8000612c:	bba080e7          	jalr	-1094(ra) # 80000ce2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006130:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006134:	89a6                	mv	s3,s1
    80006136:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006138:	02000a13          	li	s4,32
    8000613c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006140:	00391513          	slli	a0,s2,0x3
    80006144:	e3040593          	addi	a1,s0,-464
    80006148:	e3843783          	ld	a5,-456(s0)
    8000614c:	953e                	add	a0,a0,a5
    8000614e:	ffffd097          	auipc	ra,0xffffd
    80006152:	08a080e7          	jalr	138(ra) # 800031d8 <fetchaddr>
    80006156:	02054a63          	bltz	a0,8000618a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000615a:	e3043783          	ld	a5,-464(s0)
    8000615e:	c3b9                	beqz	a5,800061a4 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006160:	ffffb097          	auipc	ra,0xffffb
    80006164:	996080e7          	jalr	-1642(ra) # 80000af6 <kalloc>
    80006168:	85aa                	mv	a1,a0
    8000616a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000616e:	cd11                	beqz	a0,8000618a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006170:	6605                	lui	a2,0x1
    80006172:	e3043503          	ld	a0,-464(s0)
    80006176:	ffffd097          	auipc	ra,0xffffd
    8000617a:	0b4080e7          	jalr	180(ra) # 8000322a <fetchstr>
    8000617e:	00054663          	bltz	a0,8000618a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006182:	0905                	addi	s2,s2,1
    80006184:	09a1                	addi	s3,s3,8
    80006186:	fb491be3          	bne	s2,s4,8000613c <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000618a:	10048913          	addi	s2,s1,256
    8000618e:	6088                	ld	a0,0(s1)
    80006190:	c529                	beqz	a0,800061da <sys_exec+0xf8>
    kfree(argv[i]);
    80006192:	ffffb097          	auipc	ra,0xffffb
    80006196:	868080e7          	jalr	-1944(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000619a:	04a1                	addi	s1,s1,8
    8000619c:	ff2499e3          	bne	s1,s2,8000618e <sys_exec+0xac>
  return -1;
    800061a0:	597d                	li	s2,-1
    800061a2:	a82d                	j	800061dc <sys_exec+0xfa>
      argv[i] = 0;
    800061a4:	0a8e                	slli	s5,s5,0x3
    800061a6:	fc040793          	addi	a5,s0,-64
    800061aa:	9abe                	add	s5,s5,a5
    800061ac:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800061b0:	e4040593          	addi	a1,s0,-448
    800061b4:	f4040513          	addi	a0,s0,-192
    800061b8:	fffff097          	auipc	ra,0xfffff
    800061bc:	194080e7          	jalr	404(ra) # 8000534c <exec>
    800061c0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061c2:	10048993          	addi	s3,s1,256
    800061c6:	6088                	ld	a0,0(s1)
    800061c8:	c911                	beqz	a0,800061dc <sys_exec+0xfa>
    kfree(argv[i]);
    800061ca:	ffffb097          	auipc	ra,0xffffb
    800061ce:	830080e7          	jalr	-2000(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800061d2:	04a1                	addi	s1,s1,8
    800061d4:	ff3499e3          	bne	s1,s3,800061c6 <sys_exec+0xe4>
    800061d8:	a011                	j	800061dc <sys_exec+0xfa>
  return -1;
    800061da:	597d                	li	s2,-1
}
    800061dc:	854a                	mv	a0,s2
    800061de:	60be                	ld	ra,456(sp)
    800061e0:	641e                	ld	s0,448(sp)
    800061e2:	74fa                	ld	s1,440(sp)
    800061e4:	795a                	ld	s2,432(sp)
    800061e6:	79ba                	ld	s3,424(sp)
    800061e8:	7a1a                	ld	s4,416(sp)
    800061ea:	6afa                	ld	s5,408(sp)
    800061ec:	6179                	addi	sp,sp,464
    800061ee:	8082                	ret

00000000800061f0 <sys_pipe>:

uint64
sys_pipe(void)
{
    800061f0:	7139                	addi	sp,sp,-64
    800061f2:	fc06                	sd	ra,56(sp)
    800061f4:	f822                	sd	s0,48(sp)
    800061f6:	f426                	sd	s1,40(sp)
    800061f8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800061fa:	ffffc097          	auipc	ra,0xffffc
    800061fe:	820080e7          	jalr	-2016(ra) # 80001a1a <myproc>
    80006202:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006204:	fd840593          	addi	a1,s0,-40
    80006208:	4501                	li	a0,0
    8000620a:	ffffd097          	auipc	ra,0xffffd
    8000620e:	08a080e7          	jalr	138(ra) # 80003294 <argaddr>
    return -1;
    80006212:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006214:	0e054063          	bltz	a0,800062f4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006218:	fc840593          	addi	a1,s0,-56
    8000621c:	fd040513          	addi	a0,s0,-48
    80006220:	fffff097          	auipc	ra,0xfffff
    80006224:	df8080e7          	jalr	-520(ra) # 80005018 <pipealloc>
    return -1;
    80006228:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000622a:	0c054563          	bltz	a0,800062f4 <sys_pipe+0x104>
  fd0 = -1;
    8000622e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006232:	fd043503          	ld	a0,-48(s0)
    80006236:	fffff097          	auipc	ra,0xfffff
    8000623a:	508080e7          	jalr	1288(ra) # 8000573e <fdalloc>
    8000623e:	fca42223          	sw	a0,-60(s0)
    80006242:	08054c63          	bltz	a0,800062da <sys_pipe+0xea>
    80006246:	fc843503          	ld	a0,-56(s0)
    8000624a:	fffff097          	auipc	ra,0xfffff
    8000624e:	4f4080e7          	jalr	1268(ra) # 8000573e <fdalloc>
    80006252:	fca42023          	sw	a0,-64(s0)
    80006256:	06054863          	bltz	a0,800062c6 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000625a:	4691                	li	a3,4
    8000625c:	fc440613          	addi	a2,s0,-60
    80006260:	fd843583          	ld	a1,-40(s0)
    80006264:	68a8                	ld	a0,80(s1)
    80006266:	ffffb097          	auipc	ra,0xffffb
    8000626a:	40e080e7          	jalr	1038(ra) # 80001674 <copyout>
    8000626e:	02054063          	bltz	a0,8000628e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006272:	4691                	li	a3,4
    80006274:	fc040613          	addi	a2,s0,-64
    80006278:	fd843583          	ld	a1,-40(s0)
    8000627c:	0591                	addi	a1,a1,4
    8000627e:	68a8                	ld	a0,80(s1)
    80006280:	ffffb097          	auipc	ra,0xffffb
    80006284:	3f4080e7          	jalr	1012(ra) # 80001674 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006288:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000628a:	06055563          	bgez	a0,800062f4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000628e:	fc442783          	lw	a5,-60(s0)
    80006292:	07e9                	addi	a5,a5,26
    80006294:	078e                	slli	a5,a5,0x3
    80006296:	97a6                	add	a5,a5,s1
    80006298:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000629c:	fc042503          	lw	a0,-64(s0)
    800062a0:	0569                	addi	a0,a0,26
    800062a2:	050e                	slli	a0,a0,0x3
    800062a4:	9526                	add	a0,a0,s1
    800062a6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800062aa:	fd043503          	ld	a0,-48(s0)
    800062ae:	fffff097          	auipc	ra,0xfffff
    800062b2:	a3a080e7          	jalr	-1478(ra) # 80004ce8 <fileclose>
    fileclose(wf);
    800062b6:	fc843503          	ld	a0,-56(s0)
    800062ba:	fffff097          	auipc	ra,0xfffff
    800062be:	a2e080e7          	jalr	-1490(ra) # 80004ce8 <fileclose>
    return -1;
    800062c2:	57fd                	li	a5,-1
    800062c4:	a805                	j	800062f4 <sys_pipe+0x104>
    if(fd0 >= 0)
    800062c6:	fc442783          	lw	a5,-60(s0)
    800062ca:	0007c863          	bltz	a5,800062da <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800062ce:	01a78513          	addi	a0,a5,26
    800062d2:	050e                	slli	a0,a0,0x3
    800062d4:	9526                	add	a0,a0,s1
    800062d6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800062da:	fd043503          	ld	a0,-48(s0)
    800062de:	fffff097          	auipc	ra,0xfffff
    800062e2:	a0a080e7          	jalr	-1526(ra) # 80004ce8 <fileclose>
    fileclose(wf);
    800062e6:	fc843503          	ld	a0,-56(s0)
    800062ea:	fffff097          	auipc	ra,0xfffff
    800062ee:	9fe080e7          	jalr	-1538(ra) # 80004ce8 <fileclose>
    return -1;
    800062f2:	57fd                	li	a5,-1
}
    800062f4:	853e                	mv	a0,a5
    800062f6:	70e2                	ld	ra,56(sp)
    800062f8:	7442                	ld	s0,48(sp)
    800062fa:	74a2                	ld	s1,40(sp)
    800062fc:	6121                	addi	sp,sp,64
    800062fe:	8082                	ret

0000000080006300 <kernelvec>:
    80006300:	7111                	addi	sp,sp,-256
    80006302:	e006                	sd	ra,0(sp)
    80006304:	e40a                	sd	sp,8(sp)
    80006306:	e80e                	sd	gp,16(sp)
    80006308:	ec12                	sd	tp,24(sp)
    8000630a:	f016                	sd	t0,32(sp)
    8000630c:	f41a                	sd	t1,40(sp)
    8000630e:	f81e                	sd	t2,48(sp)
    80006310:	fc22                	sd	s0,56(sp)
    80006312:	e0a6                	sd	s1,64(sp)
    80006314:	e4aa                	sd	a0,72(sp)
    80006316:	e8ae                	sd	a1,80(sp)
    80006318:	ecb2                	sd	a2,88(sp)
    8000631a:	f0b6                	sd	a3,96(sp)
    8000631c:	f4ba                	sd	a4,104(sp)
    8000631e:	f8be                	sd	a5,112(sp)
    80006320:	fcc2                	sd	a6,120(sp)
    80006322:	e146                	sd	a7,128(sp)
    80006324:	e54a                	sd	s2,136(sp)
    80006326:	e94e                	sd	s3,144(sp)
    80006328:	ed52                	sd	s4,152(sp)
    8000632a:	f156                	sd	s5,160(sp)
    8000632c:	f55a                	sd	s6,168(sp)
    8000632e:	f95e                	sd	s7,176(sp)
    80006330:	fd62                	sd	s8,184(sp)
    80006332:	e1e6                	sd	s9,192(sp)
    80006334:	e5ea                	sd	s10,200(sp)
    80006336:	e9ee                	sd	s11,208(sp)
    80006338:	edf2                	sd	t3,216(sp)
    8000633a:	f1f6                	sd	t4,224(sp)
    8000633c:	f5fa                	sd	t5,232(sp)
    8000633e:	f9fe                	sd	t6,240(sp)
    80006340:	d63fc0ef          	jal	ra,800030a2 <kerneltrap>
    80006344:	6082                	ld	ra,0(sp)
    80006346:	6122                	ld	sp,8(sp)
    80006348:	61c2                	ld	gp,16(sp)
    8000634a:	7282                	ld	t0,32(sp)
    8000634c:	7322                	ld	t1,40(sp)
    8000634e:	73c2                	ld	t2,48(sp)
    80006350:	7462                	ld	s0,56(sp)
    80006352:	6486                	ld	s1,64(sp)
    80006354:	6526                	ld	a0,72(sp)
    80006356:	65c6                	ld	a1,80(sp)
    80006358:	6666                	ld	a2,88(sp)
    8000635a:	7686                	ld	a3,96(sp)
    8000635c:	7726                	ld	a4,104(sp)
    8000635e:	77c6                	ld	a5,112(sp)
    80006360:	7866                	ld	a6,120(sp)
    80006362:	688a                	ld	a7,128(sp)
    80006364:	692a                	ld	s2,136(sp)
    80006366:	69ca                	ld	s3,144(sp)
    80006368:	6a6a                	ld	s4,152(sp)
    8000636a:	7a8a                	ld	s5,160(sp)
    8000636c:	7b2a                	ld	s6,168(sp)
    8000636e:	7bca                	ld	s7,176(sp)
    80006370:	7c6a                	ld	s8,184(sp)
    80006372:	6c8e                	ld	s9,192(sp)
    80006374:	6d2e                	ld	s10,200(sp)
    80006376:	6dce                	ld	s11,208(sp)
    80006378:	6e6e                	ld	t3,216(sp)
    8000637a:	7e8e                	ld	t4,224(sp)
    8000637c:	7f2e                	ld	t5,232(sp)
    8000637e:	7fce                	ld	t6,240(sp)
    80006380:	6111                	addi	sp,sp,256
    80006382:	10200073          	sret
    80006386:	00000013          	nop
    8000638a:	00000013          	nop
    8000638e:	0001                	nop

0000000080006390 <timervec>:
    80006390:	34051573          	csrrw	a0,mscratch,a0
    80006394:	e10c                	sd	a1,0(a0)
    80006396:	e510                	sd	a2,8(a0)
    80006398:	e914                	sd	a3,16(a0)
    8000639a:	6d0c                	ld	a1,24(a0)
    8000639c:	7110                	ld	a2,32(a0)
    8000639e:	6194                	ld	a3,0(a1)
    800063a0:	96b2                	add	a3,a3,a2
    800063a2:	e194                	sd	a3,0(a1)
    800063a4:	4589                	li	a1,2
    800063a6:	14459073          	csrw	sip,a1
    800063aa:	6914                	ld	a3,16(a0)
    800063ac:	6510                	ld	a2,8(a0)
    800063ae:	610c                	ld	a1,0(a0)
    800063b0:	34051573          	csrrw	a0,mscratch,a0
    800063b4:	30200073          	mret
	...

00000000800063ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800063ba:	1141                	addi	sp,sp,-16
    800063bc:	e422                	sd	s0,8(sp)
    800063be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800063c0:	0c0007b7          	lui	a5,0xc000
    800063c4:	4705                	li	a4,1
    800063c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800063c8:	c3d8                	sw	a4,4(a5)
}
    800063ca:	6422                	ld	s0,8(sp)
    800063cc:	0141                	addi	sp,sp,16
    800063ce:	8082                	ret

00000000800063d0 <plicinithart>:

void
plicinithart(void)
{
    800063d0:	1141                	addi	sp,sp,-16
    800063d2:	e406                	sd	ra,8(sp)
    800063d4:	e022                	sd	s0,0(sp)
    800063d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063d8:	ffffb097          	auipc	ra,0xffffb
    800063dc:	616080e7          	jalr	1558(ra) # 800019ee <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800063e0:	0085171b          	slliw	a4,a0,0x8
    800063e4:	0c0027b7          	lui	a5,0xc002
    800063e8:	97ba                	add	a5,a5,a4
    800063ea:	40200713          	li	a4,1026
    800063ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800063f2:	00d5151b          	slliw	a0,a0,0xd
    800063f6:	0c2017b7          	lui	a5,0xc201
    800063fa:	953e                	add	a0,a0,a5
    800063fc:	00052023          	sw	zero,0(a0)
}
    80006400:	60a2                	ld	ra,8(sp)
    80006402:	6402                	ld	s0,0(sp)
    80006404:	0141                	addi	sp,sp,16
    80006406:	8082                	ret

0000000080006408 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006408:	1141                	addi	sp,sp,-16
    8000640a:	e406                	sd	ra,8(sp)
    8000640c:	e022                	sd	s0,0(sp)
    8000640e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006410:	ffffb097          	auipc	ra,0xffffb
    80006414:	5de080e7          	jalr	1502(ra) # 800019ee <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006418:	00d5179b          	slliw	a5,a0,0xd
    8000641c:	0c201537          	lui	a0,0xc201
    80006420:	953e                	add	a0,a0,a5
  return irq;
}
    80006422:	4148                	lw	a0,4(a0)
    80006424:	60a2                	ld	ra,8(sp)
    80006426:	6402                	ld	s0,0(sp)
    80006428:	0141                	addi	sp,sp,16
    8000642a:	8082                	ret

000000008000642c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000642c:	1101                	addi	sp,sp,-32
    8000642e:	ec06                	sd	ra,24(sp)
    80006430:	e822                	sd	s0,16(sp)
    80006432:	e426                	sd	s1,8(sp)
    80006434:	1000                	addi	s0,sp,32
    80006436:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006438:	ffffb097          	auipc	ra,0xffffb
    8000643c:	5b6080e7          	jalr	1462(ra) # 800019ee <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006440:	00d5151b          	slliw	a0,a0,0xd
    80006444:	0c2017b7          	lui	a5,0xc201
    80006448:	97aa                	add	a5,a5,a0
    8000644a:	c3c4                	sw	s1,4(a5)
}
    8000644c:	60e2                	ld	ra,24(sp)
    8000644e:	6442                	ld	s0,16(sp)
    80006450:	64a2                	ld	s1,8(sp)
    80006452:	6105                	addi	sp,sp,32
    80006454:	8082                	ret

0000000080006456 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006456:	1141                	addi	sp,sp,-16
    80006458:	e406                	sd	ra,8(sp)
    8000645a:	e022                	sd	s0,0(sp)
    8000645c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000645e:	479d                	li	a5,7
    80006460:	06a7c963          	blt	a5,a0,800064d2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006464:	0001d797          	auipc	a5,0x1d
    80006468:	b9c78793          	addi	a5,a5,-1124 # 80023000 <disk>
    8000646c:	00a78733          	add	a4,a5,a0
    80006470:	6789                	lui	a5,0x2
    80006472:	97ba                	add	a5,a5,a4
    80006474:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006478:	e7ad                	bnez	a5,800064e2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000647a:	00451793          	slli	a5,a0,0x4
    8000647e:	0001f717          	auipc	a4,0x1f
    80006482:	b8270713          	addi	a4,a4,-1150 # 80025000 <disk+0x2000>
    80006486:	6314                	ld	a3,0(a4)
    80006488:	96be                	add	a3,a3,a5
    8000648a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000648e:	6314                	ld	a3,0(a4)
    80006490:	96be                	add	a3,a3,a5
    80006492:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006496:	6314                	ld	a3,0(a4)
    80006498:	96be                	add	a3,a3,a5
    8000649a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000649e:	6318                	ld	a4,0(a4)
    800064a0:	97ba                	add	a5,a5,a4
    800064a2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800064a6:	0001d797          	auipc	a5,0x1d
    800064aa:	b5a78793          	addi	a5,a5,-1190 # 80023000 <disk>
    800064ae:	97aa                	add	a5,a5,a0
    800064b0:	6509                	lui	a0,0x2
    800064b2:	953e                	add	a0,a0,a5
    800064b4:	4785                	li	a5,1
    800064b6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800064ba:	0001f517          	auipc	a0,0x1f
    800064be:	b5e50513          	addi	a0,a0,-1186 # 80025018 <disk+0x2018>
    800064c2:	ffffc097          	auipc	ra,0xffffc
    800064c6:	0a6080e7          	jalr	166(ra) # 80002568 <wakeup>
}
    800064ca:	60a2                	ld	ra,8(sp)
    800064cc:	6402                	ld	s0,0(sp)
    800064ce:	0141                	addi	sp,sp,16
    800064d0:	8082                	ret
    panic("free_desc 1");
    800064d2:	00002517          	auipc	a0,0x2
    800064d6:	3de50513          	addi	a0,a0,990 # 800088b0 <syscalls+0x338>
    800064da:	ffffa097          	auipc	ra,0xffffa
    800064de:	066080e7          	jalr	102(ra) # 80000540 <panic>
    panic("free_desc 2");
    800064e2:	00002517          	auipc	a0,0x2
    800064e6:	3de50513          	addi	a0,a0,990 # 800088c0 <syscalls+0x348>
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	056080e7          	jalr	86(ra) # 80000540 <panic>

00000000800064f2 <virtio_disk_init>:
{
    800064f2:	1101                	addi	sp,sp,-32
    800064f4:	ec06                	sd	ra,24(sp)
    800064f6:	e822                	sd	s0,16(sp)
    800064f8:	e426                	sd	s1,8(sp)
    800064fa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800064fc:	00002597          	auipc	a1,0x2
    80006500:	3d458593          	addi	a1,a1,980 # 800088d0 <syscalls+0x358>
    80006504:	0001f517          	auipc	a0,0x1f
    80006508:	c2450513          	addi	a0,a0,-988 # 80025128 <disk+0x2128>
    8000650c:	ffffa097          	auipc	ra,0xffffa
    80006510:	64a080e7          	jalr	1610(ra) # 80000b56 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006514:	100017b7          	lui	a5,0x10001
    80006518:	4398                	lw	a4,0(a5)
    8000651a:	2701                	sext.w	a4,a4
    8000651c:	747277b7          	lui	a5,0x74727
    80006520:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006524:	0ef71163          	bne	a4,a5,80006606 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006528:	100017b7          	lui	a5,0x10001
    8000652c:	43dc                	lw	a5,4(a5)
    8000652e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006530:	4705                	li	a4,1
    80006532:	0ce79a63          	bne	a5,a4,80006606 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006536:	100017b7          	lui	a5,0x10001
    8000653a:	479c                	lw	a5,8(a5)
    8000653c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000653e:	4709                	li	a4,2
    80006540:	0ce79363          	bne	a5,a4,80006606 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006544:	100017b7          	lui	a5,0x10001
    80006548:	47d8                	lw	a4,12(a5)
    8000654a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000654c:	554d47b7          	lui	a5,0x554d4
    80006550:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006554:	0af71963          	bne	a4,a5,80006606 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006558:	100017b7          	lui	a5,0x10001
    8000655c:	4705                	li	a4,1
    8000655e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006560:	470d                	li	a4,3
    80006562:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006564:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006566:	c7ffe737          	lui	a4,0xc7ffe
    8000656a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000656e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006570:	2701                	sext.w	a4,a4
    80006572:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006574:	472d                	li	a4,11
    80006576:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006578:	473d                	li	a4,15
    8000657a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000657c:	6705                	lui	a4,0x1
    8000657e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006580:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006584:	5bdc                	lw	a5,52(a5)
    80006586:	2781                	sext.w	a5,a5
  if(max == 0)
    80006588:	c7d9                	beqz	a5,80006616 <virtio_disk_init+0x124>
  if(max < NUM)
    8000658a:	471d                	li	a4,7
    8000658c:	08f77d63          	bgeu	a4,a5,80006626 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006590:	100014b7          	lui	s1,0x10001
    80006594:	47a1                	li	a5,8
    80006596:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006598:	6609                	lui	a2,0x2
    8000659a:	4581                	li	a1,0
    8000659c:	0001d517          	auipc	a0,0x1d
    800065a0:	a6450513          	addi	a0,a0,-1436 # 80023000 <disk>
    800065a4:	ffffa097          	auipc	ra,0xffffa
    800065a8:	73e080e7          	jalr	1854(ra) # 80000ce2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800065ac:	0001d717          	auipc	a4,0x1d
    800065b0:	a5470713          	addi	a4,a4,-1452 # 80023000 <disk>
    800065b4:	00c75793          	srli	a5,a4,0xc
    800065b8:	2781                	sext.w	a5,a5
    800065ba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800065bc:	0001f797          	auipc	a5,0x1f
    800065c0:	a4478793          	addi	a5,a5,-1468 # 80025000 <disk+0x2000>
    800065c4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800065c6:	0001d717          	auipc	a4,0x1d
    800065ca:	aba70713          	addi	a4,a4,-1350 # 80023080 <disk+0x80>
    800065ce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800065d0:	0001e717          	auipc	a4,0x1e
    800065d4:	a3070713          	addi	a4,a4,-1488 # 80024000 <disk+0x1000>
    800065d8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800065da:	4705                	li	a4,1
    800065dc:	00e78c23          	sb	a4,24(a5)
    800065e0:	00e78ca3          	sb	a4,25(a5)
    800065e4:	00e78d23          	sb	a4,26(a5)
    800065e8:	00e78da3          	sb	a4,27(a5)
    800065ec:	00e78e23          	sb	a4,28(a5)
    800065f0:	00e78ea3          	sb	a4,29(a5)
    800065f4:	00e78f23          	sb	a4,30(a5)
    800065f8:	00e78fa3          	sb	a4,31(a5)
}
    800065fc:	60e2                	ld	ra,24(sp)
    800065fe:	6442                	ld	s0,16(sp)
    80006600:	64a2                	ld	s1,8(sp)
    80006602:	6105                	addi	sp,sp,32
    80006604:	8082                	ret
    panic("could not find virtio disk");
    80006606:	00002517          	auipc	a0,0x2
    8000660a:	2da50513          	addi	a0,a0,730 # 800088e0 <syscalls+0x368>
    8000660e:	ffffa097          	auipc	ra,0xffffa
    80006612:	f32080e7          	jalr	-206(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006616:	00002517          	auipc	a0,0x2
    8000661a:	2ea50513          	addi	a0,a0,746 # 80008900 <syscalls+0x388>
    8000661e:	ffffa097          	auipc	ra,0xffffa
    80006622:	f22080e7          	jalr	-222(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006626:	00002517          	auipc	a0,0x2
    8000662a:	2fa50513          	addi	a0,a0,762 # 80008920 <syscalls+0x3a8>
    8000662e:	ffffa097          	auipc	ra,0xffffa
    80006632:	f12080e7          	jalr	-238(ra) # 80000540 <panic>

0000000080006636 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006636:	7159                	addi	sp,sp,-112
    80006638:	f486                	sd	ra,104(sp)
    8000663a:	f0a2                	sd	s0,96(sp)
    8000663c:	eca6                	sd	s1,88(sp)
    8000663e:	e8ca                	sd	s2,80(sp)
    80006640:	e4ce                	sd	s3,72(sp)
    80006642:	e0d2                	sd	s4,64(sp)
    80006644:	fc56                	sd	s5,56(sp)
    80006646:	f85a                	sd	s6,48(sp)
    80006648:	f45e                	sd	s7,40(sp)
    8000664a:	f062                	sd	s8,32(sp)
    8000664c:	ec66                	sd	s9,24(sp)
    8000664e:	e86a                	sd	s10,16(sp)
    80006650:	1880                	addi	s0,sp,112
    80006652:	892a                	mv	s2,a0
    80006654:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006656:	00c52c83          	lw	s9,12(a0)
    8000665a:	001c9c9b          	slliw	s9,s9,0x1
    8000665e:	1c82                	slli	s9,s9,0x20
    80006660:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006664:	0001f517          	auipc	a0,0x1f
    80006668:	ac450513          	addi	a0,a0,-1340 # 80025128 <disk+0x2128>
    8000666c:	ffffa097          	auipc	ra,0xffffa
    80006670:	57a080e7          	jalr	1402(ra) # 80000be6 <acquire>
  for(int i = 0; i < 3; i++){
    80006674:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006676:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006678:	0001db97          	auipc	s7,0x1d
    8000667c:	988b8b93          	addi	s7,s7,-1656 # 80023000 <disk>
    80006680:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006682:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006684:	8a4e                	mv	s4,s3
    80006686:	a051                	j	8000670a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006688:	00fb86b3          	add	a3,s7,a5
    8000668c:	96da                	add	a3,a3,s6
    8000668e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006692:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006694:	0207c563          	bltz	a5,800066be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006698:	2485                	addiw	s1,s1,1
    8000669a:	0711                	addi	a4,a4,4
    8000669c:	25548063          	beq	s1,s5,800068dc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800066a0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800066a2:	0001f697          	auipc	a3,0x1f
    800066a6:	97668693          	addi	a3,a3,-1674 # 80025018 <disk+0x2018>
    800066aa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800066ac:	0006c583          	lbu	a1,0(a3)
    800066b0:	fde1                	bnez	a1,80006688 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800066b2:	2785                	addiw	a5,a5,1
    800066b4:	0685                	addi	a3,a3,1
    800066b6:	ff879be3          	bne	a5,s8,800066ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800066ba:	57fd                	li	a5,-1
    800066bc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800066be:	02905a63          	blez	s1,800066f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066c2:	f9042503          	lw	a0,-112(s0)
    800066c6:	00000097          	auipc	ra,0x0
    800066ca:	d90080e7          	jalr	-624(ra) # 80006456 <free_desc>
      for(int j = 0; j < i; j++)
    800066ce:	4785                	li	a5,1
    800066d0:	0297d163          	bge	a5,s1,800066f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066d4:	f9442503          	lw	a0,-108(s0)
    800066d8:	00000097          	auipc	ra,0x0
    800066dc:	d7e080e7          	jalr	-642(ra) # 80006456 <free_desc>
      for(int j = 0; j < i; j++)
    800066e0:	4789                	li	a5,2
    800066e2:	0097d863          	bge	a5,s1,800066f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800066e6:	f9842503          	lw	a0,-104(s0)
    800066ea:	00000097          	auipc	ra,0x0
    800066ee:	d6c080e7          	jalr	-660(ra) # 80006456 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066f2:	0001f597          	auipc	a1,0x1f
    800066f6:	a3658593          	addi	a1,a1,-1482 # 80025128 <disk+0x2128>
    800066fa:	0001f517          	auipc	a0,0x1f
    800066fe:	91e50513          	addi	a0,a0,-1762 # 80025018 <disk+0x2018>
    80006702:	ffffc097          	auipc	ra,0xffffc
    80006706:	c5e080e7          	jalr	-930(ra) # 80002360 <sleep>
  for(int i = 0; i < 3; i++){
    8000670a:	f9040713          	addi	a4,s0,-112
    8000670e:	84ce                	mv	s1,s3
    80006710:	bf41                	j	800066a0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006712:	20058713          	addi	a4,a1,512
    80006716:	00471693          	slli	a3,a4,0x4
    8000671a:	0001d717          	auipc	a4,0x1d
    8000671e:	8e670713          	addi	a4,a4,-1818 # 80023000 <disk>
    80006722:	9736                	add	a4,a4,a3
    80006724:	4685                	li	a3,1
    80006726:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000672a:	20058713          	addi	a4,a1,512
    8000672e:	00471693          	slli	a3,a4,0x4
    80006732:	0001d717          	auipc	a4,0x1d
    80006736:	8ce70713          	addi	a4,a4,-1842 # 80023000 <disk>
    8000673a:	9736                	add	a4,a4,a3
    8000673c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006740:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006744:	7679                	lui	a2,0xffffe
    80006746:	963e                	add	a2,a2,a5
    80006748:	0001f697          	auipc	a3,0x1f
    8000674c:	8b868693          	addi	a3,a3,-1864 # 80025000 <disk+0x2000>
    80006750:	6298                	ld	a4,0(a3)
    80006752:	9732                	add	a4,a4,a2
    80006754:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006756:	6298                	ld	a4,0(a3)
    80006758:	9732                	add	a4,a4,a2
    8000675a:	4541                	li	a0,16
    8000675c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000675e:	6298                	ld	a4,0(a3)
    80006760:	9732                	add	a4,a4,a2
    80006762:	4505                	li	a0,1
    80006764:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006768:	f9442703          	lw	a4,-108(s0)
    8000676c:	6288                	ld	a0,0(a3)
    8000676e:	962a                	add	a2,a2,a0
    80006770:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006774:	0712                	slli	a4,a4,0x4
    80006776:	6290                	ld	a2,0(a3)
    80006778:	963a                	add	a2,a2,a4
    8000677a:	05890513          	addi	a0,s2,88
    8000677e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006780:	6294                	ld	a3,0(a3)
    80006782:	96ba                	add	a3,a3,a4
    80006784:	40000613          	li	a2,1024
    80006788:	c690                	sw	a2,8(a3)
  if(write)
    8000678a:	140d0063          	beqz	s10,800068ca <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000678e:	0001f697          	auipc	a3,0x1f
    80006792:	8726b683          	ld	a3,-1934(a3) # 80025000 <disk+0x2000>
    80006796:	96ba                	add	a3,a3,a4
    80006798:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000679c:	0001d817          	auipc	a6,0x1d
    800067a0:	86480813          	addi	a6,a6,-1948 # 80023000 <disk>
    800067a4:	0001f517          	auipc	a0,0x1f
    800067a8:	85c50513          	addi	a0,a0,-1956 # 80025000 <disk+0x2000>
    800067ac:	6114                	ld	a3,0(a0)
    800067ae:	96ba                	add	a3,a3,a4
    800067b0:	00c6d603          	lhu	a2,12(a3)
    800067b4:	00166613          	ori	a2,a2,1
    800067b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800067bc:	f9842683          	lw	a3,-104(s0)
    800067c0:	6110                	ld	a2,0(a0)
    800067c2:	9732                	add	a4,a4,a2
    800067c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800067c8:	20058613          	addi	a2,a1,512
    800067cc:	0612                	slli	a2,a2,0x4
    800067ce:	9642                	add	a2,a2,a6
    800067d0:	577d                	li	a4,-1
    800067d2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067d6:	00469713          	slli	a4,a3,0x4
    800067da:	6114                	ld	a3,0(a0)
    800067dc:	96ba                	add	a3,a3,a4
    800067de:	03078793          	addi	a5,a5,48
    800067e2:	97c2                	add	a5,a5,a6
    800067e4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800067e6:	611c                	ld	a5,0(a0)
    800067e8:	97ba                	add	a5,a5,a4
    800067ea:	4685                	li	a3,1
    800067ec:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067ee:	611c                	ld	a5,0(a0)
    800067f0:	97ba                	add	a5,a5,a4
    800067f2:	4809                	li	a6,2
    800067f4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800067f8:	611c                	ld	a5,0(a0)
    800067fa:	973e                	add	a4,a4,a5
    800067fc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006800:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006804:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006808:	6518                	ld	a4,8(a0)
    8000680a:	00275783          	lhu	a5,2(a4)
    8000680e:	8b9d                	andi	a5,a5,7
    80006810:	0786                	slli	a5,a5,0x1
    80006812:	97ba                	add	a5,a5,a4
    80006814:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006818:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000681c:	6518                	ld	a4,8(a0)
    8000681e:	00275783          	lhu	a5,2(a4)
    80006822:	2785                	addiw	a5,a5,1
    80006824:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006828:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000682c:	100017b7          	lui	a5,0x10001
    80006830:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006834:	00492703          	lw	a4,4(s2)
    80006838:	4785                	li	a5,1
    8000683a:	02f71163          	bne	a4,a5,8000685c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000683e:	0001f997          	auipc	s3,0x1f
    80006842:	8ea98993          	addi	s3,s3,-1814 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006846:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006848:	85ce                	mv	a1,s3
    8000684a:	854a                	mv	a0,s2
    8000684c:	ffffc097          	auipc	ra,0xffffc
    80006850:	b14080e7          	jalr	-1260(ra) # 80002360 <sleep>
  while(b->disk == 1) {
    80006854:	00492783          	lw	a5,4(s2)
    80006858:	fe9788e3          	beq	a5,s1,80006848 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000685c:	f9042903          	lw	s2,-112(s0)
    80006860:	20090793          	addi	a5,s2,512
    80006864:	00479713          	slli	a4,a5,0x4
    80006868:	0001c797          	auipc	a5,0x1c
    8000686c:	79878793          	addi	a5,a5,1944 # 80023000 <disk>
    80006870:	97ba                	add	a5,a5,a4
    80006872:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006876:	0001e997          	auipc	s3,0x1e
    8000687a:	78a98993          	addi	s3,s3,1930 # 80025000 <disk+0x2000>
    8000687e:	00491713          	slli	a4,s2,0x4
    80006882:	0009b783          	ld	a5,0(s3)
    80006886:	97ba                	add	a5,a5,a4
    80006888:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000688c:	854a                	mv	a0,s2
    8000688e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006892:	00000097          	auipc	ra,0x0
    80006896:	bc4080e7          	jalr	-1084(ra) # 80006456 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000689a:	8885                	andi	s1,s1,1
    8000689c:	f0ed                	bnez	s1,8000687e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000689e:	0001f517          	auipc	a0,0x1f
    800068a2:	88a50513          	addi	a0,a0,-1910 # 80025128 <disk+0x2128>
    800068a6:	ffffa097          	auipc	ra,0xffffa
    800068aa:	3f4080e7          	jalr	1012(ra) # 80000c9a <release>
}
    800068ae:	70a6                	ld	ra,104(sp)
    800068b0:	7406                	ld	s0,96(sp)
    800068b2:	64e6                	ld	s1,88(sp)
    800068b4:	6946                	ld	s2,80(sp)
    800068b6:	69a6                	ld	s3,72(sp)
    800068b8:	6a06                	ld	s4,64(sp)
    800068ba:	7ae2                	ld	s5,56(sp)
    800068bc:	7b42                	ld	s6,48(sp)
    800068be:	7ba2                	ld	s7,40(sp)
    800068c0:	7c02                	ld	s8,32(sp)
    800068c2:	6ce2                	ld	s9,24(sp)
    800068c4:	6d42                	ld	s10,16(sp)
    800068c6:	6165                	addi	sp,sp,112
    800068c8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800068ca:	0001e697          	auipc	a3,0x1e
    800068ce:	7366b683          	ld	a3,1846(a3) # 80025000 <disk+0x2000>
    800068d2:	96ba                	add	a3,a3,a4
    800068d4:	4609                	li	a2,2
    800068d6:	00c69623          	sh	a2,12(a3)
    800068da:	b5c9                	j	8000679c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800068dc:	f9042583          	lw	a1,-112(s0)
    800068e0:	20058793          	addi	a5,a1,512
    800068e4:	0792                	slli	a5,a5,0x4
    800068e6:	0001c517          	auipc	a0,0x1c
    800068ea:	7c250513          	addi	a0,a0,1986 # 800230a8 <disk+0xa8>
    800068ee:	953e                	add	a0,a0,a5
  if(write)
    800068f0:	e20d11e3          	bnez	s10,80006712 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800068f4:	20058713          	addi	a4,a1,512
    800068f8:	00471693          	slli	a3,a4,0x4
    800068fc:	0001c717          	auipc	a4,0x1c
    80006900:	70470713          	addi	a4,a4,1796 # 80023000 <disk>
    80006904:	9736                	add	a4,a4,a3
    80006906:	0a072423          	sw	zero,168(a4)
    8000690a:	b505                	j	8000672a <virtio_disk_rw+0xf4>

000000008000690c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000690c:	1101                	addi	sp,sp,-32
    8000690e:	ec06                	sd	ra,24(sp)
    80006910:	e822                	sd	s0,16(sp)
    80006912:	e426                	sd	s1,8(sp)
    80006914:	e04a                	sd	s2,0(sp)
    80006916:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006918:	0001f517          	auipc	a0,0x1f
    8000691c:	81050513          	addi	a0,a0,-2032 # 80025128 <disk+0x2128>
    80006920:	ffffa097          	auipc	ra,0xffffa
    80006924:	2c6080e7          	jalr	710(ra) # 80000be6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006928:	10001737          	lui	a4,0x10001
    8000692c:	533c                	lw	a5,96(a4)
    8000692e:	8b8d                	andi	a5,a5,3
    80006930:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006932:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006936:	0001e797          	auipc	a5,0x1e
    8000693a:	6ca78793          	addi	a5,a5,1738 # 80025000 <disk+0x2000>
    8000693e:	6b94                	ld	a3,16(a5)
    80006940:	0207d703          	lhu	a4,32(a5)
    80006944:	0026d783          	lhu	a5,2(a3)
    80006948:	06f70163          	beq	a4,a5,800069aa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000694c:	0001c917          	auipc	s2,0x1c
    80006950:	6b490913          	addi	s2,s2,1716 # 80023000 <disk>
    80006954:	0001e497          	auipc	s1,0x1e
    80006958:	6ac48493          	addi	s1,s1,1708 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000695c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006960:	6898                	ld	a4,16(s1)
    80006962:	0204d783          	lhu	a5,32(s1)
    80006966:	8b9d                	andi	a5,a5,7
    80006968:	078e                	slli	a5,a5,0x3
    8000696a:	97ba                	add	a5,a5,a4
    8000696c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000696e:	20078713          	addi	a4,a5,512
    80006972:	0712                	slli	a4,a4,0x4
    80006974:	974a                	add	a4,a4,s2
    80006976:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000697a:	e731                	bnez	a4,800069c6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000697c:	20078793          	addi	a5,a5,512
    80006980:	0792                	slli	a5,a5,0x4
    80006982:	97ca                	add	a5,a5,s2
    80006984:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006986:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000698a:	ffffc097          	auipc	ra,0xffffc
    8000698e:	bde080e7          	jalr	-1058(ra) # 80002568 <wakeup>

    disk.used_idx += 1;
    80006992:	0204d783          	lhu	a5,32(s1)
    80006996:	2785                	addiw	a5,a5,1
    80006998:	17c2                	slli	a5,a5,0x30
    8000699a:	93c1                	srli	a5,a5,0x30
    8000699c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800069a0:	6898                	ld	a4,16(s1)
    800069a2:	00275703          	lhu	a4,2(a4)
    800069a6:	faf71be3          	bne	a4,a5,8000695c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800069aa:	0001e517          	auipc	a0,0x1e
    800069ae:	77e50513          	addi	a0,a0,1918 # 80025128 <disk+0x2128>
    800069b2:	ffffa097          	auipc	ra,0xffffa
    800069b6:	2e8080e7          	jalr	744(ra) # 80000c9a <release>
}
    800069ba:	60e2                	ld	ra,24(sp)
    800069bc:	6442                	ld	s0,16(sp)
    800069be:	64a2                	ld	s1,8(sp)
    800069c0:	6902                	ld	s2,0(sp)
    800069c2:	6105                	addi	sp,sp,32
    800069c4:	8082                	ret
      panic("virtio_disk_intr status");
    800069c6:	00002517          	auipc	a0,0x2
    800069ca:	f7a50513          	addi	a0,a0,-134 # 80008940 <syscalls+0x3c8>
    800069ce:	ffffa097          	auipc	ra,0xffffa
    800069d2:	b72080e7          	jalr	-1166(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
