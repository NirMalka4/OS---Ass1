
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
    80000068:	1ac78793          	addi	a5,a5,428 # 80006210 <timervec>
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
    80000130:	780080e7          	jalr	1920(ra) # 800028ac <either_copyin>
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
    800001da:	0d2080e7          	jalr	210(ra) # 800022a8 <sleep>
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
    80000216:	644080e7          	jalr	1604(ra) # 80002856 <either_copyout>
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
    800002f8:	60e080e7          	jalr	1550(ra) # 80002902 <procdump>
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
    8000044c:	046080e7          	jalr	70(ra) # 8000248e <wakeup>
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
    800008a6:	bec080e7          	jalr	-1044(ra) # 8000248e <wakeup>
    
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
    80000932:	97a080e7          	jalr	-1670(ra) # 800022a8 <sleep>
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
    80000eda:	dd0080e7          	jalr	-560(ra) # 80002ca6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ede:	00005097          	auipc	ra,0x5
    80000ee2:	372080e7          	jalr	882(ra) # 80006250 <plicinithart>
  }

  scheduler();        
    80000ee6:	00001097          	auipc	ra,0x1
    80000eea:	078080e7          	jalr	120(ra) # 80001f5e <scheduler>
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
    80000f52:	d30080e7          	jalr	-720(ra) # 80002c7e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	d50080e7          	jalr	-688(ra) # 80002ca6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5e:	00005097          	auipc	ra,0x5
    80000f62:	2dc080e7          	jalr	732(ra) # 8000623a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f66:	00005097          	auipc	ra,0x5
    80000f6a:	2ea080e7          	jalr	746(ra) # 80006250 <plicinithart>
    binit();         // buffer cache
    80000f6e:	00002097          	auipc	ra,0x2
    80000f72:	4ca080e7          	jalr	1226(ra) # 80003438 <binit>
    iinit();         // inode table
    80000f76:	00003097          	auipc	ra,0x3
    80000f7a:	b5a080e7          	jalr	-1190(ra) # 80003ad0 <iinit>
    fileinit();      // file table
    80000f7e:	00004097          	auipc	ra,0x4
    80000f82:	b04080e7          	jalr	-1276(ra) # 80004a82 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f86:	00005097          	auipc	ra,0x5
    80000f8a:	3ec080e7          	jalr	1004(ra) # 80006372 <virtio_disk_init>
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
    80001a46:	f1e7a783          	lw	a5,-226(a5) # 80008960 <first.1706>
    80001a4a:	eb89                	bnez	a5,80001a5c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a4c:	00001097          	auipc	ra,0x1
    80001a50:	272080e7          	jalr	626(ra) # 80002cbe <usertrapret>
}
    80001a54:	60a2                	ld	ra,8(sp)
    80001a56:	6402                	ld	s0,0(sp)
    80001a58:	0141                	addi	sp,sp,16
    80001a5a:	8082                	ret
    first = 0;
    80001a5c:	00007797          	auipc	a5,0x7
    80001a60:	f007a223          	sw	zero,-252(a5) # 80008960 <first.1706>
    fsinit(ROOTDEV);
    80001a64:	4505                	li	a0,1
    80001a66:	00002097          	auipc	ra,0x2
    80001a6a:	fea080e7          	jalr	-22(ra) # 80003a50 <fsinit>
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
    80001cdc:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cde:	00000097          	auipc	ra,0x0
    80001ce2:	f1e080e7          	jalr	-226(ra) # 80001bfc <allocproc>
    80001ce6:	84aa                	mv	s1,a0
  initproc = p;
    80001ce8:	00007797          	auipc	a5,0x7
    80001cec:	34a7b423          	sd	a0,840(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cf0:	03400613          	li	a2,52
    80001cf4:	00007597          	auipc	a1,0x7
    80001cf8:	c7c58593          	addi	a1,a1,-900 # 80008970 <initcode>
    80001cfc:	6928                	ld	a0,80(a0)
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	66c080e7          	jalr	1644(ra) # 8000136a <uvminit>
  p->sz = PGSIZE;
    80001d06:	6785                	lui	a5,0x1
    80001d08:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d0a:	6cb8                	ld	a4,88(s1)
    80001d0c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d10:	6cb8                	ld	a4,88(s1)
    80001d12:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d14:	4641                	li	a2,16
    80001d16:	00006597          	auipc	a1,0x6
    80001d1a:	4ea58593          	addi	a1,a1,1258 # 80008200 <digits+0x1c0>
    80001d1e:	15848513          	addi	a0,s1,344
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	112080e7          	jalr	274(ra) # 80000e34 <safestrcpy>
  p->cwd = namei("/");
    80001d2a:	00006517          	auipc	a0,0x6
    80001d2e:	4e650513          	addi	a0,a0,1254 # 80008210 <digits+0x1d0>
    80001d32:	00002097          	auipc	ra,0x2
    80001d36:	74c080e7          	jalr	1868(ra) # 8000447e <namei>
    80001d3a:	14a4b823          	sd	a0,336(s1)
  p->runnable_time = 0;
    80001d3e:	1604ae23          	sw	zero,380(s1)
  p->running_time = 0;
    80001d42:	1604ac23          	sw	zero,376(s1)
  p -> sleeping_time = 0;
    80001d46:	1604aa23          	sw	zero,372(s1)
  p->last_update_time = ticks;
    80001d4a:	00007797          	auipc	a5,0x7
    80001d4e:	30a7a783          	lw	a5,778(a5) # 80009054 <ticks>
    80001d52:	18f4a023          	sw	a5,384(s1)
  p->state = RUNNABLE;
    80001d56:	478d                	li	a5,3
    80001d58:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d5a:	8526                	mv	a0,s1
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	f3e080e7          	jalr	-194(ra) # 80000c9a <release>
}
    80001d64:	60e2                	ld	ra,24(sp)
    80001d66:	6442                	ld	s0,16(sp)
    80001d68:	64a2                	ld	s1,8(sp)
    80001d6a:	6105                	addi	sp,sp,32
    80001d6c:	8082                	ret

0000000080001d6e <growproc>:
{
    80001d6e:	1101                	addi	sp,sp,-32
    80001d70:	ec06                	sd	ra,24(sp)
    80001d72:	e822                	sd	s0,16(sp)
    80001d74:	e426                	sd	s1,8(sp)
    80001d76:	e04a                	sd	s2,0(sp)
    80001d78:	1000                	addi	s0,sp,32
    80001d7a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d7c:	00000097          	auipc	ra,0x0
    80001d80:	c76080e7          	jalr	-906(ra) # 800019f2 <myproc>
    80001d84:	892a                	mv	s2,a0
  sz = p->sz;
    80001d86:	652c                	ld	a1,72(a0)
    80001d88:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d8c:	00904f63          	bgtz	s1,80001daa <growproc+0x3c>
  } else if(n < 0){
    80001d90:	0204cc63          	bltz	s1,80001dc8 <growproc+0x5a>
  p->sz = sz;
    80001d94:	1602                	slli	a2,a2,0x20
    80001d96:	9201                	srli	a2,a2,0x20
    80001d98:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d9c:	4501                	li	a0,0
}
    80001d9e:	60e2                	ld	ra,24(sp)
    80001da0:	6442                	ld	s0,16(sp)
    80001da2:	64a2                	ld	s1,8(sp)
    80001da4:	6902                	ld	s2,0(sp)
    80001da6:	6105                	addi	sp,sp,32
    80001da8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001daa:	9e25                	addw	a2,a2,s1
    80001dac:	1602                	slli	a2,a2,0x20
    80001dae:	9201                	srli	a2,a2,0x20
    80001db0:	1582                	slli	a1,a1,0x20
    80001db2:	9181                	srli	a1,a1,0x20
    80001db4:	6928                	ld	a0,80(a0)
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	66e080e7          	jalr	1646(ra) # 80001424 <uvmalloc>
    80001dbe:	0005061b          	sext.w	a2,a0
    80001dc2:	fa69                	bnez	a2,80001d94 <growproc+0x26>
      return -1;
    80001dc4:	557d                	li	a0,-1
    80001dc6:	bfe1                	j	80001d9e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001dc8:	9e25                	addw	a2,a2,s1
    80001dca:	1602                	slli	a2,a2,0x20
    80001dcc:	9201                	srli	a2,a2,0x20
    80001dce:	1582                	slli	a1,a1,0x20
    80001dd0:	9181                	srli	a1,a1,0x20
    80001dd2:	6928                	ld	a0,80(a0)
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	608080e7          	jalr	1544(ra) # 800013dc <uvmdealloc>
    80001ddc:	0005061b          	sext.w	a2,a0
    80001de0:	bf55                	j	80001d94 <growproc+0x26>

0000000080001de2 <fork>:
{
    80001de2:	7179                	addi	sp,sp,-48
    80001de4:	f406                	sd	ra,40(sp)
    80001de6:	f022                	sd	s0,32(sp)
    80001de8:	ec26                	sd	s1,24(sp)
    80001dea:	e84a                	sd	s2,16(sp)
    80001dec:	e44e                	sd	s3,8(sp)
    80001dee:	e052                	sd	s4,0(sp)
    80001df0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001df2:	00000097          	auipc	ra,0x0
    80001df6:	c00080e7          	jalr	-1024(ra) # 800019f2 <myproc>
    80001dfa:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80001dfc:	00000097          	auipc	ra,0x0
    80001e00:	e00080e7          	jalr	-512(ra) # 80001bfc <allocproc>
    80001e04:	14050b63          	beqz	a0,80001f5a <fork+0x178>
    80001e08:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e0a:	0489b603          	ld	a2,72(s3)
    80001e0e:	692c                	ld	a1,80(a0)
    80001e10:	0509b503          	ld	a0,80(s3)
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	75c080e7          	jalr	1884(ra) # 80001570 <uvmcopy>
    80001e1c:	04054663          	bltz	a0,80001e68 <fork+0x86>
  np->sz = p->sz;
    80001e20:	0489b783          	ld	a5,72(s3)
    80001e24:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    80001e28:	0589b683          	ld	a3,88(s3)
    80001e2c:	87b6                	mv	a5,a3
    80001e2e:	05893703          	ld	a4,88(s2)
    80001e32:	12068693          	addi	a3,a3,288
    80001e36:	0007b803          	ld	a6,0(a5)
    80001e3a:	6788                	ld	a0,8(a5)
    80001e3c:	6b8c                	ld	a1,16(a5)
    80001e3e:	6f90                	ld	a2,24(a5)
    80001e40:	01073023          	sd	a6,0(a4)
    80001e44:	e708                	sd	a0,8(a4)
    80001e46:	eb0c                	sd	a1,16(a4)
    80001e48:	ef10                	sd	a2,24(a4)
    80001e4a:	02078793          	addi	a5,a5,32
    80001e4e:	02070713          	addi	a4,a4,32
    80001e52:	fed792e3          	bne	a5,a3,80001e36 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e56:	05893783          	ld	a5,88(s2)
    80001e5a:	0607b823          	sd	zero,112(a5)
    80001e5e:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e62:	15000a13          	li	s4,336
    80001e66:	a03d                	j	80001e94 <fork+0xb2>
    freeproc(np);
    80001e68:	854a                	mv	a0,s2
    80001e6a:	00000097          	auipc	ra,0x0
    80001e6e:	d3a080e7          	jalr	-710(ra) # 80001ba4 <freeproc>
    release(&np->lock);
    80001e72:	854a                	mv	a0,s2
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	e26080e7          	jalr	-474(ra) # 80000c9a <release>
    return -1;
    80001e7c:	5a7d                	li	s4,-1
    80001e7e:	a0e9                	j	80001f48 <fork+0x166>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e80:	00003097          	auipc	ra,0x3
    80001e84:	c94080e7          	jalr	-876(ra) # 80004b14 <filedup>
    80001e88:	009907b3          	add	a5,s2,s1
    80001e8c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e8e:	04a1                	addi	s1,s1,8
    80001e90:	01448763          	beq	s1,s4,80001e9e <fork+0xbc>
    if(p->ofile[i])
    80001e94:	009987b3          	add	a5,s3,s1
    80001e98:	6388                	ld	a0,0(a5)
    80001e9a:	f17d                	bnez	a0,80001e80 <fork+0x9e>
    80001e9c:	bfcd                	j	80001e8e <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e9e:	1509b503          	ld	a0,336(s3)
    80001ea2:	00002097          	auipc	ra,0x2
    80001ea6:	de8080e7          	jalr	-536(ra) # 80003c8a <idup>
    80001eaa:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eae:	4641                	li	a2,16
    80001eb0:	15898593          	addi	a1,s3,344
    80001eb4:	15890513          	addi	a0,s2,344
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	f7c080e7          	jalr	-132(ra) # 80000e34 <safestrcpy>
  pid = np->pid;
    80001ec0:	03092a03          	lw	s4,48(s2)
  np->last_ticks = 0;
    80001ec4:	16092623          	sw	zero,364(s2)
  np->mean_ticks = 0;
    80001ec8:	16092423          	sw	zero,360(s2)
  release(&np->lock);
    80001ecc:	854a                	mv	a0,s2
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	dcc080e7          	jalr	-564(ra) # 80000c9a <release>
  acquire(&wait_lock);
    80001ed6:	0000f497          	auipc	s1,0xf
    80001eda:	40248493          	addi	s1,s1,1026 # 800112d8 <wait_lock>
    80001ede:	8526                	mv	a0,s1
    80001ee0:	fffff097          	auipc	ra,0xfffff
    80001ee4:	d06080e7          	jalr	-762(ra) # 80000be6 <acquire>
  np->parent = p;
    80001ee8:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    80001eec:	8526                	mv	a0,s1
    80001eee:	fffff097          	auipc	ra,0xfffff
    80001ef2:	dac080e7          	jalr	-596(ra) # 80000c9a <release>
  acquire(&np->lock);
    80001ef6:	854a                	mv	a0,s2
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	cee080e7          	jalr	-786(ra) # 80000be6 <acquire>
  np->runnable_time = 0;
    80001f00:	16092e23          	sw	zero,380(s2)
  np->running_time = 0;
    80001f04:	16092c23          	sw	zero,376(s2)
  np -> sleeping_time = 0;
    80001f08:	16092a23          	sw	zero,372(s2)
  acquire(&tickslock);
    80001f0c:	00016517          	auipc	a0,0x16
    80001f10:	9e450513          	addi	a0,a0,-1564 # 800178f0 <tickslock>
    80001f14:	fffff097          	auipc	ra,0xfffff
    80001f18:	cd2080e7          	jalr	-814(ra) # 80000be6 <acquire>
  np->last_update_time = ticks;
    80001f1c:	00007797          	auipc	a5,0x7
    80001f20:	1387a783          	lw	a5,312(a5) # 80009054 <ticks>
    80001f24:	18f92023          	sw	a5,384(s2)
  release(&tickslock);
    80001f28:	00016517          	auipc	a0,0x16
    80001f2c:	9c850513          	addi	a0,a0,-1592 # 800178f0 <tickslock>
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	d6a080e7          	jalr	-662(ra) # 80000c9a <release>
  np->state = RUNNABLE;
    80001f38:	478d                	li	a5,3
    80001f3a:	00f92c23          	sw	a5,24(s2)
  release(&np->lock);
    80001f3e:	854a                	mv	a0,s2
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	d5a080e7          	jalr	-678(ra) # 80000c9a <release>
}
    80001f48:	8552                	mv	a0,s4
    80001f4a:	70a2                	ld	ra,40(sp)
    80001f4c:	7402                	ld	s0,32(sp)
    80001f4e:	64e2                	ld	s1,24(sp)
    80001f50:	6942                	ld	s2,16(sp)
    80001f52:	69a2                	ld	s3,8(sp)
    80001f54:	6a02                	ld	s4,0(sp)
    80001f56:	6145                	addi	sp,sp,48
    80001f58:	8082                	ret
    return -1;
    80001f5a:	5a7d                	li	s4,-1
    80001f5c:	b7f5                	j	80001f48 <fork+0x166>

0000000080001f5e <scheduler>:
{
    80001f5e:	7159                	addi	sp,sp,-112
    80001f60:	f486                	sd	ra,104(sp)
    80001f62:	f0a2                	sd	s0,96(sp)
    80001f64:	eca6                	sd	s1,88(sp)
    80001f66:	e8ca                	sd	s2,80(sp)
    80001f68:	e4ce                	sd	s3,72(sp)
    80001f6a:	e0d2                	sd	s4,64(sp)
    80001f6c:	fc56                	sd	s5,56(sp)
    80001f6e:	f85a                	sd	s6,48(sp)
    80001f70:	f45e                	sd	s7,40(sp)
    80001f72:	f062                	sd	s8,32(sp)
    80001f74:	ec66                	sd	s9,24(sp)
    80001f76:	e86a                	sd	s10,16(sp)
    80001f78:	e46e                	sd	s11,8(sp)
    80001f7a:	1880                	addi	s0,sp,112
    80001f7c:	8792                	mv	a5,tp
  int id = r_tp();
    80001f7e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f80:	00779d93          	slli	s11,a5,0x7
    80001f84:	0000f717          	auipc	a4,0xf
    80001f88:	33c70713          	addi	a4,a4,828 # 800112c0 <pid_lock>
    80001f8c:	976e                	add	a4,a4,s11
    80001f8e:	02073823          	sd	zero,48(a4)
         swtch(&c->context, &hp->context);
    80001f92:	0000f717          	auipc	a4,0xf
    80001f96:	36670713          	addi	a4,a4,870 # 800112f8 <cpus+0x8>
    80001f9a:	9dba                	add	s11,s11,a4
    while(paused)
    80001f9c:	00007c17          	auipc	s8,0x7
    80001fa0:	090c0c13          	addi	s8,s8,144 # 8000902c <paused>
      if(ticks >= pause_interval)
    80001fa4:	00007b17          	auipc	s6,0x7
    80001fa8:	0b0b0b13          	addi	s6,s6,176 # 80009054 <ticks>
         c->proc = hp;
    80001fac:	079e                	slli	a5,a5,0x7
    80001fae:	0000fb97          	auipc	s7,0xf
    80001fb2:	312b8b93          	addi	s7,s7,786 # 800112c0 <pid_lock>
    80001fb6:	9bbe                	add	s7,s7,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fb8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fbc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fc0:	10079073          	csrw	sstatus,a5
    while(paused)
    80001fc4:	000c2783          	lw	a5,0(s8)
    80001fc8:	2781                	sext.w	a5,a5
    80001fca:	cba1                	beqz	a5,8000201a <scheduler+0xbc>
      acquire(&tickslock);
    80001fcc:	00016497          	auipc	s1,0x16
    80001fd0:	92448493          	addi	s1,s1,-1756 # 800178f0 <tickslock>
      if(ticks >= pause_interval)
    80001fd4:	00007917          	auipc	s2,0x7
    80001fd8:	05490913          	addi	s2,s2,84 # 80009028 <pause_interval>
    80001fdc:	a811                	j	80001ff0 <scheduler+0x92>
      release(&tickslock);
    80001fde:	8526                	mv	a0,s1
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	cba080e7          	jalr	-838(ra) # 80000c9a <release>
    while(paused)
    80001fe8:	000c2783          	lw	a5,0(s8)
    80001fec:	2781                	sext.w	a5,a5
    80001fee:	c795                	beqz	a5,8000201a <scheduler+0xbc>
      acquire(&tickslock);
    80001ff0:	8526                	mv	a0,s1
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	bf4080e7          	jalr	-1036(ra) # 80000be6 <acquire>
      if(ticks >= pause_interval)
    80001ffa:	00092783          	lw	a5,0(s2)
    80001ffe:	2781                	sext.w	a5,a5
    80002000:	000b2703          	lw	a4,0(s6)
    80002004:	fcf76de3          	bltu	a4,a5,80001fde <scheduler+0x80>
        paused ^= paused;
    80002008:	000c2703          	lw	a4,0(s8)
    8000200c:	000c2783          	lw	a5,0(s8)
    80002010:	8fb9                	xor	a5,a5,a4
    80002012:	2781                	sext.w	a5,a5
    80002014:	00fc2023          	sw	a5,0(s8)
    80002018:	b7d9                	j	80001fde <scheduler+0x80>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000201a:	0000f917          	auipc	s2,0xf
    8000201e:	6d690913          	addi	s2,s2,1750 # 800116f0 <proc>
      if(p->state == RUNNABLE) 
    80002022:	4a8d                	li	s5,3
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    80002024:	00016a17          	auipc	s4,0x16
    80002028:	8cca0a13          	addi	s4,s4,-1844 # 800178f0 <tickslock>
          if(hp->state == RUNNING){
    8000202c:	4d11                	li	s10,4
          if(hp->state == SLEEPING){
    8000202e:	4c89                	li	s9,2
    80002030:	a0e9                	j	800020fa <scheduler+0x19c>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    80002032:	18890493          	addi	s1,s2,392
    80002036:	0544f363          	bgeu	s1,s4,8000207c <scheduler+0x11e>
    8000203a:	89ca                	mv	s3,s2
    8000203c:	a811                	j	80002050 <scheduler+0xf2>
            release(&c->lock);
    8000203e:	8526                	mv	a0,s1
    80002040:	fffff097          	auipc	ra,0xfffff
    80002044:	c5a080e7          	jalr	-934(ra) # 80000c9a <release>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    80002048:	18848493          	addi	s1,s1,392
    8000204c:	0344f963          	bgeu	s1,s4,8000207e <scheduler+0x120>
           acquire(&c->lock);
    80002050:	8526                	mv	a0,s1
    80002052:	fffff097          	auipc	ra,0xfffff
    80002056:	b94080e7          	jalr	-1132(ra) # 80000be6 <acquire>
           if((c->state == RUNNABLE) && (c->mean_ticks < hp->mean_ticks))
    8000205a:	4c9c                	lw	a5,24(s1)
    8000205c:	2781                	sext.w	a5,a5
    8000205e:	ff5790e3          	bne	a5,s5,8000203e <scheduler+0xe0>
    80002062:	1684a703          	lw	a4,360(s1)
    80002066:	1689a783          	lw	a5,360(s3)
    8000206a:	fcf77ae3          	bgeu	a4,a5,8000203e <scheduler+0xe0>
             release(&hp->lock);
    8000206e:	854e                	mv	a0,s3
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	c2a080e7          	jalr	-982(ra) # 80000c9a <release>
             hp = c;
    80002078:	89a6                	mv	s3,s1
    8000207a:	b7f9                	j	80002048 <scheduler+0xea>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    8000207c:	89ca                	mv	s3,s2
          int diff = ticks - hp->last_update_time;
    8000207e:	000b2483          	lw	s1,0(s6)
    80002082:	1809a783          	lw	a5,384(s3)
    80002086:	40f487bb          	subw	a5,s1,a5
          hp->last_update_time = ticks;
    8000208a:	1899a023          	sw	s1,384(s3)
          if(hp->state == RUNNABLE){
    8000208e:	0189a703          	lw	a4,24(s3)
    80002092:	2701                	sext.w	a4,a4
    80002094:	09570363          	beq	a4,s5,8000211a <scheduler+0x1bc>
          if(hp->state == RUNNING){
    80002098:	0189a703          	lw	a4,24(s3)
    8000209c:	2701                	sext.w	a4,a4
    8000209e:	09a70463          	beq	a4,s10,80002126 <scheduler+0x1c8>
          if(hp->state == SLEEPING){
    800020a2:	0189a703          	lw	a4,24(s3)
    800020a6:	2701                	sext.w	a4,a4
    800020a8:	09970563          	beq	a4,s9,80002132 <scheduler+0x1d4>
         hp->state = RUNNING;
    800020ac:	4791                	li	a5,4
    800020ae:	00f9ac23          	sw	a5,24(s3)
         c->proc = hp;
    800020b2:	033bb823          	sd	s3,48(s7)
         swtch(&c->context, &hp->context);
    800020b6:	06098593          	addi	a1,s3,96
    800020ba:	856e                	mv	a0,s11
    800020bc:	00001097          	auipc	ra,0x1
    800020c0:	b58080e7          	jalr	-1192(ra) # 80002c14 <swtch>
         burst = ticks - burst;
    800020c4:	000b2703          	lw	a4,0(s6)
    800020c8:	9f05                	subw	a4,a4,s1
         hp->last_ticks = burst;
    800020ca:	16e9a623          	sw	a4,364(s3)
         hp->mean_ticks = ((10 - rate) * hp->mean_ticks + burst * rate) / 10;
    800020ce:	1689a783          	lw	a5,360(s3)
    800020d2:	9f3d                	addw	a4,a4,a5
    800020d4:	0027179b          	slliw	a5,a4,0x2
    800020d8:	9fb9                	addw	a5,a5,a4
    800020da:	4729                	li	a4,10
    800020dc:	02e7d7bb          	divuw	a5,a5,a4
    800020e0:	16f9a423          	sw	a5,360(s3)
         c->proc = 0;
    800020e4:	020bb823          	sd	zero,48(s7)
         release(&hp->lock);
    800020e8:	854e                	mv	a0,s3
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	bb0080e7          	jalr	-1104(ra) # 80000c9a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800020f2:	18890913          	addi	s2,s2,392
    800020f6:	ed4901e3          	beq	s2,s4,80001fb8 <scheduler+0x5a>
      acquire(&p->lock);
    800020fa:	854a                	mv	a0,s2
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	aea080e7          	jalr	-1302(ra) # 80000be6 <acquire>
      if(p->state == RUNNABLE) 
    80002104:	01892783          	lw	a5,24(s2)
    80002108:	2781                	sext.w	a5,a5
    8000210a:	f35784e3          	beq	a5,s5,80002032 <scheduler+0xd4>
        release(&p->lock);
    8000210e:	854a                	mv	a0,s2
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	b8a080e7          	jalr	-1142(ra) # 80000c9a <release>
    80002118:	bfe9                	j	800020f2 <scheduler+0x194>
            hp->runnable_time += diff;
    8000211a:	17c9a703          	lw	a4,380(s3)
    8000211e:	9f3d                	addw	a4,a4,a5
    80002120:	16e9ae23          	sw	a4,380(s3)
    80002124:	bf95                	j	80002098 <scheduler+0x13a>
            hp->running_time += diff;
    80002126:	1789a703          	lw	a4,376(s3)
    8000212a:	9f3d                	addw	a4,a4,a5
    8000212c:	16e9ac23          	sw	a4,376(s3)
    80002130:	bf8d                	j	800020a2 <scheduler+0x144>
            hp->sleeping_time += diff;
    80002132:	1749a703          	lw	a4,372(s3)
    80002136:	9fb9                	addw	a5,a5,a4
    80002138:	16f9aa23          	sw	a5,372(s3)
    8000213c:	bf85                	j	800020ac <scheduler+0x14e>

000000008000213e <sched>:
{
    8000213e:	7179                	addi	sp,sp,-48
    80002140:	f406                	sd	ra,40(sp)
    80002142:	f022                	sd	s0,32(sp)
    80002144:	ec26                	sd	s1,24(sp)
    80002146:	e84a                	sd	s2,16(sp)
    80002148:	e44e                	sd	s3,8(sp)
    8000214a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	8a6080e7          	jalr	-1882(ra) # 800019f2 <myproc>
    80002154:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	a16080e7          	jalr	-1514(ra) # 80000b6c <holding>
    8000215e:	cd25                	beqz	a0,800021d6 <sched+0x98>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002160:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002162:	2781                	sext.w	a5,a5
    80002164:	079e                	slli	a5,a5,0x7
    80002166:	0000f717          	auipc	a4,0xf
    8000216a:	15a70713          	addi	a4,a4,346 # 800112c0 <pid_lock>
    8000216e:	97ba                	add	a5,a5,a4
    80002170:	0a87a703          	lw	a4,168(a5)
    80002174:	4785                	li	a5,1
    80002176:	06f71863          	bne	a4,a5,800021e6 <sched+0xa8>
  if(p->state == RUNNING)
    8000217a:	4c9c                	lw	a5,24(s1)
    8000217c:	2781                	sext.w	a5,a5
    8000217e:	4711                	li	a4,4
    80002180:	06e78b63          	beq	a5,a4,800021f6 <sched+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002184:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002188:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000218a:	efb5                	bnez	a5,80002206 <sched+0xc8>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000218c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000218e:	0000f917          	auipc	s2,0xf
    80002192:	13290913          	addi	s2,s2,306 # 800112c0 <pid_lock>
    80002196:	2781                	sext.w	a5,a5
    80002198:	079e                	slli	a5,a5,0x7
    8000219a:	97ca                	add	a5,a5,s2
    8000219c:	0ac7a983          	lw	s3,172(a5)
    800021a0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021a2:	2781                	sext.w	a5,a5
    800021a4:	079e                	slli	a5,a5,0x7
    800021a6:	0000f597          	auipc	a1,0xf
    800021aa:	15258593          	addi	a1,a1,338 # 800112f8 <cpus+0x8>
    800021ae:	95be                	add	a1,a1,a5
    800021b0:	06048513          	addi	a0,s1,96
    800021b4:	00001097          	auipc	ra,0x1
    800021b8:	a60080e7          	jalr	-1440(ra) # 80002c14 <swtch>
    800021bc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021be:	2781                	sext.w	a5,a5
    800021c0:	079e                	slli	a5,a5,0x7
    800021c2:	97ca                	add	a5,a5,s2
    800021c4:	0b37a623          	sw	s3,172(a5)
}
    800021c8:	70a2                	ld	ra,40(sp)
    800021ca:	7402                	ld	s0,32(sp)
    800021cc:	64e2                	ld	s1,24(sp)
    800021ce:	6942                	ld	s2,16(sp)
    800021d0:	69a2                	ld	s3,8(sp)
    800021d2:	6145                	addi	sp,sp,48
    800021d4:	8082                	ret
    panic("sched p->lock");
    800021d6:	00006517          	auipc	a0,0x6
    800021da:	04250513          	addi	a0,a0,66 # 80008218 <digits+0x1d8>
    800021de:	ffffe097          	auipc	ra,0xffffe
    800021e2:	362080e7          	jalr	866(ra) # 80000540 <panic>
    panic("sched locks");
    800021e6:	00006517          	auipc	a0,0x6
    800021ea:	04250513          	addi	a0,a0,66 # 80008228 <digits+0x1e8>
    800021ee:	ffffe097          	auipc	ra,0xffffe
    800021f2:	352080e7          	jalr	850(ra) # 80000540 <panic>
    panic("sched running");
    800021f6:	00006517          	auipc	a0,0x6
    800021fa:	04250513          	addi	a0,a0,66 # 80008238 <digits+0x1f8>
    800021fe:	ffffe097          	auipc	ra,0xffffe
    80002202:	342080e7          	jalr	834(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002206:	00006517          	auipc	a0,0x6
    8000220a:	04250513          	addi	a0,a0,66 # 80008248 <digits+0x208>
    8000220e:	ffffe097          	auipc	ra,0xffffe
    80002212:	332080e7          	jalr	818(ra) # 80000540 <panic>

0000000080002216 <yield>:
{
    80002216:	1101                	addi	sp,sp,-32
    80002218:	ec06                	sd	ra,24(sp)
    8000221a:	e822                	sd	s0,16(sp)
    8000221c:	e426                	sd	s1,8(sp)
    8000221e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	7d2080e7          	jalr	2002(ra) # 800019f2 <myproc>
    80002228:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	9bc080e7          	jalr	-1604(ra) # 80000be6 <acquire>
  int diff = ticks - p->last_update_time;
    80002232:	00007717          	auipc	a4,0x7
    80002236:	e2272703          	lw	a4,-478(a4) # 80009054 <ticks>
    8000223a:	1804a783          	lw	a5,384(s1)
    8000223e:	40f707bb          	subw	a5,a4,a5
  p->last_update_time = ticks;
    80002242:	18e4a023          	sw	a4,384(s1)
  if(p->state == RUNNABLE){
    80002246:	4c98                	lw	a4,24(s1)
    80002248:	2701                	sext.w	a4,a4
    8000224a:	468d                	li	a3,3
    8000224c:	02d70c63          	beq	a4,a3,80002284 <yield+0x6e>
  if(p->state == RUNNING){
    80002250:	4c98                	lw	a4,24(s1)
    80002252:	2701                	sext.w	a4,a4
    80002254:	4691                	li	a3,4
    80002256:	02d70d63          	beq	a4,a3,80002290 <yield+0x7a>
  if(p->state == SLEEPING){
    8000225a:	4c98                	lw	a4,24(s1)
    8000225c:	2701                	sext.w	a4,a4
    8000225e:	4689                	li	a3,2
    80002260:	02d70e63          	beq	a4,a3,8000229c <yield+0x86>
  p->state = RUNNABLE;
    80002264:	478d                	li	a5,3
    80002266:	cc9c                	sw	a5,24(s1)
  sched();
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	ed6080e7          	jalr	-298(ra) # 8000213e <sched>
  release(&p->lock);
    80002270:	8526                	mv	a0,s1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	a28080e7          	jalr	-1496(ra) # 80000c9a <release>
}
    8000227a:	60e2                	ld	ra,24(sp)
    8000227c:	6442                	ld	s0,16(sp)
    8000227e:	64a2                	ld	s1,8(sp)
    80002280:	6105                	addi	sp,sp,32
    80002282:	8082                	ret
    p->runnable_time += diff;
    80002284:	17c4a703          	lw	a4,380(s1)
    80002288:	9f3d                	addw	a4,a4,a5
    8000228a:	16e4ae23          	sw	a4,380(s1)
    8000228e:	b7c9                	j	80002250 <yield+0x3a>
    p->running_time += diff;
    80002290:	1784a703          	lw	a4,376(s1)
    80002294:	9f3d                	addw	a4,a4,a5
    80002296:	16e4ac23          	sw	a4,376(s1)
    8000229a:	b7c1                	j	8000225a <yield+0x44>
    p->sleeping_time += diff;
    8000229c:	1744a703          	lw	a4,372(s1)
    800022a0:	9fb9                	addw	a5,a5,a4
    800022a2:	16f4aa23          	sw	a5,372(s1)
    800022a6:	bf7d                	j	80002264 <yield+0x4e>

00000000800022a8 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800022a8:	7179                	addi	sp,sp,-48
    800022aa:	f406                	sd	ra,40(sp)
    800022ac:	f022                	sd	s0,32(sp)
    800022ae:	ec26                	sd	s1,24(sp)
    800022b0:	e84a                	sd	s2,16(sp)
    800022b2:	e44e                	sd	s3,8(sp)
    800022b4:	1800                	addi	s0,sp,48
    800022b6:	89aa                	mv	s3,a0
    800022b8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	738080e7          	jalr	1848(ra) # 800019f2 <myproc>
    800022c2:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	922080e7          	jalr	-1758(ra) # 80000be6 <acquire>
  release(lk);
    800022cc:	854a                	mv	a0,s2
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	9cc080e7          	jalr	-1588(ra) # 80000c9a <release>

  // Go to sleep.
  p->chan = chan;
    800022d6:	0334b023          	sd	s3,32(s1)

  //calc thicks passed
  //acquire(&tickslock);
  int diff = ticks - p->last_update_time;
    800022da:	00007717          	auipc	a4,0x7
    800022de:	d7a72703          	lw	a4,-646(a4) # 80009054 <ticks>
    800022e2:	1804a783          	lw	a5,384(s1)
    800022e6:	40f707bb          	subw	a5,a4,a5
  //release(&tickslock);
  p->last_update_time = ticks;
    800022ea:	18e4a023          	sw	a4,384(s1)

  if(p->state == RUNNABLE){
    800022ee:	4c98                	lw	a4,24(s1)
    800022f0:	2701                	sext.w	a4,a4
    800022f2:	468d                	li	a3,3
    800022f4:	04d70563          	beq	a4,a3,8000233e <sleep+0x96>
    p->runnable_time += diff;
  }
  if(p->state == RUNNING){
    800022f8:	4c98                	lw	a4,24(s1)
    800022fa:	2701                	sext.w	a4,a4
    800022fc:	4691                	li	a3,4
    800022fe:	04d70663          	beq	a4,a3,8000234a <sleep+0xa2>
    p->running_time += diff;
  }
  if(p->state == SLEEPING){
    80002302:	4c98                	lw	a4,24(s1)
    80002304:	2701                	sext.w	a4,a4
    80002306:	4689                	li	a3,2
    80002308:	04d70763          	beq	a4,a3,80002356 <sleep+0xae>
    p->sleeping_time += diff;
  }

  p->state = SLEEPING;
    8000230c:	4789                	li	a5,2
    8000230e:	cc9c                	sw	a5,24(s1)

  sched();
    80002310:	00000097          	auipc	ra,0x0
    80002314:	e2e080e7          	jalr	-466(ra) # 8000213e <sched>

  // Tidy up.
  p->chan = 0;
    80002318:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000231c:	8526                	mv	a0,s1
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	97c080e7          	jalr	-1668(ra) # 80000c9a <release>
  acquire(lk);
    80002326:	854a                	mv	a0,s2
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	8be080e7          	jalr	-1858(ra) # 80000be6 <acquire>
}
    80002330:	70a2                	ld	ra,40(sp)
    80002332:	7402                	ld	s0,32(sp)
    80002334:	64e2                	ld	s1,24(sp)
    80002336:	6942                	ld	s2,16(sp)
    80002338:	69a2                	ld	s3,8(sp)
    8000233a:	6145                	addi	sp,sp,48
    8000233c:	8082                	ret
    p->runnable_time += diff;
    8000233e:	17c4a703          	lw	a4,380(s1)
    80002342:	9f3d                	addw	a4,a4,a5
    80002344:	16e4ae23          	sw	a4,380(s1)
    80002348:	bf45                	j	800022f8 <sleep+0x50>
    p->running_time += diff;
    8000234a:	1784a703          	lw	a4,376(s1)
    8000234e:	9f3d                	addw	a4,a4,a5
    80002350:	16e4ac23          	sw	a4,376(s1)
    80002354:	b77d                	j	80002302 <sleep+0x5a>
    p->sleeping_time += diff;
    80002356:	1744a703          	lw	a4,372(s1)
    8000235a:	9fb9                	addw	a5,a5,a4
    8000235c:	16f4aa23          	sw	a5,372(s1)
    80002360:	b775                	j	8000230c <sleep+0x64>

0000000080002362 <wait>:
{
    80002362:	715d                	addi	sp,sp,-80
    80002364:	e486                	sd	ra,72(sp)
    80002366:	e0a2                	sd	s0,64(sp)
    80002368:	fc26                	sd	s1,56(sp)
    8000236a:	f84a                	sd	s2,48(sp)
    8000236c:	f44e                	sd	s3,40(sp)
    8000236e:	f052                	sd	s4,32(sp)
    80002370:	ec56                	sd	s5,24(sp)
    80002372:	e85a                	sd	s6,16(sp)
    80002374:	e45e                	sd	s7,8(sp)
    80002376:	e062                	sd	s8,0(sp)
    80002378:	0880                	addi	s0,sp,80
    8000237a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	676080e7          	jalr	1654(ra) # 800019f2 <myproc>
    80002384:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002386:	0000f517          	auipc	a0,0xf
    8000238a:	f5250513          	addi	a0,a0,-174 # 800112d8 <wait_lock>
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	858080e7          	jalr	-1960(ra) # 80000be6 <acquire>
    havekids = 0;
    80002396:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002398:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000239a:	00015997          	auipc	s3,0x15
    8000239e:	55698993          	addi	s3,s3,1366 # 800178f0 <tickslock>
        havekids = 1;
    800023a2:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023a4:	0000fc17          	auipc	s8,0xf
    800023a8:	f34c0c13          	addi	s8,s8,-204 # 800112d8 <wait_lock>
    havekids = 0;
    800023ac:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023ae:	0000f497          	auipc	s1,0xf
    800023b2:	34248493          	addi	s1,s1,834 # 800116f0 <proc>
    800023b6:	a0bd                	j	80002424 <wait+0xc2>
          pid = np->pid;
    800023b8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023bc:	000b0e63          	beqz	s6,800023d8 <wait+0x76>
    800023c0:	4691                	li	a3,4
    800023c2:	02c48613          	addi	a2,s1,44
    800023c6:	85da                	mv	a1,s6
    800023c8:	05093503          	ld	a0,80(s2)
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	2a8080e7          	jalr	680(ra) # 80001674 <copyout>
    800023d4:	02054563          	bltz	a0,800023fe <wait+0x9c>
          freeproc(np);
    800023d8:	8526                	mv	a0,s1
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	7ca080e7          	jalr	1994(ra) # 80001ba4 <freeproc>
          release(&np->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	8b6080e7          	jalr	-1866(ra) # 80000c9a <release>
          release(&wait_lock);
    800023ec:	0000f517          	auipc	a0,0xf
    800023f0:	eec50513          	addi	a0,a0,-276 # 800112d8 <wait_lock>
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	8a6080e7          	jalr	-1882(ra) # 80000c9a <release>
          return pid;
    800023fc:	a0ad                	j	80002466 <wait+0x104>
            release(&np->lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	89a080e7          	jalr	-1894(ra) # 80000c9a <release>
            release(&wait_lock);
    80002408:	0000f517          	auipc	a0,0xf
    8000240c:	ed050513          	addi	a0,a0,-304 # 800112d8 <wait_lock>
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	88a080e7          	jalr	-1910(ra) # 80000c9a <release>
            return -1;
    80002418:	59fd                	li	s3,-1
    8000241a:	a0b1                	j	80002466 <wait+0x104>
    for(np = proc; np < &proc[NPROC]; np++){
    8000241c:	18848493          	addi	s1,s1,392
    80002420:	03348563          	beq	s1,s3,8000244a <wait+0xe8>
      if(np->parent == p){
    80002424:	7c9c                	ld	a5,56(s1)
    80002426:	ff279be3          	bne	a5,s2,8000241c <wait+0xba>
        acquire(&np->lock);
    8000242a:	8526                	mv	a0,s1
    8000242c:	ffffe097          	auipc	ra,0xffffe
    80002430:	7ba080e7          	jalr	1978(ra) # 80000be6 <acquire>
        if(np->state == ZOMBIE){
    80002434:	4c9c                	lw	a5,24(s1)
    80002436:	2781                	sext.w	a5,a5
    80002438:	f94780e3          	beq	a5,s4,800023b8 <wait+0x56>
        release(&np->lock);
    8000243c:	8526                	mv	a0,s1
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	85c080e7          	jalr	-1956(ra) # 80000c9a <release>
        havekids = 1;
    80002446:	8756                	mv	a4,s5
    80002448:	bfd1                	j	8000241c <wait+0xba>
    if(!havekids || p->killed){
    8000244a:	c709                	beqz	a4,80002454 <wait+0xf2>
    8000244c:	02892783          	lw	a5,40(s2)
    80002450:	2781                	sext.w	a5,a5
    80002452:	c79d                	beqz	a5,80002480 <wait+0x11e>
      release(&wait_lock);
    80002454:	0000f517          	auipc	a0,0xf
    80002458:	e8450513          	addi	a0,a0,-380 # 800112d8 <wait_lock>
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	83e080e7          	jalr	-1986(ra) # 80000c9a <release>
      return -1;
    80002464:	59fd                	li	s3,-1
}
    80002466:	854e                	mv	a0,s3
    80002468:	60a6                	ld	ra,72(sp)
    8000246a:	6406                	ld	s0,64(sp)
    8000246c:	74e2                	ld	s1,56(sp)
    8000246e:	7942                	ld	s2,48(sp)
    80002470:	79a2                	ld	s3,40(sp)
    80002472:	7a02                	ld	s4,32(sp)
    80002474:	6ae2                	ld	s5,24(sp)
    80002476:	6b42                	ld	s6,16(sp)
    80002478:	6ba2                	ld	s7,8(sp)
    8000247a:	6c02                	ld	s8,0(sp)
    8000247c:	6161                	addi	sp,sp,80
    8000247e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002480:	85e2                	mv	a1,s8
    80002482:	854a                	mv	a0,s2
    80002484:	00000097          	auipc	ra,0x0
    80002488:	e24080e7          	jalr	-476(ra) # 800022a8 <sleep>
    havekids = 0;
    8000248c:	b705                	j	800023ac <wait+0x4a>

000000008000248e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000248e:	711d                	addi	sp,sp,-96
    80002490:	ec86                	sd	ra,88(sp)
    80002492:	e8a2                	sd	s0,80(sp)
    80002494:	e4a6                	sd	s1,72(sp)
    80002496:	e0ca                	sd	s2,64(sp)
    80002498:	fc4e                	sd	s3,56(sp)
    8000249a:	f852                	sd	s4,48(sp)
    8000249c:	f456                	sd	s5,40(sp)
    8000249e:	f05a                	sd	s6,32(sp)
    800024a0:	ec5e                	sd	s7,24(sp)
    800024a2:	e862                	sd	s8,16(sp)
    800024a4:	e466                	sd	s9,8(sp)
    800024a6:	1080                	addi	s0,sp,96
    800024a8:	8aaa                	mv	s5,a0
  struct proc *p, *mp = myproc();
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	548080e7          	jalr	1352(ra) # 800019f2 <myproc>
    800024b2:	892a                	mv	s2,a0

  for(p = proc; p < &proc[NPROC]; p++) {
    800024b4:	0000f497          	auipc	s1,0xf
    800024b8:	23c48493          	addi	s1,s1,572 # 800116f0 <proc>
    if(p != mp){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800024bc:	4a09                	li	s4,2
        //calc thicks passed
        //acquire(&tickslock);
        int diff = ticks - p->last_update_time;
    800024be:	00007c97          	auipc	s9,0x7
    800024c2:	b96c8c93          	addi	s9,s9,-1130 # 80009054 <ticks>
        //release(&tickslock);
        p->last_update_time = ticks;

        if(p->state == RUNNABLE){
    800024c6:	4c0d                	li	s8,3
          p->runnable_time += diff;
        }
        if(p->state == RUNNING){
    800024c8:	4b91                	li	s7,4
          p->running_time += diff;
        }
        if(p->state == SLEEPING){
          p->sleeping_time += diff;
        }
        p->state = RUNNABLE;
    800024ca:	4b0d                	li	s6,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800024cc:	00015997          	auipc	s3,0x15
    800024d0:	42498993          	addi	s3,s3,1060 # 800178f0 <tickslock>
    800024d4:	a805                	j	80002504 <wakeup+0x76>
          p->runnable_time += diff;
    800024d6:	17c4a703          	lw	a4,380(s1)
    800024da:	9f3d                	addw	a4,a4,a5
    800024dc:	16e4ae23          	sw	a4,380(s1)
    800024e0:	a8a1                	j	80002538 <wakeup+0xaa>
          p->running_time += diff;
    800024e2:	1784a703          	lw	a4,376(s1)
    800024e6:	9f3d                	addw	a4,a4,a5
    800024e8:	16e4ac23          	sw	a4,376(s1)
    800024ec:	a891                	j	80002540 <wakeup+0xb2>
        p->state = RUNNABLE;
    800024ee:	0164ac23          	sw	s6,24(s1)
        //acquire(&tickslock);
        p->last_runable_time = ticks;
        //release(&tickslock);
        #endif
      }
      release(&p->lock);
    800024f2:	8526                	mv	a0,s1
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	7a6080e7          	jalr	1958(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024fc:	18848493          	addi	s1,s1,392
    80002500:	05348a63          	beq	s1,s3,80002554 <wakeup+0xc6>
    if(p != mp){
    80002504:	fe990ce3          	beq	s2,s1,800024fc <wakeup+0x6e>
      acquire(&p->lock);
    80002508:	8526                	mv	a0,s1
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	6dc080e7          	jalr	1756(ra) # 80000be6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002512:	4c9c                	lw	a5,24(s1)
    80002514:	2781                	sext.w	a5,a5
    80002516:	fd479ee3          	bne	a5,s4,800024f2 <wakeup+0x64>
    8000251a:	709c                	ld	a5,32(s1)
    8000251c:	fd579be3          	bne	a5,s5,800024f2 <wakeup+0x64>
        int diff = ticks - p->last_update_time;
    80002520:	000ca703          	lw	a4,0(s9)
    80002524:	1804a783          	lw	a5,384(s1)
    80002528:	40f707bb          	subw	a5,a4,a5
        p->last_update_time = ticks;
    8000252c:	18e4a023          	sw	a4,384(s1)
        if(p->state == RUNNABLE){
    80002530:	4c98                	lw	a4,24(s1)
    80002532:	2701                	sext.w	a4,a4
    80002534:	fb8701e3          	beq	a4,s8,800024d6 <wakeup+0x48>
        if(p->state == RUNNING){
    80002538:	4c98                	lw	a4,24(s1)
    8000253a:	2701                	sext.w	a4,a4
    8000253c:	fb7703e3          	beq	a4,s7,800024e2 <wakeup+0x54>
        if(p->state == SLEEPING){
    80002540:	4c98                	lw	a4,24(s1)
    80002542:	2701                	sext.w	a4,a4
    80002544:	fb4715e3          	bne	a4,s4,800024ee <wakeup+0x60>
          p->sleeping_time += diff;
    80002548:	1744a703          	lw	a4,372(s1)
    8000254c:	9fb9                	addw	a5,a5,a4
    8000254e:	16f4aa23          	sw	a5,372(s1)
    80002552:	bf71                	j	800024ee <wakeup+0x60>
    }
  }
}
    80002554:	60e6                	ld	ra,88(sp)
    80002556:	6446                	ld	s0,80(sp)
    80002558:	64a6                	ld	s1,72(sp)
    8000255a:	6906                	ld	s2,64(sp)
    8000255c:	79e2                	ld	s3,56(sp)
    8000255e:	7a42                	ld	s4,48(sp)
    80002560:	7aa2                	ld	s5,40(sp)
    80002562:	7b02                	ld	s6,32(sp)
    80002564:	6be2                	ld	s7,24(sp)
    80002566:	6c42                	ld	s8,16(sp)
    80002568:	6ca2                	ld	s9,8(sp)
    8000256a:	6125                	addi	sp,sp,96
    8000256c:	8082                	ret

000000008000256e <reparent>:
{
    8000256e:	7179                	addi	sp,sp,-48
    80002570:	f406                	sd	ra,40(sp)
    80002572:	f022                	sd	s0,32(sp)
    80002574:	ec26                	sd	s1,24(sp)
    80002576:	e84a                	sd	s2,16(sp)
    80002578:	e44e                	sd	s3,8(sp)
    8000257a:	e052                	sd	s4,0(sp)
    8000257c:	1800                	addi	s0,sp,48
    8000257e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002580:	0000f497          	auipc	s1,0xf
    80002584:	17048493          	addi	s1,s1,368 # 800116f0 <proc>
      pp->parent = initproc;
    80002588:	00007a17          	auipc	s4,0x7
    8000258c:	aa8a0a13          	addi	s4,s4,-1368 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002590:	00015997          	auipc	s3,0x15
    80002594:	36098993          	addi	s3,s3,864 # 800178f0 <tickslock>
    80002598:	a029                	j	800025a2 <reparent+0x34>
    8000259a:	18848493          	addi	s1,s1,392
    8000259e:	01348d63          	beq	s1,s3,800025b8 <reparent+0x4a>
    if(pp->parent == p){
    800025a2:	7c9c                	ld	a5,56(s1)
    800025a4:	ff279be3          	bne	a5,s2,8000259a <reparent+0x2c>
      pp->parent = initproc;
    800025a8:	000a3503          	ld	a0,0(s4)
    800025ac:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800025ae:	00000097          	auipc	ra,0x0
    800025b2:	ee0080e7          	jalr	-288(ra) # 8000248e <wakeup>
    800025b6:	b7d5                	j	8000259a <reparent+0x2c>
}
    800025b8:	70a2                	ld	ra,40(sp)
    800025ba:	7402                	ld	s0,32(sp)
    800025bc:	64e2                	ld	s1,24(sp)
    800025be:	6942                	ld	s2,16(sp)
    800025c0:	69a2                	ld	s3,8(sp)
    800025c2:	6a02                	ld	s4,0(sp)
    800025c4:	6145                	addi	sp,sp,48
    800025c6:	8082                	ret

00000000800025c8 <exit>:
{
    800025c8:	7179                	addi	sp,sp,-48
    800025ca:	f406                	sd	ra,40(sp)
    800025cc:	f022                	sd	s0,32(sp)
    800025ce:	ec26                	sd	s1,24(sp)
    800025d0:	e84a                	sd	s2,16(sp)
    800025d2:	e44e                	sd	s3,8(sp)
    800025d4:	e052                	sd	s4,0(sp)
    800025d6:	1800                	addi	s0,sp,48
    800025d8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800025da:	fffff097          	auipc	ra,0xfffff
    800025de:	418080e7          	jalr	1048(ra) # 800019f2 <myproc>
    800025e2:	892a                	mv	s2,a0
  if(p == initproc)
    800025e4:	00007797          	auipc	a5,0x7
    800025e8:	a4c7b783          	ld	a5,-1460(a5) # 80009030 <initproc>
    800025ec:	0d050493          	addi	s1,a0,208
    800025f0:	15050993          	addi	s3,a0,336
    800025f4:	02a79363          	bne	a5,a0,8000261a <exit+0x52>
    panic("init exiting");
    800025f8:	00006517          	auipc	a0,0x6
    800025fc:	c6850513          	addi	a0,a0,-920 # 80008260 <digits+0x220>
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	f40080e7          	jalr	-192(ra) # 80000540 <panic>
      fileclose(f);
    80002608:	00002097          	auipc	ra,0x2
    8000260c:	55e080e7          	jalr	1374(ra) # 80004b66 <fileclose>
      p->ofile[fd] = 0;
    80002610:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002614:	04a1                	addi	s1,s1,8
    80002616:	01348563          	beq	s1,s3,80002620 <exit+0x58>
    if(p->ofile[fd]){
    8000261a:	6088                	ld	a0,0(s1)
    8000261c:	f575                	bnez	a0,80002608 <exit+0x40>
    8000261e:	bfdd                	j	80002614 <exit+0x4c>
  begin_op();
    80002620:	00002097          	auipc	ra,0x2
    80002624:	07a080e7          	jalr	122(ra) # 8000469a <begin_op>
  iput(p->cwd);
    80002628:	15093503          	ld	a0,336(s2)
    8000262c:	00002097          	auipc	ra,0x2
    80002630:	856080e7          	jalr	-1962(ra) # 80003e82 <iput>
  end_op();
    80002634:	00002097          	auipc	ra,0x2
    80002638:	0e6080e7          	jalr	230(ra) # 8000471a <end_op>
  p->cwd = 0;
    8000263c:	14093823          	sd	zero,336(s2)
  acquire(&wait_lock);
    80002640:	0000f517          	auipc	a0,0xf
    80002644:	c9850513          	addi	a0,a0,-872 # 800112d8 <wait_lock>
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	59e080e7          	jalr	1438(ra) # 80000be6 <acquire>
  reparent(p);
    80002650:	854a                	mv	a0,s2
    80002652:	00000097          	auipc	ra,0x0
    80002656:	f1c080e7          	jalr	-228(ra) # 8000256e <reparent>
  wakeup(p->parent);
    8000265a:	03893503          	ld	a0,56(s2)
    8000265e:	00000097          	auipc	ra,0x0
    80002662:	e30080e7          	jalr	-464(ra) # 8000248e <wakeup>
  acquire(&p->lock);
    80002666:	854a                	mv	a0,s2
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	57e080e7          	jalr	1406(ra) # 80000be6 <acquire>
  p->xstate = status;
    80002670:	03492623          	sw	s4,44(s2)
  int diff = ticks - p->last_update_time;
    80002674:	00007697          	auipc	a3,0x7
    80002678:	9e06a683          	lw	a3,-1568(a3) # 80009054 <ticks>
    8000267c:	18092783          	lw	a5,384(s2)
    80002680:	40f687bb          	subw	a5,a3,a5
  p->last_update_time = ticks;
    80002684:	18d92023          	sw	a3,384(s2)
  if(p->state == RUNNABLE){
    80002688:	01892703          	lw	a4,24(s2)
    8000268c:	2701                	sext.w	a4,a4
    8000268e:	460d                	li	a2,3
    80002690:	0cc70c63          	beq	a4,a2,80002768 <exit+0x1a0>
  if(p->state == RUNNING){
    80002694:	01892703          	lw	a4,24(s2)
    80002698:	2701                	sext.w	a4,a4
    8000269a:	4611                	li	a2,4
    8000269c:	0cc70c63          	beq	a4,a2,80002774 <exit+0x1ac>
  if(p->state == SLEEPING){
    800026a0:	01892703          	lw	a4,24(s2)
    800026a4:	2701                	sext.w	a4,a4
    800026a6:	4609                	li	a2,2
    800026a8:	0cc70c63          	beq	a4,a2,80002780 <exit+0x1b8>
  process_count++;
    800026ac:	00007797          	auipc	a5,0x7
    800026b0:	99878793          	addi	a5,a5,-1640 # 80009044 <process_count>
    800026b4:	438c                	lw	a1,0(a5)
    800026b6:	0015861b          	addiw	a2,a1,1
    800026ba:	c390                	sw	a2,0(a5)
  running_processes_mean = ((running_processes_mean * (process_count - 1)) + p->running_time)/ process_count;
    800026bc:	17892503          	lw	a0,376(s2)
    800026c0:	00007797          	auipc	a5,0x7
    800026c4:	98c78793          	addi	a5,a5,-1652 # 8000904c <running_processes_mean>
    800026c8:	4398                	lw	a4,0(a5)
    800026ca:	02b7073b          	mulw	a4,a4,a1
    800026ce:	9f29                	addw	a4,a4,a0
    800026d0:	02c7573b          	divuw	a4,a4,a2
    800026d4:	c398                	sw	a4,0(a5)
  runnable_processes_mean = ((runnable_processes_mean * (process_count - 1)) + p->runnable_time) / process_count;
    800026d6:	00007797          	auipc	a5,0x7
    800026da:	97278793          	addi	a5,a5,-1678 # 80009048 <runnable_processes_mean>
    800026de:	4398                	lw	a4,0(a5)
    800026e0:	02b7073b          	mulw	a4,a4,a1
    800026e4:	17c92803          	lw	a6,380(s2)
    800026e8:	0107073b          	addw	a4,a4,a6
    800026ec:	02c7573b          	divuw	a4,a4,a2
    800026f0:	c398                	sw	a4,0(a5)
  sleeping_processes_mean = ((sleeping_processes_mean * (process_count - 1)) + p->sleeping_time) / process_count;
    800026f2:	00007717          	auipc	a4,0x7
    800026f6:	95e70713          	addi	a4,a4,-1698 # 80009050 <sleeping_processes_mean>
    800026fa:	431c                	lw	a5,0(a4)
    800026fc:	02b787bb          	mulw	a5,a5,a1
    80002700:	17492583          	lw	a1,372(s2)
    80002704:	9fad                	addw	a5,a5,a1
    80002706:	02c7d7bb          	divuw	a5,a5,a2
    8000270a:	c31c                	sw	a5,0(a4)
  program_time += p->running_time;
    8000270c:	00007617          	auipc	a2,0x7
    80002710:	93460613          	addi	a2,a2,-1740 # 80009040 <program_time>
    80002714:	421c                	lw	a5,0(a2)
    80002716:	00a7873b          	addw	a4,a5,a0
    8000271a:	c218                	sw	a4,0(a2)
  cpu_utilization = program_time * 100 / (ticks - start_time);
    8000271c:	06400793          	li	a5,100
    80002720:	02e787bb          	mulw	a5,a5,a4
    80002724:	00007717          	auipc	a4,0x7
    80002728:	91472703          	lw	a4,-1772(a4) # 80009038 <start_time>
    8000272c:	9e99                	subw	a3,a3,a4
    8000272e:	02d7d7bb          	divuw	a5,a5,a3
    80002732:	00007717          	auipc	a4,0x7
    80002736:	90f72523          	sw	a5,-1782(a4) # 8000903c <cpu_utilization>
  p->state = ZOMBIE;
    8000273a:	4795                	li	a5,5
    8000273c:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    80002740:	0000f517          	auipc	a0,0xf
    80002744:	b9850513          	addi	a0,a0,-1128 # 800112d8 <wait_lock>
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	552080e7          	jalr	1362(ra) # 80000c9a <release>
  sched();
    80002750:	00000097          	auipc	ra,0x0
    80002754:	9ee080e7          	jalr	-1554(ra) # 8000213e <sched>
  panic("zombie exit");
    80002758:	00006517          	auipc	a0,0x6
    8000275c:	b1850513          	addi	a0,a0,-1256 # 80008270 <digits+0x230>
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	de0080e7          	jalr	-544(ra) # 80000540 <panic>
    p->runnable_time += diff;
    80002768:	17c92703          	lw	a4,380(s2)
    8000276c:	9f3d                	addw	a4,a4,a5
    8000276e:	16e92e23          	sw	a4,380(s2)
    80002772:	b70d                	j	80002694 <exit+0xcc>
    p->running_time += diff;
    80002774:	17892703          	lw	a4,376(s2)
    80002778:	9f3d                	addw	a4,a4,a5
    8000277a:	16e92c23          	sw	a4,376(s2)
    8000277e:	b70d                	j	800026a0 <exit+0xd8>
    p->sleeping_time += diff;
    80002780:	17492703          	lw	a4,372(s2)
    80002784:	9fb9                	addw	a5,a5,a4
    80002786:	16f92a23          	sw	a5,372(s2)
    8000278a:	b70d                	j	800026ac <exit+0xe4>

000000008000278c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000278c:	7179                	addi	sp,sp,-48
    8000278e:	f406                	sd	ra,40(sp)
    80002790:	f022                	sd	s0,32(sp)
    80002792:	ec26                	sd	s1,24(sp)
    80002794:	e84a                	sd	s2,16(sp)
    80002796:	e44e                	sd	s3,8(sp)
    80002798:	1800                	addi	s0,sp,48
    8000279a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000279c:	0000f497          	auipc	s1,0xf
    800027a0:	f5448493          	addi	s1,s1,-172 # 800116f0 <proc>
    800027a4:	00015997          	auipc	s3,0x15
    800027a8:	14c98993          	addi	s3,s3,332 # 800178f0 <tickslock>
    acquire(&p->lock);
    800027ac:	8526                	mv	a0,s1
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	438080e7          	jalr	1080(ra) # 80000be6 <acquire>
    if(p->pid == pid){
    800027b6:	589c                	lw	a5,48(s1)
    800027b8:	01278d63          	beq	a5,s2,800027d2 <kill+0x46>
        #endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027bc:	8526                	mv	a0,s1
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	4dc080e7          	jalr	1244(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027c6:	18848493          	addi	s1,s1,392
    800027ca:	ff3491e3          	bne	s1,s3,800027ac <kill+0x20>
  }
  return -1;
    800027ce:	557d                	li	a0,-1
    800027d0:	a831                	j	800027ec <kill+0x60>
      p->killed = 1;
    800027d2:	4785                	li	a5,1
    800027d4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800027d6:	4c9c                	lw	a5,24(s1)
    800027d8:	2781                	sext.w	a5,a5
    800027da:	4709                	li	a4,2
    800027dc:	00e78f63          	beq	a5,a4,800027fa <kill+0x6e>
      release(&p->lock);
    800027e0:	8526                	mv	a0,s1
    800027e2:	ffffe097          	auipc	ra,0xffffe
    800027e6:	4b8080e7          	jalr	1208(ra) # 80000c9a <release>
      return 0;
    800027ea:	4501                	li	a0,0
}
    800027ec:	70a2                	ld	ra,40(sp)
    800027ee:	7402                	ld	s0,32(sp)
    800027f0:	64e2                	ld	s1,24(sp)
    800027f2:	6942                	ld	s2,16(sp)
    800027f4:	69a2                	ld	s3,8(sp)
    800027f6:	6145                	addi	sp,sp,48
    800027f8:	8082                	ret
        int diff = ticks - p->last_update_time;
    800027fa:	00007717          	auipc	a4,0x7
    800027fe:	85a72703          	lw	a4,-1958(a4) # 80009054 <ticks>
    80002802:	1804a783          	lw	a5,384(s1)
    80002806:	40f707bb          	subw	a5,a4,a5
        p->last_update_time = ticks;
    8000280a:	18e4a023          	sw	a4,384(s1)
        if(p->state == RUNNABLE){
    8000280e:	4c98                	lw	a4,24(s1)
    80002810:	2701                	sext.w	a4,a4
    80002812:	468d                	li	a3,3
    80002814:	00d70f63          	beq	a4,a3,80002832 <kill+0xa6>
        if(p->state == RUNNING){
    80002818:	4c98                	lw	a4,24(s1)
    8000281a:	2701                	sext.w	a4,a4
    8000281c:	4691                	li	a3,4
    8000281e:	02d70063          	beq	a4,a3,8000283e <kill+0xb2>
        if(p->state == SLEEPING){
    80002822:	4c98                	lw	a4,24(s1)
    80002824:	2701                	sext.w	a4,a4
    80002826:	4689                	li	a3,2
    80002828:	02d70163          	beq	a4,a3,8000284a <kill+0xbe>
        p->state = RUNNABLE;
    8000282c:	478d                	li	a5,3
    8000282e:	cc9c                	sw	a5,24(s1)
    80002830:	bf45                	j	800027e0 <kill+0x54>
          p->runnable_time += diff;
    80002832:	17c4a703          	lw	a4,380(s1)
    80002836:	9f3d                	addw	a4,a4,a5
    80002838:	16e4ae23          	sw	a4,380(s1)
    8000283c:	bff1                	j	80002818 <kill+0x8c>
          p->running_time += diff;
    8000283e:	1784a703          	lw	a4,376(s1)
    80002842:	9f3d                	addw	a4,a4,a5
    80002844:	16e4ac23          	sw	a4,376(s1)
    80002848:	bfe9                	j	80002822 <kill+0x96>
          p->sleeping_time += diff;
    8000284a:	1744a703          	lw	a4,372(s1)
    8000284e:	9fb9                	addw	a5,a5,a4
    80002850:	16f4aa23          	sw	a5,372(s1)
    80002854:	bfe1                	j	8000282c <kill+0xa0>

0000000080002856 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002856:	7179                	addi	sp,sp,-48
    80002858:	f406                	sd	ra,40(sp)
    8000285a:	f022                	sd	s0,32(sp)
    8000285c:	ec26                	sd	s1,24(sp)
    8000285e:	e84a                	sd	s2,16(sp)
    80002860:	e44e                	sd	s3,8(sp)
    80002862:	e052                	sd	s4,0(sp)
    80002864:	1800                	addi	s0,sp,48
    80002866:	84aa                	mv	s1,a0
    80002868:	892e                	mv	s2,a1
    8000286a:	89b2                	mv	s3,a2
    8000286c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000286e:	fffff097          	auipc	ra,0xfffff
    80002872:	184080e7          	jalr	388(ra) # 800019f2 <myproc>
  if(user_dst){
    80002876:	c08d                	beqz	s1,80002898 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002878:	86d2                	mv	a3,s4
    8000287a:	864e                	mv	a2,s3
    8000287c:	85ca                	mv	a1,s2
    8000287e:	6928                	ld	a0,80(a0)
    80002880:	fffff097          	auipc	ra,0xfffff
    80002884:	df4080e7          	jalr	-524(ra) # 80001674 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002888:	70a2                	ld	ra,40(sp)
    8000288a:	7402                	ld	s0,32(sp)
    8000288c:	64e2                	ld	s1,24(sp)
    8000288e:	6942                	ld	s2,16(sp)
    80002890:	69a2                	ld	s3,8(sp)
    80002892:	6a02                	ld	s4,0(sp)
    80002894:	6145                	addi	sp,sp,48
    80002896:	8082                	ret
    memmove((char *)dst, src, len);
    80002898:	000a061b          	sext.w	a2,s4
    8000289c:	85ce                	mv	a1,s3
    8000289e:	854a                	mv	a0,s2
    800028a0:	ffffe097          	auipc	ra,0xffffe
    800028a4:	4a2080e7          	jalr	1186(ra) # 80000d42 <memmove>
    return 0;
    800028a8:	8526                	mv	a0,s1
    800028aa:	bff9                	j	80002888 <either_copyout+0x32>

00000000800028ac <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800028ac:	7179                	addi	sp,sp,-48
    800028ae:	f406                	sd	ra,40(sp)
    800028b0:	f022                	sd	s0,32(sp)
    800028b2:	ec26                	sd	s1,24(sp)
    800028b4:	e84a                	sd	s2,16(sp)
    800028b6:	e44e                	sd	s3,8(sp)
    800028b8:	e052                	sd	s4,0(sp)
    800028ba:	1800                	addi	s0,sp,48
    800028bc:	892a                	mv	s2,a0
    800028be:	84ae                	mv	s1,a1
    800028c0:	89b2                	mv	s3,a2
    800028c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800028c4:	fffff097          	auipc	ra,0xfffff
    800028c8:	12e080e7          	jalr	302(ra) # 800019f2 <myproc>
  if(user_src){
    800028cc:	c08d                	beqz	s1,800028ee <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800028ce:	86d2                	mv	a3,s4
    800028d0:	864e                	mv	a2,s3
    800028d2:	85ca                	mv	a1,s2
    800028d4:	6928                	ld	a0,80(a0)
    800028d6:	fffff097          	auipc	ra,0xfffff
    800028da:	e2a080e7          	jalr	-470(ra) # 80001700 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800028de:	70a2                	ld	ra,40(sp)
    800028e0:	7402                	ld	s0,32(sp)
    800028e2:	64e2                	ld	s1,24(sp)
    800028e4:	6942                	ld	s2,16(sp)
    800028e6:	69a2                	ld	s3,8(sp)
    800028e8:	6a02                	ld	s4,0(sp)
    800028ea:	6145                	addi	sp,sp,48
    800028ec:	8082                	ret
    memmove(dst, (char*)src, len);
    800028ee:	000a061b          	sext.w	a2,s4
    800028f2:	85ce                	mv	a1,s3
    800028f4:	854a                	mv	a0,s2
    800028f6:	ffffe097          	auipc	ra,0xffffe
    800028fa:	44c080e7          	jalr	1100(ra) # 80000d42 <memmove>
    return 0;
    800028fe:	8526                	mv	a0,s1
    80002900:	bff9                	j	800028de <either_copyin+0x32>

0000000080002902 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002902:	715d                	addi	sp,sp,-80
    80002904:	e486                	sd	ra,72(sp)
    80002906:	e0a2                	sd	s0,64(sp)
    80002908:	fc26                	sd	s1,56(sp)
    8000290a:	f84a                	sd	s2,48(sp)
    8000290c:	f44e                	sd	s3,40(sp)
    8000290e:	f052                	sd	s4,32(sp)
    80002910:	ec56                	sd	s5,24(sp)
    80002912:	e85a                	sd	s6,16(sp)
    80002914:	e45e                	sd	s7,8(sp)
    80002916:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002918:	00006517          	auipc	a0,0x6
    8000291c:	a9050513          	addi	a0,a0,-1392 # 800083a8 <digits+0x368>
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	c6a080e7          	jalr	-918(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002928:	0000f497          	auipc	s1,0xf
    8000292c:	dc848493          	addi	s1,s1,-568 # 800116f0 <proc>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002930:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002932:	00006917          	auipc	s2,0x6
    80002936:	94e90913          	addi	s2,s2,-1714 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000293a:	00006a97          	auipc	s5,0x6
    8000293e:	94ea8a93          	addi	s5,s5,-1714 # 80008288 <digits+0x248>
    printf("\n");
    80002942:	00006a17          	auipc	s4,0x6
    80002946:	a66a0a13          	addi	s4,s4,-1434 # 800083a8 <digits+0x368>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000294a:	00006b97          	auipc	s7,0x6
    8000294e:	aaeb8b93          	addi	s7,s7,-1362 # 800083f8 <states.1747>
  for(p = proc; p < &proc[NPROC]; p++){
    80002952:	00015997          	auipc	s3,0x15
    80002956:	f9e98993          	addi	s3,s3,-98 # 800178f0 <tickslock>
    8000295a:	a015                	j	8000297e <procdump+0x7c>
    printf("%d %s %s", p->pid, state, p->name);
    8000295c:	15848693          	addi	a3,s1,344
    80002960:	588c                	lw	a1,48(s1)
    80002962:	8556                	mv	a0,s5
    80002964:	ffffe097          	auipc	ra,0xffffe
    80002968:	c26080e7          	jalr	-986(ra) # 8000058a <printf>
    printf("\n");
    8000296c:	8552                	mv	a0,s4
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	c1c080e7          	jalr	-996(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002976:	18848493          	addi	s1,s1,392
    8000297a:	03348963          	beq	s1,s3,800029ac <procdump+0xaa>
    if(p->state == UNUSED)
    8000297e:	4c9c                	lw	a5,24(s1)
    80002980:	2781                	sext.w	a5,a5
    80002982:	dbf5                	beqz	a5,80002976 <procdump+0x74>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002984:	4c9c                	lw	a5,24(s1)
    80002986:	4c9c                	lw	a5,24(s1)
    80002988:	2781                	sext.w	a5,a5
      state = "???";
    8000298a:	864a                	mv	a2,s2
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000298c:	fcfb68e3          	bltu	s6,a5,8000295c <procdump+0x5a>
    80002990:	4c9c                	lw	a5,24(s1)
    80002992:	1782                	slli	a5,a5,0x20
    80002994:	9381                	srli	a5,a5,0x20
    80002996:	078e                	slli	a5,a5,0x3
    80002998:	97de                	add	a5,a5,s7
    8000299a:	639c                	ld	a5,0(a5)
    8000299c:	d3e1                	beqz	a5,8000295c <procdump+0x5a>
      state = states[p->state];
    8000299e:	4c9c                	lw	a5,24(s1)
    800029a0:	1782                	slli	a5,a5,0x20
    800029a2:	9381                	srli	a5,a5,0x20
    800029a4:	078e                	slli	a5,a5,0x3
    800029a6:	97de                	add	a5,a5,s7
    800029a8:	6390                	ld	a2,0(a5)
    800029aa:	bf4d                	j	8000295c <procdump+0x5a>
  }
}
    800029ac:	60a6                	ld	ra,72(sp)
    800029ae:	6406                	ld	s0,64(sp)
    800029b0:	74e2                	ld	s1,56(sp)
    800029b2:	7942                	ld	s2,48(sp)
    800029b4:	79a2                	ld	s3,40(sp)
    800029b6:	7a02                	ld	s4,32(sp)
    800029b8:	6ae2                	ld	s5,24(sp)
    800029ba:	6b42                	ld	s6,16(sp)
    800029bc:	6ba2                	ld	s7,8(sp)
    800029be:	6161                	addi	sp,sp,80
    800029c0:	8082                	ret

00000000800029c2 <pause_system>:

int
pause_system(const int seconds)
{
    800029c2:	1101                	addi	sp,sp,-32
    800029c4:	ec06                	sd	ra,24(sp)
    800029c6:	e822                	sd	s0,16(sp)
    800029c8:	e426                	sd	s1,8(sp)
    800029ca:	e04a                	sd	s2,0(sp)
    800029cc:	1000                	addi	s0,sp,32
    800029ce:	892a                	mv	s2,a0
  while(paused)
    800029d0:	00006797          	auipc	a5,0x6
    800029d4:	65c7a783          	lw	a5,1628(a5) # 8000902c <paused>
    800029d8:	cf81                	beqz	a5,800029f0 <pause_system+0x2e>
    800029da:	00006497          	auipc	s1,0x6
    800029de:	65248493          	addi	s1,s1,1618 # 8000902c <paused>
    yield();
    800029e2:	00000097          	auipc	ra,0x0
    800029e6:	834080e7          	jalr	-1996(ra) # 80002216 <yield>
  while(paused)
    800029ea:	409c                	lw	a5,0(s1)
    800029ec:	2781                	sext.w	a5,a5
    800029ee:	fbf5                	bnez	a5,800029e2 <pause_system+0x20>

  // print for debug
  struct proc* p = myproc();
    800029f0:	fffff097          	auipc	ra,0xfffff
    800029f4:	002080e7          	jalr	2(ra) # 800019f2 <myproc>
  if(p->killed)
    800029f8:	5504                	lw	s1,40(a0)
    800029fa:	2481                	sext.w	s1,s1
    800029fc:	e0a5                	bnez	s1,80002a5c <pause_system+0x9a>
  {
    printf("Pronc: %s, number: %d died during pause_sytem execution\n", p->name, p->pid);
    return -1;  
  }

  printf("Proc: %s, number: %d pause system\n", p->name, p->pid);
    800029fe:	5910                	lw	a2,48(a0)
    80002a00:	15850593          	addi	a1,a0,344
    80002a04:	00006517          	auipc	a0,0x6
    80002a08:	8d450513          	addi	a0,a0,-1836 # 800082d8 <digits+0x298>
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	b7e080e7          	jalr	-1154(ra) # 8000058a <printf>

  paused |= 1;
    80002a14:	00006797          	auipc	a5,0x6
    80002a18:	6187a783          	lw	a5,1560(a5) # 8000902c <paused>
    80002a1c:	0017e793          	ori	a5,a5,1
    80002a20:	00006717          	auipc	a4,0x6
    80002a24:	60f72623          	sw	a5,1548(a4) # 8000902c <paused>
  //acquire(&tickslock);
  pause_interval = ticks + (seconds * 10);
    80002a28:	0029179b          	slliw	a5,s2,0x2
    80002a2c:	012787bb          	addw	a5,a5,s2
    80002a30:	0017979b          	slliw	a5,a5,0x1
    80002a34:	00006717          	auipc	a4,0x6
    80002a38:	62072703          	lw	a4,1568(a4) # 80009054 <ticks>
    80002a3c:	9fb9                	addw	a5,a5,a4
    80002a3e:	00006717          	auipc	a4,0x6
    80002a42:	5ef72523          	sw	a5,1514(a4) # 80009028 <pause_interval>
  //release(&tickslock);

  yield();
    80002a46:	fffff097          	auipc	ra,0xfffff
    80002a4a:	7d0080e7          	jalr	2000(ra) # 80002216 <yield>
  return 0;
}
    80002a4e:	8526                	mv	a0,s1
    80002a50:	60e2                	ld	ra,24(sp)
    80002a52:	6442                	ld	s0,16(sp)
    80002a54:	64a2                	ld	s1,8(sp)
    80002a56:	6902                	ld	s2,0(sp)
    80002a58:	6105                	addi	sp,sp,32
    80002a5a:	8082                	ret
    printf("Pronc: %s, number: %d died during pause_sytem execution\n", p->name, p->pid);
    80002a5c:	5910                	lw	a2,48(a0)
    80002a5e:	15850593          	addi	a1,a0,344
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	83650513          	addi	a0,a0,-1994 # 80008298 <digits+0x258>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	b20080e7          	jalr	-1248(ra) # 8000058a <printf>
    return -1;  
    80002a72:	54fd                	li	s1,-1
    80002a74:	bfe9                	j	80002a4e <pause_system+0x8c>

0000000080002a76 <kill_system>:

#define INIT_SH_PROC 2
int 
kill_system(void)
{
    80002a76:	711d                	addi	sp,sp,-96
    80002a78:	ec86                	sd	ra,88(sp)
    80002a7a:	e8a2                	sd	s0,80(sp)
    80002a7c:	e4a6                	sd	s1,72(sp)
    80002a7e:	e0ca                	sd	s2,64(sp)
    80002a80:	fc4e                	sd	s3,56(sp)
    80002a82:	f852                	sd	s4,48(sp)
    80002a84:	f456                	sd	s5,40(sp)
    80002a86:	f05a                	sd	s6,32(sp)
    80002a88:	ec5e                	sd	s7,24(sp)
    80002a8a:	e862                	sd	s8,16(sp)
    80002a8c:	e466                	sd	s9,8(sp)
    80002a8e:	1080                	addi	s0,sp,96

  struct proc* p;
  // Below parameters are used for debug.
  struct proc* mp = myproc();
    80002a90:	fffff097          	auipc	ra,0xfffff
    80002a94:	f62080e7          	jalr	-158(ra) # 800019f2 <myproc>
  int pid = mp->pid;
    80002a98:	03052b83          	lw	s7,48(a0)
  const char* name = mp->name;
    80002a9c:	15850a93          	addi	s5,a0,344


  /* 
  * Set killed flag for all process besides init & sh.
  */
  for(p = proc; p < &proc[NPROC]; p++)
    80002aa0:	0000f497          	auipc	s1,0xf
    80002aa4:	c5048493          	addi	s1,s1,-944 # 800116f0 <proc>
  {
      acquire(&p->lock);
      if(p->pid > INIT_SH_PROC && p->state && !p->killed)
    80002aa8:	4909                	li	s2,2
      {
        printf("Proc: %s number: %d KILL proc: %s number: %d\n",name, pid, p->name, p->pid);
    80002aaa:	00006b17          	auipc	s6,0x6
    80002aae:	856b0b13          	addi	s6,s6,-1962 # 80008300 <digits+0x2c0>
        p->killed |= 1;
        if(p->state == SLEEPING){
          //calc thicks passed
          //calc thicks passed
          //acquire(&tickslock);
          int diff = ticks - p->last_update_time;
    80002ab2:	00006c97          	auipc	s9,0x6
    80002ab6:	5a2c8c93          	addi	s9,s9,1442 # 80009054 <ticks>
          //release(&tickslock);
          p->last_update_time = ticks;
          p->sleeping_time += diff;
          //update means...
          p->state = RUNNABLE;
    80002aba:	4c0d                	li	s8,3
  for(p = proc; p < &proc[NPROC]; p++)
    80002abc:	00015a17          	auipc	s4,0x15
    80002ac0:	e34a0a13          	addi	s4,s4,-460 # 800178f0 <tickslock>
    80002ac4:	a811                	j	80002ad8 <kill_system+0x62>
        }
      }
      release(&p->lock);
    80002ac6:	8526                	mv	a0,s1
    80002ac8:	ffffe097          	auipc	ra,0xffffe
    80002acc:	1d2080e7          	jalr	466(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++)
    80002ad0:	18848493          	addi	s1,s1,392
    80002ad4:	07448163          	beq	s1,s4,80002b36 <kill_system+0xc0>
      acquire(&p->lock);
    80002ad8:	8526                	mv	a0,s1
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	10c080e7          	jalr	268(ra) # 80000be6 <acquire>
      if(p->pid > INIT_SH_PROC && p->state && !p->killed)
    80002ae2:	5898                	lw	a4,48(s1)
    80002ae4:	fee951e3          	bge	s2,a4,80002ac6 <kill_system+0x50>
    80002ae8:	4c9c                	lw	a5,24(s1)
    80002aea:	2781                	sext.w	a5,a5
    80002aec:	dfe9                	beqz	a5,80002ac6 <kill_system+0x50>
    80002aee:	549c                	lw	a5,40(s1)
    80002af0:	2781                	sext.w	a5,a5
    80002af2:	fbf1                	bnez	a5,80002ac6 <kill_system+0x50>
        printf("Proc: %s number: %d KILL proc: %s number: %d\n",name, pid, p->name, p->pid);
    80002af4:	15848693          	addi	a3,s1,344
    80002af8:	865e                	mv	a2,s7
    80002afa:	85d6                	mv	a1,s5
    80002afc:	855a                	mv	a0,s6
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	a8c080e7          	jalr	-1396(ra) # 8000058a <printf>
        p->killed |= 1;
    80002b06:	549c                	lw	a5,40(s1)
    80002b08:	2781                	sext.w	a5,a5
    80002b0a:	0017e793          	ori	a5,a5,1
    80002b0e:	d49c                	sw	a5,40(s1)
        if(p->state == SLEEPING){
    80002b10:	4c9c                	lw	a5,24(s1)
    80002b12:	2781                	sext.w	a5,a5
    80002b14:	fb2799e3          	bne	a5,s2,80002ac6 <kill_system+0x50>
          int diff = ticks - p->last_update_time;
    80002b18:	000ca703          	lw	a4,0(s9)
    80002b1c:	1804a683          	lw	a3,384(s1)
          p->last_update_time = ticks;
    80002b20:	18e4a023          	sw	a4,384(s1)
          p->sleeping_time += diff;
    80002b24:	1744a783          	lw	a5,372(s1)
    80002b28:	9fb9                	addw	a5,a5,a4
    80002b2a:	9f95                	subw	a5,a5,a3
    80002b2c:	16f4aa23          	sw	a5,372(s1)
          p->state = RUNNABLE;
    80002b30:	0184ac23          	sw	s8,24(s1)
    80002b34:	bf49                	j	80002ac6 <kill_system+0x50>
  }
  return 0;
} 
    80002b36:	4501                	li	a0,0
    80002b38:	60e6                	ld	ra,88(sp)
    80002b3a:	6446                	ld	s0,80(sp)
    80002b3c:	64a6                	ld	s1,72(sp)
    80002b3e:	6906                	ld	s2,64(sp)
    80002b40:	79e2                	ld	s3,56(sp)
    80002b42:	7a42                	ld	s4,48(sp)
    80002b44:	7aa2                	ld	s5,40(sp)
    80002b46:	7b02                	ld	s6,32(sp)
    80002b48:	6be2                	ld	s7,24(sp)
    80002b4a:	6c42                	ld	s8,16(sp)
    80002b4c:	6ca2                	ld	s9,8(sp)
    80002b4e:	6125                	addi	sp,sp,96
    80002b50:	8082                	ret

0000000080002b52 <print_stats>:

void
print_stats(void){
    80002b52:	1101                	addi	sp,sp,-32
    80002b54:	ec06                	sd	ra,24(sp)
    80002b56:	e822                	sd	s0,16(sp)
    80002b58:	e426                	sd	s1,8(sp)
    80002b5a:	1000                	addi	s0,sp,32
  printf("_______________________\n");
    80002b5c:	00005517          	auipc	a0,0x5
    80002b60:	7d450513          	addi	a0,a0,2004 # 80008330 <digits+0x2f0>
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	a26080e7          	jalr	-1498(ra) # 8000058a <printf>
  printf("running time mean: %d\n", running_processes_mean);
    80002b6c:	00006597          	auipc	a1,0x6
    80002b70:	4e05a583          	lw	a1,1248(a1) # 8000904c <running_processes_mean>
    80002b74:	00005517          	auipc	a0,0x5
    80002b78:	7dc50513          	addi	a0,a0,2012 # 80008350 <digits+0x310>
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	a0e080e7          	jalr	-1522(ra) # 8000058a <printf>
  printf("runnable time mean: %d\n", runnable_processes_mean);
    80002b84:	00006597          	auipc	a1,0x6
    80002b88:	4c45a583          	lw	a1,1220(a1) # 80009048 <runnable_processes_mean>
    80002b8c:	00005517          	auipc	a0,0x5
    80002b90:	7dc50513          	addi	a0,a0,2012 # 80008368 <digits+0x328>
    80002b94:	ffffe097          	auipc	ra,0xffffe
    80002b98:	9f6080e7          	jalr	-1546(ra) # 8000058a <printf>
  printf("sleeping time mean: %d\n", sleeping_processes_mean);
    80002b9c:	00006597          	auipc	a1,0x6
    80002ba0:	4b45a583          	lw	a1,1204(a1) # 80009050 <sleeping_processes_mean>
    80002ba4:	00005517          	auipc	a0,0x5
    80002ba8:	7dc50513          	addi	a0,a0,2012 # 80008380 <digits+0x340>
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	9de080e7          	jalr	-1570(ra) # 8000058a <printf>
  printf("program time: %d\n", program_time);
    80002bb4:	00006497          	auipc	s1,0x6
    80002bb8:	48c48493          	addi	s1,s1,1164 # 80009040 <program_time>
    80002bbc:	408c                	lw	a1,0(s1)
    80002bbe:	00005517          	auipc	a0,0x5
    80002bc2:	7da50513          	addi	a0,a0,2010 # 80008398 <digits+0x358>
    80002bc6:	ffffe097          	auipc	ra,0xffffe
    80002bca:	9c4080e7          	jalr	-1596(ra) # 8000058a <printf>
  printf("cpu utilization: %d (%d/%d)\n", cpu_utilization, program_time, ticks - start_time);
    80002bce:	00006697          	auipc	a3,0x6
    80002bd2:	4866a683          	lw	a3,1158(a3) # 80009054 <ticks>
    80002bd6:	00006797          	auipc	a5,0x6
    80002bda:	4627a783          	lw	a5,1122(a5) # 80009038 <start_time>
    80002bde:	9e9d                	subw	a3,a3,a5
    80002be0:	4090                	lw	a2,0(s1)
    80002be2:	00006597          	auipc	a1,0x6
    80002be6:	45a5a583          	lw	a1,1114(a1) # 8000903c <cpu_utilization>
    80002bea:	00005517          	auipc	a0,0x5
    80002bee:	7c650513          	addi	a0,a0,1990 # 800083b0 <digits+0x370>
    80002bf2:	ffffe097          	auipc	ra,0xffffe
    80002bf6:	998080e7          	jalr	-1640(ra) # 8000058a <printf>
  printf("_______________________\n");
    80002bfa:	00005517          	auipc	a0,0x5
    80002bfe:	73650513          	addi	a0,a0,1846 # 80008330 <digits+0x2f0>
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	988080e7          	jalr	-1656(ra) # 8000058a <printf>
    80002c0a:	60e2                	ld	ra,24(sp)
    80002c0c:	6442                	ld	s0,16(sp)
    80002c0e:	64a2                	ld	s1,8(sp)
    80002c10:	6105                	addi	sp,sp,32
    80002c12:	8082                	ret

0000000080002c14 <swtch>:
    80002c14:	00153023          	sd	ra,0(a0)
    80002c18:	00253423          	sd	sp,8(a0)
    80002c1c:	e900                	sd	s0,16(a0)
    80002c1e:	ed04                	sd	s1,24(a0)
    80002c20:	03253023          	sd	s2,32(a0)
    80002c24:	03353423          	sd	s3,40(a0)
    80002c28:	03453823          	sd	s4,48(a0)
    80002c2c:	03553c23          	sd	s5,56(a0)
    80002c30:	05653023          	sd	s6,64(a0)
    80002c34:	05753423          	sd	s7,72(a0)
    80002c38:	05853823          	sd	s8,80(a0)
    80002c3c:	05953c23          	sd	s9,88(a0)
    80002c40:	07a53023          	sd	s10,96(a0)
    80002c44:	07b53423          	sd	s11,104(a0)
    80002c48:	0005b083          	ld	ra,0(a1)
    80002c4c:	0085b103          	ld	sp,8(a1)
    80002c50:	6980                	ld	s0,16(a1)
    80002c52:	6d84                	ld	s1,24(a1)
    80002c54:	0205b903          	ld	s2,32(a1)
    80002c58:	0285b983          	ld	s3,40(a1)
    80002c5c:	0305ba03          	ld	s4,48(a1)
    80002c60:	0385ba83          	ld	s5,56(a1)
    80002c64:	0405bb03          	ld	s6,64(a1)
    80002c68:	0485bb83          	ld	s7,72(a1)
    80002c6c:	0505bc03          	ld	s8,80(a1)
    80002c70:	0585bc83          	ld	s9,88(a1)
    80002c74:	0605bd03          	ld	s10,96(a1)
    80002c78:	0685bd83          	ld	s11,104(a1)
    80002c7c:	8082                	ret

0000000080002c7e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002c7e:	1141                	addi	sp,sp,-16
    80002c80:	e406                	sd	ra,8(sp)
    80002c82:	e022                	sd	s0,0(sp)
    80002c84:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002c86:	00005597          	auipc	a1,0x5
    80002c8a:	7a258593          	addi	a1,a1,1954 # 80008428 <states.1747+0x30>
    80002c8e:	00015517          	auipc	a0,0x15
    80002c92:	c6250513          	addi	a0,a0,-926 # 800178f0 <tickslock>
    80002c96:	ffffe097          	auipc	ra,0xffffe
    80002c9a:	ec0080e7          	jalr	-320(ra) # 80000b56 <initlock>
}
    80002c9e:	60a2                	ld	ra,8(sp)
    80002ca0:	6402                	ld	s0,0(sp)
    80002ca2:	0141                	addi	sp,sp,16
    80002ca4:	8082                	ret

0000000080002ca6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ca6:	1141                	addi	sp,sp,-16
    80002ca8:	e422                	sd	s0,8(sp)
    80002caa:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cac:	00003797          	auipc	a5,0x3
    80002cb0:	4d478793          	addi	a5,a5,1236 # 80006180 <kernelvec>
    80002cb4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002cb8:	6422                	ld	s0,8(sp)
    80002cba:	0141                	addi	sp,sp,16
    80002cbc:	8082                	ret

0000000080002cbe <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002cbe:	1141                	addi	sp,sp,-16
    80002cc0:	e406                	sd	ra,8(sp)
    80002cc2:	e022                	sd	s0,0(sp)
    80002cc4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002cc6:	fffff097          	auipc	ra,0xfffff
    80002cca:	d2c080e7          	jalr	-724(ra) # 800019f2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002cd2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cd4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002cd8:	00004617          	auipc	a2,0x4
    80002cdc:	32860613          	addi	a2,a2,808 # 80007000 <_trampoline>
    80002ce0:	00004697          	auipc	a3,0x4
    80002ce4:	32068693          	addi	a3,a3,800 # 80007000 <_trampoline>
    80002ce8:	8e91                	sub	a3,a3,a2
    80002cea:	040007b7          	lui	a5,0x4000
    80002cee:	17fd                	addi	a5,a5,-1
    80002cf0:	07b2                	slli	a5,a5,0xc
    80002cf2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cf4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002cf8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002cfa:	180026f3          	csrr	a3,satp
    80002cfe:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d00:	6d38                	ld	a4,88(a0)
    80002d02:	6134                	ld	a3,64(a0)
    80002d04:	6585                	lui	a1,0x1
    80002d06:	96ae                	add	a3,a3,a1
    80002d08:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d0a:	6d38                	ld	a4,88(a0)
    80002d0c:	00000697          	auipc	a3,0x0
    80002d10:	13868693          	addi	a3,a3,312 # 80002e44 <usertrap>
    80002d14:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d16:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d18:	8692                	mv	a3,tp
    80002d1a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d1c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d20:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d24:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d28:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002d2c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d2e:	6f18                	ld	a4,24(a4)
    80002d30:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002d34:	692c                	ld	a1,80(a0)
    80002d36:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002d38:	00004717          	auipc	a4,0x4
    80002d3c:	35870713          	addi	a4,a4,856 # 80007090 <userret>
    80002d40:	8f11                	sub	a4,a4,a2
    80002d42:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002d44:	577d                	li	a4,-1
    80002d46:	177e                	slli	a4,a4,0x3f
    80002d48:	8dd9                	or	a1,a1,a4
    80002d4a:	02000537          	lui	a0,0x2000
    80002d4e:	157d                	addi	a0,a0,-1
    80002d50:	0536                	slli	a0,a0,0xd
    80002d52:	9782                	jalr	a5
}
    80002d54:	60a2                	ld	ra,8(sp)
    80002d56:	6402                	ld	s0,0(sp)
    80002d58:	0141                	addi	sp,sp,16
    80002d5a:	8082                	ret

0000000080002d5c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002d5c:	1101                	addi	sp,sp,-32
    80002d5e:	ec06                	sd	ra,24(sp)
    80002d60:	e822                	sd	s0,16(sp)
    80002d62:	e426                	sd	s1,8(sp)
    80002d64:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002d66:	00015497          	auipc	s1,0x15
    80002d6a:	b8a48493          	addi	s1,s1,-1142 # 800178f0 <tickslock>
    80002d6e:	8526                	mv	a0,s1
    80002d70:	ffffe097          	auipc	ra,0xffffe
    80002d74:	e76080e7          	jalr	-394(ra) # 80000be6 <acquire>
  ticks++;
    80002d78:	00006517          	auipc	a0,0x6
    80002d7c:	2dc50513          	addi	a0,a0,732 # 80009054 <ticks>
    80002d80:	411c                	lw	a5,0(a0)
    80002d82:	2785                	addiw	a5,a5,1
    80002d84:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	708080e7          	jalr	1800(ra) # 8000248e <wakeup>
  release(&tickslock);
    80002d8e:	8526                	mv	a0,s1
    80002d90:	ffffe097          	auipc	ra,0xffffe
    80002d94:	f0a080e7          	jalr	-246(ra) # 80000c9a <release>
}
    80002d98:	60e2                	ld	ra,24(sp)
    80002d9a:	6442                	ld	s0,16(sp)
    80002d9c:	64a2                	ld	s1,8(sp)
    80002d9e:	6105                	addi	sp,sp,32
    80002da0:	8082                	ret

0000000080002da2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002da2:	1101                	addi	sp,sp,-32
    80002da4:	ec06                	sd	ra,24(sp)
    80002da6:	e822                	sd	s0,16(sp)
    80002da8:	e426                	sd	s1,8(sp)
    80002daa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002dac:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002db0:	00074d63          	bltz	a4,80002dca <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002db4:	57fd                	li	a5,-1
    80002db6:	17fe                	slli	a5,a5,0x3f
    80002db8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002dba:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002dbc:	06f70363          	beq	a4,a5,80002e22 <devintr+0x80>
  }
}
    80002dc0:	60e2                	ld	ra,24(sp)
    80002dc2:	6442                	ld	s0,16(sp)
    80002dc4:	64a2                	ld	s1,8(sp)
    80002dc6:	6105                	addi	sp,sp,32
    80002dc8:	8082                	ret
     (scause & 0xff) == 9){
    80002dca:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002dce:	46a5                	li	a3,9
    80002dd0:	fed792e3          	bne	a5,a3,80002db4 <devintr+0x12>
    int irq = plic_claim();
    80002dd4:	00003097          	auipc	ra,0x3
    80002dd8:	4b4080e7          	jalr	1204(ra) # 80006288 <plic_claim>
    80002ddc:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002dde:	47a9                	li	a5,10
    80002de0:	02f50763          	beq	a0,a5,80002e0e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002de4:	4785                	li	a5,1
    80002de6:	02f50963          	beq	a0,a5,80002e18 <devintr+0x76>
    return 1;
    80002dea:	4505                	li	a0,1
    } else if(irq){
    80002dec:	d8f1                	beqz	s1,80002dc0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002dee:	85a6                	mv	a1,s1
    80002df0:	00005517          	auipc	a0,0x5
    80002df4:	64050513          	addi	a0,a0,1600 # 80008430 <states.1747+0x38>
    80002df8:	ffffd097          	auipc	ra,0xffffd
    80002dfc:	792080e7          	jalr	1938(ra) # 8000058a <printf>
      plic_complete(irq);
    80002e00:	8526                	mv	a0,s1
    80002e02:	00003097          	auipc	ra,0x3
    80002e06:	4aa080e7          	jalr	1194(ra) # 800062ac <plic_complete>
    return 1;
    80002e0a:	4505                	li	a0,1
    80002e0c:	bf55                	j	80002dc0 <devintr+0x1e>
      uartintr();
    80002e0e:	ffffe097          	auipc	ra,0xffffe
    80002e12:	b9c080e7          	jalr	-1124(ra) # 800009aa <uartintr>
    80002e16:	b7ed                	j	80002e00 <devintr+0x5e>
      virtio_disk_intr();
    80002e18:	00004097          	auipc	ra,0x4
    80002e1c:	974080e7          	jalr	-1676(ra) # 8000678c <virtio_disk_intr>
    80002e20:	b7c5                	j	80002e00 <devintr+0x5e>
    if(cpuid() == 0){
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	ba4080e7          	jalr	-1116(ra) # 800019c6 <cpuid>
    80002e2a:	c901                	beqz	a0,80002e3a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002e2c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002e30:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002e32:	14479073          	csrw	sip,a5
    return 2;
    80002e36:	4509                	li	a0,2
    80002e38:	b761                	j	80002dc0 <devintr+0x1e>
      clockintr();
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	f22080e7          	jalr	-222(ra) # 80002d5c <clockintr>
    80002e42:	b7ed                	j	80002e2c <devintr+0x8a>

0000000080002e44 <usertrap>:
{
    80002e44:	1101                	addi	sp,sp,-32
    80002e46:	ec06                	sd	ra,24(sp)
    80002e48:	e822                	sd	s0,16(sp)
    80002e4a:	e426                	sd	s1,8(sp)
    80002e4c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e4e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e52:	1007f793          	andi	a5,a5,256
    80002e56:	e3b5                	bnez	a5,80002eba <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e58:	00003797          	auipc	a5,0x3
    80002e5c:	32878793          	addi	a5,a5,808 # 80006180 <kernelvec>
    80002e60:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e64:	fffff097          	auipc	ra,0xfffff
    80002e68:	b8e080e7          	jalr	-1138(ra) # 800019f2 <myproc>
    80002e6c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e6e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e70:	14102773          	csrr	a4,sepc
    80002e74:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e76:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e7a:	47a1                	li	a5,8
    80002e7c:	04f71d63          	bne	a4,a5,80002ed6 <usertrap+0x92>
    if(p->killed)
    80002e80:	551c                	lw	a5,40(a0)
    80002e82:	2781                	sext.w	a5,a5
    80002e84:	e3b9                	bnez	a5,80002eca <usertrap+0x86>
    p->trapframe->epc += 4;
    80002e86:	6cb8                	ld	a4,88(s1)
    80002e88:	6f1c                	ld	a5,24(a4)
    80002e8a:	0791                	addi	a5,a5,4
    80002e8c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e8e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e92:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e96:	10079073          	csrw	sstatus,a5
    syscall();
    80002e9a:	00000097          	auipc	ra,0x0
    80002e9e:	2ca080e7          	jalr	714(ra) # 80003164 <syscall>
  if(p->killed)
    80002ea2:	549c                	lw	a5,40(s1)
    80002ea4:	2781                	sext.w	a5,a5
    80002ea6:	e7bd                	bnez	a5,80002f14 <usertrap+0xd0>
  usertrapret();
    80002ea8:	00000097          	auipc	ra,0x0
    80002eac:	e16080e7          	jalr	-490(ra) # 80002cbe <usertrapret>
}
    80002eb0:	60e2                	ld	ra,24(sp)
    80002eb2:	6442                	ld	s0,16(sp)
    80002eb4:	64a2                	ld	s1,8(sp)
    80002eb6:	6105                	addi	sp,sp,32
    80002eb8:	8082                	ret
    panic("usertrap: not from user mode");
    80002eba:	00005517          	auipc	a0,0x5
    80002ebe:	59650513          	addi	a0,a0,1430 # 80008450 <states.1747+0x58>
    80002ec2:	ffffd097          	auipc	ra,0xffffd
    80002ec6:	67e080e7          	jalr	1662(ra) # 80000540 <panic>
      exit(-1);
    80002eca:	557d                	li	a0,-1
    80002ecc:	fffff097          	auipc	ra,0xfffff
    80002ed0:	6fc080e7          	jalr	1788(ra) # 800025c8 <exit>
    80002ed4:	bf4d                	j	80002e86 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002ed6:	00000097          	auipc	ra,0x0
    80002eda:	ecc080e7          	jalr	-308(ra) # 80002da2 <devintr>
    80002ede:	f171                	bnez	a0,80002ea2 <usertrap+0x5e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ee0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ee4:	5890                	lw	a2,48(s1)
    80002ee6:	00005517          	auipc	a0,0x5
    80002eea:	58a50513          	addi	a0,a0,1418 # 80008470 <states.1747+0x78>
    80002eee:	ffffd097          	auipc	ra,0xffffd
    80002ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ef6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002efa:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002efe:	00005517          	auipc	a0,0x5
    80002f02:	5a250513          	addi	a0,a0,1442 # 800084a0 <states.1747+0xa8>
    80002f06:	ffffd097          	auipc	ra,0xffffd
    80002f0a:	684080e7          	jalr	1668(ra) # 8000058a <printf>
    p->killed = 1;
    80002f0e:	4785                	li	a5,1
    80002f10:	d49c                	sw	a5,40(s1)
    80002f12:	bf41                	j	80002ea2 <usertrap+0x5e>
    exit(-1);
    80002f14:	557d                	li	a0,-1
    80002f16:	fffff097          	auipc	ra,0xfffff
    80002f1a:	6b2080e7          	jalr	1714(ra) # 800025c8 <exit>
    80002f1e:	b769                	j	80002ea8 <usertrap+0x64>

0000000080002f20 <kerneltrap>:
{
    80002f20:	7179                	addi	sp,sp,-48
    80002f22:	f406                	sd	ra,40(sp)
    80002f24:	f022                	sd	s0,32(sp)
    80002f26:	ec26                	sd	s1,24(sp)
    80002f28:	e84a                	sd	s2,16(sp)
    80002f2a:	e44e                	sd	s3,8(sp)
    80002f2c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f2e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f32:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f36:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002f3a:	1004f793          	andi	a5,s1,256
    80002f3e:	cb85                	beqz	a5,80002f6e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f40:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002f44:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002f46:	ef85                	bnez	a5,80002f7e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002f48:	00000097          	auipc	ra,0x0
    80002f4c:	e5a080e7          	jalr	-422(ra) # 80002da2 <devintr>
    80002f50:	cd1d                	beqz	a0,80002f8e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f52:	4789                	li	a5,2
    80002f54:	06f50a63          	beq	a0,a5,80002fc8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f58:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f5c:	10049073          	csrw	sstatus,s1
}
    80002f60:	70a2                	ld	ra,40(sp)
    80002f62:	7402                	ld	s0,32(sp)
    80002f64:	64e2                	ld	s1,24(sp)
    80002f66:	6942                	ld	s2,16(sp)
    80002f68:	69a2                	ld	s3,8(sp)
    80002f6a:	6145                	addi	sp,sp,48
    80002f6c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002f6e:	00005517          	auipc	a0,0x5
    80002f72:	55250513          	addi	a0,a0,1362 # 800084c0 <states.1747+0xc8>
    80002f76:	ffffd097          	auipc	ra,0xffffd
    80002f7a:	5ca080e7          	jalr	1482(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002f7e:	00005517          	auipc	a0,0x5
    80002f82:	56a50513          	addi	a0,a0,1386 # 800084e8 <states.1747+0xf0>
    80002f86:	ffffd097          	auipc	ra,0xffffd
    80002f8a:	5ba080e7          	jalr	1466(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002f8e:	85ce                	mv	a1,s3
    80002f90:	00005517          	auipc	a0,0x5
    80002f94:	57850513          	addi	a0,a0,1400 # 80008508 <states.1747+0x110>
    80002f98:	ffffd097          	auipc	ra,0xffffd
    80002f9c:	5f2080e7          	jalr	1522(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fa0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fa4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002fa8:	00005517          	auipc	a0,0x5
    80002fac:	57050513          	addi	a0,a0,1392 # 80008518 <states.1747+0x120>
    80002fb0:	ffffd097          	auipc	ra,0xffffd
    80002fb4:	5da080e7          	jalr	1498(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002fb8:	00005517          	auipc	a0,0x5
    80002fbc:	57850513          	addi	a0,a0,1400 # 80008530 <states.1747+0x138>
    80002fc0:	ffffd097          	auipc	ra,0xffffd
    80002fc4:	580080e7          	jalr	1408(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fc8:	fffff097          	auipc	ra,0xfffff
    80002fcc:	a2a080e7          	jalr	-1494(ra) # 800019f2 <myproc>
    80002fd0:	d541                	beqz	a0,80002f58 <kerneltrap+0x38>
    80002fd2:	fffff097          	auipc	ra,0xfffff
    80002fd6:	a20080e7          	jalr	-1504(ra) # 800019f2 <myproc>
    80002fda:	4d1c                	lw	a5,24(a0)
    80002fdc:	2781                	sext.w	a5,a5
    80002fde:	4711                	li	a4,4
    80002fe0:	f6e79ce3          	bne	a5,a4,80002f58 <kerneltrap+0x38>
    yield();
    80002fe4:	fffff097          	auipc	ra,0xfffff
    80002fe8:	232080e7          	jalr	562(ra) # 80002216 <yield>
    80002fec:	b7b5                	j	80002f58 <kerneltrap+0x38>

0000000080002fee <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002fee:	1101                	addi	sp,sp,-32
    80002ff0:	ec06                	sd	ra,24(sp)
    80002ff2:	e822                	sd	s0,16(sp)
    80002ff4:	e426                	sd	s1,8(sp)
    80002ff6:	1000                	addi	s0,sp,32
    80002ff8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ffa:	fffff097          	auipc	ra,0xfffff
    80002ffe:	9f8080e7          	jalr	-1544(ra) # 800019f2 <myproc>
  switch (n) {
    80003002:	4795                	li	a5,5
    80003004:	0497e163          	bltu	a5,s1,80003046 <argraw+0x58>
    80003008:	048a                	slli	s1,s1,0x2
    8000300a:	00005717          	auipc	a4,0x5
    8000300e:	55e70713          	addi	a4,a4,1374 # 80008568 <states.1747+0x170>
    80003012:	94ba                	add	s1,s1,a4
    80003014:	409c                	lw	a5,0(s1)
    80003016:	97ba                	add	a5,a5,a4
    80003018:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000301a:	6d3c                	ld	a5,88(a0)
    8000301c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000301e:	60e2                	ld	ra,24(sp)
    80003020:	6442                	ld	s0,16(sp)
    80003022:	64a2                	ld	s1,8(sp)
    80003024:	6105                	addi	sp,sp,32
    80003026:	8082                	ret
    return p->trapframe->a1;
    80003028:	6d3c                	ld	a5,88(a0)
    8000302a:	7fa8                	ld	a0,120(a5)
    8000302c:	bfcd                	j	8000301e <argraw+0x30>
    return p->trapframe->a2;
    8000302e:	6d3c                	ld	a5,88(a0)
    80003030:	63c8                	ld	a0,128(a5)
    80003032:	b7f5                	j	8000301e <argraw+0x30>
    return p->trapframe->a3;
    80003034:	6d3c                	ld	a5,88(a0)
    80003036:	67c8                	ld	a0,136(a5)
    80003038:	b7dd                	j	8000301e <argraw+0x30>
    return p->trapframe->a4;
    8000303a:	6d3c                	ld	a5,88(a0)
    8000303c:	6bc8                	ld	a0,144(a5)
    8000303e:	b7c5                	j	8000301e <argraw+0x30>
    return p->trapframe->a5;
    80003040:	6d3c                	ld	a5,88(a0)
    80003042:	6fc8                	ld	a0,152(a5)
    80003044:	bfe9                	j	8000301e <argraw+0x30>
  panic("argraw");
    80003046:	00005517          	auipc	a0,0x5
    8000304a:	4fa50513          	addi	a0,a0,1274 # 80008540 <states.1747+0x148>
    8000304e:	ffffd097          	auipc	ra,0xffffd
    80003052:	4f2080e7          	jalr	1266(ra) # 80000540 <panic>

0000000080003056 <fetchaddr>:
{
    80003056:	1101                	addi	sp,sp,-32
    80003058:	ec06                	sd	ra,24(sp)
    8000305a:	e822                	sd	s0,16(sp)
    8000305c:	e426                	sd	s1,8(sp)
    8000305e:	e04a                	sd	s2,0(sp)
    80003060:	1000                	addi	s0,sp,32
    80003062:	84aa                	mv	s1,a0
    80003064:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003066:	fffff097          	auipc	ra,0xfffff
    8000306a:	98c080e7          	jalr	-1652(ra) # 800019f2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    8000306e:	653c                	ld	a5,72(a0)
    80003070:	02f4f863          	bgeu	s1,a5,800030a0 <fetchaddr+0x4a>
    80003074:	00848713          	addi	a4,s1,8
    80003078:	02e7e663          	bltu	a5,a4,800030a4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000307c:	46a1                	li	a3,8
    8000307e:	8626                	mv	a2,s1
    80003080:	85ca                	mv	a1,s2
    80003082:	6928                	ld	a0,80(a0)
    80003084:	ffffe097          	auipc	ra,0xffffe
    80003088:	67c080e7          	jalr	1660(ra) # 80001700 <copyin>
    8000308c:	00a03533          	snez	a0,a0
    80003090:	40a00533          	neg	a0,a0
}
    80003094:	60e2                	ld	ra,24(sp)
    80003096:	6442                	ld	s0,16(sp)
    80003098:	64a2                	ld	s1,8(sp)
    8000309a:	6902                	ld	s2,0(sp)
    8000309c:	6105                	addi	sp,sp,32
    8000309e:	8082                	ret
    return -1;
    800030a0:	557d                	li	a0,-1
    800030a2:	bfcd                	j	80003094 <fetchaddr+0x3e>
    800030a4:	557d                	li	a0,-1
    800030a6:	b7fd                	j	80003094 <fetchaddr+0x3e>

00000000800030a8 <fetchstr>:
{
    800030a8:	7179                	addi	sp,sp,-48
    800030aa:	f406                	sd	ra,40(sp)
    800030ac:	f022                	sd	s0,32(sp)
    800030ae:	ec26                	sd	s1,24(sp)
    800030b0:	e84a                	sd	s2,16(sp)
    800030b2:	e44e                	sd	s3,8(sp)
    800030b4:	1800                	addi	s0,sp,48
    800030b6:	892a                	mv	s2,a0
    800030b8:	84ae                	mv	s1,a1
    800030ba:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    800030bc:	fffff097          	auipc	ra,0xfffff
    800030c0:	936080e7          	jalr	-1738(ra) # 800019f2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    800030c4:	86ce                	mv	a3,s3
    800030c6:	864a                	mv	a2,s2
    800030c8:	85a6                	mv	a1,s1
    800030ca:	6928                	ld	a0,80(a0)
    800030cc:	ffffe097          	auipc	ra,0xffffe
    800030d0:	6c0080e7          	jalr	1728(ra) # 8000178c <copyinstr>
  if(err < 0)
    800030d4:	00054763          	bltz	a0,800030e2 <fetchstr+0x3a>
  return strlen(buf);
    800030d8:	8526                	mv	a0,s1
    800030da:	ffffe097          	auipc	ra,0xffffe
    800030de:	d8c080e7          	jalr	-628(ra) # 80000e66 <strlen>
}
    800030e2:	70a2                	ld	ra,40(sp)
    800030e4:	7402                	ld	s0,32(sp)
    800030e6:	64e2                	ld	s1,24(sp)
    800030e8:	6942                	ld	s2,16(sp)
    800030ea:	69a2                	ld	s3,8(sp)
    800030ec:	6145                	addi	sp,sp,48
    800030ee:	8082                	ret

00000000800030f0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    800030f0:	1101                	addi	sp,sp,-32
    800030f2:	ec06                	sd	ra,24(sp)
    800030f4:	e822                	sd	s0,16(sp)
    800030f6:	e426                	sd	s1,8(sp)
    800030f8:	1000                	addi	s0,sp,32
    800030fa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800030fc:	00000097          	auipc	ra,0x0
    80003100:	ef2080e7          	jalr	-270(ra) # 80002fee <argraw>
    80003104:	c088                	sw	a0,0(s1)
  return 0;
}
    80003106:	4501                	li	a0,0
    80003108:	60e2                	ld	ra,24(sp)
    8000310a:	6442                	ld	s0,16(sp)
    8000310c:	64a2                	ld	s1,8(sp)
    8000310e:	6105                	addi	sp,sp,32
    80003110:	8082                	ret

0000000080003112 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80003112:	1101                	addi	sp,sp,-32
    80003114:	ec06                	sd	ra,24(sp)
    80003116:	e822                	sd	s0,16(sp)
    80003118:	e426                	sd	s1,8(sp)
    8000311a:	1000                	addi	s0,sp,32
    8000311c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000311e:	00000097          	auipc	ra,0x0
    80003122:	ed0080e7          	jalr	-304(ra) # 80002fee <argraw>
    80003126:	e088                	sd	a0,0(s1)
  return 0;
}
    80003128:	4501                	li	a0,0
    8000312a:	60e2                	ld	ra,24(sp)
    8000312c:	6442                	ld	s0,16(sp)
    8000312e:	64a2                	ld	s1,8(sp)
    80003130:	6105                	addi	sp,sp,32
    80003132:	8082                	ret

0000000080003134 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003134:	1101                	addi	sp,sp,-32
    80003136:	ec06                	sd	ra,24(sp)
    80003138:	e822                	sd	s0,16(sp)
    8000313a:	e426                	sd	s1,8(sp)
    8000313c:	e04a                	sd	s2,0(sp)
    8000313e:	1000                	addi	s0,sp,32
    80003140:	84ae                	mv	s1,a1
    80003142:	8932                	mv	s2,a2
  *ip = argraw(n);
    80003144:	00000097          	auipc	ra,0x0
    80003148:	eaa080e7          	jalr	-342(ra) # 80002fee <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    8000314c:	864a                	mv	a2,s2
    8000314e:	85a6                	mv	a1,s1
    80003150:	00000097          	auipc	ra,0x0
    80003154:	f58080e7          	jalr	-168(ra) # 800030a8 <fetchstr>
}
    80003158:	60e2                	ld	ra,24(sp)
    8000315a:	6442                	ld	s0,16(sp)
    8000315c:	64a2                	ld	s1,8(sp)
    8000315e:	6902                	ld	s2,0(sp)
    80003160:	6105                	addi	sp,sp,32
    80003162:	8082                	ret

0000000080003164 <syscall>:
};


void
syscall(void)
{
    80003164:	1101                	addi	sp,sp,-32
    80003166:	ec06                	sd	ra,24(sp)
    80003168:	e822                	sd	s0,16(sp)
    8000316a:	e426                	sd	s1,8(sp)
    8000316c:	e04a                	sd	s2,0(sp)
    8000316e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003170:	fffff097          	auipc	ra,0xfffff
    80003174:	882080e7          	jalr	-1918(ra) # 800019f2 <myproc>
    80003178:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000317a:	05853903          	ld	s2,88(a0)
    8000317e:	0a893783          	ld	a5,168(s2)
    80003182:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003186:	37fd                	addiw	a5,a5,-1
    80003188:	475d                	li	a4,23
    8000318a:	00f76f63          	bltu	a4,a5,800031a8 <syscall+0x44>
    8000318e:	00369713          	slli	a4,a3,0x3
    80003192:	00005797          	auipc	a5,0x5
    80003196:	3ee78793          	addi	a5,a5,1006 # 80008580 <syscalls>
    8000319a:	97ba                	add	a5,a5,a4
    8000319c:	639c                	ld	a5,0(a5)
    8000319e:	c789                	beqz	a5,800031a8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800031a0:	9782                	jalr	a5
    800031a2:	06a93823          	sd	a0,112(s2)
    800031a6:	a839                	j	800031c4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800031a8:	15848613          	addi	a2,s1,344
    800031ac:	588c                	lw	a1,48(s1)
    800031ae:	00005517          	auipc	a0,0x5
    800031b2:	39a50513          	addi	a0,a0,922 # 80008548 <states.1747+0x150>
    800031b6:	ffffd097          	auipc	ra,0xffffd
    800031ba:	3d4080e7          	jalr	980(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800031be:	6cbc                	ld	a5,88(s1)
    800031c0:	577d                	li	a4,-1
    800031c2:	fbb8                	sd	a4,112(a5)
  }
}
    800031c4:	60e2                	ld	ra,24(sp)
    800031c6:	6442                	ld	s0,16(sp)
    800031c8:	64a2                	ld	s1,8(sp)
    800031ca:	6902                	ld	s2,0(sp)
    800031cc:	6105                	addi	sp,sp,32
    800031ce:	8082                	ret

00000000800031d0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    800031d0:	1101                	addi	sp,sp,-32
    800031d2:	ec06                	sd	ra,24(sp)
    800031d4:	e822                	sd	s0,16(sp)
    800031d6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    800031d8:	fec40593          	addi	a1,s0,-20
    800031dc:	4501                	li	a0,0
    800031de:	00000097          	auipc	ra,0x0
    800031e2:	f12080e7          	jalr	-238(ra) # 800030f0 <argint>
    return -1;
    800031e6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800031e8:	00054963          	bltz	a0,800031fa <sys_exit+0x2a>
  exit(n);
    800031ec:	fec42503          	lw	a0,-20(s0)
    800031f0:	fffff097          	auipc	ra,0xfffff
    800031f4:	3d8080e7          	jalr	984(ra) # 800025c8 <exit>
  return 0;  // not reached
    800031f8:	4781                	li	a5,0
}
    800031fa:	853e                	mv	a0,a5
    800031fc:	60e2                	ld	ra,24(sp)
    800031fe:	6442                	ld	s0,16(sp)
    80003200:	6105                	addi	sp,sp,32
    80003202:	8082                	ret

0000000080003204 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003204:	1141                	addi	sp,sp,-16
    80003206:	e406                	sd	ra,8(sp)
    80003208:	e022                	sd	s0,0(sp)
    8000320a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    8000320c:	ffffe097          	auipc	ra,0xffffe
    80003210:	7e6080e7          	jalr	2022(ra) # 800019f2 <myproc>
}
    80003214:	5908                	lw	a0,48(a0)
    80003216:	60a2                	ld	ra,8(sp)
    80003218:	6402                	ld	s0,0(sp)
    8000321a:	0141                	addi	sp,sp,16
    8000321c:	8082                	ret

000000008000321e <sys_fork>:

uint64
sys_fork(void)
{
    8000321e:	1141                	addi	sp,sp,-16
    80003220:	e406                	sd	ra,8(sp)
    80003222:	e022                	sd	s0,0(sp)
    80003224:	0800                	addi	s0,sp,16
  return fork();
    80003226:	fffff097          	auipc	ra,0xfffff
    8000322a:	bbc080e7          	jalr	-1092(ra) # 80001de2 <fork>
}
    8000322e:	60a2                	ld	ra,8(sp)
    80003230:	6402                	ld	s0,0(sp)
    80003232:	0141                	addi	sp,sp,16
    80003234:	8082                	ret

0000000080003236 <sys_wait>:

uint64
sys_wait(void)
{
    80003236:	1101                	addi	sp,sp,-32
    80003238:	ec06                	sd	ra,24(sp)
    8000323a:	e822                	sd	s0,16(sp)
    8000323c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000323e:	fe840593          	addi	a1,s0,-24
    80003242:	4501                	li	a0,0
    80003244:	00000097          	auipc	ra,0x0
    80003248:	ece080e7          	jalr	-306(ra) # 80003112 <argaddr>
    8000324c:	87aa                	mv	a5,a0
    return -1;
    8000324e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80003250:	0007c863          	bltz	a5,80003260 <sys_wait+0x2a>
  return wait(p);
    80003254:	fe843503          	ld	a0,-24(s0)
    80003258:	fffff097          	auipc	ra,0xfffff
    8000325c:	10a080e7          	jalr	266(ra) # 80002362 <wait>
}
    80003260:	60e2                	ld	ra,24(sp)
    80003262:	6442                	ld	s0,16(sp)
    80003264:	6105                	addi	sp,sp,32
    80003266:	8082                	ret

0000000080003268 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003268:	7179                	addi	sp,sp,-48
    8000326a:	f406                	sd	ra,40(sp)
    8000326c:	f022                	sd	s0,32(sp)
    8000326e:	ec26                	sd	s1,24(sp)
    80003270:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80003272:	fdc40593          	addi	a1,s0,-36
    80003276:	4501                	li	a0,0
    80003278:	00000097          	auipc	ra,0x0
    8000327c:	e78080e7          	jalr	-392(ra) # 800030f0 <argint>
    80003280:	87aa                	mv	a5,a0
    return -1;
    80003282:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80003284:	0207c063          	bltz	a5,800032a4 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003288:	ffffe097          	auipc	ra,0xffffe
    8000328c:	76a080e7          	jalr	1898(ra) # 800019f2 <myproc>
    80003290:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80003292:	fdc42503          	lw	a0,-36(s0)
    80003296:	fffff097          	auipc	ra,0xfffff
    8000329a:	ad8080e7          	jalr	-1320(ra) # 80001d6e <growproc>
    8000329e:	00054863          	bltz	a0,800032ae <sys_sbrk+0x46>
    return -1;
  return addr;
    800032a2:	8526                	mv	a0,s1
}
    800032a4:	70a2                	ld	ra,40(sp)
    800032a6:	7402                	ld	s0,32(sp)
    800032a8:	64e2                	ld	s1,24(sp)
    800032aa:	6145                	addi	sp,sp,48
    800032ac:	8082                	ret
    return -1;
    800032ae:	557d                	li	a0,-1
    800032b0:	bfd5                	j	800032a4 <sys_sbrk+0x3c>

00000000800032b2 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032b2:	7139                	addi	sp,sp,-64
    800032b4:	fc06                	sd	ra,56(sp)
    800032b6:	f822                	sd	s0,48(sp)
    800032b8:	f426                	sd	s1,40(sp)
    800032ba:	f04a                	sd	s2,32(sp)
    800032bc:	ec4e                	sd	s3,24(sp)
    800032be:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    800032c0:	fcc40593          	addi	a1,s0,-52
    800032c4:	4501                	li	a0,0
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	e2a080e7          	jalr	-470(ra) # 800030f0 <argint>
    return -1;
    800032ce:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    800032d0:	06054663          	bltz	a0,8000333c <sys_sleep+0x8a>
  acquire(&tickslock);
    800032d4:	00014517          	auipc	a0,0x14
    800032d8:	61c50513          	addi	a0,a0,1564 # 800178f0 <tickslock>
    800032dc:	ffffe097          	auipc	ra,0xffffe
    800032e0:	90a080e7          	jalr	-1782(ra) # 80000be6 <acquire>
  ticks0 = ticks;
    800032e4:	00006917          	auipc	s2,0x6
    800032e8:	d7092903          	lw	s2,-656(s2) # 80009054 <ticks>
  while(ticks - ticks0 < n){
    800032ec:	fcc42783          	lw	a5,-52(s0)
    800032f0:	cf8d                	beqz	a5,8000332a <sys_sleep+0x78>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800032f2:	00014997          	auipc	s3,0x14
    800032f6:	5fe98993          	addi	s3,s3,1534 # 800178f0 <tickslock>
    800032fa:	00006497          	auipc	s1,0x6
    800032fe:	d5a48493          	addi	s1,s1,-678 # 80009054 <ticks>
    if(myproc()->killed){
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	6f0080e7          	jalr	1776(ra) # 800019f2 <myproc>
    8000330a:	551c                	lw	a5,40(a0)
    8000330c:	2781                	sext.w	a5,a5
    8000330e:	ef9d                	bnez	a5,8000334c <sys_sleep+0x9a>
    sleep(&ticks, &tickslock);
    80003310:	85ce                	mv	a1,s3
    80003312:	8526                	mv	a0,s1
    80003314:	fffff097          	auipc	ra,0xfffff
    80003318:	f94080e7          	jalr	-108(ra) # 800022a8 <sleep>
  while(ticks - ticks0 < n){
    8000331c:	409c                	lw	a5,0(s1)
    8000331e:	412787bb          	subw	a5,a5,s2
    80003322:	fcc42703          	lw	a4,-52(s0)
    80003326:	fce7eee3          	bltu	a5,a4,80003302 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000332a:	00014517          	auipc	a0,0x14
    8000332e:	5c650513          	addi	a0,a0,1478 # 800178f0 <tickslock>
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	968080e7          	jalr	-1688(ra) # 80000c9a <release>
  return 0;
    8000333a:	4781                	li	a5,0
}
    8000333c:	853e                	mv	a0,a5
    8000333e:	70e2                	ld	ra,56(sp)
    80003340:	7442                	ld	s0,48(sp)
    80003342:	74a2                	ld	s1,40(sp)
    80003344:	7902                	ld	s2,32(sp)
    80003346:	69e2                	ld	s3,24(sp)
    80003348:	6121                	addi	sp,sp,64
    8000334a:	8082                	ret
      release(&tickslock);
    8000334c:	00014517          	auipc	a0,0x14
    80003350:	5a450513          	addi	a0,a0,1444 # 800178f0 <tickslock>
    80003354:	ffffe097          	auipc	ra,0xffffe
    80003358:	946080e7          	jalr	-1722(ra) # 80000c9a <release>
      return -1;
    8000335c:	57fd                	li	a5,-1
    8000335e:	bff9                	j	8000333c <sys_sleep+0x8a>

0000000080003360 <sys_kill>:

uint64
sys_kill(void)
{
    80003360:	1101                	addi	sp,sp,-32
    80003362:	ec06                	sd	ra,24(sp)
    80003364:	e822                	sd	s0,16(sp)
    80003366:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003368:	fec40593          	addi	a1,s0,-20
    8000336c:	4501                	li	a0,0
    8000336e:	00000097          	auipc	ra,0x0
    80003372:	d82080e7          	jalr	-638(ra) # 800030f0 <argint>
    80003376:	87aa                	mv	a5,a0
    return -1;
    80003378:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000337a:	0007c863          	bltz	a5,8000338a <sys_kill+0x2a>
  return kill(pid);
    8000337e:	fec42503          	lw	a0,-20(s0)
    80003382:	fffff097          	auipc	ra,0xfffff
    80003386:	40a080e7          	jalr	1034(ra) # 8000278c <kill>
}
    8000338a:	60e2                	ld	ra,24(sp)
    8000338c:	6442                	ld	s0,16(sp)
    8000338e:	6105                	addi	sp,sp,32
    80003390:	8082                	ret

0000000080003392 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003392:	1101                	addi	sp,sp,-32
    80003394:	ec06                	sd	ra,24(sp)
    80003396:	e822                	sd	s0,16(sp)
    80003398:	e426                	sd	s1,8(sp)
    8000339a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000339c:	00014517          	auipc	a0,0x14
    800033a0:	55450513          	addi	a0,a0,1364 # 800178f0 <tickslock>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	842080e7          	jalr	-1982(ra) # 80000be6 <acquire>
  xticks = ticks;
    800033ac:	00006497          	auipc	s1,0x6
    800033b0:	ca84a483          	lw	s1,-856(s1) # 80009054 <ticks>
  release(&tickslock);
    800033b4:	00014517          	auipc	a0,0x14
    800033b8:	53c50513          	addi	a0,a0,1340 # 800178f0 <tickslock>
    800033bc:	ffffe097          	auipc	ra,0xffffe
    800033c0:	8de080e7          	jalr	-1826(ra) # 80000c9a <release>
  return xticks;
}
    800033c4:	02049513          	slli	a0,s1,0x20
    800033c8:	9101                	srli	a0,a0,0x20
    800033ca:	60e2                	ld	ra,24(sp)
    800033cc:	6442                	ld	s0,16(sp)
    800033ce:	64a2                	ld	s1,8(sp)
    800033d0:	6105                	addi	sp,sp,32
    800033d2:	8082                	ret

00000000800033d4 <sys_pause_system>:

uint64
sys_pause_system(void)
{
    800033d4:	1101                	addi	sp,sp,-32
    800033d6:	ec06                	sd	ra,24(sp)
    800033d8:	e822                	sd	s0,16(sp)
    800033da:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    800033dc:	fec40593          	addi	a1,s0,-20
    800033e0:	4501                	li	a0,0
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	d0e080e7          	jalr	-754(ra) # 800030f0 <argint>
    800033ea:	87aa                	mv	a5,a0
    return -1;
    800033ec:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    800033ee:	0007c863          	bltz	a5,800033fe <sys_pause_system+0x2a>
  return pause_system(seconds);
    800033f2:	fec42503          	lw	a0,-20(s0)
    800033f6:	fffff097          	auipc	ra,0xfffff
    800033fa:	5cc080e7          	jalr	1484(ra) # 800029c2 <pause_system>
}
    800033fe:	60e2                	ld	ra,24(sp)
    80003400:	6442                	ld	s0,16(sp)
    80003402:	6105                	addi	sp,sp,32
    80003404:	8082                	ret

0000000080003406 <sys_kill_system>:


uint64
sys_kill_system(void)
{
    80003406:	1141                	addi	sp,sp,-16
    80003408:	e406                	sd	ra,8(sp)
    8000340a:	e022                	sd	s0,0(sp)
    8000340c:	0800                	addi	s0,sp,16
  return kill_system();
    8000340e:	fffff097          	auipc	ra,0xfffff
    80003412:	668080e7          	jalr	1640(ra) # 80002a76 <kill_system>
}
    80003416:	60a2                	ld	ra,8(sp)
    80003418:	6402                	ld	s0,0(sp)
    8000341a:	0141                	addi	sp,sp,16
    8000341c:	8082                	ret

000000008000341e <sys_print_stats>:

uint64
sys_print_stats(void){
    8000341e:	1141                	addi	sp,sp,-16
    80003420:	e406                	sd	ra,8(sp)
    80003422:	e022                	sd	s0,0(sp)
    80003424:	0800                	addi	s0,sp,16
  print_stats();
    80003426:	fffff097          	auipc	ra,0xfffff
    8000342a:	72c080e7          	jalr	1836(ra) # 80002b52 <print_stats>
  return 0;
}
    8000342e:	4501                	li	a0,0
    80003430:	60a2                	ld	ra,8(sp)
    80003432:	6402                	ld	s0,0(sp)
    80003434:	0141                	addi	sp,sp,16
    80003436:	8082                	ret

0000000080003438 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003438:	7179                	addi	sp,sp,-48
    8000343a:	f406                	sd	ra,40(sp)
    8000343c:	f022                	sd	s0,32(sp)
    8000343e:	ec26                	sd	s1,24(sp)
    80003440:	e84a                	sd	s2,16(sp)
    80003442:	e44e                	sd	s3,8(sp)
    80003444:	e052                	sd	s4,0(sp)
    80003446:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003448:	00005597          	auipc	a1,0x5
    8000344c:	20058593          	addi	a1,a1,512 # 80008648 <syscalls+0xc8>
    80003450:	00014517          	auipc	a0,0x14
    80003454:	4b850513          	addi	a0,a0,1208 # 80017908 <bcache>
    80003458:	ffffd097          	auipc	ra,0xffffd
    8000345c:	6fe080e7          	jalr	1790(ra) # 80000b56 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003460:	0001c797          	auipc	a5,0x1c
    80003464:	4a878793          	addi	a5,a5,1192 # 8001f908 <bcache+0x8000>
    80003468:	0001c717          	auipc	a4,0x1c
    8000346c:	70870713          	addi	a4,a4,1800 # 8001fb70 <bcache+0x8268>
    80003470:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003474:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003478:	00014497          	auipc	s1,0x14
    8000347c:	4a848493          	addi	s1,s1,1192 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    80003480:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003482:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003484:	00005a17          	auipc	s4,0x5
    80003488:	1cca0a13          	addi	s4,s4,460 # 80008650 <syscalls+0xd0>
    b->next = bcache.head.next;
    8000348c:	2b893783          	ld	a5,696(s2)
    80003490:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003492:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003496:	85d2                	mv	a1,s4
    80003498:	01048513          	addi	a0,s1,16
    8000349c:	00001097          	auipc	ra,0x1
    800034a0:	4bc080e7          	jalr	1212(ra) # 80004958 <initsleeplock>
    bcache.head.next->prev = b;
    800034a4:	2b893783          	ld	a5,696(s2)
    800034a8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034aa:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034ae:	45848493          	addi	s1,s1,1112
    800034b2:	fd349de3          	bne	s1,s3,8000348c <binit+0x54>
  }
}
    800034b6:	70a2                	ld	ra,40(sp)
    800034b8:	7402                	ld	s0,32(sp)
    800034ba:	64e2                	ld	s1,24(sp)
    800034bc:	6942                	ld	s2,16(sp)
    800034be:	69a2                	ld	s3,8(sp)
    800034c0:	6a02                	ld	s4,0(sp)
    800034c2:	6145                	addi	sp,sp,48
    800034c4:	8082                	ret

00000000800034c6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034c6:	7179                	addi	sp,sp,-48
    800034c8:	f406                	sd	ra,40(sp)
    800034ca:	f022                	sd	s0,32(sp)
    800034cc:	ec26                	sd	s1,24(sp)
    800034ce:	e84a                	sd	s2,16(sp)
    800034d0:	e44e                	sd	s3,8(sp)
    800034d2:	1800                	addi	s0,sp,48
    800034d4:	89aa                	mv	s3,a0
    800034d6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800034d8:	00014517          	auipc	a0,0x14
    800034dc:	43050513          	addi	a0,a0,1072 # 80017908 <bcache>
    800034e0:	ffffd097          	auipc	ra,0xffffd
    800034e4:	706080e7          	jalr	1798(ra) # 80000be6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034e8:	0001c497          	auipc	s1,0x1c
    800034ec:	6d84b483          	ld	s1,1752(s1) # 8001fbc0 <bcache+0x82b8>
    800034f0:	0001c797          	auipc	a5,0x1c
    800034f4:	68078793          	addi	a5,a5,1664 # 8001fb70 <bcache+0x8268>
    800034f8:	02f48f63          	beq	s1,a5,80003536 <bread+0x70>
    800034fc:	873e                	mv	a4,a5
    800034fe:	a021                	j	80003506 <bread+0x40>
    80003500:	68a4                	ld	s1,80(s1)
    80003502:	02e48a63          	beq	s1,a4,80003536 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003506:	449c                	lw	a5,8(s1)
    80003508:	ff379ce3          	bne	a5,s3,80003500 <bread+0x3a>
    8000350c:	44dc                	lw	a5,12(s1)
    8000350e:	ff2799e3          	bne	a5,s2,80003500 <bread+0x3a>
      b->refcnt++;
    80003512:	40bc                	lw	a5,64(s1)
    80003514:	2785                	addiw	a5,a5,1
    80003516:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003518:	00014517          	auipc	a0,0x14
    8000351c:	3f050513          	addi	a0,a0,1008 # 80017908 <bcache>
    80003520:	ffffd097          	auipc	ra,0xffffd
    80003524:	77a080e7          	jalr	1914(ra) # 80000c9a <release>
      acquiresleep(&b->lock);
    80003528:	01048513          	addi	a0,s1,16
    8000352c:	00001097          	auipc	ra,0x1
    80003530:	466080e7          	jalr	1126(ra) # 80004992 <acquiresleep>
      return b;
    80003534:	a8b9                	j	80003592 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003536:	0001c497          	auipc	s1,0x1c
    8000353a:	6824b483          	ld	s1,1666(s1) # 8001fbb8 <bcache+0x82b0>
    8000353e:	0001c797          	auipc	a5,0x1c
    80003542:	63278793          	addi	a5,a5,1586 # 8001fb70 <bcache+0x8268>
    80003546:	00f48863          	beq	s1,a5,80003556 <bread+0x90>
    8000354a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000354c:	40bc                	lw	a5,64(s1)
    8000354e:	cf81                	beqz	a5,80003566 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003550:	64a4                	ld	s1,72(s1)
    80003552:	fee49de3          	bne	s1,a4,8000354c <bread+0x86>
  panic("bget: no buffers");
    80003556:	00005517          	auipc	a0,0x5
    8000355a:	10250513          	addi	a0,a0,258 # 80008658 <syscalls+0xd8>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	fe2080e7          	jalr	-30(ra) # 80000540 <panic>
      b->dev = dev;
    80003566:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000356a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000356e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003572:	4785                	li	a5,1
    80003574:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003576:	00014517          	auipc	a0,0x14
    8000357a:	39250513          	addi	a0,a0,914 # 80017908 <bcache>
    8000357e:	ffffd097          	auipc	ra,0xffffd
    80003582:	71c080e7          	jalr	1820(ra) # 80000c9a <release>
      acquiresleep(&b->lock);
    80003586:	01048513          	addi	a0,s1,16
    8000358a:	00001097          	auipc	ra,0x1
    8000358e:	408080e7          	jalr	1032(ra) # 80004992 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003592:	409c                	lw	a5,0(s1)
    80003594:	cb89                	beqz	a5,800035a6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003596:	8526                	mv	a0,s1
    80003598:	70a2                	ld	ra,40(sp)
    8000359a:	7402                	ld	s0,32(sp)
    8000359c:	64e2                	ld	s1,24(sp)
    8000359e:	6942                	ld	s2,16(sp)
    800035a0:	69a2                	ld	s3,8(sp)
    800035a2:	6145                	addi	sp,sp,48
    800035a4:	8082                	ret
    virtio_disk_rw(b, 0);
    800035a6:	4581                	li	a1,0
    800035a8:	8526                	mv	a0,s1
    800035aa:	00003097          	auipc	ra,0x3
    800035ae:	f0c080e7          	jalr	-244(ra) # 800064b6 <virtio_disk_rw>
    b->valid = 1;
    800035b2:	4785                	li	a5,1
    800035b4:	c09c                	sw	a5,0(s1)
  return b;
    800035b6:	b7c5                	j	80003596 <bread+0xd0>

00000000800035b8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035b8:	1101                	addi	sp,sp,-32
    800035ba:	ec06                	sd	ra,24(sp)
    800035bc:	e822                	sd	s0,16(sp)
    800035be:	e426                	sd	s1,8(sp)
    800035c0:	1000                	addi	s0,sp,32
    800035c2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035c4:	0541                	addi	a0,a0,16
    800035c6:	00001097          	auipc	ra,0x1
    800035ca:	466080e7          	jalr	1126(ra) # 80004a2c <holdingsleep>
    800035ce:	cd01                	beqz	a0,800035e6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035d0:	4585                	li	a1,1
    800035d2:	8526                	mv	a0,s1
    800035d4:	00003097          	auipc	ra,0x3
    800035d8:	ee2080e7          	jalr	-286(ra) # 800064b6 <virtio_disk_rw>
}
    800035dc:	60e2                	ld	ra,24(sp)
    800035de:	6442                	ld	s0,16(sp)
    800035e0:	64a2                	ld	s1,8(sp)
    800035e2:	6105                	addi	sp,sp,32
    800035e4:	8082                	ret
    panic("bwrite");
    800035e6:	00005517          	auipc	a0,0x5
    800035ea:	08a50513          	addi	a0,a0,138 # 80008670 <syscalls+0xf0>
    800035ee:	ffffd097          	auipc	ra,0xffffd
    800035f2:	f52080e7          	jalr	-174(ra) # 80000540 <panic>

00000000800035f6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035f6:	1101                	addi	sp,sp,-32
    800035f8:	ec06                	sd	ra,24(sp)
    800035fa:	e822                	sd	s0,16(sp)
    800035fc:	e426                	sd	s1,8(sp)
    800035fe:	e04a                	sd	s2,0(sp)
    80003600:	1000                	addi	s0,sp,32
    80003602:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003604:	01050913          	addi	s2,a0,16
    80003608:	854a                	mv	a0,s2
    8000360a:	00001097          	auipc	ra,0x1
    8000360e:	422080e7          	jalr	1058(ra) # 80004a2c <holdingsleep>
    80003612:	c92d                	beqz	a0,80003684 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003614:	854a                	mv	a0,s2
    80003616:	00001097          	auipc	ra,0x1
    8000361a:	3d2080e7          	jalr	978(ra) # 800049e8 <releasesleep>

  acquire(&bcache.lock);
    8000361e:	00014517          	auipc	a0,0x14
    80003622:	2ea50513          	addi	a0,a0,746 # 80017908 <bcache>
    80003626:	ffffd097          	auipc	ra,0xffffd
    8000362a:	5c0080e7          	jalr	1472(ra) # 80000be6 <acquire>
  b->refcnt--;
    8000362e:	40bc                	lw	a5,64(s1)
    80003630:	37fd                	addiw	a5,a5,-1
    80003632:	0007871b          	sext.w	a4,a5
    80003636:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003638:	eb05                	bnez	a4,80003668 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000363a:	68bc                	ld	a5,80(s1)
    8000363c:	64b8                	ld	a4,72(s1)
    8000363e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003640:	64bc                	ld	a5,72(s1)
    80003642:	68b8                	ld	a4,80(s1)
    80003644:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003646:	0001c797          	auipc	a5,0x1c
    8000364a:	2c278793          	addi	a5,a5,706 # 8001f908 <bcache+0x8000>
    8000364e:	2b87b703          	ld	a4,696(a5)
    80003652:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003654:	0001c717          	auipc	a4,0x1c
    80003658:	51c70713          	addi	a4,a4,1308 # 8001fb70 <bcache+0x8268>
    8000365c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000365e:	2b87b703          	ld	a4,696(a5)
    80003662:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003664:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003668:	00014517          	auipc	a0,0x14
    8000366c:	2a050513          	addi	a0,a0,672 # 80017908 <bcache>
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	62a080e7          	jalr	1578(ra) # 80000c9a <release>
}
    80003678:	60e2                	ld	ra,24(sp)
    8000367a:	6442                	ld	s0,16(sp)
    8000367c:	64a2                	ld	s1,8(sp)
    8000367e:	6902                	ld	s2,0(sp)
    80003680:	6105                	addi	sp,sp,32
    80003682:	8082                	ret
    panic("brelse");
    80003684:	00005517          	auipc	a0,0x5
    80003688:	ff450513          	addi	a0,a0,-12 # 80008678 <syscalls+0xf8>
    8000368c:	ffffd097          	auipc	ra,0xffffd
    80003690:	eb4080e7          	jalr	-332(ra) # 80000540 <panic>

0000000080003694 <bpin>:

void
bpin(struct buf *b) {
    80003694:	1101                	addi	sp,sp,-32
    80003696:	ec06                	sd	ra,24(sp)
    80003698:	e822                	sd	s0,16(sp)
    8000369a:	e426                	sd	s1,8(sp)
    8000369c:	1000                	addi	s0,sp,32
    8000369e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036a0:	00014517          	auipc	a0,0x14
    800036a4:	26850513          	addi	a0,a0,616 # 80017908 <bcache>
    800036a8:	ffffd097          	auipc	ra,0xffffd
    800036ac:	53e080e7          	jalr	1342(ra) # 80000be6 <acquire>
  b->refcnt++;
    800036b0:	40bc                	lw	a5,64(s1)
    800036b2:	2785                	addiw	a5,a5,1
    800036b4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036b6:	00014517          	auipc	a0,0x14
    800036ba:	25250513          	addi	a0,a0,594 # 80017908 <bcache>
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	5dc080e7          	jalr	1500(ra) # 80000c9a <release>
}
    800036c6:	60e2                	ld	ra,24(sp)
    800036c8:	6442                	ld	s0,16(sp)
    800036ca:	64a2                	ld	s1,8(sp)
    800036cc:	6105                	addi	sp,sp,32
    800036ce:	8082                	ret

00000000800036d0 <bunpin>:

void
bunpin(struct buf *b) {
    800036d0:	1101                	addi	sp,sp,-32
    800036d2:	ec06                	sd	ra,24(sp)
    800036d4:	e822                	sd	s0,16(sp)
    800036d6:	e426                	sd	s1,8(sp)
    800036d8:	1000                	addi	s0,sp,32
    800036da:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036dc:	00014517          	auipc	a0,0x14
    800036e0:	22c50513          	addi	a0,a0,556 # 80017908 <bcache>
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	502080e7          	jalr	1282(ra) # 80000be6 <acquire>
  b->refcnt--;
    800036ec:	40bc                	lw	a5,64(s1)
    800036ee:	37fd                	addiw	a5,a5,-1
    800036f0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036f2:	00014517          	auipc	a0,0x14
    800036f6:	21650513          	addi	a0,a0,534 # 80017908 <bcache>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	5a0080e7          	jalr	1440(ra) # 80000c9a <release>
}
    80003702:	60e2                	ld	ra,24(sp)
    80003704:	6442                	ld	s0,16(sp)
    80003706:	64a2                	ld	s1,8(sp)
    80003708:	6105                	addi	sp,sp,32
    8000370a:	8082                	ret

000000008000370c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000370c:	1101                	addi	sp,sp,-32
    8000370e:	ec06                	sd	ra,24(sp)
    80003710:	e822                	sd	s0,16(sp)
    80003712:	e426                	sd	s1,8(sp)
    80003714:	e04a                	sd	s2,0(sp)
    80003716:	1000                	addi	s0,sp,32
    80003718:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000371a:	00d5d59b          	srliw	a1,a1,0xd
    8000371e:	0001d797          	auipc	a5,0x1d
    80003722:	8c67a783          	lw	a5,-1850(a5) # 8001ffe4 <sb+0x1c>
    80003726:	9dbd                	addw	a1,a1,a5
    80003728:	00000097          	auipc	ra,0x0
    8000372c:	d9e080e7          	jalr	-610(ra) # 800034c6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003730:	0074f713          	andi	a4,s1,7
    80003734:	4785                	li	a5,1
    80003736:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000373a:	14ce                	slli	s1,s1,0x33
    8000373c:	90d9                	srli	s1,s1,0x36
    8000373e:	00950733          	add	a4,a0,s1
    80003742:	05874703          	lbu	a4,88(a4)
    80003746:	00e7f6b3          	and	a3,a5,a4
    8000374a:	c69d                	beqz	a3,80003778 <bfree+0x6c>
    8000374c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000374e:	94aa                	add	s1,s1,a0
    80003750:	fff7c793          	not	a5,a5
    80003754:	8ff9                	and	a5,a5,a4
    80003756:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000375a:	00001097          	auipc	ra,0x1
    8000375e:	118080e7          	jalr	280(ra) # 80004872 <log_write>
  brelse(bp);
    80003762:	854a                	mv	a0,s2
    80003764:	00000097          	auipc	ra,0x0
    80003768:	e92080e7          	jalr	-366(ra) # 800035f6 <brelse>
}
    8000376c:	60e2                	ld	ra,24(sp)
    8000376e:	6442                	ld	s0,16(sp)
    80003770:	64a2                	ld	s1,8(sp)
    80003772:	6902                	ld	s2,0(sp)
    80003774:	6105                	addi	sp,sp,32
    80003776:	8082                	ret
    panic("freeing free block");
    80003778:	00005517          	auipc	a0,0x5
    8000377c:	f0850513          	addi	a0,a0,-248 # 80008680 <syscalls+0x100>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	dc0080e7          	jalr	-576(ra) # 80000540 <panic>

0000000080003788 <balloc>:
{
    80003788:	711d                	addi	sp,sp,-96
    8000378a:	ec86                	sd	ra,88(sp)
    8000378c:	e8a2                	sd	s0,80(sp)
    8000378e:	e4a6                	sd	s1,72(sp)
    80003790:	e0ca                	sd	s2,64(sp)
    80003792:	fc4e                	sd	s3,56(sp)
    80003794:	f852                	sd	s4,48(sp)
    80003796:	f456                	sd	s5,40(sp)
    80003798:	f05a                	sd	s6,32(sp)
    8000379a:	ec5e                	sd	s7,24(sp)
    8000379c:	e862                	sd	s8,16(sp)
    8000379e:	e466                	sd	s9,8(sp)
    800037a0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037a2:	0001d797          	auipc	a5,0x1d
    800037a6:	82a7a783          	lw	a5,-2006(a5) # 8001ffcc <sb+0x4>
    800037aa:	cbd1                	beqz	a5,8000383e <balloc+0xb6>
    800037ac:	8baa                	mv	s7,a0
    800037ae:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037b0:	0001db17          	auipc	s6,0x1d
    800037b4:	818b0b13          	addi	s6,s6,-2024 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037b8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037ba:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037bc:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037be:	6c89                	lui	s9,0x2
    800037c0:	a831                	j	800037dc <balloc+0x54>
    brelse(bp);
    800037c2:	854a                	mv	a0,s2
    800037c4:	00000097          	auipc	ra,0x0
    800037c8:	e32080e7          	jalr	-462(ra) # 800035f6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037cc:	015c87bb          	addw	a5,s9,s5
    800037d0:	00078a9b          	sext.w	s5,a5
    800037d4:	004b2703          	lw	a4,4(s6)
    800037d8:	06eaf363          	bgeu	s5,a4,8000383e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800037dc:	41fad79b          	sraiw	a5,s5,0x1f
    800037e0:	0137d79b          	srliw	a5,a5,0x13
    800037e4:	015787bb          	addw	a5,a5,s5
    800037e8:	40d7d79b          	sraiw	a5,a5,0xd
    800037ec:	01cb2583          	lw	a1,28(s6)
    800037f0:	9dbd                	addw	a1,a1,a5
    800037f2:	855e                	mv	a0,s7
    800037f4:	00000097          	auipc	ra,0x0
    800037f8:	cd2080e7          	jalr	-814(ra) # 800034c6 <bread>
    800037fc:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037fe:	004b2503          	lw	a0,4(s6)
    80003802:	000a849b          	sext.w	s1,s5
    80003806:	8662                	mv	a2,s8
    80003808:	faa4fde3          	bgeu	s1,a0,800037c2 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000380c:	41f6579b          	sraiw	a5,a2,0x1f
    80003810:	01d7d69b          	srliw	a3,a5,0x1d
    80003814:	00c6873b          	addw	a4,a3,a2
    80003818:	00777793          	andi	a5,a4,7
    8000381c:	9f95                	subw	a5,a5,a3
    8000381e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003822:	4037571b          	sraiw	a4,a4,0x3
    80003826:	00e906b3          	add	a3,s2,a4
    8000382a:	0586c683          	lbu	a3,88(a3)
    8000382e:	00d7f5b3          	and	a1,a5,a3
    80003832:	cd91                	beqz	a1,8000384e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003834:	2605                	addiw	a2,a2,1
    80003836:	2485                	addiw	s1,s1,1
    80003838:	fd4618e3          	bne	a2,s4,80003808 <balloc+0x80>
    8000383c:	b759                	j	800037c2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000383e:	00005517          	auipc	a0,0x5
    80003842:	e5a50513          	addi	a0,a0,-422 # 80008698 <syscalls+0x118>
    80003846:	ffffd097          	auipc	ra,0xffffd
    8000384a:	cfa080e7          	jalr	-774(ra) # 80000540 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000384e:	974a                	add	a4,a4,s2
    80003850:	8fd5                	or	a5,a5,a3
    80003852:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003856:	854a                	mv	a0,s2
    80003858:	00001097          	auipc	ra,0x1
    8000385c:	01a080e7          	jalr	26(ra) # 80004872 <log_write>
        brelse(bp);
    80003860:	854a                	mv	a0,s2
    80003862:	00000097          	auipc	ra,0x0
    80003866:	d94080e7          	jalr	-620(ra) # 800035f6 <brelse>
  bp = bread(dev, bno);
    8000386a:	85a6                	mv	a1,s1
    8000386c:	855e                	mv	a0,s7
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	c58080e7          	jalr	-936(ra) # 800034c6 <bread>
    80003876:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003878:	40000613          	li	a2,1024
    8000387c:	4581                	li	a1,0
    8000387e:	05850513          	addi	a0,a0,88
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	460080e7          	jalr	1120(ra) # 80000ce2 <memset>
  log_write(bp);
    8000388a:	854a                	mv	a0,s2
    8000388c:	00001097          	auipc	ra,0x1
    80003890:	fe6080e7          	jalr	-26(ra) # 80004872 <log_write>
  brelse(bp);
    80003894:	854a                	mv	a0,s2
    80003896:	00000097          	auipc	ra,0x0
    8000389a:	d60080e7          	jalr	-672(ra) # 800035f6 <brelse>
}
    8000389e:	8526                	mv	a0,s1
    800038a0:	60e6                	ld	ra,88(sp)
    800038a2:	6446                	ld	s0,80(sp)
    800038a4:	64a6                	ld	s1,72(sp)
    800038a6:	6906                	ld	s2,64(sp)
    800038a8:	79e2                	ld	s3,56(sp)
    800038aa:	7a42                	ld	s4,48(sp)
    800038ac:	7aa2                	ld	s5,40(sp)
    800038ae:	7b02                	ld	s6,32(sp)
    800038b0:	6be2                	ld	s7,24(sp)
    800038b2:	6c42                	ld	s8,16(sp)
    800038b4:	6ca2                	ld	s9,8(sp)
    800038b6:	6125                	addi	sp,sp,96
    800038b8:	8082                	ret

00000000800038ba <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800038ba:	7179                	addi	sp,sp,-48
    800038bc:	f406                	sd	ra,40(sp)
    800038be:	f022                	sd	s0,32(sp)
    800038c0:	ec26                	sd	s1,24(sp)
    800038c2:	e84a                	sd	s2,16(sp)
    800038c4:	e44e                	sd	s3,8(sp)
    800038c6:	e052                	sd	s4,0(sp)
    800038c8:	1800                	addi	s0,sp,48
    800038ca:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800038cc:	47ad                	li	a5,11
    800038ce:	04b7fe63          	bgeu	a5,a1,8000392a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800038d2:	ff45849b          	addiw	s1,a1,-12
    800038d6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038da:	0ff00793          	li	a5,255
    800038de:	0ae7e363          	bltu	a5,a4,80003984 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800038e2:	08052583          	lw	a1,128(a0)
    800038e6:	c5ad                	beqz	a1,80003950 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800038e8:	00092503          	lw	a0,0(s2)
    800038ec:	00000097          	auipc	ra,0x0
    800038f0:	bda080e7          	jalr	-1062(ra) # 800034c6 <bread>
    800038f4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038f6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800038fa:	02049593          	slli	a1,s1,0x20
    800038fe:	9181                	srli	a1,a1,0x20
    80003900:	058a                	slli	a1,a1,0x2
    80003902:	00b784b3          	add	s1,a5,a1
    80003906:	0004a983          	lw	s3,0(s1)
    8000390a:	04098d63          	beqz	s3,80003964 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000390e:	8552                	mv	a0,s4
    80003910:	00000097          	auipc	ra,0x0
    80003914:	ce6080e7          	jalr	-794(ra) # 800035f6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003918:	854e                	mv	a0,s3
    8000391a:	70a2                	ld	ra,40(sp)
    8000391c:	7402                	ld	s0,32(sp)
    8000391e:	64e2                	ld	s1,24(sp)
    80003920:	6942                	ld	s2,16(sp)
    80003922:	69a2                	ld	s3,8(sp)
    80003924:	6a02                	ld	s4,0(sp)
    80003926:	6145                	addi	sp,sp,48
    80003928:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000392a:	02059493          	slli	s1,a1,0x20
    8000392e:	9081                	srli	s1,s1,0x20
    80003930:	048a                	slli	s1,s1,0x2
    80003932:	94aa                	add	s1,s1,a0
    80003934:	0504a983          	lw	s3,80(s1)
    80003938:	fe0990e3          	bnez	s3,80003918 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000393c:	4108                	lw	a0,0(a0)
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	e4a080e7          	jalr	-438(ra) # 80003788 <balloc>
    80003946:	0005099b          	sext.w	s3,a0
    8000394a:	0534a823          	sw	s3,80(s1)
    8000394e:	b7e9                	j	80003918 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003950:	4108                	lw	a0,0(a0)
    80003952:	00000097          	auipc	ra,0x0
    80003956:	e36080e7          	jalr	-458(ra) # 80003788 <balloc>
    8000395a:	0005059b          	sext.w	a1,a0
    8000395e:	08b92023          	sw	a1,128(s2)
    80003962:	b759                	j	800038e8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003964:	00092503          	lw	a0,0(s2)
    80003968:	00000097          	auipc	ra,0x0
    8000396c:	e20080e7          	jalr	-480(ra) # 80003788 <balloc>
    80003970:	0005099b          	sext.w	s3,a0
    80003974:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003978:	8552                	mv	a0,s4
    8000397a:	00001097          	auipc	ra,0x1
    8000397e:	ef8080e7          	jalr	-264(ra) # 80004872 <log_write>
    80003982:	b771                	j	8000390e <bmap+0x54>
  panic("bmap: out of range");
    80003984:	00005517          	auipc	a0,0x5
    80003988:	d2c50513          	addi	a0,a0,-724 # 800086b0 <syscalls+0x130>
    8000398c:	ffffd097          	auipc	ra,0xffffd
    80003990:	bb4080e7          	jalr	-1100(ra) # 80000540 <panic>

0000000080003994 <iget>:
{
    80003994:	7179                	addi	sp,sp,-48
    80003996:	f406                	sd	ra,40(sp)
    80003998:	f022                	sd	s0,32(sp)
    8000399a:	ec26                	sd	s1,24(sp)
    8000399c:	e84a                	sd	s2,16(sp)
    8000399e:	e44e                	sd	s3,8(sp)
    800039a0:	e052                	sd	s4,0(sp)
    800039a2:	1800                	addi	s0,sp,48
    800039a4:	89aa                	mv	s3,a0
    800039a6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039a8:	0001c517          	auipc	a0,0x1c
    800039ac:	64050513          	addi	a0,a0,1600 # 8001ffe8 <itable>
    800039b0:	ffffd097          	auipc	ra,0xffffd
    800039b4:	236080e7          	jalr	566(ra) # 80000be6 <acquire>
  empty = 0;
    800039b8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039ba:	0001c497          	auipc	s1,0x1c
    800039be:	64648493          	addi	s1,s1,1606 # 80020000 <itable+0x18>
    800039c2:	0001e697          	auipc	a3,0x1e
    800039c6:	0ce68693          	addi	a3,a3,206 # 80021a90 <log>
    800039ca:	a039                	j	800039d8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039cc:	02090b63          	beqz	s2,80003a02 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039d0:	08848493          	addi	s1,s1,136
    800039d4:	02d48a63          	beq	s1,a3,80003a08 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039d8:	449c                	lw	a5,8(s1)
    800039da:	fef059e3          	blez	a5,800039cc <iget+0x38>
    800039de:	4098                	lw	a4,0(s1)
    800039e0:	ff3716e3          	bne	a4,s3,800039cc <iget+0x38>
    800039e4:	40d8                	lw	a4,4(s1)
    800039e6:	ff4713e3          	bne	a4,s4,800039cc <iget+0x38>
      ip->ref++;
    800039ea:	2785                	addiw	a5,a5,1
    800039ec:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800039ee:	0001c517          	auipc	a0,0x1c
    800039f2:	5fa50513          	addi	a0,a0,1530 # 8001ffe8 <itable>
    800039f6:	ffffd097          	auipc	ra,0xffffd
    800039fa:	2a4080e7          	jalr	676(ra) # 80000c9a <release>
      return ip;
    800039fe:	8926                	mv	s2,s1
    80003a00:	a03d                	j	80003a2e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a02:	f7f9                	bnez	a5,800039d0 <iget+0x3c>
    80003a04:	8926                	mv	s2,s1
    80003a06:	b7e9                	j	800039d0 <iget+0x3c>
  if(empty == 0)
    80003a08:	02090c63          	beqz	s2,80003a40 <iget+0xac>
  ip->dev = dev;
    80003a0c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a10:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a14:	4785                	li	a5,1
    80003a16:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a1a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a1e:	0001c517          	auipc	a0,0x1c
    80003a22:	5ca50513          	addi	a0,a0,1482 # 8001ffe8 <itable>
    80003a26:	ffffd097          	auipc	ra,0xffffd
    80003a2a:	274080e7          	jalr	628(ra) # 80000c9a <release>
}
    80003a2e:	854a                	mv	a0,s2
    80003a30:	70a2                	ld	ra,40(sp)
    80003a32:	7402                	ld	s0,32(sp)
    80003a34:	64e2                	ld	s1,24(sp)
    80003a36:	6942                	ld	s2,16(sp)
    80003a38:	69a2                	ld	s3,8(sp)
    80003a3a:	6a02                	ld	s4,0(sp)
    80003a3c:	6145                	addi	sp,sp,48
    80003a3e:	8082                	ret
    panic("iget: no inodes");
    80003a40:	00005517          	auipc	a0,0x5
    80003a44:	c8850513          	addi	a0,a0,-888 # 800086c8 <syscalls+0x148>
    80003a48:	ffffd097          	auipc	ra,0xffffd
    80003a4c:	af8080e7          	jalr	-1288(ra) # 80000540 <panic>

0000000080003a50 <fsinit>:
fsinit(int dev) {
    80003a50:	7179                	addi	sp,sp,-48
    80003a52:	f406                	sd	ra,40(sp)
    80003a54:	f022                	sd	s0,32(sp)
    80003a56:	ec26                	sd	s1,24(sp)
    80003a58:	e84a                	sd	s2,16(sp)
    80003a5a:	e44e                	sd	s3,8(sp)
    80003a5c:	1800                	addi	s0,sp,48
    80003a5e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a60:	4585                	li	a1,1
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	a64080e7          	jalr	-1436(ra) # 800034c6 <bread>
    80003a6a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a6c:	0001c997          	auipc	s3,0x1c
    80003a70:	55c98993          	addi	s3,s3,1372 # 8001ffc8 <sb>
    80003a74:	02000613          	li	a2,32
    80003a78:	05850593          	addi	a1,a0,88
    80003a7c:	854e                	mv	a0,s3
    80003a7e:	ffffd097          	auipc	ra,0xffffd
    80003a82:	2c4080e7          	jalr	708(ra) # 80000d42 <memmove>
  brelse(bp);
    80003a86:	8526                	mv	a0,s1
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	b6e080e7          	jalr	-1170(ra) # 800035f6 <brelse>
  if(sb.magic != FSMAGIC)
    80003a90:	0009a703          	lw	a4,0(s3)
    80003a94:	102037b7          	lui	a5,0x10203
    80003a98:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a9c:	02f71263          	bne	a4,a5,80003ac0 <fsinit+0x70>
  initlog(dev, &sb);
    80003aa0:	0001c597          	auipc	a1,0x1c
    80003aa4:	52858593          	addi	a1,a1,1320 # 8001ffc8 <sb>
    80003aa8:	854a                	mv	a0,s2
    80003aaa:	00001097          	auipc	ra,0x1
    80003aae:	b4c080e7          	jalr	-1204(ra) # 800045f6 <initlog>
}
    80003ab2:	70a2                	ld	ra,40(sp)
    80003ab4:	7402                	ld	s0,32(sp)
    80003ab6:	64e2                	ld	s1,24(sp)
    80003ab8:	6942                	ld	s2,16(sp)
    80003aba:	69a2                	ld	s3,8(sp)
    80003abc:	6145                	addi	sp,sp,48
    80003abe:	8082                	ret
    panic("invalid file system");
    80003ac0:	00005517          	auipc	a0,0x5
    80003ac4:	c1850513          	addi	a0,a0,-1000 # 800086d8 <syscalls+0x158>
    80003ac8:	ffffd097          	auipc	ra,0xffffd
    80003acc:	a78080e7          	jalr	-1416(ra) # 80000540 <panic>

0000000080003ad0 <iinit>:
{
    80003ad0:	7179                	addi	sp,sp,-48
    80003ad2:	f406                	sd	ra,40(sp)
    80003ad4:	f022                	sd	s0,32(sp)
    80003ad6:	ec26                	sd	s1,24(sp)
    80003ad8:	e84a                	sd	s2,16(sp)
    80003ada:	e44e                	sd	s3,8(sp)
    80003adc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003ade:	00005597          	auipc	a1,0x5
    80003ae2:	c1258593          	addi	a1,a1,-1006 # 800086f0 <syscalls+0x170>
    80003ae6:	0001c517          	auipc	a0,0x1c
    80003aea:	50250513          	addi	a0,a0,1282 # 8001ffe8 <itable>
    80003aee:	ffffd097          	auipc	ra,0xffffd
    80003af2:	068080e7          	jalr	104(ra) # 80000b56 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003af6:	0001c497          	auipc	s1,0x1c
    80003afa:	51a48493          	addi	s1,s1,1306 # 80020010 <itable+0x28>
    80003afe:	0001e997          	auipc	s3,0x1e
    80003b02:	fa298993          	addi	s3,s3,-94 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b06:	00005917          	auipc	s2,0x5
    80003b0a:	bf290913          	addi	s2,s2,-1038 # 800086f8 <syscalls+0x178>
    80003b0e:	85ca                	mv	a1,s2
    80003b10:	8526                	mv	a0,s1
    80003b12:	00001097          	auipc	ra,0x1
    80003b16:	e46080e7          	jalr	-442(ra) # 80004958 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b1a:	08848493          	addi	s1,s1,136
    80003b1e:	ff3498e3          	bne	s1,s3,80003b0e <iinit+0x3e>
}
    80003b22:	70a2                	ld	ra,40(sp)
    80003b24:	7402                	ld	s0,32(sp)
    80003b26:	64e2                	ld	s1,24(sp)
    80003b28:	6942                	ld	s2,16(sp)
    80003b2a:	69a2                	ld	s3,8(sp)
    80003b2c:	6145                	addi	sp,sp,48
    80003b2e:	8082                	ret

0000000080003b30 <ialloc>:
{
    80003b30:	715d                	addi	sp,sp,-80
    80003b32:	e486                	sd	ra,72(sp)
    80003b34:	e0a2                	sd	s0,64(sp)
    80003b36:	fc26                	sd	s1,56(sp)
    80003b38:	f84a                	sd	s2,48(sp)
    80003b3a:	f44e                	sd	s3,40(sp)
    80003b3c:	f052                	sd	s4,32(sp)
    80003b3e:	ec56                	sd	s5,24(sp)
    80003b40:	e85a                	sd	s6,16(sp)
    80003b42:	e45e                	sd	s7,8(sp)
    80003b44:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b46:	0001c717          	auipc	a4,0x1c
    80003b4a:	48e72703          	lw	a4,1166(a4) # 8001ffd4 <sb+0xc>
    80003b4e:	4785                	li	a5,1
    80003b50:	04e7fa63          	bgeu	a5,a4,80003ba4 <ialloc+0x74>
    80003b54:	8aaa                	mv	s5,a0
    80003b56:	8bae                	mv	s7,a1
    80003b58:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b5a:	0001ca17          	auipc	s4,0x1c
    80003b5e:	46ea0a13          	addi	s4,s4,1134 # 8001ffc8 <sb>
    80003b62:	00048b1b          	sext.w	s6,s1
    80003b66:	0044d593          	srli	a1,s1,0x4
    80003b6a:	018a2783          	lw	a5,24(s4)
    80003b6e:	9dbd                	addw	a1,a1,a5
    80003b70:	8556                	mv	a0,s5
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	954080e7          	jalr	-1708(ra) # 800034c6 <bread>
    80003b7a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b7c:	05850993          	addi	s3,a0,88
    80003b80:	00f4f793          	andi	a5,s1,15
    80003b84:	079a                	slli	a5,a5,0x6
    80003b86:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b88:	00099783          	lh	a5,0(s3)
    80003b8c:	c785                	beqz	a5,80003bb4 <ialloc+0x84>
    brelse(bp);
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	a68080e7          	jalr	-1432(ra) # 800035f6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b96:	0485                	addi	s1,s1,1
    80003b98:	00ca2703          	lw	a4,12(s4)
    80003b9c:	0004879b          	sext.w	a5,s1
    80003ba0:	fce7e1e3          	bltu	a5,a4,80003b62 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003ba4:	00005517          	auipc	a0,0x5
    80003ba8:	b5c50513          	addi	a0,a0,-1188 # 80008700 <syscalls+0x180>
    80003bac:	ffffd097          	auipc	ra,0xffffd
    80003bb0:	994080e7          	jalr	-1644(ra) # 80000540 <panic>
      memset(dip, 0, sizeof(*dip));
    80003bb4:	04000613          	li	a2,64
    80003bb8:	4581                	li	a1,0
    80003bba:	854e                	mv	a0,s3
    80003bbc:	ffffd097          	auipc	ra,0xffffd
    80003bc0:	126080e7          	jalr	294(ra) # 80000ce2 <memset>
      dip->type = type;
    80003bc4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003bc8:	854a                	mv	a0,s2
    80003bca:	00001097          	auipc	ra,0x1
    80003bce:	ca8080e7          	jalr	-856(ra) # 80004872 <log_write>
      brelse(bp);
    80003bd2:	854a                	mv	a0,s2
    80003bd4:	00000097          	auipc	ra,0x0
    80003bd8:	a22080e7          	jalr	-1502(ra) # 800035f6 <brelse>
      return iget(dev, inum);
    80003bdc:	85da                	mv	a1,s6
    80003bde:	8556                	mv	a0,s5
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	db4080e7          	jalr	-588(ra) # 80003994 <iget>
}
    80003be8:	60a6                	ld	ra,72(sp)
    80003bea:	6406                	ld	s0,64(sp)
    80003bec:	74e2                	ld	s1,56(sp)
    80003bee:	7942                	ld	s2,48(sp)
    80003bf0:	79a2                	ld	s3,40(sp)
    80003bf2:	7a02                	ld	s4,32(sp)
    80003bf4:	6ae2                	ld	s5,24(sp)
    80003bf6:	6b42                	ld	s6,16(sp)
    80003bf8:	6ba2                	ld	s7,8(sp)
    80003bfa:	6161                	addi	sp,sp,80
    80003bfc:	8082                	ret

0000000080003bfe <iupdate>:
{
    80003bfe:	1101                	addi	sp,sp,-32
    80003c00:	ec06                	sd	ra,24(sp)
    80003c02:	e822                	sd	s0,16(sp)
    80003c04:	e426                	sd	s1,8(sp)
    80003c06:	e04a                	sd	s2,0(sp)
    80003c08:	1000                	addi	s0,sp,32
    80003c0a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c0c:	415c                	lw	a5,4(a0)
    80003c0e:	0047d79b          	srliw	a5,a5,0x4
    80003c12:	0001c597          	auipc	a1,0x1c
    80003c16:	3ce5a583          	lw	a1,974(a1) # 8001ffe0 <sb+0x18>
    80003c1a:	9dbd                	addw	a1,a1,a5
    80003c1c:	4108                	lw	a0,0(a0)
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	8a8080e7          	jalr	-1880(ra) # 800034c6 <bread>
    80003c26:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c28:	05850793          	addi	a5,a0,88
    80003c2c:	40c8                	lw	a0,4(s1)
    80003c2e:	893d                	andi	a0,a0,15
    80003c30:	051a                	slli	a0,a0,0x6
    80003c32:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003c34:	04449703          	lh	a4,68(s1)
    80003c38:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003c3c:	04649703          	lh	a4,70(s1)
    80003c40:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003c44:	04849703          	lh	a4,72(s1)
    80003c48:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003c4c:	04a49703          	lh	a4,74(s1)
    80003c50:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003c54:	44f8                	lw	a4,76(s1)
    80003c56:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c58:	03400613          	li	a2,52
    80003c5c:	05048593          	addi	a1,s1,80
    80003c60:	0531                	addi	a0,a0,12
    80003c62:	ffffd097          	auipc	ra,0xffffd
    80003c66:	0e0080e7          	jalr	224(ra) # 80000d42 <memmove>
  log_write(bp);
    80003c6a:	854a                	mv	a0,s2
    80003c6c:	00001097          	auipc	ra,0x1
    80003c70:	c06080e7          	jalr	-1018(ra) # 80004872 <log_write>
  brelse(bp);
    80003c74:	854a                	mv	a0,s2
    80003c76:	00000097          	auipc	ra,0x0
    80003c7a:	980080e7          	jalr	-1664(ra) # 800035f6 <brelse>
}
    80003c7e:	60e2                	ld	ra,24(sp)
    80003c80:	6442                	ld	s0,16(sp)
    80003c82:	64a2                	ld	s1,8(sp)
    80003c84:	6902                	ld	s2,0(sp)
    80003c86:	6105                	addi	sp,sp,32
    80003c88:	8082                	ret

0000000080003c8a <idup>:
{
    80003c8a:	1101                	addi	sp,sp,-32
    80003c8c:	ec06                	sd	ra,24(sp)
    80003c8e:	e822                	sd	s0,16(sp)
    80003c90:	e426                	sd	s1,8(sp)
    80003c92:	1000                	addi	s0,sp,32
    80003c94:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c96:	0001c517          	auipc	a0,0x1c
    80003c9a:	35250513          	addi	a0,a0,850 # 8001ffe8 <itable>
    80003c9e:	ffffd097          	auipc	ra,0xffffd
    80003ca2:	f48080e7          	jalr	-184(ra) # 80000be6 <acquire>
  ip->ref++;
    80003ca6:	449c                	lw	a5,8(s1)
    80003ca8:	2785                	addiw	a5,a5,1
    80003caa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cac:	0001c517          	auipc	a0,0x1c
    80003cb0:	33c50513          	addi	a0,a0,828 # 8001ffe8 <itable>
    80003cb4:	ffffd097          	auipc	ra,0xffffd
    80003cb8:	fe6080e7          	jalr	-26(ra) # 80000c9a <release>
}
    80003cbc:	8526                	mv	a0,s1
    80003cbe:	60e2                	ld	ra,24(sp)
    80003cc0:	6442                	ld	s0,16(sp)
    80003cc2:	64a2                	ld	s1,8(sp)
    80003cc4:	6105                	addi	sp,sp,32
    80003cc6:	8082                	ret

0000000080003cc8 <ilock>:
{
    80003cc8:	1101                	addi	sp,sp,-32
    80003cca:	ec06                	sd	ra,24(sp)
    80003ccc:	e822                	sd	s0,16(sp)
    80003cce:	e426                	sd	s1,8(sp)
    80003cd0:	e04a                	sd	s2,0(sp)
    80003cd2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003cd4:	c115                	beqz	a0,80003cf8 <ilock+0x30>
    80003cd6:	84aa                	mv	s1,a0
    80003cd8:	451c                	lw	a5,8(a0)
    80003cda:	00f05f63          	blez	a5,80003cf8 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003cde:	0541                	addi	a0,a0,16
    80003ce0:	00001097          	auipc	ra,0x1
    80003ce4:	cb2080e7          	jalr	-846(ra) # 80004992 <acquiresleep>
  if(ip->valid == 0){
    80003ce8:	40bc                	lw	a5,64(s1)
    80003cea:	cf99                	beqz	a5,80003d08 <ilock+0x40>
}
    80003cec:	60e2                	ld	ra,24(sp)
    80003cee:	6442                	ld	s0,16(sp)
    80003cf0:	64a2                	ld	s1,8(sp)
    80003cf2:	6902                	ld	s2,0(sp)
    80003cf4:	6105                	addi	sp,sp,32
    80003cf6:	8082                	ret
    panic("ilock");
    80003cf8:	00005517          	auipc	a0,0x5
    80003cfc:	a2050513          	addi	a0,a0,-1504 # 80008718 <syscalls+0x198>
    80003d00:	ffffd097          	auipc	ra,0xffffd
    80003d04:	840080e7          	jalr	-1984(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d08:	40dc                	lw	a5,4(s1)
    80003d0a:	0047d79b          	srliw	a5,a5,0x4
    80003d0e:	0001c597          	auipc	a1,0x1c
    80003d12:	2d25a583          	lw	a1,722(a1) # 8001ffe0 <sb+0x18>
    80003d16:	9dbd                	addw	a1,a1,a5
    80003d18:	4088                	lw	a0,0(s1)
    80003d1a:	fffff097          	auipc	ra,0xfffff
    80003d1e:	7ac080e7          	jalr	1964(ra) # 800034c6 <bread>
    80003d22:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d24:	05850593          	addi	a1,a0,88
    80003d28:	40dc                	lw	a5,4(s1)
    80003d2a:	8bbd                	andi	a5,a5,15
    80003d2c:	079a                	slli	a5,a5,0x6
    80003d2e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d30:	00059783          	lh	a5,0(a1)
    80003d34:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d38:	00259783          	lh	a5,2(a1)
    80003d3c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d40:	00459783          	lh	a5,4(a1)
    80003d44:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d48:	00659783          	lh	a5,6(a1)
    80003d4c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d50:	459c                	lw	a5,8(a1)
    80003d52:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d54:	03400613          	li	a2,52
    80003d58:	05b1                	addi	a1,a1,12
    80003d5a:	05048513          	addi	a0,s1,80
    80003d5e:	ffffd097          	auipc	ra,0xffffd
    80003d62:	fe4080e7          	jalr	-28(ra) # 80000d42 <memmove>
    brelse(bp);
    80003d66:	854a                	mv	a0,s2
    80003d68:	00000097          	auipc	ra,0x0
    80003d6c:	88e080e7          	jalr	-1906(ra) # 800035f6 <brelse>
    ip->valid = 1;
    80003d70:	4785                	li	a5,1
    80003d72:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d74:	04449783          	lh	a5,68(s1)
    80003d78:	fbb5                	bnez	a5,80003cec <ilock+0x24>
      panic("ilock: no type");
    80003d7a:	00005517          	auipc	a0,0x5
    80003d7e:	9a650513          	addi	a0,a0,-1626 # 80008720 <syscalls+0x1a0>
    80003d82:	ffffc097          	auipc	ra,0xffffc
    80003d86:	7be080e7          	jalr	1982(ra) # 80000540 <panic>

0000000080003d8a <iunlock>:
{
    80003d8a:	1101                	addi	sp,sp,-32
    80003d8c:	ec06                	sd	ra,24(sp)
    80003d8e:	e822                	sd	s0,16(sp)
    80003d90:	e426                	sd	s1,8(sp)
    80003d92:	e04a                	sd	s2,0(sp)
    80003d94:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d96:	c905                	beqz	a0,80003dc6 <iunlock+0x3c>
    80003d98:	84aa                	mv	s1,a0
    80003d9a:	01050913          	addi	s2,a0,16
    80003d9e:	854a                	mv	a0,s2
    80003da0:	00001097          	auipc	ra,0x1
    80003da4:	c8c080e7          	jalr	-884(ra) # 80004a2c <holdingsleep>
    80003da8:	cd19                	beqz	a0,80003dc6 <iunlock+0x3c>
    80003daa:	449c                	lw	a5,8(s1)
    80003dac:	00f05d63          	blez	a5,80003dc6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003db0:	854a                	mv	a0,s2
    80003db2:	00001097          	auipc	ra,0x1
    80003db6:	c36080e7          	jalr	-970(ra) # 800049e8 <releasesleep>
}
    80003dba:	60e2                	ld	ra,24(sp)
    80003dbc:	6442                	ld	s0,16(sp)
    80003dbe:	64a2                	ld	s1,8(sp)
    80003dc0:	6902                	ld	s2,0(sp)
    80003dc2:	6105                	addi	sp,sp,32
    80003dc4:	8082                	ret
    panic("iunlock");
    80003dc6:	00005517          	auipc	a0,0x5
    80003dca:	96a50513          	addi	a0,a0,-1686 # 80008730 <syscalls+0x1b0>
    80003dce:	ffffc097          	auipc	ra,0xffffc
    80003dd2:	772080e7          	jalr	1906(ra) # 80000540 <panic>

0000000080003dd6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003dd6:	7179                	addi	sp,sp,-48
    80003dd8:	f406                	sd	ra,40(sp)
    80003dda:	f022                	sd	s0,32(sp)
    80003ddc:	ec26                	sd	s1,24(sp)
    80003dde:	e84a                	sd	s2,16(sp)
    80003de0:	e44e                	sd	s3,8(sp)
    80003de2:	e052                	sd	s4,0(sp)
    80003de4:	1800                	addi	s0,sp,48
    80003de6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003de8:	05050493          	addi	s1,a0,80
    80003dec:	08050913          	addi	s2,a0,128
    80003df0:	a021                	j	80003df8 <itrunc+0x22>
    80003df2:	0491                	addi	s1,s1,4
    80003df4:	01248d63          	beq	s1,s2,80003e0e <itrunc+0x38>
    if(ip->addrs[i]){
    80003df8:	408c                	lw	a1,0(s1)
    80003dfa:	dde5                	beqz	a1,80003df2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003dfc:	0009a503          	lw	a0,0(s3)
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	90c080e7          	jalr	-1780(ra) # 8000370c <bfree>
      ip->addrs[i] = 0;
    80003e08:	0004a023          	sw	zero,0(s1)
    80003e0c:	b7dd                	j	80003df2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e0e:	0809a583          	lw	a1,128(s3)
    80003e12:	e185                	bnez	a1,80003e32 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e14:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e18:	854e                	mv	a0,s3
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	de4080e7          	jalr	-540(ra) # 80003bfe <iupdate>
}
    80003e22:	70a2                	ld	ra,40(sp)
    80003e24:	7402                	ld	s0,32(sp)
    80003e26:	64e2                	ld	s1,24(sp)
    80003e28:	6942                	ld	s2,16(sp)
    80003e2a:	69a2                	ld	s3,8(sp)
    80003e2c:	6a02                	ld	s4,0(sp)
    80003e2e:	6145                	addi	sp,sp,48
    80003e30:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e32:	0009a503          	lw	a0,0(s3)
    80003e36:	fffff097          	auipc	ra,0xfffff
    80003e3a:	690080e7          	jalr	1680(ra) # 800034c6 <bread>
    80003e3e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e40:	05850493          	addi	s1,a0,88
    80003e44:	45850913          	addi	s2,a0,1112
    80003e48:	a811                	j	80003e5c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003e4a:	0009a503          	lw	a0,0(s3)
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	8be080e7          	jalr	-1858(ra) # 8000370c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003e56:	0491                	addi	s1,s1,4
    80003e58:	01248563          	beq	s1,s2,80003e62 <itrunc+0x8c>
      if(a[j])
    80003e5c:	408c                	lw	a1,0(s1)
    80003e5e:	dde5                	beqz	a1,80003e56 <itrunc+0x80>
    80003e60:	b7ed                	j	80003e4a <itrunc+0x74>
    brelse(bp);
    80003e62:	8552                	mv	a0,s4
    80003e64:	fffff097          	auipc	ra,0xfffff
    80003e68:	792080e7          	jalr	1938(ra) # 800035f6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e6c:	0809a583          	lw	a1,128(s3)
    80003e70:	0009a503          	lw	a0,0(s3)
    80003e74:	00000097          	auipc	ra,0x0
    80003e78:	898080e7          	jalr	-1896(ra) # 8000370c <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e7c:	0809a023          	sw	zero,128(s3)
    80003e80:	bf51                	j	80003e14 <itrunc+0x3e>

0000000080003e82 <iput>:
{
    80003e82:	1101                	addi	sp,sp,-32
    80003e84:	ec06                	sd	ra,24(sp)
    80003e86:	e822                	sd	s0,16(sp)
    80003e88:	e426                	sd	s1,8(sp)
    80003e8a:	e04a                	sd	s2,0(sp)
    80003e8c:	1000                	addi	s0,sp,32
    80003e8e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e90:	0001c517          	auipc	a0,0x1c
    80003e94:	15850513          	addi	a0,a0,344 # 8001ffe8 <itable>
    80003e98:	ffffd097          	auipc	ra,0xffffd
    80003e9c:	d4e080e7          	jalr	-690(ra) # 80000be6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ea0:	4498                	lw	a4,8(s1)
    80003ea2:	4785                	li	a5,1
    80003ea4:	02f70363          	beq	a4,a5,80003eca <iput+0x48>
  ip->ref--;
    80003ea8:	449c                	lw	a5,8(s1)
    80003eaa:	37fd                	addiw	a5,a5,-1
    80003eac:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003eae:	0001c517          	auipc	a0,0x1c
    80003eb2:	13a50513          	addi	a0,a0,314 # 8001ffe8 <itable>
    80003eb6:	ffffd097          	auipc	ra,0xffffd
    80003eba:	de4080e7          	jalr	-540(ra) # 80000c9a <release>
}
    80003ebe:	60e2                	ld	ra,24(sp)
    80003ec0:	6442                	ld	s0,16(sp)
    80003ec2:	64a2                	ld	s1,8(sp)
    80003ec4:	6902                	ld	s2,0(sp)
    80003ec6:	6105                	addi	sp,sp,32
    80003ec8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003eca:	40bc                	lw	a5,64(s1)
    80003ecc:	dff1                	beqz	a5,80003ea8 <iput+0x26>
    80003ece:	04a49783          	lh	a5,74(s1)
    80003ed2:	fbf9                	bnez	a5,80003ea8 <iput+0x26>
    acquiresleep(&ip->lock);
    80003ed4:	01048913          	addi	s2,s1,16
    80003ed8:	854a                	mv	a0,s2
    80003eda:	00001097          	auipc	ra,0x1
    80003ede:	ab8080e7          	jalr	-1352(ra) # 80004992 <acquiresleep>
    release(&itable.lock);
    80003ee2:	0001c517          	auipc	a0,0x1c
    80003ee6:	10650513          	addi	a0,a0,262 # 8001ffe8 <itable>
    80003eea:	ffffd097          	auipc	ra,0xffffd
    80003eee:	db0080e7          	jalr	-592(ra) # 80000c9a <release>
    itrunc(ip);
    80003ef2:	8526                	mv	a0,s1
    80003ef4:	00000097          	auipc	ra,0x0
    80003ef8:	ee2080e7          	jalr	-286(ra) # 80003dd6 <itrunc>
    ip->type = 0;
    80003efc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f00:	8526                	mv	a0,s1
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	cfc080e7          	jalr	-772(ra) # 80003bfe <iupdate>
    ip->valid = 0;
    80003f0a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f0e:	854a                	mv	a0,s2
    80003f10:	00001097          	auipc	ra,0x1
    80003f14:	ad8080e7          	jalr	-1320(ra) # 800049e8 <releasesleep>
    acquire(&itable.lock);
    80003f18:	0001c517          	auipc	a0,0x1c
    80003f1c:	0d050513          	addi	a0,a0,208 # 8001ffe8 <itable>
    80003f20:	ffffd097          	auipc	ra,0xffffd
    80003f24:	cc6080e7          	jalr	-826(ra) # 80000be6 <acquire>
    80003f28:	b741                	j	80003ea8 <iput+0x26>

0000000080003f2a <iunlockput>:
{
    80003f2a:	1101                	addi	sp,sp,-32
    80003f2c:	ec06                	sd	ra,24(sp)
    80003f2e:	e822                	sd	s0,16(sp)
    80003f30:	e426                	sd	s1,8(sp)
    80003f32:	1000                	addi	s0,sp,32
    80003f34:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	e54080e7          	jalr	-428(ra) # 80003d8a <iunlock>
  iput(ip);
    80003f3e:	8526                	mv	a0,s1
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	f42080e7          	jalr	-190(ra) # 80003e82 <iput>
}
    80003f48:	60e2                	ld	ra,24(sp)
    80003f4a:	6442                	ld	s0,16(sp)
    80003f4c:	64a2                	ld	s1,8(sp)
    80003f4e:	6105                	addi	sp,sp,32
    80003f50:	8082                	ret

0000000080003f52 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f52:	1141                	addi	sp,sp,-16
    80003f54:	e422                	sd	s0,8(sp)
    80003f56:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f58:	411c                	lw	a5,0(a0)
    80003f5a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f5c:	415c                	lw	a5,4(a0)
    80003f5e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f60:	04451783          	lh	a5,68(a0)
    80003f64:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f68:	04a51783          	lh	a5,74(a0)
    80003f6c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f70:	04c56783          	lwu	a5,76(a0)
    80003f74:	e99c                	sd	a5,16(a1)
}
    80003f76:	6422                	ld	s0,8(sp)
    80003f78:	0141                	addi	sp,sp,16
    80003f7a:	8082                	ret

0000000080003f7c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f7c:	457c                	lw	a5,76(a0)
    80003f7e:	0ed7e963          	bltu	a5,a3,80004070 <readi+0xf4>
{
    80003f82:	7159                	addi	sp,sp,-112
    80003f84:	f486                	sd	ra,104(sp)
    80003f86:	f0a2                	sd	s0,96(sp)
    80003f88:	eca6                	sd	s1,88(sp)
    80003f8a:	e8ca                	sd	s2,80(sp)
    80003f8c:	e4ce                	sd	s3,72(sp)
    80003f8e:	e0d2                	sd	s4,64(sp)
    80003f90:	fc56                	sd	s5,56(sp)
    80003f92:	f85a                	sd	s6,48(sp)
    80003f94:	f45e                	sd	s7,40(sp)
    80003f96:	f062                	sd	s8,32(sp)
    80003f98:	ec66                	sd	s9,24(sp)
    80003f9a:	e86a                	sd	s10,16(sp)
    80003f9c:	e46e                	sd	s11,8(sp)
    80003f9e:	1880                	addi	s0,sp,112
    80003fa0:	8baa                	mv	s7,a0
    80003fa2:	8c2e                	mv	s8,a1
    80003fa4:	8ab2                	mv	s5,a2
    80003fa6:	84b6                	mv	s1,a3
    80003fa8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003faa:	9f35                	addw	a4,a4,a3
    return 0;
    80003fac:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003fae:	0ad76063          	bltu	a4,a3,8000404e <readi+0xd2>
  if(off + n > ip->size)
    80003fb2:	00e7f463          	bgeu	a5,a4,80003fba <readi+0x3e>
    n = ip->size - off;
    80003fb6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fba:	0a0b0963          	beqz	s6,8000406c <readi+0xf0>
    80003fbe:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fc0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003fc4:	5cfd                	li	s9,-1
    80003fc6:	a82d                	j	80004000 <readi+0x84>
    80003fc8:	020a1d93          	slli	s11,s4,0x20
    80003fcc:	020ddd93          	srli	s11,s11,0x20
    80003fd0:	05890613          	addi	a2,s2,88
    80003fd4:	86ee                	mv	a3,s11
    80003fd6:	963a                	add	a2,a2,a4
    80003fd8:	85d6                	mv	a1,s5
    80003fda:	8562                	mv	a0,s8
    80003fdc:	fffff097          	auipc	ra,0xfffff
    80003fe0:	87a080e7          	jalr	-1926(ra) # 80002856 <either_copyout>
    80003fe4:	05950d63          	beq	a0,s9,8000403e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003fe8:	854a                	mv	a0,s2
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	60c080e7          	jalr	1548(ra) # 800035f6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ff2:	013a09bb          	addw	s3,s4,s3
    80003ff6:	009a04bb          	addw	s1,s4,s1
    80003ffa:	9aee                	add	s5,s5,s11
    80003ffc:	0569f763          	bgeu	s3,s6,8000404a <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004000:	000ba903          	lw	s2,0(s7)
    80004004:	00a4d59b          	srliw	a1,s1,0xa
    80004008:	855e                	mv	a0,s7
    8000400a:	00000097          	auipc	ra,0x0
    8000400e:	8b0080e7          	jalr	-1872(ra) # 800038ba <bmap>
    80004012:	0005059b          	sext.w	a1,a0
    80004016:	854a                	mv	a0,s2
    80004018:	fffff097          	auipc	ra,0xfffff
    8000401c:	4ae080e7          	jalr	1198(ra) # 800034c6 <bread>
    80004020:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004022:	3ff4f713          	andi	a4,s1,1023
    80004026:	40ed07bb          	subw	a5,s10,a4
    8000402a:	413b06bb          	subw	a3,s6,s3
    8000402e:	8a3e                	mv	s4,a5
    80004030:	2781                	sext.w	a5,a5
    80004032:	0006861b          	sext.w	a2,a3
    80004036:	f8f679e3          	bgeu	a2,a5,80003fc8 <readi+0x4c>
    8000403a:	8a36                	mv	s4,a3
    8000403c:	b771                	j	80003fc8 <readi+0x4c>
      brelse(bp);
    8000403e:	854a                	mv	a0,s2
    80004040:	fffff097          	auipc	ra,0xfffff
    80004044:	5b6080e7          	jalr	1462(ra) # 800035f6 <brelse>
      tot = -1;
    80004048:	59fd                	li	s3,-1
  }
  return tot;
    8000404a:	0009851b          	sext.w	a0,s3
}
    8000404e:	70a6                	ld	ra,104(sp)
    80004050:	7406                	ld	s0,96(sp)
    80004052:	64e6                	ld	s1,88(sp)
    80004054:	6946                	ld	s2,80(sp)
    80004056:	69a6                	ld	s3,72(sp)
    80004058:	6a06                	ld	s4,64(sp)
    8000405a:	7ae2                	ld	s5,56(sp)
    8000405c:	7b42                	ld	s6,48(sp)
    8000405e:	7ba2                	ld	s7,40(sp)
    80004060:	7c02                	ld	s8,32(sp)
    80004062:	6ce2                	ld	s9,24(sp)
    80004064:	6d42                	ld	s10,16(sp)
    80004066:	6da2                	ld	s11,8(sp)
    80004068:	6165                	addi	sp,sp,112
    8000406a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000406c:	89da                	mv	s3,s6
    8000406e:	bff1                	j	8000404a <readi+0xce>
    return 0;
    80004070:	4501                	li	a0,0
}
    80004072:	8082                	ret

0000000080004074 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004074:	457c                	lw	a5,76(a0)
    80004076:	10d7e863          	bltu	a5,a3,80004186 <writei+0x112>
{
    8000407a:	7159                	addi	sp,sp,-112
    8000407c:	f486                	sd	ra,104(sp)
    8000407e:	f0a2                	sd	s0,96(sp)
    80004080:	eca6                	sd	s1,88(sp)
    80004082:	e8ca                	sd	s2,80(sp)
    80004084:	e4ce                	sd	s3,72(sp)
    80004086:	e0d2                	sd	s4,64(sp)
    80004088:	fc56                	sd	s5,56(sp)
    8000408a:	f85a                	sd	s6,48(sp)
    8000408c:	f45e                	sd	s7,40(sp)
    8000408e:	f062                	sd	s8,32(sp)
    80004090:	ec66                	sd	s9,24(sp)
    80004092:	e86a                	sd	s10,16(sp)
    80004094:	e46e                	sd	s11,8(sp)
    80004096:	1880                	addi	s0,sp,112
    80004098:	8b2a                	mv	s6,a0
    8000409a:	8c2e                	mv	s8,a1
    8000409c:	8ab2                	mv	s5,a2
    8000409e:	8936                	mv	s2,a3
    800040a0:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    800040a2:	00e687bb          	addw	a5,a3,a4
    800040a6:	0ed7e263          	bltu	a5,a3,8000418a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040aa:	00043737          	lui	a4,0x43
    800040ae:	0ef76063          	bltu	a4,a5,8000418e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040b2:	0c0b8863          	beqz	s7,80004182 <writei+0x10e>
    800040b6:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800040b8:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800040bc:	5cfd                	li	s9,-1
    800040be:	a091                	j	80004102 <writei+0x8e>
    800040c0:	02099d93          	slli	s11,s3,0x20
    800040c4:	020ddd93          	srli	s11,s11,0x20
    800040c8:	05848513          	addi	a0,s1,88
    800040cc:	86ee                	mv	a3,s11
    800040ce:	8656                	mv	a2,s5
    800040d0:	85e2                	mv	a1,s8
    800040d2:	953a                	add	a0,a0,a4
    800040d4:	ffffe097          	auipc	ra,0xffffe
    800040d8:	7d8080e7          	jalr	2008(ra) # 800028ac <either_copyin>
    800040dc:	07950263          	beq	a0,s9,80004140 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800040e0:	8526                	mv	a0,s1
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	790080e7          	jalr	1936(ra) # 80004872 <log_write>
    brelse(bp);
    800040ea:	8526                	mv	a0,s1
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	50a080e7          	jalr	1290(ra) # 800035f6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040f4:	01498a3b          	addw	s4,s3,s4
    800040f8:	0129893b          	addw	s2,s3,s2
    800040fc:	9aee                	add	s5,s5,s11
    800040fe:	057a7663          	bgeu	s4,s7,8000414a <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80004102:	000b2483          	lw	s1,0(s6)
    80004106:	00a9559b          	srliw	a1,s2,0xa
    8000410a:	855a                	mv	a0,s6
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	7ae080e7          	jalr	1966(ra) # 800038ba <bmap>
    80004114:	0005059b          	sext.w	a1,a0
    80004118:	8526                	mv	a0,s1
    8000411a:	fffff097          	auipc	ra,0xfffff
    8000411e:	3ac080e7          	jalr	940(ra) # 800034c6 <bread>
    80004122:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004124:	3ff97713          	andi	a4,s2,1023
    80004128:	40ed07bb          	subw	a5,s10,a4
    8000412c:	414b86bb          	subw	a3,s7,s4
    80004130:	89be                	mv	s3,a5
    80004132:	2781                	sext.w	a5,a5
    80004134:	0006861b          	sext.w	a2,a3
    80004138:	f8f674e3          	bgeu	a2,a5,800040c0 <writei+0x4c>
    8000413c:	89b6                	mv	s3,a3
    8000413e:	b749                	j	800040c0 <writei+0x4c>
      brelse(bp);
    80004140:	8526                	mv	a0,s1
    80004142:	fffff097          	auipc	ra,0xfffff
    80004146:	4b4080e7          	jalr	1204(ra) # 800035f6 <brelse>
  }

  if(off > ip->size)
    8000414a:	04cb2783          	lw	a5,76(s6)
    8000414e:	0127f463          	bgeu	a5,s2,80004156 <writei+0xe2>
    ip->size = off;
    80004152:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004156:	855a                	mv	a0,s6
    80004158:	00000097          	auipc	ra,0x0
    8000415c:	aa6080e7          	jalr	-1370(ra) # 80003bfe <iupdate>

  return tot;
    80004160:	000a051b          	sext.w	a0,s4
}
    80004164:	70a6                	ld	ra,104(sp)
    80004166:	7406                	ld	s0,96(sp)
    80004168:	64e6                	ld	s1,88(sp)
    8000416a:	6946                	ld	s2,80(sp)
    8000416c:	69a6                	ld	s3,72(sp)
    8000416e:	6a06                	ld	s4,64(sp)
    80004170:	7ae2                	ld	s5,56(sp)
    80004172:	7b42                	ld	s6,48(sp)
    80004174:	7ba2                	ld	s7,40(sp)
    80004176:	7c02                	ld	s8,32(sp)
    80004178:	6ce2                	ld	s9,24(sp)
    8000417a:	6d42                	ld	s10,16(sp)
    8000417c:	6da2                	ld	s11,8(sp)
    8000417e:	6165                	addi	sp,sp,112
    80004180:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004182:	8a5e                	mv	s4,s7
    80004184:	bfc9                	j	80004156 <writei+0xe2>
    return -1;
    80004186:	557d                	li	a0,-1
}
    80004188:	8082                	ret
    return -1;
    8000418a:	557d                	li	a0,-1
    8000418c:	bfe1                	j	80004164 <writei+0xf0>
    return -1;
    8000418e:	557d                	li	a0,-1
    80004190:	bfd1                	j	80004164 <writei+0xf0>

0000000080004192 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004192:	1141                	addi	sp,sp,-16
    80004194:	e406                	sd	ra,8(sp)
    80004196:	e022                	sd	s0,0(sp)
    80004198:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000419a:	4639                	li	a2,14
    8000419c:	ffffd097          	auipc	ra,0xffffd
    800041a0:	c1e080e7          	jalr	-994(ra) # 80000dba <strncmp>
}
    800041a4:	60a2                	ld	ra,8(sp)
    800041a6:	6402                	ld	s0,0(sp)
    800041a8:	0141                	addi	sp,sp,16
    800041aa:	8082                	ret

00000000800041ac <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041ac:	7139                	addi	sp,sp,-64
    800041ae:	fc06                	sd	ra,56(sp)
    800041b0:	f822                	sd	s0,48(sp)
    800041b2:	f426                	sd	s1,40(sp)
    800041b4:	f04a                	sd	s2,32(sp)
    800041b6:	ec4e                	sd	s3,24(sp)
    800041b8:	e852                	sd	s4,16(sp)
    800041ba:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800041bc:	04451703          	lh	a4,68(a0)
    800041c0:	4785                	li	a5,1
    800041c2:	00f71a63          	bne	a4,a5,800041d6 <dirlookup+0x2a>
    800041c6:	892a                	mv	s2,a0
    800041c8:	89ae                	mv	s3,a1
    800041ca:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800041cc:	457c                	lw	a5,76(a0)
    800041ce:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041d0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041d2:	e79d                	bnez	a5,80004200 <dirlookup+0x54>
    800041d4:	a8a5                	j	8000424c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041d6:	00004517          	auipc	a0,0x4
    800041da:	56250513          	addi	a0,a0,1378 # 80008738 <syscalls+0x1b8>
    800041de:	ffffc097          	auipc	ra,0xffffc
    800041e2:	362080e7          	jalr	866(ra) # 80000540 <panic>
      panic("dirlookup read");
    800041e6:	00004517          	auipc	a0,0x4
    800041ea:	56a50513          	addi	a0,a0,1386 # 80008750 <syscalls+0x1d0>
    800041ee:	ffffc097          	auipc	ra,0xffffc
    800041f2:	352080e7          	jalr	850(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041f6:	24c1                	addiw	s1,s1,16
    800041f8:	04c92783          	lw	a5,76(s2)
    800041fc:	04f4f763          	bgeu	s1,a5,8000424a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004200:	4741                	li	a4,16
    80004202:	86a6                	mv	a3,s1
    80004204:	fc040613          	addi	a2,s0,-64
    80004208:	4581                	li	a1,0
    8000420a:	854a                	mv	a0,s2
    8000420c:	00000097          	auipc	ra,0x0
    80004210:	d70080e7          	jalr	-656(ra) # 80003f7c <readi>
    80004214:	47c1                	li	a5,16
    80004216:	fcf518e3          	bne	a0,a5,800041e6 <dirlookup+0x3a>
    if(de.inum == 0)
    8000421a:	fc045783          	lhu	a5,-64(s0)
    8000421e:	dfe1                	beqz	a5,800041f6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004220:	fc240593          	addi	a1,s0,-62
    80004224:	854e                	mv	a0,s3
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	f6c080e7          	jalr	-148(ra) # 80004192 <namecmp>
    8000422e:	f561                	bnez	a0,800041f6 <dirlookup+0x4a>
      if(poff)
    80004230:	000a0463          	beqz	s4,80004238 <dirlookup+0x8c>
        *poff = off;
    80004234:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004238:	fc045583          	lhu	a1,-64(s0)
    8000423c:	00092503          	lw	a0,0(s2)
    80004240:	fffff097          	auipc	ra,0xfffff
    80004244:	754080e7          	jalr	1876(ra) # 80003994 <iget>
    80004248:	a011                	j	8000424c <dirlookup+0xa0>
  return 0;
    8000424a:	4501                	li	a0,0
}
    8000424c:	70e2                	ld	ra,56(sp)
    8000424e:	7442                	ld	s0,48(sp)
    80004250:	74a2                	ld	s1,40(sp)
    80004252:	7902                	ld	s2,32(sp)
    80004254:	69e2                	ld	s3,24(sp)
    80004256:	6a42                	ld	s4,16(sp)
    80004258:	6121                	addi	sp,sp,64
    8000425a:	8082                	ret

000000008000425c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000425c:	711d                	addi	sp,sp,-96
    8000425e:	ec86                	sd	ra,88(sp)
    80004260:	e8a2                	sd	s0,80(sp)
    80004262:	e4a6                	sd	s1,72(sp)
    80004264:	e0ca                	sd	s2,64(sp)
    80004266:	fc4e                	sd	s3,56(sp)
    80004268:	f852                	sd	s4,48(sp)
    8000426a:	f456                	sd	s5,40(sp)
    8000426c:	f05a                	sd	s6,32(sp)
    8000426e:	ec5e                	sd	s7,24(sp)
    80004270:	e862                	sd	s8,16(sp)
    80004272:	e466                	sd	s9,8(sp)
    80004274:	1080                	addi	s0,sp,96
    80004276:	84aa                	mv	s1,a0
    80004278:	8b2e                	mv	s6,a1
    8000427a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000427c:	00054703          	lbu	a4,0(a0)
    80004280:	02f00793          	li	a5,47
    80004284:	02f70363          	beq	a4,a5,800042aa <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004288:	ffffd097          	auipc	ra,0xffffd
    8000428c:	76a080e7          	jalr	1898(ra) # 800019f2 <myproc>
    80004290:	15053503          	ld	a0,336(a0)
    80004294:	00000097          	auipc	ra,0x0
    80004298:	9f6080e7          	jalr	-1546(ra) # 80003c8a <idup>
    8000429c:	89aa                	mv	s3,a0
  while(*path == '/')
    8000429e:	02f00913          	li	s2,47
  len = path - s;
    800042a2:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    800042a4:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042a6:	4c05                	li	s8,1
    800042a8:	a865                	j	80004360 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800042aa:	4585                	li	a1,1
    800042ac:	4505                	li	a0,1
    800042ae:	fffff097          	auipc	ra,0xfffff
    800042b2:	6e6080e7          	jalr	1766(ra) # 80003994 <iget>
    800042b6:	89aa                	mv	s3,a0
    800042b8:	b7dd                	j	8000429e <namex+0x42>
      iunlockput(ip);
    800042ba:	854e                	mv	a0,s3
    800042bc:	00000097          	auipc	ra,0x0
    800042c0:	c6e080e7          	jalr	-914(ra) # 80003f2a <iunlockput>
      return 0;
    800042c4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800042c6:	854e                	mv	a0,s3
    800042c8:	60e6                	ld	ra,88(sp)
    800042ca:	6446                	ld	s0,80(sp)
    800042cc:	64a6                	ld	s1,72(sp)
    800042ce:	6906                	ld	s2,64(sp)
    800042d0:	79e2                	ld	s3,56(sp)
    800042d2:	7a42                	ld	s4,48(sp)
    800042d4:	7aa2                	ld	s5,40(sp)
    800042d6:	7b02                	ld	s6,32(sp)
    800042d8:	6be2                	ld	s7,24(sp)
    800042da:	6c42                	ld	s8,16(sp)
    800042dc:	6ca2                	ld	s9,8(sp)
    800042de:	6125                	addi	sp,sp,96
    800042e0:	8082                	ret
      iunlock(ip);
    800042e2:	854e                	mv	a0,s3
    800042e4:	00000097          	auipc	ra,0x0
    800042e8:	aa6080e7          	jalr	-1370(ra) # 80003d8a <iunlock>
      return ip;
    800042ec:	bfe9                	j	800042c6 <namex+0x6a>
      iunlockput(ip);
    800042ee:	854e                	mv	a0,s3
    800042f0:	00000097          	auipc	ra,0x0
    800042f4:	c3a080e7          	jalr	-966(ra) # 80003f2a <iunlockput>
      return 0;
    800042f8:	89d2                	mv	s3,s4
    800042fa:	b7f1                	j	800042c6 <namex+0x6a>
  len = path - s;
    800042fc:	40b48633          	sub	a2,s1,a1
    80004300:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004304:	094cd463          	bge	s9,s4,8000438c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004308:	4639                	li	a2,14
    8000430a:	8556                	mv	a0,s5
    8000430c:	ffffd097          	auipc	ra,0xffffd
    80004310:	a36080e7          	jalr	-1482(ra) # 80000d42 <memmove>
  while(*path == '/')
    80004314:	0004c783          	lbu	a5,0(s1)
    80004318:	01279763          	bne	a5,s2,80004326 <namex+0xca>
    path++;
    8000431c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000431e:	0004c783          	lbu	a5,0(s1)
    80004322:	ff278de3          	beq	a5,s2,8000431c <namex+0xc0>
    ilock(ip);
    80004326:	854e                	mv	a0,s3
    80004328:	00000097          	auipc	ra,0x0
    8000432c:	9a0080e7          	jalr	-1632(ra) # 80003cc8 <ilock>
    if(ip->type != T_DIR){
    80004330:	04499783          	lh	a5,68(s3)
    80004334:	f98793e3          	bne	a5,s8,800042ba <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004338:	000b0563          	beqz	s6,80004342 <namex+0xe6>
    8000433c:	0004c783          	lbu	a5,0(s1)
    80004340:	d3cd                	beqz	a5,800042e2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004342:	865e                	mv	a2,s7
    80004344:	85d6                	mv	a1,s5
    80004346:	854e                	mv	a0,s3
    80004348:	00000097          	auipc	ra,0x0
    8000434c:	e64080e7          	jalr	-412(ra) # 800041ac <dirlookup>
    80004350:	8a2a                	mv	s4,a0
    80004352:	dd51                	beqz	a0,800042ee <namex+0x92>
    iunlockput(ip);
    80004354:	854e                	mv	a0,s3
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	bd4080e7          	jalr	-1068(ra) # 80003f2a <iunlockput>
    ip = next;
    8000435e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004360:	0004c783          	lbu	a5,0(s1)
    80004364:	05279763          	bne	a5,s2,800043b2 <namex+0x156>
    path++;
    80004368:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000436a:	0004c783          	lbu	a5,0(s1)
    8000436e:	ff278de3          	beq	a5,s2,80004368 <namex+0x10c>
  if(*path == 0)
    80004372:	c79d                	beqz	a5,800043a0 <namex+0x144>
    path++;
    80004374:	85a6                	mv	a1,s1
  len = path - s;
    80004376:	8a5e                	mv	s4,s7
    80004378:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000437a:	01278963          	beq	a5,s2,8000438c <namex+0x130>
    8000437e:	dfbd                	beqz	a5,800042fc <namex+0xa0>
    path++;
    80004380:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004382:	0004c783          	lbu	a5,0(s1)
    80004386:	ff279ce3          	bne	a5,s2,8000437e <namex+0x122>
    8000438a:	bf8d                	j	800042fc <namex+0xa0>
    memmove(name, s, len);
    8000438c:	2601                	sext.w	a2,a2
    8000438e:	8556                	mv	a0,s5
    80004390:	ffffd097          	auipc	ra,0xffffd
    80004394:	9b2080e7          	jalr	-1614(ra) # 80000d42 <memmove>
    name[len] = 0;
    80004398:	9a56                	add	s4,s4,s5
    8000439a:	000a0023          	sb	zero,0(s4)
    8000439e:	bf9d                	j	80004314 <namex+0xb8>
  if(nameiparent){
    800043a0:	f20b03e3          	beqz	s6,800042c6 <namex+0x6a>
    iput(ip);
    800043a4:	854e                	mv	a0,s3
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	adc080e7          	jalr	-1316(ra) # 80003e82 <iput>
    return 0;
    800043ae:	4981                	li	s3,0
    800043b0:	bf19                	j	800042c6 <namex+0x6a>
  if(*path == 0)
    800043b2:	d7fd                	beqz	a5,800043a0 <namex+0x144>
  while(*path != '/' && *path != 0)
    800043b4:	0004c783          	lbu	a5,0(s1)
    800043b8:	85a6                	mv	a1,s1
    800043ba:	b7d1                	j	8000437e <namex+0x122>

00000000800043bc <dirlink>:
{
    800043bc:	7139                	addi	sp,sp,-64
    800043be:	fc06                	sd	ra,56(sp)
    800043c0:	f822                	sd	s0,48(sp)
    800043c2:	f426                	sd	s1,40(sp)
    800043c4:	f04a                	sd	s2,32(sp)
    800043c6:	ec4e                	sd	s3,24(sp)
    800043c8:	e852                	sd	s4,16(sp)
    800043ca:	0080                	addi	s0,sp,64
    800043cc:	892a                	mv	s2,a0
    800043ce:	8a2e                	mv	s4,a1
    800043d0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043d2:	4601                	li	a2,0
    800043d4:	00000097          	auipc	ra,0x0
    800043d8:	dd8080e7          	jalr	-552(ra) # 800041ac <dirlookup>
    800043dc:	e93d                	bnez	a0,80004452 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043de:	04c92483          	lw	s1,76(s2)
    800043e2:	c49d                	beqz	s1,80004410 <dirlink+0x54>
    800043e4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043e6:	4741                	li	a4,16
    800043e8:	86a6                	mv	a3,s1
    800043ea:	fc040613          	addi	a2,s0,-64
    800043ee:	4581                	li	a1,0
    800043f0:	854a                	mv	a0,s2
    800043f2:	00000097          	auipc	ra,0x0
    800043f6:	b8a080e7          	jalr	-1142(ra) # 80003f7c <readi>
    800043fa:	47c1                	li	a5,16
    800043fc:	06f51163          	bne	a0,a5,8000445e <dirlink+0xa2>
    if(de.inum == 0)
    80004400:	fc045783          	lhu	a5,-64(s0)
    80004404:	c791                	beqz	a5,80004410 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004406:	24c1                	addiw	s1,s1,16
    80004408:	04c92783          	lw	a5,76(s2)
    8000440c:	fcf4ede3          	bltu	s1,a5,800043e6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004410:	4639                	li	a2,14
    80004412:	85d2                	mv	a1,s4
    80004414:	fc240513          	addi	a0,s0,-62
    80004418:	ffffd097          	auipc	ra,0xffffd
    8000441c:	9de080e7          	jalr	-1570(ra) # 80000df6 <strncpy>
  de.inum = inum;
    80004420:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004424:	4741                	li	a4,16
    80004426:	86a6                	mv	a3,s1
    80004428:	fc040613          	addi	a2,s0,-64
    8000442c:	4581                	li	a1,0
    8000442e:	854a                	mv	a0,s2
    80004430:	00000097          	auipc	ra,0x0
    80004434:	c44080e7          	jalr	-956(ra) # 80004074 <writei>
    80004438:	872a                	mv	a4,a0
    8000443a:	47c1                	li	a5,16
  return 0;
    8000443c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000443e:	02f71863          	bne	a4,a5,8000446e <dirlink+0xb2>
}
    80004442:	70e2                	ld	ra,56(sp)
    80004444:	7442                	ld	s0,48(sp)
    80004446:	74a2                	ld	s1,40(sp)
    80004448:	7902                	ld	s2,32(sp)
    8000444a:	69e2                	ld	s3,24(sp)
    8000444c:	6a42                	ld	s4,16(sp)
    8000444e:	6121                	addi	sp,sp,64
    80004450:	8082                	ret
    iput(ip);
    80004452:	00000097          	auipc	ra,0x0
    80004456:	a30080e7          	jalr	-1488(ra) # 80003e82 <iput>
    return -1;
    8000445a:	557d                	li	a0,-1
    8000445c:	b7dd                	j	80004442 <dirlink+0x86>
      panic("dirlink read");
    8000445e:	00004517          	auipc	a0,0x4
    80004462:	30250513          	addi	a0,a0,770 # 80008760 <syscalls+0x1e0>
    80004466:	ffffc097          	auipc	ra,0xffffc
    8000446a:	0da080e7          	jalr	218(ra) # 80000540 <panic>
    panic("dirlink");
    8000446e:	00004517          	auipc	a0,0x4
    80004472:	40250513          	addi	a0,a0,1026 # 80008870 <syscalls+0x2f0>
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	0ca080e7          	jalr	202(ra) # 80000540 <panic>

000000008000447e <namei>:

struct inode*
namei(char *path)
{
    8000447e:	1101                	addi	sp,sp,-32
    80004480:	ec06                	sd	ra,24(sp)
    80004482:	e822                	sd	s0,16(sp)
    80004484:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004486:	fe040613          	addi	a2,s0,-32
    8000448a:	4581                	li	a1,0
    8000448c:	00000097          	auipc	ra,0x0
    80004490:	dd0080e7          	jalr	-560(ra) # 8000425c <namex>
}
    80004494:	60e2                	ld	ra,24(sp)
    80004496:	6442                	ld	s0,16(sp)
    80004498:	6105                	addi	sp,sp,32
    8000449a:	8082                	ret

000000008000449c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000449c:	1141                	addi	sp,sp,-16
    8000449e:	e406                	sd	ra,8(sp)
    800044a0:	e022                	sd	s0,0(sp)
    800044a2:	0800                	addi	s0,sp,16
    800044a4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044a6:	4585                	li	a1,1
    800044a8:	00000097          	auipc	ra,0x0
    800044ac:	db4080e7          	jalr	-588(ra) # 8000425c <namex>
}
    800044b0:	60a2                	ld	ra,8(sp)
    800044b2:	6402                	ld	s0,0(sp)
    800044b4:	0141                	addi	sp,sp,16
    800044b6:	8082                	ret

00000000800044b8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044b8:	1101                	addi	sp,sp,-32
    800044ba:	ec06                	sd	ra,24(sp)
    800044bc:	e822                	sd	s0,16(sp)
    800044be:	e426                	sd	s1,8(sp)
    800044c0:	e04a                	sd	s2,0(sp)
    800044c2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800044c4:	0001d917          	auipc	s2,0x1d
    800044c8:	5cc90913          	addi	s2,s2,1484 # 80021a90 <log>
    800044cc:	01892583          	lw	a1,24(s2)
    800044d0:	02892503          	lw	a0,40(s2)
    800044d4:	fffff097          	auipc	ra,0xfffff
    800044d8:	ff2080e7          	jalr	-14(ra) # 800034c6 <bread>
    800044dc:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800044de:	02c92683          	lw	a3,44(s2)
    800044e2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044e4:	02d05763          	blez	a3,80004512 <write_head+0x5a>
    800044e8:	0001d797          	auipc	a5,0x1d
    800044ec:	5d878793          	addi	a5,a5,1496 # 80021ac0 <log+0x30>
    800044f0:	05c50713          	addi	a4,a0,92
    800044f4:	36fd                	addiw	a3,a3,-1
    800044f6:	1682                	slli	a3,a3,0x20
    800044f8:	9281                	srli	a3,a3,0x20
    800044fa:	068a                	slli	a3,a3,0x2
    800044fc:	0001d617          	auipc	a2,0x1d
    80004500:	5c860613          	addi	a2,a2,1480 # 80021ac4 <log+0x34>
    80004504:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004506:	4390                	lw	a2,0(a5)
    80004508:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000450a:	0791                	addi	a5,a5,4
    8000450c:	0711                	addi	a4,a4,4
    8000450e:	fed79ce3          	bne	a5,a3,80004506 <write_head+0x4e>
  }
  bwrite(buf);
    80004512:	8526                	mv	a0,s1
    80004514:	fffff097          	auipc	ra,0xfffff
    80004518:	0a4080e7          	jalr	164(ra) # 800035b8 <bwrite>
  brelse(buf);
    8000451c:	8526                	mv	a0,s1
    8000451e:	fffff097          	auipc	ra,0xfffff
    80004522:	0d8080e7          	jalr	216(ra) # 800035f6 <brelse>
}
    80004526:	60e2                	ld	ra,24(sp)
    80004528:	6442                	ld	s0,16(sp)
    8000452a:	64a2                	ld	s1,8(sp)
    8000452c:	6902                	ld	s2,0(sp)
    8000452e:	6105                	addi	sp,sp,32
    80004530:	8082                	ret

0000000080004532 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004532:	0001d797          	auipc	a5,0x1d
    80004536:	58a7a783          	lw	a5,1418(a5) # 80021abc <log+0x2c>
    8000453a:	0af05d63          	blez	a5,800045f4 <install_trans+0xc2>
{
    8000453e:	7139                	addi	sp,sp,-64
    80004540:	fc06                	sd	ra,56(sp)
    80004542:	f822                	sd	s0,48(sp)
    80004544:	f426                	sd	s1,40(sp)
    80004546:	f04a                	sd	s2,32(sp)
    80004548:	ec4e                	sd	s3,24(sp)
    8000454a:	e852                	sd	s4,16(sp)
    8000454c:	e456                	sd	s5,8(sp)
    8000454e:	e05a                	sd	s6,0(sp)
    80004550:	0080                	addi	s0,sp,64
    80004552:	8b2a                	mv	s6,a0
    80004554:	0001da97          	auipc	s5,0x1d
    80004558:	56ca8a93          	addi	s5,s5,1388 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000455c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000455e:	0001d997          	auipc	s3,0x1d
    80004562:	53298993          	addi	s3,s3,1330 # 80021a90 <log>
    80004566:	a035                	j	80004592 <install_trans+0x60>
      bunpin(dbuf);
    80004568:	8526                	mv	a0,s1
    8000456a:	fffff097          	auipc	ra,0xfffff
    8000456e:	166080e7          	jalr	358(ra) # 800036d0 <bunpin>
    brelse(lbuf);
    80004572:	854a                	mv	a0,s2
    80004574:	fffff097          	auipc	ra,0xfffff
    80004578:	082080e7          	jalr	130(ra) # 800035f6 <brelse>
    brelse(dbuf);
    8000457c:	8526                	mv	a0,s1
    8000457e:	fffff097          	auipc	ra,0xfffff
    80004582:	078080e7          	jalr	120(ra) # 800035f6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004586:	2a05                	addiw	s4,s4,1
    80004588:	0a91                	addi	s5,s5,4
    8000458a:	02c9a783          	lw	a5,44(s3)
    8000458e:	04fa5963          	bge	s4,a5,800045e0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004592:	0189a583          	lw	a1,24(s3)
    80004596:	014585bb          	addw	a1,a1,s4
    8000459a:	2585                	addiw	a1,a1,1
    8000459c:	0289a503          	lw	a0,40(s3)
    800045a0:	fffff097          	auipc	ra,0xfffff
    800045a4:	f26080e7          	jalr	-218(ra) # 800034c6 <bread>
    800045a8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045aa:	000aa583          	lw	a1,0(s5)
    800045ae:	0289a503          	lw	a0,40(s3)
    800045b2:	fffff097          	auipc	ra,0xfffff
    800045b6:	f14080e7          	jalr	-236(ra) # 800034c6 <bread>
    800045ba:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045bc:	40000613          	li	a2,1024
    800045c0:	05890593          	addi	a1,s2,88
    800045c4:	05850513          	addi	a0,a0,88
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	77a080e7          	jalr	1914(ra) # 80000d42 <memmove>
    bwrite(dbuf);  // write dst to disk
    800045d0:	8526                	mv	a0,s1
    800045d2:	fffff097          	auipc	ra,0xfffff
    800045d6:	fe6080e7          	jalr	-26(ra) # 800035b8 <bwrite>
    if(recovering == 0)
    800045da:	f80b1ce3          	bnez	s6,80004572 <install_trans+0x40>
    800045de:	b769                	j	80004568 <install_trans+0x36>
}
    800045e0:	70e2                	ld	ra,56(sp)
    800045e2:	7442                	ld	s0,48(sp)
    800045e4:	74a2                	ld	s1,40(sp)
    800045e6:	7902                	ld	s2,32(sp)
    800045e8:	69e2                	ld	s3,24(sp)
    800045ea:	6a42                	ld	s4,16(sp)
    800045ec:	6aa2                	ld	s5,8(sp)
    800045ee:	6b02                	ld	s6,0(sp)
    800045f0:	6121                	addi	sp,sp,64
    800045f2:	8082                	ret
    800045f4:	8082                	ret

00000000800045f6 <initlog>:
{
    800045f6:	7179                	addi	sp,sp,-48
    800045f8:	f406                	sd	ra,40(sp)
    800045fa:	f022                	sd	s0,32(sp)
    800045fc:	ec26                	sd	s1,24(sp)
    800045fe:	e84a                	sd	s2,16(sp)
    80004600:	e44e                	sd	s3,8(sp)
    80004602:	1800                	addi	s0,sp,48
    80004604:	892a                	mv	s2,a0
    80004606:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004608:	0001d497          	auipc	s1,0x1d
    8000460c:	48848493          	addi	s1,s1,1160 # 80021a90 <log>
    80004610:	00004597          	auipc	a1,0x4
    80004614:	16058593          	addi	a1,a1,352 # 80008770 <syscalls+0x1f0>
    80004618:	8526                	mv	a0,s1
    8000461a:	ffffc097          	auipc	ra,0xffffc
    8000461e:	53c080e7          	jalr	1340(ra) # 80000b56 <initlock>
  log.start = sb->logstart;
    80004622:	0149a583          	lw	a1,20(s3)
    80004626:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004628:	0109a783          	lw	a5,16(s3)
    8000462c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000462e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004632:	854a                	mv	a0,s2
    80004634:	fffff097          	auipc	ra,0xfffff
    80004638:	e92080e7          	jalr	-366(ra) # 800034c6 <bread>
  log.lh.n = lh->n;
    8000463c:	4d3c                	lw	a5,88(a0)
    8000463e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004640:	02f05563          	blez	a5,8000466a <initlog+0x74>
    80004644:	05c50713          	addi	a4,a0,92
    80004648:	0001d697          	auipc	a3,0x1d
    8000464c:	47868693          	addi	a3,a3,1144 # 80021ac0 <log+0x30>
    80004650:	37fd                	addiw	a5,a5,-1
    80004652:	1782                	slli	a5,a5,0x20
    80004654:	9381                	srli	a5,a5,0x20
    80004656:	078a                	slli	a5,a5,0x2
    80004658:	06050613          	addi	a2,a0,96
    8000465c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000465e:	4310                	lw	a2,0(a4)
    80004660:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004662:	0711                	addi	a4,a4,4
    80004664:	0691                	addi	a3,a3,4
    80004666:	fef71ce3          	bne	a4,a5,8000465e <initlog+0x68>
  brelse(buf);
    8000466a:	fffff097          	auipc	ra,0xfffff
    8000466e:	f8c080e7          	jalr	-116(ra) # 800035f6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004672:	4505                	li	a0,1
    80004674:	00000097          	auipc	ra,0x0
    80004678:	ebe080e7          	jalr	-322(ra) # 80004532 <install_trans>
  log.lh.n = 0;
    8000467c:	0001d797          	auipc	a5,0x1d
    80004680:	4407a023          	sw	zero,1088(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    80004684:	00000097          	auipc	ra,0x0
    80004688:	e34080e7          	jalr	-460(ra) # 800044b8 <write_head>
}
    8000468c:	70a2                	ld	ra,40(sp)
    8000468e:	7402                	ld	s0,32(sp)
    80004690:	64e2                	ld	s1,24(sp)
    80004692:	6942                	ld	s2,16(sp)
    80004694:	69a2                	ld	s3,8(sp)
    80004696:	6145                	addi	sp,sp,48
    80004698:	8082                	ret

000000008000469a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000469a:	1101                	addi	sp,sp,-32
    8000469c:	ec06                	sd	ra,24(sp)
    8000469e:	e822                	sd	s0,16(sp)
    800046a0:	e426                	sd	s1,8(sp)
    800046a2:	e04a                	sd	s2,0(sp)
    800046a4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046a6:	0001d517          	auipc	a0,0x1d
    800046aa:	3ea50513          	addi	a0,a0,1002 # 80021a90 <log>
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	538080e7          	jalr	1336(ra) # 80000be6 <acquire>
  while(1){
    if(log.committing){
    800046b6:	0001d497          	auipc	s1,0x1d
    800046ba:	3da48493          	addi	s1,s1,986 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046be:	4979                	li	s2,30
    800046c0:	a039                	j	800046ce <begin_op+0x34>
      sleep(&log, &log.lock);
    800046c2:	85a6                	mv	a1,s1
    800046c4:	8526                	mv	a0,s1
    800046c6:	ffffe097          	auipc	ra,0xffffe
    800046ca:	be2080e7          	jalr	-1054(ra) # 800022a8 <sleep>
    if(log.committing){
    800046ce:	50dc                	lw	a5,36(s1)
    800046d0:	fbed                	bnez	a5,800046c2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046d2:	509c                	lw	a5,32(s1)
    800046d4:	0017871b          	addiw	a4,a5,1
    800046d8:	0007069b          	sext.w	a3,a4
    800046dc:	0027179b          	slliw	a5,a4,0x2
    800046e0:	9fb9                	addw	a5,a5,a4
    800046e2:	0017979b          	slliw	a5,a5,0x1
    800046e6:	54d8                	lw	a4,44(s1)
    800046e8:	9fb9                	addw	a5,a5,a4
    800046ea:	00f95963          	bge	s2,a5,800046fc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800046ee:	85a6                	mv	a1,s1
    800046f0:	8526                	mv	a0,s1
    800046f2:	ffffe097          	auipc	ra,0xffffe
    800046f6:	bb6080e7          	jalr	-1098(ra) # 800022a8 <sleep>
    800046fa:	bfd1                	j	800046ce <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800046fc:	0001d517          	auipc	a0,0x1d
    80004700:	39450513          	addi	a0,a0,916 # 80021a90 <log>
    80004704:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	594080e7          	jalr	1428(ra) # 80000c9a <release>
      break;
    }
  }
}
    8000470e:	60e2                	ld	ra,24(sp)
    80004710:	6442                	ld	s0,16(sp)
    80004712:	64a2                	ld	s1,8(sp)
    80004714:	6902                	ld	s2,0(sp)
    80004716:	6105                	addi	sp,sp,32
    80004718:	8082                	ret

000000008000471a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000471a:	7139                	addi	sp,sp,-64
    8000471c:	fc06                	sd	ra,56(sp)
    8000471e:	f822                	sd	s0,48(sp)
    80004720:	f426                	sd	s1,40(sp)
    80004722:	f04a                	sd	s2,32(sp)
    80004724:	ec4e                	sd	s3,24(sp)
    80004726:	e852                	sd	s4,16(sp)
    80004728:	e456                	sd	s5,8(sp)
    8000472a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000472c:	0001d497          	auipc	s1,0x1d
    80004730:	36448493          	addi	s1,s1,868 # 80021a90 <log>
    80004734:	8526                	mv	a0,s1
    80004736:	ffffc097          	auipc	ra,0xffffc
    8000473a:	4b0080e7          	jalr	1200(ra) # 80000be6 <acquire>
  log.outstanding -= 1;
    8000473e:	509c                	lw	a5,32(s1)
    80004740:	37fd                	addiw	a5,a5,-1
    80004742:	0007891b          	sext.w	s2,a5
    80004746:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004748:	50dc                	lw	a5,36(s1)
    8000474a:	efb9                	bnez	a5,800047a8 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000474c:	06091663          	bnez	s2,800047b8 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004750:	0001d497          	auipc	s1,0x1d
    80004754:	34048493          	addi	s1,s1,832 # 80021a90 <log>
    80004758:	4785                	li	a5,1
    8000475a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000475c:	8526                	mv	a0,s1
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	53c080e7          	jalr	1340(ra) # 80000c9a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004766:	54dc                	lw	a5,44(s1)
    80004768:	06f04763          	bgtz	a5,800047d6 <end_op+0xbc>
    acquire(&log.lock);
    8000476c:	0001d497          	auipc	s1,0x1d
    80004770:	32448493          	addi	s1,s1,804 # 80021a90 <log>
    80004774:	8526                	mv	a0,s1
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	470080e7          	jalr	1136(ra) # 80000be6 <acquire>
    log.committing = 0;
    8000477e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004782:	8526                	mv	a0,s1
    80004784:	ffffe097          	auipc	ra,0xffffe
    80004788:	d0a080e7          	jalr	-758(ra) # 8000248e <wakeup>
    release(&log.lock);
    8000478c:	8526                	mv	a0,s1
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	50c080e7          	jalr	1292(ra) # 80000c9a <release>
}
    80004796:	70e2                	ld	ra,56(sp)
    80004798:	7442                	ld	s0,48(sp)
    8000479a:	74a2                	ld	s1,40(sp)
    8000479c:	7902                	ld	s2,32(sp)
    8000479e:	69e2                	ld	s3,24(sp)
    800047a0:	6a42                	ld	s4,16(sp)
    800047a2:	6aa2                	ld	s5,8(sp)
    800047a4:	6121                	addi	sp,sp,64
    800047a6:	8082                	ret
    panic("log.committing");
    800047a8:	00004517          	auipc	a0,0x4
    800047ac:	fd050513          	addi	a0,a0,-48 # 80008778 <syscalls+0x1f8>
    800047b0:	ffffc097          	auipc	ra,0xffffc
    800047b4:	d90080e7          	jalr	-624(ra) # 80000540 <panic>
    wakeup(&log);
    800047b8:	0001d497          	auipc	s1,0x1d
    800047bc:	2d848493          	addi	s1,s1,728 # 80021a90 <log>
    800047c0:	8526                	mv	a0,s1
    800047c2:	ffffe097          	auipc	ra,0xffffe
    800047c6:	ccc080e7          	jalr	-820(ra) # 8000248e <wakeup>
  release(&log.lock);
    800047ca:	8526                	mv	a0,s1
    800047cc:	ffffc097          	auipc	ra,0xffffc
    800047d0:	4ce080e7          	jalr	1230(ra) # 80000c9a <release>
  if(do_commit){
    800047d4:	b7c9                	j	80004796 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047d6:	0001da97          	auipc	s5,0x1d
    800047da:	2eaa8a93          	addi	s5,s5,746 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800047de:	0001da17          	auipc	s4,0x1d
    800047e2:	2b2a0a13          	addi	s4,s4,690 # 80021a90 <log>
    800047e6:	018a2583          	lw	a1,24(s4)
    800047ea:	012585bb          	addw	a1,a1,s2
    800047ee:	2585                	addiw	a1,a1,1
    800047f0:	028a2503          	lw	a0,40(s4)
    800047f4:	fffff097          	auipc	ra,0xfffff
    800047f8:	cd2080e7          	jalr	-814(ra) # 800034c6 <bread>
    800047fc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047fe:	000aa583          	lw	a1,0(s5)
    80004802:	028a2503          	lw	a0,40(s4)
    80004806:	fffff097          	auipc	ra,0xfffff
    8000480a:	cc0080e7          	jalr	-832(ra) # 800034c6 <bread>
    8000480e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004810:	40000613          	li	a2,1024
    80004814:	05850593          	addi	a1,a0,88
    80004818:	05848513          	addi	a0,s1,88
    8000481c:	ffffc097          	auipc	ra,0xffffc
    80004820:	526080e7          	jalr	1318(ra) # 80000d42 <memmove>
    bwrite(to);  // write the log
    80004824:	8526                	mv	a0,s1
    80004826:	fffff097          	auipc	ra,0xfffff
    8000482a:	d92080e7          	jalr	-622(ra) # 800035b8 <bwrite>
    brelse(from);
    8000482e:	854e                	mv	a0,s3
    80004830:	fffff097          	auipc	ra,0xfffff
    80004834:	dc6080e7          	jalr	-570(ra) # 800035f6 <brelse>
    brelse(to);
    80004838:	8526                	mv	a0,s1
    8000483a:	fffff097          	auipc	ra,0xfffff
    8000483e:	dbc080e7          	jalr	-580(ra) # 800035f6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004842:	2905                	addiw	s2,s2,1
    80004844:	0a91                	addi	s5,s5,4
    80004846:	02ca2783          	lw	a5,44(s4)
    8000484a:	f8f94ee3          	blt	s2,a5,800047e6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000484e:	00000097          	auipc	ra,0x0
    80004852:	c6a080e7          	jalr	-918(ra) # 800044b8 <write_head>
    install_trans(0); // Now install writes to home locations
    80004856:	4501                	li	a0,0
    80004858:	00000097          	auipc	ra,0x0
    8000485c:	cda080e7          	jalr	-806(ra) # 80004532 <install_trans>
    log.lh.n = 0;
    80004860:	0001d797          	auipc	a5,0x1d
    80004864:	2407ae23          	sw	zero,604(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004868:	00000097          	auipc	ra,0x0
    8000486c:	c50080e7          	jalr	-944(ra) # 800044b8 <write_head>
    80004870:	bdf5                	j	8000476c <end_op+0x52>

0000000080004872 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004872:	1101                	addi	sp,sp,-32
    80004874:	ec06                	sd	ra,24(sp)
    80004876:	e822                	sd	s0,16(sp)
    80004878:	e426                	sd	s1,8(sp)
    8000487a:	e04a                	sd	s2,0(sp)
    8000487c:	1000                	addi	s0,sp,32
    8000487e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004880:	0001d917          	auipc	s2,0x1d
    80004884:	21090913          	addi	s2,s2,528 # 80021a90 <log>
    80004888:	854a                	mv	a0,s2
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	35c080e7          	jalr	860(ra) # 80000be6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004892:	02c92603          	lw	a2,44(s2)
    80004896:	47f5                	li	a5,29
    80004898:	06c7c563          	blt	a5,a2,80004902 <log_write+0x90>
    8000489c:	0001d797          	auipc	a5,0x1d
    800048a0:	2107a783          	lw	a5,528(a5) # 80021aac <log+0x1c>
    800048a4:	37fd                	addiw	a5,a5,-1
    800048a6:	04f65e63          	bge	a2,a5,80004902 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800048aa:	0001d797          	auipc	a5,0x1d
    800048ae:	2067a783          	lw	a5,518(a5) # 80021ab0 <log+0x20>
    800048b2:	06f05063          	blez	a5,80004912 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048b6:	4781                	li	a5,0
    800048b8:	06c05563          	blez	a2,80004922 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048bc:	44cc                	lw	a1,12(s1)
    800048be:	0001d717          	auipc	a4,0x1d
    800048c2:	20270713          	addi	a4,a4,514 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800048c6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048c8:	4314                	lw	a3,0(a4)
    800048ca:	04b68c63          	beq	a3,a1,80004922 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800048ce:	2785                	addiw	a5,a5,1
    800048d0:	0711                	addi	a4,a4,4
    800048d2:	fef61be3          	bne	a2,a5,800048c8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800048d6:	0621                	addi	a2,a2,8
    800048d8:	060a                	slli	a2,a2,0x2
    800048da:	0001d797          	auipc	a5,0x1d
    800048de:	1b678793          	addi	a5,a5,438 # 80021a90 <log>
    800048e2:	963e                	add	a2,a2,a5
    800048e4:	44dc                	lw	a5,12(s1)
    800048e6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800048e8:	8526                	mv	a0,s1
    800048ea:	fffff097          	auipc	ra,0xfffff
    800048ee:	daa080e7          	jalr	-598(ra) # 80003694 <bpin>
    log.lh.n++;
    800048f2:	0001d717          	auipc	a4,0x1d
    800048f6:	19e70713          	addi	a4,a4,414 # 80021a90 <log>
    800048fa:	575c                	lw	a5,44(a4)
    800048fc:	2785                	addiw	a5,a5,1
    800048fe:	d75c                	sw	a5,44(a4)
    80004900:	a835                	j	8000493c <log_write+0xca>
    panic("too big a transaction");
    80004902:	00004517          	auipc	a0,0x4
    80004906:	e8650513          	addi	a0,a0,-378 # 80008788 <syscalls+0x208>
    8000490a:	ffffc097          	auipc	ra,0xffffc
    8000490e:	c36080e7          	jalr	-970(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004912:	00004517          	auipc	a0,0x4
    80004916:	e8e50513          	addi	a0,a0,-370 # 800087a0 <syscalls+0x220>
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	c26080e7          	jalr	-986(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004922:	00878713          	addi	a4,a5,8
    80004926:	00271693          	slli	a3,a4,0x2
    8000492a:	0001d717          	auipc	a4,0x1d
    8000492e:	16670713          	addi	a4,a4,358 # 80021a90 <log>
    80004932:	9736                	add	a4,a4,a3
    80004934:	44d4                	lw	a3,12(s1)
    80004936:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004938:	faf608e3          	beq	a2,a5,800048e8 <log_write+0x76>
  }
  release(&log.lock);
    8000493c:	0001d517          	auipc	a0,0x1d
    80004940:	15450513          	addi	a0,a0,340 # 80021a90 <log>
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	356080e7          	jalr	854(ra) # 80000c9a <release>
}
    8000494c:	60e2                	ld	ra,24(sp)
    8000494e:	6442                	ld	s0,16(sp)
    80004950:	64a2                	ld	s1,8(sp)
    80004952:	6902                	ld	s2,0(sp)
    80004954:	6105                	addi	sp,sp,32
    80004956:	8082                	ret

0000000080004958 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004958:	1101                	addi	sp,sp,-32
    8000495a:	ec06                	sd	ra,24(sp)
    8000495c:	e822                	sd	s0,16(sp)
    8000495e:	e426                	sd	s1,8(sp)
    80004960:	e04a                	sd	s2,0(sp)
    80004962:	1000                	addi	s0,sp,32
    80004964:	84aa                	mv	s1,a0
    80004966:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004968:	00004597          	auipc	a1,0x4
    8000496c:	e5858593          	addi	a1,a1,-424 # 800087c0 <syscalls+0x240>
    80004970:	0521                	addi	a0,a0,8
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	1e4080e7          	jalr	484(ra) # 80000b56 <initlock>
  lk->name = name;
    8000497a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000497e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004982:	0204a423          	sw	zero,40(s1)
}
    80004986:	60e2                	ld	ra,24(sp)
    80004988:	6442                	ld	s0,16(sp)
    8000498a:	64a2                	ld	s1,8(sp)
    8000498c:	6902                	ld	s2,0(sp)
    8000498e:	6105                	addi	sp,sp,32
    80004990:	8082                	ret

0000000080004992 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004992:	1101                	addi	sp,sp,-32
    80004994:	ec06                	sd	ra,24(sp)
    80004996:	e822                	sd	s0,16(sp)
    80004998:	e426                	sd	s1,8(sp)
    8000499a:	e04a                	sd	s2,0(sp)
    8000499c:	1000                	addi	s0,sp,32
    8000499e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049a0:	00850913          	addi	s2,a0,8
    800049a4:	854a                	mv	a0,s2
    800049a6:	ffffc097          	auipc	ra,0xffffc
    800049aa:	240080e7          	jalr	576(ra) # 80000be6 <acquire>
  while (lk->locked) {
    800049ae:	409c                	lw	a5,0(s1)
    800049b0:	cb89                	beqz	a5,800049c2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049b2:	85ca                	mv	a1,s2
    800049b4:	8526                	mv	a0,s1
    800049b6:	ffffe097          	auipc	ra,0xffffe
    800049ba:	8f2080e7          	jalr	-1806(ra) # 800022a8 <sleep>
  while (lk->locked) {
    800049be:	409c                	lw	a5,0(s1)
    800049c0:	fbed                	bnez	a5,800049b2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800049c2:	4785                	li	a5,1
    800049c4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800049c6:	ffffd097          	auipc	ra,0xffffd
    800049ca:	02c080e7          	jalr	44(ra) # 800019f2 <myproc>
    800049ce:	591c                	lw	a5,48(a0)
    800049d0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800049d2:	854a                	mv	a0,s2
    800049d4:	ffffc097          	auipc	ra,0xffffc
    800049d8:	2c6080e7          	jalr	710(ra) # 80000c9a <release>
}
    800049dc:	60e2                	ld	ra,24(sp)
    800049de:	6442                	ld	s0,16(sp)
    800049e0:	64a2                	ld	s1,8(sp)
    800049e2:	6902                	ld	s2,0(sp)
    800049e4:	6105                	addi	sp,sp,32
    800049e6:	8082                	ret

00000000800049e8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049e8:	1101                	addi	sp,sp,-32
    800049ea:	ec06                	sd	ra,24(sp)
    800049ec:	e822                	sd	s0,16(sp)
    800049ee:	e426                	sd	s1,8(sp)
    800049f0:	e04a                	sd	s2,0(sp)
    800049f2:	1000                	addi	s0,sp,32
    800049f4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049f6:	00850913          	addi	s2,a0,8
    800049fa:	854a                	mv	a0,s2
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	1ea080e7          	jalr	490(ra) # 80000be6 <acquire>
  lk->locked = 0;
    80004a04:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a08:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a0c:	8526                	mv	a0,s1
    80004a0e:	ffffe097          	auipc	ra,0xffffe
    80004a12:	a80080e7          	jalr	-1408(ra) # 8000248e <wakeup>
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

0000000080004a2c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a2c:	7179                	addi	sp,sp,-48
    80004a2e:	f406                	sd	ra,40(sp)
    80004a30:	f022                	sd	s0,32(sp)
    80004a32:	ec26                	sd	s1,24(sp)
    80004a34:	e84a                	sd	s2,16(sp)
    80004a36:	e44e                	sd	s3,8(sp)
    80004a38:	1800                	addi	s0,sp,48
    80004a3a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a3c:	00850913          	addi	s2,a0,8
    80004a40:	854a                	mv	a0,s2
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	1a4080e7          	jalr	420(ra) # 80000be6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a4a:	409c                	lw	a5,0(s1)
    80004a4c:	ef99                	bnez	a5,80004a6a <holdingsleep+0x3e>
    80004a4e:	4481                	li	s1,0
  release(&lk->lk);
    80004a50:	854a                	mv	a0,s2
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	248080e7          	jalr	584(ra) # 80000c9a <release>
  return r;
}
    80004a5a:	8526                	mv	a0,s1
    80004a5c:	70a2                	ld	ra,40(sp)
    80004a5e:	7402                	ld	s0,32(sp)
    80004a60:	64e2                	ld	s1,24(sp)
    80004a62:	6942                	ld	s2,16(sp)
    80004a64:	69a2                	ld	s3,8(sp)
    80004a66:	6145                	addi	sp,sp,48
    80004a68:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a6a:	0284a983          	lw	s3,40(s1)
    80004a6e:	ffffd097          	auipc	ra,0xffffd
    80004a72:	f84080e7          	jalr	-124(ra) # 800019f2 <myproc>
    80004a76:	5904                	lw	s1,48(a0)
    80004a78:	413484b3          	sub	s1,s1,s3
    80004a7c:	0014b493          	seqz	s1,s1
    80004a80:	bfc1                	j	80004a50 <holdingsleep+0x24>

0000000080004a82 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a82:	1141                	addi	sp,sp,-16
    80004a84:	e406                	sd	ra,8(sp)
    80004a86:	e022                	sd	s0,0(sp)
    80004a88:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a8a:	00004597          	auipc	a1,0x4
    80004a8e:	d4658593          	addi	a1,a1,-698 # 800087d0 <syscalls+0x250>
    80004a92:	0001d517          	auipc	a0,0x1d
    80004a96:	14650513          	addi	a0,a0,326 # 80021bd8 <ftable>
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	0bc080e7          	jalr	188(ra) # 80000b56 <initlock>
}
    80004aa2:	60a2                	ld	ra,8(sp)
    80004aa4:	6402                	ld	s0,0(sp)
    80004aa6:	0141                	addi	sp,sp,16
    80004aa8:	8082                	ret

0000000080004aaa <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004aaa:	1101                	addi	sp,sp,-32
    80004aac:	ec06                	sd	ra,24(sp)
    80004aae:	e822                	sd	s0,16(sp)
    80004ab0:	e426                	sd	s1,8(sp)
    80004ab2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ab4:	0001d517          	auipc	a0,0x1d
    80004ab8:	12450513          	addi	a0,a0,292 # 80021bd8 <ftable>
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	12a080e7          	jalr	298(ra) # 80000be6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ac4:	0001d497          	auipc	s1,0x1d
    80004ac8:	12c48493          	addi	s1,s1,300 # 80021bf0 <ftable+0x18>
    80004acc:	0001e717          	auipc	a4,0x1e
    80004ad0:	0c470713          	addi	a4,a4,196 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    80004ad4:	40dc                	lw	a5,4(s1)
    80004ad6:	cf99                	beqz	a5,80004af4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ad8:	02848493          	addi	s1,s1,40
    80004adc:	fee49ce3          	bne	s1,a4,80004ad4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004ae0:	0001d517          	auipc	a0,0x1d
    80004ae4:	0f850513          	addi	a0,a0,248 # 80021bd8 <ftable>
    80004ae8:	ffffc097          	auipc	ra,0xffffc
    80004aec:	1b2080e7          	jalr	434(ra) # 80000c9a <release>
  return 0;
    80004af0:	4481                	li	s1,0
    80004af2:	a819                	j	80004b08 <filealloc+0x5e>
      f->ref = 1;
    80004af4:	4785                	li	a5,1
    80004af6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004af8:	0001d517          	auipc	a0,0x1d
    80004afc:	0e050513          	addi	a0,a0,224 # 80021bd8 <ftable>
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	19a080e7          	jalr	410(ra) # 80000c9a <release>
}
    80004b08:	8526                	mv	a0,s1
    80004b0a:	60e2                	ld	ra,24(sp)
    80004b0c:	6442                	ld	s0,16(sp)
    80004b0e:	64a2                	ld	s1,8(sp)
    80004b10:	6105                	addi	sp,sp,32
    80004b12:	8082                	ret

0000000080004b14 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b14:	1101                	addi	sp,sp,-32
    80004b16:	ec06                	sd	ra,24(sp)
    80004b18:	e822                	sd	s0,16(sp)
    80004b1a:	e426                	sd	s1,8(sp)
    80004b1c:	1000                	addi	s0,sp,32
    80004b1e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b20:	0001d517          	auipc	a0,0x1d
    80004b24:	0b850513          	addi	a0,a0,184 # 80021bd8 <ftable>
    80004b28:	ffffc097          	auipc	ra,0xffffc
    80004b2c:	0be080e7          	jalr	190(ra) # 80000be6 <acquire>
  if(f->ref < 1)
    80004b30:	40dc                	lw	a5,4(s1)
    80004b32:	02f05263          	blez	a5,80004b56 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b36:	2785                	addiw	a5,a5,1
    80004b38:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b3a:	0001d517          	auipc	a0,0x1d
    80004b3e:	09e50513          	addi	a0,a0,158 # 80021bd8 <ftable>
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	158080e7          	jalr	344(ra) # 80000c9a <release>
  return f;
}
    80004b4a:	8526                	mv	a0,s1
    80004b4c:	60e2                	ld	ra,24(sp)
    80004b4e:	6442                	ld	s0,16(sp)
    80004b50:	64a2                	ld	s1,8(sp)
    80004b52:	6105                	addi	sp,sp,32
    80004b54:	8082                	ret
    panic("filedup");
    80004b56:	00004517          	auipc	a0,0x4
    80004b5a:	c8250513          	addi	a0,a0,-894 # 800087d8 <syscalls+0x258>
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	9e2080e7          	jalr	-1566(ra) # 80000540 <panic>

0000000080004b66 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b66:	7139                	addi	sp,sp,-64
    80004b68:	fc06                	sd	ra,56(sp)
    80004b6a:	f822                	sd	s0,48(sp)
    80004b6c:	f426                	sd	s1,40(sp)
    80004b6e:	f04a                	sd	s2,32(sp)
    80004b70:	ec4e                	sd	s3,24(sp)
    80004b72:	e852                	sd	s4,16(sp)
    80004b74:	e456                	sd	s5,8(sp)
    80004b76:	0080                	addi	s0,sp,64
    80004b78:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b7a:	0001d517          	auipc	a0,0x1d
    80004b7e:	05e50513          	addi	a0,a0,94 # 80021bd8 <ftable>
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	064080e7          	jalr	100(ra) # 80000be6 <acquire>
  if(f->ref < 1)
    80004b8a:	40dc                	lw	a5,4(s1)
    80004b8c:	06f05163          	blez	a5,80004bee <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b90:	37fd                	addiw	a5,a5,-1
    80004b92:	0007871b          	sext.w	a4,a5
    80004b96:	c0dc                	sw	a5,4(s1)
    80004b98:	06e04363          	bgtz	a4,80004bfe <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b9c:	0004a903          	lw	s2,0(s1)
    80004ba0:	0094ca83          	lbu	s5,9(s1)
    80004ba4:	0104ba03          	ld	s4,16(s1)
    80004ba8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004bac:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004bb0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004bb4:	0001d517          	auipc	a0,0x1d
    80004bb8:	02450513          	addi	a0,a0,36 # 80021bd8 <ftable>
    80004bbc:	ffffc097          	auipc	ra,0xffffc
    80004bc0:	0de080e7          	jalr	222(ra) # 80000c9a <release>

  if(ff.type == FD_PIPE){
    80004bc4:	4785                	li	a5,1
    80004bc6:	04f90d63          	beq	s2,a5,80004c20 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004bca:	3979                	addiw	s2,s2,-2
    80004bcc:	4785                	li	a5,1
    80004bce:	0527e063          	bltu	a5,s2,80004c0e <fileclose+0xa8>
    begin_op();
    80004bd2:	00000097          	auipc	ra,0x0
    80004bd6:	ac8080e7          	jalr	-1336(ra) # 8000469a <begin_op>
    iput(ff.ip);
    80004bda:	854e                	mv	a0,s3
    80004bdc:	fffff097          	auipc	ra,0xfffff
    80004be0:	2a6080e7          	jalr	678(ra) # 80003e82 <iput>
    end_op();
    80004be4:	00000097          	auipc	ra,0x0
    80004be8:	b36080e7          	jalr	-1226(ra) # 8000471a <end_op>
    80004bec:	a00d                	j	80004c0e <fileclose+0xa8>
    panic("fileclose");
    80004bee:	00004517          	auipc	a0,0x4
    80004bf2:	bf250513          	addi	a0,a0,-1038 # 800087e0 <syscalls+0x260>
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	94a080e7          	jalr	-1718(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004bfe:	0001d517          	auipc	a0,0x1d
    80004c02:	fda50513          	addi	a0,a0,-38 # 80021bd8 <ftable>
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	094080e7          	jalr	148(ra) # 80000c9a <release>
  }
}
    80004c0e:	70e2                	ld	ra,56(sp)
    80004c10:	7442                	ld	s0,48(sp)
    80004c12:	74a2                	ld	s1,40(sp)
    80004c14:	7902                	ld	s2,32(sp)
    80004c16:	69e2                	ld	s3,24(sp)
    80004c18:	6a42                	ld	s4,16(sp)
    80004c1a:	6aa2                	ld	s5,8(sp)
    80004c1c:	6121                	addi	sp,sp,64
    80004c1e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c20:	85d6                	mv	a1,s5
    80004c22:	8552                	mv	a0,s4
    80004c24:	00000097          	auipc	ra,0x0
    80004c28:	34c080e7          	jalr	844(ra) # 80004f70 <pipeclose>
    80004c2c:	b7cd                	j	80004c0e <fileclose+0xa8>

0000000080004c2e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c2e:	715d                	addi	sp,sp,-80
    80004c30:	e486                	sd	ra,72(sp)
    80004c32:	e0a2                	sd	s0,64(sp)
    80004c34:	fc26                	sd	s1,56(sp)
    80004c36:	f84a                	sd	s2,48(sp)
    80004c38:	f44e                	sd	s3,40(sp)
    80004c3a:	0880                	addi	s0,sp,80
    80004c3c:	84aa                	mv	s1,a0
    80004c3e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c40:	ffffd097          	auipc	ra,0xffffd
    80004c44:	db2080e7          	jalr	-590(ra) # 800019f2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c48:	409c                	lw	a5,0(s1)
    80004c4a:	37f9                	addiw	a5,a5,-2
    80004c4c:	4705                	li	a4,1
    80004c4e:	04f76763          	bltu	a4,a5,80004c9c <filestat+0x6e>
    80004c52:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c54:	6c88                	ld	a0,24(s1)
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	072080e7          	jalr	114(ra) # 80003cc8 <ilock>
    stati(f->ip, &st);
    80004c5e:	fb840593          	addi	a1,s0,-72
    80004c62:	6c88                	ld	a0,24(s1)
    80004c64:	fffff097          	auipc	ra,0xfffff
    80004c68:	2ee080e7          	jalr	750(ra) # 80003f52 <stati>
    iunlock(f->ip);
    80004c6c:	6c88                	ld	a0,24(s1)
    80004c6e:	fffff097          	auipc	ra,0xfffff
    80004c72:	11c080e7          	jalr	284(ra) # 80003d8a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c76:	46e1                	li	a3,24
    80004c78:	fb840613          	addi	a2,s0,-72
    80004c7c:	85ce                	mv	a1,s3
    80004c7e:	05093503          	ld	a0,80(s2)
    80004c82:	ffffd097          	auipc	ra,0xffffd
    80004c86:	9f2080e7          	jalr	-1550(ra) # 80001674 <copyout>
    80004c8a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c8e:	60a6                	ld	ra,72(sp)
    80004c90:	6406                	ld	s0,64(sp)
    80004c92:	74e2                	ld	s1,56(sp)
    80004c94:	7942                	ld	s2,48(sp)
    80004c96:	79a2                	ld	s3,40(sp)
    80004c98:	6161                	addi	sp,sp,80
    80004c9a:	8082                	ret
  return -1;
    80004c9c:	557d                	li	a0,-1
    80004c9e:	bfc5                	j	80004c8e <filestat+0x60>

0000000080004ca0 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ca0:	7179                	addi	sp,sp,-48
    80004ca2:	f406                	sd	ra,40(sp)
    80004ca4:	f022                	sd	s0,32(sp)
    80004ca6:	ec26                	sd	s1,24(sp)
    80004ca8:	e84a                	sd	s2,16(sp)
    80004caa:	e44e                	sd	s3,8(sp)
    80004cac:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004cae:	00854783          	lbu	a5,8(a0)
    80004cb2:	c3d5                	beqz	a5,80004d56 <fileread+0xb6>
    80004cb4:	84aa                	mv	s1,a0
    80004cb6:	89ae                	mv	s3,a1
    80004cb8:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cba:	411c                	lw	a5,0(a0)
    80004cbc:	4705                	li	a4,1
    80004cbe:	04e78963          	beq	a5,a4,80004d10 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cc2:	470d                	li	a4,3
    80004cc4:	04e78d63          	beq	a5,a4,80004d1e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cc8:	4709                	li	a4,2
    80004cca:	06e79e63          	bne	a5,a4,80004d46 <fileread+0xa6>
    ilock(f->ip);
    80004cce:	6d08                	ld	a0,24(a0)
    80004cd0:	fffff097          	auipc	ra,0xfffff
    80004cd4:	ff8080e7          	jalr	-8(ra) # 80003cc8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004cd8:	874a                	mv	a4,s2
    80004cda:	5094                	lw	a3,32(s1)
    80004cdc:	864e                	mv	a2,s3
    80004cde:	4585                	li	a1,1
    80004ce0:	6c88                	ld	a0,24(s1)
    80004ce2:	fffff097          	auipc	ra,0xfffff
    80004ce6:	29a080e7          	jalr	666(ra) # 80003f7c <readi>
    80004cea:	892a                	mv	s2,a0
    80004cec:	00a05563          	blez	a0,80004cf6 <fileread+0x56>
      f->off += r;
    80004cf0:	509c                	lw	a5,32(s1)
    80004cf2:	9fa9                	addw	a5,a5,a0
    80004cf4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004cf6:	6c88                	ld	a0,24(s1)
    80004cf8:	fffff097          	auipc	ra,0xfffff
    80004cfc:	092080e7          	jalr	146(ra) # 80003d8a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d00:	854a                	mv	a0,s2
    80004d02:	70a2                	ld	ra,40(sp)
    80004d04:	7402                	ld	s0,32(sp)
    80004d06:	64e2                	ld	s1,24(sp)
    80004d08:	6942                	ld	s2,16(sp)
    80004d0a:	69a2                	ld	s3,8(sp)
    80004d0c:	6145                	addi	sp,sp,48
    80004d0e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d10:	6908                	ld	a0,16(a0)
    80004d12:	00000097          	auipc	ra,0x0
    80004d16:	3ca080e7          	jalr	970(ra) # 800050dc <piperead>
    80004d1a:	892a                	mv	s2,a0
    80004d1c:	b7d5                	j	80004d00 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d1e:	02451783          	lh	a5,36(a0)
    80004d22:	03079693          	slli	a3,a5,0x30
    80004d26:	92c1                	srli	a3,a3,0x30
    80004d28:	4725                	li	a4,9
    80004d2a:	02d76863          	bltu	a4,a3,80004d5a <fileread+0xba>
    80004d2e:	0792                	slli	a5,a5,0x4
    80004d30:	0001d717          	auipc	a4,0x1d
    80004d34:	e0870713          	addi	a4,a4,-504 # 80021b38 <devsw>
    80004d38:	97ba                	add	a5,a5,a4
    80004d3a:	639c                	ld	a5,0(a5)
    80004d3c:	c38d                	beqz	a5,80004d5e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d3e:	4505                	li	a0,1
    80004d40:	9782                	jalr	a5
    80004d42:	892a                	mv	s2,a0
    80004d44:	bf75                	j	80004d00 <fileread+0x60>
    panic("fileread");
    80004d46:	00004517          	auipc	a0,0x4
    80004d4a:	aaa50513          	addi	a0,a0,-1366 # 800087f0 <syscalls+0x270>
    80004d4e:	ffffb097          	auipc	ra,0xffffb
    80004d52:	7f2080e7          	jalr	2034(ra) # 80000540 <panic>
    return -1;
    80004d56:	597d                	li	s2,-1
    80004d58:	b765                	j	80004d00 <fileread+0x60>
      return -1;
    80004d5a:	597d                	li	s2,-1
    80004d5c:	b755                	j	80004d00 <fileread+0x60>
    80004d5e:	597d                	li	s2,-1
    80004d60:	b745                	j	80004d00 <fileread+0x60>

0000000080004d62 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004d62:	715d                	addi	sp,sp,-80
    80004d64:	e486                	sd	ra,72(sp)
    80004d66:	e0a2                	sd	s0,64(sp)
    80004d68:	fc26                	sd	s1,56(sp)
    80004d6a:	f84a                	sd	s2,48(sp)
    80004d6c:	f44e                	sd	s3,40(sp)
    80004d6e:	f052                	sd	s4,32(sp)
    80004d70:	ec56                	sd	s5,24(sp)
    80004d72:	e85a                	sd	s6,16(sp)
    80004d74:	e45e                	sd	s7,8(sp)
    80004d76:	e062                	sd	s8,0(sp)
    80004d78:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004d7a:	00954783          	lbu	a5,9(a0)
    80004d7e:	10078663          	beqz	a5,80004e8a <filewrite+0x128>
    80004d82:	892a                	mv	s2,a0
    80004d84:	8aae                	mv	s5,a1
    80004d86:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d88:	411c                	lw	a5,0(a0)
    80004d8a:	4705                	li	a4,1
    80004d8c:	02e78263          	beq	a5,a4,80004db0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d90:	470d                	li	a4,3
    80004d92:	02e78663          	beq	a5,a4,80004dbe <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d96:	4709                	li	a4,2
    80004d98:	0ee79163          	bne	a5,a4,80004e7a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d9c:	0ac05d63          	blez	a2,80004e56 <filewrite+0xf4>
    int i = 0;
    80004da0:	4981                	li	s3,0
    80004da2:	6b05                	lui	s6,0x1
    80004da4:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004da8:	6b85                	lui	s7,0x1
    80004daa:	c00b8b9b          	addiw	s7,s7,-1024
    80004dae:	a861                	j	80004e46 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004db0:	6908                	ld	a0,16(a0)
    80004db2:	00000097          	auipc	ra,0x0
    80004db6:	22e080e7          	jalr	558(ra) # 80004fe0 <pipewrite>
    80004dba:	8a2a                	mv	s4,a0
    80004dbc:	a045                	j	80004e5c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004dbe:	02451783          	lh	a5,36(a0)
    80004dc2:	03079693          	slli	a3,a5,0x30
    80004dc6:	92c1                	srli	a3,a3,0x30
    80004dc8:	4725                	li	a4,9
    80004dca:	0cd76263          	bltu	a4,a3,80004e8e <filewrite+0x12c>
    80004dce:	0792                	slli	a5,a5,0x4
    80004dd0:	0001d717          	auipc	a4,0x1d
    80004dd4:	d6870713          	addi	a4,a4,-664 # 80021b38 <devsw>
    80004dd8:	97ba                	add	a5,a5,a4
    80004dda:	679c                	ld	a5,8(a5)
    80004ddc:	cbdd                	beqz	a5,80004e92 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004dde:	4505                	li	a0,1
    80004de0:	9782                	jalr	a5
    80004de2:	8a2a                	mv	s4,a0
    80004de4:	a8a5                	j	80004e5c <filewrite+0xfa>
    80004de6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004dea:	00000097          	auipc	ra,0x0
    80004dee:	8b0080e7          	jalr	-1872(ra) # 8000469a <begin_op>
      ilock(f->ip);
    80004df2:	01893503          	ld	a0,24(s2)
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	ed2080e7          	jalr	-302(ra) # 80003cc8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004dfe:	8762                	mv	a4,s8
    80004e00:	02092683          	lw	a3,32(s2)
    80004e04:	01598633          	add	a2,s3,s5
    80004e08:	4585                	li	a1,1
    80004e0a:	01893503          	ld	a0,24(s2)
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	266080e7          	jalr	614(ra) # 80004074 <writei>
    80004e16:	84aa                	mv	s1,a0
    80004e18:	00a05763          	blez	a0,80004e26 <filewrite+0xc4>
        f->off += r;
    80004e1c:	02092783          	lw	a5,32(s2)
    80004e20:	9fa9                	addw	a5,a5,a0
    80004e22:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e26:	01893503          	ld	a0,24(s2)
    80004e2a:	fffff097          	auipc	ra,0xfffff
    80004e2e:	f60080e7          	jalr	-160(ra) # 80003d8a <iunlock>
      end_op();
    80004e32:	00000097          	auipc	ra,0x0
    80004e36:	8e8080e7          	jalr	-1816(ra) # 8000471a <end_op>

      if(r != n1){
    80004e3a:	009c1f63          	bne	s8,s1,80004e58 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004e3e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e42:	0149db63          	bge	s3,s4,80004e58 <filewrite+0xf6>
      int n1 = n - i;
    80004e46:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004e4a:	84be                	mv	s1,a5
    80004e4c:	2781                	sext.w	a5,a5
    80004e4e:	f8fb5ce3          	bge	s6,a5,80004de6 <filewrite+0x84>
    80004e52:	84de                	mv	s1,s7
    80004e54:	bf49                	j	80004de6 <filewrite+0x84>
    int i = 0;
    80004e56:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e58:	013a1f63          	bne	s4,s3,80004e76 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e5c:	8552                	mv	a0,s4
    80004e5e:	60a6                	ld	ra,72(sp)
    80004e60:	6406                	ld	s0,64(sp)
    80004e62:	74e2                	ld	s1,56(sp)
    80004e64:	7942                	ld	s2,48(sp)
    80004e66:	79a2                	ld	s3,40(sp)
    80004e68:	7a02                	ld	s4,32(sp)
    80004e6a:	6ae2                	ld	s5,24(sp)
    80004e6c:	6b42                	ld	s6,16(sp)
    80004e6e:	6ba2                	ld	s7,8(sp)
    80004e70:	6c02                	ld	s8,0(sp)
    80004e72:	6161                	addi	sp,sp,80
    80004e74:	8082                	ret
    ret = (i == n ? n : -1);
    80004e76:	5a7d                	li	s4,-1
    80004e78:	b7d5                	j	80004e5c <filewrite+0xfa>
    panic("filewrite");
    80004e7a:	00004517          	auipc	a0,0x4
    80004e7e:	98650513          	addi	a0,a0,-1658 # 80008800 <syscalls+0x280>
    80004e82:	ffffb097          	auipc	ra,0xffffb
    80004e86:	6be080e7          	jalr	1726(ra) # 80000540 <panic>
    return -1;
    80004e8a:	5a7d                	li	s4,-1
    80004e8c:	bfc1                	j	80004e5c <filewrite+0xfa>
      return -1;
    80004e8e:	5a7d                	li	s4,-1
    80004e90:	b7f1                	j	80004e5c <filewrite+0xfa>
    80004e92:	5a7d                	li	s4,-1
    80004e94:	b7e1                	j	80004e5c <filewrite+0xfa>

0000000080004e96 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e96:	7179                	addi	sp,sp,-48
    80004e98:	f406                	sd	ra,40(sp)
    80004e9a:	f022                	sd	s0,32(sp)
    80004e9c:	ec26                	sd	s1,24(sp)
    80004e9e:	e84a                	sd	s2,16(sp)
    80004ea0:	e44e                	sd	s3,8(sp)
    80004ea2:	e052                	sd	s4,0(sp)
    80004ea4:	1800                	addi	s0,sp,48
    80004ea6:	84aa                	mv	s1,a0
    80004ea8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004eaa:	0005b023          	sd	zero,0(a1)
    80004eae:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004eb2:	00000097          	auipc	ra,0x0
    80004eb6:	bf8080e7          	jalr	-1032(ra) # 80004aaa <filealloc>
    80004eba:	e088                	sd	a0,0(s1)
    80004ebc:	c551                	beqz	a0,80004f48 <pipealloc+0xb2>
    80004ebe:	00000097          	auipc	ra,0x0
    80004ec2:	bec080e7          	jalr	-1044(ra) # 80004aaa <filealloc>
    80004ec6:	00aa3023          	sd	a0,0(s4)
    80004eca:	c92d                	beqz	a0,80004f3c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ecc:	ffffc097          	auipc	ra,0xffffc
    80004ed0:	c2a080e7          	jalr	-982(ra) # 80000af6 <kalloc>
    80004ed4:	892a                	mv	s2,a0
    80004ed6:	c125                	beqz	a0,80004f36 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ed8:	4985                	li	s3,1
    80004eda:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ede:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ee2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ee6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004eea:	00004597          	auipc	a1,0x4
    80004eee:	92658593          	addi	a1,a1,-1754 # 80008810 <syscalls+0x290>
    80004ef2:	ffffc097          	auipc	ra,0xffffc
    80004ef6:	c64080e7          	jalr	-924(ra) # 80000b56 <initlock>
  (*f0)->type = FD_PIPE;
    80004efa:	609c                	ld	a5,0(s1)
    80004efc:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f00:	609c                	ld	a5,0(s1)
    80004f02:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f06:	609c                	ld	a5,0(s1)
    80004f08:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f0c:	609c                	ld	a5,0(s1)
    80004f0e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f12:	000a3783          	ld	a5,0(s4)
    80004f16:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f1a:	000a3783          	ld	a5,0(s4)
    80004f1e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f22:	000a3783          	ld	a5,0(s4)
    80004f26:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f2a:	000a3783          	ld	a5,0(s4)
    80004f2e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f32:	4501                	li	a0,0
    80004f34:	a025                	j	80004f5c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f36:	6088                	ld	a0,0(s1)
    80004f38:	e501                	bnez	a0,80004f40 <pipealloc+0xaa>
    80004f3a:	a039                	j	80004f48 <pipealloc+0xb2>
    80004f3c:	6088                	ld	a0,0(s1)
    80004f3e:	c51d                	beqz	a0,80004f6c <pipealloc+0xd6>
    fileclose(*f0);
    80004f40:	00000097          	auipc	ra,0x0
    80004f44:	c26080e7          	jalr	-986(ra) # 80004b66 <fileclose>
  if(*f1)
    80004f48:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f4c:	557d                	li	a0,-1
  if(*f1)
    80004f4e:	c799                	beqz	a5,80004f5c <pipealloc+0xc6>
    fileclose(*f1);
    80004f50:	853e                	mv	a0,a5
    80004f52:	00000097          	auipc	ra,0x0
    80004f56:	c14080e7          	jalr	-1004(ra) # 80004b66 <fileclose>
  return -1;
    80004f5a:	557d                	li	a0,-1
}
    80004f5c:	70a2                	ld	ra,40(sp)
    80004f5e:	7402                	ld	s0,32(sp)
    80004f60:	64e2                	ld	s1,24(sp)
    80004f62:	6942                	ld	s2,16(sp)
    80004f64:	69a2                	ld	s3,8(sp)
    80004f66:	6a02                	ld	s4,0(sp)
    80004f68:	6145                	addi	sp,sp,48
    80004f6a:	8082                	ret
  return -1;
    80004f6c:	557d                	li	a0,-1
    80004f6e:	b7fd                	j	80004f5c <pipealloc+0xc6>

0000000080004f70 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f70:	1101                	addi	sp,sp,-32
    80004f72:	ec06                	sd	ra,24(sp)
    80004f74:	e822                	sd	s0,16(sp)
    80004f76:	e426                	sd	s1,8(sp)
    80004f78:	e04a                	sd	s2,0(sp)
    80004f7a:	1000                	addi	s0,sp,32
    80004f7c:	84aa                	mv	s1,a0
    80004f7e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	c66080e7          	jalr	-922(ra) # 80000be6 <acquire>
  if(writable){
    80004f88:	02090d63          	beqz	s2,80004fc2 <pipeclose+0x52>
    pi->writeopen = 0;
    80004f8c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f90:	21848513          	addi	a0,s1,536
    80004f94:	ffffd097          	auipc	ra,0xffffd
    80004f98:	4fa080e7          	jalr	1274(ra) # 8000248e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f9c:	2204b783          	ld	a5,544(s1)
    80004fa0:	eb95                	bnez	a5,80004fd4 <pipeclose+0x64>
    release(&pi->lock);
    80004fa2:	8526                	mv	a0,s1
    80004fa4:	ffffc097          	auipc	ra,0xffffc
    80004fa8:	cf6080e7          	jalr	-778(ra) # 80000c9a <release>
    kfree((char*)pi);
    80004fac:	8526                	mv	a0,s1
    80004fae:	ffffc097          	auipc	ra,0xffffc
    80004fb2:	a4c080e7          	jalr	-1460(ra) # 800009fa <kfree>
  } else
    release(&pi->lock);
}
    80004fb6:	60e2                	ld	ra,24(sp)
    80004fb8:	6442                	ld	s0,16(sp)
    80004fba:	64a2                	ld	s1,8(sp)
    80004fbc:	6902                	ld	s2,0(sp)
    80004fbe:	6105                	addi	sp,sp,32
    80004fc0:	8082                	ret
    pi->readopen = 0;
    80004fc2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004fc6:	21c48513          	addi	a0,s1,540
    80004fca:	ffffd097          	auipc	ra,0xffffd
    80004fce:	4c4080e7          	jalr	1220(ra) # 8000248e <wakeup>
    80004fd2:	b7e9                	j	80004f9c <pipeclose+0x2c>
    release(&pi->lock);
    80004fd4:	8526                	mv	a0,s1
    80004fd6:	ffffc097          	auipc	ra,0xffffc
    80004fda:	cc4080e7          	jalr	-828(ra) # 80000c9a <release>
}
    80004fde:	bfe1                	j	80004fb6 <pipeclose+0x46>

0000000080004fe0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004fe0:	7159                	addi	sp,sp,-112
    80004fe2:	f486                	sd	ra,104(sp)
    80004fe4:	f0a2                	sd	s0,96(sp)
    80004fe6:	eca6                	sd	s1,88(sp)
    80004fe8:	e8ca                	sd	s2,80(sp)
    80004fea:	e4ce                	sd	s3,72(sp)
    80004fec:	e0d2                	sd	s4,64(sp)
    80004fee:	fc56                	sd	s5,56(sp)
    80004ff0:	f85a                	sd	s6,48(sp)
    80004ff2:	f45e                	sd	s7,40(sp)
    80004ff4:	f062                	sd	s8,32(sp)
    80004ff6:	ec66                	sd	s9,24(sp)
    80004ff8:	1880                	addi	s0,sp,112
    80004ffa:	84aa                	mv	s1,a0
    80004ffc:	8aae                	mv	s5,a1
    80004ffe:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005000:	ffffd097          	auipc	ra,0xffffd
    80005004:	9f2080e7          	jalr	-1550(ra) # 800019f2 <myproc>
    80005008:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000500a:	8526                	mv	a0,s1
    8000500c:	ffffc097          	auipc	ra,0xffffc
    80005010:	bda080e7          	jalr	-1062(ra) # 80000be6 <acquire>
  while(i < n){
    80005014:	0d405263          	blez	s4,800050d8 <pipewrite+0xf8>
    80005018:	8ba6                	mv	s7,s1
  int i = 0;
    8000501a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000501c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000501e:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005022:	21c48c13          	addi	s8,s1,540
    80005026:	a08d                	j	80005088 <pipewrite+0xa8>
      release(&pi->lock);
    80005028:	8526                	mv	a0,s1
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	c70080e7          	jalr	-912(ra) # 80000c9a <release>
      return -1;
    80005032:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005034:	854a                	mv	a0,s2
    80005036:	70a6                	ld	ra,104(sp)
    80005038:	7406                	ld	s0,96(sp)
    8000503a:	64e6                	ld	s1,88(sp)
    8000503c:	6946                	ld	s2,80(sp)
    8000503e:	69a6                	ld	s3,72(sp)
    80005040:	6a06                	ld	s4,64(sp)
    80005042:	7ae2                	ld	s5,56(sp)
    80005044:	7b42                	ld	s6,48(sp)
    80005046:	7ba2                	ld	s7,40(sp)
    80005048:	7c02                	ld	s8,32(sp)
    8000504a:	6ce2                	ld	s9,24(sp)
    8000504c:	6165                	addi	sp,sp,112
    8000504e:	8082                	ret
      wakeup(&pi->nread);
    80005050:	8566                	mv	a0,s9
    80005052:	ffffd097          	auipc	ra,0xffffd
    80005056:	43c080e7          	jalr	1084(ra) # 8000248e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000505a:	85de                	mv	a1,s7
    8000505c:	8562                	mv	a0,s8
    8000505e:	ffffd097          	auipc	ra,0xffffd
    80005062:	24a080e7          	jalr	586(ra) # 800022a8 <sleep>
    80005066:	a839                	j	80005084 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005068:	21c4a783          	lw	a5,540(s1)
    8000506c:	0017871b          	addiw	a4,a5,1
    80005070:	20e4ae23          	sw	a4,540(s1)
    80005074:	1ff7f793          	andi	a5,a5,511
    80005078:	97a6                	add	a5,a5,s1
    8000507a:	f9f44703          	lbu	a4,-97(s0)
    8000507e:	00e78c23          	sb	a4,24(a5)
      i++;
    80005082:	2905                	addiw	s2,s2,1
  while(i < n){
    80005084:	03495e63          	bge	s2,s4,800050c0 <pipewrite+0xe0>
    if(pi->readopen == 0 || pr->killed){
    80005088:	2204a783          	lw	a5,544(s1)
    8000508c:	dfd1                	beqz	a5,80005028 <pipewrite+0x48>
    8000508e:	0289a783          	lw	a5,40(s3)
    80005092:	2781                	sext.w	a5,a5
    80005094:	fbd1                	bnez	a5,80005028 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005096:	2184a783          	lw	a5,536(s1)
    8000509a:	21c4a703          	lw	a4,540(s1)
    8000509e:	2007879b          	addiw	a5,a5,512
    800050a2:	faf707e3          	beq	a4,a5,80005050 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050a6:	4685                	li	a3,1
    800050a8:	01590633          	add	a2,s2,s5
    800050ac:	f9f40593          	addi	a1,s0,-97
    800050b0:	0509b503          	ld	a0,80(s3)
    800050b4:	ffffc097          	auipc	ra,0xffffc
    800050b8:	64c080e7          	jalr	1612(ra) # 80001700 <copyin>
    800050bc:	fb6516e3          	bne	a0,s6,80005068 <pipewrite+0x88>
  wakeup(&pi->nread);
    800050c0:	21848513          	addi	a0,s1,536
    800050c4:	ffffd097          	auipc	ra,0xffffd
    800050c8:	3ca080e7          	jalr	970(ra) # 8000248e <wakeup>
  release(&pi->lock);
    800050cc:	8526                	mv	a0,s1
    800050ce:	ffffc097          	auipc	ra,0xffffc
    800050d2:	bcc080e7          	jalr	-1076(ra) # 80000c9a <release>
  return i;
    800050d6:	bfb9                	j	80005034 <pipewrite+0x54>
  int i = 0;
    800050d8:	4901                	li	s2,0
    800050da:	b7dd                	j	800050c0 <pipewrite+0xe0>

00000000800050dc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800050dc:	715d                	addi	sp,sp,-80
    800050de:	e486                	sd	ra,72(sp)
    800050e0:	e0a2                	sd	s0,64(sp)
    800050e2:	fc26                	sd	s1,56(sp)
    800050e4:	f84a                	sd	s2,48(sp)
    800050e6:	f44e                	sd	s3,40(sp)
    800050e8:	f052                	sd	s4,32(sp)
    800050ea:	ec56                	sd	s5,24(sp)
    800050ec:	e85a                	sd	s6,16(sp)
    800050ee:	0880                	addi	s0,sp,80
    800050f0:	84aa                	mv	s1,a0
    800050f2:	892e                	mv	s2,a1
    800050f4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050f6:	ffffd097          	auipc	ra,0xffffd
    800050fa:	8fc080e7          	jalr	-1796(ra) # 800019f2 <myproc>
    800050fe:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005100:	8b26                	mv	s6,s1
    80005102:	8526                	mv	a0,s1
    80005104:	ffffc097          	auipc	ra,0xffffc
    80005108:	ae2080e7          	jalr	-1310(ra) # 80000be6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000510c:	2184a703          	lw	a4,536(s1)
    80005110:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005114:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005118:	02f71563          	bne	a4,a5,80005142 <piperead+0x66>
    8000511c:	2244a783          	lw	a5,548(s1)
    80005120:	c38d                	beqz	a5,80005142 <piperead+0x66>
    if(pr->killed){
    80005122:	028a2783          	lw	a5,40(s4)
    80005126:	2781                	sext.w	a5,a5
    80005128:	ebc1                	bnez	a5,800051b8 <piperead+0xdc>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000512a:	85da                	mv	a1,s6
    8000512c:	854e                	mv	a0,s3
    8000512e:	ffffd097          	auipc	ra,0xffffd
    80005132:	17a080e7          	jalr	378(ra) # 800022a8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005136:	2184a703          	lw	a4,536(s1)
    8000513a:	21c4a783          	lw	a5,540(s1)
    8000513e:	fcf70fe3          	beq	a4,a5,8000511c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005142:	09505263          	blez	s5,800051c6 <piperead+0xea>
    80005146:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005148:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    8000514a:	2184a783          	lw	a5,536(s1)
    8000514e:	21c4a703          	lw	a4,540(s1)
    80005152:	02f70d63          	beq	a4,a5,8000518c <piperead+0xb0>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005156:	0017871b          	addiw	a4,a5,1
    8000515a:	20e4ac23          	sw	a4,536(s1)
    8000515e:	1ff7f793          	andi	a5,a5,511
    80005162:	97a6                	add	a5,a5,s1
    80005164:	0187c783          	lbu	a5,24(a5)
    80005168:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000516c:	4685                	li	a3,1
    8000516e:	fbf40613          	addi	a2,s0,-65
    80005172:	85ca                	mv	a1,s2
    80005174:	050a3503          	ld	a0,80(s4)
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	4fc080e7          	jalr	1276(ra) # 80001674 <copyout>
    80005180:	01650663          	beq	a0,s6,8000518c <piperead+0xb0>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005184:	2985                	addiw	s3,s3,1
    80005186:	0905                	addi	s2,s2,1
    80005188:	fd3a91e3          	bne	s5,s3,8000514a <piperead+0x6e>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000518c:	21c48513          	addi	a0,s1,540
    80005190:	ffffd097          	auipc	ra,0xffffd
    80005194:	2fe080e7          	jalr	766(ra) # 8000248e <wakeup>
  release(&pi->lock);
    80005198:	8526                	mv	a0,s1
    8000519a:	ffffc097          	auipc	ra,0xffffc
    8000519e:	b00080e7          	jalr	-1280(ra) # 80000c9a <release>
  return i;
}
    800051a2:	854e                	mv	a0,s3
    800051a4:	60a6                	ld	ra,72(sp)
    800051a6:	6406                	ld	s0,64(sp)
    800051a8:	74e2                	ld	s1,56(sp)
    800051aa:	7942                	ld	s2,48(sp)
    800051ac:	79a2                	ld	s3,40(sp)
    800051ae:	7a02                	ld	s4,32(sp)
    800051b0:	6ae2                	ld	s5,24(sp)
    800051b2:	6b42                	ld	s6,16(sp)
    800051b4:	6161                	addi	sp,sp,80
    800051b6:	8082                	ret
      release(&pi->lock);
    800051b8:	8526                	mv	a0,s1
    800051ba:	ffffc097          	auipc	ra,0xffffc
    800051be:	ae0080e7          	jalr	-1312(ra) # 80000c9a <release>
      return -1;
    800051c2:	59fd                	li	s3,-1
    800051c4:	bff9                	j	800051a2 <piperead+0xc6>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051c6:	4981                	li	s3,0
    800051c8:	b7d1                	j	8000518c <piperead+0xb0>

00000000800051ca <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800051ca:	df010113          	addi	sp,sp,-528
    800051ce:	20113423          	sd	ra,520(sp)
    800051d2:	20813023          	sd	s0,512(sp)
    800051d6:	ffa6                	sd	s1,504(sp)
    800051d8:	fbca                	sd	s2,496(sp)
    800051da:	f7ce                	sd	s3,488(sp)
    800051dc:	f3d2                	sd	s4,480(sp)
    800051de:	efd6                	sd	s5,472(sp)
    800051e0:	ebda                	sd	s6,464(sp)
    800051e2:	e7de                	sd	s7,456(sp)
    800051e4:	e3e2                	sd	s8,448(sp)
    800051e6:	ff66                	sd	s9,440(sp)
    800051e8:	fb6a                	sd	s10,432(sp)
    800051ea:	f76e                	sd	s11,424(sp)
    800051ec:	0c00                	addi	s0,sp,528
    800051ee:	84aa                	mv	s1,a0
    800051f0:	dea43c23          	sd	a0,-520(s0)
    800051f4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051f8:	ffffc097          	auipc	ra,0xffffc
    800051fc:	7fa080e7          	jalr	2042(ra) # 800019f2 <myproc>
    80005200:	892a                	mv	s2,a0

  begin_op();
    80005202:	fffff097          	auipc	ra,0xfffff
    80005206:	498080e7          	jalr	1176(ra) # 8000469a <begin_op>

  if((ip = namei(path)) == 0){
    8000520a:	8526                	mv	a0,s1
    8000520c:	fffff097          	auipc	ra,0xfffff
    80005210:	272080e7          	jalr	626(ra) # 8000447e <namei>
    80005214:	c92d                	beqz	a0,80005286 <exec+0xbc>
    80005216:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005218:	fffff097          	auipc	ra,0xfffff
    8000521c:	ab0080e7          	jalr	-1360(ra) # 80003cc8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005220:	04000713          	li	a4,64
    80005224:	4681                	li	a3,0
    80005226:	e5040613          	addi	a2,s0,-432
    8000522a:	4581                	li	a1,0
    8000522c:	8526                	mv	a0,s1
    8000522e:	fffff097          	auipc	ra,0xfffff
    80005232:	d4e080e7          	jalr	-690(ra) # 80003f7c <readi>
    80005236:	04000793          	li	a5,64
    8000523a:	00f51a63          	bne	a0,a5,8000524e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    8000523e:	e5042703          	lw	a4,-432(s0)
    80005242:	464c47b7          	lui	a5,0x464c4
    80005246:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000524a:	04f70463          	beq	a4,a5,80005292 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000524e:	8526                	mv	a0,s1
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	cda080e7          	jalr	-806(ra) # 80003f2a <iunlockput>
    end_op();
    80005258:	fffff097          	auipc	ra,0xfffff
    8000525c:	4c2080e7          	jalr	1218(ra) # 8000471a <end_op>
  }
  return -1;
    80005260:	557d                	li	a0,-1
}
    80005262:	20813083          	ld	ra,520(sp)
    80005266:	20013403          	ld	s0,512(sp)
    8000526a:	74fe                	ld	s1,504(sp)
    8000526c:	795e                	ld	s2,496(sp)
    8000526e:	79be                	ld	s3,488(sp)
    80005270:	7a1e                	ld	s4,480(sp)
    80005272:	6afe                	ld	s5,472(sp)
    80005274:	6b5e                	ld	s6,464(sp)
    80005276:	6bbe                	ld	s7,456(sp)
    80005278:	6c1e                	ld	s8,448(sp)
    8000527a:	7cfa                	ld	s9,440(sp)
    8000527c:	7d5a                	ld	s10,432(sp)
    8000527e:	7dba                	ld	s11,424(sp)
    80005280:	21010113          	addi	sp,sp,528
    80005284:	8082                	ret
    end_op();
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	494080e7          	jalr	1172(ra) # 8000471a <end_op>
    return -1;
    8000528e:	557d                	li	a0,-1
    80005290:	bfc9                	j	80005262 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005292:	854a                	mv	a0,s2
    80005294:	ffffd097          	auipc	ra,0xffffd
    80005298:	822080e7          	jalr	-2014(ra) # 80001ab6 <proc_pagetable>
    8000529c:	8baa                	mv	s7,a0
    8000529e:	d945                	beqz	a0,8000524e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052a0:	e7042983          	lw	s3,-400(s0)
    800052a4:	e8845783          	lhu	a5,-376(s0)
    800052a8:	c7ad                	beqz	a5,80005312 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052aa:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052ac:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    800052ae:	6c85                	lui	s9,0x1
    800052b0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800052b4:	def43823          	sd	a5,-528(s0)
    800052b8:	a42d                	j	800054e2 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800052ba:	00003517          	auipc	a0,0x3
    800052be:	55e50513          	addi	a0,a0,1374 # 80008818 <syscalls+0x298>
    800052c2:	ffffb097          	auipc	ra,0xffffb
    800052c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800052ca:	8756                	mv	a4,s5
    800052cc:	012d86bb          	addw	a3,s11,s2
    800052d0:	4581                	li	a1,0
    800052d2:	8526                	mv	a0,s1
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	ca8080e7          	jalr	-856(ra) # 80003f7c <readi>
    800052dc:	2501                	sext.w	a0,a0
    800052de:	1aaa9963          	bne	s5,a0,80005490 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800052e2:	6785                	lui	a5,0x1
    800052e4:	0127893b          	addw	s2,a5,s2
    800052e8:	77fd                	lui	a5,0xfffff
    800052ea:	01478a3b          	addw	s4,a5,s4
    800052ee:	1f897163          	bgeu	s2,s8,800054d0 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800052f2:	02091593          	slli	a1,s2,0x20
    800052f6:	9181                	srli	a1,a1,0x20
    800052f8:	95ea                	add	a1,a1,s10
    800052fa:	855e                	mv	a0,s7
    800052fc:	ffffc097          	auipc	ra,0xffffc
    80005300:	d74080e7          	jalr	-652(ra) # 80001070 <walkaddr>
    80005304:	862a                	mv	a2,a0
    if(pa == 0)
    80005306:	d955                	beqz	a0,800052ba <exec+0xf0>
      n = PGSIZE;
    80005308:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    8000530a:	fd9a70e3          	bgeu	s4,s9,800052ca <exec+0x100>
      n = sz - i;
    8000530e:	8ad2                	mv	s5,s4
    80005310:	bf6d                	j	800052ca <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005312:	4901                	li	s2,0
  iunlockput(ip);
    80005314:	8526                	mv	a0,s1
    80005316:	fffff097          	auipc	ra,0xfffff
    8000531a:	c14080e7          	jalr	-1004(ra) # 80003f2a <iunlockput>
  end_op();
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	3fc080e7          	jalr	1020(ra) # 8000471a <end_op>
  p = myproc();
    80005326:	ffffc097          	auipc	ra,0xffffc
    8000532a:	6cc080e7          	jalr	1740(ra) # 800019f2 <myproc>
    8000532e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005330:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005334:	6785                	lui	a5,0x1
    80005336:	17fd                	addi	a5,a5,-1
    80005338:	993e                	add	s2,s2,a5
    8000533a:	757d                	lui	a0,0xfffff
    8000533c:	00a977b3          	and	a5,s2,a0
    80005340:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005344:	6609                	lui	a2,0x2
    80005346:	963e                	add	a2,a2,a5
    80005348:	85be                	mv	a1,a5
    8000534a:	855e                	mv	a0,s7
    8000534c:	ffffc097          	auipc	ra,0xffffc
    80005350:	0d8080e7          	jalr	216(ra) # 80001424 <uvmalloc>
    80005354:	8b2a                	mv	s6,a0
  ip = 0;
    80005356:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005358:	12050c63          	beqz	a0,80005490 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000535c:	75f9                	lui	a1,0xffffe
    8000535e:	95aa                	add	a1,a1,a0
    80005360:	855e                	mv	a0,s7
    80005362:	ffffc097          	auipc	ra,0xffffc
    80005366:	2e0080e7          	jalr	736(ra) # 80001642 <uvmclear>
  stackbase = sp - PGSIZE;
    8000536a:	7c7d                	lui	s8,0xfffff
    8000536c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000536e:	e0043783          	ld	a5,-512(s0)
    80005372:	6388                	ld	a0,0(a5)
    80005374:	c535                	beqz	a0,800053e0 <exec+0x216>
    80005376:	e9040993          	addi	s3,s0,-368
    8000537a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000537e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005380:	ffffc097          	auipc	ra,0xffffc
    80005384:	ae6080e7          	jalr	-1306(ra) # 80000e66 <strlen>
    80005388:	2505                	addiw	a0,a0,1
    8000538a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000538e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005392:	13896363          	bltu	s2,s8,800054b8 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005396:	e0043d83          	ld	s11,-512(s0)
    8000539a:	000dba03          	ld	s4,0(s11)
    8000539e:	8552                	mv	a0,s4
    800053a0:	ffffc097          	auipc	ra,0xffffc
    800053a4:	ac6080e7          	jalr	-1338(ra) # 80000e66 <strlen>
    800053a8:	0015069b          	addiw	a3,a0,1
    800053ac:	8652                	mv	a2,s4
    800053ae:	85ca                	mv	a1,s2
    800053b0:	855e                	mv	a0,s7
    800053b2:	ffffc097          	auipc	ra,0xffffc
    800053b6:	2c2080e7          	jalr	706(ra) # 80001674 <copyout>
    800053ba:	10054363          	bltz	a0,800054c0 <exec+0x2f6>
    ustack[argc] = sp;
    800053be:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800053c2:	0485                	addi	s1,s1,1
    800053c4:	008d8793          	addi	a5,s11,8
    800053c8:	e0f43023          	sd	a5,-512(s0)
    800053cc:	008db503          	ld	a0,8(s11)
    800053d0:	c911                	beqz	a0,800053e4 <exec+0x21a>
    if(argc >= MAXARG)
    800053d2:	09a1                	addi	s3,s3,8
    800053d4:	fb3c96e3          	bne	s9,s3,80005380 <exec+0x1b6>
  sz = sz1;
    800053d8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053dc:	4481                	li	s1,0
    800053de:	a84d                	j	80005490 <exec+0x2c6>
  sp = sz;
    800053e0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800053e2:	4481                	li	s1,0
  ustack[argc] = 0;
    800053e4:	00349793          	slli	a5,s1,0x3
    800053e8:	f9040713          	addi	a4,s0,-112
    800053ec:	97ba                	add	a5,a5,a4
    800053ee:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800053f2:	00148693          	addi	a3,s1,1
    800053f6:	068e                	slli	a3,a3,0x3
    800053f8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800053fc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005400:	01897663          	bgeu	s2,s8,8000540c <exec+0x242>
  sz = sz1;
    80005404:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005408:	4481                	li	s1,0
    8000540a:	a059                	j	80005490 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000540c:	e9040613          	addi	a2,s0,-368
    80005410:	85ca                	mv	a1,s2
    80005412:	855e                	mv	a0,s7
    80005414:	ffffc097          	auipc	ra,0xffffc
    80005418:	260080e7          	jalr	608(ra) # 80001674 <copyout>
    8000541c:	0a054663          	bltz	a0,800054c8 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005420:	058ab783          	ld	a5,88(s5)
    80005424:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005428:	df843783          	ld	a5,-520(s0)
    8000542c:	0007c703          	lbu	a4,0(a5)
    80005430:	cf11                	beqz	a4,8000544c <exec+0x282>
    80005432:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005434:	02f00693          	li	a3,47
    80005438:	a039                	j	80005446 <exec+0x27c>
      last = s+1;
    8000543a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000543e:	0785                	addi	a5,a5,1
    80005440:	fff7c703          	lbu	a4,-1(a5)
    80005444:	c701                	beqz	a4,8000544c <exec+0x282>
    if(*s == '/')
    80005446:	fed71ce3          	bne	a4,a3,8000543e <exec+0x274>
    8000544a:	bfc5                	j	8000543a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    8000544c:	4641                	li	a2,16
    8000544e:	df843583          	ld	a1,-520(s0)
    80005452:	158a8513          	addi	a0,s5,344
    80005456:	ffffc097          	auipc	ra,0xffffc
    8000545a:	9de080e7          	jalr	-1570(ra) # 80000e34 <safestrcpy>
  oldpagetable = p->pagetable;
    8000545e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005462:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005466:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000546a:	058ab783          	ld	a5,88(s5)
    8000546e:	e6843703          	ld	a4,-408(s0)
    80005472:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005474:	058ab783          	ld	a5,88(s5)
    80005478:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000547c:	85ea                	mv	a1,s10
    8000547e:	ffffc097          	auipc	ra,0xffffc
    80005482:	6d4080e7          	jalr	1748(ra) # 80001b52 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005486:	0004851b          	sext.w	a0,s1
    8000548a:	bbe1                	j	80005262 <exec+0x98>
    8000548c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005490:	e0843583          	ld	a1,-504(s0)
    80005494:	855e                	mv	a0,s7
    80005496:	ffffc097          	auipc	ra,0xffffc
    8000549a:	6bc080e7          	jalr	1724(ra) # 80001b52 <proc_freepagetable>
  if(ip){
    8000549e:	da0498e3          	bnez	s1,8000524e <exec+0x84>
  return -1;
    800054a2:	557d                	li	a0,-1
    800054a4:	bb7d                	j	80005262 <exec+0x98>
    800054a6:	e1243423          	sd	s2,-504(s0)
    800054aa:	b7dd                	j	80005490 <exec+0x2c6>
    800054ac:	e1243423          	sd	s2,-504(s0)
    800054b0:	b7c5                	j	80005490 <exec+0x2c6>
    800054b2:	e1243423          	sd	s2,-504(s0)
    800054b6:	bfe9                	j	80005490 <exec+0x2c6>
  sz = sz1;
    800054b8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054bc:	4481                	li	s1,0
    800054be:	bfc9                	j	80005490 <exec+0x2c6>
  sz = sz1;
    800054c0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054c4:	4481                	li	s1,0
    800054c6:	b7e9                	j	80005490 <exec+0x2c6>
  sz = sz1;
    800054c8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800054cc:	4481                	li	s1,0
    800054ce:	b7c9                	j	80005490 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800054d0:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800054d4:	2b05                	addiw	s6,s6,1
    800054d6:	0389899b          	addiw	s3,s3,56
    800054da:	e8845783          	lhu	a5,-376(s0)
    800054de:	e2fb5be3          	bge	s6,a5,80005314 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800054e2:	2981                	sext.w	s3,s3
    800054e4:	03800713          	li	a4,56
    800054e8:	86ce                	mv	a3,s3
    800054ea:	e1840613          	addi	a2,s0,-488
    800054ee:	4581                	li	a1,0
    800054f0:	8526                	mv	a0,s1
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	a8a080e7          	jalr	-1398(ra) # 80003f7c <readi>
    800054fa:	03800793          	li	a5,56
    800054fe:	f8f517e3          	bne	a0,a5,8000548c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005502:	e1842783          	lw	a5,-488(s0)
    80005506:	4705                	li	a4,1
    80005508:	fce796e3          	bne	a5,a4,800054d4 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000550c:	e4043603          	ld	a2,-448(s0)
    80005510:	e3843783          	ld	a5,-456(s0)
    80005514:	f8f669e3          	bltu	a2,a5,800054a6 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005518:	e2843783          	ld	a5,-472(s0)
    8000551c:	963e                	add	a2,a2,a5
    8000551e:	f8f667e3          	bltu	a2,a5,800054ac <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005522:	85ca                	mv	a1,s2
    80005524:	855e                	mv	a0,s7
    80005526:	ffffc097          	auipc	ra,0xffffc
    8000552a:	efe080e7          	jalr	-258(ra) # 80001424 <uvmalloc>
    8000552e:	e0a43423          	sd	a0,-504(s0)
    80005532:	d141                	beqz	a0,800054b2 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    80005534:	e2843d03          	ld	s10,-472(s0)
    80005538:	df043783          	ld	a5,-528(s0)
    8000553c:	00fd77b3          	and	a5,s10,a5
    80005540:	fba1                	bnez	a5,80005490 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005542:	e2042d83          	lw	s11,-480(s0)
    80005546:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000554a:	f80c03e3          	beqz	s8,800054d0 <exec+0x306>
    8000554e:	8a62                	mv	s4,s8
    80005550:	4901                	li	s2,0
    80005552:	b345                	j	800052f2 <exec+0x128>

0000000080005554 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005554:	7179                	addi	sp,sp,-48
    80005556:	f406                	sd	ra,40(sp)
    80005558:	f022                	sd	s0,32(sp)
    8000555a:	ec26                	sd	s1,24(sp)
    8000555c:	e84a                	sd	s2,16(sp)
    8000555e:	1800                	addi	s0,sp,48
    80005560:	892e                	mv	s2,a1
    80005562:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005564:	fdc40593          	addi	a1,s0,-36
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	b88080e7          	jalr	-1144(ra) # 800030f0 <argint>
    80005570:	04054063          	bltz	a0,800055b0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005574:	fdc42703          	lw	a4,-36(s0)
    80005578:	47bd                	li	a5,15
    8000557a:	02e7ed63          	bltu	a5,a4,800055b4 <argfd+0x60>
    8000557e:	ffffc097          	auipc	ra,0xffffc
    80005582:	474080e7          	jalr	1140(ra) # 800019f2 <myproc>
    80005586:	fdc42703          	lw	a4,-36(s0)
    8000558a:	01a70793          	addi	a5,a4,26
    8000558e:	078e                	slli	a5,a5,0x3
    80005590:	953e                	add	a0,a0,a5
    80005592:	611c                	ld	a5,0(a0)
    80005594:	c395                	beqz	a5,800055b8 <argfd+0x64>
    return -1;
  if(pfd)
    80005596:	00090463          	beqz	s2,8000559e <argfd+0x4a>
    *pfd = fd;
    8000559a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000559e:	4501                	li	a0,0
  if(pf)
    800055a0:	c091                	beqz	s1,800055a4 <argfd+0x50>
    *pf = f;
    800055a2:	e09c                	sd	a5,0(s1)
}
    800055a4:	70a2                	ld	ra,40(sp)
    800055a6:	7402                	ld	s0,32(sp)
    800055a8:	64e2                	ld	s1,24(sp)
    800055aa:	6942                	ld	s2,16(sp)
    800055ac:	6145                	addi	sp,sp,48
    800055ae:	8082                	ret
    return -1;
    800055b0:	557d                	li	a0,-1
    800055b2:	bfcd                	j	800055a4 <argfd+0x50>
    return -1;
    800055b4:	557d                	li	a0,-1
    800055b6:	b7fd                	j	800055a4 <argfd+0x50>
    800055b8:	557d                	li	a0,-1
    800055ba:	b7ed                	j	800055a4 <argfd+0x50>

00000000800055bc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800055bc:	1101                	addi	sp,sp,-32
    800055be:	ec06                	sd	ra,24(sp)
    800055c0:	e822                	sd	s0,16(sp)
    800055c2:	e426                	sd	s1,8(sp)
    800055c4:	1000                	addi	s0,sp,32
    800055c6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800055c8:	ffffc097          	auipc	ra,0xffffc
    800055cc:	42a080e7          	jalr	1066(ra) # 800019f2 <myproc>
    800055d0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800055d2:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800055d6:	4501                	li	a0,0
    800055d8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800055da:	6398                	ld	a4,0(a5)
    800055dc:	cb19                	beqz	a4,800055f2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800055de:	2505                	addiw	a0,a0,1
    800055e0:	07a1                	addi	a5,a5,8
    800055e2:	fed51ce3          	bne	a0,a3,800055da <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055e6:	557d                	li	a0,-1
}
    800055e8:	60e2                	ld	ra,24(sp)
    800055ea:	6442                	ld	s0,16(sp)
    800055ec:	64a2                	ld	s1,8(sp)
    800055ee:	6105                	addi	sp,sp,32
    800055f0:	8082                	ret
      p->ofile[fd] = f;
    800055f2:	01a50793          	addi	a5,a0,26
    800055f6:	078e                	slli	a5,a5,0x3
    800055f8:	963e                	add	a2,a2,a5
    800055fa:	e204                	sd	s1,0(a2)
      return fd;
    800055fc:	b7f5                	j	800055e8 <fdalloc+0x2c>

00000000800055fe <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055fe:	715d                	addi	sp,sp,-80
    80005600:	e486                	sd	ra,72(sp)
    80005602:	e0a2                	sd	s0,64(sp)
    80005604:	fc26                	sd	s1,56(sp)
    80005606:	f84a                	sd	s2,48(sp)
    80005608:	f44e                	sd	s3,40(sp)
    8000560a:	f052                	sd	s4,32(sp)
    8000560c:	ec56                	sd	s5,24(sp)
    8000560e:	0880                	addi	s0,sp,80
    80005610:	89ae                	mv	s3,a1
    80005612:	8ab2                	mv	s5,a2
    80005614:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005616:	fb040593          	addi	a1,s0,-80
    8000561a:	fffff097          	auipc	ra,0xfffff
    8000561e:	e82080e7          	jalr	-382(ra) # 8000449c <nameiparent>
    80005622:	892a                	mv	s2,a0
    80005624:	12050f63          	beqz	a0,80005762 <create+0x164>
    return 0;

  ilock(dp);
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	6a0080e7          	jalr	1696(ra) # 80003cc8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005630:	4601                	li	a2,0
    80005632:	fb040593          	addi	a1,s0,-80
    80005636:	854a                	mv	a0,s2
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	b74080e7          	jalr	-1164(ra) # 800041ac <dirlookup>
    80005640:	84aa                	mv	s1,a0
    80005642:	c921                	beqz	a0,80005692 <create+0x94>
    iunlockput(dp);
    80005644:	854a                	mv	a0,s2
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	8e4080e7          	jalr	-1820(ra) # 80003f2a <iunlockput>
    ilock(ip);
    8000564e:	8526                	mv	a0,s1
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	678080e7          	jalr	1656(ra) # 80003cc8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005658:	2981                	sext.w	s3,s3
    8000565a:	4789                	li	a5,2
    8000565c:	02f99463          	bne	s3,a5,80005684 <create+0x86>
    80005660:	0444d783          	lhu	a5,68(s1)
    80005664:	37f9                	addiw	a5,a5,-2
    80005666:	17c2                	slli	a5,a5,0x30
    80005668:	93c1                	srli	a5,a5,0x30
    8000566a:	4705                	li	a4,1
    8000566c:	00f76c63          	bltu	a4,a5,80005684 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005670:	8526                	mv	a0,s1
    80005672:	60a6                	ld	ra,72(sp)
    80005674:	6406                	ld	s0,64(sp)
    80005676:	74e2                	ld	s1,56(sp)
    80005678:	7942                	ld	s2,48(sp)
    8000567a:	79a2                	ld	s3,40(sp)
    8000567c:	7a02                	ld	s4,32(sp)
    8000567e:	6ae2                	ld	s5,24(sp)
    80005680:	6161                	addi	sp,sp,80
    80005682:	8082                	ret
    iunlockput(ip);
    80005684:	8526                	mv	a0,s1
    80005686:	fffff097          	auipc	ra,0xfffff
    8000568a:	8a4080e7          	jalr	-1884(ra) # 80003f2a <iunlockput>
    return 0;
    8000568e:	4481                	li	s1,0
    80005690:	b7c5                	j	80005670 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005692:	85ce                	mv	a1,s3
    80005694:	00092503          	lw	a0,0(s2)
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	498080e7          	jalr	1176(ra) # 80003b30 <ialloc>
    800056a0:	84aa                	mv	s1,a0
    800056a2:	c529                	beqz	a0,800056ec <create+0xee>
  ilock(ip);
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	624080e7          	jalr	1572(ra) # 80003cc8 <ilock>
  ip->major = major;
    800056ac:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800056b0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800056b4:	4785                	li	a5,1
    800056b6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056ba:	8526                	mv	a0,s1
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	542080e7          	jalr	1346(ra) # 80003bfe <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800056c4:	2981                	sext.w	s3,s3
    800056c6:	4785                	li	a5,1
    800056c8:	02f98a63          	beq	s3,a5,800056fc <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800056cc:	40d0                	lw	a2,4(s1)
    800056ce:	fb040593          	addi	a1,s0,-80
    800056d2:	854a                	mv	a0,s2
    800056d4:	fffff097          	auipc	ra,0xfffff
    800056d8:	ce8080e7          	jalr	-792(ra) # 800043bc <dirlink>
    800056dc:	06054b63          	bltz	a0,80005752 <create+0x154>
  iunlockput(dp);
    800056e0:	854a                	mv	a0,s2
    800056e2:	fffff097          	auipc	ra,0xfffff
    800056e6:	848080e7          	jalr	-1976(ra) # 80003f2a <iunlockput>
  return ip;
    800056ea:	b759                	j	80005670 <create+0x72>
    panic("create: ialloc");
    800056ec:	00003517          	auipc	a0,0x3
    800056f0:	14c50513          	addi	a0,a0,332 # 80008838 <syscalls+0x2b8>
    800056f4:	ffffb097          	auipc	ra,0xffffb
    800056f8:	e4c080e7          	jalr	-436(ra) # 80000540 <panic>
    dp->nlink++;  // for ".."
    800056fc:	04a95783          	lhu	a5,74(s2)
    80005700:	2785                	addiw	a5,a5,1
    80005702:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005706:	854a                	mv	a0,s2
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	4f6080e7          	jalr	1270(ra) # 80003bfe <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005710:	40d0                	lw	a2,4(s1)
    80005712:	00003597          	auipc	a1,0x3
    80005716:	13658593          	addi	a1,a1,310 # 80008848 <syscalls+0x2c8>
    8000571a:	8526                	mv	a0,s1
    8000571c:	fffff097          	auipc	ra,0xfffff
    80005720:	ca0080e7          	jalr	-864(ra) # 800043bc <dirlink>
    80005724:	00054f63          	bltz	a0,80005742 <create+0x144>
    80005728:	00492603          	lw	a2,4(s2)
    8000572c:	00003597          	auipc	a1,0x3
    80005730:	12458593          	addi	a1,a1,292 # 80008850 <syscalls+0x2d0>
    80005734:	8526                	mv	a0,s1
    80005736:	fffff097          	auipc	ra,0xfffff
    8000573a:	c86080e7          	jalr	-890(ra) # 800043bc <dirlink>
    8000573e:	f80557e3          	bgez	a0,800056cc <create+0xce>
      panic("create dots");
    80005742:	00003517          	auipc	a0,0x3
    80005746:	11650513          	addi	a0,a0,278 # 80008858 <syscalls+0x2d8>
    8000574a:	ffffb097          	auipc	ra,0xffffb
    8000574e:	df6080e7          	jalr	-522(ra) # 80000540 <panic>
    panic("create: dirlink");
    80005752:	00003517          	auipc	a0,0x3
    80005756:	11650513          	addi	a0,a0,278 # 80008868 <syscalls+0x2e8>
    8000575a:	ffffb097          	auipc	ra,0xffffb
    8000575e:	de6080e7          	jalr	-538(ra) # 80000540 <panic>
    return 0;
    80005762:	84aa                	mv	s1,a0
    80005764:	b731                	j	80005670 <create+0x72>

0000000080005766 <sys_dup>:
{
    80005766:	7179                	addi	sp,sp,-48
    80005768:	f406                	sd	ra,40(sp)
    8000576a:	f022                	sd	s0,32(sp)
    8000576c:	ec26                	sd	s1,24(sp)
    8000576e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005770:	fd840613          	addi	a2,s0,-40
    80005774:	4581                	li	a1,0
    80005776:	4501                	li	a0,0
    80005778:	00000097          	auipc	ra,0x0
    8000577c:	ddc080e7          	jalr	-548(ra) # 80005554 <argfd>
    return -1;
    80005780:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005782:	02054363          	bltz	a0,800057a8 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005786:	fd843503          	ld	a0,-40(s0)
    8000578a:	00000097          	auipc	ra,0x0
    8000578e:	e32080e7          	jalr	-462(ra) # 800055bc <fdalloc>
    80005792:	84aa                	mv	s1,a0
    return -1;
    80005794:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005796:	00054963          	bltz	a0,800057a8 <sys_dup+0x42>
  filedup(f);
    8000579a:	fd843503          	ld	a0,-40(s0)
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	376080e7          	jalr	886(ra) # 80004b14 <filedup>
  return fd;
    800057a6:	87a6                	mv	a5,s1
}
    800057a8:	853e                	mv	a0,a5
    800057aa:	70a2                	ld	ra,40(sp)
    800057ac:	7402                	ld	s0,32(sp)
    800057ae:	64e2                	ld	s1,24(sp)
    800057b0:	6145                	addi	sp,sp,48
    800057b2:	8082                	ret

00000000800057b4 <sys_read>:
{
    800057b4:	7179                	addi	sp,sp,-48
    800057b6:	f406                	sd	ra,40(sp)
    800057b8:	f022                	sd	s0,32(sp)
    800057ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057bc:	fe840613          	addi	a2,s0,-24
    800057c0:	4581                	li	a1,0
    800057c2:	4501                	li	a0,0
    800057c4:	00000097          	auipc	ra,0x0
    800057c8:	d90080e7          	jalr	-624(ra) # 80005554 <argfd>
    return -1;
    800057cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057ce:	04054163          	bltz	a0,80005810 <sys_read+0x5c>
    800057d2:	fe440593          	addi	a1,s0,-28
    800057d6:	4509                	li	a0,2
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	918080e7          	jalr	-1768(ra) # 800030f0 <argint>
    return -1;
    800057e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057e2:	02054763          	bltz	a0,80005810 <sys_read+0x5c>
    800057e6:	fd840593          	addi	a1,s0,-40
    800057ea:	4505                	li	a0,1
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	926080e7          	jalr	-1754(ra) # 80003112 <argaddr>
    return -1;
    800057f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800057f6:	00054d63          	bltz	a0,80005810 <sys_read+0x5c>
  return fileread(f, p, n);
    800057fa:	fe442603          	lw	a2,-28(s0)
    800057fe:	fd843583          	ld	a1,-40(s0)
    80005802:	fe843503          	ld	a0,-24(s0)
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	49a080e7          	jalr	1178(ra) # 80004ca0 <fileread>
    8000580e:	87aa                	mv	a5,a0
}
    80005810:	853e                	mv	a0,a5
    80005812:	70a2                	ld	ra,40(sp)
    80005814:	7402                	ld	s0,32(sp)
    80005816:	6145                	addi	sp,sp,48
    80005818:	8082                	ret

000000008000581a <sys_write>:
{
    8000581a:	7179                	addi	sp,sp,-48
    8000581c:	f406                	sd	ra,40(sp)
    8000581e:	f022                	sd	s0,32(sp)
    80005820:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005822:	fe840613          	addi	a2,s0,-24
    80005826:	4581                	li	a1,0
    80005828:	4501                	li	a0,0
    8000582a:	00000097          	auipc	ra,0x0
    8000582e:	d2a080e7          	jalr	-726(ra) # 80005554 <argfd>
    return -1;
    80005832:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005834:	04054163          	bltz	a0,80005876 <sys_write+0x5c>
    80005838:	fe440593          	addi	a1,s0,-28
    8000583c:	4509                	li	a0,2
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	8b2080e7          	jalr	-1870(ra) # 800030f0 <argint>
    return -1;
    80005846:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005848:	02054763          	bltz	a0,80005876 <sys_write+0x5c>
    8000584c:	fd840593          	addi	a1,s0,-40
    80005850:	4505                	li	a0,1
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	8c0080e7          	jalr	-1856(ra) # 80003112 <argaddr>
    return -1;
    8000585a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000585c:	00054d63          	bltz	a0,80005876 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005860:	fe442603          	lw	a2,-28(s0)
    80005864:	fd843583          	ld	a1,-40(s0)
    80005868:	fe843503          	ld	a0,-24(s0)
    8000586c:	fffff097          	auipc	ra,0xfffff
    80005870:	4f6080e7          	jalr	1270(ra) # 80004d62 <filewrite>
    80005874:	87aa                	mv	a5,a0
}
    80005876:	853e                	mv	a0,a5
    80005878:	70a2                	ld	ra,40(sp)
    8000587a:	7402                	ld	s0,32(sp)
    8000587c:	6145                	addi	sp,sp,48
    8000587e:	8082                	ret

0000000080005880 <sys_close>:
{
    80005880:	1101                	addi	sp,sp,-32
    80005882:	ec06                	sd	ra,24(sp)
    80005884:	e822                	sd	s0,16(sp)
    80005886:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005888:	fe040613          	addi	a2,s0,-32
    8000588c:	fec40593          	addi	a1,s0,-20
    80005890:	4501                	li	a0,0
    80005892:	00000097          	auipc	ra,0x0
    80005896:	cc2080e7          	jalr	-830(ra) # 80005554 <argfd>
    return -1;
    8000589a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000589c:	02054463          	bltz	a0,800058c4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800058a0:	ffffc097          	auipc	ra,0xffffc
    800058a4:	152080e7          	jalr	338(ra) # 800019f2 <myproc>
    800058a8:	fec42783          	lw	a5,-20(s0)
    800058ac:	07e9                	addi	a5,a5,26
    800058ae:	078e                	slli	a5,a5,0x3
    800058b0:	97aa                	add	a5,a5,a0
    800058b2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800058b6:	fe043503          	ld	a0,-32(s0)
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	2ac080e7          	jalr	684(ra) # 80004b66 <fileclose>
  return 0;
    800058c2:	4781                	li	a5,0
}
    800058c4:	853e                	mv	a0,a5
    800058c6:	60e2                	ld	ra,24(sp)
    800058c8:	6442                	ld	s0,16(sp)
    800058ca:	6105                	addi	sp,sp,32
    800058cc:	8082                	ret

00000000800058ce <sys_fstat>:
{
    800058ce:	1101                	addi	sp,sp,-32
    800058d0:	ec06                	sd	ra,24(sp)
    800058d2:	e822                	sd	s0,16(sp)
    800058d4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058d6:	fe840613          	addi	a2,s0,-24
    800058da:	4581                	li	a1,0
    800058dc:	4501                	li	a0,0
    800058de:	00000097          	auipc	ra,0x0
    800058e2:	c76080e7          	jalr	-906(ra) # 80005554 <argfd>
    return -1;
    800058e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058e8:	02054563          	bltz	a0,80005912 <sys_fstat+0x44>
    800058ec:	fe040593          	addi	a1,s0,-32
    800058f0:	4505                	li	a0,1
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	820080e7          	jalr	-2016(ra) # 80003112 <argaddr>
    return -1;
    800058fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800058fc:	00054b63          	bltz	a0,80005912 <sys_fstat+0x44>
  return filestat(f, st);
    80005900:	fe043583          	ld	a1,-32(s0)
    80005904:	fe843503          	ld	a0,-24(s0)
    80005908:	fffff097          	auipc	ra,0xfffff
    8000590c:	326080e7          	jalr	806(ra) # 80004c2e <filestat>
    80005910:	87aa                	mv	a5,a0
}
    80005912:	853e                	mv	a0,a5
    80005914:	60e2                	ld	ra,24(sp)
    80005916:	6442                	ld	s0,16(sp)
    80005918:	6105                	addi	sp,sp,32
    8000591a:	8082                	ret

000000008000591c <sys_link>:
{
    8000591c:	7169                	addi	sp,sp,-304
    8000591e:	f606                	sd	ra,296(sp)
    80005920:	f222                	sd	s0,288(sp)
    80005922:	ee26                	sd	s1,280(sp)
    80005924:	ea4a                	sd	s2,272(sp)
    80005926:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005928:	08000613          	li	a2,128
    8000592c:	ed040593          	addi	a1,s0,-304
    80005930:	4501                	li	a0,0
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	802080e7          	jalr	-2046(ra) # 80003134 <argstr>
    return -1;
    8000593a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000593c:	10054e63          	bltz	a0,80005a58 <sys_link+0x13c>
    80005940:	08000613          	li	a2,128
    80005944:	f5040593          	addi	a1,s0,-176
    80005948:	4505                	li	a0,1
    8000594a:	ffffd097          	auipc	ra,0xffffd
    8000594e:	7ea080e7          	jalr	2026(ra) # 80003134 <argstr>
    return -1;
    80005952:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005954:	10054263          	bltz	a0,80005a58 <sys_link+0x13c>
  begin_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	d42080e7          	jalr	-702(ra) # 8000469a <begin_op>
  if((ip = namei(old)) == 0){
    80005960:	ed040513          	addi	a0,s0,-304
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	b1a080e7          	jalr	-1254(ra) # 8000447e <namei>
    8000596c:	84aa                	mv	s1,a0
    8000596e:	c551                	beqz	a0,800059fa <sys_link+0xde>
  ilock(ip);
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	358080e7          	jalr	856(ra) # 80003cc8 <ilock>
  if(ip->type == T_DIR){
    80005978:	04449703          	lh	a4,68(s1)
    8000597c:	4785                	li	a5,1
    8000597e:	08f70463          	beq	a4,a5,80005a06 <sys_link+0xea>
  ip->nlink++;
    80005982:	04a4d783          	lhu	a5,74(s1)
    80005986:	2785                	addiw	a5,a5,1
    80005988:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000598c:	8526                	mv	a0,s1
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	270080e7          	jalr	624(ra) # 80003bfe <iupdate>
  iunlock(ip);
    80005996:	8526                	mv	a0,s1
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	3f2080e7          	jalr	1010(ra) # 80003d8a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059a0:	fd040593          	addi	a1,s0,-48
    800059a4:	f5040513          	addi	a0,s0,-176
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	af4080e7          	jalr	-1292(ra) # 8000449c <nameiparent>
    800059b0:	892a                	mv	s2,a0
    800059b2:	c935                	beqz	a0,80005a26 <sys_link+0x10a>
  ilock(dp);
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	314080e7          	jalr	788(ra) # 80003cc8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800059bc:	00092703          	lw	a4,0(s2)
    800059c0:	409c                	lw	a5,0(s1)
    800059c2:	04f71d63          	bne	a4,a5,80005a1c <sys_link+0x100>
    800059c6:	40d0                	lw	a2,4(s1)
    800059c8:	fd040593          	addi	a1,s0,-48
    800059cc:	854a                	mv	a0,s2
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	9ee080e7          	jalr	-1554(ra) # 800043bc <dirlink>
    800059d6:	04054363          	bltz	a0,80005a1c <sys_link+0x100>
  iunlockput(dp);
    800059da:	854a                	mv	a0,s2
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	54e080e7          	jalr	1358(ra) # 80003f2a <iunlockput>
  iput(ip);
    800059e4:	8526                	mv	a0,s1
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	49c080e7          	jalr	1180(ra) # 80003e82 <iput>
  end_op();
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	d2c080e7          	jalr	-724(ra) # 8000471a <end_op>
  return 0;
    800059f6:	4781                	li	a5,0
    800059f8:	a085                	j	80005a58 <sys_link+0x13c>
    end_op();
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	d20080e7          	jalr	-736(ra) # 8000471a <end_op>
    return -1;
    80005a02:	57fd                	li	a5,-1
    80005a04:	a891                	j	80005a58 <sys_link+0x13c>
    iunlockput(ip);
    80005a06:	8526                	mv	a0,s1
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	522080e7          	jalr	1314(ra) # 80003f2a <iunlockput>
    end_op();
    80005a10:	fffff097          	auipc	ra,0xfffff
    80005a14:	d0a080e7          	jalr	-758(ra) # 8000471a <end_op>
    return -1;
    80005a18:	57fd                	li	a5,-1
    80005a1a:	a83d                	j	80005a58 <sys_link+0x13c>
    iunlockput(dp);
    80005a1c:	854a                	mv	a0,s2
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	50c080e7          	jalr	1292(ra) # 80003f2a <iunlockput>
  ilock(ip);
    80005a26:	8526                	mv	a0,s1
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	2a0080e7          	jalr	672(ra) # 80003cc8 <ilock>
  ip->nlink--;
    80005a30:	04a4d783          	lhu	a5,74(s1)
    80005a34:	37fd                	addiw	a5,a5,-1
    80005a36:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a3a:	8526                	mv	a0,s1
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	1c2080e7          	jalr	450(ra) # 80003bfe <iupdate>
  iunlockput(ip);
    80005a44:	8526                	mv	a0,s1
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	4e4080e7          	jalr	1252(ra) # 80003f2a <iunlockput>
  end_op();
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	ccc080e7          	jalr	-820(ra) # 8000471a <end_op>
  return -1;
    80005a56:	57fd                	li	a5,-1
}
    80005a58:	853e                	mv	a0,a5
    80005a5a:	70b2                	ld	ra,296(sp)
    80005a5c:	7412                	ld	s0,288(sp)
    80005a5e:	64f2                	ld	s1,280(sp)
    80005a60:	6952                	ld	s2,272(sp)
    80005a62:	6155                	addi	sp,sp,304
    80005a64:	8082                	ret

0000000080005a66 <sys_unlink>:
{
    80005a66:	7151                	addi	sp,sp,-240
    80005a68:	f586                	sd	ra,232(sp)
    80005a6a:	f1a2                	sd	s0,224(sp)
    80005a6c:	eda6                	sd	s1,216(sp)
    80005a6e:	e9ca                	sd	s2,208(sp)
    80005a70:	e5ce                	sd	s3,200(sp)
    80005a72:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a74:	08000613          	li	a2,128
    80005a78:	f3040593          	addi	a1,s0,-208
    80005a7c:	4501                	li	a0,0
    80005a7e:	ffffd097          	auipc	ra,0xffffd
    80005a82:	6b6080e7          	jalr	1718(ra) # 80003134 <argstr>
    80005a86:	18054163          	bltz	a0,80005c08 <sys_unlink+0x1a2>
  begin_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	c10080e7          	jalr	-1008(ra) # 8000469a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a92:	fb040593          	addi	a1,s0,-80
    80005a96:	f3040513          	addi	a0,s0,-208
    80005a9a:	fffff097          	auipc	ra,0xfffff
    80005a9e:	a02080e7          	jalr	-1534(ra) # 8000449c <nameiparent>
    80005aa2:	84aa                	mv	s1,a0
    80005aa4:	c979                	beqz	a0,80005b7a <sys_unlink+0x114>
  ilock(dp);
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	222080e7          	jalr	546(ra) # 80003cc8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005aae:	00003597          	auipc	a1,0x3
    80005ab2:	d9a58593          	addi	a1,a1,-614 # 80008848 <syscalls+0x2c8>
    80005ab6:	fb040513          	addi	a0,s0,-80
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	6d8080e7          	jalr	1752(ra) # 80004192 <namecmp>
    80005ac2:	14050a63          	beqz	a0,80005c16 <sys_unlink+0x1b0>
    80005ac6:	00003597          	auipc	a1,0x3
    80005aca:	d8a58593          	addi	a1,a1,-630 # 80008850 <syscalls+0x2d0>
    80005ace:	fb040513          	addi	a0,s0,-80
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	6c0080e7          	jalr	1728(ra) # 80004192 <namecmp>
    80005ada:	12050e63          	beqz	a0,80005c16 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005ade:	f2c40613          	addi	a2,s0,-212
    80005ae2:	fb040593          	addi	a1,s0,-80
    80005ae6:	8526                	mv	a0,s1
    80005ae8:	ffffe097          	auipc	ra,0xffffe
    80005aec:	6c4080e7          	jalr	1732(ra) # 800041ac <dirlookup>
    80005af0:	892a                	mv	s2,a0
    80005af2:	12050263          	beqz	a0,80005c16 <sys_unlink+0x1b0>
  ilock(ip);
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	1d2080e7          	jalr	466(ra) # 80003cc8 <ilock>
  if(ip->nlink < 1)
    80005afe:	04a91783          	lh	a5,74(s2)
    80005b02:	08f05263          	blez	a5,80005b86 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b06:	04491703          	lh	a4,68(s2)
    80005b0a:	4785                	li	a5,1
    80005b0c:	08f70563          	beq	a4,a5,80005b96 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b10:	4641                	li	a2,16
    80005b12:	4581                	li	a1,0
    80005b14:	fc040513          	addi	a0,s0,-64
    80005b18:	ffffb097          	auipc	ra,0xffffb
    80005b1c:	1ca080e7          	jalr	458(ra) # 80000ce2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b20:	4741                	li	a4,16
    80005b22:	f2c42683          	lw	a3,-212(s0)
    80005b26:	fc040613          	addi	a2,s0,-64
    80005b2a:	4581                	li	a1,0
    80005b2c:	8526                	mv	a0,s1
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	546080e7          	jalr	1350(ra) # 80004074 <writei>
    80005b36:	47c1                	li	a5,16
    80005b38:	0af51563          	bne	a0,a5,80005be2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b3c:	04491703          	lh	a4,68(s2)
    80005b40:	4785                	li	a5,1
    80005b42:	0af70863          	beq	a4,a5,80005bf2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b46:	8526                	mv	a0,s1
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	3e2080e7          	jalr	994(ra) # 80003f2a <iunlockput>
  ip->nlink--;
    80005b50:	04a95783          	lhu	a5,74(s2)
    80005b54:	37fd                	addiw	a5,a5,-1
    80005b56:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b5a:	854a                	mv	a0,s2
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	0a2080e7          	jalr	162(ra) # 80003bfe <iupdate>
  iunlockput(ip);
    80005b64:	854a                	mv	a0,s2
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	3c4080e7          	jalr	964(ra) # 80003f2a <iunlockput>
  end_op();
    80005b6e:	fffff097          	auipc	ra,0xfffff
    80005b72:	bac080e7          	jalr	-1108(ra) # 8000471a <end_op>
  return 0;
    80005b76:	4501                	li	a0,0
    80005b78:	a84d                	j	80005c2a <sys_unlink+0x1c4>
    end_op();
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	ba0080e7          	jalr	-1120(ra) # 8000471a <end_op>
    return -1;
    80005b82:	557d                	li	a0,-1
    80005b84:	a05d                	j	80005c2a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b86:	00003517          	auipc	a0,0x3
    80005b8a:	cf250513          	addi	a0,a0,-782 # 80008878 <syscalls+0x2f8>
    80005b8e:	ffffb097          	auipc	ra,0xffffb
    80005b92:	9b2080e7          	jalr	-1614(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b96:	04c92703          	lw	a4,76(s2)
    80005b9a:	02000793          	li	a5,32
    80005b9e:	f6e7f9e3          	bgeu	a5,a4,80005b10 <sys_unlink+0xaa>
    80005ba2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ba6:	4741                	li	a4,16
    80005ba8:	86ce                	mv	a3,s3
    80005baa:	f1840613          	addi	a2,s0,-232
    80005bae:	4581                	li	a1,0
    80005bb0:	854a                	mv	a0,s2
    80005bb2:	ffffe097          	auipc	ra,0xffffe
    80005bb6:	3ca080e7          	jalr	970(ra) # 80003f7c <readi>
    80005bba:	47c1                	li	a5,16
    80005bbc:	00f51b63          	bne	a0,a5,80005bd2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005bc0:	f1845783          	lhu	a5,-232(s0)
    80005bc4:	e7a1                	bnez	a5,80005c0c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bc6:	29c1                	addiw	s3,s3,16
    80005bc8:	04c92783          	lw	a5,76(s2)
    80005bcc:	fcf9ede3          	bltu	s3,a5,80005ba6 <sys_unlink+0x140>
    80005bd0:	b781                	j	80005b10 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005bd2:	00003517          	auipc	a0,0x3
    80005bd6:	cbe50513          	addi	a0,a0,-834 # 80008890 <syscalls+0x310>
    80005bda:	ffffb097          	auipc	ra,0xffffb
    80005bde:	966080e7          	jalr	-1690(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005be2:	00003517          	auipc	a0,0x3
    80005be6:	cc650513          	addi	a0,a0,-826 # 800088a8 <syscalls+0x328>
    80005bea:	ffffb097          	auipc	ra,0xffffb
    80005bee:	956080e7          	jalr	-1706(ra) # 80000540 <panic>
    dp->nlink--;
    80005bf2:	04a4d783          	lhu	a5,74(s1)
    80005bf6:	37fd                	addiw	a5,a5,-1
    80005bf8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bfc:	8526                	mv	a0,s1
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	000080e7          	jalr	ra # 80003bfe <iupdate>
    80005c06:	b781                	j	80005b46 <sys_unlink+0xe0>
    return -1;
    80005c08:	557d                	li	a0,-1
    80005c0a:	a005                	j	80005c2a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c0c:	854a                	mv	a0,s2
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	31c080e7          	jalr	796(ra) # 80003f2a <iunlockput>
  iunlockput(dp);
    80005c16:	8526                	mv	a0,s1
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	312080e7          	jalr	786(ra) # 80003f2a <iunlockput>
  end_op();
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	afa080e7          	jalr	-1286(ra) # 8000471a <end_op>
  return -1;
    80005c28:	557d                	li	a0,-1
}
    80005c2a:	70ae                	ld	ra,232(sp)
    80005c2c:	740e                	ld	s0,224(sp)
    80005c2e:	64ee                	ld	s1,216(sp)
    80005c30:	694e                	ld	s2,208(sp)
    80005c32:	69ae                	ld	s3,200(sp)
    80005c34:	616d                	addi	sp,sp,240
    80005c36:	8082                	ret

0000000080005c38 <sys_open>:

uint64
sys_open(void)
{
    80005c38:	7131                	addi	sp,sp,-192
    80005c3a:	fd06                	sd	ra,184(sp)
    80005c3c:	f922                	sd	s0,176(sp)
    80005c3e:	f526                	sd	s1,168(sp)
    80005c40:	f14a                	sd	s2,160(sp)
    80005c42:	ed4e                	sd	s3,152(sp)
    80005c44:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c46:	08000613          	li	a2,128
    80005c4a:	f5040593          	addi	a1,s0,-176
    80005c4e:	4501                	li	a0,0
    80005c50:	ffffd097          	auipc	ra,0xffffd
    80005c54:	4e4080e7          	jalr	1252(ra) # 80003134 <argstr>
    return -1;
    80005c58:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005c5a:	0c054163          	bltz	a0,80005d1c <sys_open+0xe4>
    80005c5e:	f4c40593          	addi	a1,s0,-180
    80005c62:	4505                	li	a0,1
    80005c64:	ffffd097          	auipc	ra,0xffffd
    80005c68:	48c080e7          	jalr	1164(ra) # 800030f0 <argint>
    80005c6c:	0a054863          	bltz	a0,80005d1c <sys_open+0xe4>

  begin_op();
    80005c70:	fffff097          	auipc	ra,0xfffff
    80005c74:	a2a080e7          	jalr	-1494(ra) # 8000469a <begin_op>

  if(omode & O_CREATE){
    80005c78:	f4c42783          	lw	a5,-180(s0)
    80005c7c:	2007f793          	andi	a5,a5,512
    80005c80:	cbdd                	beqz	a5,80005d36 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c82:	4681                	li	a3,0
    80005c84:	4601                	li	a2,0
    80005c86:	4589                	li	a1,2
    80005c88:	f5040513          	addi	a0,s0,-176
    80005c8c:	00000097          	auipc	ra,0x0
    80005c90:	972080e7          	jalr	-1678(ra) # 800055fe <create>
    80005c94:	892a                	mv	s2,a0
    if(ip == 0){
    80005c96:	c959                	beqz	a0,80005d2c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c98:	04491703          	lh	a4,68(s2)
    80005c9c:	478d                	li	a5,3
    80005c9e:	00f71763          	bne	a4,a5,80005cac <sys_open+0x74>
    80005ca2:	04695703          	lhu	a4,70(s2)
    80005ca6:	47a5                	li	a5,9
    80005ca8:	0ce7ec63          	bltu	a5,a4,80005d80 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	dfe080e7          	jalr	-514(ra) # 80004aaa <filealloc>
    80005cb4:	89aa                	mv	s3,a0
    80005cb6:	10050263          	beqz	a0,80005dba <sys_open+0x182>
    80005cba:	00000097          	auipc	ra,0x0
    80005cbe:	902080e7          	jalr	-1790(ra) # 800055bc <fdalloc>
    80005cc2:	84aa                	mv	s1,a0
    80005cc4:	0e054663          	bltz	a0,80005db0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005cc8:	04491703          	lh	a4,68(s2)
    80005ccc:	478d                	li	a5,3
    80005cce:	0cf70463          	beq	a4,a5,80005d96 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005cd2:	4789                	li	a5,2
    80005cd4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005cd8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005cdc:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ce0:	f4c42783          	lw	a5,-180(s0)
    80005ce4:	0017c713          	xori	a4,a5,1
    80005ce8:	8b05                	andi	a4,a4,1
    80005cea:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cee:	0037f713          	andi	a4,a5,3
    80005cf2:	00e03733          	snez	a4,a4
    80005cf6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cfa:	4007f793          	andi	a5,a5,1024
    80005cfe:	c791                	beqz	a5,80005d0a <sys_open+0xd2>
    80005d00:	04491703          	lh	a4,68(s2)
    80005d04:	4789                	li	a5,2
    80005d06:	08f70f63          	beq	a4,a5,80005da4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d0a:	854a                	mv	a0,s2
    80005d0c:	ffffe097          	auipc	ra,0xffffe
    80005d10:	07e080e7          	jalr	126(ra) # 80003d8a <iunlock>
  end_op();
    80005d14:	fffff097          	auipc	ra,0xfffff
    80005d18:	a06080e7          	jalr	-1530(ra) # 8000471a <end_op>

  return fd;
}
    80005d1c:	8526                	mv	a0,s1
    80005d1e:	70ea                	ld	ra,184(sp)
    80005d20:	744a                	ld	s0,176(sp)
    80005d22:	74aa                	ld	s1,168(sp)
    80005d24:	790a                	ld	s2,160(sp)
    80005d26:	69ea                	ld	s3,152(sp)
    80005d28:	6129                	addi	sp,sp,192
    80005d2a:	8082                	ret
      end_op();
    80005d2c:	fffff097          	auipc	ra,0xfffff
    80005d30:	9ee080e7          	jalr	-1554(ra) # 8000471a <end_op>
      return -1;
    80005d34:	b7e5                	j	80005d1c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005d36:	f5040513          	addi	a0,s0,-176
    80005d3a:	ffffe097          	auipc	ra,0xffffe
    80005d3e:	744080e7          	jalr	1860(ra) # 8000447e <namei>
    80005d42:	892a                	mv	s2,a0
    80005d44:	c905                	beqz	a0,80005d74 <sys_open+0x13c>
    ilock(ip);
    80005d46:	ffffe097          	auipc	ra,0xffffe
    80005d4a:	f82080e7          	jalr	-126(ra) # 80003cc8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d4e:	04491703          	lh	a4,68(s2)
    80005d52:	4785                	li	a5,1
    80005d54:	f4f712e3          	bne	a4,a5,80005c98 <sys_open+0x60>
    80005d58:	f4c42783          	lw	a5,-180(s0)
    80005d5c:	dba1                	beqz	a5,80005cac <sys_open+0x74>
      iunlockput(ip);
    80005d5e:	854a                	mv	a0,s2
    80005d60:	ffffe097          	auipc	ra,0xffffe
    80005d64:	1ca080e7          	jalr	458(ra) # 80003f2a <iunlockput>
      end_op();
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	9b2080e7          	jalr	-1614(ra) # 8000471a <end_op>
      return -1;
    80005d70:	54fd                	li	s1,-1
    80005d72:	b76d                	j	80005d1c <sys_open+0xe4>
      end_op();
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	9a6080e7          	jalr	-1626(ra) # 8000471a <end_op>
      return -1;
    80005d7c:	54fd                	li	s1,-1
    80005d7e:	bf79                	j	80005d1c <sys_open+0xe4>
    iunlockput(ip);
    80005d80:	854a                	mv	a0,s2
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	1a8080e7          	jalr	424(ra) # 80003f2a <iunlockput>
    end_op();
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	990080e7          	jalr	-1648(ra) # 8000471a <end_op>
    return -1;
    80005d92:	54fd                	li	s1,-1
    80005d94:	b761                	j	80005d1c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d96:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d9a:	04691783          	lh	a5,70(s2)
    80005d9e:	02f99223          	sh	a5,36(s3)
    80005da2:	bf2d                	j	80005cdc <sys_open+0xa4>
    itrunc(ip);
    80005da4:	854a                	mv	a0,s2
    80005da6:	ffffe097          	auipc	ra,0xffffe
    80005daa:	030080e7          	jalr	48(ra) # 80003dd6 <itrunc>
    80005dae:	bfb1                	j	80005d0a <sys_open+0xd2>
      fileclose(f);
    80005db0:	854e                	mv	a0,s3
    80005db2:	fffff097          	auipc	ra,0xfffff
    80005db6:	db4080e7          	jalr	-588(ra) # 80004b66 <fileclose>
    iunlockput(ip);
    80005dba:	854a                	mv	a0,s2
    80005dbc:	ffffe097          	auipc	ra,0xffffe
    80005dc0:	16e080e7          	jalr	366(ra) # 80003f2a <iunlockput>
    end_op();
    80005dc4:	fffff097          	auipc	ra,0xfffff
    80005dc8:	956080e7          	jalr	-1706(ra) # 8000471a <end_op>
    return -1;
    80005dcc:	54fd                	li	s1,-1
    80005dce:	b7b9                	j	80005d1c <sys_open+0xe4>

0000000080005dd0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005dd0:	7175                	addi	sp,sp,-144
    80005dd2:	e506                	sd	ra,136(sp)
    80005dd4:	e122                	sd	s0,128(sp)
    80005dd6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	8c2080e7          	jalr	-1854(ra) # 8000469a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005de0:	08000613          	li	a2,128
    80005de4:	f7040593          	addi	a1,s0,-144
    80005de8:	4501                	li	a0,0
    80005dea:	ffffd097          	auipc	ra,0xffffd
    80005dee:	34a080e7          	jalr	842(ra) # 80003134 <argstr>
    80005df2:	02054963          	bltz	a0,80005e24 <sys_mkdir+0x54>
    80005df6:	4681                	li	a3,0
    80005df8:	4601                	li	a2,0
    80005dfa:	4585                	li	a1,1
    80005dfc:	f7040513          	addi	a0,s0,-144
    80005e00:	fffff097          	auipc	ra,0xfffff
    80005e04:	7fe080e7          	jalr	2046(ra) # 800055fe <create>
    80005e08:	cd11                	beqz	a0,80005e24 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e0a:	ffffe097          	auipc	ra,0xffffe
    80005e0e:	120080e7          	jalr	288(ra) # 80003f2a <iunlockput>
  end_op();
    80005e12:	fffff097          	auipc	ra,0xfffff
    80005e16:	908080e7          	jalr	-1784(ra) # 8000471a <end_op>
  return 0;
    80005e1a:	4501                	li	a0,0
}
    80005e1c:	60aa                	ld	ra,136(sp)
    80005e1e:	640a                	ld	s0,128(sp)
    80005e20:	6149                	addi	sp,sp,144
    80005e22:	8082                	ret
    end_op();
    80005e24:	fffff097          	auipc	ra,0xfffff
    80005e28:	8f6080e7          	jalr	-1802(ra) # 8000471a <end_op>
    return -1;
    80005e2c:	557d                	li	a0,-1
    80005e2e:	b7fd                	j	80005e1c <sys_mkdir+0x4c>

0000000080005e30 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e30:	7135                	addi	sp,sp,-160
    80005e32:	ed06                	sd	ra,152(sp)
    80005e34:	e922                	sd	s0,144(sp)
    80005e36:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e38:	fffff097          	auipc	ra,0xfffff
    80005e3c:	862080e7          	jalr	-1950(ra) # 8000469a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e40:	08000613          	li	a2,128
    80005e44:	f7040593          	addi	a1,s0,-144
    80005e48:	4501                	li	a0,0
    80005e4a:	ffffd097          	auipc	ra,0xffffd
    80005e4e:	2ea080e7          	jalr	746(ra) # 80003134 <argstr>
    80005e52:	04054a63          	bltz	a0,80005ea6 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005e56:	f6c40593          	addi	a1,s0,-148
    80005e5a:	4505                	li	a0,1
    80005e5c:	ffffd097          	auipc	ra,0xffffd
    80005e60:	294080e7          	jalr	660(ra) # 800030f0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e64:	04054163          	bltz	a0,80005ea6 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005e68:	f6840593          	addi	a1,s0,-152
    80005e6c:	4509                	li	a0,2
    80005e6e:	ffffd097          	auipc	ra,0xffffd
    80005e72:	282080e7          	jalr	642(ra) # 800030f0 <argint>
     argint(1, &major) < 0 ||
    80005e76:	02054863          	bltz	a0,80005ea6 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e7a:	f6841683          	lh	a3,-152(s0)
    80005e7e:	f6c41603          	lh	a2,-148(s0)
    80005e82:	458d                	li	a1,3
    80005e84:	f7040513          	addi	a0,s0,-144
    80005e88:	fffff097          	auipc	ra,0xfffff
    80005e8c:	776080e7          	jalr	1910(ra) # 800055fe <create>
     argint(2, &minor) < 0 ||
    80005e90:	c919                	beqz	a0,80005ea6 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e92:	ffffe097          	auipc	ra,0xffffe
    80005e96:	098080e7          	jalr	152(ra) # 80003f2a <iunlockput>
  end_op();
    80005e9a:	fffff097          	auipc	ra,0xfffff
    80005e9e:	880080e7          	jalr	-1920(ra) # 8000471a <end_op>
  return 0;
    80005ea2:	4501                	li	a0,0
    80005ea4:	a031                	j	80005eb0 <sys_mknod+0x80>
    end_op();
    80005ea6:	fffff097          	auipc	ra,0xfffff
    80005eaa:	874080e7          	jalr	-1932(ra) # 8000471a <end_op>
    return -1;
    80005eae:	557d                	li	a0,-1
}
    80005eb0:	60ea                	ld	ra,152(sp)
    80005eb2:	644a                	ld	s0,144(sp)
    80005eb4:	610d                	addi	sp,sp,160
    80005eb6:	8082                	ret

0000000080005eb8 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005eb8:	7135                	addi	sp,sp,-160
    80005eba:	ed06                	sd	ra,152(sp)
    80005ebc:	e922                	sd	s0,144(sp)
    80005ebe:	e526                	sd	s1,136(sp)
    80005ec0:	e14a                	sd	s2,128(sp)
    80005ec2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ec4:	ffffc097          	auipc	ra,0xffffc
    80005ec8:	b2e080e7          	jalr	-1234(ra) # 800019f2 <myproc>
    80005ecc:	892a                	mv	s2,a0
  
  begin_op();
    80005ece:	ffffe097          	auipc	ra,0xffffe
    80005ed2:	7cc080e7          	jalr	1996(ra) # 8000469a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ed6:	08000613          	li	a2,128
    80005eda:	f6040593          	addi	a1,s0,-160
    80005ede:	4501                	li	a0,0
    80005ee0:	ffffd097          	auipc	ra,0xffffd
    80005ee4:	254080e7          	jalr	596(ra) # 80003134 <argstr>
    80005ee8:	04054b63          	bltz	a0,80005f3e <sys_chdir+0x86>
    80005eec:	f6040513          	addi	a0,s0,-160
    80005ef0:	ffffe097          	auipc	ra,0xffffe
    80005ef4:	58e080e7          	jalr	1422(ra) # 8000447e <namei>
    80005ef8:	84aa                	mv	s1,a0
    80005efa:	c131                	beqz	a0,80005f3e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005efc:	ffffe097          	auipc	ra,0xffffe
    80005f00:	dcc080e7          	jalr	-564(ra) # 80003cc8 <ilock>
  if(ip->type != T_DIR){
    80005f04:	04449703          	lh	a4,68(s1)
    80005f08:	4785                	li	a5,1
    80005f0a:	04f71063          	bne	a4,a5,80005f4a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f0e:	8526                	mv	a0,s1
    80005f10:	ffffe097          	auipc	ra,0xffffe
    80005f14:	e7a080e7          	jalr	-390(ra) # 80003d8a <iunlock>
  iput(p->cwd);
    80005f18:	15093503          	ld	a0,336(s2)
    80005f1c:	ffffe097          	auipc	ra,0xffffe
    80005f20:	f66080e7          	jalr	-154(ra) # 80003e82 <iput>
  end_op();
    80005f24:	ffffe097          	auipc	ra,0xffffe
    80005f28:	7f6080e7          	jalr	2038(ra) # 8000471a <end_op>
  p->cwd = ip;
    80005f2c:	14993823          	sd	s1,336(s2)
  return 0;
    80005f30:	4501                	li	a0,0
}
    80005f32:	60ea                	ld	ra,152(sp)
    80005f34:	644a                	ld	s0,144(sp)
    80005f36:	64aa                	ld	s1,136(sp)
    80005f38:	690a                	ld	s2,128(sp)
    80005f3a:	610d                	addi	sp,sp,160
    80005f3c:	8082                	ret
    end_op();
    80005f3e:	ffffe097          	auipc	ra,0xffffe
    80005f42:	7dc080e7          	jalr	2012(ra) # 8000471a <end_op>
    return -1;
    80005f46:	557d                	li	a0,-1
    80005f48:	b7ed                	j	80005f32 <sys_chdir+0x7a>
    iunlockput(ip);
    80005f4a:	8526                	mv	a0,s1
    80005f4c:	ffffe097          	auipc	ra,0xffffe
    80005f50:	fde080e7          	jalr	-34(ra) # 80003f2a <iunlockput>
    end_op();
    80005f54:	ffffe097          	auipc	ra,0xffffe
    80005f58:	7c6080e7          	jalr	1990(ra) # 8000471a <end_op>
    return -1;
    80005f5c:	557d                	li	a0,-1
    80005f5e:	bfd1                	j	80005f32 <sys_chdir+0x7a>

0000000080005f60 <sys_exec>:

uint64
sys_exec(void)
{
    80005f60:	7145                	addi	sp,sp,-464
    80005f62:	e786                	sd	ra,456(sp)
    80005f64:	e3a2                	sd	s0,448(sp)
    80005f66:	ff26                	sd	s1,440(sp)
    80005f68:	fb4a                	sd	s2,432(sp)
    80005f6a:	f74e                	sd	s3,424(sp)
    80005f6c:	f352                	sd	s4,416(sp)
    80005f6e:	ef56                	sd	s5,408(sp)
    80005f70:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f72:	08000613          	li	a2,128
    80005f76:	f4040593          	addi	a1,s0,-192
    80005f7a:	4501                	li	a0,0
    80005f7c:	ffffd097          	auipc	ra,0xffffd
    80005f80:	1b8080e7          	jalr	440(ra) # 80003134 <argstr>
    return -1;
    80005f84:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005f86:	0c054a63          	bltz	a0,8000605a <sys_exec+0xfa>
    80005f8a:	e3840593          	addi	a1,s0,-456
    80005f8e:	4505                	li	a0,1
    80005f90:	ffffd097          	auipc	ra,0xffffd
    80005f94:	182080e7          	jalr	386(ra) # 80003112 <argaddr>
    80005f98:	0c054163          	bltz	a0,8000605a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005f9c:	10000613          	li	a2,256
    80005fa0:	4581                	li	a1,0
    80005fa2:	e4040513          	addi	a0,s0,-448
    80005fa6:	ffffb097          	auipc	ra,0xffffb
    80005faa:	d3c080e7          	jalr	-708(ra) # 80000ce2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005fae:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005fb2:	89a6                	mv	s3,s1
    80005fb4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005fb6:	02000a13          	li	s4,32
    80005fba:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005fbe:	00391513          	slli	a0,s2,0x3
    80005fc2:	e3040593          	addi	a1,s0,-464
    80005fc6:	e3843783          	ld	a5,-456(s0)
    80005fca:	953e                	add	a0,a0,a5
    80005fcc:	ffffd097          	auipc	ra,0xffffd
    80005fd0:	08a080e7          	jalr	138(ra) # 80003056 <fetchaddr>
    80005fd4:	02054a63          	bltz	a0,80006008 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005fd8:	e3043783          	ld	a5,-464(s0)
    80005fdc:	c3b9                	beqz	a5,80006022 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005fde:	ffffb097          	auipc	ra,0xffffb
    80005fe2:	b18080e7          	jalr	-1256(ra) # 80000af6 <kalloc>
    80005fe6:	85aa                	mv	a1,a0
    80005fe8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005fec:	cd11                	beqz	a0,80006008 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fee:	6605                	lui	a2,0x1
    80005ff0:	e3043503          	ld	a0,-464(s0)
    80005ff4:	ffffd097          	auipc	ra,0xffffd
    80005ff8:	0b4080e7          	jalr	180(ra) # 800030a8 <fetchstr>
    80005ffc:	00054663          	bltz	a0,80006008 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80006000:	0905                	addi	s2,s2,1
    80006002:	09a1                	addi	s3,s3,8
    80006004:	fb491be3          	bne	s2,s4,80005fba <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006008:	10048913          	addi	s2,s1,256
    8000600c:	6088                	ld	a0,0(s1)
    8000600e:	c529                	beqz	a0,80006058 <sys_exec+0xf8>
    kfree(argv[i]);
    80006010:	ffffb097          	auipc	ra,0xffffb
    80006014:	9ea080e7          	jalr	-1558(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006018:	04a1                	addi	s1,s1,8
    8000601a:	ff2499e3          	bne	s1,s2,8000600c <sys_exec+0xac>
  return -1;
    8000601e:	597d                	li	s2,-1
    80006020:	a82d                	j	8000605a <sys_exec+0xfa>
      argv[i] = 0;
    80006022:	0a8e                	slli	s5,s5,0x3
    80006024:	fc040793          	addi	a5,s0,-64
    80006028:	9abe                	add	s5,s5,a5
    8000602a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    8000602e:	e4040593          	addi	a1,s0,-448
    80006032:	f4040513          	addi	a0,s0,-192
    80006036:	fffff097          	auipc	ra,0xfffff
    8000603a:	194080e7          	jalr	404(ra) # 800051ca <exec>
    8000603e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006040:	10048993          	addi	s3,s1,256
    80006044:	6088                	ld	a0,0(s1)
    80006046:	c911                	beqz	a0,8000605a <sys_exec+0xfa>
    kfree(argv[i]);
    80006048:	ffffb097          	auipc	ra,0xffffb
    8000604c:	9b2080e7          	jalr	-1614(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006050:	04a1                	addi	s1,s1,8
    80006052:	ff3499e3          	bne	s1,s3,80006044 <sys_exec+0xe4>
    80006056:	a011                	j	8000605a <sys_exec+0xfa>
  return -1;
    80006058:	597d                	li	s2,-1
}
    8000605a:	854a                	mv	a0,s2
    8000605c:	60be                	ld	ra,456(sp)
    8000605e:	641e                	ld	s0,448(sp)
    80006060:	74fa                	ld	s1,440(sp)
    80006062:	795a                	ld	s2,432(sp)
    80006064:	79ba                	ld	s3,424(sp)
    80006066:	7a1a                	ld	s4,416(sp)
    80006068:	6afa                	ld	s5,408(sp)
    8000606a:	6179                	addi	sp,sp,464
    8000606c:	8082                	ret

000000008000606e <sys_pipe>:

uint64
sys_pipe(void)
{
    8000606e:	7139                	addi	sp,sp,-64
    80006070:	fc06                	sd	ra,56(sp)
    80006072:	f822                	sd	s0,48(sp)
    80006074:	f426                	sd	s1,40(sp)
    80006076:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	97a080e7          	jalr	-1670(ra) # 800019f2 <myproc>
    80006080:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80006082:	fd840593          	addi	a1,s0,-40
    80006086:	4501                	li	a0,0
    80006088:	ffffd097          	auipc	ra,0xffffd
    8000608c:	08a080e7          	jalr	138(ra) # 80003112 <argaddr>
    return -1;
    80006090:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80006092:	0e054063          	bltz	a0,80006172 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006096:	fc840593          	addi	a1,s0,-56
    8000609a:	fd040513          	addi	a0,s0,-48
    8000609e:	fffff097          	auipc	ra,0xfffff
    800060a2:	df8080e7          	jalr	-520(ra) # 80004e96 <pipealloc>
    return -1;
    800060a6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800060a8:	0c054563          	bltz	a0,80006172 <sys_pipe+0x104>
  fd0 = -1;
    800060ac:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800060b0:	fd043503          	ld	a0,-48(s0)
    800060b4:	fffff097          	auipc	ra,0xfffff
    800060b8:	508080e7          	jalr	1288(ra) # 800055bc <fdalloc>
    800060bc:	fca42223          	sw	a0,-60(s0)
    800060c0:	08054c63          	bltz	a0,80006158 <sys_pipe+0xea>
    800060c4:	fc843503          	ld	a0,-56(s0)
    800060c8:	fffff097          	auipc	ra,0xfffff
    800060cc:	4f4080e7          	jalr	1268(ra) # 800055bc <fdalloc>
    800060d0:	fca42023          	sw	a0,-64(s0)
    800060d4:	06054863          	bltz	a0,80006144 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060d8:	4691                	li	a3,4
    800060da:	fc440613          	addi	a2,s0,-60
    800060de:	fd843583          	ld	a1,-40(s0)
    800060e2:	68a8                	ld	a0,80(s1)
    800060e4:	ffffb097          	auipc	ra,0xffffb
    800060e8:	590080e7          	jalr	1424(ra) # 80001674 <copyout>
    800060ec:	02054063          	bltz	a0,8000610c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060f0:	4691                	li	a3,4
    800060f2:	fc040613          	addi	a2,s0,-64
    800060f6:	fd843583          	ld	a1,-40(s0)
    800060fa:	0591                	addi	a1,a1,4
    800060fc:	68a8                	ld	a0,80(s1)
    800060fe:	ffffb097          	auipc	ra,0xffffb
    80006102:	576080e7          	jalr	1398(ra) # 80001674 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006106:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006108:	06055563          	bgez	a0,80006172 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    8000610c:	fc442783          	lw	a5,-60(s0)
    80006110:	07e9                	addi	a5,a5,26
    80006112:	078e                	slli	a5,a5,0x3
    80006114:	97a6                	add	a5,a5,s1
    80006116:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000611a:	fc042503          	lw	a0,-64(s0)
    8000611e:	0569                	addi	a0,a0,26
    80006120:	050e                	slli	a0,a0,0x3
    80006122:	9526                	add	a0,a0,s1
    80006124:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006128:	fd043503          	ld	a0,-48(s0)
    8000612c:	fffff097          	auipc	ra,0xfffff
    80006130:	a3a080e7          	jalr	-1478(ra) # 80004b66 <fileclose>
    fileclose(wf);
    80006134:	fc843503          	ld	a0,-56(s0)
    80006138:	fffff097          	auipc	ra,0xfffff
    8000613c:	a2e080e7          	jalr	-1490(ra) # 80004b66 <fileclose>
    return -1;
    80006140:	57fd                	li	a5,-1
    80006142:	a805                	j	80006172 <sys_pipe+0x104>
    if(fd0 >= 0)
    80006144:	fc442783          	lw	a5,-60(s0)
    80006148:	0007c863          	bltz	a5,80006158 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    8000614c:	01a78513          	addi	a0,a5,26
    80006150:	050e                	slli	a0,a0,0x3
    80006152:	9526                	add	a0,a0,s1
    80006154:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006158:	fd043503          	ld	a0,-48(s0)
    8000615c:	fffff097          	auipc	ra,0xfffff
    80006160:	a0a080e7          	jalr	-1526(ra) # 80004b66 <fileclose>
    fileclose(wf);
    80006164:	fc843503          	ld	a0,-56(s0)
    80006168:	fffff097          	auipc	ra,0xfffff
    8000616c:	9fe080e7          	jalr	-1538(ra) # 80004b66 <fileclose>
    return -1;
    80006170:	57fd                	li	a5,-1
}
    80006172:	853e                	mv	a0,a5
    80006174:	70e2                	ld	ra,56(sp)
    80006176:	7442                	ld	s0,48(sp)
    80006178:	74a2                	ld	s1,40(sp)
    8000617a:	6121                	addi	sp,sp,64
    8000617c:	8082                	ret
	...

0000000080006180 <kernelvec>:
    80006180:	7111                	addi	sp,sp,-256
    80006182:	e006                	sd	ra,0(sp)
    80006184:	e40a                	sd	sp,8(sp)
    80006186:	e80e                	sd	gp,16(sp)
    80006188:	ec12                	sd	tp,24(sp)
    8000618a:	f016                	sd	t0,32(sp)
    8000618c:	f41a                	sd	t1,40(sp)
    8000618e:	f81e                	sd	t2,48(sp)
    80006190:	fc22                	sd	s0,56(sp)
    80006192:	e0a6                	sd	s1,64(sp)
    80006194:	e4aa                	sd	a0,72(sp)
    80006196:	e8ae                	sd	a1,80(sp)
    80006198:	ecb2                	sd	a2,88(sp)
    8000619a:	f0b6                	sd	a3,96(sp)
    8000619c:	f4ba                	sd	a4,104(sp)
    8000619e:	f8be                	sd	a5,112(sp)
    800061a0:	fcc2                	sd	a6,120(sp)
    800061a2:	e146                	sd	a7,128(sp)
    800061a4:	e54a                	sd	s2,136(sp)
    800061a6:	e94e                	sd	s3,144(sp)
    800061a8:	ed52                	sd	s4,152(sp)
    800061aa:	f156                	sd	s5,160(sp)
    800061ac:	f55a                	sd	s6,168(sp)
    800061ae:	f95e                	sd	s7,176(sp)
    800061b0:	fd62                	sd	s8,184(sp)
    800061b2:	e1e6                	sd	s9,192(sp)
    800061b4:	e5ea                	sd	s10,200(sp)
    800061b6:	e9ee                	sd	s11,208(sp)
    800061b8:	edf2                	sd	t3,216(sp)
    800061ba:	f1f6                	sd	t4,224(sp)
    800061bc:	f5fa                	sd	t5,232(sp)
    800061be:	f9fe                	sd	t6,240(sp)
    800061c0:	d61fc0ef          	jal	ra,80002f20 <kerneltrap>
    800061c4:	6082                	ld	ra,0(sp)
    800061c6:	6122                	ld	sp,8(sp)
    800061c8:	61c2                	ld	gp,16(sp)
    800061ca:	7282                	ld	t0,32(sp)
    800061cc:	7322                	ld	t1,40(sp)
    800061ce:	73c2                	ld	t2,48(sp)
    800061d0:	7462                	ld	s0,56(sp)
    800061d2:	6486                	ld	s1,64(sp)
    800061d4:	6526                	ld	a0,72(sp)
    800061d6:	65c6                	ld	a1,80(sp)
    800061d8:	6666                	ld	a2,88(sp)
    800061da:	7686                	ld	a3,96(sp)
    800061dc:	7726                	ld	a4,104(sp)
    800061de:	77c6                	ld	a5,112(sp)
    800061e0:	7866                	ld	a6,120(sp)
    800061e2:	688a                	ld	a7,128(sp)
    800061e4:	692a                	ld	s2,136(sp)
    800061e6:	69ca                	ld	s3,144(sp)
    800061e8:	6a6a                	ld	s4,152(sp)
    800061ea:	7a8a                	ld	s5,160(sp)
    800061ec:	7b2a                	ld	s6,168(sp)
    800061ee:	7bca                	ld	s7,176(sp)
    800061f0:	7c6a                	ld	s8,184(sp)
    800061f2:	6c8e                	ld	s9,192(sp)
    800061f4:	6d2e                	ld	s10,200(sp)
    800061f6:	6dce                	ld	s11,208(sp)
    800061f8:	6e6e                	ld	t3,216(sp)
    800061fa:	7e8e                	ld	t4,224(sp)
    800061fc:	7f2e                	ld	t5,232(sp)
    800061fe:	7fce                	ld	t6,240(sp)
    80006200:	6111                	addi	sp,sp,256
    80006202:	10200073          	sret
    80006206:	00000013          	nop
    8000620a:	00000013          	nop
    8000620e:	0001                	nop

0000000080006210 <timervec>:
    80006210:	34051573          	csrrw	a0,mscratch,a0
    80006214:	e10c                	sd	a1,0(a0)
    80006216:	e510                	sd	a2,8(a0)
    80006218:	e914                	sd	a3,16(a0)
    8000621a:	6d0c                	ld	a1,24(a0)
    8000621c:	7110                	ld	a2,32(a0)
    8000621e:	6194                	ld	a3,0(a1)
    80006220:	96b2                	add	a3,a3,a2
    80006222:	e194                	sd	a3,0(a1)
    80006224:	4589                	li	a1,2
    80006226:	14459073          	csrw	sip,a1
    8000622a:	6914                	ld	a3,16(a0)
    8000622c:	6510                	ld	a2,8(a0)
    8000622e:	610c                	ld	a1,0(a0)
    80006230:	34051573          	csrrw	a0,mscratch,a0
    80006234:	30200073          	mret
	...

000000008000623a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000623a:	1141                	addi	sp,sp,-16
    8000623c:	e422                	sd	s0,8(sp)
    8000623e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006240:	0c0007b7          	lui	a5,0xc000
    80006244:	4705                	li	a4,1
    80006246:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006248:	c3d8                	sw	a4,4(a5)
}
    8000624a:	6422                	ld	s0,8(sp)
    8000624c:	0141                	addi	sp,sp,16
    8000624e:	8082                	ret

0000000080006250 <plicinithart>:

void
plicinithart(void)
{
    80006250:	1141                	addi	sp,sp,-16
    80006252:	e406                	sd	ra,8(sp)
    80006254:	e022                	sd	s0,0(sp)
    80006256:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006258:	ffffb097          	auipc	ra,0xffffb
    8000625c:	76e080e7          	jalr	1902(ra) # 800019c6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006260:	0085171b          	slliw	a4,a0,0x8
    80006264:	0c0027b7          	lui	a5,0xc002
    80006268:	97ba                	add	a5,a5,a4
    8000626a:	40200713          	li	a4,1026
    8000626e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006272:	00d5151b          	slliw	a0,a0,0xd
    80006276:	0c2017b7          	lui	a5,0xc201
    8000627a:	953e                	add	a0,a0,a5
    8000627c:	00052023          	sw	zero,0(a0)
}
    80006280:	60a2                	ld	ra,8(sp)
    80006282:	6402                	ld	s0,0(sp)
    80006284:	0141                	addi	sp,sp,16
    80006286:	8082                	ret

0000000080006288 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006288:	1141                	addi	sp,sp,-16
    8000628a:	e406                	sd	ra,8(sp)
    8000628c:	e022                	sd	s0,0(sp)
    8000628e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006290:	ffffb097          	auipc	ra,0xffffb
    80006294:	736080e7          	jalr	1846(ra) # 800019c6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006298:	00d5179b          	slliw	a5,a0,0xd
    8000629c:	0c201537          	lui	a0,0xc201
    800062a0:	953e                	add	a0,a0,a5
  return irq;
}
    800062a2:	4148                	lw	a0,4(a0)
    800062a4:	60a2                	ld	ra,8(sp)
    800062a6:	6402                	ld	s0,0(sp)
    800062a8:	0141                	addi	sp,sp,16
    800062aa:	8082                	ret

00000000800062ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062ac:	1101                	addi	sp,sp,-32
    800062ae:	ec06                	sd	ra,24(sp)
    800062b0:	e822                	sd	s0,16(sp)
    800062b2:	e426                	sd	s1,8(sp)
    800062b4:	1000                	addi	s0,sp,32
    800062b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800062b8:	ffffb097          	auipc	ra,0xffffb
    800062bc:	70e080e7          	jalr	1806(ra) # 800019c6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800062c0:	00d5151b          	slliw	a0,a0,0xd
    800062c4:	0c2017b7          	lui	a5,0xc201
    800062c8:	97aa                	add	a5,a5,a0
    800062ca:	c3c4                	sw	s1,4(a5)
}
    800062cc:	60e2                	ld	ra,24(sp)
    800062ce:	6442                	ld	s0,16(sp)
    800062d0:	64a2                	ld	s1,8(sp)
    800062d2:	6105                	addi	sp,sp,32
    800062d4:	8082                	ret

00000000800062d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800062d6:	1141                	addi	sp,sp,-16
    800062d8:	e406                	sd	ra,8(sp)
    800062da:	e022                	sd	s0,0(sp)
    800062dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800062de:	479d                	li	a5,7
    800062e0:	06a7c963          	blt	a5,a0,80006352 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800062e4:	0001d797          	auipc	a5,0x1d
    800062e8:	d1c78793          	addi	a5,a5,-740 # 80023000 <disk>
    800062ec:	00a78733          	add	a4,a5,a0
    800062f0:	6789                	lui	a5,0x2
    800062f2:	97ba                	add	a5,a5,a4
    800062f4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800062f8:	e7ad                	bnez	a5,80006362 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062fa:	00451793          	slli	a5,a0,0x4
    800062fe:	0001f717          	auipc	a4,0x1f
    80006302:	d0270713          	addi	a4,a4,-766 # 80025000 <disk+0x2000>
    80006306:	6314                	ld	a3,0(a4)
    80006308:	96be                	add	a3,a3,a5
    8000630a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000630e:	6314                	ld	a3,0(a4)
    80006310:	96be                	add	a3,a3,a5
    80006312:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006316:	6314                	ld	a3,0(a4)
    80006318:	96be                	add	a3,a3,a5
    8000631a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000631e:	6318                	ld	a4,0(a4)
    80006320:	97ba                	add	a5,a5,a4
    80006322:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006326:	0001d797          	auipc	a5,0x1d
    8000632a:	cda78793          	addi	a5,a5,-806 # 80023000 <disk>
    8000632e:	97aa                	add	a5,a5,a0
    80006330:	6509                	lui	a0,0x2
    80006332:	953e                	add	a0,a0,a5
    80006334:	4785                	li	a5,1
    80006336:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000633a:	0001f517          	auipc	a0,0x1f
    8000633e:	cde50513          	addi	a0,a0,-802 # 80025018 <disk+0x2018>
    80006342:	ffffc097          	auipc	ra,0xffffc
    80006346:	14c080e7          	jalr	332(ra) # 8000248e <wakeup>
}
    8000634a:	60a2                	ld	ra,8(sp)
    8000634c:	6402                	ld	s0,0(sp)
    8000634e:	0141                	addi	sp,sp,16
    80006350:	8082                	ret
    panic("free_desc 1");
    80006352:	00002517          	auipc	a0,0x2
    80006356:	56650513          	addi	a0,a0,1382 # 800088b8 <syscalls+0x338>
    8000635a:	ffffa097          	auipc	ra,0xffffa
    8000635e:	1e6080e7          	jalr	486(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006362:	00002517          	auipc	a0,0x2
    80006366:	56650513          	addi	a0,a0,1382 # 800088c8 <syscalls+0x348>
    8000636a:	ffffa097          	auipc	ra,0xffffa
    8000636e:	1d6080e7          	jalr	470(ra) # 80000540 <panic>

0000000080006372 <virtio_disk_init>:
{
    80006372:	1101                	addi	sp,sp,-32
    80006374:	ec06                	sd	ra,24(sp)
    80006376:	e822                	sd	s0,16(sp)
    80006378:	e426                	sd	s1,8(sp)
    8000637a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000637c:	00002597          	auipc	a1,0x2
    80006380:	55c58593          	addi	a1,a1,1372 # 800088d8 <syscalls+0x358>
    80006384:	0001f517          	auipc	a0,0x1f
    80006388:	da450513          	addi	a0,a0,-604 # 80025128 <disk+0x2128>
    8000638c:	ffffa097          	auipc	ra,0xffffa
    80006390:	7ca080e7          	jalr	1994(ra) # 80000b56 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006394:	100017b7          	lui	a5,0x10001
    80006398:	4398                	lw	a4,0(a5)
    8000639a:	2701                	sext.w	a4,a4
    8000639c:	747277b7          	lui	a5,0x74727
    800063a0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800063a4:	0ef71163          	bne	a4,a5,80006486 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063a8:	100017b7          	lui	a5,0x10001
    800063ac:	43dc                	lw	a5,4(a5)
    800063ae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800063b0:	4705                	li	a4,1
    800063b2:	0ce79a63          	bne	a5,a4,80006486 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063b6:	100017b7          	lui	a5,0x10001
    800063ba:	479c                	lw	a5,8(a5)
    800063bc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800063be:	4709                	li	a4,2
    800063c0:	0ce79363          	bne	a5,a4,80006486 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800063c4:	100017b7          	lui	a5,0x10001
    800063c8:	47d8                	lw	a4,12(a5)
    800063ca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063cc:	554d47b7          	lui	a5,0x554d4
    800063d0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800063d4:	0af71963          	bne	a4,a5,80006486 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800063d8:	100017b7          	lui	a5,0x10001
    800063dc:	4705                	li	a4,1
    800063de:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063e0:	470d                	li	a4,3
    800063e2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800063e4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800063e6:	c7ffe737          	lui	a4,0xc7ffe
    800063ea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800063ee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063f0:	2701                	sext.w	a4,a4
    800063f2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063f4:	472d                	li	a4,11
    800063f6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063f8:	473d                	li	a4,15
    800063fa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800063fc:	6705                	lui	a4,0x1
    800063fe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006400:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006404:	5bdc                	lw	a5,52(a5)
    80006406:	2781                	sext.w	a5,a5
  if(max == 0)
    80006408:	c7d9                	beqz	a5,80006496 <virtio_disk_init+0x124>
  if(max < NUM)
    8000640a:	471d                	li	a4,7
    8000640c:	08f77d63          	bgeu	a4,a5,800064a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006410:	100014b7          	lui	s1,0x10001
    80006414:	47a1                	li	a5,8
    80006416:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006418:	6609                	lui	a2,0x2
    8000641a:	4581                	li	a1,0
    8000641c:	0001d517          	auipc	a0,0x1d
    80006420:	be450513          	addi	a0,a0,-1052 # 80023000 <disk>
    80006424:	ffffb097          	auipc	ra,0xffffb
    80006428:	8be080e7          	jalr	-1858(ra) # 80000ce2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000642c:	0001d717          	auipc	a4,0x1d
    80006430:	bd470713          	addi	a4,a4,-1068 # 80023000 <disk>
    80006434:	00c75793          	srli	a5,a4,0xc
    80006438:	2781                	sext.w	a5,a5
    8000643a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000643c:	0001f797          	auipc	a5,0x1f
    80006440:	bc478793          	addi	a5,a5,-1084 # 80025000 <disk+0x2000>
    80006444:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006446:	0001d717          	auipc	a4,0x1d
    8000644a:	c3a70713          	addi	a4,a4,-966 # 80023080 <disk+0x80>
    8000644e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006450:	0001e717          	auipc	a4,0x1e
    80006454:	bb070713          	addi	a4,a4,-1104 # 80024000 <disk+0x1000>
    80006458:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000645a:	4705                	li	a4,1
    8000645c:	00e78c23          	sb	a4,24(a5)
    80006460:	00e78ca3          	sb	a4,25(a5)
    80006464:	00e78d23          	sb	a4,26(a5)
    80006468:	00e78da3          	sb	a4,27(a5)
    8000646c:	00e78e23          	sb	a4,28(a5)
    80006470:	00e78ea3          	sb	a4,29(a5)
    80006474:	00e78f23          	sb	a4,30(a5)
    80006478:	00e78fa3          	sb	a4,31(a5)
}
    8000647c:	60e2                	ld	ra,24(sp)
    8000647e:	6442                	ld	s0,16(sp)
    80006480:	64a2                	ld	s1,8(sp)
    80006482:	6105                	addi	sp,sp,32
    80006484:	8082                	ret
    panic("could not find virtio disk");
    80006486:	00002517          	auipc	a0,0x2
    8000648a:	46250513          	addi	a0,a0,1122 # 800088e8 <syscalls+0x368>
    8000648e:	ffffa097          	auipc	ra,0xffffa
    80006492:	0b2080e7          	jalr	178(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006496:	00002517          	auipc	a0,0x2
    8000649a:	47250513          	addi	a0,a0,1138 # 80008908 <syscalls+0x388>
    8000649e:	ffffa097          	auipc	ra,0xffffa
    800064a2:	0a2080e7          	jalr	162(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800064a6:	00002517          	auipc	a0,0x2
    800064aa:	48250513          	addi	a0,a0,1154 # 80008928 <syscalls+0x3a8>
    800064ae:	ffffa097          	auipc	ra,0xffffa
    800064b2:	092080e7          	jalr	146(ra) # 80000540 <panic>

00000000800064b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064b6:	7159                	addi	sp,sp,-112
    800064b8:	f486                	sd	ra,104(sp)
    800064ba:	f0a2                	sd	s0,96(sp)
    800064bc:	eca6                	sd	s1,88(sp)
    800064be:	e8ca                	sd	s2,80(sp)
    800064c0:	e4ce                	sd	s3,72(sp)
    800064c2:	e0d2                	sd	s4,64(sp)
    800064c4:	fc56                	sd	s5,56(sp)
    800064c6:	f85a                	sd	s6,48(sp)
    800064c8:	f45e                	sd	s7,40(sp)
    800064ca:	f062                	sd	s8,32(sp)
    800064cc:	ec66                	sd	s9,24(sp)
    800064ce:	e86a                	sd	s10,16(sp)
    800064d0:	1880                	addi	s0,sp,112
    800064d2:	892a                	mv	s2,a0
    800064d4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064d6:	00c52c83          	lw	s9,12(a0)
    800064da:	001c9c9b          	slliw	s9,s9,0x1
    800064de:	1c82                	slli	s9,s9,0x20
    800064e0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800064e4:	0001f517          	auipc	a0,0x1f
    800064e8:	c4450513          	addi	a0,a0,-956 # 80025128 <disk+0x2128>
    800064ec:	ffffa097          	auipc	ra,0xffffa
    800064f0:	6fa080e7          	jalr	1786(ra) # 80000be6 <acquire>
  for(int i = 0; i < 3; i++){
    800064f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800064f6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800064f8:	0001db97          	auipc	s7,0x1d
    800064fc:	b08b8b93          	addi	s7,s7,-1272 # 80023000 <disk>
    80006500:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006502:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006504:	8a4e                	mv	s4,s3
    80006506:	a051                	j	8000658a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006508:	00fb86b3          	add	a3,s7,a5
    8000650c:	96da                	add	a3,a3,s6
    8000650e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006512:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006514:	0207c563          	bltz	a5,8000653e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006518:	2485                	addiw	s1,s1,1
    8000651a:	0711                	addi	a4,a4,4
    8000651c:	25548063          	beq	s1,s5,8000675c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006520:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006522:	0001f697          	auipc	a3,0x1f
    80006526:	af668693          	addi	a3,a3,-1290 # 80025018 <disk+0x2018>
    8000652a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000652c:	0006c583          	lbu	a1,0(a3)
    80006530:	fde1                	bnez	a1,80006508 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006532:	2785                	addiw	a5,a5,1
    80006534:	0685                	addi	a3,a3,1
    80006536:	ff879be3          	bne	a5,s8,8000652c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000653a:	57fd                	li	a5,-1
    8000653c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000653e:	02905a63          	blez	s1,80006572 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006542:	f9042503          	lw	a0,-112(s0)
    80006546:	00000097          	auipc	ra,0x0
    8000654a:	d90080e7          	jalr	-624(ra) # 800062d6 <free_desc>
      for(int j = 0; j < i; j++)
    8000654e:	4785                	li	a5,1
    80006550:	0297d163          	bge	a5,s1,80006572 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006554:	f9442503          	lw	a0,-108(s0)
    80006558:	00000097          	auipc	ra,0x0
    8000655c:	d7e080e7          	jalr	-642(ra) # 800062d6 <free_desc>
      for(int j = 0; j < i; j++)
    80006560:	4789                	li	a5,2
    80006562:	0097d863          	bge	a5,s1,80006572 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006566:	f9842503          	lw	a0,-104(s0)
    8000656a:	00000097          	auipc	ra,0x0
    8000656e:	d6c080e7          	jalr	-660(ra) # 800062d6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006572:	0001f597          	auipc	a1,0x1f
    80006576:	bb658593          	addi	a1,a1,-1098 # 80025128 <disk+0x2128>
    8000657a:	0001f517          	auipc	a0,0x1f
    8000657e:	a9e50513          	addi	a0,a0,-1378 # 80025018 <disk+0x2018>
    80006582:	ffffc097          	auipc	ra,0xffffc
    80006586:	d26080e7          	jalr	-730(ra) # 800022a8 <sleep>
  for(int i = 0; i < 3; i++){
    8000658a:	f9040713          	addi	a4,s0,-112
    8000658e:	84ce                	mv	s1,s3
    80006590:	bf41                	j	80006520 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006592:	20058713          	addi	a4,a1,512
    80006596:	00471693          	slli	a3,a4,0x4
    8000659a:	0001d717          	auipc	a4,0x1d
    8000659e:	a6670713          	addi	a4,a4,-1434 # 80023000 <disk>
    800065a2:	9736                	add	a4,a4,a3
    800065a4:	4685                	li	a3,1
    800065a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065aa:	20058713          	addi	a4,a1,512
    800065ae:	00471693          	slli	a3,a4,0x4
    800065b2:	0001d717          	auipc	a4,0x1d
    800065b6:	a4e70713          	addi	a4,a4,-1458 # 80023000 <disk>
    800065ba:	9736                	add	a4,a4,a3
    800065bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800065c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800065c4:	7679                	lui	a2,0xffffe
    800065c6:	963e                	add	a2,a2,a5
    800065c8:	0001f697          	auipc	a3,0x1f
    800065cc:	a3868693          	addi	a3,a3,-1480 # 80025000 <disk+0x2000>
    800065d0:	6298                	ld	a4,0(a3)
    800065d2:	9732                	add	a4,a4,a2
    800065d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065d6:	6298                	ld	a4,0(a3)
    800065d8:	9732                	add	a4,a4,a2
    800065da:	4541                	li	a0,16
    800065dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065de:	6298                	ld	a4,0(a3)
    800065e0:	9732                	add	a4,a4,a2
    800065e2:	4505                	li	a0,1
    800065e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800065e8:	f9442703          	lw	a4,-108(s0)
    800065ec:	6288                	ld	a0,0(a3)
    800065ee:	962a                	add	a2,a2,a0
    800065f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065f4:	0712                	slli	a4,a4,0x4
    800065f6:	6290                	ld	a2,0(a3)
    800065f8:	963a                	add	a2,a2,a4
    800065fa:	05890513          	addi	a0,s2,88
    800065fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006600:	6294                	ld	a3,0(a3)
    80006602:	96ba                	add	a3,a3,a4
    80006604:	40000613          	li	a2,1024
    80006608:	c690                	sw	a2,8(a3)
  if(write)
    8000660a:	140d0063          	beqz	s10,8000674a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000660e:	0001f697          	auipc	a3,0x1f
    80006612:	9f26b683          	ld	a3,-1550(a3) # 80025000 <disk+0x2000>
    80006616:	96ba                	add	a3,a3,a4
    80006618:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000661c:	0001d817          	auipc	a6,0x1d
    80006620:	9e480813          	addi	a6,a6,-1564 # 80023000 <disk>
    80006624:	0001f517          	auipc	a0,0x1f
    80006628:	9dc50513          	addi	a0,a0,-1572 # 80025000 <disk+0x2000>
    8000662c:	6114                	ld	a3,0(a0)
    8000662e:	96ba                	add	a3,a3,a4
    80006630:	00c6d603          	lhu	a2,12(a3)
    80006634:	00166613          	ori	a2,a2,1
    80006638:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000663c:	f9842683          	lw	a3,-104(s0)
    80006640:	6110                	ld	a2,0(a0)
    80006642:	9732                	add	a4,a4,a2
    80006644:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006648:	20058613          	addi	a2,a1,512
    8000664c:	0612                	slli	a2,a2,0x4
    8000664e:	9642                	add	a2,a2,a6
    80006650:	577d                	li	a4,-1
    80006652:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006656:	00469713          	slli	a4,a3,0x4
    8000665a:	6114                	ld	a3,0(a0)
    8000665c:	96ba                	add	a3,a3,a4
    8000665e:	03078793          	addi	a5,a5,48
    80006662:	97c2                	add	a5,a5,a6
    80006664:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006666:	611c                	ld	a5,0(a0)
    80006668:	97ba                	add	a5,a5,a4
    8000666a:	4685                	li	a3,1
    8000666c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000666e:	611c                	ld	a5,0(a0)
    80006670:	97ba                	add	a5,a5,a4
    80006672:	4809                	li	a6,2
    80006674:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006678:	611c                	ld	a5,0(a0)
    8000667a:	973e                	add	a4,a4,a5
    8000667c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006680:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006684:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006688:	6518                	ld	a4,8(a0)
    8000668a:	00275783          	lhu	a5,2(a4)
    8000668e:	8b9d                	andi	a5,a5,7
    80006690:	0786                	slli	a5,a5,0x1
    80006692:	97ba                	add	a5,a5,a4
    80006694:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006698:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000669c:	6518                	ld	a4,8(a0)
    8000669e:	00275783          	lhu	a5,2(a4)
    800066a2:	2785                	addiw	a5,a5,1
    800066a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066ac:	100017b7          	lui	a5,0x10001
    800066b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800066b4:	00492703          	lw	a4,4(s2)
    800066b8:	4785                	li	a5,1
    800066ba:	02f71163          	bne	a4,a5,800066dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800066be:	0001f997          	auipc	s3,0x1f
    800066c2:	a6a98993          	addi	s3,s3,-1430 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800066c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800066c8:	85ce                	mv	a1,s3
    800066ca:	854a                	mv	a0,s2
    800066cc:	ffffc097          	auipc	ra,0xffffc
    800066d0:	bdc080e7          	jalr	-1060(ra) # 800022a8 <sleep>
  while(b->disk == 1) {
    800066d4:	00492783          	lw	a5,4(s2)
    800066d8:	fe9788e3          	beq	a5,s1,800066c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800066dc:	f9042903          	lw	s2,-112(s0)
    800066e0:	20090793          	addi	a5,s2,512
    800066e4:	00479713          	slli	a4,a5,0x4
    800066e8:	0001d797          	auipc	a5,0x1d
    800066ec:	91878793          	addi	a5,a5,-1768 # 80023000 <disk>
    800066f0:	97ba                	add	a5,a5,a4
    800066f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800066f6:	0001f997          	auipc	s3,0x1f
    800066fa:	90a98993          	addi	s3,s3,-1782 # 80025000 <disk+0x2000>
    800066fe:	00491713          	slli	a4,s2,0x4
    80006702:	0009b783          	ld	a5,0(s3)
    80006706:	97ba                	add	a5,a5,a4
    80006708:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000670c:	854a                	mv	a0,s2
    8000670e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006712:	00000097          	auipc	ra,0x0
    80006716:	bc4080e7          	jalr	-1084(ra) # 800062d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000671a:	8885                	andi	s1,s1,1
    8000671c:	f0ed                	bnez	s1,800066fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000671e:	0001f517          	auipc	a0,0x1f
    80006722:	a0a50513          	addi	a0,a0,-1526 # 80025128 <disk+0x2128>
    80006726:	ffffa097          	auipc	ra,0xffffa
    8000672a:	574080e7          	jalr	1396(ra) # 80000c9a <release>
}
    8000672e:	70a6                	ld	ra,104(sp)
    80006730:	7406                	ld	s0,96(sp)
    80006732:	64e6                	ld	s1,88(sp)
    80006734:	6946                	ld	s2,80(sp)
    80006736:	69a6                	ld	s3,72(sp)
    80006738:	6a06                	ld	s4,64(sp)
    8000673a:	7ae2                	ld	s5,56(sp)
    8000673c:	7b42                	ld	s6,48(sp)
    8000673e:	7ba2                	ld	s7,40(sp)
    80006740:	7c02                	ld	s8,32(sp)
    80006742:	6ce2                	ld	s9,24(sp)
    80006744:	6d42                	ld	s10,16(sp)
    80006746:	6165                	addi	sp,sp,112
    80006748:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000674a:	0001f697          	auipc	a3,0x1f
    8000674e:	8b66b683          	ld	a3,-1866(a3) # 80025000 <disk+0x2000>
    80006752:	96ba                	add	a3,a3,a4
    80006754:	4609                	li	a2,2
    80006756:	00c69623          	sh	a2,12(a3)
    8000675a:	b5c9                	j	8000661c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000675c:	f9042583          	lw	a1,-112(s0)
    80006760:	20058793          	addi	a5,a1,512
    80006764:	0792                	slli	a5,a5,0x4
    80006766:	0001d517          	auipc	a0,0x1d
    8000676a:	94250513          	addi	a0,a0,-1726 # 800230a8 <disk+0xa8>
    8000676e:	953e                	add	a0,a0,a5
  if(write)
    80006770:	e20d11e3          	bnez	s10,80006592 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006774:	20058713          	addi	a4,a1,512
    80006778:	00471693          	slli	a3,a4,0x4
    8000677c:	0001d717          	auipc	a4,0x1d
    80006780:	88470713          	addi	a4,a4,-1916 # 80023000 <disk>
    80006784:	9736                	add	a4,a4,a3
    80006786:	0a072423          	sw	zero,168(a4)
    8000678a:	b505                	j	800065aa <virtio_disk_rw+0xf4>

000000008000678c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000678c:	1101                	addi	sp,sp,-32
    8000678e:	ec06                	sd	ra,24(sp)
    80006790:	e822                	sd	s0,16(sp)
    80006792:	e426                	sd	s1,8(sp)
    80006794:	e04a                	sd	s2,0(sp)
    80006796:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006798:	0001f517          	auipc	a0,0x1f
    8000679c:	99050513          	addi	a0,a0,-1648 # 80025128 <disk+0x2128>
    800067a0:	ffffa097          	auipc	ra,0xffffa
    800067a4:	446080e7          	jalr	1094(ra) # 80000be6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800067a8:	10001737          	lui	a4,0x10001
    800067ac:	533c                	lw	a5,96(a4)
    800067ae:	8b8d                	andi	a5,a5,3
    800067b0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800067b2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067b6:	0001f797          	auipc	a5,0x1f
    800067ba:	84a78793          	addi	a5,a5,-1974 # 80025000 <disk+0x2000>
    800067be:	6b94                	ld	a3,16(a5)
    800067c0:	0207d703          	lhu	a4,32(a5)
    800067c4:	0026d783          	lhu	a5,2(a3)
    800067c8:	06f70163          	beq	a4,a5,8000682a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067cc:	0001d917          	auipc	s2,0x1d
    800067d0:	83490913          	addi	s2,s2,-1996 # 80023000 <disk>
    800067d4:	0001f497          	auipc	s1,0x1f
    800067d8:	82c48493          	addi	s1,s1,-2004 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800067dc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067e0:	6898                	ld	a4,16(s1)
    800067e2:	0204d783          	lhu	a5,32(s1)
    800067e6:	8b9d                	andi	a5,a5,7
    800067e8:	078e                	slli	a5,a5,0x3
    800067ea:	97ba                	add	a5,a5,a4
    800067ec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067ee:	20078713          	addi	a4,a5,512
    800067f2:	0712                	slli	a4,a4,0x4
    800067f4:	974a                	add	a4,a4,s2
    800067f6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800067fa:	e731                	bnez	a4,80006846 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067fc:	20078793          	addi	a5,a5,512
    80006800:	0792                	slli	a5,a5,0x4
    80006802:	97ca                	add	a5,a5,s2
    80006804:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006806:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000680a:	ffffc097          	auipc	ra,0xffffc
    8000680e:	c84080e7          	jalr	-892(ra) # 8000248e <wakeup>

    disk.used_idx += 1;
    80006812:	0204d783          	lhu	a5,32(s1)
    80006816:	2785                	addiw	a5,a5,1
    80006818:	17c2                	slli	a5,a5,0x30
    8000681a:	93c1                	srli	a5,a5,0x30
    8000681c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006820:	6898                	ld	a4,16(s1)
    80006822:	00275703          	lhu	a4,2(a4)
    80006826:	faf71be3          	bne	a4,a5,800067dc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000682a:	0001f517          	auipc	a0,0x1f
    8000682e:	8fe50513          	addi	a0,a0,-1794 # 80025128 <disk+0x2128>
    80006832:	ffffa097          	auipc	ra,0xffffa
    80006836:	468080e7          	jalr	1128(ra) # 80000c9a <release>
}
    8000683a:	60e2                	ld	ra,24(sp)
    8000683c:	6442                	ld	s0,16(sp)
    8000683e:	64a2                	ld	s1,8(sp)
    80006840:	6902                	ld	s2,0(sp)
    80006842:	6105                	addi	sp,sp,32
    80006844:	8082                	ret
      panic("virtio_disk_intr status");
    80006846:	00002517          	auipc	a0,0x2
    8000684a:	10250513          	addi	a0,a0,258 # 80008948 <syscalls+0x3c8>
    8000684e:	ffffa097          	auipc	ra,0xffffa
    80006852:	cf2080e7          	jalr	-782(ra) # 80000540 <panic>
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
