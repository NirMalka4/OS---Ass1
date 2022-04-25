
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9d013103          	ld	sp,-1584(sp) # 800089d0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	22c78793          	addi	a5,a5,556 # 80006290 <timervec>
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
    80000130:	814080e7          	jalr	-2028(ra) # 80002940 <either_copyin>
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
    800001c8:	83e080e7          	jalr	-1986(ra) # 80001a02 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	2781                	sext.w	a5,a5
    800001d0:	e7b5                	bnez	a5,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85ce                	mv	a1,s3
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	11e080e7          	jalr	286(ra) # 800022f4 <sleep>
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
    80000216:	6d8080e7          	jalr	1752(ra) # 800028ea <either_copyout>
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
    800002f8:	6a2080e7          	jalr	1698(ra) # 80002996 <procdump>
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
    8000044c:	092080e7          	jalr	146(ra) # 800024da <wakeup>
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
    80000572:	d1250513          	addi	a0,a0,-750 # 80008280 <digits+0x240>
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
    800008a6:	c38080e7          	jalr	-968(ra) # 800024da <wakeup>
    
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
    80000932:	9c6080e7          	jalr	-1594(ra) # 800022f4 <sleep>
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
    80000b84:	e66080e7          	jalr	-410(ra) # 800019e6 <mycpu>
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
    80000bb6:	e34080e7          	jalr	-460(ra) # 800019e6 <mycpu>
    80000bba:	5d3c                	lw	a5,120(a0)
    80000bbc:	cf89                	beqz	a5,80000bd6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbe:	00001097          	auipc	ra,0x1
    80000bc2:	e28080e7          	jalr	-472(ra) # 800019e6 <mycpu>
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
    80000bda:	e10080e7          	jalr	-496(ra) # 800019e6 <mycpu>
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
    80000c1a:	dd0080e7          	jalr	-560(ra) # 800019e6 <mycpu>
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
    80000c46:	da4080e7          	jalr	-604(ra) # 800019e6 <mycpu>
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
    80000e9c:	b3e080e7          	jalr	-1218(ra) # 800019d6 <cpuid>
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
    80000eb8:	b22080e7          	jalr	-1246(ra) # 800019d6 <cpuid>
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
    80000eda:	e4a080e7          	jalr	-438(ra) # 80002d20 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ede:	00005097          	auipc	ra,0x5
    80000ee2:	3f2080e7          	jalr	1010(ra) # 800062d0 <plicinithart>
  }

  scheduler();        
    80000ee6:	00001097          	auipc	ra,0x1
    80000eea:	0e0080e7          	jalr	224(ra) # 80001fc6 <scheduler>
    consoleinit();
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	564080e7          	jalr	1380(ra) # 80000452 <consoleinit>
    printfinit();
    80000ef6:	00000097          	auipc	ra,0x0
    80000efa:	87a080e7          	jalr	-1926(ra) # 80000770 <printfinit>
    printf("\n");
    80000efe:	00007517          	auipc	a0,0x7
    80000f02:	38250513          	addi	a0,a0,898 # 80008280 <digits+0x240>
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	684080e7          	jalr	1668(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000f0e:	00007517          	auipc	a0,0x7
    80000f12:	19250513          	addi	a0,a0,402 # 800080a0 <digits+0x60>
    80000f16:	fffff097          	auipc	ra,0xfffff
    80000f1a:	674080e7          	jalr	1652(ra) # 8000058a <printf>
    printf("\n");
    80000f1e:	00007517          	auipc	a0,0x7
    80000f22:	36250513          	addi	a0,a0,866 # 80008280 <digits+0x240>
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
    80000f52:	daa080e7          	jalr	-598(ra) # 80002cf8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	dca080e7          	jalr	-566(ra) # 80002d20 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5e:	00005097          	auipc	ra,0x5
    80000f62:	35c080e7          	jalr	860(ra) # 800062ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f66:	00005097          	auipc	ra,0x5
    80000f6a:	36a080e7          	jalr	874(ra) # 800062d0 <plicinithart>
    binit();         // buffer cache
    80000f6e:	00002097          	auipc	ra,0x2
    80000f72:	544080e7          	jalr	1348(ra) # 800034b2 <binit>
    iinit();         // inode table
    80000f76:	00003097          	auipc	ra,0x3
    80000f7a:	bd4080e7          	jalr	-1068(ra) # 80003b4a <iinit>
    fileinit();      // file table
    80000f7e:	00004097          	auipc	ra,0x4
    80000f82:	b7e080e7          	jalr	-1154(ra) # 80004afc <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f86:	00005097          	auipc	ra,0x5
    80000f8a:	46c080e7          	jalr	1132(ra) # 800063f2 <virtio_disk_init>
    userinit();      // first user process
    80000f8e:	00001097          	auipc	ra,0x1
    80000f92:	d56080e7          	jalr	-682(ra) # 80001ce4 <userinit>
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
  start_time = ticks;
    8000191a:	00007797          	auipc	a5,0x7
    8000191e:	73a7a783          	lw	a5,1850(a5) # 80009054 <ticks>
    80001922:	00007717          	auipc	a4,0x7
    80001926:	70f72b23          	sw	a5,1814(a4) # 80009038 <start_time>

  //acquire(&tickslock);
  
  //release(&tickslock);

  initlock(&pid_lock, "nextpid");
    8000192a:	00007597          	auipc	a1,0x7
    8000192e:	8b658593          	addi	a1,a1,-1866 # 800081e0 <digits+0x1a0>
    80001932:	00010517          	auipc	a0,0x10
    80001936:	98e50513          	addi	a0,a0,-1650 # 800112c0 <pid_lock>
    8000193a:	fffff097          	auipc	ra,0xfffff
    8000193e:	21c080e7          	jalr	540(ra) # 80000b56 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001942:	00007597          	auipc	a1,0x7
    80001946:	8a658593          	addi	a1,a1,-1882 # 800081e8 <digits+0x1a8>
    8000194a:	00010517          	auipc	a0,0x10
    8000194e:	98e50513          	addi	a0,a0,-1650 # 800112d8 <wait_lock>
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	204080e7          	jalr	516(ra) # 80000b56 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195a:	00010497          	auipc	s1,0x10
    8000195e:	d9648493          	addi	s1,s1,-618 # 800116f0 <proc>
      initlock(&p->lock, "proc");
    80001962:	00007b17          	auipc	s6,0x7
    80001966:	896b0b13          	addi	s6,s6,-1898 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000196a:	8aa6                	mv	s5,s1
    8000196c:	00006a17          	auipc	s4,0x6
    80001970:	694a0a13          	addi	s4,s4,1684 # 80008000 <etext>
    80001974:	04000937          	lui	s2,0x4000
    80001978:	197d                	addi	s2,s2,-1
    8000197a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	00016997          	auipc	s3,0x16
    80001980:	f7498993          	addi	s3,s3,-140 # 800178f0 <tickslock>
      initlock(&p->lock, "proc");
    80001984:	85da                	mv	a1,s6
    80001986:	8526                	mv	a0,s1
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	1ce080e7          	jalr	462(ra) # 80000b56 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001990:	415487b3          	sub	a5,s1,s5
    80001994:	878d                	srai	a5,a5,0x3
    80001996:	000a3703          	ld	a4,0(s4)
    8000199a:	02e787b3          	mul	a5,a5,a4
    8000199e:	2785                	addiw	a5,a5,1
    800019a0:	00d7979b          	slliw	a5,a5,0xd
    800019a4:	40f907b3          	sub	a5,s2,a5
    800019a8:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019aa:	18848493          	addi	s1,s1,392
    800019ae:	fd349be3          	bne	s1,s3,80001984 <procinit+0xae>
  }
  start_time = ticks;
    800019b2:	00007797          	auipc	a5,0x7
    800019b6:	6a27a783          	lw	a5,1698(a5) # 80009054 <ticks>
    800019ba:	00007717          	auipc	a4,0x7
    800019be:	66f72f23          	sw	a5,1662(a4) # 80009038 <start_time>
}
    800019c2:	70e2                	ld	ra,56(sp)
    800019c4:	7442                	ld	s0,48(sp)
    800019c6:	74a2                	ld	s1,40(sp)
    800019c8:	7902                	ld	s2,32(sp)
    800019ca:	69e2                	ld	s3,24(sp)
    800019cc:	6a42                	ld	s4,16(sp)
    800019ce:	6aa2                	ld	s5,8(sp)
    800019d0:	6b02                	ld	s6,0(sp)
    800019d2:	6121                	addi	sp,sp,64
    800019d4:	8082                	ret

00000000800019d6 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019d6:	1141                	addi	sp,sp,-16
    800019d8:	e422                	sd	s0,8(sp)
    800019da:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019dc:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019de:	2501                	sext.w	a0,a0
    800019e0:	6422                	ld	s0,8(sp)
    800019e2:	0141                	addi	sp,sp,16
    800019e4:	8082                	ret

00000000800019e6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    800019e6:	1141                	addi	sp,sp,-16
    800019e8:	e422                	sd	s0,8(sp)
    800019ea:	0800                	addi	s0,sp,16
    800019ec:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019ee:	2781                	sext.w	a5,a5
    800019f0:	079e                	slli	a5,a5,0x7
  return c;
}
    800019f2:	00010517          	auipc	a0,0x10
    800019f6:	8fe50513          	addi	a0,a0,-1794 # 800112f0 <cpus>
    800019fa:	953e                	add	a0,a0,a5
    800019fc:	6422                	ld	s0,8(sp)
    800019fe:	0141                	addi	sp,sp,16
    80001a00:	8082                	ret

0000000080001a02 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a02:	1101                	addi	sp,sp,-32
    80001a04:	ec06                	sd	ra,24(sp)
    80001a06:	e822                	sd	s0,16(sp)
    80001a08:	e426                	sd	s1,8(sp)
    80001a0a:	1000                	addi	s0,sp,32
  push_off();
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	18e080e7          	jalr	398(ra) # 80000b9a <push_off>
    80001a14:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a16:	2781                	sext.w	a5,a5
    80001a18:	079e                	slli	a5,a5,0x7
    80001a1a:	00010717          	auipc	a4,0x10
    80001a1e:	8a670713          	addi	a4,a4,-1882 # 800112c0 <pid_lock>
    80001a22:	97ba                	add	a5,a5,a4
    80001a24:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	214080e7          	jalr	532(ra) # 80000c3a <pop_off>
  return p;
}
    80001a2e:	8526                	mv	a0,s1
    80001a30:	60e2                	ld	ra,24(sp)
    80001a32:	6442                	ld	s0,16(sp)
    80001a34:	64a2                	ld	s1,8(sp)
    80001a36:	6105                	addi	sp,sp,32
    80001a38:	8082                	ret

0000000080001a3a <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a3a:	1141                	addi	sp,sp,-16
    80001a3c:	e406                	sd	ra,8(sp)
    80001a3e:	e022                	sd	s0,0(sp)
    80001a40:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a42:	00000097          	auipc	ra,0x0
    80001a46:	fc0080e7          	jalr	-64(ra) # 80001a02 <myproc>
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	250080e7          	jalr	592(ra) # 80000c9a <release>

  if (first) {
    80001a52:	00007797          	auipc	a5,0x7
    80001a56:	f2e7a783          	lw	a5,-210(a5) # 80008980 <first.1705>
    80001a5a:	eb89                	bnez	a5,80001a6c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a5c:	00001097          	auipc	ra,0x1
    80001a60:	2dc080e7          	jalr	732(ra) # 80002d38 <usertrapret>
}
    80001a64:	60a2                	ld	ra,8(sp)
    80001a66:	6402                	ld	s0,0(sp)
    80001a68:	0141                	addi	sp,sp,16
    80001a6a:	8082                	ret
    first = 0;
    80001a6c:	00007797          	auipc	a5,0x7
    80001a70:	f007aa23          	sw	zero,-236(a5) # 80008980 <first.1705>
    fsinit(ROOTDEV);
    80001a74:	4505                	li	a0,1
    80001a76:	00002097          	auipc	ra,0x2
    80001a7a:	054080e7          	jalr	84(ra) # 80003aca <fsinit>
    80001a7e:	bff9                	j	80001a5c <forkret+0x22>

0000000080001a80 <allocpid>:
allocpid() {
    80001a80:	1101                	addi	sp,sp,-32
    80001a82:	ec06                	sd	ra,24(sp)
    80001a84:	e822                	sd	s0,16(sp)
    80001a86:	e426                	sd	s1,8(sp)
    80001a88:	e04a                	sd	s2,0(sp)
    80001a8a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a8c:	00010917          	auipc	s2,0x10
    80001a90:	83490913          	addi	s2,s2,-1996 # 800112c0 <pid_lock>
    80001a94:	854a                	mv	a0,s2
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	150080e7          	jalr	336(ra) # 80000be6 <acquire>
  pid = nextpid;
    80001a9e:	00007797          	auipc	a5,0x7
    80001aa2:	ee678793          	addi	a5,a5,-282 # 80008984 <nextpid>
    80001aa6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aa8:	0014871b          	addiw	a4,s1,1
    80001aac:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aae:	854a                	mv	a0,s2
    80001ab0:	fffff097          	auipc	ra,0xfffff
    80001ab4:	1ea080e7          	jalr	490(ra) # 80000c9a <release>
}
    80001ab8:	8526                	mv	a0,s1
    80001aba:	60e2                	ld	ra,24(sp)
    80001abc:	6442                	ld	s0,16(sp)
    80001abe:	64a2                	ld	s1,8(sp)
    80001ac0:	6902                	ld	s2,0(sp)
    80001ac2:	6105                	addi	sp,sp,32
    80001ac4:	8082                	ret

0000000080001ac6 <proc_pagetable>:
{
    80001ac6:	1101                	addi	sp,sp,-32
    80001ac8:	ec06                	sd	ra,24(sp)
    80001aca:	e822                	sd	s0,16(sp)
    80001acc:	e426                	sd	s1,8(sp)
    80001ace:	e04a                	sd	s2,0(sp)
    80001ad0:	1000                	addi	s0,sp,32
    80001ad2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	868080e7          	jalr	-1944(ra) # 8000133c <uvmcreate>
    80001adc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ade:	c121                	beqz	a0,80001b1e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ae0:	4729                	li	a4,10
    80001ae2:	00005697          	auipc	a3,0x5
    80001ae6:	51e68693          	addi	a3,a3,1310 # 80007000 <_trampoline>
    80001aea:	6605                	lui	a2,0x1
    80001aec:	040005b7          	lui	a1,0x4000
    80001af0:	15fd                	addi	a1,a1,-1
    80001af2:	05b2                	slli	a1,a1,0xc
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	5be080e7          	jalr	1470(ra) # 800010b2 <mappages>
    80001afc:	02054863          	bltz	a0,80001b2c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b00:	4719                	li	a4,6
    80001b02:	05893683          	ld	a3,88(s2)
    80001b06:	6605                	lui	a2,0x1
    80001b08:	020005b7          	lui	a1,0x2000
    80001b0c:	15fd                	addi	a1,a1,-1
    80001b0e:	05b6                	slli	a1,a1,0xd
    80001b10:	8526                	mv	a0,s1
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	5a0080e7          	jalr	1440(ra) # 800010b2 <mappages>
    80001b1a:	02054163          	bltz	a0,80001b3c <proc_pagetable+0x76>
}
    80001b1e:	8526                	mv	a0,s1
    80001b20:	60e2                	ld	ra,24(sp)
    80001b22:	6442                	ld	s0,16(sp)
    80001b24:	64a2                	ld	s1,8(sp)
    80001b26:	6902                	ld	s2,0(sp)
    80001b28:	6105                	addi	sp,sp,32
    80001b2a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b2c:	4581                	li	a1,0
    80001b2e:	8526                	mv	a0,s1
    80001b30:	00000097          	auipc	ra,0x0
    80001b34:	a08080e7          	jalr	-1528(ra) # 80001538 <uvmfree>
    return 0;
    80001b38:	4481                	li	s1,0
    80001b3a:	b7d5                	j	80001b1e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b3c:	4681                	li	a3,0
    80001b3e:	4605                	li	a2,1
    80001b40:	040005b7          	lui	a1,0x4000
    80001b44:	15fd                	addi	a1,a1,-1
    80001b46:	05b2                	slli	a1,a1,0xc
    80001b48:	8526                	mv	a0,s1
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	72e080e7          	jalr	1838(ra) # 80001278 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b52:	4581                	li	a1,0
    80001b54:	8526                	mv	a0,s1
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	9e2080e7          	jalr	-1566(ra) # 80001538 <uvmfree>
    return 0;
    80001b5e:	4481                	li	s1,0
    80001b60:	bf7d                	j	80001b1e <proc_pagetable+0x58>

0000000080001b62 <proc_freepagetable>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	e04a                	sd	s2,0(sp)
    80001b6c:	1000                	addi	s0,sp,32
    80001b6e:	84aa                	mv	s1,a0
    80001b70:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b72:	4681                	li	a3,0
    80001b74:	4605                	li	a2,1
    80001b76:	040005b7          	lui	a1,0x4000
    80001b7a:	15fd                	addi	a1,a1,-1
    80001b7c:	05b2                	slli	a1,a1,0xc
    80001b7e:	fffff097          	auipc	ra,0xfffff
    80001b82:	6fa080e7          	jalr	1786(ra) # 80001278 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b86:	4681                	li	a3,0
    80001b88:	4605                	li	a2,1
    80001b8a:	020005b7          	lui	a1,0x2000
    80001b8e:	15fd                	addi	a1,a1,-1
    80001b90:	05b6                	slli	a1,a1,0xd
    80001b92:	8526                	mv	a0,s1
    80001b94:	fffff097          	auipc	ra,0xfffff
    80001b98:	6e4080e7          	jalr	1764(ra) # 80001278 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b9c:	85ca                	mv	a1,s2
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	00000097          	auipc	ra,0x0
    80001ba4:	998080e7          	jalr	-1640(ra) # 80001538 <uvmfree>
}
    80001ba8:	60e2                	ld	ra,24(sp)
    80001baa:	6442                	ld	s0,16(sp)
    80001bac:	64a2                	ld	s1,8(sp)
    80001bae:	6902                	ld	s2,0(sp)
    80001bb0:	6105                	addi	sp,sp,32
    80001bb2:	8082                	ret

0000000080001bb4 <freeproc>:
{
    80001bb4:	1101                	addi	sp,sp,-32
    80001bb6:	ec06                	sd	ra,24(sp)
    80001bb8:	e822                	sd	s0,16(sp)
    80001bba:	e426                	sd	s1,8(sp)
    80001bbc:	1000                	addi	s0,sp,32
    80001bbe:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bc0:	6d28                	ld	a0,88(a0)
    80001bc2:	c509                	beqz	a0,80001bcc <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bc4:	fffff097          	auipc	ra,0xfffff
    80001bc8:	e36080e7          	jalr	-458(ra) # 800009fa <kfree>
  p->trapframe = 0;
    80001bcc:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bd0:	68a8                	ld	a0,80(s1)
    80001bd2:	c511                	beqz	a0,80001bde <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bd4:	64ac                	ld	a1,72(s1)
    80001bd6:	00000097          	auipc	ra,0x0
    80001bda:	f8c080e7          	jalr	-116(ra) # 80001b62 <proc_freepagetable>
  p->pagetable = 0;
    80001bde:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001be2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001be6:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bea:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bee:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bf2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bf6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bfa:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bfe:	0004ac23          	sw	zero,24(s1)
}
    80001c02:	60e2                	ld	ra,24(sp)
    80001c04:	6442                	ld	s0,16(sp)
    80001c06:	64a2                	ld	s1,8(sp)
    80001c08:	6105                	addi	sp,sp,32
    80001c0a:	8082                	ret

0000000080001c0c <allocproc>:
{
    80001c0c:	1101                	addi	sp,sp,-32
    80001c0e:	ec06                	sd	ra,24(sp)
    80001c10:	e822                	sd	s0,16(sp)
    80001c12:	e426                	sd	s1,8(sp)
    80001c14:	e04a                	sd	s2,0(sp)
    80001c16:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c18:	00010497          	auipc	s1,0x10
    80001c1c:	ad848493          	addi	s1,s1,-1320 # 800116f0 <proc>
    80001c20:	00016917          	auipc	s2,0x16
    80001c24:	cd090913          	addi	s2,s2,-816 # 800178f0 <tickslock>
    acquire(&p->lock);
    80001c28:	8526                	mv	a0,s1
    80001c2a:	fffff097          	auipc	ra,0xfffff
    80001c2e:	fbc080e7          	jalr	-68(ra) # 80000be6 <acquire>
    if(p->state == UNUSED) {
    80001c32:	4c9c                	lw	a5,24(s1)
    80001c34:	2781                	sext.w	a5,a5
    80001c36:	cf81                	beqz	a5,80001c4e <allocproc+0x42>
      release(&p->lock);
    80001c38:	8526                	mv	a0,s1
    80001c3a:	fffff097          	auipc	ra,0xfffff
    80001c3e:	060080e7          	jalr	96(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c42:	18848493          	addi	s1,s1,392
    80001c46:	ff2491e3          	bne	s1,s2,80001c28 <allocproc+0x1c>
  return 0;
    80001c4a:	4481                	li	s1,0
    80001c4c:	a8a9                	j	80001ca6 <allocproc+0x9a>
  p->pid = allocpid();
    80001c4e:	00000097          	auipc	ra,0x0
    80001c52:	e32080e7          	jalr	-462(ra) # 80001a80 <allocpid>
    80001c56:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c58:	4785                	li	a5,1
    80001c5a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c5c:	fffff097          	auipc	ra,0xfffff
    80001c60:	e9a080e7          	jalr	-358(ra) # 80000af6 <kalloc>
    80001c64:	892a                	mv	s2,a0
    80001c66:	eca8                	sd	a0,88(s1)
    80001c68:	c531                	beqz	a0,80001cb4 <allocproc+0xa8>
  p->pagetable = proc_pagetable(p);
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	00000097          	auipc	ra,0x0
    80001c70:	e5a080e7          	jalr	-422(ra) # 80001ac6 <proc_pagetable>
    80001c74:	892a                	mv	s2,a0
    80001c76:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c78:	c931                	beqz	a0,80001ccc <allocproc+0xc0>
  memset(&p->context, 0, sizeof(p->context));
    80001c7a:	07000613          	li	a2,112
    80001c7e:	4581                	li	a1,0
    80001c80:	06048513          	addi	a0,s1,96
    80001c84:	fffff097          	auipc	ra,0xfffff
    80001c88:	05e080e7          	jalr	94(ra) # 80000ce2 <memset>
  p->context.ra = (uint64)forkret;
    80001c8c:	00000797          	auipc	a5,0x0
    80001c90:	dae78793          	addi	a5,a5,-594 # 80001a3a <forkret>
    80001c94:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c96:	60bc                	ld	a5,64(s1)
    80001c98:	6705                	lui	a4,0x1
    80001c9a:	97ba                	add	a5,a5,a4
    80001c9c:	f4bc                	sd	a5,104(s1)
  p->mean_ticks = 0;
    80001c9e:	1604a423          	sw	zero,360(s1)
  p->last_ticks = 0;
    80001ca2:	1604a623          	sw	zero,364(s1)
}
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	60e2                	ld	ra,24(sp)
    80001caa:	6442                	ld	s0,16(sp)
    80001cac:	64a2                	ld	s1,8(sp)
    80001cae:	6902                	ld	s2,0(sp)
    80001cb0:	6105                	addi	sp,sp,32
    80001cb2:	8082                	ret
    freeproc(p);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	efe080e7          	jalr	-258(ra) # 80001bb4 <freeproc>
    release(&p->lock);
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	fda080e7          	jalr	-38(ra) # 80000c9a <release>
    return 0;
    80001cc8:	84ca                	mv	s1,s2
    80001cca:	bff1                	j	80001ca6 <allocproc+0x9a>
    freeproc(p);
    80001ccc:	8526                	mv	a0,s1
    80001cce:	00000097          	auipc	ra,0x0
    80001cd2:	ee6080e7          	jalr	-282(ra) # 80001bb4 <freeproc>
    release(&p->lock);
    80001cd6:	8526                	mv	a0,s1
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	fc2080e7          	jalr	-62(ra) # 80000c9a <release>
    return 0;
    80001ce0:	84ca                	mv	s1,s2
    80001ce2:	b7d1                	j	80001ca6 <allocproc+0x9a>

0000000080001ce4 <userinit>:
{
    80001ce4:	1101                	addi	sp,sp,-32
    80001ce6:	ec06                	sd	ra,24(sp)
    80001ce8:	e822                	sd	s0,16(sp)
    80001cea:	e426                	sd	s1,8(sp)
    80001cec:	e04a                	sd	s2,0(sp)
    80001cee:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cf0:	00000097          	auipc	ra,0x0
    80001cf4:	f1c080e7          	jalr	-228(ra) # 80001c0c <allocproc>
    80001cf8:	84aa                	mv	s1,a0
  initproc = p;
    80001cfa:	00007797          	auipc	a5,0x7
    80001cfe:	32a7bb23          	sd	a0,822(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d02:	03400613          	li	a2,52
    80001d06:	00007597          	auipc	a1,0x7
    80001d0a:	c8a58593          	addi	a1,a1,-886 # 80008990 <initcode>
    80001d0e:	6928                	ld	a0,80(a0)
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	65a080e7          	jalr	1626(ra) # 8000136a <uvminit>
  p->sz = PGSIZE;
    80001d18:	6785                	lui	a5,0x1
    80001d1a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d1c:	6cb8                	ld	a4,88(s1)
    80001d1e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d22:	6cb8                	ld	a4,88(s1)
    80001d24:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d26:	4641                	li	a2,16
    80001d28:	00006597          	auipc	a1,0x6
    80001d2c:	4d858593          	addi	a1,a1,1240 # 80008200 <digits+0x1c0>
    80001d30:	15848513          	addi	a0,s1,344
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	100080e7          	jalr	256(ra) # 80000e34 <safestrcpy>
  p->cwd = namei("/");
    80001d3c:	00006517          	auipc	a0,0x6
    80001d40:	4d450513          	addi	a0,a0,1236 # 80008210 <digits+0x1d0>
    80001d44:	00002097          	auipc	ra,0x2
    80001d48:	7b4080e7          	jalr	1972(ra) # 800044f8 <namei>
    80001d4c:	14a4b823          	sd	a0,336(s1)
  p->runnable_time = 0;
    80001d50:	1604ae23          	sw	zero,380(s1)
  p->running_time = 0;
    80001d54:	1604ac23          	sw	zero,376(s1)
  p -> sleeping_time = 0;
    80001d58:	1604aa23          	sw	zero,372(s1)
  p->last_update_time = ticks;
    80001d5c:	00007917          	auipc	s2,0x7
    80001d60:	2f890913          	addi	s2,s2,760 # 80009054 <ticks>
    80001d64:	00092783          	lw	a5,0(s2)
    80001d68:	18f4a023          	sw	a5,384(s1)
  p->state = RUNNABLE;
    80001d6c:	478d                	li	a5,3
    80001d6e:	cc9c                	sw	a5,24(s1)
  acquire(&tickslock);
    80001d70:	00016517          	auipc	a0,0x16
    80001d74:	b8050513          	addi	a0,a0,-1152 # 800178f0 <tickslock>
    80001d78:	fffff097          	auipc	ra,0xfffff
    80001d7c:	e6e080e7          	jalr	-402(ra) # 80000be6 <acquire>
  p->last_runable_time = ticks;
    80001d80:	00092783          	lw	a5,0(s2)
    80001d84:	16f4a823          	sw	a5,368(s1)
  release(&tickslock);
    80001d88:	00016517          	auipc	a0,0x16
    80001d8c:	b6850513          	addi	a0,a0,-1176 # 800178f0 <tickslock>
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	f0a080e7          	jalr	-246(ra) # 80000c9a <release>
  release(&p->lock);
    80001d98:	8526                	mv	a0,s1
    80001d9a:	fffff097          	auipc	ra,0xfffff
    80001d9e:	f00080e7          	jalr	-256(ra) # 80000c9a <release>
}
    80001da2:	60e2                	ld	ra,24(sp)
    80001da4:	6442                	ld	s0,16(sp)
    80001da6:	64a2                	ld	s1,8(sp)
    80001da8:	6902                	ld	s2,0(sp)
    80001daa:	6105                	addi	sp,sp,32
    80001dac:	8082                	ret

0000000080001dae <growproc>:
{
    80001dae:	1101                	addi	sp,sp,-32
    80001db0:	ec06                	sd	ra,24(sp)
    80001db2:	e822                	sd	s0,16(sp)
    80001db4:	e426                	sd	s1,8(sp)
    80001db6:	e04a                	sd	s2,0(sp)
    80001db8:	1000                	addi	s0,sp,32
    80001dba:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	c46080e7          	jalr	-954(ra) # 80001a02 <myproc>
    80001dc4:	892a                	mv	s2,a0
  sz = p->sz;
    80001dc6:	652c                	ld	a1,72(a0)
    80001dc8:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001dcc:	00904f63          	bgtz	s1,80001dea <growproc+0x3c>
  } else if(n < 0){
    80001dd0:	0204cc63          	bltz	s1,80001e08 <growproc+0x5a>
  p->sz = sz;
    80001dd4:	1602                	slli	a2,a2,0x20
    80001dd6:	9201                	srli	a2,a2,0x20
    80001dd8:	04c93423          	sd	a2,72(s2)
  return 0;
    80001ddc:	4501                	li	a0,0
}
    80001dde:	60e2                	ld	ra,24(sp)
    80001de0:	6442                	ld	s0,16(sp)
    80001de2:	64a2                	ld	s1,8(sp)
    80001de4:	6902                	ld	s2,0(sp)
    80001de6:	6105                	addi	sp,sp,32
    80001de8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dea:	9e25                	addw	a2,a2,s1
    80001dec:	1602                	slli	a2,a2,0x20
    80001dee:	9201                	srli	a2,a2,0x20
    80001df0:	1582                	slli	a1,a1,0x20
    80001df2:	9181                	srli	a1,a1,0x20
    80001df4:	6928                	ld	a0,80(a0)
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	62e080e7          	jalr	1582(ra) # 80001424 <uvmalloc>
    80001dfe:	0005061b          	sext.w	a2,a0
    80001e02:	fa69                	bnez	a2,80001dd4 <growproc+0x26>
      return -1;
    80001e04:	557d                	li	a0,-1
    80001e06:	bfe1                	j	80001dde <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e08:	9e25                	addw	a2,a2,s1
    80001e0a:	1602                	slli	a2,a2,0x20
    80001e0c:	9201                	srli	a2,a2,0x20
    80001e0e:	1582                	slli	a1,a1,0x20
    80001e10:	9181                	srli	a1,a1,0x20
    80001e12:	6928                	ld	a0,80(a0)
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	5c8080e7          	jalr	1480(ra) # 800013dc <uvmdealloc>
    80001e1c:	0005061b          	sext.w	a2,a0
    80001e20:	bf55                	j	80001dd4 <growproc+0x26>

0000000080001e22 <fork>:
{
    80001e22:	7179                	addi	sp,sp,-48
    80001e24:	f406                	sd	ra,40(sp)
    80001e26:	f022                	sd	s0,32(sp)
    80001e28:	ec26                	sd	s1,24(sp)
    80001e2a:	e84a                	sd	s2,16(sp)
    80001e2c:	e44e                	sd	s3,8(sp)
    80001e2e:	e052                	sd	s4,0(sp)
    80001e30:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	bd0080e7          	jalr	-1072(ra) # 80001a02 <myproc>
    80001e3a:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80001e3c:	00000097          	auipc	ra,0x0
    80001e40:	dd0080e7          	jalr	-560(ra) # 80001c0c <allocproc>
    80001e44:	16050f63          	beqz	a0,80001fc2 <fork+0x1a0>
    80001e48:	892a                	mv	s2,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e4a:	0489b603          	ld	a2,72(s3)
    80001e4e:	692c                	ld	a1,80(a0)
    80001e50:	0509b503          	ld	a0,80(s3)
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	71c080e7          	jalr	1820(ra) # 80001570 <uvmcopy>
    80001e5c:	04054663          	bltz	a0,80001ea8 <fork+0x86>
  np->sz = p->sz;
    80001e60:	0489b783          	ld	a5,72(s3)
    80001e64:	04f93423          	sd	a5,72(s2)
  *(np->trapframe) = *(p->trapframe);
    80001e68:	0589b683          	ld	a3,88(s3)
    80001e6c:	87b6                	mv	a5,a3
    80001e6e:	05893703          	ld	a4,88(s2)
    80001e72:	12068693          	addi	a3,a3,288
    80001e76:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e7a:	6788                	ld	a0,8(a5)
    80001e7c:	6b8c                	ld	a1,16(a5)
    80001e7e:	6f90                	ld	a2,24(a5)
    80001e80:	01073023          	sd	a6,0(a4)
    80001e84:	e708                	sd	a0,8(a4)
    80001e86:	eb0c                	sd	a1,16(a4)
    80001e88:	ef10                	sd	a2,24(a4)
    80001e8a:	02078793          	addi	a5,a5,32
    80001e8e:	02070713          	addi	a4,a4,32
    80001e92:	fed792e3          	bne	a5,a3,80001e76 <fork+0x54>
  np->trapframe->a0 = 0;
    80001e96:	05893783          	ld	a5,88(s2)
    80001e9a:	0607b823          	sd	zero,112(a5)
    80001e9e:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001ea2:	15000a13          	li	s4,336
    80001ea6:	a03d                	j	80001ed4 <fork+0xb2>
    freeproc(np);
    80001ea8:	854a                	mv	a0,s2
    80001eaa:	00000097          	auipc	ra,0x0
    80001eae:	d0a080e7          	jalr	-758(ra) # 80001bb4 <freeproc>
    release(&np->lock);
    80001eb2:	854a                	mv	a0,s2
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	de6080e7          	jalr	-538(ra) # 80000c9a <release>
    return -1;
    80001ebc:	5a7d                	li	s4,-1
    80001ebe:	a8cd                	j	80001fb0 <fork+0x18e>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ec0:	00003097          	auipc	ra,0x3
    80001ec4:	cce080e7          	jalr	-818(ra) # 80004b8e <filedup>
    80001ec8:	009907b3          	add	a5,s2,s1
    80001ecc:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ece:	04a1                	addi	s1,s1,8
    80001ed0:	01448763          	beq	s1,s4,80001ede <fork+0xbc>
    if(p->ofile[i])
    80001ed4:	009987b3          	add	a5,s3,s1
    80001ed8:	6388                	ld	a0,0(a5)
    80001eda:	f17d                	bnez	a0,80001ec0 <fork+0x9e>
    80001edc:	bfcd                	j	80001ece <fork+0xac>
  np->cwd = idup(p->cwd);
    80001ede:	1509b503          	ld	a0,336(s3)
    80001ee2:	00002097          	auipc	ra,0x2
    80001ee6:	e22080e7          	jalr	-478(ra) # 80003d04 <idup>
    80001eea:	14a93823          	sd	a0,336(s2)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001eee:	4641                	li	a2,16
    80001ef0:	15898593          	addi	a1,s3,344
    80001ef4:	15890513          	addi	a0,s2,344
    80001ef8:	fffff097          	auipc	ra,0xfffff
    80001efc:	f3c080e7          	jalr	-196(ra) # 80000e34 <safestrcpy>
  pid = np->pid;
    80001f00:	03092a03          	lw	s4,48(s2)
  np->last_ticks = 0;
    80001f04:	16092623          	sw	zero,364(s2)
  np->mean_ticks = 0;
    80001f08:	16092423          	sw	zero,360(s2)
  release(&np->lock);
    80001f0c:	854a                	mv	a0,s2
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	d8c080e7          	jalr	-628(ra) # 80000c9a <release>
  acquire(&wait_lock);
    80001f16:	0000f497          	auipc	s1,0xf
    80001f1a:	3c248493          	addi	s1,s1,962 # 800112d8 <wait_lock>
    80001f1e:	8526                	mv	a0,s1
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	cc6080e7          	jalr	-826(ra) # 80000be6 <acquire>
  np->parent = p;
    80001f28:	03393c23          	sd	s3,56(s2)
  release(&wait_lock);
    80001f2c:	8526                	mv	a0,s1
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	d6c080e7          	jalr	-660(ra) # 80000c9a <release>
  acquire(&np->lock);
    80001f36:	854a                	mv	a0,s2
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	cae080e7          	jalr	-850(ra) # 80000be6 <acquire>
  np->runnable_time = 0;
    80001f40:	16092e23          	sw	zero,380(s2)
  np->running_time = 0;
    80001f44:	16092c23          	sw	zero,376(s2)
  np -> sleeping_time = 0;
    80001f48:	16092a23          	sw	zero,372(s2)
  acquire(&tickslock);
    80001f4c:	00016517          	auipc	a0,0x16
    80001f50:	9a450513          	addi	a0,a0,-1628 # 800178f0 <tickslock>
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	c92080e7          	jalr	-878(ra) # 80000be6 <acquire>
  np->last_update_time = ticks;
    80001f5c:	00007497          	auipc	s1,0x7
    80001f60:	0f848493          	addi	s1,s1,248 # 80009054 <ticks>
    80001f64:	409c                	lw	a5,0(s1)
    80001f66:	18f92023          	sw	a5,384(s2)
  release(&tickslock);
    80001f6a:	00016517          	auipc	a0,0x16
    80001f6e:	98650513          	addi	a0,a0,-1658 # 800178f0 <tickslock>
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	d28080e7          	jalr	-728(ra) # 80000c9a <release>
  np->state = RUNNABLE;
    80001f7a:	478d                	li	a5,3
    80001f7c:	00f92c23          	sw	a5,24(s2)
  acquire(&tickslock);
    80001f80:	00016517          	auipc	a0,0x16
    80001f84:	97050513          	addi	a0,a0,-1680 # 800178f0 <tickslock>
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	c5e080e7          	jalr	-930(ra) # 80000be6 <acquire>
  p->last_runable_time = ticks;
    80001f90:	409c                	lw	a5,0(s1)
    80001f92:	16f9a823          	sw	a5,368(s3)
  release(&tickslock);
    80001f96:	00016517          	auipc	a0,0x16
    80001f9a:	95a50513          	addi	a0,a0,-1702 # 800178f0 <tickslock>
    80001f9e:	fffff097          	auipc	ra,0xfffff
    80001fa2:	cfc080e7          	jalr	-772(ra) # 80000c9a <release>
  release(&np->lock);
    80001fa6:	854a                	mv	a0,s2
    80001fa8:	fffff097          	auipc	ra,0xfffff
    80001fac:	cf2080e7          	jalr	-782(ra) # 80000c9a <release>
}
    80001fb0:	8552                	mv	a0,s4
    80001fb2:	70a2                	ld	ra,40(sp)
    80001fb4:	7402                	ld	s0,32(sp)
    80001fb6:	64e2                	ld	s1,24(sp)
    80001fb8:	6942                	ld	s2,16(sp)
    80001fba:	69a2                	ld	s3,8(sp)
    80001fbc:	6a02                	ld	s4,0(sp)
    80001fbe:	6145                	addi	sp,sp,48
    80001fc0:	8082                	ret
    return -1;
    80001fc2:	5a7d                	li	s4,-1
    80001fc4:	b7f5                	j	80001fb0 <fork+0x18e>

0000000080001fc6 <scheduler>:
{
    80001fc6:	7159                	addi	sp,sp,-112
    80001fc8:	f486                	sd	ra,104(sp)
    80001fca:	f0a2                	sd	s0,96(sp)
    80001fcc:	eca6                	sd	s1,88(sp)
    80001fce:	e8ca                	sd	s2,80(sp)
    80001fd0:	e4ce                	sd	s3,72(sp)
    80001fd2:	e0d2                	sd	s4,64(sp)
    80001fd4:	fc56                	sd	s5,56(sp)
    80001fd6:	f85a                	sd	s6,48(sp)
    80001fd8:	f45e                	sd	s7,40(sp)
    80001fda:	f062                	sd	s8,32(sp)
    80001fdc:	ec66                	sd	s9,24(sp)
    80001fde:	e86a                	sd	s10,16(sp)
    80001fe0:	e46e                	sd	s11,8(sp)
    80001fe2:	1880                	addi	s0,sp,112
    80001fe4:	8792                	mv	a5,tp
  int id = r_tp();
    80001fe6:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fe8:	00779d93          	slli	s11,a5,0x7
    80001fec:	0000f717          	auipc	a4,0xf
    80001ff0:	2d470713          	addi	a4,a4,724 # 800112c0 <pid_lock>
    80001ff4:	976e                	add	a4,a4,s11
    80001ff6:	02073823          	sd	zero,48(a4)
         swtch(&c->context, &hp->context);
    80001ffa:	0000f717          	auipc	a4,0xf
    80001ffe:	2fe70713          	addi	a4,a4,766 # 800112f8 <cpus+0x8>
    80002002:	9dba                	add	s11,s11,a4
    while(paused)
    80002004:	00007c17          	auipc	s8,0x7
    80002008:	028c0c13          	addi	s8,s8,40 # 8000902c <paused>
      if(ticks >= pause_interval)
    8000200c:	00007b97          	auipc	s7,0x7
    80002010:	048b8b93          	addi	s7,s7,72 # 80009054 <ticks>
         c->proc = hp;
    80002014:	079e                	slli	a5,a5,0x7
    80002016:	0000fb17          	auipc	s6,0xf
    8000201a:	2aab0b13          	addi	s6,s6,682 # 800112c0 <pid_lock>
    8000201e:	9b3e                	add	s6,s6,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002020:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002024:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002028:	10079073          	csrw	sstatus,a5
    while(paused)
    8000202c:	000c2783          	lw	a5,0(s8)
    80002030:	2781                	sext.w	a5,a5
    80002032:	cba1                	beqz	a5,80002082 <scheduler+0xbc>
      acquire(&tickslock);
    80002034:	00016497          	auipc	s1,0x16
    80002038:	8bc48493          	addi	s1,s1,-1860 # 800178f0 <tickslock>
      if(ticks >= pause_interval)
    8000203c:	00007917          	auipc	s2,0x7
    80002040:	fec90913          	addi	s2,s2,-20 # 80009028 <pause_interval>
    80002044:	a811                	j	80002058 <scheduler+0x92>
      release(&tickslock);
    80002046:	8526                	mv	a0,s1
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	c52080e7          	jalr	-942(ra) # 80000c9a <release>
    while(paused)
    80002050:	000c2783          	lw	a5,0(s8)
    80002054:	2781                	sext.w	a5,a5
    80002056:	c795                	beqz	a5,80002082 <scheduler+0xbc>
      acquire(&tickslock);
    80002058:	8526                	mv	a0,s1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	b8c080e7          	jalr	-1140(ra) # 80000be6 <acquire>
      if(ticks >= pause_interval)
    80002062:	00092783          	lw	a5,0(s2)
    80002066:	2781                	sext.w	a5,a5
    80002068:	000ba703          	lw	a4,0(s7)
    8000206c:	fcf76de3          	bltu	a4,a5,80002046 <scheduler+0x80>
        paused ^= paused;
    80002070:	000c2703          	lw	a4,0(s8)
    80002074:	000c2783          	lw	a5,0(s8)
    80002078:	8fb9                	xor	a5,a5,a4
    8000207a:	2781                	sext.w	a5,a5
    8000207c:	00fc2023          	sw	a5,0(s8)
    80002080:	b7d9                	j	80002046 <scheduler+0x80>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002082:	0000f917          	auipc	s2,0xf
    80002086:	66e90913          	addi	s2,s2,1646 # 800116f0 <proc>
      if(p->state == RUNNABLE) 
    8000208a:	4a8d                	li	s5,3
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    8000208c:	00016a17          	auipc	s4,0x16
    80002090:	864a0a13          	addi	s4,s4,-1948 # 800178f0 <tickslock>
          if(hp->state == RUNNING){
    80002094:	4d11                	li	s10,4
          if(hp->state == SLEEPING){
    80002096:	4c89                	li	s9,2
    80002098:	a06d                	j	80002142 <scheduler+0x17c>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    8000209a:	18890493          	addi	s1,s2,392
    8000209e:	0544f363          	bgeu	s1,s4,800020e4 <scheduler+0x11e>
    800020a2:	89ca                	mv	s3,s2
    800020a4:	a811                	j	800020b8 <scheduler+0xf2>
            release(&c->lock);
    800020a6:	8526                	mv	a0,s1
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	bf2080e7          	jalr	-1038(ra) # 80000c9a <release>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    800020b0:	18848493          	addi	s1,s1,392
    800020b4:	0344f963          	bgeu	s1,s4,800020e6 <scheduler+0x120>
           acquire(&c->lock);
    800020b8:	8526                	mv	a0,s1
    800020ba:	fffff097          	auipc	ra,0xfffff
    800020be:	b2c080e7          	jalr	-1236(ra) # 80000be6 <acquire>
           if((c->state == RUNNABLE) && (c->mean_ticks < hp->mean_ticks))
    800020c2:	4c9c                	lw	a5,24(s1)
    800020c4:	2781                	sext.w	a5,a5
    800020c6:	ff5790e3          	bne	a5,s5,800020a6 <scheduler+0xe0>
    800020ca:	1684a703          	lw	a4,360(s1)
    800020ce:	1689a783          	lw	a5,360(s3)
    800020d2:	fcf77ae3          	bgeu	a4,a5,800020a6 <scheduler+0xe0>
             release(&hp->lock);
    800020d6:	854e                	mv	a0,s3
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	bc2080e7          	jalr	-1086(ra) # 80000c9a <release>
             hp = c;
    800020e0:	89a6                	mv	s3,s1
    800020e2:	b7f9                	j	800020b0 <scheduler+0xea>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    800020e4:	89ca                	mv	s3,s2
          int diff = ticks - p->last_update_time;
    800020e6:	000ba703          	lw	a4,0(s7)
    800020ea:	18092783          	lw	a5,384(s2)
    800020ee:	40f707bb          	subw	a5,a4,a5
          p->last_update_time = ticks;
    800020f2:	18e92023          	sw	a4,384(s2)
          if(hp->state == RUNNABLE){
    800020f6:	0189a703          	lw	a4,24(s3)
    800020fa:	2701                	sext.w	a4,a4
    800020fc:	07570363          	beq	a4,s5,80002162 <scheduler+0x19c>
          if(hp->state == RUNNING){
    80002100:	0189a703          	lw	a4,24(s3)
    80002104:	2701                	sext.w	a4,a4
    80002106:	07a70463          	beq	a4,s10,8000216e <scheduler+0x1a8>
          if(hp->state == SLEEPING){
    8000210a:	0189a703          	lw	a4,24(s3)
    8000210e:	2701                	sext.w	a4,a4
    80002110:	07970563          	beq	a4,s9,8000217a <scheduler+0x1b4>
         hp->state = RUNNING;
    80002114:	4791                	li	a5,4
    80002116:	00f9ac23          	sw	a5,24(s3)
         c->proc = hp;
    8000211a:	033b3823          	sd	s3,48(s6)
         swtch(&c->context, &hp->context);
    8000211e:	06098593          	addi	a1,s3,96
    80002122:	856e                	mv	a0,s11
    80002124:	00001097          	auipc	ra,0x1
    80002128:	b6a080e7          	jalr	-1174(ra) # 80002c8e <swtch>
         c->proc = 0;
    8000212c:	020b3823          	sd	zero,48(s6)
         release(&hp->lock);          
    80002130:	854e                	mv	a0,s3
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	b68080e7          	jalr	-1176(ra) # 80000c9a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000213a:	18890913          	addi	s2,s2,392
    8000213e:	ef4901e3          	beq	s2,s4,80002020 <scheduler+0x5a>
      acquire(&p->lock);
    80002142:	854a                	mv	a0,s2
    80002144:	fffff097          	auipc	ra,0xfffff
    80002148:	aa2080e7          	jalr	-1374(ra) # 80000be6 <acquire>
      if(p->state == RUNNABLE) 
    8000214c:	01892783          	lw	a5,24(s2)
    80002150:	2781                	sext.w	a5,a5
    80002152:	f55784e3          	beq	a5,s5,8000209a <scheduler+0xd4>
        release(&p->lock);
    80002156:	854a                	mv	a0,s2
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	b42080e7          	jalr	-1214(ra) # 80000c9a <release>
    80002160:	bfe9                	j	8000213a <scheduler+0x174>
            hp->runnable_time += diff;
    80002162:	17c9a703          	lw	a4,380(s3)
    80002166:	9f3d                	addw	a4,a4,a5
    80002168:	16e9ae23          	sw	a4,380(s3)
    8000216c:	bf51                	j	80002100 <scheduler+0x13a>
            hp->running_time += diff;
    8000216e:	1789a703          	lw	a4,376(s3)
    80002172:	9f3d                	addw	a4,a4,a5
    80002174:	16e9ac23          	sw	a4,376(s3)
    80002178:	bf49                	j	8000210a <scheduler+0x144>
            hp->sleeping_time += diff;
    8000217a:	1749a703          	lw	a4,372(s3)
    8000217e:	9fb9                	addw	a5,a5,a4
    80002180:	16f9aa23          	sw	a5,372(s3)
    80002184:	bf41                	j	80002114 <scheduler+0x14e>

0000000080002186 <sched>:
{
    80002186:	7179                	addi	sp,sp,-48
    80002188:	f406                	sd	ra,40(sp)
    8000218a:	f022                	sd	s0,32(sp)
    8000218c:	ec26                	sd	s1,24(sp)
    8000218e:	e84a                	sd	s2,16(sp)
    80002190:	e44e                	sd	s3,8(sp)
    80002192:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002194:	00000097          	auipc	ra,0x0
    80002198:	86e080e7          	jalr	-1938(ra) # 80001a02 <myproc>
    8000219c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	9ce080e7          	jalr	-1586(ra) # 80000b6c <holding>
    800021a6:	cd25                	beqz	a0,8000221e <sched+0x98>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021a8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021aa:	2781                	sext.w	a5,a5
    800021ac:	079e                	slli	a5,a5,0x7
    800021ae:	0000f717          	auipc	a4,0xf
    800021b2:	11270713          	addi	a4,a4,274 # 800112c0 <pid_lock>
    800021b6:	97ba                	add	a5,a5,a4
    800021b8:	0a87a703          	lw	a4,168(a5)
    800021bc:	4785                	li	a5,1
    800021be:	06f71863          	bne	a4,a5,8000222e <sched+0xa8>
  if(p->state == RUNNING)
    800021c2:	4c9c                	lw	a5,24(s1)
    800021c4:	2781                	sext.w	a5,a5
    800021c6:	4711                	li	a4,4
    800021c8:	06e78b63          	beq	a5,a4,8000223e <sched+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021cc:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021d0:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021d2:	efb5                	bnez	a5,8000224e <sched+0xc8>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021d4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021d6:	0000f917          	auipc	s2,0xf
    800021da:	0ea90913          	addi	s2,s2,234 # 800112c0 <pid_lock>
    800021de:	2781                	sext.w	a5,a5
    800021e0:	079e                	slli	a5,a5,0x7
    800021e2:	97ca                	add	a5,a5,s2
    800021e4:	0ac7a983          	lw	s3,172(a5)
    800021e8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021ea:	2781                	sext.w	a5,a5
    800021ec:	079e                	slli	a5,a5,0x7
    800021ee:	0000f597          	auipc	a1,0xf
    800021f2:	10a58593          	addi	a1,a1,266 # 800112f8 <cpus+0x8>
    800021f6:	95be                	add	a1,a1,a5
    800021f8:	06048513          	addi	a0,s1,96
    800021fc:	00001097          	auipc	ra,0x1
    80002200:	a92080e7          	jalr	-1390(ra) # 80002c8e <swtch>
    80002204:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002206:	2781                	sext.w	a5,a5
    80002208:	079e                	slli	a5,a5,0x7
    8000220a:	97ca                	add	a5,a5,s2
    8000220c:	0b37a623          	sw	s3,172(a5)
}
    80002210:	70a2                	ld	ra,40(sp)
    80002212:	7402                	ld	s0,32(sp)
    80002214:	64e2                	ld	s1,24(sp)
    80002216:	6942                	ld	s2,16(sp)
    80002218:	69a2                	ld	s3,8(sp)
    8000221a:	6145                	addi	sp,sp,48
    8000221c:	8082                	ret
    panic("sched p->lock");
    8000221e:	00006517          	auipc	a0,0x6
    80002222:	ffa50513          	addi	a0,a0,-6 # 80008218 <digits+0x1d8>
    80002226:	ffffe097          	auipc	ra,0xffffe
    8000222a:	31a080e7          	jalr	794(ra) # 80000540 <panic>
    panic("sched locks");
    8000222e:	00006517          	auipc	a0,0x6
    80002232:	ffa50513          	addi	a0,a0,-6 # 80008228 <digits+0x1e8>
    80002236:	ffffe097          	auipc	ra,0xffffe
    8000223a:	30a080e7          	jalr	778(ra) # 80000540 <panic>
    panic("sched running");
    8000223e:	00006517          	auipc	a0,0x6
    80002242:	ffa50513          	addi	a0,a0,-6 # 80008238 <digits+0x1f8>
    80002246:	ffffe097          	auipc	ra,0xffffe
    8000224a:	2fa080e7          	jalr	762(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000224e:	00006517          	auipc	a0,0x6
    80002252:	ffa50513          	addi	a0,a0,-6 # 80008248 <digits+0x208>
    80002256:	ffffe097          	auipc	ra,0xffffe
    8000225a:	2ea080e7          	jalr	746(ra) # 80000540 <panic>

000000008000225e <yield>:
{
    8000225e:	1101                	addi	sp,sp,-32
    80002260:	ec06                	sd	ra,24(sp)
    80002262:	e822                	sd	s0,16(sp)
    80002264:	e426                	sd	s1,8(sp)
    80002266:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	79a080e7          	jalr	1946(ra) # 80001a02 <myproc>
    80002270:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	974080e7          	jalr	-1676(ra) # 80000be6 <acquire>
  int diff = ticks - p->last_update_time;
    8000227a:	00007717          	auipc	a4,0x7
    8000227e:	dda72703          	lw	a4,-550(a4) # 80009054 <ticks>
    80002282:	1804a783          	lw	a5,384(s1)
    80002286:	40f707bb          	subw	a5,a4,a5
  p->last_update_time = ticks;
    8000228a:	18e4a023          	sw	a4,384(s1)
  if(p->state == RUNNABLE){
    8000228e:	4c94                	lw	a3,24(s1)
    80002290:	2681                	sext.w	a3,a3
    80002292:	460d                	li	a2,3
    80002294:	02c68e63          	beq	a3,a2,800022d0 <yield+0x72>
  if(p->state == RUNNING){
    80002298:	4c94                	lw	a3,24(s1)
    8000229a:	2681                	sext.w	a3,a3
    8000229c:	4611                	li	a2,4
    8000229e:	02c68f63          	beq	a3,a2,800022dc <yield+0x7e>
  if(p->state == SLEEPING){
    800022a2:	4c94                	lw	a3,24(s1)
    800022a4:	2681                	sext.w	a3,a3
    800022a6:	4609                	li	a2,2
    800022a8:	04c68063          	beq	a3,a2,800022e8 <yield+0x8a>
  p->state = RUNNABLE;
    800022ac:	478d                	li	a5,3
    800022ae:	cc9c                	sw	a5,24(s1)
  p->last_runable_time = ticks;
    800022b0:	16e4a823          	sw	a4,368(s1)
  sched();
    800022b4:	00000097          	auipc	ra,0x0
    800022b8:	ed2080e7          	jalr	-302(ra) # 80002186 <sched>
  release(&p->lock);
    800022bc:	8526                	mv	a0,s1
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	9dc080e7          	jalr	-1572(ra) # 80000c9a <release>
}
    800022c6:	60e2                	ld	ra,24(sp)
    800022c8:	6442                	ld	s0,16(sp)
    800022ca:	64a2                	ld	s1,8(sp)
    800022cc:	6105                	addi	sp,sp,32
    800022ce:	8082                	ret
    p->runnable_time += diff;
    800022d0:	17c4a683          	lw	a3,380(s1)
    800022d4:	9ebd                	addw	a3,a3,a5
    800022d6:	16d4ae23          	sw	a3,380(s1)
    800022da:	bf7d                	j	80002298 <yield+0x3a>
    p->running_time += diff;
    800022dc:	1784a683          	lw	a3,376(s1)
    800022e0:	9ebd                	addw	a3,a3,a5
    800022e2:	16d4ac23          	sw	a3,376(s1)
    800022e6:	bf75                	j	800022a2 <yield+0x44>
    p->sleeping_time += diff;
    800022e8:	1744a683          	lw	a3,372(s1)
    800022ec:	9fb5                	addw	a5,a5,a3
    800022ee:	16f4aa23          	sw	a5,372(s1)
    800022f2:	bf6d                	j	800022ac <yield+0x4e>

00000000800022f4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800022f4:	7179                	addi	sp,sp,-48
    800022f6:	f406                	sd	ra,40(sp)
    800022f8:	f022                	sd	s0,32(sp)
    800022fa:	ec26                	sd	s1,24(sp)
    800022fc:	e84a                	sd	s2,16(sp)
    800022fe:	e44e                	sd	s3,8(sp)
    80002300:	1800                	addi	s0,sp,48
    80002302:	89aa                	mv	s3,a0
    80002304:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	6fc080e7          	jalr	1788(ra) # 80001a02 <myproc>
    8000230e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	8d6080e7          	jalr	-1834(ra) # 80000be6 <acquire>
  release(lk);
    80002318:	854a                	mv	a0,s2
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	980080e7          	jalr	-1664(ra) # 80000c9a <release>

  // Go to sleep.
  p->chan = chan;
    80002322:	0334b023          	sd	s3,32(s1)

  //calc thicks passed
  //acquire(&tickslock);
  int diff = ticks - p->last_update_time;
    80002326:	00007717          	auipc	a4,0x7
    8000232a:	d2e72703          	lw	a4,-722(a4) # 80009054 <ticks>
    8000232e:	1804a783          	lw	a5,384(s1)
    80002332:	40f707bb          	subw	a5,a4,a5
  //release(&tickslock);
  p->last_update_time = ticks;
    80002336:	18e4a023          	sw	a4,384(s1)

  if(p->state == RUNNABLE){
    8000233a:	4c98                	lw	a4,24(s1)
    8000233c:	2701                	sext.w	a4,a4
    8000233e:	468d                	li	a3,3
    80002340:	04d70563          	beq	a4,a3,8000238a <sleep+0x96>
    p->runnable_time += diff;
  }
  if(p->state == RUNNING){
    80002344:	4c98                	lw	a4,24(s1)
    80002346:	2701                	sext.w	a4,a4
    80002348:	4691                	li	a3,4
    8000234a:	04d70663          	beq	a4,a3,80002396 <sleep+0xa2>
    p->running_time += diff;
  }
  if(p->state == SLEEPING){
    8000234e:	4c98                	lw	a4,24(s1)
    80002350:	2701                	sext.w	a4,a4
    80002352:	4689                	li	a3,2
    80002354:	04d70763          	beq	a4,a3,800023a2 <sleep+0xae>
    p->sleeping_time += diff;
  }

  p->state = SLEEPING;
    80002358:	4789                	li	a5,2
    8000235a:	cc9c                	sw	a5,24(s1)

  sched();
    8000235c:	00000097          	auipc	ra,0x0
    80002360:	e2a080e7          	jalr	-470(ra) # 80002186 <sched>

  // Tidy up.
  p->chan = 0;
    80002364:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002368:	8526                	mv	a0,s1
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	930080e7          	jalr	-1744(ra) # 80000c9a <release>
  acquire(lk);
    80002372:	854a                	mv	a0,s2
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	872080e7          	jalr	-1934(ra) # 80000be6 <acquire>
}
    8000237c:	70a2                	ld	ra,40(sp)
    8000237e:	7402                	ld	s0,32(sp)
    80002380:	64e2                	ld	s1,24(sp)
    80002382:	6942                	ld	s2,16(sp)
    80002384:	69a2                	ld	s3,8(sp)
    80002386:	6145                	addi	sp,sp,48
    80002388:	8082                	ret
    p->runnable_time += diff;
    8000238a:	17c4a703          	lw	a4,380(s1)
    8000238e:	9f3d                	addw	a4,a4,a5
    80002390:	16e4ae23          	sw	a4,380(s1)
    80002394:	bf45                	j	80002344 <sleep+0x50>
    p->running_time += diff;
    80002396:	1784a703          	lw	a4,376(s1)
    8000239a:	9f3d                	addw	a4,a4,a5
    8000239c:	16e4ac23          	sw	a4,376(s1)
    800023a0:	b77d                	j	8000234e <sleep+0x5a>
    p->sleeping_time += diff;
    800023a2:	1744a703          	lw	a4,372(s1)
    800023a6:	9fb9                	addw	a5,a5,a4
    800023a8:	16f4aa23          	sw	a5,372(s1)
    800023ac:	b775                	j	80002358 <sleep+0x64>

00000000800023ae <wait>:
{
    800023ae:	715d                	addi	sp,sp,-80
    800023b0:	e486                	sd	ra,72(sp)
    800023b2:	e0a2                	sd	s0,64(sp)
    800023b4:	fc26                	sd	s1,56(sp)
    800023b6:	f84a                	sd	s2,48(sp)
    800023b8:	f44e                	sd	s3,40(sp)
    800023ba:	f052                	sd	s4,32(sp)
    800023bc:	ec56                	sd	s5,24(sp)
    800023be:	e85a                	sd	s6,16(sp)
    800023c0:	e45e                	sd	s7,8(sp)
    800023c2:	e062                	sd	s8,0(sp)
    800023c4:	0880                	addi	s0,sp,80
    800023c6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	63a080e7          	jalr	1594(ra) # 80001a02 <myproc>
    800023d0:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023d2:	0000f517          	auipc	a0,0xf
    800023d6:	f0650513          	addi	a0,a0,-250 # 800112d8 <wait_lock>
    800023da:	fffff097          	auipc	ra,0xfffff
    800023de:	80c080e7          	jalr	-2036(ra) # 80000be6 <acquire>
    havekids = 0;
    800023e2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023e4:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800023e6:	00015997          	auipc	s3,0x15
    800023ea:	50a98993          	addi	s3,s3,1290 # 800178f0 <tickslock>
        havekids = 1;
    800023ee:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023f0:	0000fc17          	auipc	s8,0xf
    800023f4:	ee8c0c13          	addi	s8,s8,-280 # 800112d8 <wait_lock>
    havekids = 0;
    800023f8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023fa:	0000f497          	auipc	s1,0xf
    800023fe:	2f648493          	addi	s1,s1,758 # 800116f0 <proc>
    80002402:	a0bd                	j	80002470 <wait+0xc2>
          pid = np->pid;
    80002404:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002408:	000b0e63          	beqz	s6,80002424 <wait+0x76>
    8000240c:	4691                	li	a3,4
    8000240e:	02c48613          	addi	a2,s1,44
    80002412:	85da                	mv	a1,s6
    80002414:	05093503          	ld	a0,80(s2)
    80002418:	fffff097          	auipc	ra,0xfffff
    8000241c:	25c080e7          	jalr	604(ra) # 80001674 <copyout>
    80002420:	02054563          	bltz	a0,8000244a <wait+0x9c>
          freeproc(np);
    80002424:	8526                	mv	a0,s1
    80002426:	fffff097          	auipc	ra,0xfffff
    8000242a:	78e080e7          	jalr	1934(ra) # 80001bb4 <freeproc>
          release(&np->lock);
    8000242e:	8526                	mv	a0,s1
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	86a080e7          	jalr	-1942(ra) # 80000c9a <release>
          release(&wait_lock);
    80002438:	0000f517          	auipc	a0,0xf
    8000243c:	ea050513          	addi	a0,a0,-352 # 800112d8 <wait_lock>
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	85a080e7          	jalr	-1958(ra) # 80000c9a <release>
          return pid;
    80002448:	a0ad                	j	800024b2 <wait+0x104>
            release(&np->lock);
    8000244a:	8526                	mv	a0,s1
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	84e080e7          	jalr	-1970(ra) # 80000c9a <release>
            release(&wait_lock);
    80002454:	0000f517          	auipc	a0,0xf
    80002458:	e8450513          	addi	a0,a0,-380 # 800112d8 <wait_lock>
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	83e080e7          	jalr	-1986(ra) # 80000c9a <release>
            return -1;
    80002464:	59fd                	li	s3,-1
    80002466:	a0b1                	j	800024b2 <wait+0x104>
    for(np = proc; np < &proc[NPROC]; np++){
    80002468:	18848493          	addi	s1,s1,392
    8000246c:	03348563          	beq	s1,s3,80002496 <wait+0xe8>
      if(np->parent == p){
    80002470:	7c9c                	ld	a5,56(s1)
    80002472:	ff279be3          	bne	a5,s2,80002468 <wait+0xba>
        acquire(&np->lock);
    80002476:	8526                	mv	a0,s1
    80002478:	ffffe097          	auipc	ra,0xffffe
    8000247c:	76e080e7          	jalr	1902(ra) # 80000be6 <acquire>
        if(np->state == ZOMBIE){
    80002480:	4c9c                	lw	a5,24(s1)
    80002482:	2781                	sext.w	a5,a5
    80002484:	f94780e3          	beq	a5,s4,80002404 <wait+0x56>
        release(&np->lock);
    80002488:	8526                	mv	a0,s1
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	810080e7          	jalr	-2032(ra) # 80000c9a <release>
        havekids = 1;
    80002492:	8756                	mv	a4,s5
    80002494:	bfd1                	j	80002468 <wait+0xba>
    if(!havekids || p->killed){
    80002496:	c709                	beqz	a4,800024a0 <wait+0xf2>
    80002498:	02892783          	lw	a5,40(s2)
    8000249c:	2781                	sext.w	a5,a5
    8000249e:	c79d                	beqz	a5,800024cc <wait+0x11e>
      release(&wait_lock);
    800024a0:	0000f517          	auipc	a0,0xf
    800024a4:	e3850513          	addi	a0,a0,-456 # 800112d8 <wait_lock>
    800024a8:	ffffe097          	auipc	ra,0xffffe
    800024ac:	7f2080e7          	jalr	2034(ra) # 80000c9a <release>
      return -1;
    800024b0:	59fd                	li	s3,-1
}
    800024b2:	854e                	mv	a0,s3
    800024b4:	60a6                	ld	ra,72(sp)
    800024b6:	6406                	ld	s0,64(sp)
    800024b8:	74e2                	ld	s1,56(sp)
    800024ba:	7942                	ld	s2,48(sp)
    800024bc:	79a2                	ld	s3,40(sp)
    800024be:	7a02                	ld	s4,32(sp)
    800024c0:	6ae2                	ld	s5,24(sp)
    800024c2:	6b42                	ld	s6,16(sp)
    800024c4:	6ba2                	ld	s7,8(sp)
    800024c6:	6c02                	ld	s8,0(sp)
    800024c8:	6161                	addi	sp,sp,80
    800024ca:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024cc:	85e2                	mv	a1,s8
    800024ce:	854a                	mv	a0,s2
    800024d0:	00000097          	auipc	ra,0x0
    800024d4:	e24080e7          	jalr	-476(ra) # 800022f4 <sleep>
    havekids = 0;
    800024d8:	b705                	j	800023f8 <wait+0x4a>

00000000800024da <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800024da:	711d                	addi	sp,sp,-96
    800024dc:	ec86                	sd	ra,88(sp)
    800024de:	e8a2                	sd	s0,80(sp)
    800024e0:	e4a6                	sd	s1,72(sp)
    800024e2:	e0ca                	sd	s2,64(sp)
    800024e4:	fc4e                	sd	s3,56(sp)
    800024e6:	f852                	sd	s4,48(sp)
    800024e8:	f456                	sd	s5,40(sp)
    800024ea:	f05a                	sd	s6,32(sp)
    800024ec:	ec5e                	sd	s7,24(sp)
    800024ee:	e862                	sd	s8,16(sp)
    800024f0:	e466                	sd	s9,8(sp)
    800024f2:	1080                	addi	s0,sp,96
    800024f4:	8aaa                	mv	s5,a0
  struct proc *p, *mp = myproc();
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	50c080e7          	jalr	1292(ra) # 80001a02 <myproc>
    800024fe:	892a                	mv	s2,a0

  for(p = proc; p < &proc[NPROC]; p++) {
    80002500:	0000f497          	auipc	s1,0xf
    80002504:	1f048493          	addi	s1,s1,496 # 800116f0 <proc>
    if(p != mp){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002508:	4a09                	li	s4,2
        //calc thicks passed
        //acquire(&tickslock);
        int diff = ticks - p->last_update_time;
    8000250a:	00007c97          	auipc	s9,0x7
    8000250e:	b4ac8c93          	addi	s9,s9,-1206 # 80009054 <ticks>
        //release(&tickslock);
        p->last_update_time = ticks;

        if(p->state == RUNNABLE){
    80002512:	4c0d                	li	s8,3
          p->runnable_time += diff;
        }
        if(p->state == RUNNING){
    80002514:	4b91                	li	s7,4
          p->running_time += diff;
        }
        if(p->state == SLEEPING){
          p->sleeping_time += diff;
        }
        p->state = RUNNABLE;
    80002516:	4b0d                	li	s6,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002518:	00015997          	auipc	s3,0x15
    8000251c:	3d898993          	addi	s3,s3,984 # 800178f0 <tickslock>
    80002520:	a815                	j	80002554 <wakeup+0x7a>
          p->runnable_time += diff;
    80002522:	17c4a683          	lw	a3,380(s1)
    80002526:	9ebd                	addw	a3,a3,a5
    80002528:	16d4ae23          	sw	a3,380(s1)
    8000252c:	a8b1                	j	80002588 <wakeup+0xae>
          p->running_time += diff;
    8000252e:	1784a683          	lw	a3,376(s1)
    80002532:	9ebd                	addw	a3,a3,a5
    80002534:	16d4ac23          	sw	a3,376(s1)
    80002538:	a8a1                	j	80002590 <wakeup+0xb6>
        p->state = RUNNABLE;
    8000253a:	0164ac23          	sw	s6,24(s1)
        /* FCFS */
        #ifdef FCFS
        //acquire(&tickslock);
        p->last_runable_time = ticks;
    8000253e:	16e4a823          	sw	a4,368(s1)
        //release(&tickslock);
        #endif
      }
      release(&p->lock);
    80002542:	8526                	mv	a0,s1
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	756080e7          	jalr	1878(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000254c:	18848493          	addi	s1,s1,392
    80002550:	05348a63          	beq	s1,s3,800025a4 <wakeup+0xca>
    if(p != mp){
    80002554:	fe990ce3          	beq	s2,s1,8000254c <wakeup+0x72>
      acquire(&p->lock);
    80002558:	8526                	mv	a0,s1
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	68c080e7          	jalr	1676(ra) # 80000be6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002562:	4c9c                	lw	a5,24(s1)
    80002564:	2781                	sext.w	a5,a5
    80002566:	fd479ee3          	bne	a5,s4,80002542 <wakeup+0x68>
    8000256a:	709c                	ld	a5,32(s1)
    8000256c:	fd579be3          	bne	a5,s5,80002542 <wakeup+0x68>
        int diff = ticks - p->last_update_time;
    80002570:	000ca703          	lw	a4,0(s9)
    80002574:	1804a783          	lw	a5,384(s1)
    80002578:	40f707bb          	subw	a5,a4,a5
        p->last_update_time = ticks;
    8000257c:	18e4a023          	sw	a4,384(s1)
        if(p->state == RUNNABLE){
    80002580:	4c94                	lw	a3,24(s1)
    80002582:	2681                	sext.w	a3,a3
    80002584:	f9868fe3          	beq	a3,s8,80002522 <wakeup+0x48>
        if(p->state == RUNNING){
    80002588:	4c94                	lw	a3,24(s1)
    8000258a:	2681                	sext.w	a3,a3
    8000258c:	fb7681e3          	beq	a3,s7,8000252e <wakeup+0x54>
        if(p->state == SLEEPING){
    80002590:	4c94                	lw	a3,24(s1)
    80002592:	2681                	sext.w	a3,a3
    80002594:	fb4693e3          	bne	a3,s4,8000253a <wakeup+0x60>
          p->sleeping_time += diff;
    80002598:	1744a683          	lw	a3,372(s1)
    8000259c:	9fb5                	addw	a5,a5,a3
    8000259e:	16f4aa23          	sw	a5,372(s1)
    800025a2:	bf61                	j	8000253a <wakeup+0x60>
    }
  }
}
    800025a4:	60e6                	ld	ra,88(sp)
    800025a6:	6446                	ld	s0,80(sp)
    800025a8:	64a6                	ld	s1,72(sp)
    800025aa:	6906                	ld	s2,64(sp)
    800025ac:	79e2                	ld	s3,56(sp)
    800025ae:	7a42                	ld	s4,48(sp)
    800025b0:	7aa2                	ld	s5,40(sp)
    800025b2:	7b02                	ld	s6,32(sp)
    800025b4:	6be2                	ld	s7,24(sp)
    800025b6:	6c42                	ld	s8,16(sp)
    800025b8:	6ca2                	ld	s9,8(sp)
    800025ba:	6125                	addi	sp,sp,96
    800025bc:	8082                	ret

00000000800025be <reparent>:
{
    800025be:	7179                	addi	sp,sp,-48
    800025c0:	f406                	sd	ra,40(sp)
    800025c2:	f022                	sd	s0,32(sp)
    800025c4:	ec26                	sd	s1,24(sp)
    800025c6:	e84a                	sd	s2,16(sp)
    800025c8:	e44e                	sd	s3,8(sp)
    800025ca:	e052                	sd	s4,0(sp)
    800025cc:	1800                	addi	s0,sp,48
    800025ce:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025d0:	0000f497          	auipc	s1,0xf
    800025d4:	12048493          	addi	s1,s1,288 # 800116f0 <proc>
      pp->parent = initproc;
    800025d8:	00007a17          	auipc	s4,0x7
    800025dc:	a58a0a13          	addi	s4,s4,-1448 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800025e0:	00015997          	auipc	s3,0x15
    800025e4:	31098993          	addi	s3,s3,784 # 800178f0 <tickslock>
    800025e8:	a029                	j	800025f2 <reparent+0x34>
    800025ea:	18848493          	addi	s1,s1,392
    800025ee:	01348d63          	beq	s1,s3,80002608 <reparent+0x4a>
    if(pp->parent == p){
    800025f2:	7c9c                	ld	a5,56(s1)
    800025f4:	ff279be3          	bne	a5,s2,800025ea <reparent+0x2c>
      pp->parent = initproc;
    800025f8:	000a3503          	ld	a0,0(s4)
    800025fc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800025fe:	00000097          	auipc	ra,0x0
    80002602:	edc080e7          	jalr	-292(ra) # 800024da <wakeup>
    80002606:	b7d5                	j	800025ea <reparent+0x2c>
}
    80002608:	70a2                	ld	ra,40(sp)
    8000260a:	7402                	ld	s0,32(sp)
    8000260c:	64e2                	ld	s1,24(sp)
    8000260e:	6942                	ld	s2,16(sp)
    80002610:	69a2                	ld	s3,8(sp)
    80002612:	6a02                	ld	s4,0(sp)
    80002614:	6145                	addi	sp,sp,48
    80002616:	8082                	ret

0000000080002618 <exit>:
{
    80002618:	7179                	addi	sp,sp,-48
    8000261a:	f406                	sd	ra,40(sp)
    8000261c:	f022                	sd	s0,32(sp)
    8000261e:	ec26                	sd	s1,24(sp)
    80002620:	e84a                	sd	s2,16(sp)
    80002622:	e44e                	sd	s3,8(sp)
    80002624:	e052                	sd	s4,0(sp)
    80002626:	1800                	addi	s0,sp,48
    80002628:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000262a:	fffff097          	auipc	ra,0xfffff
    8000262e:	3d8080e7          	jalr	984(ra) # 80001a02 <myproc>
    80002632:	892a                	mv	s2,a0
  if(p == initproc)
    80002634:	00007797          	auipc	a5,0x7
    80002638:	9fc7b783          	ld	a5,-1540(a5) # 80009030 <initproc>
    8000263c:	0d050493          	addi	s1,a0,208
    80002640:	15050993          	addi	s3,a0,336
    80002644:	02a79363          	bne	a5,a0,8000266a <exit+0x52>
    panic("init exiting");
    80002648:	00006517          	auipc	a0,0x6
    8000264c:	c1850513          	addi	a0,a0,-1000 # 80008260 <digits+0x220>
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	ef0080e7          	jalr	-272(ra) # 80000540 <panic>
      fileclose(f);
    80002658:	00002097          	auipc	ra,0x2
    8000265c:	588080e7          	jalr	1416(ra) # 80004be0 <fileclose>
      p->ofile[fd] = 0;
    80002660:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002664:	04a1                	addi	s1,s1,8
    80002666:	01348563          	beq	s1,s3,80002670 <exit+0x58>
    if(p->ofile[fd]){
    8000266a:	6088                	ld	a0,0(s1)
    8000266c:	f575                	bnez	a0,80002658 <exit+0x40>
    8000266e:	bfdd                	j	80002664 <exit+0x4c>
  begin_op();
    80002670:	00002097          	auipc	ra,0x2
    80002674:	0a4080e7          	jalr	164(ra) # 80004714 <begin_op>
  iput(p->cwd);
    80002678:	15093503          	ld	a0,336(s2)
    8000267c:	00002097          	auipc	ra,0x2
    80002680:	880080e7          	jalr	-1920(ra) # 80003efc <iput>
  end_op();
    80002684:	00002097          	auipc	ra,0x2
    80002688:	110080e7          	jalr	272(ra) # 80004794 <end_op>
  p->cwd = 0;
    8000268c:	14093823          	sd	zero,336(s2)
  acquire(&wait_lock);
    80002690:	0000f517          	auipc	a0,0xf
    80002694:	c4850513          	addi	a0,a0,-952 # 800112d8 <wait_lock>
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	54e080e7          	jalr	1358(ra) # 80000be6 <acquire>
  reparent(p);
    800026a0:	854a                	mv	a0,s2
    800026a2:	00000097          	auipc	ra,0x0
    800026a6:	f1c080e7          	jalr	-228(ra) # 800025be <reparent>
  wakeup(p->parent);
    800026aa:	03893503          	ld	a0,56(s2)
    800026ae:	00000097          	auipc	ra,0x0
    800026b2:	e2c080e7          	jalr	-468(ra) # 800024da <wakeup>
  acquire(&p->lock);
    800026b6:	854a                	mv	a0,s2
    800026b8:	ffffe097          	auipc	ra,0xffffe
    800026bc:	52e080e7          	jalr	1326(ra) # 80000be6 <acquire>
  p->xstate = status;
    800026c0:	03492623          	sw	s4,44(s2)
  int diff = ticks - p->last_update_time;
    800026c4:	00007717          	auipc	a4,0x7
    800026c8:	99072703          	lw	a4,-1648(a4) # 80009054 <ticks>
    800026cc:	18092783          	lw	a5,384(s2)
    800026d0:	40f707bb          	subw	a5,a4,a5
  p->last_update_time = ticks;
    800026d4:	18e92023          	sw	a4,384(s2)
  if(p->state == RUNNABLE){
    800026d8:	01892703          	lw	a4,24(s2)
    800026dc:	2701                	sext.w	a4,a4
    800026de:	468d                	li	a3,3
    800026e0:	10d70c63          	beq	a4,a3,800027f8 <exit+0x1e0>
  if(p->state == RUNNING){
    800026e4:	01892703          	lw	a4,24(s2)
    800026e8:	2701                	sext.w	a4,a4
    800026ea:	4691                	li	a3,4
    800026ec:	10d70c63          	beq	a4,a3,80002804 <exit+0x1ec>
  if(p->state == SLEEPING){
    800026f0:	01892703          	lw	a4,24(s2)
    800026f4:	2701                	sext.w	a4,a4
    800026f6:	4689                	li	a3,2
    800026f8:	10d70c63          	beq	a4,a3,80002810 <exit+0x1f8>
  process_count++;
    800026fc:	00007797          	auipc	a5,0x7
    80002700:	94878793          	addi	a5,a5,-1720 # 80009044 <process_count>
    80002704:	0007a803          	lw	a6,0(a5)
    80002708:	0018051b          	addiw	a0,a6,1
    8000270c:	c388                	sw	a0,0(a5)
  running_processes_mean = ((running_processes_mean * (process_count - 1)) + p->running_time)/ process_count;
    8000270e:	17892583          	lw	a1,376(s2)
    80002712:	00007797          	auipc	a5,0x7
    80002716:	93a78793          	addi	a5,a5,-1734 # 8000904c <running_processes_mean>
    8000271a:	4398                	lw	a4,0(a5)
    8000271c:	0307073b          	mulw	a4,a4,a6
    80002720:	9f2d                	addw	a4,a4,a1
    80002722:	02a7573b          	divuw	a4,a4,a0
    80002726:	c398                	sw	a4,0(a5)
  runnable_processes_mean = ((runnable_processes_mean * (process_count - 1)) + p->runnable_time) / process_count;
    80002728:	17c92603          	lw	a2,380(s2)
    8000272c:	00007797          	auipc	a5,0x7
    80002730:	91c78793          	addi	a5,a5,-1764 # 80009048 <runnable_processes_mean>
    80002734:	4398                	lw	a4,0(a5)
    80002736:	0307073b          	mulw	a4,a4,a6
    8000273a:	9f31                	addw	a4,a4,a2
    8000273c:	02a7573b          	divuw	a4,a4,a0
    80002740:	c398                	sw	a4,0(a5)
  sleeping_processes_mean = ((sleeping_processes_mean * (process_count - 1)) + p->sleeping_time) / process_count;
    80002742:	17492683          	lw	a3,372(s2)
    80002746:	00007717          	auipc	a4,0x7
    8000274a:	90a70713          	addi	a4,a4,-1782 # 80009050 <sleeping_processes_mean>
    8000274e:	431c                	lw	a5,0(a4)
    80002750:	030787bb          	mulw	a5,a5,a6
    80002754:	9fb5                	addw	a5,a5,a3
    80002756:	02a7d7bb          	divuw	a5,a5,a0
    8000275a:	c31c                	sw	a5,0(a4)
  printf("###%d, %d, %d###\n", p->running_time, p->runnable_time, p->sleeping_time);
    8000275c:	00006517          	auipc	a0,0x6
    80002760:	b1450513          	addi	a0,a0,-1260 # 80008270 <digits+0x230>
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	e26080e7          	jalr	-474(ra) # 8000058a <printf>
  program_time += p->running_time;
    8000276c:	00007497          	auipc	s1,0x7
    80002770:	8d448493          	addi	s1,s1,-1836 # 80009040 <program_time>
    80002774:	17892583          	lw	a1,376(s2)
    80002778:	409c                	lw	a5,0(s1)
    8000277a:	9dbd                	addw	a1,a1,a5
    8000277c:	c08c                	sw	a1,0(s1)
  printf("@@@%d, %d@@@\n", program_time, ticks - start_time);
    8000277e:	00007a17          	auipc	s4,0x7
    80002782:	8d6a0a13          	addi	s4,s4,-1834 # 80009054 <ticks>
    80002786:	00007997          	auipc	s3,0x7
    8000278a:	8b298993          	addi	s3,s3,-1870 # 80009038 <start_time>
    8000278e:	000a2603          	lw	a2,0(s4)
    80002792:	0009a783          	lw	a5,0(s3)
    80002796:	9e1d                	subw	a2,a2,a5
    80002798:	2581                	sext.w	a1,a1
    8000279a:	00006517          	auipc	a0,0x6
    8000279e:	aee50513          	addi	a0,a0,-1298 # 80008288 <digits+0x248>
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	de8080e7          	jalr	-536(ra) # 8000058a <printf>
  cpu_utilization = program_time * 100 / (ticks - start_time);
    800027aa:	4098                	lw	a4,0(s1)
    800027ac:	06400793          	li	a5,100
    800027b0:	02e787bb          	mulw	a5,a5,a4
    800027b4:	000a2703          	lw	a4,0(s4)
    800027b8:	0009a683          	lw	a3,0(s3)
    800027bc:	9f15                	subw	a4,a4,a3
    800027be:	02e7d7bb          	divuw	a5,a5,a4
    800027c2:	00007717          	auipc	a4,0x7
    800027c6:	86f72d23          	sw	a5,-1926(a4) # 8000903c <cpu_utilization>
  p->state = ZOMBIE;
    800027ca:	4795                	li	a5,5
    800027cc:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    800027d0:	0000f517          	auipc	a0,0xf
    800027d4:	b0850513          	addi	a0,a0,-1272 # 800112d8 <wait_lock>
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	4c2080e7          	jalr	1218(ra) # 80000c9a <release>
  sched();
    800027e0:	00000097          	auipc	ra,0x0
    800027e4:	9a6080e7          	jalr	-1626(ra) # 80002186 <sched>
  panic("zombie exit");
    800027e8:	00006517          	auipc	a0,0x6
    800027ec:	ab050513          	addi	a0,a0,-1360 # 80008298 <digits+0x258>
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	d50080e7          	jalr	-688(ra) # 80000540 <panic>
    p->runnable_time += diff;
    800027f8:	17c92703          	lw	a4,380(s2)
    800027fc:	9f3d                	addw	a4,a4,a5
    800027fe:	16e92e23          	sw	a4,380(s2)
    80002802:	b5cd                	j	800026e4 <exit+0xcc>
    p->running_time += diff;
    80002804:	17892703          	lw	a4,376(s2)
    80002808:	9f3d                	addw	a4,a4,a5
    8000280a:	16e92c23          	sw	a4,376(s2)
    8000280e:	b5cd                	j	800026f0 <exit+0xd8>
    p->sleeping_time += diff;
    80002810:	17492703          	lw	a4,372(s2)
    80002814:	9fb9                	addw	a5,a5,a4
    80002816:	16f92a23          	sw	a5,372(s2)
    8000281a:	b5cd                	j	800026fc <exit+0xe4>

000000008000281c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000281c:	7179                	addi	sp,sp,-48
    8000281e:	f406                	sd	ra,40(sp)
    80002820:	f022                	sd	s0,32(sp)
    80002822:	ec26                	sd	s1,24(sp)
    80002824:	e84a                	sd	s2,16(sp)
    80002826:	e44e                	sd	s3,8(sp)
    80002828:	1800                	addi	s0,sp,48
    8000282a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000282c:	0000f497          	auipc	s1,0xf
    80002830:	ec448493          	addi	s1,s1,-316 # 800116f0 <proc>
    80002834:	00015997          	auipc	s3,0x15
    80002838:	0bc98993          	addi	s3,s3,188 # 800178f0 <tickslock>
    acquire(&p->lock);
    8000283c:	8526                	mv	a0,s1
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	3a8080e7          	jalr	936(ra) # 80000be6 <acquire>
    if(p->pid == pid){
    80002846:	589c                	lw	a5,48(s1)
    80002848:	01278d63          	beq	a5,s2,80002862 <kill+0x46>
        #endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000284c:	8526                	mv	a0,s1
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	44c080e7          	jalr	1100(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002856:	18848493          	addi	s1,s1,392
    8000285a:	ff3491e3          	bne	s1,s3,8000283c <kill+0x20>
  }
  return -1;
    8000285e:	557d                	li	a0,-1
    80002860:	a831                	j	8000287c <kill+0x60>
      p->killed = 1;
    80002862:	4785                	li	a5,1
    80002864:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002866:	4c9c                	lw	a5,24(s1)
    80002868:	2781                	sext.w	a5,a5
    8000286a:	4709                	li	a4,2
    8000286c:	00e78f63          	beq	a5,a4,8000288a <kill+0x6e>
      release(&p->lock);
    80002870:	8526                	mv	a0,s1
    80002872:	ffffe097          	auipc	ra,0xffffe
    80002876:	428080e7          	jalr	1064(ra) # 80000c9a <release>
      return 0;
    8000287a:	4501                	li	a0,0
}
    8000287c:	70a2                	ld	ra,40(sp)
    8000287e:	7402                	ld	s0,32(sp)
    80002880:	64e2                	ld	s1,24(sp)
    80002882:	6942                	ld	s2,16(sp)
    80002884:	69a2                	ld	s3,8(sp)
    80002886:	6145                	addi	sp,sp,48
    80002888:	8082                	ret
        int diff = ticks - p->last_update_time;
    8000288a:	00006797          	auipc	a5,0x6
    8000288e:	7ca7a783          	lw	a5,1994(a5) # 80009054 <ticks>
    80002892:	1804a703          	lw	a4,384(s1)
    80002896:	40e7873b          	subw	a4,a5,a4
        p->last_update_time = ticks;
    8000289a:	18f4a023          	sw	a5,384(s1)
        if(p->state == RUNNABLE){
    8000289e:	4c94                	lw	a3,24(s1)
    800028a0:	2681                	sext.w	a3,a3
    800028a2:	460d                	li	a2,3
    800028a4:	02c68163          	beq	a3,a2,800028c6 <kill+0xaa>
        if(p->state == RUNNING){
    800028a8:	4c94                	lw	a3,24(s1)
    800028aa:	2681                	sext.w	a3,a3
    800028ac:	4611                	li	a2,4
    800028ae:	02c68263          	beq	a3,a2,800028d2 <kill+0xb6>
        if(p->state == SLEEPING){
    800028b2:	4c94                	lw	a3,24(s1)
    800028b4:	2681                	sext.w	a3,a3
    800028b6:	4609                	li	a2,2
    800028b8:	02c68363          	beq	a3,a2,800028de <kill+0xc2>
        p->state = RUNNABLE;
    800028bc:	470d                	li	a4,3
    800028be:	cc98                	sw	a4,24(s1)
        p->last_runable_time = ticks;
    800028c0:	16f4a823          	sw	a5,368(s1)
    800028c4:	b775                	j	80002870 <kill+0x54>
          p->runnable_time += diff;
    800028c6:	17c4a683          	lw	a3,380(s1)
    800028ca:	9eb9                	addw	a3,a3,a4
    800028cc:	16d4ae23          	sw	a3,380(s1)
    800028d0:	bfe1                	j	800028a8 <kill+0x8c>
          p->running_time += diff;
    800028d2:	1784a683          	lw	a3,376(s1)
    800028d6:	9eb9                	addw	a3,a3,a4
    800028d8:	16d4ac23          	sw	a3,376(s1)
    800028dc:	bfd9                	j	800028b2 <kill+0x96>
          p->sleeping_time += diff;
    800028de:	1744a683          	lw	a3,372(s1)
    800028e2:	9f35                	addw	a4,a4,a3
    800028e4:	16e4aa23          	sw	a4,372(s1)
    800028e8:	bfd1                	j	800028bc <kill+0xa0>

00000000800028ea <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800028ea:	7179                	addi	sp,sp,-48
    800028ec:	f406                	sd	ra,40(sp)
    800028ee:	f022                	sd	s0,32(sp)
    800028f0:	ec26                	sd	s1,24(sp)
    800028f2:	e84a                	sd	s2,16(sp)
    800028f4:	e44e                	sd	s3,8(sp)
    800028f6:	e052                	sd	s4,0(sp)
    800028f8:	1800                	addi	s0,sp,48
    800028fa:	84aa                	mv	s1,a0
    800028fc:	892e                	mv	s2,a1
    800028fe:	89b2                	mv	s3,a2
    80002900:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002902:	fffff097          	auipc	ra,0xfffff
    80002906:	100080e7          	jalr	256(ra) # 80001a02 <myproc>
  if(user_dst){
    8000290a:	c08d                	beqz	s1,8000292c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000290c:	86d2                	mv	a3,s4
    8000290e:	864e                	mv	a2,s3
    80002910:	85ca                	mv	a1,s2
    80002912:	6928                	ld	a0,80(a0)
    80002914:	fffff097          	auipc	ra,0xfffff
    80002918:	d60080e7          	jalr	-672(ra) # 80001674 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000291c:	70a2                	ld	ra,40(sp)
    8000291e:	7402                	ld	s0,32(sp)
    80002920:	64e2                	ld	s1,24(sp)
    80002922:	6942                	ld	s2,16(sp)
    80002924:	69a2                	ld	s3,8(sp)
    80002926:	6a02                	ld	s4,0(sp)
    80002928:	6145                	addi	sp,sp,48
    8000292a:	8082                	ret
    memmove((char *)dst, src, len);
    8000292c:	000a061b          	sext.w	a2,s4
    80002930:	85ce                	mv	a1,s3
    80002932:	854a                	mv	a0,s2
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	40e080e7          	jalr	1038(ra) # 80000d42 <memmove>
    return 0;
    8000293c:	8526                	mv	a0,s1
    8000293e:	bff9                	j	8000291c <either_copyout+0x32>

0000000080002940 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002940:	7179                	addi	sp,sp,-48
    80002942:	f406                	sd	ra,40(sp)
    80002944:	f022                	sd	s0,32(sp)
    80002946:	ec26                	sd	s1,24(sp)
    80002948:	e84a                	sd	s2,16(sp)
    8000294a:	e44e                	sd	s3,8(sp)
    8000294c:	e052                	sd	s4,0(sp)
    8000294e:	1800                	addi	s0,sp,48
    80002950:	892a                	mv	s2,a0
    80002952:	84ae                	mv	s1,a1
    80002954:	89b2                	mv	s3,a2
    80002956:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002958:	fffff097          	auipc	ra,0xfffff
    8000295c:	0aa080e7          	jalr	170(ra) # 80001a02 <myproc>
  if(user_src){
    80002960:	c08d                	beqz	s1,80002982 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002962:	86d2                	mv	a3,s4
    80002964:	864e                	mv	a2,s3
    80002966:	85ca                	mv	a1,s2
    80002968:	6928                	ld	a0,80(a0)
    8000296a:	fffff097          	auipc	ra,0xfffff
    8000296e:	d96080e7          	jalr	-618(ra) # 80001700 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002972:	70a2                	ld	ra,40(sp)
    80002974:	7402                	ld	s0,32(sp)
    80002976:	64e2                	ld	s1,24(sp)
    80002978:	6942                	ld	s2,16(sp)
    8000297a:	69a2                	ld	s3,8(sp)
    8000297c:	6a02                	ld	s4,0(sp)
    8000297e:	6145                	addi	sp,sp,48
    80002980:	8082                	ret
    memmove(dst, (char*)src, len);
    80002982:	000a061b          	sext.w	a2,s4
    80002986:	85ce                	mv	a1,s3
    80002988:	854a                	mv	a0,s2
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	3b8080e7          	jalr	952(ra) # 80000d42 <memmove>
    return 0;
    80002992:	8526                	mv	a0,s1
    80002994:	bff9                	j	80002972 <either_copyin+0x32>

0000000080002996 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002996:	715d                	addi	sp,sp,-80
    80002998:	e486                	sd	ra,72(sp)
    8000299a:	e0a2                	sd	s0,64(sp)
    8000299c:	fc26                	sd	s1,56(sp)
    8000299e:	f84a                	sd	s2,48(sp)
    800029a0:	f44e                	sd	s3,40(sp)
    800029a2:	f052                	sd	s4,32(sp)
    800029a4:	ec56                	sd	s5,24(sp)
    800029a6:	e85a                	sd	s6,16(sp)
    800029a8:	e45e                	sd	s7,8(sp)
    800029aa:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800029ac:	00006517          	auipc	a0,0x6
    800029b0:	8d450513          	addi	a0,a0,-1836 # 80008280 <digits+0x240>
    800029b4:	ffffe097          	auipc	ra,0xffffe
    800029b8:	bd6080e7          	jalr	-1066(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800029bc:	0000f497          	auipc	s1,0xf
    800029c0:	d3448493          	addi	s1,s1,-716 # 800116f0 <proc>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029c4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800029c6:	00006917          	auipc	s2,0x6
    800029ca:	8e290913          	addi	s2,s2,-1822 # 800082a8 <digits+0x268>
    printf("%d %s %s", p->pid, state, p->name);
    800029ce:	00006a97          	auipc	s5,0x6
    800029d2:	8e2a8a93          	addi	s5,s5,-1822 # 800082b0 <digits+0x270>
    printf("\n");
    800029d6:	00006a17          	auipc	s4,0x6
    800029da:	8aaa0a13          	addi	s4,s4,-1878 # 80008280 <digits+0x240>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029de:	00006b97          	auipc	s7,0x6
    800029e2:	a3ab8b93          	addi	s7,s7,-1478 # 80008418 <states.1746>
  for(p = proc; p < &proc[NPROC]; p++){
    800029e6:	00015997          	auipc	s3,0x15
    800029ea:	f0a98993          	addi	s3,s3,-246 # 800178f0 <tickslock>
    800029ee:	a015                	j	80002a12 <procdump+0x7c>
    printf("%d %s %s", p->pid, state, p->name);
    800029f0:	15848693          	addi	a3,s1,344
    800029f4:	588c                	lw	a1,48(s1)
    800029f6:	8556                	mv	a0,s5
    800029f8:	ffffe097          	auipc	ra,0xffffe
    800029fc:	b92080e7          	jalr	-1134(ra) # 8000058a <printf>
    printf("\n");
    80002a00:	8552                	mv	a0,s4
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	b88080e7          	jalr	-1144(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002a0a:	18848493          	addi	s1,s1,392
    80002a0e:	03348963          	beq	s1,s3,80002a40 <procdump+0xaa>
    if(p->state == UNUSED)
    80002a12:	4c9c                	lw	a5,24(s1)
    80002a14:	2781                	sext.w	a5,a5
    80002a16:	dbf5                	beqz	a5,80002a0a <procdump+0x74>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a18:	4c9c                	lw	a5,24(s1)
    80002a1a:	4c9c                	lw	a5,24(s1)
    80002a1c:	2781                	sext.w	a5,a5
      state = "???";
    80002a1e:	864a                	mv	a2,s2
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a20:	fcfb68e3          	bltu	s6,a5,800029f0 <procdump+0x5a>
    80002a24:	4c9c                	lw	a5,24(s1)
    80002a26:	1782                	slli	a5,a5,0x20
    80002a28:	9381                	srli	a5,a5,0x20
    80002a2a:	078e                	slli	a5,a5,0x3
    80002a2c:	97de                	add	a5,a5,s7
    80002a2e:	639c                	ld	a5,0(a5)
    80002a30:	d3e1                	beqz	a5,800029f0 <procdump+0x5a>
      state = states[p->state];
    80002a32:	4c9c                	lw	a5,24(s1)
    80002a34:	1782                	slli	a5,a5,0x20
    80002a36:	9381                	srli	a5,a5,0x20
    80002a38:	078e                	slli	a5,a5,0x3
    80002a3a:	97de                	add	a5,a5,s7
    80002a3c:	6390                	ld	a2,0(a5)
    80002a3e:	bf4d                	j	800029f0 <procdump+0x5a>
  }
}
    80002a40:	60a6                	ld	ra,72(sp)
    80002a42:	6406                	ld	s0,64(sp)
    80002a44:	74e2                	ld	s1,56(sp)
    80002a46:	7942                	ld	s2,48(sp)
    80002a48:	79a2                	ld	s3,40(sp)
    80002a4a:	7a02                	ld	s4,32(sp)
    80002a4c:	6ae2                	ld	s5,24(sp)
    80002a4e:	6b42                	ld	s6,16(sp)
    80002a50:	6ba2                	ld	s7,8(sp)
    80002a52:	6161                	addi	sp,sp,80
    80002a54:	8082                	ret

0000000080002a56 <pause_system>:

int
pause_system(const int seconds)
{
    80002a56:	1101                	addi	sp,sp,-32
    80002a58:	ec06                	sd	ra,24(sp)
    80002a5a:	e822                	sd	s0,16(sp)
    80002a5c:	e426                	sd	s1,8(sp)
    80002a5e:	e04a                	sd	s2,0(sp)
    80002a60:	1000                	addi	s0,sp,32
    80002a62:	892a                	mv	s2,a0
  while(paused)
    80002a64:	00006797          	auipc	a5,0x6
    80002a68:	5c87a783          	lw	a5,1480(a5) # 8000902c <paused>
    80002a6c:	cf81                	beqz	a5,80002a84 <pause_system+0x2e>
    80002a6e:	00006497          	auipc	s1,0x6
    80002a72:	5be48493          	addi	s1,s1,1470 # 8000902c <paused>
    yield();
    80002a76:	fffff097          	auipc	ra,0xfffff
    80002a7a:	7e8080e7          	jalr	2024(ra) # 8000225e <yield>
  while(paused)
    80002a7e:	409c                	lw	a5,0(s1)
    80002a80:	2781                	sext.w	a5,a5
    80002a82:	fbf5                	bnez	a5,80002a76 <pause_system+0x20>

  // print for debug
  struct proc* p = myproc();
    80002a84:	fffff097          	auipc	ra,0xfffff
    80002a88:	f7e080e7          	jalr	-130(ra) # 80001a02 <myproc>
  if(p->killed)
    80002a8c:	5504                	lw	s1,40(a0)
    80002a8e:	2481                	sext.w	s1,s1
    80002a90:	e0a5                	bnez	s1,80002af0 <pause_system+0x9a>
  {
    printf("Pronc: %s, number: %d died during pause_sytem execution\n", p->name, p->pid);
    return -1;  
  }

  printf("Proc: %s, number: %d pause system\n", p->name, p->pid);
    80002a92:	5910                	lw	a2,48(a0)
    80002a94:	15850593          	addi	a1,a0,344
    80002a98:	00006517          	auipc	a0,0x6
    80002a9c:	86850513          	addi	a0,a0,-1944 # 80008300 <digits+0x2c0>
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	aea080e7          	jalr	-1302(ra) # 8000058a <printf>

  paused |= 1;
    80002aa8:	00006797          	auipc	a5,0x6
    80002aac:	5847a783          	lw	a5,1412(a5) # 8000902c <paused>
    80002ab0:	0017e793          	ori	a5,a5,1
    80002ab4:	00006717          	auipc	a4,0x6
    80002ab8:	56f72c23          	sw	a5,1400(a4) # 8000902c <paused>
  //acquire(&tickslock);
  pause_interval = ticks + (seconds * 10);
    80002abc:	0029179b          	slliw	a5,s2,0x2
    80002ac0:	012787bb          	addw	a5,a5,s2
    80002ac4:	0017979b          	slliw	a5,a5,0x1
    80002ac8:	00006717          	auipc	a4,0x6
    80002acc:	58c72703          	lw	a4,1420(a4) # 80009054 <ticks>
    80002ad0:	9fb9                	addw	a5,a5,a4
    80002ad2:	00006717          	auipc	a4,0x6
    80002ad6:	54f72b23          	sw	a5,1366(a4) # 80009028 <pause_interval>
  //release(&tickslock);

  yield();
    80002ada:	fffff097          	auipc	ra,0xfffff
    80002ade:	784080e7          	jalr	1924(ra) # 8000225e <yield>
  return 0;
}
    80002ae2:	8526                	mv	a0,s1
    80002ae4:	60e2                	ld	ra,24(sp)
    80002ae6:	6442                	ld	s0,16(sp)
    80002ae8:	64a2                	ld	s1,8(sp)
    80002aea:	6902                	ld	s2,0(sp)
    80002aec:	6105                	addi	sp,sp,32
    80002aee:	8082                	ret
    printf("Pronc: %s, number: %d died during pause_sytem execution\n", p->name, p->pid);
    80002af0:	5910                	lw	a2,48(a0)
    80002af2:	15850593          	addi	a1,a0,344
    80002af6:	00005517          	auipc	a0,0x5
    80002afa:	7ca50513          	addi	a0,a0,1994 # 800082c0 <digits+0x280>
    80002afe:	ffffe097          	auipc	ra,0xffffe
    80002b02:	a8c080e7          	jalr	-1396(ra) # 8000058a <printf>
    return -1;  
    80002b06:	54fd                	li	s1,-1
    80002b08:	bfe9                	j	80002ae2 <pause_system+0x8c>

0000000080002b0a <kill_system>:

#define INIT_SH_PROC 2
int 
kill_system(void)
{
    80002b0a:	711d                	addi	sp,sp,-96
    80002b0c:	ec86                	sd	ra,88(sp)
    80002b0e:	e8a2                	sd	s0,80(sp)
    80002b10:	e4a6                	sd	s1,72(sp)
    80002b12:	e0ca                	sd	s2,64(sp)
    80002b14:	fc4e                	sd	s3,56(sp)
    80002b16:	f852                	sd	s4,48(sp)
    80002b18:	f456                	sd	s5,40(sp)
    80002b1a:	f05a                	sd	s6,32(sp)
    80002b1c:	ec5e                	sd	s7,24(sp)
    80002b1e:	e862                	sd	s8,16(sp)
    80002b20:	e466                	sd	s9,8(sp)
    80002b22:	1080                	addi	s0,sp,96

  struct proc* p;
  // Below parameters are used for debug.
  struct proc* mp = myproc();
    80002b24:	fffff097          	auipc	ra,0xfffff
    80002b28:	ede080e7          	jalr	-290(ra) # 80001a02 <myproc>
  int pid = mp->pid;
    80002b2c:	03052b83          	lw	s7,48(a0)
  const char* name = mp->name;
    80002b30:	15850a93          	addi	s5,a0,344


  /* 
  * Set killed flag for all process besides init & sh.
  */
  for(p = proc; p < &proc[NPROC]; p++)
    80002b34:	0000f497          	auipc	s1,0xf
    80002b38:	bbc48493          	addi	s1,s1,-1092 # 800116f0 <proc>
  {
      acquire(&p->lock);
      if(p->pid > INIT_SH_PROC && p->state && !p->killed)
    80002b3c:	4909                	li	s2,2
      {
        printf("Proc: %s number: %d KILL proc: %s number: %d\n",name, pid, p->name, p->pid);
    80002b3e:	00005b17          	auipc	s6,0x5
    80002b42:	7eab0b13          	addi	s6,s6,2026 # 80008328 <digits+0x2e8>
        p->killed |= 1;
        if(p->state == SLEEPING){
          //calc thicks passed
          //calc thicks passed
          //acquire(&tickslock);
          int diff = ticks - p->last_update_time;
    80002b46:	00006c97          	auipc	s9,0x6
    80002b4a:	50ec8c93          	addi	s9,s9,1294 # 80009054 <ticks>
          //release(&tickslock);
          p->last_update_time = ticks;
          p->sleeping_time += diff;
          //update means...
          p->state = RUNNABLE;
    80002b4e:	4c0d                	li	s8,3
  for(p = proc; p < &proc[NPROC]; p++)
    80002b50:	00015a17          	auipc	s4,0x15
    80002b54:	da0a0a13          	addi	s4,s4,-608 # 800178f0 <tickslock>
    80002b58:	a811                	j	80002b6c <kill_system+0x62>
        }
      }
      release(&p->lock);
    80002b5a:	8526                	mv	a0,s1
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	13e080e7          	jalr	318(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++)
    80002b64:	18848493          	addi	s1,s1,392
    80002b68:	07448163          	beq	s1,s4,80002bca <kill_system+0xc0>
      acquire(&p->lock);
    80002b6c:	8526                	mv	a0,s1
    80002b6e:	ffffe097          	auipc	ra,0xffffe
    80002b72:	078080e7          	jalr	120(ra) # 80000be6 <acquire>
      if(p->pid > INIT_SH_PROC && p->state && !p->killed)
    80002b76:	5898                	lw	a4,48(s1)
    80002b78:	fee951e3          	bge	s2,a4,80002b5a <kill_system+0x50>
    80002b7c:	4c9c                	lw	a5,24(s1)
    80002b7e:	2781                	sext.w	a5,a5
    80002b80:	dfe9                	beqz	a5,80002b5a <kill_system+0x50>
    80002b82:	549c                	lw	a5,40(s1)
    80002b84:	2781                	sext.w	a5,a5
    80002b86:	fbf1                	bnez	a5,80002b5a <kill_system+0x50>
        printf("Proc: %s number: %d KILL proc: %s number: %d\n",name, pid, p->name, p->pid);
    80002b88:	15848693          	addi	a3,s1,344
    80002b8c:	865e                	mv	a2,s7
    80002b8e:	85d6                	mv	a1,s5
    80002b90:	855a                	mv	a0,s6
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	9f8080e7          	jalr	-1544(ra) # 8000058a <printf>
        p->killed |= 1;
    80002b9a:	549c                	lw	a5,40(s1)
    80002b9c:	2781                	sext.w	a5,a5
    80002b9e:	0017e793          	ori	a5,a5,1
    80002ba2:	d49c                	sw	a5,40(s1)
        if(p->state == SLEEPING){
    80002ba4:	4c9c                	lw	a5,24(s1)
    80002ba6:	2781                	sext.w	a5,a5
    80002ba8:	fb2799e3          	bne	a5,s2,80002b5a <kill_system+0x50>
          int diff = ticks - p->last_update_time;
    80002bac:	000ca703          	lw	a4,0(s9)
    80002bb0:	1804a683          	lw	a3,384(s1)
          p->last_update_time = ticks;
    80002bb4:	18e4a023          	sw	a4,384(s1)
          p->sleeping_time += diff;
    80002bb8:	1744a783          	lw	a5,372(s1)
    80002bbc:	9fb9                	addw	a5,a5,a4
    80002bbe:	9f95                	subw	a5,a5,a3
    80002bc0:	16f4aa23          	sw	a5,372(s1)
          p->state = RUNNABLE;
    80002bc4:	0184ac23          	sw	s8,24(s1)
    80002bc8:	bf49                	j	80002b5a <kill_system+0x50>
  }
  return 0;
} 
    80002bca:	4501                	li	a0,0
    80002bcc:	60e6                	ld	ra,88(sp)
    80002bce:	6446                	ld	s0,80(sp)
    80002bd0:	64a6                	ld	s1,72(sp)
    80002bd2:	6906                	ld	s2,64(sp)
    80002bd4:	79e2                	ld	s3,56(sp)
    80002bd6:	7a42                	ld	s4,48(sp)
    80002bd8:	7aa2                	ld	s5,40(sp)
    80002bda:	7b02                	ld	s6,32(sp)
    80002bdc:	6be2                	ld	s7,24(sp)
    80002bde:	6c42                	ld	s8,16(sp)
    80002be0:	6ca2                	ld	s9,8(sp)
    80002be2:	6125                	addi	sp,sp,96
    80002be4:	8082                	ret

0000000080002be6 <print_stats>:

void
print_stats(void){
    80002be6:	1141                	addi	sp,sp,-16
    80002be8:	e406                	sd	ra,8(sp)
    80002bea:	e022                	sd	s0,0(sp)
    80002bec:	0800                	addi	s0,sp,16
  printf("_______________________\n");
    80002bee:	00005517          	auipc	a0,0x5
    80002bf2:	76a50513          	addi	a0,a0,1898 # 80008358 <digits+0x318>
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	994080e7          	jalr	-1644(ra) # 8000058a <printf>
  printf("running time mean: %d\n", running_processes_mean);
    80002bfe:	00006597          	auipc	a1,0x6
    80002c02:	44e5a583          	lw	a1,1102(a1) # 8000904c <running_processes_mean>
    80002c06:	00005517          	auipc	a0,0x5
    80002c0a:	77250513          	addi	a0,a0,1906 # 80008378 <digits+0x338>
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	97c080e7          	jalr	-1668(ra) # 8000058a <printf>
  printf("runnable time mean: %d\n", runnable_processes_mean);
    80002c16:	00006597          	auipc	a1,0x6
    80002c1a:	4325a583          	lw	a1,1074(a1) # 80009048 <runnable_processes_mean>
    80002c1e:	00005517          	auipc	a0,0x5
    80002c22:	77250513          	addi	a0,a0,1906 # 80008390 <digits+0x350>
    80002c26:	ffffe097          	auipc	ra,0xffffe
    80002c2a:	964080e7          	jalr	-1692(ra) # 8000058a <printf>
  printf("sleeping time mean: %d\n", sleeping_processes_mean);
    80002c2e:	00006597          	auipc	a1,0x6
    80002c32:	4225a583          	lw	a1,1058(a1) # 80009050 <sleeping_processes_mean>
    80002c36:	00005517          	auipc	a0,0x5
    80002c3a:	77250513          	addi	a0,a0,1906 # 800083a8 <digits+0x368>
    80002c3e:	ffffe097          	auipc	ra,0xffffe
    80002c42:	94c080e7          	jalr	-1716(ra) # 8000058a <printf>
  printf("program time: %d\n", program_time);
    80002c46:	00006597          	auipc	a1,0x6
    80002c4a:	3fa5a583          	lw	a1,1018(a1) # 80009040 <program_time>
    80002c4e:	00005517          	auipc	a0,0x5
    80002c52:	77250513          	addi	a0,a0,1906 # 800083c0 <digits+0x380>
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	934080e7          	jalr	-1740(ra) # 8000058a <printf>
  printf("cpu utilization: %d\n", cpu_utilization);
    80002c5e:	00006597          	auipc	a1,0x6
    80002c62:	3de5a583          	lw	a1,990(a1) # 8000903c <cpu_utilization>
    80002c66:	00005517          	auipc	a0,0x5
    80002c6a:	77250513          	addi	a0,a0,1906 # 800083d8 <digits+0x398>
    80002c6e:	ffffe097          	auipc	ra,0xffffe
    80002c72:	91c080e7          	jalr	-1764(ra) # 8000058a <printf>
  printf("_______________________\n");
    80002c76:	00005517          	auipc	a0,0x5
    80002c7a:	6e250513          	addi	a0,a0,1762 # 80008358 <digits+0x318>
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	90c080e7          	jalr	-1780(ra) # 8000058a <printf>
    80002c86:	60a2                	ld	ra,8(sp)
    80002c88:	6402                	ld	s0,0(sp)
    80002c8a:	0141                	addi	sp,sp,16
    80002c8c:	8082                	ret

0000000080002c8e <swtch>:
    80002c8e:	00153023          	sd	ra,0(a0)
    80002c92:	00253423          	sd	sp,8(a0)
    80002c96:	e900                	sd	s0,16(a0)
    80002c98:	ed04                	sd	s1,24(a0)
    80002c9a:	03253023          	sd	s2,32(a0)
    80002c9e:	03353423          	sd	s3,40(a0)
    80002ca2:	03453823          	sd	s4,48(a0)
    80002ca6:	03553c23          	sd	s5,56(a0)
    80002caa:	05653023          	sd	s6,64(a0)
    80002cae:	05753423          	sd	s7,72(a0)
    80002cb2:	05853823          	sd	s8,80(a0)
    80002cb6:	05953c23          	sd	s9,88(a0)
    80002cba:	07a53023          	sd	s10,96(a0)
    80002cbe:	07b53423          	sd	s11,104(a0)
    80002cc2:	0005b083          	ld	ra,0(a1)
    80002cc6:	0085b103          	ld	sp,8(a1)
    80002cca:	6980                	ld	s0,16(a1)
    80002ccc:	6d84                	ld	s1,24(a1)
    80002cce:	0205b903          	ld	s2,32(a1)
    80002cd2:	0285b983          	ld	s3,40(a1)
    80002cd6:	0305ba03          	ld	s4,48(a1)
    80002cda:	0385ba83          	ld	s5,56(a1)
    80002cde:	0405bb03          	ld	s6,64(a1)
    80002ce2:	0485bb83          	ld	s7,72(a1)
    80002ce6:	0505bc03          	ld	s8,80(a1)
    80002cea:	0585bc83          	ld	s9,88(a1)
    80002cee:	0605bd03          	ld	s10,96(a1)
    80002cf2:	0685bd83          	ld	s11,104(a1)
    80002cf6:	8082                	ret

0000000080002cf8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002cf8:	1141                	addi	sp,sp,-16
    80002cfa:	e406                	sd	ra,8(sp)
    80002cfc:	e022                	sd	s0,0(sp)
    80002cfe:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002d00:	00005597          	auipc	a1,0x5
    80002d04:	74858593          	addi	a1,a1,1864 # 80008448 <states.1746+0x30>
    80002d08:	00015517          	auipc	a0,0x15
    80002d0c:	be850513          	addi	a0,a0,-1048 # 800178f0 <tickslock>
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	e46080e7          	jalr	-442(ra) # 80000b56 <initlock>
}
    80002d18:	60a2                	ld	ra,8(sp)
    80002d1a:	6402                	ld	s0,0(sp)
    80002d1c:	0141                	addi	sp,sp,16
    80002d1e:	8082                	ret

0000000080002d20 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002d20:	1141                	addi	sp,sp,-16
    80002d22:	e422                	sd	s0,8(sp)
    80002d24:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d26:	00003797          	auipc	a5,0x3
    80002d2a:	4da78793          	addi	a5,a5,1242 # 80006200 <kernelvec>
    80002d2e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002d32:	6422                	ld	s0,8(sp)
    80002d34:	0141                	addi	sp,sp,16
    80002d36:	8082                	ret

0000000080002d38 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002d38:	1141                	addi	sp,sp,-16
    80002d3a:	e406                	sd	ra,8(sp)
    80002d3c:	e022                	sd	s0,0(sp)
    80002d3e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	cc2080e7          	jalr	-830(ra) # 80001a02 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d48:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d4c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d4e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002d52:	00004617          	auipc	a2,0x4
    80002d56:	2ae60613          	addi	a2,a2,686 # 80007000 <_trampoline>
    80002d5a:	00004697          	auipc	a3,0x4
    80002d5e:	2a668693          	addi	a3,a3,678 # 80007000 <_trampoline>
    80002d62:	8e91                	sub	a3,a3,a2
    80002d64:	040007b7          	lui	a5,0x4000
    80002d68:	17fd                	addi	a5,a5,-1
    80002d6a:	07b2                	slli	a5,a5,0xc
    80002d6c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d6e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002d72:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002d74:	180026f3          	csrr	a3,satp
    80002d78:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002d7a:	6d38                	ld	a4,88(a0)
    80002d7c:	6134                	ld	a3,64(a0)
    80002d7e:	6585                	lui	a1,0x1
    80002d80:	96ae                	add	a3,a3,a1
    80002d82:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002d84:	6d38                	ld	a4,88(a0)
    80002d86:	00000697          	auipc	a3,0x0
    80002d8a:	13868693          	addi	a3,a3,312 # 80002ebe <usertrap>
    80002d8e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002d90:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002d92:	8692                	mv	a3,tp
    80002d94:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d96:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002d9a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002d9e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002da2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002da6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002da8:	6f18                	ld	a4,24(a4)
    80002daa:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002dae:	692c                	ld	a1,80(a0)
    80002db0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002db2:	00004717          	auipc	a4,0x4
    80002db6:	2de70713          	addi	a4,a4,734 # 80007090 <userret>
    80002dba:	8f11                	sub	a4,a4,a2
    80002dbc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002dbe:	577d                	li	a4,-1
    80002dc0:	177e                	slli	a4,a4,0x3f
    80002dc2:	8dd9                	or	a1,a1,a4
    80002dc4:	02000537          	lui	a0,0x2000
    80002dc8:	157d                	addi	a0,a0,-1
    80002dca:	0536                	slli	a0,a0,0xd
    80002dcc:	9782                	jalr	a5
}
    80002dce:	60a2                	ld	ra,8(sp)
    80002dd0:	6402                	ld	s0,0(sp)
    80002dd2:	0141                	addi	sp,sp,16
    80002dd4:	8082                	ret

0000000080002dd6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002dd6:	1101                	addi	sp,sp,-32
    80002dd8:	ec06                	sd	ra,24(sp)
    80002dda:	e822                	sd	s0,16(sp)
    80002ddc:	e426                	sd	s1,8(sp)
    80002dde:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002de0:	00015497          	auipc	s1,0x15
    80002de4:	b1048493          	addi	s1,s1,-1264 # 800178f0 <tickslock>
    80002de8:	8526                	mv	a0,s1
    80002dea:	ffffe097          	auipc	ra,0xffffe
    80002dee:	dfc080e7          	jalr	-516(ra) # 80000be6 <acquire>
  ticks++;
    80002df2:	00006517          	auipc	a0,0x6
    80002df6:	26250513          	addi	a0,a0,610 # 80009054 <ticks>
    80002dfa:	411c                	lw	a5,0(a0)
    80002dfc:	2785                	addiw	a5,a5,1
    80002dfe:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	6da080e7          	jalr	1754(ra) # 800024da <wakeup>
  release(&tickslock);
    80002e08:	8526                	mv	a0,s1
    80002e0a:	ffffe097          	auipc	ra,0xffffe
    80002e0e:	e90080e7          	jalr	-368(ra) # 80000c9a <release>
}
    80002e12:	60e2                	ld	ra,24(sp)
    80002e14:	6442                	ld	s0,16(sp)
    80002e16:	64a2                	ld	s1,8(sp)
    80002e18:	6105                	addi	sp,sp,32
    80002e1a:	8082                	ret

0000000080002e1c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002e1c:	1101                	addi	sp,sp,-32
    80002e1e:	ec06                	sd	ra,24(sp)
    80002e20:	e822                	sd	s0,16(sp)
    80002e22:	e426                	sd	s1,8(sp)
    80002e24:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e26:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002e2a:	00074d63          	bltz	a4,80002e44 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002e2e:	57fd                	li	a5,-1
    80002e30:	17fe                	slli	a5,a5,0x3f
    80002e32:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002e34:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002e36:	06f70363          	beq	a4,a5,80002e9c <devintr+0x80>
  }
}
    80002e3a:	60e2                	ld	ra,24(sp)
    80002e3c:	6442                	ld	s0,16(sp)
    80002e3e:	64a2                	ld	s1,8(sp)
    80002e40:	6105                	addi	sp,sp,32
    80002e42:	8082                	ret
     (scause & 0xff) == 9){
    80002e44:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002e48:	46a5                	li	a3,9
    80002e4a:	fed792e3          	bne	a5,a3,80002e2e <devintr+0x12>
    int irq = plic_claim();
    80002e4e:	00003097          	auipc	ra,0x3
    80002e52:	4ba080e7          	jalr	1210(ra) # 80006308 <plic_claim>
    80002e56:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002e58:	47a9                	li	a5,10
    80002e5a:	02f50763          	beq	a0,a5,80002e88 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002e5e:	4785                	li	a5,1
    80002e60:	02f50963          	beq	a0,a5,80002e92 <devintr+0x76>
    return 1;
    80002e64:	4505                	li	a0,1
    } else if(irq){
    80002e66:	d8f1                	beqz	s1,80002e3a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002e68:	85a6                	mv	a1,s1
    80002e6a:	00005517          	auipc	a0,0x5
    80002e6e:	5e650513          	addi	a0,a0,1510 # 80008450 <states.1746+0x38>
    80002e72:	ffffd097          	auipc	ra,0xffffd
    80002e76:	718080e7          	jalr	1816(ra) # 8000058a <printf>
      plic_complete(irq);
    80002e7a:	8526                	mv	a0,s1
    80002e7c:	00003097          	auipc	ra,0x3
    80002e80:	4b0080e7          	jalr	1200(ra) # 8000632c <plic_complete>
    return 1;
    80002e84:	4505                	li	a0,1
    80002e86:	bf55                	j	80002e3a <devintr+0x1e>
      uartintr();
    80002e88:	ffffe097          	auipc	ra,0xffffe
    80002e8c:	b22080e7          	jalr	-1246(ra) # 800009aa <uartintr>
    80002e90:	b7ed                	j	80002e7a <devintr+0x5e>
      virtio_disk_intr();
    80002e92:	00004097          	auipc	ra,0x4
    80002e96:	97a080e7          	jalr	-1670(ra) # 8000680c <virtio_disk_intr>
    80002e9a:	b7c5                	j	80002e7a <devintr+0x5e>
    if(cpuid() == 0){
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	b3a080e7          	jalr	-1222(ra) # 800019d6 <cpuid>
    80002ea4:	c901                	beqz	a0,80002eb4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ea6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002eaa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002eac:	14479073          	csrw	sip,a5
    return 2;
    80002eb0:	4509                	li	a0,2
    80002eb2:	b761                	j	80002e3a <devintr+0x1e>
      clockintr();
    80002eb4:	00000097          	auipc	ra,0x0
    80002eb8:	f22080e7          	jalr	-222(ra) # 80002dd6 <clockintr>
    80002ebc:	b7ed                	j	80002ea6 <devintr+0x8a>

0000000080002ebe <usertrap>:
{
    80002ebe:	1101                	addi	sp,sp,-32
    80002ec0:	ec06                	sd	ra,24(sp)
    80002ec2:	e822                	sd	s0,16(sp)
    80002ec4:	e426                	sd	s1,8(sp)
    80002ec6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ec8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ecc:	1007f793          	andi	a5,a5,256
    80002ed0:	e3b5                	bnez	a5,80002f34 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ed2:	00003797          	auipc	a5,0x3
    80002ed6:	32e78793          	addi	a5,a5,814 # 80006200 <kernelvec>
    80002eda:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ede:	fffff097          	auipc	ra,0xfffff
    80002ee2:	b24080e7          	jalr	-1244(ra) # 80001a02 <myproc>
    80002ee6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ee8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eea:	14102773          	csrr	a4,sepc
    80002eee:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ef0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ef4:	47a1                	li	a5,8
    80002ef6:	04f71d63          	bne	a4,a5,80002f50 <usertrap+0x92>
    if(p->killed)
    80002efa:	551c                	lw	a5,40(a0)
    80002efc:	2781                	sext.w	a5,a5
    80002efe:	e3b9                	bnez	a5,80002f44 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002f00:	6cb8                	ld	a4,88(s1)
    80002f02:	6f1c                	ld	a5,24(a4)
    80002f04:	0791                	addi	a5,a5,4
    80002f06:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f08:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f0c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f10:	10079073          	csrw	sstatus,a5
    syscall();
    80002f14:	00000097          	auipc	ra,0x0
    80002f18:	2ca080e7          	jalr	714(ra) # 800031de <syscall>
  if(p->killed)
    80002f1c:	549c                	lw	a5,40(s1)
    80002f1e:	2781                	sext.w	a5,a5
    80002f20:	e7bd                	bnez	a5,80002f8e <usertrap+0xd0>
  usertrapret();
    80002f22:	00000097          	auipc	ra,0x0
    80002f26:	e16080e7          	jalr	-490(ra) # 80002d38 <usertrapret>
}
    80002f2a:	60e2                	ld	ra,24(sp)
    80002f2c:	6442                	ld	s0,16(sp)
    80002f2e:	64a2                	ld	s1,8(sp)
    80002f30:	6105                	addi	sp,sp,32
    80002f32:	8082                	ret
    panic("usertrap: not from user mode");
    80002f34:	00005517          	auipc	a0,0x5
    80002f38:	53c50513          	addi	a0,a0,1340 # 80008470 <states.1746+0x58>
    80002f3c:	ffffd097          	auipc	ra,0xffffd
    80002f40:	604080e7          	jalr	1540(ra) # 80000540 <panic>
      exit(-1);
    80002f44:	557d                	li	a0,-1
    80002f46:	fffff097          	auipc	ra,0xfffff
    80002f4a:	6d2080e7          	jalr	1746(ra) # 80002618 <exit>
    80002f4e:	bf4d                	j	80002f00 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002f50:	00000097          	auipc	ra,0x0
    80002f54:	ecc080e7          	jalr	-308(ra) # 80002e1c <devintr>
    80002f58:	f171                	bnez	a0,80002f1c <usertrap+0x5e>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f5a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f5e:	5890                	lw	a2,48(s1)
    80002f60:	00005517          	auipc	a0,0x5
    80002f64:	53050513          	addi	a0,a0,1328 # 80008490 <states.1746+0x78>
    80002f68:	ffffd097          	auipc	ra,0xffffd
    80002f6c:	622080e7          	jalr	1570(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f70:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f74:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f78:	00005517          	auipc	a0,0x5
    80002f7c:	54850513          	addi	a0,a0,1352 # 800084c0 <states.1746+0xa8>
    80002f80:	ffffd097          	auipc	ra,0xffffd
    80002f84:	60a080e7          	jalr	1546(ra) # 8000058a <printf>
    p->killed = 1;
    80002f88:	4785                	li	a5,1
    80002f8a:	d49c                	sw	a5,40(s1)
    80002f8c:	bf41                	j	80002f1c <usertrap+0x5e>
    exit(-1);
    80002f8e:	557d                	li	a0,-1
    80002f90:	fffff097          	auipc	ra,0xfffff
    80002f94:	688080e7          	jalr	1672(ra) # 80002618 <exit>
    80002f98:	b769                	j	80002f22 <usertrap+0x64>

0000000080002f9a <kerneltrap>:
{
    80002f9a:	7179                	addi	sp,sp,-48
    80002f9c:	f406                	sd	ra,40(sp)
    80002f9e:	f022                	sd	s0,32(sp)
    80002fa0:	ec26                	sd	s1,24(sp)
    80002fa2:	e84a                	sd	s2,16(sp)
    80002fa4:	e44e                	sd	s3,8(sp)
    80002fa6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002fa8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fac:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002fb0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002fb4:	1004f793          	andi	a5,s1,256
    80002fb8:	cb85                	beqz	a5,80002fe8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002fbe:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002fc0:	ef85                	bnez	a5,80002ff8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002fc2:	00000097          	auipc	ra,0x0
    80002fc6:	e5a080e7          	jalr	-422(ra) # 80002e1c <devintr>
    80002fca:	cd1d                	beqz	a0,80003008 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002fcc:	4789                	li	a5,2
    80002fce:	06f50a63          	beq	a0,a5,80003042 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002fd2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fd6:	10049073          	csrw	sstatus,s1
}
    80002fda:	70a2                	ld	ra,40(sp)
    80002fdc:	7402                	ld	s0,32(sp)
    80002fde:	64e2                	ld	s1,24(sp)
    80002fe0:	6942                	ld	s2,16(sp)
    80002fe2:	69a2                	ld	s3,8(sp)
    80002fe4:	6145                	addi	sp,sp,48
    80002fe6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002fe8:	00005517          	auipc	a0,0x5
    80002fec:	4f850513          	addi	a0,a0,1272 # 800084e0 <states.1746+0xc8>
    80002ff0:	ffffd097          	auipc	ra,0xffffd
    80002ff4:	550080e7          	jalr	1360(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002ff8:	00005517          	auipc	a0,0x5
    80002ffc:	51050513          	addi	a0,a0,1296 # 80008508 <states.1746+0xf0>
    80003000:	ffffd097          	auipc	ra,0xffffd
    80003004:	540080e7          	jalr	1344(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80003008:	85ce                	mv	a1,s3
    8000300a:	00005517          	auipc	a0,0x5
    8000300e:	51e50513          	addi	a0,a0,1310 # 80008528 <states.1746+0x110>
    80003012:	ffffd097          	auipc	ra,0xffffd
    80003016:	578080e7          	jalr	1400(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000301a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000301e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003022:	00005517          	auipc	a0,0x5
    80003026:	51650513          	addi	a0,a0,1302 # 80008538 <states.1746+0x120>
    8000302a:	ffffd097          	auipc	ra,0xffffd
    8000302e:	560080e7          	jalr	1376(ra) # 8000058a <printf>
    panic("kerneltrap");
    80003032:	00005517          	auipc	a0,0x5
    80003036:	51e50513          	addi	a0,a0,1310 # 80008550 <states.1746+0x138>
    8000303a:	ffffd097          	auipc	ra,0xffffd
    8000303e:	506080e7          	jalr	1286(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	9c0080e7          	jalr	-1600(ra) # 80001a02 <myproc>
    8000304a:	d541                	beqz	a0,80002fd2 <kerneltrap+0x38>
    8000304c:	fffff097          	auipc	ra,0xfffff
    80003050:	9b6080e7          	jalr	-1610(ra) # 80001a02 <myproc>
    80003054:	4d1c                	lw	a5,24(a0)
    80003056:	2781                	sext.w	a5,a5
    80003058:	4711                	li	a4,4
    8000305a:	f6e79ce3          	bne	a5,a4,80002fd2 <kerneltrap+0x38>
    yield();
    8000305e:	fffff097          	auipc	ra,0xfffff
    80003062:	200080e7          	jalr	512(ra) # 8000225e <yield>
    80003066:	b7b5                	j	80002fd2 <kerneltrap+0x38>

0000000080003068 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80003068:	1101                	addi	sp,sp,-32
    8000306a:	ec06                	sd	ra,24(sp)
    8000306c:	e822                	sd	s0,16(sp)
    8000306e:	e426                	sd	s1,8(sp)
    80003070:	1000                	addi	s0,sp,32
    80003072:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003074:	fffff097          	auipc	ra,0xfffff
    80003078:	98e080e7          	jalr	-1650(ra) # 80001a02 <myproc>
  switch (n) {
    8000307c:	4795                	li	a5,5
    8000307e:	0497e163          	bltu	a5,s1,800030c0 <argraw+0x58>
    80003082:	048a                	slli	s1,s1,0x2
    80003084:	00005717          	auipc	a4,0x5
    80003088:	50470713          	addi	a4,a4,1284 # 80008588 <states.1746+0x170>
    8000308c:	94ba                	add	s1,s1,a4
    8000308e:	409c                	lw	a5,0(s1)
    80003090:	97ba                	add	a5,a5,a4
    80003092:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003094:	6d3c                	ld	a5,88(a0)
    80003096:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80003098:	60e2                	ld	ra,24(sp)
    8000309a:	6442                	ld	s0,16(sp)
    8000309c:	64a2                	ld	s1,8(sp)
    8000309e:	6105                	addi	sp,sp,32
    800030a0:	8082                	ret
    return p->trapframe->a1;
    800030a2:	6d3c                	ld	a5,88(a0)
    800030a4:	7fa8                	ld	a0,120(a5)
    800030a6:	bfcd                	j	80003098 <argraw+0x30>
    return p->trapframe->a2;
    800030a8:	6d3c                	ld	a5,88(a0)
    800030aa:	63c8                	ld	a0,128(a5)
    800030ac:	b7f5                	j	80003098 <argraw+0x30>
    return p->trapframe->a3;
    800030ae:	6d3c                	ld	a5,88(a0)
    800030b0:	67c8                	ld	a0,136(a5)
    800030b2:	b7dd                	j	80003098 <argraw+0x30>
    return p->trapframe->a4;
    800030b4:	6d3c                	ld	a5,88(a0)
    800030b6:	6bc8                	ld	a0,144(a5)
    800030b8:	b7c5                	j	80003098 <argraw+0x30>
    return p->trapframe->a5;
    800030ba:	6d3c                	ld	a5,88(a0)
    800030bc:	6fc8                	ld	a0,152(a5)
    800030be:	bfe9                	j	80003098 <argraw+0x30>
  panic("argraw");
    800030c0:	00005517          	auipc	a0,0x5
    800030c4:	4a050513          	addi	a0,a0,1184 # 80008560 <states.1746+0x148>
    800030c8:	ffffd097          	auipc	ra,0xffffd
    800030cc:	478080e7          	jalr	1144(ra) # 80000540 <panic>

00000000800030d0 <fetchaddr>:
{
    800030d0:	1101                	addi	sp,sp,-32
    800030d2:	ec06                	sd	ra,24(sp)
    800030d4:	e822                	sd	s0,16(sp)
    800030d6:	e426                	sd	s1,8(sp)
    800030d8:	e04a                	sd	s2,0(sp)
    800030da:	1000                	addi	s0,sp,32
    800030dc:	84aa                	mv	s1,a0
    800030de:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800030e0:	fffff097          	auipc	ra,0xfffff
    800030e4:	922080e7          	jalr	-1758(ra) # 80001a02 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800030e8:	653c                	ld	a5,72(a0)
    800030ea:	02f4f863          	bgeu	s1,a5,8000311a <fetchaddr+0x4a>
    800030ee:	00848713          	addi	a4,s1,8
    800030f2:	02e7e663          	bltu	a5,a4,8000311e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030f6:	46a1                	li	a3,8
    800030f8:	8626                	mv	a2,s1
    800030fa:	85ca                	mv	a1,s2
    800030fc:	6928                	ld	a0,80(a0)
    800030fe:	ffffe097          	auipc	ra,0xffffe
    80003102:	602080e7          	jalr	1538(ra) # 80001700 <copyin>
    80003106:	00a03533          	snez	a0,a0
    8000310a:	40a00533          	neg	a0,a0
}
    8000310e:	60e2                	ld	ra,24(sp)
    80003110:	6442                	ld	s0,16(sp)
    80003112:	64a2                	ld	s1,8(sp)
    80003114:	6902                	ld	s2,0(sp)
    80003116:	6105                	addi	sp,sp,32
    80003118:	8082                	ret
    return -1;
    8000311a:	557d                	li	a0,-1
    8000311c:	bfcd                	j	8000310e <fetchaddr+0x3e>
    8000311e:	557d                	li	a0,-1
    80003120:	b7fd                	j	8000310e <fetchaddr+0x3e>

0000000080003122 <fetchstr>:
{
    80003122:	7179                	addi	sp,sp,-48
    80003124:	f406                	sd	ra,40(sp)
    80003126:	f022                	sd	s0,32(sp)
    80003128:	ec26                	sd	s1,24(sp)
    8000312a:	e84a                	sd	s2,16(sp)
    8000312c:	e44e                	sd	s3,8(sp)
    8000312e:	1800                	addi	s0,sp,48
    80003130:	892a                	mv	s2,a0
    80003132:	84ae                	mv	s1,a1
    80003134:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003136:	fffff097          	auipc	ra,0xfffff
    8000313a:	8cc080e7          	jalr	-1844(ra) # 80001a02 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    8000313e:	86ce                	mv	a3,s3
    80003140:	864a                	mv	a2,s2
    80003142:	85a6                	mv	a1,s1
    80003144:	6928                	ld	a0,80(a0)
    80003146:	ffffe097          	auipc	ra,0xffffe
    8000314a:	646080e7          	jalr	1606(ra) # 8000178c <copyinstr>
  if(err < 0)
    8000314e:	00054763          	bltz	a0,8000315c <fetchstr+0x3a>
  return strlen(buf);
    80003152:	8526                	mv	a0,s1
    80003154:	ffffe097          	auipc	ra,0xffffe
    80003158:	d12080e7          	jalr	-750(ra) # 80000e66 <strlen>
}
    8000315c:	70a2                	ld	ra,40(sp)
    8000315e:	7402                	ld	s0,32(sp)
    80003160:	64e2                	ld	s1,24(sp)
    80003162:	6942                	ld	s2,16(sp)
    80003164:	69a2                	ld	s3,8(sp)
    80003166:	6145                	addi	sp,sp,48
    80003168:	8082                	ret

000000008000316a <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000316a:	1101                	addi	sp,sp,-32
    8000316c:	ec06                	sd	ra,24(sp)
    8000316e:	e822                	sd	s0,16(sp)
    80003170:	e426                	sd	s1,8(sp)
    80003172:	1000                	addi	s0,sp,32
    80003174:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003176:	00000097          	auipc	ra,0x0
    8000317a:	ef2080e7          	jalr	-270(ra) # 80003068 <argraw>
    8000317e:	c088                	sw	a0,0(s1)
  return 0;
}
    80003180:	4501                	li	a0,0
    80003182:	60e2                	ld	ra,24(sp)
    80003184:	6442                	ld	s0,16(sp)
    80003186:	64a2                	ld	s1,8(sp)
    80003188:	6105                	addi	sp,sp,32
    8000318a:	8082                	ret

000000008000318c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000318c:	1101                	addi	sp,sp,-32
    8000318e:	ec06                	sd	ra,24(sp)
    80003190:	e822                	sd	s0,16(sp)
    80003192:	e426                	sd	s1,8(sp)
    80003194:	1000                	addi	s0,sp,32
    80003196:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003198:	00000097          	auipc	ra,0x0
    8000319c:	ed0080e7          	jalr	-304(ra) # 80003068 <argraw>
    800031a0:	e088                	sd	a0,0(s1)
  return 0;
}
    800031a2:	4501                	li	a0,0
    800031a4:	60e2                	ld	ra,24(sp)
    800031a6:	6442                	ld	s0,16(sp)
    800031a8:	64a2                	ld	s1,8(sp)
    800031aa:	6105                	addi	sp,sp,32
    800031ac:	8082                	ret

00000000800031ae <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800031ae:	1101                	addi	sp,sp,-32
    800031b0:	ec06                	sd	ra,24(sp)
    800031b2:	e822                	sd	s0,16(sp)
    800031b4:	e426                	sd	s1,8(sp)
    800031b6:	e04a                	sd	s2,0(sp)
    800031b8:	1000                	addi	s0,sp,32
    800031ba:	84ae                	mv	s1,a1
    800031bc:	8932                	mv	s2,a2
  *ip = argraw(n);
    800031be:	00000097          	auipc	ra,0x0
    800031c2:	eaa080e7          	jalr	-342(ra) # 80003068 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800031c6:	864a                	mv	a2,s2
    800031c8:	85a6                	mv	a1,s1
    800031ca:	00000097          	auipc	ra,0x0
    800031ce:	f58080e7          	jalr	-168(ra) # 80003122 <fetchstr>
}
    800031d2:	60e2                	ld	ra,24(sp)
    800031d4:	6442                	ld	s0,16(sp)
    800031d6:	64a2                	ld	s1,8(sp)
    800031d8:	6902                	ld	s2,0(sp)
    800031da:	6105                	addi	sp,sp,32
    800031dc:	8082                	ret

00000000800031de <syscall>:
};


void
syscall(void)
{
    800031de:	1101                	addi	sp,sp,-32
    800031e0:	ec06                	sd	ra,24(sp)
    800031e2:	e822                	sd	s0,16(sp)
    800031e4:	e426                	sd	s1,8(sp)
    800031e6:	e04a                	sd	s2,0(sp)
    800031e8:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800031ea:	fffff097          	auipc	ra,0xfffff
    800031ee:	818080e7          	jalr	-2024(ra) # 80001a02 <myproc>
    800031f2:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800031f4:	05853903          	ld	s2,88(a0)
    800031f8:	0a893783          	ld	a5,168(s2)
    800031fc:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80003200:	37fd                	addiw	a5,a5,-1
    80003202:	475d                	li	a4,23
    80003204:	00f76f63          	bltu	a4,a5,80003222 <syscall+0x44>
    80003208:	00369713          	slli	a4,a3,0x3
    8000320c:	00005797          	auipc	a5,0x5
    80003210:	39478793          	addi	a5,a5,916 # 800085a0 <syscalls>
    80003214:	97ba                	add	a5,a5,a4
    80003216:	639c                	ld	a5,0(a5)
    80003218:	c789                	beqz	a5,80003222 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    8000321a:	9782                	jalr	a5
    8000321c:	06a93823          	sd	a0,112(s2)
    80003220:	a839                	j	8000323e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003222:	15848613          	addi	a2,s1,344
    80003226:	588c                	lw	a1,48(s1)
    80003228:	00005517          	auipc	a0,0x5
    8000322c:	34050513          	addi	a0,a0,832 # 80008568 <states.1746+0x150>
    80003230:	ffffd097          	auipc	ra,0xffffd
    80003234:	35a080e7          	jalr	858(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003238:	6cbc                	ld	a5,88(s1)
    8000323a:	577d                	li	a4,-1
    8000323c:	fbb8                	sd	a4,112(a5)
  }
}
    8000323e:	60e2                	ld	ra,24(sp)
    80003240:	6442                	ld	s0,16(sp)
    80003242:	64a2                	ld	s1,8(sp)
    80003244:	6902                	ld	s2,0(sp)
    80003246:	6105                	addi	sp,sp,32
    80003248:	8082                	ret

000000008000324a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000324a:	1101                	addi	sp,sp,-32
    8000324c:	ec06                	sd	ra,24(sp)
    8000324e:	e822                	sd	s0,16(sp)
    80003250:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003252:	fec40593          	addi	a1,s0,-20
    80003256:	4501                	li	a0,0
    80003258:	00000097          	auipc	ra,0x0
    8000325c:	f12080e7          	jalr	-238(ra) # 8000316a <argint>
    return -1;
    80003260:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003262:	00054963          	bltz	a0,80003274 <sys_exit+0x2a>
  exit(n);
    80003266:	fec42503          	lw	a0,-20(s0)
    8000326a:	fffff097          	auipc	ra,0xfffff
    8000326e:	3ae080e7          	jalr	942(ra) # 80002618 <exit>
  return 0;  // not reached
    80003272:	4781                	li	a5,0
}
    80003274:	853e                	mv	a0,a5
    80003276:	60e2                	ld	ra,24(sp)
    80003278:	6442                	ld	s0,16(sp)
    8000327a:	6105                	addi	sp,sp,32
    8000327c:	8082                	ret

000000008000327e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000327e:	1141                	addi	sp,sp,-16
    80003280:	e406                	sd	ra,8(sp)
    80003282:	e022                	sd	s0,0(sp)
    80003284:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003286:	ffffe097          	auipc	ra,0xffffe
    8000328a:	77c080e7          	jalr	1916(ra) # 80001a02 <myproc>
}
    8000328e:	5908                	lw	a0,48(a0)
    80003290:	60a2                	ld	ra,8(sp)
    80003292:	6402                	ld	s0,0(sp)
    80003294:	0141                	addi	sp,sp,16
    80003296:	8082                	ret

0000000080003298 <sys_fork>:

uint64
sys_fork(void)
{
    80003298:	1141                	addi	sp,sp,-16
    8000329a:	e406                	sd	ra,8(sp)
    8000329c:	e022                	sd	s0,0(sp)
    8000329e:	0800                	addi	s0,sp,16
  return fork();
    800032a0:	fffff097          	auipc	ra,0xfffff
    800032a4:	b82080e7          	jalr	-1150(ra) # 80001e22 <fork>
}
    800032a8:	60a2                	ld	ra,8(sp)
    800032aa:	6402                	ld	s0,0(sp)
    800032ac:	0141                	addi	sp,sp,16
    800032ae:	8082                	ret

00000000800032b0 <sys_wait>:

uint64
sys_wait(void)
{
    800032b0:	1101                	addi	sp,sp,-32
    800032b2:	ec06                	sd	ra,24(sp)
    800032b4:	e822                	sd	s0,16(sp)
    800032b6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    800032b8:	fe840593          	addi	a1,s0,-24
    800032bc:	4501                	li	a0,0
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	ece080e7          	jalr	-306(ra) # 8000318c <argaddr>
    800032c6:	87aa                	mv	a5,a0
    return -1;
    800032c8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800032ca:	0007c863          	bltz	a5,800032da <sys_wait+0x2a>
  return wait(p);
    800032ce:	fe843503          	ld	a0,-24(s0)
    800032d2:	fffff097          	auipc	ra,0xfffff
    800032d6:	0dc080e7          	jalr	220(ra) # 800023ae <wait>
}
    800032da:	60e2                	ld	ra,24(sp)
    800032dc:	6442                	ld	s0,16(sp)
    800032de:	6105                	addi	sp,sp,32
    800032e0:	8082                	ret

00000000800032e2 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800032e2:	7179                	addi	sp,sp,-48
    800032e4:	f406                	sd	ra,40(sp)
    800032e6:	f022                	sd	s0,32(sp)
    800032e8:	ec26                	sd	s1,24(sp)
    800032ea:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800032ec:	fdc40593          	addi	a1,s0,-36
    800032f0:	4501                	li	a0,0
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	e78080e7          	jalr	-392(ra) # 8000316a <argint>
    800032fa:	87aa                	mv	a5,a0
    return -1;
    800032fc:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800032fe:	0207c063          	bltz	a5,8000331e <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	700080e7          	jalr	1792(ra) # 80001a02 <myproc>
    8000330a:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    8000330c:	fdc42503          	lw	a0,-36(s0)
    80003310:	fffff097          	auipc	ra,0xfffff
    80003314:	a9e080e7          	jalr	-1378(ra) # 80001dae <growproc>
    80003318:	00054863          	bltz	a0,80003328 <sys_sbrk+0x46>
    return -1;
  return addr;
    8000331c:	8526                	mv	a0,s1
}
    8000331e:	70a2                	ld	ra,40(sp)
    80003320:	7402                	ld	s0,32(sp)
    80003322:	64e2                	ld	s1,24(sp)
    80003324:	6145                	addi	sp,sp,48
    80003326:	8082                	ret
    return -1;
    80003328:	557d                	li	a0,-1
    8000332a:	bfd5                	j	8000331e <sys_sbrk+0x3c>

000000008000332c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000332c:	7139                	addi	sp,sp,-64
    8000332e:	fc06                	sd	ra,56(sp)
    80003330:	f822                	sd	s0,48(sp)
    80003332:	f426                	sd	s1,40(sp)
    80003334:	f04a                	sd	s2,32(sp)
    80003336:	ec4e                	sd	s3,24(sp)
    80003338:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000333a:	fcc40593          	addi	a1,s0,-52
    8000333e:	4501                	li	a0,0
    80003340:	00000097          	auipc	ra,0x0
    80003344:	e2a080e7          	jalr	-470(ra) # 8000316a <argint>
    return -1;
    80003348:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000334a:	06054663          	bltz	a0,800033b6 <sys_sleep+0x8a>
  acquire(&tickslock);
    8000334e:	00014517          	auipc	a0,0x14
    80003352:	5a250513          	addi	a0,a0,1442 # 800178f0 <tickslock>
    80003356:	ffffe097          	auipc	ra,0xffffe
    8000335a:	890080e7          	jalr	-1904(ra) # 80000be6 <acquire>
  ticks0 = ticks;
    8000335e:	00006917          	auipc	s2,0x6
    80003362:	cf692903          	lw	s2,-778(s2) # 80009054 <ticks>
  while(ticks - ticks0 < n){
    80003366:	fcc42783          	lw	a5,-52(s0)
    8000336a:	cf8d                	beqz	a5,800033a4 <sys_sleep+0x78>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000336c:	00014997          	auipc	s3,0x14
    80003370:	58498993          	addi	s3,s3,1412 # 800178f0 <tickslock>
    80003374:	00006497          	auipc	s1,0x6
    80003378:	ce048493          	addi	s1,s1,-800 # 80009054 <ticks>
    if(myproc()->killed){
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	686080e7          	jalr	1670(ra) # 80001a02 <myproc>
    80003384:	551c                	lw	a5,40(a0)
    80003386:	2781                	sext.w	a5,a5
    80003388:	ef9d                	bnez	a5,800033c6 <sys_sleep+0x9a>
    sleep(&ticks, &tickslock);
    8000338a:	85ce                	mv	a1,s3
    8000338c:	8526                	mv	a0,s1
    8000338e:	fffff097          	auipc	ra,0xfffff
    80003392:	f66080e7          	jalr	-154(ra) # 800022f4 <sleep>
  while(ticks - ticks0 < n){
    80003396:	409c                	lw	a5,0(s1)
    80003398:	412787bb          	subw	a5,a5,s2
    8000339c:	fcc42703          	lw	a4,-52(s0)
    800033a0:	fce7eee3          	bltu	a5,a4,8000337c <sys_sleep+0x50>
  }
  release(&tickslock);
    800033a4:	00014517          	auipc	a0,0x14
    800033a8:	54c50513          	addi	a0,a0,1356 # 800178f0 <tickslock>
    800033ac:	ffffe097          	auipc	ra,0xffffe
    800033b0:	8ee080e7          	jalr	-1810(ra) # 80000c9a <release>
  return 0;
    800033b4:	4781                	li	a5,0
}
    800033b6:	853e                	mv	a0,a5
    800033b8:	70e2                	ld	ra,56(sp)
    800033ba:	7442                	ld	s0,48(sp)
    800033bc:	74a2                	ld	s1,40(sp)
    800033be:	7902                	ld	s2,32(sp)
    800033c0:	69e2                	ld	s3,24(sp)
    800033c2:	6121                	addi	sp,sp,64
    800033c4:	8082                	ret
      release(&tickslock);
    800033c6:	00014517          	auipc	a0,0x14
    800033ca:	52a50513          	addi	a0,a0,1322 # 800178f0 <tickslock>
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	8cc080e7          	jalr	-1844(ra) # 80000c9a <release>
      return -1;
    800033d6:	57fd                	li	a5,-1
    800033d8:	bff9                	j	800033b6 <sys_sleep+0x8a>

00000000800033da <sys_kill>:

uint64
sys_kill(void)
{
    800033da:	1101                	addi	sp,sp,-32
    800033dc:	ec06                	sd	ra,24(sp)
    800033de:	e822                	sd	s0,16(sp)
    800033e0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800033e2:	fec40593          	addi	a1,s0,-20
    800033e6:	4501                	li	a0,0
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	d82080e7          	jalr	-638(ra) # 8000316a <argint>
    800033f0:	87aa                	mv	a5,a0
    return -1;
    800033f2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800033f4:	0007c863          	bltz	a5,80003404 <sys_kill+0x2a>
  return kill(pid);
    800033f8:	fec42503          	lw	a0,-20(s0)
    800033fc:	fffff097          	auipc	ra,0xfffff
    80003400:	420080e7          	jalr	1056(ra) # 8000281c <kill>
}
    80003404:	60e2                	ld	ra,24(sp)
    80003406:	6442                	ld	s0,16(sp)
    80003408:	6105                	addi	sp,sp,32
    8000340a:	8082                	ret

000000008000340c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000340c:	1101                	addi	sp,sp,-32
    8000340e:	ec06                	sd	ra,24(sp)
    80003410:	e822                	sd	s0,16(sp)
    80003412:	e426                	sd	s1,8(sp)
    80003414:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003416:	00014517          	auipc	a0,0x14
    8000341a:	4da50513          	addi	a0,a0,1242 # 800178f0 <tickslock>
    8000341e:	ffffd097          	auipc	ra,0xffffd
    80003422:	7c8080e7          	jalr	1992(ra) # 80000be6 <acquire>
  xticks = ticks;
    80003426:	00006497          	auipc	s1,0x6
    8000342a:	c2e4a483          	lw	s1,-978(s1) # 80009054 <ticks>
  release(&tickslock);
    8000342e:	00014517          	auipc	a0,0x14
    80003432:	4c250513          	addi	a0,a0,1218 # 800178f0 <tickslock>
    80003436:	ffffe097          	auipc	ra,0xffffe
    8000343a:	864080e7          	jalr	-1948(ra) # 80000c9a <release>
  return xticks;
}
    8000343e:	02049513          	slli	a0,s1,0x20
    80003442:	9101                	srli	a0,a0,0x20
    80003444:	60e2                	ld	ra,24(sp)
    80003446:	6442                	ld	s0,16(sp)
    80003448:	64a2                	ld	s1,8(sp)
    8000344a:	6105                	addi	sp,sp,32
    8000344c:	8082                	ret

000000008000344e <sys_pause_system>:

uint64
sys_pause_system(void)
{
    8000344e:	1101                	addi	sp,sp,-32
    80003450:	ec06                	sd	ra,24(sp)
    80003452:	e822                	sd	s0,16(sp)
    80003454:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    80003456:	fec40593          	addi	a1,s0,-20
    8000345a:	4501                	li	a0,0
    8000345c:	00000097          	auipc	ra,0x0
    80003460:	d0e080e7          	jalr	-754(ra) # 8000316a <argint>
    80003464:	87aa                	mv	a5,a0
    return -1;
    80003466:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    80003468:	0007c863          	bltz	a5,80003478 <sys_pause_system+0x2a>
  return pause_system(seconds);
    8000346c:	fec42503          	lw	a0,-20(s0)
    80003470:	fffff097          	auipc	ra,0xfffff
    80003474:	5e6080e7          	jalr	1510(ra) # 80002a56 <pause_system>
}
    80003478:	60e2                	ld	ra,24(sp)
    8000347a:	6442                	ld	s0,16(sp)
    8000347c:	6105                	addi	sp,sp,32
    8000347e:	8082                	ret

0000000080003480 <sys_kill_system>:


uint64
sys_kill_system(void)
{
    80003480:	1141                	addi	sp,sp,-16
    80003482:	e406                	sd	ra,8(sp)
    80003484:	e022                	sd	s0,0(sp)
    80003486:	0800                	addi	s0,sp,16
  return kill_system();
    80003488:	fffff097          	auipc	ra,0xfffff
    8000348c:	682080e7          	jalr	1666(ra) # 80002b0a <kill_system>
}
    80003490:	60a2                	ld	ra,8(sp)
    80003492:	6402                	ld	s0,0(sp)
    80003494:	0141                	addi	sp,sp,16
    80003496:	8082                	ret

0000000080003498 <sys_print_stats>:

uint64
sys_print_stats(void){
    80003498:	1141                	addi	sp,sp,-16
    8000349a:	e406                	sd	ra,8(sp)
    8000349c:	e022                	sd	s0,0(sp)
    8000349e:	0800                	addi	s0,sp,16
  print_stats();
    800034a0:	fffff097          	auipc	ra,0xfffff
    800034a4:	746080e7          	jalr	1862(ra) # 80002be6 <print_stats>
  return 0;
}
    800034a8:	4501                	li	a0,0
    800034aa:	60a2                	ld	ra,8(sp)
    800034ac:	6402                	ld	s0,0(sp)
    800034ae:	0141                	addi	sp,sp,16
    800034b0:	8082                	ret

00000000800034b2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800034b2:	7179                	addi	sp,sp,-48
    800034b4:	f406                	sd	ra,40(sp)
    800034b6:	f022                	sd	s0,32(sp)
    800034b8:	ec26                	sd	s1,24(sp)
    800034ba:	e84a                	sd	s2,16(sp)
    800034bc:	e44e                	sd	s3,8(sp)
    800034be:	e052                	sd	s4,0(sp)
    800034c0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800034c2:	00005597          	auipc	a1,0x5
    800034c6:	1a658593          	addi	a1,a1,422 # 80008668 <syscalls+0xc8>
    800034ca:	00014517          	auipc	a0,0x14
    800034ce:	43e50513          	addi	a0,a0,1086 # 80017908 <bcache>
    800034d2:	ffffd097          	auipc	ra,0xffffd
    800034d6:	684080e7          	jalr	1668(ra) # 80000b56 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800034da:	0001c797          	auipc	a5,0x1c
    800034de:	42e78793          	addi	a5,a5,1070 # 8001f908 <bcache+0x8000>
    800034e2:	0001c717          	auipc	a4,0x1c
    800034e6:	68e70713          	addi	a4,a4,1678 # 8001fb70 <bcache+0x8268>
    800034ea:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800034ee:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034f2:	00014497          	auipc	s1,0x14
    800034f6:	42e48493          	addi	s1,s1,1070 # 80017920 <bcache+0x18>
    b->next = bcache.head.next;
    800034fa:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800034fc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800034fe:	00005a17          	auipc	s4,0x5
    80003502:	172a0a13          	addi	s4,s4,370 # 80008670 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003506:	2b893783          	ld	a5,696(s2)
    8000350a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000350c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003510:	85d2                	mv	a1,s4
    80003512:	01048513          	addi	a0,s1,16
    80003516:	00001097          	auipc	ra,0x1
    8000351a:	4bc080e7          	jalr	1212(ra) # 800049d2 <initsleeplock>
    bcache.head.next->prev = b;
    8000351e:	2b893783          	ld	a5,696(s2)
    80003522:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003524:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003528:	45848493          	addi	s1,s1,1112
    8000352c:	fd349de3          	bne	s1,s3,80003506 <binit+0x54>
  }
}
    80003530:	70a2                	ld	ra,40(sp)
    80003532:	7402                	ld	s0,32(sp)
    80003534:	64e2                	ld	s1,24(sp)
    80003536:	6942                	ld	s2,16(sp)
    80003538:	69a2                	ld	s3,8(sp)
    8000353a:	6a02                	ld	s4,0(sp)
    8000353c:	6145                	addi	sp,sp,48
    8000353e:	8082                	ret

0000000080003540 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003540:	7179                	addi	sp,sp,-48
    80003542:	f406                	sd	ra,40(sp)
    80003544:	f022                	sd	s0,32(sp)
    80003546:	ec26                	sd	s1,24(sp)
    80003548:	e84a                	sd	s2,16(sp)
    8000354a:	e44e                	sd	s3,8(sp)
    8000354c:	1800                	addi	s0,sp,48
    8000354e:	89aa                	mv	s3,a0
    80003550:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003552:	00014517          	auipc	a0,0x14
    80003556:	3b650513          	addi	a0,a0,950 # 80017908 <bcache>
    8000355a:	ffffd097          	auipc	ra,0xffffd
    8000355e:	68c080e7          	jalr	1676(ra) # 80000be6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003562:	0001c497          	auipc	s1,0x1c
    80003566:	65e4b483          	ld	s1,1630(s1) # 8001fbc0 <bcache+0x82b8>
    8000356a:	0001c797          	auipc	a5,0x1c
    8000356e:	60678793          	addi	a5,a5,1542 # 8001fb70 <bcache+0x8268>
    80003572:	02f48f63          	beq	s1,a5,800035b0 <bread+0x70>
    80003576:	873e                	mv	a4,a5
    80003578:	a021                	j	80003580 <bread+0x40>
    8000357a:	68a4                	ld	s1,80(s1)
    8000357c:	02e48a63          	beq	s1,a4,800035b0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003580:	449c                	lw	a5,8(s1)
    80003582:	ff379ce3          	bne	a5,s3,8000357a <bread+0x3a>
    80003586:	44dc                	lw	a5,12(s1)
    80003588:	ff2799e3          	bne	a5,s2,8000357a <bread+0x3a>
      b->refcnt++;
    8000358c:	40bc                	lw	a5,64(s1)
    8000358e:	2785                	addiw	a5,a5,1
    80003590:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003592:	00014517          	auipc	a0,0x14
    80003596:	37650513          	addi	a0,a0,886 # 80017908 <bcache>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	700080e7          	jalr	1792(ra) # 80000c9a <release>
      acquiresleep(&b->lock);
    800035a2:	01048513          	addi	a0,s1,16
    800035a6:	00001097          	auipc	ra,0x1
    800035aa:	466080e7          	jalr	1126(ra) # 80004a0c <acquiresleep>
      return b;
    800035ae:	a8b9                	j	8000360c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035b0:	0001c497          	auipc	s1,0x1c
    800035b4:	6084b483          	ld	s1,1544(s1) # 8001fbb8 <bcache+0x82b0>
    800035b8:	0001c797          	auipc	a5,0x1c
    800035bc:	5b878793          	addi	a5,a5,1464 # 8001fb70 <bcache+0x8268>
    800035c0:	00f48863          	beq	s1,a5,800035d0 <bread+0x90>
    800035c4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800035c6:	40bc                	lw	a5,64(s1)
    800035c8:	cf81                	beqz	a5,800035e0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800035ca:	64a4                	ld	s1,72(s1)
    800035cc:	fee49de3          	bne	s1,a4,800035c6 <bread+0x86>
  panic("bget: no buffers");
    800035d0:	00005517          	auipc	a0,0x5
    800035d4:	0a850513          	addi	a0,a0,168 # 80008678 <syscalls+0xd8>
    800035d8:	ffffd097          	auipc	ra,0xffffd
    800035dc:	f68080e7          	jalr	-152(ra) # 80000540 <panic>
      b->dev = dev;
    800035e0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800035e4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800035e8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800035ec:	4785                	li	a5,1
    800035ee:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035f0:	00014517          	auipc	a0,0x14
    800035f4:	31850513          	addi	a0,a0,792 # 80017908 <bcache>
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	6a2080e7          	jalr	1698(ra) # 80000c9a <release>
      acquiresleep(&b->lock);
    80003600:	01048513          	addi	a0,s1,16
    80003604:	00001097          	auipc	ra,0x1
    80003608:	408080e7          	jalr	1032(ra) # 80004a0c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000360c:	409c                	lw	a5,0(s1)
    8000360e:	cb89                	beqz	a5,80003620 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003610:	8526                	mv	a0,s1
    80003612:	70a2                	ld	ra,40(sp)
    80003614:	7402                	ld	s0,32(sp)
    80003616:	64e2                	ld	s1,24(sp)
    80003618:	6942                	ld	s2,16(sp)
    8000361a:	69a2                	ld	s3,8(sp)
    8000361c:	6145                	addi	sp,sp,48
    8000361e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003620:	4581                	li	a1,0
    80003622:	8526                	mv	a0,s1
    80003624:	00003097          	auipc	ra,0x3
    80003628:	f12080e7          	jalr	-238(ra) # 80006536 <virtio_disk_rw>
    b->valid = 1;
    8000362c:	4785                	li	a5,1
    8000362e:	c09c                	sw	a5,0(s1)
  return b;
    80003630:	b7c5                	j	80003610 <bread+0xd0>

0000000080003632 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003632:	1101                	addi	sp,sp,-32
    80003634:	ec06                	sd	ra,24(sp)
    80003636:	e822                	sd	s0,16(sp)
    80003638:	e426                	sd	s1,8(sp)
    8000363a:	1000                	addi	s0,sp,32
    8000363c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000363e:	0541                	addi	a0,a0,16
    80003640:	00001097          	auipc	ra,0x1
    80003644:	466080e7          	jalr	1126(ra) # 80004aa6 <holdingsleep>
    80003648:	cd01                	beqz	a0,80003660 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000364a:	4585                	li	a1,1
    8000364c:	8526                	mv	a0,s1
    8000364e:	00003097          	auipc	ra,0x3
    80003652:	ee8080e7          	jalr	-280(ra) # 80006536 <virtio_disk_rw>
}
    80003656:	60e2                	ld	ra,24(sp)
    80003658:	6442                	ld	s0,16(sp)
    8000365a:	64a2                	ld	s1,8(sp)
    8000365c:	6105                	addi	sp,sp,32
    8000365e:	8082                	ret
    panic("bwrite");
    80003660:	00005517          	auipc	a0,0x5
    80003664:	03050513          	addi	a0,a0,48 # 80008690 <syscalls+0xf0>
    80003668:	ffffd097          	auipc	ra,0xffffd
    8000366c:	ed8080e7          	jalr	-296(ra) # 80000540 <panic>

0000000080003670 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003670:	1101                	addi	sp,sp,-32
    80003672:	ec06                	sd	ra,24(sp)
    80003674:	e822                	sd	s0,16(sp)
    80003676:	e426                	sd	s1,8(sp)
    80003678:	e04a                	sd	s2,0(sp)
    8000367a:	1000                	addi	s0,sp,32
    8000367c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000367e:	01050913          	addi	s2,a0,16
    80003682:	854a                	mv	a0,s2
    80003684:	00001097          	auipc	ra,0x1
    80003688:	422080e7          	jalr	1058(ra) # 80004aa6 <holdingsleep>
    8000368c:	c92d                	beqz	a0,800036fe <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000368e:	854a                	mv	a0,s2
    80003690:	00001097          	auipc	ra,0x1
    80003694:	3d2080e7          	jalr	978(ra) # 80004a62 <releasesleep>

  acquire(&bcache.lock);
    80003698:	00014517          	auipc	a0,0x14
    8000369c:	27050513          	addi	a0,a0,624 # 80017908 <bcache>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	546080e7          	jalr	1350(ra) # 80000be6 <acquire>
  b->refcnt--;
    800036a8:	40bc                	lw	a5,64(s1)
    800036aa:	37fd                	addiw	a5,a5,-1
    800036ac:	0007871b          	sext.w	a4,a5
    800036b0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800036b2:	eb05                	bnez	a4,800036e2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800036b4:	68bc                	ld	a5,80(s1)
    800036b6:	64b8                	ld	a4,72(s1)
    800036b8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800036ba:	64bc                	ld	a5,72(s1)
    800036bc:	68b8                	ld	a4,80(s1)
    800036be:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800036c0:	0001c797          	auipc	a5,0x1c
    800036c4:	24878793          	addi	a5,a5,584 # 8001f908 <bcache+0x8000>
    800036c8:	2b87b703          	ld	a4,696(a5)
    800036cc:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800036ce:	0001c717          	auipc	a4,0x1c
    800036d2:	4a270713          	addi	a4,a4,1186 # 8001fb70 <bcache+0x8268>
    800036d6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800036d8:	2b87b703          	ld	a4,696(a5)
    800036dc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800036de:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800036e2:	00014517          	auipc	a0,0x14
    800036e6:	22650513          	addi	a0,a0,550 # 80017908 <bcache>
    800036ea:	ffffd097          	auipc	ra,0xffffd
    800036ee:	5b0080e7          	jalr	1456(ra) # 80000c9a <release>
}
    800036f2:	60e2                	ld	ra,24(sp)
    800036f4:	6442                	ld	s0,16(sp)
    800036f6:	64a2                	ld	s1,8(sp)
    800036f8:	6902                	ld	s2,0(sp)
    800036fa:	6105                	addi	sp,sp,32
    800036fc:	8082                	ret
    panic("brelse");
    800036fe:	00005517          	auipc	a0,0x5
    80003702:	f9a50513          	addi	a0,a0,-102 # 80008698 <syscalls+0xf8>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	e3a080e7          	jalr	-454(ra) # 80000540 <panic>

000000008000370e <bpin>:

void
bpin(struct buf *b) {
    8000370e:	1101                	addi	sp,sp,-32
    80003710:	ec06                	sd	ra,24(sp)
    80003712:	e822                	sd	s0,16(sp)
    80003714:	e426                	sd	s1,8(sp)
    80003716:	1000                	addi	s0,sp,32
    80003718:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000371a:	00014517          	auipc	a0,0x14
    8000371e:	1ee50513          	addi	a0,a0,494 # 80017908 <bcache>
    80003722:	ffffd097          	auipc	ra,0xffffd
    80003726:	4c4080e7          	jalr	1220(ra) # 80000be6 <acquire>
  b->refcnt++;
    8000372a:	40bc                	lw	a5,64(s1)
    8000372c:	2785                	addiw	a5,a5,1
    8000372e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003730:	00014517          	auipc	a0,0x14
    80003734:	1d850513          	addi	a0,a0,472 # 80017908 <bcache>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	562080e7          	jalr	1378(ra) # 80000c9a <release>
}
    80003740:	60e2                	ld	ra,24(sp)
    80003742:	6442                	ld	s0,16(sp)
    80003744:	64a2                	ld	s1,8(sp)
    80003746:	6105                	addi	sp,sp,32
    80003748:	8082                	ret

000000008000374a <bunpin>:

void
bunpin(struct buf *b) {
    8000374a:	1101                	addi	sp,sp,-32
    8000374c:	ec06                	sd	ra,24(sp)
    8000374e:	e822                	sd	s0,16(sp)
    80003750:	e426                	sd	s1,8(sp)
    80003752:	1000                	addi	s0,sp,32
    80003754:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003756:	00014517          	auipc	a0,0x14
    8000375a:	1b250513          	addi	a0,a0,434 # 80017908 <bcache>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	488080e7          	jalr	1160(ra) # 80000be6 <acquire>
  b->refcnt--;
    80003766:	40bc                	lw	a5,64(s1)
    80003768:	37fd                	addiw	a5,a5,-1
    8000376a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000376c:	00014517          	auipc	a0,0x14
    80003770:	19c50513          	addi	a0,a0,412 # 80017908 <bcache>
    80003774:	ffffd097          	auipc	ra,0xffffd
    80003778:	526080e7          	jalr	1318(ra) # 80000c9a <release>
}
    8000377c:	60e2                	ld	ra,24(sp)
    8000377e:	6442                	ld	s0,16(sp)
    80003780:	64a2                	ld	s1,8(sp)
    80003782:	6105                	addi	sp,sp,32
    80003784:	8082                	ret

0000000080003786 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003786:	1101                	addi	sp,sp,-32
    80003788:	ec06                	sd	ra,24(sp)
    8000378a:	e822                	sd	s0,16(sp)
    8000378c:	e426                	sd	s1,8(sp)
    8000378e:	e04a                	sd	s2,0(sp)
    80003790:	1000                	addi	s0,sp,32
    80003792:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003794:	00d5d59b          	srliw	a1,a1,0xd
    80003798:	0001d797          	auipc	a5,0x1d
    8000379c:	84c7a783          	lw	a5,-1972(a5) # 8001ffe4 <sb+0x1c>
    800037a0:	9dbd                	addw	a1,a1,a5
    800037a2:	00000097          	auipc	ra,0x0
    800037a6:	d9e080e7          	jalr	-610(ra) # 80003540 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800037aa:	0074f713          	andi	a4,s1,7
    800037ae:	4785                	li	a5,1
    800037b0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800037b4:	14ce                	slli	s1,s1,0x33
    800037b6:	90d9                	srli	s1,s1,0x36
    800037b8:	00950733          	add	a4,a0,s1
    800037bc:	05874703          	lbu	a4,88(a4)
    800037c0:	00e7f6b3          	and	a3,a5,a4
    800037c4:	c69d                	beqz	a3,800037f2 <bfree+0x6c>
    800037c6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800037c8:	94aa                	add	s1,s1,a0
    800037ca:	fff7c793          	not	a5,a5
    800037ce:	8ff9                	and	a5,a5,a4
    800037d0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800037d4:	00001097          	auipc	ra,0x1
    800037d8:	118080e7          	jalr	280(ra) # 800048ec <log_write>
  brelse(bp);
    800037dc:	854a                	mv	a0,s2
    800037de:	00000097          	auipc	ra,0x0
    800037e2:	e92080e7          	jalr	-366(ra) # 80003670 <brelse>
}
    800037e6:	60e2                	ld	ra,24(sp)
    800037e8:	6442                	ld	s0,16(sp)
    800037ea:	64a2                	ld	s1,8(sp)
    800037ec:	6902                	ld	s2,0(sp)
    800037ee:	6105                	addi	sp,sp,32
    800037f0:	8082                	ret
    panic("freeing free block");
    800037f2:	00005517          	auipc	a0,0x5
    800037f6:	eae50513          	addi	a0,a0,-338 # 800086a0 <syscalls+0x100>
    800037fa:	ffffd097          	auipc	ra,0xffffd
    800037fe:	d46080e7          	jalr	-698(ra) # 80000540 <panic>

0000000080003802 <balloc>:
{
    80003802:	711d                	addi	sp,sp,-96
    80003804:	ec86                	sd	ra,88(sp)
    80003806:	e8a2                	sd	s0,80(sp)
    80003808:	e4a6                	sd	s1,72(sp)
    8000380a:	e0ca                	sd	s2,64(sp)
    8000380c:	fc4e                	sd	s3,56(sp)
    8000380e:	f852                	sd	s4,48(sp)
    80003810:	f456                	sd	s5,40(sp)
    80003812:	f05a                	sd	s6,32(sp)
    80003814:	ec5e                	sd	s7,24(sp)
    80003816:	e862                	sd	s8,16(sp)
    80003818:	e466                	sd	s9,8(sp)
    8000381a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000381c:	0001c797          	auipc	a5,0x1c
    80003820:	7b07a783          	lw	a5,1968(a5) # 8001ffcc <sb+0x4>
    80003824:	cbd1                	beqz	a5,800038b8 <balloc+0xb6>
    80003826:	8baa                	mv	s7,a0
    80003828:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000382a:	0001cb17          	auipc	s6,0x1c
    8000382e:	79eb0b13          	addi	s6,s6,1950 # 8001ffc8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003832:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003834:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003836:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003838:	6c89                	lui	s9,0x2
    8000383a:	a831                	j	80003856 <balloc+0x54>
    brelse(bp);
    8000383c:	854a                	mv	a0,s2
    8000383e:	00000097          	auipc	ra,0x0
    80003842:	e32080e7          	jalr	-462(ra) # 80003670 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003846:	015c87bb          	addw	a5,s9,s5
    8000384a:	00078a9b          	sext.w	s5,a5
    8000384e:	004b2703          	lw	a4,4(s6)
    80003852:	06eaf363          	bgeu	s5,a4,800038b8 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003856:	41fad79b          	sraiw	a5,s5,0x1f
    8000385a:	0137d79b          	srliw	a5,a5,0x13
    8000385e:	015787bb          	addw	a5,a5,s5
    80003862:	40d7d79b          	sraiw	a5,a5,0xd
    80003866:	01cb2583          	lw	a1,28(s6)
    8000386a:	9dbd                	addw	a1,a1,a5
    8000386c:	855e                	mv	a0,s7
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	cd2080e7          	jalr	-814(ra) # 80003540 <bread>
    80003876:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003878:	004b2503          	lw	a0,4(s6)
    8000387c:	000a849b          	sext.w	s1,s5
    80003880:	8662                	mv	a2,s8
    80003882:	faa4fde3          	bgeu	s1,a0,8000383c <balloc+0x3a>
      m = 1 << (bi % 8);
    80003886:	41f6579b          	sraiw	a5,a2,0x1f
    8000388a:	01d7d69b          	srliw	a3,a5,0x1d
    8000388e:	00c6873b          	addw	a4,a3,a2
    80003892:	00777793          	andi	a5,a4,7
    80003896:	9f95                	subw	a5,a5,a3
    80003898:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000389c:	4037571b          	sraiw	a4,a4,0x3
    800038a0:	00e906b3          	add	a3,s2,a4
    800038a4:	0586c683          	lbu	a3,88(a3)
    800038a8:	00d7f5b3          	and	a1,a5,a3
    800038ac:	cd91                	beqz	a1,800038c8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038ae:	2605                	addiw	a2,a2,1
    800038b0:	2485                	addiw	s1,s1,1
    800038b2:	fd4618e3          	bne	a2,s4,80003882 <balloc+0x80>
    800038b6:	b759                	j	8000383c <balloc+0x3a>
  panic("balloc: out of blocks");
    800038b8:	00005517          	auipc	a0,0x5
    800038bc:	e0050513          	addi	a0,a0,-512 # 800086b8 <syscalls+0x118>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	c80080e7          	jalr	-896(ra) # 80000540 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800038c8:	974a                	add	a4,a4,s2
    800038ca:	8fd5                	or	a5,a5,a3
    800038cc:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800038d0:	854a                	mv	a0,s2
    800038d2:	00001097          	auipc	ra,0x1
    800038d6:	01a080e7          	jalr	26(ra) # 800048ec <log_write>
        brelse(bp);
    800038da:	854a                	mv	a0,s2
    800038dc:	00000097          	auipc	ra,0x0
    800038e0:	d94080e7          	jalr	-620(ra) # 80003670 <brelse>
  bp = bread(dev, bno);
    800038e4:	85a6                	mv	a1,s1
    800038e6:	855e                	mv	a0,s7
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	c58080e7          	jalr	-936(ra) # 80003540 <bread>
    800038f0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038f2:	40000613          	li	a2,1024
    800038f6:	4581                	li	a1,0
    800038f8:	05850513          	addi	a0,a0,88
    800038fc:	ffffd097          	auipc	ra,0xffffd
    80003900:	3e6080e7          	jalr	998(ra) # 80000ce2 <memset>
  log_write(bp);
    80003904:	854a                	mv	a0,s2
    80003906:	00001097          	auipc	ra,0x1
    8000390a:	fe6080e7          	jalr	-26(ra) # 800048ec <log_write>
  brelse(bp);
    8000390e:	854a                	mv	a0,s2
    80003910:	00000097          	auipc	ra,0x0
    80003914:	d60080e7          	jalr	-672(ra) # 80003670 <brelse>
}
    80003918:	8526                	mv	a0,s1
    8000391a:	60e6                	ld	ra,88(sp)
    8000391c:	6446                	ld	s0,80(sp)
    8000391e:	64a6                	ld	s1,72(sp)
    80003920:	6906                	ld	s2,64(sp)
    80003922:	79e2                	ld	s3,56(sp)
    80003924:	7a42                	ld	s4,48(sp)
    80003926:	7aa2                	ld	s5,40(sp)
    80003928:	7b02                	ld	s6,32(sp)
    8000392a:	6be2                	ld	s7,24(sp)
    8000392c:	6c42                	ld	s8,16(sp)
    8000392e:	6ca2                	ld	s9,8(sp)
    80003930:	6125                	addi	sp,sp,96
    80003932:	8082                	ret

0000000080003934 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003934:	7179                	addi	sp,sp,-48
    80003936:	f406                	sd	ra,40(sp)
    80003938:	f022                	sd	s0,32(sp)
    8000393a:	ec26                	sd	s1,24(sp)
    8000393c:	e84a                	sd	s2,16(sp)
    8000393e:	e44e                	sd	s3,8(sp)
    80003940:	e052                	sd	s4,0(sp)
    80003942:	1800                	addi	s0,sp,48
    80003944:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003946:	47ad                	li	a5,11
    80003948:	04b7fe63          	bgeu	a5,a1,800039a4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000394c:	ff45849b          	addiw	s1,a1,-12
    80003950:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003954:	0ff00793          	li	a5,255
    80003958:	0ae7e363          	bltu	a5,a4,800039fe <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000395c:	08052583          	lw	a1,128(a0)
    80003960:	c5ad                	beqz	a1,800039ca <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003962:	00092503          	lw	a0,0(s2)
    80003966:	00000097          	auipc	ra,0x0
    8000396a:	bda080e7          	jalr	-1062(ra) # 80003540 <bread>
    8000396e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003970:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003974:	02049593          	slli	a1,s1,0x20
    80003978:	9181                	srli	a1,a1,0x20
    8000397a:	058a                	slli	a1,a1,0x2
    8000397c:	00b784b3          	add	s1,a5,a1
    80003980:	0004a983          	lw	s3,0(s1)
    80003984:	04098d63          	beqz	s3,800039de <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003988:	8552                	mv	a0,s4
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	ce6080e7          	jalr	-794(ra) # 80003670 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003992:	854e                	mv	a0,s3
    80003994:	70a2                	ld	ra,40(sp)
    80003996:	7402                	ld	s0,32(sp)
    80003998:	64e2                	ld	s1,24(sp)
    8000399a:	6942                	ld	s2,16(sp)
    8000399c:	69a2                	ld	s3,8(sp)
    8000399e:	6a02                	ld	s4,0(sp)
    800039a0:	6145                	addi	sp,sp,48
    800039a2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800039a4:	02059493          	slli	s1,a1,0x20
    800039a8:	9081                	srli	s1,s1,0x20
    800039aa:	048a                	slli	s1,s1,0x2
    800039ac:	94aa                	add	s1,s1,a0
    800039ae:	0504a983          	lw	s3,80(s1)
    800039b2:	fe0990e3          	bnez	s3,80003992 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800039b6:	4108                	lw	a0,0(a0)
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	e4a080e7          	jalr	-438(ra) # 80003802 <balloc>
    800039c0:	0005099b          	sext.w	s3,a0
    800039c4:	0534a823          	sw	s3,80(s1)
    800039c8:	b7e9                	j	80003992 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800039ca:	4108                	lw	a0,0(a0)
    800039cc:	00000097          	auipc	ra,0x0
    800039d0:	e36080e7          	jalr	-458(ra) # 80003802 <balloc>
    800039d4:	0005059b          	sext.w	a1,a0
    800039d8:	08b92023          	sw	a1,128(s2)
    800039dc:	b759                	j	80003962 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800039de:	00092503          	lw	a0,0(s2)
    800039e2:	00000097          	auipc	ra,0x0
    800039e6:	e20080e7          	jalr	-480(ra) # 80003802 <balloc>
    800039ea:	0005099b          	sext.w	s3,a0
    800039ee:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800039f2:	8552                	mv	a0,s4
    800039f4:	00001097          	auipc	ra,0x1
    800039f8:	ef8080e7          	jalr	-264(ra) # 800048ec <log_write>
    800039fc:	b771                	j	80003988 <bmap+0x54>
  panic("bmap: out of range");
    800039fe:	00005517          	auipc	a0,0x5
    80003a02:	cd250513          	addi	a0,a0,-814 # 800086d0 <syscalls+0x130>
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	b3a080e7          	jalr	-1222(ra) # 80000540 <panic>

0000000080003a0e <iget>:
{
    80003a0e:	7179                	addi	sp,sp,-48
    80003a10:	f406                	sd	ra,40(sp)
    80003a12:	f022                	sd	s0,32(sp)
    80003a14:	ec26                	sd	s1,24(sp)
    80003a16:	e84a                	sd	s2,16(sp)
    80003a18:	e44e                	sd	s3,8(sp)
    80003a1a:	e052                	sd	s4,0(sp)
    80003a1c:	1800                	addi	s0,sp,48
    80003a1e:	89aa                	mv	s3,a0
    80003a20:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a22:	0001c517          	auipc	a0,0x1c
    80003a26:	5c650513          	addi	a0,a0,1478 # 8001ffe8 <itable>
    80003a2a:	ffffd097          	auipc	ra,0xffffd
    80003a2e:	1bc080e7          	jalr	444(ra) # 80000be6 <acquire>
  empty = 0;
    80003a32:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a34:	0001c497          	auipc	s1,0x1c
    80003a38:	5cc48493          	addi	s1,s1,1484 # 80020000 <itable+0x18>
    80003a3c:	0001e697          	auipc	a3,0x1e
    80003a40:	05468693          	addi	a3,a3,84 # 80021a90 <log>
    80003a44:	a039                	j	80003a52 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a46:	02090b63          	beqz	s2,80003a7c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003a4a:	08848493          	addi	s1,s1,136
    80003a4e:	02d48a63          	beq	s1,a3,80003a82 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003a52:	449c                	lw	a5,8(s1)
    80003a54:	fef059e3          	blez	a5,80003a46 <iget+0x38>
    80003a58:	4098                	lw	a4,0(s1)
    80003a5a:	ff3716e3          	bne	a4,s3,80003a46 <iget+0x38>
    80003a5e:	40d8                	lw	a4,4(s1)
    80003a60:	ff4713e3          	bne	a4,s4,80003a46 <iget+0x38>
      ip->ref++;
    80003a64:	2785                	addiw	a5,a5,1
    80003a66:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a68:	0001c517          	auipc	a0,0x1c
    80003a6c:	58050513          	addi	a0,a0,1408 # 8001ffe8 <itable>
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	22a080e7          	jalr	554(ra) # 80000c9a <release>
      return ip;
    80003a78:	8926                	mv	s2,s1
    80003a7a:	a03d                	j	80003aa8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a7c:	f7f9                	bnez	a5,80003a4a <iget+0x3c>
    80003a7e:	8926                	mv	s2,s1
    80003a80:	b7e9                	j	80003a4a <iget+0x3c>
  if(empty == 0)
    80003a82:	02090c63          	beqz	s2,80003aba <iget+0xac>
  ip->dev = dev;
    80003a86:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a8a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a8e:	4785                	li	a5,1
    80003a90:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a94:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a98:	0001c517          	auipc	a0,0x1c
    80003a9c:	55050513          	addi	a0,a0,1360 # 8001ffe8 <itable>
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	1fa080e7          	jalr	506(ra) # 80000c9a <release>
}
    80003aa8:	854a                	mv	a0,s2
    80003aaa:	70a2                	ld	ra,40(sp)
    80003aac:	7402                	ld	s0,32(sp)
    80003aae:	64e2                	ld	s1,24(sp)
    80003ab0:	6942                	ld	s2,16(sp)
    80003ab2:	69a2                	ld	s3,8(sp)
    80003ab4:	6a02                	ld	s4,0(sp)
    80003ab6:	6145                	addi	sp,sp,48
    80003ab8:	8082                	ret
    panic("iget: no inodes");
    80003aba:	00005517          	auipc	a0,0x5
    80003abe:	c2e50513          	addi	a0,a0,-978 # 800086e8 <syscalls+0x148>
    80003ac2:	ffffd097          	auipc	ra,0xffffd
    80003ac6:	a7e080e7          	jalr	-1410(ra) # 80000540 <panic>

0000000080003aca <fsinit>:
fsinit(int dev) {
    80003aca:	7179                	addi	sp,sp,-48
    80003acc:	f406                	sd	ra,40(sp)
    80003ace:	f022                	sd	s0,32(sp)
    80003ad0:	ec26                	sd	s1,24(sp)
    80003ad2:	e84a                	sd	s2,16(sp)
    80003ad4:	e44e                	sd	s3,8(sp)
    80003ad6:	1800                	addi	s0,sp,48
    80003ad8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003ada:	4585                	li	a1,1
    80003adc:	00000097          	auipc	ra,0x0
    80003ae0:	a64080e7          	jalr	-1436(ra) # 80003540 <bread>
    80003ae4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003ae6:	0001c997          	auipc	s3,0x1c
    80003aea:	4e298993          	addi	s3,s3,1250 # 8001ffc8 <sb>
    80003aee:	02000613          	li	a2,32
    80003af2:	05850593          	addi	a1,a0,88
    80003af6:	854e                	mv	a0,s3
    80003af8:	ffffd097          	auipc	ra,0xffffd
    80003afc:	24a080e7          	jalr	586(ra) # 80000d42 <memmove>
  brelse(bp);
    80003b00:	8526                	mv	a0,s1
    80003b02:	00000097          	auipc	ra,0x0
    80003b06:	b6e080e7          	jalr	-1170(ra) # 80003670 <brelse>
  if(sb.magic != FSMAGIC)
    80003b0a:	0009a703          	lw	a4,0(s3)
    80003b0e:	102037b7          	lui	a5,0x10203
    80003b12:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b16:	02f71263          	bne	a4,a5,80003b3a <fsinit+0x70>
  initlog(dev, &sb);
    80003b1a:	0001c597          	auipc	a1,0x1c
    80003b1e:	4ae58593          	addi	a1,a1,1198 # 8001ffc8 <sb>
    80003b22:	854a                	mv	a0,s2
    80003b24:	00001097          	auipc	ra,0x1
    80003b28:	b4c080e7          	jalr	-1204(ra) # 80004670 <initlog>
}
    80003b2c:	70a2                	ld	ra,40(sp)
    80003b2e:	7402                	ld	s0,32(sp)
    80003b30:	64e2                	ld	s1,24(sp)
    80003b32:	6942                	ld	s2,16(sp)
    80003b34:	69a2                	ld	s3,8(sp)
    80003b36:	6145                	addi	sp,sp,48
    80003b38:	8082                	ret
    panic("invalid file system");
    80003b3a:	00005517          	auipc	a0,0x5
    80003b3e:	bbe50513          	addi	a0,a0,-1090 # 800086f8 <syscalls+0x158>
    80003b42:	ffffd097          	auipc	ra,0xffffd
    80003b46:	9fe080e7          	jalr	-1538(ra) # 80000540 <panic>

0000000080003b4a <iinit>:
{
    80003b4a:	7179                	addi	sp,sp,-48
    80003b4c:	f406                	sd	ra,40(sp)
    80003b4e:	f022                	sd	s0,32(sp)
    80003b50:	ec26                	sd	s1,24(sp)
    80003b52:	e84a                	sd	s2,16(sp)
    80003b54:	e44e                	sd	s3,8(sp)
    80003b56:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b58:	00005597          	auipc	a1,0x5
    80003b5c:	bb858593          	addi	a1,a1,-1096 # 80008710 <syscalls+0x170>
    80003b60:	0001c517          	auipc	a0,0x1c
    80003b64:	48850513          	addi	a0,a0,1160 # 8001ffe8 <itable>
    80003b68:	ffffd097          	auipc	ra,0xffffd
    80003b6c:	fee080e7          	jalr	-18(ra) # 80000b56 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b70:	0001c497          	auipc	s1,0x1c
    80003b74:	4a048493          	addi	s1,s1,1184 # 80020010 <itable+0x28>
    80003b78:	0001e997          	auipc	s3,0x1e
    80003b7c:	f2898993          	addi	s3,s3,-216 # 80021aa0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b80:	00005917          	auipc	s2,0x5
    80003b84:	b9890913          	addi	s2,s2,-1128 # 80008718 <syscalls+0x178>
    80003b88:	85ca                	mv	a1,s2
    80003b8a:	8526                	mv	a0,s1
    80003b8c:	00001097          	auipc	ra,0x1
    80003b90:	e46080e7          	jalr	-442(ra) # 800049d2 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b94:	08848493          	addi	s1,s1,136
    80003b98:	ff3498e3          	bne	s1,s3,80003b88 <iinit+0x3e>
}
    80003b9c:	70a2                	ld	ra,40(sp)
    80003b9e:	7402                	ld	s0,32(sp)
    80003ba0:	64e2                	ld	s1,24(sp)
    80003ba2:	6942                	ld	s2,16(sp)
    80003ba4:	69a2                	ld	s3,8(sp)
    80003ba6:	6145                	addi	sp,sp,48
    80003ba8:	8082                	ret

0000000080003baa <ialloc>:
{
    80003baa:	715d                	addi	sp,sp,-80
    80003bac:	e486                	sd	ra,72(sp)
    80003bae:	e0a2                	sd	s0,64(sp)
    80003bb0:	fc26                	sd	s1,56(sp)
    80003bb2:	f84a                	sd	s2,48(sp)
    80003bb4:	f44e                	sd	s3,40(sp)
    80003bb6:	f052                	sd	s4,32(sp)
    80003bb8:	ec56                	sd	s5,24(sp)
    80003bba:	e85a                	sd	s6,16(sp)
    80003bbc:	e45e                	sd	s7,8(sp)
    80003bbe:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bc0:	0001c717          	auipc	a4,0x1c
    80003bc4:	41472703          	lw	a4,1044(a4) # 8001ffd4 <sb+0xc>
    80003bc8:	4785                	li	a5,1
    80003bca:	04e7fa63          	bgeu	a5,a4,80003c1e <ialloc+0x74>
    80003bce:	8aaa                	mv	s5,a0
    80003bd0:	8bae                	mv	s7,a1
    80003bd2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003bd4:	0001ca17          	auipc	s4,0x1c
    80003bd8:	3f4a0a13          	addi	s4,s4,1012 # 8001ffc8 <sb>
    80003bdc:	00048b1b          	sext.w	s6,s1
    80003be0:	0044d593          	srli	a1,s1,0x4
    80003be4:	018a2783          	lw	a5,24(s4)
    80003be8:	9dbd                	addw	a1,a1,a5
    80003bea:	8556                	mv	a0,s5
    80003bec:	00000097          	auipc	ra,0x0
    80003bf0:	954080e7          	jalr	-1708(ra) # 80003540 <bread>
    80003bf4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003bf6:	05850993          	addi	s3,a0,88
    80003bfa:	00f4f793          	andi	a5,s1,15
    80003bfe:	079a                	slli	a5,a5,0x6
    80003c00:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c02:	00099783          	lh	a5,0(s3)
    80003c06:	c785                	beqz	a5,80003c2e <ialloc+0x84>
    brelse(bp);
    80003c08:	00000097          	auipc	ra,0x0
    80003c0c:	a68080e7          	jalr	-1432(ra) # 80003670 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c10:	0485                	addi	s1,s1,1
    80003c12:	00ca2703          	lw	a4,12(s4)
    80003c16:	0004879b          	sext.w	a5,s1
    80003c1a:	fce7e1e3          	bltu	a5,a4,80003bdc <ialloc+0x32>
  panic("ialloc: no inodes");
    80003c1e:	00005517          	auipc	a0,0x5
    80003c22:	b0250513          	addi	a0,a0,-1278 # 80008720 <syscalls+0x180>
    80003c26:	ffffd097          	auipc	ra,0xffffd
    80003c2a:	91a080e7          	jalr	-1766(ra) # 80000540 <panic>
      memset(dip, 0, sizeof(*dip));
    80003c2e:	04000613          	li	a2,64
    80003c32:	4581                	li	a1,0
    80003c34:	854e                	mv	a0,s3
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	0ac080e7          	jalr	172(ra) # 80000ce2 <memset>
      dip->type = type;
    80003c3e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003c42:	854a                	mv	a0,s2
    80003c44:	00001097          	auipc	ra,0x1
    80003c48:	ca8080e7          	jalr	-856(ra) # 800048ec <log_write>
      brelse(bp);
    80003c4c:	854a                	mv	a0,s2
    80003c4e:	00000097          	auipc	ra,0x0
    80003c52:	a22080e7          	jalr	-1502(ra) # 80003670 <brelse>
      return iget(dev, inum);
    80003c56:	85da                	mv	a1,s6
    80003c58:	8556                	mv	a0,s5
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	db4080e7          	jalr	-588(ra) # 80003a0e <iget>
}
    80003c62:	60a6                	ld	ra,72(sp)
    80003c64:	6406                	ld	s0,64(sp)
    80003c66:	74e2                	ld	s1,56(sp)
    80003c68:	7942                	ld	s2,48(sp)
    80003c6a:	79a2                	ld	s3,40(sp)
    80003c6c:	7a02                	ld	s4,32(sp)
    80003c6e:	6ae2                	ld	s5,24(sp)
    80003c70:	6b42                	ld	s6,16(sp)
    80003c72:	6ba2                	ld	s7,8(sp)
    80003c74:	6161                	addi	sp,sp,80
    80003c76:	8082                	ret

0000000080003c78 <iupdate>:
{
    80003c78:	1101                	addi	sp,sp,-32
    80003c7a:	ec06                	sd	ra,24(sp)
    80003c7c:	e822                	sd	s0,16(sp)
    80003c7e:	e426                	sd	s1,8(sp)
    80003c80:	e04a                	sd	s2,0(sp)
    80003c82:	1000                	addi	s0,sp,32
    80003c84:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c86:	415c                	lw	a5,4(a0)
    80003c88:	0047d79b          	srliw	a5,a5,0x4
    80003c8c:	0001c597          	auipc	a1,0x1c
    80003c90:	3545a583          	lw	a1,852(a1) # 8001ffe0 <sb+0x18>
    80003c94:	9dbd                	addw	a1,a1,a5
    80003c96:	4108                	lw	a0,0(a0)
    80003c98:	00000097          	auipc	ra,0x0
    80003c9c:	8a8080e7          	jalr	-1880(ra) # 80003540 <bread>
    80003ca0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003ca2:	05850793          	addi	a5,a0,88
    80003ca6:	40c8                	lw	a0,4(s1)
    80003ca8:	893d                	andi	a0,a0,15
    80003caa:	051a                	slli	a0,a0,0x6
    80003cac:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003cae:	04449703          	lh	a4,68(s1)
    80003cb2:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003cb6:	04649703          	lh	a4,70(s1)
    80003cba:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003cbe:	04849703          	lh	a4,72(s1)
    80003cc2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003cc6:	04a49703          	lh	a4,74(s1)
    80003cca:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003cce:	44f8                	lw	a4,76(s1)
    80003cd0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003cd2:	03400613          	li	a2,52
    80003cd6:	05048593          	addi	a1,s1,80
    80003cda:	0531                	addi	a0,a0,12
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	066080e7          	jalr	102(ra) # 80000d42 <memmove>
  log_write(bp);
    80003ce4:	854a                	mv	a0,s2
    80003ce6:	00001097          	auipc	ra,0x1
    80003cea:	c06080e7          	jalr	-1018(ra) # 800048ec <log_write>
  brelse(bp);
    80003cee:	854a                	mv	a0,s2
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	980080e7          	jalr	-1664(ra) # 80003670 <brelse>
}
    80003cf8:	60e2                	ld	ra,24(sp)
    80003cfa:	6442                	ld	s0,16(sp)
    80003cfc:	64a2                	ld	s1,8(sp)
    80003cfe:	6902                	ld	s2,0(sp)
    80003d00:	6105                	addi	sp,sp,32
    80003d02:	8082                	ret

0000000080003d04 <idup>:
{
    80003d04:	1101                	addi	sp,sp,-32
    80003d06:	ec06                	sd	ra,24(sp)
    80003d08:	e822                	sd	s0,16(sp)
    80003d0a:	e426                	sd	s1,8(sp)
    80003d0c:	1000                	addi	s0,sp,32
    80003d0e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d10:	0001c517          	auipc	a0,0x1c
    80003d14:	2d850513          	addi	a0,a0,728 # 8001ffe8 <itable>
    80003d18:	ffffd097          	auipc	ra,0xffffd
    80003d1c:	ece080e7          	jalr	-306(ra) # 80000be6 <acquire>
  ip->ref++;
    80003d20:	449c                	lw	a5,8(s1)
    80003d22:	2785                	addiw	a5,a5,1
    80003d24:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d26:	0001c517          	auipc	a0,0x1c
    80003d2a:	2c250513          	addi	a0,a0,706 # 8001ffe8 <itable>
    80003d2e:	ffffd097          	auipc	ra,0xffffd
    80003d32:	f6c080e7          	jalr	-148(ra) # 80000c9a <release>
}
    80003d36:	8526                	mv	a0,s1
    80003d38:	60e2                	ld	ra,24(sp)
    80003d3a:	6442                	ld	s0,16(sp)
    80003d3c:	64a2                	ld	s1,8(sp)
    80003d3e:	6105                	addi	sp,sp,32
    80003d40:	8082                	ret

0000000080003d42 <ilock>:
{
    80003d42:	1101                	addi	sp,sp,-32
    80003d44:	ec06                	sd	ra,24(sp)
    80003d46:	e822                	sd	s0,16(sp)
    80003d48:	e426                	sd	s1,8(sp)
    80003d4a:	e04a                	sd	s2,0(sp)
    80003d4c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003d4e:	c115                	beqz	a0,80003d72 <ilock+0x30>
    80003d50:	84aa                	mv	s1,a0
    80003d52:	451c                	lw	a5,8(a0)
    80003d54:	00f05f63          	blez	a5,80003d72 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d58:	0541                	addi	a0,a0,16
    80003d5a:	00001097          	auipc	ra,0x1
    80003d5e:	cb2080e7          	jalr	-846(ra) # 80004a0c <acquiresleep>
  if(ip->valid == 0){
    80003d62:	40bc                	lw	a5,64(s1)
    80003d64:	cf99                	beqz	a5,80003d82 <ilock+0x40>
}
    80003d66:	60e2                	ld	ra,24(sp)
    80003d68:	6442                	ld	s0,16(sp)
    80003d6a:	64a2                	ld	s1,8(sp)
    80003d6c:	6902                	ld	s2,0(sp)
    80003d6e:	6105                	addi	sp,sp,32
    80003d70:	8082                	ret
    panic("ilock");
    80003d72:	00005517          	auipc	a0,0x5
    80003d76:	9c650513          	addi	a0,a0,-1594 # 80008738 <syscalls+0x198>
    80003d7a:	ffffc097          	auipc	ra,0xffffc
    80003d7e:	7c6080e7          	jalr	1990(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d82:	40dc                	lw	a5,4(s1)
    80003d84:	0047d79b          	srliw	a5,a5,0x4
    80003d88:	0001c597          	auipc	a1,0x1c
    80003d8c:	2585a583          	lw	a1,600(a1) # 8001ffe0 <sb+0x18>
    80003d90:	9dbd                	addw	a1,a1,a5
    80003d92:	4088                	lw	a0,0(s1)
    80003d94:	fffff097          	auipc	ra,0xfffff
    80003d98:	7ac080e7          	jalr	1964(ra) # 80003540 <bread>
    80003d9c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d9e:	05850593          	addi	a1,a0,88
    80003da2:	40dc                	lw	a5,4(s1)
    80003da4:	8bbd                	andi	a5,a5,15
    80003da6:	079a                	slli	a5,a5,0x6
    80003da8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003daa:	00059783          	lh	a5,0(a1)
    80003dae:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003db2:	00259783          	lh	a5,2(a1)
    80003db6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003dba:	00459783          	lh	a5,4(a1)
    80003dbe:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003dc2:	00659783          	lh	a5,6(a1)
    80003dc6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003dca:	459c                	lw	a5,8(a1)
    80003dcc:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003dce:	03400613          	li	a2,52
    80003dd2:	05b1                	addi	a1,a1,12
    80003dd4:	05048513          	addi	a0,s1,80
    80003dd8:	ffffd097          	auipc	ra,0xffffd
    80003ddc:	f6a080e7          	jalr	-150(ra) # 80000d42 <memmove>
    brelse(bp);
    80003de0:	854a                	mv	a0,s2
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	88e080e7          	jalr	-1906(ra) # 80003670 <brelse>
    ip->valid = 1;
    80003dea:	4785                	li	a5,1
    80003dec:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003dee:	04449783          	lh	a5,68(s1)
    80003df2:	fbb5                	bnez	a5,80003d66 <ilock+0x24>
      panic("ilock: no type");
    80003df4:	00005517          	auipc	a0,0x5
    80003df8:	94c50513          	addi	a0,a0,-1716 # 80008740 <syscalls+0x1a0>
    80003dfc:	ffffc097          	auipc	ra,0xffffc
    80003e00:	744080e7          	jalr	1860(ra) # 80000540 <panic>

0000000080003e04 <iunlock>:
{
    80003e04:	1101                	addi	sp,sp,-32
    80003e06:	ec06                	sd	ra,24(sp)
    80003e08:	e822                	sd	s0,16(sp)
    80003e0a:	e426                	sd	s1,8(sp)
    80003e0c:	e04a                	sd	s2,0(sp)
    80003e0e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e10:	c905                	beqz	a0,80003e40 <iunlock+0x3c>
    80003e12:	84aa                	mv	s1,a0
    80003e14:	01050913          	addi	s2,a0,16
    80003e18:	854a                	mv	a0,s2
    80003e1a:	00001097          	auipc	ra,0x1
    80003e1e:	c8c080e7          	jalr	-884(ra) # 80004aa6 <holdingsleep>
    80003e22:	cd19                	beqz	a0,80003e40 <iunlock+0x3c>
    80003e24:	449c                	lw	a5,8(s1)
    80003e26:	00f05d63          	blez	a5,80003e40 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e2a:	854a                	mv	a0,s2
    80003e2c:	00001097          	auipc	ra,0x1
    80003e30:	c36080e7          	jalr	-970(ra) # 80004a62 <releasesleep>
}
    80003e34:	60e2                	ld	ra,24(sp)
    80003e36:	6442                	ld	s0,16(sp)
    80003e38:	64a2                	ld	s1,8(sp)
    80003e3a:	6902                	ld	s2,0(sp)
    80003e3c:	6105                	addi	sp,sp,32
    80003e3e:	8082                	ret
    panic("iunlock");
    80003e40:	00005517          	auipc	a0,0x5
    80003e44:	91050513          	addi	a0,a0,-1776 # 80008750 <syscalls+0x1b0>
    80003e48:	ffffc097          	auipc	ra,0xffffc
    80003e4c:	6f8080e7          	jalr	1784(ra) # 80000540 <panic>

0000000080003e50 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003e50:	7179                	addi	sp,sp,-48
    80003e52:	f406                	sd	ra,40(sp)
    80003e54:	f022                	sd	s0,32(sp)
    80003e56:	ec26                	sd	s1,24(sp)
    80003e58:	e84a                	sd	s2,16(sp)
    80003e5a:	e44e                	sd	s3,8(sp)
    80003e5c:	e052                	sd	s4,0(sp)
    80003e5e:	1800                	addi	s0,sp,48
    80003e60:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e62:	05050493          	addi	s1,a0,80
    80003e66:	08050913          	addi	s2,a0,128
    80003e6a:	a021                	j	80003e72 <itrunc+0x22>
    80003e6c:	0491                	addi	s1,s1,4
    80003e6e:	01248d63          	beq	s1,s2,80003e88 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e72:	408c                	lw	a1,0(s1)
    80003e74:	dde5                	beqz	a1,80003e6c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e76:	0009a503          	lw	a0,0(s3)
    80003e7a:	00000097          	auipc	ra,0x0
    80003e7e:	90c080e7          	jalr	-1780(ra) # 80003786 <bfree>
      ip->addrs[i] = 0;
    80003e82:	0004a023          	sw	zero,0(s1)
    80003e86:	b7dd                	j	80003e6c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e88:	0809a583          	lw	a1,128(s3)
    80003e8c:	e185                	bnez	a1,80003eac <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e8e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e92:	854e                	mv	a0,s3
    80003e94:	00000097          	auipc	ra,0x0
    80003e98:	de4080e7          	jalr	-540(ra) # 80003c78 <iupdate>
}
    80003e9c:	70a2                	ld	ra,40(sp)
    80003e9e:	7402                	ld	s0,32(sp)
    80003ea0:	64e2                	ld	s1,24(sp)
    80003ea2:	6942                	ld	s2,16(sp)
    80003ea4:	69a2                	ld	s3,8(sp)
    80003ea6:	6a02                	ld	s4,0(sp)
    80003ea8:	6145                	addi	sp,sp,48
    80003eaa:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003eac:	0009a503          	lw	a0,0(s3)
    80003eb0:	fffff097          	auipc	ra,0xfffff
    80003eb4:	690080e7          	jalr	1680(ra) # 80003540 <bread>
    80003eb8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003eba:	05850493          	addi	s1,a0,88
    80003ebe:	45850913          	addi	s2,a0,1112
    80003ec2:	a811                	j	80003ed6 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003ec4:	0009a503          	lw	a0,0(s3)
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	8be080e7          	jalr	-1858(ra) # 80003786 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ed0:	0491                	addi	s1,s1,4
    80003ed2:	01248563          	beq	s1,s2,80003edc <itrunc+0x8c>
      if(a[j])
    80003ed6:	408c                	lw	a1,0(s1)
    80003ed8:	dde5                	beqz	a1,80003ed0 <itrunc+0x80>
    80003eda:	b7ed                	j	80003ec4 <itrunc+0x74>
    brelse(bp);
    80003edc:	8552                	mv	a0,s4
    80003ede:	fffff097          	auipc	ra,0xfffff
    80003ee2:	792080e7          	jalr	1938(ra) # 80003670 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ee6:	0809a583          	lw	a1,128(s3)
    80003eea:	0009a503          	lw	a0,0(s3)
    80003eee:	00000097          	auipc	ra,0x0
    80003ef2:	898080e7          	jalr	-1896(ra) # 80003786 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ef6:	0809a023          	sw	zero,128(s3)
    80003efa:	bf51                	j	80003e8e <itrunc+0x3e>

0000000080003efc <iput>:
{
    80003efc:	1101                	addi	sp,sp,-32
    80003efe:	ec06                	sd	ra,24(sp)
    80003f00:	e822                	sd	s0,16(sp)
    80003f02:	e426                	sd	s1,8(sp)
    80003f04:	e04a                	sd	s2,0(sp)
    80003f06:	1000                	addi	s0,sp,32
    80003f08:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f0a:	0001c517          	auipc	a0,0x1c
    80003f0e:	0de50513          	addi	a0,a0,222 # 8001ffe8 <itable>
    80003f12:	ffffd097          	auipc	ra,0xffffd
    80003f16:	cd4080e7          	jalr	-812(ra) # 80000be6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f1a:	4498                	lw	a4,8(s1)
    80003f1c:	4785                	li	a5,1
    80003f1e:	02f70363          	beq	a4,a5,80003f44 <iput+0x48>
  ip->ref--;
    80003f22:	449c                	lw	a5,8(s1)
    80003f24:	37fd                	addiw	a5,a5,-1
    80003f26:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f28:	0001c517          	auipc	a0,0x1c
    80003f2c:	0c050513          	addi	a0,a0,192 # 8001ffe8 <itable>
    80003f30:	ffffd097          	auipc	ra,0xffffd
    80003f34:	d6a080e7          	jalr	-662(ra) # 80000c9a <release>
}
    80003f38:	60e2                	ld	ra,24(sp)
    80003f3a:	6442                	ld	s0,16(sp)
    80003f3c:	64a2                	ld	s1,8(sp)
    80003f3e:	6902                	ld	s2,0(sp)
    80003f40:	6105                	addi	sp,sp,32
    80003f42:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f44:	40bc                	lw	a5,64(s1)
    80003f46:	dff1                	beqz	a5,80003f22 <iput+0x26>
    80003f48:	04a49783          	lh	a5,74(s1)
    80003f4c:	fbf9                	bnez	a5,80003f22 <iput+0x26>
    acquiresleep(&ip->lock);
    80003f4e:	01048913          	addi	s2,s1,16
    80003f52:	854a                	mv	a0,s2
    80003f54:	00001097          	auipc	ra,0x1
    80003f58:	ab8080e7          	jalr	-1352(ra) # 80004a0c <acquiresleep>
    release(&itable.lock);
    80003f5c:	0001c517          	auipc	a0,0x1c
    80003f60:	08c50513          	addi	a0,a0,140 # 8001ffe8 <itable>
    80003f64:	ffffd097          	auipc	ra,0xffffd
    80003f68:	d36080e7          	jalr	-714(ra) # 80000c9a <release>
    itrunc(ip);
    80003f6c:	8526                	mv	a0,s1
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	ee2080e7          	jalr	-286(ra) # 80003e50 <itrunc>
    ip->type = 0;
    80003f76:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f7a:	8526                	mv	a0,s1
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	cfc080e7          	jalr	-772(ra) # 80003c78 <iupdate>
    ip->valid = 0;
    80003f84:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f88:	854a                	mv	a0,s2
    80003f8a:	00001097          	auipc	ra,0x1
    80003f8e:	ad8080e7          	jalr	-1320(ra) # 80004a62 <releasesleep>
    acquire(&itable.lock);
    80003f92:	0001c517          	auipc	a0,0x1c
    80003f96:	05650513          	addi	a0,a0,86 # 8001ffe8 <itable>
    80003f9a:	ffffd097          	auipc	ra,0xffffd
    80003f9e:	c4c080e7          	jalr	-948(ra) # 80000be6 <acquire>
    80003fa2:	b741                	j	80003f22 <iput+0x26>

0000000080003fa4 <iunlockput>:
{
    80003fa4:	1101                	addi	sp,sp,-32
    80003fa6:	ec06                	sd	ra,24(sp)
    80003fa8:	e822                	sd	s0,16(sp)
    80003faa:	e426                	sd	s1,8(sp)
    80003fac:	1000                	addi	s0,sp,32
    80003fae:	84aa                	mv	s1,a0
  iunlock(ip);
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	e54080e7          	jalr	-428(ra) # 80003e04 <iunlock>
  iput(ip);
    80003fb8:	8526                	mv	a0,s1
    80003fba:	00000097          	auipc	ra,0x0
    80003fbe:	f42080e7          	jalr	-190(ra) # 80003efc <iput>
}
    80003fc2:	60e2                	ld	ra,24(sp)
    80003fc4:	6442                	ld	s0,16(sp)
    80003fc6:	64a2                	ld	s1,8(sp)
    80003fc8:	6105                	addi	sp,sp,32
    80003fca:	8082                	ret

0000000080003fcc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003fcc:	1141                	addi	sp,sp,-16
    80003fce:	e422                	sd	s0,8(sp)
    80003fd0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003fd2:	411c                	lw	a5,0(a0)
    80003fd4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003fd6:	415c                	lw	a5,4(a0)
    80003fd8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003fda:	04451783          	lh	a5,68(a0)
    80003fde:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003fe2:	04a51783          	lh	a5,74(a0)
    80003fe6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003fea:	04c56783          	lwu	a5,76(a0)
    80003fee:	e99c                	sd	a5,16(a1)
}
    80003ff0:	6422                	ld	s0,8(sp)
    80003ff2:	0141                	addi	sp,sp,16
    80003ff4:	8082                	ret

0000000080003ff6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ff6:	457c                	lw	a5,76(a0)
    80003ff8:	0ed7e963          	bltu	a5,a3,800040ea <readi+0xf4>
{
    80003ffc:	7159                	addi	sp,sp,-112
    80003ffe:	f486                	sd	ra,104(sp)
    80004000:	f0a2                	sd	s0,96(sp)
    80004002:	eca6                	sd	s1,88(sp)
    80004004:	e8ca                	sd	s2,80(sp)
    80004006:	e4ce                	sd	s3,72(sp)
    80004008:	e0d2                	sd	s4,64(sp)
    8000400a:	fc56                	sd	s5,56(sp)
    8000400c:	f85a                	sd	s6,48(sp)
    8000400e:	f45e                	sd	s7,40(sp)
    80004010:	f062                	sd	s8,32(sp)
    80004012:	ec66                	sd	s9,24(sp)
    80004014:	e86a                	sd	s10,16(sp)
    80004016:	e46e                	sd	s11,8(sp)
    80004018:	1880                	addi	s0,sp,112
    8000401a:	8baa                	mv	s7,a0
    8000401c:	8c2e                	mv	s8,a1
    8000401e:	8ab2                	mv	s5,a2
    80004020:	84b6                	mv	s1,a3
    80004022:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004024:	9f35                	addw	a4,a4,a3
    return 0;
    80004026:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004028:	0ad76063          	bltu	a4,a3,800040c8 <readi+0xd2>
  if(off + n > ip->size)
    8000402c:	00e7f463          	bgeu	a5,a4,80004034 <readi+0x3e>
    n = ip->size - off;
    80004030:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004034:	0a0b0963          	beqz	s6,800040e6 <readi+0xf0>
    80004038:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    8000403a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000403e:	5cfd                	li	s9,-1
    80004040:	a82d                	j	8000407a <readi+0x84>
    80004042:	020a1d93          	slli	s11,s4,0x20
    80004046:	020ddd93          	srli	s11,s11,0x20
    8000404a:	05890613          	addi	a2,s2,88
    8000404e:	86ee                	mv	a3,s11
    80004050:	963a                	add	a2,a2,a4
    80004052:	85d6                	mv	a1,s5
    80004054:	8562                	mv	a0,s8
    80004056:	fffff097          	auipc	ra,0xfffff
    8000405a:	894080e7          	jalr	-1900(ra) # 800028ea <either_copyout>
    8000405e:	05950d63          	beq	a0,s9,800040b8 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004062:	854a                	mv	a0,s2
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	60c080e7          	jalr	1548(ra) # 80003670 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000406c:	013a09bb          	addw	s3,s4,s3
    80004070:	009a04bb          	addw	s1,s4,s1
    80004074:	9aee                	add	s5,s5,s11
    80004076:	0569f763          	bgeu	s3,s6,800040c4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000407a:	000ba903          	lw	s2,0(s7)
    8000407e:	00a4d59b          	srliw	a1,s1,0xa
    80004082:	855e                	mv	a0,s7
    80004084:	00000097          	auipc	ra,0x0
    80004088:	8b0080e7          	jalr	-1872(ra) # 80003934 <bmap>
    8000408c:	0005059b          	sext.w	a1,a0
    80004090:	854a                	mv	a0,s2
    80004092:	fffff097          	auipc	ra,0xfffff
    80004096:	4ae080e7          	jalr	1198(ra) # 80003540 <bread>
    8000409a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000409c:	3ff4f713          	andi	a4,s1,1023
    800040a0:	40ed07bb          	subw	a5,s10,a4
    800040a4:	413b06bb          	subw	a3,s6,s3
    800040a8:	8a3e                	mv	s4,a5
    800040aa:	2781                	sext.w	a5,a5
    800040ac:	0006861b          	sext.w	a2,a3
    800040b0:	f8f679e3          	bgeu	a2,a5,80004042 <readi+0x4c>
    800040b4:	8a36                	mv	s4,a3
    800040b6:	b771                	j	80004042 <readi+0x4c>
      brelse(bp);
    800040b8:	854a                	mv	a0,s2
    800040ba:	fffff097          	auipc	ra,0xfffff
    800040be:	5b6080e7          	jalr	1462(ra) # 80003670 <brelse>
      tot = -1;
    800040c2:	59fd                	li	s3,-1
  }
  return tot;
    800040c4:	0009851b          	sext.w	a0,s3
}
    800040c8:	70a6                	ld	ra,104(sp)
    800040ca:	7406                	ld	s0,96(sp)
    800040cc:	64e6                	ld	s1,88(sp)
    800040ce:	6946                	ld	s2,80(sp)
    800040d0:	69a6                	ld	s3,72(sp)
    800040d2:	6a06                	ld	s4,64(sp)
    800040d4:	7ae2                	ld	s5,56(sp)
    800040d6:	7b42                	ld	s6,48(sp)
    800040d8:	7ba2                	ld	s7,40(sp)
    800040da:	7c02                	ld	s8,32(sp)
    800040dc:	6ce2                	ld	s9,24(sp)
    800040de:	6d42                	ld	s10,16(sp)
    800040e0:	6da2                	ld	s11,8(sp)
    800040e2:	6165                	addi	sp,sp,112
    800040e4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040e6:	89da                	mv	s3,s6
    800040e8:	bff1                	j	800040c4 <readi+0xce>
    return 0;
    800040ea:	4501                	li	a0,0
}
    800040ec:	8082                	ret

00000000800040ee <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800040ee:	457c                	lw	a5,76(a0)
    800040f0:	10d7e863          	bltu	a5,a3,80004200 <writei+0x112>
{
    800040f4:	7159                	addi	sp,sp,-112
    800040f6:	f486                	sd	ra,104(sp)
    800040f8:	f0a2                	sd	s0,96(sp)
    800040fa:	eca6                	sd	s1,88(sp)
    800040fc:	e8ca                	sd	s2,80(sp)
    800040fe:	e4ce                	sd	s3,72(sp)
    80004100:	e0d2                	sd	s4,64(sp)
    80004102:	fc56                	sd	s5,56(sp)
    80004104:	f85a                	sd	s6,48(sp)
    80004106:	f45e                	sd	s7,40(sp)
    80004108:	f062                	sd	s8,32(sp)
    8000410a:	ec66                	sd	s9,24(sp)
    8000410c:	e86a                	sd	s10,16(sp)
    8000410e:	e46e                	sd	s11,8(sp)
    80004110:	1880                	addi	s0,sp,112
    80004112:	8b2a                	mv	s6,a0
    80004114:	8c2e                	mv	s8,a1
    80004116:	8ab2                	mv	s5,a2
    80004118:	8936                	mv	s2,a3
    8000411a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    8000411c:	00e687bb          	addw	a5,a3,a4
    80004120:	0ed7e263          	bltu	a5,a3,80004204 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004124:	00043737          	lui	a4,0x43
    80004128:	0ef76063          	bltu	a4,a5,80004208 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000412c:	0c0b8863          	beqz	s7,800041fc <writei+0x10e>
    80004130:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80004132:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004136:	5cfd                	li	s9,-1
    80004138:	a091                	j	8000417c <writei+0x8e>
    8000413a:	02099d93          	slli	s11,s3,0x20
    8000413e:	020ddd93          	srli	s11,s11,0x20
    80004142:	05848513          	addi	a0,s1,88
    80004146:	86ee                	mv	a3,s11
    80004148:	8656                	mv	a2,s5
    8000414a:	85e2                	mv	a1,s8
    8000414c:	953a                	add	a0,a0,a4
    8000414e:	ffffe097          	auipc	ra,0xffffe
    80004152:	7f2080e7          	jalr	2034(ra) # 80002940 <either_copyin>
    80004156:	07950263          	beq	a0,s9,800041ba <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    8000415a:	8526                	mv	a0,s1
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	790080e7          	jalr	1936(ra) # 800048ec <log_write>
    brelse(bp);
    80004164:	8526                	mv	a0,s1
    80004166:	fffff097          	auipc	ra,0xfffff
    8000416a:	50a080e7          	jalr	1290(ra) # 80003670 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000416e:	01498a3b          	addw	s4,s3,s4
    80004172:	0129893b          	addw	s2,s3,s2
    80004176:	9aee                	add	s5,s5,s11
    80004178:	057a7663          	bgeu	s4,s7,800041c4 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    8000417c:	000b2483          	lw	s1,0(s6)
    80004180:	00a9559b          	srliw	a1,s2,0xa
    80004184:	855a                	mv	a0,s6
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	7ae080e7          	jalr	1966(ra) # 80003934 <bmap>
    8000418e:	0005059b          	sext.w	a1,a0
    80004192:	8526                	mv	a0,s1
    80004194:	fffff097          	auipc	ra,0xfffff
    80004198:	3ac080e7          	jalr	940(ra) # 80003540 <bread>
    8000419c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000419e:	3ff97713          	andi	a4,s2,1023
    800041a2:	40ed07bb          	subw	a5,s10,a4
    800041a6:	414b86bb          	subw	a3,s7,s4
    800041aa:	89be                	mv	s3,a5
    800041ac:	2781                	sext.w	a5,a5
    800041ae:	0006861b          	sext.w	a2,a3
    800041b2:	f8f674e3          	bgeu	a2,a5,8000413a <writei+0x4c>
    800041b6:	89b6                	mv	s3,a3
    800041b8:	b749                	j	8000413a <writei+0x4c>
      brelse(bp);
    800041ba:	8526                	mv	a0,s1
    800041bc:	fffff097          	auipc	ra,0xfffff
    800041c0:	4b4080e7          	jalr	1204(ra) # 80003670 <brelse>
  }

  if(off > ip->size)
    800041c4:	04cb2783          	lw	a5,76(s6)
    800041c8:	0127f463          	bgeu	a5,s2,800041d0 <writei+0xe2>
    ip->size = off;
    800041cc:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800041d0:	855a                	mv	a0,s6
    800041d2:	00000097          	auipc	ra,0x0
    800041d6:	aa6080e7          	jalr	-1370(ra) # 80003c78 <iupdate>

  return tot;
    800041da:	000a051b          	sext.w	a0,s4
}
    800041de:	70a6                	ld	ra,104(sp)
    800041e0:	7406                	ld	s0,96(sp)
    800041e2:	64e6                	ld	s1,88(sp)
    800041e4:	6946                	ld	s2,80(sp)
    800041e6:	69a6                	ld	s3,72(sp)
    800041e8:	6a06                	ld	s4,64(sp)
    800041ea:	7ae2                	ld	s5,56(sp)
    800041ec:	7b42                	ld	s6,48(sp)
    800041ee:	7ba2                	ld	s7,40(sp)
    800041f0:	7c02                	ld	s8,32(sp)
    800041f2:	6ce2                	ld	s9,24(sp)
    800041f4:	6d42                	ld	s10,16(sp)
    800041f6:	6da2                	ld	s11,8(sp)
    800041f8:	6165                	addi	sp,sp,112
    800041fa:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041fc:	8a5e                	mv	s4,s7
    800041fe:	bfc9                	j	800041d0 <writei+0xe2>
    return -1;
    80004200:	557d                	li	a0,-1
}
    80004202:	8082                	ret
    return -1;
    80004204:	557d                	li	a0,-1
    80004206:	bfe1                	j	800041de <writei+0xf0>
    return -1;
    80004208:	557d                	li	a0,-1
    8000420a:	bfd1                	j	800041de <writei+0xf0>

000000008000420c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000420c:	1141                	addi	sp,sp,-16
    8000420e:	e406                	sd	ra,8(sp)
    80004210:	e022                	sd	s0,0(sp)
    80004212:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004214:	4639                	li	a2,14
    80004216:	ffffd097          	auipc	ra,0xffffd
    8000421a:	ba4080e7          	jalr	-1116(ra) # 80000dba <strncmp>
}
    8000421e:	60a2                	ld	ra,8(sp)
    80004220:	6402                	ld	s0,0(sp)
    80004222:	0141                	addi	sp,sp,16
    80004224:	8082                	ret

0000000080004226 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004226:	7139                	addi	sp,sp,-64
    80004228:	fc06                	sd	ra,56(sp)
    8000422a:	f822                	sd	s0,48(sp)
    8000422c:	f426                	sd	s1,40(sp)
    8000422e:	f04a                	sd	s2,32(sp)
    80004230:	ec4e                	sd	s3,24(sp)
    80004232:	e852                	sd	s4,16(sp)
    80004234:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004236:	04451703          	lh	a4,68(a0)
    8000423a:	4785                	li	a5,1
    8000423c:	00f71a63          	bne	a4,a5,80004250 <dirlookup+0x2a>
    80004240:	892a                	mv	s2,a0
    80004242:	89ae                	mv	s3,a1
    80004244:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004246:	457c                	lw	a5,76(a0)
    80004248:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000424a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000424c:	e79d                	bnez	a5,8000427a <dirlookup+0x54>
    8000424e:	a8a5                	j	800042c6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004250:	00004517          	auipc	a0,0x4
    80004254:	50850513          	addi	a0,a0,1288 # 80008758 <syscalls+0x1b8>
    80004258:	ffffc097          	auipc	ra,0xffffc
    8000425c:	2e8080e7          	jalr	744(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004260:	00004517          	auipc	a0,0x4
    80004264:	51050513          	addi	a0,a0,1296 # 80008770 <syscalls+0x1d0>
    80004268:	ffffc097          	auipc	ra,0xffffc
    8000426c:	2d8080e7          	jalr	728(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004270:	24c1                	addiw	s1,s1,16
    80004272:	04c92783          	lw	a5,76(s2)
    80004276:	04f4f763          	bgeu	s1,a5,800042c4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000427a:	4741                	li	a4,16
    8000427c:	86a6                	mv	a3,s1
    8000427e:	fc040613          	addi	a2,s0,-64
    80004282:	4581                	li	a1,0
    80004284:	854a                	mv	a0,s2
    80004286:	00000097          	auipc	ra,0x0
    8000428a:	d70080e7          	jalr	-656(ra) # 80003ff6 <readi>
    8000428e:	47c1                	li	a5,16
    80004290:	fcf518e3          	bne	a0,a5,80004260 <dirlookup+0x3a>
    if(de.inum == 0)
    80004294:	fc045783          	lhu	a5,-64(s0)
    80004298:	dfe1                	beqz	a5,80004270 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000429a:	fc240593          	addi	a1,s0,-62
    8000429e:	854e                	mv	a0,s3
    800042a0:	00000097          	auipc	ra,0x0
    800042a4:	f6c080e7          	jalr	-148(ra) # 8000420c <namecmp>
    800042a8:	f561                	bnez	a0,80004270 <dirlookup+0x4a>
      if(poff)
    800042aa:	000a0463          	beqz	s4,800042b2 <dirlookup+0x8c>
        *poff = off;
    800042ae:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800042b2:	fc045583          	lhu	a1,-64(s0)
    800042b6:	00092503          	lw	a0,0(s2)
    800042ba:	fffff097          	auipc	ra,0xfffff
    800042be:	754080e7          	jalr	1876(ra) # 80003a0e <iget>
    800042c2:	a011                	j	800042c6 <dirlookup+0xa0>
  return 0;
    800042c4:	4501                	li	a0,0
}
    800042c6:	70e2                	ld	ra,56(sp)
    800042c8:	7442                	ld	s0,48(sp)
    800042ca:	74a2                	ld	s1,40(sp)
    800042cc:	7902                	ld	s2,32(sp)
    800042ce:	69e2                	ld	s3,24(sp)
    800042d0:	6a42                	ld	s4,16(sp)
    800042d2:	6121                	addi	sp,sp,64
    800042d4:	8082                	ret

00000000800042d6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800042d6:	711d                	addi	sp,sp,-96
    800042d8:	ec86                	sd	ra,88(sp)
    800042da:	e8a2                	sd	s0,80(sp)
    800042dc:	e4a6                	sd	s1,72(sp)
    800042de:	e0ca                	sd	s2,64(sp)
    800042e0:	fc4e                	sd	s3,56(sp)
    800042e2:	f852                	sd	s4,48(sp)
    800042e4:	f456                	sd	s5,40(sp)
    800042e6:	f05a                	sd	s6,32(sp)
    800042e8:	ec5e                	sd	s7,24(sp)
    800042ea:	e862                	sd	s8,16(sp)
    800042ec:	e466                	sd	s9,8(sp)
    800042ee:	1080                	addi	s0,sp,96
    800042f0:	84aa                	mv	s1,a0
    800042f2:	8b2e                	mv	s6,a1
    800042f4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042f6:	00054703          	lbu	a4,0(a0)
    800042fa:	02f00793          	li	a5,47
    800042fe:	02f70363          	beq	a4,a5,80004324 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004302:	ffffd097          	auipc	ra,0xffffd
    80004306:	700080e7          	jalr	1792(ra) # 80001a02 <myproc>
    8000430a:	15053503          	ld	a0,336(a0)
    8000430e:	00000097          	auipc	ra,0x0
    80004312:	9f6080e7          	jalr	-1546(ra) # 80003d04 <idup>
    80004316:	89aa                	mv	s3,a0
  while(*path == '/')
    80004318:	02f00913          	li	s2,47
  len = path - s;
    8000431c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000431e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004320:	4c05                	li	s8,1
    80004322:	a865                	j	800043da <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004324:	4585                	li	a1,1
    80004326:	4505                	li	a0,1
    80004328:	fffff097          	auipc	ra,0xfffff
    8000432c:	6e6080e7          	jalr	1766(ra) # 80003a0e <iget>
    80004330:	89aa                	mv	s3,a0
    80004332:	b7dd                	j	80004318 <namex+0x42>
      iunlockput(ip);
    80004334:	854e                	mv	a0,s3
    80004336:	00000097          	auipc	ra,0x0
    8000433a:	c6e080e7          	jalr	-914(ra) # 80003fa4 <iunlockput>
      return 0;
    8000433e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004340:	854e                	mv	a0,s3
    80004342:	60e6                	ld	ra,88(sp)
    80004344:	6446                	ld	s0,80(sp)
    80004346:	64a6                	ld	s1,72(sp)
    80004348:	6906                	ld	s2,64(sp)
    8000434a:	79e2                	ld	s3,56(sp)
    8000434c:	7a42                	ld	s4,48(sp)
    8000434e:	7aa2                	ld	s5,40(sp)
    80004350:	7b02                	ld	s6,32(sp)
    80004352:	6be2                	ld	s7,24(sp)
    80004354:	6c42                	ld	s8,16(sp)
    80004356:	6ca2                	ld	s9,8(sp)
    80004358:	6125                	addi	sp,sp,96
    8000435a:	8082                	ret
      iunlock(ip);
    8000435c:	854e                	mv	a0,s3
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	aa6080e7          	jalr	-1370(ra) # 80003e04 <iunlock>
      return ip;
    80004366:	bfe9                	j	80004340 <namex+0x6a>
      iunlockput(ip);
    80004368:	854e                	mv	a0,s3
    8000436a:	00000097          	auipc	ra,0x0
    8000436e:	c3a080e7          	jalr	-966(ra) # 80003fa4 <iunlockput>
      return 0;
    80004372:	89d2                	mv	s3,s4
    80004374:	b7f1                	j	80004340 <namex+0x6a>
  len = path - s;
    80004376:	40b48633          	sub	a2,s1,a1
    8000437a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000437e:	094cd463          	bge	s9,s4,80004406 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004382:	4639                	li	a2,14
    80004384:	8556                	mv	a0,s5
    80004386:	ffffd097          	auipc	ra,0xffffd
    8000438a:	9bc080e7          	jalr	-1604(ra) # 80000d42 <memmove>
  while(*path == '/')
    8000438e:	0004c783          	lbu	a5,0(s1)
    80004392:	01279763          	bne	a5,s2,800043a0 <namex+0xca>
    path++;
    80004396:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004398:	0004c783          	lbu	a5,0(s1)
    8000439c:	ff278de3          	beq	a5,s2,80004396 <namex+0xc0>
    ilock(ip);
    800043a0:	854e                	mv	a0,s3
    800043a2:	00000097          	auipc	ra,0x0
    800043a6:	9a0080e7          	jalr	-1632(ra) # 80003d42 <ilock>
    if(ip->type != T_DIR){
    800043aa:	04499783          	lh	a5,68(s3)
    800043ae:	f98793e3          	bne	a5,s8,80004334 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800043b2:	000b0563          	beqz	s6,800043bc <namex+0xe6>
    800043b6:	0004c783          	lbu	a5,0(s1)
    800043ba:	d3cd                	beqz	a5,8000435c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800043bc:	865e                	mv	a2,s7
    800043be:	85d6                	mv	a1,s5
    800043c0:	854e                	mv	a0,s3
    800043c2:	00000097          	auipc	ra,0x0
    800043c6:	e64080e7          	jalr	-412(ra) # 80004226 <dirlookup>
    800043ca:	8a2a                	mv	s4,a0
    800043cc:	dd51                	beqz	a0,80004368 <namex+0x92>
    iunlockput(ip);
    800043ce:	854e                	mv	a0,s3
    800043d0:	00000097          	auipc	ra,0x0
    800043d4:	bd4080e7          	jalr	-1068(ra) # 80003fa4 <iunlockput>
    ip = next;
    800043d8:	89d2                	mv	s3,s4
  while(*path == '/')
    800043da:	0004c783          	lbu	a5,0(s1)
    800043de:	05279763          	bne	a5,s2,8000442c <namex+0x156>
    path++;
    800043e2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800043e4:	0004c783          	lbu	a5,0(s1)
    800043e8:	ff278de3          	beq	a5,s2,800043e2 <namex+0x10c>
  if(*path == 0)
    800043ec:	c79d                	beqz	a5,8000441a <namex+0x144>
    path++;
    800043ee:	85a6                	mv	a1,s1
  len = path - s;
    800043f0:	8a5e                	mv	s4,s7
    800043f2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800043f4:	01278963          	beq	a5,s2,80004406 <namex+0x130>
    800043f8:	dfbd                	beqz	a5,80004376 <namex+0xa0>
    path++;
    800043fa:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800043fc:	0004c783          	lbu	a5,0(s1)
    80004400:	ff279ce3          	bne	a5,s2,800043f8 <namex+0x122>
    80004404:	bf8d                	j	80004376 <namex+0xa0>
    memmove(name, s, len);
    80004406:	2601                	sext.w	a2,a2
    80004408:	8556                	mv	a0,s5
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	938080e7          	jalr	-1736(ra) # 80000d42 <memmove>
    name[len] = 0;
    80004412:	9a56                	add	s4,s4,s5
    80004414:	000a0023          	sb	zero,0(s4)
    80004418:	bf9d                	j	8000438e <namex+0xb8>
  if(nameiparent){
    8000441a:	f20b03e3          	beqz	s6,80004340 <namex+0x6a>
    iput(ip);
    8000441e:	854e                	mv	a0,s3
    80004420:	00000097          	auipc	ra,0x0
    80004424:	adc080e7          	jalr	-1316(ra) # 80003efc <iput>
    return 0;
    80004428:	4981                	li	s3,0
    8000442a:	bf19                	j	80004340 <namex+0x6a>
  if(*path == 0)
    8000442c:	d7fd                	beqz	a5,8000441a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000442e:	0004c783          	lbu	a5,0(s1)
    80004432:	85a6                	mv	a1,s1
    80004434:	b7d1                	j	800043f8 <namex+0x122>

0000000080004436 <dirlink>:
{
    80004436:	7139                	addi	sp,sp,-64
    80004438:	fc06                	sd	ra,56(sp)
    8000443a:	f822                	sd	s0,48(sp)
    8000443c:	f426                	sd	s1,40(sp)
    8000443e:	f04a                	sd	s2,32(sp)
    80004440:	ec4e                	sd	s3,24(sp)
    80004442:	e852                	sd	s4,16(sp)
    80004444:	0080                	addi	s0,sp,64
    80004446:	892a                	mv	s2,a0
    80004448:	8a2e                	mv	s4,a1
    8000444a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000444c:	4601                	li	a2,0
    8000444e:	00000097          	auipc	ra,0x0
    80004452:	dd8080e7          	jalr	-552(ra) # 80004226 <dirlookup>
    80004456:	e93d                	bnez	a0,800044cc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004458:	04c92483          	lw	s1,76(s2)
    8000445c:	c49d                	beqz	s1,8000448a <dirlink+0x54>
    8000445e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004460:	4741                	li	a4,16
    80004462:	86a6                	mv	a3,s1
    80004464:	fc040613          	addi	a2,s0,-64
    80004468:	4581                	li	a1,0
    8000446a:	854a                	mv	a0,s2
    8000446c:	00000097          	auipc	ra,0x0
    80004470:	b8a080e7          	jalr	-1142(ra) # 80003ff6 <readi>
    80004474:	47c1                	li	a5,16
    80004476:	06f51163          	bne	a0,a5,800044d8 <dirlink+0xa2>
    if(de.inum == 0)
    8000447a:	fc045783          	lhu	a5,-64(s0)
    8000447e:	c791                	beqz	a5,8000448a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004480:	24c1                	addiw	s1,s1,16
    80004482:	04c92783          	lw	a5,76(s2)
    80004486:	fcf4ede3          	bltu	s1,a5,80004460 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000448a:	4639                	li	a2,14
    8000448c:	85d2                	mv	a1,s4
    8000448e:	fc240513          	addi	a0,s0,-62
    80004492:	ffffd097          	auipc	ra,0xffffd
    80004496:	964080e7          	jalr	-1692(ra) # 80000df6 <strncpy>
  de.inum = inum;
    8000449a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000449e:	4741                	li	a4,16
    800044a0:	86a6                	mv	a3,s1
    800044a2:	fc040613          	addi	a2,s0,-64
    800044a6:	4581                	li	a1,0
    800044a8:	854a                	mv	a0,s2
    800044aa:	00000097          	auipc	ra,0x0
    800044ae:	c44080e7          	jalr	-956(ra) # 800040ee <writei>
    800044b2:	872a                	mv	a4,a0
    800044b4:	47c1                	li	a5,16
  return 0;
    800044b6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044b8:	02f71863          	bne	a4,a5,800044e8 <dirlink+0xb2>
}
    800044bc:	70e2                	ld	ra,56(sp)
    800044be:	7442                	ld	s0,48(sp)
    800044c0:	74a2                	ld	s1,40(sp)
    800044c2:	7902                	ld	s2,32(sp)
    800044c4:	69e2                	ld	s3,24(sp)
    800044c6:	6a42                	ld	s4,16(sp)
    800044c8:	6121                	addi	sp,sp,64
    800044ca:	8082                	ret
    iput(ip);
    800044cc:	00000097          	auipc	ra,0x0
    800044d0:	a30080e7          	jalr	-1488(ra) # 80003efc <iput>
    return -1;
    800044d4:	557d                	li	a0,-1
    800044d6:	b7dd                	j	800044bc <dirlink+0x86>
      panic("dirlink read");
    800044d8:	00004517          	auipc	a0,0x4
    800044dc:	2a850513          	addi	a0,a0,680 # 80008780 <syscalls+0x1e0>
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	060080e7          	jalr	96(ra) # 80000540 <panic>
    panic("dirlink");
    800044e8:	00004517          	auipc	a0,0x4
    800044ec:	3a850513          	addi	a0,a0,936 # 80008890 <syscalls+0x2f0>
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	050080e7          	jalr	80(ra) # 80000540 <panic>

00000000800044f8 <namei>:

struct inode*
namei(char *path)
{
    800044f8:	1101                	addi	sp,sp,-32
    800044fa:	ec06                	sd	ra,24(sp)
    800044fc:	e822                	sd	s0,16(sp)
    800044fe:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004500:	fe040613          	addi	a2,s0,-32
    80004504:	4581                	li	a1,0
    80004506:	00000097          	auipc	ra,0x0
    8000450a:	dd0080e7          	jalr	-560(ra) # 800042d6 <namex>
}
    8000450e:	60e2                	ld	ra,24(sp)
    80004510:	6442                	ld	s0,16(sp)
    80004512:	6105                	addi	sp,sp,32
    80004514:	8082                	ret

0000000080004516 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004516:	1141                	addi	sp,sp,-16
    80004518:	e406                	sd	ra,8(sp)
    8000451a:	e022                	sd	s0,0(sp)
    8000451c:	0800                	addi	s0,sp,16
    8000451e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004520:	4585                	li	a1,1
    80004522:	00000097          	auipc	ra,0x0
    80004526:	db4080e7          	jalr	-588(ra) # 800042d6 <namex>
}
    8000452a:	60a2                	ld	ra,8(sp)
    8000452c:	6402                	ld	s0,0(sp)
    8000452e:	0141                	addi	sp,sp,16
    80004530:	8082                	ret

0000000080004532 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004532:	1101                	addi	sp,sp,-32
    80004534:	ec06                	sd	ra,24(sp)
    80004536:	e822                	sd	s0,16(sp)
    80004538:	e426                	sd	s1,8(sp)
    8000453a:	e04a                	sd	s2,0(sp)
    8000453c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000453e:	0001d917          	auipc	s2,0x1d
    80004542:	55290913          	addi	s2,s2,1362 # 80021a90 <log>
    80004546:	01892583          	lw	a1,24(s2)
    8000454a:	02892503          	lw	a0,40(s2)
    8000454e:	fffff097          	auipc	ra,0xfffff
    80004552:	ff2080e7          	jalr	-14(ra) # 80003540 <bread>
    80004556:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004558:	02c92683          	lw	a3,44(s2)
    8000455c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000455e:	02d05763          	blez	a3,8000458c <write_head+0x5a>
    80004562:	0001d797          	auipc	a5,0x1d
    80004566:	55e78793          	addi	a5,a5,1374 # 80021ac0 <log+0x30>
    8000456a:	05c50713          	addi	a4,a0,92
    8000456e:	36fd                	addiw	a3,a3,-1
    80004570:	1682                	slli	a3,a3,0x20
    80004572:	9281                	srli	a3,a3,0x20
    80004574:	068a                	slli	a3,a3,0x2
    80004576:	0001d617          	auipc	a2,0x1d
    8000457a:	54e60613          	addi	a2,a2,1358 # 80021ac4 <log+0x34>
    8000457e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004580:	4390                	lw	a2,0(a5)
    80004582:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004584:	0791                	addi	a5,a5,4
    80004586:	0711                	addi	a4,a4,4
    80004588:	fed79ce3          	bne	a5,a3,80004580 <write_head+0x4e>
  }
  bwrite(buf);
    8000458c:	8526                	mv	a0,s1
    8000458e:	fffff097          	auipc	ra,0xfffff
    80004592:	0a4080e7          	jalr	164(ra) # 80003632 <bwrite>
  brelse(buf);
    80004596:	8526                	mv	a0,s1
    80004598:	fffff097          	auipc	ra,0xfffff
    8000459c:	0d8080e7          	jalr	216(ra) # 80003670 <brelse>
}
    800045a0:	60e2                	ld	ra,24(sp)
    800045a2:	6442                	ld	s0,16(sp)
    800045a4:	64a2                	ld	s1,8(sp)
    800045a6:	6902                	ld	s2,0(sp)
    800045a8:	6105                	addi	sp,sp,32
    800045aa:	8082                	ret

00000000800045ac <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ac:	0001d797          	auipc	a5,0x1d
    800045b0:	5107a783          	lw	a5,1296(a5) # 80021abc <log+0x2c>
    800045b4:	0af05d63          	blez	a5,8000466e <install_trans+0xc2>
{
    800045b8:	7139                	addi	sp,sp,-64
    800045ba:	fc06                	sd	ra,56(sp)
    800045bc:	f822                	sd	s0,48(sp)
    800045be:	f426                	sd	s1,40(sp)
    800045c0:	f04a                	sd	s2,32(sp)
    800045c2:	ec4e                	sd	s3,24(sp)
    800045c4:	e852                	sd	s4,16(sp)
    800045c6:	e456                	sd	s5,8(sp)
    800045c8:	e05a                	sd	s6,0(sp)
    800045ca:	0080                	addi	s0,sp,64
    800045cc:	8b2a                	mv	s6,a0
    800045ce:	0001da97          	auipc	s5,0x1d
    800045d2:	4f2a8a93          	addi	s5,s5,1266 # 80021ac0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800045d6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800045d8:	0001d997          	auipc	s3,0x1d
    800045dc:	4b898993          	addi	s3,s3,1208 # 80021a90 <log>
    800045e0:	a035                	j	8000460c <install_trans+0x60>
      bunpin(dbuf);
    800045e2:	8526                	mv	a0,s1
    800045e4:	fffff097          	auipc	ra,0xfffff
    800045e8:	166080e7          	jalr	358(ra) # 8000374a <bunpin>
    brelse(lbuf);
    800045ec:	854a                	mv	a0,s2
    800045ee:	fffff097          	auipc	ra,0xfffff
    800045f2:	082080e7          	jalr	130(ra) # 80003670 <brelse>
    brelse(dbuf);
    800045f6:	8526                	mv	a0,s1
    800045f8:	fffff097          	auipc	ra,0xfffff
    800045fc:	078080e7          	jalr	120(ra) # 80003670 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004600:	2a05                	addiw	s4,s4,1
    80004602:	0a91                	addi	s5,s5,4
    80004604:	02c9a783          	lw	a5,44(s3)
    80004608:	04fa5963          	bge	s4,a5,8000465a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000460c:	0189a583          	lw	a1,24(s3)
    80004610:	014585bb          	addw	a1,a1,s4
    80004614:	2585                	addiw	a1,a1,1
    80004616:	0289a503          	lw	a0,40(s3)
    8000461a:	fffff097          	auipc	ra,0xfffff
    8000461e:	f26080e7          	jalr	-218(ra) # 80003540 <bread>
    80004622:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004624:	000aa583          	lw	a1,0(s5)
    80004628:	0289a503          	lw	a0,40(s3)
    8000462c:	fffff097          	auipc	ra,0xfffff
    80004630:	f14080e7          	jalr	-236(ra) # 80003540 <bread>
    80004634:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004636:	40000613          	li	a2,1024
    8000463a:	05890593          	addi	a1,s2,88
    8000463e:	05850513          	addi	a0,a0,88
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	700080e7          	jalr	1792(ra) # 80000d42 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000464a:	8526                	mv	a0,s1
    8000464c:	fffff097          	auipc	ra,0xfffff
    80004650:	fe6080e7          	jalr	-26(ra) # 80003632 <bwrite>
    if(recovering == 0)
    80004654:	f80b1ce3          	bnez	s6,800045ec <install_trans+0x40>
    80004658:	b769                	j	800045e2 <install_trans+0x36>
}
    8000465a:	70e2                	ld	ra,56(sp)
    8000465c:	7442                	ld	s0,48(sp)
    8000465e:	74a2                	ld	s1,40(sp)
    80004660:	7902                	ld	s2,32(sp)
    80004662:	69e2                	ld	s3,24(sp)
    80004664:	6a42                	ld	s4,16(sp)
    80004666:	6aa2                	ld	s5,8(sp)
    80004668:	6b02                	ld	s6,0(sp)
    8000466a:	6121                	addi	sp,sp,64
    8000466c:	8082                	ret
    8000466e:	8082                	ret

0000000080004670 <initlog>:
{
    80004670:	7179                	addi	sp,sp,-48
    80004672:	f406                	sd	ra,40(sp)
    80004674:	f022                	sd	s0,32(sp)
    80004676:	ec26                	sd	s1,24(sp)
    80004678:	e84a                	sd	s2,16(sp)
    8000467a:	e44e                	sd	s3,8(sp)
    8000467c:	1800                	addi	s0,sp,48
    8000467e:	892a                	mv	s2,a0
    80004680:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004682:	0001d497          	auipc	s1,0x1d
    80004686:	40e48493          	addi	s1,s1,1038 # 80021a90 <log>
    8000468a:	00004597          	auipc	a1,0x4
    8000468e:	10658593          	addi	a1,a1,262 # 80008790 <syscalls+0x1f0>
    80004692:	8526                	mv	a0,s1
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	4c2080e7          	jalr	1218(ra) # 80000b56 <initlock>
  log.start = sb->logstart;
    8000469c:	0149a583          	lw	a1,20(s3)
    800046a0:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800046a2:	0109a783          	lw	a5,16(s3)
    800046a6:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800046a8:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800046ac:	854a                	mv	a0,s2
    800046ae:	fffff097          	auipc	ra,0xfffff
    800046b2:	e92080e7          	jalr	-366(ra) # 80003540 <bread>
  log.lh.n = lh->n;
    800046b6:	4d3c                	lw	a5,88(a0)
    800046b8:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800046ba:	02f05563          	blez	a5,800046e4 <initlog+0x74>
    800046be:	05c50713          	addi	a4,a0,92
    800046c2:	0001d697          	auipc	a3,0x1d
    800046c6:	3fe68693          	addi	a3,a3,1022 # 80021ac0 <log+0x30>
    800046ca:	37fd                	addiw	a5,a5,-1
    800046cc:	1782                	slli	a5,a5,0x20
    800046ce:	9381                	srli	a5,a5,0x20
    800046d0:	078a                	slli	a5,a5,0x2
    800046d2:	06050613          	addi	a2,a0,96
    800046d6:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800046d8:	4310                	lw	a2,0(a4)
    800046da:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800046dc:	0711                	addi	a4,a4,4
    800046de:	0691                	addi	a3,a3,4
    800046e0:	fef71ce3          	bne	a4,a5,800046d8 <initlog+0x68>
  brelse(buf);
    800046e4:	fffff097          	auipc	ra,0xfffff
    800046e8:	f8c080e7          	jalr	-116(ra) # 80003670 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800046ec:	4505                	li	a0,1
    800046ee:	00000097          	auipc	ra,0x0
    800046f2:	ebe080e7          	jalr	-322(ra) # 800045ac <install_trans>
  log.lh.n = 0;
    800046f6:	0001d797          	auipc	a5,0x1d
    800046fa:	3c07a323          	sw	zero,966(a5) # 80021abc <log+0x2c>
  write_head(); // clear the log
    800046fe:	00000097          	auipc	ra,0x0
    80004702:	e34080e7          	jalr	-460(ra) # 80004532 <write_head>
}
    80004706:	70a2                	ld	ra,40(sp)
    80004708:	7402                	ld	s0,32(sp)
    8000470a:	64e2                	ld	s1,24(sp)
    8000470c:	6942                	ld	s2,16(sp)
    8000470e:	69a2                	ld	s3,8(sp)
    80004710:	6145                	addi	sp,sp,48
    80004712:	8082                	ret

0000000080004714 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004714:	1101                	addi	sp,sp,-32
    80004716:	ec06                	sd	ra,24(sp)
    80004718:	e822                	sd	s0,16(sp)
    8000471a:	e426                	sd	s1,8(sp)
    8000471c:	e04a                	sd	s2,0(sp)
    8000471e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004720:	0001d517          	auipc	a0,0x1d
    80004724:	37050513          	addi	a0,a0,880 # 80021a90 <log>
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	4be080e7          	jalr	1214(ra) # 80000be6 <acquire>
  while(1){
    if(log.committing){
    80004730:	0001d497          	auipc	s1,0x1d
    80004734:	36048493          	addi	s1,s1,864 # 80021a90 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004738:	4979                	li	s2,30
    8000473a:	a039                	j	80004748 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000473c:	85a6                	mv	a1,s1
    8000473e:	8526                	mv	a0,s1
    80004740:	ffffe097          	auipc	ra,0xffffe
    80004744:	bb4080e7          	jalr	-1100(ra) # 800022f4 <sleep>
    if(log.committing){
    80004748:	50dc                	lw	a5,36(s1)
    8000474a:	fbed                	bnez	a5,8000473c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000474c:	509c                	lw	a5,32(s1)
    8000474e:	0017871b          	addiw	a4,a5,1
    80004752:	0007069b          	sext.w	a3,a4
    80004756:	0027179b          	slliw	a5,a4,0x2
    8000475a:	9fb9                	addw	a5,a5,a4
    8000475c:	0017979b          	slliw	a5,a5,0x1
    80004760:	54d8                	lw	a4,44(s1)
    80004762:	9fb9                	addw	a5,a5,a4
    80004764:	00f95963          	bge	s2,a5,80004776 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004768:	85a6                	mv	a1,s1
    8000476a:	8526                	mv	a0,s1
    8000476c:	ffffe097          	auipc	ra,0xffffe
    80004770:	b88080e7          	jalr	-1144(ra) # 800022f4 <sleep>
    80004774:	bfd1                	j	80004748 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004776:	0001d517          	auipc	a0,0x1d
    8000477a:	31a50513          	addi	a0,a0,794 # 80021a90 <log>
    8000477e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	51a080e7          	jalr	1306(ra) # 80000c9a <release>
      break;
    }
  }
}
    80004788:	60e2                	ld	ra,24(sp)
    8000478a:	6442                	ld	s0,16(sp)
    8000478c:	64a2                	ld	s1,8(sp)
    8000478e:	6902                	ld	s2,0(sp)
    80004790:	6105                	addi	sp,sp,32
    80004792:	8082                	ret

0000000080004794 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004794:	7139                	addi	sp,sp,-64
    80004796:	fc06                	sd	ra,56(sp)
    80004798:	f822                	sd	s0,48(sp)
    8000479a:	f426                	sd	s1,40(sp)
    8000479c:	f04a                	sd	s2,32(sp)
    8000479e:	ec4e                	sd	s3,24(sp)
    800047a0:	e852                	sd	s4,16(sp)
    800047a2:	e456                	sd	s5,8(sp)
    800047a4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800047a6:	0001d497          	auipc	s1,0x1d
    800047aa:	2ea48493          	addi	s1,s1,746 # 80021a90 <log>
    800047ae:	8526                	mv	a0,s1
    800047b0:	ffffc097          	auipc	ra,0xffffc
    800047b4:	436080e7          	jalr	1078(ra) # 80000be6 <acquire>
  log.outstanding -= 1;
    800047b8:	509c                	lw	a5,32(s1)
    800047ba:	37fd                	addiw	a5,a5,-1
    800047bc:	0007891b          	sext.w	s2,a5
    800047c0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047c2:	50dc                	lw	a5,36(s1)
    800047c4:	efb9                	bnez	a5,80004822 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800047c6:	06091663          	bnez	s2,80004832 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800047ca:	0001d497          	auipc	s1,0x1d
    800047ce:	2c648493          	addi	s1,s1,710 # 80021a90 <log>
    800047d2:	4785                	li	a5,1
    800047d4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800047d6:	8526                	mv	a0,s1
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	4c2080e7          	jalr	1218(ra) # 80000c9a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800047e0:	54dc                	lw	a5,44(s1)
    800047e2:	06f04763          	bgtz	a5,80004850 <end_op+0xbc>
    acquire(&log.lock);
    800047e6:	0001d497          	auipc	s1,0x1d
    800047ea:	2aa48493          	addi	s1,s1,682 # 80021a90 <log>
    800047ee:	8526                	mv	a0,s1
    800047f0:	ffffc097          	auipc	ra,0xffffc
    800047f4:	3f6080e7          	jalr	1014(ra) # 80000be6 <acquire>
    log.committing = 0;
    800047f8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800047fc:	8526                	mv	a0,s1
    800047fe:	ffffe097          	auipc	ra,0xffffe
    80004802:	cdc080e7          	jalr	-804(ra) # 800024da <wakeup>
    release(&log.lock);
    80004806:	8526                	mv	a0,s1
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	492080e7          	jalr	1170(ra) # 80000c9a <release>
}
    80004810:	70e2                	ld	ra,56(sp)
    80004812:	7442                	ld	s0,48(sp)
    80004814:	74a2                	ld	s1,40(sp)
    80004816:	7902                	ld	s2,32(sp)
    80004818:	69e2                	ld	s3,24(sp)
    8000481a:	6a42                	ld	s4,16(sp)
    8000481c:	6aa2                	ld	s5,8(sp)
    8000481e:	6121                	addi	sp,sp,64
    80004820:	8082                	ret
    panic("log.committing");
    80004822:	00004517          	auipc	a0,0x4
    80004826:	f7650513          	addi	a0,a0,-138 # 80008798 <syscalls+0x1f8>
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	d16080e7          	jalr	-746(ra) # 80000540 <panic>
    wakeup(&log);
    80004832:	0001d497          	auipc	s1,0x1d
    80004836:	25e48493          	addi	s1,s1,606 # 80021a90 <log>
    8000483a:	8526                	mv	a0,s1
    8000483c:	ffffe097          	auipc	ra,0xffffe
    80004840:	c9e080e7          	jalr	-866(ra) # 800024da <wakeup>
  release(&log.lock);
    80004844:	8526                	mv	a0,s1
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	454080e7          	jalr	1108(ra) # 80000c9a <release>
  if(do_commit){
    8000484e:	b7c9                	j	80004810 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004850:	0001da97          	auipc	s5,0x1d
    80004854:	270a8a93          	addi	s5,s5,624 # 80021ac0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004858:	0001da17          	auipc	s4,0x1d
    8000485c:	238a0a13          	addi	s4,s4,568 # 80021a90 <log>
    80004860:	018a2583          	lw	a1,24(s4)
    80004864:	012585bb          	addw	a1,a1,s2
    80004868:	2585                	addiw	a1,a1,1
    8000486a:	028a2503          	lw	a0,40(s4)
    8000486e:	fffff097          	auipc	ra,0xfffff
    80004872:	cd2080e7          	jalr	-814(ra) # 80003540 <bread>
    80004876:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004878:	000aa583          	lw	a1,0(s5)
    8000487c:	028a2503          	lw	a0,40(s4)
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	cc0080e7          	jalr	-832(ra) # 80003540 <bread>
    80004888:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000488a:	40000613          	li	a2,1024
    8000488e:	05850593          	addi	a1,a0,88
    80004892:	05848513          	addi	a0,s1,88
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	4ac080e7          	jalr	1196(ra) # 80000d42 <memmove>
    bwrite(to);  // write the log
    8000489e:	8526                	mv	a0,s1
    800048a0:	fffff097          	auipc	ra,0xfffff
    800048a4:	d92080e7          	jalr	-622(ra) # 80003632 <bwrite>
    brelse(from);
    800048a8:	854e                	mv	a0,s3
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	dc6080e7          	jalr	-570(ra) # 80003670 <brelse>
    brelse(to);
    800048b2:	8526                	mv	a0,s1
    800048b4:	fffff097          	auipc	ra,0xfffff
    800048b8:	dbc080e7          	jalr	-580(ra) # 80003670 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048bc:	2905                	addiw	s2,s2,1
    800048be:	0a91                	addi	s5,s5,4
    800048c0:	02ca2783          	lw	a5,44(s4)
    800048c4:	f8f94ee3          	blt	s2,a5,80004860 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800048c8:	00000097          	auipc	ra,0x0
    800048cc:	c6a080e7          	jalr	-918(ra) # 80004532 <write_head>
    install_trans(0); // Now install writes to home locations
    800048d0:	4501                	li	a0,0
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	cda080e7          	jalr	-806(ra) # 800045ac <install_trans>
    log.lh.n = 0;
    800048da:	0001d797          	auipc	a5,0x1d
    800048de:	1e07a123          	sw	zero,482(a5) # 80021abc <log+0x2c>
    write_head();    // Erase the transaction from the log
    800048e2:	00000097          	auipc	ra,0x0
    800048e6:	c50080e7          	jalr	-944(ra) # 80004532 <write_head>
    800048ea:	bdf5                	j	800047e6 <end_op+0x52>

00000000800048ec <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800048ec:	1101                	addi	sp,sp,-32
    800048ee:	ec06                	sd	ra,24(sp)
    800048f0:	e822                	sd	s0,16(sp)
    800048f2:	e426                	sd	s1,8(sp)
    800048f4:	e04a                	sd	s2,0(sp)
    800048f6:	1000                	addi	s0,sp,32
    800048f8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800048fa:	0001d917          	auipc	s2,0x1d
    800048fe:	19690913          	addi	s2,s2,406 # 80021a90 <log>
    80004902:	854a                	mv	a0,s2
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	2e2080e7          	jalr	738(ra) # 80000be6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000490c:	02c92603          	lw	a2,44(s2)
    80004910:	47f5                	li	a5,29
    80004912:	06c7c563          	blt	a5,a2,8000497c <log_write+0x90>
    80004916:	0001d797          	auipc	a5,0x1d
    8000491a:	1967a783          	lw	a5,406(a5) # 80021aac <log+0x1c>
    8000491e:	37fd                	addiw	a5,a5,-1
    80004920:	04f65e63          	bge	a2,a5,8000497c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004924:	0001d797          	auipc	a5,0x1d
    80004928:	18c7a783          	lw	a5,396(a5) # 80021ab0 <log+0x20>
    8000492c:	06f05063          	blez	a5,8000498c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004930:	4781                	li	a5,0
    80004932:	06c05563          	blez	a2,8000499c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004936:	44cc                	lw	a1,12(s1)
    80004938:	0001d717          	auipc	a4,0x1d
    8000493c:	18870713          	addi	a4,a4,392 # 80021ac0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004940:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004942:	4314                	lw	a3,0(a4)
    80004944:	04b68c63          	beq	a3,a1,8000499c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004948:	2785                	addiw	a5,a5,1
    8000494a:	0711                	addi	a4,a4,4
    8000494c:	fef61be3          	bne	a2,a5,80004942 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004950:	0621                	addi	a2,a2,8
    80004952:	060a                	slli	a2,a2,0x2
    80004954:	0001d797          	auipc	a5,0x1d
    80004958:	13c78793          	addi	a5,a5,316 # 80021a90 <log>
    8000495c:	963e                	add	a2,a2,a5
    8000495e:	44dc                	lw	a5,12(s1)
    80004960:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004962:	8526                	mv	a0,s1
    80004964:	fffff097          	auipc	ra,0xfffff
    80004968:	daa080e7          	jalr	-598(ra) # 8000370e <bpin>
    log.lh.n++;
    8000496c:	0001d717          	auipc	a4,0x1d
    80004970:	12470713          	addi	a4,a4,292 # 80021a90 <log>
    80004974:	575c                	lw	a5,44(a4)
    80004976:	2785                	addiw	a5,a5,1
    80004978:	d75c                	sw	a5,44(a4)
    8000497a:	a835                	j	800049b6 <log_write+0xca>
    panic("too big a transaction");
    8000497c:	00004517          	auipc	a0,0x4
    80004980:	e2c50513          	addi	a0,a0,-468 # 800087a8 <syscalls+0x208>
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	bbc080e7          	jalr	-1092(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000498c:	00004517          	auipc	a0,0x4
    80004990:	e3450513          	addi	a0,a0,-460 # 800087c0 <syscalls+0x220>
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	bac080e7          	jalr	-1108(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    8000499c:	00878713          	addi	a4,a5,8
    800049a0:	00271693          	slli	a3,a4,0x2
    800049a4:	0001d717          	auipc	a4,0x1d
    800049a8:	0ec70713          	addi	a4,a4,236 # 80021a90 <log>
    800049ac:	9736                	add	a4,a4,a3
    800049ae:	44d4                	lw	a3,12(s1)
    800049b0:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800049b2:	faf608e3          	beq	a2,a5,80004962 <log_write+0x76>
  }
  release(&log.lock);
    800049b6:	0001d517          	auipc	a0,0x1d
    800049ba:	0da50513          	addi	a0,a0,218 # 80021a90 <log>
    800049be:	ffffc097          	auipc	ra,0xffffc
    800049c2:	2dc080e7          	jalr	732(ra) # 80000c9a <release>
}
    800049c6:	60e2                	ld	ra,24(sp)
    800049c8:	6442                	ld	s0,16(sp)
    800049ca:	64a2                	ld	s1,8(sp)
    800049cc:	6902                	ld	s2,0(sp)
    800049ce:	6105                	addi	sp,sp,32
    800049d0:	8082                	ret

00000000800049d2 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800049d2:	1101                	addi	sp,sp,-32
    800049d4:	ec06                	sd	ra,24(sp)
    800049d6:	e822                	sd	s0,16(sp)
    800049d8:	e426                	sd	s1,8(sp)
    800049da:	e04a                	sd	s2,0(sp)
    800049dc:	1000                	addi	s0,sp,32
    800049de:	84aa                	mv	s1,a0
    800049e0:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800049e2:	00004597          	auipc	a1,0x4
    800049e6:	dfe58593          	addi	a1,a1,-514 # 800087e0 <syscalls+0x240>
    800049ea:	0521                	addi	a0,a0,8
    800049ec:	ffffc097          	auipc	ra,0xffffc
    800049f0:	16a080e7          	jalr	362(ra) # 80000b56 <initlock>
  lk->name = name;
    800049f4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800049f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049fc:	0204a423          	sw	zero,40(s1)
}
    80004a00:	60e2                	ld	ra,24(sp)
    80004a02:	6442                	ld	s0,16(sp)
    80004a04:	64a2                	ld	s1,8(sp)
    80004a06:	6902                	ld	s2,0(sp)
    80004a08:	6105                	addi	sp,sp,32
    80004a0a:	8082                	ret

0000000080004a0c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a0c:	1101                	addi	sp,sp,-32
    80004a0e:	ec06                	sd	ra,24(sp)
    80004a10:	e822                	sd	s0,16(sp)
    80004a12:	e426                	sd	s1,8(sp)
    80004a14:	e04a                	sd	s2,0(sp)
    80004a16:	1000                	addi	s0,sp,32
    80004a18:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a1a:	00850913          	addi	s2,a0,8
    80004a1e:	854a                	mv	a0,s2
    80004a20:	ffffc097          	auipc	ra,0xffffc
    80004a24:	1c6080e7          	jalr	454(ra) # 80000be6 <acquire>
  while (lk->locked) {
    80004a28:	409c                	lw	a5,0(s1)
    80004a2a:	cb89                	beqz	a5,80004a3c <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a2c:	85ca                	mv	a1,s2
    80004a2e:	8526                	mv	a0,s1
    80004a30:	ffffe097          	auipc	ra,0xffffe
    80004a34:	8c4080e7          	jalr	-1852(ra) # 800022f4 <sleep>
  while (lk->locked) {
    80004a38:	409c                	lw	a5,0(s1)
    80004a3a:	fbed                	bnez	a5,80004a2c <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a3c:	4785                	li	a5,1
    80004a3e:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a40:	ffffd097          	auipc	ra,0xffffd
    80004a44:	fc2080e7          	jalr	-62(ra) # 80001a02 <myproc>
    80004a48:	591c                	lw	a5,48(a0)
    80004a4a:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a4c:	854a                	mv	a0,s2
    80004a4e:	ffffc097          	auipc	ra,0xffffc
    80004a52:	24c080e7          	jalr	588(ra) # 80000c9a <release>
}
    80004a56:	60e2                	ld	ra,24(sp)
    80004a58:	6442                	ld	s0,16(sp)
    80004a5a:	64a2                	ld	s1,8(sp)
    80004a5c:	6902                	ld	s2,0(sp)
    80004a5e:	6105                	addi	sp,sp,32
    80004a60:	8082                	ret

0000000080004a62 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a62:	1101                	addi	sp,sp,-32
    80004a64:	ec06                	sd	ra,24(sp)
    80004a66:	e822                	sd	s0,16(sp)
    80004a68:	e426                	sd	s1,8(sp)
    80004a6a:	e04a                	sd	s2,0(sp)
    80004a6c:	1000                	addi	s0,sp,32
    80004a6e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a70:	00850913          	addi	s2,a0,8
    80004a74:	854a                	mv	a0,s2
    80004a76:	ffffc097          	auipc	ra,0xffffc
    80004a7a:	170080e7          	jalr	368(ra) # 80000be6 <acquire>
  lk->locked = 0;
    80004a7e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a82:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004a86:	8526                	mv	a0,s1
    80004a88:	ffffe097          	auipc	ra,0xffffe
    80004a8c:	a52080e7          	jalr	-1454(ra) # 800024da <wakeup>
  release(&lk->lk);
    80004a90:	854a                	mv	a0,s2
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	208080e7          	jalr	520(ra) # 80000c9a <release>
}
    80004a9a:	60e2                	ld	ra,24(sp)
    80004a9c:	6442                	ld	s0,16(sp)
    80004a9e:	64a2                	ld	s1,8(sp)
    80004aa0:	6902                	ld	s2,0(sp)
    80004aa2:	6105                	addi	sp,sp,32
    80004aa4:	8082                	ret

0000000080004aa6 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004aa6:	7179                	addi	sp,sp,-48
    80004aa8:	f406                	sd	ra,40(sp)
    80004aaa:	f022                	sd	s0,32(sp)
    80004aac:	ec26                	sd	s1,24(sp)
    80004aae:	e84a                	sd	s2,16(sp)
    80004ab0:	e44e                	sd	s3,8(sp)
    80004ab2:	1800                	addi	s0,sp,48
    80004ab4:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004ab6:	00850913          	addi	s2,a0,8
    80004aba:	854a                	mv	a0,s2
    80004abc:	ffffc097          	auipc	ra,0xffffc
    80004ac0:	12a080e7          	jalr	298(ra) # 80000be6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ac4:	409c                	lw	a5,0(s1)
    80004ac6:	ef99                	bnez	a5,80004ae4 <holdingsleep+0x3e>
    80004ac8:	4481                	li	s1,0
  release(&lk->lk);
    80004aca:	854a                	mv	a0,s2
    80004acc:	ffffc097          	auipc	ra,0xffffc
    80004ad0:	1ce080e7          	jalr	462(ra) # 80000c9a <release>
  return r;
}
    80004ad4:	8526                	mv	a0,s1
    80004ad6:	70a2                	ld	ra,40(sp)
    80004ad8:	7402                	ld	s0,32(sp)
    80004ada:	64e2                	ld	s1,24(sp)
    80004adc:	6942                	ld	s2,16(sp)
    80004ade:	69a2                	ld	s3,8(sp)
    80004ae0:	6145                	addi	sp,sp,48
    80004ae2:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004ae4:	0284a983          	lw	s3,40(s1)
    80004ae8:	ffffd097          	auipc	ra,0xffffd
    80004aec:	f1a080e7          	jalr	-230(ra) # 80001a02 <myproc>
    80004af0:	5904                	lw	s1,48(a0)
    80004af2:	413484b3          	sub	s1,s1,s3
    80004af6:	0014b493          	seqz	s1,s1
    80004afa:	bfc1                	j	80004aca <holdingsleep+0x24>

0000000080004afc <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004afc:	1141                	addi	sp,sp,-16
    80004afe:	e406                	sd	ra,8(sp)
    80004b00:	e022                	sd	s0,0(sp)
    80004b02:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b04:	00004597          	auipc	a1,0x4
    80004b08:	cec58593          	addi	a1,a1,-788 # 800087f0 <syscalls+0x250>
    80004b0c:	0001d517          	auipc	a0,0x1d
    80004b10:	0cc50513          	addi	a0,a0,204 # 80021bd8 <ftable>
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	042080e7          	jalr	66(ra) # 80000b56 <initlock>
}
    80004b1c:	60a2                	ld	ra,8(sp)
    80004b1e:	6402                	ld	s0,0(sp)
    80004b20:	0141                	addi	sp,sp,16
    80004b22:	8082                	ret

0000000080004b24 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b24:	1101                	addi	sp,sp,-32
    80004b26:	ec06                	sd	ra,24(sp)
    80004b28:	e822                	sd	s0,16(sp)
    80004b2a:	e426                	sd	s1,8(sp)
    80004b2c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b2e:	0001d517          	auipc	a0,0x1d
    80004b32:	0aa50513          	addi	a0,a0,170 # 80021bd8 <ftable>
    80004b36:	ffffc097          	auipc	ra,0xffffc
    80004b3a:	0b0080e7          	jalr	176(ra) # 80000be6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b3e:	0001d497          	auipc	s1,0x1d
    80004b42:	0b248493          	addi	s1,s1,178 # 80021bf0 <ftable+0x18>
    80004b46:	0001e717          	auipc	a4,0x1e
    80004b4a:	04a70713          	addi	a4,a4,74 # 80022b90 <ftable+0xfb8>
    if(f->ref == 0){
    80004b4e:	40dc                	lw	a5,4(s1)
    80004b50:	cf99                	beqz	a5,80004b6e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b52:	02848493          	addi	s1,s1,40
    80004b56:	fee49ce3          	bne	s1,a4,80004b4e <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b5a:	0001d517          	auipc	a0,0x1d
    80004b5e:	07e50513          	addi	a0,a0,126 # 80021bd8 <ftable>
    80004b62:	ffffc097          	auipc	ra,0xffffc
    80004b66:	138080e7          	jalr	312(ra) # 80000c9a <release>
  return 0;
    80004b6a:	4481                	li	s1,0
    80004b6c:	a819                	j	80004b82 <filealloc+0x5e>
      f->ref = 1;
    80004b6e:	4785                	li	a5,1
    80004b70:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004b72:	0001d517          	auipc	a0,0x1d
    80004b76:	06650513          	addi	a0,a0,102 # 80021bd8 <ftable>
    80004b7a:	ffffc097          	auipc	ra,0xffffc
    80004b7e:	120080e7          	jalr	288(ra) # 80000c9a <release>
}
    80004b82:	8526                	mv	a0,s1
    80004b84:	60e2                	ld	ra,24(sp)
    80004b86:	6442                	ld	s0,16(sp)
    80004b88:	64a2                	ld	s1,8(sp)
    80004b8a:	6105                	addi	sp,sp,32
    80004b8c:	8082                	ret

0000000080004b8e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b8e:	1101                	addi	sp,sp,-32
    80004b90:	ec06                	sd	ra,24(sp)
    80004b92:	e822                	sd	s0,16(sp)
    80004b94:	e426                	sd	s1,8(sp)
    80004b96:	1000                	addi	s0,sp,32
    80004b98:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b9a:	0001d517          	auipc	a0,0x1d
    80004b9e:	03e50513          	addi	a0,a0,62 # 80021bd8 <ftable>
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	044080e7          	jalr	68(ra) # 80000be6 <acquire>
  if(f->ref < 1)
    80004baa:	40dc                	lw	a5,4(s1)
    80004bac:	02f05263          	blez	a5,80004bd0 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004bb0:	2785                	addiw	a5,a5,1
    80004bb2:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004bb4:	0001d517          	auipc	a0,0x1d
    80004bb8:	02450513          	addi	a0,a0,36 # 80021bd8 <ftable>
    80004bbc:	ffffc097          	auipc	ra,0xffffc
    80004bc0:	0de080e7          	jalr	222(ra) # 80000c9a <release>
  return f;
}
    80004bc4:	8526                	mv	a0,s1
    80004bc6:	60e2                	ld	ra,24(sp)
    80004bc8:	6442                	ld	s0,16(sp)
    80004bca:	64a2                	ld	s1,8(sp)
    80004bcc:	6105                	addi	sp,sp,32
    80004bce:	8082                	ret
    panic("filedup");
    80004bd0:	00004517          	auipc	a0,0x4
    80004bd4:	c2850513          	addi	a0,a0,-984 # 800087f8 <syscalls+0x258>
    80004bd8:	ffffc097          	auipc	ra,0xffffc
    80004bdc:	968080e7          	jalr	-1688(ra) # 80000540 <panic>

0000000080004be0 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004be0:	7139                	addi	sp,sp,-64
    80004be2:	fc06                	sd	ra,56(sp)
    80004be4:	f822                	sd	s0,48(sp)
    80004be6:	f426                	sd	s1,40(sp)
    80004be8:	f04a                	sd	s2,32(sp)
    80004bea:	ec4e                	sd	s3,24(sp)
    80004bec:	e852                	sd	s4,16(sp)
    80004bee:	e456                	sd	s5,8(sp)
    80004bf0:	0080                	addi	s0,sp,64
    80004bf2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004bf4:	0001d517          	auipc	a0,0x1d
    80004bf8:	fe450513          	addi	a0,a0,-28 # 80021bd8 <ftable>
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	fea080e7          	jalr	-22(ra) # 80000be6 <acquire>
  if(f->ref < 1)
    80004c04:	40dc                	lw	a5,4(s1)
    80004c06:	06f05163          	blez	a5,80004c68 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c0a:	37fd                	addiw	a5,a5,-1
    80004c0c:	0007871b          	sext.w	a4,a5
    80004c10:	c0dc                	sw	a5,4(s1)
    80004c12:	06e04363          	bgtz	a4,80004c78 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c16:	0004a903          	lw	s2,0(s1)
    80004c1a:	0094ca83          	lbu	s5,9(s1)
    80004c1e:	0104ba03          	ld	s4,16(s1)
    80004c22:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c26:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c2a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c2e:	0001d517          	auipc	a0,0x1d
    80004c32:	faa50513          	addi	a0,a0,-86 # 80021bd8 <ftable>
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	064080e7          	jalr	100(ra) # 80000c9a <release>

  if(ff.type == FD_PIPE){
    80004c3e:	4785                	li	a5,1
    80004c40:	04f90d63          	beq	s2,a5,80004c9a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c44:	3979                	addiw	s2,s2,-2
    80004c46:	4785                	li	a5,1
    80004c48:	0527e063          	bltu	a5,s2,80004c88 <fileclose+0xa8>
    begin_op();
    80004c4c:	00000097          	auipc	ra,0x0
    80004c50:	ac8080e7          	jalr	-1336(ra) # 80004714 <begin_op>
    iput(ff.ip);
    80004c54:	854e                	mv	a0,s3
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	2a6080e7          	jalr	678(ra) # 80003efc <iput>
    end_op();
    80004c5e:	00000097          	auipc	ra,0x0
    80004c62:	b36080e7          	jalr	-1226(ra) # 80004794 <end_op>
    80004c66:	a00d                	j	80004c88 <fileclose+0xa8>
    panic("fileclose");
    80004c68:	00004517          	auipc	a0,0x4
    80004c6c:	b9850513          	addi	a0,a0,-1128 # 80008800 <syscalls+0x260>
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	8d0080e7          	jalr	-1840(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004c78:	0001d517          	auipc	a0,0x1d
    80004c7c:	f6050513          	addi	a0,a0,-160 # 80021bd8 <ftable>
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	01a080e7          	jalr	26(ra) # 80000c9a <release>
  }
}
    80004c88:	70e2                	ld	ra,56(sp)
    80004c8a:	7442                	ld	s0,48(sp)
    80004c8c:	74a2                	ld	s1,40(sp)
    80004c8e:	7902                	ld	s2,32(sp)
    80004c90:	69e2                	ld	s3,24(sp)
    80004c92:	6a42                	ld	s4,16(sp)
    80004c94:	6aa2                	ld	s5,8(sp)
    80004c96:	6121                	addi	sp,sp,64
    80004c98:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c9a:	85d6                	mv	a1,s5
    80004c9c:	8552                	mv	a0,s4
    80004c9e:	00000097          	auipc	ra,0x0
    80004ca2:	34c080e7          	jalr	844(ra) # 80004fea <pipeclose>
    80004ca6:	b7cd                	j	80004c88 <fileclose+0xa8>

0000000080004ca8 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ca8:	715d                	addi	sp,sp,-80
    80004caa:	e486                	sd	ra,72(sp)
    80004cac:	e0a2                	sd	s0,64(sp)
    80004cae:	fc26                	sd	s1,56(sp)
    80004cb0:	f84a                	sd	s2,48(sp)
    80004cb2:	f44e                	sd	s3,40(sp)
    80004cb4:	0880                	addi	s0,sp,80
    80004cb6:	84aa                	mv	s1,a0
    80004cb8:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004cba:	ffffd097          	auipc	ra,0xffffd
    80004cbe:	d48080e7          	jalr	-696(ra) # 80001a02 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004cc2:	409c                	lw	a5,0(s1)
    80004cc4:	37f9                	addiw	a5,a5,-2
    80004cc6:	4705                	li	a4,1
    80004cc8:	04f76763          	bltu	a4,a5,80004d16 <filestat+0x6e>
    80004ccc:	892a                	mv	s2,a0
    ilock(f->ip);
    80004cce:	6c88                	ld	a0,24(s1)
    80004cd0:	fffff097          	auipc	ra,0xfffff
    80004cd4:	072080e7          	jalr	114(ra) # 80003d42 <ilock>
    stati(f->ip, &st);
    80004cd8:	fb840593          	addi	a1,s0,-72
    80004cdc:	6c88                	ld	a0,24(s1)
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	2ee080e7          	jalr	750(ra) # 80003fcc <stati>
    iunlock(f->ip);
    80004ce6:	6c88                	ld	a0,24(s1)
    80004ce8:	fffff097          	auipc	ra,0xfffff
    80004cec:	11c080e7          	jalr	284(ra) # 80003e04 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004cf0:	46e1                	li	a3,24
    80004cf2:	fb840613          	addi	a2,s0,-72
    80004cf6:	85ce                	mv	a1,s3
    80004cf8:	05093503          	ld	a0,80(s2)
    80004cfc:	ffffd097          	auipc	ra,0xffffd
    80004d00:	978080e7          	jalr	-1672(ra) # 80001674 <copyout>
    80004d04:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d08:	60a6                	ld	ra,72(sp)
    80004d0a:	6406                	ld	s0,64(sp)
    80004d0c:	74e2                	ld	s1,56(sp)
    80004d0e:	7942                	ld	s2,48(sp)
    80004d10:	79a2                	ld	s3,40(sp)
    80004d12:	6161                	addi	sp,sp,80
    80004d14:	8082                	ret
  return -1;
    80004d16:	557d                	li	a0,-1
    80004d18:	bfc5                	j	80004d08 <filestat+0x60>

0000000080004d1a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d1a:	7179                	addi	sp,sp,-48
    80004d1c:	f406                	sd	ra,40(sp)
    80004d1e:	f022                	sd	s0,32(sp)
    80004d20:	ec26                	sd	s1,24(sp)
    80004d22:	e84a                	sd	s2,16(sp)
    80004d24:	e44e                	sd	s3,8(sp)
    80004d26:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d28:	00854783          	lbu	a5,8(a0)
    80004d2c:	c3d5                	beqz	a5,80004dd0 <fileread+0xb6>
    80004d2e:	84aa                	mv	s1,a0
    80004d30:	89ae                	mv	s3,a1
    80004d32:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d34:	411c                	lw	a5,0(a0)
    80004d36:	4705                	li	a4,1
    80004d38:	04e78963          	beq	a5,a4,80004d8a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d3c:	470d                	li	a4,3
    80004d3e:	04e78d63          	beq	a5,a4,80004d98 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d42:	4709                	li	a4,2
    80004d44:	06e79e63          	bne	a5,a4,80004dc0 <fileread+0xa6>
    ilock(f->ip);
    80004d48:	6d08                	ld	a0,24(a0)
    80004d4a:	fffff097          	auipc	ra,0xfffff
    80004d4e:	ff8080e7          	jalr	-8(ra) # 80003d42 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d52:	874a                	mv	a4,s2
    80004d54:	5094                	lw	a3,32(s1)
    80004d56:	864e                	mv	a2,s3
    80004d58:	4585                	li	a1,1
    80004d5a:	6c88                	ld	a0,24(s1)
    80004d5c:	fffff097          	auipc	ra,0xfffff
    80004d60:	29a080e7          	jalr	666(ra) # 80003ff6 <readi>
    80004d64:	892a                	mv	s2,a0
    80004d66:	00a05563          	blez	a0,80004d70 <fileread+0x56>
      f->off += r;
    80004d6a:	509c                	lw	a5,32(s1)
    80004d6c:	9fa9                	addw	a5,a5,a0
    80004d6e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004d70:	6c88                	ld	a0,24(s1)
    80004d72:	fffff097          	auipc	ra,0xfffff
    80004d76:	092080e7          	jalr	146(ra) # 80003e04 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004d7a:	854a                	mv	a0,s2
    80004d7c:	70a2                	ld	ra,40(sp)
    80004d7e:	7402                	ld	s0,32(sp)
    80004d80:	64e2                	ld	s1,24(sp)
    80004d82:	6942                	ld	s2,16(sp)
    80004d84:	69a2                	ld	s3,8(sp)
    80004d86:	6145                	addi	sp,sp,48
    80004d88:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d8a:	6908                	ld	a0,16(a0)
    80004d8c:	00000097          	auipc	ra,0x0
    80004d90:	3ca080e7          	jalr	970(ra) # 80005156 <piperead>
    80004d94:	892a                	mv	s2,a0
    80004d96:	b7d5                	j	80004d7a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d98:	02451783          	lh	a5,36(a0)
    80004d9c:	03079693          	slli	a3,a5,0x30
    80004da0:	92c1                	srli	a3,a3,0x30
    80004da2:	4725                	li	a4,9
    80004da4:	02d76863          	bltu	a4,a3,80004dd4 <fileread+0xba>
    80004da8:	0792                	slli	a5,a5,0x4
    80004daa:	0001d717          	auipc	a4,0x1d
    80004dae:	d8e70713          	addi	a4,a4,-626 # 80021b38 <devsw>
    80004db2:	97ba                	add	a5,a5,a4
    80004db4:	639c                	ld	a5,0(a5)
    80004db6:	c38d                	beqz	a5,80004dd8 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004db8:	4505                	li	a0,1
    80004dba:	9782                	jalr	a5
    80004dbc:	892a                	mv	s2,a0
    80004dbe:	bf75                	j	80004d7a <fileread+0x60>
    panic("fileread");
    80004dc0:	00004517          	auipc	a0,0x4
    80004dc4:	a5050513          	addi	a0,a0,-1456 # 80008810 <syscalls+0x270>
    80004dc8:	ffffb097          	auipc	ra,0xffffb
    80004dcc:	778080e7          	jalr	1912(ra) # 80000540 <panic>
    return -1;
    80004dd0:	597d                	li	s2,-1
    80004dd2:	b765                	j	80004d7a <fileread+0x60>
      return -1;
    80004dd4:	597d                	li	s2,-1
    80004dd6:	b755                	j	80004d7a <fileread+0x60>
    80004dd8:	597d                	li	s2,-1
    80004dda:	b745                	j	80004d7a <fileread+0x60>

0000000080004ddc <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004ddc:	715d                	addi	sp,sp,-80
    80004dde:	e486                	sd	ra,72(sp)
    80004de0:	e0a2                	sd	s0,64(sp)
    80004de2:	fc26                	sd	s1,56(sp)
    80004de4:	f84a                	sd	s2,48(sp)
    80004de6:	f44e                	sd	s3,40(sp)
    80004de8:	f052                	sd	s4,32(sp)
    80004dea:	ec56                	sd	s5,24(sp)
    80004dec:	e85a                	sd	s6,16(sp)
    80004dee:	e45e                	sd	s7,8(sp)
    80004df0:	e062                	sd	s8,0(sp)
    80004df2:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004df4:	00954783          	lbu	a5,9(a0)
    80004df8:	10078663          	beqz	a5,80004f04 <filewrite+0x128>
    80004dfc:	892a                	mv	s2,a0
    80004dfe:	8aae                	mv	s5,a1
    80004e00:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e02:	411c                	lw	a5,0(a0)
    80004e04:	4705                	li	a4,1
    80004e06:	02e78263          	beq	a5,a4,80004e2a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e0a:	470d                	li	a4,3
    80004e0c:	02e78663          	beq	a5,a4,80004e38 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e10:	4709                	li	a4,2
    80004e12:	0ee79163          	bne	a5,a4,80004ef4 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e16:	0ac05d63          	blez	a2,80004ed0 <filewrite+0xf4>
    int i = 0;
    80004e1a:	4981                	li	s3,0
    80004e1c:	6b05                	lui	s6,0x1
    80004e1e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004e22:	6b85                	lui	s7,0x1
    80004e24:	c00b8b9b          	addiw	s7,s7,-1024
    80004e28:	a861                	j	80004ec0 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e2a:	6908                	ld	a0,16(a0)
    80004e2c:	00000097          	auipc	ra,0x0
    80004e30:	22e080e7          	jalr	558(ra) # 8000505a <pipewrite>
    80004e34:	8a2a                	mv	s4,a0
    80004e36:	a045                	j	80004ed6 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e38:	02451783          	lh	a5,36(a0)
    80004e3c:	03079693          	slli	a3,a5,0x30
    80004e40:	92c1                	srli	a3,a3,0x30
    80004e42:	4725                	li	a4,9
    80004e44:	0cd76263          	bltu	a4,a3,80004f08 <filewrite+0x12c>
    80004e48:	0792                	slli	a5,a5,0x4
    80004e4a:	0001d717          	auipc	a4,0x1d
    80004e4e:	cee70713          	addi	a4,a4,-786 # 80021b38 <devsw>
    80004e52:	97ba                	add	a5,a5,a4
    80004e54:	679c                	ld	a5,8(a5)
    80004e56:	cbdd                	beqz	a5,80004f0c <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004e58:	4505                	li	a0,1
    80004e5a:	9782                	jalr	a5
    80004e5c:	8a2a                	mv	s4,a0
    80004e5e:	a8a5                	j	80004ed6 <filewrite+0xfa>
    80004e60:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004e64:	00000097          	auipc	ra,0x0
    80004e68:	8b0080e7          	jalr	-1872(ra) # 80004714 <begin_op>
      ilock(f->ip);
    80004e6c:	01893503          	ld	a0,24(s2)
    80004e70:	fffff097          	auipc	ra,0xfffff
    80004e74:	ed2080e7          	jalr	-302(ra) # 80003d42 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004e78:	8762                	mv	a4,s8
    80004e7a:	02092683          	lw	a3,32(s2)
    80004e7e:	01598633          	add	a2,s3,s5
    80004e82:	4585                	li	a1,1
    80004e84:	01893503          	ld	a0,24(s2)
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	266080e7          	jalr	614(ra) # 800040ee <writei>
    80004e90:	84aa                	mv	s1,a0
    80004e92:	00a05763          	blez	a0,80004ea0 <filewrite+0xc4>
        f->off += r;
    80004e96:	02092783          	lw	a5,32(s2)
    80004e9a:	9fa9                	addw	a5,a5,a0
    80004e9c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ea0:	01893503          	ld	a0,24(s2)
    80004ea4:	fffff097          	auipc	ra,0xfffff
    80004ea8:	f60080e7          	jalr	-160(ra) # 80003e04 <iunlock>
      end_op();
    80004eac:	00000097          	auipc	ra,0x0
    80004eb0:	8e8080e7          	jalr	-1816(ra) # 80004794 <end_op>

      if(r != n1){
    80004eb4:	009c1f63          	bne	s8,s1,80004ed2 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004eb8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ebc:	0149db63          	bge	s3,s4,80004ed2 <filewrite+0xf6>
      int n1 = n - i;
    80004ec0:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ec4:	84be                	mv	s1,a5
    80004ec6:	2781                	sext.w	a5,a5
    80004ec8:	f8fb5ce3          	bge	s6,a5,80004e60 <filewrite+0x84>
    80004ecc:	84de                	mv	s1,s7
    80004ece:	bf49                	j	80004e60 <filewrite+0x84>
    int i = 0;
    80004ed0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ed2:	013a1f63          	bne	s4,s3,80004ef0 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ed6:	8552                	mv	a0,s4
    80004ed8:	60a6                	ld	ra,72(sp)
    80004eda:	6406                	ld	s0,64(sp)
    80004edc:	74e2                	ld	s1,56(sp)
    80004ede:	7942                	ld	s2,48(sp)
    80004ee0:	79a2                	ld	s3,40(sp)
    80004ee2:	7a02                	ld	s4,32(sp)
    80004ee4:	6ae2                	ld	s5,24(sp)
    80004ee6:	6b42                	ld	s6,16(sp)
    80004ee8:	6ba2                	ld	s7,8(sp)
    80004eea:	6c02                	ld	s8,0(sp)
    80004eec:	6161                	addi	sp,sp,80
    80004eee:	8082                	ret
    ret = (i == n ? n : -1);
    80004ef0:	5a7d                	li	s4,-1
    80004ef2:	b7d5                	j	80004ed6 <filewrite+0xfa>
    panic("filewrite");
    80004ef4:	00004517          	auipc	a0,0x4
    80004ef8:	92c50513          	addi	a0,a0,-1748 # 80008820 <syscalls+0x280>
    80004efc:	ffffb097          	auipc	ra,0xffffb
    80004f00:	644080e7          	jalr	1604(ra) # 80000540 <panic>
    return -1;
    80004f04:	5a7d                	li	s4,-1
    80004f06:	bfc1                	j	80004ed6 <filewrite+0xfa>
      return -1;
    80004f08:	5a7d                	li	s4,-1
    80004f0a:	b7f1                	j	80004ed6 <filewrite+0xfa>
    80004f0c:	5a7d                	li	s4,-1
    80004f0e:	b7e1                	j	80004ed6 <filewrite+0xfa>

0000000080004f10 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f10:	7179                	addi	sp,sp,-48
    80004f12:	f406                	sd	ra,40(sp)
    80004f14:	f022                	sd	s0,32(sp)
    80004f16:	ec26                	sd	s1,24(sp)
    80004f18:	e84a                	sd	s2,16(sp)
    80004f1a:	e44e                	sd	s3,8(sp)
    80004f1c:	e052                	sd	s4,0(sp)
    80004f1e:	1800                	addi	s0,sp,48
    80004f20:	84aa                	mv	s1,a0
    80004f22:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f24:	0005b023          	sd	zero,0(a1)
    80004f28:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f2c:	00000097          	auipc	ra,0x0
    80004f30:	bf8080e7          	jalr	-1032(ra) # 80004b24 <filealloc>
    80004f34:	e088                	sd	a0,0(s1)
    80004f36:	c551                	beqz	a0,80004fc2 <pipealloc+0xb2>
    80004f38:	00000097          	auipc	ra,0x0
    80004f3c:	bec080e7          	jalr	-1044(ra) # 80004b24 <filealloc>
    80004f40:	00aa3023          	sd	a0,0(s4)
    80004f44:	c92d                	beqz	a0,80004fb6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	bb0080e7          	jalr	-1104(ra) # 80000af6 <kalloc>
    80004f4e:	892a                	mv	s2,a0
    80004f50:	c125                	beqz	a0,80004fb0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f52:	4985                	li	s3,1
    80004f54:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f58:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f5c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f60:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f64:	00004597          	auipc	a1,0x4
    80004f68:	8cc58593          	addi	a1,a1,-1844 # 80008830 <syscalls+0x290>
    80004f6c:	ffffc097          	auipc	ra,0xffffc
    80004f70:	bea080e7          	jalr	-1046(ra) # 80000b56 <initlock>
  (*f0)->type = FD_PIPE;
    80004f74:	609c                	ld	a5,0(s1)
    80004f76:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004f7a:	609c                	ld	a5,0(s1)
    80004f7c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004f80:	609c                	ld	a5,0(s1)
    80004f82:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004f86:	609c                	ld	a5,0(s1)
    80004f88:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f8c:	000a3783          	ld	a5,0(s4)
    80004f90:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f94:	000a3783          	ld	a5,0(s4)
    80004f98:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f9c:	000a3783          	ld	a5,0(s4)
    80004fa0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004fa4:	000a3783          	ld	a5,0(s4)
    80004fa8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004fac:	4501                	li	a0,0
    80004fae:	a025                	j	80004fd6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004fb0:	6088                	ld	a0,0(s1)
    80004fb2:	e501                	bnez	a0,80004fba <pipealloc+0xaa>
    80004fb4:	a039                	j	80004fc2 <pipealloc+0xb2>
    80004fb6:	6088                	ld	a0,0(s1)
    80004fb8:	c51d                	beqz	a0,80004fe6 <pipealloc+0xd6>
    fileclose(*f0);
    80004fba:	00000097          	auipc	ra,0x0
    80004fbe:	c26080e7          	jalr	-986(ra) # 80004be0 <fileclose>
  if(*f1)
    80004fc2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004fc6:	557d                	li	a0,-1
  if(*f1)
    80004fc8:	c799                	beqz	a5,80004fd6 <pipealloc+0xc6>
    fileclose(*f1);
    80004fca:	853e                	mv	a0,a5
    80004fcc:	00000097          	auipc	ra,0x0
    80004fd0:	c14080e7          	jalr	-1004(ra) # 80004be0 <fileclose>
  return -1;
    80004fd4:	557d                	li	a0,-1
}
    80004fd6:	70a2                	ld	ra,40(sp)
    80004fd8:	7402                	ld	s0,32(sp)
    80004fda:	64e2                	ld	s1,24(sp)
    80004fdc:	6942                	ld	s2,16(sp)
    80004fde:	69a2                	ld	s3,8(sp)
    80004fe0:	6a02                	ld	s4,0(sp)
    80004fe2:	6145                	addi	sp,sp,48
    80004fe4:	8082                	ret
  return -1;
    80004fe6:	557d                	li	a0,-1
    80004fe8:	b7fd                	j	80004fd6 <pipealloc+0xc6>

0000000080004fea <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004fea:	1101                	addi	sp,sp,-32
    80004fec:	ec06                	sd	ra,24(sp)
    80004fee:	e822                	sd	s0,16(sp)
    80004ff0:	e426                	sd	s1,8(sp)
    80004ff2:	e04a                	sd	s2,0(sp)
    80004ff4:	1000                	addi	s0,sp,32
    80004ff6:	84aa                	mv	s1,a0
    80004ff8:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	bec080e7          	jalr	-1044(ra) # 80000be6 <acquire>
  if(writable){
    80005002:	02090d63          	beqz	s2,8000503c <pipeclose+0x52>
    pi->writeopen = 0;
    80005006:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000500a:	21848513          	addi	a0,s1,536
    8000500e:	ffffd097          	auipc	ra,0xffffd
    80005012:	4cc080e7          	jalr	1228(ra) # 800024da <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005016:	2204b783          	ld	a5,544(s1)
    8000501a:	eb95                	bnez	a5,8000504e <pipeclose+0x64>
    release(&pi->lock);
    8000501c:	8526                	mv	a0,s1
    8000501e:	ffffc097          	auipc	ra,0xffffc
    80005022:	c7c080e7          	jalr	-900(ra) # 80000c9a <release>
    kfree((char*)pi);
    80005026:	8526                	mv	a0,s1
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	9d2080e7          	jalr	-1582(ra) # 800009fa <kfree>
  } else
    release(&pi->lock);
}
    80005030:	60e2                	ld	ra,24(sp)
    80005032:	6442                	ld	s0,16(sp)
    80005034:	64a2                	ld	s1,8(sp)
    80005036:	6902                	ld	s2,0(sp)
    80005038:	6105                	addi	sp,sp,32
    8000503a:	8082                	ret
    pi->readopen = 0;
    8000503c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005040:	21c48513          	addi	a0,s1,540
    80005044:	ffffd097          	auipc	ra,0xffffd
    80005048:	496080e7          	jalr	1174(ra) # 800024da <wakeup>
    8000504c:	b7e9                	j	80005016 <pipeclose+0x2c>
    release(&pi->lock);
    8000504e:	8526                	mv	a0,s1
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	c4a080e7          	jalr	-950(ra) # 80000c9a <release>
}
    80005058:	bfe1                	j	80005030 <pipeclose+0x46>

000000008000505a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000505a:	7159                	addi	sp,sp,-112
    8000505c:	f486                	sd	ra,104(sp)
    8000505e:	f0a2                	sd	s0,96(sp)
    80005060:	eca6                	sd	s1,88(sp)
    80005062:	e8ca                	sd	s2,80(sp)
    80005064:	e4ce                	sd	s3,72(sp)
    80005066:	e0d2                	sd	s4,64(sp)
    80005068:	fc56                	sd	s5,56(sp)
    8000506a:	f85a                	sd	s6,48(sp)
    8000506c:	f45e                	sd	s7,40(sp)
    8000506e:	f062                	sd	s8,32(sp)
    80005070:	ec66                	sd	s9,24(sp)
    80005072:	1880                	addi	s0,sp,112
    80005074:	84aa                	mv	s1,a0
    80005076:	8aae                	mv	s5,a1
    80005078:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000507a:	ffffd097          	auipc	ra,0xffffd
    8000507e:	988080e7          	jalr	-1656(ra) # 80001a02 <myproc>
    80005082:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005084:	8526                	mv	a0,s1
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	b60080e7          	jalr	-1184(ra) # 80000be6 <acquire>
  while(i < n){
    8000508e:	0d405263          	blez	s4,80005152 <pipewrite+0xf8>
    80005092:	8ba6                	mv	s7,s1
  int i = 0;
    80005094:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005096:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005098:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000509c:	21c48c13          	addi	s8,s1,540
    800050a0:	a08d                	j	80005102 <pipewrite+0xa8>
      release(&pi->lock);
    800050a2:	8526                	mv	a0,s1
    800050a4:	ffffc097          	auipc	ra,0xffffc
    800050a8:	bf6080e7          	jalr	-1034(ra) # 80000c9a <release>
      return -1;
    800050ac:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800050ae:	854a                	mv	a0,s2
    800050b0:	70a6                	ld	ra,104(sp)
    800050b2:	7406                	ld	s0,96(sp)
    800050b4:	64e6                	ld	s1,88(sp)
    800050b6:	6946                	ld	s2,80(sp)
    800050b8:	69a6                	ld	s3,72(sp)
    800050ba:	6a06                	ld	s4,64(sp)
    800050bc:	7ae2                	ld	s5,56(sp)
    800050be:	7b42                	ld	s6,48(sp)
    800050c0:	7ba2                	ld	s7,40(sp)
    800050c2:	7c02                	ld	s8,32(sp)
    800050c4:	6ce2                	ld	s9,24(sp)
    800050c6:	6165                	addi	sp,sp,112
    800050c8:	8082                	ret
      wakeup(&pi->nread);
    800050ca:	8566                	mv	a0,s9
    800050cc:	ffffd097          	auipc	ra,0xffffd
    800050d0:	40e080e7          	jalr	1038(ra) # 800024da <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800050d4:	85de                	mv	a1,s7
    800050d6:	8562                	mv	a0,s8
    800050d8:	ffffd097          	auipc	ra,0xffffd
    800050dc:	21c080e7          	jalr	540(ra) # 800022f4 <sleep>
    800050e0:	a839                	j	800050fe <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800050e2:	21c4a783          	lw	a5,540(s1)
    800050e6:	0017871b          	addiw	a4,a5,1
    800050ea:	20e4ae23          	sw	a4,540(s1)
    800050ee:	1ff7f793          	andi	a5,a5,511
    800050f2:	97a6                	add	a5,a5,s1
    800050f4:	f9f44703          	lbu	a4,-97(s0)
    800050f8:	00e78c23          	sb	a4,24(a5)
      i++;
    800050fc:	2905                	addiw	s2,s2,1
  while(i < n){
    800050fe:	03495e63          	bge	s2,s4,8000513a <pipewrite+0xe0>
    if(pi->readopen == 0 || pr->killed){
    80005102:	2204a783          	lw	a5,544(s1)
    80005106:	dfd1                	beqz	a5,800050a2 <pipewrite+0x48>
    80005108:	0289a783          	lw	a5,40(s3)
    8000510c:	2781                	sext.w	a5,a5
    8000510e:	fbd1                	bnez	a5,800050a2 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005110:	2184a783          	lw	a5,536(s1)
    80005114:	21c4a703          	lw	a4,540(s1)
    80005118:	2007879b          	addiw	a5,a5,512
    8000511c:	faf707e3          	beq	a4,a5,800050ca <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005120:	4685                	li	a3,1
    80005122:	01590633          	add	a2,s2,s5
    80005126:	f9f40593          	addi	a1,s0,-97
    8000512a:	0509b503          	ld	a0,80(s3)
    8000512e:	ffffc097          	auipc	ra,0xffffc
    80005132:	5d2080e7          	jalr	1490(ra) # 80001700 <copyin>
    80005136:	fb6516e3          	bne	a0,s6,800050e2 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000513a:	21848513          	addi	a0,s1,536
    8000513e:	ffffd097          	auipc	ra,0xffffd
    80005142:	39c080e7          	jalr	924(ra) # 800024da <wakeup>
  release(&pi->lock);
    80005146:	8526                	mv	a0,s1
    80005148:	ffffc097          	auipc	ra,0xffffc
    8000514c:	b52080e7          	jalr	-1198(ra) # 80000c9a <release>
  return i;
    80005150:	bfb9                	j	800050ae <pipewrite+0x54>
  int i = 0;
    80005152:	4901                	li	s2,0
    80005154:	b7dd                	j	8000513a <pipewrite+0xe0>

0000000080005156 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005156:	715d                	addi	sp,sp,-80
    80005158:	e486                	sd	ra,72(sp)
    8000515a:	e0a2                	sd	s0,64(sp)
    8000515c:	fc26                	sd	s1,56(sp)
    8000515e:	f84a                	sd	s2,48(sp)
    80005160:	f44e                	sd	s3,40(sp)
    80005162:	f052                	sd	s4,32(sp)
    80005164:	ec56                	sd	s5,24(sp)
    80005166:	e85a                	sd	s6,16(sp)
    80005168:	0880                	addi	s0,sp,80
    8000516a:	84aa                	mv	s1,a0
    8000516c:	892e                	mv	s2,a1
    8000516e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005170:	ffffd097          	auipc	ra,0xffffd
    80005174:	892080e7          	jalr	-1902(ra) # 80001a02 <myproc>
    80005178:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000517a:	8b26                	mv	s6,s1
    8000517c:	8526                	mv	a0,s1
    8000517e:	ffffc097          	auipc	ra,0xffffc
    80005182:	a68080e7          	jalr	-1432(ra) # 80000be6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005186:	2184a703          	lw	a4,536(s1)
    8000518a:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000518e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005192:	02f71563          	bne	a4,a5,800051bc <piperead+0x66>
    80005196:	2244a783          	lw	a5,548(s1)
    8000519a:	c38d                	beqz	a5,800051bc <piperead+0x66>
    if(pr->killed){
    8000519c:	028a2783          	lw	a5,40(s4)
    800051a0:	2781                	sext.w	a5,a5
    800051a2:	ebc1                	bnez	a5,80005232 <piperead+0xdc>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051a4:	85da                	mv	a1,s6
    800051a6:	854e                	mv	a0,s3
    800051a8:	ffffd097          	auipc	ra,0xffffd
    800051ac:	14c080e7          	jalr	332(ra) # 800022f4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051b0:	2184a703          	lw	a4,536(s1)
    800051b4:	21c4a783          	lw	a5,540(s1)
    800051b8:	fcf70fe3          	beq	a4,a5,80005196 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051bc:	09505263          	blez	s5,80005240 <piperead+0xea>
    800051c0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051c2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800051c4:	2184a783          	lw	a5,536(s1)
    800051c8:	21c4a703          	lw	a4,540(s1)
    800051cc:	02f70d63          	beq	a4,a5,80005206 <piperead+0xb0>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800051d0:	0017871b          	addiw	a4,a5,1
    800051d4:	20e4ac23          	sw	a4,536(s1)
    800051d8:	1ff7f793          	andi	a5,a5,511
    800051dc:	97a6                	add	a5,a5,s1
    800051de:	0187c783          	lbu	a5,24(a5)
    800051e2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051e6:	4685                	li	a3,1
    800051e8:	fbf40613          	addi	a2,s0,-65
    800051ec:	85ca                	mv	a1,s2
    800051ee:	050a3503          	ld	a0,80(s4)
    800051f2:	ffffc097          	auipc	ra,0xffffc
    800051f6:	482080e7          	jalr	1154(ra) # 80001674 <copyout>
    800051fa:	01650663          	beq	a0,s6,80005206 <piperead+0xb0>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051fe:	2985                	addiw	s3,s3,1
    80005200:	0905                	addi	s2,s2,1
    80005202:	fd3a91e3          	bne	s5,s3,800051c4 <piperead+0x6e>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005206:	21c48513          	addi	a0,s1,540
    8000520a:	ffffd097          	auipc	ra,0xffffd
    8000520e:	2d0080e7          	jalr	720(ra) # 800024da <wakeup>
  release(&pi->lock);
    80005212:	8526                	mv	a0,s1
    80005214:	ffffc097          	auipc	ra,0xffffc
    80005218:	a86080e7          	jalr	-1402(ra) # 80000c9a <release>
  return i;
}
    8000521c:	854e                	mv	a0,s3
    8000521e:	60a6                	ld	ra,72(sp)
    80005220:	6406                	ld	s0,64(sp)
    80005222:	74e2                	ld	s1,56(sp)
    80005224:	7942                	ld	s2,48(sp)
    80005226:	79a2                	ld	s3,40(sp)
    80005228:	7a02                	ld	s4,32(sp)
    8000522a:	6ae2                	ld	s5,24(sp)
    8000522c:	6b42                	ld	s6,16(sp)
    8000522e:	6161                	addi	sp,sp,80
    80005230:	8082                	ret
      release(&pi->lock);
    80005232:	8526                	mv	a0,s1
    80005234:	ffffc097          	auipc	ra,0xffffc
    80005238:	a66080e7          	jalr	-1434(ra) # 80000c9a <release>
      return -1;
    8000523c:	59fd                	li	s3,-1
    8000523e:	bff9                	j	8000521c <piperead+0xc6>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005240:	4981                	li	s3,0
    80005242:	b7d1                	j	80005206 <piperead+0xb0>

0000000080005244 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005244:	df010113          	addi	sp,sp,-528
    80005248:	20113423          	sd	ra,520(sp)
    8000524c:	20813023          	sd	s0,512(sp)
    80005250:	ffa6                	sd	s1,504(sp)
    80005252:	fbca                	sd	s2,496(sp)
    80005254:	f7ce                	sd	s3,488(sp)
    80005256:	f3d2                	sd	s4,480(sp)
    80005258:	efd6                	sd	s5,472(sp)
    8000525a:	ebda                	sd	s6,464(sp)
    8000525c:	e7de                	sd	s7,456(sp)
    8000525e:	e3e2                	sd	s8,448(sp)
    80005260:	ff66                	sd	s9,440(sp)
    80005262:	fb6a                	sd	s10,432(sp)
    80005264:	f76e                	sd	s11,424(sp)
    80005266:	0c00                	addi	s0,sp,528
    80005268:	84aa                	mv	s1,a0
    8000526a:	dea43c23          	sd	a0,-520(s0)
    8000526e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005272:	ffffc097          	auipc	ra,0xffffc
    80005276:	790080e7          	jalr	1936(ra) # 80001a02 <myproc>
    8000527a:	892a                	mv	s2,a0

  begin_op();
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	498080e7          	jalr	1176(ra) # 80004714 <begin_op>

  if((ip = namei(path)) == 0){
    80005284:	8526                	mv	a0,s1
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	272080e7          	jalr	626(ra) # 800044f8 <namei>
    8000528e:	c92d                	beqz	a0,80005300 <exec+0xbc>
    80005290:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005292:	fffff097          	auipc	ra,0xfffff
    80005296:	ab0080e7          	jalr	-1360(ra) # 80003d42 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000529a:	04000713          	li	a4,64
    8000529e:	4681                	li	a3,0
    800052a0:	e5040613          	addi	a2,s0,-432
    800052a4:	4581                	li	a1,0
    800052a6:	8526                	mv	a0,s1
    800052a8:	fffff097          	auipc	ra,0xfffff
    800052ac:	d4e080e7          	jalr	-690(ra) # 80003ff6 <readi>
    800052b0:	04000793          	li	a5,64
    800052b4:	00f51a63          	bne	a0,a5,800052c8 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800052b8:	e5042703          	lw	a4,-432(s0)
    800052bc:	464c47b7          	lui	a5,0x464c4
    800052c0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800052c4:	04f70463          	beq	a4,a5,8000530c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800052c8:	8526                	mv	a0,s1
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	cda080e7          	jalr	-806(ra) # 80003fa4 <iunlockput>
    end_op();
    800052d2:	fffff097          	auipc	ra,0xfffff
    800052d6:	4c2080e7          	jalr	1218(ra) # 80004794 <end_op>
  }
  return -1;
    800052da:	557d                	li	a0,-1
}
    800052dc:	20813083          	ld	ra,520(sp)
    800052e0:	20013403          	ld	s0,512(sp)
    800052e4:	74fe                	ld	s1,504(sp)
    800052e6:	795e                	ld	s2,496(sp)
    800052e8:	79be                	ld	s3,488(sp)
    800052ea:	7a1e                	ld	s4,480(sp)
    800052ec:	6afe                	ld	s5,472(sp)
    800052ee:	6b5e                	ld	s6,464(sp)
    800052f0:	6bbe                	ld	s7,456(sp)
    800052f2:	6c1e                	ld	s8,448(sp)
    800052f4:	7cfa                	ld	s9,440(sp)
    800052f6:	7d5a                	ld	s10,432(sp)
    800052f8:	7dba                	ld	s11,424(sp)
    800052fa:	21010113          	addi	sp,sp,528
    800052fe:	8082                	ret
    end_op();
    80005300:	fffff097          	auipc	ra,0xfffff
    80005304:	494080e7          	jalr	1172(ra) # 80004794 <end_op>
    return -1;
    80005308:	557d                	li	a0,-1
    8000530a:	bfc9                	j	800052dc <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000530c:	854a                	mv	a0,s2
    8000530e:	ffffc097          	auipc	ra,0xffffc
    80005312:	7b8080e7          	jalr	1976(ra) # 80001ac6 <proc_pagetable>
    80005316:	8baa                	mv	s7,a0
    80005318:	d945                	beqz	a0,800052c8 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000531a:	e7042983          	lw	s3,-400(s0)
    8000531e:	e8845783          	lhu	a5,-376(s0)
    80005322:	c7ad                	beqz	a5,8000538c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005324:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005326:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005328:	6c85                	lui	s9,0x1
    8000532a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000532e:	def43823          	sd	a5,-528(s0)
    80005332:	a42d                	j	8000555c <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005334:	00003517          	auipc	a0,0x3
    80005338:	50450513          	addi	a0,a0,1284 # 80008838 <syscalls+0x298>
    8000533c:	ffffb097          	auipc	ra,0xffffb
    80005340:	204080e7          	jalr	516(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005344:	8756                	mv	a4,s5
    80005346:	012d86bb          	addw	a3,s11,s2
    8000534a:	4581                	li	a1,0
    8000534c:	8526                	mv	a0,s1
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	ca8080e7          	jalr	-856(ra) # 80003ff6 <readi>
    80005356:	2501                	sext.w	a0,a0
    80005358:	1aaa9963          	bne	s5,a0,8000550a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000535c:	6785                	lui	a5,0x1
    8000535e:	0127893b          	addw	s2,a5,s2
    80005362:	77fd                	lui	a5,0xfffff
    80005364:	01478a3b          	addw	s4,a5,s4
    80005368:	1f897163          	bgeu	s2,s8,8000554a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    8000536c:	02091593          	slli	a1,s2,0x20
    80005370:	9181                	srli	a1,a1,0x20
    80005372:	95ea                	add	a1,a1,s10
    80005374:	855e                	mv	a0,s7
    80005376:	ffffc097          	auipc	ra,0xffffc
    8000537a:	cfa080e7          	jalr	-774(ra) # 80001070 <walkaddr>
    8000537e:	862a                	mv	a2,a0
    if(pa == 0)
    80005380:	d955                	beqz	a0,80005334 <exec+0xf0>
      n = PGSIZE;
    80005382:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005384:	fd9a70e3          	bgeu	s4,s9,80005344 <exec+0x100>
      n = sz - i;
    80005388:	8ad2                	mv	s5,s4
    8000538a:	bf6d                	j	80005344 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000538c:	4901                	li	s2,0
  iunlockput(ip);
    8000538e:	8526                	mv	a0,s1
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	c14080e7          	jalr	-1004(ra) # 80003fa4 <iunlockput>
  end_op();
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	3fc080e7          	jalr	1020(ra) # 80004794 <end_op>
  p = myproc();
    800053a0:	ffffc097          	auipc	ra,0xffffc
    800053a4:	662080e7          	jalr	1634(ra) # 80001a02 <myproc>
    800053a8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800053aa:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800053ae:	6785                	lui	a5,0x1
    800053b0:	17fd                	addi	a5,a5,-1
    800053b2:	993e                	add	s2,s2,a5
    800053b4:	757d                	lui	a0,0xfffff
    800053b6:	00a977b3          	and	a5,s2,a0
    800053ba:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800053be:	6609                	lui	a2,0x2
    800053c0:	963e                	add	a2,a2,a5
    800053c2:	85be                	mv	a1,a5
    800053c4:	855e                	mv	a0,s7
    800053c6:	ffffc097          	auipc	ra,0xffffc
    800053ca:	05e080e7          	jalr	94(ra) # 80001424 <uvmalloc>
    800053ce:	8b2a                	mv	s6,a0
  ip = 0;
    800053d0:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800053d2:	12050c63          	beqz	a0,8000550a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053d6:	75f9                	lui	a1,0xffffe
    800053d8:	95aa                	add	a1,a1,a0
    800053da:	855e                	mv	a0,s7
    800053dc:	ffffc097          	auipc	ra,0xffffc
    800053e0:	266080e7          	jalr	614(ra) # 80001642 <uvmclear>
  stackbase = sp - PGSIZE;
    800053e4:	7c7d                	lui	s8,0xfffff
    800053e6:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800053e8:	e0043783          	ld	a5,-512(s0)
    800053ec:	6388                	ld	a0,0(a5)
    800053ee:	c535                	beqz	a0,8000545a <exec+0x216>
    800053f0:	e9040993          	addi	s3,s0,-368
    800053f4:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800053f8:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800053fa:	ffffc097          	auipc	ra,0xffffc
    800053fe:	a6c080e7          	jalr	-1428(ra) # 80000e66 <strlen>
    80005402:	2505                	addiw	a0,a0,1
    80005404:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005408:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000540c:	13896363          	bltu	s2,s8,80005532 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005410:	e0043d83          	ld	s11,-512(s0)
    80005414:	000dba03          	ld	s4,0(s11)
    80005418:	8552                	mv	a0,s4
    8000541a:	ffffc097          	auipc	ra,0xffffc
    8000541e:	a4c080e7          	jalr	-1460(ra) # 80000e66 <strlen>
    80005422:	0015069b          	addiw	a3,a0,1
    80005426:	8652                	mv	a2,s4
    80005428:	85ca                	mv	a1,s2
    8000542a:	855e                	mv	a0,s7
    8000542c:	ffffc097          	auipc	ra,0xffffc
    80005430:	248080e7          	jalr	584(ra) # 80001674 <copyout>
    80005434:	10054363          	bltz	a0,8000553a <exec+0x2f6>
    ustack[argc] = sp;
    80005438:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000543c:	0485                	addi	s1,s1,1
    8000543e:	008d8793          	addi	a5,s11,8
    80005442:	e0f43023          	sd	a5,-512(s0)
    80005446:	008db503          	ld	a0,8(s11)
    8000544a:	c911                	beqz	a0,8000545e <exec+0x21a>
    if(argc >= MAXARG)
    8000544c:	09a1                	addi	s3,s3,8
    8000544e:	fb3c96e3          	bne	s9,s3,800053fa <exec+0x1b6>
  sz = sz1;
    80005452:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005456:	4481                	li	s1,0
    80005458:	a84d                	j	8000550a <exec+0x2c6>
  sp = sz;
    8000545a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000545c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000545e:	00349793          	slli	a5,s1,0x3
    80005462:	f9040713          	addi	a4,s0,-112
    80005466:	97ba                	add	a5,a5,a4
    80005468:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000546c:	00148693          	addi	a3,s1,1
    80005470:	068e                	slli	a3,a3,0x3
    80005472:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005476:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000547a:	01897663          	bgeu	s2,s8,80005486 <exec+0x242>
  sz = sz1;
    8000547e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005482:	4481                	li	s1,0
    80005484:	a059                	j	8000550a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005486:	e9040613          	addi	a2,s0,-368
    8000548a:	85ca                	mv	a1,s2
    8000548c:	855e                	mv	a0,s7
    8000548e:	ffffc097          	auipc	ra,0xffffc
    80005492:	1e6080e7          	jalr	486(ra) # 80001674 <copyout>
    80005496:	0a054663          	bltz	a0,80005542 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000549a:	058ab783          	ld	a5,88(s5)
    8000549e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800054a2:	df843783          	ld	a5,-520(s0)
    800054a6:	0007c703          	lbu	a4,0(a5)
    800054aa:	cf11                	beqz	a4,800054c6 <exec+0x282>
    800054ac:	0785                	addi	a5,a5,1
    if(*s == '/')
    800054ae:	02f00693          	li	a3,47
    800054b2:	a039                	j	800054c0 <exec+0x27c>
      last = s+1;
    800054b4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800054b8:	0785                	addi	a5,a5,1
    800054ba:	fff7c703          	lbu	a4,-1(a5)
    800054be:	c701                	beqz	a4,800054c6 <exec+0x282>
    if(*s == '/')
    800054c0:	fed71ce3          	bne	a4,a3,800054b8 <exec+0x274>
    800054c4:	bfc5                	j	800054b4 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    800054c6:	4641                	li	a2,16
    800054c8:	df843583          	ld	a1,-520(s0)
    800054cc:	158a8513          	addi	a0,s5,344
    800054d0:	ffffc097          	auipc	ra,0xffffc
    800054d4:	964080e7          	jalr	-1692(ra) # 80000e34 <safestrcpy>
  oldpagetable = p->pagetable;
    800054d8:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800054dc:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800054e0:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054e4:	058ab783          	ld	a5,88(s5)
    800054e8:	e6843703          	ld	a4,-408(s0)
    800054ec:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054ee:	058ab783          	ld	a5,88(s5)
    800054f2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054f6:	85ea                	mv	a1,s10
    800054f8:	ffffc097          	auipc	ra,0xffffc
    800054fc:	66a080e7          	jalr	1642(ra) # 80001b62 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005500:	0004851b          	sext.w	a0,s1
    80005504:	bbe1                	j	800052dc <exec+0x98>
    80005506:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000550a:	e0843583          	ld	a1,-504(s0)
    8000550e:	855e                	mv	a0,s7
    80005510:	ffffc097          	auipc	ra,0xffffc
    80005514:	652080e7          	jalr	1618(ra) # 80001b62 <proc_freepagetable>
  if(ip){
    80005518:	da0498e3          	bnez	s1,800052c8 <exec+0x84>
  return -1;
    8000551c:	557d                	li	a0,-1
    8000551e:	bb7d                	j	800052dc <exec+0x98>
    80005520:	e1243423          	sd	s2,-504(s0)
    80005524:	b7dd                	j	8000550a <exec+0x2c6>
    80005526:	e1243423          	sd	s2,-504(s0)
    8000552a:	b7c5                	j	8000550a <exec+0x2c6>
    8000552c:	e1243423          	sd	s2,-504(s0)
    80005530:	bfe9                	j	8000550a <exec+0x2c6>
  sz = sz1;
    80005532:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005536:	4481                	li	s1,0
    80005538:	bfc9                	j	8000550a <exec+0x2c6>
  sz = sz1;
    8000553a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000553e:	4481                	li	s1,0
    80005540:	b7e9                	j	8000550a <exec+0x2c6>
  sz = sz1;
    80005542:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005546:	4481                	li	s1,0
    80005548:	b7c9                	j	8000550a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000554a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000554e:	2b05                	addiw	s6,s6,1
    80005550:	0389899b          	addiw	s3,s3,56
    80005554:	e8845783          	lhu	a5,-376(s0)
    80005558:	e2fb5be3          	bge	s6,a5,8000538e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000555c:	2981                	sext.w	s3,s3
    8000555e:	03800713          	li	a4,56
    80005562:	86ce                	mv	a3,s3
    80005564:	e1840613          	addi	a2,s0,-488
    80005568:	4581                	li	a1,0
    8000556a:	8526                	mv	a0,s1
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	a8a080e7          	jalr	-1398(ra) # 80003ff6 <readi>
    80005574:	03800793          	li	a5,56
    80005578:	f8f517e3          	bne	a0,a5,80005506 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000557c:	e1842783          	lw	a5,-488(s0)
    80005580:	4705                	li	a4,1
    80005582:	fce796e3          	bne	a5,a4,8000554e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005586:	e4043603          	ld	a2,-448(s0)
    8000558a:	e3843783          	ld	a5,-456(s0)
    8000558e:	f8f669e3          	bltu	a2,a5,80005520 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005592:	e2843783          	ld	a5,-472(s0)
    80005596:	963e                	add	a2,a2,a5
    80005598:	f8f667e3          	bltu	a2,a5,80005526 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000559c:	85ca                	mv	a1,s2
    8000559e:	855e                	mv	a0,s7
    800055a0:	ffffc097          	auipc	ra,0xffffc
    800055a4:	e84080e7          	jalr	-380(ra) # 80001424 <uvmalloc>
    800055a8:	e0a43423          	sd	a0,-504(s0)
    800055ac:	d141                	beqz	a0,8000552c <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800055ae:	e2843d03          	ld	s10,-472(s0)
    800055b2:	df043783          	ld	a5,-528(s0)
    800055b6:	00fd77b3          	and	a5,s10,a5
    800055ba:	fba1                	bnez	a5,8000550a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800055bc:	e2042d83          	lw	s11,-480(s0)
    800055c0:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800055c4:	f80c03e3          	beqz	s8,8000554a <exec+0x306>
    800055c8:	8a62                	mv	s4,s8
    800055ca:	4901                	li	s2,0
    800055cc:	b345                	j	8000536c <exec+0x128>

00000000800055ce <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800055ce:	7179                	addi	sp,sp,-48
    800055d0:	f406                	sd	ra,40(sp)
    800055d2:	f022                	sd	s0,32(sp)
    800055d4:	ec26                	sd	s1,24(sp)
    800055d6:	e84a                	sd	s2,16(sp)
    800055d8:	1800                	addi	s0,sp,48
    800055da:	892e                	mv	s2,a1
    800055dc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800055de:	fdc40593          	addi	a1,s0,-36
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	b88080e7          	jalr	-1144(ra) # 8000316a <argint>
    800055ea:	04054063          	bltz	a0,8000562a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800055ee:	fdc42703          	lw	a4,-36(s0)
    800055f2:	47bd                	li	a5,15
    800055f4:	02e7ed63          	bltu	a5,a4,8000562e <argfd+0x60>
    800055f8:	ffffc097          	auipc	ra,0xffffc
    800055fc:	40a080e7          	jalr	1034(ra) # 80001a02 <myproc>
    80005600:	fdc42703          	lw	a4,-36(s0)
    80005604:	01a70793          	addi	a5,a4,26
    80005608:	078e                	slli	a5,a5,0x3
    8000560a:	953e                	add	a0,a0,a5
    8000560c:	611c                	ld	a5,0(a0)
    8000560e:	c395                	beqz	a5,80005632 <argfd+0x64>
    return -1;
  if(pfd)
    80005610:	00090463          	beqz	s2,80005618 <argfd+0x4a>
    *pfd = fd;
    80005614:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005618:	4501                	li	a0,0
  if(pf)
    8000561a:	c091                	beqz	s1,8000561e <argfd+0x50>
    *pf = f;
    8000561c:	e09c                	sd	a5,0(s1)
}
    8000561e:	70a2                	ld	ra,40(sp)
    80005620:	7402                	ld	s0,32(sp)
    80005622:	64e2                	ld	s1,24(sp)
    80005624:	6942                	ld	s2,16(sp)
    80005626:	6145                	addi	sp,sp,48
    80005628:	8082                	ret
    return -1;
    8000562a:	557d                	li	a0,-1
    8000562c:	bfcd                	j	8000561e <argfd+0x50>
    return -1;
    8000562e:	557d                	li	a0,-1
    80005630:	b7fd                	j	8000561e <argfd+0x50>
    80005632:	557d                	li	a0,-1
    80005634:	b7ed                	j	8000561e <argfd+0x50>

0000000080005636 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005636:	1101                	addi	sp,sp,-32
    80005638:	ec06                	sd	ra,24(sp)
    8000563a:	e822                	sd	s0,16(sp)
    8000563c:	e426                	sd	s1,8(sp)
    8000563e:	1000                	addi	s0,sp,32
    80005640:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005642:	ffffc097          	auipc	ra,0xffffc
    80005646:	3c0080e7          	jalr	960(ra) # 80001a02 <myproc>
    8000564a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000564c:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005650:	4501                	li	a0,0
    80005652:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005654:	6398                	ld	a4,0(a5)
    80005656:	cb19                	beqz	a4,8000566c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005658:	2505                	addiw	a0,a0,1
    8000565a:	07a1                	addi	a5,a5,8
    8000565c:	fed51ce3          	bne	a0,a3,80005654 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005660:	557d                	li	a0,-1
}
    80005662:	60e2                	ld	ra,24(sp)
    80005664:	6442                	ld	s0,16(sp)
    80005666:	64a2                	ld	s1,8(sp)
    80005668:	6105                	addi	sp,sp,32
    8000566a:	8082                	ret
      p->ofile[fd] = f;
    8000566c:	01a50793          	addi	a5,a0,26
    80005670:	078e                	slli	a5,a5,0x3
    80005672:	963e                	add	a2,a2,a5
    80005674:	e204                	sd	s1,0(a2)
      return fd;
    80005676:	b7f5                	j	80005662 <fdalloc+0x2c>

0000000080005678 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005678:	715d                	addi	sp,sp,-80
    8000567a:	e486                	sd	ra,72(sp)
    8000567c:	e0a2                	sd	s0,64(sp)
    8000567e:	fc26                	sd	s1,56(sp)
    80005680:	f84a                	sd	s2,48(sp)
    80005682:	f44e                	sd	s3,40(sp)
    80005684:	f052                	sd	s4,32(sp)
    80005686:	ec56                	sd	s5,24(sp)
    80005688:	0880                	addi	s0,sp,80
    8000568a:	89ae                	mv	s3,a1
    8000568c:	8ab2                	mv	s5,a2
    8000568e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005690:	fb040593          	addi	a1,s0,-80
    80005694:	fffff097          	auipc	ra,0xfffff
    80005698:	e82080e7          	jalr	-382(ra) # 80004516 <nameiparent>
    8000569c:	892a                	mv	s2,a0
    8000569e:	12050f63          	beqz	a0,800057dc <create+0x164>
    return 0;

  ilock(dp);
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	6a0080e7          	jalr	1696(ra) # 80003d42 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800056aa:	4601                	li	a2,0
    800056ac:	fb040593          	addi	a1,s0,-80
    800056b0:	854a                	mv	a0,s2
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	b74080e7          	jalr	-1164(ra) # 80004226 <dirlookup>
    800056ba:	84aa                	mv	s1,a0
    800056bc:	c921                	beqz	a0,8000570c <create+0x94>
    iunlockput(dp);
    800056be:	854a                	mv	a0,s2
    800056c0:	fffff097          	auipc	ra,0xfffff
    800056c4:	8e4080e7          	jalr	-1820(ra) # 80003fa4 <iunlockput>
    ilock(ip);
    800056c8:	8526                	mv	a0,s1
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	678080e7          	jalr	1656(ra) # 80003d42 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800056d2:	2981                	sext.w	s3,s3
    800056d4:	4789                	li	a5,2
    800056d6:	02f99463          	bne	s3,a5,800056fe <create+0x86>
    800056da:	0444d783          	lhu	a5,68(s1)
    800056de:	37f9                	addiw	a5,a5,-2
    800056e0:	17c2                	slli	a5,a5,0x30
    800056e2:	93c1                	srli	a5,a5,0x30
    800056e4:	4705                	li	a4,1
    800056e6:	00f76c63          	bltu	a4,a5,800056fe <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800056ea:	8526                	mv	a0,s1
    800056ec:	60a6                	ld	ra,72(sp)
    800056ee:	6406                	ld	s0,64(sp)
    800056f0:	74e2                	ld	s1,56(sp)
    800056f2:	7942                	ld	s2,48(sp)
    800056f4:	79a2                	ld	s3,40(sp)
    800056f6:	7a02                	ld	s4,32(sp)
    800056f8:	6ae2                	ld	s5,24(sp)
    800056fa:	6161                	addi	sp,sp,80
    800056fc:	8082                	ret
    iunlockput(ip);
    800056fe:	8526                	mv	a0,s1
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	8a4080e7          	jalr	-1884(ra) # 80003fa4 <iunlockput>
    return 0;
    80005708:	4481                	li	s1,0
    8000570a:	b7c5                	j	800056ea <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000570c:	85ce                	mv	a1,s3
    8000570e:	00092503          	lw	a0,0(s2)
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	498080e7          	jalr	1176(ra) # 80003baa <ialloc>
    8000571a:	84aa                	mv	s1,a0
    8000571c:	c529                	beqz	a0,80005766 <create+0xee>
  ilock(ip);
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	624080e7          	jalr	1572(ra) # 80003d42 <ilock>
  ip->major = major;
    80005726:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000572a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000572e:	4785                	li	a5,1
    80005730:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005734:	8526                	mv	a0,s1
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	542080e7          	jalr	1346(ra) # 80003c78 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000573e:	2981                	sext.w	s3,s3
    80005740:	4785                	li	a5,1
    80005742:	02f98a63          	beq	s3,a5,80005776 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005746:	40d0                	lw	a2,4(s1)
    80005748:	fb040593          	addi	a1,s0,-80
    8000574c:	854a                	mv	a0,s2
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	ce8080e7          	jalr	-792(ra) # 80004436 <dirlink>
    80005756:	06054b63          	bltz	a0,800057cc <create+0x154>
  iunlockput(dp);
    8000575a:	854a                	mv	a0,s2
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	848080e7          	jalr	-1976(ra) # 80003fa4 <iunlockput>
  return ip;
    80005764:	b759                	j	800056ea <create+0x72>
    panic("create: ialloc");
    80005766:	00003517          	auipc	a0,0x3
    8000576a:	0f250513          	addi	a0,a0,242 # 80008858 <syscalls+0x2b8>
    8000576e:	ffffb097          	auipc	ra,0xffffb
    80005772:	dd2080e7          	jalr	-558(ra) # 80000540 <panic>
    dp->nlink++;  // for ".."
    80005776:	04a95783          	lhu	a5,74(s2)
    8000577a:	2785                	addiw	a5,a5,1
    8000577c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005780:	854a                	mv	a0,s2
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	4f6080e7          	jalr	1270(ra) # 80003c78 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000578a:	40d0                	lw	a2,4(s1)
    8000578c:	00003597          	auipc	a1,0x3
    80005790:	0dc58593          	addi	a1,a1,220 # 80008868 <syscalls+0x2c8>
    80005794:	8526                	mv	a0,s1
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	ca0080e7          	jalr	-864(ra) # 80004436 <dirlink>
    8000579e:	00054f63          	bltz	a0,800057bc <create+0x144>
    800057a2:	00492603          	lw	a2,4(s2)
    800057a6:	00003597          	auipc	a1,0x3
    800057aa:	0ca58593          	addi	a1,a1,202 # 80008870 <syscalls+0x2d0>
    800057ae:	8526                	mv	a0,s1
    800057b0:	fffff097          	auipc	ra,0xfffff
    800057b4:	c86080e7          	jalr	-890(ra) # 80004436 <dirlink>
    800057b8:	f80557e3          	bgez	a0,80005746 <create+0xce>
      panic("create dots");
    800057bc:	00003517          	auipc	a0,0x3
    800057c0:	0bc50513          	addi	a0,a0,188 # 80008878 <syscalls+0x2d8>
    800057c4:	ffffb097          	auipc	ra,0xffffb
    800057c8:	d7c080e7          	jalr	-644(ra) # 80000540 <panic>
    panic("create: dirlink");
    800057cc:	00003517          	auipc	a0,0x3
    800057d0:	0bc50513          	addi	a0,a0,188 # 80008888 <syscalls+0x2e8>
    800057d4:	ffffb097          	auipc	ra,0xffffb
    800057d8:	d6c080e7          	jalr	-660(ra) # 80000540 <panic>
    return 0;
    800057dc:	84aa                	mv	s1,a0
    800057de:	b731                	j	800056ea <create+0x72>

00000000800057e0 <sys_dup>:
{
    800057e0:	7179                	addi	sp,sp,-48
    800057e2:	f406                	sd	ra,40(sp)
    800057e4:	f022                	sd	s0,32(sp)
    800057e6:	ec26                	sd	s1,24(sp)
    800057e8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057ea:	fd840613          	addi	a2,s0,-40
    800057ee:	4581                	li	a1,0
    800057f0:	4501                	li	a0,0
    800057f2:	00000097          	auipc	ra,0x0
    800057f6:	ddc080e7          	jalr	-548(ra) # 800055ce <argfd>
    return -1;
    800057fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057fc:	02054363          	bltz	a0,80005822 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005800:	fd843503          	ld	a0,-40(s0)
    80005804:	00000097          	auipc	ra,0x0
    80005808:	e32080e7          	jalr	-462(ra) # 80005636 <fdalloc>
    8000580c:	84aa                	mv	s1,a0
    return -1;
    8000580e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005810:	00054963          	bltz	a0,80005822 <sys_dup+0x42>
  filedup(f);
    80005814:	fd843503          	ld	a0,-40(s0)
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	376080e7          	jalr	886(ra) # 80004b8e <filedup>
  return fd;
    80005820:	87a6                	mv	a5,s1
}
    80005822:	853e                	mv	a0,a5
    80005824:	70a2                	ld	ra,40(sp)
    80005826:	7402                	ld	s0,32(sp)
    80005828:	64e2                	ld	s1,24(sp)
    8000582a:	6145                	addi	sp,sp,48
    8000582c:	8082                	ret

000000008000582e <sys_read>:
{
    8000582e:	7179                	addi	sp,sp,-48
    80005830:	f406                	sd	ra,40(sp)
    80005832:	f022                	sd	s0,32(sp)
    80005834:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005836:	fe840613          	addi	a2,s0,-24
    8000583a:	4581                	li	a1,0
    8000583c:	4501                	li	a0,0
    8000583e:	00000097          	auipc	ra,0x0
    80005842:	d90080e7          	jalr	-624(ra) # 800055ce <argfd>
    return -1;
    80005846:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005848:	04054163          	bltz	a0,8000588a <sys_read+0x5c>
    8000584c:	fe440593          	addi	a1,s0,-28
    80005850:	4509                	li	a0,2
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	918080e7          	jalr	-1768(ra) # 8000316a <argint>
    return -1;
    8000585a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000585c:	02054763          	bltz	a0,8000588a <sys_read+0x5c>
    80005860:	fd840593          	addi	a1,s0,-40
    80005864:	4505                	li	a0,1
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	926080e7          	jalr	-1754(ra) # 8000318c <argaddr>
    return -1;
    8000586e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005870:	00054d63          	bltz	a0,8000588a <sys_read+0x5c>
  return fileread(f, p, n);
    80005874:	fe442603          	lw	a2,-28(s0)
    80005878:	fd843583          	ld	a1,-40(s0)
    8000587c:	fe843503          	ld	a0,-24(s0)
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	49a080e7          	jalr	1178(ra) # 80004d1a <fileread>
    80005888:	87aa                	mv	a5,a0
}
    8000588a:	853e                	mv	a0,a5
    8000588c:	70a2                	ld	ra,40(sp)
    8000588e:	7402                	ld	s0,32(sp)
    80005890:	6145                	addi	sp,sp,48
    80005892:	8082                	ret

0000000080005894 <sys_write>:
{
    80005894:	7179                	addi	sp,sp,-48
    80005896:	f406                	sd	ra,40(sp)
    80005898:	f022                	sd	s0,32(sp)
    8000589a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000589c:	fe840613          	addi	a2,s0,-24
    800058a0:	4581                	li	a1,0
    800058a2:	4501                	li	a0,0
    800058a4:	00000097          	auipc	ra,0x0
    800058a8:	d2a080e7          	jalr	-726(ra) # 800055ce <argfd>
    return -1;
    800058ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058ae:	04054163          	bltz	a0,800058f0 <sys_write+0x5c>
    800058b2:	fe440593          	addi	a1,s0,-28
    800058b6:	4509                	li	a0,2
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	8b2080e7          	jalr	-1870(ra) # 8000316a <argint>
    return -1;
    800058c0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058c2:	02054763          	bltz	a0,800058f0 <sys_write+0x5c>
    800058c6:	fd840593          	addi	a1,s0,-40
    800058ca:	4505                	li	a0,1
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	8c0080e7          	jalr	-1856(ra) # 8000318c <argaddr>
    return -1;
    800058d4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800058d6:	00054d63          	bltz	a0,800058f0 <sys_write+0x5c>
  return filewrite(f, p, n);
    800058da:	fe442603          	lw	a2,-28(s0)
    800058de:	fd843583          	ld	a1,-40(s0)
    800058e2:	fe843503          	ld	a0,-24(s0)
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	4f6080e7          	jalr	1270(ra) # 80004ddc <filewrite>
    800058ee:	87aa                	mv	a5,a0
}
    800058f0:	853e                	mv	a0,a5
    800058f2:	70a2                	ld	ra,40(sp)
    800058f4:	7402                	ld	s0,32(sp)
    800058f6:	6145                	addi	sp,sp,48
    800058f8:	8082                	ret

00000000800058fa <sys_close>:
{
    800058fa:	1101                	addi	sp,sp,-32
    800058fc:	ec06                	sd	ra,24(sp)
    800058fe:	e822                	sd	s0,16(sp)
    80005900:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005902:	fe040613          	addi	a2,s0,-32
    80005906:	fec40593          	addi	a1,s0,-20
    8000590a:	4501                	li	a0,0
    8000590c:	00000097          	auipc	ra,0x0
    80005910:	cc2080e7          	jalr	-830(ra) # 800055ce <argfd>
    return -1;
    80005914:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005916:	02054463          	bltz	a0,8000593e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000591a:	ffffc097          	auipc	ra,0xffffc
    8000591e:	0e8080e7          	jalr	232(ra) # 80001a02 <myproc>
    80005922:	fec42783          	lw	a5,-20(s0)
    80005926:	07e9                	addi	a5,a5,26
    80005928:	078e                	slli	a5,a5,0x3
    8000592a:	97aa                	add	a5,a5,a0
    8000592c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005930:	fe043503          	ld	a0,-32(s0)
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	2ac080e7          	jalr	684(ra) # 80004be0 <fileclose>
  return 0;
    8000593c:	4781                	li	a5,0
}
    8000593e:	853e                	mv	a0,a5
    80005940:	60e2                	ld	ra,24(sp)
    80005942:	6442                	ld	s0,16(sp)
    80005944:	6105                	addi	sp,sp,32
    80005946:	8082                	ret

0000000080005948 <sys_fstat>:
{
    80005948:	1101                	addi	sp,sp,-32
    8000594a:	ec06                	sd	ra,24(sp)
    8000594c:	e822                	sd	s0,16(sp)
    8000594e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005950:	fe840613          	addi	a2,s0,-24
    80005954:	4581                	li	a1,0
    80005956:	4501                	li	a0,0
    80005958:	00000097          	auipc	ra,0x0
    8000595c:	c76080e7          	jalr	-906(ra) # 800055ce <argfd>
    return -1;
    80005960:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005962:	02054563          	bltz	a0,8000598c <sys_fstat+0x44>
    80005966:	fe040593          	addi	a1,s0,-32
    8000596a:	4505                	li	a0,1
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	820080e7          	jalr	-2016(ra) # 8000318c <argaddr>
    return -1;
    80005974:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005976:	00054b63          	bltz	a0,8000598c <sys_fstat+0x44>
  return filestat(f, st);
    8000597a:	fe043583          	ld	a1,-32(s0)
    8000597e:	fe843503          	ld	a0,-24(s0)
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	326080e7          	jalr	806(ra) # 80004ca8 <filestat>
    8000598a:	87aa                	mv	a5,a0
}
    8000598c:	853e                	mv	a0,a5
    8000598e:	60e2                	ld	ra,24(sp)
    80005990:	6442                	ld	s0,16(sp)
    80005992:	6105                	addi	sp,sp,32
    80005994:	8082                	ret

0000000080005996 <sys_link>:
{
    80005996:	7169                	addi	sp,sp,-304
    80005998:	f606                	sd	ra,296(sp)
    8000599a:	f222                	sd	s0,288(sp)
    8000599c:	ee26                	sd	s1,280(sp)
    8000599e:	ea4a                	sd	s2,272(sp)
    800059a0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059a2:	08000613          	li	a2,128
    800059a6:	ed040593          	addi	a1,s0,-304
    800059aa:	4501                	li	a0,0
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	802080e7          	jalr	-2046(ra) # 800031ae <argstr>
    return -1;
    800059b4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059b6:	10054e63          	bltz	a0,80005ad2 <sys_link+0x13c>
    800059ba:	08000613          	li	a2,128
    800059be:	f5040593          	addi	a1,s0,-176
    800059c2:	4505                	li	a0,1
    800059c4:	ffffd097          	auipc	ra,0xffffd
    800059c8:	7ea080e7          	jalr	2026(ra) # 800031ae <argstr>
    return -1;
    800059cc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059ce:	10054263          	bltz	a0,80005ad2 <sys_link+0x13c>
  begin_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	d42080e7          	jalr	-702(ra) # 80004714 <begin_op>
  if((ip = namei(old)) == 0){
    800059da:	ed040513          	addi	a0,s0,-304
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	b1a080e7          	jalr	-1254(ra) # 800044f8 <namei>
    800059e6:	84aa                	mv	s1,a0
    800059e8:	c551                	beqz	a0,80005a74 <sys_link+0xde>
  ilock(ip);
    800059ea:	ffffe097          	auipc	ra,0xffffe
    800059ee:	358080e7          	jalr	856(ra) # 80003d42 <ilock>
  if(ip->type == T_DIR){
    800059f2:	04449703          	lh	a4,68(s1)
    800059f6:	4785                	li	a5,1
    800059f8:	08f70463          	beq	a4,a5,80005a80 <sys_link+0xea>
  ip->nlink++;
    800059fc:	04a4d783          	lhu	a5,74(s1)
    80005a00:	2785                	addiw	a5,a5,1
    80005a02:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a06:	8526                	mv	a0,s1
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	270080e7          	jalr	624(ra) # 80003c78 <iupdate>
  iunlock(ip);
    80005a10:	8526                	mv	a0,s1
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	3f2080e7          	jalr	1010(ra) # 80003e04 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a1a:	fd040593          	addi	a1,s0,-48
    80005a1e:	f5040513          	addi	a0,s0,-176
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	af4080e7          	jalr	-1292(ra) # 80004516 <nameiparent>
    80005a2a:	892a                	mv	s2,a0
    80005a2c:	c935                	beqz	a0,80005aa0 <sys_link+0x10a>
  ilock(dp);
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	314080e7          	jalr	788(ra) # 80003d42 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a36:	00092703          	lw	a4,0(s2)
    80005a3a:	409c                	lw	a5,0(s1)
    80005a3c:	04f71d63          	bne	a4,a5,80005a96 <sys_link+0x100>
    80005a40:	40d0                	lw	a2,4(s1)
    80005a42:	fd040593          	addi	a1,s0,-48
    80005a46:	854a                	mv	a0,s2
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	9ee080e7          	jalr	-1554(ra) # 80004436 <dirlink>
    80005a50:	04054363          	bltz	a0,80005a96 <sys_link+0x100>
  iunlockput(dp);
    80005a54:	854a                	mv	a0,s2
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	54e080e7          	jalr	1358(ra) # 80003fa4 <iunlockput>
  iput(ip);
    80005a5e:	8526                	mv	a0,s1
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	49c080e7          	jalr	1180(ra) # 80003efc <iput>
  end_op();
    80005a68:	fffff097          	auipc	ra,0xfffff
    80005a6c:	d2c080e7          	jalr	-724(ra) # 80004794 <end_op>
  return 0;
    80005a70:	4781                	li	a5,0
    80005a72:	a085                	j	80005ad2 <sys_link+0x13c>
    end_op();
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	d20080e7          	jalr	-736(ra) # 80004794 <end_op>
    return -1;
    80005a7c:	57fd                	li	a5,-1
    80005a7e:	a891                	j	80005ad2 <sys_link+0x13c>
    iunlockput(ip);
    80005a80:	8526                	mv	a0,s1
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	522080e7          	jalr	1314(ra) # 80003fa4 <iunlockput>
    end_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	d0a080e7          	jalr	-758(ra) # 80004794 <end_op>
    return -1;
    80005a92:	57fd                	li	a5,-1
    80005a94:	a83d                	j	80005ad2 <sys_link+0x13c>
    iunlockput(dp);
    80005a96:	854a                	mv	a0,s2
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	50c080e7          	jalr	1292(ra) # 80003fa4 <iunlockput>
  ilock(ip);
    80005aa0:	8526                	mv	a0,s1
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	2a0080e7          	jalr	672(ra) # 80003d42 <ilock>
  ip->nlink--;
    80005aaa:	04a4d783          	lhu	a5,74(s1)
    80005aae:	37fd                	addiw	a5,a5,-1
    80005ab0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005ab4:	8526                	mv	a0,s1
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	1c2080e7          	jalr	450(ra) # 80003c78 <iupdate>
  iunlockput(ip);
    80005abe:	8526                	mv	a0,s1
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	4e4080e7          	jalr	1252(ra) # 80003fa4 <iunlockput>
  end_op();
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	ccc080e7          	jalr	-820(ra) # 80004794 <end_op>
  return -1;
    80005ad0:	57fd                	li	a5,-1
}
    80005ad2:	853e                	mv	a0,a5
    80005ad4:	70b2                	ld	ra,296(sp)
    80005ad6:	7412                	ld	s0,288(sp)
    80005ad8:	64f2                	ld	s1,280(sp)
    80005ada:	6952                	ld	s2,272(sp)
    80005adc:	6155                	addi	sp,sp,304
    80005ade:	8082                	ret

0000000080005ae0 <sys_unlink>:
{
    80005ae0:	7151                	addi	sp,sp,-240
    80005ae2:	f586                	sd	ra,232(sp)
    80005ae4:	f1a2                	sd	s0,224(sp)
    80005ae6:	eda6                	sd	s1,216(sp)
    80005ae8:	e9ca                	sd	s2,208(sp)
    80005aea:	e5ce                	sd	s3,200(sp)
    80005aec:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005aee:	08000613          	li	a2,128
    80005af2:	f3040593          	addi	a1,s0,-208
    80005af6:	4501                	li	a0,0
    80005af8:	ffffd097          	auipc	ra,0xffffd
    80005afc:	6b6080e7          	jalr	1718(ra) # 800031ae <argstr>
    80005b00:	18054163          	bltz	a0,80005c82 <sys_unlink+0x1a2>
  begin_op();
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	c10080e7          	jalr	-1008(ra) # 80004714 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b0c:	fb040593          	addi	a1,s0,-80
    80005b10:	f3040513          	addi	a0,s0,-208
    80005b14:	fffff097          	auipc	ra,0xfffff
    80005b18:	a02080e7          	jalr	-1534(ra) # 80004516 <nameiparent>
    80005b1c:	84aa                	mv	s1,a0
    80005b1e:	c979                	beqz	a0,80005bf4 <sys_unlink+0x114>
  ilock(dp);
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	222080e7          	jalr	546(ra) # 80003d42 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b28:	00003597          	auipc	a1,0x3
    80005b2c:	d4058593          	addi	a1,a1,-704 # 80008868 <syscalls+0x2c8>
    80005b30:	fb040513          	addi	a0,s0,-80
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	6d8080e7          	jalr	1752(ra) # 8000420c <namecmp>
    80005b3c:	14050a63          	beqz	a0,80005c90 <sys_unlink+0x1b0>
    80005b40:	00003597          	auipc	a1,0x3
    80005b44:	d3058593          	addi	a1,a1,-720 # 80008870 <syscalls+0x2d0>
    80005b48:	fb040513          	addi	a0,s0,-80
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	6c0080e7          	jalr	1728(ra) # 8000420c <namecmp>
    80005b54:	12050e63          	beqz	a0,80005c90 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005b58:	f2c40613          	addi	a2,s0,-212
    80005b5c:	fb040593          	addi	a1,s0,-80
    80005b60:	8526                	mv	a0,s1
    80005b62:	ffffe097          	auipc	ra,0xffffe
    80005b66:	6c4080e7          	jalr	1732(ra) # 80004226 <dirlookup>
    80005b6a:	892a                	mv	s2,a0
    80005b6c:	12050263          	beqz	a0,80005c90 <sys_unlink+0x1b0>
  ilock(ip);
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	1d2080e7          	jalr	466(ra) # 80003d42 <ilock>
  if(ip->nlink < 1)
    80005b78:	04a91783          	lh	a5,74(s2)
    80005b7c:	08f05263          	blez	a5,80005c00 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b80:	04491703          	lh	a4,68(s2)
    80005b84:	4785                	li	a5,1
    80005b86:	08f70563          	beq	a4,a5,80005c10 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b8a:	4641                	li	a2,16
    80005b8c:	4581                	li	a1,0
    80005b8e:	fc040513          	addi	a0,s0,-64
    80005b92:	ffffb097          	auipc	ra,0xffffb
    80005b96:	150080e7          	jalr	336(ra) # 80000ce2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b9a:	4741                	li	a4,16
    80005b9c:	f2c42683          	lw	a3,-212(s0)
    80005ba0:	fc040613          	addi	a2,s0,-64
    80005ba4:	4581                	li	a1,0
    80005ba6:	8526                	mv	a0,s1
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	546080e7          	jalr	1350(ra) # 800040ee <writei>
    80005bb0:	47c1                	li	a5,16
    80005bb2:	0af51563          	bne	a0,a5,80005c5c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005bb6:	04491703          	lh	a4,68(s2)
    80005bba:	4785                	li	a5,1
    80005bbc:	0af70863          	beq	a4,a5,80005c6c <sys_unlink+0x18c>
  iunlockput(dp);
    80005bc0:	8526                	mv	a0,s1
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	3e2080e7          	jalr	994(ra) # 80003fa4 <iunlockput>
  ip->nlink--;
    80005bca:	04a95783          	lhu	a5,74(s2)
    80005bce:	37fd                	addiw	a5,a5,-1
    80005bd0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005bd4:	854a                	mv	a0,s2
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	0a2080e7          	jalr	162(ra) # 80003c78 <iupdate>
  iunlockput(ip);
    80005bde:	854a                	mv	a0,s2
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	3c4080e7          	jalr	964(ra) # 80003fa4 <iunlockput>
  end_op();
    80005be8:	fffff097          	auipc	ra,0xfffff
    80005bec:	bac080e7          	jalr	-1108(ra) # 80004794 <end_op>
  return 0;
    80005bf0:	4501                	li	a0,0
    80005bf2:	a84d                	j	80005ca4 <sys_unlink+0x1c4>
    end_op();
    80005bf4:	fffff097          	auipc	ra,0xfffff
    80005bf8:	ba0080e7          	jalr	-1120(ra) # 80004794 <end_op>
    return -1;
    80005bfc:	557d                	li	a0,-1
    80005bfe:	a05d                	j	80005ca4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c00:	00003517          	auipc	a0,0x3
    80005c04:	c9850513          	addi	a0,a0,-872 # 80008898 <syscalls+0x2f8>
    80005c08:	ffffb097          	auipc	ra,0xffffb
    80005c0c:	938080e7          	jalr	-1736(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c10:	04c92703          	lw	a4,76(s2)
    80005c14:	02000793          	li	a5,32
    80005c18:	f6e7f9e3          	bgeu	a5,a4,80005b8a <sys_unlink+0xaa>
    80005c1c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c20:	4741                	li	a4,16
    80005c22:	86ce                	mv	a3,s3
    80005c24:	f1840613          	addi	a2,s0,-232
    80005c28:	4581                	li	a1,0
    80005c2a:	854a                	mv	a0,s2
    80005c2c:	ffffe097          	auipc	ra,0xffffe
    80005c30:	3ca080e7          	jalr	970(ra) # 80003ff6 <readi>
    80005c34:	47c1                	li	a5,16
    80005c36:	00f51b63          	bne	a0,a5,80005c4c <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c3a:	f1845783          	lhu	a5,-232(s0)
    80005c3e:	e7a1                	bnez	a5,80005c86 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c40:	29c1                	addiw	s3,s3,16
    80005c42:	04c92783          	lw	a5,76(s2)
    80005c46:	fcf9ede3          	bltu	s3,a5,80005c20 <sys_unlink+0x140>
    80005c4a:	b781                	j	80005b8a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005c4c:	00003517          	auipc	a0,0x3
    80005c50:	c6450513          	addi	a0,a0,-924 # 800088b0 <syscalls+0x310>
    80005c54:	ffffb097          	auipc	ra,0xffffb
    80005c58:	8ec080e7          	jalr	-1812(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005c5c:	00003517          	auipc	a0,0x3
    80005c60:	c6c50513          	addi	a0,a0,-916 # 800088c8 <syscalls+0x328>
    80005c64:	ffffb097          	auipc	ra,0xffffb
    80005c68:	8dc080e7          	jalr	-1828(ra) # 80000540 <panic>
    dp->nlink--;
    80005c6c:	04a4d783          	lhu	a5,74(s1)
    80005c70:	37fd                	addiw	a5,a5,-1
    80005c72:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c76:	8526                	mv	a0,s1
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	000080e7          	jalr	ra # 80003c78 <iupdate>
    80005c80:	b781                	j	80005bc0 <sys_unlink+0xe0>
    return -1;
    80005c82:	557d                	li	a0,-1
    80005c84:	a005                	j	80005ca4 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c86:	854a                	mv	a0,s2
    80005c88:	ffffe097          	auipc	ra,0xffffe
    80005c8c:	31c080e7          	jalr	796(ra) # 80003fa4 <iunlockput>
  iunlockput(dp);
    80005c90:	8526                	mv	a0,s1
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	312080e7          	jalr	786(ra) # 80003fa4 <iunlockput>
  end_op();
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	afa080e7          	jalr	-1286(ra) # 80004794 <end_op>
  return -1;
    80005ca2:	557d                	li	a0,-1
}
    80005ca4:	70ae                	ld	ra,232(sp)
    80005ca6:	740e                	ld	s0,224(sp)
    80005ca8:	64ee                	ld	s1,216(sp)
    80005caa:	694e                	ld	s2,208(sp)
    80005cac:	69ae                	ld	s3,200(sp)
    80005cae:	616d                	addi	sp,sp,240
    80005cb0:	8082                	ret

0000000080005cb2 <sys_open>:

uint64
sys_open(void)
{
    80005cb2:	7131                	addi	sp,sp,-192
    80005cb4:	fd06                	sd	ra,184(sp)
    80005cb6:	f922                	sd	s0,176(sp)
    80005cb8:	f526                	sd	s1,168(sp)
    80005cba:	f14a                	sd	s2,160(sp)
    80005cbc:	ed4e                	sd	s3,152(sp)
    80005cbe:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005cc0:	08000613          	li	a2,128
    80005cc4:	f5040593          	addi	a1,s0,-176
    80005cc8:	4501                	li	a0,0
    80005cca:	ffffd097          	auipc	ra,0xffffd
    80005cce:	4e4080e7          	jalr	1252(ra) # 800031ae <argstr>
    return -1;
    80005cd2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005cd4:	0c054163          	bltz	a0,80005d96 <sys_open+0xe4>
    80005cd8:	f4c40593          	addi	a1,s0,-180
    80005cdc:	4505                	li	a0,1
    80005cde:	ffffd097          	auipc	ra,0xffffd
    80005ce2:	48c080e7          	jalr	1164(ra) # 8000316a <argint>
    80005ce6:	0a054863          	bltz	a0,80005d96 <sys_open+0xe4>

  begin_op();
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	a2a080e7          	jalr	-1494(ra) # 80004714 <begin_op>

  if(omode & O_CREATE){
    80005cf2:	f4c42783          	lw	a5,-180(s0)
    80005cf6:	2007f793          	andi	a5,a5,512
    80005cfa:	cbdd                	beqz	a5,80005db0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005cfc:	4681                	li	a3,0
    80005cfe:	4601                	li	a2,0
    80005d00:	4589                	li	a1,2
    80005d02:	f5040513          	addi	a0,s0,-176
    80005d06:	00000097          	auipc	ra,0x0
    80005d0a:	972080e7          	jalr	-1678(ra) # 80005678 <create>
    80005d0e:	892a                	mv	s2,a0
    if(ip == 0){
    80005d10:	c959                	beqz	a0,80005da6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d12:	04491703          	lh	a4,68(s2)
    80005d16:	478d                	li	a5,3
    80005d18:	00f71763          	bne	a4,a5,80005d26 <sys_open+0x74>
    80005d1c:	04695703          	lhu	a4,70(s2)
    80005d20:	47a5                	li	a5,9
    80005d22:	0ce7ec63          	bltu	a5,a4,80005dfa <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	dfe080e7          	jalr	-514(ra) # 80004b24 <filealloc>
    80005d2e:	89aa                	mv	s3,a0
    80005d30:	10050263          	beqz	a0,80005e34 <sys_open+0x182>
    80005d34:	00000097          	auipc	ra,0x0
    80005d38:	902080e7          	jalr	-1790(ra) # 80005636 <fdalloc>
    80005d3c:	84aa                	mv	s1,a0
    80005d3e:	0e054663          	bltz	a0,80005e2a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d42:	04491703          	lh	a4,68(s2)
    80005d46:	478d                	li	a5,3
    80005d48:	0cf70463          	beq	a4,a5,80005e10 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005d4c:	4789                	li	a5,2
    80005d4e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005d52:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005d56:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005d5a:	f4c42783          	lw	a5,-180(s0)
    80005d5e:	0017c713          	xori	a4,a5,1
    80005d62:	8b05                	andi	a4,a4,1
    80005d64:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005d68:	0037f713          	andi	a4,a5,3
    80005d6c:	00e03733          	snez	a4,a4
    80005d70:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d74:	4007f793          	andi	a5,a5,1024
    80005d78:	c791                	beqz	a5,80005d84 <sys_open+0xd2>
    80005d7a:	04491703          	lh	a4,68(s2)
    80005d7e:	4789                	li	a5,2
    80005d80:	08f70f63          	beq	a4,a5,80005e1e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005d84:	854a                	mv	a0,s2
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	07e080e7          	jalr	126(ra) # 80003e04 <iunlock>
  end_op();
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	a06080e7          	jalr	-1530(ra) # 80004794 <end_op>

  return fd;
}
    80005d96:	8526                	mv	a0,s1
    80005d98:	70ea                	ld	ra,184(sp)
    80005d9a:	744a                	ld	s0,176(sp)
    80005d9c:	74aa                	ld	s1,168(sp)
    80005d9e:	790a                	ld	s2,160(sp)
    80005da0:	69ea                	ld	s3,152(sp)
    80005da2:	6129                	addi	sp,sp,192
    80005da4:	8082                	ret
      end_op();
    80005da6:	fffff097          	auipc	ra,0xfffff
    80005daa:	9ee080e7          	jalr	-1554(ra) # 80004794 <end_op>
      return -1;
    80005dae:	b7e5                	j	80005d96 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005db0:	f5040513          	addi	a0,s0,-176
    80005db4:	ffffe097          	auipc	ra,0xffffe
    80005db8:	744080e7          	jalr	1860(ra) # 800044f8 <namei>
    80005dbc:	892a                	mv	s2,a0
    80005dbe:	c905                	beqz	a0,80005dee <sys_open+0x13c>
    ilock(ip);
    80005dc0:	ffffe097          	auipc	ra,0xffffe
    80005dc4:	f82080e7          	jalr	-126(ra) # 80003d42 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005dc8:	04491703          	lh	a4,68(s2)
    80005dcc:	4785                	li	a5,1
    80005dce:	f4f712e3          	bne	a4,a5,80005d12 <sys_open+0x60>
    80005dd2:	f4c42783          	lw	a5,-180(s0)
    80005dd6:	dba1                	beqz	a5,80005d26 <sys_open+0x74>
      iunlockput(ip);
    80005dd8:	854a                	mv	a0,s2
    80005dda:	ffffe097          	auipc	ra,0xffffe
    80005dde:	1ca080e7          	jalr	458(ra) # 80003fa4 <iunlockput>
      end_op();
    80005de2:	fffff097          	auipc	ra,0xfffff
    80005de6:	9b2080e7          	jalr	-1614(ra) # 80004794 <end_op>
      return -1;
    80005dea:	54fd                	li	s1,-1
    80005dec:	b76d                	j	80005d96 <sys_open+0xe4>
      end_op();
    80005dee:	fffff097          	auipc	ra,0xfffff
    80005df2:	9a6080e7          	jalr	-1626(ra) # 80004794 <end_op>
      return -1;
    80005df6:	54fd                	li	s1,-1
    80005df8:	bf79                	j	80005d96 <sys_open+0xe4>
    iunlockput(ip);
    80005dfa:	854a                	mv	a0,s2
    80005dfc:	ffffe097          	auipc	ra,0xffffe
    80005e00:	1a8080e7          	jalr	424(ra) # 80003fa4 <iunlockput>
    end_op();
    80005e04:	fffff097          	auipc	ra,0xfffff
    80005e08:	990080e7          	jalr	-1648(ra) # 80004794 <end_op>
    return -1;
    80005e0c:	54fd                	li	s1,-1
    80005e0e:	b761                	j	80005d96 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005e10:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005e14:	04691783          	lh	a5,70(s2)
    80005e18:	02f99223          	sh	a5,36(s3)
    80005e1c:	bf2d                	j	80005d56 <sys_open+0xa4>
    itrunc(ip);
    80005e1e:	854a                	mv	a0,s2
    80005e20:	ffffe097          	auipc	ra,0xffffe
    80005e24:	030080e7          	jalr	48(ra) # 80003e50 <itrunc>
    80005e28:	bfb1                	j	80005d84 <sys_open+0xd2>
      fileclose(f);
    80005e2a:	854e                	mv	a0,s3
    80005e2c:	fffff097          	auipc	ra,0xfffff
    80005e30:	db4080e7          	jalr	-588(ra) # 80004be0 <fileclose>
    iunlockput(ip);
    80005e34:	854a                	mv	a0,s2
    80005e36:	ffffe097          	auipc	ra,0xffffe
    80005e3a:	16e080e7          	jalr	366(ra) # 80003fa4 <iunlockput>
    end_op();
    80005e3e:	fffff097          	auipc	ra,0xfffff
    80005e42:	956080e7          	jalr	-1706(ra) # 80004794 <end_op>
    return -1;
    80005e46:	54fd                	li	s1,-1
    80005e48:	b7b9                	j	80005d96 <sys_open+0xe4>

0000000080005e4a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005e4a:	7175                	addi	sp,sp,-144
    80005e4c:	e506                	sd	ra,136(sp)
    80005e4e:	e122                	sd	s0,128(sp)
    80005e50:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005e52:	fffff097          	auipc	ra,0xfffff
    80005e56:	8c2080e7          	jalr	-1854(ra) # 80004714 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005e5a:	08000613          	li	a2,128
    80005e5e:	f7040593          	addi	a1,s0,-144
    80005e62:	4501                	li	a0,0
    80005e64:	ffffd097          	auipc	ra,0xffffd
    80005e68:	34a080e7          	jalr	842(ra) # 800031ae <argstr>
    80005e6c:	02054963          	bltz	a0,80005e9e <sys_mkdir+0x54>
    80005e70:	4681                	li	a3,0
    80005e72:	4601                	li	a2,0
    80005e74:	4585                	li	a1,1
    80005e76:	f7040513          	addi	a0,s0,-144
    80005e7a:	fffff097          	auipc	ra,0xfffff
    80005e7e:	7fe080e7          	jalr	2046(ra) # 80005678 <create>
    80005e82:	cd11                	beqz	a0,80005e9e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e84:	ffffe097          	auipc	ra,0xffffe
    80005e88:	120080e7          	jalr	288(ra) # 80003fa4 <iunlockput>
  end_op();
    80005e8c:	fffff097          	auipc	ra,0xfffff
    80005e90:	908080e7          	jalr	-1784(ra) # 80004794 <end_op>
  return 0;
    80005e94:	4501                	li	a0,0
}
    80005e96:	60aa                	ld	ra,136(sp)
    80005e98:	640a                	ld	s0,128(sp)
    80005e9a:	6149                	addi	sp,sp,144
    80005e9c:	8082                	ret
    end_op();
    80005e9e:	fffff097          	auipc	ra,0xfffff
    80005ea2:	8f6080e7          	jalr	-1802(ra) # 80004794 <end_op>
    return -1;
    80005ea6:	557d                	li	a0,-1
    80005ea8:	b7fd                	j	80005e96 <sys_mkdir+0x4c>

0000000080005eaa <sys_mknod>:

uint64
sys_mknod(void)
{
    80005eaa:	7135                	addi	sp,sp,-160
    80005eac:	ed06                	sd	ra,152(sp)
    80005eae:	e922                	sd	s0,144(sp)
    80005eb0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005eb2:	fffff097          	auipc	ra,0xfffff
    80005eb6:	862080e7          	jalr	-1950(ra) # 80004714 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005eba:	08000613          	li	a2,128
    80005ebe:	f7040593          	addi	a1,s0,-144
    80005ec2:	4501                	li	a0,0
    80005ec4:	ffffd097          	auipc	ra,0xffffd
    80005ec8:	2ea080e7          	jalr	746(ra) # 800031ae <argstr>
    80005ecc:	04054a63          	bltz	a0,80005f20 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005ed0:	f6c40593          	addi	a1,s0,-148
    80005ed4:	4505                	li	a0,1
    80005ed6:	ffffd097          	auipc	ra,0xffffd
    80005eda:	294080e7          	jalr	660(ra) # 8000316a <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ede:	04054163          	bltz	a0,80005f20 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005ee2:	f6840593          	addi	a1,s0,-152
    80005ee6:	4509                	li	a0,2
    80005ee8:	ffffd097          	auipc	ra,0xffffd
    80005eec:	282080e7          	jalr	642(ra) # 8000316a <argint>
     argint(1, &major) < 0 ||
    80005ef0:	02054863          	bltz	a0,80005f20 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ef4:	f6841683          	lh	a3,-152(s0)
    80005ef8:	f6c41603          	lh	a2,-148(s0)
    80005efc:	458d                	li	a1,3
    80005efe:	f7040513          	addi	a0,s0,-144
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	776080e7          	jalr	1910(ra) # 80005678 <create>
     argint(2, &minor) < 0 ||
    80005f0a:	c919                	beqz	a0,80005f20 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f0c:	ffffe097          	auipc	ra,0xffffe
    80005f10:	098080e7          	jalr	152(ra) # 80003fa4 <iunlockput>
  end_op();
    80005f14:	fffff097          	auipc	ra,0xfffff
    80005f18:	880080e7          	jalr	-1920(ra) # 80004794 <end_op>
  return 0;
    80005f1c:	4501                	li	a0,0
    80005f1e:	a031                	j	80005f2a <sys_mknod+0x80>
    end_op();
    80005f20:	fffff097          	auipc	ra,0xfffff
    80005f24:	874080e7          	jalr	-1932(ra) # 80004794 <end_op>
    return -1;
    80005f28:	557d                	li	a0,-1
}
    80005f2a:	60ea                	ld	ra,152(sp)
    80005f2c:	644a                	ld	s0,144(sp)
    80005f2e:	610d                	addi	sp,sp,160
    80005f30:	8082                	ret

0000000080005f32 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f32:	7135                	addi	sp,sp,-160
    80005f34:	ed06                	sd	ra,152(sp)
    80005f36:	e922                	sd	s0,144(sp)
    80005f38:	e526                	sd	s1,136(sp)
    80005f3a:	e14a                	sd	s2,128(sp)
    80005f3c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f3e:	ffffc097          	auipc	ra,0xffffc
    80005f42:	ac4080e7          	jalr	-1340(ra) # 80001a02 <myproc>
    80005f46:	892a                	mv	s2,a0
  
  begin_op();
    80005f48:	ffffe097          	auipc	ra,0xffffe
    80005f4c:	7cc080e7          	jalr	1996(ra) # 80004714 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f50:	08000613          	li	a2,128
    80005f54:	f6040593          	addi	a1,s0,-160
    80005f58:	4501                	li	a0,0
    80005f5a:	ffffd097          	auipc	ra,0xffffd
    80005f5e:	254080e7          	jalr	596(ra) # 800031ae <argstr>
    80005f62:	04054b63          	bltz	a0,80005fb8 <sys_chdir+0x86>
    80005f66:	f6040513          	addi	a0,s0,-160
    80005f6a:	ffffe097          	auipc	ra,0xffffe
    80005f6e:	58e080e7          	jalr	1422(ra) # 800044f8 <namei>
    80005f72:	84aa                	mv	s1,a0
    80005f74:	c131                	beqz	a0,80005fb8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f76:	ffffe097          	auipc	ra,0xffffe
    80005f7a:	dcc080e7          	jalr	-564(ra) # 80003d42 <ilock>
  if(ip->type != T_DIR){
    80005f7e:	04449703          	lh	a4,68(s1)
    80005f82:	4785                	li	a5,1
    80005f84:	04f71063          	bne	a4,a5,80005fc4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f88:	8526                	mv	a0,s1
    80005f8a:	ffffe097          	auipc	ra,0xffffe
    80005f8e:	e7a080e7          	jalr	-390(ra) # 80003e04 <iunlock>
  iput(p->cwd);
    80005f92:	15093503          	ld	a0,336(s2)
    80005f96:	ffffe097          	auipc	ra,0xffffe
    80005f9a:	f66080e7          	jalr	-154(ra) # 80003efc <iput>
  end_op();
    80005f9e:	ffffe097          	auipc	ra,0xffffe
    80005fa2:	7f6080e7          	jalr	2038(ra) # 80004794 <end_op>
  p->cwd = ip;
    80005fa6:	14993823          	sd	s1,336(s2)
  return 0;
    80005faa:	4501                	li	a0,0
}
    80005fac:	60ea                	ld	ra,152(sp)
    80005fae:	644a                	ld	s0,144(sp)
    80005fb0:	64aa                	ld	s1,136(sp)
    80005fb2:	690a                	ld	s2,128(sp)
    80005fb4:	610d                	addi	sp,sp,160
    80005fb6:	8082                	ret
    end_op();
    80005fb8:	ffffe097          	auipc	ra,0xffffe
    80005fbc:	7dc080e7          	jalr	2012(ra) # 80004794 <end_op>
    return -1;
    80005fc0:	557d                	li	a0,-1
    80005fc2:	b7ed                	j	80005fac <sys_chdir+0x7a>
    iunlockput(ip);
    80005fc4:	8526                	mv	a0,s1
    80005fc6:	ffffe097          	auipc	ra,0xffffe
    80005fca:	fde080e7          	jalr	-34(ra) # 80003fa4 <iunlockput>
    end_op();
    80005fce:	ffffe097          	auipc	ra,0xffffe
    80005fd2:	7c6080e7          	jalr	1990(ra) # 80004794 <end_op>
    return -1;
    80005fd6:	557d                	li	a0,-1
    80005fd8:	bfd1                	j	80005fac <sys_chdir+0x7a>

0000000080005fda <sys_exec>:

uint64
sys_exec(void)
{
    80005fda:	7145                	addi	sp,sp,-464
    80005fdc:	e786                	sd	ra,456(sp)
    80005fde:	e3a2                	sd	s0,448(sp)
    80005fe0:	ff26                	sd	s1,440(sp)
    80005fe2:	fb4a                	sd	s2,432(sp)
    80005fe4:	f74e                	sd	s3,424(sp)
    80005fe6:	f352                	sd	s4,416(sp)
    80005fe8:	ef56                	sd	s5,408(sp)
    80005fea:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005fec:	08000613          	li	a2,128
    80005ff0:	f4040593          	addi	a1,s0,-192
    80005ff4:	4501                	li	a0,0
    80005ff6:	ffffd097          	auipc	ra,0xffffd
    80005ffa:	1b8080e7          	jalr	440(ra) # 800031ae <argstr>
    return -1;
    80005ffe:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006000:	0c054a63          	bltz	a0,800060d4 <sys_exec+0xfa>
    80006004:	e3840593          	addi	a1,s0,-456
    80006008:	4505                	li	a0,1
    8000600a:	ffffd097          	auipc	ra,0xffffd
    8000600e:	182080e7          	jalr	386(ra) # 8000318c <argaddr>
    80006012:	0c054163          	bltz	a0,800060d4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006016:	10000613          	li	a2,256
    8000601a:	4581                	li	a1,0
    8000601c:	e4040513          	addi	a0,s0,-448
    80006020:	ffffb097          	auipc	ra,0xffffb
    80006024:	cc2080e7          	jalr	-830(ra) # 80000ce2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006028:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000602c:	89a6                	mv	s3,s1
    8000602e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006030:	02000a13          	li	s4,32
    80006034:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80006038:	00391513          	slli	a0,s2,0x3
    8000603c:	e3040593          	addi	a1,s0,-464
    80006040:	e3843783          	ld	a5,-456(s0)
    80006044:	953e                	add	a0,a0,a5
    80006046:	ffffd097          	auipc	ra,0xffffd
    8000604a:	08a080e7          	jalr	138(ra) # 800030d0 <fetchaddr>
    8000604e:	02054a63          	bltz	a0,80006082 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80006052:	e3043783          	ld	a5,-464(s0)
    80006056:	c3b9                	beqz	a5,8000609c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80006058:	ffffb097          	auipc	ra,0xffffb
    8000605c:	a9e080e7          	jalr	-1378(ra) # 80000af6 <kalloc>
    80006060:	85aa                	mv	a1,a0
    80006062:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006066:	cd11                	beqz	a0,80006082 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006068:	6605                	lui	a2,0x1
    8000606a:	e3043503          	ld	a0,-464(s0)
    8000606e:	ffffd097          	auipc	ra,0xffffd
    80006072:	0b4080e7          	jalr	180(ra) # 80003122 <fetchstr>
    80006076:	00054663          	bltz	a0,80006082 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    8000607a:	0905                	addi	s2,s2,1
    8000607c:	09a1                	addi	s3,s3,8
    8000607e:	fb491be3          	bne	s2,s4,80006034 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006082:	10048913          	addi	s2,s1,256
    80006086:	6088                	ld	a0,0(s1)
    80006088:	c529                	beqz	a0,800060d2 <sys_exec+0xf8>
    kfree(argv[i]);
    8000608a:	ffffb097          	auipc	ra,0xffffb
    8000608e:	970080e7          	jalr	-1680(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006092:	04a1                	addi	s1,s1,8
    80006094:	ff2499e3          	bne	s1,s2,80006086 <sys_exec+0xac>
  return -1;
    80006098:	597d                	li	s2,-1
    8000609a:	a82d                	j	800060d4 <sys_exec+0xfa>
      argv[i] = 0;
    8000609c:	0a8e                	slli	s5,s5,0x3
    8000609e:	fc040793          	addi	a5,s0,-64
    800060a2:	9abe                	add	s5,s5,a5
    800060a4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800060a8:	e4040593          	addi	a1,s0,-448
    800060ac:	f4040513          	addi	a0,s0,-192
    800060b0:	fffff097          	auipc	ra,0xfffff
    800060b4:	194080e7          	jalr	404(ra) # 80005244 <exec>
    800060b8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060ba:	10048993          	addi	s3,s1,256
    800060be:	6088                	ld	a0,0(s1)
    800060c0:	c911                	beqz	a0,800060d4 <sys_exec+0xfa>
    kfree(argv[i]);
    800060c2:	ffffb097          	auipc	ra,0xffffb
    800060c6:	938080e7          	jalr	-1736(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060ca:	04a1                	addi	s1,s1,8
    800060cc:	ff3499e3          	bne	s1,s3,800060be <sys_exec+0xe4>
    800060d0:	a011                	j	800060d4 <sys_exec+0xfa>
  return -1;
    800060d2:	597d                	li	s2,-1
}
    800060d4:	854a                	mv	a0,s2
    800060d6:	60be                	ld	ra,456(sp)
    800060d8:	641e                	ld	s0,448(sp)
    800060da:	74fa                	ld	s1,440(sp)
    800060dc:	795a                	ld	s2,432(sp)
    800060de:	79ba                	ld	s3,424(sp)
    800060e0:	7a1a                	ld	s4,416(sp)
    800060e2:	6afa                	ld	s5,408(sp)
    800060e4:	6179                	addi	sp,sp,464
    800060e6:	8082                	ret

00000000800060e8 <sys_pipe>:

uint64
sys_pipe(void)
{
    800060e8:	7139                	addi	sp,sp,-64
    800060ea:	fc06                	sd	ra,56(sp)
    800060ec:	f822                	sd	s0,48(sp)
    800060ee:	f426                	sd	s1,40(sp)
    800060f0:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800060f2:	ffffc097          	auipc	ra,0xffffc
    800060f6:	910080e7          	jalr	-1776(ra) # 80001a02 <myproc>
    800060fa:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    800060fc:	fd840593          	addi	a1,s0,-40
    80006100:	4501                	li	a0,0
    80006102:	ffffd097          	auipc	ra,0xffffd
    80006106:	08a080e7          	jalr	138(ra) # 8000318c <argaddr>
    return -1;
    8000610a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000610c:	0e054063          	bltz	a0,800061ec <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006110:	fc840593          	addi	a1,s0,-56
    80006114:	fd040513          	addi	a0,s0,-48
    80006118:	fffff097          	auipc	ra,0xfffff
    8000611c:	df8080e7          	jalr	-520(ra) # 80004f10 <pipealloc>
    return -1;
    80006120:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006122:	0c054563          	bltz	a0,800061ec <sys_pipe+0x104>
  fd0 = -1;
    80006126:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000612a:	fd043503          	ld	a0,-48(s0)
    8000612e:	fffff097          	auipc	ra,0xfffff
    80006132:	508080e7          	jalr	1288(ra) # 80005636 <fdalloc>
    80006136:	fca42223          	sw	a0,-60(s0)
    8000613a:	08054c63          	bltz	a0,800061d2 <sys_pipe+0xea>
    8000613e:	fc843503          	ld	a0,-56(s0)
    80006142:	fffff097          	auipc	ra,0xfffff
    80006146:	4f4080e7          	jalr	1268(ra) # 80005636 <fdalloc>
    8000614a:	fca42023          	sw	a0,-64(s0)
    8000614e:	06054863          	bltz	a0,800061be <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006152:	4691                	li	a3,4
    80006154:	fc440613          	addi	a2,s0,-60
    80006158:	fd843583          	ld	a1,-40(s0)
    8000615c:	68a8                	ld	a0,80(s1)
    8000615e:	ffffb097          	auipc	ra,0xffffb
    80006162:	516080e7          	jalr	1302(ra) # 80001674 <copyout>
    80006166:	02054063          	bltz	a0,80006186 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000616a:	4691                	li	a3,4
    8000616c:	fc040613          	addi	a2,s0,-64
    80006170:	fd843583          	ld	a1,-40(s0)
    80006174:	0591                	addi	a1,a1,4
    80006176:	68a8                	ld	a0,80(s1)
    80006178:	ffffb097          	auipc	ra,0xffffb
    8000617c:	4fc080e7          	jalr	1276(ra) # 80001674 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006180:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006182:	06055563          	bgez	a0,800061ec <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006186:	fc442783          	lw	a5,-60(s0)
    8000618a:	07e9                	addi	a5,a5,26
    8000618c:	078e                	slli	a5,a5,0x3
    8000618e:	97a6                	add	a5,a5,s1
    80006190:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006194:	fc042503          	lw	a0,-64(s0)
    80006198:	0569                	addi	a0,a0,26
    8000619a:	050e                	slli	a0,a0,0x3
    8000619c:	9526                	add	a0,a0,s1
    8000619e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800061a2:	fd043503          	ld	a0,-48(s0)
    800061a6:	fffff097          	auipc	ra,0xfffff
    800061aa:	a3a080e7          	jalr	-1478(ra) # 80004be0 <fileclose>
    fileclose(wf);
    800061ae:	fc843503          	ld	a0,-56(s0)
    800061b2:	fffff097          	auipc	ra,0xfffff
    800061b6:	a2e080e7          	jalr	-1490(ra) # 80004be0 <fileclose>
    return -1;
    800061ba:	57fd                	li	a5,-1
    800061bc:	a805                	j	800061ec <sys_pipe+0x104>
    if(fd0 >= 0)
    800061be:	fc442783          	lw	a5,-60(s0)
    800061c2:	0007c863          	bltz	a5,800061d2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    800061c6:	01a78513          	addi	a0,a5,26
    800061ca:	050e                	slli	a0,a0,0x3
    800061cc:	9526                	add	a0,a0,s1
    800061ce:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    800061d2:	fd043503          	ld	a0,-48(s0)
    800061d6:	fffff097          	auipc	ra,0xfffff
    800061da:	a0a080e7          	jalr	-1526(ra) # 80004be0 <fileclose>
    fileclose(wf);
    800061de:	fc843503          	ld	a0,-56(s0)
    800061e2:	fffff097          	auipc	ra,0xfffff
    800061e6:	9fe080e7          	jalr	-1538(ra) # 80004be0 <fileclose>
    return -1;
    800061ea:	57fd                	li	a5,-1
}
    800061ec:	853e                	mv	a0,a5
    800061ee:	70e2                	ld	ra,56(sp)
    800061f0:	7442                	ld	s0,48(sp)
    800061f2:	74a2                	ld	s1,40(sp)
    800061f4:	6121                	addi	sp,sp,64
    800061f6:	8082                	ret
	...

0000000080006200 <kernelvec>:
    80006200:	7111                	addi	sp,sp,-256
    80006202:	e006                	sd	ra,0(sp)
    80006204:	e40a                	sd	sp,8(sp)
    80006206:	e80e                	sd	gp,16(sp)
    80006208:	ec12                	sd	tp,24(sp)
    8000620a:	f016                	sd	t0,32(sp)
    8000620c:	f41a                	sd	t1,40(sp)
    8000620e:	f81e                	sd	t2,48(sp)
    80006210:	fc22                	sd	s0,56(sp)
    80006212:	e0a6                	sd	s1,64(sp)
    80006214:	e4aa                	sd	a0,72(sp)
    80006216:	e8ae                	sd	a1,80(sp)
    80006218:	ecb2                	sd	a2,88(sp)
    8000621a:	f0b6                	sd	a3,96(sp)
    8000621c:	f4ba                	sd	a4,104(sp)
    8000621e:	f8be                	sd	a5,112(sp)
    80006220:	fcc2                	sd	a6,120(sp)
    80006222:	e146                	sd	a7,128(sp)
    80006224:	e54a                	sd	s2,136(sp)
    80006226:	e94e                	sd	s3,144(sp)
    80006228:	ed52                	sd	s4,152(sp)
    8000622a:	f156                	sd	s5,160(sp)
    8000622c:	f55a                	sd	s6,168(sp)
    8000622e:	f95e                	sd	s7,176(sp)
    80006230:	fd62                	sd	s8,184(sp)
    80006232:	e1e6                	sd	s9,192(sp)
    80006234:	e5ea                	sd	s10,200(sp)
    80006236:	e9ee                	sd	s11,208(sp)
    80006238:	edf2                	sd	t3,216(sp)
    8000623a:	f1f6                	sd	t4,224(sp)
    8000623c:	f5fa                	sd	t5,232(sp)
    8000623e:	f9fe                	sd	t6,240(sp)
    80006240:	d5bfc0ef          	jal	ra,80002f9a <kerneltrap>
    80006244:	6082                	ld	ra,0(sp)
    80006246:	6122                	ld	sp,8(sp)
    80006248:	61c2                	ld	gp,16(sp)
    8000624a:	7282                	ld	t0,32(sp)
    8000624c:	7322                	ld	t1,40(sp)
    8000624e:	73c2                	ld	t2,48(sp)
    80006250:	7462                	ld	s0,56(sp)
    80006252:	6486                	ld	s1,64(sp)
    80006254:	6526                	ld	a0,72(sp)
    80006256:	65c6                	ld	a1,80(sp)
    80006258:	6666                	ld	a2,88(sp)
    8000625a:	7686                	ld	a3,96(sp)
    8000625c:	7726                	ld	a4,104(sp)
    8000625e:	77c6                	ld	a5,112(sp)
    80006260:	7866                	ld	a6,120(sp)
    80006262:	688a                	ld	a7,128(sp)
    80006264:	692a                	ld	s2,136(sp)
    80006266:	69ca                	ld	s3,144(sp)
    80006268:	6a6a                	ld	s4,152(sp)
    8000626a:	7a8a                	ld	s5,160(sp)
    8000626c:	7b2a                	ld	s6,168(sp)
    8000626e:	7bca                	ld	s7,176(sp)
    80006270:	7c6a                	ld	s8,184(sp)
    80006272:	6c8e                	ld	s9,192(sp)
    80006274:	6d2e                	ld	s10,200(sp)
    80006276:	6dce                	ld	s11,208(sp)
    80006278:	6e6e                	ld	t3,216(sp)
    8000627a:	7e8e                	ld	t4,224(sp)
    8000627c:	7f2e                	ld	t5,232(sp)
    8000627e:	7fce                	ld	t6,240(sp)
    80006280:	6111                	addi	sp,sp,256
    80006282:	10200073          	sret
    80006286:	00000013          	nop
    8000628a:	00000013          	nop
    8000628e:	0001                	nop

0000000080006290 <timervec>:
    80006290:	34051573          	csrrw	a0,mscratch,a0
    80006294:	e10c                	sd	a1,0(a0)
    80006296:	e510                	sd	a2,8(a0)
    80006298:	e914                	sd	a3,16(a0)
    8000629a:	6d0c                	ld	a1,24(a0)
    8000629c:	7110                	ld	a2,32(a0)
    8000629e:	6194                	ld	a3,0(a1)
    800062a0:	96b2                	add	a3,a3,a2
    800062a2:	e194                	sd	a3,0(a1)
    800062a4:	4589                	li	a1,2
    800062a6:	14459073          	csrw	sip,a1
    800062aa:	6914                	ld	a3,16(a0)
    800062ac:	6510                	ld	a2,8(a0)
    800062ae:	610c                	ld	a1,0(a0)
    800062b0:	34051573          	csrrw	a0,mscratch,a0
    800062b4:	30200073          	mret
	...

00000000800062ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062ba:	1141                	addi	sp,sp,-16
    800062bc:	e422                	sd	s0,8(sp)
    800062be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062c0:	0c0007b7          	lui	a5,0xc000
    800062c4:	4705                	li	a4,1
    800062c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062c8:	c3d8                	sw	a4,4(a5)
}
    800062ca:	6422                	ld	s0,8(sp)
    800062cc:	0141                	addi	sp,sp,16
    800062ce:	8082                	ret

00000000800062d0 <plicinithart>:

void
plicinithart(void)
{
    800062d0:	1141                	addi	sp,sp,-16
    800062d2:	e406                	sd	ra,8(sp)
    800062d4:	e022                	sd	s0,0(sp)
    800062d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062d8:	ffffb097          	auipc	ra,0xffffb
    800062dc:	6fe080e7          	jalr	1790(ra) # 800019d6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062e0:	0085171b          	slliw	a4,a0,0x8
    800062e4:	0c0027b7          	lui	a5,0xc002
    800062e8:	97ba                	add	a5,a5,a4
    800062ea:	40200713          	li	a4,1026
    800062ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062f2:	00d5151b          	slliw	a0,a0,0xd
    800062f6:	0c2017b7          	lui	a5,0xc201
    800062fa:	953e                	add	a0,a0,a5
    800062fc:	00052023          	sw	zero,0(a0)
}
    80006300:	60a2                	ld	ra,8(sp)
    80006302:	6402                	ld	s0,0(sp)
    80006304:	0141                	addi	sp,sp,16
    80006306:	8082                	ret

0000000080006308 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006308:	1141                	addi	sp,sp,-16
    8000630a:	e406                	sd	ra,8(sp)
    8000630c:	e022                	sd	s0,0(sp)
    8000630e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006310:	ffffb097          	auipc	ra,0xffffb
    80006314:	6c6080e7          	jalr	1734(ra) # 800019d6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006318:	00d5179b          	slliw	a5,a0,0xd
    8000631c:	0c201537          	lui	a0,0xc201
    80006320:	953e                	add	a0,a0,a5
  return irq;
}
    80006322:	4148                	lw	a0,4(a0)
    80006324:	60a2                	ld	ra,8(sp)
    80006326:	6402                	ld	s0,0(sp)
    80006328:	0141                	addi	sp,sp,16
    8000632a:	8082                	ret

000000008000632c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000632c:	1101                	addi	sp,sp,-32
    8000632e:	ec06                	sd	ra,24(sp)
    80006330:	e822                	sd	s0,16(sp)
    80006332:	e426                	sd	s1,8(sp)
    80006334:	1000                	addi	s0,sp,32
    80006336:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006338:	ffffb097          	auipc	ra,0xffffb
    8000633c:	69e080e7          	jalr	1694(ra) # 800019d6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006340:	00d5151b          	slliw	a0,a0,0xd
    80006344:	0c2017b7          	lui	a5,0xc201
    80006348:	97aa                	add	a5,a5,a0
    8000634a:	c3c4                	sw	s1,4(a5)
}
    8000634c:	60e2                	ld	ra,24(sp)
    8000634e:	6442                	ld	s0,16(sp)
    80006350:	64a2                	ld	s1,8(sp)
    80006352:	6105                	addi	sp,sp,32
    80006354:	8082                	ret

0000000080006356 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006356:	1141                	addi	sp,sp,-16
    80006358:	e406                	sd	ra,8(sp)
    8000635a:	e022                	sd	s0,0(sp)
    8000635c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000635e:	479d                	li	a5,7
    80006360:	06a7c963          	blt	a5,a0,800063d2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006364:	0001d797          	auipc	a5,0x1d
    80006368:	c9c78793          	addi	a5,a5,-868 # 80023000 <disk>
    8000636c:	00a78733          	add	a4,a5,a0
    80006370:	6789                	lui	a5,0x2
    80006372:	97ba                	add	a5,a5,a4
    80006374:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006378:	e7ad                	bnez	a5,800063e2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000637a:	00451793          	slli	a5,a0,0x4
    8000637e:	0001f717          	auipc	a4,0x1f
    80006382:	c8270713          	addi	a4,a4,-894 # 80025000 <disk+0x2000>
    80006386:	6314                	ld	a3,0(a4)
    80006388:	96be                	add	a3,a3,a5
    8000638a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000638e:	6314                	ld	a3,0(a4)
    80006390:	96be                	add	a3,a3,a5
    80006392:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006396:	6314                	ld	a3,0(a4)
    80006398:	96be                	add	a3,a3,a5
    8000639a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000639e:	6318                	ld	a4,0(a4)
    800063a0:	97ba                	add	a5,a5,a4
    800063a2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800063a6:	0001d797          	auipc	a5,0x1d
    800063aa:	c5a78793          	addi	a5,a5,-934 # 80023000 <disk>
    800063ae:	97aa                	add	a5,a5,a0
    800063b0:	6509                	lui	a0,0x2
    800063b2:	953e                	add	a0,a0,a5
    800063b4:	4785                	li	a5,1
    800063b6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800063ba:	0001f517          	auipc	a0,0x1f
    800063be:	c5e50513          	addi	a0,a0,-930 # 80025018 <disk+0x2018>
    800063c2:	ffffc097          	auipc	ra,0xffffc
    800063c6:	118080e7          	jalr	280(ra) # 800024da <wakeup>
}
    800063ca:	60a2                	ld	ra,8(sp)
    800063cc:	6402                	ld	s0,0(sp)
    800063ce:	0141                	addi	sp,sp,16
    800063d0:	8082                	ret
    panic("free_desc 1");
    800063d2:	00002517          	auipc	a0,0x2
    800063d6:	50650513          	addi	a0,a0,1286 # 800088d8 <syscalls+0x338>
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	166080e7          	jalr	358(ra) # 80000540 <panic>
    panic("free_desc 2");
    800063e2:	00002517          	auipc	a0,0x2
    800063e6:	50650513          	addi	a0,a0,1286 # 800088e8 <syscalls+0x348>
    800063ea:	ffffa097          	auipc	ra,0xffffa
    800063ee:	156080e7          	jalr	342(ra) # 80000540 <panic>

00000000800063f2 <virtio_disk_init>:
{
    800063f2:	1101                	addi	sp,sp,-32
    800063f4:	ec06                	sd	ra,24(sp)
    800063f6:	e822                	sd	s0,16(sp)
    800063f8:	e426                	sd	s1,8(sp)
    800063fa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063fc:	00002597          	auipc	a1,0x2
    80006400:	4fc58593          	addi	a1,a1,1276 # 800088f8 <syscalls+0x358>
    80006404:	0001f517          	auipc	a0,0x1f
    80006408:	d2450513          	addi	a0,a0,-732 # 80025128 <disk+0x2128>
    8000640c:	ffffa097          	auipc	ra,0xffffa
    80006410:	74a080e7          	jalr	1866(ra) # 80000b56 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006414:	100017b7          	lui	a5,0x10001
    80006418:	4398                	lw	a4,0(a5)
    8000641a:	2701                	sext.w	a4,a4
    8000641c:	747277b7          	lui	a5,0x74727
    80006420:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006424:	0ef71163          	bne	a4,a5,80006506 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006428:	100017b7          	lui	a5,0x10001
    8000642c:	43dc                	lw	a5,4(a5)
    8000642e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006430:	4705                	li	a4,1
    80006432:	0ce79a63          	bne	a5,a4,80006506 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006436:	100017b7          	lui	a5,0x10001
    8000643a:	479c                	lw	a5,8(a5)
    8000643c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000643e:	4709                	li	a4,2
    80006440:	0ce79363          	bne	a5,a4,80006506 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006444:	100017b7          	lui	a5,0x10001
    80006448:	47d8                	lw	a4,12(a5)
    8000644a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000644c:	554d47b7          	lui	a5,0x554d4
    80006450:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006454:	0af71963          	bne	a4,a5,80006506 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006458:	100017b7          	lui	a5,0x10001
    8000645c:	4705                	li	a4,1
    8000645e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006460:	470d                	li	a4,3
    80006462:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006464:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006466:	c7ffe737          	lui	a4,0xc7ffe
    8000646a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000646e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006470:	2701                	sext.w	a4,a4
    80006472:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006474:	472d                	li	a4,11
    80006476:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006478:	473d                	li	a4,15
    8000647a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000647c:	6705                	lui	a4,0x1
    8000647e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006480:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006484:	5bdc                	lw	a5,52(a5)
    80006486:	2781                	sext.w	a5,a5
  if(max == 0)
    80006488:	c7d9                	beqz	a5,80006516 <virtio_disk_init+0x124>
  if(max < NUM)
    8000648a:	471d                	li	a4,7
    8000648c:	08f77d63          	bgeu	a4,a5,80006526 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006490:	100014b7          	lui	s1,0x10001
    80006494:	47a1                	li	a5,8
    80006496:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006498:	6609                	lui	a2,0x2
    8000649a:	4581                	li	a1,0
    8000649c:	0001d517          	auipc	a0,0x1d
    800064a0:	b6450513          	addi	a0,a0,-1180 # 80023000 <disk>
    800064a4:	ffffb097          	auipc	ra,0xffffb
    800064a8:	83e080e7          	jalr	-1986(ra) # 80000ce2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800064ac:	0001d717          	auipc	a4,0x1d
    800064b0:	b5470713          	addi	a4,a4,-1196 # 80023000 <disk>
    800064b4:	00c75793          	srli	a5,a4,0xc
    800064b8:	2781                	sext.w	a5,a5
    800064ba:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800064bc:	0001f797          	auipc	a5,0x1f
    800064c0:	b4478793          	addi	a5,a5,-1212 # 80025000 <disk+0x2000>
    800064c4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800064c6:	0001d717          	auipc	a4,0x1d
    800064ca:	bba70713          	addi	a4,a4,-1094 # 80023080 <disk+0x80>
    800064ce:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800064d0:	0001e717          	auipc	a4,0x1e
    800064d4:	b3070713          	addi	a4,a4,-1232 # 80024000 <disk+0x1000>
    800064d8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800064da:	4705                	li	a4,1
    800064dc:	00e78c23          	sb	a4,24(a5)
    800064e0:	00e78ca3          	sb	a4,25(a5)
    800064e4:	00e78d23          	sb	a4,26(a5)
    800064e8:	00e78da3          	sb	a4,27(a5)
    800064ec:	00e78e23          	sb	a4,28(a5)
    800064f0:	00e78ea3          	sb	a4,29(a5)
    800064f4:	00e78f23          	sb	a4,30(a5)
    800064f8:	00e78fa3          	sb	a4,31(a5)
}
    800064fc:	60e2                	ld	ra,24(sp)
    800064fe:	6442                	ld	s0,16(sp)
    80006500:	64a2                	ld	s1,8(sp)
    80006502:	6105                	addi	sp,sp,32
    80006504:	8082                	ret
    panic("could not find virtio disk");
    80006506:	00002517          	auipc	a0,0x2
    8000650a:	40250513          	addi	a0,a0,1026 # 80008908 <syscalls+0x368>
    8000650e:	ffffa097          	auipc	ra,0xffffa
    80006512:	032080e7          	jalr	50(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006516:	00002517          	auipc	a0,0x2
    8000651a:	41250513          	addi	a0,a0,1042 # 80008928 <syscalls+0x388>
    8000651e:	ffffa097          	auipc	ra,0xffffa
    80006522:	022080e7          	jalr	34(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006526:	00002517          	auipc	a0,0x2
    8000652a:	42250513          	addi	a0,a0,1058 # 80008948 <syscalls+0x3a8>
    8000652e:	ffffa097          	auipc	ra,0xffffa
    80006532:	012080e7          	jalr	18(ra) # 80000540 <panic>

0000000080006536 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006536:	7159                	addi	sp,sp,-112
    80006538:	f486                	sd	ra,104(sp)
    8000653a:	f0a2                	sd	s0,96(sp)
    8000653c:	eca6                	sd	s1,88(sp)
    8000653e:	e8ca                	sd	s2,80(sp)
    80006540:	e4ce                	sd	s3,72(sp)
    80006542:	e0d2                	sd	s4,64(sp)
    80006544:	fc56                	sd	s5,56(sp)
    80006546:	f85a                	sd	s6,48(sp)
    80006548:	f45e                	sd	s7,40(sp)
    8000654a:	f062                	sd	s8,32(sp)
    8000654c:	ec66                	sd	s9,24(sp)
    8000654e:	e86a                	sd	s10,16(sp)
    80006550:	1880                	addi	s0,sp,112
    80006552:	892a                	mv	s2,a0
    80006554:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006556:	00c52c83          	lw	s9,12(a0)
    8000655a:	001c9c9b          	slliw	s9,s9,0x1
    8000655e:	1c82                	slli	s9,s9,0x20
    80006560:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006564:	0001f517          	auipc	a0,0x1f
    80006568:	bc450513          	addi	a0,a0,-1084 # 80025128 <disk+0x2128>
    8000656c:	ffffa097          	auipc	ra,0xffffa
    80006570:	67a080e7          	jalr	1658(ra) # 80000be6 <acquire>
  for(int i = 0; i < 3; i++){
    80006574:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006576:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006578:	0001db97          	auipc	s7,0x1d
    8000657c:	a88b8b93          	addi	s7,s7,-1400 # 80023000 <disk>
    80006580:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006582:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006584:	8a4e                	mv	s4,s3
    80006586:	a051                	j	8000660a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006588:	00fb86b3          	add	a3,s7,a5
    8000658c:	96da                	add	a3,a3,s6
    8000658e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006592:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006594:	0207c563          	bltz	a5,800065be <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006598:	2485                	addiw	s1,s1,1
    8000659a:	0711                	addi	a4,a4,4
    8000659c:	25548063          	beq	s1,s5,800067dc <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800065a0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800065a2:	0001f697          	auipc	a3,0x1f
    800065a6:	a7668693          	addi	a3,a3,-1418 # 80025018 <disk+0x2018>
    800065aa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800065ac:	0006c583          	lbu	a1,0(a3)
    800065b0:	fde1                	bnez	a1,80006588 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800065b2:	2785                	addiw	a5,a5,1
    800065b4:	0685                	addi	a3,a3,1
    800065b6:	ff879be3          	bne	a5,s8,800065ac <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800065ba:	57fd                	li	a5,-1
    800065bc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800065be:	02905a63          	blez	s1,800065f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065c2:	f9042503          	lw	a0,-112(s0)
    800065c6:	00000097          	auipc	ra,0x0
    800065ca:	d90080e7          	jalr	-624(ra) # 80006356 <free_desc>
      for(int j = 0; j < i; j++)
    800065ce:	4785                	li	a5,1
    800065d0:	0297d163          	bge	a5,s1,800065f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065d4:	f9442503          	lw	a0,-108(s0)
    800065d8:	00000097          	auipc	ra,0x0
    800065dc:	d7e080e7          	jalr	-642(ra) # 80006356 <free_desc>
      for(int j = 0; j < i; j++)
    800065e0:	4789                	li	a5,2
    800065e2:	0097d863          	bge	a5,s1,800065f2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800065e6:	f9842503          	lw	a0,-104(s0)
    800065ea:	00000097          	auipc	ra,0x0
    800065ee:	d6c080e7          	jalr	-660(ra) # 80006356 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065f2:	0001f597          	auipc	a1,0x1f
    800065f6:	b3658593          	addi	a1,a1,-1226 # 80025128 <disk+0x2128>
    800065fa:	0001f517          	auipc	a0,0x1f
    800065fe:	a1e50513          	addi	a0,a0,-1506 # 80025018 <disk+0x2018>
    80006602:	ffffc097          	auipc	ra,0xffffc
    80006606:	cf2080e7          	jalr	-782(ra) # 800022f4 <sleep>
  for(int i = 0; i < 3; i++){
    8000660a:	f9040713          	addi	a4,s0,-112
    8000660e:	84ce                	mv	s1,s3
    80006610:	bf41                	j	800065a0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006612:	20058713          	addi	a4,a1,512
    80006616:	00471693          	slli	a3,a4,0x4
    8000661a:	0001d717          	auipc	a4,0x1d
    8000661e:	9e670713          	addi	a4,a4,-1562 # 80023000 <disk>
    80006622:	9736                	add	a4,a4,a3
    80006624:	4685                	li	a3,1
    80006626:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000662a:	20058713          	addi	a4,a1,512
    8000662e:	00471693          	slli	a3,a4,0x4
    80006632:	0001d717          	auipc	a4,0x1d
    80006636:	9ce70713          	addi	a4,a4,-1586 # 80023000 <disk>
    8000663a:	9736                	add	a4,a4,a3
    8000663c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006640:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006644:	7679                	lui	a2,0xffffe
    80006646:	963e                	add	a2,a2,a5
    80006648:	0001f697          	auipc	a3,0x1f
    8000664c:	9b868693          	addi	a3,a3,-1608 # 80025000 <disk+0x2000>
    80006650:	6298                	ld	a4,0(a3)
    80006652:	9732                	add	a4,a4,a2
    80006654:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006656:	6298                	ld	a4,0(a3)
    80006658:	9732                	add	a4,a4,a2
    8000665a:	4541                	li	a0,16
    8000665c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000665e:	6298                	ld	a4,0(a3)
    80006660:	9732                	add	a4,a4,a2
    80006662:	4505                	li	a0,1
    80006664:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006668:	f9442703          	lw	a4,-108(s0)
    8000666c:	6288                	ld	a0,0(a3)
    8000666e:	962a                	add	a2,a2,a0
    80006670:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006674:	0712                	slli	a4,a4,0x4
    80006676:	6290                	ld	a2,0(a3)
    80006678:	963a                	add	a2,a2,a4
    8000667a:	05890513          	addi	a0,s2,88
    8000667e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006680:	6294                	ld	a3,0(a3)
    80006682:	96ba                	add	a3,a3,a4
    80006684:	40000613          	li	a2,1024
    80006688:	c690                	sw	a2,8(a3)
  if(write)
    8000668a:	140d0063          	beqz	s10,800067ca <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000668e:	0001f697          	auipc	a3,0x1f
    80006692:	9726b683          	ld	a3,-1678(a3) # 80025000 <disk+0x2000>
    80006696:	96ba                	add	a3,a3,a4
    80006698:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000669c:	0001d817          	auipc	a6,0x1d
    800066a0:	96480813          	addi	a6,a6,-1692 # 80023000 <disk>
    800066a4:	0001f517          	auipc	a0,0x1f
    800066a8:	95c50513          	addi	a0,a0,-1700 # 80025000 <disk+0x2000>
    800066ac:	6114                	ld	a3,0(a0)
    800066ae:	96ba                	add	a3,a3,a4
    800066b0:	00c6d603          	lhu	a2,12(a3)
    800066b4:	00166613          	ori	a2,a2,1
    800066b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800066bc:	f9842683          	lw	a3,-104(s0)
    800066c0:	6110                	ld	a2,0(a0)
    800066c2:	9732                	add	a4,a4,a2
    800066c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800066c8:	20058613          	addi	a2,a1,512
    800066cc:	0612                	slli	a2,a2,0x4
    800066ce:	9642                	add	a2,a2,a6
    800066d0:	577d                	li	a4,-1
    800066d2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066d6:	00469713          	slli	a4,a3,0x4
    800066da:	6114                	ld	a3,0(a0)
    800066dc:	96ba                	add	a3,a3,a4
    800066de:	03078793          	addi	a5,a5,48
    800066e2:	97c2                	add	a5,a5,a6
    800066e4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800066e6:	611c                	ld	a5,0(a0)
    800066e8:	97ba                	add	a5,a5,a4
    800066ea:	4685                	li	a3,1
    800066ec:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066ee:	611c                	ld	a5,0(a0)
    800066f0:	97ba                	add	a5,a5,a4
    800066f2:	4809                	li	a6,2
    800066f4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800066f8:	611c                	ld	a5,0(a0)
    800066fa:	973e                	add	a4,a4,a5
    800066fc:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006700:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006704:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006708:	6518                	ld	a4,8(a0)
    8000670a:	00275783          	lhu	a5,2(a4)
    8000670e:	8b9d                	andi	a5,a5,7
    80006710:	0786                	slli	a5,a5,0x1
    80006712:	97ba                	add	a5,a5,a4
    80006714:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006718:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000671c:	6518                	ld	a4,8(a0)
    8000671e:	00275783          	lhu	a5,2(a4)
    80006722:	2785                	addiw	a5,a5,1
    80006724:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006728:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000672c:	100017b7          	lui	a5,0x10001
    80006730:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006734:	00492703          	lw	a4,4(s2)
    80006738:	4785                	li	a5,1
    8000673a:	02f71163          	bne	a4,a5,8000675c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000673e:	0001f997          	auipc	s3,0x1f
    80006742:	9ea98993          	addi	s3,s3,-1558 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006746:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006748:	85ce                	mv	a1,s3
    8000674a:	854a                	mv	a0,s2
    8000674c:	ffffc097          	auipc	ra,0xffffc
    80006750:	ba8080e7          	jalr	-1112(ra) # 800022f4 <sleep>
  while(b->disk == 1) {
    80006754:	00492783          	lw	a5,4(s2)
    80006758:	fe9788e3          	beq	a5,s1,80006748 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000675c:	f9042903          	lw	s2,-112(s0)
    80006760:	20090793          	addi	a5,s2,512
    80006764:	00479713          	slli	a4,a5,0x4
    80006768:	0001d797          	auipc	a5,0x1d
    8000676c:	89878793          	addi	a5,a5,-1896 # 80023000 <disk>
    80006770:	97ba                	add	a5,a5,a4
    80006772:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006776:	0001f997          	auipc	s3,0x1f
    8000677a:	88a98993          	addi	s3,s3,-1910 # 80025000 <disk+0x2000>
    8000677e:	00491713          	slli	a4,s2,0x4
    80006782:	0009b783          	ld	a5,0(s3)
    80006786:	97ba                	add	a5,a5,a4
    80006788:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000678c:	854a                	mv	a0,s2
    8000678e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006792:	00000097          	auipc	ra,0x0
    80006796:	bc4080e7          	jalr	-1084(ra) # 80006356 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000679a:	8885                	andi	s1,s1,1
    8000679c:	f0ed                	bnez	s1,8000677e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000679e:	0001f517          	auipc	a0,0x1f
    800067a2:	98a50513          	addi	a0,a0,-1654 # 80025128 <disk+0x2128>
    800067a6:	ffffa097          	auipc	ra,0xffffa
    800067aa:	4f4080e7          	jalr	1268(ra) # 80000c9a <release>
}
    800067ae:	70a6                	ld	ra,104(sp)
    800067b0:	7406                	ld	s0,96(sp)
    800067b2:	64e6                	ld	s1,88(sp)
    800067b4:	6946                	ld	s2,80(sp)
    800067b6:	69a6                	ld	s3,72(sp)
    800067b8:	6a06                	ld	s4,64(sp)
    800067ba:	7ae2                	ld	s5,56(sp)
    800067bc:	7b42                	ld	s6,48(sp)
    800067be:	7ba2                	ld	s7,40(sp)
    800067c0:	7c02                	ld	s8,32(sp)
    800067c2:	6ce2                	ld	s9,24(sp)
    800067c4:	6d42                	ld	s10,16(sp)
    800067c6:	6165                	addi	sp,sp,112
    800067c8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800067ca:	0001f697          	auipc	a3,0x1f
    800067ce:	8366b683          	ld	a3,-1994(a3) # 80025000 <disk+0x2000>
    800067d2:	96ba                	add	a3,a3,a4
    800067d4:	4609                	li	a2,2
    800067d6:	00c69623          	sh	a2,12(a3)
    800067da:	b5c9                	j	8000669c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067dc:	f9042583          	lw	a1,-112(s0)
    800067e0:	20058793          	addi	a5,a1,512
    800067e4:	0792                	slli	a5,a5,0x4
    800067e6:	0001d517          	auipc	a0,0x1d
    800067ea:	8c250513          	addi	a0,a0,-1854 # 800230a8 <disk+0xa8>
    800067ee:	953e                	add	a0,a0,a5
  if(write)
    800067f0:	e20d11e3          	bnez	s10,80006612 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800067f4:	20058713          	addi	a4,a1,512
    800067f8:	00471693          	slli	a3,a4,0x4
    800067fc:	0001d717          	auipc	a4,0x1d
    80006800:	80470713          	addi	a4,a4,-2044 # 80023000 <disk>
    80006804:	9736                	add	a4,a4,a3
    80006806:	0a072423          	sw	zero,168(a4)
    8000680a:	b505                	j	8000662a <virtio_disk_rw+0xf4>

000000008000680c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000680c:	1101                	addi	sp,sp,-32
    8000680e:	ec06                	sd	ra,24(sp)
    80006810:	e822                	sd	s0,16(sp)
    80006812:	e426                	sd	s1,8(sp)
    80006814:	e04a                	sd	s2,0(sp)
    80006816:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006818:	0001f517          	auipc	a0,0x1f
    8000681c:	91050513          	addi	a0,a0,-1776 # 80025128 <disk+0x2128>
    80006820:	ffffa097          	auipc	ra,0xffffa
    80006824:	3c6080e7          	jalr	966(ra) # 80000be6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006828:	10001737          	lui	a4,0x10001
    8000682c:	533c                	lw	a5,96(a4)
    8000682e:	8b8d                	andi	a5,a5,3
    80006830:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006832:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006836:	0001e797          	auipc	a5,0x1e
    8000683a:	7ca78793          	addi	a5,a5,1994 # 80025000 <disk+0x2000>
    8000683e:	6b94                	ld	a3,16(a5)
    80006840:	0207d703          	lhu	a4,32(a5)
    80006844:	0026d783          	lhu	a5,2(a3)
    80006848:	06f70163          	beq	a4,a5,800068aa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000684c:	0001c917          	auipc	s2,0x1c
    80006850:	7b490913          	addi	s2,s2,1972 # 80023000 <disk>
    80006854:	0001e497          	auipc	s1,0x1e
    80006858:	7ac48493          	addi	s1,s1,1964 # 80025000 <disk+0x2000>
    __sync_synchronize();
    8000685c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006860:	6898                	ld	a4,16(s1)
    80006862:	0204d783          	lhu	a5,32(s1)
    80006866:	8b9d                	andi	a5,a5,7
    80006868:	078e                	slli	a5,a5,0x3
    8000686a:	97ba                	add	a5,a5,a4
    8000686c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000686e:	20078713          	addi	a4,a5,512
    80006872:	0712                	slli	a4,a4,0x4
    80006874:	974a                	add	a4,a4,s2
    80006876:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000687a:	e731                	bnez	a4,800068c6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000687c:	20078793          	addi	a5,a5,512
    80006880:	0792                	slli	a5,a5,0x4
    80006882:	97ca                	add	a5,a5,s2
    80006884:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006886:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000688a:	ffffc097          	auipc	ra,0xffffc
    8000688e:	c50080e7          	jalr	-944(ra) # 800024da <wakeup>

    disk.used_idx += 1;
    80006892:	0204d783          	lhu	a5,32(s1)
    80006896:	2785                	addiw	a5,a5,1
    80006898:	17c2                	slli	a5,a5,0x30
    8000689a:	93c1                	srli	a5,a5,0x30
    8000689c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068a0:	6898                	ld	a4,16(s1)
    800068a2:	00275703          	lhu	a4,2(a4)
    800068a6:	faf71be3          	bne	a4,a5,8000685c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800068aa:	0001f517          	auipc	a0,0x1f
    800068ae:	87e50513          	addi	a0,a0,-1922 # 80025128 <disk+0x2128>
    800068b2:	ffffa097          	auipc	ra,0xffffa
    800068b6:	3e8080e7          	jalr	1000(ra) # 80000c9a <release>
}
    800068ba:	60e2                	ld	ra,24(sp)
    800068bc:	6442                	ld	s0,16(sp)
    800068be:	64a2                	ld	s1,8(sp)
    800068c0:	6902                	ld	s2,0(sp)
    800068c2:	6105                	addi	sp,sp,32
    800068c4:	8082                	ret
      panic("virtio_disk_intr status");
    800068c6:	00002517          	auipc	a0,0x2
    800068ca:	0a250513          	addi	a0,a0,162 # 80008968 <syscalls+0x3c8>
    800068ce:	ffffa097          	auipc	ra,0xffffa
    800068d2:	c72080e7          	jalr	-910(ra) # 80000540 <panic>
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
