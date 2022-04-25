
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
    80000068:	1fc78793          	addi	a5,a5,508 # 80006260 <timervec>
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
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	7c4080e7          	jalr	1988(ra) # 800028f0 <either_copyin>
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
    800001c8:	82e080e7          	jalr	-2002(ra) # 800019f2 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	2781                	sext.w	a5,a5
    800001d0:	e7b5                	bnez	a5,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85ce                	mv	a1,s3
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	10e080e7          	jalr	270(ra) # 800022e4 <sleep>
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
    80000216:	688080e7          	jalr	1672(ra) # 8000289a <either_copyout>
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
    800002f8:	652080e7          	jalr	1618(ra) # 80002946 <procdump>
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
    8000044c:	082080e7          	jalr	130(ra) # 800024ca <wakeup>
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
    800008a6:	c28080e7          	jalr	-984(ra) # 800024ca <wakeup>
    
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
    80000932:	9b6080e7          	jalr	-1610(ra) # 800022e4 <sleep>
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
    80000b84:	e56080e7          	jalr	-426(ra) # 800019d6 <mycpu>
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
    80000bb6:	e24080e7          	jalr	-476(ra) # 800019d6 <mycpu>
    80000bba:	5d3c                	lw	a5,120(a0)
    80000bbc:	cf89                	beqz	a5,80000bd6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbe:	00001097          	auipc	ra,0x1
    80000bc2:	e18080e7          	jalr	-488(ra) # 800019d6 <mycpu>
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
    80000bda:	e00080e7          	jalr	-512(ra) # 800019d6 <mycpu>
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
    80000c1a:	dc0080e7          	jalr	-576(ra) # 800019d6 <mycpu>
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
    80000c46:	d94080e7          	jalr	-620(ra) # 800019d6 <mycpu>
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
    80000e9c:	b2e080e7          	jalr	-1234(ra) # 800019c6 <cpuid>
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
    80000eb8:	b12080e7          	jalr	-1262(ra) # 800019c6 <cpuid>
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
    80000eda:	e14080e7          	jalr	-492(ra) # 80002cea <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ede:	00005097          	auipc	ra,0x5
    80000ee2:	3c2080e7          	jalr	962(ra) # 800062a0 <plicinithart>
  }

  scheduler();        
    80000ee6:	00001097          	auipc	ra,0x1
    80000eea:	0d0080e7          	jalr	208(ra) # 80001fb6 <scheduler>
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
    80000f52:	d74080e7          	jalr	-652(ra) # 80002cc2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	d94080e7          	jalr	-620(ra) # 80002cea <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5e:	00005097          	auipc	ra,0x5
    80000f62:	32c080e7          	jalr	812(ra) # 8000628a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f66:	00005097          	auipc	ra,0x5
    80000f6a:	33a080e7          	jalr	826(ra) # 800062a0 <plicinithart>
    binit();         // buffer cache
    80000f6e:	00002097          	auipc	ra,0x2
    80000f72:	50e080e7          	jalr	1294(ra) # 8000347c <binit>
    iinit();         // inode table
    80000f76:	00003097          	auipc	ra,0x3
    80000f7a:	b9e080e7          	jalr	-1122(ra) # 80003b14 <iinit>
    fileinit();      // file table
    80000f7e:	00004097          	auipc	ra,0x4
    80000f82:	b48080e7          	jalr	-1208(ra) # 80004ac6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f86:	00005097          	auipc	ra,0x5
    80000f8a:	43c080e7          	jalr	1084(ra) # 800063c2 <virtio_disk_init>
    userinit();      // first user process
    80000f8e:	00001097          	auipc	ra,0x1
    80000f92:	d46080e7          	jalr	-698(ra) # 80001cd4 <userinit>
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
  process_count = 0;
    80001902:	00007797          	auipc	a5,0x7
    80001906:	7407a123          	sw	zero,1858(a5) # 80009044 <process_count>
  program_time = 0;
    8000190a:	00007797          	auipc	a5,0x7
    8000190e:	7207ab23          	sw	zero,1846(a5) # 80009040 <program_time>
  cpu_utilization = 0;
    80001912:	00007797          	auipc	a5,0x7
    80001916:	7207a523          	sw	zero,1834(a5) # 8000903c <cpu_utilization>

  //acquire(&tickslock);
  
  //release(&tickslock);

  initlock(&pid_lock, "nextpid");
    8000191a:	00007597          	auipc	a1,0x7
    8000191e:	8c658593          	addi	a1,a1,-1850 # 800081e0 <digits+0x1a0>
    80001922:	00010517          	auipc	a0,0x10
    80001926:	99e50513          	addi	a0,a0,-1634 # 800112c0 <pid_lock>
    8000192a:	fffff097          	auipc	ra,0xfffff
    8000192e:	22c080e7          	jalr	556(ra) # 80000b56 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001932:	00007597          	auipc	a1,0x7
    80001936:	8b658593          	addi	a1,a1,-1866 # 800081e8 <digits+0x1a8>
    8000193a:	00010517          	auipc	a0,0x10
    8000193e:	99e50513          	addi	a0,a0,-1634 # 800112d8 <wait_lock>
    80001942:	fffff097          	auipc	ra,0xfffff
    80001946:	214080e7          	jalr	532(ra) # 80000b56 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194a:	00010497          	auipc	s1,0x10
    8000194e:	da648493          	addi	s1,s1,-602 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    80001952:	00007b17          	auipc	s6,0x7
    80001956:	8a6b0b13          	addi	s6,s6,-1882 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000195a:	8aa6                	mv	s5,s1
    8000195c:	00006a17          	auipc	s4,0x6
    80001960:	6a4a0a13          	addi	s4,s4,1700 # 80008000 <etext>
    80001964:	04000937          	lui	s2,0x4000
    80001968:	197d                	addi	s2,s2,-1
    8000196a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196c:	00016997          	auipc	s3,0x16
    80001970:	f8498993          	addi	s3,s3,-124 # 800178f0 <tickslock>
      initlock(&p->lock, "proc");
    80001974:	85da                	mv	a1,s6
    80001976:	8526                	mv	a0,s1
    80001978:	fffff097          	auipc	ra,0xfffff
    8000197c:	1de080e7          	jalr	478(ra) # 80000b56 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001980:	415487b3          	sub	a5,s1,s5
    80001984:	878d                	srai	a5,a5,0x3
    80001986:	000a3703          	ld	a4,0(s4)
    8000198a:	02e787b3          	mul	a5,a5,a4
    8000198e:	2785                	addiw	a5,a5,1
    80001990:	00d7979b          	slliw	a5,a5,0xd
    80001994:	40f907b3          	sub	a5,s2,a5
    80001998:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000199a:	18848493          	addi	s1,s1,392
    8000199e:	fd349be3          	bne	s1,s3,80001974 <procinit+0x9e>
  }
  start_time = ticks;
    800019a2:	00007797          	auipc	a5,0x7
    800019a6:	6b27a783          	lw	a5,1714(a5) # 80009054 <ticks>
    800019aa:	00007717          	auipc	a4,0x7
    800019ae:	68f72723          	sw	a5,1678(a4) # 80009038 <start_time>
}
    800019b2:	70e2                	ld	ra,56(sp)
    800019b4:	7442                	ld	s0,48(sp)
    800019b6:	74a2                	ld	s1,40(sp)
    800019b8:	7902                	ld	s2,32(sp)
    800019ba:	69e2                	ld	s3,24(sp)
    800019bc:	6a42                	ld	s4,16(sp)
    800019be:	6aa2                	ld	s5,8(sp)
    800019c0:	6b02                	ld	s6,0(sp)
    800019c2:	6121                	addi	sp,sp,64
    800019c4:	8082                	ret

00000000800019c6 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019c6:	1141                	addi	sp,sp,-16
    800019c8:	e422                	sd	s0,8(sp)
    800019ca:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019cc:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019ce:	2501                	sext.w	a0,a0
    800019d0:	6422                	ld	s0,8(sp)
    800019d2:	0141                	addi	sp,sp,16
    800019d4:	8082                	ret

00000000800019d6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019d6:	1141                	addi	sp,sp,-16
    800019d8:	e422                	sd	s0,8(sp)
    800019da:	0800                	addi	s0,sp,16
    800019dc:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019de:	2781                	sext.w	a5,a5
    800019e0:	079e                	slli	a5,a5,0x7
  return c;
}
    800019e2:	00010517          	auipc	a0,0x10
    800019e6:	90e50513          	addi	a0,a0,-1778 # 800112f0 <cpus>
    800019ea:	953e                	add	a0,a0,a5
    800019ec:	6422                	ld	s0,8(sp)
    800019ee:	0141                	addi	sp,sp,16
    800019f0:	8082                	ret

00000000800019f2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019f2:	1101                	addi	sp,sp,-32
    800019f4:	ec06                	sd	ra,24(sp)
    800019f6:	e822                	sd	s0,16(sp)
    800019f8:	e426                	sd	s1,8(sp)
    800019fa:	1000                	addi	s0,sp,32
  push_off();
    800019fc:	fffff097          	auipc	ra,0xfffff
    80001a00:	19e080e7          	jalr	414(ra) # 80000b9a <push_off>
    80001a04:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a06:	2781                	sext.w	a5,a5
    80001a08:	079e                	slli	a5,a5,0x7
    80001a0a:	00010717          	auipc	a4,0x10
    80001a0e:	8b670713          	addi	a4,a4,-1866 # 800112c0 <pid_lock>
    80001a12:	97ba                	add	a5,a5,a4
    80001a14:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	224080e7          	jalr	548(ra) # 80000c3a <pop_off>
  return p;
}
    80001a1e:	8526                	mv	a0,s1
    80001a20:	60e2                	ld	ra,24(sp)
    80001a22:	6442                	ld	s0,16(sp)
    80001a24:	64a2                	ld	s1,8(sp)
    80001a26:	6105                	addi	sp,sp,32
    80001a28:	8082                	ret

0000000080001a2a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a2a:	1141                	addi	sp,sp,-16
    80001a2c:	e406                	sd	ra,8(sp)
    80001a2e:	e022                	sd	s0,0(sp)
    80001a30:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a32:	00000097          	auipc	ra,0x0
    80001a36:	fc0080e7          	jalr	-64(ra) # 800019f2 <myproc>
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	260080e7          	jalr	608(ra) # 80000c9a <release>

  if (first) {
    80001a42:	00007797          	auipc	a5,0x7
    80001a46:	f1e7a783          	lw	a5,-226(a5) # 80008960 <first.1705>
    80001a4a:	eb89                	bnez	a5,80001a5c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a4c:	00001097          	auipc	ra,0x1
    80001a50:	2b6080e7          	jalr	694(ra) # 80002d02 <usertrapret>
}
    80001a54:	60a2                	ld	ra,8(sp)
    80001a56:	6402                	ld	s0,0(sp)
    80001a58:	0141                	addi	sp,sp,16
    80001a5a:	8082                	ret
    first = 0;
    80001a5c:	00007797          	auipc	a5,0x7
    80001a60:	f007a223          	sw	zero,-252(a5) # 80008960 <first.1705>
    fsinit(ROOTDEV);
    80001a64:	4505                	li	a0,1
    80001a66:	00002097          	auipc	ra,0x2
    80001a6a:	02e080e7          	jalr	46(ra) # 80003a94 <fsinit>
    80001a6e:	bff9                	j	80001a4c <forkret+0x22>

0000000080001a70 <allocpid>:
allocpid() {
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a7c:	00010917          	auipc	s2,0x10
    80001a80:	84490913          	addi	s2,s2,-1980 # 800112c0 <pid_lock>
    80001a84:	854a                	mv	a0,s2
    80001a86:	fffff097          	auipc	ra,0xfffff
    80001a8a:	160080e7          	jalr	352(ra) # 80000be6 <acquire>
  pid = nextpid;
    80001a8e:	00007797          	auipc	a5,0x7
    80001a92:	ed678793          	addi	a5,a5,-298 # 80008964 <nextpid>
    80001a96:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a98:	0014871b          	addiw	a4,s1,1
    80001a9c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a9e:	854a                	mv	a0,s2
    80001aa0:	fffff097          	auipc	ra,0xfffff
    80001aa4:	1fa080e7          	jalr	506(ra) # 80000c9a <release>
}
    80001aa8:	8526                	mv	a0,s1
    80001aaa:	60e2                	ld	ra,24(sp)
    80001aac:	6442                	ld	s0,16(sp)
    80001aae:	64a2                	ld	s1,8(sp)
    80001ab0:	6902                	ld	s2,0(sp)
    80001ab2:	6105                	addi	sp,sp,32
    80001ab4:	8082                	ret

0000000080001ab6 <proc_pagetable>:
{
    80001ab6:	1101                	addi	sp,sp,-32
    80001ab8:	ec06                	sd	ra,24(sp)
    80001aba:	e822                	sd	s0,16(sp)
    80001abc:	e426                	sd	s1,8(sp)
    80001abe:	e04a                	sd	s2,0(sp)
    80001ac0:	1000                	addi	s0,sp,32
    80001ac2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ac4:	00000097          	auipc	ra,0x0
    80001ac8:	878080e7          	jalr	-1928(ra) # 8000133c <uvmcreate>
    80001acc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ace:	c121                	beqz	a0,80001b0e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ad0:	4729                	li	a4,10
    80001ad2:	00005697          	auipc	a3,0x5
    80001ad6:	52e68693          	addi	a3,a3,1326 # 80007000 <_trampoline>
    80001ada:	6605                	lui	a2,0x1
    80001adc:	040005b7          	lui	a1,0x4000
    80001ae0:	15fd                	addi	a1,a1,-1
    80001ae2:	05b2                	slli	a1,a1,0xc
    80001ae4:	fffff097          	auipc	ra,0xfffff
    80001ae8:	5ce080e7          	jalr	1486(ra) # 800010b2 <mappages>
    80001aec:	02054863          	bltz	a0,80001b1c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001af0:	4719                	li	a4,6
    80001af2:	05893683          	ld	a3,88(s2)
    80001af6:	6605                	lui	a2,0x1
    80001af8:	020005b7          	lui	a1,0x2000
    80001afc:	15fd                	addi	a1,a1,-1
    80001afe:	05b6                	slli	a1,a1,0xd
    80001b00:	8526                	mv	a0,s1
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	5b0080e7          	jalr	1456(ra) # 800010b2 <mappages>
    80001b0a:	02054163          	bltz	a0,80001b2c <proc_pagetable+0x76>
}
    80001b0e:	8526                	mv	a0,s1
    80001b10:	60e2                	ld	ra,24(sp)
    80001b12:	6442                	ld	s0,16(sp)
    80001b14:	64a2                	ld	s1,8(sp)
    80001b16:	6902                	ld	s2,0(sp)
    80001b18:	6105                	addi	sp,sp,32
    80001b1a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b1c:	4581                	li	a1,0
    80001b1e:	8526                	mv	a0,s1
    80001b20:	00000097          	auipc	ra,0x0
    80001b24:	a18080e7          	jalr	-1512(ra) # 80001538 <uvmfree>
    return 0;
    80001b28:	4481                	li	s1,0
    80001b2a:	b7d5                	j	80001b0e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b2c:	4681                	li	a3,0
    80001b2e:	4605                	li	a2,1
    80001b30:	040005b7          	lui	a1,0x4000
    80001b34:	15fd                	addi	a1,a1,-1
    80001b36:	05b2                	slli	a1,a1,0xc
    80001b38:	8526                	mv	a0,s1
    80001b3a:	fffff097          	auipc	ra,0xfffff
    80001b3e:	73e080e7          	jalr	1854(ra) # 80001278 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b42:	4581                	li	a1,0
    80001b44:	8526                	mv	a0,s1
    80001b46:	00000097          	auipc	ra,0x0
    80001b4a:	9f2080e7          	jalr	-1550(ra) # 80001538 <uvmfree>
    return 0;
    80001b4e:	4481                	li	s1,0
    80001b50:	bf7d                	j	80001b0e <proc_pagetable+0x58>

0000000080001b52 <proc_freepagetable>:
{
    80001b52:	1101                	addi	sp,sp,-32
    80001b54:	ec06                	sd	ra,24(sp)
    80001b56:	e822                	sd	s0,16(sp)
    80001b58:	e426                	sd	s1,8(sp)
    80001b5a:	e04a                	sd	s2,0(sp)
    80001b5c:	1000                	addi	s0,sp,32
    80001b5e:	84aa                	mv	s1,a0
    80001b60:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b62:	4681                	li	a3,0
    80001b64:	4605                	li	a2,1
    80001b66:	040005b7          	lui	a1,0x4000
    80001b6a:	15fd                	addi	a1,a1,-1
    80001b6c:	05b2                	slli	a1,a1,0xc
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	70a080e7          	jalr	1802(ra) # 80001278 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b76:	4681                	li	a3,0
    80001b78:	4605                	li	a2,1
    80001b7a:	020005b7          	lui	a1,0x2000
    80001b7e:	15fd                	addi	a1,a1,-1
    80001b80:	05b6                	slli	a1,a1,0xd
    80001b82:	8526                	mv	a0,s1
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	6f4080e7          	jalr	1780(ra) # 80001278 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b8c:	85ca                	mv	a1,s2
    80001b8e:	8526                	mv	a0,s1
    80001b90:	00000097          	auipc	ra,0x0
    80001b94:	9a8080e7          	jalr	-1624(ra) # 80001538 <uvmfree>
}
    80001b98:	60e2                	ld	ra,24(sp)
    80001b9a:	6442                	ld	s0,16(sp)
    80001b9c:	64a2                	ld	s1,8(sp)
    80001b9e:	6902                	ld	s2,0(sp)
    80001ba0:	6105                	addi	sp,sp,32
    80001ba2:	8082                	ret

0000000080001ba4 <freeproc>:
{
    80001ba4:	1101                	addi	sp,sp,-32
    80001ba6:	ec06                	sd	ra,24(sp)
    80001ba8:	e822                	sd	s0,16(sp)
    80001baa:	e426                	sd	s1,8(sp)
    80001bac:	1000                	addi	s0,sp,32
    80001bae:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bb0:	6d28                	ld	a0,88(a0)
    80001bb2:	c509                	beqz	a0,80001bbc <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	e46080e7          	jalr	-442(ra) # 800009fa <kfree>
  p->trapframe = 0;
    80001bbc:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bc0:	68a8                	ld	a0,80(s1)
    80001bc2:	c511                	beqz	a0,80001bce <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bc4:	64ac                	ld	a1,72(s1)
    80001bc6:	00000097          	auipc	ra,0x0
    80001bca:	f8c080e7          	jalr	-116(ra) # 80001b52 <proc_freepagetable>
  p->pagetable = 0;
    80001bce:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bd2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bd6:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bda:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bde:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001be2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001be6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bea:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bee:	0004ac23          	sw	zero,24(s1)
}
    80001bf2:	60e2                	ld	ra,24(sp)
    80001bf4:	6442                	ld	s0,16(sp)
    80001bf6:	64a2                	ld	s1,8(sp)
    80001bf8:	6105                	addi	sp,sp,32
    80001bfa:	8082                	ret

0000000080001bfc <allocproc>:
{
    80001bfc:	1101                	addi	sp,sp,-32
    80001bfe:	ec06                	sd	ra,24(sp)
    80001c00:	e822                	sd	s0,16(sp)
    80001c02:	e426                	sd	s1,8(sp)
    80001c04:	e04a                	sd	s2,0(sp)
    80001c06:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c08:	00010497          	auipc	s1,0x10
    80001c0c:	ae848493          	addi	s1,s1,-1304 # 800116f0 <proc>
    80001c10:	00016917          	auipc	s2,0x16
    80001c14:	ce090913          	addi	s2,s2,-800 # 800178f0 <tickslock>
    acquire(&p->lock);
    80001c18:	8526                	mv	a0,s1
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	fcc080e7          	jalr	-52(ra) # 80000be6 <acquire>
    if(p->state == UNUSED) {
    80001c22:	4c9c                	lw	a5,24(s1)
    80001c24:	2781                	sext.w	a5,a5
    80001c26:	cf81                	beqz	a5,80001c3e <allocproc+0x42>
      release(&p->lock);
    80001c28:	8526                	mv	a0,s1
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	070080e7          	jalr	112(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c32:	18848493          	addi	s1,s1,392
    80001c36:	ff2491e3          	bne	s1,s2,80001c18 <allocproc+0x1c>
  return 0;
    80001c3a:	4481                	li	s1,0
    80001c3c:	a8a9                	j	80001c96 <allocproc+0x9a>
  p->pid = allocpid();
    80001c3e:	00000097          	auipc	ra,0x0
    80001c42:	e32080e7          	jalr	-462(ra) # 80001a70 <allocpid>
    80001c46:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c48:	4785                	li	a5,1
    80001c4a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	eaa080e7          	jalr	-342(ra) # 80000af6 <kalloc>
    80001c54:	892a                	mv	s2,a0
    80001c56:	eca8                	sd	a0,88(s1)
    80001c58:	c531                	beqz	a0,80001ca4 <allocproc+0xa8>
  p->pagetable = proc_pagetable(p);
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	00000097          	auipc	ra,0x0
    80001c60:	e5a080e7          	jalr	-422(ra) # 80001ab6 <proc_pagetable>
    80001c64:	892a                	mv	s2,a0
    80001c66:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c68:	c931                	beqz	a0,80001cbc <allocproc+0xc0>
  memset(&p->context, 0, sizeof(p->context));
    80001c6a:	07000613          	li	a2,112
    80001c6e:	4581                	li	a1,0
    80001c70:	06048513          	addi	a0,s1,96
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	06e080e7          	jalr	110(ra) # 80000ce2 <memset>
  p->context.ra = (uint64)forkret;
    80001c7c:	00000797          	auipc	a5,0x0
    80001c80:	dae78793          	addi	a5,a5,-594 # 80001a2a <forkret>
    80001c84:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c86:	60bc                	ld	a5,64(s1)
    80001c88:	6705                	lui	a4,0x1
    80001c8a:	97ba                	add	a5,a5,a4
    80001c8c:	f4bc                	sd	a5,104(s1)
  p->mean_ticks = 0;
    80001c8e:	1604a423          	sw	zero,360(s1)
  p->last_ticks = 0;
    80001c92:	1604a623          	sw	zero,364(s1)
}
    80001c96:	8526                	mv	a0,s1
    80001c98:	60e2                	ld	ra,24(sp)
    80001c9a:	6442                	ld	s0,16(sp)
    80001c9c:	64a2                	ld	s1,8(sp)
    80001c9e:	6902                	ld	s2,0(sp)
    80001ca0:	6105                	addi	sp,sp,32
    80001ca2:	8082                	ret
    freeproc(p);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	efe080e7          	jalr	-258(ra) # 80001ba4 <freeproc>
    release(&p->lock);
    80001cae:	8526                	mv	a0,s1
    80001cb0:	fffff097          	auipc	ra,0xfffff
    80001cb4:	fea080e7          	jalr	-22(ra) # 80000c9a <release>
    return 0;
    80001cb8:	84ca                	mv	s1,s2
    80001cba:	bff1                	j	80001c96 <allocproc+0x9a>
    freeproc(p);
    80001cbc:	8526                	mv	a0,s1
    80001cbe:	00000097          	auipc	ra,0x0
    80001cc2:	ee6080e7          	jalr	-282(ra) # 80001ba4 <freeproc>
    release(&p->lock);
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	fd2080e7          	jalr	-46(ra) # 80000c9a <release>
    return 0;
    80001cd0:	84ca                	mv	s1,s2
    80001cd2:	b7d1                	j	80001c96 <allocproc+0x9a>

0000000080001cd4 <userinit>:
{
    80001cd4:	1101                	addi	sp,sp,-32
    80001cd6:	ec06                	sd	ra,24(sp)
    80001cd8:	e822                	sd	s0,16(sp)
    80001cda:	e426                	sd	s1,8(sp)
    80001cdc:	e04a                	sd	s2,0(sp)
    80001cde:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	f1c080e7          	jalr	-228(ra) # 80001bfc <allocproc>
    80001ce8:	84aa                	mv	s1,a0
  initproc = p;
    80001cea:	00007797          	auipc	a5,0x7
    80001cee:	34a7b323          	sd	a0,838(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cf2:	03400613          	li	a2,52
    80001cf6:	00007597          	auipc	a1,0x7
    80001cfa:	c7a58593          	addi	a1,a1,-902 # 80008970 <initcode>
    80001cfe:	6928                	ld	a0,80(a0)
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	66a080e7          	jalr	1642(ra) # 8000136a <uvminit>
  p->sz = PGSIZE;
    80001d08:	6785                	lui	a5,0x1
    80001d0a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d0c:	6cb8                	ld	a4,88(s1)
    80001d0e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d12:	6cb8                	ld	a4,88(s1)
    80001d14:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d16:	4641                	li	a2,16
    80001d18:	00006597          	auipc	a1,0x6
    80001d1c:	4e858593          	addi	a1,a1,1256 # 80008200 <digits+0x1c0>
    80001d20:	15848513          	addi	a0,s1,344
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	110080e7          	jalr	272(ra) # 80000e34 <safestrcpy>
  p->cwd = namei("/");
    80001d2c:	00006517          	auipc	a0,0x6
    80001d30:	4e450513          	addi	a0,a0,1252 # 80008210 <digits+0x1d0>
    80001d34:	00002097          	auipc	ra,0x2
    80001d38:	78e080e7          	jalr	1934(ra) # 800044c2 <namei>
    80001d3c:	14a4b823          	sd	a0,336(s1)
  p->runnable_time = 0;
    80001d40:	1604ae23          	sw	zero,380(s1)
  p->running_time = 0;
    80001d44:	1604ac23          	sw	zero,376(s1)
  p -> sleeping_time = 0;
    80001d48:	1604aa23          	sw	zero,372(s1)
  p->last_update_time = ticks;
    80001d4c:	00007917          	auipc	s2,0x7
    80001d50:	30890913          	addi	s2,s2,776 # 80009054 <ticks>
    80001d54:	00092783          	lw	a5,0(s2)
    80001d58:	18f4a023          	sw	a5,384(s1)
  p->state = RUNNABLE;
    80001d5c:	478d                	li	a5,3
    80001d5e:	cc9c                	sw	a5,24(s1)
  acquire(&tickslock);
    80001d60:	00016517          	auipc	a0,0x16
    80001d64:	b9050513          	addi	a0,a0,-1136 # 800178f0 <tickslock>
    80001d68:	fffff097          	auipc	ra,0xfffff
    80001d6c:	e7e080e7          	jalr	-386(ra) # 80000be6 <acquire>
  p->last_runable_time = ticks;
    80001d70:	00092783          	lw	a5,0(s2)
    80001d74:	16f4a823          	sw	a5,368(s1)
  release(&tickslock);
    80001d78:	00016517          	auipc	a0,0x16
    80001d7c:	b7850513          	addi	a0,a0,-1160 # 800178f0 <tickslock>
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	f1a080e7          	jalr	-230(ra) # 80000c9a <release>
  release(&p->lock);
    80001d88:	8526                	mv	a0,s1
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	f10080e7          	jalr	-240(ra) # 80000c9a <release>
}
    80001d92:	60e2                	ld	ra,24(sp)
    80001d94:	6442                	ld	s0,16(sp)
    80001d96:	64a2                	ld	s1,8(sp)
    80001d98:	6902                	ld	s2,0(sp)
    80001d9a:	6105                	addi	sp,sp,32
    80001d9c:	8082                	ret

0000000080001d9e <growproc>:
{
    80001d9e:	1101                	addi	sp,sp,-32
    80001da0:	ec06                	sd	ra,24(sp)
    80001da2:	e822                	sd	s0,16(sp)
    80001da4:	e426                	sd	s1,8(sp)
    80001da6:	e04a                	sd	s2,0(sp)
    80001da8:	1000                	addi	s0,sp,32
    80001daa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	c46080e7          	jalr	-954(ra) # 800019f2 <myproc>
    80001db4:	892a                	mv	s2,a0
  sz = p->sz;
    80001db6:	652c                	ld	a1,72(a0)
    80001db8:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001dbc:	00904f63          	bgtz	s1,80001dda <growproc+0x3c>
  } else if(n < 0){
    80001dc0:	0204cc63          	bltz	s1,80001df8 <growproc+0x5a>
  p->sz = sz;
    80001dc4:	1602                	slli	a2,a2,0x20
    80001dc6:	9201                	srli	a2,a2,0x20
    80001dc8:	04c93423          	sd	a2,72(s2)
  return 0;
    80001dcc:	4501                	li	a0,0
}
    80001dce:	60e2                	ld	ra,24(sp)
    80001dd0:	6442                	ld	s0,16(sp)
    80001dd2:	64a2                	ld	s1,8(sp)
    80001dd4:	6902                	ld	s2,0(sp)
    80001dd6:	6105                	addi	sp,sp,32
    80001dd8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dda:	9e25                	addw	a2,a2,s1
    80001ddc:	1602                	slli	a2,a2,0x20
    80001dde:	9201                	srli	a2,a2,0x20
    80001de0:	1582                	slli	a1,a1,0x20
    80001de2:	9181                	srli	a1,a1,0x20
    80001de4:	6928                	ld	a0,80(a0)
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	63e080e7          	jalr	1598(ra) # 80001424 <uvmalloc>
    80001dee:	0005061b          	sext.w	a2,a0
    80001df2:	fa69                	bnez	a2,80001dc4 <growproc+0x26>
      return -1;
    80001df4:	557d                	li	a0,-1
    80001df6:	bfe1                	j	80001dce <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001df8:	9e25                	addw	a2,a2,s1
    80001dfa:	1602                	slli	a2,a2,0x20
    80001dfc:	9201                	srli	a2,a2,0x20
    80001dfe:	1582                	slli	a1,a1,0x20
    80001e00:	9181                	srli	a1,a1,0x20
    80001e02:	6928                	ld	a0,80(a0)
    80001e04:	fffff097          	auipc	ra,0xfffff
    80001e08:	5d8080e7          	jalr	1496(ra) # 800013dc <uvmdealloc>
    80001e0c:	0005061b          	sext.w	a2,a0
    80001e10:	bf55                	j	80001dc4 <growproc+0x26>

0000000080001e12 <fork>:
{
    80001e12:	7179                	addi	sp,sp,-48
    80001e14:	f406                	sd	ra,40(sp)
    80001e16:	f022                	sd	s0,32(sp)
    80001e18:	ec26                	sd	s1,24(sp)
    80001e1a:	e84a                	sd	s2,16(sp)
    80001e1c:	e44e                	sd	s3,8(sp)
    80001e1e:	e052                	sd	s4,0(sp)
    80001e20:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	bd0080e7          	jalr	-1072(ra) # 800019f2 <myproc>
    80001e2a:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80001e2c:	00000097          	auipc	ra,0x0
    80001e30:	dd0080e7          	jalr	-560(ra) # 80001bfc <allocproc>
    80001e34:	16050f63          	beqz	a0,80001fb2 <fork+0x1a0>
    80001e38:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e3a:	0489b603          	ld	a2,72(s3)
    80001e3e:	692c                	ld	a1,80(a0)
    80001e40:	0509b503          	ld	a0,80(s3)
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	72c080e7          	jalr	1836(ra) # 80001570 <uvmcopy>
    80001e4c:	04054663          	bltz	a0,80001e98 <fork+0x86>
  np->sz = p->sz;
    80001e50:	0489b783          	ld	a5,72(s3)
    80001e54:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    80001e58:	0589b683          	ld	a3,88(s3)
    80001e5c:	87b6                	mv	a5,a3
    80001e5e:	05893703          	ld	a4,88(s2)
    80001e62:	12068693          	addi	a3,a3,288
    80001e66:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e6a:	6788                	ld	a0,8(a5)
    80001e6c:	6b8c                	ld	a1,16(a5)
    80001e6e:	6f90                	ld	a2,24(a5)
    80001e70:	01073023          	sd	a6,0(a4)
    80001e74:	e708                	sd	a0,8(a4)
    80001e76:	eb0c                	sd	a1,16(a4)
    80001e78:	ef10                	sd	a2,24(a4)
    80001e7a:	02078793          	addi	a5,a5,32
    80001e7e:	02070713          	addi	a4,a4,32
    80001e82:	fed792e3          	bne	a5,a3,80001e66 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e86:	05893783          	ld	a5,88(s2)
    80001e8a:	0607b823          	sd	zero,112(a5)
    80001e8e:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e92:	15000a13          	li	s4,336
    80001e96:	a03d                	j	80001ec4 <fork+0xb2>
    freeproc(np);
    80001e98:	854a                	mv	a0,s2
    80001e9a:	00000097          	auipc	ra,0x0
    80001e9e:	d0a080e7          	jalr	-758(ra) # 80001ba4 <freeproc>
    release(&np->lock);
    80001ea2:	854a                	mv	a0,s2
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	df6080e7          	jalr	-522(ra) # 80000c9a <release>
    return -1;
    80001eac:	5a7d                	li	s4,-1
    80001eae:	a8cd                	j	80001fa0 <fork+0x18e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001eb0:	00003097          	auipc	ra,0x3
    80001eb4:	ca8080e7          	jalr	-856(ra) # 80004b58 <filedup>
    80001eb8:	009907b3          	add	a5,s2,s1
    80001ebc:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ebe:	04a1                	addi	s1,s1,8
    80001ec0:	01448763          	beq	s1,s4,80001ece <fork+0xbc>
    if(p->ofile[i])
    80001ec4:	009987b3          	add	a5,s3,s1
    80001ec8:	6388                	ld	a0,0(a5)
    80001eca:	f17d                	bnez	a0,80001eb0 <fork+0x9e>
    80001ecc:	bfcd                	j	80001ebe <fork+0xac>
  np->cwd = idup(p->cwd);
    80001ece:	1509b503          	ld	a0,336(s3)
    80001ed2:	00002097          	auipc	ra,0x2
    80001ed6:	dfc080e7          	jalr	-516(ra) # 80003cce <idup>
    80001eda:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ede:	4641                	li	a2,16
    80001ee0:	15898593          	addi	a1,s3,344
    80001ee4:	15890513          	addi	a0,s2,344
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	f4c080e7          	jalr	-180(ra) # 80000e34 <safestrcpy>
  pid = np->pid;
    80001ef0:	03092a03          	lw	s4,48(s2)
  np->last_ticks = 0;
    80001ef4:	16092623          	sw	zero,364(s2)
  np->mean_ticks = 0;
    80001ef8:	16092423          	sw	zero,360(s2)
  release(&np->lock);
    80001efc:	854a                	mv	a0,s2
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	d9c080e7          	jalr	-612(ra) # 80000c9a <release>
  acquire(&wait_lock);
    80001f06:	0000f497          	auipc	s1,0xf
    80001f0a:	3d248493          	addi	s1,s1,978 # 800112d8 <wait_lock>
    80001f0e:	8526                	mv	a0,s1
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	cd6080e7          	jalr	-810(ra) # 80000be6 <acquire>
  np->parent = p;
    80001f18:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    80001f1c:	8526                	mv	a0,s1
    80001f1e:	fffff097          	auipc	ra,0xfffff
    80001f22:	d7c080e7          	jalr	-644(ra) # 80000c9a <release>
  acquire(&np->lock);
    80001f26:	854a                	mv	a0,s2
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	cbe080e7          	jalr	-834(ra) # 80000be6 <acquire>
  np->runnable_time = 0;
    80001f30:	16092e23          	sw	zero,380(s2)
  np->running_time = 0;
    80001f34:	16092c23          	sw	zero,376(s2)
  np -> sleeping_time = 0;
    80001f38:	16092a23          	sw	zero,372(s2)
  acquire(&tickslock);
    80001f3c:	00016517          	auipc	a0,0x16
    80001f40:	9b450513          	addi	a0,a0,-1612 # 800178f0 <tickslock>
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	ca2080e7          	jalr	-862(ra) # 80000be6 <acquire>
  np->last_update_time = ticks;
    80001f4c:	00007497          	auipc	s1,0x7
    80001f50:	10848493          	addi	s1,s1,264 # 80009054 <ticks>
    80001f54:	409c                	lw	a5,0(s1)
    80001f56:	18f92023          	sw	a5,384(s2)
  release(&tickslock);
    80001f5a:	00016517          	auipc	a0,0x16
    80001f5e:	99650513          	addi	a0,a0,-1642 # 800178f0 <tickslock>
    80001f62:	fffff097          	auipc	ra,0xfffff
    80001f66:	d38080e7          	jalr	-712(ra) # 80000c9a <release>
  np->state = RUNNABLE;
    80001f6a:	478d                	li	a5,3
    80001f6c:	00f92c23          	sw	a5,24(s2)
  acquire(&tickslock);
    80001f70:	00016517          	auipc	a0,0x16
    80001f74:	98050513          	addi	a0,a0,-1664 # 800178f0 <tickslock>
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	c6e080e7          	jalr	-914(ra) # 80000be6 <acquire>
  p->last_runable_time = ticks;
    80001f80:	409c                	lw	a5,0(s1)
    80001f82:	16f9a823          	sw	a5,368(s3)
  release(&tickslock);
    80001f86:	00016517          	auipc	a0,0x16
    80001f8a:	96a50513          	addi	a0,a0,-1686 # 800178f0 <tickslock>
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	d0c080e7          	jalr	-756(ra) # 80000c9a <release>
  release(&np->lock);
    80001f96:	854a                	mv	a0,s2
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	d02080e7          	jalr	-766(ra) # 80000c9a <release>
}
    80001fa0:	8552                	mv	a0,s4
    80001fa2:	70a2                	ld	ra,40(sp)
    80001fa4:	7402                	ld	s0,32(sp)
    80001fa6:	64e2                	ld	s1,24(sp)
    80001fa8:	6942                	ld	s2,16(sp)
    80001faa:	69a2                	ld	s3,8(sp)
    80001fac:	6a02                	ld	s4,0(sp)
    80001fae:	6145                	addi	sp,sp,48
    80001fb0:	8082                	ret
    return -1;
    80001fb2:	5a7d                	li	s4,-1
    80001fb4:	b7f5                	j	80001fa0 <fork+0x18e>

0000000080001fb6 <scheduler>:
{
    80001fb6:	7159                	addi	sp,sp,-112
    80001fb8:	f486                	sd	ra,104(sp)
    80001fba:	f0a2                	sd	s0,96(sp)
    80001fbc:	eca6                	sd	s1,88(sp)
    80001fbe:	e8ca                	sd	s2,80(sp)
    80001fc0:	e4ce                	sd	s3,72(sp)
    80001fc2:	e0d2                	sd	s4,64(sp)
    80001fc4:	fc56                	sd	s5,56(sp)
    80001fc6:	f85a                	sd	s6,48(sp)
    80001fc8:	f45e                	sd	s7,40(sp)
    80001fca:	f062                	sd	s8,32(sp)
    80001fcc:	ec66                	sd	s9,24(sp)
    80001fce:	e86a                	sd	s10,16(sp)
    80001fd0:	e46e                	sd	s11,8(sp)
    80001fd2:	1880                	addi	s0,sp,112
    80001fd4:	8792                	mv	a5,tp
  int id = r_tp();
    80001fd6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fd8:	00779d93          	slli	s11,a5,0x7
    80001fdc:	0000f717          	auipc	a4,0xf
    80001fe0:	2e470713          	addi	a4,a4,740 # 800112c0 <pid_lock>
    80001fe4:	976e                	add	a4,a4,s11
    80001fe6:	02073823          	sd	zero,48(a4)
         swtch(&c->context, &hp->context);
    80001fea:	0000f717          	auipc	a4,0xf
    80001fee:	30e70713          	addi	a4,a4,782 # 800112f8 <cpus+0x8>
    80001ff2:	9dba                	add	s11,s11,a4
    while(paused)
    80001ff4:	00007c17          	auipc	s8,0x7
    80001ff8:	038c0c13          	addi	s8,s8,56 # 8000902c <paused>
      if(ticks >= pause_interval)
    80001ffc:	00007b97          	auipc	s7,0x7
    80002000:	058b8b93          	addi	s7,s7,88 # 80009054 <ticks>
         c->proc = hp;
    80002004:	079e                	slli	a5,a5,0x7
    80002006:	0000fb17          	auipc	s6,0xf
    8000200a:	2bab0b13          	addi	s6,s6,698 # 800112c0 <pid_lock>
    8000200e:	9b3e                	add	s6,s6,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002010:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002014:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002018:	10079073          	csrw	sstatus,a5
    while(paused)
    8000201c:	000c2783          	lw	a5,0(s8)
    80002020:	2781                	sext.w	a5,a5
    80002022:	cba1                	beqz	a5,80002072 <scheduler+0xbc>
      acquire(&tickslock);
    80002024:	00016497          	auipc	s1,0x16
    80002028:	8cc48493          	addi	s1,s1,-1844 # 800178f0 <tickslock>
      if(ticks >= pause_interval)
    8000202c:	00007917          	auipc	s2,0x7
    80002030:	ffc90913          	addi	s2,s2,-4 # 80009028 <pause_interval>
    80002034:	a811                	j	80002048 <scheduler+0x92>
      release(&tickslock);
    80002036:	8526                	mv	a0,s1
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	c62080e7          	jalr	-926(ra) # 80000c9a <release>
    while(paused)
    80002040:	000c2783          	lw	a5,0(s8)
    80002044:	2781                	sext.w	a5,a5
    80002046:	c795                	beqz	a5,80002072 <scheduler+0xbc>
      acquire(&tickslock);
    80002048:	8526                	mv	a0,s1
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	b9c080e7          	jalr	-1124(ra) # 80000be6 <acquire>
      if(ticks >= pause_interval)
    80002052:	00092783          	lw	a5,0(s2)
    80002056:	2781                	sext.w	a5,a5
    80002058:	000ba703          	lw	a4,0(s7)
    8000205c:	fcf76de3          	bltu	a4,a5,80002036 <scheduler+0x80>
        paused ^= paused;
    80002060:	000c2703          	lw	a4,0(s8)
    80002064:	000c2783          	lw	a5,0(s8)
    80002068:	8fb9                	xor	a5,a5,a4
    8000206a:	2781                	sext.w	a5,a5
    8000206c:	00fc2023          	sw	a5,0(s8)
    80002070:	b7d9                	j	80002036 <scheduler+0x80>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002072:	0000f917          	auipc	s2,0xf
    80002076:	67e90913          	addi	s2,s2,1662 # 800116f0 <proc>
      if(p->state == RUNNABLE) 
    8000207a:	4a8d                	li	s5,3
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    8000207c:	00016a17          	auipc	s4,0x16
    80002080:	874a0a13          	addi	s4,s4,-1932 # 800178f0 <tickslock>
          if(hp->state == RUNNING){
    80002084:	4d11                	li	s10,4
          if(hp->state == SLEEPING){
    80002086:	4c89                	li	s9,2
    80002088:	a06d                	j	80002132 <scheduler+0x17c>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    8000208a:	18890493          	addi	s1,s2,392
    8000208e:	0544f363          	bgeu	s1,s4,800020d4 <scheduler+0x11e>
    80002092:	89ca                	mv	s3,s2
    80002094:	a811                	j	800020a8 <scheduler+0xf2>
            release(&c->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	c02080e7          	jalr	-1022(ra) # 80000c9a <release>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    800020a0:	18848493          	addi	s1,s1,392
    800020a4:	0344f963          	bgeu	s1,s4,800020d6 <scheduler+0x120>
           acquire(&c->lock);
    800020a8:	8526                	mv	a0,s1
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	b3c080e7          	jalr	-1220(ra) # 80000be6 <acquire>
           if((c->state == RUNNABLE) && (c->mean_ticks < hp->mean_ticks))
    800020b2:	4c9c                	lw	a5,24(s1)
    800020b4:	2781                	sext.w	a5,a5
    800020b6:	ff5790e3          	bne	a5,s5,80002096 <scheduler+0xe0>
    800020ba:	1684a703          	lw	a4,360(s1)
    800020be:	1689a783          	lw	a5,360(s3)
    800020c2:	fcf77ae3          	bgeu	a4,a5,80002096 <scheduler+0xe0>
             release(&hp->lock);
    800020c6:	854e                	mv	a0,s3
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	bd2080e7          	jalr	-1070(ra) # 80000c9a <release>
             hp = c;
    800020d0:	89a6                	mv	s3,s1
    800020d2:	b7f9                	j	800020a0 <scheduler+0xea>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    800020d4:	89ca                	mv	s3,s2
          int diff = ticks - p->last_update_time;
    800020d6:	000ba703          	lw	a4,0(s7)
    800020da:	18092783          	lw	a5,384(s2)
    800020de:	40f707bb          	subw	a5,a4,a5
          p->last_update_time = ticks;
    800020e2:	18e92023          	sw	a4,384(s2)
          if(hp->state == RUNNABLE){
    800020e6:	0189a703          	lw	a4,24(s3)
    800020ea:	2701                	sext.w	a4,a4
    800020ec:	07570363          	beq	a4,s5,80002152 <scheduler+0x19c>
          if(hp->state == RUNNING){
    800020f0:	0189a703          	lw	a4,24(s3)
    800020f4:	2701                	sext.w	a4,a4
    800020f6:	07a70463          	beq	a4,s10,8000215e <scheduler+0x1a8>
          if(hp->state == SLEEPING){
    800020fa:	0189a703          	lw	a4,24(s3)
    800020fe:	2701                	sext.w	a4,a4
    80002100:	07970563          	beq	a4,s9,8000216a <scheduler+0x1b4>
         hp->state = RUNNING;
    80002104:	4791                	li	a5,4
    80002106:	00f9ac23          	sw	a5,24(s3)
         c->proc = hp;
    8000210a:	033b3823          	sd	s3,48(s6)
         swtch(&c->context, &hp->context);
    8000210e:	06098593          	addi	a1,s3,96
    80002112:	856e                	mv	a0,s11
    80002114:	00001097          	auipc	ra,0x1
    80002118:	b44080e7          	jalr	-1212(ra) # 80002c58 <swtch>
         c->proc = 0;
    8000211c:	020b3823          	sd	zero,48(s6)
         release(&hp->lock);          
    80002120:	854e                	mv	a0,s3
    80002122:	fffff097          	auipc	ra,0xfffff
    80002126:	b78080e7          	jalr	-1160(ra) # 80000c9a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000212a:	18890913          	addi	s2,s2,392
    8000212e:	ef4901e3          	beq	s2,s4,80002010 <scheduler+0x5a>
      acquire(&p->lock);
    80002132:	854a                	mv	a0,s2
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	ab2080e7          	jalr	-1358(ra) # 80000be6 <acquire>
      if(p->state == RUNNABLE) 
    8000213c:	01892783          	lw	a5,24(s2)
    80002140:	2781                	sext.w	a5,a5
    80002142:	f55784e3          	beq	a5,s5,8000208a <scheduler+0xd4>
        release(&p->lock);
    80002146:	854a                	mv	a0,s2
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b52080e7          	jalr	-1198(ra) # 80000c9a <release>
    80002150:	bfe9                	j	8000212a <scheduler+0x174>
            hp->runnable_time += diff;
    80002152:	17c9a703          	lw	a4,380(s3)
    80002156:	9f3d                	addw	a4,a4,a5
    80002158:	16e9ae23          	sw	a4,380(s3)
    8000215c:	bf51                	j	800020f0 <scheduler+0x13a>
            hp->running_time += diff;
    8000215e:	1789a703          	lw	a4,376(s3)
    80002162:	9f3d                	addw	a4,a4,a5
    80002164:	16e9ac23          	sw	a4,376(s3)
    80002168:	bf49                	j	800020fa <scheduler+0x144>
            hp->sleeping_time += diff;
    8000216a:	1749a703          	lw	a4,372(s3)
    8000216e:	9fb9                	addw	a5,a5,a4
    80002170:	16f9aa23          	sw	a5,372(s3)
    80002174:	bf41                	j	80002104 <scheduler+0x14e>

0000000080002176 <sched>:
{
    80002176:	7179                	addi	sp,sp,-48
    80002178:	f406                	sd	ra,40(sp)
    8000217a:	f022                	sd	s0,32(sp)
    8000217c:	ec26                	sd	s1,24(sp)
    8000217e:	e84a                	sd	s2,16(sp)
    80002180:	e44e                	sd	s3,8(sp)
    80002182:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002184:	00000097          	auipc	ra,0x0
    80002188:	86e080e7          	jalr	-1938(ra) # 800019f2 <myproc>
    8000218c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000218e:	fffff097          	auipc	ra,0xfffff
    80002192:	9de080e7          	jalr	-1570(ra) # 80000b6c <holding>
    80002196:	cd25                	beqz	a0,8000220e <sched+0x98>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002198:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000219a:	2781                	sext.w	a5,a5
    8000219c:	079e                	slli	a5,a5,0x7
    8000219e:	0000f717          	auipc	a4,0xf
    800021a2:	12270713          	addi	a4,a4,290 # 800112c0 <pid_lock>
    800021a6:	97ba                	add	a5,a5,a4
    800021a8:	0a87a703          	lw	a4,168(a5)
    800021ac:	4785                	li	a5,1
    800021ae:	06f71863          	bne	a4,a5,8000221e <sched+0xa8>
  if(p->state == RUNNING)
    800021b2:	4c9c                	lw	a5,24(s1)
    800021b4:	2781                	sext.w	a5,a5
    800021b6:	4711                	li	a4,4
    800021b8:	06e78b63          	beq	a5,a4,8000222e <sched+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021bc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021c0:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021c2:	efb5                	bnez	a5,8000223e <sched+0xc8>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021c4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021c6:	0000f917          	auipc	s2,0xf
    800021ca:	0fa90913          	addi	s2,s2,250 # 800112c0 <pid_lock>
    800021ce:	2781                	sext.w	a5,a5
    800021d0:	079e                	slli	a5,a5,0x7
    800021d2:	97ca                	add	a5,a5,s2
    800021d4:	0ac7a983          	lw	s3,172(a5)
    800021d8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021da:	2781                	sext.w	a5,a5
    800021dc:	079e                	slli	a5,a5,0x7
    800021de:	0000f597          	auipc	a1,0xf
    800021e2:	11a58593          	addi	a1,a1,282 # 800112f8 <cpus+0x8>
    800021e6:	95be                	add	a1,a1,a5
    800021e8:	06048513          	addi	a0,s1,96
    800021ec:	00001097          	auipc	ra,0x1
    800021f0:	a6c080e7          	jalr	-1428(ra) # 80002c58 <swtch>
    800021f4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021f6:	2781                	sext.w	a5,a5
    800021f8:	079e                	slli	a5,a5,0x7
    800021fa:	97ca                	add	a5,a5,s2
    800021fc:	0b37a623          	sw	s3,172(a5)
}
    80002200:	70a2                	ld	ra,40(sp)
    80002202:	7402                	ld	s0,32(sp)
    80002204:	64e2                	ld	s1,24(sp)
    80002206:	6942                	ld	s2,16(sp)
    80002208:	69a2                	ld	s3,8(sp)
    8000220a:	6145                	addi	sp,sp,48
    8000220c:	8082                	ret
    panic("sched p->lock");
    8000220e:	00006517          	auipc	a0,0x6
    80002212:	00a50513          	addi	a0,a0,10 # 80008218 <digits+0x1d8>
    80002216:	ffffe097          	auipc	ra,0xffffe
    8000221a:	32a080e7          	jalr	810(ra) # 80000540 <panic>
    panic("sched locks");
    8000221e:	00006517          	auipc	a0,0x6
    80002222:	00a50513          	addi	a0,a0,10 # 80008228 <digits+0x1e8>
    80002226:	ffffe097          	auipc	ra,0xffffe
    8000222a:	31a080e7          	jalr	794(ra) # 80000540 <panic>
    panic("sched running");
    8000222e:	00006517          	auipc	a0,0x6
    80002232:	00a50513          	addi	a0,a0,10 # 80008238 <digits+0x1f8>
    80002236:	ffffe097          	auipc	ra,0xffffe
    8000223a:	30a080e7          	jalr	778(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000223e:	00006517          	auipc	a0,0x6
    80002242:	00a50513          	addi	a0,a0,10 # 80008248 <digits+0x208>
    80002246:	ffffe097          	auipc	ra,0xffffe
    8000224a:	2fa080e7          	jalr	762(ra) # 80000540 <panic>

000000008000224e <yield>:
{
    8000224e:	1101                	addi	sp,sp,-32
    80002250:	ec06                	sd	ra,24(sp)
    80002252:	e822                	sd	s0,16(sp)
    80002254:	e426                	sd	s1,8(sp)
    80002256:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	79a080e7          	jalr	1946(ra) # 800019f2 <myproc>
    80002260:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	984080e7          	jalr	-1660(ra) # 80000be6 <acquire>
  int diff = ticks - p->last_update_time;
    8000226a:	00007717          	auipc	a4,0x7
    8000226e:	dea72703          	lw	a4,-534(a4) # 80009054 <ticks>
    80002272:	1804a783          	lw	a5,384(s1)
    80002276:	40f707bb          	subw	a5,a4,a5
  p->last_update_time = ticks;
    8000227a:	18e4a023          	sw	a4,384(s1)
  if(p->state == RUNNABLE){
    8000227e:	4c94                	lw	a3,24(s1)
    80002280:	2681                	sext.w	a3,a3
    80002282:	460d                	li	a2,3
    80002284:	02c68e63          	beq	a3,a2,800022c0 <yield+0x72>
  if(p->state == RUNNING){
    80002288:	4c94                	lw	a3,24(s1)
    8000228a:	2681                	sext.w	a3,a3
    8000228c:	4611                	li	a2,4
    8000228e:	02c68f63          	beq	a3,a2,800022cc <yield+0x7e>
  if(p->state == SLEEPING){
    80002292:	4c94                	lw	a3,24(s1)
    80002294:	2681                	sext.w	a3,a3
    80002296:	4609                	li	a2,2
    80002298:	04c68063          	beq	a3,a2,800022d8 <yield+0x8a>
  p->state = RUNNABLE;
    8000229c:	478d                	li	a5,3
    8000229e:	cc9c                	sw	a5,24(s1)
  p->last_runable_time = ticks;
    800022a0:	16e4a823          	sw	a4,368(s1)
  sched();
    800022a4:	00000097          	auipc	ra,0x0
    800022a8:	ed2080e7          	jalr	-302(ra) # 80002176 <sched>
  release(&p->lock);
    800022ac:	8526                	mv	a0,s1
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	9ec080e7          	jalr	-1556(ra) # 80000c9a <release>
}
    800022b6:	60e2                	ld	ra,24(sp)
    800022b8:	6442                	ld	s0,16(sp)
    800022ba:	64a2                	ld	s1,8(sp)
    800022bc:	6105                	addi	sp,sp,32
    800022be:	8082                	ret
    p->runnable_time += diff;
    800022c0:	17c4a683          	lw	a3,380(s1)
    800022c4:	9ebd                	addw	a3,a3,a5
    800022c6:	16d4ae23          	sw	a3,380(s1)
    800022ca:	bf7d                	j	80002288 <yield+0x3a>
    p->running_time += diff;
    800022cc:	1784a683          	lw	a3,376(s1)
    800022d0:	9ebd                	addw	a3,a3,a5
    800022d2:	16d4ac23          	sw	a3,376(s1)
    800022d6:	bf75                	j	80002292 <yield+0x44>
    p->sleeping_time += diff;
    800022d8:	1744a683          	lw	a3,372(s1)
    800022dc:	9fb5                	addw	a5,a5,a3
    800022de:	16f4aa23          	sw	a5,372(s1)
    800022e2:	bf6d                	j	8000229c <yield+0x4e>

00000000800022e4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800022e4:	7179                	addi	sp,sp,-48
    800022e6:	f406                	sd	ra,40(sp)
    800022e8:	f022                	sd	s0,32(sp)
    800022ea:	ec26                	sd	s1,24(sp)
    800022ec:	e84a                	sd	s2,16(sp)
    800022ee:	e44e                	sd	s3,8(sp)
    800022f0:	1800                	addi	s0,sp,48
    800022f2:	89aa                	mv	s3,a0
    800022f4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	6fc080e7          	jalr	1788(ra) # 800019f2 <myproc>
    800022fe:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	8e6080e7          	jalr	-1818(ra) # 80000be6 <acquire>
  release(lk);
    80002308:	854a                	mv	a0,s2
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	990080e7          	jalr	-1648(ra) # 80000c9a <release>

  // Go to sleep.
  p->chan = chan;
    80002312:	0334b023          	sd	s3,32(s1)

  //calc thicks passed
  //acquire(&tickslock);
  int diff = ticks - p->last_update_time;
    80002316:	00007717          	auipc	a4,0x7
    8000231a:	d3e72703          	lw	a4,-706(a4) # 80009054 <ticks>
    8000231e:	1804a783          	lw	a5,384(s1)
    80002322:	40f707bb          	subw	a5,a4,a5
  //release(&tickslock);
  p->last_update_time = ticks;
    80002326:	18e4a023          	sw	a4,384(s1)

  if(p->state == RUNNABLE){
    8000232a:	4c98                	lw	a4,24(s1)
    8000232c:	2701                	sext.w	a4,a4
    8000232e:	468d                	li	a3,3
    80002330:	04d70563          	beq	a4,a3,8000237a <sleep+0x96>
    p->runnable_time += diff;
  }
  if(p->state == RUNNING){
    80002334:	4c98                	lw	a4,24(s1)
    80002336:	2701                	sext.w	a4,a4
    80002338:	4691                	li	a3,4
    8000233a:	04d70663          	beq	a4,a3,80002386 <sleep+0xa2>
    p->running_time += diff;
  }
  if(p->state == SLEEPING){
    8000233e:	4c98                	lw	a4,24(s1)
    80002340:	2701                	sext.w	a4,a4
    80002342:	4689                	li	a3,2
    80002344:	04d70763          	beq	a4,a3,80002392 <sleep+0xae>
    p->sleeping_time += diff;
  }

  p->state = SLEEPING;
    80002348:	4789                	li	a5,2
    8000234a:	cc9c                	sw	a5,24(s1)

  sched();
    8000234c:	00000097          	auipc	ra,0x0
    80002350:	e2a080e7          	jalr	-470(ra) # 80002176 <sched>

  // Tidy up.
  p->chan = 0;
    80002354:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	940080e7          	jalr	-1728(ra) # 80000c9a <release>
  acquire(lk);
    80002362:	854a                	mv	a0,s2
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	882080e7          	jalr	-1918(ra) # 80000be6 <acquire>
}
    8000236c:	70a2                	ld	ra,40(sp)
    8000236e:	7402                	ld	s0,32(sp)
    80002370:	64e2                	ld	s1,24(sp)
    80002372:	6942                	ld	s2,16(sp)
    80002374:	69a2                	ld	s3,8(sp)
    80002376:	6145                	addi	sp,sp,48
    80002378:	8082                	ret
    p->runnable_time += diff;
    8000237a:	17c4a703          	lw	a4,380(s1)
    8000237e:	9f3d                	addw	a4,a4,a5
    80002380:	16e4ae23          	sw	a4,380(s1)
    80002384:	bf45                	j	80002334 <sleep+0x50>
    p->running_time += diff;
    80002386:	1784a703          	lw	a4,376(s1)
    8000238a:	9f3d                	addw	a4,a4,a5
    8000238c:	16e4ac23          	sw	a4,376(s1)
    80002390:	b77d                	j	8000233e <sleep+0x5a>
    p->sleeping_time += diff;
    80002392:	1744a703          	lw	a4,372(s1)
    80002396:	9fb9                	addw	a5,a5,a4
    80002398:	16f4aa23          	sw	a5,372(s1)
    8000239c:	b775                	j	80002348 <sleep+0x64>

000000008000239e <wait>:
{
    8000239e:	715d                	addi	sp,sp,-80
    800023a0:	e486                	sd	ra,72(sp)
    800023a2:	e0a2                	sd	s0,64(sp)
    800023a4:	fc26                	sd	s1,56(sp)
    800023a6:	f84a                	sd	s2,48(sp)
    800023a8:	f44e                	sd	s3,40(sp)
    800023aa:	f052                	sd	s4,32(sp)
    800023ac:	ec56                	sd	s5,24(sp)
    800023ae:	e85a                	sd	s6,16(sp)
    800023b0:	e45e                	sd	s7,8(sp)
    800023b2:	e062                	sd	s8,0(sp)
    800023b4:	0880                	addi	s0,sp,80
    800023b6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	63a080e7          	jalr	1594(ra) # 800019f2 <myproc>
    800023c0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023c2:	0000f517          	auipc	a0,0xf
    800023c6:	f1650513          	addi	a0,a0,-234 # 800112d8 <wait_lock>
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	81c080e7          	jalr	-2020(ra) # 80000be6 <acquire>
    havekids = 0;
    800023d2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023d4:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800023d6:	00015997          	auipc	s3,0x15
    800023da:	51a98993          	addi	s3,s3,1306 # 800178f0 <tickslock>
        havekids = 1;
    800023de:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023e0:	0000fc17          	auipc	s8,0xf
    800023e4:	ef8c0c13          	addi	s8,s8,-264 # 800112d8 <wait_lock>
    havekids = 0;
    800023e8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023ea:	0000f497          	auipc	s1,0xf
    800023ee:	30648493          	addi	s1,s1,774 # 800116f0 <proc>
    800023f2:	a0bd                	j	80002460 <wait+0xc2>
          pid = np->pid;
    800023f4:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023f8:	000b0e63          	beqz	s6,80002414 <wait+0x76>
    800023fc:	4691                	li	a3,4
    800023fe:	02c48613          	addi	a2,s1,44
    80002402:	85da                	mv	a1,s6
    80002404:	05093503          	ld	a0,80(s2)
    80002408:	fffff097          	auipc	ra,0xfffff
    8000240c:	26c080e7          	jalr	620(ra) # 80001674 <copyout>
    80002410:	02054563          	bltz	a0,8000243a <wait+0x9c>
          freeproc(np);
    80002414:	8526                	mv	a0,s1
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	78e080e7          	jalr	1934(ra) # 80001ba4 <freeproc>
          release(&np->lock);
    8000241e:	8526                	mv	a0,s1
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	87a080e7          	jalr	-1926(ra) # 80000c9a <release>
          release(&wait_lock);
    80002428:	0000f517          	auipc	a0,0xf
    8000242c:	eb050513          	addi	a0,a0,-336 # 800112d8 <wait_lock>
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	86a080e7          	jalr	-1942(ra) # 80000c9a <release>
          return pid;
    80002438:	a0ad                	j	800024a2 <wait+0x104>
            release(&np->lock);
    8000243a:	8526                	mv	a0,s1
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	85e080e7          	jalr	-1954(ra) # 80000c9a <release>
            release(&wait_lock);
    80002444:	0000f517          	auipc	a0,0xf
    80002448:	e9450513          	addi	a0,a0,-364 # 800112d8 <wait_lock>
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	84e080e7          	jalr	-1970(ra) # 80000c9a <release>
            return -1;
    80002454:	59fd                	li	s3,-1
    80002456:	a0b1                	j	800024a2 <wait+0x104>
    for(np = proc; np < &proc[NPROC]; np++){
    80002458:	18848493          	addi	s1,s1,392
    8000245c:	03348563          	beq	s1,s3,80002486 <wait+0xe8>
      if(np->parent == p){
    80002460:	7c9c                	ld	a5,56(s1)
    80002462:	ff279be3          	bne	a5,s2,80002458 <wait+0xba>
        acquire(&np->lock);
    80002466:	8526                	mv	a0,s1
    80002468:	ffffe097          	auipc	ra,0xffffe
    8000246c:	77e080e7          	jalr	1918(ra) # 80000be6 <acquire>
        if(np->state == ZOMBIE){
    80002470:	4c9c                	lw	a5,24(s1)
    80002472:	2781                	sext.w	a5,a5
    80002474:	f94780e3          	beq	a5,s4,800023f4 <wait+0x56>
        release(&np->lock);
    80002478:	8526                	mv	a0,s1
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	820080e7          	jalr	-2016(ra) # 80000c9a <release>
        havekids = 1;
    80002482:	8756                	mv	a4,s5
    80002484:	bfd1                	j	80002458 <wait+0xba>
    if(!havekids || p->killed){
    80002486:	c709                	beqz	a4,80002490 <wait+0xf2>
    80002488:	02892783          	lw	a5,40(s2)
    8000248c:	2781                	sext.w	a5,a5
    8000248e:	c79d                	beqz	a5,800024bc <wait+0x11e>
      release(&wait_lock);
    80002490:	0000f517          	auipc	a0,0xf
    80002494:	e4850513          	addi	a0,a0,-440 # 800112d8 <wait_lock>
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	802080e7          	jalr	-2046(ra) # 80000c9a <release>
      return -1;
    800024a0:	59fd                	li	s3,-1
}
    800024a2:	854e                	mv	a0,s3
    800024a4:	60a6                	ld	ra,72(sp)
    800024a6:	6406                	ld	s0,64(sp)
    800024a8:	74e2                	ld	s1,56(sp)
    800024aa:	7942                	ld	s2,48(sp)
    800024ac:	79a2                	ld	s3,40(sp)
    800024ae:	7a02                	ld	s4,32(sp)
    800024b0:	6ae2                	ld	s5,24(sp)
    800024b2:	6b42                	ld	s6,16(sp)
    800024b4:	6ba2                	ld	s7,8(sp)
    800024b6:	6c02                	ld	s8,0(sp)
    800024b8:	6161                	addi	sp,sp,80
    800024ba:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024bc:	85e2                	mv	a1,s8
    800024be:	854a                	mv	a0,s2
    800024c0:	00000097          	auipc	ra,0x0
    800024c4:	e24080e7          	jalr	-476(ra) # 800022e4 <sleep>
    havekids = 0;
    800024c8:	b705                	j	800023e8 <wait+0x4a>

00000000800024ca <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800024ca:	711d                	addi	sp,sp,-96
    800024cc:	ec86                	sd	ra,88(sp)
    800024ce:	e8a2                	sd	s0,80(sp)
    800024d0:	e4a6                	sd	s1,72(sp)
    800024d2:	e0ca                	sd	s2,64(sp)
    800024d4:	fc4e                	sd	s3,56(sp)
    800024d6:	f852                	sd	s4,48(sp)
    800024d8:	f456                	sd	s5,40(sp)
    800024da:	f05a                	sd	s6,32(sp)
    800024dc:	ec5e                	sd	s7,24(sp)
    800024de:	e862                	sd	s8,16(sp)
    800024e0:	e466                	sd	s9,8(sp)
    800024e2:	1080                	addi	s0,sp,96
    800024e4:	8aaa                	mv	s5,a0
  struct proc *p, *mp = myproc();
    800024e6:	fffff097          	auipc	ra,0xfffff
    800024ea:	50c080e7          	jalr	1292(ra) # 800019f2 <myproc>
    800024ee:	892a                	mv	s2,a0

  for(p = proc; p < &proc[NPROC]; p++) {
    800024f0:	0000f497          	auipc	s1,0xf
    800024f4:	20048493          	addi	s1,s1,512 # 800116f0 <proc>
    if(p != mp){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800024f8:	4a09                	li	s4,2
        //calc thicks passed
        //acquire(&tickslock);
        int diff = ticks - p->last_update_time;
    800024fa:	00007c97          	auipc	s9,0x7
    800024fe:	b5ac8c93          	addi	s9,s9,-1190 # 80009054 <ticks>
        //release(&tickslock);
        p->last_update_time = ticks;

        if(p->state == RUNNABLE){
    80002502:	4c0d                	li	s8,3
          p->runnable_time += diff;
        }
        if(p->state == RUNNING){
    80002504:	4b91                	li	s7,4
          p->running_time += diff;
        }
        if(p->state == SLEEPING){
          p->sleeping_time += diff;
        }
        p->state = RUNNABLE;
    80002506:	4b0d                	li	s6,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002508:	00015997          	auipc	s3,0x15
    8000250c:	3e898993          	addi	s3,s3,1000 # 800178f0 <tickslock>
    80002510:	a815                	j	80002544 <wakeup+0x7a>
          p->runnable_time += diff;
    80002512:	17c4a683          	lw	a3,380(s1)
    80002516:	9ebd                	addw	a3,a3,a5
    80002518:	16d4ae23          	sw	a3,380(s1)
    8000251c:	a8b1                	j	80002578 <wakeup+0xae>
          p->running_time += diff;
    8000251e:	1784a683          	lw	a3,376(s1)
    80002522:	9ebd                	addw	a3,a3,a5
    80002524:	16d4ac23          	sw	a3,376(s1)
    80002528:	a8a1                	j	80002580 <wakeup+0xb6>
        p->state = RUNNABLE;
    8000252a:	0164ac23          	sw	s6,24(s1)
        /* FCFS */
        #ifdef FCFS
        //acquire(&tickslock);
        p->last_runable_time = ticks;
    8000252e:	16e4a823          	sw	a4,368(s1)
        //release(&tickslock);
        #endif
      }
      release(&p->lock);
    80002532:	8526                	mv	a0,s1
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	766080e7          	jalr	1894(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000253c:	18848493          	addi	s1,s1,392
    80002540:	05348a63          	beq	s1,s3,80002594 <wakeup+0xca>
    if(p != mp){
    80002544:	fe990ce3          	beq	s2,s1,8000253c <wakeup+0x72>
      acquire(&p->lock);
    80002548:	8526                	mv	a0,s1
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	69c080e7          	jalr	1692(ra) # 80000be6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002552:	4c9c                	lw	a5,24(s1)
    80002554:	2781                	sext.w	a5,a5
    80002556:	fd479ee3          	bne	a5,s4,80002532 <wakeup+0x68>
    8000255a:	709c                	ld	a5,32(s1)
    8000255c:	fd579be3          	bne	a5,s5,80002532 <wakeup+0x68>
        int diff = ticks - p->last_update_time;
    80002560:	000ca703          	lw	a4,0(s9)
    80002564:	1804a783          	lw	a5,384(s1)
    80002568:	40f707bb          	subw	a5,a4,a5
        p->last_update_time = ticks;
    8000256c:	18e4a023          	sw	a4,384(s1)
        if(p->state == RUNNABLE){
    80002570:	4c94                	lw	a3,24(s1)
    80002572:	2681                	sext.w	a3,a3
    80002574:	f9868fe3          	beq	a3,s8,80002512 <wakeup+0x48>
        if(p->state == RUNNING){
    80002578:	4c94                	lw	a3,24(s1)
    8000257a:	2681                	sext.w	a3,a3
    8000257c:	fb7681e3          	beq	a3,s7,8000251e <wakeup+0x54>
        if(p->state == SLEEPING){
    80002580:	4c94                	lw	a3,24(s1)
    80002582:	2681                	sext.w	a3,a3
    80002584:	fb4693e3          	bne	a3,s4,8000252a <wakeup+0x60>
          p->sleeping_time += diff;
    80002588:	1744a683          	lw	a3,372(s1)
    8000258c:	9fb5                	addw	a5,a5,a3
    8000258e:	16f4aa23          	sw	a5,372(s1)
    80002592:	bf61                	j	8000252a <wakeup+0x60>
    }
  }
}
    80002594:	60e6                	ld	ra,88(sp)
    80002596:	6446                	ld	s0,80(sp)
    80002598:	64a6                	ld	s1,72(sp)
    8000259a:	6906                	ld	s2,64(sp)
    8000259c:	79e2                	ld	s3,56(sp)
    8000259e:	7a42                	ld	s4,48(sp)
    800025a0:	7aa2                	ld	s5,40(sp)
    800025a2:	7b02                	ld	s6,32(sp)
    800025a4:	6be2                	ld	s7,24(sp)
    800025a6:	6c42                	ld	s8,16(sp)
    800025a8:	6ca2                	ld	s9,8(sp)
    800025aa:	6125                	addi	sp,sp,96
    800025ac:	8082                	ret

00000000800025ae <reparent>:
{
    800025ae:	7179                	addi	sp,sp,-48
    800025b0:	f406                	sd	ra,40(sp)
    800025b2:	f022                	sd	s0,32(sp)
    800025b4:	ec26                	sd	s1,24(sp)
    800025b6:	e84a                	sd	s2,16(sp)
    800025b8:	e44e                	sd	s3,8(sp)
    800025ba:	e052                	sd	s4,0(sp)
    800025bc:	1800                	addi	s0,sp,48
    800025be:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025c0:	0000f497          	auipc	s1,0xf
    800025c4:	13048493          	addi	s1,s1,304 # 800116f0 <proc>
      pp->parent = initproc;
    800025c8:	00007a17          	auipc	s4,0x7
    800025cc:	a68a0a13          	addi	s4,s4,-1432 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025d0:	00015997          	auipc	s3,0x15
    800025d4:	32098993          	addi	s3,s3,800 # 800178f0 <tickslock>
    800025d8:	a029                	j	800025e2 <reparent+0x34>
    800025da:	18848493          	addi	s1,s1,392
    800025de:	01348d63          	beq	s1,s3,800025f8 <reparent+0x4a>
    if(pp->parent == p){
    800025e2:	7c9c                	ld	a5,56(s1)
    800025e4:	ff279be3          	bne	a5,s2,800025da <reparent+0x2c>
      pp->parent = initproc;
    800025e8:	000a3503          	ld	a0,0(s4)
    800025ec:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800025ee:	00000097          	auipc	ra,0x0
    800025f2:	edc080e7          	jalr	-292(ra) # 800024ca <wakeup>
    800025f6:	b7d5                	j	800025da <reparent+0x2c>
}
    800025f8:	70a2                	ld	ra,40(sp)
    800025fa:	7402                	ld	s0,32(sp)
    800025fc:	64e2                	ld	s1,24(sp)
    800025fe:	6942                	ld	s2,16(sp)
    80002600:	69a2                	ld	s3,8(sp)
    80002602:	6a02                	ld	s4,0(sp)
    80002604:	6145                	addi	sp,sp,48
    80002606:	8082                	ret

0000000080002608 <exit>:
{
    80002608:	7179                	addi	sp,sp,-48
    8000260a:	f406                	sd	ra,40(sp)
    8000260c:	f022                	sd	s0,32(sp)
    8000260e:	ec26                	sd	s1,24(sp)
    80002610:	e84a                	sd	s2,16(sp)
    80002612:	e44e                	sd	s3,8(sp)
    80002614:	e052                	sd	s4,0(sp)
    80002616:	1800                	addi	s0,sp,48
    80002618:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000261a:	fffff097          	auipc	ra,0xfffff
    8000261e:	3d8080e7          	jalr	984(ra) # 800019f2 <myproc>
    80002622:	892a                	mv	s2,a0
  if(p == initproc)
    80002624:	00007797          	auipc	a5,0x7
    80002628:	a0c7b783          	ld	a5,-1524(a5) # 80009030 <initproc>
    8000262c:	0d050493          	addi	s1,a0,208
    80002630:	15050993          	addi	s3,a0,336
    80002634:	02a79363          	bne	a5,a0,8000265a <exit+0x52>
    panic("init exiting");
    80002638:	00006517          	auipc	a0,0x6
    8000263c:	c2850513          	addi	a0,a0,-984 # 80008260 <digits+0x220>
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	f00080e7          	jalr	-256(ra) # 80000540 <panic>
      fileclose(f);
    80002648:	00002097          	auipc	ra,0x2
    8000264c:	562080e7          	jalr	1378(ra) # 80004baa <fileclose>
      p->ofile[fd] = 0;
    80002650:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002654:	04a1                	addi	s1,s1,8
    80002656:	01348563          	beq	s1,s3,80002660 <exit+0x58>
    if(p->ofile[fd]){
    8000265a:	6088                	ld	a0,0(s1)
    8000265c:	f575                	bnez	a0,80002648 <exit+0x40>
    8000265e:	bfdd                	j	80002654 <exit+0x4c>
  begin_op();
    80002660:	00002097          	auipc	ra,0x2
    80002664:	07e080e7          	jalr	126(ra) # 800046de <begin_op>
  iput(p->cwd);
    80002668:	15093503          	ld	a0,336(s2)
    8000266c:	00002097          	auipc	ra,0x2
    80002670:	85a080e7          	jalr	-1958(ra) # 80003ec6 <iput>
  end_op();
    80002674:	00002097          	auipc	ra,0x2
    80002678:	0ea080e7          	jalr	234(ra) # 8000475e <end_op>
  p->cwd = 0;
    8000267c:	14093823          	sd	zero,336(s2)
  acquire(&wait_lock);
    80002680:	0000f517          	auipc	a0,0xf
    80002684:	c5850513          	addi	a0,a0,-936 # 800112d8 <wait_lock>
    80002688:	ffffe097          	auipc	ra,0xffffe
    8000268c:	55e080e7          	jalr	1374(ra) # 80000be6 <acquire>
  reparent(p);
    80002690:	854a                	mv	a0,s2
    80002692:	00000097          	auipc	ra,0x0
    80002696:	f1c080e7          	jalr	-228(ra) # 800025ae <reparent>
  wakeup(p->parent);
    8000269a:	03893503          	ld	a0,56(s2)
    8000269e:	00000097          	auipc	ra,0x0
    800026a2:	e2c080e7          	jalr	-468(ra) # 800024ca <wakeup>
  acquire(&p->lock);
    800026a6:	854a                	mv	a0,s2
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	53e080e7          	jalr	1342(ra) # 80000be6 <acquire>
  p->xstate = status;
    800026b0:	03492623          	sw	s4,44(s2)
  int diff = ticks - p->last_update_time;
    800026b4:	00007697          	auipc	a3,0x7
    800026b8:	9a06a683          	lw	a3,-1632(a3) # 80009054 <ticks>
    800026bc:	18092783          	lw	a5,384(s2)
    800026c0:	40f687bb          	subw	a5,a3,a5
  p->last_update_time = ticks;
    800026c4:	18d92023          	sw	a3,384(s2)
  if(p->state == RUNNABLE){
    800026c8:	01892703          	lw	a4,24(s2)
    800026cc:	2701                	sext.w	a4,a4
    800026ce:	460d                	li	a2,3
    800026d0:	0cc70c63          	beq	a4,a2,800027a8 <exit+0x1a0>
  if(p->state == RUNNING){
    800026d4:	01892703          	lw	a4,24(s2)
    800026d8:	2701                	sext.w	a4,a4
    800026da:	4611                	li	a2,4
    800026dc:	0cc70c63          	beq	a4,a2,800027b4 <exit+0x1ac>
  if(p->state == SLEEPING){
    800026e0:	01892703          	lw	a4,24(s2)
    800026e4:	2701                	sext.w	a4,a4
    800026e6:	4609                	li	a2,2
    800026e8:	0cc70c63          	beq	a4,a2,800027c0 <exit+0x1b8>
  process_count++;
    800026ec:	00007797          	auipc	a5,0x7
    800026f0:	95878793          	addi	a5,a5,-1704 # 80009044 <process_count>
    800026f4:	438c                	lw	a1,0(a5)
    800026f6:	0015861b          	addiw	a2,a1,1
    800026fa:	c390                	sw	a2,0(a5)
  running_processes_mean = ((running_processes_mean * (process_count - 1)) + p->running_time)/ process_count;
    800026fc:	17892503          	lw	a0,376(s2)
    80002700:	00007797          	auipc	a5,0x7
    80002704:	94c78793          	addi	a5,a5,-1716 # 8000904c <running_processes_mean>
    80002708:	4398                	lw	a4,0(a5)
    8000270a:	02b7073b          	mulw	a4,a4,a1
    8000270e:	9f29                	addw	a4,a4,a0
    80002710:	02c7573b          	divuw	a4,a4,a2
    80002714:	c398                	sw	a4,0(a5)
  runnable_processes_mean = ((runnable_processes_mean * (process_count - 1)) + p->runnable_time) / process_count;
    80002716:	00007797          	auipc	a5,0x7
    8000271a:	93278793          	addi	a5,a5,-1742 # 80009048 <runnable_processes_mean>
    8000271e:	4398                	lw	a4,0(a5)
    80002720:	02b7073b          	mulw	a4,a4,a1
    80002724:	17c92803          	lw	a6,380(s2)
    80002728:	0107073b          	addw	a4,a4,a6
    8000272c:	02c7573b          	divuw	a4,a4,a2
    80002730:	c398                	sw	a4,0(a5)
  sleeping_processes_mean = ((sleeping_processes_mean * (process_count - 1)) + p->sleeping_time) / process_count;
    80002732:	00007717          	auipc	a4,0x7
    80002736:	91e70713          	addi	a4,a4,-1762 # 80009050 <sleeping_processes_mean>
    8000273a:	431c                	lw	a5,0(a4)
    8000273c:	02b787bb          	mulw	a5,a5,a1
    80002740:	17492583          	lw	a1,372(s2)
    80002744:	9fad                	addw	a5,a5,a1
    80002746:	02c7d7bb          	divuw	a5,a5,a2
    8000274a:	c31c                	sw	a5,0(a4)
  program_time += p->running_time;
    8000274c:	00007617          	auipc	a2,0x7
    80002750:	8f460613          	addi	a2,a2,-1804 # 80009040 <program_time>
    80002754:	421c                	lw	a5,0(a2)
    80002756:	00a7873b          	addw	a4,a5,a0
    8000275a:	c218                	sw	a4,0(a2)
  cpu_utilization = program_time * 100 / (ticks - start_time);
    8000275c:	06400793          	li	a5,100
    80002760:	02e787bb          	mulw	a5,a5,a4
    80002764:	00007717          	auipc	a4,0x7
    80002768:	8d472703          	lw	a4,-1836(a4) # 80009038 <start_time>
    8000276c:	9e99                	subw	a3,a3,a4
    8000276e:	02d7d7bb          	divuw	a5,a5,a3
    80002772:	00007717          	auipc	a4,0x7
    80002776:	8cf72523          	sw	a5,-1846(a4) # 8000903c <cpu_utilization>
  p->state = ZOMBIE;
    8000277a:	4795                	li	a5,5
    8000277c:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    80002780:	0000f517          	auipc	a0,0xf
    80002784:	b5850513          	addi	a0,a0,-1192 # 800112d8 <wait_lock>
    80002788:	ffffe097          	auipc	ra,0xffffe
    8000278c:	512080e7          	jalr	1298(ra) # 80000c9a <release>
  sched();
    80002790:	00000097          	auipc	ra,0x0
    80002794:	9e6080e7          	jalr	-1562(ra) # 80002176 <sched>
  panic("zombie exit");
    80002798:	00006517          	auipc	a0,0x6
    8000279c:	ad850513          	addi	a0,a0,-1320 # 80008270 <digits+0x230>
    800027a0:	ffffe097          	auipc	ra,0xffffe
    800027a4:	da0080e7          	jalr	-608(ra) # 80000540 <panic>
    p->runnable_time += diff;
    800027a8:	17c92703          	lw	a4,380(s2)
    800027ac:	9f3d                	addw	a4,a4,a5
    800027ae:	16e92e23          	sw	a4,380(s2)
    800027b2:	b70d                	j	800026d4 <exit+0xcc>
    p->running_time += diff;
    800027b4:	17892703          	lw	a4,376(s2)
    800027b8:	9f3d                	addw	a4,a4,a5
    800027ba:	16e92c23          	sw	a4,376(s2)
    800027be:	b70d                	j	800026e0 <exit+0xd8>
    p->sleeping_time += diff;
    800027c0:	17492703          	lw	a4,372(s2)
    800027c4:	9fb9                	addw	a5,a5,a4
    800027c6:	16f92a23          	sw	a5,372(s2)
    800027ca:	b70d                	j	800026ec <exit+0xe4>

00000000800027cc <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800027cc:	7179                	addi	sp,sp,-48
    800027ce:	f406                	sd	ra,40(sp)
    800027d0:	f022                	sd	s0,32(sp)
    800027d2:	ec26                	sd	s1,24(sp)
    800027d4:	e84a                	sd	s2,16(sp)
    800027d6:	e44e                	sd	s3,8(sp)
    800027d8:	1800                	addi	s0,sp,48
    800027da:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800027dc:	0000f497          	auipc	s1,0xf
    800027e0:	f1448493          	addi	s1,s1,-236 # 800116f0 <proc>
    800027e4:	00015997          	auipc	s3,0x15
    800027e8:	10c98993          	addi	s3,s3,268 # 800178f0 <tickslock>
    acquire(&p->lock);
    800027ec:	8526                	mv	a0,s1
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	3f8080e7          	jalr	1016(ra) # 80000be6 <acquire>
    if(p->pid == pid){
    800027f6:	589c                	lw	a5,48(s1)
    800027f8:	01278d63          	beq	a5,s2,80002812 <kill+0x46>
        #endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027fc:	8526                	mv	a0,s1
    800027fe:	ffffe097          	auipc	ra,0xffffe
    80002802:	49c080e7          	jalr	1180(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002806:	18848493          	addi	s1,s1,392
    8000280a:	ff3491e3          	bne	s1,s3,800027ec <kill+0x20>
  }
  return -1;
    8000280e:	557d                	li	a0,-1
    80002810:	a831                	j	8000282c <kill+0x60>
      p->killed = 1;
    80002812:	4785                	li	a5,1
    80002814:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002816:	4c9c                	lw	a5,24(s1)
    80002818:	2781                	sext.w	a5,a5
    8000281a:	4709                	li	a4,2
    8000281c:	00e78f63          	beq	a5,a4,8000283a <kill+0x6e>
      release(&p->lock);
    80002820:	8526                	mv	a0,s1
    80002822:	ffffe097          	auipc	ra,0xffffe
    80002826:	478080e7          	jalr	1144(ra) # 80000c9a <release>
      return 0;
    8000282a:	4501                	li	a0,0
}
    8000282c:	70a2                	ld	ra,40(sp)
    8000282e:	7402                	ld	s0,32(sp)
    80002830:	64e2                	ld	s1,24(sp)
    80002832:	6942                	ld	s2,16(sp)
    80002834:	69a2                	ld	s3,8(sp)
    80002836:	6145                	addi	sp,sp,48
    80002838:	8082                	ret
        int diff = ticks - p->last_update_time;
    8000283a:	00007797          	auipc	a5,0x7
    8000283e:	81a7a783          	lw	a5,-2022(a5) # 80009054 <ticks>
    80002842:	1804a703          	lw	a4,384(s1)
    80002846:	40e7873b          	subw	a4,a5,a4
        p->last_update_time = ticks;
    8000284a:	18f4a023          	sw	a5,384(s1)
        if(p->state == RUNNABLE){
    8000284e:	4c94                	lw	a3,24(s1)
    80002850:	2681                	sext.w	a3,a3
    80002852:	460d                	li	a2,3
    80002854:	02c68163          	beq	a3,a2,80002876 <kill+0xaa>
        if(p->state == RUNNING){
    80002858:	4c94                	lw	a3,24(s1)
    8000285a:	2681                	sext.w	a3,a3
    8000285c:	4611                	li	a2,4
    8000285e:	02c68263          	beq	a3,a2,80002882 <kill+0xb6>
        if(p->state == SLEEPING){
    80002862:	4c94                	lw	a3,24(s1)
    80002864:	2681                	sext.w	a3,a3
    80002866:	4609                	li	a2,2
    80002868:	02c68363          	beq	a3,a2,8000288e <kill+0xc2>
        p->state = RUNNABLE;
    8000286c:	470d                	li	a4,3
    8000286e:	cc98                	sw	a4,24(s1)
        p->last_runable_time = ticks;
    80002870:	16f4a823          	sw	a5,368(s1)
    80002874:	b775                	j	80002820 <kill+0x54>
          p->runnable_time += diff;
    80002876:	17c4a683          	lw	a3,380(s1)
    8000287a:	9eb9                	addw	a3,a3,a4
    8000287c:	16d4ae23          	sw	a3,380(s1)
    80002880:	bfe1                	j	80002858 <kill+0x8c>
          p->running_time += diff;
    80002882:	1784a683          	lw	a3,376(s1)
    80002886:	9eb9                	addw	a3,a3,a4
    80002888:	16d4ac23          	sw	a3,376(s1)
    8000288c:	bfd9                	j	80002862 <kill+0x96>
          p->sleeping_time += diff;
    8000288e:	1744a683          	lw	a3,372(s1)
    80002892:	9f35                	addw	a4,a4,a3
    80002894:	16e4aa23          	sw	a4,372(s1)
    80002898:	bfd1                	j	8000286c <kill+0xa0>

000000008000289a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000289a:	7179                	addi	sp,sp,-48
    8000289c:	f406                	sd	ra,40(sp)
    8000289e:	f022                	sd	s0,32(sp)
    800028a0:	ec26                	sd	s1,24(sp)
    800028a2:	e84a                	sd	s2,16(sp)
    800028a4:	e44e                	sd	s3,8(sp)
    800028a6:	e052                	sd	s4,0(sp)
    800028a8:	1800                	addi	s0,sp,48
    800028aa:	84aa                	mv	s1,a0
    800028ac:	892e                	mv	s2,a1
    800028ae:	89b2                	mv	s3,a2
    800028b0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800028b2:	fffff097          	auipc	ra,0xfffff
    800028b6:	140080e7          	jalr	320(ra) # 800019f2 <myproc>
  if(user_dst){
    800028ba:	c08d                	beqz	s1,800028dc <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800028bc:	86d2                	mv	a3,s4
    800028be:	864e                	mv	a2,s3
    800028c0:	85ca                	mv	a1,s2
    800028c2:	6928                	ld	a0,80(a0)
    800028c4:	fffff097          	auipc	ra,0xfffff
    800028c8:	db0080e7          	jalr	-592(ra) # 80001674 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800028cc:	70a2                	ld	ra,40(sp)
    800028ce:	7402                	ld	s0,32(sp)
    800028d0:	64e2                	ld	s1,24(sp)
    800028d2:	6942                	ld	s2,16(sp)
    800028d4:	69a2                	ld	s3,8(sp)
    800028d6:	6a02                	ld	s4,0(sp)
    800028d8:	6145                	addi	sp,sp,48
    800028da:	8082                	ret
    memmove((char *)dst, src, len);
    800028dc:	000a061b          	sext.w	a2,s4
    800028e0:	85ce                	mv	a1,s3
    800028e2:	854a                	mv	a0,s2
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	45e080e7          	jalr	1118(ra) # 80000d42 <memmove>
    return 0;
    800028ec:	8526                	mv	a0,s1
    800028ee:	bff9                	j	800028cc <either_copyout+0x32>

00000000800028f0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800028f0:	7179                	addi	sp,sp,-48
    800028f2:	f406                	sd	ra,40(sp)
    800028f4:	f022                	sd	s0,32(sp)
    800028f6:	ec26                	sd	s1,24(sp)
    800028f8:	e84a                	sd	s2,16(sp)
    800028fa:	e44e                	sd	s3,8(sp)
    800028fc:	e052                	sd	s4,0(sp)
    800028fe:	1800                	addi	s0,sp,48
    80002900:	892a                	mv	s2,a0
    80002902:	84ae                	mv	s1,a1
    80002904:	89b2                	mv	s3,a2
    80002906:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002908:	fffff097          	auipc	ra,0xfffff
    8000290c:	0ea080e7          	jalr	234(ra) # 800019f2 <myproc>
  if(user_src){
    80002910:	c08d                	beqz	s1,80002932 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002912:	86d2                	mv	a3,s4
    80002914:	864e                	mv	a2,s3
    80002916:	85ca                	mv	a1,s2
    80002918:	6928                	ld	a0,80(a0)
    8000291a:	fffff097          	auipc	ra,0xfffff
    8000291e:	de6080e7          	jalr	-538(ra) # 80001700 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002922:	70a2                	ld	ra,40(sp)
    80002924:	7402                	ld	s0,32(sp)
    80002926:	64e2                	ld	s1,24(sp)
    80002928:	6942                	ld	s2,16(sp)
    8000292a:	69a2                	ld	s3,8(sp)
    8000292c:	6a02                	ld	s4,0(sp)
    8000292e:	6145                	addi	sp,sp,48
    80002930:	8082                	ret
    memmove(dst, (char*)src, len);
    80002932:	000a061b          	sext.w	a2,s4
    80002936:	85ce                	mv	a1,s3
    80002938:	854a                	mv	a0,s2
    8000293a:	ffffe097          	auipc	ra,0xffffe
    8000293e:	408080e7          	jalr	1032(ra) # 80000d42 <memmove>
    return 0;
    80002942:	8526                	mv	a0,s1
    80002944:	bff9                	j	80002922 <either_copyin+0x32>

0000000080002946 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002946:	715d                	addi	sp,sp,-80
    80002948:	e486                	sd	ra,72(sp)
    8000294a:	e0a2                	sd	s0,64(sp)
    8000294c:	fc26                	sd	s1,56(sp)
    8000294e:	f84a                	sd	s2,48(sp)
    80002950:	f44e                	sd	s3,40(sp)
    80002952:	f052                	sd	s4,32(sp)
    80002954:	ec56                	sd	s5,24(sp)
    80002956:	e85a                	sd	s6,16(sp)
    80002958:	e45e                	sd	s7,8(sp)
    8000295a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000295c:	00006517          	auipc	a0,0x6
    80002960:	a4c50513          	addi	a0,a0,-1460 # 800083a8 <digits+0x368>
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	c26080e7          	jalr	-986(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000296c:	0000f497          	auipc	s1,0xf
    80002970:	d8448493          	addi	s1,s1,-636 # 800116f0 <proc>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002974:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002976:	00006917          	auipc	s2,0x6
    8000297a:	90a90913          	addi	s2,s2,-1782 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000297e:	00006a97          	auipc	s5,0x6
    80002982:	90aa8a93          	addi	s5,s5,-1782 # 80008288 <digits+0x248>
    printf("\n");
    80002986:	00006a17          	auipc	s4,0x6
    8000298a:	a22a0a13          	addi	s4,s4,-1502 # 800083a8 <digits+0x368>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000298e:	00006b97          	auipc	s7,0x6
    80002992:	a6ab8b93          	addi	s7,s7,-1430 # 800083f8 <states.1746>
  for(p = proc; p < &proc[NPROC]; p++){
    80002996:	00015997          	auipc	s3,0x15
    8000299a:	f5a98993          	addi	s3,s3,-166 # 800178f0 <tickslock>
    8000299e:	a015                	j	800029c2 <procdump+0x7c>
    printf("%d %s %s", p->pid, state, p->name);
    800029a0:	15848693          	addi	a3,s1,344
    800029a4:	588c                	lw	a1,48(s1)
    800029a6:	8556                	mv	a0,s5
    800029a8:	ffffe097          	auipc	ra,0xffffe
    800029ac:	be2080e7          	jalr	-1054(ra) # 8000058a <printf>
    printf("\n");
    800029b0:	8552                	mv	a0,s4
    800029b2:	ffffe097          	auipc	ra,0xffffe
    800029b6:	bd8080e7          	jalr	-1064(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800029ba:	18848493          	addi	s1,s1,392
    800029be:	03348963          	beq	s1,s3,800029f0 <procdump+0xaa>
    if(p->state == UNUSED)
    800029c2:	4c9c                	lw	a5,24(s1)
    800029c4:	2781                	sext.w	a5,a5
    800029c6:	dbf5                	beqz	a5,800029ba <procdump+0x74>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029c8:	4c9c                	lw	a5,24(s1)
    800029ca:	4c9c                	lw	a5,24(s1)
    800029cc:	2781                	sext.w	a5,a5
      state = "???";
    800029ce:	864a                	mv	a2,s2
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029d0:	fcfb68e3          	bltu	s6,a5,800029a0 <procdump+0x5a>
    800029d4:	4c9c                	lw	a5,24(s1)
    800029d6:	1782                	slli	a5,a5,0x20
    800029d8:	9381                	srli	a5,a5,0x20
    800029da:	078e                	slli	a5,a5,0x3
    800029dc:	97de                	add	a5,a5,s7
    800029de:	639c                	ld	a5,0(a5)
    800029e0:	d3e1                	beqz	a5,800029a0 <procdump+0x5a>
      state = states[p->state];
    800029e2:	4c9c                	lw	a5,24(s1)
    800029e4:	1782                	slli	a5,a5,0x20
    800029e6:	9381                	srli	a5,a5,0x20
    800029e8:	078e                	slli	a5,a5,0x3
    800029ea:	97de                	add	a5,a5,s7
    800029ec:	6390                	ld	a2,0(a5)
    800029ee:	bf4d                	j	800029a0 <procdump+0x5a>
  }
}
    800029f0:	60a6                	ld	ra,72(sp)
    800029f2:	6406                	ld	s0,64(sp)
    800029f4:	74e2                	ld	s1,56(sp)
    800029f6:	7942                	ld	s2,48(sp)
    800029f8:	79a2                	ld	s3,40(sp)
    800029fa:	7a02                	ld	s4,32(sp)
    800029fc:	6ae2                	ld	s5,24(sp)
    800029fe:	6b42                	ld	s6,16(sp)
    80002a00:	6ba2                	ld	s7,8(sp)
    80002a02:	6161                	addi	sp,sp,80
    80002a04:	8082                	ret

0000000080002a06 <pause_system>:

int
pause_system(const int seconds)
{
    80002a06:	1101                	addi	sp,sp,-32
    80002a08:	ec06                	sd	ra,24(sp)
    80002a0a:	e822                	sd	s0,16(sp)
    80002a0c:	e426                	sd	s1,8(sp)
    80002a0e:	e04a                	sd	s2,0(sp)
    80002a10:	1000                	addi	s0,sp,32
    80002a12:	892a                	mv	s2,a0
  while(paused)
    80002a14:	00006797          	auipc	a5,0x6
    80002a18:	6187a783          	lw	a5,1560(a5) # 8000902c <paused>
    80002a1c:	cf81                	beqz	a5,80002a34 <pause_system+0x2e>
    80002a1e:	00006497          	auipc	s1,0x6
    80002a22:	60e48493          	addi	s1,s1,1550 # 8000902c <paused>
    yield();
    80002a26:	00000097          	auipc	ra,0x0
    80002a2a:	828080e7          	jalr	-2008(ra) # 8000224e <yield>
  while(paused)
    80002a2e:	409c                	lw	a5,0(s1)
    80002a30:	2781                	sext.w	a5,a5
    80002a32:	fbf5                	bnez	a5,80002a26 <pause_system+0x20>

  // print for debug
  struct proc* p = myproc();
    80002a34:	fffff097          	auipc	ra,0xfffff
    80002a38:	fbe080e7          	jalr	-66(ra) # 800019f2 <myproc>
  if(p->killed)
    80002a3c:	5504                	lw	s1,40(a0)
    80002a3e:	2481                	sext.w	s1,s1
    80002a40:	e0a5                	bnez	s1,80002aa0 <pause_system+0x9a>
  {
    printf("Pronc: %s, number: %d died during pause_sytem execution\n", p->name, p->pid);
    return -1;  
  }

  printf("Proc: %s, number: %d pause system\n", p->name, p->pid);
    80002a42:	5910                	lw	a2,48(a0)
    80002a44:	15850593          	addi	a1,a0,344
    80002a48:	00006517          	auipc	a0,0x6
    80002a4c:	89050513          	addi	a0,a0,-1904 # 800082d8 <digits+0x298>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	b3a080e7          	jalr	-1222(ra) # 8000058a <printf>

  paused |= 1;
    80002a58:	00006797          	auipc	a5,0x6
    80002a5c:	5d47a783          	lw	a5,1492(a5) # 8000902c <paused>
    80002a60:	0017e793          	ori	a5,a5,1
    80002a64:	00006717          	auipc	a4,0x6
    80002a68:	5cf72423          	sw	a5,1480(a4) # 8000902c <paused>
  //acquire(&tickslock);
  pause_interval = ticks + (seconds * 10);
    80002a6c:	0029179b          	slliw	a5,s2,0x2
    80002a70:	012787bb          	addw	a5,a5,s2
    80002a74:	0017979b          	slliw	a5,a5,0x1
    80002a78:	00006717          	auipc	a4,0x6
    80002a7c:	5dc72703          	lw	a4,1500(a4) # 80009054 <ticks>
    80002a80:	9fb9                	addw	a5,a5,a4
    80002a82:	00006717          	auipc	a4,0x6
    80002a86:	5af72323          	sw	a5,1446(a4) # 80009028 <pause_interval>
  //release(&tickslock);

  yield();
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	7c4080e7          	jalr	1988(ra) # 8000224e <yield>
  return 0;
}
    80002a92:	8526                	mv	a0,s1
    80002a94:	60e2                	ld	ra,24(sp)
    80002a96:	6442                	ld	s0,16(sp)
    80002a98:	64a2                	ld	s1,8(sp)
    80002a9a:	6902                	ld	s2,0(sp)
    80002a9c:	6105                	addi	sp,sp,32
    80002a9e:	8082                	ret
    printf("Pronc: %s, number: %d died during pause_sytem execution\n", p->name, p->pid);
    80002aa0:	5910                	lw	a2,48(a0)
    80002aa2:	15850593          	addi	a1,a0,344
    80002aa6:	00005517          	auipc	a0,0x5
    80002aaa:	7f250513          	addi	a0,a0,2034 # 80008298 <digits+0x258>
    80002aae:	ffffe097          	auipc	ra,0xffffe
    80002ab2:	adc080e7          	jalr	-1316(ra) # 8000058a <printf>
    return -1;  
    80002ab6:	54fd                	li	s1,-1
    80002ab8:	bfe9                	j	80002a92 <pause_system+0x8c>

0000000080002aba <kill_system>:

#define INIT_SH_PROC 2
int 
kill_system(void)
{
    80002aba:	711d                	addi	sp,sp,-96
    80002abc:	ec86                	sd	ra,88(sp)
    80002abe:	e8a2                	sd	s0,80(sp)
    80002ac0:	e4a6                	sd	s1,72(sp)
    80002ac2:	e0ca                	sd	s2,64(sp)
    80002ac4:	fc4e                	sd	s3,56(sp)
    80002ac6:	f852                	sd	s4,48(sp)
    80002ac8:	f456                	sd	s5,40(sp)
    80002aca:	f05a                	sd	s6,32(sp)
    80002acc:	ec5e                	sd	s7,24(sp)
    80002ace:	e862                	sd	s8,16(sp)
    80002ad0:	e466                	sd	s9,8(sp)
    80002ad2:	1080                	addi	s0,sp,96

  struct proc* p;
  // Below parameters are used for debug.
  struct proc* mp = myproc();
    80002ad4:	fffff097          	auipc	ra,0xfffff
    80002ad8:	f1e080e7          	jalr	-226(ra) # 800019f2 <myproc>
  int pid = mp->pid;
    80002adc:	03052b83          	lw	s7,48(a0)
  const char* name = mp->name;
    80002ae0:	15850a93          	addi	s5,a0,344


  /* 
  * Set killed flag for all process besides init & sh.
  */
  for(p = proc; p < &proc[NPROC]; p++)
    80002ae4:	0000f497          	auipc	s1,0xf
    80002ae8:	c0c48493          	addi	s1,s1,-1012 # 800116f0 <proc>
  {
      acquire(&p->lock);
      if(p->pid > INIT_SH_PROC && p->state && !p->killed)
    80002aec:	4909                	li	s2,2
      {
        printf("Proc: %s number: %d KILL proc: %s number: %d\n",name, pid, p->name, p->pid);
    80002aee:	00006b17          	auipc	s6,0x6
    80002af2:	812b0b13          	addi	s6,s6,-2030 # 80008300 <digits+0x2c0>
        p->killed |= 1;
        if(p->state == SLEEPING){
          //calc thicks passed
          //calc thicks passed
          //acquire(&tickslock);
          int diff = ticks - p->last_update_time;
    80002af6:	00006c97          	auipc	s9,0x6
    80002afa:	55ec8c93          	addi	s9,s9,1374 # 80009054 <ticks>
          //release(&tickslock);
          p->last_update_time = ticks;
          p->sleeping_time += diff;
          //update means...
          p->state = RUNNABLE;
    80002afe:	4c0d                	li	s8,3
  for(p = proc; p < &proc[NPROC]; p++)
    80002b00:	00015a17          	auipc	s4,0x15
    80002b04:	df0a0a13          	addi	s4,s4,-528 # 800178f0 <tickslock>
    80002b08:	a811                	j	80002b1c <kill_system+0x62>
        }
      }
      release(&p->lock);
    80002b0a:	8526                	mv	a0,s1
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	18e080e7          	jalr	398(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++)
    80002b14:	18848493          	addi	s1,s1,392
    80002b18:	07448163          	beq	s1,s4,80002b7a <kill_system+0xc0>
      acquire(&p->lock);
    80002b1c:	8526                	mv	a0,s1
    80002b1e:	ffffe097          	auipc	ra,0xffffe
    80002b22:	0c8080e7          	jalr	200(ra) # 80000be6 <acquire>
      if(p->pid > INIT_SH_PROC && p->state && !p->killed)
    80002b26:	5898                	lw	a4,48(s1)
    80002b28:	fee951e3          	bge	s2,a4,80002b0a <kill_system+0x50>
    80002b2c:	4c9c                	lw	a5,24(s1)
    80002b2e:	2781                	sext.w	a5,a5
    80002b30:	dfe9                	beqz	a5,80002b0a <kill_system+0x50>
    80002b32:	549c                	lw	a5,40(s1)
    80002b34:	2781                	sext.w	a5,a5
    80002b36:	fbf1                	bnez	a5,80002b0a <kill_system+0x50>
        printf("Proc: %s number: %d KILL proc: %s number: %d\n",name, pid, p->name, p->pid);
    80002b38:	15848693          	addi	a3,s1,344
    80002b3c:	865e                	mv	a2,s7
    80002b3e:	85d6                	mv	a1,s5
    80002b40:	855a                	mv	a0,s6
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	a48080e7          	jalr	-1464(ra) # 8000058a <printf>
        p->killed |= 1;
    80002b4a:	549c                	lw	a5,40(s1)
    80002b4c:	2781                	sext.w	a5,a5
    80002b4e:	0017e793          	ori	a5,a5,1
    80002b52:	d49c                	sw	a5,40(s1)
        if(p->state == SLEEPING){
    80002b54:	4c9c                	lw	a5,24(s1)
    80002b56:	2781                	sext.w	a5,a5
    80002b58:	fb2799e3          	bne	a5,s2,80002b0a <kill_system+0x50>
          int diff = ticks - p->last_update_time;
    80002b5c:	000ca703          	lw	a4,0(s9)
    80002b60:	1804a683          	lw	a3,384(s1)
          p->last_update_time = ticks;
    80002b64:	18e4a023          	sw	a4,384(s1)
          p->sleeping_time += diff;
    80002b68:	1744a783          	lw	a5,372(s1)
    80002b6c:	9fb9                	addw	a5,a5,a4
    80002b6e:	9f95                	subw	a5,a5,a3
    80002b70:	16f4aa23          	sw	a5,372(s1)
          p->state = RUNNABLE;
    80002b74:	0184ac23          	sw	s8,24(s1)
    80002b78:	bf49                	j	80002b0a <kill_system+0x50>
  }
  return 0;
} 
    80002b7a:	4501                	li	a0,0
    80002b7c:	60e6                	ld	ra,88(sp)
    80002b7e:	6446                	ld	s0,80(sp)
    80002b80:	64a6                	ld	s1,72(sp)
    80002b82:	6906                	ld	s2,64(sp)
    80002b84:	79e2                	ld	s3,56(sp)
    80002b86:	7a42                	ld	s4,48(sp)
    80002b88:	7aa2                	ld	s5,40(sp)
    80002b8a:	7b02                	ld	s6,32(sp)
    80002b8c:	6be2                	ld	s7,24(sp)
    80002b8e:	6c42                	ld	s8,16(sp)
    80002b90:	6ca2                	ld	s9,8(sp)
    80002b92:	6125                	addi	sp,sp,96
    80002b94:	8082                	ret

0000000080002b96 <print_stats>:

void
print_stats(void){
    80002b96:	1101                	addi	sp,sp,-32
    80002b98:	ec06                	sd	ra,24(sp)
    80002b9a:	e822                	sd	s0,16(sp)
    80002b9c:	e426                	sd	s1,8(sp)
    80002b9e:	1000                	addi	s0,sp,32
  printf("_______________________\n");
    80002ba0:	00005517          	auipc	a0,0x5
    80002ba4:	79050513          	addi	a0,a0,1936 # 80008330 <digits+0x2f0>
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	9e2080e7          	jalr	-1566(ra) # 8000058a <printf>
  printf("running time mean: %d\n", running_processes_mean);
    80002bb0:	00006597          	auipc	a1,0x6
    80002bb4:	49c5a583          	lw	a1,1180(a1) # 8000904c <running_processes_mean>
    80002bb8:	00005517          	auipc	a0,0x5
    80002bbc:	79850513          	addi	a0,a0,1944 # 80008350 <digits+0x310>
    80002bc0:	ffffe097          	auipc	ra,0xffffe
    80002bc4:	9ca080e7          	jalr	-1590(ra) # 8000058a <printf>
  printf("runnable time mean: %d\n", runnable_processes_mean);
    80002bc8:	00006597          	auipc	a1,0x6
    80002bcc:	4805a583          	lw	a1,1152(a1) # 80009048 <runnable_processes_mean>
    80002bd0:	00005517          	auipc	a0,0x5
    80002bd4:	79850513          	addi	a0,a0,1944 # 80008368 <digits+0x328>
    80002bd8:	ffffe097          	auipc	ra,0xffffe
    80002bdc:	9b2080e7          	jalr	-1614(ra) # 8000058a <printf>
  printf("sleeping time mean: %d\n", sleeping_processes_mean);
    80002be0:	00006597          	auipc	a1,0x6
    80002be4:	4705a583          	lw	a1,1136(a1) # 80009050 <sleeping_processes_mean>
    80002be8:	00005517          	auipc	a0,0x5
    80002bec:	79850513          	addi	a0,a0,1944 # 80008380 <digits+0x340>
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	99a080e7          	jalr	-1638(ra) # 8000058a <printf>
  printf("program time: %d\n", program_time);
    80002bf8:	00006497          	auipc	s1,0x6
    80002bfc:	44848493          	addi	s1,s1,1096 # 80009040 <program_time>
    80002c00:	408c                	lw	a1,0(s1)
    80002c02:	00005517          	auipc	a0,0x5
    80002c06:	79650513          	addi	a0,a0,1942 # 80008398 <digits+0x358>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	980080e7          	jalr	-1664(ra) # 8000058a <printf>
  printf("cpu utilization: %d (%d/%d)\n", cpu_utilization, program_time, ticks - start_time);
    80002c12:	00006697          	auipc	a3,0x6
    80002c16:	4426a683          	lw	a3,1090(a3) # 80009054 <ticks>
    80002c1a:	00006797          	auipc	a5,0x6
    80002c1e:	41e7a783          	lw	a5,1054(a5) # 80009038 <start_time>
    80002c22:	9e9d                	subw	a3,a3,a5
    80002c24:	4090                	lw	a2,0(s1)
    80002c26:	00006597          	auipc	a1,0x6
    80002c2a:	4165a583          	lw	a1,1046(a1) # 8000903c <cpu_utilization>
    80002c2e:	00005517          	auipc	a0,0x5
    80002c32:	78250513          	addi	a0,a0,1922 # 800083b0 <digits+0x370>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	954080e7          	jalr	-1708(ra) # 8000058a <printf>
  printf("_______________________\n");
    80002c3e:	00005517          	auipc	a0,0x5
    80002c42:	6f250513          	addi	a0,a0,1778 # 80008330 <digits+0x2f0>
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	944080e7          	jalr	-1724(ra) # 8000058a <printf>
    80002c4e:	60e2                	ld	ra,24(sp)
    80002c50:	6442                	ld	s0,16(sp)
    80002c52:	64a2                	ld	s1,8(sp)
    80002c54:	6105                	addi	sp,sp,32
    80002c56:	8082                	ret

0000000080002c58 <swtch>:
    80002c58:	00153023          	sd	ra,0(a0)
    80002c5c:	00253423          	sd	sp,8(a0)
    80002c60:	e900                	sd	s0,16(a0)
    80002c62:	ed04                	sd	s1,24(a0)
    80002c64:	03253023          	sd	s2,32(a0)
    80002c68:	03353423          	sd	s3,40(a0)
    80002c6c:	03453823          	sd	s4,48(a0)
    80002c70:	03553c23          	sd	s5,56(a0)
    80002c74:	05653023          	sd	s6,64(a0)
    80002c78:	05753423          	sd	s7,72(a0)
    80002c7c:	05853823          	sd	s8,80(a0)
    80002c80:	05953c23          	sd	s9,88(a0)
    80002c84:	07a53023          	sd	s10,96(a0)
    80002c88:	07b53423          	sd	s11,104(a0)
    80002c8c:	0005b083          	ld	ra,0(a1)
    80002c90:	0085b103          	ld	sp,8(a1)
    80002c94:	6980                	ld	s0,16(a1)
    80002c96:	6d84                	ld	s1,24(a1)
    80002c98:	0205b903          	ld	s2,32(a1)
    80002c9c:	0285b983          	ld	s3,40(a1)
    80002ca0:	0305ba03          	ld	s4,48(a1)
    80002ca4:	0385ba83          	ld	s5,56(a1)
    80002ca8:	0405bb03          	ld	s6,64(a1)
    80002cac:	0485bb83          	ld	s7,72(a1)
    80002cb0:	0505bc03          	ld	s8,80(a1)
    80002cb4:	0585bc83          	ld	s9,88(a1)
    80002cb8:	0605bd03          	ld	s10,96(a1)
    80002cbc:	0685bd83          	ld	s11,104(a1)
    80002cc0:	8082                	ret

0000000080002cc2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002cc2:	1141                	addi	sp,sp,-16
    80002cc4:	e406                	sd	ra,8(sp)
    80002cc6:	e022                	sd	s0,0(sp)
    80002cc8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002cca:	00005597          	auipc	a1,0x5
    80002cce:	75e58593          	addi	a1,a1,1886 # 80008428 <states.1746+0x30>
    80002cd2:	00015517          	auipc	a0,0x15
    80002cd6:	c1e50513          	addi	a0,a0,-994 # 800178f0 <tickslock>
    80002cda:	ffffe097          	auipc	ra,0xffffe
    80002cde:	e7c080e7          	jalr	-388(ra) # 80000b56 <initlock>
}
    80002ce2:	60a2                	ld	ra,8(sp)
    80002ce4:	6402                	ld	s0,0(sp)
    80002ce6:	0141                	addi	sp,sp,16
    80002ce8:	8082                	ret

0000000080002cea <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002cea:	1141                	addi	sp,sp,-16
    80002cec:	e422                	sd	s0,8(sp)
    80002cee:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cf0:	00003797          	auipc	a5,0x3
    80002cf4:	4e078793          	addi	a5,a5,1248 # 800061d0 <kernelvec>
    80002cf8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cfc:	6422                	ld	s0,8(sp)
    80002cfe:	0141                	addi	sp,sp,16
    80002d00:	8082                	ret

0000000080002d02 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002d02:	1141                	addi	sp,sp,-16
    80002d04:	e406                	sd	ra,8(sp)
    80002d06:	e022                	sd	s0,0(sp)
    80002d08:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d0a:	fffff097          	auipc	ra,0xfffff
    80002d0e:	ce8080e7          	jalr	-792(ra) # 800019f2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d12:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d16:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d18:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002d1c:	00004617          	auipc	a2,0x4
    80002d20:	2e460613          	addi	a2,a2,740 # 80007000 <_trampoline>
    80002d24:	00004697          	auipc	a3,0x4
    80002d28:	2dc68693          	addi	a3,a3,732 # 80007000 <_trampoline>
    80002d2c:	8e91                	sub	a3,a3,a2
    80002d2e:	040007b7          	lui	a5,0x4000
    80002d32:	17fd                	addi	a5,a5,-1
    80002d34:	07b2                	slli	a5,a5,0xc
    80002d36:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d38:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d3c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d3e:	180026f3          	csrr	a3,satp
    80002d42:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d44:	6d38                	ld	a4,88(a0)
    80002d46:	6134                	ld	a3,64(a0)
    80002d48:	6585                	lui	a1,0x1
    80002d4a:	96ae                	add	a3,a3,a1
    80002d4c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d4e:	6d38                	ld	a4,88(a0)
    80002d50:	00000697          	auipc	a3,0x0
    80002d54:	13868693          	addi	a3,a3,312 # 80002e88 <usertrap>
    80002d58:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d5a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d5c:	8692                	mv	a3,tp
    80002d5e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d60:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d64:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d68:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d6c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d70:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d72:	6f18                	ld	a4,24(a4)
    80002d74:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d78:	692c                	ld	a1,80(a0)
    80002d7a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d7c:	00004717          	auipc	a4,0x4
    80002d80:	31470713          	addi	a4,a4,788 # 80007090 <userret>
    80002d84:	8f11                	sub	a4,a4,a2
    80002d86:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d88:	577d                	li	a4,-1
    80002d8a:	177e                	slli	a4,a4,0x3f
    80002d8c:	8dd9                	or	a1,a1,a4
    80002d8e:	02000537          	lui	a0,0x2000
    80002d92:	157d                	addi	a0,a0,-1
    80002d94:	0536                	slli	a0,a0,0xd
    80002d96:	9782                	jalr	a5
}
    80002d98:	60a2                	ld	ra,8(sp)
    80002d9a:	6402                	ld	s0,0(sp)
    80002d9c:	0141                	addi	sp,sp,16
    80002d9e:	8082                	ret

0000000080002da0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002da0:	1101                	addi	sp,sp,-32
    80002da2:	ec06                	sd	ra,24(sp)
    80002da4:	e822                	sd	s0,16(sp)
    80002da6:	e426                	sd	s1,8(sp)
    80002da8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002daa:	00015497          	auipc	s1,0x15
    80002dae:	b4648493          	addi	s1,s1,-1210 # 800178f0 <tickslock>
    80002db2:	8526                	mv	a0,s1
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	e32080e7          	jalr	-462(ra) # 80000be6 <acquire>
  ticks++;
    80002dbc:	00006517          	auipc	a0,0x6
    80002dc0:	29850513          	addi	a0,a0,664 # 80009054 <ticks>
    80002dc4:	411c                	lw	a5,0(a0)
    80002dc6:	2785                	addiw	a5,a5,1
    80002dc8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002dca:	fffff097          	auipc	ra,0xfffff
    80002dce:	700080e7          	jalr	1792(ra) # 800024ca <wakeup>
  release(&tickslock);
    80002dd2:	8526                	mv	a0,s1
    80002dd4:	ffffe097          	auipc	ra,0xffffe
    80002dd8:	ec6080e7          	jalr	-314(ra) # 80000c9a <release>
}
    80002ddc:	60e2                	ld	ra,24(sp)
    80002dde:	6442                	ld	s0,16(sp)
    80002de0:	64a2                	ld	s1,8(sp)
    80002de2:	6105                	addi	sp,sp,32
    80002de4:	8082                	ret

0000000080002de6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002de6:	1101                	addi	sp,sp,-32
    80002de8:	ec06                	sd	ra,24(sp)
    80002dea:	e822                	sd	s0,16(sp)
    80002dec:	e426                	sd	s1,8(sp)
    80002dee:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002df0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002df4:	00074d63          	bltz	a4,80002e0e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002df8:	57fd                	li	a5,-1
    80002dfa:	17fe                	slli	a5,a5,0x3f
    80002dfc:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002dfe:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002e00:	06f70363          	beq	a4,a5,80002e66 <devintr+0x80>
  }
}
    80002e04:	60e2                	ld	ra,24(sp)
    80002e06:	6442                	ld	s0,16(sp)
    80002e08:	64a2                	ld	s1,8(sp)
    80002e0a:	6105                	addi	sp,sp,32
    80002e0c:	8082                	ret
     (scause & 0xff) == 9){
    80002e0e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002e12:	46a5                	li	a3,9
    80002e14:	fed792e3          	bne	a5,a3,80002df8 <devintr+0x12>
    int irq = plic_claim();
    80002e18:	00003097          	auipc	ra,0x3
    80002e1c:	4c0080e7          	jalr	1216(ra) # 800062d8 <plic_claim>
    80002e20:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e22:	47a9                	li	a5,10
    80002e24:	02f50763          	beq	a0,a5,80002e52 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002e28:	4785                	li	a5,1
    80002e2a:	02f50963          	beq	a0,a5,80002e5c <devintr+0x76>
    return 1;
    80002e2e:	4505                	li	a0,1
    } else if(irq){
    80002e30:	d8f1                	beqz	s1,80002e04 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e32:	85a6                	mv	a1,s1
    80002e34:	00005517          	auipc	a0,0x5
    80002e38:	5fc50513          	addi	a0,a0,1532 # 80008430 <states.1746+0x38>
    80002e3c:	ffffd097          	auipc	ra,0xffffd
    80002e40:	74e080e7          	jalr	1870(ra) # 8000058a <printf>
      plic_complete(irq);
    80002e44:	8526                	mv	a0,s1
    80002e46:	00003097          	auipc	ra,0x3
    80002e4a:	4b6080e7          	jalr	1206(ra) # 800062fc <plic_complete>
    return 1;
    80002e4e:	4505                	li	a0,1
    80002e50:	bf55                	j	80002e04 <devintr+0x1e>
      uartintr();
    80002e52:	ffffe097          	auipc	ra,0xffffe
    80002e56:	b58080e7          	jalr	-1192(ra) # 800009aa <uartintr>
    80002e5a:	b7ed                	j	80002e44 <devintr+0x5e>
      virtio_disk_intr();
    80002e5c:	00004097          	auipc	ra,0x4
    80002e60:	980080e7          	jalr	-1664(ra) # 800067dc <virtio_disk_intr>
    80002e64:	b7c5                	j	80002e44 <devintr+0x5e>
    if(cpuid() == 0){
    80002e66:	fffff097          	auipc	ra,0xfffff
    80002e6a:	b60080e7          	jalr	-1184(ra) # 800019c6 <cpuid>
    80002e6e:	c901                	beqz	a0,80002e7e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e70:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e74:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e76:	14479073          	csrw	sip,a5
    return 2;
    80002e7a:	4509                	li	a0,2
    80002e7c:	b761                	j	80002e04 <devintr+0x1e>
      clockintr();
    80002e7e:	00000097          	auipc	ra,0x0
    80002e82:	f22080e7          	jalr	-222(ra) # 80002da0 <clockintr>
    80002e86:	b7ed                	j	80002e70 <devintr+0x8a>

0000000080002e88 <usertrap>:
{
    80002e88:	1101                	addi	sp,sp,-32
    80002e8a:	ec06                	sd	ra,24(sp)
    80002e8c:	e822                	sd	s0,16(sp)
    80002e8e:	e426                	sd	s1,8(sp)
    80002e90:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e92:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e96:	1007f793          	andi	a5,a5,256
    80002e9a:	e3b5                	bnez	a5,80002efe <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e9c:	00003797          	auipc	a5,0x3
    80002ea0:	33478793          	addi	a5,a5,820 # 800061d0 <kernelvec>
    80002ea4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ea8:	fffff097          	auipc	ra,0xfffff
    80002eac:	b4a080e7          	jalr	-1206(ra) # 800019f2 <myproc>
    80002eb0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002eb2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eb4:	14102773          	csrr	a4,sepc
    80002eb8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eba:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ebe:	47a1                	li	a5,8
    80002ec0:	04f71d63          	bne	a4,a5,80002f1a <usertrap+0x92>
    if(p->killed)
    80002ec4:	551c                	lw	a5,40(a0)
    80002ec6:	2781                	sext.w	a5,a5
    80002ec8:	e3b9                	bnez	a5,80002f0e <usertrap+0x86>
    p->trapframe->epc += 4;
    80002eca:	6cb8                	ld	a4,88(s1)
    80002ecc:	6f1c                	ld	a5,24(a4)
    80002ece:	0791                	addi	a5,a5,4
    80002ed0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ed2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ed6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eda:	10079073          	csrw	sstatus,a5
    syscall();
    80002ede:	00000097          	auipc	ra,0x0
    80002ee2:	2ca080e7          	jalr	714(ra) # 800031a8 <syscall>
  if(p->killed)
    80002ee6:	549c                	lw	a5,40(s1)
    80002ee8:	2781                	sext.w	a5,a5
    80002eea:	e7bd                	bnez	a5,80002f58 <usertrap+0xd0>
  usertrapret();
    80002eec:	00000097          	auipc	ra,0x0
    80002ef0:	e16080e7          	jalr	-490(ra) # 80002d02 <usertrapret>
}
    80002ef4:	60e2                	ld	ra,24(sp)
    80002ef6:	6442                	ld	s0,16(sp)
    80002ef8:	64a2                	ld	s1,8(sp)
    80002efa:	6105                	addi	sp,sp,32
    80002efc:	8082                	ret
    panic("usertrap: not from user mode");
    80002efe:	00005517          	auipc	a0,0x5
    80002f02:	55250513          	addi	a0,a0,1362 # 80008450 <states.1746+0x58>
    80002f06:	ffffd097          	auipc	ra,0xffffd
    80002f0a:	63a080e7          	jalr	1594(ra) # 80000540 <panic>
      exit(-1);
    80002f0e:	557d                	li	a0,-1
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	6f8080e7          	jalr	1784(ra) # 80002608 <exit>
    80002f18:	bf4d                	j	80002eca <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002f1a:	00000097          	auipc	ra,0x0
    80002f1e:	ecc080e7          	jalr	-308(ra) # 80002de6 <devintr>
    80002f22:	f171                	bnez	a0,80002ee6 <usertrap+0x5e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f24:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f28:	5890                	lw	a2,48(s1)
    80002f2a:	00005517          	auipc	a0,0x5
    80002f2e:	54650513          	addi	a0,a0,1350 # 80008470 <states.1746+0x78>
    80002f32:	ffffd097          	auipc	ra,0xffffd
    80002f36:	658080e7          	jalr	1624(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f3a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f3e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f42:	00005517          	auipc	a0,0x5
    80002f46:	55e50513          	addi	a0,a0,1374 # 800084a0 <states.1746+0xa8>
    80002f4a:	ffffd097          	auipc	ra,0xffffd
    80002f4e:	640080e7          	jalr	1600(ra) # 8000058a <printf>
    p->killed = 1;
    80002f52:	4785                	li	a5,1
    80002f54:	d49c                	sw	a5,40(s1)
    80002f56:	bf41                	j	80002ee6 <usertrap+0x5e>
    exit(-1);
    80002f58:	557d                	li	a0,-1
    80002f5a:	fffff097          	auipc	ra,0xfffff
    80002f5e:	6ae080e7          	jalr	1710(ra) # 80002608 <exit>
    80002f62:	b769                	j	80002eec <usertrap+0x64>

0000000080002f64 <kerneltrap>:
{
    80002f64:	7179                	addi	sp,sp,-48
    80002f66:	f406                	sd	ra,40(sp)
    80002f68:	f022                	sd	s0,32(sp)
    80002f6a:	ec26                	sd	s1,24(sp)
    80002f6c:	e84a                	sd	s2,16(sp)
    80002f6e:	e44e                	sd	s3,8(sp)
    80002f70:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f72:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f76:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f7a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f7e:	1004f793          	andi	a5,s1,256
    80002f82:	cb85                	beqz	a5,80002fb2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f84:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f88:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f8a:	ef85                	bnez	a5,80002fc2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f8c:	00000097          	auipc	ra,0x0
    80002f90:	e5a080e7          	jalr	-422(ra) # 80002de6 <devintr>
    80002f94:	cd1d                	beqz	a0,80002fd2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f96:	4789                	li	a5,2
    80002f98:	06f50a63          	beq	a0,a5,8000300c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f9c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fa0:	10049073          	csrw	sstatus,s1
}
    80002fa4:	70a2                	ld	ra,40(sp)
    80002fa6:	7402                	ld	s0,32(sp)
    80002fa8:	64e2                	ld	s1,24(sp)
    80002faa:	6942                	ld	s2,16(sp)
    80002fac:	69a2                	ld	s3,8(sp)
    80002fae:	6145                	addi	sp,sp,48
    80002fb0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002fb2:	00005517          	auipc	a0,0x5
    80002fb6:	50e50513          	addi	a0,a0,1294 # 800084c0 <states.1746+0xc8>
    80002fba:	ffffd097          	auipc	ra,0xffffd
    80002fbe:	586080e7          	jalr	1414(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002fc2:	00005517          	auipc	a0,0x5
    80002fc6:	52650513          	addi	a0,a0,1318 # 800084e8 <states.1746+0xf0>
    80002fca:	ffffd097          	auipc	ra,0xffffd
    80002fce:	576080e7          	jalr	1398(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002fd2:	85ce                	mv	a1,s3
    80002fd4:	00005517          	auipc	a0,0x5
    80002fd8:	53450513          	addi	a0,a0,1332 # 80008508 <states.1746+0x110>
    80002fdc:	ffffd097          	auipc	ra,0xffffd
    80002fe0:	5ae080e7          	jalr	1454(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fe4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fe8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fec:	00005517          	auipc	a0,0x5
    80002ff0:	52c50513          	addi	a0,a0,1324 # 80008518 <states.1746+0x120>
    80002ff4:	ffffd097          	auipc	ra,0xffffd
    80002ff8:	596080e7          	jalr	1430(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002ffc:	00005517          	auipc	a0,0x5
    80003000:	53450513          	addi	a0,a0,1332 # 80008530 <states.1746+0x138>
    80003004:	ffffd097          	auipc	ra,0xffffd
    80003008:	53c080e7          	jalr	1340(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	9e6080e7          	jalr	-1562(ra) # 800019f2 <myproc>
    80003014:	d541                	beqz	a0,80002f9c <kerneltrap+0x38>
    80003016:	fffff097          	auipc	ra,0xfffff
    8000301a:	9dc080e7          	jalr	-1572(ra) # 800019f2 <myproc>
    8000301e:	4d1c                	lw	a5,24(a0)
    80003020:	2781                	sext.w	a5,a5
    80003022:	4711                	li	a4,4
    80003024:	f6e79ce3          	bne	a5,a4,80002f9c <kerneltrap+0x38>
    yield();
    80003028:	fffff097          	auipc	ra,0xfffff
    8000302c:	226080e7          	jalr	550(ra) # 8000224e <yield>
    80003030:	b7b5                	j	80002f9c <kerneltrap+0x38>

0000000080003032 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003032:	1101                	addi	sp,sp,-32
    80003034:	ec06                	sd	ra,24(sp)
    80003036:	e822                	sd	s0,16(sp)
    80003038:	e426                	sd	s1,8(sp)
    8000303a:	1000                	addi	s0,sp,32
    8000303c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000303e:	fffff097          	auipc	ra,0xfffff
    80003042:	9b4080e7          	jalr	-1612(ra) # 800019f2 <myproc>
  switch (n) {
    80003046:	4795                	li	a5,5
    80003048:	0497e163          	bltu	a5,s1,8000308a <argraw+0x58>
    8000304c:	048a                	slli	s1,s1,0x2
    8000304e:	00005717          	auipc	a4,0x5
    80003052:	51a70713          	addi	a4,a4,1306 # 80008568 <states.1746+0x170>
    80003056:	94ba                	add	s1,s1,a4
    80003058:	409c                	lw	a5,0(s1)
    8000305a:	97ba                	add	a5,a5,a4
    8000305c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000305e:	6d3c                	ld	a5,88(a0)
    80003060:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003062:	60e2                	ld	ra,24(sp)
    80003064:	6442                	ld	s0,16(sp)
    80003066:	64a2                	ld	s1,8(sp)
    80003068:	6105                	addi	sp,sp,32
    8000306a:	8082                	ret
    return p->trapframe->a1;
    8000306c:	6d3c                	ld	a5,88(a0)
    8000306e:	7fa8                	ld	a0,120(a5)
    80003070:	bfcd                	j	80003062 <argraw+0x30>
    return p->trapframe->a2;
    80003072:	6d3c                	ld	a5,88(a0)
    80003074:	63c8                	ld	a0,128(a5)
    80003076:	b7f5                	j	80003062 <argraw+0x30>
    return p->trapframe->a3;
    80003078:	6d3c                	ld	a5,88(a0)
    8000307a:	67c8                	ld	a0,136(a5)
    8000307c:	b7dd                	j	80003062 <argraw+0x30>
    return p->trapframe->a4;
    8000307e:	6d3c                	ld	a5,88(a0)
    80003080:	6bc8                	ld	a0,144(a5)
    80003082:	b7c5                	j	80003062 <argraw+0x30>
    return p->trapframe->a5;
    80003084:	6d3c                	ld	a5,88(a0)
    80003086:	6fc8                	ld	a0,152(a5)
    80003088:	bfe9                	j	80003062 <argraw+0x30>
  panic("argraw");
    8000308a:	00005517          	auipc	a0,0x5
    8000308e:	4b650513          	addi	a0,a0,1206 # 80008540 <states.1746+0x148>
    80003092:	ffffd097          	auipc	ra,0xffffd
    80003096:	4ae080e7          	jalr	1198(ra) # 80000540 <panic>

000000008000309a <fetchaddr>:
{
    8000309a:	1101                	addi	sp,sp,-32
    8000309c:	ec06                	sd	ra,24(sp)
    8000309e:	e822                	sd	s0,16(sp)
    800030a0:	e426                	sd	s1,8(sp)
    800030a2:	e04a                	sd	s2,0(sp)
    800030a4:	1000                	addi	s0,sp,32
    800030a6:	84aa                	mv	s1,a0
    800030a8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800030aa:	fffff097          	auipc	ra,0xfffff
    800030ae:	948080e7          	jalr	-1720(ra) # 800019f2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800030b2:	653c                	ld	a5,72(a0)
    800030b4:	02f4f863          	bgeu	s1,a5,800030e4 <fetchaddr+0x4a>
    800030b8:	00848713          	addi	a4,s1,8
    800030bc:	02e7e663          	bltu	a5,a4,800030e8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030c0:	46a1                	li	a3,8
    800030c2:	8626                	mv	a2,s1
    800030c4:	85ca                	mv	a1,s2
    800030c6:	6928                	ld	a0,80(a0)
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	638080e7          	jalr	1592(ra) # 80001700 <copyin>
    800030d0:	00a03533          	snez	a0,a0
    800030d4:	40a00533          	neg	a0,a0
}
    800030d8:	60e2                	ld	ra,24(sp)
    800030da:	6442                	ld	s0,16(sp)
    800030dc:	64a2                	ld	s1,8(sp)
    800030de:	6902                	ld	s2,0(sp)
    800030e0:	6105                	addi	sp,sp,32
    800030e2:	8082                	ret
    return -1;
    800030e4:	557d                	li	a0,-1
    800030e6:	bfcd                	j	800030d8 <fetchaddr+0x3e>
    800030e8:	557d                	li	a0,-1
    800030ea:	b7fd                	j	800030d8 <fetchaddr+0x3e>

00000000800030ec <fetchstr>:
{
    800030ec:	7179                	addi	sp,sp,-48
    800030ee:	f406                	sd	ra,40(sp)
    800030f0:	f022                	sd	s0,32(sp)
    800030f2:	ec26                	sd	s1,24(sp)
    800030f4:	e84a                	sd	s2,16(sp)
    800030f6:	e44e                	sd	s3,8(sp)
    800030f8:	1800                	addi	s0,sp,48
    800030fa:	892a                	mv	s2,a0
    800030fc:	84ae                	mv	s1,a1
    800030fe:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003100:	fffff097          	auipc	ra,0xfffff
    80003104:	8f2080e7          	jalr	-1806(ra) # 800019f2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003108:	86ce                	mv	a3,s3
    8000310a:	864a                	mv	a2,s2
    8000310c:	85a6                	mv	a1,s1
    8000310e:	6928                	ld	a0,80(a0)
    80003110:	ffffe097          	auipc	ra,0xffffe
    80003114:	67c080e7          	jalr	1660(ra) # 8000178c <copyinstr>
  if(err < 0)
    80003118:	00054763          	bltz	a0,80003126 <fetchstr+0x3a>
  return strlen(buf);
    8000311c:	8526                	mv	a0,s1
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	d48080e7          	jalr	-696(ra) # 80000e66 <strlen>
}
    80003126:	70a2                	ld	ra,40(sp)
    80003128:	7402                	ld	s0,32(sp)
    8000312a:	64e2                	ld	s1,24(sp)
    8000312c:	6942                	ld	s2,16(sp)
    8000312e:	69a2                	ld	s3,8(sp)
    80003130:	6145                	addi	sp,sp,48
    80003132:	8082                	ret

0000000080003134 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80003134:	1101                	addi	sp,sp,-32
    80003136:	ec06                	sd	ra,24(sp)
    80003138:	e822                	sd	s0,16(sp)
    8000313a:	e426                	sd	s1,8(sp)
    8000313c:	1000                	addi	s0,sp,32
    8000313e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003140:	00000097          	auipc	ra,0x0
    80003144:	ef2080e7          	jalr	-270(ra) # 80003032 <argraw>
    80003148:	c088                	sw	a0,0(s1)
  return 0;
}
    8000314a:	4501                	li	a0,0
    8000314c:	60e2                	ld	ra,24(sp)
    8000314e:	6442                	ld	s0,16(sp)
    80003150:	64a2                	ld	s1,8(sp)
    80003152:	6105                	addi	sp,sp,32
    80003154:	8082                	ret

0000000080003156 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003156:	1101                	addi	sp,sp,-32
    80003158:	ec06                	sd	ra,24(sp)
    8000315a:	e822                	sd	s0,16(sp)
    8000315c:	e426                	sd	s1,8(sp)
    8000315e:	1000                	addi	s0,sp,32
    80003160:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003162:	00000097          	auipc	ra,0x0
    80003166:	ed0080e7          	jalr	-304(ra) # 80003032 <argraw>
    8000316a:	e088                	sd	a0,0(s1)
  return 0;
}
    8000316c:	4501                	li	a0,0
    8000316e:	60e2                	ld	ra,24(sp)
    80003170:	6442                	ld	s0,16(sp)
    80003172:	64a2                	ld	s1,8(sp)
    80003174:	6105                	addi	sp,sp,32
    80003176:	8082                	ret

0000000080003178 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003178:	1101                	addi	sp,sp,-32
    8000317a:	ec06                	sd	ra,24(sp)
    8000317c:	e822                	sd	s0,16(sp)
    8000317e:	e426                	sd	s1,8(sp)
    80003180:	e04a                	sd	s2,0(sp)
    80003182:	1000                	addi	s0,sp,32
    80003184:	84ae                	mv	s1,a1
    80003186:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003188:	00000097          	auipc	ra,0x0
    8000318c:	eaa080e7          	jalr	-342(ra) # 80003032 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80003190:	864a                	mv	a2,s2
    80003192:	85a6                	mv	a1,s1
    80003194:	00000097          	auipc	ra,0x0
    80003198:	f58080e7          	jalr	-168(ra) # 800030ec <fetchstr>
}
    8000319c:	60e2                	ld	ra,24(sp)
    8000319e:	6442                	ld	s0,16(sp)
    800031a0:	64a2                	ld	s1,8(sp)
    800031a2:	6902                	ld	s2,0(sp)
    800031a4:	6105                	addi	sp,sp,32
    800031a6:	8082                	ret

00000000800031a8 <syscall>:
};


void
syscall(void)
{
    800031a8:	1101                	addi	sp,sp,-32
    800031aa:	ec06                	sd	ra,24(sp)
    800031ac:	e822                	sd	s0,16(sp)
    800031ae:	e426                	sd	s1,8(sp)
    800031b0:	e04a                	sd	s2,0(sp)
    800031b2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800031b4:	fffff097          	auipc	ra,0xfffff
    800031b8:	83e080e7          	jalr	-1986(ra) # 800019f2 <myproc>
    800031bc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800031be:	05853903          	ld	s2,88(a0)
    800031c2:	0a893783          	ld	a5,168(s2)
    800031c6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800031ca:	37fd                	addiw	a5,a5,-1
    800031cc:	475d                	li	a4,23
    800031ce:	00f76f63          	bltu	a4,a5,800031ec <syscall+0x44>
    800031d2:	00369713          	slli	a4,a3,0x3
    800031d6:	00005797          	auipc	a5,0x5
    800031da:	3aa78793          	addi	a5,a5,938 # 80008580 <syscalls>
    800031de:	97ba                	add	a5,a5,a4
    800031e0:	639c                	ld	a5,0(a5)
    800031e2:	c789                	beqz	a5,800031ec <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800031e4:	9782                	jalr	a5
    800031e6:	06a93823          	sd	a0,112(s2)
    800031ea:	a839                	j	80003208 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800031ec:	15848613          	addi	a2,s1,344
    800031f0:	588c                	lw	a1,48(s1)
    800031f2:	00005517          	auipc	a0,0x5
    800031f6:	35650513          	addi	a0,a0,854 # 80008548 <states.1746+0x150>
    800031fa:	ffffd097          	auipc	ra,0xffffd
    800031fe:	390080e7          	jalr	912(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003202:	6cbc                	ld	a5,88(s1)
    80003204:	577d                	li	a4,-1
    80003206:	fbb8                	sd	a4,112(a5)
  }
}
    80003208:	60e2                	ld	ra,24(sp)
    8000320a:	6442                	ld	s0,16(sp)
    8000320c:	64a2                	ld	s1,8(sp)
    8000320e:	6902                	ld	s2,0(sp)
    80003210:	6105                	addi	sp,sp,32
    80003212:	8082                	ret

0000000080003214 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003214:	1101                	addi	sp,sp,-32
    80003216:	ec06                	sd	ra,24(sp)
    80003218:	e822                	sd	s0,16(sp)
    8000321a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    8000321c:	fec40593          	addi	a1,s0,-20
    80003220:	4501                	li	a0,0
    80003222:	00000097          	auipc	ra,0x0
    80003226:	f12080e7          	jalr	-238(ra) # 80003134 <argint>
    return -1;
    8000322a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000322c:	00054963          	bltz	a0,8000323e <sys_exit+0x2a>
  exit(n);
    80003230:	fec42503          	lw	a0,-20(s0)
    80003234:	fffff097          	auipc	ra,0xfffff
    80003238:	3d4080e7          	jalr	980(ra) # 80002608 <exit>
  return 0;  // not reached
    8000323c:	4781                	li	a5,0
}
    8000323e:	853e                	mv	a0,a5
    80003240:	60e2                	ld	ra,24(sp)
    80003242:	6442                	ld	s0,16(sp)
    80003244:	6105                	addi	sp,sp,32
    80003246:	8082                	ret

0000000080003248 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003248:	1141                	addi	sp,sp,-16
    8000324a:	e406                	sd	ra,8(sp)
    8000324c:	e022                	sd	s0,0(sp)
    8000324e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003250:	ffffe097          	auipc	ra,0xffffe
    80003254:	7a2080e7          	jalr	1954(ra) # 800019f2 <myproc>
}
    80003258:	5908                	lw	a0,48(a0)
    8000325a:	60a2                	ld	ra,8(sp)
    8000325c:	6402                	ld	s0,0(sp)
    8000325e:	0141                	addi	sp,sp,16
    80003260:	8082                	ret

0000000080003262 <sys_fork>:

uint64
sys_fork(void)
{
    80003262:	1141                	addi	sp,sp,-16
    80003264:	e406                	sd	ra,8(sp)
    80003266:	e022                	sd	s0,0(sp)
    80003268:	0800                	addi	s0,sp,16
  return fork();
    8000326a:	fffff097          	auipc	ra,0xfffff
    8000326e:	ba8080e7          	jalr	-1112(ra) # 80001e12 <fork>
}
    80003272:	60a2                	ld	ra,8(sp)
    80003274:	6402                	ld	s0,0(sp)
    80003276:	0141                	addi	sp,sp,16
    80003278:	8082                	ret

000000008000327a <sys_wait>:

uint64
sys_wait(void)
{
    8000327a:	1101                	addi	sp,sp,-32
    8000327c:	ec06                	sd	ra,24(sp)
    8000327e:	e822                	sd	s0,16(sp)
    80003280:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80003282:	fe840593          	addi	a1,s0,-24
    80003286:	4501                	li	a0,0
    80003288:	00000097          	auipc	ra,0x0
    8000328c:	ece080e7          	jalr	-306(ra) # 80003156 <argaddr>
    80003290:	87aa                	mv	a5,a0
    return -1;
    80003292:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003294:	0007c863          	bltz	a5,800032a4 <sys_wait+0x2a>
  return wait(p);
    80003298:	fe843503          	ld	a0,-24(s0)
    8000329c:	fffff097          	auipc	ra,0xfffff
    800032a0:	102080e7          	jalr	258(ra) # 8000239e <wait>
}
    800032a4:	60e2                	ld	ra,24(sp)
    800032a6:	6442                	ld	s0,16(sp)
    800032a8:	6105                	addi	sp,sp,32
    800032aa:	8082                	ret

00000000800032ac <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800032ac:	7179                	addi	sp,sp,-48
    800032ae:	f406                	sd	ra,40(sp)
    800032b0:	f022                	sd	s0,32(sp)
    800032b2:	ec26                	sd	s1,24(sp)
    800032b4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800032b6:	fdc40593          	addi	a1,s0,-36
    800032ba:	4501                	li	a0,0
    800032bc:	00000097          	auipc	ra,0x0
    800032c0:	e78080e7          	jalr	-392(ra) # 80003134 <argint>
    800032c4:	87aa                	mv	a5,a0
    return -1;
    800032c6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800032c8:	0207c063          	bltz	a5,800032e8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800032cc:	ffffe097          	auipc	ra,0xffffe
    800032d0:	726080e7          	jalr	1830(ra) # 800019f2 <myproc>
    800032d4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800032d6:	fdc42503          	lw	a0,-36(s0)
    800032da:	fffff097          	auipc	ra,0xfffff
    800032de:	ac4080e7          	jalr	-1340(ra) # 80001d9e <growproc>
    800032e2:	00054863          	bltz	a0,800032f2 <sys_sbrk+0x46>
    return -1;
  return addr;
    800032e6:	8526                	mv	a0,s1
}
    800032e8:	70a2                	ld	ra,40(sp)
    800032ea:	7402                	ld	s0,32(sp)
    800032ec:	64e2                	ld	s1,24(sp)
    800032ee:	6145                	addi	sp,sp,48
    800032f0:	8082                	ret
    return -1;
    800032f2:	557d                	li	a0,-1
    800032f4:	bfd5                	j	800032e8 <sys_sbrk+0x3c>

00000000800032f6 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032f6:	7139                	addi	sp,sp,-64
    800032f8:	fc06                	sd	ra,56(sp)
    800032fa:	f822                	sd	s0,48(sp)
    800032fc:	f426                	sd	s1,40(sp)
    800032fe:	f04a                	sd	s2,32(sp)
    80003300:	ec4e                	sd	s3,24(sp)
    80003302:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003304:	fcc40593          	addi	a1,s0,-52
    80003308:	4501                	li	a0,0
    8000330a:	00000097          	auipc	ra,0x0
    8000330e:	e2a080e7          	jalr	-470(ra) # 80003134 <argint>
    return -1;
    80003312:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003314:	06054663          	bltz	a0,80003380 <sys_sleep+0x8a>
  acquire(&tickslock);
    80003318:	00014517          	auipc	a0,0x14
    8000331c:	5d850513          	addi	a0,a0,1496 # 800178f0 <tickslock>
    80003320:	ffffe097          	auipc	ra,0xffffe
    80003324:	8c6080e7          	jalr	-1850(ra) # 80000be6 <acquire>
  ticks0 = ticks;
    80003328:	00006917          	auipc	s2,0x6
    8000332c:	d2c92903          	lw	s2,-724(s2) # 80009054 <ticks>
  while(ticks - ticks0 < n){
    80003330:	fcc42783          	lw	a5,-52(s0)
    80003334:	cf8d                	beqz	a5,8000336e <sys_sleep+0x78>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003336:	00014997          	auipc	s3,0x14
    8000333a:	5ba98993          	addi	s3,s3,1466 # 800178f0 <tickslock>
    8000333e:	00006497          	auipc	s1,0x6
    80003342:	d1648493          	addi	s1,s1,-746 # 80009054 <ticks>
    if(myproc()->killed){
    80003346:	ffffe097          	auipc	ra,0xffffe
    8000334a:	6ac080e7          	jalr	1708(ra) # 800019f2 <myproc>
    8000334e:	551c                	lw	a5,40(a0)
    80003350:	2781                	sext.w	a5,a5
    80003352:	ef9d                	bnez	a5,80003390 <sys_sleep+0x9a>
    sleep(&ticks, &tickslock);
    80003354:	85ce                	mv	a1,s3
    80003356:	8526                	mv	a0,s1
    80003358:	fffff097          	auipc	ra,0xfffff
    8000335c:	f8c080e7          	jalr	-116(ra) # 800022e4 <sleep>
  while(ticks - ticks0 < n){
    80003360:	409c                	lw	a5,0(s1)
    80003362:	412787bb          	subw	a5,a5,s2
    80003366:	fcc42703          	lw	a4,-52(s0)
    8000336a:	fce7eee3          	bltu	a5,a4,80003346 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000336e:	00014517          	auipc	a0,0x14
    80003372:	58250513          	addi	a0,a0,1410 # 800178f0 <tickslock>
    80003376:	ffffe097          	auipc	ra,0xffffe
    8000337a:	924080e7          	jalr	-1756(ra) # 80000c9a <release>
  return 0;
    8000337e:	4781                	li	a5,0
}
    80003380:	853e                	mv	a0,a5
    80003382:	70e2                	ld	ra,56(sp)
    80003384:	7442                	ld	s0,48(sp)
    80003386:	74a2                	ld	s1,40(sp)
    80003388:	7902                	ld	s2,32(sp)
    8000338a:	69e2                	ld	s3,24(sp)
    8000338c:	6121                	addi	sp,sp,64
    8000338e:	8082                	ret
      release(&tickslock);
    80003390:	00014517          	auipc	a0,0x14
    80003394:	56050513          	addi	a0,a0,1376 # 800178f0 <tickslock>
    80003398:	ffffe097          	auipc	ra,0xffffe
    8000339c:	902080e7          	jalr	-1790(ra) # 80000c9a <release>
      return -1;
    800033a0:	57fd                	li	a5,-1
    800033a2:	bff9                	j	80003380 <sys_sleep+0x8a>

00000000800033a4 <sys_kill>:

uint64
sys_kill(void)
{
    800033a4:	1101                	addi	sp,sp,-32
    800033a6:	ec06                	sd	ra,24(sp)
    800033a8:	e822                	sd	s0,16(sp)
    800033aa:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800033ac:	fec40593          	addi	a1,s0,-20
    800033b0:	4501                	li	a0,0
    800033b2:	00000097          	auipc	ra,0x0
    800033b6:	d82080e7          	jalr	-638(ra) # 80003134 <argint>
    800033ba:	87aa                	mv	a5,a0
    return -1;
    800033bc:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800033be:	0007c863          	bltz	a5,800033ce <sys_kill+0x2a>
  return kill(pid);
    800033c2:	fec42503          	lw	a0,-20(s0)
    800033c6:	fffff097          	auipc	ra,0xfffff
    800033ca:	406080e7          	jalr	1030(ra) # 800027cc <kill>
}
    800033ce:	60e2                	ld	ra,24(sp)
    800033d0:	6442                	ld	s0,16(sp)
    800033d2:	6105                	addi	sp,sp,32
    800033d4:	8082                	ret

00000000800033d6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033d6:	1101                	addi	sp,sp,-32
    800033d8:	ec06                	sd	ra,24(sp)
    800033da:	e822                	sd	s0,16(sp)
    800033dc:	e426                	sd	s1,8(sp)
    800033de:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800033e0:	00014517          	auipc	a0,0x14
    800033e4:	51050513          	addi	a0,a0,1296 # 800178f0 <tickslock>
    800033e8:	ffffd097          	auipc	ra,0xffffd
    800033ec:	7fe080e7          	jalr	2046(ra) # 80000be6 <acquire>
  xticks = ticks;
    800033f0:	00006497          	auipc	s1,0x6
    800033f4:	c644a483          	lw	s1,-924(s1) # 80009054 <ticks>
  release(&tickslock);
    800033f8:	00014517          	auipc	a0,0x14
    800033fc:	4f850513          	addi	a0,a0,1272 # 800178f0 <tickslock>
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	89a080e7          	jalr	-1894(ra) # 80000c9a <release>
  return xticks;
}
    80003408:	02049513          	slli	a0,s1,0x20
    8000340c:	9101                	srli	a0,a0,0x20
    8000340e:	60e2                	ld	ra,24(sp)
    80003410:	6442                	ld	s0,16(sp)
    80003412:	64a2                	ld	s1,8(sp)
    80003414:	6105                	addi	sp,sp,32
    80003416:	8082                	ret

0000000080003418 <sys_pause_system>:

uint64
sys_pause_system(void)
{
    80003418:	1101                	addi	sp,sp,-32
    8000341a:	ec06                	sd	ra,24(sp)
    8000341c:	e822                	sd	s0,16(sp)
    8000341e:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    80003420:	fec40593          	addi	a1,s0,-20
    80003424:	4501                	li	a0,0
    80003426:	00000097          	auipc	ra,0x0
    8000342a:	d0e080e7          	jalr	-754(ra) # 80003134 <argint>
    8000342e:	87aa                	mv	a5,a0
    return -1;
    80003430:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    80003432:	0007c863          	bltz	a5,80003442 <sys_pause_system+0x2a>
  return pause_system(seconds);
    80003436:	fec42503          	lw	a0,-20(s0)
    8000343a:	fffff097          	auipc	ra,0xfffff
    8000343e:	5cc080e7          	jalr	1484(ra) # 80002a06 <pause_system>
}
    80003442:	60e2                	ld	ra,24(sp)
    80003444:	6442                	ld	s0,16(sp)
    80003446:	6105                	addi	sp,sp,32
    80003448:	8082                	ret

000000008000344a <sys_kill_system>:


uint64
sys_kill_system(void)
{
    8000344a:	1141                	addi	sp,sp,-16
    8000344c:	e406                	sd	ra,8(sp)
    8000344e:	e022                	sd	s0,0(sp)
    80003450:	0800                	addi	s0,sp,16
  return kill_system();
    80003452:	fffff097          	auipc	ra,0xfffff
    80003456:	668080e7          	jalr	1640(ra) # 80002aba <kill_system>
}
    8000345a:	60a2                	ld	ra,8(sp)
    8000345c:	6402                	ld	s0,0(sp)
    8000345e:	0141                	addi	sp,sp,16
    80003460:	8082                	ret

0000000080003462 <sys_print_stats>:

uint64
sys_print_stats(void){
    80003462:	1141                	addi	sp,sp,-16
    80003464:	e406                	sd	ra,8(sp)
    80003466:	e022                	sd	s0,0(sp)
    80003468:	0800                	addi	s0,sp,16
  print_stats();
    8000346a:	fffff097          	auipc	ra,0xfffff
    8000346e:	72c080e7          	jalr	1836(ra) # 80002b96 <print_stats>
  return 0;
}
    80003472:	4501                	li	a0,0
    80003474:	60a2                	ld	ra,8(sp)
    80003476:	6402                	ld	s0,0(sp)
    80003478:	0141                	addi	sp,sp,16
    8000347a:	8082                	ret

000000008000347c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000347c:	7179                	addi	sp,sp,-48
    8000347e:	f406                	sd	ra,40(sp)
    80003480:	f022                	sd	s0,32(sp)
    80003482:	ec26                	sd	s1,24(sp)
    80003484:	e84a                	sd	s2,16(sp)
    80003486:	e44e                	sd	s3,8(sp)
    80003488:	e052                	sd	s4,0(sp)
    8000348a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000348c:	00005597          	auipc	a1,0x5
    80003490:	1bc58593          	addi	a1,a1,444 # 80008648 <syscalls+0xc8>
    80003494:	00014517          	auipc	a0,0x14
    80003498:	47450513          	addi	a0,a0,1140 # 80017908 <bcache>
    8000349c:	ffffd097          	auipc	ra,0xffffd
    800034a0:	6ba080e7          	jalr	1722(ra) # 80000b56 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034a4:	0001c797          	auipc	a5,0x1c
    800034a8:	46478793          	addi	a5,a5,1124 # 8001f908 <bcache+0x8000>
    800034ac:	0001c717          	auipc	a4,0x1c
    800034b0:	6c470713          	addi	a4,a4,1732 # 8001fb70 <bcache+0x8268>
    800034b4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034b8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034bc:	00014497          	auipc	s1,0x14
    800034c0:	46448493          	addi	s1,s1,1124 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    800034c4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034c6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034c8:	00005a17          	auipc	s4,0x5
    800034cc:	188a0a13          	addi	s4,s4,392 # 80008650 <syscalls+0xd0>
    b->next = bcache.head.next;
    800034d0:	2b893783          	ld	a5,696(s2)
    800034d4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034d6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034da:	85d2                	mv	a1,s4
    800034dc:	01048513          	addi	a0,s1,16
    800034e0:	00001097          	auipc	ra,0x1
    800034e4:	4bc080e7          	jalr	1212(ra) # 8000499c <initsleeplock>
    bcache.head.next->prev = b;
    800034e8:	2b893783          	ld	a5,696(s2)
    800034ec:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034ee:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034f2:	45848493          	addi	s1,s1,1112
    800034f6:	fd349de3          	bne	s1,s3,800034d0 <binit+0x54>
  }
}
    800034fa:	70a2                	ld	ra,40(sp)
    800034fc:	7402                	ld	s0,32(sp)
    800034fe:	64e2                	ld	s1,24(sp)
    80003500:	6942                	ld	s2,16(sp)
    80003502:	69a2                	ld	s3,8(sp)
    80003504:	6a02                	ld	s4,0(sp)
    80003506:	6145                	addi	sp,sp,48
    80003508:	8082                	ret

000000008000350a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000350a:	7179                	addi	sp,sp,-48
    8000350c:	f406                	sd	ra,40(sp)
    8000350e:	f022                	sd	s0,32(sp)
    80003510:	ec26                	sd	s1,24(sp)
    80003512:	e84a                	sd	s2,16(sp)
    80003514:	e44e                	sd	s3,8(sp)
    80003516:	1800                	addi	s0,sp,48
    80003518:	89aa                	mv	s3,a0
    8000351a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000351c:	00014517          	auipc	a0,0x14
    80003520:	3ec50513          	addi	a0,a0,1004 # 80017908 <bcache>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	6c2080e7          	jalr	1730(ra) # 80000be6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000352c:	0001c497          	auipc	s1,0x1c
    80003530:	6944b483          	ld	s1,1684(s1) # 8001fbc0 <bcache+0x82b8>
    80003534:	0001c797          	auipc	a5,0x1c
    80003538:	63c78793          	addi	a5,a5,1596 # 8001fb70 <bcache+0x8268>
    8000353c:	02f48f63          	beq	s1,a5,8000357a <bread+0x70>
    80003540:	873e                	mv	a4,a5
    80003542:	a021                	j	8000354a <bread+0x40>
    80003544:	68a4                	ld	s1,80(s1)
    80003546:	02e48a63          	beq	s1,a4,8000357a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000354a:	449c                	lw	a5,8(s1)
    8000354c:	ff379ce3          	bne	a5,s3,80003544 <bread+0x3a>
    80003550:	44dc                	lw	a5,12(s1)
    80003552:	ff2799e3          	bne	a5,s2,80003544 <bread+0x3a>
      b->refcnt++;
    80003556:	40bc                	lw	a5,64(s1)
    80003558:	2785                	addiw	a5,a5,1
    8000355a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000355c:	00014517          	auipc	a0,0x14
    80003560:	3ac50513          	addi	a0,a0,940 # 80017908 <bcache>
    80003564:	ffffd097          	auipc	ra,0xffffd
    80003568:	736080e7          	jalr	1846(ra) # 80000c9a <release>
      acquiresleep(&b->lock);
    8000356c:	01048513          	addi	a0,s1,16
    80003570:	00001097          	auipc	ra,0x1
    80003574:	466080e7          	jalr	1126(ra) # 800049d6 <acquiresleep>
      return b;
    80003578:	a8b9                	j	800035d6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000357a:	0001c497          	auipc	s1,0x1c
    8000357e:	63e4b483          	ld	s1,1598(s1) # 8001fbb8 <bcache+0x82b0>
    80003582:	0001c797          	auipc	a5,0x1c
    80003586:	5ee78793          	addi	a5,a5,1518 # 8001fb70 <bcache+0x8268>
    8000358a:	00f48863          	beq	s1,a5,8000359a <bread+0x90>
    8000358e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003590:	40bc                	lw	a5,64(s1)
    80003592:	cf81                	beqz	a5,800035aa <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003594:	64a4                	ld	s1,72(s1)
    80003596:	fee49de3          	bne	s1,a4,80003590 <bread+0x86>
  panic("bget: no buffers");
    8000359a:	00005517          	auipc	a0,0x5
    8000359e:	0be50513          	addi	a0,a0,190 # 80008658 <syscalls+0xd8>
    800035a2:	ffffd097          	auipc	ra,0xffffd
    800035a6:	f9e080e7          	jalr	-98(ra) # 80000540 <panic>
      b->dev = dev;
    800035aa:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800035ae:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800035b2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035b6:	4785                	li	a5,1
    800035b8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035ba:	00014517          	auipc	a0,0x14
    800035be:	34e50513          	addi	a0,a0,846 # 80017908 <bcache>
    800035c2:	ffffd097          	auipc	ra,0xffffd
    800035c6:	6d8080e7          	jalr	1752(ra) # 80000c9a <release>
      acquiresleep(&b->lock);
    800035ca:	01048513          	addi	a0,s1,16
    800035ce:	00001097          	auipc	ra,0x1
    800035d2:	408080e7          	jalr	1032(ra) # 800049d6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035d6:	409c                	lw	a5,0(s1)
    800035d8:	cb89                	beqz	a5,800035ea <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035da:	8526                	mv	a0,s1
    800035dc:	70a2                	ld	ra,40(sp)
    800035de:	7402                	ld	s0,32(sp)
    800035e0:	64e2                	ld	s1,24(sp)
    800035e2:	6942                	ld	s2,16(sp)
    800035e4:	69a2                	ld	s3,8(sp)
    800035e6:	6145                	addi	sp,sp,48
    800035e8:	8082                	ret
    virtio_disk_rw(b, 0);
    800035ea:	4581                	li	a1,0
    800035ec:	8526                	mv	a0,s1
    800035ee:	00003097          	auipc	ra,0x3
    800035f2:	f18080e7          	jalr	-232(ra) # 80006506 <virtio_disk_rw>
    b->valid = 1;
    800035f6:	4785                	li	a5,1
    800035f8:	c09c                	sw	a5,0(s1)
  return b;
    800035fa:	b7c5                	j	800035da <bread+0xd0>

00000000800035fc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035fc:	1101                	addi	sp,sp,-32
    800035fe:	ec06                	sd	ra,24(sp)
    80003600:	e822                	sd	s0,16(sp)
    80003602:	e426                	sd	s1,8(sp)
    80003604:	1000                	addi	s0,sp,32
    80003606:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003608:	0541                	addi	a0,a0,16
    8000360a:	00001097          	auipc	ra,0x1
    8000360e:	466080e7          	jalr	1126(ra) # 80004a70 <holdingsleep>
    80003612:	cd01                	beqz	a0,8000362a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003614:	4585                	li	a1,1
    80003616:	8526                	mv	a0,s1
    80003618:	00003097          	auipc	ra,0x3
    8000361c:	eee080e7          	jalr	-274(ra) # 80006506 <virtio_disk_rw>
}
    80003620:	60e2                	ld	ra,24(sp)
    80003622:	6442                	ld	s0,16(sp)
    80003624:	64a2                	ld	s1,8(sp)
    80003626:	6105                	addi	sp,sp,32
    80003628:	8082                	ret
    panic("bwrite");
    8000362a:	00005517          	auipc	a0,0x5
    8000362e:	04650513          	addi	a0,a0,70 # 80008670 <syscalls+0xf0>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	f0e080e7          	jalr	-242(ra) # 80000540 <panic>

000000008000363a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000363a:	1101                	addi	sp,sp,-32
    8000363c:	ec06                	sd	ra,24(sp)
    8000363e:	e822                	sd	s0,16(sp)
    80003640:	e426                	sd	s1,8(sp)
    80003642:	e04a                	sd	s2,0(sp)
    80003644:	1000                	addi	s0,sp,32
    80003646:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003648:	01050913          	addi	s2,a0,16
    8000364c:	854a                	mv	a0,s2
    8000364e:	00001097          	auipc	ra,0x1
    80003652:	422080e7          	jalr	1058(ra) # 80004a70 <holdingsleep>
    80003656:	c92d                	beqz	a0,800036c8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003658:	854a                	mv	a0,s2
    8000365a:	00001097          	auipc	ra,0x1
    8000365e:	3d2080e7          	jalr	978(ra) # 80004a2c <releasesleep>

  acquire(&bcache.lock);
    80003662:	00014517          	auipc	a0,0x14
    80003666:	2a650513          	addi	a0,a0,678 # 80017908 <bcache>
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	57c080e7          	jalr	1404(ra) # 80000be6 <acquire>
  b->refcnt--;
    80003672:	40bc                	lw	a5,64(s1)
    80003674:	37fd                	addiw	a5,a5,-1
    80003676:	0007871b          	sext.w	a4,a5
    8000367a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000367c:	eb05                	bnez	a4,800036ac <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000367e:	68bc                	ld	a5,80(s1)
    80003680:	64b8                	ld	a4,72(s1)
    80003682:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003684:	64bc                	ld	a5,72(s1)
    80003686:	68b8                	ld	a4,80(s1)
    80003688:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000368a:	0001c797          	auipc	a5,0x1c
    8000368e:	27e78793          	addi	a5,a5,638 # 8001f908 <bcache+0x8000>
    80003692:	2b87b703          	ld	a4,696(a5)
    80003696:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003698:	0001c717          	auipc	a4,0x1c
    8000369c:	4d870713          	addi	a4,a4,1240 # 8001fb70 <bcache+0x8268>
    800036a0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036a2:	2b87b703          	ld	a4,696(a5)
    800036a6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036a8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036ac:	00014517          	auipc	a0,0x14
    800036b0:	25c50513          	addi	a0,a0,604 # 80017908 <bcache>
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	5e6080e7          	jalr	1510(ra) # 80000c9a <release>
}
    800036bc:	60e2                	ld	ra,24(sp)
    800036be:	6442                	ld	s0,16(sp)
    800036c0:	64a2                	ld	s1,8(sp)
    800036c2:	6902                	ld	s2,0(sp)
    800036c4:	6105                	addi	sp,sp,32
    800036c6:	8082                	ret
    panic("brelse");
    800036c8:	00005517          	auipc	a0,0x5
    800036cc:	fb050513          	addi	a0,a0,-80 # 80008678 <syscalls+0xf8>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	e70080e7          	jalr	-400(ra) # 80000540 <panic>

00000000800036d8 <bpin>:

void
bpin(struct buf *b) {
    800036d8:	1101                	addi	sp,sp,-32
    800036da:	ec06                	sd	ra,24(sp)
    800036dc:	e822                	sd	s0,16(sp)
    800036de:	e426                	sd	s1,8(sp)
    800036e0:	1000                	addi	s0,sp,32
    800036e2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036e4:	00014517          	auipc	a0,0x14
    800036e8:	22450513          	addi	a0,a0,548 # 80017908 <bcache>
    800036ec:	ffffd097          	auipc	ra,0xffffd
    800036f0:	4fa080e7          	jalr	1274(ra) # 80000be6 <acquire>
  b->refcnt++;
    800036f4:	40bc                	lw	a5,64(s1)
    800036f6:	2785                	addiw	a5,a5,1
    800036f8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036fa:	00014517          	auipc	a0,0x14
    800036fe:	20e50513          	addi	a0,a0,526 # 80017908 <bcache>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	598080e7          	jalr	1432(ra) # 80000c9a <release>
}
    8000370a:	60e2                	ld	ra,24(sp)
    8000370c:	6442                	ld	s0,16(sp)
    8000370e:	64a2                	ld	s1,8(sp)
    80003710:	6105                	addi	sp,sp,32
    80003712:	8082                	ret

0000000080003714 <bunpin>:

void
bunpin(struct buf *b) {
    80003714:	1101                	addi	sp,sp,-32
    80003716:	ec06                	sd	ra,24(sp)
    80003718:	e822                	sd	s0,16(sp)
    8000371a:	e426                	sd	s1,8(sp)
    8000371c:	1000                	addi	s0,sp,32
    8000371e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003720:	00014517          	auipc	a0,0x14
    80003724:	1e850513          	addi	a0,a0,488 # 80017908 <bcache>
    80003728:	ffffd097          	auipc	ra,0xffffd
    8000372c:	4be080e7          	jalr	1214(ra) # 80000be6 <acquire>
  b->refcnt--;
    80003730:	40bc                	lw	a5,64(s1)
    80003732:	37fd                	addiw	a5,a5,-1
    80003734:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003736:	00014517          	auipc	a0,0x14
    8000373a:	1d250513          	addi	a0,a0,466 # 80017908 <bcache>
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	55c080e7          	jalr	1372(ra) # 80000c9a <release>
}
    80003746:	60e2                	ld	ra,24(sp)
    80003748:	6442                	ld	s0,16(sp)
    8000374a:	64a2                	ld	s1,8(sp)
    8000374c:	6105                	addi	sp,sp,32
    8000374e:	8082                	ret

0000000080003750 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003750:	1101                	addi	sp,sp,-32
    80003752:	ec06                	sd	ra,24(sp)
    80003754:	e822                	sd	s0,16(sp)
    80003756:	e426                	sd	s1,8(sp)
    80003758:	e04a                	sd	s2,0(sp)
    8000375a:	1000                	addi	s0,sp,32
    8000375c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000375e:	00d5d59b          	srliw	a1,a1,0xd
    80003762:	0001d797          	auipc	a5,0x1d
    80003766:	8827a783          	lw	a5,-1918(a5) # 8001ffe4 <sb+0x1c>
    8000376a:	9dbd                	addw	a1,a1,a5
    8000376c:	00000097          	auipc	ra,0x0
    80003770:	d9e080e7          	jalr	-610(ra) # 8000350a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003774:	0074f713          	andi	a4,s1,7
    80003778:	4785                	li	a5,1
    8000377a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000377e:	14ce                	slli	s1,s1,0x33
    80003780:	90d9                	srli	s1,s1,0x36
    80003782:	00950733          	add	a4,a0,s1
    80003786:	05874703          	lbu	a4,88(a4)
    8000378a:	00e7f6b3          	and	a3,a5,a4
    8000378e:	c69d                	beqz	a3,800037bc <bfree+0x6c>
    80003790:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003792:	94aa                	add	s1,s1,a0
    80003794:	fff7c793          	not	a5,a5
    80003798:	8ff9                	and	a5,a5,a4
    8000379a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000379e:	00001097          	auipc	ra,0x1
    800037a2:	118080e7          	jalr	280(ra) # 800048b6 <log_write>
  brelse(bp);
    800037a6:	854a                	mv	a0,s2
    800037a8:	00000097          	auipc	ra,0x0
    800037ac:	e92080e7          	jalr	-366(ra) # 8000363a <brelse>
}
    800037b0:	60e2                	ld	ra,24(sp)
    800037b2:	6442                	ld	s0,16(sp)
    800037b4:	64a2                	ld	s1,8(sp)
    800037b6:	6902                	ld	s2,0(sp)
    800037b8:	6105                	addi	sp,sp,32
    800037ba:	8082                	ret
    panic("freeing free block");
    800037bc:	00005517          	auipc	a0,0x5
    800037c0:	ec450513          	addi	a0,a0,-316 # 80008680 <syscalls+0x100>
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	d7c080e7          	jalr	-644(ra) # 80000540 <panic>

00000000800037cc <balloc>:
{
    800037cc:	711d                	addi	sp,sp,-96
    800037ce:	ec86                	sd	ra,88(sp)
    800037d0:	e8a2                	sd	s0,80(sp)
    800037d2:	e4a6                	sd	s1,72(sp)
    800037d4:	e0ca                	sd	s2,64(sp)
    800037d6:	fc4e                	sd	s3,56(sp)
    800037d8:	f852                	sd	s4,48(sp)
    800037da:	f456                	sd	s5,40(sp)
    800037dc:	f05a                	sd	s6,32(sp)
    800037de:	ec5e                	sd	s7,24(sp)
    800037e0:	e862                	sd	s8,16(sp)
    800037e2:	e466                	sd	s9,8(sp)
    800037e4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037e6:	0001c797          	auipc	a5,0x1c
    800037ea:	7e67a783          	lw	a5,2022(a5) # 8001ffcc <sb+0x4>
    800037ee:	cbd1                	beqz	a5,80003882 <balloc+0xb6>
    800037f0:	8baa                	mv	s7,a0
    800037f2:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037f4:	0001cb17          	auipc	s6,0x1c
    800037f8:	7d4b0b13          	addi	s6,s6,2004 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037fc:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037fe:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003800:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003802:	6c89                	lui	s9,0x2
    80003804:	a831                	j	80003820 <balloc+0x54>
    brelse(bp);
    80003806:	854a                	mv	a0,s2
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	e32080e7          	jalr	-462(ra) # 8000363a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003810:	015c87bb          	addw	a5,s9,s5
    80003814:	00078a9b          	sext.w	s5,a5
    80003818:	004b2703          	lw	a4,4(s6)
    8000381c:	06eaf363          	bgeu	s5,a4,80003882 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003820:	41fad79b          	sraiw	a5,s5,0x1f
    80003824:	0137d79b          	srliw	a5,a5,0x13
    80003828:	015787bb          	addw	a5,a5,s5
    8000382c:	40d7d79b          	sraiw	a5,a5,0xd
    80003830:	01cb2583          	lw	a1,28(s6)
    80003834:	9dbd                	addw	a1,a1,a5
    80003836:	855e                	mv	a0,s7
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	cd2080e7          	jalr	-814(ra) # 8000350a <bread>
    80003840:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003842:	004b2503          	lw	a0,4(s6)
    80003846:	000a849b          	sext.w	s1,s5
    8000384a:	8662                	mv	a2,s8
    8000384c:	faa4fde3          	bgeu	s1,a0,80003806 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003850:	41f6579b          	sraiw	a5,a2,0x1f
    80003854:	01d7d69b          	srliw	a3,a5,0x1d
    80003858:	00c6873b          	addw	a4,a3,a2
    8000385c:	00777793          	andi	a5,a4,7
    80003860:	9f95                	subw	a5,a5,a3
    80003862:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003866:	4037571b          	sraiw	a4,a4,0x3
    8000386a:	00e906b3          	add	a3,s2,a4
    8000386e:	0586c683          	lbu	a3,88(a3)
    80003872:	00d7f5b3          	and	a1,a5,a3
    80003876:	cd91                	beqz	a1,80003892 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003878:	2605                	addiw	a2,a2,1
    8000387a:	2485                	addiw	s1,s1,1
    8000387c:	fd4618e3          	bne	a2,s4,8000384c <balloc+0x80>
    80003880:	b759                	j	80003806 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003882:	00005517          	auipc	a0,0x5
    80003886:	e1650513          	addi	a0,a0,-490 # 80008698 <syscalls+0x118>
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	cb6080e7          	jalr	-842(ra) # 80000540 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003892:	974a                	add	a4,a4,s2
    80003894:	8fd5                	or	a5,a5,a3
    80003896:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000389a:	854a                	mv	a0,s2
    8000389c:	00001097          	auipc	ra,0x1
    800038a0:	01a080e7          	jalr	26(ra) # 800048b6 <log_write>
        brelse(bp);
    800038a4:	854a                	mv	a0,s2
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	d94080e7          	jalr	-620(ra) # 8000363a <brelse>
  bp = bread(dev, bno);
    800038ae:	85a6                	mv	a1,s1
    800038b0:	855e                	mv	a0,s7
    800038b2:	00000097          	auipc	ra,0x0
    800038b6:	c58080e7          	jalr	-936(ra) # 8000350a <bread>
    800038ba:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038bc:	40000613          	li	a2,1024
    800038c0:	4581                	li	a1,0
    800038c2:	05850513          	addi	a0,a0,88
    800038c6:	ffffd097          	auipc	ra,0xffffd
    800038ca:	41c080e7          	jalr	1052(ra) # 80000ce2 <memset>
  log_write(bp);
    800038ce:	854a                	mv	a0,s2
    800038d0:	00001097          	auipc	ra,0x1
    800038d4:	fe6080e7          	jalr	-26(ra) # 800048b6 <log_write>
  brelse(bp);
    800038d8:	854a                	mv	a0,s2
    800038da:	00000097          	auipc	ra,0x0
    800038de:	d60080e7          	jalr	-672(ra) # 8000363a <brelse>
}
    800038e2:	8526                	mv	a0,s1
    800038e4:	60e6                	ld	ra,88(sp)
    800038e6:	6446                	ld	s0,80(sp)
    800038e8:	64a6                	ld	s1,72(sp)
    800038ea:	6906                	ld	s2,64(sp)
    800038ec:	79e2                	ld	s3,56(sp)
    800038ee:	7a42                	ld	s4,48(sp)
    800038f0:	7aa2                	ld	s5,40(sp)
    800038f2:	7b02                	ld	s6,32(sp)
    800038f4:	6be2                	ld	s7,24(sp)
    800038f6:	6c42                	ld	s8,16(sp)
    800038f8:	6ca2                	ld	s9,8(sp)
    800038fa:	6125                	addi	sp,sp,96
    800038fc:	8082                	ret

00000000800038fe <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800038fe:	7179                	addi	sp,sp,-48
    80003900:	f406                	sd	ra,40(sp)
    80003902:	f022                	sd	s0,32(sp)
    80003904:	ec26                	sd	s1,24(sp)
    80003906:	e84a                	sd	s2,16(sp)
    80003908:	e44e                	sd	s3,8(sp)
    8000390a:	e052                	sd	s4,0(sp)
    8000390c:	1800                	addi	s0,sp,48
    8000390e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003910:	47ad                	li	a5,11
    80003912:	04b7fe63          	bgeu	a5,a1,8000396e <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003916:	ff45849b          	addiw	s1,a1,-12
    8000391a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000391e:	0ff00793          	li	a5,255
    80003922:	0ae7e363          	bltu	a5,a4,800039c8 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003926:	08052583          	lw	a1,128(a0)
    8000392a:	c5ad                	beqz	a1,80003994 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000392c:	00092503          	lw	a0,0(s2)
    80003930:	00000097          	auipc	ra,0x0
    80003934:	bda080e7          	jalr	-1062(ra) # 8000350a <bread>
    80003938:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000393a:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000393e:	02049593          	slli	a1,s1,0x20
    80003942:	9181                	srli	a1,a1,0x20
    80003944:	058a                	slli	a1,a1,0x2
    80003946:	00b784b3          	add	s1,a5,a1
    8000394a:	0004a983          	lw	s3,0(s1)
    8000394e:	04098d63          	beqz	s3,800039a8 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003952:	8552                	mv	a0,s4
    80003954:	00000097          	auipc	ra,0x0
    80003958:	ce6080e7          	jalr	-794(ra) # 8000363a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000395c:	854e                	mv	a0,s3
    8000395e:	70a2                	ld	ra,40(sp)
    80003960:	7402                	ld	s0,32(sp)
    80003962:	64e2                	ld	s1,24(sp)
    80003964:	6942                	ld	s2,16(sp)
    80003966:	69a2                	ld	s3,8(sp)
    80003968:	6a02                	ld	s4,0(sp)
    8000396a:	6145                	addi	sp,sp,48
    8000396c:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000396e:	02059493          	slli	s1,a1,0x20
    80003972:	9081                	srli	s1,s1,0x20
    80003974:	048a                	slli	s1,s1,0x2
    80003976:	94aa                	add	s1,s1,a0
    80003978:	0504a983          	lw	s3,80(s1)
    8000397c:	fe0990e3          	bnez	s3,8000395c <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003980:	4108                	lw	a0,0(a0)
    80003982:	00000097          	auipc	ra,0x0
    80003986:	e4a080e7          	jalr	-438(ra) # 800037cc <balloc>
    8000398a:	0005099b          	sext.w	s3,a0
    8000398e:	0534a823          	sw	s3,80(s1)
    80003992:	b7e9                	j	8000395c <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003994:	4108                	lw	a0,0(a0)
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	e36080e7          	jalr	-458(ra) # 800037cc <balloc>
    8000399e:	0005059b          	sext.w	a1,a0
    800039a2:	08b92023          	sw	a1,128(s2)
    800039a6:	b759                	j	8000392c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800039a8:	00092503          	lw	a0,0(s2)
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	e20080e7          	jalr	-480(ra) # 800037cc <balloc>
    800039b4:	0005099b          	sext.w	s3,a0
    800039b8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800039bc:	8552                	mv	a0,s4
    800039be:	00001097          	auipc	ra,0x1
    800039c2:	ef8080e7          	jalr	-264(ra) # 800048b6 <log_write>
    800039c6:	b771                	j	80003952 <bmap+0x54>
  panic("bmap: out of range");
    800039c8:	00005517          	auipc	a0,0x5
    800039cc:	ce850513          	addi	a0,a0,-792 # 800086b0 <syscalls+0x130>
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	b70080e7          	jalr	-1168(ra) # 80000540 <panic>

00000000800039d8 <iget>:
{
    800039d8:	7179                	addi	sp,sp,-48
    800039da:	f406                	sd	ra,40(sp)
    800039dc:	f022                	sd	s0,32(sp)
    800039de:	ec26                	sd	s1,24(sp)
    800039e0:	e84a                	sd	s2,16(sp)
    800039e2:	e44e                	sd	s3,8(sp)
    800039e4:	e052                	sd	s4,0(sp)
    800039e6:	1800                	addi	s0,sp,48
    800039e8:	89aa                	mv	s3,a0
    800039ea:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039ec:	0001c517          	auipc	a0,0x1c
    800039f0:	5fc50513          	addi	a0,a0,1532 # 8001ffe8 <itable>
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	1f2080e7          	jalr	498(ra) # 80000be6 <acquire>
  empty = 0;
    800039fc:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039fe:	0001c497          	auipc	s1,0x1c
    80003a02:	60248493          	addi	s1,s1,1538 # 80020000 <itable+0x18>
    80003a06:	0001e697          	auipc	a3,0x1e
    80003a0a:	08a68693          	addi	a3,a3,138 # 80021a90 <log>
    80003a0e:	a039                	j	80003a1c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a10:	02090b63          	beqz	s2,80003a46 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a14:	08848493          	addi	s1,s1,136
    80003a18:	02d48a63          	beq	s1,a3,80003a4c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a1c:	449c                	lw	a5,8(s1)
    80003a1e:	fef059e3          	blez	a5,80003a10 <iget+0x38>
    80003a22:	4098                	lw	a4,0(s1)
    80003a24:	ff3716e3          	bne	a4,s3,80003a10 <iget+0x38>
    80003a28:	40d8                	lw	a4,4(s1)
    80003a2a:	ff4713e3          	bne	a4,s4,80003a10 <iget+0x38>
      ip->ref++;
    80003a2e:	2785                	addiw	a5,a5,1
    80003a30:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a32:	0001c517          	auipc	a0,0x1c
    80003a36:	5b650513          	addi	a0,a0,1462 # 8001ffe8 <itable>
    80003a3a:	ffffd097          	auipc	ra,0xffffd
    80003a3e:	260080e7          	jalr	608(ra) # 80000c9a <release>
      return ip;
    80003a42:	8926                	mv	s2,s1
    80003a44:	a03d                	j	80003a72 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a46:	f7f9                	bnez	a5,80003a14 <iget+0x3c>
    80003a48:	8926                	mv	s2,s1
    80003a4a:	b7e9                	j	80003a14 <iget+0x3c>
  if(empty == 0)
    80003a4c:	02090c63          	beqz	s2,80003a84 <iget+0xac>
  ip->dev = dev;
    80003a50:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a54:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a58:	4785                	li	a5,1
    80003a5a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a5e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a62:	0001c517          	auipc	a0,0x1c
    80003a66:	58650513          	addi	a0,a0,1414 # 8001ffe8 <itable>
    80003a6a:	ffffd097          	auipc	ra,0xffffd
    80003a6e:	230080e7          	jalr	560(ra) # 80000c9a <release>
}
    80003a72:	854a                	mv	a0,s2
    80003a74:	70a2                	ld	ra,40(sp)
    80003a76:	7402                	ld	s0,32(sp)
    80003a78:	64e2                	ld	s1,24(sp)
    80003a7a:	6942                	ld	s2,16(sp)
    80003a7c:	69a2                	ld	s3,8(sp)
    80003a7e:	6a02                	ld	s4,0(sp)
    80003a80:	6145                	addi	sp,sp,48
    80003a82:	8082                	ret
    panic("iget: no inodes");
    80003a84:	00005517          	auipc	a0,0x5
    80003a88:	c4450513          	addi	a0,a0,-956 # 800086c8 <syscalls+0x148>
    80003a8c:	ffffd097          	auipc	ra,0xffffd
    80003a90:	ab4080e7          	jalr	-1356(ra) # 80000540 <panic>

0000000080003a94 <fsinit>:
fsinit(int dev) {
    80003a94:	7179                	addi	sp,sp,-48
    80003a96:	f406                	sd	ra,40(sp)
    80003a98:	f022                	sd	s0,32(sp)
    80003a9a:	ec26                	sd	s1,24(sp)
    80003a9c:	e84a                	sd	s2,16(sp)
    80003a9e:	e44e                	sd	s3,8(sp)
    80003aa0:	1800                	addi	s0,sp,48
    80003aa2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003aa4:	4585                	li	a1,1
    80003aa6:	00000097          	auipc	ra,0x0
    80003aaa:	a64080e7          	jalr	-1436(ra) # 8000350a <bread>
    80003aae:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ab0:	0001c997          	auipc	s3,0x1c
    80003ab4:	51898993          	addi	s3,s3,1304 # 8001ffc8 <sb>
    80003ab8:	02000613          	li	a2,32
    80003abc:	05850593          	addi	a1,a0,88
    80003ac0:	854e                	mv	a0,s3
    80003ac2:	ffffd097          	auipc	ra,0xffffd
    80003ac6:	280080e7          	jalr	640(ra) # 80000d42 <memmove>
  brelse(bp);
    80003aca:	8526                	mv	a0,s1
    80003acc:	00000097          	auipc	ra,0x0
    80003ad0:	b6e080e7          	jalr	-1170(ra) # 8000363a <brelse>
  if(sb.magic != FSMAGIC)
    80003ad4:	0009a703          	lw	a4,0(s3)
    80003ad8:	102037b7          	lui	a5,0x10203
    80003adc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ae0:	02f71263          	bne	a4,a5,80003b04 <fsinit+0x70>
  initlog(dev, &sb);
    80003ae4:	0001c597          	auipc	a1,0x1c
    80003ae8:	4e458593          	addi	a1,a1,1252 # 8001ffc8 <sb>
    80003aec:	854a                	mv	a0,s2
    80003aee:	00001097          	auipc	ra,0x1
    80003af2:	b4c080e7          	jalr	-1204(ra) # 8000463a <initlog>
}
    80003af6:	70a2                	ld	ra,40(sp)
    80003af8:	7402                	ld	s0,32(sp)
    80003afa:	64e2                	ld	s1,24(sp)
    80003afc:	6942                	ld	s2,16(sp)
    80003afe:	69a2                	ld	s3,8(sp)
    80003b00:	6145                	addi	sp,sp,48
    80003b02:	8082                	ret
    panic("invalid file system");
    80003b04:	00005517          	auipc	a0,0x5
    80003b08:	bd450513          	addi	a0,a0,-1068 # 800086d8 <syscalls+0x158>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	a34080e7          	jalr	-1484(ra) # 80000540 <panic>

0000000080003b14 <iinit>:
{
    80003b14:	7179                	addi	sp,sp,-48
    80003b16:	f406                	sd	ra,40(sp)
    80003b18:	f022                	sd	s0,32(sp)
    80003b1a:	ec26                	sd	s1,24(sp)
    80003b1c:	e84a                	sd	s2,16(sp)
    80003b1e:	e44e                	sd	s3,8(sp)
    80003b20:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b22:	00005597          	auipc	a1,0x5
    80003b26:	bce58593          	addi	a1,a1,-1074 # 800086f0 <syscalls+0x170>
    80003b2a:	0001c517          	auipc	a0,0x1c
    80003b2e:	4be50513          	addi	a0,a0,1214 # 8001ffe8 <itable>
    80003b32:	ffffd097          	auipc	ra,0xffffd
    80003b36:	024080e7          	jalr	36(ra) # 80000b56 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b3a:	0001c497          	auipc	s1,0x1c
    80003b3e:	4d648493          	addi	s1,s1,1238 # 80020010 <itable+0x28>
    80003b42:	0001e997          	auipc	s3,0x1e
    80003b46:	f5e98993          	addi	s3,s3,-162 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b4a:	00005917          	auipc	s2,0x5
    80003b4e:	bae90913          	addi	s2,s2,-1106 # 800086f8 <syscalls+0x178>
    80003b52:	85ca                	mv	a1,s2
    80003b54:	8526                	mv	a0,s1
    80003b56:	00001097          	auipc	ra,0x1
    80003b5a:	e46080e7          	jalr	-442(ra) # 8000499c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b5e:	08848493          	addi	s1,s1,136
    80003b62:	ff3498e3          	bne	s1,s3,80003b52 <iinit+0x3e>
}
    80003b66:	70a2                	ld	ra,40(sp)
    80003b68:	7402                	ld	s0,32(sp)
    80003b6a:	64e2                	ld	s1,24(sp)
    80003b6c:	6942                	ld	s2,16(sp)
    80003b6e:	69a2                	ld	s3,8(sp)
    80003b70:	6145                	addi	sp,sp,48
    80003b72:	8082                	ret

0000000080003b74 <ialloc>:
{
    80003b74:	715d                	addi	sp,sp,-80
    80003b76:	e486                	sd	ra,72(sp)
    80003b78:	e0a2                	sd	s0,64(sp)
    80003b7a:	fc26                	sd	s1,56(sp)
    80003b7c:	f84a                	sd	s2,48(sp)
    80003b7e:	f44e                	sd	s3,40(sp)
    80003b80:	f052                	sd	s4,32(sp)
    80003b82:	ec56                	sd	s5,24(sp)
    80003b84:	e85a                	sd	s6,16(sp)
    80003b86:	e45e                	sd	s7,8(sp)
    80003b88:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b8a:	0001c717          	auipc	a4,0x1c
    80003b8e:	44a72703          	lw	a4,1098(a4) # 8001ffd4 <sb+0xc>
    80003b92:	4785                	li	a5,1
    80003b94:	04e7fa63          	bgeu	a5,a4,80003be8 <ialloc+0x74>
    80003b98:	8aaa                	mv	s5,a0
    80003b9a:	8bae                	mv	s7,a1
    80003b9c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b9e:	0001ca17          	auipc	s4,0x1c
    80003ba2:	42aa0a13          	addi	s4,s4,1066 # 8001ffc8 <sb>
    80003ba6:	00048b1b          	sext.w	s6,s1
    80003baa:	0044d593          	srli	a1,s1,0x4
    80003bae:	018a2783          	lw	a5,24(s4)
    80003bb2:	9dbd                	addw	a1,a1,a5
    80003bb4:	8556                	mv	a0,s5
    80003bb6:	00000097          	auipc	ra,0x0
    80003bba:	954080e7          	jalr	-1708(ra) # 8000350a <bread>
    80003bbe:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bc0:	05850993          	addi	s3,a0,88
    80003bc4:	00f4f793          	andi	a5,s1,15
    80003bc8:	079a                	slli	a5,a5,0x6
    80003bca:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003bcc:	00099783          	lh	a5,0(s3)
    80003bd0:	c785                	beqz	a5,80003bf8 <ialloc+0x84>
    brelse(bp);
    80003bd2:	00000097          	auipc	ra,0x0
    80003bd6:	a68080e7          	jalr	-1432(ra) # 8000363a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bda:	0485                	addi	s1,s1,1
    80003bdc:	00ca2703          	lw	a4,12(s4)
    80003be0:	0004879b          	sext.w	a5,s1
    80003be4:	fce7e1e3          	bltu	a5,a4,80003ba6 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003be8:	00005517          	auipc	a0,0x5
    80003bec:	b1850513          	addi	a0,a0,-1256 # 80008700 <syscalls+0x180>
    80003bf0:	ffffd097          	auipc	ra,0xffffd
    80003bf4:	950080e7          	jalr	-1712(ra) # 80000540 <panic>
      memset(dip, 0, sizeof(*dip));
    80003bf8:	04000613          	li	a2,64
    80003bfc:	4581                	li	a1,0
    80003bfe:	854e                	mv	a0,s3
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	0e2080e7          	jalr	226(ra) # 80000ce2 <memset>
      dip->type = type;
    80003c08:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c0c:	854a                	mv	a0,s2
    80003c0e:	00001097          	auipc	ra,0x1
    80003c12:	ca8080e7          	jalr	-856(ra) # 800048b6 <log_write>
      brelse(bp);
    80003c16:	854a                	mv	a0,s2
    80003c18:	00000097          	auipc	ra,0x0
    80003c1c:	a22080e7          	jalr	-1502(ra) # 8000363a <brelse>
      return iget(dev, inum);
    80003c20:	85da                	mv	a1,s6
    80003c22:	8556                	mv	a0,s5
    80003c24:	00000097          	auipc	ra,0x0
    80003c28:	db4080e7          	jalr	-588(ra) # 800039d8 <iget>
}
    80003c2c:	60a6                	ld	ra,72(sp)
    80003c2e:	6406                	ld	s0,64(sp)
    80003c30:	74e2                	ld	s1,56(sp)
    80003c32:	7942                	ld	s2,48(sp)
    80003c34:	79a2                	ld	s3,40(sp)
    80003c36:	7a02                	ld	s4,32(sp)
    80003c38:	6ae2                	ld	s5,24(sp)
    80003c3a:	6b42                	ld	s6,16(sp)
    80003c3c:	6ba2                	ld	s7,8(sp)
    80003c3e:	6161                	addi	sp,sp,80
    80003c40:	8082                	ret

0000000080003c42 <iupdate>:
{
    80003c42:	1101                	addi	sp,sp,-32
    80003c44:	ec06                	sd	ra,24(sp)
    80003c46:	e822                	sd	s0,16(sp)
    80003c48:	e426                	sd	s1,8(sp)
    80003c4a:	e04a                	sd	s2,0(sp)
    80003c4c:	1000                	addi	s0,sp,32
    80003c4e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c50:	415c                	lw	a5,4(a0)
    80003c52:	0047d79b          	srliw	a5,a5,0x4
    80003c56:	0001c597          	auipc	a1,0x1c
    80003c5a:	38a5a583          	lw	a1,906(a1) # 8001ffe0 <sb+0x18>
    80003c5e:	9dbd                	addw	a1,a1,a5
    80003c60:	4108                	lw	a0,0(a0)
    80003c62:	00000097          	auipc	ra,0x0
    80003c66:	8a8080e7          	jalr	-1880(ra) # 8000350a <bread>
    80003c6a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c6c:	05850793          	addi	a5,a0,88
    80003c70:	40c8                	lw	a0,4(s1)
    80003c72:	893d                	andi	a0,a0,15
    80003c74:	051a                	slli	a0,a0,0x6
    80003c76:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c78:	04449703          	lh	a4,68(s1)
    80003c7c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c80:	04649703          	lh	a4,70(s1)
    80003c84:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c88:	04849703          	lh	a4,72(s1)
    80003c8c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c90:	04a49703          	lh	a4,74(s1)
    80003c94:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c98:	44f8                	lw	a4,76(s1)
    80003c9a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c9c:	03400613          	li	a2,52
    80003ca0:	05048593          	addi	a1,s1,80
    80003ca4:	0531                	addi	a0,a0,12
    80003ca6:	ffffd097          	auipc	ra,0xffffd
    80003caa:	09c080e7          	jalr	156(ra) # 80000d42 <memmove>
  log_write(bp);
    80003cae:	854a                	mv	a0,s2
    80003cb0:	00001097          	auipc	ra,0x1
    80003cb4:	c06080e7          	jalr	-1018(ra) # 800048b6 <log_write>
  brelse(bp);
    80003cb8:	854a                	mv	a0,s2
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	980080e7          	jalr	-1664(ra) # 8000363a <brelse>
}
    80003cc2:	60e2                	ld	ra,24(sp)
    80003cc4:	6442                	ld	s0,16(sp)
    80003cc6:	64a2                	ld	s1,8(sp)
    80003cc8:	6902                	ld	s2,0(sp)
    80003cca:	6105                	addi	sp,sp,32
    80003ccc:	8082                	ret

0000000080003cce <idup>:
{
    80003cce:	1101                	addi	sp,sp,-32
    80003cd0:	ec06                	sd	ra,24(sp)
    80003cd2:	e822                	sd	s0,16(sp)
    80003cd4:	e426                	sd	s1,8(sp)
    80003cd6:	1000                	addi	s0,sp,32
    80003cd8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cda:	0001c517          	auipc	a0,0x1c
    80003cde:	30e50513          	addi	a0,a0,782 # 8001ffe8 <itable>
    80003ce2:	ffffd097          	auipc	ra,0xffffd
    80003ce6:	f04080e7          	jalr	-252(ra) # 80000be6 <acquire>
  ip->ref++;
    80003cea:	449c                	lw	a5,8(s1)
    80003cec:	2785                	addiw	a5,a5,1
    80003cee:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cf0:	0001c517          	auipc	a0,0x1c
    80003cf4:	2f850513          	addi	a0,a0,760 # 8001ffe8 <itable>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	fa2080e7          	jalr	-94(ra) # 80000c9a <release>
}
    80003d00:	8526                	mv	a0,s1
    80003d02:	60e2                	ld	ra,24(sp)
    80003d04:	6442                	ld	s0,16(sp)
    80003d06:	64a2                	ld	s1,8(sp)
    80003d08:	6105                	addi	sp,sp,32
    80003d0a:	8082                	ret

0000000080003d0c <ilock>:
{
    80003d0c:	1101                	addi	sp,sp,-32
    80003d0e:	ec06                	sd	ra,24(sp)
    80003d10:	e822                	sd	s0,16(sp)
    80003d12:	e426                	sd	s1,8(sp)
    80003d14:	e04a                	sd	s2,0(sp)
    80003d16:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d18:	c115                	beqz	a0,80003d3c <ilock+0x30>
    80003d1a:	84aa                	mv	s1,a0
    80003d1c:	451c                	lw	a5,8(a0)
    80003d1e:	00f05f63          	blez	a5,80003d3c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d22:	0541                	addi	a0,a0,16
    80003d24:	00001097          	auipc	ra,0x1
    80003d28:	cb2080e7          	jalr	-846(ra) # 800049d6 <acquiresleep>
  if(ip->valid == 0){
    80003d2c:	40bc                	lw	a5,64(s1)
    80003d2e:	cf99                	beqz	a5,80003d4c <ilock+0x40>
}
    80003d30:	60e2                	ld	ra,24(sp)
    80003d32:	6442                	ld	s0,16(sp)
    80003d34:	64a2                	ld	s1,8(sp)
    80003d36:	6902                	ld	s2,0(sp)
    80003d38:	6105                	addi	sp,sp,32
    80003d3a:	8082                	ret
    panic("ilock");
    80003d3c:	00005517          	auipc	a0,0x5
    80003d40:	9dc50513          	addi	a0,a0,-1572 # 80008718 <syscalls+0x198>
    80003d44:	ffffc097          	auipc	ra,0xffffc
    80003d48:	7fc080e7          	jalr	2044(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d4c:	40dc                	lw	a5,4(s1)
    80003d4e:	0047d79b          	srliw	a5,a5,0x4
    80003d52:	0001c597          	auipc	a1,0x1c
    80003d56:	28e5a583          	lw	a1,654(a1) # 8001ffe0 <sb+0x18>
    80003d5a:	9dbd                	addw	a1,a1,a5
    80003d5c:	4088                	lw	a0,0(s1)
    80003d5e:	fffff097          	auipc	ra,0xfffff
    80003d62:	7ac080e7          	jalr	1964(ra) # 8000350a <bread>
    80003d66:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d68:	05850593          	addi	a1,a0,88
    80003d6c:	40dc                	lw	a5,4(s1)
    80003d6e:	8bbd                	andi	a5,a5,15
    80003d70:	079a                	slli	a5,a5,0x6
    80003d72:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d74:	00059783          	lh	a5,0(a1)
    80003d78:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d7c:	00259783          	lh	a5,2(a1)
    80003d80:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d84:	00459783          	lh	a5,4(a1)
    80003d88:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d8c:	00659783          	lh	a5,6(a1)
    80003d90:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d94:	459c                	lw	a5,8(a1)
    80003d96:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d98:	03400613          	li	a2,52
    80003d9c:	05b1                	addi	a1,a1,12
    80003d9e:	05048513          	addi	a0,s1,80
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	fa0080e7          	jalr	-96(ra) # 80000d42 <memmove>
    brelse(bp);
    80003daa:	854a                	mv	a0,s2
    80003dac:	00000097          	auipc	ra,0x0
    80003db0:	88e080e7          	jalr	-1906(ra) # 8000363a <brelse>
    ip->valid = 1;
    80003db4:	4785                	li	a5,1
    80003db6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003db8:	04449783          	lh	a5,68(s1)
    80003dbc:	fbb5                	bnez	a5,80003d30 <ilock+0x24>
      panic("ilock: no type");
    80003dbe:	00005517          	auipc	a0,0x5
    80003dc2:	96250513          	addi	a0,a0,-1694 # 80008720 <syscalls+0x1a0>
    80003dc6:	ffffc097          	auipc	ra,0xffffc
    80003dca:	77a080e7          	jalr	1914(ra) # 80000540 <panic>

0000000080003dce <iunlock>:
{
    80003dce:	1101                	addi	sp,sp,-32
    80003dd0:	ec06                	sd	ra,24(sp)
    80003dd2:	e822                	sd	s0,16(sp)
    80003dd4:	e426                	sd	s1,8(sp)
    80003dd6:	e04a                	sd	s2,0(sp)
    80003dd8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dda:	c905                	beqz	a0,80003e0a <iunlock+0x3c>
    80003ddc:	84aa                	mv	s1,a0
    80003dde:	01050913          	addi	s2,a0,16
    80003de2:	854a                	mv	a0,s2
    80003de4:	00001097          	auipc	ra,0x1
    80003de8:	c8c080e7          	jalr	-884(ra) # 80004a70 <holdingsleep>
    80003dec:	cd19                	beqz	a0,80003e0a <iunlock+0x3c>
    80003dee:	449c                	lw	a5,8(s1)
    80003df0:	00f05d63          	blez	a5,80003e0a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003df4:	854a                	mv	a0,s2
    80003df6:	00001097          	auipc	ra,0x1
    80003dfa:	c36080e7          	jalr	-970(ra) # 80004a2c <releasesleep>
}
    80003dfe:	60e2                	ld	ra,24(sp)
    80003e00:	6442                	ld	s0,16(sp)
    80003e02:	64a2                	ld	s1,8(sp)
    80003e04:	6902                	ld	s2,0(sp)
    80003e06:	6105                	addi	sp,sp,32
    80003e08:	8082                	ret
    panic("iunlock");
    80003e0a:	00005517          	auipc	a0,0x5
    80003e0e:	92650513          	addi	a0,a0,-1754 # 80008730 <syscalls+0x1b0>
    80003e12:	ffffc097          	auipc	ra,0xffffc
    80003e16:	72e080e7          	jalr	1838(ra) # 80000540 <panic>

0000000080003e1a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e1a:	7179                	addi	sp,sp,-48
    80003e1c:	f406                	sd	ra,40(sp)
    80003e1e:	f022                	sd	s0,32(sp)
    80003e20:	ec26                	sd	s1,24(sp)
    80003e22:	e84a                	sd	s2,16(sp)
    80003e24:	e44e                	sd	s3,8(sp)
    80003e26:	e052                	sd	s4,0(sp)
    80003e28:	1800                	addi	s0,sp,48
    80003e2a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e2c:	05050493          	addi	s1,a0,80
    80003e30:	08050913          	addi	s2,a0,128
    80003e34:	a021                	j	80003e3c <itrunc+0x22>
    80003e36:	0491                	addi	s1,s1,4
    80003e38:	01248d63          	beq	s1,s2,80003e52 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e3c:	408c                	lw	a1,0(s1)
    80003e3e:	dde5                	beqz	a1,80003e36 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e40:	0009a503          	lw	a0,0(s3)
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	90c080e7          	jalr	-1780(ra) # 80003750 <bfree>
      ip->addrs[i] = 0;
    80003e4c:	0004a023          	sw	zero,0(s1)
    80003e50:	b7dd                	j	80003e36 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e52:	0809a583          	lw	a1,128(s3)
    80003e56:	e185                	bnez	a1,80003e76 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e58:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e5c:	854e                	mv	a0,s3
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	de4080e7          	jalr	-540(ra) # 80003c42 <iupdate>
}
    80003e66:	70a2                	ld	ra,40(sp)
    80003e68:	7402                	ld	s0,32(sp)
    80003e6a:	64e2                	ld	s1,24(sp)
    80003e6c:	6942                	ld	s2,16(sp)
    80003e6e:	69a2                	ld	s3,8(sp)
    80003e70:	6a02                	ld	s4,0(sp)
    80003e72:	6145                	addi	sp,sp,48
    80003e74:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e76:	0009a503          	lw	a0,0(s3)
    80003e7a:	fffff097          	auipc	ra,0xfffff
    80003e7e:	690080e7          	jalr	1680(ra) # 8000350a <bread>
    80003e82:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e84:	05850493          	addi	s1,a0,88
    80003e88:	45850913          	addi	s2,a0,1112
    80003e8c:	a811                	j	80003ea0 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e8e:	0009a503          	lw	a0,0(s3)
    80003e92:	00000097          	auipc	ra,0x0
    80003e96:	8be080e7          	jalr	-1858(ra) # 80003750 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e9a:	0491                	addi	s1,s1,4
    80003e9c:	01248563          	beq	s1,s2,80003ea6 <itrunc+0x8c>
      if(a[j])
    80003ea0:	408c                	lw	a1,0(s1)
    80003ea2:	dde5                	beqz	a1,80003e9a <itrunc+0x80>
    80003ea4:	b7ed                	j	80003e8e <itrunc+0x74>
    brelse(bp);
    80003ea6:	8552                	mv	a0,s4
    80003ea8:	fffff097          	auipc	ra,0xfffff
    80003eac:	792080e7          	jalr	1938(ra) # 8000363a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003eb0:	0809a583          	lw	a1,128(s3)
    80003eb4:	0009a503          	lw	a0,0(s3)
    80003eb8:	00000097          	auipc	ra,0x0
    80003ebc:	898080e7          	jalr	-1896(ra) # 80003750 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ec0:	0809a023          	sw	zero,128(s3)
    80003ec4:	bf51                	j	80003e58 <itrunc+0x3e>

0000000080003ec6 <iput>:
{
    80003ec6:	1101                	addi	sp,sp,-32
    80003ec8:	ec06                	sd	ra,24(sp)
    80003eca:	e822                	sd	s0,16(sp)
    80003ecc:	e426                	sd	s1,8(sp)
    80003ece:	e04a                	sd	s2,0(sp)
    80003ed0:	1000                	addi	s0,sp,32
    80003ed2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ed4:	0001c517          	auipc	a0,0x1c
    80003ed8:	11450513          	addi	a0,a0,276 # 8001ffe8 <itable>
    80003edc:	ffffd097          	auipc	ra,0xffffd
    80003ee0:	d0a080e7          	jalr	-758(ra) # 80000be6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ee4:	4498                	lw	a4,8(s1)
    80003ee6:	4785                	li	a5,1
    80003ee8:	02f70363          	beq	a4,a5,80003f0e <iput+0x48>
  ip->ref--;
    80003eec:	449c                	lw	a5,8(s1)
    80003eee:	37fd                	addiw	a5,a5,-1
    80003ef0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ef2:	0001c517          	auipc	a0,0x1c
    80003ef6:	0f650513          	addi	a0,a0,246 # 8001ffe8 <itable>
    80003efa:	ffffd097          	auipc	ra,0xffffd
    80003efe:	da0080e7          	jalr	-608(ra) # 80000c9a <release>
}
    80003f02:	60e2                	ld	ra,24(sp)
    80003f04:	6442                	ld	s0,16(sp)
    80003f06:	64a2                	ld	s1,8(sp)
    80003f08:	6902                	ld	s2,0(sp)
    80003f0a:	6105                	addi	sp,sp,32
    80003f0c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f0e:	40bc                	lw	a5,64(s1)
    80003f10:	dff1                	beqz	a5,80003eec <iput+0x26>
    80003f12:	04a49783          	lh	a5,74(s1)
    80003f16:	fbf9                	bnez	a5,80003eec <iput+0x26>
    acquiresleep(&ip->lock);
    80003f18:	01048913          	addi	s2,s1,16
    80003f1c:	854a                	mv	a0,s2
    80003f1e:	00001097          	auipc	ra,0x1
    80003f22:	ab8080e7          	jalr	-1352(ra) # 800049d6 <acquiresleep>
    release(&itable.lock);
    80003f26:	0001c517          	auipc	a0,0x1c
    80003f2a:	0c250513          	addi	a0,a0,194 # 8001ffe8 <itable>
    80003f2e:	ffffd097          	auipc	ra,0xffffd
    80003f32:	d6c080e7          	jalr	-660(ra) # 80000c9a <release>
    itrunc(ip);
    80003f36:	8526                	mv	a0,s1
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	ee2080e7          	jalr	-286(ra) # 80003e1a <itrunc>
    ip->type = 0;
    80003f40:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f44:	8526                	mv	a0,s1
    80003f46:	00000097          	auipc	ra,0x0
    80003f4a:	cfc080e7          	jalr	-772(ra) # 80003c42 <iupdate>
    ip->valid = 0;
    80003f4e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f52:	854a                	mv	a0,s2
    80003f54:	00001097          	auipc	ra,0x1
    80003f58:	ad8080e7          	jalr	-1320(ra) # 80004a2c <releasesleep>
    acquire(&itable.lock);
    80003f5c:	0001c517          	auipc	a0,0x1c
    80003f60:	08c50513          	addi	a0,a0,140 # 8001ffe8 <itable>
    80003f64:	ffffd097          	auipc	ra,0xffffd
    80003f68:	c82080e7          	jalr	-894(ra) # 80000be6 <acquire>
    80003f6c:	b741                	j	80003eec <iput+0x26>

0000000080003f6e <iunlockput>:
{
    80003f6e:	1101                	addi	sp,sp,-32
    80003f70:	ec06                	sd	ra,24(sp)
    80003f72:	e822                	sd	s0,16(sp)
    80003f74:	e426                	sd	s1,8(sp)
    80003f76:	1000                	addi	s0,sp,32
    80003f78:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	e54080e7          	jalr	-428(ra) # 80003dce <iunlock>
  iput(ip);
    80003f82:	8526                	mv	a0,s1
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	f42080e7          	jalr	-190(ra) # 80003ec6 <iput>
}
    80003f8c:	60e2                	ld	ra,24(sp)
    80003f8e:	6442                	ld	s0,16(sp)
    80003f90:	64a2                	ld	s1,8(sp)
    80003f92:	6105                	addi	sp,sp,32
    80003f94:	8082                	ret

0000000080003f96 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f96:	1141                	addi	sp,sp,-16
    80003f98:	e422                	sd	s0,8(sp)
    80003f9a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f9c:	411c                	lw	a5,0(a0)
    80003f9e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fa0:	415c                	lw	a5,4(a0)
    80003fa2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fa4:	04451783          	lh	a5,68(a0)
    80003fa8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fac:	04a51783          	lh	a5,74(a0)
    80003fb0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fb4:	04c56783          	lwu	a5,76(a0)
    80003fb8:	e99c                	sd	a5,16(a1)
}
    80003fba:	6422                	ld	s0,8(sp)
    80003fbc:	0141                	addi	sp,sp,16
    80003fbe:	8082                	ret

0000000080003fc0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fc0:	457c                	lw	a5,76(a0)
    80003fc2:	0ed7e963          	bltu	a5,a3,800040b4 <readi+0xf4>
{
    80003fc6:	7159                	addi	sp,sp,-112
    80003fc8:	f486                	sd	ra,104(sp)
    80003fca:	f0a2                	sd	s0,96(sp)
    80003fcc:	eca6                	sd	s1,88(sp)
    80003fce:	e8ca                	sd	s2,80(sp)
    80003fd0:	e4ce                	sd	s3,72(sp)
    80003fd2:	e0d2                	sd	s4,64(sp)
    80003fd4:	fc56                	sd	s5,56(sp)
    80003fd6:	f85a                	sd	s6,48(sp)
    80003fd8:	f45e                	sd	s7,40(sp)
    80003fda:	f062                	sd	s8,32(sp)
    80003fdc:	ec66                	sd	s9,24(sp)
    80003fde:	e86a                	sd	s10,16(sp)
    80003fe0:	e46e                	sd	s11,8(sp)
    80003fe2:	1880                	addi	s0,sp,112
    80003fe4:	8baa                	mv	s7,a0
    80003fe6:	8c2e                	mv	s8,a1
    80003fe8:	8ab2                	mv	s5,a2
    80003fea:	84b6                	mv	s1,a3
    80003fec:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003fee:	9f35                	addw	a4,a4,a3
    return 0;
    80003ff0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ff2:	0ad76063          	bltu	a4,a3,80004092 <readi+0xd2>
  if(off + n > ip->size)
    80003ff6:	00e7f463          	bgeu	a5,a4,80003ffe <readi+0x3e>
    n = ip->size - off;
    80003ffa:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ffe:	0a0b0963          	beqz	s6,800040b0 <readi+0xf0>
    80004002:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004004:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004008:	5cfd                	li	s9,-1
    8000400a:	a82d                	j	80004044 <readi+0x84>
    8000400c:	020a1d93          	slli	s11,s4,0x20
    80004010:	020ddd93          	srli	s11,s11,0x20
    80004014:	05890613          	addi	a2,s2,88
    80004018:	86ee                	mv	a3,s11
    8000401a:	963a                	add	a2,a2,a4
    8000401c:	85d6                	mv	a1,s5
    8000401e:	8562                	mv	a0,s8
    80004020:	fffff097          	auipc	ra,0xfffff
    80004024:	87a080e7          	jalr	-1926(ra) # 8000289a <either_copyout>
    80004028:	05950d63          	beq	a0,s9,80004082 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000402c:	854a                	mv	a0,s2
    8000402e:	fffff097          	auipc	ra,0xfffff
    80004032:	60c080e7          	jalr	1548(ra) # 8000363a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004036:	013a09bb          	addw	s3,s4,s3
    8000403a:	009a04bb          	addw	s1,s4,s1
    8000403e:	9aee                	add	s5,s5,s11
    80004040:	0569f763          	bgeu	s3,s6,8000408e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004044:	000ba903          	lw	s2,0(s7)
    80004048:	00a4d59b          	srliw	a1,s1,0xa
    8000404c:	855e                	mv	a0,s7
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	8b0080e7          	jalr	-1872(ra) # 800038fe <bmap>
    80004056:	0005059b          	sext.w	a1,a0
    8000405a:	854a                	mv	a0,s2
    8000405c:	fffff097          	auipc	ra,0xfffff
    80004060:	4ae080e7          	jalr	1198(ra) # 8000350a <bread>
    80004064:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004066:	3ff4f713          	andi	a4,s1,1023
    8000406a:	40ed07bb          	subw	a5,s10,a4
    8000406e:	413b06bb          	subw	a3,s6,s3
    80004072:	8a3e                	mv	s4,a5
    80004074:	2781                	sext.w	a5,a5
    80004076:	0006861b          	sext.w	a2,a3
    8000407a:	f8f679e3          	bgeu	a2,a5,8000400c <readi+0x4c>
    8000407e:	8a36                	mv	s4,a3
    80004080:	b771                	j	8000400c <readi+0x4c>
      brelse(bp);
    80004082:	854a                	mv	a0,s2
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	5b6080e7          	jalr	1462(ra) # 8000363a <brelse>
      tot = -1;
    8000408c:	59fd                	li	s3,-1
  }
  return tot;
    8000408e:	0009851b          	sext.w	a0,s3
}
    80004092:	70a6                	ld	ra,104(sp)
    80004094:	7406                	ld	s0,96(sp)
    80004096:	64e6                	ld	s1,88(sp)
    80004098:	6946                	ld	s2,80(sp)
    8000409a:	69a6                	ld	s3,72(sp)
    8000409c:	6a06                	ld	s4,64(sp)
    8000409e:	7ae2                	ld	s5,56(sp)
    800040a0:	7b42                	ld	s6,48(sp)
    800040a2:	7ba2                	ld	s7,40(sp)
    800040a4:	7c02                	ld	s8,32(sp)
    800040a6:	6ce2                	ld	s9,24(sp)
    800040a8:	6d42                	ld	s10,16(sp)
    800040aa:	6da2                	ld	s11,8(sp)
    800040ac:	6165                	addi	sp,sp,112
    800040ae:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040b0:	89da                	mv	s3,s6
    800040b2:	bff1                	j	8000408e <readi+0xce>
    return 0;
    800040b4:	4501                	li	a0,0
}
    800040b6:	8082                	ret

00000000800040b8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040b8:	457c                	lw	a5,76(a0)
    800040ba:	10d7e863          	bltu	a5,a3,800041ca <writei+0x112>
{
    800040be:	7159                	addi	sp,sp,-112
    800040c0:	f486                	sd	ra,104(sp)
    800040c2:	f0a2                	sd	s0,96(sp)
    800040c4:	eca6                	sd	s1,88(sp)
    800040c6:	e8ca                	sd	s2,80(sp)
    800040c8:	e4ce                	sd	s3,72(sp)
    800040ca:	e0d2                	sd	s4,64(sp)
    800040cc:	fc56                	sd	s5,56(sp)
    800040ce:	f85a                	sd	s6,48(sp)
    800040d0:	f45e                	sd	s7,40(sp)
    800040d2:	f062                	sd	s8,32(sp)
    800040d4:	ec66                	sd	s9,24(sp)
    800040d6:	e86a                	sd	s10,16(sp)
    800040d8:	e46e                	sd	s11,8(sp)
    800040da:	1880                	addi	s0,sp,112
    800040dc:	8b2a                	mv	s6,a0
    800040de:	8c2e                	mv	s8,a1
    800040e0:	8ab2                	mv	s5,a2
    800040e2:	8936                	mv	s2,a3
    800040e4:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800040e6:	00e687bb          	addw	a5,a3,a4
    800040ea:	0ed7e263          	bltu	a5,a3,800041ce <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040ee:	00043737          	lui	a4,0x43
    800040f2:	0ef76063          	bltu	a4,a5,800041d2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040f6:	0c0b8863          	beqz	s7,800041c6 <writei+0x10e>
    800040fa:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040fc:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004100:	5cfd                	li	s9,-1
    80004102:	a091                	j	80004146 <writei+0x8e>
    80004104:	02099d93          	slli	s11,s3,0x20
    80004108:	020ddd93          	srli	s11,s11,0x20
    8000410c:	05848513          	addi	a0,s1,88
    80004110:	86ee                	mv	a3,s11
    80004112:	8656                	mv	a2,s5
    80004114:	85e2                	mv	a1,s8
    80004116:	953a                	add	a0,a0,a4
    80004118:	ffffe097          	auipc	ra,0xffffe
    8000411c:	7d8080e7          	jalr	2008(ra) # 800028f0 <either_copyin>
    80004120:	07950263          	beq	a0,s9,80004184 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004124:	8526                	mv	a0,s1
    80004126:	00000097          	auipc	ra,0x0
    8000412a:	790080e7          	jalr	1936(ra) # 800048b6 <log_write>
    brelse(bp);
    8000412e:	8526                	mv	a0,s1
    80004130:	fffff097          	auipc	ra,0xfffff
    80004134:	50a080e7          	jalr	1290(ra) # 8000363a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004138:	01498a3b          	addw	s4,s3,s4
    8000413c:	0129893b          	addw	s2,s3,s2
    80004140:	9aee                	add	s5,s5,s11
    80004142:	057a7663          	bgeu	s4,s7,8000418e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004146:	000b2483          	lw	s1,0(s6)
    8000414a:	00a9559b          	srliw	a1,s2,0xa
    8000414e:	855a                	mv	a0,s6
    80004150:	fffff097          	auipc	ra,0xfffff
    80004154:	7ae080e7          	jalr	1966(ra) # 800038fe <bmap>
    80004158:	0005059b          	sext.w	a1,a0
    8000415c:	8526                	mv	a0,s1
    8000415e:	fffff097          	auipc	ra,0xfffff
    80004162:	3ac080e7          	jalr	940(ra) # 8000350a <bread>
    80004166:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004168:	3ff97713          	andi	a4,s2,1023
    8000416c:	40ed07bb          	subw	a5,s10,a4
    80004170:	414b86bb          	subw	a3,s7,s4
    80004174:	89be                	mv	s3,a5
    80004176:	2781                	sext.w	a5,a5
    80004178:	0006861b          	sext.w	a2,a3
    8000417c:	f8f674e3          	bgeu	a2,a5,80004104 <writei+0x4c>
    80004180:	89b6                	mv	s3,a3
    80004182:	b749                	j	80004104 <writei+0x4c>
      brelse(bp);
    80004184:	8526                	mv	a0,s1
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	4b4080e7          	jalr	1204(ra) # 8000363a <brelse>
  }

  if(off > ip->size)
    8000418e:	04cb2783          	lw	a5,76(s6)
    80004192:	0127f463          	bgeu	a5,s2,8000419a <writei+0xe2>
    ip->size = off;
    80004196:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000419a:	855a                	mv	a0,s6
    8000419c:	00000097          	auipc	ra,0x0
    800041a0:	aa6080e7          	jalr	-1370(ra) # 80003c42 <iupdate>

  return tot;
    800041a4:	000a051b          	sext.w	a0,s4
}
    800041a8:	70a6                	ld	ra,104(sp)
    800041aa:	7406                	ld	s0,96(sp)
    800041ac:	64e6                	ld	s1,88(sp)
    800041ae:	6946                	ld	s2,80(sp)
    800041b0:	69a6                	ld	s3,72(sp)
    800041b2:	6a06                	ld	s4,64(sp)
    800041b4:	7ae2                	ld	s5,56(sp)
    800041b6:	7b42                	ld	s6,48(sp)
    800041b8:	7ba2                	ld	s7,40(sp)
    800041ba:	7c02                	ld	s8,32(sp)
    800041bc:	6ce2                	ld	s9,24(sp)
    800041be:	6d42                	ld	s10,16(sp)
    800041c0:	6da2                	ld	s11,8(sp)
    800041c2:	6165                	addi	sp,sp,112
    800041c4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041c6:	8a5e                	mv	s4,s7
    800041c8:	bfc9                	j	8000419a <writei+0xe2>
    return -1;
    800041ca:	557d                	li	a0,-1
}
    800041cc:	8082                	ret
    return -1;
    800041ce:	557d                	li	a0,-1
    800041d0:	bfe1                	j	800041a8 <writei+0xf0>
    return -1;
    800041d2:	557d                	li	a0,-1
    800041d4:	bfd1                	j	800041a8 <writei+0xf0>

00000000800041d6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041d6:	1141                	addi	sp,sp,-16
    800041d8:	e406                	sd	ra,8(sp)
    800041da:	e022                	sd	s0,0(sp)
    800041dc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041de:	4639                	li	a2,14
    800041e0:	ffffd097          	auipc	ra,0xffffd
    800041e4:	bda080e7          	jalr	-1062(ra) # 80000dba <strncmp>
}
    800041e8:	60a2                	ld	ra,8(sp)
    800041ea:	6402                	ld	s0,0(sp)
    800041ec:	0141                	addi	sp,sp,16
    800041ee:	8082                	ret

00000000800041f0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041f0:	7139                	addi	sp,sp,-64
    800041f2:	fc06                	sd	ra,56(sp)
    800041f4:	f822                	sd	s0,48(sp)
    800041f6:	f426                	sd	s1,40(sp)
    800041f8:	f04a                	sd	s2,32(sp)
    800041fa:	ec4e                	sd	s3,24(sp)
    800041fc:	e852                	sd	s4,16(sp)
    800041fe:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004200:	04451703          	lh	a4,68(a0)
    80004204:	4785                	li	a5,1
    80004206:	00f71a63          	bne	a4,a5,8000421a <dirlookup+0x2a>
    8000420a:	892a                	mv	s2,a0
    8000420c:	89ae                	mv	s3,a1
    8000420e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004210:	457c                	lw	a5,76(a0)
    80004212:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004214:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004216:	e79d                	bnez	a5,80004244 <dirlookup+0x54>
    80004218:	a8a5                	j	80004290 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000421a:	00004517          	auipc	a0,0x4
    8000421e:	51e50513          	addi	a0,a0,1310 # 80008738 <syscalls+0x1b8>
    80004222:	ffffc097          	auipc	ra,0xffffc
    80004226:	31e080e7          	jalr	798(ra) # 80000540 <panic>
      panic("dirlookup read");
    8000422a:	00004517          	auipc	a0,0x4
    8000422e:	52650513          	addi	a0,a0,1318 # 80008750 <syscalls+0x1d0>
    80004232:	ffffc097          	auipc	ra,0xffffc
    80004236:	30e080e7          	jalr	782(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000423a:	24c1                	addiw	s1,s1,16
    8000423c:	04c92783          	lw	a5,76(s2)
    80004240:	04f4f763          	bgeu	s1,a5,8000428e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004244:	4741                	li	a4,16
    80004246:	86a6                	mv	a3,s1
    80004248:	fc040613          	addi	a2,s0,-64
    8000424c:	4581                	li	a1,0
    8000424e:	854a                	mv	a0,s2
    80004250:	00000097          	auipc	ra,0x0
    80004254:	d70080e7          	jalr	-656(ra) # 80003fc0 <readi>
    80004258:	47c1                	li	a5,16
    8000425a:	fcf518e3          	bne	a0,a5,8000422a <dirlookup+0x3a>
    if(de.inum == 0)
    8000425e:	fc045783          	lhu	a5,-64(s0)
    80004262:	dfe1                	beqz	a5,8000423a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004264:	fc240593          	addi	a1,s0,-62
    80004268:	854e                	mv	a0,s3
    8000426a:	00000097          	auipc	ra,0x0
    8000426e:	f6c080e7          	jalr	-148(ra) # 800041d6 <namecmp>
    80004272:	f561                	bnez	a0,8000423a <dirlookup+0x4a>
      if(poff)
    80004274:	000a0463          	beqz	s4,8000427c <dirlookup+0x8c>
        *poff = off;
    80004278:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000427c:	fc045583          	lhu	a1,-64(s0)
    80004280:	00092503          	lw	a0,0(s2)
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	754080e7          	jalr	1876(ra) # 800039d8 <iget>
    8000428c:	a011                	j	80004290 <dirlookup+0xa0>
  return 0;
    8000428e:	4501                	li	a0,0
}
    80004290:	70e2                	ld	ra,56(sp)
    80004292:	7442                	ld	s0,48(sp)
    80004294:	74a2                	ld	s1,40(sp)
    80004296:	7902                	ld	s2,32(sp)
    80004298:	69e2                	ld	s3,24(sp)
    8000429a:	6a42                	ld	s4,16(sp)
    8000429c:	6121                	addi	sp,sp,64
    8000429e:	8082                	ret

00000000800042a0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042a0:	711d                	addi	sp,sp,-96
    800042a2:	ec86                	sd	ra,88(sp)
    800042a4:	e8a2                	sd	s0,80(sp)
    800042a6:	e4a6                	sd	s1,72(sp)
    800042a8:	e0ca                	sd	s2,64(sp)
    800042aa:	fc4e                	sd	s3,56(sp)
    800042ac:	f852                	sd	s4,48(sp)
    800042ae:	f456                	sd	s5,40(sp)
    800042b0:	f05a                	sd	s6,32(sp)
    800042b2:	ec5e                	sd	s7,24(sp)
    800042b4:	e862                	sd	s8,16(sp)
    800042b6:	e466                	sd	s9,8(sp)
    800042b8:	1080                	addi	s0,sp,96
    800042ba:	84aa                	mv	s1,a0
    800042bc:	8b2e                	mv	s6,a1
    800042be:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042c0:	00054703          	lbu	a4,0(a0)
    800042c4:	02f00793          	li	a5,47
    800042c8:	02f70363          	beq	a4,a5,800042ee <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	726080e7          	jalr	1830(ra) # 800019f2 <myproc>
    800042d4:	15053503          	ld	a0,336(a0)
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	9f6080e7          	jalr	-1546(ra) # 80003cce <idup>
    800042e0:	89aa                	mv	s3,a0
  while(*path == '/')
    800042e2:	02f00913          	li	s2,47
  len = path - s;
    800042e6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800042e8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042ea:	4c05                	li	s8,1
    800042ec:	a865                	j	800043a4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800042ee:	4585                	li	a1,1
    800042f0:	4505                	li	a0,1
    800042f2:	fffff097          	auipc	ra,0xfffff
    800042f6:	6e6080e7          	jalr	1766(ra) # 800039d8 <iget>
    800042fa:	89aa                	mv	s3,a0
    800042fc:	b7dd                	j	800042e2 <namex+0x42>
      iunlockput(ip);
    800042fe:	854e                	mv	a0,s3
    80004300:	00000097          	auipc	ra,0x0
    80004304:	c6e080e7          	jalr	-914(ra) # 80003f6e <iunlockput>
      return 0;
    80004308:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000430a:	854e                	mv	a0,s3
    8000430c:	60e6                	ld	ra,88(sp)
    8000430e:	6446                	ld	s0,80(sp)
    80004310:	64a6                	ld	s1,72(sp)
    80004312:	6906                	ld	s2,64(sp)
    80004314:	79e2                	ld	s3,56(sp)
    80004316:	7a42                	ld	s4,48(sp)
    80004318:	7aa2                	ld	s5,40(sp)
    8000431a:	7b02                	ld	s6,32(sp)
    8000431c:	6be2                	ld	s7,24(sp)
    8000431e:	6c42                	ld	s8,16(sp)
    80004320:	6ca2                	ld	s9,8(sp)
    80004322:	6125                	addi	sp,sp,96
    80004324:	8082                	ret
      iunlock(ip);
    80004326:	854e                	mv	a0,s3
    80004328:	00000097          	auipc	ra,0x0
    8000432c:	aa6080e7          	jalr	-1370(ra) # 80003dce <iunlock>
      return ip;
    80004330:	bfe9                	j	8000430a <namex+0x6a>
      iunlockput(ip);
    80004332:	854e                	mv	a0,s3
    80004334:	00000097          	auipc	ra,0x0
    80004338:	c3a080e7          	jalr	-966(ra) # 80003f6e <iunlockput>
      return 0;
    8000433c:	89d2                	mv	s3,s4
    8000433e:	b7f1                	j	8000430a <namex+0x6a>
  len = path - s;
    80004340:	40b48633          	sub	a2,s1,a1
    80004344:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004348:	094cd463          	bge	s9,s4,800043d0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000434c:	4639                	li	a2,14
    8000434e:	8556                	mv	a0,s5
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	9f2080e7          	jalr	-1550(ra) # 80000d42 <memmove>
  while(*path == '/')
    80004358:	0004c783          	lbu	a5,0(s1)
    8000435c:	01279763          	bne	a5,s2,8000436a <namex+0xca>
    path++;
    80004360:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004362:	0004c783          	lbu	a5,0(s1)
    80004366:	ff278de3          	beq	a5,s2,80004360 <namex+0xc0>
    ilock(ip);
    8000436a:	854e                	mv	a0,s3
    8000436c:	00000097          	auipc	ra,0x0
    80004370:	9a0080e7          	jalr	-1632(ra) # 80003d0c <ilock>
    if(ip->type != T_DIR){
    80004374:	04499783          	lh	a5,68(s3)
    80004378:	f98793e3          	bne	a5,s8,800042fe <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000437c:	000b0563          	beqz	s6,80004386 <namex+0xe6>
    80004380:	0004c783          	lbu	a5,0(s1)
    80004384:	d3cd                	beqz	a5,80004326 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004386:	865e                	mv	a2,s7
    80004388:	85d6                	mv	a1,s5
    8000438a:	854e                	mv	a0,s3
    8000438c:	00000097          	auipc	ra,0x0
    80004390:	e64080e7          	jalr	-412(ra) # 800041f0 <dirlookup>
    80004394:	8a2a                	mv	s4,a0
    80004396:	dd51                	beqz	a0,80004332 <namex+0x92>
    iunlockput(ip);
    80004398:	854e                	mv	a0,s3
    8000439a:	00000097          	auipc	ra,0x0
    8000439e:	bd4080e7          	jalr	-1068(ra) # 80003f6e <iunlockput>
    ip = next;
    800043a2:	89d2                	mv	s3,s4
  while(*path == '/')
    800043a4:	0004c783          	lbu	a5,0(s1)
    800043a8:	05279763          	bne	a5,s2,800043f6 <namex+0x156>
    path++;
    800043ac:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043ae:	0004c783          	lbu	a5,0(s1)
    800043b2:	ff278de3          	beq	a5,s2,800043ac <namex+0x10c>
  if(*path == 0)
    800043b6:	c79d                	beqz	a5,800043e4 <namex+0x144>
    path++;
    800043b8:	85a6                	mv	a1,s1
  len = path - s;
    800043ba:	8a5e                	mv	s4,s7
    800043bc:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043be:	01278963          	beq	a5,s2,800043d0 <namex+0x130>
    800043c2:	dfbd                	beqz	a5,80004340 <namex+0xa0>
    path++;
    800043c4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043c6:	0004c783          	lbu	a5,0(s1)
    800043ca:	ff279ce3          	bne	a5,s2,800043c2 <namex+0x122>
    800043ce:	bf8d                	j	80004340 <namex+0xa0>
    memmove(name, s, len);
    800043d0:	2601                	sext.w	a2,a2
    800043d2:	8556                	mv	a0,s5
    800043d4:	ffffd097          	auipc	ra,0xffffd
    800043d8:	96e080e7          	jalr	-1682(ra) # 80000d42 <memmove>
    name[len] = 0;
    800043dc:	9a56                	add	s4,s4,s5
    800043de:	000a0023          	sb	zero,0(s4)
    800043e2:	bf9d                	j	80004358 <namex+0xb8>
  if(nameiparent){
    800043e4:	f20b03e3          	beqz	s6,8000430a <namex+0x6a>
    iput(ip);
    800043e8:	854e                	mv	a0,s3
    800043ea:	00000097          	auipc	ra,0x0
    800043ee:	adc080e7          	jalr	-1316(ra) # 80003ec6 <iput>
    return 0;
    800043f2:	4981                	li	s3,0
    800043f4:	bf19                	j	8000430a <namex+0x6a>
  if(*path == 0)
    800043f6:	d7fd                	beqz	a5,800043e4 <namex+0x144>
  while(*path != '/' && *path != 0)
    800043f8:	0004c783          	lbu	a5,0(s1)
    800043fc:	85a6                	mv	a1,s1
    800043fe:	b7d1                	j	800043c2 <namex+0x122>

0000000080004400 <dirlink>:
{
    80004400:	7139                	addi	sp,sp,-64
    80004402:	fc06                	sd	ra,56(sp)
    80004404:	f822                	sd	s0,48(sp)
    80004406:	f426                	sd	s1,40(sp)
    80004408:	f04a                	sd	s2,32(sp)
    8000440a:	ec4e                	sd	s3,24(sp)
    8000440c:	e852                	sd	s4,16(sp)
    8000440e:	0080                	addi	s0,sp,64
    80004410:	892a                	mv	s2,a0
    80004412:	8a2e                	mv	s4,a1
    80004414:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004416:	4601                	li	a2,0
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	dd8080e7          	jalr	-552(ra) # 800041f0 <dirlookup>
    80004420:	e93d                	bnez	a0,80004496 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004422:	04c92483          	lw	s1,76(s2)
    80004426:	c49d                	beqz	s1,80004454 <dirlink+0x54>
    80004428:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000442a:	4741                	li	a4,16
    8000442c:	86a6                	mv	a3,s1
    8000442e:	fc040613          	addi	a2,s0,-64
    80004432:	4581                	li	a1,0
    80004434:	854a                	mv	a0,s2
    80004436:	00000097          	auipc	ra,0x0
    8000443a:	b8a080e7          	jalr	-1142(ra) # 80003fc0 <readi>
    8000443e:	47c1                	li	a5,16
    80004440:	06f51163          	bne	a0,a5,800044a2 <dirlink+0xa2>
    if(de.inum == 0)
    80004444:	fc045783          	lhu	a5,-64(s0)
    80004448:	c791                	beqz	a5,80004454 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000444a:	24c1                	addiw	s1,s1,16
    8000444c:	04c92783          	lw	a5,76(s2)
    80004450:	fcf4ede3          	bltu	s1,a5,8000442a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004454:	4639                	li	a2,14
    80004456:	85d2                	mv	a1,s4
    80004458:	fc240513          	addi	a0,s0,-62
    8000445c:	ffffd097          	auipc	ra,0xffffd
    80004460:	99a080e7          	jalr	-1638(ra) # 80000df6 <strncpy>
  de.inum = inum;
    80004464:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004468:	4741                	li	a4,16
    8000446a:	86a6                	mv	a3,s1
    8000446c:	fc040613          	addi	a2,s0,-64
    80004470:	4581                	li	a1,0
    80004472:	854a                	mv	a0,s2
    80004474:	00000097          	auipc	ra,0x0
    80004478:	c44080e7          	jalr	-956(ra) # 800040b8 <writei>
    8000447c:	872a                	mv	a4,a0
    8000447e:	47c1                	li	a5,16
  return 0;
    80004480:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004482:	02f71863          	bne	a4,a5,800044b2 <dirlink+0xb2>
}
    80004486:	70e2                	ld	ra,56(sp)
    80004488:	7442                	ld	s0,48(sp)
    8000448a:	74a2                	ld	s1,40(sp)
    8000448c:	7902                	ld	s2,32(sp)
    8000448e:	69e2                	ld	s3,24(sp)
    80004490:	6a42                	ld	s4,16(sp)
    80004492:	6121                	addi	sp,sp,64
    80004494:	8082                	ret
    iput(ip);
    80004496:	00000097          	auipc	ra,0x0
    8000449a:	a30080e7          	jalr	-1488(ra) # 80003ec6 <iput>
    return -1;
    8000449e:	557d                	li	a0,-1
    800044a0:	b7dd                	j	80004486 <dirlink+0x86>
      panic("dirlink read");
    800044a2:	00004517          	auipc	a0,0x4
    800044a6:	2be50513          	addi	a0,a0,702 # 80008760 <syscalls+0x1e0>
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	096080e7          	jalr	150(ra) # 80000540 <panic>
    panic("dirlink");
    800044b2:	00004517          	auipc	a0,0x4
    800044b6:	3be50513          	addi	a0,a0,958 # 80008870 <syscalls+0x2f0>
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	086080e7          	jalr	134(ra) # 80000540 <panic>

00000000800044c2 <namei>:

struct inode*
namei(char *path)
{
    800044c2:	1101                	addi	sp,sp,-32
    800044c4:	ec06                	sd	ra,24(sp)
    800044c6:	e822                	sd	s0,16(sp)
    800044c8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800044ca:	fe040613          	addi	a2,s0,-32
    800044ce:	4581                	li	a1,0
    800044d0:	00000097          	auipc	ra,0x0
    800044d4:	dd0080e7          	jalr	-560(ra) # 800042a0 <namex>
}
    800044d8:	60e2                	ld	ra,24(sp)
    800044da:	6442                	ld	s0,16(sp)
    800044dc:	6105                	addi	sp,sp,32
    800044de:	8082                	ret

00000000800044e0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044e0:	1141                	addi	sp,sp,-16
    800044e2:	e406                	sd	ra,8(sp)
    800044e4:	e022                	sd	s0,0(sp)
    800044e6:	0800                	addi	s0,sp,16
    800044e8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044ea:	4585                	li	a1,1
    800044ec:	00000097          	auipc	ra,0x0
    800044f0:	db4080e7          	jalr	-588(ra) # 800042a0 <namex>
}
    800044f4:	60a2                	ld	ra,8(sp)
    800044f6:	6402                	ld	s0,0(sp)
    800044f8:	0141                	addi	sp,sp,16
    800044fa:	8082                	ret

00000000800044fc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044fc:	1101                	addi	sp,sp,-32
    800044fe:	ec06                	sd	ra,24(sp)
    80004500:	e822                	sd	s0,16(sp)
    80004502:	e426                	sd	s1,8(sp)
    80004504:	e04a                	sd	s2,0(sp)
    80004506:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004508:	0001d917          	auipc	s2,0x1d
    8000450c:	58890913          	addi	s2,s2,1416 # 80021a90 <log>
    80004510:	01892583          	lw	a1,24(s2)
    80004514:	02892503          	lw	a0,40(s2)
    80004518:	fffff097          	auipc	ra,0xfffff
    8000451c:	ff2080e7          	jalr	-14(ra) # 8000350a <bread>
    80004520:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004522:	02c92683          	lw	a3,44(s2)
    80004526:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004528:	02d05763          	blez	a3,80004556 <write_head+0x5a>
    8000452c:	0001d797          	auipc	a5,0x1d
    80004530:	59478793          	addi	a5,a5,1428 # 80021ac0 <log+0x30>
    80004534:	05c50713          	addi	a4,a0,92
    80004538:	36fd                	addiw	a3,a3,-1
    8000453a:	1682                	slli	a3,a3,0x20
    8000453c:	9281                	srli	a3,a3,0x20
    8000453e:	068a                	slli	a3,a3,0x2
    80004540:	0001d617          	auipc	a2,0x1d
    80004544:	58460613          	addi	a2,a2,1412 # 80021ac4 <log+0x34>
    80004548:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000454a:	4390                	lw	a2,0(a5)
    8000454c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000454e:	0791                	addi	a5,a5,4
    80004550:	0711                	addi	a4,a4,4
    80004552:	fed79ce3          	bne	a5,a3,8000454a <write_head+0x4e>
  }
  bwrite(buf);
    80004556:	8526                	mv	a0,s1
    80004558:	fffff097          	auipc	ra,0xfffff
    8000455c:	0a4080e7          	jalr	164(ra) # 800035fc <bwrite>
  brelse(buf);
    80004560:	8526                	mv	a0,s1
    80004562:	fffff097          	auipc	ra,0xfffff
    80004566:	0d8080e7          	jalr	216(ra) # 8000363a <brelse>
}
    8000456a:	60e2                	ld	ra,24(sp)
    8000456c:	6442                	ld	s0,16(sp)
    8000456e:	64a2                	ld	s1,8(sp)
    80004570:	6902                	ld	s2,0(sp)
    80004572:	6105                	addi	sp,sp,32
    80004574:	8082                	ret

0000000080004576 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004576:	0001d797          	auipc	a5,0x1d
    8000457a:	5467a783          	lw	a5,1350(a5) # 80021abc <log+0x2c>
    8000457e:	0af05d63          	blez	a5,80004638 <install_trans+0xc2>
{
    80004582:	7139                	addi	sp,sp,-64
    80004584:	fc06                	sd	ra,56(sp)
    80004586:	f822                	sd	s0,48(sp)
    80004588:	f426                	sd	s1,40(sp)
    8000458a:	f04a                	sd	s2,32(sp)
    8000458c:	ec4e                	sd	s3,24(sp)
    8000458e:	e852                	sd	s4,16(sp)
    80004590:	e456                	sd	s5,8(sp)
    80004592:	e05a                	sd	s6,0(sp)
    80004594:	0080                	addi	s0,sp,64
    80004596:	8b2a                	mv	s6,a0
    80004598:	0001da97          	auipc	s5,0x1d
    8000459c:	528a8a93          	addi	s5,s5,1320 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045a0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045a2:	0001d997          	auipc	s3,0x1d
    800045a6:	4ee98993          	addi	s3,s3,1262 # 80021a90 <log>
    800045aa:	a035                	j	800045d6 <install_trans+0x60>
      bunpin(dbuf);
    800045ac:	8526                	mv	a0,s1
    800045ae:	fffff097          	auipc	ra,0xfffff
    800045b2:	166080e7          	jalr	358(ra) # 80003714 <bunpin>
    brelse(lbuf);
    800045b6:	854a                	mv	a0,s2
    800045b8:	fffff097          	auipc	ra,0xfffff
    800045bc:	082080e7          	jalr	130(ra) # 8000363a <brelse>
    brelse(dbuf);
    800045c0:	8526                	mv	a0,s1
    800045c2:	fffff097          	auipc	ra,0xfffff
    800045c6:	078080e7          	jalr	120(ra) # 8000363a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ca:	2a05                	addiw	s4,s4,1
    800045cc:	0a91                	addi	s5,s5,4
    800045ce:	02c9a783          	lw	a5,44(s3)
    800045d2:	04fa5963          	bge	s4,a5,80004624 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045d6:	0189a583          	lw	a1,24(s3)
    800045da:	014585bb          	addw	a1,a1,s4
    800045de:	2585                	addiw	a1,a1,1
    800045e0:	0289a503          	lw	a0,40(s3)
    800045e4:	fffff097          	auipc	ra,0xfffff
    800045e8:	f26080e7          	jalr	-218(ra) # 8000350a <bread>
    800045ec:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045ee:	000aa583          	lw	a1,0(s5)
    800045f2:	0289a503          	lw	a0,40(s3)
    800045f6:	fffff097          	auipc	ra,0xfffff
    800045fa:	f14080e7          	jalr	-236(ra) # 8000350a <bread>
    800045fe:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004600:	40000613          	li	a2,1024
    80004604:	05890593          	addi	a1,s2,88
    80004608:	05850513          	addi	a0,a0,88
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	736080e7          	jalr	1846(ra) # 80000d42 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004614:	8526                	mv	a0,s1
    80004616:	fffff097          	auipc	ra,0xfffff
    8000461a:	fe6080e7          	jalr	-26(ra) # 800035fc <bwrite>
    if(recovering == 0)
    8000461e:	f80b1ce3          	bnez	s6,800045b6 <install_trans+0x40>
    80004622:	b769                	j	800045ac <install_trans+0x36>
}
    80004624:	70e2                	ld	ra,56(sp)
    80004626:	7442                	ld	s0,48(sp)
    80004628:	74a2                	ld	s1,40(sp)
    8000462a:	7902                	ld	s2,32(sp)
    8000462c:	69e2                	ld	s3,24(sp)
    8000462e:	6a42                	ld	s4,16(sp)
    80004630:	6aa2                	ld	s5,8(sp)
    80004632:	6b02                	ld	s6,0(sp)
    80004634:	6121                	addi	sp,sp,64
    80004636:	8082                	ret
    80004638:	8082                	ret

000000008000463a <initlog>:
{
    8000463a:	7179                	addi	sp,sp,-48
    8000463c:	f406                	sd	ra,40(sp)
    8000463e:	f022                	sd	s0,32(sp)
    80004640:	ec26                	sd	s1,24(sp)
    80004642:	e84a                	sd	s2,16(sp)
    80004644:	e44e                	sd	s3,8(sp)
    80004646:	1800                	addi	s0,sp,48
    80004648:	892a                	mv	s2,a0
    8000464a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000464c:	0001d497          	auipc	s1,0x1d
    80004650:	44448493          	addi	s1,s1,1092 # 80021a90 <log>
    80004654:	00004597          	auipc	a1,0x4
    80004658:	11c58593          	addi	a1,a1,284 # 80008770 <syscalls+0x1f0>
    8000465c:	8526                	mv	a0,s1
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	4f8080e7          	jalr	1272(ra) # 80000b56 <initlock>
  log.start = sb->logstart;
    80004666:	0149a583          	lw	a1,20(s3)
    8000466a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000466c:	0109a783          	lw	a5,16(s3)
    80004670:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004672:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004676:	854a                	mv	a0,s2
    80004678:	fffff097          	auipc	ra,0xfffff
    8000467c:	e92080e7          	jalr	-366(ra) # 8000350a <bread>
  log.lh.n = lh->n;
    80004680:	4d3c                	lw	a5,88(a0)
    80004682:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004684:	02f05563          	blez	a5,800046ae <initlog+0x74>
    80004688:	05c50713          	addi	a4,a0,92
    8000468c:	0001d697          	auipc	a3,0x1d
    80004690:	43468693          	addi	a3,a3,1076 # 80021ac0 <log+0x30>
    80004694:	37fd                	addiw	a5,a5,-1
    80004696:	1782                	slli	a5,a5,0x20
    80004698:	9381                	srli	a5,a5,0x20
    8000469a:	078a                	slli	a5,a5,0x2
    8000469c:	06050613          	addi	a2,a0,96
    800046a0:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800046a2:	4310                	lw	a2,0(a4)
    800046a4:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800046a6:	0711                	addi	a4,a4,4
    800046a8:	0691                	addi	a3,a3,4
    800046aa:	fef71ce3          	bne	a4,a5,800046a2 <initlog+0x68>
  brelse(buf);
    800046ae:	fffff097          	auipc	ra,0xfffff
    800046b2:	f8c080e7          	jalr	-116(ra) # 8000363a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046b6:	4505                	li	a0,1
    800046b8:	00000097          	auipc	ra,0x0
    800046bc:	ebe080e7          	jalr	-322(ra) # 80004576 <install_trans>
  log.lh.n = 0;
    800046c0:	0001d797          	auipc	a5,0x1d
    800046c4:	3e07ae23          	sw	zero,1020(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	e34080e7          	jalr	-460(ra) # 800044fc <write_head>
}
    800046d0:	70a2                	ld	ra,40(sp)
    800046d2:	7402                	ld	s0,32(sp)
    800046d4:	64e2                	ld	s1,24(sp)
    800046d6:	6942                	ld	s2,16(sp)
    800046d8:	69a2                	ld	s3,8(sp)
    800046da:	6145                	addi	sp,sp,48
    800046dc:	8082                	ret

00000000800046de <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800046de:	1101                	addi	sp,sp,-32
    800046e0:	ec06                	sd	ra,24(sp)
    800046e2:	e822                	sd	s0,16(sp)
    800046e4:	e426                	sd	s1,8(sp)
    800046e6:	e04a                	sd	s2,0(sp)
    800046e8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046ea:	0001d517          	auipc	a0,0x1d
    800046ee:	3a650513          	addi	a0,a0,934 # 80021a90 <log>
    800046f2:	ffffc097          	auipc	ra,0xffffc
    800046f6:	4f4080e7          	jalr	1268(ra) # 80000be6 <acquire>
  while(1){
    if(log.committing){
    800046fa:	0001d497          	auipc	s1,0x1d
    800046fe:	39648493          	addi	s1,s1,918 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004702:	4979                	li	s2,30
    80004704:	a039                	j	80004712 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004706:	85a6                	mv	a1,s1
    80004708:	8526                	mv	a0,s1
    8000470a:	ffffe097          	auipc	ra,0xffffe
    8000470e:	bda080e7          	jalr	-1062(ra) # 800022e4 <sleep>
    if(log.committing){
    80004712:	50dc                	lw	a5,36(s1)
    80004714:	fbed                	bnez	a5,80004706 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004716:	509c                	lw	a5,32(s1)
    80004718:	0017871b          	addiw	a4,a5,1
    8000471c:	0007069b          	sext.w	a3,a4
    80004720:	0027179b          	slliw	a5,a4,0x2
    80004724:	9fb9                	addw	a5,a5,a4
    80004726:	0017979b          	slliw	a5,a5,0x1
    8000472a:	54d8                	lw	a4,44(s1)
    8000472c:	9fb9                	addw	a5,a5,a4
    8000472e:	00f95963          	bge	s2,a5,80004740 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004732:	85a6                	mv	a1,s1
    80004734:	8526                	mv	a0,s1
    80004736:	ffffe097          	auipc	ra,0xffffe
    8000473a:	bae080e7          	jalr	-1106(ra) # 800022e4 <sleep>
    8000473e:	bfd1                	j	80004712 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004740:	0001d517          	auipc	a0,0x1d
    80004744:	35050513          	addi	a0,a0,848 # 80021a90 <log>
    80004748:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000474a:	ffffc097          	auipc	ra,0xffffc
    8000474e:	550080e7          	jalr	1360(ra) # 80000c9a <release>
      break;
    }
  }
}
    80004752:	60e2                	ld	ra,24(sp)
    80004754:	6442                	ld	s0,16(sp)
    80004756:	64a2                	ld	s1,8(sp)
    80004758:	6902                	ld	s2,0(sp)
    8000475a:	6105                	addi	sp,sp,32
    8000475c:	8082                	ret

000000008000475e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000475e:	7139                	addi	sp,sp,-64
    80004760:	fc06                	sd	ra,56(sp)
    80004762:	f822                	sd	s0,48(sp)
    80004764:	f426                	sd	s1,40(sp)
    80004766:	f04a                	sd	s2,32(sp)
    80004768:	ec4e                	sd	s3,24(sp)
    8000476a:	e852                	sd	s4,16(sp)
    8000476c:	e456                	sd	s5,8(sp)
    8000476e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004770:	0001d497          	auipc	s1,0x1d
    80004774:	32048493          	addi	s1,s1,800 # 80021a90 <log>
    80004778:	8526                	mv	a0,s1
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	46c080e7          	jalr	1132(ra) # 80000be6 <acquire>
  log.outstanding -= 1;
    80004782:	509c                	lw	a5,32(s1)
    80004784:	37fd                	addiw	a5,a5,-1
    80004786:	0007891b          	sext.w	s2,a5
    8000478a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000478c:	50dc                	lw	a5,36(s1)
    8000478e:	efb9                	bnez	a5,800047ec <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004790:	06091663          	bnez	s2,800047fc <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004794:	0001d497          	auipc	s1,0x1d
    80004798:	2fc48493          	addi	s1,s1,764 # 80021a90 <log>
    8000479c:	4785                	li	a5,1
    8000479e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047a0:	8526                	mv	a0,s1
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	4f8080e7          	jalr	1272(ra) # 80000c9a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047aa:	54dc                	lw	a5,44(s1)
    800047ac:	06f04763          	bgtz	a5,8000481a <end_op+0xbc>
    acquire(&log.lock);
    800047b0:	0001d497          	auipc	s1,0x1d
    800047b4:	2e048493          	addi	s1,s1,736 # 80021a90 <log>
    800047b8:	8526                	mv	a0,s1
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	42c080e7          	jalr	1068(ra) # 80000be6 <acquire>
    log.committing = 0;
    800047c2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047c6:	8526                	mv	a0,s1
    800047c8:	ffffe097          	auipc	ra,0xffffe
    800047cc:	d02080e7          	jalr	-766(ra) # 800024ca <wakeup>
    release(&log.lock);
    800047d0:	8526                	mv	a0,s1
    800047d2:	ffffc097          	auipc	ra,0xffffc
    800047d6:	4c8080e7          	jalr	1224(ra) # 80000c9a <release>
}
    800047da:	70e2                	ld	ra,56(sp)
    800047dc:	7442                	ld	s0,48(sp)
    800047de:	74a2                	ld	s1,40(sp)
    800047e0:	7902                	ld	s2,32(sp)
    800047e2:	69e2                	ld	s3,24(sp)
    800047e4:	6a42                	ld	s4,16(sp)
    800047e6:	6aa2                	ld	s5,8(sp)
    800047e8:	6121                	addi	sp,sp,64
    800047ea:	8082                	ret
    panic("log.committing");
    800047ec:	00004517          	auipc	a0,0x4
    800047f0:	f8c50513          	addi	a0,a0,-116 # 80008778 <syscalls+0x1f8>
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	d4c080e7          	jalr	-692(ra) # 80000540 <panic>
    wakeup(&log);
    800047fc:	0001d497          	auipc	s1,0x1d
    80004800:	29448493          	addi	s1,s1,660 # 80021a90 <log>
    80004804:	8526                	mv	a0,s1
    80004806:	ffffe097          	auipc	ra,0xffffe
    8000480a:	cc4080e7          	jalr	-828(ra) # 800024ca <wakeup>
  release(&log.lock);
    8000480e:	8526                	mv	a0,s1
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	48a080e7          	jalr	1162(ra) # 80000c9a <release>
  if(do_commit){
    80004818:	b7c9                	j	800047da <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000481a:	0001da97          	auipc	s5,0x1d
    8000481e:	2a6a8a93          	addi	s5,s5,678 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004822:	0001da17          	auipc	s4,0x1d
    80004826:	26ea0a13          	addi	s4,s4,622 # 80021a90 <log>
    8000482a:	018a2583          	lw	a1,24(s4)
    8000482e:	012585bb          	addw	a1,a1,s2
    80004832:	2585                	addiw	a1,a1,1
    80004834:	028a2503          	lw	a0,40(s4)
    80004838:	fffff097          	auipc	ra,0xfffff
    8000483c:	cd2080e7          	jalr	-814(ra) # 8000350a <bread>
    80004840:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004842:	000aa583          	lw	a1,0(s5)
    80004846:	028a2503          	lw	a0,40(s4)
    8000484a:	fffff097          	auipc	ra,0xfffff
    8000484e:	cc0080e7          	jalr	-832(ra) # 8000350a <bread>
    80004852:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004854:	40000613          	li	a2,1024
    80004858:	05850593          	addi	a1,a0,88
    8000485c:	05848513          	addi	a0,s1,88
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	4e2080e7          	jalr	1250(ra) # 80000d42 <memmove>
    bwrite(to);  // write the log
    80004868:	8526                	mv	a0,s1
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	d92080e7          	jalr	-622(ra) # 800035fc <bwrite>
    brelse(from);
    80004872:	854e                	mv	a0,s3
    80004874:	fffff097          	auipc	ra,0xfffff
    80004878:	dc6080e7          	jalr	-570(ra) # 8000363a <brelse>
    brelse(to);
    8000487c:	8526                	mv	a0,s1
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	dbc080e7          	jalr	-580(ra) # 8000363a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004886:	2905                	addiw	s2,s2,1
    80004888:	0a91                	addi	s5,s5,4
    8000488a:	02ca2783          	lw	a5,44(s4)
    8000488e:	f8f94ee3          	blt	s2,a5,8000482a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004892:	00000097          	auipc	ra,0x0
    80004896:	c6a080e7          	jalr	-918(ra) # 800044fc <write_head>
    install_trans(0); // Now install writes to home locations
    8000489a:	4501                	li	a0,0
    8000489c:	00000097          	auipc	ra,0x0
    800048a0:	cda080e7          	jalr	-806(ra) # 80004576 <install_trans>
    log.lh.n = 0;
    800048a4:	0001d797          	auipc	a5,0x1d
    800048a8:	2007ac23          	sw	zero,536(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048ac:	00000097          	auipc	ra,0x0
    800048b0:	c50080e7          	jalr	-944(ra) # 800044fc <write_head>
    800048b4:	bdf5                	j	800047b0 <end_op+0x52>

00000000800048b6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048b6:	1101                	addi	sp,sp,-32
    800048b8:	ec06                	sd	ra,24(sp)
    800048ba:	e822                	sd	s0,16(sp)
    800048bc:	e426                	sd	s1,8(sp)
    800048be:	e04a                	sd	s2,0(sp)
    800048c0:	1000                	addi	s0,sp,32
    800048c2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048c4:	0001d917          	auipc	s2,0x1d
    800048c8:	1cc90913          	addi	s2,s2,460 # 80021a90 <log>
    800048cc:	854a                	mv	a0,s2
    800048ce:	ffffc097          	auipc	ra,0xffffc
    800048d2:	318080e7          	jalr	792(ra) # 80000be6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800048d6:	02c92603          	lw	a2,44(s2)
    800048da:	47f5                	li	a5,29
    800048dc:	06c7c563          	blt	a5,a2,80004946 <log_write+0x90>
    800048e0:	0001d797          	auipc	a5,0x1d
    800048e4:	1cc7a783          	lw	a5,460(a5) # 80021aac <log+0x1c>
    800048e8:	37fd                	addiw	a5,a5,-1
    800048ea:	04f65e63          	bge	a2,a5,80004946 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048ee:	0001d797          	auipc	a5,0x1d
    800048f2:	1c27a783          	lw	a5,450(a5) # 80021ab0 <log+0x20>
    800048f6:	06f05063          	blez	a5,80004956 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048fa:	4781                	li	a5,0
    800048fc:	06c05563          	blez	a2,80004966 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004900:	44cc                	lw	a1,12(s1)
    80004902:	0001d717          	auipc	a4,0x1d
    80004906:	1be70713          	addi	a4,a4,446 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000490a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000490c:	4314                	lw	a3,0(a4)
    8000490e:	04b68c63          	beq	a3,a1,80004966 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004912:	2785                	addiw	a5,a5,1
    80004914:	0711                	addi	a4,a4,4
    80004916:	fef61be3          	bne	a2,a5,8000490c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000491a:	0621                	addi	a2,a2,8
    8000491c:	060a                	slli	a2,a2,0x2
    8000491e:	0001d797          	auipc	a5,0x1d
    80004922:	17278793          	addi	a5,a5,370 # 80021a90 <log>
    80004926:	963e                	add	a2,a2,a5
    80004928:	44dc                	lw	a5,12(s1)
    8000492a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000492c:	8526                	mv	a0,s1
    8000492e:	fffff097          	auipc	ra,0xfffff
    80004932:	daa080e7          	jalr	-598(ra) # 800036d8 <bpin>
    log.lh.n++;
    80004936:	0001d717          	auipc	a4,0x1d
    8000493a:	15a70713          	addi	a4,a4,346 # 80021a90 <log>
    8000493e:	575c                	lw	a5,44(a4)
    80004940:	2785                	addiw	a5,a5,1
    80004942:	d75c                	sw	a5,44(a4)
    80004944:	a835                	j	80004980 <log_write+0xca>
    panic("too big a transaction");
    80004946:	00004517          	auipc	a0,0x4
    8000494a:	e4250513          	addi	a0,a0,-446 # 80008788 <syscalls+0x208>
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	bf2080e7          	jalr	-1038(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004956:	00004517          	auipc	a0,0x4
    8000495a:	e4a50513          	addi	a0,a0,-438 # 800087a0 <syscalls+0x220>
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	be2080e7          	jalr	-1054(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004966:	00878713          	addi	a4,a5,8
    8000496a:	00271693          	slli	a3,a4,0x2
    8000496e:	0001d717          	auipc	a4,0x1d
    80004972:	12270713          	addi	a4,a4,290 # 80021a90 <log>
    80004976:	9736                	add	a4,a4,a3
    80004978:	44d4                	lw	a3,12(s1)
    8000497a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000497c:	faf608e3          	beq	a2,a5,8000492c <log_write+0x76>
  }
  release(&log.lock);
    80004980:	0001d517          	auipc	a0,0x1d
    80004984:	11050513          	addi	a0,a0,272 # 80021a90 <log>
    80004988:	ffffc097          	auipc	ra,0xffffc
    8000498c:	312080e7          	jalr	786(ra) # 80000c9a <release>
}
    80004990:	60e2                	ld	ra,24(sp)
    80004992:	6442                	ld	s0,16(sp)
    80004994:	64a2                	ld	s1,8(sp)
    80004996:	6902                	ld	s2,0(sp)
    80004998:	6105                	addi	sp,sp,32
    8000499a:	8082                	ret

000000008000499c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000499c:	1101                	addi	sp,sp,-32
    8000499e:	ec06                	sd	ra,24(sp)
    800049a0:	e822                	sd	s0,16(sp)
    800049a2:	e426                	sd	s1,8(sp)
    800049a4:	e04a                	sd	s2,0(sp)
    800049a6:	1000                	addi	s0,sp,32
    800049a8:	84aa                	mv	s1,a0
    800049aa:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049ac:	00004597          	auipc	a1,0x4
    800049b0:	e1458593          	addi	a1,a1,-492 # 800087c0 <syscalls+0x240>
    800049b4:	0521                	addi	a0,a0,8
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	1a0080e7          	jalr	416(ra) # 80000b56 <initlock>
  lk->name = name;
    800049be:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049c2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049c6:	0204a423          	sw	zero,40(s1)
}
    800049ca:	60e2                	ld	ra,24(sp)
    800049cc:	6442                	ld	s0,16(sp)
    800049ce:	64a2                	ld	s1,8(sp)
    800049d0:	6902                	ld	s2,0(sp)
    800049d2:	6105                	addi	sp,sp,32
    800049d4:	8082                	ret

00000000800049d6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800049d6:	1101                	addi	sp,sp,-32
    800049d8:	ec06                	sd	ra,24(sp)
    800049da:	e822                	sd	s0,16(sp)
    800049dc:	e426                	sd	s1,8(sp)
    800049de:	e04a                	sd	s2,0(sp)
    800049e0:	1000                	addi	s0,sp,32
    800049e2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049e4:	00850913          	addi	s2,a0,8
    800049e8:	854a                	mv	a0,s2
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	1fc080e7          	jalr	508(ra) # 80000be6 <acquire>
  while (lk->locked) {
    800049f2:	409c                	lw	a5,0(s1)
    800049f4:	cb89                	beqz	a5,80004a06 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049f6:	85ca                	mv	a1,s2
    800049f8:	8526                	mv	a0,s1
    800049fa:	ffffe097          	auipc	ra,0xffffe
    800049fe:	8ea080e7          	jalr	-1814(ra) # 800022e4 <sleep>
  while (lk->locked) {
    80004a02:	409c                	lw	a5,0(s1)
    80004a04:	fbed                	bnez	a5,800049f6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a06:	4785                	li	a5,1
    80004a08:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a0a:	ffffd097          	auipc	ra,0xffffd
    80004a0e:	fe8080e7          	jalr	-24(ra) # 800019f2 <myproc>
    80004a12:	591c                	lw	a5,48(a0)
    80004a14:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a16:	854a                	mv	a0,s2
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	282080e7          	jalr	642(ra) # 80000c9a <release>
}
    80004a20:	60e2                	ld	ra,24(sp)
    80004a22:	6442                	ld	s0,16(sp)
    80004a24:	64a2                	ld	s1,8(sp)
    80004a26:	6902                	ld	s2,0(sp)
    80004a28:	6105                	addi	sp,sp,32
    80004a2a:	8082                	ret

0000000080004a2c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a2c:	1101                	addi	sp,sp,-32
    80004a2e:	ec06                	sd	ra,24(sp)
    80004a30:	e822                	sd	s0,16(sp)
    80004a32:	e426                	sd	s1,8(sp)
    80004a34:	e04a                	sd	s2,0(sp)
    80004a36:	1000                	addi	s0,sp,32
    80004a38:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a3a:	00850913          	addi	s2,a0,8
    80004a3e:	854a                	mv	a0,s2
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	1a6080e7          	jalr	422(ra) # 80000be6 <acquire>
  lk->locked = 0;
    80004a48:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a4c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a50:	8526                	mv	a0,s1
    80004a52:	ffffe097          	auipc	ra,0xffffe
    80004a56:	a78080e7          	jalr	-1416(ra) # 800024ca <wakeup>
  release(&lk->lk);
    80004a5a:	854a                	mv	a0,s2
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	23e080e7          	jalr	574(ra) # 80000c9a <release>
}
    80004a64:	60e2                	ld	ra,24(sp)
    80004a66:	6442                	ld	s0,16(sp)
    80004a68:	64a2                	ld	s1,8(sp)
    80004a6a:	6902                	ld	s2,0(sp)
    80004a6c:	6105                	addi	sp,sp,32
    80004a6e:	8082                	ret

0000000080004a70 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a70:	7179                	addi	sp,sp,-48
    80004a72:	f406                	sd	ra,40(sp)
    80004a74:	f022                	sd	s0,32(sp)
    80004a76:	ec26                	sd	s1,24(sp)
    80004a78:	e84a                	sd	s2,16(sp)
    80004a7a:	e44e                	sd	s3,8(sp)
    80004a7c:	1800                	addi	s0,sp,48
    80004a7e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a80:	00850913          	addi	s2,a0,8
    80004a84:	854a                	mv	a0,s2
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	160080e7          	jalr	352(ra) # 80000be6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a8e:	409c                	lw	a5,0(s1)
    80004a90:	ef99                	bnez	a5,80004aae <holdingsleep+0x3e>
    80004a92:	4481                	li	s1,0
  release(&lk->lk);
    80004a94:	854a                	mv	a0,s2
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	204080e7          	jalr	516(ra) # 80000c9a <release>
  return r;
}
    80004a9e:	8526                	mv	a0,s1
    80004aa0:	70a2                	ld	ra,40(sp)
    80004aa2:	7402                	ld	s0,32(sp)
    80004aa4:	64e2                	ld	s1,24(sp)
    80004aa6:	6942                	ld	s2,16(sp)
    80004aa8:	69a2                	ld	s3,8(sp)
    80004aaa:	6145                	addi	sp,sp,48
    80004aac:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004aae:	0284a983          	lw	s3,40(s1)
    80004ab2:	ffffd097          	auipc	ra,0xffffd
    80004ab6:	f40080e7          	jalr	-192(ra) # 800019f2 <myproc>
    80004aba:	5904                	lw	s1,48(a0)
    80004abc:	413484b3          	sub	s1,s1,s3
    80004ac0:	0014b493          	seqz	s1,s1
    80004ac4:	bfc1                	j	80004a94 <holdingsleep+0x24>

0000000080004ac6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004ac6:	1141                	addi	sp,sp,-16
    80004ac8:	e406                	sd	ra,8(sp)
    80004aca:	e022                	sd	s0,0(sp)
    80004acc:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004ace:	00004597          	auipc	a1,0x4
    80004ad2:	d0258593          	addi	a1,a1,-766 # 800087d0 <syscalls+0x250>
    80004ad6:	0001d517          	auipc	a0,0x1d
    80004ada:	10250513          	addi	a0,a0,258 # 80021bd8 <ftable>
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	078080e7          	jalr	120(ra) # 80000b56 <initlock>
}
    80004ae6:	60a2                	ld	ra,8(sp)
    80004ae8:	6402                	ld	s0,0(sp)
    80004aea:	0141                	addi	sp,sp,16
    80004aec:	8082                	ret

0000000080004aee <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004aee:	1101                	addi	sp,sp,-32
    80004af0:	ec06                	sd	ra,24(sp)
    80004af2:	e822                	sd	s0,16(sp)
    80004af4:	e426                	sd	s1,8(sp)
    80004af6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004af8:	0001d517          	auipc	a0,0x1d
    80004afc:	0e050513          	addi	a0,a0,224 # 80021bd8 <ftable>
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	0e6080e7          	jalr	230(ra) # 80000be6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b08:	0001d497          	auipc	s1,0x1d
    80004b0c:	0e848493          	addi	s1,s1,232 # 80021bf0 <ftable+0x18>
    80004b10:	0001e717          	auipc	a4,0x1e
    80004b14:	08070713          	addi	a4,a4,128 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    80004b18:	40dc                	lw	a5,4(s1)
    80004b1a:	cf99                	beqz	a5,80004b38 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b1c:	02848493          	addi	s1,s1,40
    80004b20:	fee49ce3          	bne	s1,a4,80004b18 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b24:	0001d517          	auipc	a0,0x1d
    80004b28:	0b450513          	addi	a0,a0,180 # 80021bd8 <ftable>
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	16e080e7          	jalr	366(ra) # 80000c9a <release>
  return 0;
    80004b34:	4481                	li	s1,0
    80004b36:	a819                	j	80004b4c <filealloc+0x5e>
      f->ref = 1;
    80004b38:	4785                	li	a5,1
    80004b3a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b3c:	0001d517          	auipc	a0,0x1d
    80004b40:	09c50513          	addi	a0,a0,156 # 80021bd8 <ftable>
    80004b44:	ffffc097          	auipc	ra,0xffffc
    80004b48:	156080e7          	jalr	342(ra) # 80000c9a <release>
}
    80004b4c:	8526                	mv	a0,s1
    80004b4e:	60e2                	ld	ra,24(sp)
    80004b50:	6442                	ld	s0,16(sp)
    80004b52:	64a2                	ld	s1,8(sp)
    80004b54:	6105                	addi	sp,sp,32
    80004b56:	8082                	ret

0000000080004b58 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b58:	1101                	addi	sp,sp,-32
    80004b5a:	ec06                	sd	ra,24(sp)
    80004b5c:	e822                	sd	s0,16(sp)
    80004b5e:	e426                	sd	s1,8(sp)
    80004b60:	1000                	addi	s0,sp,32
    80004b62:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b64:	0001d517          	auipc	a0,0x1d
    80004b68:	07450513          	addi	a0,a0,116 # 80021bd8 <ftable>
    80004b6c:	ffffc097          	auipc	ra,0xffffc
    80004b70:	07a080e7          	jalr	122(ra) # 80000be6 <acquire>
  if(f->ref < 1)
    80004b74:	40dc                	lw	a5,4(s1)
    80004b76:	02f05263          	blez	a5,80004b9a <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b7a:	2785                	addiw	a5,a5,1
    80004b7c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b7e:	0001d517          	auipc	a0,0x1d
    80004b82:	05a50513          	addi	a0,a0,90 # 80021bd8 <ftable>
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	114080e7          	jalr	276(ra) # 80000c9a <release>
  return f;
}
    80004b8e:	8526                	mv	a0,s1
    80004b90:	60e2                	ld	ra,24(sp)
    80004b92:	6442                	ld	s0,16(sp)
    80004b94:	64a2                	ld	s1,8(sp)
    80004b96:	6105                	addi	sp,sp,32
    80004b98:	8082                	ret
    panic("filedup");
    80004b9a:	00004517          	auipc	a0,0x4
    80004b9e:	c3e50513          	addi	a0,a0,-962 # 800087d8 <syscalls+0x258>
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	99e080e7          	jalr	-1634(ra) # 80000540 <panic>

0000000080004baa <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004baa:	7139                	addi	sp,sp,-64
    80004bac:	fc06                	sd	ra,56(sp)
    80004bae:	f822                	sd	s0,48(sp)
    80004bb0:	f426                	sd	s1,40(sp)
    80004bb2:	f04a                	sd	s2,32(sp)
    80004bb4:	ec4e                	sd	s3,24(sp)
    80004bb6:	e852                	sd	s4,16(sp)
    80004bb8:	e456                	sd	s5,8(sp)
    80004bba:	0080                	addi	s0,sp,64
    80004bbc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bbe:	0001d517          	auipc	a0,0x1d
    80004bc2:	01a50513          	addi	a0,a0,26 # 80021bd8 <ftable>
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	020080e7          	jalr	32(ra) # 80000be6 <acquire>
  if(f->ref < 1)
    80004bce:	40dc                	lw	a5,4(s1)
    80004bd0:	06f05163          	blez	a5,80004c32 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004bd4:	37fd                	addiw	a5,a5,-1
    80004bd6:	0007871b          	sext.w	a4,a5
    80004bda:	c0dc                	sw	a5,4(s1)
    80004bdc:	06e04363          	bgtz	a4,80004c42 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004be0:	0004a903          	lw	s2,0(s1)
    80004be4:	0094ca83          	lbu	s5,9(s1)
    80004be8:	0104ba03          	ld	s4,16(s1)
    80004bec:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bf0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bf4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bf8:	0001d517          	auipc	a0,0x1d
    80004bfc:	fe050513          	addi	a0,a0,-32 # 80021bd8 <ftable>
    80004c00:	ffffc097          	auipc	ra,0xffffc
    80004c04:	09a080e7          	jalr	154(ra) # 80000c9a <release>

  if(ff.type == FD_PIPE){
    80004c08:	4785                	li	a5,1
    80004c0a:	04f90d63          	beq	s2,a5,80004c64 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c0e:	3979                	addiw	s2,s2,-2
    80004c10:	4785                	li	a5,1
    80004c12:	0527e063          	bltu	a5,s2,80004c52 <fileclose+0xa8>
    begin_op();
    80004c16:	00000097          	auipc	ra,0x0
    80004c1a:	ac8080e7          	jalr	-1336(ra) # 800046de <begin_op>
    iput(ff.ip);
    80004c1e:	854e                	mv	a0,s3
    80004c20:	fffff097          	auipc	ra,0xfffff
    80004c24:	2a6080e7          	jalr	678(ra) # 80003ec6 <iput>
    end_op();
    80004c28:	00000097          	auipc	ra,0x0
    80004c2c:	b36080e7          	jalr	-1226(ra) # 8000475e <end_op>
    80004c30:	a00d                	j	80004c52 <fileclose+0xa8>
    panic("fileclose");
    80004c32:	00004517          	auipc	a0,0x4
    80004c36:	bae50513          	addi	a0,a0,-1106 # 800087e0 <syscalls+0x260>
    80004c3a:	ffffc097          	auipc	ra,0xffffc
    80004c3e:	906080e7          	jalr	-1786(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004c42:	0001d517          	auipc	a0,0x1d
    80004c46:	f9650513          	addi	a0,a0,-106 # 80021bd8 <ftable>
    80004c4a:	ffffc097          	auipc	ra,0xffffc
    80004c4e:	050080e7          	jalr	80(ra) # 80000c9a <release>
  }
}
    80004c52:	70e2                	ld	ra,56(sp)
    80004c54:	7442                	ld	s0,48(sp)
    80004c56:	74a2                	ld	s1,40(sp)
    80004c58:	7902                	ld	s2,32(sp)
    80004c5a:	69e2                	ld	s3,24(sp)
    80004c5c:	6a42                	ld	s4,16(sp)
    80004c5e:	6aa2                	ld	s5,8(sp)
    80004c60:	6121                	addi	sp,sp,64
    80004c62:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c64:	85d6                	mv	a1,s5
    80004c66:	8552                	mv	a0,s4
    80004c68:	00000097          	auipc	ra,0x0
    80004c6c:	34c080e7          	jalr	844(ra) # 80004fb4 <pipeclose>
    80004c70:	b7cd                	j	80004c52 <fileclose+0xa8>

0000000080004c72 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c72:	715d                	addi	sp,sp,-80
    80004c74:	e486                	sd	ra,72(sp)
    80004c76:	e0a2                	sd	s0,64(sp)
    80004c78:	fc26                	sd	s1,56(sp)
    80004c7a:	f84a                	sd	s2,48(sp)
    80004c7c:	f44e                	sd	s3,40(sp)
    80004c7e:	0880                	addi	s0,sp,80
    80004c80:	84aa                	mv	s1,a0
    80004c82:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c84:	ffffd097          	auipc	ra,0xffffd
    80004c88:	d6e080e7          	jalr	-658(ra) # 800019f2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c8c:	409c                	lw	a5,0(s1)
    80004c8e:	37f9                	addiw	a5,a5,-2
    80004c90:	4705                	li	a4,1
    80004c92:	04f76763          	bltu	a4,a5,80004ce0 <filestat+0x6e>
    80004c96:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c98:	6c88                	ld	a0,24(s1)
    80004c9a:	fffff097          	auipc	ra,0xfffff
    80004c9e:	072080e7          	jalr	114(ra) # 80003d0c <ilock>
    stati(f->ip, &st);
    80004ca2:	fb840593          	addi	a1,s0,-72
    80004ca6:	6c88                	ld	a0,24(s1)
    80004ca8:	fffff097          	auipc	ra,0xfffff
    80004cac:	2ee080e7          	jalr	750(ra) # 80003f96 <stati>
    iunlock(f->ip);
    80004cb0:	6c88                	ld	a0,24(s1)
    80004cb2:	fffff097          	auipc	ra,0xfffff
    80004cb6:	11c080e7          	jalr	284(ra) # 80003dce <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cba:	46e1                	li	a3,24
    80004cbc:	fb840613          	addi	a2,s0,-72
    80004cc0:	85ce                	mv	a1,s3
    80004cc2:	05093503          	ld	a0,80(s2)
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	9ae080e7          	jalr	-1618(ra) # 80001674 <copyout>
    80004cce:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004cd2:	60a6                	ld	ra,72(sp)
    80004cd4:	6406                	ld	s0,64(sp)
    80004cd6:	74e2                	ld	s1,56(sp)
    80004cd8:	7942                	ld	s2,48(sp)
    80004cda:	79a2                	ld	s3,40(sp)
    80004cdc:	6161                	addi	sp,sp,80
    80004cde:	8082                	ret
  return -1;
    80004ce0:	557d                	li	a0,-1
    80004ce2:	bfc5                	j	80004cd2 <filestat+0x60>

0000000080004ce4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ce4:	7179                	addi	sp,sp,-48
    80004ce6:	f406                	sd	ra,40(sp)
    80004ce8:	f022                	sd	s0,32(sp)
    80004cea:	ec26                	sd	s1,24(sp)
    80004cec:	e84a                	sd	s2,16(sp)
    80004cee:	e44e                	sd	s3,8(sp)
    80004cf0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cf2:	00854783          	lbu	a5,8(a0)
    80004cf6:	c3d5                	beqz	a5,80004d9a <fileread+0xb6>
    80004cf8:	84aa                	mv	s1,a0
    80004cfa:	89ae                	mv	s3,a1
    80004cfc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cfe:	411c                	lw	a5,0(a0)
    80004d00:	4705                	li	a4,1
    80004d02:	04e78963          	beq	a5,a4,80004d54 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d06:	470d                	li	a4,3
    80004d08:	04e78d63          	beq	a5,a4,80004d62 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d0c:	4709                	li	a4,2
    80004d0e:	06e79e63          	bne	a5,a4,80004d8a <fileread+0xa6>
    ilock(f->ip);
    80004d12:	6d08                	ld	a0,24(a0)
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	ff8080e7          	jalr	-8(ra) # 80003d0c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d1c:	874a                	mv	a4,s2
    80004d1e:	5094                	lw	a3,32(s1)
    80004d20:	864e                	mv	a2,s3
    80004d22:	4585                	li	a1,1
    80004d24:	6c88                	ld	a0,24(s1)
    80004d26:	fffff097          	auipc	ra,0xfffff
    80004d2a:	29a080e7          	jalr	666(ra) # 80003fc0 <readi>
    80004d2e:	892a                	mv	s2,a0
    80004d30:	00a05563          	blez	a0,80004d3a <fileread+0x56>
      f->off += r;
    80004d34:	509c                	lw	a5,32(s1)
    80004d36:	9fa9                	addw	a5,a5,a0
    80004d38:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d3a:	6c88                	ld	a0,24(s1)
    80004d3c:	fffff097          	auipc	ra,0xfffff
    80004d40:	092080e7          	jalr	146(ra) # 80003dce <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d44:	854a                	mv	a0,s2
    80004d46:	70a2                	ld	ra,40(sp)
    80004d48:	7402                	ld	s0,32(sp)
    80004d4a:	64e2                	ld	s1,24(sp)
    80004d4c:	6942                	ld	s2,16(sp)
    80004d4e:	69a2                	ld	s3,8(sp)
    80004d50:	6145                	addi	sp,sp,48
    80004d52:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d54:	6908                	ld	a0,16(a0)
    80004d56:	00000097          	auipc	ra,0x0
    80004d5a:	3ca080e7          	jalr	970(ra) # 80005120 <piperead>
    80004d5e:	892a                	mv	s2,a0
    80004d60:	b7d5                	j	80004d44 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d62:	02451783          	lh	a5,36(a0)
    80004d66:	03079693          	slli	a3,a5,0x30
    80004d6a:	92c1                	srli	a3,a3,0x30
    80004d6c:	4725                	li	a4,9
    80004d6e:	02d76863          	bltu	a4,a3,80004d9e <fileread+0xba>
    80004d72:	0792                	slli	a5,a5,0x4
    80004d74:	0001d717          	auipc	a4,0x1d
    80004d78:	dc470713          	addi	a4,a4,-572 # 80021b38 <devsw>
    80004d7c:	97ba                	add	a5,a5,a4
    80004d7e:	639c                	ld	a5,0(a5)
    80004d80:	c38d                	beqz	a5,80004da2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d82:	4505                	li	a0,1
    80004d84:	9782                	jalr	a5
    80004d86:	892a                	mv	s2,a0
    80004d88:	bf75                	j	80004d44 <fileread+0x60>
    panic("fileread");
    80004d8a:	00004517          	auipc	a0,0x4
    80004d8e:	a6650513          	addi	a0,a0,-1434 # 800087f0 <syscalls+0x270>
    80004d92:	ffffb097          	auipc	ra,0xffffb
    80004d96:	7ae080e7          	jalr	1966(ra) # 80000540 <panic>
    return -1;
    80004d9a:	597d                	li	s2,-1
    80004d9c:	b765                	j	80004d44 <fileread+0x60>
      return -1;
    80004d9e:	597d                	li	s2,-1
    80004da0:	b755                	j	80004d44 <fileread+0x60>
    80004da2:	597d                	li	s2,-1
    80004da4:	b745                	j	80004d44 <fileread+0x60>

0000000080004da6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004da6:	715d                	addi	sp,sp,-80
    80004da8:	e486                	sd	ra,72(sp)
    80004daa:	e0a2                	sd	s0,64(sp)
    80004dac:	fc26                	sd	s1,56(sp)
    80004dae:	f84a                	sd	s2,48(sp)
    80004db0:	f44e                	sd	s3,40(sp)
    80004db2:	f052                	sd	s4,32(sp)
    80004db4:	ec56                	sd	s5,24(sp)
    80004db6:	e85a                	sd	s6,16(sp)
    80004db8:	e45e                	sd	s7,8(sp)
    80004dba:	e062                	sd	s8,0(sp)
    80004dbc:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004dbe:	00954783          	lbu	a5,9(a0)
    80004dc2:	10078663          	beqz	a5,80004ece <filewrite+0x128>
    80004dc6:	892a                	mv	s2,a0
    80004dc8:	8aae                	mv	s5,a1
    80004dca:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004dcc:	411c                	lw	a5,0(a0)
    80004dce:	4705                	li	a4,1
    80004dd0:	02e78263          	beq	a5,a4,80004df4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004dd4:	470d                	li	a4,3
    80004dd6:	02e78663          	beq	a5,a4,80004e02 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004dda:	4709                	li	a4,2
    80004ddc:	0ee79163          	bne	a5,a4,80004ebe <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004de0:	0ac05d63          	blez	a2,80004e9a <filewrite+0xf4>
    int i = 0;
    80004de4:	4981                	li	s3,0
    80004de6:	6b05                	lui	s6,0x1
    80004de8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004dec:	6b85                	lui	s7,0x1
    80004dee:	c00b8b9b          	addiw	s7,s7,-1024
    80004df2:	a861                	j	80004e8a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004df4:	6908                	ld	a0,16(a0)
    80004df6:	00000097          	auipc	ra,0x0
    80004dfa:	22e080e7          	jalr	558(ra) # 80005024 <pipewrite>
    80004dfe:	8a2a                	mv	s4,a0
    80004e00:	a045                	j	80004ea0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e02:	02451783          	lh	a5,36(a0)
    80004e06:	03079693          	slli	a3,a5,0x30
    80004e0a:	92c1                	srli	a3,a3,0x30
    80004e0c:	4725                	li	a4,9
    80004e0e:	0cd76263          	bltu	a4,a3,80004ed2 <filewrite+0x12c>
    80004e12:	0792                	slli	a5,a5,0x4
    80004e14:	0001d717          	auipc	a4,0x1d
    80004e18:	d2470713          	addi	a4,a4,-732 # 80021b38 <devsw>
    80004e1c:	97ba                	add	a5,a5,a4
    80004e1e:	679c                	ld	a5,8(a5)
    80004e20:	cbdd                	beqz	a5,80004ed6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e22:	4505                	li	a0,1
    80004e24:	9782                	jalr	a5
    80004e26:	8a2a                	mv	s4,a0
    80004e28:	a8a5                	j	80004ea0 <filewrite+0xfa>
    80004e2a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e2e:	00000097          	auipc	ra,0x0
    80004e32:	8b0080e7          	jalr	-1872(ra) # 800046de <begin_op>
      ilock(f->ip);
    80004e36:	01893503          	ld	a0,24(s2)
    80004e3a:	fffff097          	auipc	ra,0xfffff
    80004e3e:	ed2080e7          	jalr	-302(ra) # 80003d0c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e42:	8762                	mv	a4,s8
    80004e44:	02092683          	lw	a3,32(s2)
    80004e48:	01598633          	add	a2,s3,s5
    80004e4c:	4585                	li	a1,1
    80004e4e:	01893503          	ld	a0,24(s2)
    80004e52:	fffff097          	auipc	ra,0xfffff
    80004e56:	266080e7          	jalr	614(ra) # 800040b8 <writei>
    80004e5a:	84aa                	mv	s1,a0
    80004e5c:	00a05763          	blez	a0,80004e6a <filewrite+0xc4>
        f->off += r;
    80004e60:	02092783          	lw	a5,32(s2)
    80004e64:	9fa9                	addw	a5,a5,a0
    80004e66:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e6a:	01893503          	ld	a0,24(s2)
    80004e6e:	fffff097          	auipc	ra,0xfffff
    80004e72:	f60080e7          	jalr	-160(ra) # 80003dce <iunlock>
      end_op();
    80004e76:	00000097          	auipc	ra,0x0
    80004e7a:	8e8080e7          	jalr	-1816(ra) # 8000475e <end_op>

      if(r != n1){
    80004e7e:	009c1f63          	bne	s8,s1,80004e9c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e82:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e86:	0149db63          	bge	s3,s4,80004e9c <filewrite+0xf6>
      int n1 = n - i;
    80004e8a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e8e:	84be                	mv	s1,a5
    80004e90:	2781                	sext.w	a5,a5
    80004e92:	f8fb5ce3          	bge	s6,a5,80004e2a <filewrite+0x84>
    80004e96:	84de                	mv	s1,s7
    80004e98:	bf49                	j	80004e2a <filewrite+0x84>
    int i = 0;
    80004e9a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e9c:	013a1f63          	bne	s4,s3,80004eba <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ea0:	8552                	mv	a0,s4
    80004ea2:	60a6                	ld	ra,72(sp)
    80004ea4:	6406                	ld	s0,64(sp)
    80004ea6:	74e2                	ld	s1,56(sp)
    80004ea8:	7942                	ld	s2,48(sp)
    80004eaa:	79a2                	ld	s3,40(sp)
    80004eac:	7a02                	ld	s4,32(sp)
    80004eae:	6ae2                	ld	s5,24(sp)
    80004eb0:	6b42                	ld	s6,16(sp)
    80004eb2:	6ba2                	ld	s7,8(sp)
    80004eb4:	6c02                	ld	s8,0(sp)
    80004eb6:	6161                	addi	sp,sp,80
    80004eb8:	8082                	ret
    ret = (i == n ? n : -1);
    80004eba:	5a7d                	li	s4,-1
    80004ebc:	b7d5                	j	80004ea0 <filewrite+0xfa>
    panic("filewrite");
    80004ebe:	00004517          	auipc	a0,0x4
    80004ec2:	94250513          	addi	a0,a0,-1726 # 80008800 <syscalls+0x280>
    80004ec6:	ffffb097          	auipc	ra,0xffffb
    80004eca:	67a080e7          	jalr	1658(ra) # 80000540 <panic>
    return -1;
    80004ece:	5a7d                	li	s4,-1
    80004ed0:	bfc1                	j	80004ea0 <filewrite+0xfa>
      return -1;
    80004ed2:	5a7d                	li	s4,-1
    80004ed4:	b7f1                	j	80004ea0 <filewrite+0xfa>
    80004ed6:	5a7d                	li	s4,-1
    80004ed8:	b7e1                	j	80004ea0 <filewrite+0xfa>

0000000080004eda <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004eda:	7179                	addi	sp,sp,-48
    80004edc:	f406                	sd	ra,40(sp)
    80004ede:	f022                	sd	s0,32(sp)
    80004ee0:	ec26                	sd	s1,24(sp)
    80004ee2:	e84a                	sd	s2,16(sp)
    80004ee4:	e44e                	sd	s3,8(sp)
    80004ee6:	e052                	sd	s4,0(sp)
    80004ee8:	1800                	addi	s0,sp,48
    80004eea:	84aa                	mv	s1,a0
    80004eec:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004eee:	0005b023          	sd	zero,0(a1)
    80004ef2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ef6:	00000097          	auipc	ra,0x0
    80004efa:	bf8080e7          	jalr	-1032(ra) # 80004aee <filealloc>
    80004efe:	e088                	sd	a0,0(s1)
    80004f00:	c551                	beqz	a0,80004f8c <pipealloc+0xb2>
    80004f02:	00000097          	auipc	ra,0x0
    80004f06:	bec080e7          	jalr	-1044(ra) # 80004aee <filealloc>
    80004f0a:	00aa3023          	sd	a0,0(s4)
    80004f0e:	c92d                	beqz	a0,80004f80 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	be6080e7          	jalr	-1050(ra) # 80000af6 <kalloc>
    80004f18:	892a                	mv	s2,a0
    80004f1a:	c125                	beqz	a0,80004f7a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f1c:	4985                	li	s3,1
    80004f1e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f22:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f26:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f2a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f2e:	00004597          	auipc	a1,0x4
    80004f32:	8e258593          	addi	a1,a1,-1822 # 80008810 <syscalls+0x290>
    80004f36:	ffffc097          	auipc	ra,0xffffc
    80004f3a:	c20080e7          	jalr	-992(ra) # 80000b56 <initlock>
  (*f0)->type = FD_PIPE;
    80004f3e:	609c                	ld	a5,0(s1)
    80004f40:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f44:	609c                	ld	a5,0(s1)
    80004f46:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f4a:	609c                	ld	a5,0(s1)
    80004f4c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f50:	609c                	ld	a5,0(s1)
    80004f52:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f56:	000a3783          	ld	a5,0(s4)
    80004f5a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f5e:	000a3783          	ld	a5,0(s4)
    80004f62:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f66:	000a3783          	ld	a5,0(s4)
    80004f6a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f6e:	000a3783          	ld	a5,0(s4)
    80004f72:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f76:	4501                	li	a0,0
    80004f78:	a025                	j	80004fa0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f7a:	6088                	ld	a0,0(s1)
    80004f7c:	e501                	bnez	a0,80004f84 <pipealloc+0xaa>
    80004f7e:	a039                	j	80004f8c <pipealloc+0xb2>
    80004f80:	6088                	ld	a0,0(s1)
    80004f82:	c51d                	beqz	a0,80004fb0 <pipealloc+0xd6>
    fileclose(*f0);
    80004f84:	00000097          	auipc	ra,0x0
    80004f88:	c26080e7          	jalr	-986(ra) # 80004baa <fileclose>
  if(*f1)
    80004f8c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f90:	557d                	li	a0,-1
  if(*f1)
    80004f92:	c799                	beqz	a5,80004fa0 <pipealloc+0xc6>
    fileclose(*f1);
    80004f94:	853e                	mv	a0,a5
    80004f96:	00000097          	auipc	ra,0x0
    80004f9a:	c14080e7          	jalr	-1004(ra) # 80004baa <fileclose>
  return -1;
    80004f9e:	557d                	li	a0,-1
}
    80004fa0:	70a2                	ld	ra,40(sp)
    80004fa2:	7402                	ld	s0,32(sp)
    80004fa4:	64e2                	ld	s1,24(sp)
    80004fa6:	6942                	ld	s2,16(sp)
    80004fa8:	69a2                	ld	s3,8(sp)
    80004faa:	6a02                	ld	s4,0(sp)
    80004fac:	6145                	addi	sp,sp,48
    80004fae:	8082                	ret
  return -1;
    80004fb0:	557d                	li	a0,-1
    80004fb2:	b7fd                	j	80004fa0 <pipealloc+0xc6>

0000000080004fb4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fb4:	1101                	addi	sp,sp,-32
    80004fb6:	ec06                	sd	ra,24(sp)
    80004fb8:	e822                	sd	s0,16(sp)
    80004fba:	e426                	sd	s1,8(sp)
    80004fbc:	e04a                	sd	s2,0(sp)
    80004fbe:	1000                	addi	s0,sp,32
    80004fc0:	84aa                	mv	s1,a0
    80004fc2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	c22080e7          	jalr	-990(ra) # 80000be6 <acquire>
  if(writable){
    80004fcc:	02090d63          	beqz	s2,80005006 <pipeclose+0x52>
    pi->writeopen = 0;
    80004fd0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004fd4:	21848513          	addi	a0,s1,536
    80004fd8:	ffffd097          	auipc	ra,0xffffd
    80004fdc:	4f2080e7          	jalr	1266(ra) # 800024ca <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004fe0:	2204b783          	ld	a5,544(s1)
    80004fe4:	eb95                	bnez	a5,80005018 <pipeclose+0x64>
    release(&pi->lock);
    80004fe6:	8526                	mv	a0,s1
    80004fe8:	ffffc097          	auipc	ra,0xffffc
    80004fec:	cb2080e7          	jalr	-846(ra) # 80000c9a <release>
    kfree((char*)pi);
    80004ff0:	8526                	mv	a0,s1
    80004ff2:	ffffc097          	auipc	ra,0xffffc
    80004ff6:	a08080e7          	jalr	-1528(ra) # 800009fa <kfree>
  } else
    release(&pi->lock);
}
    80004ffa:	60e2                	ld	ra,24(sp)
    80004ffc:	6442                	ld	s0,16(sp)
    80004ffe:	64a2                	ld	s1,8(sp)
    80005000:	6902                	ld	s2,0(sp)
    80005002:	6105                	addi	sp,sp,32
    80005004:	8082                	ret
    pi->readopen = 0;
    80005006:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000500a:	21c48513          	addi	a0,s1,540
    8000500e:	ffffd097          	auipc	ra,0xffffd
    80005012:	4bc080e7          	jalr	1212(ra) # 800024ca <wakeup>
    80005016:	b7e9                	j	80004fe0 <pipeclose+0x2c>
    release(&pi->lock);
    80005018:	8526                	mv	a0,s1
    8000501a:	ffffc097          	auipc	ra,0xffffc
    8000501e:	c80080e7          	jalr	-896(ra) # 80000c9a <release>
}
    80005022:	bfe1                	j	80004ffa <pipeclose+0x46>

0000000080005024 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005024:	7159                	addi	sp,sp,-112
    80005026:	f486                	sd	ra,104(sp)
    80005028:	f0a2                	sd	s0,96(sp)
    8000502a:	eca6                	sd	s1,88(sp)
    8000502c:	e8ca                	sd	s2,80(sp)
    8000502e:	e4ce                	sd	s3,72(sp)
    80005030:	e0d2                	sd	s4,64(sp)
    80005032:	fc56                	sd	s5,56(sp)
    80005034:	f85a                	sd	s6,48(sp)
    80005036:	f45e                	sd	s7,40(sp)
    80005038:	f062                	sd	s8,32(sp)
    8000503a:	ec66                	sd	s9,24(sp)
    8000503c:	1880                	addi	s0,sp,112
    8000503e:	84aa                	mv	s1,a0
    80005040:	8aae                	mv	s5,a1
    80005042:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	9ae080e7          	jalr	-1618(ra) # 800019f2 <myproc>
    8000504c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000504e:	8526                	mv	a0,s1
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	b96080e7          	jalr	-1130(ra) # 80000be6 <acquire>
  while(i < n){
    80005058:	0d405263          	blez	s4,8000511c <pipewrite+0xf8>
    8000505c:	8ba6                	mv	s7,s1
  int i = 0;
    8000505e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005060:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005062:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005066:	21c48c13          	addi	s8,s1,540
    8000506a:	a08d                	j	800050cc <pipewrite+0xa8>
      release(&pi->lock);
    8000506c:	8526                	mv	a0,s1
    8000506e:	ffffc097          	auipc	ra,0xffffc
    80005072:	c2c080e7          	jalr	-980(ra) # 80000c9a <release>
      return -1;
    80005076:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005078:	854a                	mv	a0,s2
    8000507a:	70a6                	ld	ra,104(sp)
    8000507c:	7406                	ld	s0,96(sp)
    8000507e:	64e6                	ld	s1,88(sp)
    80005080:	6946                	ld	s2,80(sp)
    80005082:	69a6                	ld	s3,72(sp)
    80005084:	6a06                	ld	s4,64(sp)
    80005086:	7ae2                	ld	s5,56(sp)
    80005088:	7b42                	ld	s6,48(sp)
    8000508a:	7ba2                	ld	s7,40(sp)
    8000508c:	7c02                	ld	s8,32(sp)
    8000508e:	6ce2                	ld	s9,24(sp)
    80005090:	6165                	addi	sp,sp,112
    80005092:	8082                	ret
      wakeup(&pi->nread);
    80005094:	8566                	mv	a0,s9
    80005096:	ffffd097          	auipc	ra,0xffffd
    8000509a:	434080e7          	jalr	1076(ra) # 800024ca <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000509e:	85de                	mv	a1,s7
    800050a0:	8562                	mv	a0,s8
    800050a2:	ffffd097          	auipc	ra,0xffffd
    800050a6:	242080e7          	jalr	578(ra) # 800022e4 <sleep>
    800050aa:	a839                	j	800050c8 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050ac:	21c4a783          	lw	a5,540(s1)
    800050b0:	0017871b          	addiw	a4,a5,1
    800050b4:	20e4ae23          	sw	a4,540(s1)
    800050b8:	1ff7f793          	andi	a5,a5,511
    800050bc:	97a6                	add	a5,a5,s1
    800050be:	f9f44703          	lbu	a4,-97(s0)
    800050c2:	00e78c23          	sb	a4,24(a5)
      i++;
    800050c6:	2905                	addiw	s2,s2,1
  while(i < n){
    800050c8:	03495e63          	bge	s2,s4,80005104 <pipewrite+0xe0>
    if(pi->readopen == 0 || pr->killed){
    800050cc:	2204a783          	lw	a5,544(s1)
    800050d0:	dfd1                	beqz	a5,8000506c <pipewrite+0x48>
    800050d2:	0289a783          	lw	a5,40(s3)
    800050d6:	2781                	sext.w	a5,a5
    800050d8:	fbd1                	bnez	a5,8000506c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800050da:	2184a783          	lw	a5,536(s1)
    800050de:	21c4a703          	lw	a4,540(s1)
    800050e2:	2007879b          	addiw	a5,a5,512
    800050e6:	faf707e3          	beq	a4,a5,80005094 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050ea:	4685                	li	a3,1
    800050ec:	01590633          	add	a2,s2,s5
    800050f0:	f9f40593          	addi	a1,s0,-97
    800050f4:	0509b503          	ld	a0,80(s3)
    800050f8:	ffffc097          	auipc	ra,0xffffc
    800050fc:	608080e7          	jalr	1544(ra) # 80001700 <copyin>
    80005100:	fb6516e3          	bne	a0,s6,800050ac <pipewrite+0x88>
  wakeup(&pi->nread);
    80005104:	21848513          	addi	a0,s1,536
    80005108:	ffffd097          	auipc	ra,0xffffd
    8000510c:	3c2080e7          	jalr	962(ra) # 800024ca <wakeup>
  release(&pi->lock);
    80005110:	8526                	mv	a0,s1
    80005112:	ffffc097          	auipc	ra,0xffffc
    80005116:	b88080e7          	jalr	-1144(ra) # 80000c9a <release>
  return i;
    8000511a:	bfb9                	j	80005078 <pipewrite+0x54>
  int i = 0;
    8000511c:	4901                	li	s2,0
    8000511e:	b7dd                	j	80005104 <pipewrite+0xe0>

0000000080005120 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005120:	715d                	addi	sp,sp,-80
    80005122:	e486                	sd	ra,72(sp)
    80005124:	e0a2                	sd	s0,64(sp)
    80005126:	fc26                	sd	s1,56(sp)
    80005128:	f84a                	sd	s2,48(sp)
    8000512a:	f44e                	sd	s3,40(sp)
    8000512c:	f052                	sd	s4,32(sp)
    8000512e:	ec56                	sd	s5,24(sp)
    80005130:	e85a                	sd	s6,16(sp)
    80005132:	0880                	addi	s0,sp,80
    80005134:	84aa                	mv	s1,a0
    80005136:	892e                	mv	s2,a1
    80005138:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000513a:	ffffd097          	auipc	ra,0xffffd
    8000513e:	8b8080e7          	jalr	-1864(ra) # 800019f2 <myproc>
    80005142:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005144:	8b26                	mv	s6,s1
    80005146:	8526                	mv	a0,s1
    80005148:	ffffc097          	auipc	ra,0xffffc
    8000514c:	a9e080e7          	jalr	-1378(ra) # 80000be6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005150:	2184a703          	lw	a4,536(s1)
    80005154:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005158:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000515c:	02f71563          	bne	a4,a5,80005186 <piperead+0x66>
    80005160:	2244a783          	lw	a5,548(s1)
    80005164:	c38d                	beqz	a5,80005186 <piperead+0x66>
    if(pr->killed){
    80005166:	028a2783          	lw	a5,40(s4)
    8000516a:	2781                	sext.w	a5,a5
    8000516c:	ebc1                	bnez	a5,800051fc <piperead+0xdc>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000516e:	85da                	mv	a1,s6
    80005170:	854e                	mv	a0,s3
    80005172:	ffffd097          	auipc	ra,0xffffd
    80005176:	172080e7          	jalr	370(ra) # 800022e4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000517a:	2184a703          	lw	a4,536(s1)
    8000517e:	21c4a783          	lw	a5,540(s1)
    80005182:	fcf70fe3          	beq	a4,a5,80005160 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005186:	09505263          	blez	s5,8000520a <piperead+0xea>
    8000518a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000518c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000518e:	2184a783          	lw	a5,536(s1)
    80005192:	21c4a703          	lw	a4,540(s1)
    80005196:	02f70d63          	beq	a4,a5,800051d0 <piperead+0xb0>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000519a:	0017871b          	addiw	a4,a5,1
    8000519e:	20e4ac23          	sw	a4,536(s1)
    800051a2:	1ff7f793          	andi	a5,a5,511
    800051a6:	97a6                	add	a5,a5,s1
    800051a8:	0187c783          	lbu	a5,24(a5)
    800051ac:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051b0:	4685                	li	a3,1
    800051b2:	fbf40613          	addi	a2,s0,-65
    800051b6:	85ca                	mv	a1,s2
    800051b8:	050a3503          	ld	a0,80(s4)
    800051bc:	ffffc097          	auipc	ra,0xffffc
    800051c0:	4b8080e7          	jalr	1208(ra) # 80001674 <copyout>
    800051c4:	01650663          	beq	a0,s6,800051d0 <piperead+0xb0>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051c8:	2985                	addiw	s3,s3,1
    800051ca:	0905                	addi	s2,s2,1
    800051cc:	fd3a91e3          	bne	s5,s3,8000518e <piperead+0x6e>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800051d0:	21c48513          	addi	a0,s1,540
    800051d4:	ffffd097          	auipc	ra,0xffffd
    800051d8:	2f6080e7          	jalr	758(ra) # 800024ca <wakeup>
  release(&pi->lock);
    800051dc:	8526                	mv	a0,s1
    800051de:	ffffc097          	auipc	ra,0xffffc
    800051e2:	abc080e7          	jalr	-1348(ra) # 80000c9a <release>
  return i;
}
    800051e6:	854e                	mv	a0,s3
    800051e8:	60a6                	ld	ra,72(sp)
    800051ea:	6406                	ld	s0,64(sp)
    800051ec:	74e2                	ld	s1,56(sp)
    800051ee:	7942                	ld	s2,48(sp)
    800051f0:	79a2                	ld	s3,40(sp)
    800051f2:	7a02                	ld	s4,32(sp)
    800051f4:	6ae2                	ld	s5,24(sp)
    800051f6:	6b42                	ld	s6,16(sp)
    800051f8:	6161                	addi	sp,sp,80
    800051fa:	8082                	ret
      release(&pi->lock);
    800051fc:	8526                	mv	a0,s1
    800051fe:	ffffc097          	auipc	ra,0xffffc
    80005202:	a9c080e7          	jalr	-1380(ra) # 80000c9a <release>
      return -1;
    80005206:	59fd                	li	s3,-1
    80005208:	bff9                	j	800051e6 <piperead+0xc6>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000520a:	4981                	li	s3,0
    8000520c:	b7d1                	j	800051d0 <piperead+0xb0>

000000008000520e <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    8000520e:	df010113          	addi	sp,sp,-528
    80005212:	20113423          	sd	ra,520(sp)
    80005216:	20813023          	sd	s0,512(sp)
    8000521a:	ffa6                	sd	s1,504(sp)
    8000521c:	fbca                	sd	s2,496(sp)
    8000521e:	f7ce                	sd	s3,488(sp)
    80005220:	f3d2                	sd	s4,480(sp)
    80005222:	efd6                	sd	s5,472(sp)
    80005224:	ebda                	sd	s6,464(sp)
    80005226:	e7de                	sd	s7,456(sp)
    80005228:	e3e2                	sd	s8,448(sp)
    8000522a:	ff66                	sd	s9,440(sp)
    8000522c:	fb6a                	sd	s10,432(sp)
    8000522e:	f76e                	sd	s11,424(sp)
    80005230:	0c00                	addi	s0,sp,528
    80005232:	84aa                	mv	s1,a0
    80005234:	dea43c23          	sd	a0,-520(s0)
    80005238:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000523c:	ffffc097          	auipc	ra,0xffffc
    80005240:	7b6080e7          	jalr	1974(ra) # 800019f2 <myproc>
    80005244:	892a                	mv	s2,a0

  begin_op();
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	498080e7          	jalr	1176(ra) # 800046de <begin_op>

  if((ip = namei(path)) == 0){
    8000524e:	8526                	mv	a0,s1
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	272080e7          	jalr	626(ra) # 800044c2 <namei>
    80005258:	c92d                	beqz	a0,800052ca <exec+0xbc>
    8000525a:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	ab0080e7          	jalr	-1360(ra) # 80003d0c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005264:	04000713          	li	a4,64
    80005268:	4681                	li	a3,0
    8000526a:	e5040613          	addi	a2,s0,-432
    8000526e:	4581                	li	a1,0
    80005270:	8526                	mv	a0,s1
    80005272:	fffff097          	auipc	ra,0xfffff
    80005276:	d4e080e7          	jalr	-690(ra) # 80003fc0 <readi>
    8000527a:	04000793          	li	a5,64
    8000527e:	00f51a63          	bne	a0,a5,80005292 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005282:	e5042703          	lw	a4,-432(s0)
    80005286:	464c47b7          	lui	a5,0x464c4
    8000528a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000528e:	04f70463          	beq	a4,a5,800052d6 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005292:	8526                	mv	a0,s1
    80005294:	fffff097          	auipc	ra,0xfffff
    80005298:	cda080e7          	jalr	-806(ra) # 80003f6e <iunlockput>
    end_op();
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	4c2080e7          	jalr	1218(ra) # 8000475e <end_op>
  }
  return -1;
    800052a4:	557d                	li	a0,-1
}
    800052a6:	20813083          	ld	ra,520(sp)
    800052aa:	20013403          	ld	s0,512(sp)
    800052ae:	74fe                	ld	s1,504(sp)
    800052b0:	795e                	ld	s2,496(sp)
    800052b2:	79be                	ld	s3,488(sp)
    800052b4:	7a1e                	ld	s4,480(sp)
    800052b6:	6afe                	ld	s5,472(sp)
    800052b8:	6b5e                	ld	s6,464(sp)
    800052ba:	6bbe                	ld	s7,456(sp)
    800052bc:	6c1e                	ld	s8,448(sp)
    800052be:	7cfa                	ld	s9,440(sp)
    800052c0:	7d5a                	ld	s10,432(sp)
    800052c2:	7dba                	ld	s11,424(sp)
    800052c4:	21010113          	addi	sp,sp,528
    800052c8:	8082                	ret
    end_op();
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	494080e7          	jalr	1172(ra) # 8000475e <end_op>
    return -1;
    800052d2:	557d                	li	a0,-1
    800052d4:	bfc9                	j	800052a6 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800052d6:	854a                	mv	a0,s2
    800052d8:	ffffc097          	auipc	ra,0xffffc
    800052dc:	7de080e7          	jalr	2014(ra) # 80001ab6 <proc_pagetable>
    800052e0:	8baa                	mv	s7,a0
    800052e2:	d945                	beqz	a0,80005292 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052e4:	e7042983          	lw	s3,-400(s0)
    800052e8:	e8845783          	lhu	a5,-376(s0)
    800052ec:	c7ad                	beqz	a5,80005356 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052ee:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052f0:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800052f2:	6c85                	lui	s9,0x1
    800052f4:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800052f8:	def43823          	sd	a5,-528(s0)
    800052fc:	a42d                	j	80005526 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800052fe:	00003517          	auipc	a0,0x3
    80005302:	51a50513          	addi	a0,a0,1306 # 80008818 <syscalls+0x298>
    80005306:	ffffb097          	auipc	ra,0xffffb
    8000530a:	23a080e7          	jalr	570(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000530e:	8756                	mv	a4,s5
    80005310:	012d86bb          	addw	a3,s11,s2
    80005314:	4581                	li	a1,0
    80005316:	8526                	mv	a0,s1
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	ca8080e7          	jalr	-856(ra) # 80003fc0 <readi>
    80005320:	2501                	sext.w	a0,a0
    80005322:	1aaa9963          	bne	s5,a0,800054d4 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005326:	6785                	lui	a5,0x1
    80005328:	0127893b          	addw	s2,a5,s2
    8000532c:	77fd                	lui	a5,0xfffff
    8000532e:	01478a3b          	addw	s4,a5,s4
    80005332:	1f897163          	bgeu	s2,s8,80005514 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005336:	02091593          	slli	a1,s2,0x20
    8000533a:	9181                	srli	a1,a1,0x20
    8000533c:	95ea                	add	a1,a1,s10
    8000533e:	855e                	mv	a0,s7
    80005340:	ffffc097          	auipc	ra,0xffffc
    80005344:	d30080e7          	jalr	-720(ra) # 80001070 <walkaddr>
    80005348:	862a                	mv	a2,a0
    if(pa == 0)
    8000534a:	d955                	beqz	a0,800052fe <exec+0xf0>
      n = PGSIZE;
    8000534c:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000534e:	fd9a70e3          	bgeu	s4,s9,8000530e <exec+0x100>
      n = sz - i;
    80005352:	8ad2                	mv	s5,s4
    80005354:	bf6d                	j	8000530e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005356:	4901                	li	s2,0
  iunlockput(ip);
    80005358:	8526                	mv	a0,s1
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	c14080e7          	jalr	-1004(ra) # 80003f6e <iunlockput>
  end_op();
    80005362:	fffff097          	auipc	ra,0xfffff
    80005366:	3fc080e7          	jalr	1020(ra) # 8000475e <end_op>
  p = myproc();
    8000536a:	ffffc097          	auipc	ra,0xffffc
    8000536e:	688080e7          	jalr	1672(ra) # 800019f2 <myproc>
    80005372:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005374:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005378:	6785                	lui	a5,0x1
    8000537a:	17fd                	addi	a5,a5,-1
    8000537c:	993e                	add	s2,s2,a5
    8000537e:	757d                	lui	a0,0xfffff
    80005380:	00a977b3          	and	a5,s2,a0
    80005384:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005388:	6609                	lui	a2,0x2
    8000538a:	963e                	add	a2,a2,a5
    8000538c:	85be                	mv	a1,a5
    8000538e:	855e                	mv	a0,s7
    80005390:	ffffc097          	auipc	ra,0xffffc
    80005394:	094080e7          	jalr	148(ra) # 80001424 <uvmalloc>
    80005398:	8b2a                	mv	s6,a0
  ip = 0;
    8000539a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000539c:	12050c63          	beqz	a0,800054d4 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053a0:	75f9                	lui	a1,0xffffe
    800053a2:	95aa                	add	a1,a1,a0
    800053a4:	855e                	mv	a0,s7
    800053a6:	ffffc097          	auipc	ra,0xffffc
    800053aa:	29c080e7          	jalr	668(ra) # 80001642 <uvmclear>
  stackbase = sp - PGSIZE;
    800053ae:	7c7d                	lui	s8,0xfffff
    800053b0:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800053b2:	e0043783          	ld	a5,-512(s0)
    800053b6:	6388                	ld	a0,0(a5)
    800053b8:	c535                	beqz	a0,80005424 <exec+0x216>
    800053ba:	e9040993          	addi	s3,s0,-368
    800053be:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053c2:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800053c4:	ffffc097          	auipc	ra,0xffffc
    800053c8:	aa2080e7          	jalr	-1374(ra) # 80000e66 <strlen>
    800053cc:	2505                	addiw	a0,a0,1
    800053ce:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053d2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800053d6:	13896363          	bltu	s2,s8,800054fc <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053da:	e0043d83          	ld	s11,-512(s0)
    800053de:	000dba03          	ld	s4,0(s11)
    800053e2:	8552                	mv	a0,s4
    800053e4:	ffffc097          	auipc	ra,0xffffc
    800053e8:	a82080e7          	jalr	-1406(ra) # 80000e66 <strlen>
    800053ec:	0015069b          	addiw	a3,a0,1
    800053f0:	8652                	mv	a2,s4
    800053f2:	85ca                	mv	a1,s2
    800053f4:	855e                	mv	a0,s7
    800053f6:	ffffc097          	auipc	ra,0xffffc
    800053fa:	27e080e7          	jalr	638(ra) # 80001674 <copyout>
    800053fe:	10054363          	bltz	a0,80005504 <exec+0x2f6>
    ustack[argc] = sp;
    80005402:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005406:	0485                	addi	s1,s1,1
    80005408:	008d8793          	addi	a5,s11,8
    8000540c:	e0f43023          	sd	a5,-512(s0)
    80005410:	008db503          	ld	a0,8(s11)
    80005414:	c911                	beqz	a0,80005428 <exec+0x21a>
    if(argc >= MAXARG)
    80005416:	09a1                	addi	s3,s3,8
    80005418:	fb3c96e3          	bne	s9,s3,800053c4 <exec+0x1b6>
  sz = sz1;
    8000541c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005420:	4481                	li	s1,0
    80005422:	a84d                	j	800054d4 <exec+0x2c6>
  sp = sz;
    80005424:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005426:	4481                	li	s1,0
  ustack[argc] = 0;
    80005428:	00349793          	slli	a5,s1,0x3
    8000542c:	f9040713          	addi	a4,s0,-112
    80005430:	97ba                	add	a5,a5,a4
    80005432:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005436:	00148693          	addi	a3,s1,1
    8000543a:	068e                	slli	a3,a3,0x3
    8000543c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005440:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005444:	01897663          	bgeu	s2,s8,80005450 <exec+0x242>
  sz = sz1;
    80005448:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000544c:	4481                	li	s1,0
    8000544e:	a059                	j	800054d4 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005450:	e9040613          	addi	a2,s0,-368
    80005454:	85ca                	mv	a1,s2
    80005456:	855e                	mv	a0,s7
    80005458:	ffffc097          	auipc	ra,0xffffc
    8000545c:	21c080e7          	jalr	540(ra) # 80001674 <copyout>
    80005460:	0a054663          	bltz	a0,8000550c <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005464:	058ab783          	ld	a5,88(s5)
    80005468:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000546c:	df843783          	ld	a5,-520(s0)
    80005470:	0007c703          	lbu	a4,0(a5)
    80005474:	cf11                	beqz	a4,80005490 <exec+0x282>
    80005476:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005478:	02f00693          	li	a3,47
    8000547c:	a039                	j	8000548a <exec+0x27c>
      last = s+1;
    8000547e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005482:	0785                	addi	a5,a5,1
    80005484:	fff7c703          	lbu	a4,-1(a5)
    80005488:	c701                	beqz	a4,80005490 <exec+0x282>
    if(*s == '/')
    8000548a:	fed71ce3          	bne	a4,a3,80005482 <exec+0x274>
    8000548e:	bfc5                	j	8000547e <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005490:	4641                	li	a2,16
    80005492:	df843583          	ld	a1,-520(s0)
    80005496:	158a8513          	addi	a0,s5,344
    8000549a:	ffffc097          	auipc	ra,0xffffc
    8000549e:	99a080e7          	jalr	-1638(ra) # 80000e34 <safestrcpy>
  oldpagetable = p->pagetable;
    800054a2:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800054a6:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800054aa:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054ae:	058ab783          	ld	a5,88(s5)
    800054b2:	e6843703          	ld	a4,-408(s0)
    800054b6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054b8:	058ab783          	ld	a5,88(s5)
    800054bc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054c0:	85ea                	mv	a1,s10
    800054c2:	ffffc097          	auipc	ra,0xffffc
    800054c6:	690080e7          	jalr	1680(ra) # 80001b52 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054ca:	0004851b          	sext.w	a0,s1
    800054ce:	bbe1                	j	800052a6 <exec+0x98>
    800054d0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800054d4:	e0843583          	ld	a1,-504(s0)
    800054d8:	855e                	mv	a0,s7
    800054da:	ffffc097          	auipc	ra,0xffffc
    800054de:	678080e7          	jalr	1656(ra) # 80001b52 <proc_freepagetable>
  if(ip){
    800054e2:	da0498e3          	bnez	s1,80005292 <exec+0x84>
  return -1;
    800054e6:	557d                	li	a0,-1
    800054e8:	bb7d                	j	800052a6 <exec+0x98>
    800054ea:	e1243423          	sd	s2,-504(s0)
    800054ee:	b7dd                	j	800054d4 <exec+0x2c6>
    800054f0:	e1243423          	sd	s2,-504(s0)
    800054f4:	b7c5                	j	800054d4 <exec+0x2c6>
    800054f6:	e1243423          	sd	s2,-504(s0)
    800054fa:	bfe9                	j	800054d4 <exec+0x2c6>
  sz = sz1;
    800054fc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005500:	4481                	li	s1,0
    80005502:	bfc9                	j	800054d4 <exec+0x2c6>
  sz = sz1;
    80005504:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005508:	4481                	li	s1,0
    8000550a:	b7e9                	j	800054d4 <exec+0x2c6>
  sz = sz1;
    8000550c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005510:	4481                	li	s1,0
    80005512:	b7c9                	j	800054d4 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005514:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005518:	2b05                	addiw	s6,s6,1
    8000551a:	0389899b          	addiw	s3,s3,56
    8000551e:	e8845783          	lhu	a5,-376(s0)
    80005522:	e2fb5be3          	bge	s6,a5,80005358 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005526:	2981                	sext.w	s3,s3
    80005528:	03800713          	li	a4,56
    8000552c:	86ce                	mv	a3,s3
    8000552e:	e1840613          	addi	a2,s0,-488
    80005532:	4581                	li	a1,0
    80005534:	8526                	mv	a0,s1
    80005536:	fffff097          	auipc	ra,0xfffff
    8000553a:	a8a080e7          	jalr	-1398(ra) # 80003fc0 <readi>
    8000553e:	03800793          	li	a5,56
    80005542:	f8f517e3          	bne	a0,a5,800054d0 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005546:	e1842783          	lw	a5,-488(s0)
    8000554a:	4705                	li	a4,1
    8000554c:	fce796e3          	bne	a5,a4,80005518 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005550:	e4043603          	ld	a2,-448(s0)
    80005554:	e3843783          	ld	a5,-456(s0)
    80005558:	f8f669e3          	bltu	a2,a5,800054ea <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000555c:	e2843783          	ld	a5,-472(s0)
    80005560:	963e                	add	a2,a2,a5
    80005562:	f8f667e3          	bltu	a2,a5,800054f0 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005566:	85ca                	mv	a1,s2
    80005568:	855e                	mv	a0,s7
    8000556a:	ffffc097          	auipc	ra,0xffffc
    8000556e:	eba080e7          	jalr	-326(ra) # 80001424 <uvmalloc>
    80005572:	e0a43423          	sd	a0,-504(s0)
    80005576:	d141                	beqz	a0,800054f6 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005578:	e2843d03          	ld	s10,-472(s0)
    8000557c:	df043783          	ld	a5,-528(s0)
    80005580:	00fd77b3          	and	a5,s10,a5
    80005584:	fba1                	bnez	a5,800054d4 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005586:	e2042d83          	lw	s11,-480(s0)
    8000558a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000558e:	f80c03e3          	beqz	s8,80005514 <exec+0x306>
    80005592:	8a62                	mv	s4,s8
    80005594:	4901                	li	s2,0
    80005596:	b345                	j	80005336 <exec+0x128>

0000000080005598 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005598:	7179                	addi	sp,sp,-48
    8000559a:	f406                	sd	ra,40(sp)
    8000559c:	f022                	sd	s0,32(sp)
    8000559e:	ec26                	sd	s1,24(sp)
    800055a0:	e84a                	sd	s2,16(sp)
    800055a2:	1800                	addi	s0,sp,48
    800055a4:	892e                	mv	s2,a1
    800055a6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800055a8:	fdc40593          	addi	a1,s0,-36
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	b88080e7          	jalr	-1144(ra) # 80003134 <argint>
    800055b4:	04054063          	bltz	a0,800055f4 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055b8:	fdc42703          	lw	a4,-36(s0)
    800055bc:	47bd                	li	a5,15
    800055be:	02e7ed63          	bltu	a5,a4,800055f8 <argfd+0x60>
    800055c2:	ffffc097          	auipc	ra,0xffffc
    800055c6:	430080e7          	jalr	1072(ra) # 800019f2 <myproc>
    800055ca:	fdc42703          	lw	a4,-36(s0)
    800055ce:	01a70793          	addi	a5,a4,26
    800055d2:	078e                	slli	a5,a5,0x3
    800055d4:	953e                	add	a0,a0,a5
    800055d6:	611c                	ld	a5,0(a0)
    800055d8:	c395                	beqz	a5,800055fc <argfd+0x64>
    return -1;
  if(pfd)
    800055da:	00090463          	beqz	s2,800055e2 <argfd+0x4a>
    *pfd = fd;
    800055de:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055e2:	4501                	li	a0,0
  if(pf)
    800055e4:	c091                	beqz	s1,800055e8 <argfd+0x50>
    *pf = f;
    800055e6:	e09c                	sd	a5,0(s1)
}
    800055e8:	70a2                	ld	ra,40(sp)
    800055ea:	7402                	ld	s0,32(sp)
    800055ec:	64e2                	ld	s1,24(sp)
    800055ee:	6942                	ld	s2,16(sp)
    800055f0:	6145                	addi	sp,sp,48
    800055f2:	8082                	ret
    return -1;
    800055f4:	557d                	li	a0,-1
    800055f6:	bfcd                	j	800055e8 <argfd+0x50>
    return -1;
    800055f8:	557d                	li	a0,-1
    800055fa:	b7fd                	j	800055e8 <argfd+0x50>
    800055fc:	557d                	li	a0,-1
    800055fe:	b7ed                	j	800055e8 <argfd+0x50>

0000000080005600 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005600:	1101                	addi	sp,sp,-32
    80005602:	ec06                	sd	ra,24(sp)
    80005604:	e822                	sd	s0,16(sp)
    80005606:	e426                	sd	s1,8(sp)
    80005608:	1000                	addi	s0,sp,32
    8000560a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000560c:	ffffc097          	auipc	ra,0xffffc
    80005610:	3e6080e7          	jalr	998(ra) # 800019f2 <myproc>
    80005614:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005616:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000561a:	4501                	li	a0,0
    8000561c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000561e:	6398                	ld	a4,0(a5)
    80005620:	cb19                	beqz	a4,80005636 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005622:	2505                	addiw	a0,a0,1
    80005624:	07a1                	addi	a5,a5,8
    80005626:	fed51ce3          	bne	a0,a3,8000561e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000562a:	557d                	li	a0,-1
}
    8000562c:	60e2                	ld	ra,24(sp)
    8000562e:	6442                	ld	s0,16(sp)
    80005630:	64a2                	ld	s1,8(sp)
    80005632:	6105                	addi	sp,sp,32
    80005634:	8082                	ret
      p->ofile[fd] = f;
    80005636:	01a50793          	addi	a5,a0,26
    8000563a:	078e                	slli	a5,a5,0x3
    8000563c:	963e                	add	a2,a2,a5
    8000563e:	e204                	sd	s1,0(a2)
      return fd;
    80005640:	b7f5                	j	8000562c <fdalloc+0x2c>

0000000080005642 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005642:	715d                	addi	sp,sp,-80
    80005644:	e486                	sd	ra,72(sp)
    80005646:	e0a2                	sd	s0,64(sp)
    80005648:	fc26                	sd	s1,56(sp)
    8000564a:	f84a                	sd	s2,48(sp)
    8000564c:	f44e                	sd	s3,40(sp)
    8000564e:	f052                	sd	s4,32(sp)
    80005650:	ec56                	sd	s5,24(sp)
    80005652:	0880                	addi	s0,sp,80
    80005654:	89ae                	mv	s3,a1
    80005656:	8ab2                	mv	s5,a2
    80005658:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000565a:	fb040593          	addi	a1,s0,-80
    8000565e:	fffff097          	auipc	ra,0xfffff
    80005662:	e82080e7          	jalr	-382(ra) # 800044e0 <nameiparent>
    80005666:	892a                	mv	s2,a0
    80005668:	12050f63          	beqz	a0,800057a6 <create+0x164>
    return 0;

  ilock(dp);
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	6a0080e7          	jalr	1696(ra) # 80003d0c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005674:	4601                	li	a2,0
    80005676:	fb040593          	addi	a1,s0,-80
    8000567a:	854a                	mv	a0,s2
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	b74080e7          	jalr	-1164(ra) # 800041f0 <dirlookup>
    80005684:	84aa                	mv	s1,a0
    80005686:	c921                	beqz	a0,800056d6 <create+0x94>
    iunlockput(dp);
    80005688:	854a                	mv	a0,s2
    8000568a:	fffff097          	auipc	ra,0xfffff
    8000568e:	8e4080e7          	jalr	-1820(ra) # 80003f6e <iunlockput>
    ilock(ip);
    80005692:	8526                	mv	a0,s1
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	678080e7          	jalr	1656(ra) # 80003d0c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000569c:	2981                	sext.w	s3,s3
    8000569e:	4789                	li	a5,2
    800056a0:	02f99463          	bne	s3,a5,800056c8 <create+0x86>
    800056a4:	0444d783          	lhu	a5,68(s1)
    800056a8:	37f9                	addiw	a5,a5,-2
    800056aa:	17c2                	slli	a5,a5,0x30
    800056ac:	93c1                	srli	a5,a5,0x30
    800056ae:	4705                	li	a4,1
    800056b0:	00f76c63          	bltu	a4,a5,800056c8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800056b4:	8526                	mv	a0,s1
    800056b6:	60a6                	ld	ra,72(sp)
    800056b8:	6406                	ld	s0,64(sp)
    800056ba:	74e2                	ld	s1,56(sp)
    800056bc:	7942                	ld	s2,48(sp)
    800056be:	79a2                	ld	s3,40(sp)
    800056c0:	7a02                	ld	s4,32(sp)
    800056c2:	6ae2                	ld	s5,24(sp)
    800056c4:	6161                	addi	sp,sp,80
    800056c6:	8082                	ret
    iunlockput(ip);
    800056c8:	8526                	mv	a0,s1
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	8a4080e7          	jalr	-1884(ra) # 80003f6e <iunlockput>
    return 0;
    800056d2:	4481                	li	s1,0
    800056d4:	b7c5                	j	800056b4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800056d6:	85ce                	mv	a1,s3
    800056d8:	00092503          	lw	a0,0(s2)
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	498080e7          	jalr	1176(ra) # 80003b74 <ialloc>
    800056e4:	84aa                	mv	s1,a0
    800056e6:	c529                	beqz	a0,80005730 <create+0xee>
  ilock(ip);
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	624080e7          	jalr	1572(ra) # 80003d0c <ilock>
  ip->major = major;
    800056f0:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800056f4:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800056f8:	4785                	li	a5,1
    800056fa:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056fe:	8526                	mv	a0,s1
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	542080e7          	jalr	1346(ra) # 80003c42 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005708:	2981                	sext.w	s3,s3
    8000570a:	4785                	li	a5,1
    8000570c:	02f98a63          	beq	s3,a5,80005740 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005710:	40d0                	lw	a2,4(s1)
    80005712:	fb040593          	addi	a1,s0,-80
    80005716:	854a                	mv	a0,s2
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	ce8080e7          	jalr	-792(ra) # 80004400 <dirlink>
    80005720:	06054b63          	bltz	a0,80005796 <create+0x154>
  iunlockput(dp);
    80005724:	854a                	mv	a0,s2
    80005726:	fffff097          	auipc	ra,0xfffff
    8000572a:	848080e7          	jalr	-1976(ra) # 80003f6e <iunlockput>
  return ip;
    8000572e:	b759                	j	800056b4 <create+0x72>
    panic("create: ialloc");
    80005730:	00003517          	auipc	a0,0x3
    80005734:	10850513          	addi	a0,a0,264 # 80008838 <syscalls+0x2b8>
    80005738:	ffffb097          	auipc	ra,0xffffb
    8000573c:	e08080e7          	jalr	-504(ra) # 80000540 <panic>
    dp->nlink++;  // for ".."
    80005740:	04a95783          	lhu	a5,74(s2)
    80005744:	2785                	addiw	a5,a5,1
    80005746:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000574a:	854a                	mv	a0,s2
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	4f6080e7          	jalr	1270(ra) # 80003c42 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005754:	40d0                	lw	a2,4(s1)
    80005756:	00003597          	auipc	a1,0x3
    8000575a:	0f258593          	addi	a1,a1,242 # 80008848 <syscalls+0x2c8>
    8000575e:	8526                	mv	a0,s1
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	ca0080e7          	jalr	-864(ra) # 80004400 <dirlink>
    80005768:	00054f63          	bltz	a0,80005786 <create+0x144>
    8000576c:	00492603          	lw	a2,4(s2)
    80005770:	00003597          	auipc	a1,0x3
    80005774:	0e058593          	addi	a1,a1,224 # 80008850 <syscalls+0x2d0>
    80005778:	8526                	mv	a0,s1
    8000577a:	fffff097          	auipc	ra,0xfffff
    8000577e:	c86080e7          	jalr	-890(ra) # 80004400 <dirlink>
    80005782:	f80557e3          	bgez	a0,80005710 <create+0xce>
      panic("create dots");
    80005786:	00003517          	auipc	a0,0x3
    8000578a:	0d250513          	addi	a0,a0,210 # 80008858 <syscalls+0x2d8>
    8000578e:	ffffb097          	auipc	ra,0xffffb
    80005792:	db2080e7          	jalr	-590(ra) # 80000540 <panic>
    panic("create: dirlink");
    80005796:	00003517          	auipc	a0,0x3
    8000579a:	0d250513          	addi	a0,a0,210 # 80008868 <syscalls+0x2e8>
    8000579e:	ffffb097          	auipc	ra,0xffffb
    800057a2:	da2080e7          	jalr	-606(ra) # 80000540 <panic>
    return 0;
    800057a6:	84aa                	mv	s1,a0
    800057a8:	b731                	j	800056b4 <create+0x72>

00000000800057aa <sys_dup>:
{
    800057aa:	7179                	addi	sp,sp,-48
    800057ac:	f406                	sd	ra,40(sp)
    800057ae:	f022                	sd	s0,32(sp)
    800057b0:	ec26                	sd	s1,24(sp)
    800057b2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057b4:	fd840613          	addi	a2,s0,-40
    800057b8:	4581                	li	a1,0
    800057ba:	4501                	li	a0,0
    800057bc:	00000097          	auipc	ra,0x0
    800057c0:	ddc080e7          	jalr	-548(ra) # 80005598 <argfd>
    return -1;
    800057c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057c6:	02054363          	bltz	a0,800057ec <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800057ca:	fd843503          	ld	a0,-40(s0)
    800057ce:	00000097          	auipc	ra,0x0
    800057d2:	e32080e7          	jalr	-462(ra) # 80005600 <fdalloc>
    800057d6:	84aa                	mv	s1,a0
    return -1;
    800057d8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800057da:	00054963          	bltz	a0,800057ec <sys_dup+0x42>
  filedup(f);
    800057de:	fd843503          	ld	a0,-40(s0)
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	376080e7          	jalr	886(ra) # 80004b58 <filedup>
  return fd;
    800057ea:	87a6                	mv	a5,s1
}
    800057ec:	853e                	mv	a0,a5
    800057ee:	70a2                	ld	ra,40(sp)
    800057f0:	7402                	ld	s0,32(sp)
    800057f2:	64e2                	ld	s1,24(sp)
    800057f4:	6145                	addi	sp,sp,48
    800057f6:	8082                	ret

00000000800057f8 <sys_read>:
{
    800057f8:	7179                	addi	sp,sp,-48
    800057fa:	f406                	sd	ra,40(sp)
    800057fc:	f022                	sd	s0,32(sp)
    800057fe:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005800:	fe840613          	addi	a2,s0,-24
    80005804:	4581                	li	a1,0
    80005806:	4501                	li	a0,0
    80005808:	00000097          	auipc	ra,0x0
    8000580c:	d90080e7          	jalr	-624(ra) # 80005598 <argfd>
    return -1;
    80005810:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005812:	04054163          	bltz	a0,80005854 <sys_read+0x5c>
    80005816:	fe440593          	addi	a1,s0,-28
    8000581a:	4509                	li	a0,2
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	918080e7          	jalr	-1768(ra) # 80003134 <argint>
    return -1;
    80005824:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005826:	02054763          	bltz	a0,80005854 <sys_read+0x5c>
    8000582a:	fd840593          	addi	a1,s0,-40
    8000582e:	4505                	li	a0,1
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	926080e7          	jalr	-1754(ra) # 80003156 <argaddr>
    return -1;
    80005838:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000583a:	00054d63          	bltz	a0,80005854 <sys_read+0x5c>
  return fileread(f, p, n);
    8000583e:	fe442603          	lw	a2,-28(s0)
    80005842:	fd843583          	ld	a1,-40(s0)
    80005846:	fe843503          	ld	a0,-24(s0)
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	49a080e7          	jalr	1178(ra) # 80004ce4 <fileread>
    80005852:	87aa                	mv	a5,a0
}
    80005854:	853e                	mv	a0,a5
    80005856:	70a2                	ld	ra,40(sp)
    80005858:	7402                	ld	s0,32(sp)
    8000585a:	6145                	addi	sp,sp,48
    8000585c:	8082                	ret

000000008000585e <sys_write>:
{
    8000585e:	7179                	addi	sp,sp,-48
    80005860:	f406                	sd	ra,40(sp)
    80005862:	f022                	sd	s0,32(sp)
    80005864:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005866:	fe840613          	addi	a2,s0,-24
    8000586a:	4581                	li	a1,0
    8000586c:	4501                	li	a0,0
    8000586e:	00000097          	auipc	ra,0x0
    80005872:	d2a080e7          	jalr	-726(ra) # 80005598 <argfd>
    return -1;
    80005876:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005878:	04054163          	bltz	a0,800058ba <sys_write+0x5c>
    8000587c:	fe440593          	addi	a1,s0,-28
    80005880:	4509                	li	a0,2
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	8b2080e7          	jalr	-1870(ra) # 80003134 <argint>
    return -1;
    8000588a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000588c:	02054763          	bltz	a0,800058ba <sys_write+0x5c>
    80005890:	fd840593          	addi	a1,s0,-40
    80005894:	4505                	li	a0,1
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	8c0080e7          	jalr	-1856(ra) # 80003156 <argaddr>
    return -1;
    8000589e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058a0:	00054d63          	bltz	a0,800058ba <sys_write+0x5c>
  return filewrite(f, p, n);
    800058a4:	fe442603          	lw	a2,-28(s0)
    800058a8:	fd843583          	ld	a1,-40(s0)
    800058ac:	fe843503          	ld	a0,-24(s0)
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	4f6080e7          	jalr	1270(ra) # 80004da6 <filewrite>
    800058b8:	87aa                	mv	a5,a0
}
    800058ba:	853e                	mv	a0,a5
    800058bc:	70a2                	ld	ra,40(sp)
    800058be:	7402                	ld	s0,32(sp)
    800058c0:	6145                	addi	sp,sp,48
    800058c2:	8082                	ret

00000000800058c4 <sys_close>:
{
    800058c4:	1101                	addi	sp,sp,-32
    800058c6:	ec06                	sd	ra,24(sp)
    800058c8:	e822                	sd	s0,16(sp)
    800058ca:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058cc:	fe040613          	addi	a2,s0,-32
    800058d0:	fec40593          	addi	a1,s0,-20
    800058d4:	4501                	li	a0,0
    800058d6:	00000097          	auipc	ra,0x0
    800058da:	cc2080e7          	jalr	-830(ra) # 80005598 <argfd>
    return -1;
    800058de:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800058e0:	02054463          	bltz	a0,80005908 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800058e4:	ffffc097          	auipc	ra,0xffffc
    800058e8:	10e080e7          	jalr	270(ra) # 800019f2 <myproc>
    800058ec:	fec42783          	lw	a5,-20(s0)
    800058f0:	07e9                	addi	a5,a5,26
    800058f2:	078e                	slli	a5,a5,0x3
    800058f4:	97aa                	add	a5,a5,a0
    800058f6:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800058fa:	fe043503          	ld	a0,-32(s0)
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	2ac080e7          	jalr	684(ra) # 80004baa <fileclose>
  return 0;
    80005906:	4781                	li	a5,0
}
    80005908:	853e                	mv	a0,a5
    8000590a:	60e2                	ld	ra,24(sp)
    8000590c:	6442                	ld	s0,16(sp)
    8000590e:	6105                	addi	sp,sp,32
    80005910:	8082                	ret

0000000080005912 <sys_fstat>:
{
    80005912:	1101                	addi	sp,sp,-32
    80005914:	ec06                	sd	ra,24(sp)
    80005916:	e822                	sd	s0,16(sp)
    80005918:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000591a:	fe840613          	addi	a2,s0,-24
    8000591e:	4581                	li	a1,0
    80005920:	4501                	li	a0,0
    80005922:	00000097          	auipc	ra,0x0
    80005926:	c76080e7          	jalr	-906(ra) # 80005598 <argfd>
    return -1;
    8000592a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000592c:	02054563          	bltz	a0,80005956 <sys_fstat+0x44>
    80005930:	fe040593          	addi	a1,s0,-32
    80005934:	4505                	li	a0,1
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	820080e7          	jalr	-2016(ra) # 80003156 <argaddr>
    return -1;
    8000593e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005940:	00054b63          	bltz	a0,80005956 <sys_fstat+0x44>
  return filestat(f, st);
    80005944:	fe043583          	ld	a1,-32(s0)
    80005948:	fe843503          	ld	a0,-24(s0)
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	326080e7          	jalr	806(ra) # 80004c72 <filestat>
    80005954:	87aa                	mv	a5,a0
}
    80005956:	853e                	mv	a0,a5
    80005958:	60e2                	ld	ra,24(sp)
    8000595a:	6442                	ld	s0,16(sp)
    8000595c:	6105                	addi	sp,sp,32
    8000595e:	8082                	ret

0000000080005960 <sys_link>:
{
    80005960:	7169                	addi	sp,sp,-304
    80005962:	f606                	sd	ra,296(sp)
    80005964:	f222                	sd	s0,288(sp)
    80005966:	ee26                	sd	s1,280(sp)
    80005968:	ea4a                	sd	s2,272(sp)
    8000596a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000596c:	08000613          	li	a2,128
    80005970:	ed040593          	addi	a1,s0,-304
    80005974:	4501                	li	a0,0
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	802080e7          	jalr	-2046(ra) # 80003178 <argstr>
    return -1;
    8000597e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005980:	10054e63          	bltz	a0,80005a9c <sys_link+0x13c>
    80005984:	08000613          	li	a2,128
    80005988:	f5040593          	addi	a1,s0,-176
    8000598c:	4505                	li	a0,1
    8000598e:	ffffd097          	auipc	ra,0xffffd
    80005992:	7ea080e7          	jalr	2026(ra) # 80003178 <argstr>
    return -1;
    80005996:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005998:	10054263          	bltz	a0,80005a9c <sys_link+0x13c>
  begin_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	d42080e7          	jalr	-702(ra) # 800046de <begin_op>
  if((ip = namei(old)) == 0){
    800059a4:	ed040513          	addi	a0,s0,-304
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	b1a080e7          	jalr	-1254(ra) # 800044c2 <namei>
    800059b0:	84aa                	mv	s1,a0
    800059b2:	c551                	beqz	a0,80005a3e <sys_link+0xde>
  ilock(ip);
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	358080e7          	jalr	856(ra) # 80003d0c <ilock>
  if(ip->type == T_DIR){
    800059bc:	04449703          	lh	a4,68(s1)
    800059c0:	4785                	li	a5,1
    800059c2:	08f70463          	beq	a4,a5,80005a4a <sys_link+0xea>
  ip->nlink++;
    800059c6:	04a4d783          	lhu	a5,74(s1)
    800059ca:	2785                	addiw	a5,a5,1
    800059cc:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059d0:	8526                	mv	a0,s1
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	270080e7          	jalr	624(ra) # 80003c42 <iupdate>
  iunlock(ip);
    800059da:	8526                	mv	a0,s1
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	3f2080e7          	jalr	1010(ra) # 80003dce <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059e4:	fd040593          	addi	a1,s0,-48
    800059e8:	f5040513          	addi	a0,s0,-176
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	af4080e7          	jalr	-1292(ra) # 800044e0 <nameiparent>
    800059f4:	892a                	mv	s2,a0
    800059f6:	c935                	beqz	a0,80005a6a <sys_link+0x10a>
  ilock(dp);
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	314080e7          	jalr	788(ra) # 80003d0c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a00:	00092703          	lw	a4,0(s2)
    80005a04:	409c                	lw	a5,0(s1)
    80005a06:	04f71d63          	bne	a4,a5,80005a60 <sys_link+0x100>
    80005a0a:	40d0                	lw	a2,4(s1)
    80005a0c:	fd040593          	addi	a1,s0,-48
    80005a10:	854a                	mv	a0,s2
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	9ee080e7          	jalr	-1554(ra) # 80004400 <dirlink>
    80005a1a:	04054363          	bltz	a0,80005a60 <sys_link+0x100>
  iunlockput(dp);
    80005a1e:	854a                	mv	a0,s2
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	54e080e7          	jalr	1358(ra) # 80003f6e <iunlockput>
  iput(ip);
    80005a28:	8526                	mv	a0,s1
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	49c080e7          	jalr	1180(ra) # 80003ec6 <iput>
  end_op();
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	d2c080e7          	jalr	-724(ra) # 8000475e <end_op>
  return 0;
    80005a3a:	4781                	li	a5,0
    80005a3c:	a085                	j	80005a9c <sys_link+0x13c>
    end_op();
    80005a3e:	fffff097          	auipc	ra,0xfffff
    80005a42:	d20080e7          	jalr	-736(ra) # 8000475e <end_op>
    return -1;
    80005a46:	57fd                	li	a5,-1
    80005a48:	a891                	j	80005a9c <sys_link+0x13c>
    iunlockput(ip);
    80005a4a:	8526                	mv	a0,s1
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	522080e7          	jalr	1314(ra) # 80003f6e <iunlockput>
    end_op();
    80005a54:	fffff097          	auipc	ra,0xfffff
    80005a58:	d0a080e7          	jalr	-758(ra) # 8000475e <end_op>
    return -1;
    80005a5c:	57fd                	li	a5,-1
    80005a5e:	a83d                	j	80005a9c <sys_link+0x13c>
    iunlockput(dp);
    80005a60:	854a                	mv	a0,s2
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	50c080e7          	jalr	1292(ra) # 80003f6e <iunlockput>
  ilock(ip);
    80005a6a:	8526                	mv	a0,s1
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	2a0080e7          	jalr	672(ra) # 80003d0c <ilock>
  ip->nlink--;
    80005a74:	04a4d783          	lhu	a5,74(s1)
    80005a78:	37fd                	addiw	a5,a5,-1
    80005a7a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a7e:	8526                	mv	a0,s1
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	1c2080e7          	jalr	450(ra) # 80003c42 <iupdate>
  iunlockput(ip);
    80005a88:	8526                	mv	a0,s1
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	4e4080e7          	jalr	1252(ra) # 80003f6e <iunlockput>
  end_op();
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	ccc080e7          	jalr	-820(ra) # 8000475e <end_op>
  return -1;
    80005a9a:	57fd                	li	a5,-1
}
    80005a9c:	853e                	mv	a0,a5
    80005a9e:	70b2                	ld	ra,296(sp)
    80005aa0:	7412                	ld	s0,288(sp)
    80005aa2:	64f2                	ld	s1,280(sp)
    80005aa4:	6952                	ld	s2,272(sp)
    80005aa6:	6155                	addi	sp,sp,304
    80005aa8:	8082                	ret

0000000080005aaa <sys_unlink>:
{
    80005aaa:	7151                	addi	sp,sp,-240
    80005aac:	f586                	sd	ra,232(sp)
    80005aae:	f1a2                	sd	s0,224(sp)
    80005ab0:	eda6                	sd	s1,216(sp)
    80005ab2:	e9ca                	sd	s2,208(sp)
    80005ab4:	e5ce                	sd	s3,200(sp)
    80005ab6:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005ab8:	08000613          	li	a2,128
    80005abc:	f3040593          	addi	a1,s0,-208
    80005ac0:	4501                	li	a0,0
    80005ac2:	ffffd097          	auipc	ra,0xffffd
    80005ac6:	6b6080e7          	jalr	1718(ra) # 80003178 <argstr>
    80005aca:	18054163          	bltz	a0,80005c4c <sys_unlink+0x1a2>
  begin_op();
    80005ace:	fffff097          	auipc	ra,0xfffff
    80005ad2:	c10080e7          	jalr	-1008(ra) # 800046de <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ad6:	fb040593          	addi	a1,s0,-80
    80005ada:	f3040513          	addi	a0,s0,-208
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	a02080e7          	jalr	-1534(ra) # 800044e0 <nameiparent>
    80005ae6:	84aa                	mv	s1,a0
    80005ae8:	c979                	beqz	a0,80005bbe <sys_unlink+0x114>
  ilock(dp);
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	222080e7          	jalr	546(ra) # 80003d0c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005af2:	00003597          	auipc	a1,0x3
    80005af6:	d5658593          	addi	a1,a1,-682 # 80008848 <syscalls+0x2c8>
    80005afa:	fb040513          	addi	a0,s0,-80
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	6d8080e7          	jalr	1752(ra) # 800041d6 <namecmp>
    80005b06:	14050a63          	beqz	a0,80005c5a <sys_unlink+0x1b0>
    80005b0a:	00003597          	auipc	a1,0x3
    80005b0e:	d4658593          	addi	a1,a1,-698 # 80008850 <syscalls+0x2d0>
    80005b12:	fb040513          	addi	a0,s0,-80
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	6c0080e7          	jalr	1728(ra) # 800041d6 <namecmp>
    80005b1e:	12050e63          	beqz	a0,80005c5a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b22:	f2c40613          	addi	a2,s0,-212
    80005b26:	fb040593          	addi	a1,s0,-80
    80005b2a:	8526                	mv	a0,s1
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	6c4080e7          	jalr	1732(ra) # 800041f0 <dirlookup>
    80005b34:	892a                	mv	s2,a0
    80005b36:	12050263          	beqz	a0,80005c5a <sys_unlink+0x1b0>
  ilock(ip);
    80005b3a:	ffffe097          	auipc	ra,0xffffe
    80005b3e:	1d2080e7          	jalr	466(ra) # 80003d0c <ilock>
  if(ip->nlink < 1)
    80005b42:	04a91783          	lh	a5,74(s2)
    80005b46:	08f05263          	blez	a5,80005bca <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b4a:	04491703          	lh	a4,68(s2)
    80005b4e:	4785                	li	a5,1
    80005b50:	08f70563          	beq	a4,a5,80005bda <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b54:	4641                	li	a2,16
    80005b56:	4581                	li	a1,0
    80005b58:	fc040513          	addi	a0,s0,-64
    80005b5c:	ffffb097          	auipc	ra,0xffffb
    80005b60:	186080e7          	jalr	390(ra) # 80000ce2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b64:	4741                	li	a4,16
    80005b66:	f2c42683          	lw	a3,-212(s0)
    80005b6a:	fc040613          	addi	a2,s0,-64
    80005b6e:	4581                	li	a1,0
    80005b70:	8526                	mv	a0,s1
    80005b72:	ffffe097          	auipc	ra,0xffffe
    80005b76:	546080e7          	jalr	1350(ra) # 800040b8 <writei>
    80005b7a:	47c1                	li	a5,16
    80005b7c:	0af51563          	bne	a0,a5,80005c26 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b80:	04491703          	lh	a4,68(s2)
    80005b84:	4785                	li	a5,1
    80005b86:	0af70863          	beq	a4,a5,80005c36 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b8a:	8526                	mv	a0,s1
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	3e2080e7          	jalr	994(ra) # 80003f6e <iunlockput>
  ip->nlink--;
    80005b94:	04a95783          	lhu	a5,74(s2)
    80005b98:	37fd                	addiw	a5,a5,-1
    80005b9a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b9e:	854a                	mv	a0,s2
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	0a2080e7          	jalr	162(ra) # 80003c42 <iupdate>
  iunlockput(ip);
    80005ba8:	854a                	mv	a0,s2
    80005baa:	ffffe097          	auipc	ra,0xffffe
    80005bae:	3c4080e7          	jalr	964(ra) # 80003f6e <iunlockput>
  end_op();
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	bac080e7          	jalr	-1108(ra) # 8000475e <end_op>
  return 0;
    80005bba:	4501                	li	a0,0
    80005bbc:	a84d                	j	80005c6e <sys_unlink+0x1c4>
    end_op();
    80005bbe:	fffff097          	auipc	ra,0xfffff
    80005bc2:	ba0080e7          	jalr	-1120(ra) # 8000475e <end_op>
    return -1;
    80005bc6:	557d                	li	a0,-1
    80005bc8:	a05d                	j	80005c6e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005bca:	00003517          	auipc	a0,0x3
    80005bce:	cae50513          	addi	a0,a0,-850 # 80008878 <syscalls+0x2f8>
    80005bd2:	ffffb097          	auipc	ra,0xffffb
    80005bd6:	96e080e7          	jalr	-1682(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bda:	04c92703          	lw	a4,76(s2)
    80005bde:	02000793          	li	a5,32
    80005be2:	f6e7f9e3          	bgeu	a5,a4,80005b54 <sys_unlink+0xaa>
    80005be6:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bea:	4741                	li	a4,16
    80005bec:	86ce                	mv	a3,s3
    80005bee:	f1840613          	addi	a2,s0,-232
    80005bf2:	4581                	li	a1,0
    80005bf4:	854a                	mv	a0,s2
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	3ca080e7          	jalr	970(ra) # 80003fc0 <readi>
    80005bfe:	47c1                	li	a5,16
    80005c00:	00f51b63          	bne	a0,a5,80005c16 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c04:	f1845783          	lhu	a5,-232(s0)
    80005c08:	e7a1                	bnez	a5,80005c50 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c0a:	29c1                	addiw	s3,s3,16
    80005c0c:	04c92783          	lw	a5,76(s2)
    80005c10:	fcf9ede3          	bltu	s3,a5,80005bea <sys_unlink+0x140>
    80005c14:	b781                	j	80005b54 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c16:	00003517          	auipc	a0,0x3
    80005c1a:	c7a50513          	addi	a0,a0,-902 # 80008890 <syscalls+0x310>
    80005c1e:	ffffb097          	auipc	ra,0xffffb
    80005c22:	922080e7          	jalr	-1758(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005c26:	00003517          	auipc	a0,0x3
    80005c2a:	c8250513          	addi	a0,a0,-894 # 800088a8 <syscalls+0x328>
    80005c2e:	ffffb097          	auipc	ra,0xffffb
    80005c32:	912080e7          	jalr	-1774(ra) # 80000540 <panic>
    dp->nlink--;
    80005c36:	04a4d783          	lhu	a5,74(s1)
    80005c3a:	37fd                	addiw	a5,a5,-1
    80005c3c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c40:	8526                	mv	a0,s1
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	000080e7          	jalr	ra # 80003c42 <iupdate>
    80005c4a:	b781                	j	80005b8a <sys_unlink+0xe0>
    return -1;
    80005c4c:	557d                	li	a0,-1
    80005c4e:	a005                	j	80005c6e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c50:	854a                	mv	a0,s2
    80005c52:	ffffe097          	auipc	ra,0xffffe
    80005c56:	31c080e7          	jalr	796(ra) # 80003f6e <iunlockput>
  iunlockput(dp);
    80005c5a:	8526                	mv	a0,s1
    80005c5c:	ffffe097          	auipc	ra,0xffffe
    80005c60:	312080e7          	jalr	786(ra) # 80003f6e <iunlockput>
  end_op();
    80005c64:	fffff097          	auipc	ra,0xfffff
    80005c68:	afa080e7          	jalr	-1286(ra) # 8000475e <end_op>
  return -1;
    80005c6c:	557d                	li	a0,-1
}
    80005c6e:	70ae                	ld	ra,232(sp)
    80005c70:	740e                	ld	s0,224(sp)
    80005c72:	64ee                	ld	s1,216(sp)
    80005c74:	694e                	ld	s2,208(sp)
    80005c76:	69ae                	ld	s3,200(sp)
    80005c78:	616d                	addi	sp,sp,240
    80005c7a:	8082                	ret

0000000080005c7c <sys_open>:

uint64
sys_open(void)
{
    80005c7c:	7131                	addi	sp,sp,-192
    80005c7e:	fd06                	sd	ra,184(sp)
    80005c80:	f922                	sd	s0,176(sp)
    80005c82:	f526                	sd	s1,168(sp)
    80005c84:	f14a                	sd	s2,160(sp)
    80005c86:	ed4e                	sd	s3,152(sp)
    80005c88:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c8a:	08000613          	li	a2,128
    80005c8e:	f5040593          	addi	a1,s0,-176
    80005c92:	4501                	li	a0,0
    80005c94:	ffffd097          	auipc	ra,0xffffd
    80005c98:	4e4080e7          	jalr	1252(ra) # 80003178 <argstr>
    return -1;
    80005c9c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c9e:	0c054163          	bltz	a0,80005d60 <sys_open+0xe4>
    80005ca2:	f4c40593          	addi	a1,s0,-180
    80005ca6:	4505                	li	a0,1
    80005ca8:	ffffd097          	auipc	ra,0xffffd
    80005cac:	48c080e7          	jalr	1164(ra) # 80003134 <argint>
    80005cb0:	0a054863          	bltz	a0,80005d60 <sys_open+0xe4>

  begin_op();
    80005cb4:	fffff097          	auipc	ra,0xfffff
    80005cb8:	a2a080e7          	jalr	-1494(ra) # 800046de <begin_op>

  if(omode & O_CREATE){
    80005cbc:	f4c42783          	lw	a5,-180(s0)
    80005cc0:	2007f793          	andi	a5,a5,512
    80005cc4:	cbdd                	beqz	a5,80005d7a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005cc6:	4681                	li	a3,0
    80005cc8:	4601                	li	a2,0
    80005cca:	4589                	li	a1,2
    80005ccc:	f5040513          	addi	a0,s0,-176
    80005cd0:	00000097          	auipc	ra,0x0
    80005cd4:	972080e7          	jalr	-1678(ra) # 80005642 <create>
    80005cd8:	892a                	mv	s2,a0
    if(ip == 0){
    80005cda:	c959                	beqz	a0,80005d70 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005cdc:	04491703          	lh	a4,68(s2)
    80005ce0:	478d                	li	a5,3
    80005ce2:	00f71763          	bne	a4,a5,80005cf0 <sys_open+0x74>
    80005ce6:	04695703          	lhu	a4,70(s2)
    80005cea:	47a5                	li	a5,9
    80005cec:	0ce7ec63          	bltu	a5,a4,80005dc4 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005cf0:	fffff097          	auipc	ra,0xfffff
    80005cf4:	dfe080e7          	jalr	-514(ra) # 80004aee <filealloc>
    80005cf8:	89aa                	mv	s3,a0
    80005cfa:	10050263          	beqz	a0,80005dfe <sys_open+0x182>
    80005cfe:	00000097          	auipc	ra,0x0
    80005d02:	902080e7          	jalr	-1790(ra) # 80005600 <fdalloc>
    80005d06:	84aa                	mv	s1,a0
    80005d08:	0e054663          	bltz	a0,80005df4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d0c:	04491703          	lh	a4,68(s2)
    80005d10:	478d                	li	a5,3
    80005d12:	0cf70463          	beq	a4,a5,80005dda <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d16:	4789                	li	a5,2
    80005d18:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d1c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d20:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d24:	f4c42783          	lw	a5,-180(s0)
    80005d28:	0017c713          	xori	a4,a5,1
    80005d2c:	8b05                	andi	a4,a4,1
    80005d2e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d32:	0037f713          	andi	a4,a5,3
    80005d36:	00e03733          	snez	a4,a4
    80005d3a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d3e:	4007f793          	andi	a5,a5,1024
    80005d42:	c791                	beqz	a5,80005d4e <sys_open+0xd2>
    80005d44:	04491703          	lh	a4,68(s2)
    80005d48:	4789                	li	a5,2
    80005d4a:	08f70f63          	beq	a4,a5,80005de8 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d4e:	854a                	mv	a0,s2
    80005d50:	ffffe097          	auipc	ra,0xffffe
    80005d54:	07e080e7          	jalr	126(ra) # 80003dce <iunlock>
  end_op();
    80005d58:	fffff097          	auipc	ra,0xfffff
    80005d5c:	a06080e7          	jalr	-1530(ra) # 8000475e <end_op>

  return fd;
}
    80005d60:	8526                	mv	a0,s1
    80005d62:	70ea                	ld	ra,184(sp)
    80005d64:	744a                	ld	s0,176(sp)
    80005d66:	74aa                	ld	s1,168(sp)
    80005d68:	790a                	ld	s2,160(sp)
    80005d6a:	69ea                	ld	s3,152(sp)
    80005d6c:	6129                	addi	sp,sp,192
    80005d6e:	8082                	ret
      end_op();
    80005d70:	fffff097          	auipc	ra,0xfffff
    80005d74:	9ee080e7          	jalr	-1554(ra) # 8000475e <end_op>
      return -1;
    80005d78:	b7e5                	j	80005d60 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d7a:	f5040513          	addi	a0,s0,-176
    80005d7e:	ffffe097          	auipc	ra,0xffffe
    80005d82:	744080e7          	jalr	1860(ra) # 800044c2 <namei>
    80005d86:	892a                	mv	s2,a0
    80005d88:	c905                	beqz	a0,80005db8 <sys_open+0x13c>
    ilock(ip);
    80005d8a:	ffffe097          	auipc	ra,0xffffe
    80005d8e:	f82080e7          	jalr	-126(ra) # 80003d0c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d92:	04491703          	lh	a4,68(s2)
    80005d96:	4785                	li	a5,1
    80005d98:	f4f712e3          	bne	a4,a5,80005cdc <sys_open+0x60>
    80005d9c:	f4c42783          	lw	a5,-180(s0)
    80005da0:	dba1                	beqz	a5,80005cf0 <sys_open+0x74>
      iunlockput(ip);
    80005da2:	854a                	mv	a0,s2
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	1ca080e7          	jalr	458(ra) # 80003f6e <iunlockput>
      end_op();
    80005dac:	fffff097          	auipc	ra,0xfffff
    80005db0:	9b2080e7          	jalr	-1614(ra) # 8000475e <end_op>
      return -1;
    80005db4:	54fd                	li	s1,-1
    80005db6:	b76d                	j	80005d60 <sys_open+0xe4>
      end_op();
    80005db8:	fffff097          	auipc	ra,0xfffff
    80005dbc:	9a6080e7          	jalr	-1626(ra) # 8000475e <end_op>
      return -1;
    80005dc0:	54fd                	li	s1,-1
    80005dc2:	bf79                	j	80005d60 <sys_open+0xe4>
    iunlockput(ip);
    80005dc4:	854a                	mv	a0,s2
    80005dc6:	ffffe097          	auipc	ra,0xffffe
    80005dca:	1a8080e7          	jalr	424(ra) # 80003f6e <iunlockput>
    end_op();
    80005dce:	fffff097          	auipc	ra,0xfffff
    80005dd2:	990080e7          	jalr	-1648(ra) # 8000475e <end_op>
    return -1;
    80005dd6:	54fd                	li	s1,-1
    80005dd8:	b761                	j	80005d60 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005dda:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005dde:	04691783          	lh	a5,70(s2)
    80005de2:	02f99223          	sh	a5,36(s3)
    80005de6:	bf2d                	j	80005d20 <sys_open+0xa4>
    itrunc(ip);
    80005de8:	854a                	mv	a0,s2
    80005dea:	ffffe097          	auipc	ra,0xffffe
    80005dee:	030080e7          	jalr	48(ra) # 80003e1a <itrunc>
    80005df2:	bfb1                	j	80005d4e <sys_open+0xd2>
      fileclose(f);
    80005df4:	854e                	mv	a0,s3
    80005df6:	fffff097          	auipc	ra,0xfffff
    80005dfa:	db4080e7          	jalr	-588(ra) # 80004baa <fileclose>
    iunlockput(ip);
    80005dfe:	854a                	mv	a0,s2
    80005e00:	ffffe097          	auipc	ra,0xffffe
    80005e04:	16e080e7          	jalr	366(ra) # 80003f6e <iunlockput>
    end_op();
    80005e08:	fffff097          	auipc	ra,0xfffff
    80005e0c:	956080e7          	jalr	-1706(ra) # 8000475e <end_op>
    return -1;
    80005e10:	54fd                	li	s1,-1
    80005e12:	b7b9                	j	80005d60 <sys_open+0xe4>

0000000080005e14 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e14:	7175                	addi	sp,sp,-144
    80005e16:	e506                	sd	ra,136(sp)
    80005e18:	e122                	sd	s0,128(sp)
    80005e1a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e1c:	fffff097          	auipc	ra,0xfffff
    80005e20:	8c2080e7          	jalr	-1854(ra) # 800046de <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e24:	08000613          	li	a2,128
    80005e28:	f7040593          	addi	a1,s0,-144
    80005e2c:	4501                	li	a0,0
    80005e2e:	ffffd097          	auipc	ra,0xffffd
    80005e32:	34a080e7          	jalr	842(ra) # 80003178 <argstr>
    80005e36:	02054963          	bltz	a0,80005e68 <sys_mkdir+0x54>
    80005e3a:	4681                	li	a3,0
    80005e3c:	4601                	li	a2,0
    80005e3e:	4585                	li	a1,1
    80005e40:	f7040513          	addi	a0,s0,-144
    80005e44:	fffff097          	auipc	ra,0xfffff
    80005e48:	7fe080e7          	jalr	2046(ra) # 80005642 <create>
    80005e4c:	cd11                	beqz	a0,80005e68 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	120080e7          	jalr	288(ra) # 80003f6e <iunlockput>
  end_op();
    80005e56:	fffff097          	auipc	ra,0xfffff
    80005e5a:	908080e7          	jalr	-1784(ra) # 8000475e <end_op>
  return 0;
    80005e5e:	4501                	li	a0,0
}
    80005e60:	60aa                	ld	ra,136(sp)
    80005e62:	640a                	ld	s0,128(sp)
    80005e64:	6149                	addi	sp,sp,144
    80005e66:	8082                	ret
    end_op();
    80005e68:	fffff097          	auipc	ra,0xfffff
    80005e6c:	8f6080e7          	jalr	-1802(ra) # 8000475e <end_op>
    return -1;
    80005e70:	557d                	li	a0,-1
    80005e72:	b7fd                	j	80005e60 <sys_mkdir+0x4c>

0000000080005e74 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e74:	7135                	addi	sp,sp,-160
    80005e76:	ed06                	sd	ra,152(sp)
    80005e78:	e922                	sd	s0,144(sp)
    80005e7a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e7c:	fffff097          	auipc	ra,0xfffff
    80005e80:	862080e7          	jalr	-1950(ra) # 800046de <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e84:	08000613          	li	a2,128
    80005e88:	f7040593          	addi	a1,s0,-144
    80005e8c:	4501                	li	a0,0
    80005e8e:	ffffd097          	auipc	ra,0xffffd
    80005e92:	2ea080e7          	jalr	746(ra) # 80003178 <argstr>
    80005e96:	04054a63          	bltz	a0,80005eea <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e9a:	f6c40593          	addi	a1,s0,-148
    80005e9e:	4505                	li	a0,1
    80005ea0:	ffffd097          	auipc	ra,0xffffd
    80005ea4:	294080e7          	jalr	660(ra) # 80003134 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ea8:	04054163          	bltz	a0,80005eea <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005eac:	f6840593          	addi	a1,s0,-152
    80005eb0:	4509                	li	a0,2
    80005eb2:	ffffd097          	auipc	ra,0xffffd
    80005eb6:	282080e7          	jalr	642(ra) # 80003134 <argint>
     argint(1, &major) < 0 ||
    80005eba:	02054863          	bltz	a0,80005eea <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ebe:	f6841683          	lh	a3,-152(s0)
    80005ec2:	f6c41603          	lh	a2,-148(s0)
    80005ec6:	458d                	li	a1,3
    80005ec8:	f7040513          	addi	a0,s0,-144
    80005ecc:	fffff097          	auipc	ra,0xfffff
    80005ed0:	776080e7          	jalr	1910(ra) # 80005642 <create>
     argint(2, &minor) < 0 ||
    80005ed4:	c919                	beqz	a0,80005eea <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ed6:	ffffe097          	auipc	ra,0xffffe
    80005eda:	098080e7          	jalr	152(ra) # 80003f6e <iunlockput>
  end_op();
    80005ede:	fffff097          	auipc	ra,0xfffff
    80005ee2:	880080e7          	jalr	-1920(ra) # 8000475e <end_op>
  return 0;
    80005ee6:	4501                	li	a0,0
    80005ee8:	a031                	j	80005ef4 <sys_mknod+0x80>
    end_op();
    80005eea:	fffff097          	auipc	ra,0xfffff
    80005eee:	874080e7          	jalr	-1932(ra) # 8000475e <end_op>
    return -1;
    80005ef2:	557d                	li	a0,-1
}
    80005ef4:	60ea                	ld	ra,152(sp)
    80005ef6:	644a                	ld	s0,144(sp)
    80005ef8:	610d                	addi	sp,sp,160
    80005efa:	8082                	ret

0000000080005efc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005efc:	7135                	addi	sp,sp,-160
    80005efe:	ed06                	sd	ra,152(sp)
    80005f00:	e922                	sd	s0,144(sp)
    80005f02:	e526                	sd	s1,136(sp)
    80005f04:	e14a                	sd	s2,128(sp)
    80005f06:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f08:	ffffc097          	auipc	ra,0xffffc
    80005f0c:	aea080e7          	jalr	-1302(ra) # 800019f2 <myproc>
    80005f10:	892a                	mv	s2,a0
  
  begin_op();
    80005f12:	ffffe097          	auipc	ra,0xffffe
    80005f16:	7cc080e7          	jalr	1996(ra) # 800046de <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f1a:	08000613          	li	a2,128
    80005f1e:	f6040593          	addi	a1,s0,-160
    80005f22:	4501                	li	a0,0
    80005f24:	ffffd097          	auipc	ra,0xffffd
    80005f28:	254080e7          	jalr	596(ra) # 80003178 <argstr>
    80005f2c:	04054b63          	bltz	a0,80005f82 <sys_chdir+0x86>
    80005f30:	f6040513          	addi	a0,s0,-160
    80005f34:	ffffe097          	auipc	ra,0xffffe
    80005f38:	58e080e7          	jalr	1422(ra) # 800044c2 <namei>
    80005f3c:	84aa                	mv	s1,a0
    80005f3e:	c131                	beqz	a0,80005f82 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f40:	ffffe097          	auipc	ra,0xffffe
    80005f44:	dcc080e7          	jalr	-564(ra) # 80003d0c <ilock>
  if(ip->type != T_DIR){
    80005f48:	04449703          	lh	a4,68(s1)
    80005f4c:	4785                	li	a5,1
    80005f4e:	04f71063          	bne	a4,a5,80005f8e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f52:	8526                	mv	a0,s1
    80005f54:	ffffe097          	auipc	ra,0xffffe
    80005f58:	e7a080e7          	jalr	-390(ra) # 80003dce <iunlock>
  iput(p->cwd);
    80005f5c:	15093503          	ld	a0,336(s2)
    80005f60:	ffffe097          	auipc	ra,0xffffe
    80005f64:	f66080e7          	jalr	-154(ra) # 80003ec6 <iput>
  end_op();
    80005f68:	ffffe097          	auipc	ra,0xffffe
    80005f6c:	7f6080e7          	jalr	2038(ra) # 8000475e <end_op>
  p->cwd = ip;
    80005f70:	14993823          	sd	s1,336(s2)
  return 0;
    80005f74:	4501                	li	a0,0
}
    80005f76:	60ea                	ld	ra,152(sp)
    80005f78:	644a                	ld	s0,144(sp)
    80005f7a:	64aa                	ld	s1,136(sp)
    80005f7c:	690a                	ld	s2,128(sp)
    80005f7e:	610d                	addi	sp,sp,160
    80005f80:	8082                	ret
    end_op();
    80005f82:	ffffe097          	auipc	ra,0xffffe
    80005f86:	7dc080e7          	jalr	2012(ra) # 8000475e <end_op>
    return -1;
    80005f8a:	557d                	li	a0,-1
    80005f8c:	b7ed                	j	80005f76 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f8e:	8526                	mv	a0,s1
    80005f90:	ffffe097          	auipc	ra,0xffffe
    80005f94:	fde080e7          	jalr	-34(ra) # 80003f6e <iunlockput>
    end_op();
    80005f98:	ffffe097          	auipc	ra,0xffffe
    80005f9c:	7c6080e7          	jalr	1990(ra) # 8000475e <end_op>
    return -1;
    80005fa0:	557d                	li	a0,-1
    80005fa2:	bfd1                	j	80005f76 <sys_chdir+0x7a>

0000000080005fa4 <sys_exec>:

uint64
sys_exec(void)
{
    80005fa4:	7145                	addi	sp,sp,-464
    80005fa6:	e786                	sd	ra,456(sp)
    80005fa8:	e3a2                	sd	s0,448(sp)
    80005faa:	ff26                	sd	s1,440(sp)
    80005fac:	fb4a                	sd	s2,432(sp)
    80005fae:	f74e                	sd	s3,424(sp)
    80005fb0:	f352                	sd	s4,416(sp)
    80005fb2:	ef56                	sd	s5,408(sp)
    80005fb4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fb6:	08000613          	li	a2,128
    80005fba:	f4040593          	addi	a1,s0,-192
    80005fbe:	4501                	li	a0,0
    80005fc0:	ffffd097          	auipc	ra,0xffffd
    80005fc4:	1b8080e7          	jalr	440(ra) # 80003178 <argstr>
    return -1;
    80005fc8:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fca:	0c054a63          	bltz	a0,8000609e <sys_exec+0xfa>
    80005fce:	e3840593          	addi	a1,s0,-456
    80005fd2:	4505                	li	a0,1
    80005fd4:	ffffd097          	auipc	ra,0xffffd
    80005fd8:	182080e7          	jalr	386(ra) # 80003156 <argaddr>
    80005fdc:	0c054163          	bltz	a0,8000609e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005fe0:	10000613          	li	a2,256
    80005fe4:	4581                	li	a1,0
    80005fe6:	e4040513          	addi	a0,s0,-448
    80005fea:	ffffb097          	auipc	ra,0xffffb
    80005fee:	cf8080e7          	jalr	-776(ra) # 80000ce2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ff2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ff6:	89a6                	mv	s3,s1
    80005ff8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ffa:	02000a13          	li	s4,32
    80005ffe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006002:	00391513          	slli	a0,s2,0x3
    80006006:	e3040593          	addi	a1,s0,-464
    8000600a:	e3843783          	ld	a5,-456(s0)
    8000600e:	953e                	add	a0,a0,a5
    80006010:	ffffd097          	auipc	ra,0xffffd
    80006014:	08a080e7          	jalr	138(ra) # 8000309a <fetchaddr>
    80006018:	02054a63          	bltz	a0,8000604c <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    8000601c:	e3043783          	ld	a5,-464(s0)
    80006020:	c3b9                	beqz	a5,80006066 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006022:	ffffb097          	auipc	ra,0xffffb
    80006026:	ad4080e7          	jalr	-1324(ra) # 80000af6 <kalloc>
    8000602a:	85aa                	mv	a1,a0
    8000602c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006030:	cd11                	beqz	a0,8000604c <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006032:	6605                	lui	a2,0x1
    80006034:	e3043503          	ld	a0,-464(s0)
    80006038:	ffffd097          	auipc	ra,0xffffd
    8000603c:	0b4080e7          	jalr	180(ra) # 800030ec <fetchstr>
    80006040:	00054663          	bltz	a0,8000604c <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006044:	0905                	addi	s2,s2,1
    80006046:	09a1                	addi	s3,s3,8
    80006048:	fb491be3          	bne	s2,s4,80005ffe <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000604c:	10048913          	addi	s2,s1,256
    80006050:	6088                	ld	a0,0(s1)
    80006052:	c529                	beqz	a0,8000609c <sys_exec+0xf8>
    kfree(argv[i]);
    80006054:	ffffb097          	auipc	ra,0xffffb
    80006058:	9a6080e7          	jalr	-1626(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000605c:	04a1                	addi	s1,s1,8
    8000605e:	ff2499e3          	bne	s1,s2,80006050 <sys_exec+0xac>
  return -1;
    80006062:	597d                	li	s2,-1
    80006064:	a82d                	j	8000609e <sys_exec+0xfa>
      argv[i] = 0;
    80006066:	0a8e                	slli	s5,s5,0x3
    80006068:	fc040793          	addi	a5,s0,-64
    8000606c:	9abe                	add	s5,s5,a5
    8000606e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006072:	e4040593          	addi	a1,s0,-448
    80006076:	f4040513          	addi	a0,s0,-192
    8000607a:	fffff097          	auipc	ra,0xfffff
    8000607e:	194080e7          	jalr	404(ra) # 8000520e <exec>
    80006082:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006084:	10048993          	addi	s3,s1,256
    80006088:	6088                	ld	a0,0(s1)
    8000608a:	c911                	beqz	a0,8000609e <sys_exec+0xfa>
    kfree(argv[i]);
    8000608c:	ffffb097          	auipc	ra,0xffffb
    80006090:	96e080e7          	jalr	-1682(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006094:	04a1                	addi	s1,s1,8
    80006096:	ff3499e3          	bne	s1,s3,80006088 <sys_exec+0xe4>
    8000609a:	a011                	j	8000609e <sys_exec+0xfa>
  return -1;
    8000609c:	597d                	li	s2,-1
}
    8000609e:	854a                	mv	a0,s2
    800060a0:	60be                	ld	ra,456(sp)
    800060a2:	641e                	ld	s0,448(sp)
    800060a4:	74fa                	ld	s1,440(sp)
    800060a6:	795a                	ld	s2,432(sp)
    800060a8:	79ba                	ld	s3,424(sp)
    800060aa:	7a1a                	ld	s4,416(sp)
    800060ac:	6afa                	ld	s5,408(sp)
    800060ae:	6179                	addi	sp,sp,464
    800060b0:	8082                	ret

00000000800060b2 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060b2:	7139                	addi	sp,sp,-64
    800060b4:	fc06                	sd	ra,56(sp)
    800060b6:	f822                	sd	s0,48(sp)
    800060b8:	f426                	sd	s1,40(sp)
    800060ba:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060bc:	ffffc097          	auipc	ra,0xffffc
    800060c0:	936080e7          	jalr	-1738(ra) # 800019f2 <myproc>
    800060c4:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800060c6:	fd840593          	addi	a1,s0,-40
    800060ca:	4501                	li	a0,0
    800060cc:	ffffd097          	auipc	ra,0xffffd
    800060d0:	08a080e7          	jalr	138(ra) # 80003156 <argaddr>
    return -1;
    800060d4:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    800060d6:	0e054063          	bltz	a0,800061b6 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    800060da:	fc840593          	addi	a1,s0,-56
    800060de:	fd040513          	addi	a0,s0,-48
    800060e2:	fffff097          	auipc	ra,0xfffff
    800060e6:	df8080e7          	jalr	-520(ra) # 80004eda <pipealloc>
    return -1;
    800060ea:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800060ec:	0c054563          	bltz	a0,800061b6 <sys_pipe+0x104>
  fd0 = -1;
    800060f0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800060f4:	fd043503          	ld	a0,-48(s0)
    800060f8:	fffff097          	auipc	ra,0xfffff
    800060fc:	508080e7          	jalr	1288(ra) # 80005600 <fdalloc>
    80006100:	fca42223          	sw	a0,-60(s0)
    80006104:	08054c63          	bltz	a0,8000619c <sys_pipe+0xea>
    80006108:	fc843503          	ld	a0,-56(s0)
    8000610c:	fffff097          	auipc	ra,0xfffff
    80006110:	4f4080e7          	jalr	1268(ra) # 80005600 <fdalloc>
    80006114:	fca42023          	sw	a0,-64(s0)
    80006118:	06054863          	bltz	a0,80006188 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000611c:	4691                	li	a3,4
    8000611e:	fc440613          	addi	a2,s0,-60
    80006122:	fd843583          	ld	a1,-40(s0)
    80006126:	68a8                	ld	a0,80(s1)
    80006128:	ffffb097          	auipc	ra,0xffffb
    8000612c:	54c080e7          	jalr	1356(ra) # 80001674 <copyout>
    80006130:	02054063          	bltz	a0,80006150 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006134:	4691                	li	a3,4
    80006136:	fc040613          	addi	a2,s0,-64
    8000613a:	fd843583          	ld	a1,-40(s0)
    8000613e:	0591                	addi	a1,a1,4
    80006140:	68a8                	ld	a0,80(s1)
    80006142:	ffffb097          	auipc	ra,0xffffb
    80006146:	532080e7          	jalr	1330(ra) # 80001674 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000614a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000614c:	06055563          	bgez	a0,800061b6 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006150:	fc442783          	lw	a5,-60(s0)
    80006154:	07e9                	addi	a5,a5,26
    80006156:	078e                	slli	a5,a5,0x3
    80006158:	97a6                	add	a5,a5,s1
    8000615a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000615e:	fc042503          	lw	a0,-64(s0)
    80006162:	0569                	addi	a0,a0,26
    80006164:	050e                	slli	a0,a0,0x3
    80006166:	9526                	add	a0,a0,s1
    80006168:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000616c:	fd043503          	ld	a0,-48(s0)
    80006170:	fffff097          	auipc	ra,0xfffff
    80006174:	a3a080e7          	jalr	-1478(ra) # 80004baa <fileclose>
    fileclose(wf);
    80006178:	fc843503          	ld	a0,-56(s0)
    8000617c:	fffff097          	auipc	ra,0xfffff
    80006180:	a2e080e7          	jalr	-1490(ra) # 80004baa <fileclose>
    return -1;
    80006184:	57fd                	li	a5,-1
    80006186:	a805                	j	800061b6 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006188:	fc442783          	lw	a5,-60(s0)
    8000618c:	0007c863          	bltz	a5,8000619c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006190:	01a78513          	addi	a0,a5,26
    80006194:	050e                	slli	a0,a0,0x3
    80006196:	9526                	add	a0,a0,s1
    80006198:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    8000619c:	fd043503          	ld	a0,-48(s0)
    800061a0:	fffff097          	auipc	ra,0xfffff
    800061a4:	a0a080e7          	jalr	-1526(ra) # 80004baa <fileclose>
    fileclose(wf);
    800061a8:	fc843503          	ld	a0,-56(s0)
    800061ac:	fffff097          	auipc	ra,0xfffff
    800061b0:	9fe080e7          	jalr	-1538(ra) # 80004baa <fileclose>
    return -1;
    800061b4:	57fd                	li	a5,-1
}
    800061b6:	853e                	mv	a0,a5
    800061b8:	70e2                	ld	ra,56(sp)
    800061ba:	7442                	ld	s0,48(sp)
    800061bc:	74a2                	ld	s1,40(sp)
    800061be:	6121                	addi	sp,sp,64
    800061c0:	8082                	ret
	...

00000000800061d0 <kernelvec>:
    800061d0:	7111                	addi	sp,sp,-256
    800061d2:	e006                	sd	ra,0(sp)
    800061d4:	e40a                	sd	sp,8(sp)
    800061d6:	e80e                	sd	gp,16(sp)
    800061d8:	ec12                	sd	tp,24(sp)
    800061da:	f016                	sd	t0,32(sp)
    800061dc:	f41a                	sd	t1,40(sp)
    800061de:	f81e                	sd	t2,48(sp)
    800061e0:	fc22                	sd	s0,56(sp)
    800061e2:	e0a6                	sd	s1,64(sp)
    800061e4:	e4aa                	sd	a0,72(sp)
    800061e6:	e8ae                	sd	a1,80(sp)
    800061e8:	ecb2                	sd	a2,88(sp)
    800061ea:	f0b6                	sd	a3,96(sp)
    800061ec:	f4ba                	sd	a4,104(sp)
    800061ee:	f8be                	sd	a5,112(sp)
    800061f0:	fcc2                	sd	a6,120(sp)
    800061f2:	e146                	sd	a7,128(sp)
    800061f4:	e54a                	sd	s2,136(sp)
    800061f6:	e94e                	sd	s3,144(sp)
    800061f8:	ed52                	sd	s4,152(sp)
    800061fa:	f156                	sd	s5,160(sp)
    800061fc:	f55a                	sd	s6,168(sp)
    800061fe:	f95e                	sd	s7,176(sp)
    80006200:	fd62                	sd	s8,184(sp)
    80006202:	e1e6                	sd	s9,192(sp)
    80006204:	e5ea                	sd	s10,200(sp)
    80006206:	e9ee                	sd	s11,208(sp)
    80006208:	edf2                	sd	t3,216(sp)
    8000620a:	f1f6                	sd	t4,224(sp)
    8000620c:	f5fa                	sd	t5,232(sp)
    8000620e:	f9fe                	sd	t6,240(sp)
    80006210:	d55fc0ef          	jal	ra,80002f64 <kerneltrap>
    80006214:	6082                	ld	ra,0(sp)
    80006216:	6122                	ld	sp,8(sp)
    80006218:	61c2                	ld	gp,16(sp)
    8000621a:	7282                	ld	t0,32(sp)
    8000621c:	7322                	ld	t1,40(sp)
    8000621e:	73c2                	ld	t2,48(sp)
    80006220:	7462                	ld	s0,56(sp)
    80006222:	6486                	ld	s1,64(sp)
    80006224:	6526                	ld	a0,72(sp)
    80006226:	65c6                	ld	a1,80(sp)
    80006228:	6666                	ld	a2,88(sp)
    8000622a:	7686                	ld	a3,96(sp)
    8000622c:	7726                	ld	a4,104(sp)
    8000622e:	77c6                	ld	a5,112(sp)
    80006230:	7866                	ld	a6,120(sp)
    80006232:	688a                	ld	a7,128(sp)
    80006234:	692a                	ld	s2,136(sp)
    80006236:	69ca                	ld	s3,144(sp)
    80006238:	6a6a                	ld	s4,152(sp)
    8000623a:	7a8a                	ld	s5,160(sp)
    8000623c:	7b2a                	ld	s6,168(sp)
    8000623e:	7bca                	ld	s7,176(sp)
    80006240:	7c6a                	ld	s8,184(sp)
    80006242:	6c8e                	ld	s9,192(sp)
    80006244:	6d2e                	ld	s10,200(sp)
    80006246:	6dce                	ld	s11,208(sp)
    80006248:	6e6e                	ld	t3,216(sp)
    8000624a:	7e8e                	ld	t4,224(sp)
    8000624c:	7f2e                	ld	t5,232(sp)
    8000624e:	7fce                	ld	t6,240(sp)
    80006250:	6111                	addi	sp,sp,256
    80006252:	10200073          	sret
    80006256:	00000013          	nop
    8000625a:	00000013          	nop
    8000625e:	0001                	nop

0000000080006260 <timervec>:
    80006260:	34051573          	csrrw	a0,mscratch,a0
    80006264:	e10c                	sd	a1,0(a0)
    80006266:	e510                	sd	a2,8(a0)
    80006268:	e914                	sd	a3,16(a0)
    8000626a:	6d0c                	ld	a1,24(a0)
    8000626c:	7110                	ld	a2,32(a0)
    8000626e:	6194                	ld	a3,0(a1)
    80006270:	96b2                	add	a3,a3,a2
    80006272:	e194                	sd	a3,0(a1)
    80006274:	4589                	li	a1,2
    80006276:	14459073          	csrw	sip,a1
    8000627a:	6914                	ld	a3,16(a0)
    8000627c:	6510                	ld	a2,8(a0)
    8000627e:	610c                	ld	a1,0(a0)
    80006280:	34051573          	csrrw	a0,mscratch,a0
    80006284:	30200073          	mret
	...

000000008000628a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000628a:	1141                	addi	sp,sp,-16
    8000628c:	e422                	sd	s0,8(sp)
    8000628e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006290:	0c0007b7          	lui	a5,0xc000
    80006294:	4705                	li	a4,1
    80006296:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006298:	c3d8                	sw	a4,4(a5)
}
    8000629a:	6422                	ld	s0,8(sp)
    8000629c:	0141                	addi	sp,sp,16
    8000629e:	8082                	ret

00000000800062a0 <plicinithart>:

void
plicinithart(void)
{
    800062a0:	1141                	addi	sp,sp,-16
    800062a2:	e406                	sd	ra,8(sp)
    800062a4:	e022                	sd	s0,0(sp)
    800062a6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062a8:	ffffb097          	auipc	ra,0xffffb
    800062ac:	71e080e7          	jalr	1822(ra) # 800019c6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062b0:	0085171b          	slliw	a4,a0,0x8
    800062b4:	0c0027b7          	lui	a5,0xc002
    800062b8:	97ba                	add	a5,a5,a4
    800062ba:	40200713          	li	a4,1026
    800062be:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062c2:	00d5151b          	slliw	a0,a0,0xd
    800062c6:	0c2017b7          	lui	a5,0xc201
    800062ca:	953e                	add	a0,a0,a5
    800062cc:	00052023          	sw	zero,0(a0)
}
    800062d0:	60a2                	ld	ra,8(sp)
    800062d2:	6402                	ld	s0,0(sp)
    800062d4:	0141                	addi	sp,sp,16
    800062d6:	8082                	ret

00000000800062d8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062d8:	1141                	addi	sp,sp,-16
    800062da:	e406                	sd	ra,8(sp)
    800062dc:	e022                	sd	s0,0(sp)
    800062de:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062e0:	ffffb097          	auipc	ra,0xffffb
    800062e4:	6e6080e7          	jalr	1766(ra) # 800019c6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800062e8:	00d5179b          	slliw	a5,a0,0xd
    800062ec:	0c201537          	lui	a0,0xc201
    800062f0:	953e                	add	a0,a0,a5
  return irq;
}
    800062f2:	4148                	lw	a0,4(a0)
    800062f4:	60a2                	ld	ra,8(sp)
    800062f6:	6402                	ld	s0,0(sp)
    800062f8:	0141                	addi	sp,sp,16
    800062fa:	8082                	ret

00000000800062fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062fc:	1101                	addi	sp,sp,-32
    800062fe:	ec06                	sd	ra,24(sp)
    80006300:	e822                	sd	s0,16(sp)
    80006302:	e426                	sd	s1,8(sp)
    80006304:	1000                	addi	s0,sp,32
    80006306:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006308:	ffffb097          	auipc	ra,0xffffb
    8000630c:	6be080e7          	jalr	1726(ra) # 800019c6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006310:	00d5151b          	slliw	a0,a0,0xd
    80006314:	0c2017b7          	lui	a5,0xc201
    80006318:	97aa                	add	a5,a5,a0
    8000631a:	c3c4                	sw	s1,4(a5)
}
    8000631c:	60e2                	ld	ra,24(sp)
    8000631e:	6442                	ld	s0,16(sp)
    80006320:	64a2                	ld	s1,8(sp)
    80006322:	6105                	addi	sp,sp,32
    80006324:	8082                	ret

0000000080006326 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006326:	1141                	addi	sp,sp,-16
    80006328:	e406                	sd	ra,8(sp)
    8000632a:	e022                	sd	s0,0(sp)
    8000632c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000632e:	479d                	li	a5,7
    80006330:	06a7c963          	blt	a5,a0,800063a2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006334:	0001d797          	auipc	a5,0x1d
    80006338:	ccc78793          	addi	a5,a5,-820 # 80023000 <disk>
    8000633c:	00a78733          	add	a4,a5,a0
    80006340:	6789                	lui	a5,0x2
    80006342:	97ba                	add	a5,a5,a4
    80006344:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006348:	e7ad                	bnez	a5,800063b2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000634a:	00451793          	slli	a5,a0,0x4
    8000634e:	0001f717          	auipc	a4,0x1f
    80006352:	cb270713          	addi	a4,a4,-846 # 80025000 <disk+0x2000>
    80006356:	6314                	ld	a3,0(a4)
    80006358:	96be                	add	a3,a3,a5
    8000635a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000635e:	6314                	ld	a3,0(a4)
    80006360:	96be                	add	a3,a3,a5
    80006362:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006366:	6314                	ld	a3,0(a4)
    80006368:	96be                	add	a3,a3,a5
    8000636a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000636e:	6318                	ld	a4,0(a4)
    80006370:	97ba                	add	a5,a5,a4
    80006372:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006376:	0001d797          	auipc	a5,0x1d
    8000637a:	c8a78793          	addi	a5,a5,-886 # 80023000 <disk>
    8000637e:	97aa                	add	a5,a5,a0
    80006380:	6509                	lui	a0,0x2
    80006382:	953e                	add	a0,a0,a5
    80006384:	4785                	li	a5,1
    80006386:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000638a:	0001f517          	auipc	a0,0x1f
    8000638e:	c8e50513          	addi	a0,a0,-882 # 80025018 <disk+0x2018>
    80006392:	ffffc097          	auipc	ra,0xffffc
    80006396:	138080e7          	jalr	312(ra) # 800024ca <wakeup>
}
    8000639a:	60a2                	ld	ra,8(sp)
    8000639c:	6402                	ld	s0,0(sp)
    8000639e:	0141                	addi	sp,sp,16
    800063a0:	8082                	ret
    panic("free_desc 1");
    800063a2:	00002517          	auipc	a0,0x2
    800063a6:	51650513          	addi	a0,a0,1302 # 800088b8 <syscalls+0x338>
    800063aa:	ffffa097          	auipc	ra,0xffffa
    800063ae:	196080e7          	jalr	406(ra) # 80000540 <panic>
    panic("free_desc 2");
    800063b2:	00002517          	auipc	a0,0x2
    800063b6:	51650513          	addi	a0,a0,1302 # 800088c8 <syscalls+0x348>
    800063ba:	ffffa097          	auipc	ra,0xffffa
    800063be:	186080e7          	jalr	390(ra) # 80000540 <panic>

00000000800063c2 <virtio_disk_init>:
{
    800063c2:	1101                	addi	sp,sp,-32
    800063c4:	ec06                	sd	ra,24(sp)
    800063c6:	e822                	sd	s0,16(sp)
    800063c8:	e426                	sd	s1,8(sp)
    800063ca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063cc:	00002597          	auipc	a1,0x2
    800063d0:	50c58593          	addi	a1,a1,1292 # 800088d8 <syscalls+0x358>
    800063d4:	0001f517          	auipc	a0,0x1f
    800063d8:	d5450513          	addi	a0,a0,-684 # 80025128 <disk+0x2128>
    800063dc:	ffffa097          	auipc	ra,0xffffa
    800063e0:	77a080e7          	jalr	1914(ra) # 80000b56 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063e4:	100017b7          	lui	a5,0x10001
    800063e8:	4398                	lw	a4,0(a5)
    800063ea:	2701                	sext.w	a4,a4
    800063ec:	747277b7          	lui	a5,0x74727
    800063f0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063f4:	0ef71163          	bne	a4,a5,800064d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063f8:	100017b7          	lui	a5,0x10001
    800063fc:	43dc                	lw	a5,4(a5)
    800063fe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006400:	4705                	li	a4,1
    80006402:	0ce79a63          	bne	a5,a4,800064d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006406:	100017b7          	lui	a5,0x10001
    8000640a:	479c                	lw	a5,8(a5)
    8000640c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000640e:	4709                	li	a4,2
    80006410:	0ce79363          	bne	a5,a4,800064d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006414:	100017b7          	lui	a5,0x10001
    80006418:	47d8                	lw	a4,12(a5)
    8000641a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000641c:	554d47b7          	lui	a5,0x554d4
    80006420:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006424:	0af71963          	bne	a4,a5,800064d6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006428:	100017b7          	lui	a5,0x10001
    8000642c:	4705                	li	a4,1
    8000642e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006430:	470d                	li	a4,3
    80006432:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006434:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006436:	c7ffe737          	lui	a4,0xc7ffe
    8000643a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000643e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006440:	2701                	sext.w	a4,a4
    80006442:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006444:	472d                	li	a4,11
    80006446:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006448:	473d                	li	a4,15
    8000644a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000644c:	6705                	lui	a4,0x1
    8000644e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006450:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006454:	5bdc                	lw	a5,52(a5)
    80006456:	2781                	sext.w	a5,a5
  if(max == 0)
    80006458:	c7d9                	beqz	a5,800064e6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000645a:	471d                	li	a4,7
    8000645c:	08f77d63          	bgeu	a4,a5,800064f6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006460:	100014b7          	lui	s1,0x10001
    80006464:	47a1                	li	a5,8
    80006466:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006468:	6609                	lui	a2,0x2
    8000646a:	4581                	li	a1,0
    8000646c:	0001d517          	auipc	a0,0x1d
    80006470:	b9450513          	addi	a0,a0,-1132 # 80023000 <disk>
    80006474:	ffffb097          	auipc	ra,0xffffb
    80006478:	86e080e7          	jalr	-1938(ra) # 80000ce2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000647c:	0001d717          	auipc	a4,0x1d
    80006480:	b8470713          	addi	a4,a4,-1148 # 80023000 <disk>
    80006484:	00c75793          	srli	a5,a4,0xc
    80006488:	2781                	sext.w	a5,a5
    8000648a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000648c:	0001f797          	auipc	a5,0x1f
    80006490:	b7478793          	addi	a5,a5,-1164 # 80025000 <disk+0x2000>
    80006494:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006496:	0001d717          	auipc	a4,0x1d
    8000649a:	bea70713          	addi	a4,a4,-1046 # 80023080 <disk+0x80>
    8000649e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800064a0:	0001e717          	auipc	a4,0x1e
    800064a4:	b6070713          	addi	a4,a4,-1184 # 80024000 <disk+0x1000>
    800064a8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800064aa:	4705                	li	a4,1
    800064ac:	00e78c23          	sb	a4,24(a5)
    800064b0:	00e78ca3          	sb	a4,25(a5)
    800064b4:	00e78d23          	sb	a4,26(a5)
    800064b8:	00e78da3          	sb	a4,27(a5)
    800064bc:	00e78e23          	sb	a4,28(a5)
    800064c0:	00e78ea3          	sb	a4,29(a5)
    800064c4:	00e78f23          	sb	a4,30(a5)
    800064c8:	00e78fa3          	sb	a4,31(a5)
}
    800064cc:	60e2                	ld	ra,24(sp)
    800064ce:	6442                	ld	s0,16(sp)
    800064d0:	64a2                	ld	s1,8(sp)
    800064d2:	6105                	addi	sp,sp,32
    800064d4:	8082                	ret
    panic("could not find virtio disk");
    800064d6:	00002517          	auipc	a0,0x2
    800064da:	41250513          	addi	a0,a0,1042 # 800088e8 <syscalls+0x368>
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	062080e7          	jalr	98(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800064e6:	00002517          	auipc	a0,0x2
    800064ea:	42250513          	addi	a0,a0,1058 # 80008908 <syscalls+0x388>
    800064ee:	ffffa097          	auipc	ra,0xffffa
    800064f2:	052080e7          	jalr	82(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800064f6:	00002517          	auipc	a0,0x2
    800064fa:	43250513          	addi	a0,a0,1074 # 80008928 <syscalls+0x3a8>
    800064fe:	ffffa097          	auipc	ra,0xffffa
    80006502:	042080e7          	jalr	66(ra) # 80000540 <panic>

0000000080006506 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006506:	7159                	addi	sp,sp,-112
    80006508:	f486                	sd	ra,104(sp)
    8000650a:	f0a2                	sd	s0,96(sp)
    8000650c:	eca6                	sd	s1,88(sp)
    8000650e:	e8ca                	sd	s2,80(sp)
    80006510:	e4ce                	sd	s3,72(sp)
    80006512:	e0d2                	sd	s4,64(sp)
    80006514:	fc56                	sd	s5,56(sp)
    80006516:	f85a                	sd	s6,48(sp)
    80006518:	f45e                	sd	s7,40(sp)
    8000651a:	f062                	sd	s8,32(sp)
    8000651c:	ec66                	sd	s9,24(sp)
    8000651e:	e86a                	sd	s10,16(sp)
    80006520:	1880                	addi	s0,sp,112
    80006522:	892a                	mv	s2,a0
    80006524:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006526:	00c52c83          	lw	s9,12(a0)
    8000652a:	001c9c9b          	slliw	s9,s9,0x1
    8000652e:	1c82                	slli	s9,s9,0x20
    80006530:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006534:	0001f517          	auipc	a0,0x1f
    80006538:	bf450513          	addi	a0,a0,-1036 # 80025128 <disk+0x2128>
    8000653c:	ffffa097          	auipc	ra,0xffffa
    80006540:	6aa080e7          	jalr	1706(ra) # 80000be6 <acquire>
  for(int i = 0; i < 3; i++){
    80006544:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006546:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006548:	0001db97          	auipc	s7,0x1d
    8000654c:	ab8b8b93          	addi	s7,s7,-1352 # 80023000 <disk>
    80006550:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006552:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006554:	8a4e                	mv	s4,s3
    80006556:	a051                	j	800065da <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006558:	00fb86b3          	add	a3,s7,a5
    8000655c:	96da                	add	a3,a3,s6
    8000655e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006562:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006564:	0207c563          	bltz	a5,8000658e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006568:	2485                	addiw	s1,s1,1
    8000656a:	0711                	addi	a4,a4,4
    8000656c:	25548063          	beq	s1,s5,800067ac <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006570:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006572:	0001f697          	auipc	a3,0x1f
    80006576:	aa668693          	addi	a3,a3,-1370 # 80025018 <disk+0x2018>
    8000657a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000657c:	0006c583          	lbu	a1,0(a3)
    80006580:	fde1                	bnez	a1,80006558 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006582:	2785                	addiw	a5,a5,1
    80006584:	0685                	addi	a3,a3,1
    80006586:	ff879be3          	bne	a5,s8,8000657c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000658a:	57fd                	li	a5,-1
    8000658c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000658e:	02905a63          	blez	s1,800065c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006592:	f9042503          	lw	a0,-112(s0)
    80006596:	00000097          	auipc	ra,0x0
    8000659a:	d90080e7          	jalr	-624(ra) # 80006326 <free_desc>
      for(int j = 0; j < i; j++)
    8000659e:	4785                	li	a5,1
    800065a0:	0297d163          	bge	a5,s1,800065c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065a4:	f9442503          	lw	a0,-108(s0)
    800065a8:	00000097          	auipc	ra,0x0
    800065ac:	d7e080e7          	jalr	-642(ra) # 80006326 <free_desc>
      for(int j = 0; j < i; j++)
    800065b0:	4789                	li	a5,2
    800065b2:	0097d863          	bge	a5,s1,800065c2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065b6:	f9842503          	lw	a0,-104(s0)
    800065ba:	00000097          	auipc	ra,0x0
    800065be:	d6c080e7          	jalr	-660(ra) # 80006326 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065c2:	0001f597          	auipc	a1,0x1f
    800065c6:	b6658593          	addi	a1,a1,-1178 # 80025128 <disk+0x2128>
    800065ca:	0001f517          	auipc	a0,0x1f
    800065ce:	a4e50513          	addi	a0,a0,-1458 # 80025018 <disk+0x2018>
    800065d2:	ffffc097          	auipc	ra,0xffffc
    800065d6:	d12080e7          	jalr	-750(ra) # 800022e4 <sleep>
  for(int i = 0; i < 3; i++){
    800065da:	f9040713          	addi	a4,s0,-112
    800065de:	84ce                	mv	s1,s3
    800065e0:	bf41                	j	80006570 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800065e2:	20058713          	addi	a4,a1,512
    800065e6:	00471693          	slli	a3,a4,0x4
    800065ea:	0001d717          	auipc	a4,0x1d
    800065ee:	a1670713          	addi	a4,a4,-1514 # 80023000 <disk>
    800065f2:	9736                	add	a4,a4,a3
    800065f4:	4685                	li	a3,1
    800065f6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065fa:	20058713          	addi	a4,a1,512
    800065fe:	00471693          	slli	a3,a4,0x4
    80006602:	0001d717          	auipc	a4,0x1d
    80006606:	9fe70713          	addi	a4,a4,-1538 # 80023000 <disk>
    8000660a:	9736                	add	a4,a4,a3
    8000660c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006610:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006614:	7679                	lui	a2,0xffffe
    80006616:	963e                	add	a2,a2,a5
    80006618:	0001f697          	auipc	a3,0x1f
    8000661c:	9e868693          	addi	a3,a3,-1560 # 80025000 <disk+0x2000>
    80006620:	6298                	ld	a4,0(a3)
    80006622:	9732                	add	a4,a4,a2
    80006624:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006626:	6298                	ld	a4,0(a3)
    80006628:	9732                	add	a4,a4,a2
    8000662a:	4541                	li	a0,16
    8000662c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000662e:	6298                	ld	a4,0(a3)
    80006630:	9732                	add	a4,a4,a2
    80006632:	4505                	li	a0,1
    80006634:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006638:	f9442703          	lw	a4,-108(s0)
    8000663c:	6288                	ld	a0,0(a3)
    8000663e:	962a                	add	a2,a2,a0
    80006640:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006644:	0712                	slli	a4,a4,0x4
    80006646:	6290                	ld	a2,0(a3)
    80006648:	963a                	add	a2,a2,a4
    8000664a:	05890513          	addi	a0,s2,88
    8000664e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006650:	6294                	ld	a3,0(a3)
    80006652:	96ba                	add	a3,a3,a4
    80006654:	40000613          	li	a2,1024
    80006658:	c690                	sw	a2,8(a3)
  if(write)
    8000665a:	140d0063          	beqz	s10,8000679a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000665e:	0001f697          	auipc	a3,0x1f
    80006662:	9a26b683          	ld	a3,-1630(a3) # 80025000 <disk+0x2000>
    80006666:	96ba                	add	a3,a3,a4
    80006668:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000666c:	0001d817          	auipc	a6,0x1d
    80006670:	99480813          	addi	a6,a6,-1644 # 80023000 <disk>
    80006674:	0001f517          	auipc	a0,0x1f
    80006678:	98c50513          	addi	a0,a0,-1652 # 80025000 <disk+0x2000>
    8000667c:	6114                	ld	a3,0(a0)
    8000667e:	96ba                	add	a3,a3,a4
    80006680:	00c6d603          	lhu	a2,12(a3)
    80006684:	00166613          	ori	a2,a2,1
    80006688:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000668c:	f9842683          	lw	a3,-104(s0)
    80006690:	6110                	ld	a2,0(a0)
    80006692:	9732                	add	a4,a4,a2
    80006694:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006698:	20058613          	addi	a2,a1,512
    8000669c:	0612                	slli	a2,a2,0x4
    8000669e:	9642                	add	a2,a2,a6
    800066a0:	577d                	li	a4,-1
    800066a2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066a6:	00469713          	slli	a4,a3,0x4
    800066aa:	6114                	ld	a3,0(a0)
    800066ac:	96ba                	add	a3,a3,a4
    800066ae:	03078793          	addi	a5,a5,48
    800066b2:	97c2                	add	a5,a5,a6
    800066b4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800066b6:	611c                	ld	a5,0(a0)
    800066b8:	97ba                	add	a5,a5,a4
    800066ba:	4685                	li	a3,1
    800066bc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066be:	611c                	ld	a5,0(a0)
    800066c0:	97ba                	add	a5,a5,a4
    800066c2:	4809                	li	a6,2
    800066c4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800066c8:	611c                	ld	a5,0(a0)
    800066ca:	973e                	add	a4,a4,a5
    800066cc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066d0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800066d4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066d8:	6518                	ld	a4,8(a0)
    800066da:	00275783          	lhu	a5,2(a4)
    800066de:	8b9d                	andi	a5,a5,7
    800066e0:	0786                	slli	a5,a5,0x1
    800066e2:	97ba                	add	a5,a5,a4
    800066e4:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800066e8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800066ec:	6518                	ld	a4,8(a0)
    800066ee:	00275783          	lhu	a5,2(a4)
    800066f2:	2785                	addiw	a5,a5,1
    800066f4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066f8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066fc:	100017b7          	lui	a5,0x10001
    80006700:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006704:	00492703          	lw	a4,4(s2)
    80006708:	4785                	li	a5,1
    8000670a:	02f71163          	bne	a4,a5,8000672c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000670e:	0001f997          	auipc	s3,0x1f
    80006712:	a1a98993          	addi	s3,s3,-1510 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006716:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006718:	85ce                	mv	a1,s3
    8000671a:	854a                	mv	a0,s2
    8000671c:	ffffc097          	auipc	ra,0xffffc
    80006720:	bc8080e7          	jalr	-1080(ra) # 800022e4 <sleep>
  while(b->disk == 1) {
    80006724:	00492783          	lw	a5,4(s2)
    80006728:	fe9788e3          	beq	a5,s1,80006718 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000672c:	f9042903          	lw	s2,-112(s0)
    80006730:	20090793          	addi	a5,s2,512
    80006734:	00479713          	slli	a4,a5,0x4
    80006738:	0001d797          	auipc	a5,0x1d
    8000673c:	8c878793          	addi	a5,a5,-1848 # 80023000 <disk>
    80006740:	97ba                	add	a5,a5,a4
    80006742:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006746:	0001f997          	auipc	s3,0x1f
    8000674a:	8ba98993          	addi	s3,s3,-1862 # 80025000 <disk+0x2000>
    8000674e:	00491713          	slli	a4,s2,0x4
    80006752:	0009b783          	ld	a5,0(s3)
    80006756:	97ba                	add	a5,a5,a4
    80006758:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000675c:	854a                	mv	a0,s2
    8000675e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006762:	00000097          	auipc	ra,0x0
    80006766:	bc4080e7          	jalr	-1084(ra) # 80006326 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000676a:	8885                	andi	s1,s1,1
    8000676c:	f0ed                	bnez	s1,8000674e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000676e:	0001f517          	auipc	a0,0x1f
    80006772:	9ba50513          	addi	a0,a0,-1606 # 80025128 <disk+0x2128>
    80006776:	ffffa097          	auipc	ra,0xffffa
    8000677a:	524080e7          	jalr	1316(ra) # 80000c9a <release>
}
    8000677e:	70a6                	ld	ra,104(sp)
    80006780:	7406                	ld	s0,96(sp)
    80006782:	64e6                	ld	s1,88(sp)
    80006784:	6946                	ld	s2,80(sp)
    80006786:	69a6                	ld	s3,72(sp)
    80006788:	6a06                	ld	s4,64(sp)
    8000678a:	7ae2                	ld	s5,56(sp)
    8000678c:	7b42                	ld	s6,48(sp)
    8000678e:	7ba2                	ld	s7,40(sp)
    80006790:	7c02                	ld	s8,32(sp)
    80006792:	6ce2                	ld	s9,24(sp)
    80006794:	6d42                	ld	s10,16(sp)
    80006796:	6165                	addi	sp,sp,112
    80006798:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000679a:	0001f697          	auipc	a3,0x1f
    8000679e:	8666b683          	ld	a3,-1946(a3) # 80025000 <disk+0x2000>
    800067a2:	96ba                	add	a3,a3,a4
    800067a4:	4609                	li	a2,2
    800067a6:	00c69623          	sh	a2,12(a3)
    800067aa:	b5c9                	j	8000666c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067ac:	f9042583          	lw	a1,-112(s0)
    800067b0:	20058793          	addi	a5,a1,512
    800067b4:	0792                	slli	a5,a5,0x4
    800067b6:	0001d517          	auipc	a0,0x1d
    800067ba:	8f250513          	addi	a0,a0,-1806 # 800230a8 <disk+0xa8>
    800067be:	953e                	add	a0,a0,a5
  if(write)
    800067c0:	e20d11e3          	bnez	s10,800065e2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800067c4:	20058713          	addi	a4,a1,512
    800067c8:	00471693          	slli	a3,a4,0x4
    800067cc:	0001d717          	auipc	a4,0x1d
    800067d0:	83470713          	addi	a4,a4,-1996 # 80023000 <disk>
    800067d4:	9736                	add	a4,a4,a3
    800067d6:	0a072423          	sw	zero,168(a4)
    800067da:	b505                	j	800065fa <virtio_disk_rw+0xf4>

00000000800067dc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800067dc:	1101                	addi	sp,sp,-32
    800067de:	ec06                	sd	ra,24(sp)
    800067e0:	e822                	sd	s0,16(sp)
    800067e2:	e426                	sd	s1,8(sp)
    800067e4:	e04a                	sd	s2,0(sp)
    800067e6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800067e8:	0001f517          	auipc	a0,0x1f
    800067ec:	94050513          	addi	a0,a0,-1728 # 80025128 <disk+0x2128>
    800067f0:	ffffa097          	auipc	ra,0xffffa
    800067f4:	3f6080e7          	jalr	1014(ra) # 80000be6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067f8:	10001737          	lui	a4,0x10001
    800067fc:	533c                	lw	a5,96(a4)
    800067fe:	8b8d                	andi	a5,a5,3
    80006800:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006802:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006806:	0001e797          	auipc	a5,0x1e
    8000680a:	7fa78793          	addi	a5,a5,2042 # 80025000 <disk+0x2000>
    8000680e:	6b94                	ld	a3,16(a5)
    80006810:	0207d703          	lhu	a4,32(a5)
    80006814:	0026d783          	lhu	a5,2(a3)
    80006818:	06f70163          	beq	a4,a5,8000687a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000681c:	0001c917          	auipc	s2,0x1c
    80006820:	7e490913          	addi	s2,s2,2020 # 80023000 <disk>
    80006824:	0001e497          	auipc	s1,0x1e
    80006828:	7dc48493          	addi	s1,s1,2012 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000682c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006830:	6898                	ld	a4,16(s1)
    80006832:	0204d783          	lhu	a5,32(s1)
    80006836:	8b9d                	andi	a5,a5,7
    80006838:	078e                	slli	a5,a5,0x3
    8000683a:	97ba                	add	a5,a5,a4
    8000683c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000683e:	20078713          	addi	a4,a5,512
    80006842:	0712                	slli	a4,a4,0x4
    80006844:	974a                	add	a4,a4,s2
    80006846:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000684a:	e731                	bnez	a4,80006896 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000684c:	20078793          	addi	a5,a5,512
    80006850:	0792                	slli	a5,a5,0x4
    80006852:	97ca                	add	a5,a5,s2
    80006854:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006856:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000685a:	ffffc097          	auipc	ra,0xffffc
    8000685e:	c70080e7          	jalr	-912(ra) # 800024ca <wakeup>

    disk.used_idx += 1;
    80006862:	0204d783          	lhu	a5,32(s1)
    80006866:	2785                	addiw	a5,a5,1
    80006868:	17c2                	slli	a5,a5,0x30
    8000686a:	93c1                	srli	a5,a5,0x30
    8000686c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006870:	6898                	ld	a4,16(s1)
    80006872:	00275703          	lhu	a4,2(a4)
    80006876:	faf71be3          	bne	a4,a5,8000682c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000687a:	0001f517          	auipc	a0,0x1f
    8000687e:	8ae50513          	addi	a0,a0,-1874 # 80025128 <disk+0x2128>
    80006882:	ffffa097          	auipc	ra,0xffffa
    80006886:	418080e7          	jalr	1048(ra) # 80000c9a <release>
}
    8000688a:	60e2                	ld	ra,24(sp)
    8000688c:	6442                	ld	s0,16(sp)
    8000688e:	64a2                	ld	s1,8(sp)
    80006890:	6902                	ld	s2,0(sp)
    80006892:	6105                	addi	sp,sp,32
    80006894:	8082                	ret
      panic("virtio_disk_intr status");
    80006896:	00002517          	auipc	a0,0x2
    8000689a:	0b250513          	addi	a0,a0,178 # 80008948 <syscalls+0x3c8>
    8000689e:	ffffa097          	auipc	ra,0xffffa
    800068a2:	ca2080e7          	jalr	-862(ra) # 80000540 <panic>
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
