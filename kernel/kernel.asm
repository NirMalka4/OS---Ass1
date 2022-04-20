
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	94013103          	ld	sp,-1728(sp) # 80008940 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
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
    80000068:	e9c78793          	addi	a5,a5,-356 # 80005f00 <timervec>
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
    80000130:	528080e7          	jalr	1320(ra) # 80002654 <either_copyin>
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
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a52080e7          	jalr	-1454(ra) # 80000be6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
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
    800001c4:	00001097          	auipc	ra,0x1
    800001c8:	7ee080e7          	jalr	2030(ra) # 800019b2 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	2781                	sext.w	a5,a5
    800001d0:	e7b5                	bnez	a5,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85ce                	mv	a1,s3
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	016080e7          	jalr	22(ra) # 800021ec <sleep>
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
    80000216:	3ec080e7          	jalr	1004(ra) # 800025fe <either_copyout>
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
    8000022a:	f5a50513          	addi	a0,a0,-166 # 80011180 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a6c080e7          	jalr	-1428(ra) # 80000c9a <release>

  return target - n;
    80000236:	414b853b          	subw	a0,s7,s4
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	f4450513          	addi	a0,a0,-188 # 80011180 <cons>
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
    80000278:	faf72223          	sw	a5,-92(a4) # 80011218 <cons+0x98>
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
    800002d2:	eb250513          	addi	a0,a0,-334 # 80011180 <cons>
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
    800002f8:	3b6080e7          	jalr	950(ra) # 800026aa <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fc:	00011517          	auipc	a0,0x11
    80000300:	e8450513          	addi	a0,a0,-380 # 80011180 <cons>
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
    80000324:	e6070713          	addi	a4,a4,-416 # 80011180 <cons>
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
    8000034e:	e3678793          	addi	a5,a5,-458 # 80011180 <cons>
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
    8000037c:	ea07a783          	lw	a5,-352(a5) # 80011218 <cons+0x98>
    80000380:	0807879b          	addiw	a5,a5,128
    80000384:	f6f61ce3          	bne	a2,a5,800002fc <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000388:	863e                	mv	a2,a5
    8000038a:	a07d                	j	80000438 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038c:	00011717          	auipc	a4,0x11
    80000390:	df470713          	addi	a4,a4,-524 # 80011180 <cons>
    80000394:	0a072783          	lw	a5,160(a4)
    80000398:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039c:	00011497          	auipc	s1,0x11
    800003a0:	de448493          	addi	s1,s1,-540 # 80011180 <cons>
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
    800003dc:	da870713          	addi	a4,a4,-600 # 80011180 <cons>
    800003e0:	0a072783          	lw	a5,160(a4)
    800003e4:	09c72703          	lw	a4,156(a4)
    800003e8:	f0f70ae3          	beq	a4,a5,800002fc <consoleintr+0x3c>
      cons.e--;
    800003ec:	37fd                	addiw	a5,a5,-1
    800003ee:	00011717          	auipc	a4,0x11
    800003f2:	e2f72923          	sw	a5,-462(a4) # 80011220 <cons+0xa0>
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
    80000418:	d6c78793          	addi	a5,a5,-660 # 80011180 <cons>
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
    8000043c:	dec7a223          	sw	a2,-540(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000440:	00011517          	auipc	a0,0x11
    80000444:	dd850513          	addi	a0,a0,-552 # 80011218 <cons+0x98>
    80000448:	00002097          	auipc	ra,0x2
    8000044c:	f34080e7          	jalr	-204(ra) # 8000237c <wakeup>
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
    80000466:	d1e50513          	addi	a0,a0,-738 # 80011180 <cons>
    8000046a:	00000097          	auipc	ra,0x0
    8000046e:	6ec080e7          	jalr	1772(ra) # 80000b56 <initlock>

  uartinit();
    80000472:	00000097          	auipc	ra,0x0
    80000476:	330080e7          	jalr	816(ra) # 800007a2 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047a:	00021797          	auipc	a5,0x21
    8000047e:	29e78793          	addi	a5,a5,670 # 80021718 <devsw>
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
    80000550:	ce07aa23          	sw	zero,-780(a5) # 80011240 <pr+0x18>
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
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
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
    800005c0:	c84dad83          	lw	s11,-892(s11) # 80011240 <pr+0x18>
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
    800005fe:	c2e50513          	addi	a0,a0,-978 # 80011228 <pr>
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
    80000762:	aca50513          	addi	a0,a0,-1334 # 80011228 <pr>
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
    8000077e:	aae48493          	addi	s1,s1,-1362 # 80011228 <pr>
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
    800007de:	a6e50513          	addi	a0,a0,-1426 # 80011248 <uart_tx_lock>
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
    80000870:	9dca0a13          	addi	s4,s4,-1572 # 80011248 <uart_tx_lock>
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
    800008a6:	ada080e7          	jalr	-1318(ra) # 8000237c <wakeup>
    
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
    800008e2:	96a50513          	addi	a0,a0,-1686 # 80011248 <uart_tx_lock>
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
    80000916:	936a0a13          	addi	s4,s4,-1738 # 80011248 <uart_tx_lock>
    8000091a:	00008497          	auipc	s1,0x8
    8000091e:	6ee48493          	addi	s1,s1,1774 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000922:	00008917          	auipc	s2,0x8
    80000926:	6ee90913          	addi	s2,s2,1774 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000092a:	85d2                	mv	a1,s4
    8000092c:	8526                	mv	a0,s1
    8000092e:	00002097          	auipc	ra,0x2
    80000932:	8be080e7          	jalr	-1858(ra) # 800021ec <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000936:	00093783          	ld	a5,0(s2)
    8000093a:	6098                	ld	a4,0(s1)
    8000093c:	02070713          	addi	a4,a4,32
    80000940:	fef705e3          	beq	a4,a5,8000092a <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000944:	00011497          	auipc	s1,0x11
    80000948:	90448493          	addi	s1,s1,-1788 # 80011248 <uart_tx_lock>
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
    800009d0:	87c48493          	addi	s1,s1,-1924 # 80011248 <uart_tx_lock>
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
    80000a32:	85290913          	addi	s2,s2,-1966 # 80011280 <kmem>
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
    80000ace:	7b650513          	addi	a0,a0,1974 # 80011280 <kmem>
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
    80000b04:	78048493          	addi	s1,s1,1920 # 80011280 <kmem>
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
    80000b1c:	76850513          	addi	a0,a0,1896 # 80011280 <kmem>
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
    80000b48:	73c50513          	addi	a0,a0,1852 # 80011280 <kmem>
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
    80000b84:	e16080e7          	jalr	-490(ra) # 80001996 <mycpu>
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
    80000bb6:	de4080e7          	jalr	-540(ra) # 80001996 <mycpu>
    80000bba:	5d3c                	lw	a5,120(a0)
    80000bbc:	cf89                	beqz	a5,80000bd6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbe:	00001097          	auipc	ra,0x1
    80000bc2:	dd8080e7          	jalr	-552(ra) # 80001996 <mycpu>
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
    80000bda:	dc0080e7          	jalr	-576(ra) # 80001996 <mycpu>
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
    80000c1a:	d80080e7          	jalr	-640(ra) # 80001996 <mycpu>
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
    80000c46:	d54080e7          	jalr	-684(ra) # 80001996 <mycpu>
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
    80000e9c:	aee080e7          	jalr	-1298(ra) # 80001986 <cpuid>
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
    80000eb8:	ad2080e7          	jalr	-1326(ra) # 80001986 <cpuid>
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
    80000eda:	ab2080e7          	jalr	-1358(ra) # 80002988 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ede:	00005097          	auipc	ra,0x5
    80000ee2:	062080e7          	jalr	98(ra) # 80005f40 <plicinithart>
  }

  scheduler();        
    80000ee6:	00001097          	auipc	ra,0x1
    80000eea:	040080e7          	jalr	64(ra) # 80001f26 <scheduler>
    consoleinit();
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	564080e7          	jalr	1380(ra) # 80000452 <consoleinit>
    printfinit();
    80000ef6:	00000097          	auipc	ra,0x0
    80000efa:	87a080e7          	jalr	-1926(ra) # 80000770 <printfinit>
    printf("\n");
    80000efe:	00007517          	auipc	a0,0x7
    80000f02:	1ca50513          	addi	a0,a0,458 # 800080c8 <digits+0x88>
    80000f06:	fffff097          	auipc	ra,0xfffff
    80000f0a:	684080e7          	jalr	1668(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000f0e:	00007517          	auipc	a0,0x7
    80000f12:	19250513          	addi	a0,a0,402 # 800080a0 <digits+0x60>
    80000f16:	fffff097          	auipc	ra,0xfffff
    80000f1a:	674080e7          	jalr	1652(ra) # 8000058a <printf>
    printf("\n");
    80000f1e:	00007517          	auipc	a0,0x7
    80000f22:	1aa50513          	addi	a0,a0,426 # 800080c8 <digits+0x88>
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
    80000f52:	a12080e7          	jalr	-1518(ra) # 80002960 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	a32080e7          	jalr	-1486(ra) # 80002988 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5e:	00005097          	auipc	ra,0x5
    80000f62:	fcc080e7          	jalr	-52(ra) # 80005f2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f66:	00005097          	auipc	ra,0x5
    80000f6a:	fda080e7          	jalr	-38(ra) # 80005f40 <plicinithart>
    binit();         // buffer cache
    80000f6e:	00002097          	auipc	ra,0x2
    80000f72:	1b0080e7          	jalr	432(ra) # 8000311e <binit>
    iinit();         // inode table
    80000f76:	00003097          	auipc	ra,0x3
    80000f7a:	840080e7          	jalr	-1984(ra) # 800037b6 <iinit>
    fileinit();      // file table
    80000f7e:	00003097          	auipc	ra,0x3
    80000f82:	7ea080e7          	jalr	2026(ra) # 80004768 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f86:	00005097          	auipc	ra,0x5
    80000f8a:	0dc080e7          	jalr	220(ra) # 80006062 <virtio_disk_init>
    userinit();      // first user process
    80000f8e:	00001097          	auipc	ra,0x1
    80000f92:	d06080e7          	jalr	-762(ra) # 80001c94 <userinit>
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
    8000185a:	e7a48493          	addi	s1,s1,-390 # 800116d0 <proc>
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
    80001874:	c60a0a13          	addi	s4,s4,-928 # 800174d0 <tickslock>
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
    800018aa:	17848493          	addi	s1,s1,376
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
  
  initlock(&pid_lock, "nextpid");
    800018ea:	00007597          	auipc	a1,0x7
    800018ee:	8f658593          	addi	a1,a1,-1802 # 800081e0 <digits+0x1a0>
    800018f2:	00010517          	auipc	a0,0x10
    800018f6:	9ae50513          	addi	a0,a0,-1618 # 800112a0 <pid_lock>
    800018fa:	fffff097          	auipc	ra,0xfffff
    800018fe:	25c080e7          	jalr	604(ra) # 80000b56 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001902:	00007597          	auipc	a1,0x7
    80001906:	8e658593          	addi	a1,a1,-1818 # 800081e8 <digits+0x1a8>
    8000190a:	00010517          	auipc	a0,0x10
    8000190e:	9ae50513          	addi	a0,a0,-1618 # 800112b8 <wait_lock>
    80001912:	fffff097          	auipc	ra,0xfffff
    80001916:	244080e7          	jalr	580(ra) # 80000b56 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000191a:	00010497          	auipc	s1,0x10
    8000191e:	db648493          	addi	s1,s1,-586 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001922:	00007b17          	auipc	s6,0x7
    80001926:	8d6b0b13          	addi	s6,s6,-1834 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000192a:	8aa6                	mv	s5,s1
    8000192c:	00006a17          	auipc	s4,0x6
    80001930:	6d4a0a13          	addi	s4,s4,1748 # 80008000 <etext>
    80001934:	04000937          	lui	s2,0x4000
    80001938:	197d                	addi	s2,s2,-1
    8000193a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193c:	00016997          	auipc	s3,0x16
    80001940:	b9498993          	addi	s3,s3,-1132 # 800174d0 <tickslock>
      initlock(&p->lock, "proc");
    80001944:	85da                	mv	a1,s6
    80001946:	8526                	mv	a0,s1
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	20e080e7          	jalr	526(ra) # 80000b56 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001950:	415487b3          	sub	a5,s1,s5
    80001954:	878d                	srai	a5,a5,0x3
    80001956:	000a3703          	ld	a4,0(s4)
    8000195a:	02e787b3          	mul	a5,a5,a4
    8000195e:	2785                	addiw	a5,a5,1
    80001960:	00d7979b          	slliw	a5,a5,0xd
    80001964:	40f907b3          	sub	a5,s2,a5
    80001968:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196a:	17848493          	addi	s1,s1,376
    8000196e:	fd349be3          	bne	s1,s3,80001944 <procinit+0x6e>
  }
}
    80001972:	70e2                	ld	ra,56(sp)
    80001974:	7442                	ld	s0,48(sp)
    80001976:	74a2                	ld	s1,40(sp)
    80001978:	7902                	ld	s2,32(sp)
    8000197a:	69e2                	ld	s3,24(sp)
    8000197c:	6a42                	ld	s4,16(sp)
    8000197e:	6aa2                	ld	s5,8(sp)
    80001980:	6b02                	ld	s6,0(sp)
    80001982:	6121                	addi	sp,sp,64
    80001984:	8082                	ret

0000000080001986 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001986:	1141                	addi	sp,sp,-16
    80001988:	e422                	sd	s0,8(sp)
    8000198a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000198c:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    8000198e:	2501                	sext.w	a0,a0
    80001990:	6422                	ld	s0,8(sp)
    80001992:	0141                	addi	sp,sp,16
    80001994:	8082                	ret

0000000080001996 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001996:	1141                	addi	sp,sp,-16
    80001998:	e422                	sd	s0,8(sp)
    8000199a:	0800                	addi	s0,sp,16
    8000199c:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    8000199e:	2781                	sext.w	a5,a5
    800019a0:	079e                	slli	a5,a5,0x7
  return c;
}
    800019a2:	00010517          	auipc	a0,0x10
    800019a6:	92e50513          	addi	a0,a0,-1746 # 800112d0 <cpus>
    800019aa:	953e                	add	a0,a0,a5
    800019ac:	6422                	ld	s0,8(sp)
    800019ae:	0141                	addi	sp,sp,16
    800019b0:	8082                	ret

00000000800019b2 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    800019b2:	1101                	addi	sp,sp,-32
    800019b4:	ec06                	sd	ra,24(sp)
    800019b6:	e822                	sd	s0,16(sp)
    800019b8:	e426                	sd	s1,8(sp)
    800019ba:	1000                	addi	s0,sp,32
  push_off();
    800019bc:	fffff097          	auipc	ra,0xfffff
    800019c0:	1de080e7          	jalr	478(ra) # 80000b9a <push_off>
    800019c4:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c6:	2781                	sext.w	a5,a5
    800019c8:	079e                	slli	a5,a5,0x7
    800019ca:	00010717          	auipc	a4,0x10
    800019ce:	8d670713          	addi	a4,a4,-1834 # 800112a0 <pid_lock>
    800019d2:	97ba                	add	a5,a5,a4
    800019d4:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d6:	fffff097          	auipc	ra,0xfffff
    800019da:	264080e7          	jalr	612(ra) # 80000c3a <pop_off>
  return p;
}
    800019de:	8526                	mv	a0,s1
    800019e0:	60e2                	ld	ra,24(sp)
    800019e2:	6442                	ld	s0,16(sp)
    800019e4:	64a2                	ld	s1,8(sp)
    800019e6:	6105                	addi	sp,sp,32
    800019e8:	8082                	ret

00000000800019ea <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019ea:	1141                	addi	sp,sp,-16
    800019ec:	e406                	sd	ra,8(sp)
    800019ee:	e022                	sd	s0,0(sp)
    800019f0:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019f2:	00000097          	auipc	ra,0x0
    800019f6:	fc0080e7          	jalr	-64(ra) # 800019b2 <myproc>
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	2a0080e7          	jalr	672(ra) # 80000c9a <release>

  if (first) {
    80001a02:	00007797          	auipc	a5,0x7
    80001a06:	eee7a783          	lw	a5,-274(a5) # 800088f0 <first.1689>
    80001a0a:	eb89                	bnez	a5,80001a1c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a0c:	00001097          	auipc	ra,0x1
    80001a10:	f94080e7          	jalr	-108(ra) # 800029a0 <usertrapret>
}
    80001a14:	60a2                	ld	ra,8(sp)
    80001a16:	6402                	ld	s0,0(sp)
    80001a18:	0141                	addi	sp,sp,16
    80001a1a:	8082                	ret
    first = 0;
    80001a1c:	00007797          	auipc	a5,0x7
    80001a20:	ec07aa23          	sw	zero,-300(a5) # 800088f0 <first.1689>
    fsinit(ROOTDEV);
    80001a24:	4505                	li	a0,1
    80001a26:	00002097          	auipc	ra,0x2
    80001a2a:	d10080e7          	jalr	-752(ra) # 80003736 <fsinit>
    80001a2e:	bff9                	j	80001a0c <forkret+0x22>

0000000080001a30 <allocpid>:
allocpid() {
    80001a30:	1101                	addi	sp,sp,-32
    80001a32:	ec06                	sd	ra,24(sp)
    80001a34:	e822                	sd	s0,16(sp)
    80001a36:	e426                	sd	s1,8(sp)
    80001a38:	e04a                	sd	s2,0(sp)
    80001a3a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a3c:	00010917          	auipc	s2,0x10
    80001a40:	86490913          	addi	s2,s2,-1948 # 800112a0 <pid_lock>
    80001a44:	854a                	mv	a0,s2
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	1a0080e7          	jalr	416(ra) # 80000be6 <acquire>
  pid = nextpid;
    80001a4e:	00007797          	auipc	a5,0x7
    80001a52:	ea678793          	addi	a5,a5,-346 # 800088f4 <nextpid>
    80001a56:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a58:	0014871b          	addiw	a4,s1,1
    80001a5c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a5e:	854a                	mv	a0,s2
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	23a080e7          	jalr	570(ra) # 80000c9a <release>
}
    80001a68:	8526                	mv	a0,s1
    80001a6a:	60e2                	ld	ra,24(sp)
    80001a6c:	6442                	ld	s0,16(sp)
    80001a6e:	64a2                	ld	s1,8(sp)
    80001a70:	6902                	ld	s2,0(sp)
    80001a72:	6105                	addi	sp,sp,32
    80001a74:	8082                	ret

0000000080001a76 <proc_pagetable>:
{
    80001a76:	1101                	addi	sp,sp,-32
    80001a78:	ec06                	sd	ra,24(sp)
    80001a7a:	e822                	sd	s0,16(sp)
    80001a7c:	e426                	sd	s1,8(sp)
    80001a7e:	e04a                	sd	s2,0(sp)
    80001a80:	1000                	addi	s0,sp,32
    80001a82:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a84:	00000097          	auipc	ra,0x0
    80001a88:	8b8080e7          	jalr	-1864(ra) # 8000133c <uvmcreate>
    80001a8c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a8e:	c121                	beqz	a0,80001ace <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a90:	4729                	li	a4,10
    80001a92:	00005697          	auipc	a3,0x5
    80001a96:	56e68693          	addi	a3,a3,1390 # 80007000 <_trampoline>
    80001a9a:	6605                	lui	a2,0x1
    80001a9c:	040005b7          	lui	a1,0x4000
    80001aa0:	15fd                	addi	a1,a1,-1
    80001aa2:	05b2                	slli	a1,a1,0xc
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	60e080e7          	jalr	1550(ra) # 800010b2 <mappages>
    80001aac:	02054863          	bltz	a0,80001adc <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ab0:	4719                	li	a4,6
    80001ab2:	05893683          	ld	a3,88(s2)
    80001ab6:	6605                	lui	a2,0x1
    80001ab8:	020005b7          	lui	a1,0x2000
    80001abc:	15fd                	addi	a1,a1,-1
    80001abe:	05b6                	slli	a1,a1,0xd
    80001ac0:	8526                	mv	a0,s1
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	5f0080e7          	jalr	1520(ra) # 800010b2 <mappages>
    80001aca:	02054163          	bltz	a0,80001aec <proc_pagetable+0x76>
}
    80001ace:	8526                	mv	a0,s1
    80001ad0:	60e2                	ld	ra,24(sp)
    80001ad2:	6442                	ld	s0,16(sp)
    80001ad4:	64a2                	ld	s1,8(sp)
    80001ad6:	6902                	ld	s2,0(sp)
    80001ad8:	6105                	addi	sp,sp,32
    80001ada:	8082                	ret
    uvmfree(pagetable, 0);
    80001adc:	4581                	li	a1,0
    80001ade:	8526                	mv	a0,s1
    80001ae0:	00000097          	auipc	ra,0x0
    80001ae4:	a58080e7          	jalr	-1448(ra) # 80001538 <uvmfree>
    return 0;
    80001ae8:	4481                	li	s1,0
    80001aea:	b7d5                	j	80001ace <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aec:	4681                	li	a3,0
    80001aee:	4605                	li	a2,1
    80001af0:	040005b7          	lui	a1,0x4000
    80001af4:	15fd                	addi	a1,a1,-1
    80001af6:	05b2                	slli	a1,a1,0xc
    80001af8:	8526                	mv	a0,s1
    80001afa:	fffff097          	auipc	ra,0xfffff
    80001afe:	77e080e7          	jalr	1918(ra) # 80001278 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b02:	4581                	li	a1,0
    80001b04:	8526                	mv	a0,s1
    80001b06:	00000097          	auipc	ra,0x0
    80001b0a:	a32080e7          	jalr	-1486(ra) # 80001538 <uvmfree>
    return 0;
    80001b0e:	4481                	li	s1,0
    80001b10:	bf7d                	j	80001ace <proc_pagetable+0x58>

0000000080001b12 <proc_freepagetable>:
{
    80001b12:	1101                	addi	sp,sp,-32
    80001b14:	ec06                	sd	ra,24(sp)
    80001b16:	e822                	sd	s0,16(sp)
    80001b18:	e426                	sd	s1,8(sp)
    80001b1a:	e04a                	sd	s2,0(sp)
    80001b1c:	1000                	addi	s0,sp,32
    80001b1e:	84aa                	mv	s1,a0
    80001b20:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b22:	4681                	li	a3,0
    80001b24:	4605                	li	a2,1
    80001b26:	040005b7          	lui	a1,0x4000
    80001b2a:	15fd                	addi	a1,a1,-1
    80001b2c:	05b2                	slli	a1,a1,0xc
    80001b2e:	fffff097          	auipc	ra,0xfffff
    80001b32:	74a080e7          	jalr	1866(ra) # 80001278 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	020005b7          	lui	a1,0x2000
    80001b3e:	15fd                	addi	a1,a1,-1
    80001b40:	05b6                	slli	a1,a1,0xd
    80001b42:	8526                	mv	a0,s1
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	734080e7          	jalr	1844(ra) # 80001278 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b4c:	85ca                	mv	a1,s2
    80001b4e:	8526                	mv	a0,s1
    80001b50:	00000097          	auipc	ra,0x0
    80001b54:	9e8080e7          	jalr	-1560(ra) # 80001538 <uvmfree>
}
    80001b58:	60e2                	ld	ra,24(sp)
    80001b5a:	6442                	ld	s0,16(sp)
    80001b5c:	64a2                	ld	s1,8(sp)
    80001b5e:	6902                	ld	s2,0(sp)
    80001b60:	6105                	addi	sp,sp,32
    80001b62:	8082                	ret

0000000080001b64 <freeproc>:
{
    80001b64:	1101                	addi	sp,sp,-32
    80001b66:	ec06                	sd	ra,24(sp)
    80001b68:	e822                	sd	s0,16(sp)
    80001b6a:	e426                	sd	s1,8(sp)
    80001b6c:	1000                	addi	s0,sp,32
    80001b6e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b70:	6d28                	ld	a0,88(a0)
    80001b72:	c509                	beqz	a0,80001b7c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	e86080e7          	jalr	-378(ra) # 800009fa <kfree>
  p->trapframe = 0;
    80001b7c:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b80:	68a8                	ld	a0,80(s1)
    80001b82:	c511                	beqz	a0,80001b8e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b84:	64ac                	ld	a1,72(s1)
    80001b86:	00000097          	auipc	ra,0x0
    80001b8a:	f8c080e7          	jalr	-116(ra) # 80001b12 <proc_freepagetable>
  p->pagetable = 0;
    80001b8e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b92:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b96:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b9a:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b9e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ba2:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba6:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001baa:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bae:	0004ac23          	sw	zero,24(s1)
}
    80001bb2:	60e2                	ld	ra,24(sp)
    80001bb4:	6442                	ld	s0,16(sp)
    80001bb6:	64a2                	ld	s1,8(sp)
    80001bb8:	6105                	addi	sp,sp,32
    80001bba:	8082                	ret

0000000080001bbc <allocproc>:
{
    80001bbc:	1101                	addi	sp,sp,-32
    80001bbe:	ec06                	sd	ra,24(sp)
    80001bc0:	e822                	sd	s0,16(sp)
    80001bc2:	e426                	sd	s1,8(sp)
    80001bc4:	e04a                	sd	s2,0(sp)
    80001bc6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc8:	00010497          	auipc	s1,0x10
    80001bcc:	b0848493          	addi	s1,s1,-1272 # 800116d0 <proc>
    80001bd0:	00016917          	auipc	s2,0x16
    80001bd4:	90090913          	addi	s2,s2,-1792 # 800174d0 <tickslock>
    acquire(&p->lock);
    80001bd8:	8526                	mv	a0,s1
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	00c080e7          	jalr	12(ra) # 80000be6 <acquire>
    if(p->state == UNUSED) {
    80001be2:	4c9c                	lw	a5,24(s1)
    80001be4:	2781                	sext.w	a5,a5
    80001be6:	cf81                	beqz	a5,80001bfe <allocproc+0x42>
      release(&p->lock);
    80001be8:	8526                	mv	a0,s1
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	0b0080e7          	jalr	176(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bf2:	17848493          	addi	s1,s1,376
    80001bf6:	ff2491e3          	bne	s1,s2,80001bd8 <allocproc+0x1c>
  return 0;
    80001bfa:	4481                	li	s1,0
    80001bfc:	a8a9                	j	80001c56 <allocproc+0x9a>
  p->pid = allocpid();
    80001bfe:	00000097          	auipc	ra,0x0
    80001c02:	e32080e7          	jalr	-462(ra) # 80001a30 <allocpid>
    80001c06:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c08:	4785                	li	a5,1
    80001c0a:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	eea080e7          	jalr	-278(ra) # 80000af6 <kalloc>
    80001c14:	892a                	mv	s2,a0
    80001c16:	eca8                	sd	a0,88(s1)
    80001c18:	c531                	beqz	a0,80001c64 <allocproc+0xa8>
  p->pagetable = proc_pagetable(p);
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	00000097          	auipc	ra,0x0
    80001c20:	e5a080e7          	jalr	-422(ra) # 80001a76 <proc_pagetable>
    80001c24:	892a                	mv	s2,a0
    80001c26:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c28:	c931                	beqz	a0,80001c7c <allocproc+0xc0>
  memset(&p->context, 0, sizeof(p->context));
    80001c2a:	07000613          	li	a2,112
    80001c2e:	4581                	li	a1,0
    80001c30:	06048513          	addi	a0,s1,96
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	0ae080e7          	jalr	174(ra) # 80000ce2 <memset>
  p->context.ra = (uint64)forkret;
    80001c3c:	00000797          	auipc	a5,0x0
    80001c40:	dae78793          	addi	a5,a5,-594 # 800019ea <forkret>
    80001c44:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c46:	60bc                	ld	a5,64(s1)
    80001c48:	6705                	lui	a4,0x1
    80001c4a:	97ba                	add	a5,a5,a4
    80001c4c:	f4bc                	sd	a5,104(s1)
  p->mean_ticks = 0;
    80001c4e:	1604a423          	sw	zero,360(s1)
  p->last_ticks = 0;
    80001c52:	1604a623          	sw	zero,364(s1)
}
    80001c56:	8526                	mv	a0,s1
    80001c58:	60e2                	ld	ra,24(sp)
    80001c5a:	6442                	ld	s0,16(sp)
    80001c5c:	64a2                	ld	s1,8(sp)
    80001c5e:	6902                	ld	s2,0(sp)
    80001c60:	6105                	addi	sp,sp,32
    80001c62:	8082                	ret
    freeproc(p);
    80001c64:	8526                	mv	a0,s1
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	efe080e7          	jalr	-258(ra) # 80001b64 <freeproc>
    release(&p->lock);
    80001c6e:	8526                	mv	a0,s1
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	02a080e7          	jalr	42(ra) # 80000c9a <release>
    return 0;
    80001c78:	84ca                	mv	s1,s2
    80001c7a:	bff1                	j	80001c56 <allocproc+0x9a>
    freeproc(p);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	00000097          	auipc	ra,0x0
    80001c82:	ee6080e7          	jalr	-282(ra) # 80001b64 <freeproc>
    release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	012080e7          	jalr	18(ra) # 80000c9a <release>
    return 0;
    80001c90:	84ca                	mv	s1,s2
    80001c92:	b7d1                	j	80001c56 <allocproc+0x9a>

0000000080001c94 <userinit>:
{
    80001c94:	1101                	addi	sp,sp,-32
    80001c96:	ec06                	sd	ra,24(sp)
    80001c98:	e822                	sd	s0,16(sp)
    80001c9a:	e426                	sd	s1,8(sp)
    80001c9c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	f1e080e7          	jalr	-226(ra) # 80001bbc <allocproc>
    80001ca6:	84aa                	mv	s1,a0
  initproc = p;
    80001ca8:	00007797          	auipc	a5,0x7
    80001cac:	38a7b423          	sd	a0,904(a5) # 80009030 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cb0:	03400613          	li	a2,52
    80001cb4:	00007597          	auipc	a1,0x7
    80001cb8:	c4c58593          	addi	a1,a1,-948 # 80008900 <initcode>
    80001cbc:	6928                	ld	a0,80(a0)
    80001cbe:	fffff097          	auipc	ra,0xfffff
    80001cc2:	6ac080e7          	jalr	1708(ra) # 8000136a <uvminit>
  p->sz = PGSIZE;
    80001cc6:	6785                	lui	a5,0x1
    80001cc8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cca:	6cb8                	ld	a4,88(s1)
    80001ccc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cd0:	6cb8                	ld	a4,88(s1)
    80001cd2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cd4:	4641                	li	a2,16
    80001cd6:	00006597          	auipc	a1,0x6
    80001cda:	52a58593          	addi	a1,a1,1322 # 80008200 <digits+0x1c0>
    80001cde:	15848513          	addi	a0,s1,344
    80001ce2:	fffff097          	auipc	ra,0xfffff
    80001ce6:	152080e7          	jalr	338(ra) # 80000e34 <safestrcpy>
  p->cwd = namei("/");
    80001cea:	00006517          	auipc	a0,0x6
    80001cee:	52650513          	addi	a0,a0,1318 # 80008210 <digits+0x1d0>
    80001cf2:	00002097          	auipc	ra,0x2
    80001cf6:	472080e7          	jalr	1138(ra) # 80004164 <namei>
    80001cfa:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cfe:	478d                	li	a5,3
    80001d00:	cc9c                	sw	a5,24(s1)
  acquire(&tickslock);
    80001d02:	00015517          	auipc	a0,0x15
    80001d06:	7ce50513          	addi	a0,a0,1998 # 800174d0 <tickslock>
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	edc080e7          	jalr	-292(ra) # 80000be6 <acquire>
  p->last_runable_time = ticks;
    80001d12:	00007797          	auipc	a5,0x7
    80001d16:	3267a783          	lw	a5,806(a5) # 80009038 <ticks>
    80001d1a:	16f4a823          	sw	a5,368(s1)
  release(&tickslock);
    80001d1e:	00015517          	auipc	a0,0x15
    80001d22:	7b250513          	addi	a0,a0,1970 # 800174d0 <tickslock>
    80001d26:	fffff097          	auipc	ra,0xfffff
    80001d2a:	f74080e7          	jalr	-140(ra) # 80000c9a <release>
  release(&p->lock);
    80001d2e:	8526                	mv	a0,s1
    80001d30:	fffff097          	auipc	ra,0xfffff
    80001d34:	f6a080e7          	jalr	-150(ra) # 80000c9a <release>
}
    80001d38:	60e2                	ld	ra,24(sp)
    80001d3a:	6442                	ld	s0,16(sp)
    80001d3c:	64a2                	ld	s1,8(sp)
    80001d3e:	6105                	addi	sp,sp,32
    80001d40:	8082                	ret

0000000080001d42 <growproc>:
{
    80001d42:	1101                	addi	sp,sp,-32
    80001d44:	ec06                	sd	ra,24(sp)
    80001d46:	e822                	sd	s0,16(sp)
    80001d48:	e426                	sd	s1,8(sp)
    80001d4a:	e04a                	sd	s2,0(sp)
    80001d4c:	1000                	addi	s0,sp,32
    80001d4e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d50:	00000097          	auipc	ra,0x0
    80001d54:	c62080e7          	jalr	-926(ra) # 800019b2 <myproc>
    80001d58:	892a                	mv	s2,a0
  sz = p->sz;
    80001d5a:	652c                	ld	a1,72(a0)
    80001d5c:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d60:	00904f63          	bgtz	s1,80001d7e <growproc+0x3c>
  } else if(n < 0){
    80001d64:	0204cc63          	bltz	s1,80001d9c <growproc+0x5a>
  p->sz = sz;
    80001d68:	1602                	slli	a2,a2,0x20
    80001d6a:	9201                	srli	a2,a2,0x20
    80001d6c:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d70:	4501                	li	a0,0
}
    80001d72:	60e2                	ld	ra,24(sp)
    80001d74:	6442                	ld	s0,16(sp)
    80001d76:	64a2                	ld	s1,8(sp)
    80001d78:	6902                	ld	s2,0(sp)
    80001d7a:	6105                	addi	sp,sp,32
    80001d7c:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d7e:	9e25                	addw	a2,a2,s1
    80001d80:	1602                	slli	a2,a2,0x20
    80001d82:	9201                	srli	a2,a2,0x20
    80001d84:	1582                	slli	a1,a1,0x20
    80001d86:	9181                	srli	a1,a1,0x20
    80001d88:	6928                	ld	a0,80(a0)
    80001d8a:	fffff097          	auipc	ra,0xfffff
    80001d8e:	69a080e7          	jalr	1690(ra) # 80001424 <uvmalloc>
    80001d92:	0005061b          	sext.w	a2,a0
    80001d96:	fa69                	bnez	a2,80001d68 <growproc+0x26>
      return -1;
    80001d98:	557d                	li	a0,-1
    80001d9a:	bfe1                	j	80001d72 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d9c:	9e25                	addw	a2,a2,s1
    80001d9e:	1602                	slli	a2,a2,0x20
    80001da0:	9201                	srli	a2,a2,0x20
    80001da2:	1582                	slli	a1,a1,0x20
    80001da4:	9181                	srli	a1,a1,0x20
    80001da6:	6928                	ld	a0,80(a0)
    80001da8:	fffff097          	auipc	ra,0xfffff
    80001dac:	634080e7          	jalr	1588(ra) # 800013dc <uvmdealloc>
    80001db0:	0005061b          	sext.w	a2,a0
    80001db4:	bf55                	j	80001d68 <growproc+0x26>

0000000080001db6 <fork>:
{
    80001db6:	7179                	addi	sp,sp,-48
    80001db8:	f406                	sd	ra,40(sp)
    80001dba:	f022                	sd	s0,32(sp)
    80001dbc:	ec26                	sd	s1,24(sp)
    80001dbe:	e84a                	sd	s2,16(sp)
    80001dc0:	e44e                	sd	s3,8(sp)
    80001dc2:	e052                	sd	s4,0(sp)
    80001dc4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dc6:	00000097          	auipc	ra,0x0
    80001dca:	bec080e7          	jalr	-1044(ra) # 800019b2 <myproc>
    80001dce:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	dec080e7          	jalr	-532(ra) # 80001bbc <allocproc>
    80001dd8:	14050563          	beqz	a0,80001f22 <fork+0x16c>
    80001ddc:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dde:	04893603          	ld	a2,72(s2)
    80001de2:	692c                	ld	a1,80(a0)
    80001de4:	05093503          	ld	a0,80(s2)
    80001de8:	fffff097          	auipc	ra,0xfffff
    80001dec:	788080e7          	jalr	1928(ra) # 80001570 <uvmcopy>
    80001df0:	04054663          	bltz	a0,80001e3c <fork+0x86>
  np->sz = p->sz;
    80001df4:	04893783          	ld	a5,72(s2)
    80001df8:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dfc:	05893683          	ld	a3,88(s2)
    80001e00:	87b6                	mv	a5,a3
    80001e02:	0589b703          	ld	a4,88(s3)
    80001e06:	12068693          	addi	a3,a3,288
    80001e0a:	0007b803          	ld	a6,0(a5)
    80001e0e:	6788                	ld	a0,8(a5)
    80001e10:	6b8c                	ld	a1,16(a5)
    80001e12:	6f90                	ld	a2,24(a5)
    80001e14:	01073023          	sd	a6,0(a4)
    80001e18:	e708                	sd	a0,8(a4)
    80001e1a:	eb0c                	sd	a1,16(a4)
    80001e1c:	ef10                	sd	a2,24(a4)
    80001e1e:	02078793          	addi	a5,a5,32
    80001e22:	02070713          	addi	a4,a4,32
    80001e26:	fed792e3          	bne	a5,a3,80001e0a <fork+0x54>
  np->trapframe->a0 = 0;
    80001e2a:	0589b783          	ld	a5,88(s3)
    80001e2e:	0607b823          	sd	zero,112(a5)
    80001e32:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e36:	15000a13          	li	s4,336
    80001e3a:	a03d                	j	80001e68 <fork+0xb2>
    freeproc(np);
    80001e3c:	854e                	mv	a0,s3
    80001e3e:	00000097          	auipc	ra,0x0
    80001e42:	d26080e7          	jalr	-730(ra) # 80001b64 <freeproc>
    release(&np->lock);
    80001e46:	854e                	mv	a0,s3
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e52080e7          	jalr	-430(ra) # 80000c9a <release>
    return -1;
    80001e50:	5a7d                	li	s4,-1
    80001e52:	a87d                	j	80001f10 <fork+0x15a>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e54:	00003097          	auipc	ra,0x3
    80001e58:	9a6080e7          	jalr	-1626(ra) # 800047fa <filedup>
    80001e5c:	009987b3          	add	a5,s3,s1
    80001e60:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e62:	04a1                	addi	s1,s1,8
    80001e64:	01448763          	beq	s1,s4,80001e72 <fork+0xbc>
    if(p->ofile[i])
    80001e68:	009907b3          	add	a5,s2,s1
    80001e6c:	6388                	ld	a0,0(a5)
    80001e6e:	f17d                	bnez	a0,80001e54 <fork+0x9e>
    80001e70:	bfcd                	j	80001e62 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e72:	15093503          	ld	a0,336(s2)
    80001e76:	00002097          	auipc	ra,0x2
    80001e7a:	afa080e7          	jalr	-1286(ra) # 80003970 <idup>
    80001e7e:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e82:	4641                	li	a2,16
    80001e84:	15890593          	addi	a1,s2,344
    80001e88:	15898513          	addi	a0,s3,344
    80001e8c:	fffff097          	auipc	ra,0xfffff
    80001e90:	fa8080e7          	jalr	-88(ra) # 80000e34 <safestrcpy>
  pid = np->pid;
    80001e94:	0309aa03          	lw	s4,48(s3)
  np->last_ticks = 0;
    80001e98:	1609a623          	sw	zero,364(s3)
  np->mean_ticks = 0;
    80001e9c:	1609a423          	sw	zero,360(s3)
  release(&np->lock);
    80001ea0:	854e                	mv	a0,s3
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	df8080e7          	jalr	-520(ra) # 80000c9a <release>
  acquire(&wait_lock);
    80001eaa:	0000f497          	auipc	s1,0xf
    80001eae:	40e48493          	addi	s1,s1,1038 # 800112b8 <wait_lock>
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	d32080e7          	jalr	-718(ra) # 80000be6 <acquire>
  np->parent = p;
    80001ebc:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001ec0:	8526                	mv	a0,s1
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	dd8080e7          	jalr	-552(ra) # 80000c9a <release>
  acquire(&np->lock);
    80001eca:	854e                	mv	a0,s3
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	d1a080e7          	jalr	-742(ra) # 80000be6 <acquire>
  np->state = RUNNABLE;
    80001ed4:	478d                	li	a5,3
    80001ed6:	00f9ac23          	sw	a5,24(s3)
  acquire(&tickslock);
    80001eda:	00015517          	auipc	a0,0x15
    80001ede:	5f650513          	addi	a0,a0,1526 # 800174d0 <tickslock>
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	d04080e7          	jalr	-764(ra) # 80000be6 <acquire>
  p->last_runable_time = ticks;
    80001eea:	00007797          	auipc	a5,0x7
    80001eee:	14e7a783          	lw	a5,334(a5) # 80009038 <ticks>
    80001ef2:	16f92823          	sw	a5,368(s2)
  release(&tickslock);
    80001ef6:	00015517          	auipc	a0,0x15
    80001efa:	5da50513          	addi	a0,a0,1498 # 800174d0 <tickslock>
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	d9c080e7          	jalr	-612(ra) # 80000c9a <release>
  release(&np->lock);
    80001f06:	854e                	mv	a0,s3
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	d92080e7          	jalr	-622(ra) # 80000c9a <release>
}
    80001f10:	8552                	mv	a0,s4
    80001f12:	70a2                	ld	ra,40(sp)
    80001f14:	7402                	ld	s0,32(sp)
    80001f16:	64e2                	ld	s1,24(sp)
    80001f18:	6942                	ld	s2,16(sp)
    80001f1a:	69a2                	ld	s3,8(sp)
    80001f1c:	6a02                	ld	s4,0(sp)
    80001f1e:	6145                	addi	sp,sp,48
    80001f20:	8082                	ret
    return -1;
    80001f22:	5a7d                	li	s4,-1
    80001f24:	b7f5                	j	80001f10 <fork+0x15a>

0000000080001f26 <scheduler>:
{
    80001f26:	711d                	addi	sp,sp,-96
    80001f28:	ec86                	sd	ra,88(sp)
    80001f2a:	e8a2                	sd	s0,80(sp)
    80001f2c:	e4a6                	sd	s1,72(sp)
    80001f2e:	e0ca                	sd	s2,64(sp)
    80001f30:	fc4e                	sd	s3,56(sp)
    80001f32:	f852                	sd	s4,48(sp)
    80001f34:	f456                	sd	s5,40(sp)
    80001f36:	f05a                	sd	s6,32(sp)
    80001f38:	ec5e                	sd	s7,24(sp)
    80001f3a:	e862                	sd	s8,16(sp)
    80001f3c:	e466                	sd	s9,8(sp)
    80001f3e:	e06a                	sd	s10,0(sp)
    80001f40:	1080                	addi	s0,sp,96
    80001f42:	8792                	mv	a5,tp
  int id = r_tp();
    80001f44:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f46:	00779d13          	slli	s10,a5,0x7
    80001f4a:	0000f717          	auipc	a4,0xf
    80001f4e:	35670713          	addi	a4,a4,854 # 800112a0 <pid_lock>
    80001f52:	976a                	add	a4,a4,s10
    80001f54:	02073823          	sd	zero,48(a4)
         swtch(&c->context, &hp->context);
    80001f58:	0000f717          	auipc	a4,0xf
    80001f5c:	38070713          	addi	a4,a4,896 # 800112d8 <cpus+0x8>
    80001f60:	9d3a                	add	s10,s10,a4
    while(paused)
    80001f62:	00007b97          	auipc	s7,0x7
    80001f66:	0cab8b93          	addi	s7,s7,202 # 8000902c <paused>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    80001f6a:	00015a17          	auipc	s4,0x15
    80001f6e:	566a0a13          	addi	s4,s4,1382 # 800174d0 <tickslock>
         c->proc = hp;
    80001f72:	079e                	slli	a5,a5,0x7
    80001f74:	0000fb17          	auipc	s6,0xf
    80001f78:	32cb0b13          	addi	s6,s6,812 # 800112a0 <pid_lock>
    80001f7c:	9b3e                	add	s6,s6,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f7e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f82:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f86:	10079073          	csrw	sstatus,a5
    while(paused)
    80001f8a:	000ba783          	lw	a5,0(s7)
    80001f8e:	2781                	sext.w	a5,a5
    80001f90:	cfa1                	beqz	a5,80001fe8 <scheduler+0xc2>
      acquire(&tickslock);
    80001f92:	00015497          	auipc	s1,0x15
    80001f96:	53e48493          	addi	s1,s1,1342 # 800174d0 <tickslock>
      if(ticks >= pause_interval)
    80001f9a:	00007997          	auipc	s3,0x7
    80001f9e:	08e98993          	addi	s3,s3,142 # 80009028 <pause_interval>
    80001fa2:	00007917          	auipc	s2,0x7
    80001fa6:	09690913          	addi	s2,s2,150 # 80009038 <ticks>
    80001faa:	a811                	j	80001fbe <scheduler+0x98>
      release(&tickslock);
    80001fac:	8526                	mv	a0,s1
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	cec080e7          	jalr	-788(ra) # 80000c9a <release>
    while(paused)
    80001fb6:	000ba783          	lw	a5,0(s7)
    80001fba:	2781                	sext.w	a5,a5
    80001fbc:	c795                	beqz	a5,80001fe8 <scheduler+0xc2>
      acquire(&tickslock);
    80001fbe:	8526                	mv	a0,s1
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	c26080e7          	jalr	-986(ra) # 80000be6 <acquire>
      if(ticks >= pause_interval)
    80001fc8:	0009a783          	lw	a5,0(s3)
    80001fcc:	2781                	sext.w	a5,a5
    80001fce:	00092703          	lw	a4,0(s2)
    80001fd2:	fcf76de3          	bltu	a4,a5,80001fac <scheduler+0x86>
        paused ^= paused;
    80001fd6:	000ba703          	lw	a4,0(s7)
    80001fda:	000ba783          	lw	a5,0(s7)
    80001fde:	8fb9                	xor	a5,a5,a4
    80001fe0:	2781                	sext.w	a5,a5
    80001fe2:	00fba023          	sw	a5,0(s7)
    80001fe6:	b7d9                	j	80001fac <scheduler+0x86>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe8:	0000f917          	auipc	s2,0xf
    80001fec:	6e890913          	addi	s2,s2,1768 # 800116d0 <proc>
      if(p->state == RUNNABLE) 
    80001ff0:	4a8d                	li	s5,3
         hp->state = RUNNING;
    80001ff2:	4c91                	li	s9,4
         printf("Proc: %s number: %d last_runable_time: %d\n", hp->name, hp->pid, hp->last_runable_time);
    80001ff4:	00006c17          	auipc	s8,0x6
    80001ff8:	224c0c13          	addi	s8,s8,548 # 80008218 <digits+0x1d8>
    80001ffc:	a841                	j	8000208c <scheduler+0x166>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    80001ffe:	17890493          	addi	s1,s2,376
    80002002:	0544f363          	bgeu	s1,s4,80002048 <scheduler+0x122>
    80002006:	89ca                	mv	s3,s2
    80002008:	a811                	j	8000201c <scheduler+0xf6>
            release(&c->lock);
    8000200a:	8526                	mv	a0,s1
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	c8e080e7          	jalr	-882(ra) # 80000c9a <release>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    80002014:	17848493          	addi	s1,s1,376
    80002018:	0344f963          	bgeu	s1,s4,8000204a <scheduler+0x124>
           acquire(&c->lock);
    8000201c:	8526                	mv	a0,s1
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	bc8080e7          	jalr	-1080(ra) # 80000be6 <acquire>
           if((c->state == RUNNABLE) && (c->mean_ticks < hp->mean_ticks))
    80002026:	4c9c                	lw	a5,24(s1)
    80002028:	2781                	sext.w	a5,a5
    8000202a:	ff5790e3          	bne	a5,s5,8000200a <scheduler+0xe4>
    8000202e:	1684a703          	lw	a4,360(s1)
    80002032:	1689a783          	lw	a5,360(s3)
    80002036:	fcf77ae3          	bgeu	a4,a5,8000200a <scheduler+0xe4>
             release(&hp->lock);
    8000203a:	854e                	mv	a0,s3
    8000203c:	fffff097          	auipc	ra,0xfffff
    80002040:	c5e080e7          	jalr	-930(ra) # 80000c9a <release>
             hp = c;
    80002044:	89a6                	mv	s3,s1
    80002046:	b7f9                	j	80002014 <scheduler+0xee>
         for(struct proc* c = p + 1; c < &proc[NPROC]; c++)
    80002048:	89ca                	mv	s3,s2
         hp->state = RUNNING;
    8000204a:	0199ac23          	sw	s9,24(s3)
         c->proc = hp;
    8000204e:	033b3823          	sd	s3,48(s6)
         swtch(&c->context, &hp->context);
    80002052:	06098593          	addi	a1,s3,96
    80002056:	856a                	mv	a0,s10
    80002058:	00001097          	auipc	ra,0x1
    8000205c:	89e080e7          	jalr	-1890(ra) # 800028f6 <swtch>
         c->proc = 0;
    80002060:	020b3823          	sd	zero,48(s6)
         printf("Proc: %s number: %d last_runable_time: %d\n", hp->name, hp->pid, hp->last_runable_time);
    80002064:	1709a683          	lw	a3,368(s3)
    80002068:	0309a603          	lw	a2,48(s3)
    8000206c:	15898593          	addi	a1,s3,344
    80002070:	8562                	mv	a0,s8
    80002072:	ffffe097          	auipc	ra,0xffffe
    80002076:	518080e7          	jalr	1304(ra) # 8000058a <printf>
         release(&hp->lock);          
    8000207a:	854e                	mv	a0,s3
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	c1e080e7          	jalr	-994(ra) # 80000c9a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002084:	17890913          	addi	s2,s2,376
    80002088:	ef490be3          	beq	s2,s4,80001f7e <scheduler+0x58>
      acquire(&p->lock);
    8000208c:	854a                	mv	a0,s2
    8000208e:	fffff097          	auipc	ra,0xfffff
    80002092:	b58080e7          	jalr	-1192(ra) # 80000be6 <acquire>
      if(p->state == RUNNABLE) 
    80002096:	01892783          	lw	a5,24(s2)
    8000209a:	2781                	sext.w	a5,a5
    8000209c:	f75781e3          	beq	a5,s5,80001ffe <scheduler+0xd8>
        release(&p->lock);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	bf8080e7          	jalr	-1032(ra) # 80000c9a <release>
    800020aa:	bfe9                	j	80002084 <scheduler+0x15e>

00000000800020ac <sched>:
{
    800020ac:	7179                	addi	sp,sp,-48
    800020ae:	f406                	sd	ra,40(sp)
    800020b0:	f022                	sd	s0,32(sp)
    800020b2:	ec26                	sd	s1,24(sp)
    800020b4:	e84a                	sd	s2,16(sp)
    800020b6:	e44e                	sd	s3,8(sp)
    800020b8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020ba:	00000097          	auipc	ra,0x0
    800020be:	8f8080e7          	jalr	-1800(ra) # 800019b2 <myproc>
    800020c2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	aa8080e7          	jalr	-1368(ra) # 80000b6c <holding>
    800020cc:	cd25                	beqz	a0,80002144 <sched+0x98>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ce:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020d0:	2781                	sext.w	a5,a5
    800020d2:	079e                	slli	a5,a5,0x7
    800020d4:	0000f717          	auipc	a4,0xf
    800020d8:	1cc70713          	addi	a4,a4,460 # 800112a0 <pid_lock>
    800020dc:	97ba                	add	a5,a5,a4
    800020de:	0a87a703          	lw	a4,168(a5)
    800020e2:	4785                	li	a5,1
    800020e4:	06f71863          	bne	a4,a5,80002154 <sched+0xa8>
  if(p->state == RUNNING)
    800020e8:	4c9c                	lw	a5,24(s1)
    800020ea:	2781                	sext.w	a5,a5
    800020ec:	4711                	li	a4,4
    800020ee:	06e78b63          	beq	a5,a4,80002164 <sched+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020f2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020f6:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020f8:	efb5                	bnez	a5,80002174 <sched+0xc8>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020fa:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020fc:	0000f917          	auipc	s2,0xf
    80002100:	1a490913          	addi	s2,s2,420 # 800112a0 <pid_lock>
    80002104:	2781                	sext.w	a5,a5
    80002106:	079e                	slli	a5,a5,0x7
    80002108:	97ca                	add	a5,a5,s2
    8000210a:	0ac7a983          	lw	s3,172(a5)
    8000210e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002110:	2781                	sext.w	a5,a5
    80002112:	079e                	slli	a5,a5,0x7
    80002114:	0000f597          	auipc	a1,0xf
    80002118:	1c458593          	addi	a1,a1,452 # 800112d8 <cpus+0x8>
    8000211c:	95be                	add	a1,a1,a5
    8000211e:	06048513          	addi	a0,s1,96
    80002122:	00000097          	auipc	ra,0x0
    80002126:	7d4080e7          	jalr	2004(ra) # 800028f6 <swtch>
    8000212a:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000212c:	2781                	sext.w	a5,a5
    8000212e:	079e                	slli	a5,a5,0x7
    80002130:	97ca                	add	a5,a5,s2
    80002132:	0b37a623          	sw	s3,172(a5)
}
    80002136:	70a2                	ld	ra,40(sp)
    80002138:	7402                	ld	s0,32(sp)
    8000213a:	64e2                	ld	s1,24(sp)
    8000213c:	6942                	ld	s2,16(sp)
    8000213e:	69a2                	ld	s3,8(sp)
    80002140:	6145                	addi	sp,sp,48
    80002142:	8082                	ret
    panic("sched p->lock");
    80002144:	00006517          	auipc	a0,0x6
    80002148:	10450513          	addi	a0,a0,260 # 80008248 <digits+0x208>
    8000214c:	ffffe097          	auipc	ra,0xffffe
    80002150:	3f4080e7          	jalr	1012(ra) # 80000540 <panic>
    panic("sched locks");
    80002154:	00006517          	auipc	a0,0x6
    80002158:	10450513          	addi	a0,a0,260 # 80008258 <digits+0x218>
    8000215c:	ffffe097          	auipc	ra,0xffffe
    80002160:	3e4080e7          	jalr	996(ra) # 80000540 <panic>
    panic("sched running");
    80002164:	00006517          	auipc	a0,0x6
    80002168:	10450513          	addi	a0,a0,260 # 80008268 <digits+0x228>
    8000216c:	ffffe097          	auipc	ra,0xffffe
    80002170:	3d4080e7          	jalr	980(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002174:	00006517          	auipc	a0,0x6
    80002178:	10450513          	addi	a0,a0,260 # 80008278 <digits+0x238>
    8000217c:	ffffe097          	auipc	ra,0xffffe
    80002180:	3c4080e7          	jalr	964(ra) # 80000540 <panic>

0000000080002184 <yield>:
{
    80002184:	1101                	addi	sp,sp,-32
    80002186:	ec06                	sd	ra,24(sp)
    80002188:	e822                	sd	s0,16(sp)
    8000218a:	e426                	sd	s1,8(sp)
    8000218c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	824080e7          	jalr	-2012(ra) # 800019b2 <myproc>
    80002196:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	a4e080e7          	jalr	-1458(ra) # 80000be6 <acquire>
  p->state = RUNNABLE;
    800021a0:	478d                	li	a5,3
    800021a2:	cc9c                	sw	a5,24(s1)
  acquire(&tickslock);
    800021a4:	00015517          	auipc	a0,0x15
    800021a8:	32c50513          	addi	a0,a0,812 # 800174d0 <tickslock>
    800021ac:	fffff097          	auipc	ra,0xfffff
    800021b0:	a3a080e7          	jalr	-1478(ra) # 80000be6 <acquire>
  p->last_runable_time = ticks;
    800021b4:	00007797          	auipc	a5,0x7
    800021b8:	e847a783          	lw	a5,-380(a5) # 80009038 <ticks>
    800021bc:	16f4a823          	sw	a5,368(s1)
  release(&tickslock);
    800021c0:	00015517          	auipc	a0,0x15
    800021c4:	31050513          	addi	a0,a0,784 # 800174d0 <tickslock>
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	ad2080e7          	jalr	-1326(ra) # 80000c9a <release>
  sched();
    800021d0:	00000097          	auipc	ra,0x0
    800021d4:	edc080e7          	jalr	-292(ra) # 800020ac <sched>
  release(&p->lock);
    800021d8:	8526                	mv	a0,s1
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	ac0080e7          	jalr	-1344(ra) # 80000c9a <release>
}
    800021e2:	60e2                	ld	ra,24(sp)
    800021e4:	6442                	ld	s0,16(sp)
    800021e6:	64a2                	ld	s1,8(sp)
    800021e8:	6105                	addi	sp,sp,32
    800021ea:	8082                	ret

00000000800021ec <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800021ec:	7179                	addi	sp,sp,-48
    800021ee:	f406                	sd	ra,40(sp)
    800021f0:	f022                	sd	s0,32(sp)
    800021f2:	ec26                	sd	s1,24(sp)
    800021f4:	e84a                	sd	s2,16(sp)
    800021f6:	e44e                	sd	s3,8(sp)
    800021f8:	1800                	addi	s0,sp,48
    800021fa:	89aa                	mv	s3,a0
    800021fc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	7b4080e7          	jalr	1972(ra) # 800019b2 <myproc>
    80002206:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002208:	fffff097          	auipc	ra,0xfffff
    8000220c:	9de080e7          	jalr	-1570(ra) # 80000be6 <acquire>
  release(lk);
    80002210:	854a                	mv	a0,s2
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	a88080e7          	jalr	-1400(ra) # 80000c9a <release>

  // Go to sleep.
  p->chan = chan;
    8000221a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000221e:	4789                	li	a5,2
    80002220:	cc9c                	sw	a5,24(s1)

  sched();
    80002222:	00000097          	auipc	ra,0x0
    80002226:	e8a080e7          	jalr	-374(ra) # 800020ac <sched>

  // Tidy up.
  p->chan = 0;
    8000222a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000222e:	8526                	mv	a0,s1
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	a6a080e7          	jalr	-1430(ra) # 80000c9a <release>
  acquire(lk);
    80002238:	854a                	mv	a0,s2
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	9ac080e7          	jalr	-1620(ra) # 80000be6 <acquire>
}
    80002242:	70a2                	ld	ra,40(sp)
    80002244:	7402                	ld	s0,32(sp)
    80002246:	64e2                	ld	s1,24(sp)
    80002248:	6942                	ld	s2,16(sp)
    8000224a:	69a2                	ld	s3,8(sp)
    8000224c:	6145                	addi	sp,sp,48
    8000224e:	8082                	ret

0000000080002250 <wait>:
{
    80002250:	715d                	addi	sp,sp,-80
    80002252:	e486                	sd	ra,72(sp)
    80002254:	e0a2                	sd	s0,64(sp)
    80002256:	fc26                	sd	s1,56(sp)
    80002258:	f84a                	sd	s2,48(sp)
    8000225a:	f44e                	sd	s3,40(sp)
    8000225c:	f052                	sd	s4,32(sp)
    8000225e:	ec56                	sd	s5,24(sp)
    80002260:	e85a                	sd	s6,16(sp)
    80002262:	e45e                	sd	s7,8(sp)
    80002264:	e062                	sd	s8,0(sp)
    80002266:	0880                	addi	s0,sp,80
    80002268:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	748080e7          	jalr	1864(ra) # 800019b2 <myproc>
    80002272:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002274:	0000f517          	auipc	a0,0xf
    80002278:	04450513          	addi	a0,a0,68 # 800112b8 <wait_lock>
    8000227c:	fffff097          	auipc	ra,0xfffff
    80002280:	96a080e7          	jalr	-1686(ra) # 80000be6 <acquire>
    havekids = 0;
    80002284:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002286:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    80002288:	00015997          	auipc	s3,0x15
    8000228c:	24898993          	addi	s3,s3,584 # 800174d0 <tickslock>
        havekids = 1;
    80002290:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002292:	0000fc17          	auipc	s8,0xf
    80002296:	026c0c13          	addi	s8,s8,38 # 800112b8 <wait_lock>
    havekids = 0;
    8000229a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000229c:	0000f497          	auipc	s1,0xf
    800022a0:	43448493          	addi	s1,s1,1076 # 800116d0 <proc>
    800022a4:	a0bd                	j	80002312 <wait+0xc2>
          pid = np->pid;
    800022a6:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022aa:	000b0e63          	beqz	s6,800022c6 <wait+0x76>
    800022ae:	4691                	li	a3,4
    800022b0:	02c48613          	addi	a2,s1,44
    800022b4:	85da                	mv	a1,s6
    800022b6:	05093503          	ld	a0,80(s2)
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	3ba080e7          	jalr	954(ra) # 80001674 <copyout>
    800022c2:	02054563          	bltz	a0,800022ec <wait+0x9c>
          freeproc(np);
    800022c6:	8526                	mv	a0,s1
    800022c8:	00000097          	auipc	ra,0x0
    800022cc:	89c080e7          	jalr	-1892(ra) # 80001b64 <freeproc>
          release(&np->lock);
    800022d0:	8526                	mv	a0,s1
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	9c8080e7          	jalr	-1592(ra) # 80000c9a <release>
          release(&wait_lock);
    800022da:	0000f517          	auipc	a0,0xf
    800022de:	fde50513          	addi	a0,a0,-34 # 800112b8 <wait_lock>
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	9b8080e7          	jalr	-1608(ra) # 80000c9a <release>
          return pid;
    800022ea:	a0ad                	j	80002354 <wait+0x104>
            release(&np->lock);
    800022ec:	8526                	mv	a0,s1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	9ac080e7          	jalr	-1620(ra) # 80000c9a <release>
            release(&wait_lock);
    800022f6:	0000f517          	auipc	a0,0xf
    800022fa:	fc250513          	addi	a0,a0,-62 # 800112b8 <wait_lock>
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	99c080e7          	jalr	-1636(ra) # 80000c9a <release>
            return -1;
    80002306:	59fd                	li	s3,-1
    80002308:	a0b1                	j	80002354 <wait+0x104>
    for(np = proc; np < &proc[NPROC]; np++){
    8000230a:	17848493          	addi	s1,s1,376
    8000230e:	03348563          	beq	s1,s3,80002338 <wait+0xe8>
      if(np->parent == p){
    80002312:	7c9c                	ld	a5,56(s1)
    80002314:	ff279be3          	bne	a5,s2,8000230a <wait+0xba>
        acquire(&np->lock);
    80002318:	8526                	mv	a0,s1
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	8cc080e7          	jalr	-1844(ra) # 80000be6 <acquire>
        if(np->state == ZOMBIE){
    80002322:	4c9c                	lw	a5,24(s1)
    80002324:	2781                	sext.w	a5,a5
    80002326:	f94780e3          	beq	a5,s4,800022a6 <wait+0x56>
        release(&np->lock);
    8000232a:	8526                	mv	a0,s1
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	96e080e7          	jalr	-1682(ra) # 80000c9a <release>
        havekids = 1;
    80002334:	8756                	mv	a4,s5
    80002336:	bfd1                	j	8000230a <wait+0xba>
    if(!havekids || p->killed){
    80002338:	c709                	beqz	a4,80002342 <wait+0xf2>
    8000233a:	02892783          	lw	a5,40(s2)
    8000233e:	2781                	sext.w	a5,a5
    80002340:	c79d                	beqz	a5,8000236e <wait+0x11e>
      release(&wait_lock);
    80002342:	0000f517          	auipc	a0,0xf
    80002346:	f7650513          	addi	a0,a0,-138 # 800112b8 <wait_lock>
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	950080e7          	jalr	-1712(ra) # 80000c9a <release>
      return -1;
    80002352:	59fd                	li	s3,-1
}
    80002354:	854e                	mv	a0,s3
    80002356:	60a6                	ld	ra,72(sp)
    80002358:	6406                	ld	s0,64(sp)
    8000235a:	74e2                	ld	s1,56(sp)
    8000235c:	7942                	ld	s2,48(sp)
    8000235e:	79a2                	ld	s3,40(sp)
    80002360:	7a02                	ld	s4,32(sp)
    80002362:	6ae2                	ld	s5,24(sp)
    80002364:	6b42                	ld	s6,16(sp)
    80002366:	6ba2                	ld	s7,8(sp)
    80002368:	6c02                	ld	s8,0(sp)
    8000236a:	6161                	addi	sp,sp,80
    8000236c:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000236e:	85e2                	mv	a1,s8
    80002370:	854a                	mv	a0,s2
    80002372:	00000097          	auipc	ra,0x0
    80002376:	e7a080e7          	jalr	-390(ra) # 800021ec <sleep>
    havekids = 0;
    8000237a:	b705                	j	8000229a <wait+0x4a>

000000008000237c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000237c:	715d                	addi	sp,sp,-80
    8000237e:	e486                	sd	ra,72(sp)
    80002380:	e0a2                	sd	s0,64(sp)
    80002382:	fc26                	sd	s1,56(sp)
    80002384:	f84a                	sd	s2,48(sp)
    80002386:	f44e                	sd	s3,40(sp)
    80002388:	f052                	sd	s4,32(sp)
    8000238a:	ec56                	sd	s5,24(sp)
    8000238c:	e85a                	sd	s6,16(sp)
    8000238e:	e45e                	sd	s7,8(sp)
    80002390:	e062                	sd	s8,0(sp)
    80002392:	0880                	addi	s0,sp,80
    80002394:	8aaa                	mv	s5,a0
  struct proc *p, *mp = myproc();
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	61c080e7          	jalr	1564(ra) # 800019b2 <myproc>
    8000239e:	892a                	mv	s2,a0

  for(p = proc; p < &proc[NPROC]; p++) {
    800023a0:	0000f497          	auipc	s1,0xf
    800023a4:	33048493          	addi	s1,s1,816 # 800116d0 <proc>
    if(p != mp){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800023a8:	4a09                	li	s4,2
        p->state = RUNNABLE;
    800023aa:	4c0d                	li	s8,3
        /* FCFS */
        #ifdef FCFS
        acquire(&tickslock);
    800023ac:	00015b17          	auipc	s6,0x15
    800023b0:	124b0b13          	addi	s6,s6,292 # 800174d0 <tickslock>
        p->last_runable_time = ticks;
    800023b4:	00007b97          	auipc	s7,0x7
    800023b8:	c84b8b93          	addi	s7,s7,-892 # 80009038 <ticks>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023bc:	00015997          	auipc	s3,0x15
    800023c0:	11498993          	addi	s3,s3,276 # 800174d0 <tickslock>
    800023c4:	a811                	j	800023d8 <wakeup+0x5c>
        release(&tickslock);
        #endif
      }
      release(&p->lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	8d2080e7          	jalr	-1838(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023d0:	17848493          	addi	s1,s1,376
    800023d4:	05348163          	beq	s1,s3,80002416 <wakeup+0x9a>
    if(p != mp){
    800023d8:	fe990ce3          	beq	s2,s1,800023d0 <wakeup+0x54>
      acquire(&p->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	808080e7          	jalr	-2040(ra) # 80000be6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800023e6:	4c9c                	lw	a5,24(s1)
    800023e8:	2781                	sext.w	a5,a5
    800023ea:	fd479ee3          	bne	a5,s4,800023c6 <wakeup+0x4a>
    800023ee:	709c                	ld	a5,32(s1)
    800023f0:	fd579be3          	bne	a5,s5,800023c6 <wakeup+0x4a>
        p->state = RUNNABLE;
    800023f4:	0184ac23          	sw	s8,24(s1)
        acquire(&tickslock);
    800023f8:	855a                	mv	a0,s6
    800023fa:	ffffe097          	auipc	ra,0xffffe
    800023fe:	7ec080e7          	jalr	2028(ra) # 80000be6 <acquire>
        p->last_runable_time = ticks;
    80002402:	000ba783          	lw	a5,0(s7)
    80002406:	16f4a823          	sw	a5,368(s1)
        release(&tickslock);
    8000240a:	855a                	mv	a0,s6
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	88e080e7          	jalr	-1906(ra) # 80000c9a <release>
    80002414:	bf4d                	j	800023c6 <wakeup+0x4a>
    }
  }
}
    80002416:	60a6                	ld	ra,72(sp)
    80002418:	6406                	ld	s0,64(sp)
    8000241a:	74e2                	ld	s1,56(sp)
    8000241c:	7942                	ld	s2,48(sp)
    8000241e:	79a2                	ld	s3,40(sp)
    80002420:	7a02                	ld	s4,32(sp)
    80002422:	6ae2                	ld	s5,24(sp)
    80002424:	6b42                	ld	s6,16(sp)
    80002426:	6ba2                	ld	s7,8(sp)
    80002428:	6c02                	ld	s8,0(sp)
    8000242a:	6161                	addi	sp,sp,80
    8000242c:	8082                	ret

000000008000242e <reparent>:
{
    8000242e:	7179                	addi	sp,sp,-48
    80002430:	f406                	sd	ra,40(sp)
    80002432:	f022                	sd	s0,32(sp)
    80002434:	ec26                	sd	s1,24(sp)
    80002436:	e84a                	sd	s2,16(sp)
    80002438:	e44e                	sd	s3,8(sp)
    8000243a:	e052                	sd	s4,0(sp)
    8000243c:	1800                	addi	s0,sp,48
    8000243e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002440:	0000f497          	auipc	s1,0xf
    80002444:	29048493          	addi	s1,s1,656 # 800116d0 <proc>
      pp->parent = initproc;
    80002448:	00007a17          	auipc	s4,0x7
    8000244c:	be8a0a13          	addi	s4,s4,-1048 # 80009030 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002450:	00015997          	auipc	s3,0x15
    80002454:	08098993          	addi	s3,s3,128 # 800174d0 <tickslock>
    80002458:	a029                	j	80002462 <reparent+0x34>
    8000245a:	17848493          	addi	s1,s1,376
    8000245e:	01348d63          	beq	s1,s3,80002478 <reparent+0x4a>
    if(pp->parent == p){
    80002462:	7c9c                	ld	a5,56(s1)
    80002464:	ff279be3          	bne	a5,s2,8000245a <reparent+0x2c>
      pp->parent = initproc;
    80002468:	000a3503          	ld	a0,0(s4)
    8000246c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000246e:	00000097          	auipc	ra,0x0
    80002472:	f0e080e7          	jalr	-242(ra) # 8000237c <wakeup>
    80002476:	b7d5                	j	8000245a <reparent+0x2c>
}
    80002478:	70a2                	ld	ra,40(sp)
    8000247a:	7402                	ld	s0,32(sp)
    8000247c:	64e2                	ld	s1,24(sp)
    8000247e:	6942                	ld	s2,16(sp)
    80002480:	69a2                	ld	s3,8(sp)
    80002482:	6a02                	ld	s4,0(sp)
    80002484:	6145                	addi	sp,sp,48
    80002486:	8082                	ret

0000000080002488 <exit>:
{
    80002488:	7179                	addi	sp,sp,-48
    8000248a:	f406                	sd	ra,40(sp)
    8000248c:	f022                	sd	s0,32(sp)
    8000248e:	ec26                	sd	s1,24(sp)
    80002490:	e84a                	sd	s2,16(sp)
    80002492:	e44e                	sd	s3,8(sp)
    80002494:	e052                	sd	s4,0(sp)
    80002496:	1800                	addi	s0,sp,48
    80002498:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000249a:	fffff097          	auipc	ra,0xfffff
    8000249e:	518080e7          	jalr	1304(ra) # 800019b2 <myproc>
    800024a2:	89aa                	mv	s3,a0
  if(p == initproc)
    800024a4:	00007797          	auipc	a5,0x7
    800024a8:	b8c7b783          	ld	a5,-1140(a5) # 80009030 <initproc>
    800024ac:	0d050493          	addi	s1,a0,208
    800024b0:	15050913          	addi	s2,a0,336
    800024b4:	02a79363          	bne	a5,a0,800024da <exit+0x52>
    panic("init exiting");
    800024b8:	00006517          	auipc	a0,0x6
    800024bc:	dd850513          	addi	a0,a0,-552 # 80008290 <digits+0x250>
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	080080e7          	jalr	128(ra) # 80000540 <panic>
      fileclose(f);
    800024c8:	00002097          	auipc	ra,0x2
    800024cc:	384080e7          	jalr	900(ra) # 8000484c <fileclose>
      p->ofile[fd] = 0;
    800024d0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024d4:	04a1                	addi	s1,s1,8
    800024d6:	01248563          	beq	s1,s2,800024e0 <exit+0x58>
    if(p->ofile[fd]){
    800024da:	6088                	ld	a0,0(s1)
    800024dc:	f575                	bnez	a0,800024c8 <exit+0x40>
    800024de:	bfdd                	j	800024d4 <exit+0x4c>
  begin_op();
    800024e0:	00002097          	auipc	ra,0x2
    800024e4:	ea0080e7          	jalr	-352(ra) # 80004380 <begin_op>
  iput(p->cwd);
    800024e8:	1509b503          	ld	a0,336(s3)
    800024ec:	00001097          	auipc	ra,0x1
    800024f0:	67c080e7          	jalr	1660(ra) # 80003b68 <iput>
  end_op();
    800024f4:	00002097          	auipc	ra,0x2
    800024f8:	f0c080e7          	jalr	-244(ra) # 80004400 <end_op>
  p->cwd = 0;
    800024fc:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002500:	0000f497          	auipc	s1,0xf
    80002504:	db848493          	addi	s1,s1,-584 # 800112b8 <wait_lock>
    80002508:	8526                	mv	a0,s1
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	6dc080e7          	jalr	1756(ra) # 80000be6 <acquire>
  reparent(p);
    80002512:	854e                	mv	a0,s3
    80002514:	00000097          	auipc	ra,0x0
    80002518:	f1a080e7          	jalr	-230(ra) # 8000242e <reparent>
  wakeup(p->parent);
    8000251c:	0389b503          	ld	a0,56(s3)
    80002520:	00000097          	auipc	ra,0x0
    80002524:	e5c080e7          	jalr	-420(ra) # 8000237c <wakeup>
  acquire(&p->lock);
    80002528:	854e                	mv	a0,s3
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	6bc080e7          	jalr	1724(ra) # 80000be6 <acquire>
  p->xstate = status;
    80002532:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002536:	4795                	li	a5,5
    80002538:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000253c:	8526                	mv	a0,s1
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	75c080e7          	jalr	1884(ra) # 80000c9a <release>
  sched();
    80002546:	00000097          	auipc	ra,0x0
    8000254a:	b66080e7          	jalr	-1178(ra) # 800020ac <sched>
  panic("zombie exit");
    8000254e:	00006517          	auipc	a0,0x6
    80002552:	d5250513          	addi	a0,a0,-686 # 800082a0 <digits+0x260>
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	fea080e7          	jalr	-22(ra) # 80000540 <panic>

000000008000255e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000255e:	7179                	addi	sp,sp,-48
    80002560:	f406                	sd	ra,40(sp)
    80002562:	f022                	sd	s0,32(sp)
    80002564:	ec26                	sd	s1,24(sp)
    80002566:	e84a                	sd	s2,16(sp)
    80002568:	e44e                	sd	s3,8(sp)
    8000256a:	1800                	addi	s0,sp,48
    8000256c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000256e:	0000f497          	auipc	s1,0xf
    80002572:	16248493          	addi	s1,s1,354 # 800116d0 <proc>
    80002576:	00015997          	auipc	s3,0x15
    8000257a:	f5a98993          	addi	s3,s3,-166 # 800174d0 <tickslock>
    acquire(&p->lock);
    8000257e:	8526                	mv	a0,s1
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	666080e7          	jalr	1638(ra) # 80000be6 <acquire>
    if(p->pid == pid){
    80002588:	589c                	lw	a5,48(s1)
    8000258a:	01278d63          	beq	a5,s2,800025a4 <kill+0x46>
        #endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000258e:	8526                	mv	a0,s1
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	70a080e7          	jalr	1802(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002598:	17848493          	addi	s1,s1,376
    8000259c:	ff3491e3          	bne	s1,s3,8000257e <kill+0x20>
  }
  return -1;
    800025a0:	557d                	li	a0,-1
    800025a2:	a831                	j	800025be <kill+0x60>
      p->killed = 1;
    800025a4:	4785                	li	a5,1
    800025a6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800025a8:	4c9c                	lw	a5,24(s1)
    800025aa:	2781                	sext.w	a5,a5
    800025ac:	4709                	li	a4,2
    800025ae:	00e78f63          	beq	a5,a4,800025cc <kill+0x6e>
      release(&p->lock);
    800025b2:	8526                	mv	a0,s1
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	6e6080e7          	jalr	1766(ra) # 80000c9a <release>
      return 0;
    800025bc:	4501                	li	a0,0
}
    800025be:	70a2                	ld	ra,40(sp)
    800025c0:	7402                	ld	s0,32(sp)
    800025c2:	64e2                	ld	s1,24(sp)
    800025c4:	6942                	ld	s2,16(sp)
    800025c6:	69a2                	ld	s3,8(sp)
    800025c8:	6145                	addi	sp,sp,48
    800025ca:	8082                	ret
        p->state = RUNNABLE;
    800025cc:	478d                	li	a5,3
    800025ce:	cc9c                	sw	a5,24(s1)
        acquire(&tickslock);
    800025d0:	00015517          	auipc	a0,0x15
    800025d4:	f0050513          	addi	a0,a0,-256 # 800174d0 <tickslock>
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	60e080e7          	jalr	1550(ra) # 80000be6 <acquire>
        p->last_runable_time = ticks;
    800025e0:	00007797          	auipc	a5,0x7
    800025e4:	a587a783          	lw	a5,-1448(a5) # 80009038 <ticks>
    800025e8:	16f4a823          	sw	a5,368(s1)
        release(&tickslock);
    800025ec:	00015517          	auipc	a0,0x15
    800025f0:	ee450513          	addi	a0,a0,-284 # 800174d0 <tickslock>
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	6a6080e7          	jalr	1702(ra) # 80000c9a <release>
    800025fc:	bf5d                	j	800025b2 <kill+0x54>

00000000800025fe <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025fe:	7179                	addi	sp,sp,-48
    80002600:	f406                	sd	ra,40(sp)
    80002602:	f022                	sd	s0,32(sp)
    80002604:	ec26                	sd	s1,24(sp)
    80002606:	e84a                	sd	s2,16(sp)
    80002608:	e44e                	sd	s3,8(sp)
    8000260a:	e052                	sd	s4,0(sp)
    8000260c:	1800                	addi	s0,sp,48
    8000260e:	84aa                	mv	s1,a0
    80002610:	892e                	mv	s2,a1
    80002612:	89b2                	mv	s3,a2
    80002614:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002616:	fffff097          	auipc	ra,0xfffff
    8000261a:	39c080e7          	jalr	924(ra) # 800019b2 <myproc>
  if(user_dst){
    8000261e:	c08d                	beqz	s1,80002640 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002620:	86d2                	mv	a3,s4
    80002622:	864e                	mv	a2,s3
    80002624:	85ca                	mv	a1,s2
    80002626:	6928                	ld	a0,80(a0)
    80002628:	fffff097          	auipc	ra,0xfffff
    8000262c:	04c080e7          	jalr	76(ra) # 80001674 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002630:	70a2                	ld	ra,40(sp)
    80002632:	7402                	ld	s0,32(sp)
    80002634:	64e2                	ld	s1,24(sp)
    80002636:	6942                	ld	s2,16(sp)
    80002638:	69a2                	ld	s3,8(sp)
    8000263a:	6a02                	ld	s4,0(sp)
    8000263c:	6145                	addi	sp,sp,48
    8000263e:	8082                	ret
    memmove((char *)dst, src, len);
    80002640:	000a061b          	sext.w	a2,s4
    80002644:	85ce                	mv	a1,s3
    80002646:	854a                	mv	a0,s2
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	6fa080e7          	jalr	1786(ra) # 80000d42 <memmove>
    return 0;
    80002650:	8526                	mv	a0,s1
    80002652:	bff9                	j	80002630 <either_copyout+0x32>

0000000080002654 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002654:	7179                	addi	sp,sp,-48
    80002656:	f406                	sd	ra,40(sp)
    80002658:	f022                	sd	s0,32(sp)
    8000265a:	ec26                	sd	s1,24(sp)
    8000265c:	e84a                	sd	s2,16(sp)
    8000265e:	e44e                	sd	s3,8(sp)
    80002660:	e052                	sd	s4,0(sp)
    80002662:	1800                	addi	s0,sp,48
    80002664:	892a                	mv	s2,a0
    80002666:	84ae                	mv	s1,a1
    80002668:	89b2                	mv	s3,a2
    8000266a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000266c:	fffff097          	auipc	ra,0xfffff
    80002670:	346080e7          	jalr	838(ra) # 800019b2 <myproc>
  if(user_src){
    80002674:	c08d                	beqz	s1,80002696 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002676:	86d2                	mv	a3,s4
    80002678:	864e                	mv	a2,s3
    8000267a:	85ca                	mv	a1,s2
    8000267c:	6928                	ld	a0,80(a0)
    8000267e:	fffff097          	auipc	ra,0xfffff
    80002682:	082080e7          	jalr	130(ra) # 80001700 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002686:	70a2                	ld	ra,40(sp)
    80002688:	7402                	ld	s0,32(sp)
    8000268a:	64e2                	ld	s1,24(sp)
    8000268c:	6942                	ld	s2,16(sp)
    8000268e:	69a2                	ld	s3,8(sp)
    80002690:	6a02                	ld	s4,0(sp)
    80002692:	6145                	addi	sp,sp,48
    80002694:	8082                	ret
    memmove(dst, (char*)src, len);
    80002696:	000a061b          	sext.w	a2,s4
    8000269a:	85ce                	mv	a1,s3
    8000269c:	854a                	mv	a0,s2
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	6a4080e7          	jalr	1700(ra) # 80000d42 <memmove>
    return 0;
    800026a6:	8526                	mv	a0,s1
    800026a8:	bff9                	j	80002686 <either_copyin+0x32>

00000000800026aa <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026aa:	715d                	addi	sp,sp,-80
    800026ac:	e486                	sd	ra,72(sp)
    800026ae:	e0a2                	sd	s0,64(sp)
    800026b0:	fc26                	sd	s1,56(sp)
    800026b2:	f84a                	sd	s2,48(sp)
    800026b4:	f44e                	sd	s3,40(sp)
    800026b6:	f052                	sd	s4,32(sp)
    800026b8:	ec56                	sd	s5,24(sp)
    800026ba:	e85a                	sd	s6,16(sp)
    800026bc:	e45e                	sd	s7,8(sp)
    800026be:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026c0:	00006517          	auipc	a0,0x6
    800026c4:	a0850513          	addi	a0,a0,-1528 # 800080c8 <digits+0x88>
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	ec2080e7          	jalr	-318(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026d0:	0000f497          	auipc	s1,0xf
    800026d4:	00048493          	mv	s1,s1
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026d8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026da:	00006917          	auipc	s2,0x6
    800026de:	bd690913          	addi	s2,s2,-1066 # 800082b0 <digits+0x270>
    printf("%d %s %s", p->pid, state, p->name);
    800026e2:	00006a97          	auipc	s5,0x6
    800026e6:	bd6a8a93          	addi	s5,s5,-1066 # 800082b8 <digits+0x278>
    printf("\n");
    800026ea:	00006a17          	auipc	s4,0x6
    800026ee:	9dea0a13          	addi	s4,s4,-1570 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f2:	00006b97          	auipc	s7,0x6
    800026f6:	c96b8b93          	addi	s7,s7,-874 # 80008388 <states.1727>
  for(p = proc; p < &proc[NPROC]; p++){
    800026fa:	00015997          	auipc	s3,0x15
    800026fe:	dd698993          	addi	s3,s3,-554 # 800174d0 <tickslock>
    80002702:	a015                	j	80002726 <procdump+0x7c>
    printf("%d %s %s", p->pid, state, p->name);
    80002704:	15848693          	addi	a3,s1,344 # 80011828 <proc+0x158>
    80002708:	588c                	lw	a1,48(s1)
    8000270a:	8556                	mv	a0,s5
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	e7e080e7          	jalr	-386(ra) # 8000058a <printf>
    printf("\n");
    80002714:	8552                	mv	a0,s4
    80002716:	ffffe097          	auipc	ra,0xffffe
    8000271a:	e74080e7          	jalr	-396(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000271e:	17848493          	addi	s1,s1,376
    80002722:	03348963          	beq	s1,s3,80002754 <procdump+0xaa>
    if(p->state == UNUSED)
    80002726:	4c9c                	lw	a5,24(s1)
    80002728:	2781                	sext.w	a5,a5
    8000272a:	dbf5                	beqz	a5,8000271e <procdump+0x74>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000272c:	4c9c                	lw	a5,24(s1)
    8000272e:	4c9c                	lw	a5,24(s1)
    80002730:	2781                	sext.w	a5,a5
      state = "???";
    80002732:	864a                	mv	a2,s2
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002734:	fcfb68e3          	bltu	s6,a5,80002704 <procdump+0x5a>
    80002738:	4c9c                	lw	a5,24(s1)
    8000273a:	1782                	slli	a5,a5,0x20
    8000273c:	9381                	srli	a5,a5,0x20
    8000273e:	078e                	slli	a5,a5,0x3
    80002740:	97de                	add	a5,a5,s7
    80002742:	639c                	ld	a5,0(a5)
    80002744:	d3e1                	beqz	a5,80002704 <procdump+0x5a>
      state = states[p->state];
    80002746:	4c9c                	lw	a5,24(s1)
    80002748:	1782                	slli	a5,a5,0x20
    8000274a:	9381                	srli	a5,a5,0x20
    8000274c:	078e                	slli	a5,a5,0x3
    8000274e:	97de                	add	a5,a5,s7
    80002750:	6390                	ld	a2,0(a5)
    80002752:	bf4d                	j	80002704 <procdump+0x5a>
  }
}
    80002754:	60a6                	ld	ra,72(sp)
    80002756:	6406                	ld	s0,64(sp)
    80002758:	74e2                	ld	s1,56(sp)
    8000275a:	7942                	ld	s2,48(sp)
    8000275c:	79a2                	ld	s3,40(sp)
    8000275e:	7a02                	ld	s4,32(sp)
    80002760:	6ae2                	ld	s5,24(sp)
    80002762:	6b42                	ld	s6,16(sp)
    80002764:	6ba2                	ld	s7,8(sp)
    80002766:	6161                	addi	sp,sp,80
    80002768:	8082                	ret

000000008000276a <pause_system>:

int
pause_system(const int seconds)
{
    8000276a:	1101                	addi	sp,sp,-32
    8000276c:	ec06                	sd	ra,24(sp)
    8000276e:	e822                	sd	s0,16(sp)
    80002770:	e426                	sd	s1,8(sp)
    80002772:	e04a                	sd	s2,0(sp)
    80002774:	1000                	addi	s0,sp,32
    80002776:	892a                	mv	s2,a0
  while(paused)
    80002778:	00007797          	auipc	a5,0x7
    8000277c:	8b47a783          	lw	a5,-1868(a5) # 8000902c <paused>
    80002780:	cf81                	beqz	a5,80002798 <pause_system+0x2e>
    80002782:	00007497          	auipc	s1,0x7
    80002786:	8aa48493          	addi	s1,s1,-1878 # 8000902c <paused>
    yield();
    8000278a:	00000097          	auipc	ra,0x0
    8000278e:	9fa080e7          	jalr	-1542(ra) # 80002184 <yield>
  while(paused)
    80002792:	409c                	lw	a5,0(s1)
    80002794:	2781                	sext.w	a5,a5
    80002796:	fbf5                	bnez	a5,8000278a <pause_system+0x20>

  // print for debug
  struct proc* p = myproc();
    80002798:	fffff097          	auipc	ra,0xfffff
    8000279c:	21a080e7          	jalr	538(ra) # 800019b2 <myproc>
  if(p->killed)
    800027a0:	5504                	lw	s1,40(a0)
    800027a2:	2481                	sext.w	s1,s1
    800027a4:	e0c1                	bnez	s1,80002824 <pause_system+0xba>
  {
    printf("Pronc: %s, number: %d died during pause_sytem execution\n", p->name, p->pid);
    return -1;  
  }

  printf("Proc: %s, number: %d pause system\n", p->name, p->pid);
    800027a6:	5910                	lw	a2,48(a0)
    800027a8:	15850593          	addi	a1,a0,344
    800027ac:	00006517          	auipc	a0,0x6
    800027b0:	b5c50513          	addi	a0,a0,-1188 # 80008308 <digits+0x2c8>
    800027b4:	ffffe097          	auipc	ra,0xffffe
    800027b8:	dd6080e7          	jalr	-554(ra) # 8000058a <printf>

  paused |= 1;
    800027bc:	00007797          	auipc	a5,0x7
    800027c0:	8707a783          	lw	a5,-1936(a5) # 8000902c <paused>
    800027c4:	0017e793          	ori	a5,a5,1
    800027c8:	00007717          	auipc	a4,0x7
    800027cc:	86f72223          	sw	a5,-1948(a4) # 8000902c <paused>
  acquire(&tickslock);
    800027d0:	00015517          	auipc	a0,0x15
    800027d4:	d0050513          	addi	a0,a0,-768 # 800174d0 <tickslock>
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	40e080e7          	jalr	1038(ra) # 80000be6 <acquire>
  pause_interval = ticks + (seconds * 10);
    800027e0:	0029179b          	slliw	a5,s2,0x2
    800027e4:	012787bb          	addw	a5,a5,s2
    800027e8:	0017979b          	slliw	a5,a5,0x1
    800027ec:	00007717          	auipc	a4,0x7
    800027f0:	84c72703          	lw	a4,-1972(a4) # 80009038 <ticks>
    800027f4:	9fb9                	addw	a5,a5,a4
    800027f6:	00007717          	auipc	a4,0x7
    800027fa:	82f72923          	sw	a5,-1998(a4) # 80009028 <pause_interval>
  release(&tickslock);
    800027fe:	00015517          	auipc	a0,0x15
    80002802:	cd250513          	addi	a0,a0,-814 # 800174d0 <tickslock>
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	494080e7          	jalr	1172(ra) # 80000c9a <release>

  yield();
    8000280e:	00000097          	auipc	ra,0x0
    80002812:	976080e7          	jalr	-1674(ra) # 80002184 <yield>
  return 0;
}
    80002816:	8526                	mv	a0,s1
    80002818:	60e2                	ld	ra,24(sp)
    8000281a:	6442                	ld	s0,16(sp)
    8000281c:	64a2                	ld	s1,8(sp)
    8000281e:	6902                	ld	s2,0(sp)
    80002820:	6105                	addi	sp,sp,32
    80002822:	8082                	ret
    printf("Pronc: %s, number: %d died during pause_sytem execution\n", p->name, p->pid);
    80002824:	5910                	lw	a2,48(a0)
    80002826:	15850593          	addi	a1,a0,344
    8000282a:	00006517          	auipc	a0,0x6
    8000282e:	a9e50513          	addi	a0,a0,-1378 # 800082c8 <digits+0x288>
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	d58080e7          	jalr	-680(ra) # 8000058a <printf>
    return -1;  
    8000283a:	54fd                	li	s1,-1
    8000283c:	bfe9                	j	80002816 <pause_system+0xac>

000000008000283e <kill_system>:

#define INIT_SH_PROC 2
int 
kill_system(void)
{
    8000283e:	715d                	addi	sp,sp,-80
    80002840:	e486                	sd	ra,72(sp)
    80002842:	e0a2                	sd	s0,64(sp)
    80002844:	fc26                	sd	s1,56(sp)
    80002846:	f84a                	sd	s2,48(sp)
    80002848:	f44e                	sd	s3,40(sp)
    8000284a:	f052                	sd	s4,32(sp)
    8000284c:	ec56                	sd	s5,24(sp)
    8000284e:	e85a                	sd	s6,16(sp)
    80002850:	e45e                	sd	s7,8(sp)
    80002852:	e062                	sd	s8,0(sp)
    80002854:	0880                	addi	s0,sp,80

  struct proc* p;
  // Below parameters are used for debug.
  struct proc* mp = myproc();
    80002856:	fffff097          	auipc	ra,0xfffff
    8000285a:	15c080e7          	jalr	348(ra) # 800019b2 <myproc>
  int pid = mp->pid;
    8000285e:	03052b83          	lw	s7,48(a0)
  const char* name = mp->name;
    80002862:	15850a93          	addi	s5,a0,344


  /* 
  * Set killed flag for all process besides init & sh.
  */
  for(p = proc; p < &proc[NPROC]; p++)
    80002866:	0000f497          	auipc	s1,0xf
    8000286a:	e6a48493          	addi	s1,s1,-406 # 800116d0 <proc>
  {
      acquire(&p->lock);
      if(p->pid > INIT_SH_PROC && p->state && !p->killed)
    8000286e:	4909                	li	s2,2
      {
        printf("Proc: %s number: %d KILL proc: %s number: %d\n",name, pid, p->name, p->pid);
    80002870:	00006b17          	auipc	s6,0x6
    80002874:	ac0b0b13          	addi	s6,s6,-1344 # 80008330 <digits+0x2f0>
        p->killed |= 1;
        if(p->state == SLEEPING)
          p->state = RUNNABLE;
    80002878:	4c0d                	li	s8,3
  for(p = proc; p < &proc[NPROC]; p++)
    8000287a:	00015a17          	auipc	s4,0x15
    8000287e:	c56a0a13          	addi	s4,s4,-938 # 800174d0 <tickslock>
    80002882:	a811                	j	80002896 <kill_system+0x58>
      }
      release(&p->lock);
    80002884:	8526                	mv	a0,s1
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	414080e7          	jalr	1044(ra) # 80000c9a <release>
  for(p = proc; p < &proc[NPROC]; p++)
    8000288e:	17848493          	addi	s1,s1,376
    80002892:	05448563          	beq	s1,s4,800028dc <kill_system+0x9e>
      acquire(&p->lock);
    80002896:	8526                	mv	a0,s1
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	34e080e7          	jalr	846(ra) # 80000be6 <acquire>
      if(p->pid > INIT_SH_PROC && p->state && !p->killed)
    800028a0:	5898                	lw	a4,48(s1)
    800028a2:	fee951e3          	bge	s2,a4,80002884 <kill_system+0x46>
    800028a6:	4c9c                	lw	a5,24(s1)
    800028a8:	2781                	sext.w	a5,a5
    800028aa:	dfe9                	beqz	a5,80002884 <kill_system+0x46>
    800028ac:	549c                	lw	a5,40(s1)
    800028ae:	2781                	sext.w	a5,a5
    800028b0:	fbf1                	bnez	a5,80002884 <kill_system+0x46>
        printf("Proc: %s number: %d KILL proc: %s number: %d\n",name, pid, p->name, p->pid);
    800028b2:	15848693          	addi	a3,s1,344
    800028b6:	865e                	mv	a2,s7
    800028b8:	85d6                	mv	a1,s5
    800028ba:	855a                	mv	a0,s6
    800028bc:	ffffe097          	auipc	ra,0xffffe
    800028c0:	cce080e7          	jalr	-818(ra) # 8000058a <printf>
        p->killed |= 1;
    800028c4:	549c                	lw	a5,40(s1)
    800028c6:	2781                	sext.w	a5,a5
    800028c8:	0017e793          	ori	a5,a5,1
    800028cc:	d49c                	sw	a5,40(s1)
        if(p->state == SLEEPING)
    800028ce:	4c9c                	lw	a5,24(s1)
    800028d0:	2781                	sext.w	a5,a5
    800028d2:	fb2799e3          	bne	a5,s2,80002884 <kill_system+0x46>
          p->state = RUNNABLE;
    800028d6:	0184ac23          	sw	s8,24(s1)
    800028da:	b76d                	j	80002884 <kill_system+0x46>
  }
  return 0;
    800028dc:	4501                	li	a0,0
    800028de:	60a6                	ld	ra,72(sp)
    800028e0:	6406                	ld	s0,64(sp)
    800028e2:	74e2                	ld	s1,56(sp)
    800028e4:	7942                	ld	s2,48(sp)
    800028e6:	79a2                	ld	s3,40(sp)
    800028e8:	7a02                	ld	s4,32(sp)
    800028ea:	6ae2                	ld	s5,24(sp)
    800028ec:	6b42                	ld	s6,16(sp)
    800028ee:	6ba2                	ld	s7,8(sp)
    800028f0:	6c02                	ld	s8,0(sp)
    800028f2:	6161                	addi	sp,sp,80
    800028f4:	8082                	ret

00000000800028f6 <swtch>:
    800028f6:	00153023          	sd	ra,0(a0)
    800028fa:	00253423          	sd	sp,8(a0)
    800028fe:	e900                	sd	s0,16(a0)
    80002900:	ed04                	sd	s1,24(a0)
    80002902:	03253023          	sd	s2,32(a0)
    80002906:	03353423          	sd	s3,40(a0)
    8000290a:	03453823          	sd	s4,48(a0)
    8000290e:	03553c23          	sd	s5,56(a0)
    80002912:	05653023          	sd	s6,64(a0)
    80002916:	05753423          	sd	s7,72(a0)
    8000291a:	05853823          	sd	s8,80(a0)
    8000291e:	05953c23          	sd	s9,88(a0)
    80002922:	07a53023          	sd	s10,96(a0)
    80002926:	07b53423          	sd	s11,104(a0)
    8000292a:	0005b083          	ld	ra,0(a1)
    8000292e:	0085b103          	ld	sp,8(a1)
    80002932:	6980                	ld	s0,16(a1)
    80002934:	6d84                	ld	s1,24(a1)
    80002936:	0205b903          	ld	s2,32(a1)
    8000293a:	0285b983          	ld	s3,40(a1)
    8000293e:	0305ba03          	ld	s4,48(a1)
    80002942:	0385ba83          	ld	s5,56(a1)
    80002946:	0405bb03          	ld	s6,64(a1)
    8000294a:	0485bb83          	ld	s7,72(a1)
    8000294e:	0505bc03          	ld	s8,80(a1)
    80002952:	0585bc83          	ld	s9,88(a1)
    80002956:	0605bd03          	ld	s10,96(a1)
    8000295a:	0685bd83          	ld	s11,104(a1)
    8000295e:	8082                	ret

0000000080002960 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002960:	1141                	addi	sp,sp,-16
    80002962:	e406                	sd	ra,8(sp)
    80002964:	e022                	sd	s0,0(sp)
    80002966:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002968:	00006597          	auipc	a1,0x6
    8000296c:	a5058593          	addi	a1,a1,-1456 # 800083b8 <states.1727+0x30>
    80002970:	00015517          	auipc	a0,0x15
    80002974:	b6050513          	addi	a0,a0,-1184 # 800174d0 <tickslock>
    80002978:	ffffe097          	auipc	ra,0xffffe
    8000297c:	1de080e7          	jalr	478(ra) # 80000b56 <initlock>
}
    80002980:	60a2                	ld	ra,8(sp)
    80002982:	6402                	ld	s0,0(sp)
    80002984:	0141                	addi	sp,sp,16
    80002986:	8082                	ret

0000000080002988 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002988:	1141                	addi	sp,sp,-16
    8000298a:	e422                	sd	s0,8(sp)
    8000298c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000298e:	00003797          	auipc	a5,0x3
    80002992:	4e278793          	addi	a5,a5,1250 # 80005e70 <kernelvec>
    80002996:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000299a:	6422                	ld	s0,8(sp)
    8000299c:	0141                	addi	sp,sp,16
    8000299e:	8082                	ret

00000000800029a0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029a0:	1141                	addi	sp,sp,-16
    800029a2:	e406                	sd	ra,8(sp)
    800029a4:	e022                	sd	s0,0(sp)
    800029a6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029a8:	fffff097          	auipc	ra,0xfffff
    800029ac:	00a080e7          	jalr	10(ra) # 800019b2 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029b4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029ba:	00004617          	auipc	a2,0x4
    800029be:	64660613          	addi	a2,a2,1606 # 80007000 <_trampoline>
    800029c2:	00004697          	auipc	a3,0x4
    800029c6:	63e68693          	addi	a3,a3,1598 # 80007000 <_trampoline>
    800029ca:	8e91                	sub	a3,a3,a2
    800029cc:	040007b7          	lui	a5,0x4000
    800029d0:	17fd                	addi	a5,a5,-1
    800029d2:	07b2                	slli	a5,a5,0xc
    800029d4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029d6:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029da:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029dc:	180026f3          	csrr	a3,satp
    800029e0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029e2:	6d38                	ld	a4,88(a0)
    800029e4:	6134                	ld	a3,64(a0)
    800029e6:	6585                	lui	a1,0x1
    800029e8:	96ae                	add	a3,a3,a1
    800029ea:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800029ec:	6d38                	ld	a4,88(a0)
    800029ee:	00000697          	auipc	a3,0x0
    800029f2:	13868693          	addi	a3,a3,312 # 80002b26 <usertrap>
    800029f6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029f8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029fa:	8692                	mv	a3,tp
    800029fc:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fe:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a02:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a06:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a0a:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a0e:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a10:	6f18                	ld	a4,24(a4)
    80002a12:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a16:	692c                	ld	a1,80(a0)
    80002a18:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a1a:	00004717          	auipc	a4,0x4
    80002a1e:	67670713          	addi	a4,a4,1654 # 80007090 <userret>
    80002a22:	8f11                	sub	a4,a4,a2
    80002a24:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a26:	577d                	li	a4,-1
    80002a28:	177e                	slli	a4,a4,0x3f
    80002a2a:	8dd9                	or	a1,a1,a4
    80002a2c:	02000537          	lui	a0,0x2000
    80002a30:	157d                	addi	a0,a0,-1
    80002a32:	0536                	slli	a0,a0,0xd
    80002a34:	9782                	jalr	a5
}
    80002a36:	60a2                	ld	ra,8(sp)
    80002a38:	6402                	ld	s0,0(sp)
    80002a3a:	0141                	addi	sp,sp,16
    80002a3c:	8082                	ret

0000000080002a3e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a3e:	1101                	addi	sp,sp,-32
    80002a40:	ec06                	sd	ra,24(sp)
    80002a42:	e822                	sd	s0,16(sp)
    80002a44:	e426                	sd	s1,8(sp)
    80002a46:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a48:	00015497          	auipc	s1,0x15
    80002a4c:	a8848493          	addi	s1,s1,-1400 # 800174d0 <tickslock>
    80002a50:	8526                	mv	a0,s1
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	194080e7          	jalr	404(ra) # 80000be6 <acquire>
  ticks++;
    80002a5a:	00006517          	auipc	a0,0x6
    80002a5e:	5de50513          	addi	a0,a0,1502 # 80009038 <ticks>
    80002a62:	411c                	lw	a5,0(a0)
    80002a64:	2785                	addiw	a5,a5,1
    80002a66:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	914080e7          	jalr	-1772(ra) # 8000237c <wakeup>
  release(&tickslock);
    80002a70:	8526                	mv	a0,s1
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	228080e7          	jalr	552(ra) # 80000c9a <release>
}
    80002a7a:	60e2                	ld	ra,24(sp)
    80002a7c:	6442                	ld	s0,16(sp)
    80002a7e:	64a2                	ld	s1,8(sp)
    80002a80:	6105                	addi	sp,sp,32
    80002a82:	8082                	ret

0000000080002a84 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a84:	1101                	addi	sp,sp,-32
    80002a86:	ec06                	sd	ra,24(sp)
    80002a88:	e822                	sd	s0,16(sp)
    80002a8a:	e426                	sd	s1,8(sp)
    80002a8c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a8e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a92:	00074d63          	bltz	a4,80002aac <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a96:	57fd                	li	a5,-1
    80002a98:	17fe                	slli	a5,a5,0x3f
    80002a9a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a9c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a9e:	06f70363          	beq	a4,a5,80002b04 <devintr+0x80>
  }
}
    80002aa2:	60e2                	ld	ra,24(sp)
    80002aa4:	6442                	ld	s0,16(sp)
    80002aa6:	64a2                	ld	s1,8(sp)
    80002aa8:	6105                	addi	sp,sp,32
    80002aaa:	8082                	ret
     (scause & 0xff) == 9){
    80002aac:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ab0:	46a5                	li	a3,9
    80002ab2:	fed792e3          	bne	a5,a3,80002a96 <devintr+0x12>
    int irq = plic_claim();
    80002ab6:	00003097          	auipc	ra,0x3
    80002aba:	4c2080e7          	jalr	1218(ra) # 80005f78 <plic_claim>
    80002abe:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002ac0:	47a9                	li	a5,10
    80002ac2:	02f50763          	beq	a0,a5,80002af0 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002ac6:	4785                	li	a5,1
    80002ac8:	02f50963          	beq	a0,a5,80002afa <devintr+0x76>
    return 1;
    80002acc:	4505                	li	a0,1
    } else if(irq){
    80002ace:	d8f1                	beqz	s1,80002aa2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ad0:	85a6                	mv	a1,s1
    80002ad2:	00006517          	auipc	a0,0x6
    80002ad6:	8ee50513          	addi	a0,a0,-1810 # 800083c0 <states.1727+0x38>
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	ab0080e7          	jalr	-1360(ra) # 8000058a <printf>
      plic_complete(irq);
    80002ae2:	8526                	mv	a0,s1
    80002ae4:	00003097          	auipc	ra,0x3
    80002ae8:	4b8080e7          	jalr	1208(ra) # 80005f9c <plic_complete>
    return 1;
    80002aec:	4505                	li	a0,1
    80002aee:	bf55                	j	80002aa2 <devintr+0x1e>
      uartintr();
    80002af0:	ffffe097          	auipc	ra,0xffffe
    80002af4:	eba080e7          	jalr	-326(ra) # 800009aa <uartintr>
    80002af8:	b7ed                	j	80002ae2 <devintr+0x5e>
      virtio_disk_intr();
    80002afa:	00004097          	auipc	ra,0x4
    80002afe:	982080e7          	jalr	-1662(ra) # 8000647c <virtio_disk_intr>
    80002b02:	b7c5                	j	80002ae2 <devintr+0x5e>
    if(cpuid() == 0){
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	e82080e7          	jalr	-382(ra) # 80001986 <cpuid>
    80002b0c:	c901                	beqz	a0,80002b1c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b0e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b12:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b14:	14479073          	csrw	sip,a5
    return 2;
    80002b18:	4509                	li	a0,2
    80002b1a:	b761                	j	80002aa2 <devintr+0x1e>
      clockintr();
    80002b1c:	00000097          	auipc	ra,0x0
    80002b20:	f22080e7          	jalr	-222(ra) # 80002a3e <clockintr>
    80002b24:	b7ed                	j	80002b0e <devintr+0x8a>

0000000080002b26 <usertrap>:
{
    80002b26:	1101                	addi	sp,sp,-32
    80002b28:	ec06                	sd	ra,24(sp)
    80002b2a:	e822                	sd	s0,16(sp)
    80002b2c:	e426                	sd	s1,8(sp)
    80002b2e:	e04a                	sd	s2,0(sp)
    80002b30:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b32:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b36:	1007f793          	andi	a5,a5,256
    80002b3a:	e3bd                	bnez	a5,80002ba0 <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b3c:	00003797          	auipc	a5,0x3
    80002b40:	33478793          	addi	a5,a5,820 # 80005e70 <kernelvec>
    80002b44:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	e6a080e7          	jalr	-406(ra) # 800019b2 <myproc>
    80002b50:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b52:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b54:	14102773          	csrr	a4,sepc
    80002b58:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b5a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b5e:	47a1                	li	a5,8
    80002b60:	04f71e63          	bne	a4,a5,80002bbc <usertrap+0x96>
    if(p->killed)
    80002b64:	551c                	lw	a5,40(a0)
    80002b66:	2781                	sext.w	a5,a5
    80002b68:	e7a1                	bnez	a5,80002bb0 <usertrap+0x8a>
    p->trapframe->epc += 4;
    80002b6a:	6cb8                	ld	a4,88(s1)
    80002b6c:	6f1c                	ld	a5,24(a4)
    80002b6e:	0791                	addi	a5,a5,4
    80002b70:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b72:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b76:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b7a:	10079073          	csrw	sstatus,a5
    syscall();
    80002b7e:	00000097          	auipc	ra,0x0
    80002b82:	2e6080e7          	jalr	742(ra) # 80002e64 <syscall>
  if(p->killed)
    80002b86:	549c                	lw	a5,40(s1)
    80002b88:	2781                	sext.w	a5,a5
    80002b8a:	efad                	bnez	a5,80002c04 <usertrap+0xde>
  usertrapret();
    80002b8c:	00000097          	auipc	ra,0x0
    80002b90:	e14080e7          	jalr	-492(ra) # 800029a0 <usertrapret>
}
    80002b94:	60e2                	ld	ra,24(sp)
    80002b96:	6442                	ld	s0,16(sp)
    80002b98:	64a2                	ld	s1,8(sp)
    80002b9a:	6902                	ld	s2,0(sp)
    80002b9c:	6105                	addi	sp,sp,32
    80002b9e:	8082                	ret
    panic("usertrap: not from user mode");
    80002ba0:	00006517          	auipc	a0,0x6
    80002ba4:	84050513          	addi	a0,a0,-1984 # 800083e0 <states.1727+0x58>
    80002ba8:	ffffe097          	auipc	ra,0xffffe
    80002bac:	998080e7          	jalr	-1640(ra) # 80000540 <panic>
      exit(-1);
    80002bb0:	557d                	li	a0,-1
    80002bb2:	00000097          	auipc	ra,0x0
    80002bb6:	8d6080e7          	jalr	-1834(ra) # 80002488 <exit>
    80002bba:	bf45                	j	80002b6a <usertrap+0x44>
  } else if((which_dev = devintr()) != 0){
    80002bbc:	00000097          	auipc	ra,0x0
    80002bc0:	ec8080e7          	jalr	-312(ra) # 80002a84 <devintr>
    80002bc4:	892a                	mv	s2,a0
    80002bc6:	c509                	beqz	a0,80002bd0 <usertrap+0xaa>
  if(p->killed)
    80002bc8:	549c                	lw	a5,40(s1)
    80002bca:	2781                	sext.w	a5,a5
    80002bcc:	c3b1                	beqz	a5,80002c10 <usertrap+0xea>
    80002bce:	a825                	j	80002c06 <usertrap+0xe0>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002bd4:	5890                	lw	a2,48(s1)
    80002bd6:	00006517          	auipc	a0,0x6
    80002bda:	82a50513          	addi	a0,a0,-2006 # 80008400 <states.1727+0x78>
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	9ac080e7          	jalr	-1620(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002be6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bea:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bee:	00006517          	auipc	a0,0x6
    80002bf2:	84250513          	addi	a0,a0,-1982 # 80008430 <states.1727+0xa8>
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	994080e7          	jalr	-1644(ra) # 8000058a <printf>
    p->killed = 1;
    80002bfe:	4785                	li	a5,1
    80002c00:	d49c                	sw	a5,40(s1)
    80002c02:	b751                	j	80002b86 <usertrap+0x60>
  if(p->killed)
    80002c04:	4901                	li	s2,0
    exit(-1);
    80002c06:	557d                	li	a0,-1
    80002c08:	00000097          	auipc	ra,0x0
    80002c0c:	880080e7          	jalr	-1920(ra) # 80002488 <exit>
  if(which_dev == 2)
    80002c10:	4789                	li	a5,2
    80002c12:	f6f91de3          	bne	s2,a5,80002b8c <usertrap+0x66>
    yield();
    80002c16:	fffff097          	auipc	ra,0xfffff
    80002c1a:	56e080e7          	jalr	1390(ra) # 80002184 <yield>
    80002c1e:	b7bd                	j	80002b8c <usertrap+0x66>

0000000080002c20 <kerneltrap>:
{
    80002c20:	7179                	addi	sp,sp,-48
    80002c22:	f406                	sd	ra,40(sp)
    80002c24:	f022                	sd	s0,32(sp)
    80002c26:	ec26                	sd	s1,24(sp)
    80002c28:	e84a                	sd	s2,16(sp)
    80002c2a:	e44e                	sd	s3,8(sp)
    80002c2c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c2e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c32:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c36:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c3a:	1004f793          	andi	a5,s1,256
    80002c3e:	cb85                	beqz	a5,80002c6e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c40:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c44:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c46:	ef85                	bnez	a5,80002c7e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c48:	00000097          	auipc	ra,0x0
    80002c4c:	e3c080e7          	jalr	-452(ra) # 80002a84 <devintr>
    80002c50:	cd1d                	beqz	a0,80002c8e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c52:	4789                	li	a5,2
    80002c54:	06f50a63          	beq	a0,a5,80002cc8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c58:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c5c:	10049073          	csrw	sstatus,s1
}
    80002c60:	70a2                	ld	ra,40(sp)
    80002c62:	7402                	ld	s0,32(sp)
    80002c64:	64e2                	ld	s1,24(sp)
    80002c66:	6942                	ld	s2,16(sp)
    80002c68:	69a2                	ld	s3,8(sp)
    80002c6a:	6145                	addi	sp,sp,48
    80002c6c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c6e:	00005517          	auipc	a0,0x5
    80002c72:	7e250513          	addi	a0,a0,2018 # 80008450 <states.1727+0xc8>
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	8ca080e7          	jalr	-1846(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c7e:	00005517          	auipc	a0,0x5
    80002c82:	7fa50513          	addi	a0,a0,2042 # 80008478 <states.1727+0xf0>
    80002c86:	ffffe097          	auipc	ra,0xffffe
    80002c8a:	8ba080e7          	jalr	-1862(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002c8e:	85ce                	mv	a1,s3
    80002c90:	00006517          	auipc	a0,0x6
    80002c94:	80850513          	addi	a0,a0,-2040 # 80008498 <states.1727+0x110>
    80002c98:	ffffe097          	auipc	ra,0xffffe
    80002c9c:	8f2080e7          	jalr	-1806(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ca0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ca4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ca8:	00006517          	auipc	a0,0x6
    80002cac:	80050513          	addi	a0,a0,-2048 # 800084a8 <states.1727+0x120>
    80002cb0:	ffffe097          	auipc	ra,0xffffe
    80002cb4:	8da080e7          	jalr	-1830(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002cb8:	00006517          	auipc	a0,0x6
    80002cbc:	80850513          	addi	a0,a0,-2040 # 800084c0 <states.1727+0x138>
    80002cc0:	ffffe097          	auipc	ra,0xffffe
    80002cc4:	880080e7          	jalr	-1920(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	cea080e7          	jalr	-790(ra) # 800019b2 <myproc>
    80002cd0:	d541                	beqz	a0,80002c58 <kerneltrap+0x38>
    80002cd2:	fffff097          	auipc	ra,0xfffff
    80002cd6:	ce0080e7          	jalr	-800(ra) # 800019b2 <myproc>
    80002cda:	4d1c                	lw	a5,24(a0)
    80002cdc:	2781                	sext.w	a5,a5
    80002cde:	4711                	li	a4,4
    80002ce0:	f6e79ce3          	bne	a5,a4,80002c58 <kerneltrap+0x38>
    yield();
    80002ce4:	fffff097          	auipc	ra,0xfffff
    80002ce8:	4a0080e7          	jalr	1184(ra) # 80002184 <yield>
    80002cec:	b7b5                	j	80002c58 <kerneltrap+0x38>

0000000080002cee <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cee:	1101                	addi	sp,sp,-32
    80002cf0:	ec06                	sd	ra,24(sp)
    80002cf2:	e822                	sd	s0,16(sp)
    80002cf4:	e426                	sd	s1,8(sp)
    80002cf6:	1000                	addi	s0,sp,32
    80002cf8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002cfa:	fffff097          	auipc	ra,0xfffff
    80002cfe:	cb8080e7          	jalr	-840(ra) # 800019b2 <myproc>
  switch (n) {
    80002d02:	4795                	li	a5,5
    80002d04:	0497e163          	bltu	a5,s1,80002d46 <argraw+0x58>
    80002d08:	048a                	slli	s1,s1,0x2
    80002d0a:	00005717          	auipc	a4,0x5
    80002d0e:	7ee70713          	addi	a4,a4,2030 # 800084f8 <states.1727+0x170>
    80002d12:	94ba                	add	s1,s1,a4
    80002d14:	409c                	lw	a5,0(s1)
    80002d16:	97ba                	add	a5,a5,a4
    80002d18:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d1a:	6d3c                	ld	a5,88(a0)
    80002d1c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d1e:	60e2                	ld	ra,24(sp)
    80002d20:	6442                	ld	s0,16(sp)
    80002d22:	64a2                	ld	s1,8(sp)
    80002d24:	6105                	addi	sp,sp,32
    80002d26:	8082                	ret
    return p->trapframe->a1;
    80002d28:	6d3c                	ld	a5,88(a0)
    80002d2a:	7fa8                	ld	a0,120(a5)
    80002d2c:	bfcd                	j	80002d1e <argraw+0x30>
    return p->trapframe->a2;
    80002d2e:	6d3c                	ld	a5,88(a0)
    80002d30:	63c8                	ld	a0,128(a5)
    80002d32:	b7f5                	j	80002d1e <argraw+0x30>
    return p->trapframe->a3;
    80002d34:	6d3c                	ld	a5,88(a0)
    80002d36:	67c8                	ld	a0,136(a5)
    80002d38:	b7dd                	j	80002d1e <argraw+0x30>
    return p->trapframe->a4;
    80002d3a:	6d3c                	ld	a5,88(a0)
    80002d3c:	6bc8                	ld	a0,144(a5)
    80002d3e:	b7c5                	j	80002d1e <argraw+0x30>
    return p->trapframe->a5;
    80002d40:	6d3c                	ld	a5,88(a0)
    80002d42:	6fc8                	ld	a0,152(a5)
    80002d44:	bfe9                	j	80002d1e <argraw+0x30>
  panic("argraw");
    80002d46:	00005517          	auipc	a0,0x5
    80002d4a:	78a50513          	addi	a0,a0,1930 # 800084d0 <states.1727+0x148>
    80002d4e:	ffffd097          	auipc	ra,0xffffd
    80002d52:	7f2080e7          	jalr	2034(ra) # 80000540 <panic>

0000000080002d56 <fetchaddr>:
{
    80002d56:	1101                	addi	sp,sp,-32
    80002d58:	ec06                	sd	ra,24(sp)
    80002d5a:	e822                	sd	s0,16(sp)
    80002d5c:	e426                	sd	s1,8(sp)
    80002d5e:	e04a                	sd	s2,0(sp)
    80002d60:	1000                	addi	s0,sp,32
    80002d62:	84aa                	mv	s1,a0
    80002d64:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	c4c080e7          	jalr	-948(ra) # 800019b2 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d6e:	653c                	ld	a5,72(a0)
    80002d70:	02f4f863          	bgeu	s1,a5,80002da0 <fetchaddr+0x4a>
    80002d74:	00848713          	addi	a4,s1,8
    80002d78:	02e7e663          	bltu	a5,a4,80002da4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d7c:	46a1                	li	a3,8
    80002d7e:	8626                	mv	a2,s1
    80002d80:	85ca                	mv	a1,s2
    80002d82:	6928                	ld	a0,80(a0)
    80002d84:	fffff097          	auipc	ra,0xfffff
    80002d88:	97c080e7          	jalr	-1668(ra) # 80001700 <copyin>
    80002d8c:	00a03533          	snez	a0,a0
    80002d90:	40a00533          	neg	a0,a0
}
    80002d94:	60e2                	ld	ra,24(sp)
    80002d96:	6442                	ld	s0,16(sp)
    80002d98:	64a2                	ld	s1,8(sp)
    80002d9a:	6902                	ld	s2,0(sp)
    80002d9c:	6105                	addi	sp,sp,32
    80002d9e:	8082                	ret
    return -1;
    80002da0:	557d                	li	a0,-1
    80002da2:	bfcd                	j	80002d94 <fetchaddr+0x3e>
    80002da4:	557d                	li	a0,-1
    80002da6:	b7fd                	j	80002d94 <fetchaddr+0x3e>

0000000080002da8 <fetchstr>:
{
    80002da8:	7179                	addi	sp,sp,-48
    80002daa:	f406                	sd	ra,40(sp)
    80002dac:	f022                	sd	s0,32(sp)
    80002dae:	ec26                	sd	s1,24(sp)
    80002db0:	e84a                	sd	s2,16(sp)
    80002db2:	e44e                	sd	s3,8(sp)
    80002db4:	1800                	addi	s0,sp,48
    80002db6:	892a                	mv	s2,a0
    80002db8:	84ae                	mv	s1,a1
    80002dba:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	bf6080e7          	jalr	-1034(ra) # 800019b2 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002dc4:	86ce                	mv	a3,s3
    80002dc6:	864a                	mv	a2,s2
    80002dc8:	85a6                	mv	a1,s1
    80002dca:	6928                	ld	a0,80(a0)
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	9c0080e7          	jalr	-1600(ra) # 8000178c <copyinstr>
  if(err < 0)
    80002dd4:	00054763          	bltz	a0,80002de2 <fetchstr+0x3a>
  return strlen(buf);
    80002dd8:	8526                	mv	a0,s1
    80002dda:	ffffe097          	auipc	ra,0xffffe
    80002dde:	08c080e7          	jalr	140(ra) # 80000e66 <strlen>
}
    80002de2:	70a2                	ld	ra,40(sp)
    80002de4:	7402                	ld	s0,32(sp)
    80002de6:	64e2                	ld	s1,24(sp)
    80002de8:	6942                	ld	s2,16(sp)
    80002dea:	69a2                	ld	s3,8(sp)
    80002dec:	6145                	addi	sp,sp,48
    80002dee:	8082                	ret

0000000080002df0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002df0:	1101                	addi	sp,sp,-32
    80002df2:	ec06                	sd	ra,24(sp)
    80002df4:	e822                	sd	s0,16(sp)
    80002df6:	e426                	sd	s1,8(sp)
    80002df8:	1000                	addi	s0,sp,32
    80002dfa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dfc:	00000097          	auipc	ra,0x0
    80002e00:	ef2080e7          	jalr	-270(ra) # 80002cee <argraw>
    80002e04:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e06:	4501                	li	a0,0
    80002e08:	60e2                	ld	ra,24(sp)
    80002e0a:	6442                	ld	s0,16(sp)
    80002e0c:	64a2                	ld	s1,8(sp)
    80002e0e:	6105                	addi	sp,sp,32
    80002e10:	8082                	ret

0000000080002e12 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e12:	1101                	addi	sp,sp,-32
    80002e14:	ec06                	sd	ra,24(sp)
    80002e16:	e822                	sd	s0,16(sp)
    80002e18:	e426                	sd	s1,8(sp)
    80002e1a:	1000                	addi	s0,sp,32
    80002e1c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e1e:	00000097          	auipc	ra,0x0
    80002e22:	ed0080e7          	jalr	-304(ra) # 80002cee <argraw>
    80002e26:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e28:	4501                	li	a0,0
    80002e2a:	60e2                	ld	ra,24(sp)
    80002e2c:	6442                	ld	s0,16(sp)
    80002e2e:	64a2                	ld	s1,8(sp)
    80002e30:	6105                	addi	sp,sp,32
    80002e32:	8082                	ret

0000000080002e34 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e34:	1101                	addi	sp,sp,-32
    80002e36:	ec06                	sd	ra,24(sp)
    80002e38:	e822                	sd	s0,16(sp)
    80002e3a:	e426                	sd	s1,8(sp)
    80002e3c:	e04a                	sd	s2,0(sp)
    80002e3e:	1000                	addi	s0,sp,32
    80002e40:	84ae                	mv	s1,a1
    80002e42:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e44:	00000097          	auipc	ra,0x0
    80002e48:	eaa080e7          	jalr	-342(ra) # 80002cee <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e4c:	864a                	mv	a2,s2
    80002e4e:	85a6                	mv	a1,s1
    80002e50:	00000097          	auipc	ra,0x0
    80002e54:	f58080e7          	jalr	-168(ra) # 80002da8 <fetchstr>
}
    80002e58:	60e2                	ld	ra,24(sp)
    80002e5a:	6442                	ld	s0,16(sp)
    80002e5c:	64a2                	ld	s1,8(sp)
    80002e5e:	6902                	ld	s2,0(sp)
    80002e60:	6105                	addi	sp,sp,32
    80002e62:	8082                	ret

0000000080002e64 <syscall>:
[SYS_kill_system] sys_kill_system
};

void
syscall(void)
{
    80002e64:	1101                	addi	sp,sp,-32
    80002e66:	ec06                	sd	ra,24(sp)
    80002e68:	e822                	sd	s0,16(sp)
    80002e6a:	e426                	sd	s1,8(sp)
    80002e6c:	e04a                	sd	s2,0(sp)
    80002e6e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e70:	fffff097          	auipc	ra,0xfffff
    80002e74:	b42080e7          	jalr	-1214(ra) # 800019b2 <myproc>
    80002e78:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e7a:	05853903          	ld	s2,88(a0)
    80002e7e:	0a893783          	ld	a5,168(s2)
    80002e82:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e86:	37fd                	addiw	a5,a5,-1
    80002e88:	4759                	li	a4,22
    80002e8a:	00f76f63          	bltu	a4,a5,80002ea8 <syscall+0x44>
    80002e8e:	00369713          	slli	a4,a3,0x3
    80002e92:	00005797          	auipc	a5,0x5
    80002e96:	67e78793          	addi	a5,a5,1662 # 80008510 <syscalls>
    80002e9a:	97ba                	add	a5,a5,a4
    80002e9c:	639c                	ld	a5,0(a5)
    80002e9e:	c789                	beqz	a5,80002ea8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ea0:	9782                	jalr	a5
    80002ea2:	06a93823          	sd	a0,112(s2)
    80002ea6:	a839                	j	80002ec4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ea8:	15848613          	addi	a2,s1,344
    80002eac:	588c                	lw	a1,48(s1)
    80002eae:	00005517          	auipc	a0,0x5
    80002eb2:	62a50513          	addi	a0,a0,1578 # 800084d8 <states.1727+0x150>
    80002eb6:	ffffd097          	auipc	ra,0xffffd
    80002eba:	6d4080e7          	jalr	1748(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ebe:	6cbc                	ld	a5,88(s1)
    80002ec0:	577d                	li	a4,-1
    80002ec2:	fbb8                	sd	a4,112(a5)
  }
}
    80002ec4:	60e2                	ld	ra,24(sp)
    80002ec6:	6442                	ld	s0,16(sp)
    80002ec8:	64a2                	ld	s1,8(sp)
    80002eca:	6902                	ld	s2,0(sp)
    80002ecc:	6105                	addi	sp,sp,32
    80002ece:	8082                	ret

0000000080002ed0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ed0:	1101                	addi	sp,sp,-32
    80002ed2:	ec06                	sd	ra,24(sp)
    80002ed4:	e822                	sd	s0,16(sp)
    80002ed6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ed8:	fec40593          	addi	a1,s0,-20
    80002edc:	4501                	li	a0,0
    80002ede:	00000097          	auipc	ra,0x0
    80002ee2:	f12080e7          	jalr	-238(ra) # 80002df0 <argint>
    return -1;
    80002ee6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ee8:	00054963          	bltz	a0,80002efa <sys_exit+0x2a>
  exit(n);
    80002eec:	fec42503          	lw	a0,-20(s0)
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	598080e7          	jalr	1432(ra) # 80002488 <exit>
  return 0;  // not reached
    80002ef8:	4781                	li	a5,0
}
    80002efa:	853e                	mv	a0,a5
    80002efc:	60e2                	ld	ra,24(sp)
    80002efe:	6442                	ld	s0,16(sp)
    80002f00:	6105                	addi	sp,sp,32
    80002f02:	8082                	ret

0000000080002f04 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f04:	1141                	addi	sp,sp,-16
    80002f06:	e406                	sd	ra,8(sp)
    80002f08:	e022                	sd	s0,0(sp)
    80002f0a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f0c:	fffff097          	auipc	ra,0xfffff
    80002f10:	aa6080e7          	jalr	-1370(ra) # 800019b2 <myproc>
}
    80002f14:	5908                	lw	a0,48(a0)
    80002f16:	60a2                	ld	ra,8(sp)
    80002f18:	6402                	ld	s0,0(sp)
    80002f1a:	0141                	addi	sp,sp,16
    80002f1c:	8082                	ret

0000000080002f1e <sys_fork>:

uint64
sys_fork(void)
{
    80002f1e:	1141                	addi	sp,sp,-16
    80002f20:	e406                	sd	ra,8(sp)
    80002f22:	e022                	sd	s0,0(sp)
    80002f24:	0800                	addi	s0,sp,16
  return fork();
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	e90080e7          	jalr	-368(ra) # 80001db6 <fork>
}
    80002f2e:	60a2                	ld	ra,8(sp)
    80002f30:	6402                	ld	s0,0(sp)
    80002f32:	0141                	addi	sp,sp,16
    80002f34:	8082                	ret

0000000080002f36 <sys_wait>:

uint64
sys_wait(void)
{
    80002f36:	1101                	addi	sp,sp,-32
    80002f38:	ec06                	sd	ra,24(sp)
    80002f3a:	e822                	sd	s0,16(sp)
    80002f3c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f3e:	fe840593          	addi	a1,s0,-24
    80002f42:	4501                	li	a0,0
    80002f44:	00000097          	auipc	ra,0x0
    80002f48:	ece080e7          	jalr	-306(ra) # 80002e12 <argaddr>
    80002f4c:	87aa                	mv	a5,a0
    return -1;
    80002f4e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f50:	0007c863          	bltz	a5,80002f60 <sys_wait+0x2a>
  return wait(p);
    80002f54:	fe843503          	ld	a0,-24(s0)
    80002f58:	fffff097          	auipc	ra,0xfffff
    80002f5c:	2f8080e7          	jalr	760(ra) # 80002250 <wait>
}
    80002f60:	60e2                	ld	ra,24(sp)
    80002f62:	6442                	ld	s0,16(sp)
    80002f64:	6105                	addi	sp,sp,32
    80002f66:	8082                	ret

0000000080002f68 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f68:	7179                	addi	sp,sp,-48
    80002f6a:	f406                	sd	ra,40(sp)
    80002f6c:	f022                	sd	s0,32(sp)
    80002f6e:	ec26                	sd	s1,24(sp)
    80002f70:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f72:	fdc40593          	addi	a1,s0,-36
    80002f76:	4501                	li	a0,0
    80002f78:	00000097          	auipc	ra,0x0
    80002f7c:	e78080e7          	jalr	-392(ra) # 80002df0 <argint>
    80002f80:	87aa                	mv	a5,a0
    return -1;
    80002f82:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f84:	0207c063          	bltz	a5,80002fa4 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f88:	fffff097          	auipc	ra,0xfffff
    80002f8c:	a2a080e7          	jalr	-1494(ra) # 800019b2 <myproc>
    80002f90:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f92:	fdc42503          	lw	a0,-36(s0)
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	dac080e7          	jalr	-596(ra) # 80001d42 <growproc>
    80002f9e:	00054863          	bltz	a0,80002fae <sys_sbrk+0x46>
    return -1;
  return addr;
    80002fa2:	8526                	mv	a0,s1
}
    80002fa4:	70a2                	ld	ra,40(sp)
    80002fa6:	7402                	ld	s0,32(sp)
    80002fa8:	64e2                	ld	s1,24(sp)
    80002faa:	6145                	addi	sp,sp,48
    80002fac:	8082                	ret
    return -1;
    80002fae:	557d                	li	a0,-1
    80002fb0:	bfd5                	j	80002fa4 <sys_sbrk+0x3c>

0000000080002fb2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fb2:	7139                	addi	sp,sp,-64
    80002fb4:	fc06                	sd	ra,56(sp)
    80002fb6:	f822                	sd	s0,48(sp)
    80002fb8:	f426                	sd	s1,40(sp)
    80002fba:	f04a                	sd	s2,32(sp)
    80002fbc:	ec4e                	sd	s3,24(sp)
    80002fbe:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002fc0:	fcc40593          	addi	a1,s0,-52
    80002fc4:	4501                	li	a0,0
    80002fc6:	00000097          	auipc	ra,0x0
    80002fca:	e2a080e7          	jalr	-470(ra) # 80002df0 <argint>
    return -1;
    80002fce:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fd0:	06054663          	bltz	a0,8000303c <sys_sleep+0x8a>
  acquire(&tickslock);
    80002fd4:	00014517          	auipc	a0,0x14
    80002fd8:	4fc50513          	addi	a0,a0,1276 # 800174d0 <tickslock>
    80002fdc:	ffffe097          	auipc	ra,0xffffe
    80002fe0:	c0a080e7          	jalr	-1014(ra) # 80000be6 <acquire>
  ticks0 = ticks;
    80002fe4:	00006917          	auipc	s2,0x6
    80002fe8:	05492903          	lw	s2,84(s2) # 80009038 <ticks>
  while(ticks - ticks0 < n){
    80002fec:	fcc42783          	lw	a5,-52(s0)
    80002ff0:	cf8d                	beqz	a5,8000302a <sys_sleep+0x78>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ff2:	00014997          	auipc	s3,0x14
    80002ff6:	4de98993          	addi	s3,s3,1246 # 800174d0 <tickslock>
    80002ffa:	00006497          	auipc	s1,0x6
    80002ffe:	03e48493          	addi	s1,s1,62 # 80009038 <ticks>
    if(myproc()->killed){
    80003002:	fffff097          	auipc	ra,0xfffff
    80003006:	9b0080e7          	jalr	-1616(ra) # 800019b2 <myproc>
    8000300a:	551c                	lw	a5,40(a0)
    8000300c:	2781                	sext.w	a5,a5
    8000300e:	ef9d                	bnez	a5,8000304c <sys_sleep+0x9a>
    sleep(&ticks, &tickslock);
    80003010:	85ce                	mv	a1,s3
    80003012:	8526                	mv	a0,s1
    80003014:	fffff097          	auipc	ra,0xfffff
    80003018:	1d8080e7          	jalr	472(ra) # 800021ec <sleep>
  while(ticks - ticks0 < n){
    8000301c:	409c                	lw	a5,0(s1)
    8000301e:	412787bb          	subw	a5,a5,s2
    80003022:	fcc42703          	lw	a4,-52(s0)
    80003026:	fce7eee3          	bltu	a5,a4,80003002 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000302a:	00014517          	auipc	a0,0x14
    8000302e:	4a650513          	addi	a0,a0,1190 # 800174d0 <tickslock>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	c68080e7          	jalr	-920(ra) # 80000c9a <release>
  return 0;
    8000303a:	4781                	li	a5,0
}
    8000303c:	853e                	mv	a0,a5
    8000303e:	70e2                	ld	ra,56(sp)
    80003040:	7442                	ld	s0,48(sp)
    80003042:	74a2                	ld	s1,40(sp)
    80003044:	7902                	ld	s2,32(sp)
    80003046:	69e2                	ld	s3,24(sp)
    80003048:	6121                	addi	sp,sp,64
    8000304a:	8082                	ret
      release(&tickslock);
    8000304c:	00014517          	auipc	a0,0x14
    80003050:	48450513          	addi	a0,a0,1156 # 800174d0 <tickslock>
    80003054:	ffffe097          	auipc	ra,0xffffe
    80003058:	c46080e7          	jalr	-954(ra) # 80000c9a <release>
      return -1;
    8000305c:	57fd                	li	a5,-1
    8000305e:	bff9                	j	8000303c <sys_sleep+0x8a>

0000000080003060 <sys_kill>:

uint64
sys_kill(void)
{
    80003060:	1101                	addi	sp,sp,-32
    80003062:	ec06                	sd	ra,24(sp)
    80003064:	e822                	sd	s0,16(sp)
    80003066:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003068:	fec40593          	addi	a1,s0,-20
    8000306c:	4501                	li	a0,0
    8000306e:	00000097          	auipc	ra,0x0
    80003072:	d82080e7          	jalr	-638(ra) # 80002df0 <argint>
    80003076:	87aa                	mv	a5,a0
    return -1;
    80003078:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    8000307a:	0007c863          	bltz	a5,8000308a <sys_kill+0x2a>
  return kill(pid);
    8000307e:	fec42503          	lw	a0,-20(s0)
    80003082:	fffff097          	auipc	ra,0xfffff
    80003086:	4dc080e7          	jalr	1244(ra) # 8000255e <kill>
}
    8000308a:	60e2                	ld	ra,24(sp)
    8000308c:	6442                	ld	s0,16(sp)
    8000308e:	6105                	addi	sp,sp,32
    80003090:	8082                	ret

0000000080003092 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003092:	1101                	addi	sp,sp,-32
    80003094:	ec06                	sd	ra,24(sp)
    80003096:	e822                	sd	s0,16(sp)
    80003098:	e426                	sd	s1,8(sp)
    8000309a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000309c:	00014517          	auipc	a0,0x14
    800030a0:	43450513          	addi	a0,a0,1076 # 800174d0 <tickslock>
    800030a4:	ffffe097          	auipc	ra,0xffffe
    800030a8:	b42080e7          	jalr	-1214(ra) # 80000be6 <acquire>
  xticks = ticks;
    800030ac:	00006497          	auipc	s1,0x6
    800030b0:	f8c4a483          	lw	s1,-116(s1) # 80009038 <ticks>
  release(&tickslock);
    800030b4:	00014517          	auipc	a0,0x14
    800030b8:	41c50513          	addi	a0,a0,1052 # 800174d0 <tickslock>
    800030bc:	ffffe097          	auipc	ra,0xffffe
    800030c0:	bde080e7          	jalr	-1058(ra) # 80000c9a <release>
  return xticks;
}
    800030c4:	02049513          	slli	a0,s1,0x20
    800030c8:	9101                	srli	a0,a0,0x20
    800030ca:	60e2                	ld	ra,24(sp)
    800030cc:	6442                	ld	s0,16(sp)
    800030ce:	64a2                	ld	s1,8(sp)
    800030d0:	6105                	addi	sp,sp,32
    800030d2:	8082                	ret

00000000800030d4 <sys_pause_system>:

uint64
sys_pause_system(void)
{
    800030d4:	1101                	addi	sp,sp,-32
    800030d6:	ec06                	sd	ra,24(sp)
    800030d8:	e822                	sd	s0,16(sp)
    800030da:	1000                	addi	s0,sp,32
  int seconds;

  if(argint(0, &seconds) < 0)
    800030dc:	fec40593          	addi	a1,s0,-20
    800030e0:	4501                	li	a0,0
    800030e2:	00000097          	auipc	ra,0x0
    800030e6:	d0e080e7          	jalr	-754(ra) # 80002df0 <argint>
    800030ea:	87aa                	mv	a5,a0
    return -1;
    800030ec:	557d                	li	a0,-1
  if(argint(0, &seconds) < 0)
    800030ee:	0007c863          	bltz	a5,800030fe <sys_pause_system+0x2a>
  return pause_system(seconds);
    800030f2:	fec42503          	lw	a0,-20(s0)
    800030f6:	fffff097          	auipc	ra,0xfffff
    800030fa:	674080e7          	jalr	1652(ra) # 8000276a <pause_system>
}
    800030fe:	60e2                	ld	ra,24(sp)
    80003100:	6442                	ld	s0,16(sp)
    80003102:	6105                	addi	sp,sp,32
    80003104:	8082                	ret

0000000080003106 <sys_kill_system>:


uint64
sys_kill_system(void)
{
    80003106:	1141                	addi	sp,sp,-16
    80003108:	e406                	sd	ra,8(sp)
    8000310a:	e022                	sd	s0,0(sp)
    8000310c:	0800                	addi	s0,sp,16
  return kill_system();
    8000310e:	fffff097          	auipc	ra,0xfffff
    80003112:	730080e7          	jalr	1840(ra) # 8000283e <kill_system>
}
    80003116:	60a2                	ld	ra,8(sp)
    80003118:	6402                	ld	s0,0(sp)
    8000311a:	0141                	addi	sp,sp,16
    8000311c:	8082                	ret

000000008000311e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000311e:	7179                	addi	sp,sp,-48
    80003120:	f406                	sd	ra,40(sp)
    80003122:	f022                	sd	s0,32(sp)
    80003124:	ec26                	sd	s1,24(sp)
    80003126:	e84a                	sd	s2,16(sp)
    80003128:	e44e                	sd	s3,8(sp)
    8000312a:	e052                	sd	s4,0(sp)
    8000312c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000312e:	00005597          	auipc	a1,0x5
    80003132:	4a258593          	addi	a1,a1,1186 # 800085d0 <syscalls+0xc0>
    80003136:	00014517          	auipc	a0,0x14
    8000313a:	3b250513          	addi	a0,a0,946 # 800174e8 <bcache>
    8000313e:	ffffe097          	auipc	ra,0xffffe
    80003142:	a18080e7          	jalr	-1512(ra) # 80000b56 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003146:	0001c797          	auipc	a5,0x1c
    8000314a:	3a278793          	addi	a5,a5,930 # 8001f4e8 <bcache+0x8000>
    8000314e:	0001c717          	auipc	a4,0x1c
    80003152:	60270713          	addi	a4,a4,1538 # 8001f750 <bcache+0x8268>
    80003156:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000315a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000315e:	00014497          	auipc	s1,0x14
    80003162:	3a248493          	addi	s1,s1,930 # 80017500 <bcache+0x18>
    b->next = bcache.head.next;
    80003166:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003168:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000316a:	00005a17          	auipc	s4,0x5
    8000316e:	46ea0a13          	addi	s4,s4,1134 # 800085d8 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003172:	2b893783          	ld	a5,696(s2)
    80003176:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003178:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000317c:	85d2                	mv	a1,s4
    8000317e:	01048513          	addi	a0,s1,16
    80003182:	00001097          	auipc	ra,0x1
    80003186:	4bc080e7          	jalr	1212(ra) # 8000463e <initsleeplock>
    bcache.head.next->prev = b;
    8000318a:	2b893783          	ld	a5,696(s2)
    8000318e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003190:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003194:	45848493          	addi	s1,s1,1112
    80003198:	fd349de3          	bne	s1,s3,80003172 <binit+0x54>
  }
}
    8000319c:	70a2                	ld	ra,40(sp)
    8000319e:	7402                	ld	s0,32(sp)
    800031a0:	64e2                	ld	s1,24(sp)
    800031a2:	6942                	ld	s2,16(sp)
    800031a4:	69a2                	ld	s3,8(sp)
    800031a6:	6a02                	ld	s4,0(sp)
    800031a8:	6145                	addi	sp,sp,48
    800031aa:	8082                	ret

00000000800031ac <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031ac:	7179                	addi	sp,sp,-48
    800031ae:	f406                	sd	ra,40(sp)
    800031b0:	f022                	sd	s0,32(sp)
    800031b2:	ec26                	sd	s1,24(sp)
    800031b4:	e84a                	sd	s2,16(sp)
    800031b6:	e44e                	sd	s3,8(sp)
    800031b8:	1800                	addi	s0,sp,48
    800031ba:	89aa                	mv	s3,a0
    800031bc:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800031be:	00014517          	auipc	a0,0x14
    800031c2:	32a50513          	addi	a0,a0,810 # 800174e8 <bcache>
    800031c6:	ffffe097          	auipc	ra,0xffffe
    800031ca:	a20080e7          	jalr	-1504(ra) # 80000be6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031ce:	0001c497          	auipc	s1,0x1c
    800031d2:	5d24b483          	ld	s1,1490(s1) # 8001f7a0 <bcache+0x82b8>
    800031d6:	0001c797          	auipc	a5,0x1c
    800031da:	57a78793          	addi	a5,a5,1402 # 8001f750 <bcache+0x8268>
    800031de:	02f48f63          	beq	s1,a5,8000321c <bread+0x70>
    800031e2:	873e                	mv	a4,a5
    800031e4:	a021                	j	800031ec <bread+0x40>
    800031e6:	68a4                	ld	s1,80(s1)
    800031e8:	02e48a63          	beq	s1,a4,8000321c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031ec:	449c                	lw	a5,8(s1)
    800031ee:	ff379ce3          	bne	a5,s3,800031e6 <bread+0x3a>
    800031f2:	44dc                	lw	a5,12(s1)
    800031f4:	ff2799e3          	bne	a5,s2,800031e6 <bread+0x3a>
      b->refcnt++;
    800031f8:	40bc                	lw	a5,64(s1)
    800031fa:	2785                	addiw	a5,a5,1
    800031fc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031fe:	00014517          	auipc	a0,0x14
    80003202:	2ea50513          	addi	a0,a0,746 # 800174e8 <bcache>
    80003206:	ffffe097          	auipc	ra,0xffffe
    8000320a:	a94080e7          	jalr	-1388(ra) # 80000c9a <release>
      acquiresleep(&b->lock);
    8000320e:	01048513          	addi	a0,s1,16
    80003212:	00001097          	auipc	ra,0x1
    80003216:	466080e7          	jalr	1126(ra) # 80004678 <acquiresleep>
      return b;
    8000321a:	a8b9                	j	80003278 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000321c:	0001c497          	auipc	s1,0x1c
    80003220:	57c4b483          	ld	s1,1404(s1) # 8001f798 <bcache+0x82b0>
    80003224:	0001c797          	auipc	a5,0x1c
    80003228:	52c78793          	addi	a5,a5,1324 # 8001f750 <bcache+0x8268>
    8000322c:	00f48863          	beq	s1,a5,8000323c <bread+0x90>
    80003230:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003232:	40bc                	lw	a5,64(s1)
    80003234:	cf81                	beqz	a5,8000324c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003236:	64a4                	ld	s1,72(s1)
    80003238:	fee49de3          	bne	s1,a4,80003232 <bread+0x86>
  panic("bget: no buffers");
    8000323c:	00005517          	auipc	a0,0x5
    80003240:	3a450513          	addi	a0,a0,932 # 800085e0 <syscalls+0xd0>
    80003244:	ffffd097          	auipc	ra,0xffffd
    80003248:	2fc080e7          	jalr	764(ra) # 80000540 <panic>
      b->dev = dev;
    8000324c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003250:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003254:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003258:	4785                	li	a5,1
    8000325a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000325c:	00014517          	auipc	a0,0x14
    80003260:	28c50513          	addi	a0,a0,652 # 800174e8 <bcache>
    80003264:	ffffe097          	auipc	ra,0xffffe
    80003268:	a36080e7          	jalr	-1482(ra) # 80000c9a <release>
      acquiresleep(&b->lock);
    8000326c:	01048513          	addi	a0,s1,16
    80003270:	00001097          	auipc	ra,0x1
    80003274:	408080e7          	jalr	1032(ra) # 80004678 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003278:	409c                	lw	a5,0(s1)
    8000327a:	cb89                	beqz	a5,8000328c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000327c:	8526                	mv	a0,s1
    8000327e:	70a2                	ld	ra,40(sp)
    80003280:	7402                	ld	s0,32(sp)
    80003282:	64e2                	ld	s1,24(sp)
    80003284:	6942                	ld	s2,16(sp)
    80003286:	69a2                	ld	s3,8(sp)
    80003288:	6145                	addi	sp,sp,48
    8000328a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000328c:	4581                	li	a1,0
    8000328e:	8526                	mv	a0,s1
    80003290:	00003097          	auipc	ra,0x3
    80003294:	f16080e7          	jalr	-234(ra) # 800061a6 <virtio_disk_rw>
    b->valid = 1;
    80003298:	4785                	li	a5,1
    8000329a:	c09c                	sw	a5,0(s1)
  return b;
    8000329c:	b7c5                	j	8000327c <bread+0xd0>

000000008000329e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000329e:	1101                	addi	sp,sp,-32
    800032a0:	ec06                	sd	ra,24(sp)
    800032a2:	e822                	sd	s0,16(sp)
    800032a4:	e426                	sd	s1,8(sp)
    800032a6:	1000                	addi	s0,sp,32
    800032a8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032aa:	0541                	addi	a0,a0,16
    800032ac:	00001097          	auipc	ra,0x1
    800032b0:	466080e7          	jalr	1126(ra) # 80004712 <holdingsleep>
    800032b4:	cd01                	beqz	a0,800032cc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032b6:	4585                	li	a1,1
    800032b8:	8526                	mv	a0,s1
    800032ba:	00003097          	auipc	ra,0x3
    800032be:	eec080e7          	jalr	-276(ra) # 800061a6 <virtio_disk_rw>
}
    800032c2:	60e2                	ld	ra,24(sp)
    800032c4:	6442                	ld	s0,16(sp)
    800032c6:	64a2                	ld	s1,8(sp)
    800032c8:	6105                	addi	sp,sp,32
    800032ca:	8082                	ret
    panic("bwrite");
    800032cc:	00005517          	auipc	a0,0x5
    800032d0:	32c50513          	addi	a0,a0,812 # 800085f8 <syscalls+0xe8>
    800032d4:	ffffd097          	auipc	ra,0xffffd
    800032d8:	26c080e7          	jalr	620(ra) # 80000540 <panic>

00000000800032dc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032dc:	1101                	addi	sp,sp,-32
    800032de:	ec06                	sd	ra,24(sp)
    800032e0:	e822                	sd	s0,16(sp)
    800032e2:	e426                	sd	s1,8(sp)
    800032e4:	e04a                	sd	s2,0(sp)
    800032e6:	1000                	addi	s0,sp,32
    800032e8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032ea:	01050913          	addi	s2,a0,16
    800032ee:	854a                	mv	a0,s2
    800032f0:	00001097          	auipc	ra,0x1
    800032f4:	422080e7          	jalr	1058(ra) # 80004712 <holdingsleep>
    800032f8:	c92d                	beqz	a0,8000336a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032fa:	854a                	mv	a0,s2
    800032fc:	00001097          	auipc	ra,0x1
    80003300:	3d2080e7          	jalr	978(ra) # 800046ce <releasesleep>

  acquire(&bcache.lock);
    80003304:	00014517          	auipc	a0,0x14
    80003308:	1e450513          	addi	a0,a0,484 # 800174e8 <bcache>
    8000330c:	ffffe097          	auipc	ra,0xffffe
    80003310:	8da080e7          	jalr	-1830(ra) # 80000be6 <acquire>
  b->refcnt--;
    80003314:	40bc                	lw	a5,64(s1)
    80003316:	37fd                	addiw	a5,a5,-1
    80003318:	0007871b          	sext.w	a4,a5
    8000331c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000331e:	eb05                	bnez	a4,8000334e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003320:	68bc                	ld	a5,80(s1)
    80003322:	64b8                	ld	a4,72(s1)
    80003324:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003326:	64bc                	ld	a5,72(s1)
    80003328:	68b8                	ld	a4,80(s1)
    8000332a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000332c:	0001c797          	auipc	a5,0x1c
    80003330:	1bc78793          	addi	a5,a5,444 # 8001f4e8 <bcache+0x8000>
    80003334:	2b87b703          	ld	a4,696(a5)
    80003338:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000333a:	0001c717          	auipc	a4,0x1c
    8000333e:	41670713          	addi	a4,a4,1046 # 8001f750 <bcache+0x8268>
    80003342:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003344:	2b87b703          	ld	a4,696(a5)
    80003348:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000334a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000334e:	00014517          	auipc	a0,0x14
    80003352:	19a50513          	addi	a0,a0,410 # 800174e8 <bcache>
    80003356:	ffffe097          	auipc	ra,0xffffe
    8000335a:	944080e7          	jalr	-1724(ra) # 80000c9a <release>
}
    8000335e:	60e2                	ld	ra,24(sp)
    80003360:	6442                	ld	s0,16(sp)
    80003362:	64a2                	ld	s1,8(sp)
    80003364:	6902                	ld	s2,0(sp)
    80003366:	6105                	addi	sp,sp,32
    80003368:	8082                	ret
    panic("brelse");
    8000336a:	00005517          	auipc	a0,0x5
    8000336e:	29650513          	addi	a0,a0,662 # 80008600 <syscalls+0xf0>
    80003372:	ffffd097          	auipc	ra,0xffffd
    80003376:	1ce080e7          	jalr	462(ra) # 80000540 <panic>

000000008000337a <bpin>:

void
bpin(struct buf *b) {
    8000337a:	1101                	addi	sp,sp,-32
    8000337c:	ec06                	sd	ra,24(sp)
    8000337e:	e822                	sd	s0,16(sp)
    80003380:	e426                	sd	s1,8(sp)
    80003382:	1000                	addi	s0,sp,32
    80003384:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003386:	00014517          	auipc	a0,0x14
    8000338a:	16250513          	addi	a0,a0,354 # 800174e8 <bcache>
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	858080e7          	jalr	-1960(ra) # 80000be6 <acquire>
  b->refcnt++;
    80003396:	40bc                	lw	a5,64(s1)
    80003398:	2785                	addiw	a5,a5,1
    8000339a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000339c:	00014517          	auipc	a0,0x14
    800033a0:	14c50513          	addi	a0,a0,332 # 800174e8 <bcache>
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	8f6080e7          	jalr	-1802(ra) # 80000c9a <release>
}
    800033ac:	60e2                	ld	ra,24(sp)
    800033ae:	6442                	ld	s0,16(sp)
    800033b0:	64a2                	ld	s1,8(sp)
    800033b2:	6105                	addi	sp,sp,32
    800033b4:	8082                	ret

00000000800033b6 <bunpin>:

void
bunpin(struct buf *b) {
    800033b6:	1101                	addi	sp,sp,-32
    800033b8:	ec06                	sd	ra,24(sp)
    800033ba:	e822                	sd	s0,16(sp)
    800033bc:	e426                	sd	s1,8(sp)
    800033be:	1000                	addi	s0,sp,32
    800033c0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033c2:	00014517          	auipc	a0,0x14
    800033c6:	12650513          	addi	a0,a0,294 # 800174e8 <bcache>
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	81c080e7          	jalr	-2020(ra) # 80000be6 <acquire>
  b->refcnt--;
    800033d2:	40bc                	lw	a5,64(s1)
    800033d4:	37fd                	addiw	a5,a5,-1
    800033d6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033d8:	00014517          	auipc	a0,0x14
    800033dc:	11050513          	addi	a0,a0,272 # 800174e8 <bcache>
    800033e0:	ffffe097          	auipc	ra,0xffffe
    800033e4:	8ba080e7          	jalr	-1862(ra) # 80000c9a <release>
}
    800033e8:	60e2                	ld	ra,24(sp)
    800033ea:	6442                	ld	s0,16(sp)
    800033ec:	64a2                	ld	s1,8(sp)
    800033ee:	6105                	addi	sp,sp,32
    800033f0:	8082                	ret

00000000800033f2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033f2:	1101                	addi	sp,sp,-32
    800033f4:	ec06                	sd	ra,24(sp)
    800033f6:	e822                	sd	s0,16(sp)
    800033f8:	e426                	sd	s1,8(sp)
    800033fa:	e04a                	sd	s2,0(sp)
    800033fc:	1000                	addi	s0,sp,32
    800033fe:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003400:	00d5d59b          	srliw	a1,a1,0xd
    80003404:	0001c797          	auipc	a5,0x1c
    80003408:	7c07a783          	lw	a5,1984(a5) # 8001fbc4 <sb+0x1c>
    8000340c:	9dbd                	addw	a1,a1,a5
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	d9e080e7          	jalr	-610(ra) # 800031ac <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003416:	0074f713          	andi	a4,s1,7
    8000341a:	4785                	li	a5,1
    8000341c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003420:	14ce                	slli	s1,s1,0x33
    80003422:	90d9                	srli	s1,s1,0x36
    80003424:	00950733          	add	a4,a0,s1
    80003428:	05874703          	lbu	a4,88(a4)
    8000342c:	00e7f6b3          	and	a3,a5,a4
    80003430:	c69d                	beqz	a3,8000345e <bfree+0x6c>
    80003432:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003434:	94aa                	add	s1,s1,a0
    80003436:	fff7c793          	not	a5,a5
    8000343a:	8ff9                	and	a5,a5,a4
    8000343c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003440:	00001097          	auipc	ra,0x1
    80003444:	118080e7          	jalr	280(ra) # 80004558 <log_write>
  brelse(bp);
    80003448:	854a                	mv	a0,s2
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	e92080e7          	jalr	-366(ra) # 800032dc <brelse>
}
    80003452:	60e2                	ld	ra,24(sp)
    80003454:	6442                	ld	s0,16(sp)
    80003456:	64a2                	ld	s1,8(sp)
    80003458:	6902                	ld	s2,0(sp)
    8000345a:	6105                	addi	sp,sp,32
    8000345c:	8082                	ret
    panic("freeing free block");
    8000345e:	00005517          	auipc	a0,0x5
    80003462:	1aa50513          	addi	a0,a0,426 # 80008608 <syscalls+0xf8>
    80003466:	ffffd097          	auipc	ra,0xffffd
    8000346a:	0da080e7          	jalr	218(ra) # 80000540 <panic>

000000008000346e <balloc>:
{
    8000346e:	711d                	addi	sp,sp,-96
    80003470:	ec86                	sd	ra,88(sp)
    80003472:	e8a2                	sd	s0,80(sp)
    80003474:	e4a6                	sd	s1,72(sp)
    80003476:	e0ca                	sd	s2,64(sp)
    80003478:	fc4e                	sd	s3,56(sp)
    8000347a:	f852                	sd	s4,48(sp)
    8000347c:	f456                	sd	s5,40(sp)
    8000347e:	f05a                	sd	s6,32(sp)
    80003480:	ec5e                	sd	s7,24(sp)
    80003482:	e862                	sd	s8,16(sp)
    80003484:	e466                	sd	s9,8(sp)
    80003486:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003488:	0001c797          	auipc	a5,0x1c
    8000348c:	7247a783          	lw	a5,1828(a5) # 8001fbac <sb+0x4>
    80003490:	cbd1                	beqz	a5,80003524 <balloc+0xb6>
    80003492:	8baa                	mv	s7,a0
    80003494:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003496:	0001cb17          	auipc	s6,0x1c
    8000349a:	712b0b13          	addi	s6,s6,1810 # 8001fba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000349e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034a0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034a4:	6c89                	lui	s9,0x2
    800034a6:	a831                	j	800034c2 <balloc+0x54>
    brelse(bp);
    800034a8:	854a                	mv	a0,s2
    800034aa:	00000097          	auipc	ra,0x0
    800034ae:	e32080e7          	jalr	-462(ra) # 800032dc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034b2:	015c87bb          	addw	a5,s9,s5
    800034b6:	00078a9b          	sext.w	s5,a5
    800034ba:	004b2703          	lw	a4,4(s6)
    800034be:	06eaf363          	bgeu	s5,a4,80003524 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800034c2:	41fad79b          	sraiw	a5,s5,0x1f
    800034c6:	0137d79b          	srliw	a5,a5,0x13
    800034ca:	015787bb          	addw	a5,a5,s5
    800034ce:	40d7d79b          	sraiw	a5,a5,0xd
    800034d2:	01cb2583          	lw	a1,28(s6)
    800034d6:	9dbd                	addw	a1,a1,a5
    800034d8:	855e                	mv	a0,s7
    800034da:	00000097          	auipc	ra,0x0
    800034de:	cd2080e7          	jalr	-814(ra) # 800031ac <bread>
    800034e2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034e4:	004b2503          	lw	a0,4(s6)
    800034e8:	000a849b          	sext.w	s1,s5
    800034ec:	8662                	mv	a2,s8
    800034ee:	faa4fde3          	bgeu	s1,a0,800034a8 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034f2:	41f6579b          	sraiw	a5,a2,0x1f
    800034f6:	01d7d69b          	srliw	a3,a5,0x1d
    800034fa:	00c6873b          	addw	a4,a3,a2
    800034fe:	00777793          	andi	a5,a4,7
    80003502:	9f95                	subw	a5,a5,a3
    80003504:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003508:	4037571b          	sraiw	a4,a4,0x3
    8000350c:	00e906b3          	add	a3,s2,a4
    80003510:	0586c683          	lbu	a3,88(a3)
    80003514:	00d7f5b3          	and	a1,a5,a3
    80003518:	cd91                	beqz	a1,80003534 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000351a:	2605                	addiw	a2,a2,1
    8000351c:	2485                	addiw	s1,s1,1
    8000351e:	fd4618e3          	bne	a2,s4,800034ee <balloc+0x80>
    80003522:	b759                	j	800034a8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003524:	00005517          	auipc	a0,0x5
    80003528:	0fc50513          	addi	a0,a0,252 # 80008620 <syscalls+0x110>
    8000352c:	ffffd097          	auipc	ra,0xffffd
    80003530:	014080e7          	jalr	20(ra) # 80000540 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003534:	974a                	add	a4,a4,s2
    80003536:	8fd5                	or	a5,a5,a3
    80003538:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000353c:	854a                	mv	a0,s2
    8000353e:	00001097          	auipc	ra,0x1
    80003542:	01a080e7          	jalr	26(ra) # 80004558 <log_write>
        brelse(bp);
    80003546:	854a                	mv	a0,s2
    80003548:	00000097          	auipc	ra,0x0
    8000354c:	d94080e7          	jalr	-620(ra) # 800032dc <brelse>
  bp = bread(dev, bno);
    80003550:	85a6                	mv	a1,s1
    80003552:	855e                	mv	a0,s7
    80003554:	00000097          	auipc	ra,0x0
    80003558:	c58080e7          	jalr	-936(ra) # 800031ac <bread>
    8000355c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000355e:	40000613          	li	a2,1024
    80003562:	4581                	li	a1,0
    80003564:	05850513          	addi	a0,a0,88
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	77a080e7          	jalr	1914(ra) # 80000ce2 <memset>
  log_write(bp);
    80003570:	854a                	mv	a0,s2
    80003572:	00001097          	auipc	ra,0x1
    80003576:	fe6080e7          	jalr	-26(ra) # 80004558 <log_write>
  brelse(bp);
    8000357a:	854a                	mv	a0,s2
    8000357c:	00000097          	auipc	ra,0x0
    80003580:	d60080e7          	jalr	-672(ra) # 800032dc <brelse>
}
    80003584:	8526                	mv	a0,s1
    80003586:	60e6                	ld	ra,88(sp)
    80003588:	6446                	ld	s0,80(sp)
    8000358a:	64a6                	ld	s1,72(sp)
    8000358c:	6906                	ld	s2,64(sp)
    8000358e:	79e2                	ld	s3,56(sp)
    80003590:	7a42                	ld	s4,48(sp)
    80003592:	7aa2                	ld	s5,40(sp)
    80003594:	7b02                	ld	s6,32(sp)
    80003596:	6be2                	ld	s7,24(sp)
    80003598:	6c42                	ld	s8,16(sp)
    8000359a:	6ca2                	ld	s9,8(sp)
    8000359c:	6125                	addi	sp,sp,96
    8000359e:	8082                	ret

00000000800035a0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800035a0:	7179                	addi	sp,sp,-48
    800035a2:	f406                	sd	ra,40(sp)
    800035a4:	f022                	sd	s0,32(sp)
    800035a6:	ec26                	sd	s1,24(sp)
    800035a8:	e84a                	sd	s2,16(sp)
    800035aa:	e44e                	sd	s3,8(sp)
    800035ac:	e052                	sd	s4,0(sp)
    800035ae:	1800                	addi	s0,sp,48
    800035b0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035b2:	47ad                	li	a5,11
    800035b4:	04b7fe63          	bgeu	a5,a1,80003610 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800035b8:	ff45849b          	addiw	s1,a1,-12
    800035bc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035c0:	0ff00793          	li	a5,255
    800035c4:	0ae7e363          	bltu	a5,a4,8000366a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035c8:	08052583          	lw	a1,128(a0)
    800035cc:	c5ad                	beqz	a1,80003636 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035ce:	00092503          	lw	a0,0(s2)
    800035d2:	00000097          	auipc	ra,0x0
    800035d6:	bda080e7          	jalr	-1062(ra) # 800031ac <bread>
    800035da:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035dc:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035e0:	02049593          	slli	a1,s1,0x20
    800035e4:	9181                	srli	a1,a1,0x20
    800035e6:	058a                	slli	a1,a1,0x2
    800035e8:	00b784b3          	add	s1,a5,a1
    800035ec:	0004a983          	lw	s3,0(s1)
    800035f0:	04098d63          	beqz	s3,8000364a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035f4:	8552                	mv	a0,s4
    800035f6:	00000097          	auipc	ra,0x0
    800035fa:	ce6080e7          	jalr	-794(ra) # 800032dc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035fe:	854e                	mv	a0,s3
    80003600:	70a2                	ld	ra,40(sp)
    80003602:	7402                	ld	s0,32(sp)
    80003604:	64e2                	ld	s1,24(sp)
    80003606:	6942                	ld	s2,16(sp)
    80003608:	69a2                	ld	s3,8(sp)
    8000360a:	6a02                	ld	s4,0(sp)
    8000360c:	6145                	addi	sp,sp,48
    8000360e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003610:	02059493          	slli	s1,a1,0x20
    80003614:	9081                	srli	s1,s1,0x20
    80003616:	048a                	slli	s1,s1,0x2
    80003618:	94aa                	add	s1,s1,a0
    8000361a:	0504a983          	lw	s3,80(s1)
    8000361e:	fe0990e3          	bnez	s3,800035fe <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003622:	4108                	lw	a0,0(a0)
    80003624:	00000097          	auipc	ra,0x0
    80003628:	e4a080e7          	jalr	-438(ra) # 8000346e <balloc>
    8000362c:	0005099b          	sext.w	s3,a0
    80003630:	0534a823          	sw	s3,80(s1)
    80003634:	b7e9                	j	800035fe <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003636:	4108                	lw	a0,0(a0)
    80003638:	00000097          	auipc	ra,0x0
    8000363c:	e36080e7          	jalr	-458(ra) # 8000346e <balloc>
    80003640:	0005059b          	sext.w	a1,a0
    80003644:	08b92023          	sw	a1,128(s2)
    80003648:	b759                	j	800035ce <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000364a:	00092503          	lw	a0,0(s2)
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	e20080e7          	jalr	-480(ra) # 8000346e <balloc>
    80003656:	0005099b          	sext.w	s3,a0
    8000365a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000365e:	8552                	mv	a0,s4
    80003660:	00001097          	auipc	ra,0x1
    80003664:	ef8080e7          	jalr	-264(ra) # 80004558 <log_write>
    80003668:	b771                	j	800035f4 <bmap+0x54>
  panic("bmap: out of range");
    8000366a:	00005517          	auipc	a0,0x5
    8000366e:	fce50513          	addi	a0,a0,-50 # 80008638 <syscalls+0x128>
    80003672:	ffffd097          	auipc	ra,0xffffd
    80003676:	ece080e7          	jalr	-306(ra) # 80000540 <panic>

000000008000367a <iget>:
{
    8000367a:	7179                	addi	sp,sp,-48
    8000367c:	f406                	sd	ra,40(sp)
    8000367e:	f022                	sd	s0,32(sp)
    80003680:	ec26                	sd	s1,24(sp)
    80003682:	e84a                	sd	s2,16(sp)
    80003684:	e44e                	sd	s3,8(sp)
    80003686:	e052                	sd	s4,0(sp)
    80003688:	1800                	addi	s0,sp,48
    8000368a:	89aa                	mv	s3,a0
    8000368c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000368e:	0001c517          	auipc	a0,0x1c
    80003692:	53a50513          	addi	a0,a0,1338 # 8001fbc8 <itable>
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	550080e7          	jalr	1360(ra) # 80000be6 <acquire>
  empty = 0;
    8000369e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036a0:	0001c497          	auipc	s1,0x1c
    800036a4:	54048493          	addi	s1,s1,1344 # 8001fbe0 <itable+0x18>
    800036a8:	0001e697          	auipc	a3,0x1e
    800036ac:	fc868693          	addi	a3,a3,-56 # 80021670 <log>
    800036b0:	a039                	j	800036be <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036b2:	02090b63          	beqz	s2,800036e8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036b6:	08848493          	addi	s1,s1,136
    800036ba:	02d48a63          	beq	s1,a3,800036ee <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036be:	449c                	lw	a5,8(s1)
    800036c0:	fef059e3          	blez	a5,800036b2 <iget+0x38>
    800036c4:	4098                	lw	a4,0(s1)
    800036c6:	ff3716e3          	bne	a4,s3,800036b2 <iget+0x38>
    800036ca:	40d8                	lw	a4,4(s1)
    800036cc:	ff4713e3          	bne	a4,s4,800036b2 <iget+0x38>
      ip->ref++;
    800036d0:	2785                	addiw	a5,a5,1
    800036d2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036d4:	0001c517          	auipc	a0,0x1c
    800036d8:	4f450513          	addi	a0,a0,1268 # 8001fbc8 <itable>
    800036dc:	ffffd097          	auipc	ra,0xffffd
    800036e0:	5be080e7          	jalr	1470(ra) # 80000c9a <release>
      return ip;
    800036e4:	8926                	mv	s2,s1
    800036e6:	a03d                	j	80003714 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036e8:	f7f9                	bnez	a5,800036b6 <iget+0x3c>
    800036ea:	8926                	mv	s2,s1
    800036ec:	b7e9                	j	800036b6 <iget+0x3c>
  if(empty == 0)
    800036ee:	02090c63          	beqz	s2,80003726 <iget+0xac>
  ip->dev = dev;
    800036f2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036f6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036fa:	4785                	li	a5,1
    800036fc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003700:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003704:	0001c517          	auipc	a0,0x1c
    80003708:	4c450513          	addi	a0,a0,1220 # 8001fbc8 <itable>
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	58e080e7          	jalr	1422(ra) # 80000c9a <release>
}
    80003714:	854a                	mv	a0,s2
    80003716:	70a2                	ld	ra,40(sp)
    80003718:	7402                	ld	s0,32(sp)
    8000371a:	64e2                	ld	s1,24(sp)
    8000371c:	6942                	ld	s2,16(sp)
    8000371e:	69a2                	ld	s3,8(sp)
    80003720:	6a02                	ld	s4,0(sp)
    80003722:	6145                	addi	sp,sp,48
    80003724:	8082                	ret
    panic("iget: no inodes");
    80003726:	00005517          	auipc	a0,0x5
    8000372a:	f2a50513          	addi	a0,a0,-214 # 80008650 <syscalls+0x140>
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	e12080e7          	jalr	-494(ra) # 80000540 <panic>

0000000080003736 <fsinit>:
fsinit(int dev) {
    80003736:	7179                	addi	sp,sp,-48
    80003738:	f406                	sd	ra,40(sp)
    8000373a:	f022                	sd	s0,32(sp)
    8000373c:	ec26                	sd	s1,24(sp)
    8000373e:	e84a                	sd	s2,16(sp)
    80003740:	e44e                	sd	s3,8(sp)
    80003742:	1800                	addi	s0,sp,48
    80003744:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003746:	4585                	li	a1,1
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	a64080e7          	jalr	-1436(ra) # 800031ac <bread>
    80003750:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003752:	0001c997          	auipc	s3,0x1c
    80003756:	45698993          	addi	s3,s3,1110 # 8001fba8 <sb>
    8000375a:	02000613          	li	a2,32
    8000375e:	05850593          	addi	a1,a0,88
    80003762:	854e                	mv	a0,s3
    80003764:	ffffd097          	auipc	ra,0xffffd
    80003768:	5de080e7          	jalr	1502(ra) # 80000d42 <memmove>
  brelse(bp);
    8000376c:	8526                	mv	a0,s1
    8000376e:	00000097          	auipc	ra,0x0
    80003772:	b6e080e7          	jalr	-1170(ra) # 800032dc <brelse>
  if(sb.magic != FSMAGIC)
    80003776:	0009a703          	lw	a4,0(s3)
    8000377a:	102037b7          	lui	a5,0x10203
    8000377e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003782:	02f71263          	bne	a4,a5,800037a6 <fsinit+0x70>
  initlog(dev, &sb);
    80003786:	0001c597          	auipc	a1,0x1c
    8000378a:	42258593          	addi	a1,a1,1058 # 8001fba8 <sb>
    8000378e:	854a                	mv	a0,s2
    80003790:	00001097          	auipc	ra,0x1
    80003794:	b4c080e7          	jalr	-1204(ra) # 800042dc <initlog>
}
    80003798:	70a2                	ld	ra,40(sp)
    8000379a:	7402                	ld	s0,32(sp)
    8000379c:	64e2                	ld	s1,24(sp)
    8000379e:	6942                	ld	s2,16(sp)
    800037a0:	69a2                	ld	s3,8(sp)
    800037a2:	6145                	addi	sp,sp,48
    800037a4:	8082                	ret
    panic("invalid file system");
    800037a6:	00005517          	auipc	a0,0x5
    800037aa:	eba50513          	addi	a0,a0,-326 # 80008660 <syscalls+0x150>
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	d92080e7          	jalr	-622(ra) # 80000540 <panic>

00000000800037b6 <iinit>:
{
    800037b6:	7179                	addi	sp,sp,-48
    800037b8:	f406                	sd	ra,40(sp)
    800037ba:	f022                	sd	s0,32(sp)
    800037bc:	ec26                	sd	s1,24(sp)
    800037be:	e84a                	sd	s2,16(sp)
    800037c0:	e44e                	sd	s3,8(sp)
    800037c2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037c4:	00005597          	auipc	a1,0x5
    800037c8:	eb458593          	addi	a1,a1,-332 # 80008678 <syscalls+0x168>
    800037cc:	0001c517          	auipc	a0,0x1c
    800037d0:	3fc50513          	addi	a0,a0,1020 # 8001fbc8 <itable>
    800037d4:	ffffd097          	auipc	ra,0xffffd
    800037d8:	382080e7          	jalr	898(ra) # 80000b56 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037dc:	0001c497          	auipc	s1,0x1c
    800037e0:	41448493          	addi	s1,s1,1044 # 8001fbf0 <itable+0x28>
    800037e4:	0001e997          	auipc	s3,0x1e
    800037e8:	e9c98993          	addi	s3,s3,-356 # 80021680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037ec:	00005917          	auipc	s2,0x5
    800037f0:	e9490913          	addi	s2,s2,-364 # 80008680 <syscalls+0x170>
    800037f4:	85ca                	mv	a1,s2
    800037f6:	8526                	mv	a0,s1
    800037f8:	00001097          	auipc	ra,0x1
    800037fc:	e46080e7          	jalr	-442(ra) # 8000463e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003800:	08848493          	addi	s1,s1,136
    80003804:	ff3498e3          	bne	s1,s3,800037f4 <iinit+0x3e>
}
    80003808:	70a2                	ld	ra,40(sp)
    8000380a:	7402                	ld	s0,32(sp)
    8000380c:	64e2                	ld	s1,24(sp)
    8000380e:	6942                	ld	s2,16(sp)
    80003810:	69a2                	ld	s3,8(sp)
    80003812:	6145                	addi	sp,sp,48
    80003814:	8082                	ret

0000000080003816 <ialloc>:
{
    80003816:	715d                	addi	sp,sp,-80
    80003818:	e486                	sd	ra,72(sp)
    8000381a:	e0a2                	sd	s0,64(sp)
    8000381c:	fc26                	sd	s1,56(sp)
    8000381e:	f84a                	sd	s2,48(sp)
    80003820:	f44e                	sd	s3,40(sp)
    80003822:	f052                	sd	s4,32(sp)
    80003824:	ec56                	sd	s5,24(sp)
    80003826:	e85a                	sd	s6,16(sp)
    80003828:	e45e                	sd	s7,8(sp)
    8000382a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000382c:	0001c717          	auipc	a4,0x1c
    80003830:	38872703          	lw	a4,904(a4) # 8001fbb4 <sb+0xc>
    80003834:	4785                	li	a5,1
    80003836:	04e7fa63          	bgeu	a5,a4,8000388a <ialloc+0x74>
    8000383a:	8aaa                	mv	s5,a0
    8000383c:	8bae                	mv	s7,a1
    8000383e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003840:	0001ca17          	auipc	s4,0x1c
    80003844:	368a0a13          	addi	s4,s4,872 # 8001fba8 <sb>
    80003848:	00048b1b          	sext.w	s6,s1
    8000384c:	0044d593          	srli	a1,s1,0x4
    80003850:	018a2783          	lw	a5,24(s4)
    80003854:	9dbd                	addw	a1,a1,a5
    80003856:	8556                	mv	a0,s5
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	954080e7          	jalr	-1708(ra) # 800031ac <bread>
    80003860:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003862:	05850993          	addi	s3,a0,88
    80003866:	00f4f793          	andi	a5,s1,15
    8000386a:	079a                	slli	a5,a5,0x6
    8000386c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000386e:	00099783          	lh	a5,0(s3)
    80003872:	c785                	beqz	a5,8000389a <ialloc+0x84>
    brelse(bp);
    80003874:	00000097          	auipc	ra,0x0
    80003878:	a68080e7          	jalr	-1432(ra) # 800032dc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000387c:	0485                	addi	s1,s1,1
    8000387e:	00ca2703          	lw	a4,12(s4)
    80003882:	0004879b          	sext.w	a5,s1
    80003886:	fce7e1e3          	bltu	a5,a4,80003848 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000388a:	00005517          	auipc	a0,0x5
    8000388e:	dfe50513          	addi	a0,a0,-514 # 80008688 <syscalls+0x178>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	cae080e7          	jalr	-850(ra) # 80000540 <panic>
      memset(dip, 0, sizeof(*dip));
    8000389a:	04000613          	li	a2,64
    8000389e:	4581                	li	a1,0
    800038a0:	854e                	mv	a0,s3
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	440080e7          	jalr	1088(ra) # 80000ce2 <memset>
      dip->type = type;
    800038aa:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038ae:	854a                	mv	a0,s2
    800038b0:	00001097          	auipc	ra,0x1
    800038b4:	ca8080e7          	jalr	-856(ra) # 80004558 <log_write>
      brelse(bp);
    800038b8:	854a                	mv	a0,s2
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	a22080e7          	jalr	-1502(ra) # 800032dc <brelse>
      return iget(dev, inum);
    800038c2:	85da                	mv	a1,s6
    800038c4:	8556                	mv	a0,s5
    800038c6:	00000097          	auipc	ra,0x0
    800038ca:	db4080e7          	jalr	-588(ra) # 8000367a <iget>
}
    800038ce:	60a6                	ld	ra,72(sp)
    800038d0:	6406                	ld	s0,64(sp)
    800038d2:	74e2                	ld	s1,56(sp)
    800038d4:	7942                	ld	s2,48(sp)
    800038d6:	79a2                	ld	s3,40(sp)
    800038d8:	7a02                	ld	s4,32(sp)
    800038da:	6ae2                	ld	s5,24(sp)
    800038dc:	6b42                	ld	s6,16(sp)
    800038de:	6ba2                	ld	s7,8(sp)
    800038e0:	6161                	addi	sp,sp,80
    800038e2:	8082                	ret

00000000800038e4 <iupdate>:
{
    800038e4:	1101                	addi	sp,sp,-32
    800038e6:	ec06                	sd	ra,24(sp)
    800038e8:	e822                	sd	s0,16(sp)
    800038ea:	e426                	sd	s1,8(sp)
    800038ec:	e04a                	sd	s2,0(sp)
    800038ee:	1000                	addi	s0,sp,32
    800038f0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038f2:	415c                	lw	a5,4(a0)
    800038f4:	0047d79b          	srliw	a5,a5,0x4
    800038f8:	0001c597          	auipc	a1,0x1c
    800038fc:	2c85a583          	lw	a1,712(a1) # 8001fbc0 <sb+0x18>
    80003900:	9dbd                	addw	a1,a1,a5
    80003902:	4108                	lw	a0,0(a0)
    80003904:	00000097          	auipc	ra,0x0
    80003908:	8a8080e7          	jalr	-1880(ra) # 800031ac <bread>
    8000390c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000390e:	05850793          	addi	a5,a0,88
    80003912:	40c8                	lw	a0,4(s1)
    80003914:	893d                	andi	a0,a0,15
    80003916:	051a                	slli	a0,a0,0x6
    80003918:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000391a:	04449703          	lh	a4,68(s1)
    8000391e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003922:	04649703          	lh	a4,70(s1)
    80003926:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000392a:	04849703          	lh	a4,72(s1)
    8000392e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003932:	04a49703          	lh	a4,74(s1)
    80003936:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000393a:	44f8                	lw	a4,76(s1)
    8000393c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000393e:	03400613          	li	a2,52
    80003942:	05048593          	addi	a1,s1,80
    80003946:	0531                	addi	a0,a0,12
    80003948:	ffffd097          	auipc	ra,0xffffd
    8000394c:	3fa080e7          	jalr	1018(ra) # 80000d42 <memmove>
  log_write(bp);
    80003950:	854a                	mv	a0,s2
    80003952:	00001097          	auipc	ra,0x1
    80003956:	c06080e7          	jalr	-1018(ra) # 80004558 <log_write>
  brelse(bp);
    8000395a:	854a                	mv	a0,s2
    8000395c:	00000097          	auipc	ra,0x0
    80003960:	980080e7          	jalr	-1664(ra) # 800032dc <brelse>
}
    80003964:	60e2                	ld	ra,24(sp)
    80003966:	6442                	ld	s0,16(sp)
    80003968:	64a2                	ld	s1,8(sp)
    8000396a:	6902                	ld	s2,0(sp)
    8000396c:	6105                	addi	sp,sp,32
    8000396e:	8082                	ret

0000000080003970 <idup>:
{
    80003970:	1101                	addi	sp,sp,-32
    80003972:	ec06                	sd	ra,24(sp)
    80003974:	e822                	sd	s0,16(sp)
    80003976:	e426                	sd	s1,8(sp)
    80003978:	1000                	addi	s0,sp,32
    8000397a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000397c:	0001c517          	auipc	a0,0x1c
    80003980:	24c50513          	addi	a0,a0,588 # 8001fbc8 <itable>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	262080e7          	jalr	610(ra) # 80000be6 <acquire>
  ip->ref++;
    8000398c:	449c                	lw	a5,8(s1)
    8000398e:	2785                	addiw	a5,a5,1
    80003990:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003992:	0001c517          	auipc	a0,0x1c
    80003996:	23650513          	addi	a0,a0,566 # 8001fbc8 <itable>
    8000399a:	ffffd097          	auipc	ra,0xffffd
    8000399e:	300080e7          	jalr	768(ra) # 80000c9a <release>
}
    800039a2:	8526                	mv	a0,s1
    800039a4:	60e2                	ld	ra,24(sp)
    800039a6:	6442                	ld	s0,16(sp)
    800039a8:	64a2                	ld	s1,8(sp)
    800039aa:	6105                	addi	sp,sp,32
    800039ac:	8082                	ret

00000000800039ae <ilock>:
{
    800039ae:	1101                	addi	sp,sp,-32
    800039b0:	ec06                	sd	ra,24(sp)
    800039b2:	e822                	sd	s0,16(sp)
    800039b4:	e426                	sd	s1,8(sp)
    800039b6:	e04a                	sd	s2,0(sp)
    800039b8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039ba:	c115                	beqz	a0,800039de <ilock+0x30>
    800039bc:	84aa                	mv	s1,a0
    800039be:	451c                	lw	a5,8(a0)
    800039c0:	00f05f63          	blez	a5,800039de <ilock+0x30>
  acquiresleep(&ip->lock);
    800039c4:	0541                	addi	a0,a0,16
    800039c6:	00001097          	auipc	ra,0x1
    800039ca:	cb2080e7          	jalr	-846(ra) # 80004678 <acquiresleep>
  if(ip->valid == 0){
    800039ce:	40bc                	lw	a5,64(s1)
    800039d0:	cf99                	beqz	a5,800039ee <ilock+0x40>
}
    800039d2:	60e2                	ld	ra,24(sp)
    800039d4:	6442                	ld	s0,16(sp)
    800039d6:	64a2                	ld	s1,8(sp)
    800039d8:	6902                	ld	s2,0(sp)
    800039da:	6105                	addi	sp,sp,32
    800039dc:	8082                	ret
    panic("ilock");
    800039de:	00005517          	auipc	a0,0x5
    800039e2:	cc250513          	addi	a0,a0,-830 # 800086a0 <syscalls+0x190>
    800039e6:	ffffd097          	auipc	ra,0xffffd
    800039ea:	b5a080e7          	jalr	-1190(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039ee:	40dc                	lw	a5,4(s1)
    800039f0:	0047d79b          	srliw	a5,a5,0x4
    800039f4:	0001c597          	auipc	a1,0x1c
    800039f8:	1cc5a583          	lw	a1,460(a1) # 8001fbc0 <sb+0x18>
    800039fc:	9dbd                	addw	a1,a1,a5
    800039fe:	4088                	lw	a0,0(s1)
    80003a00:	fffff097          	auipc	ra,0xfffff
    80003a04:	7ac080e7          	jalr	1964(ra) # 800031ac <bread>
    80003a08:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a0a:	05850593          	addi	a1,a0,88
    80003a0e:	40dc                	lw	a5,4(s1)
    80003a10:	8bbd                	andi	a5,a5,15
    80003a12:	079a                	slli	a5,a5,0x6
    80003a14:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a16:	00059783          	lh	a5,0(a1)
    80003a1a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a1e:	00259783          	lh	a5,2(a1)
    80003a22:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a26:	00459783          	lh	a5,4(a1)
    80003a2a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a2e:	00659783          	lh	a5,6(a1)
    80003a32:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a36:	459c                	lw	a5,8(a1)
    80003a38:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a3a:	03400613          	li	a2,52
    80003a3e:	05b1                	addi	a1,a1,12
    80003a40:	05048513          	addi	a0,s1,80
    80003a44:	ffffd097          	auipc	ra,0xffffd
    80003a48:	2fe080e7          	jalr	766(ra) # 80000d42 <memmove>
    brelse(bp);
    80003a4c:	854a                	mv	a0,s2
    80003a4e:	00000097          	auipc	ra,0x0
    80003a52:	88e080e7          	jalr	-1906(ra) # 800032dc <brelse>
    ip->valid = 1;
    80003a56:	4785                	li	a5,1
    80003a58:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a5a:	04449783          	lh	a5,68(s1)
    80003a5e:	fbb5                	bnez	a5,800039d2 <ilock+0x24>
      panic("ilock: no type");
    80003a60:	00005517          	auipc	a0,0x5
    80003a64:	c4850513          	addi	a0,a0,-952 # 800086a8 <syscalls+0x198>
    80003a68:	ffffd097          	auipc	ra,0xffffd
    80003a6c:	ad8080e7          	jalr	-1320(ra) # 80000540 <panic>

0000000080003a70 <iunlock>:
{
    80003a70:	1101                	addi	sp,sp,-32
    80003a72:	ec06                	sd	ra,24(sp)
    80003a74:	e822                	sd	s0,16(sp)
    80003a76:	e426                	sd	s1,8(sp)
    80003a78:	e04a                	sd	s2,0(sp)
    80003a7a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a7c:	c905                	beqz	a0,80003aac <iunlock+0x3c>
    80003a7e:	84aa                	mv	s1,a0
    80003a80:	01050913          	addi	s2,a0,16
    80003a84:	854a                	mv	a0,s2
    80003a86:	00001097          	auipc	ra,0x1
    80003a8a:	c8c080e7          	jalr	-884(ra) # 80004712 <holdingsleep>
    80003a8e:	cd19                	beqz	a0,80003aac <iunlock+0x3c>
    80003a90:	449c                	lw	a5,8(s1)
    80003a92:	00f05d63          	blez	a5,80003aac <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a96:	854a                	mv	a0,s2
    80003a98:	00001097          	auipc	ra,0x1
    80003a9c:	c36080e7          	jalr	-970(ra) # 800046ce <releasesleep>
}
    80003aa0:	60e2                	ld	ra,24(sp)
    80003aa2:	6442                	ld	s0,16(sp)
    80003aa4:	64a2                	ld	s1,8(sp)
    80003aa6:	6902                	ld	s2,0(sp)
    80003aa8:	6105                	addi	sp,sp,32
    80003aaa:	8082                	ret
    panic("iunlock");
    80003aac:	00005517          	auipc	a0,0x5
    80003ab0:	c0c50513          	addi	a0,a0,-1012 # 800086b8 <syscalls+0x1a8>
    80003ab4:	ffffd097          	auipc	ra,0xffffd
    80003ab8:	a8c080e7          	jalr	-1396(ra) # 80000540 <panic>

0000000080003abc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003abc:	7179                	addi	sp,sp,-48
    80003abe:	f406                	sd	ra,40(sp)
    80003ac0:	f022                	sd	s0,32(sp)
    80003ac2:	ec26                	sd	s1,24(sp)
    80003ac4:	e84a                	sd	s2,16(sp)
    80003ac6:	e44e                	sd	s3,8(sp)
    80003ac8:	e052                	sd	s4,0(sp)
    80003aca:	1800                	addi	s0,sp,48
    80003acc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ace:	05050493          	addi	s1,a0,80
    80003ad2:	08050913          	addi	s2,a0,128
    80003ad6:	a021                	j	80003ade <itrunc+0x22>
    80003ad8:	0491                	addi	s1,s1,4
    80003ada:	01248d63          	beq	s1,s2,80003af4 <itrunc+0x38>
    if(ip->addrs[i]){
    80003ade:	408c                	lw	a1,0(s1)
    80003ae0:	dde5                	beqz	a1,80003ad8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ae2:	0009a503          	lw	a0,0(s3)
    80003ae6:	00000097          	auipc	ra,0x0
    80003aea:	90c080e7          	jalr	-1780(ra) # 800033f2 <bfree>
      ip->addrs[i] = 0;
    80003aee:	0004a023          	sw	zero,0(s1)
    80003af2:	b7dd                	j	80003ad8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003af4:	0809a583          	lw	a1,128(s3)
    80003af8:	e185                	bnez	a1,80003b18 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003afa:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003afe:	854e                	mv	a0,s3
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	de4080e7          	jalr	-540(ra) # 800038e4 <iupdate>
}
    80003b08:	70a2                	ld	ra,40(sp)
    80003b0a:	7402                	ld	s0,32(sp)
    80003b0c:	64e2                	ld	s1,24(sp)
    80003b0e:	6942                	ld	s2,16(sp)
    80003b10:	69a2                	ld	s3,8(sp)
    80003b12:	6a02                	ld	s4,0(sp)
    80003b14:	6145                	addi	sp,sp,48
    80003b16:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b18:	0009a503          	lw	a0,0(s3)
    80003b1c:	fffff097          	auipc	ra,0xfffff
    80003b20:	690080e7          	jalr	1680(ra) # 800031ac <bread>
    80003b24:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b26:	05850493          	addi	s1,a0,88
    80003b2a:	45850913          	addi	s2,a0,1112
    80003b2e:	a811                	j	80003b42 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b30:	0009a503          	lw	a0,0(s3)
    80003b34:	00000097          	auipc	ra,0x0
    80003b38:	8be080e7          	jalr	-1858(ra) # 800033f2 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b3c:	0491                	addi	s1,s1,4
    80003b3e:	01248563          	beq	s1,s2,80003b48 <itrunc+0x8c>
      if(a[j])
    80003b42:	408c                	lw	a1,0(s1)
    80003b44:	dde5                	beqz	a1,80003b3c <itrunc+0x80>
    80003b46:	b7ed                	j	80003b30 <itrunc+0x74>
    brelse(bp);
    80003b48:	8552                	mv	a0,s4
    80003b4a:	fffff097          	auipc	ra,0xfffff
    80003b4e:	792080e7          	jalr	1938(ra) # 800032dc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b52:	0809a583          	lw	a1,128(s3)
    80003b56:	0009a503          	lw	a0,0(s3)
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	898080e7          	jalr	-1896(ra) # 800033f2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b62:	0809a023          	sw	zero,128(s3)
    80003b66:	bf51                	j	80003afa <itrunc+0x3e>

0000000080003b68 <iput>:
{
    80003b68:	1101                	addi	sp,sp,-32
    80003b6a:	ec06                	sd	ra,24(sp)
    80003b6c:	e822                	sd	s0,16(sp)
    80003b6e:	e426                	sd	s1,8(sp)
    80003b70:	e04a                	sd	s2,0(sp)
    80003b72:	1000                	addi	s0,sp,32
    80003b74:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b76:	0001c517          	auipc	a0,0x1c
    80003b7a:	05250513          	addi	a0,a0,82 # 8001fbc8 <itable>
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	068080e7          	jalr	104(ra) # 80000be6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b86:	4498                	lw	a4,8(s1)
    80003b88:	4785                	li	a5,1
    80003b8a:	02f70363          	beq	a4,a5,80003bb0 <iput+0x48>
  ip->ref--;
    80003b8e:	449c                	lw	a5,8(s1)
    80003b90:	37fd                	addiw	a5,a5,-1
    80003b92:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b94:	0001c517          	auipc	a0,0x1c
    80003b98:	03450513          	addi	a0,a0,52 # 8001fbc8 <itable>
    80003b9c:	ffffd097          	auipc	ra,0xffffd
    80003ba0:	0fe080e7          	jalr	254(ra) # 80000c9a <release>
}
    80003ba4:	60e2                	ld	ra,24(sp)
    80003ba6:	6442                	ld	s0,16(sp)
    80003ba8:	64a2                	ld	s1,8(sp)
    80003baa:	6902                	ld	s2,0(sp)
    80003bac:	6105                	addi	sp,sp,32
    80003bae:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bb0:	40bc                	lw	a5,64(s1)
    80003bb2:	dff1                	beqz	a5,80003b8e <iput+0x26>
    80003bb4:	04a49783          	lh	a5,74(s1)
    80003bb8:	fbf9                	bnez	a5,80003b8e <iput+0x26>
    acquiresleep(&ip->lock);
    80003bba:	01048913          	addi	s2,s1,16
    80003bbe:	854a                	mv	a0,s2
    80003bc0:	00001097          	auipc	ra,0x1
    80003bc4:	ab8080e7          	jalr	-1352(ra) # 80004678 <acquiresleep>
    release(&itable.lock);
    80003bc8:	0001c517          	auipc	a0,0x1c
    80003bcc:	00050513          	mv	a0,a0
    80003bd0:	ffffd097          	auipc	ra,0xffffd
    80003bd4:	0ca080e7          	jalr	202(ra) # 80000c9a <release>
    itrunc(ip);
    80003bd8:	8526                	mv	a0,s1
    80003bda:	00000097          	auipc	ra,0x0
    80003bde:	ee2080e7          	jalr	-286(ra) # 80003abc <itrunc>
    ip->type = 0;
    80003be2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003be6:	8526                	mv	a0,s1
    80003be8:	00000097          	auipc	ra,0x0
    80003bec:	cfc080e7          	jalr	-772(ra) # 800038e4 <iupdate>
    ip->valid = 0;
    80003bf0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bf4:	854a                	mv	a0,s2
    80003bf6:	00001097          	auipc	ra,0x1
    80003bfa:	ad8080e7          	jalr	-1320(ra) # 800046ce <releasesleep>
    acquire(&itable.lock);
    80003bfe:	0001c517          	auipc	a0,0x1c
    80003c02:	fca50513          	addi	a0,a0,-54 # 8001fbc8 <itable>
    80003c06:	ffffd097          	auipc	ra,0xffffd
    80003c0a:	fe0080e7          	jalr	-32(ra) # 80000be6 <acquire>
    80003c0e:	b741                	j	80003b8e <iput+0x26>

0000000080003c10 <iunlockput>:
{
    80003c10:	1101                	addi	sp,sp,-32
    80003c12:	ec06                	sd	ra,24(sp)
    80003c14:	e822                	sd	s0,16(sp)
    80003c16:	e426                	sd	s1,8(sp)
    80003c18:	1000                	addi	s0,sp,32
    80003c1a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c1c:	00000097          	auipc	ra,0x0
    80003c20:	e54080e7          	jalr	-428(ra) # 80003a70 <iunlock>
  iput(ip);
    80003c24:	8526                	mv	a0,s1
    80003c26:	00000097          	auipc	ra,0x0
    80003c2a:	f42080e7          	jalr	-190(ra) # 80003b68 <iput>
}
    80003c2e:	60e2                	ld	ra,24(sp)
    80003c30:	6442                	ld	s0,16(sp)
    80003c32:	64a2                	ld	s1,8(sp)
    80003c34:	6105                	addi	sp,sp,32
    80003c36:	8082                	ret

0000000080003c38 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c38:	1141                	addi	sp,sp,-16
    80003c3a:	e422                	sd	s0,8(sp)
    80003c3c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c3e:	411c                	lw	a5,0(a0)
    80003c40:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c42:	415c                	lw	a5,4(a0)
    80003c44:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c46:	04451783          	lh	a5,68(a0)
    80003c4a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c4e:	04a51783          	lh	a5,74(a0)
    80003c52:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c56:	04c56783          	lwu	a5,76(a0)
    80003c5a:	e99c                	sd	a5,16(a1)
}
    80003c5c:	6422                	ld	s0,8(sp)
    80003c5e:	0141                	addi	sp,sp,16
    80003c60:	8082                	ret

0000000080003c62 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c62:	457c                	lw	a5,76(a0)
    80003c64:	0ed7e963          	bltu	a5,a3,80003d56 <readi+0xf4>
{
    80003c68:	7159                	addi	sp,sp,-112
    80003c6a:	f486                	sd	ra,104(sp)
    80003c6c:	f0a2                	sd	s0,96(sp)
    80003c6e:	eca6                	sd	s1,88(sp)
    80003c70:	e8ca                	sd	s2,80(sp)
    80003c72:	e4ce                	sd	s3,72(sp)
    80003c74:	e0d2                	sd	s4,64(sp)
    80003c76:	fc56                	sd	s5,56(sp)
    80003c78:	f85a                	sd	s6,48(sp)
    80003c7a:	f45e                	sd	s7,40(sp)
    80003c7c:	f062                	sd	s8,32(sp)
    80003c7e:	ec66                	sd	s9,24(sp)
    80003c80:	e86a                	sd	s10,16(sp)
    80003c82:	e46e                	sd	s11,8(sp)
    80003c84:	1880                	addi	s0,sp,112
    80003c86:	8baa                	mv	s7,a0
    80003c88:	8c2e                	mv	s8,a1
    80003c8a:	8ab2                	mv	s5,a2
    80003c8c:	84b6                	mv	s1,a3
    80003c8e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c90:	9f35                	addw	a4,a4,a3
    return 0;
    80003c92:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c94:	0ad76063          	bltu	a4,a3,80003d34 <readi+0xd2>
  if(off + n > ip->size)
    80003c98:	00e7f463          	bgeu	a5,a4,80003ca0 <readi+0x3e>
    n = ip->size - off;
    80003c9c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ca0:	0a0b0963          	beqz	s6,80003d52 <readi+0xf0>
    80003ca4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ca6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003caa:	5cfd                	li	s9,-1
    80003cac:	a82d                	j	80003ce6 <readi+0x84>
    80003cae:	020a1d93          	slli	s11,s4,0x20
    80003cb2:	020ddd93          	srli	s11,s11,0x20
    80003cb6:	05890613          	addi	a2,s2,88
    80003cba:	86ee                	mv	a3,s11
    80003cbc:	963a                	add	a2,a2,a4
    80003cbe:	85d6                	mv	a1,s5
    80003cc0:	8562                	mv	a0,s8
    80003cc2:	fffff097          	auipc	ra,0xfffff
    80003cc6:	93c080e7          	jalr	-1732(ra) # 800025fe <either_copyout>
    80003cca:	05950d63          	beq	a0,s9,80003d24 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003cce:	854a                	mv	a0,s2
    80003cd0:	fffff097          	auipc	ra,0xfffff
    80003cd4:	60c080e7          	jalr	1548(ra) # 800032dc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cd8:	013a09bb          	addw	s3,s4,s3
    80003cdc:	009a04bb          	addw	s1,s4,s1
    80003ce0:	9aee                	add	s5,s5,s11
    80003ce2:	0569f763          	bgeu	s3,s6,80003d30 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ce6:	000ba903          	lw	s2,0(s7)
    80003cea:	00a4d59b          	srliw	a1,s1,0xa
    80003cee:	855e                	mv	a0,s7
    80003cf0:	00000097          	auipc	ra,0x0
    80003cf4:	8b0080e7          	jalr	-1872(ra) # 800035a0 <bmap>
    80003cf8:	0005059b          	sext.w	a1,a0
    80003cfc:	854a                	mv	a0,s2
    80003cfe:	fffff097          	auipc	ra,0xfffff
    80003d02:	4ae080e7          	jalr	1198(ra) # 800031ac <bread>
    80003d06:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d08:	3ff4f713          	andi	a4,s1,1023
    80003d0c:	40ed07bb          	subw	a5,s10,a4
    80003d10:	413b06bb          	subw	a3,s6,s3
    80003d14:	8a3e                	mv	s4,a5
    80003d16:	2781                	sext.w	a5,a5
    80003d18:	0006861b          	sext.w	a2,a3
    80003d1c:	f8f679e3          	bgeu	a2,a5,80003cae <readi+0x4c>
    80003d20:	8a36                	mv	s4,a3
    80003d22:	b771                	j	80003cae <readi+0x4c>
      brelse(bp);
    80003d24:	854a                	mv	a0,s2
    80003d26:	fffff097          	auipc	ra,0xfffff
    80003d2a:	5b6080e7          	jalr	1462(ra) # 800032dc <brelse>
      tot = -1;
    80003d2e:	59fd                	li	s3,-1
  }
  return tot;
    80003d30:	0009851b          	sext.w	a0,s3
}
    80003d34:	70a6                	ld	ra,104(sp)
    80003d36:	7406                	ld	s0,96(sp)
    80003d38:	64e6                	ld	s1,88(sp)
    80003d3a:	6946                	ld	s2,80(sp)
    80003d3c:	69a6                	ld	s3,72(sp)
    80003d3e:	6a06                	ld	s4,64(sp)
    80003d40:	7ae2                	ld	s5,56(sp)
    80003d42:	7b42                	ld	s6,48(sp)
    80003d44:	7ba2                	ld	s7,40(sp)
    80003d46:	7c02                	ld	s8,32(sp)
    80003d48:	6ce2                	ld	s9,24(sp)
    80003d4a:	6d42                	ld	s10,16(sp)
    80003d4c:	6da2                	ld	s11,8(sp)
    80003d4e:	6165                	addi	sp,sp,112
    80003d50:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d52:	89da                	mv	s3,s6
    80003d54:	bff1                	j	80003d30 <readi+0xce>
    return 0;
    80003d56:	4501                	li	a0,0
}
    80003d58:	8082                	ret

0000000080003d5a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d5a:	457c                	lw	a5,76(a0)
    80003d5c:	10d7e863          	bltu	a5,a3,80003e6c <writei+0x112>
{
    80003d60:	7159                	addi	sp,sp,-112
    80003d62:	f486                	sd	ra,104(sp)
    80003d64:	f0a2                	sd	s0,96(sp)
    80003d66:	eca6                	sd	s1,88(sp)
    80003d68:	e8ca                	sd	s2,80(sp)
    80003d6a:	e4ce                	sd	s3,72(sp)
    80003d6c:	e0d2                	sd	s4,64(sp)
    80003d6e:	fc56                	sd	s5,56(sp)
    80003d70:	f85a                	sd	s6,48(sp)
    80003d72:	f45e                	sd	s7,40(sp)
    80003d74:	f062                	sd	s8,32(sp)
    80003d76:	ec66                	sd	s9,24(sp)
    80003d78:	e86a                	sd	s10,16(sp)
    80003d7a:	e46e                	sd	s11,8(sp)
    80003d7c:	1880                	addi	s0,sp,112
    80003d7e:	8b2a                	mv	s6,a0
    80003d80:	8c2e                	mv	s8,a1
    80003d82:	8ab2                	mv	s5,a2
    80003d84:	8936                	mv	s2,a3
    80003d86:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d88:	00e687bb          	addw	a5,a3,a4
    80003d8c:	0ed7e263          	bltu	a5,a3,80003e70 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d90:	00043737          	lui	a4,0x43
    80003d94:	0ef76063          	bltu	a4,a5,80003e74 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d98:	0c0b8863          	beqz	s7,80003e68 <writei+0x10e>
    80003d9c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d9e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003da2:	5cfd                	li	s9,-1
    80003da4:	a091                	j	80003de8 <writei+0x8e>
    80003da6:	02099d93          	slli	s11,s3,0x20
    80003daa:	020ddd93          	srli	s11,s11,0x20
    80003dae:	05848513          	addi	a0,s1,88
    80003db2:	86ee                	mv	a3,s11
    80003db4:	8656                	mv	a2,s5
    80003db6:	85e2                	mv	a1,s8
    80003db8:	953a                	add	a0,a0,a4
    80003dba:	fffff097          	auipc	ra,0xfffff
    80003dbe:	89a080e7          	jalr	-1894(ra) # 80002654 <either_copyin>
    80003dc2:	07950263          	beq	a0,s9,80003e26 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003dc6:	8526                	mv	a0,s1
    80003dc8:	00000097          	auipc	ra,0x0
    80003dcc:	790080e7          	jalr	1936(ra) # 80004558 <log_write>
    brelse(bp);
    80003dd0:	8526                	mv	a0,s1
    80003dd2:	fffff097          	auipc	ra,0xfffff
    80003dd6:	50a080e7          	jalr	1290(ra) # 800032dc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dda:	01498a3b          	addw	s4,s3,s4
    80003dde:	0129893b          	addw	s2,s3,s2
    80003de2:	9aee                	add	s5,s5,s11
    80003de4:	057a7663          	bgeu	s4,s7,80003e30 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003de8:	000b2483          	lw	s1,0(s6)
    80003dec:	00a9559b          	srliw	a1,s2,0xa
    80003df0:	855a                	mv	a0,s6
    80003df2:	fffff097          	auipc	ra,0xfffff
    80003df6:	7ae080e7          	jalr	1966(ra) # 800035a0 <bmap>
    80003dfa:	0005059b          	sext.w	a1,a0
    80003dfe:	8526                	mv	a0,s1
    80003e00:	fffff097          	auipc	ra,0xfffff
    80003e04:	3ac080e7          	jalr	940(ra) # 800031ac <bread>
    80003e08:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e0a:	3ff97713          	andi	a4,s2,1023
    80003e0e:	40ed07bb          	subw	a5,s10,a4
    80003e12:	414b86bb          	subw	a3,s7,s4
    80003e16:	89be                	mv	s3,a5
    80003e18:	2781                	sext.w	a5,a5
    80003e1a:	0006861b          	sext.w	a2,a3
    80003e1e:	f8f674e3          	bgeu	a2,a5,80003da6 <writei+0x4c>
    80003e22:	89b6                	mv	s3,a3
    80003e24:	b749                	j	80003da6 <writei+0x4c>
      brelse(bp);
    80003e26:	8526                	mv	a0,s1
    80003e28:	fffff097          	auipc	ra,0xfffff
    80003e2c:	4b4080e7          	jalr	1204(ra) # 800032dc <brelse>
  }

  if(off > ip->size)
    80003e30:	04cb2783          	lw	a5,76(s6)
    80003e34:	0127f463          	bgeu	a5,s2,80003e3c <writei+0xe2>
    ip->size = off;
    80003e38:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e3c:	855a                	mv	a0,s6
    80003e3e:	00000097          	auipc	ra,0x0
    80003e42:	aa6080e7          	jalr	-1370(ra) # 800038e4 <iupdate>

  return tot;
    80003e46:	000a051b          	sext.w	a0,s4
}
    80003e4a:	70a6                	ld	ra,104(sp)
    80003e4c:	7406                	ld	s0,96(sp)
    80003e4e:	64e6                	ld	s1,88(sp)
    80003e50:	6946                	ld	s2,80(sp)
    80003e52:	69a6                	ld	s3,72(sp)
    80003e54:	6a06                	ld	s4,64(sp)
    80003e56:	7ae2                	ld	s5,56(sp)
    80003e58:	7b42                	ld	s6,48(sp)
    80003e5a:	7ba2                	ld	s7,40(sp)
    80003e5c:	7c02                	ld	s8,32(sp)
    80003e5e:	6ce2                	ld	s9,24(sp)
    80003e60:	6d42                	ld	s10,16(sp)
    80003e62:	6da2                	ld	s11,8(sp)
    80003e64:	6165                	addi	sp,sp,112
    80003e66:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e68:	8a5e                	mv	s4,s7
    80003e6a:	bfc9                	j	80003e3c <writei+0xe2>
    return -1;
    80003e6c:	557d                	li	a0,-1
}
    80003e6e:	8082                	ret
    return -1;
    80003e70:	557d                	li	a0,-1
    80003e72:	bfe1                	j	80003e4a <writei+0xf0>
    return -1;
    80003e74:	557d                	li	a0,-1
    80003e76:	bfd1                	j	80003e4a <writei+0xf0>

0000000080003e78 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e78:	1141                	addi	sp,sp,-16
    80003e7a:	e406                	sd	ra,8(sp)
    80003e7c:	e022                	sd	s0,0(sp)
    80003e7e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e80:	4639                	li	a2,14
    80003e82:	ffffd097          	auipc	ra,0xffffd
    80003e86:	f38080e7          	jalr	-200(ra) # 80000dba <strncmp>
}
    80003e8a:	60a2                	ld	ra,8(sp)
    80003e8c:	6402                	ld	s0,0(sp)
    80003e8e:	0141                	addi	sp,sp,16
    80003e90:	8082                	ret

0000000080003e92 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e92:	7139                	addi	sp,sp,-64
    80003e94:	fc06                	sd	ra,56(sp)
    80003e96:	f822                	sd	s0,48(sp)
    80003e98:	f426                	sd	s1,40(sp)
    80003e9a:	f04a                	sd	s2,32(sp)
    80003e9c:	ec4e                	sd	s3,24(sp)
    80003e9e:	e852                	sd	s4,16(sp)
    80003ea0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ea2:	04451703          	lh	a4,68(a0)
    80003ea6:	4785                	li	a5,1
    80003ea8:	00f71a63          	bne	a4,a5,80003ebc <dirlookup+0x2a>
    80003eac:	892a                	mv	s2,a0
    80003eae:	89ae                	mv	s3,a1
    80003eb0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb2:	457c                	lw	a5,76(a0)
    80003eb4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003eb6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb8:	e79d                	bnez	a5,80003ee6 <dirlookup+0x54>
    80003eba:	a8a5                	j	80003f32 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ebc:	00005517          	auipc	a0,0x5
    80003ec0:	80450513          	addi	a0,a0,-2044 # 800086c0 <syscalls+0x1b0>
    80003ec4:	ffffc097          	auipc	ra,0xffffc
    80003ec8:	67c080e7          	jalr	1660(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003ecc:	00005517          	auipc	a0,0x5
    80003ed0:	80c50513          	addi	a0,a0,-2036 # 800086d8 <syscalls+0x1c8>
    80003ed4:	ffffc097          	auipc	ra,0xffffc
    80003ed8:	66c080e7          	jalr	1644(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003edc:	24c1                	addiw	s1,s1,16
    80003ede:	04c92783          	lw	a5,76(s2)
    80003ee2:	04f4f763          	bgeu	s1,a5,80003f30 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee6:	4741                	li	a4,16
    80003ee8:	86a6                	mv	a3,s1
    80003eea:	fc040613          	addi	a2,s0,-64
    80003eee:	4581                	li	a1,0
    80003ef0:	854a                	mv	a0,s2
    80003ef2:	00000097          	auipc	ra,0x0
    80003ef6:	d70080e7          	jalr	-656(ra) # 80003c62 <readi>
    80003efa:	47c1                	li	a5,16
    80003efc:	fcf518e3          	bne	a0,a5,80003ecc <dirlookup+0x3a>
    if(de.inum == 0)
    80003f00:	fc045783          	lhu	a5,-64(s0)
    80003f04:	dfe1                	beqz	a5,80003edc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f06:	fc240593          	addi	a1,s0,-62
    80003f0a:	854e                	mv	a0,s3
    80003f0c:	00000097          	auipc	ra,0x0
    80003f10:	f6c080e7          	jalr	-148(ra) # 80003e78 <namecmp>
    80003f14:	f561                	bnez	a0,80003edc <dirlookup+0x4a>
      if(poff)
    80003f16:	000a0463          	beqz	s4,80003f1e <dirlookup+0x8c>
        *poff = off;
    80003f1a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f1e:	fc045583          	lhu	a1,-64(s0)
    80003f22:	00092503          	lw	a0,0(s2)
    80003f26:	fffff097          	auipc	ra,0xfffff
    80003f2a:	754080e7          	jalr	1876(ra) # 8000367a <iget>
    80003f2e:	a011                	j	80003f32 <dirlookup+0xa0>
  return 0;
    80003f30:	4501                	li	a0,0
}
    80003f32:	70e2                	ld	ra,56(sp)
    80003f34:	7442                	ld	s0,48(sp)
    80003f36:	74a2                	ld	s1,40(sp)
    80003f38:	7902                	ld	s2,32(sp)
    80003f3a:	69e2                	ld	s3,24(sp)
    80003f3c:	6a42                	ld	s4,16(sp)
    80003f3e:	6121                	addi	sp,sp,64
    80003f40:	8082                	ret

0000000080003f42 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f42:	711d                	addi	sp,sp,-96
    80003f44:	ec86                	sd	ra,88(sp)
    80003f46:	e8a2                	sd	s0,80(sp)
    80003f48:	e4a6                	sd	s1,72(sp)
    80003f4a:	e0ca                	sd	s2,64(sp)
    80003f4c:	fc4e                	sd	s3,56(sp)
    80003f4e:	f852                	sd	s4,48(sp)
    80003f50:	f456                	sd	s5,40(sp)
    80003f52:	f05a                	sd	s6,32(sp)
    80003f54:	ec5e                	sd	s7,24(sp)
    80003f56:	e862                	sd	s8,16(sp)
    80003f58:	e466                	sd	s9,8(sp)
    80003f5a:	1080                	addi	s0,sp,96
    80003f5c:	84aa                	mv	s1,a0
    80003f5e:	8b2e                	mv	s6,a1
    80003f60:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f62:	00054703          	lbu	a4,0(a0)
    80003f66:	02f00793          	li	a5,47
    80003f6a:	02f70363          	beq	a4,a5,80003f90 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f6e:	ffffe097          	auipc	ra,0xffffe
    80003f72:	a44080e7          	jalr	-1468(ra) # 800019b2 <myproc>
    80003f76:	15053503          	ld	a0,336(a0)
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	9f6080e7          	jalr	-1546(ra) # 80003970 <idup>
    80003f82:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f84:	02f00913          	li	s2,47
  len = path - s;
    80003f88:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f8a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f8c:	4c05                	li	s8,1
    80003f8e:	a865                	j	80004046 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f90:	4585                	li	a1,1
    80003f92:	4505                	li	a0,1
    80003f94:	fffff097          	auipc	ra,0xfffff
    80003f98:	6e6080e7          	jalr	1766(ra) # 8000367a <iget>
    80003f9c:	89aa                	mv	s3,a0
    80003f9e:	b7dd                	j	80003f84 <namex+0x42>
      iunlockput(ip);
    80003fa0:	854e                	mv	a0,s3
    80003fa2:	00000097          	auipc	ra,0x0
    80003fa6:	c6e080e7          	jalr	-914(ra) # 80003c10 <iunlockput>
      return 0;
    80003faa:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fac:	854e                	mv	a0,s3
    80003fae:	60e6                	ld	ra,88(sp)
    80003fb0:	6446                	ld	s0,80(sp)
    80003fb2:	64a6                	ld	s1,72(sp)
    80003fb4:	6906                	ld	s2,64(sp)
    80003fb6:	79e2                	ld	s3,56(sp)
    80003fb8:	7a42                	ld	s4,48(sp)
    80003fba:	7aa2                	ld	s5,40(sp)
    80003fbc:	7b02                	ld	s6,32(sp)
    80003fbe:	6be2                	ld	s7,24(sp)
    80003fc0:	6c42                	ld	s8,16(sp)
    80003fc2:	6ca2                	ld	s9,8(sp)
    80003fc4:	6125                	addi	sp,sp,96
    80003fc6:	8082                	ret
      iunlock(ip);
    80003fc8:	854e                	mv	a0,s3
    80003fca:	00000097          	auipc	ra,0x0
    80003fce:	aa6080e7          	jalr	-1370(ra) # 80003a70 <iunlock>
      return ip;
    80003fd2:	bfe9                	j	80003fac <namex+0x6a>
      iunlockput(ip);
    80003fd4:	854e                	mv	a0,s3
    80003fd6:	00000097          	auipc	ra,0x0
    80003fda:	c3a080e7          	jalr	-966(ra) # 80003c10 <iunlockput>
      return 0;
    80003fde:	89d2                	mv	s3,s4
    80003fe0:	b7f1                	j	80003fac <namex+0x6a>
  len = path - s;
    80003fe2:	40b48633          	sub	a2,s1,a1
    80003fe6:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003fea:	094cd463          	bge	s9,s4,80004072 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fee:	4639                	li	a2,14
    80003ff0:	8556                	mv	a0,s5
    80003ff2:	ffffd097          	auipc	ra,0xffffd
    80003ff6:	d50080e7          	jalr	-688(ra) # 80000d42 <memmove>
  while(*path == '/')
    80003ffa:	0004c783          	lbu	a5,0(s1)
    80003ffe:	01279763          	bne	a5,s2,8000400c <namex+0xca>
    path++;
    80004002:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004004:	0004c783          	lbu	a5,0(s1)
    80004008:	ff278de3          	beq	a5,s2,80004002 <namex+0xc0>
    ilock(ip);
    8000400c:	854e                	mv	a0,s3
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	9a0080e7          	jalr	-1632(ra) # 800039ae <ilock>
    if(ip->type != T_DIR){
    80004016:	04499783          	lh	a5,68(s3)
    8000401a:	f98793e3          	bne	a5,s8,80003fa0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000401e:	000b0563          	beqz	s6,80004028 <namex+0xe6>
    80004022:	0004c783          	lbu	a5,0(s1)
    80004026:	d3cd                	beqz	a5,80003fc8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004028:	865e                	mv	a2,s7
    8000402a:	85d6                	mv	a1,s5
    8000402c:	854e                	mv	a0,s3
    8000402e:	00000097          	auipc	ra,0x0
    80004032:	e64080e7          	jalr	-412(ra) # 80003e92 <dirlookup>
    80004036:	8a2a                	mv	s4,a0
    80004038:	dd51                	beqz	a0,80003fd4 <namex+0x92>
    iunlockput(ip);
    8000403a:	854e                	mv	a0,s3
    8000403c:	00000097          	auipc	ra,0x0
    80004040:	bd4080e7          	jalr	-1068(ra) # 80003c10 <iunlockput>
    ip = next;
    80004044:	89d2                	mv	s3,s4
  while(*path == '/')
    80004046:	0004c783          	lbu	a5,0(s1)
    8000404a:	05279763          	bne	a5,s2,80004098 <namex+0x156>
    path++;
    8000404e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004050:	0004c783          	lbu	a5,0(s1)
    80004054:	ff278de3          	beq	a5,s2,8000404e <namex+0x10c>
  if(*path == 0)
    80004058:	c79d                	beqz	a5,80004086 <namex+0x144>
    path++;
    8000405a:	85a6                	mv	a1,s1
  len = path - s;
    8000405c:	8a5e                	mv	s4,s7
    8000405e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004060:	01278963          	beq	a5,s2,80004072 <namex+0x130>
    80004064:	dfbd                	beqz	a5,80003fe2 <namex+0xa0>
    path++;
    80004066:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004068:	0004c783          	lbu	a5,0(s1)
    8000406c:	ff279ce3          	bne	a5,s2,80004064 <namex+0x122>
    80004070:	bf8d                	j	80003fe2 <namex+0xa0>
    memmove(name, s, len);
    80004072:	2601                	sext.w	a2,a2
    80004074:	8556                	mv	a0,s5
    80004076:	ffffd097          	auipc	ra,0xffffd
    8000407a:	ccc080e7          	jalr	-820(ra) # 80000d42 <memmove>
    name[len] = 0;
    8000407e:	9a56                	add	s4,s4,s5
    80004080:	000a0023          	sb	zero,0(s4)
    80004084:	bf9d                	j	80003ffa <namex+0xb8>
  if(nameiparent){
    80004086:	f20b03e3          	beqz	s6,80003fac <namex+0x6a>
    iput(ip);
    8000408a:	854e                	mv	a0,s3
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	adc080e7          	jalr	-1316(ra) # 80003b68 <iput>
    return 0;
    80004094:	4981                	li	s3,0
    80004096:	bf19                	j	80003fac <namex+0x6a>
  if(*path == 0)
    80004098:	d7fd                	beqz	a5,80004086 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000409a:	0004c783          	lbu	a5,0(s1)
    8000409e:	85a6                	mv	a1,s1
    800040a0:	b7d1                	j	80004064 <namex+0x122>

00000000800040a2 <dirlink>:
{
    800040a2:	7139                	addi	sp,sp,-64
    800040a4:	fc06                	sd	ra,56(sp)
    800040a6:	f822                	sd	s0,48(sp)
    800040a8:	f426                	sd	s1,40(sp)
    800040aa:	f04a                	sd	s2,32(sp)
    800040ac:	ec4e                	sd	s3,24(sp)
    800040ae:	e852                	sd	s4,16(sp)
    800040b0:	0080                	addi	s0,sp,64
    800040b2:	892a                	mv	s2,a0
    800040b4:	8a2e                	mv	s4,a1
    800040b6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040b8:	4601                	li	a2,0
    800040ba:	00000097          	auipc	ra,0x0
    800040be:	dd8080e7          	jalr	-552(ra) # 80003e92 <dirlookup>
    800040c2:	e93d                	bnez	a0,80004138 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040c4:	04c92483          	lw	s1,76(s2)
    800040c8:	c49d                	beqz	s1,800040f6 <dirlink+0x54>
    800040ca:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040cc:	4741                	li	a4,16
    800040ce:	86a6                	mv	a3,s1
    800040d0:	fc040613          	addi	a2,s0,-64
    800040d4:	4581                	li	a1,0
    800040d6:	854a                	mv	a0,s2
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	b8a080e7          	jalr	-1142(ra) # 80003c62 <readi>
    800040e0:	47c1                	li	a5,16
    800040e2:	06f51163          	bne	a0,a5,80004144 <dirlink+0xa2>
    if(de.inum == 0)
    800040e6:	fc045783          	lhu	a5,-64(s0)
    800040ea:	c791                	beqz	a5,800040f6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ec:	24c1                	addiw	s1,s1,16
    800040ee:	04c92783          	lw	a5,76(s2)
    800040f2:	fcf4ede3          	bltu	s1,a5,800040cc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040f6:	4639                	li	a2,14
    800040f8:	85d2                	mv	a1,s4
    800040fa:	fc240513          	addi	a0,s0,-62
    800040fe:	ffffd097          	auipc	ra,0xffffd
    80004102:	cf8080e7          	jalr	-776(ra) # 80000df6 <strncpy>
  de.inum = inum;
    80004106:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000410a:	4741                	li	a4,16
    8000410c:	86a6                	mv	a3,s1
    8000410e:	fc040613          	addi	a2,s0,-64
    80004112:	4581                	li	a1,0
    80004114:	854a                	mv	a0,s2
    80004116:	00000097          	auipc	ra,0x0
    8000411a:	c44080e7          	jalr	-956(ra) # 80003d5a <writei>
    8000411e:	872a                	mv	a4,a0
    80004120:	47c1                	li	a5,16
  return 0;
    80004122:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004124:	02f71863          	bne	a4,a5,80004154 <dirlink+0xb2>
}
    80004128:	70e2                	ld	ra,56(sp)
    8000412a:	7442                	ld	s0,48(sp)
    8000412c:	74a2                	ld	s1,40(sp)
    8000412e:	7902                	ld	s2,32(sp)
    80004130:	69e2                	ld	s3,24(sp)
    80004132:	6a42                	ld	s4,16(sp)
    80004134:	6121                	addi	sp,sp,64
    80004136:	8082                	ret
    iput(ip);
    80004138:	00000097          	auipc	ra,0x0
    8000413c:	a30080e7          	jalr	-1488(ra) # 80003b68 <iput>
    return -1;
    80004140:	557d                	li	a0,-1
    80004142:	b7dd                	j	80004128 <dirlink+0x86>
      panic("dirlink read");
    80004144:	00004517          	auipc	a0,0x4
    80004148:	5a450513          	addi	a0,a0,1444 # 800086e8 <syscalls+0x1d8>
    8000414c:	ffffc097          	auipc	ra,0xffffc
    80004150:	3f4080e7          	jalr	1012(ra) # 80000540 <panic>
    panic("dirlink");
    80004154:	00004517          	auipc	a0,0x4
    80004158:	6a450513          	addi	a0,a0,1700 # 800087f8 <syscalls+0x2e8>
    8000415c:	ffffc097          	auipc	ra,0xffffc
    80004160:	3e4080e7          	jalr	996(ra) # 80000540 <panic>

0000000080004164 <namei>:

struct inode*
namei(char *path)
{
    80004164:	1101                	addi	sp,sp,-32
    80004166:	ec06                	sd	ra,24(sp)
    80004168:	e822                	sd	s0,16(sp)
    8000416a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000416c:	fe040613          	addi	a2,s0,-32
    80004170:	4581                	li	a1,0
    80004172:	00000097          	auipc	ra,0x0
    80004176:	dd0080e7          	jalr	-560(ra) # 80003f42 <namex>
}
    8000417a:	60e2                	ld	ra,24(sp)
    8000417c:	6442                	ld	s0,16(sp)
    8000417e:	6105                	addi	sp,sp,32
    80004180:	8082                	ret

0000000080004182 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004182:	1141                	addi	sp,sp,-16
    80004184:	e406                	sd	ra,8(sp)
    80004186:	e022                	sd	s0,0(sp)
    80004188:	0800                	addi	s0,sp,16
    8000418a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000418c:	4585                	li	a1,1
    8000418e:	00000097          	auipc	ra,0x0
    80004192:	db4080e7          	jalr	-588(ra) # 80003f42 <namex>
}
    80004196:	60a2                	ld	ra,8(sp)
    80004198:	6402                	ld	s0,0(sp)
    8000419a:	0141                	addi	sp,sp,16
    8000419c:	8082                	ret

000000008000419e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000419e:	1101                	addi	sp,sp,-32
    800041a0:	ec06                	sd	ra,24(sp)
    800041a2:	e822                	sd	s0,16(sp)
    800041a4:	e426                	sd	s1,8(sp)
    800041a6:	e04a                	sd	s2,0(sp)
    800041a8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041aa:	0001d917          	auipc	s2,0x1d
    800041ae:	4c690913          	addi	s2,s2,1222 # 80021670 <log>
    800041b2:	01892583          	lw	a1,24(s2)
    800041b6:	02892503          	lw	a0,40(s2)
    800041ba:	fffff097          	auipc	ra,0xfffff
    800041be:	ff2080e7          	jalr	-14(ra) # 800031ac <bread>
    800041c2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041c4:	02c92683          	lw	a3,44(s2)
    800041c8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041ca:	02d05763          	blez	a3,800041f8 <write_head+0x5a>
    800041ce:	0001d797          	auipc	a5,0x1d
    800041d2:	4d278793          	addi	a5,a5,1234 # 800216a0 <log+0x30>
    800041d6:	05c50713          	addi	a4,a0,92
    800041da:	36fd                	addiw	a3,a3,-1
    800041dc:	1682                	slli	a3,a3,0x20
    800041de:	9281                	srli	a3,a3,0x20
    800041e0:	068a                	slli	a3,a3,0x2
    800041e2:	0001d617          	auipc	a2,0x1d
    800041e6:	4c260613          	addi	a2,a2,1218 # 800216a4 <log+0x34>
    800041ea:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041ec:	4390                	lw	a2,0(a5)
    800041ee:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041f0:	0791                	addi	a5,a5,4
    800041f2:	0711                	addi	a4,a4,4
    800041f4:	fed79ce3          	bne	a5,a3,800041ec <write_head+0x4e>
  }
  bwrite(buf);
    800041f8:	8526                	mv	a0,s1
    800041fa:	fffff097          	auipc	ra,0xfffff
    800041fe:	0a4080e7          	jalr	164(ra) # 8000329e <bwrite>
  brelse(buf);
    80004202:	8526                	mv	a0,s1
    80004204:	fffff097          	auipc	ra,0xfffff
    80004208:	0d8080e7          	jalr	216(ra) # 800032dc <brelse>
}
    8000420c:	60e2                	ld	ra,24(sp)
    8000420e:	6442                	ld	s0,16(sp)
    80004210:	64a2                	ld	s1,8(sp)
    80004212:	6902                	ld	s2,0(sp)
    80004214:	6105                	addi	sp,sp,32
    80004216:	8082                	ret

0000000080004218 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004218:	0001d797          	auipc	a5,0x1d
    8000421c:	4847a783          	lw	a5,1156(a5) # 8002169c <log+0x2c>
    80004220:	0af05d63          	blez	a5,800042da <install_trans+0xc2>
{
    80004224:	7139                	addi	sp,sp,-64
    80004226:	fc06                	sd	ra,56(sp)
    80004228:	f822                	sd	s0,48(sp)
    8000422a:	f426                	sd	s1,40(sp)
    8000422c:	f04a                	sd	s2,32(sp)
    8000422e:	ec4e                	sd	s3,24(sp)
    80004230:	e852                	sd	s4,16(sp)
    80004232:	e456                	sd	s5,8(sp)
    80004234:	e05a                	sd	s6,0(sp)
    80004236:	0080                	addi	s0,sp,64
    80004238:	8b2a                	mv	s6,a0
    8000423a:	0001da97          	auipc	s5,0x1d
    8000423e:	466a8a93          	addi	s5,s5,1126 # 800216a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004242:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004244:	0001d997          	auipc	s3,0x1d
    80004248:	42c98993          	addi	s3,s3,1068 # 80021670 <log>
    8000424c:	a035                	j	80004278 <install_trans+0x60>
      bunpin(dbuf);
    8000424e:	8526                	mv	a0,s1
    80004250:	fffff097          	auipc	ra,0xfffff
    80004254:	166080e7          	jalr	358(ra) # 800033b6 <bunpin>
    brelse(lbuf);
    80004258:	854a                	mv	a0,s2
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	082080e7          	jalr	130(ra) # 800032dc <brelse>
    brelse(dbuf);
    80004262:	8526                	mv	a0,s1
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	078080e7          	jalr	120(ra) # 800032dc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000426c:	2a05                	addiw	s4,s4,1
    8000426e:	0a91                	addi	s5,s5,4
    80004270:	02c9a783          	lw	a5,44(s3)
    80004274:	04fa5963          	bge	s4,a5,800042c6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004278:	0189a583          	lw	a1,24(s3)
    8000427c:	014585bb          	addw	a1,a1,s4
    80004280:	2585                	addiw	a1,a1,1
    80004282:	0289a503          	lw	a0,40(s3)
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	f26080e7          	jalr	-218(ra) # 800031ac <bread>
    8000428e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004290:	000aa583          	lw	a1,0(s5)
    80004294:	0289a503          	lw	a0,40(s3)
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	f14080e7          	jalr	-236(ra) # 800031ac <bread>
    800042a0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042a2:	40000613          	li	a2,1024
    800042a6:	05890593          	addi	a1,s2,88
    800042aa:	05850513          	addi	a0,a0,88
    800042ae:	ffffd097          	auipc	ra,0xffffd
    800042b2:	a94080e7          	jalr	-1388(ra) # 80000d42 <memmove>
    bwrite(dbuf);  // write dst to disk
    800042b6:	8526                	mv	a0,s1
    800042b8:	fffff097          	auipc	ra,0xfffff
    800042bc:	fe6080e7          	jalr	-26(ra) # 8000329e <bwrite>
    if(recovering == 0)
    800042c0:	f80b1ce3          	bnez	s6,80004258 <install_trans+0x40>
    800042c4:	b769                	j	8000424e <install_trans+0x36>
}
    800042c6:	70e2                	ld	ra,56(sp)
    800042c8:	7442                	ld	s0,48(sp)
    800042ca:	74a2                	ld	s1,40(sp)
    800042cc:	7902                	ld	s2,32(sp)
    800042ce:	69e2                	ld	s3,24(sp)
    800042d0:	6a42                	ld	s4,16(sp)
    800042d2:	6aa2                	ld	s5,8(sp)
    800042d4:	6b02                	ld	s6,0(sp)
    800042d6:	6121                	addi	sp,sp,64
    800042d8:	8082                	ret
    800042da:	8082                	ret

00000000800042dc <initlog>:
{
    800042dc:	7179                	addi	sp,sp,-48
    800042de:	f406                	sd	ra,40(sp)
    800042e0:	f022                	sd	s0,32(sp)
    800042e2:	ec26                	sd	s1,24(sp)
    800042e4:	e84a                	sd	s2,16(sp)
    800042e6:	e44e                	sd	s3,8(sp)
    800042e8:	1800                	addi	s0,sp,48
    800042ea:	892a                	mv	s2,a0
    800042ec:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042ee:	0001d497          	auipc	s1,0x1d
    800042f2:	38248493          	addi	s1,s1,898 # 80021670 <log>
    800042f6:	00004597          	auipc	a1,0x4
    800042fa:	40258593          	addi	a1,a1,1026 # 800086f8 <syscalls+0x1e8>
    800042fe:	8526                	mv	a0,s1
    80004300:	ffffd097          	auipc	ra,0xffffd
    80004304:	856080e7          	jalr	-1962(ra) # 80000b56 <initlock>
  log.start = sb->logstart;
    80004308:	0149a583          	lw	a1,20(s3)
    8000430c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000430e:	0109a783          	lw	a5,16(s3)
    80004312:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004314:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004318:	854a                	mv	a0,s2
    8000431a:	fffff097          	auipc	ra,0xfffff
    8000431e:	e92080e7          	jalr	-366(ra) # 800031ac <bread>
  log.lh.n = lh->n;
    80004322:	4d3c                	lw	a5,88(a0)
    80004324:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004326:	02f05563          	blez	a5,80004350 <initlog+0x74>
    8000432a:	05c50713          	addi	a4,a0,92
    8000432e:	0001d697          	auipc	a3,0x1d
    80004332:	37268693          	addi	a3,a3,882 # 800216a0 <log+0x30>
    80004336:	37fd                	addiw	a5,a5,-1
    80004338:	1782                	slli	a5,a5,0x20
    8000433a:	9381                	srli	a5,a5,0x20
    8000433c:	078a                	slli	a5,a5,0x2
    8000433e:	06050613          	addi	a2,a0,96
    80004342:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004344:	4310                	lw	a2,0(a4)
    80004346:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004348:	0711                	addi	a4,a4,4
    8000434a:	0691                	addi	a3,a3,4
    8000434c:	fef71ce3          	bne	a4,a5,80004344 <initlog+0x68>
  brelse(buf);
    80004350:	fffff097          	auipc	ra,0xfffff
    80004354:	f8c080e7          	jalr	-116(ra) # 800032dc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004358:	4505                	li	a0,1
    8000435a:	00000097          	auipc	ra,0x0
    8000435e:	ebe080e7          	jalr	-322(ra) # 80004218 <install_trans>
  log.lh.n = 0;
    80004362:	0001d797          	auipc	a5,0x1d
    80004366:	3207ad23          	sw	zero,826(a5) # 8002169c <log+0x2c>
  write_head(); // clear the log
    8000436a:	00000097          	auipc	ra,0x0
    8000436e:	e34080e7          	jalr	-460(ra) # 8000419e <write_head>
}
    80004372:	70a2                	ld	ra,40(sp)
    80004374:	7402                	ld	s0,32(sp)
    80004376:	64e2                	ld	s1,24(sp)
    80004378:	6942                	ld	s2,16(sp)
    8000437a:	69a2                	ld	s3,8(sp)
    8000437c:	6145                	addi	sp,sp,48
    8000437e:	8082                	ret

0000000080004380 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004380:	1101                	addi	sp,sp,-32
    80004382:	ec06                	sd	ra,24(sp)
    80004384:	e822                	sd	s0,16(sp)
    80004386:	e426                	sd	s1,8(sp)
    80004388:	e04a                	sd	s2,0(sp)
    8000438a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000438c:	0001d517          	auipc	a0,0x1d
    80004390:	2e450513          	addi	a0,a0,740 # 80021670 <log>
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	852080e7          	jalr	-1966(ra) # 80000be6 <acquire>
  while(1){
    if(log.committing){
    8000439c:	0001d497          	auipc	s1,0x1d
    800043a0:	2d448493          	addi	s1,s1,724 # 80021670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043a4:	4979                	li	s2,30
    800043a6:	a039                	j	800043b4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800043a8:	85a6                	mv	a1,s1
    800043aa:	8526                	mv	a0,s1
    800043ac:	ffffe097          	auipc	ra,0xffffe
    800043b0:	e40080e7          	jalr	-448(ra) # 800021ec <sleep>
    if(log.committing){
    800043b4:	50dc                	lw	a5,36(s1)
    800043b6:	fbed                	bnez	a5,800043a8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043b8:	509c                	lw	a5,32(s1)
    800043ba:	0017871b          	addiw	a4,a5,1
    800043be:	0007069b          	sext.w	a3,a4
    800043c2:	0027179b          	slliw	a5,a4,0x2
    800043c6:	9fb9                	addw	a5,a5,a4
    800043c8:	0017979b          	slliw	a5,a5,0x1
    800043cc:	54d8                	lw	a4,44(s1)
    800043ce:	9fb9                	addw	a5,a5,a4
    800043d0:	00f95963          	bge	s2,a5,800043e2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043d4:	85a6                	mv	a1,s1
    800043d6:	8526                	mv	a0,s1
    800043d8:	ffffe097          	auipc	ra,0xffffe
    800043dc:	e14080e7          	jalr	-492(ra) # 800021ec <sleep>
    800043e0:	bfd1                	j	800043b4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043e2:	0001d517          	auipc	a0,0x1d
    800043e6:	28e50513          	addi	a0,a0,654 # 80021670 <log>
    800043ea:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043ec:	ffffd097          	auipc	ra,0xffffd
    800043f0:	8ae080e7          	jalr	-1874(ra) # 80000c9a <release>
      break;
    }
  }
}
    800043f4:	60e2                	ld	ra,24(sp)
    800043f6:	6442                	ld	s0,16(sp)
    800043f8:	64a2                	ld	s1,8(sp)
    800043fa:	6902                	ld	s2,0(sp)
    800043fc:	6105                	addi	sp,sp,32
    800043fe:	8082                	ret

0000000080004400 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004400:	7139                	addi	sp,sp,-64
    80004402:	fc06                	sd	ra,56(sp)
    80004404:	f822                	sd	s0,48(sp)
    80004406:	f426                	sd	s1,40(sp)
    80004408:	f04a                	sd	s2,32(sp)
    8000440a:	ec4e                	sd	s3,24(sp)
    8000440c:	e852                	sd	s4,16(sp)
    8000440e:	e456                	sd	s5,8(sp)
    80004410:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004412:	0001d497          	auipc	s1,0x1d
    80004416:	25e48493          	addi	s1,s1,606 # 80021670 <log>
    8000441a:	8526                	mv	a0,s1
    8000441c:	ffffc097          	auipc	ra,0xffffc
    80004420:	7ca080e7          	jalr	1994(ra) # 80000be6 <acquire>
  log.outstanding -= 1;
    80004424:	509c                	lw	a5,32(s1)
    80004426:	37fd                	addiw	a5,a5,-1
    80004428:	0007891b          	sext.w	s2,a5
    8000442c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000442e:	50dc                	lw	a5,36(s1)
    80004430:	efb9                	bnez	a5,8000448e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004432:	06091663          	bnez	s2,8000449e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004436:	0001d497          	auipc	s1,0x1d
    8000443a:	23a48493          	addi	s1,s1,570 # 80021670 <log>
    8000443e:	4785                	li	a5,1
    80004440:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004442:	8526                	mv	a0,s1
    80004444:	ffffd097          	auipc	ra,0xffffd
    80004448:	856080e7          	jalr	-1962(ra) # 80000c9a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000444c:	54dc                	lw	a5,44(s1)
    8000444e:	06f04763          	bgtz	a5,800044bc <end_op+0xbc>
    acquire(&log.lock);
    80004452:	0001d497          	auipc	s1,0x1d
    80004456:	21e48493          	addi	s1,s1,542 # 80021670 <log>
    8000445a:	8526                	mv	a0,s1
    8000445c:	ffffc097          	auipc	ra,0xffffc
    80004460:	78a080e7          	jalr	1930(ra) # 80000be6 <acquire>
    log.committing = 0;
    80004464:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004468:	8526                	mv	a0,s1
    8000446a:	ffffe097          	auipc	ra,0xffffe
    8000446e:	f12080e7          	jalr	-238(ra) # 8000237c <wakeup>
    release(&log.lock);
    80004472:	8526                	mv	a0,s1
    80004474:	ffffd097          	auipc	ra,0xffffd
    80004478:	826080e7          	jalr	-2010(ra) # 80000c9a <release>
}
    8000447c:	70e2                	ld	ra,56(sp)
    8000447e:	7442                	ld	s0,48(sp)
    80004480:	74a2                	ld	s1,40(sp)
    80004482:	7902                	ld	s2,32(sp)
    80004484:	69e2                	ld	s3,24(sp)
    80004486:	6a42                	ld	s4,16(sp)
    80004488:	6aa2                	ld	s5,8(sp)
    8000448a:	6121                	addi	sp,sp,64
    8000448c:	8082                	ret
    panic("log.committing");
    8000448e:	00004517          	auipc	a0,0x4
    80004492:	27250513          	addi	a0,a0,626 # 80008700 <syscalls+0x1f0>
    80004496:	ffffc097          	auipc	ra,0xffffc
    8000449a:	0aa080e7          	jalr	170(ra) # 80000540 <panic>
    wakeup(&log);
    8000449e:	0001d497          	auipc	s1,0x1d
    800044a2:	1d248493          	addi	s1,s1,466 # 80021670 <log>
    800044a6:	8526                	mv	a0,s1
    800044a8:	ffffe097          	auipc	ra,0xffffe
    800044ac:	ed4080e7          	jalr	-300(ra) # 8000237c <wakeup>
  release(&log.lock);
    800044b0:	8526                	mv	a0,s1
    800044b2:	ffffc097          	auipc	ra,0xffffc
    800044b6:	7e8080e7          	jalr	2024(ra) # 80000c9a <release>
  if(do_commit){
    800044ba:	b7c9                	j	8000447c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044bc:	0001da97          	auipc	s5,0x1d
    800044c0:	1e4a8a93          	addi	s5,s5,484 # 800216a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044c4:	0001da17          	auipc	s4,0x1d
    800044c8:	1aca0a13          	addi	s4,s4,428 # 80021670 <log>
    800044cc:	018a2583          	lw	a1,24(s4)
    800044d0:	012585bb          	addw	a1,a1,s2
    800044d4:	2585                	addiw	a1,a1,1
    800044d6:	028a2503          	lw	a0,40(s4)
    800044da:	fffff097          	auipc	ra,0xfffff
    800044de:	cd2080e7          	jalr	-814(ra) # 800031ac <bread>
    800044e2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044e4:	000aa583          	lw	a1,0(s5)
    800044e8:	028a2503          	lw	a0,40(s4)
    800044ec:	fffff097          	auipc	ra,0xfffff
    800044f0:	cc0080e7          	jalr	-832(ra) # 800031ac <bread>
    800044f4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044f6:	40000613          	li	a2,1024
    800044fa:	05850593          	addi	a1,a0,88
    800044fe:	05848513          	addi	a0,s1,88
    80004502:	ffffd097          	auipc	ra,0xffffd
    80004506:	840080e7          	jalr	-1984(ra) # 80000d42 <memmove>
    bwrite(to);  // write the log
    8000450a:	8526                	mv	a0,s1
    8000450c:	fffff097          	auipc	ra,0xfffff
    80004510:	d92080e7          	jalr	-622(ra) # 8000329e <bwrite>
    brelse(from);
    80004514:	854e                	mv	a0,s3
    80004516:	fffff097          	auipc	ra,0xfffff
    8000451a:	dc6080e7          	jalr	-570(ra) # 800032dc <brelse>
    brelse(to);
    8000451e:	8526                	mv	a0,s1
    80004520:	fffff097          	auipc	ra,0xfffff
    80004524:	dbc080e7          	jalr	-580(ra) # 800032dc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004528:	2905                	addiw	s2,s2,1
    8000452a:	0a91                	addi	s5,s5,4
    8000452c:	02ca2783          	lw	a5,44(s4)
    80004530:	f8f94ee3          	blt	s2,a5,800044cc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004534:	00000097          	auipc	ra,0x0
    80004538:	c6a080e7          	jalr	-918(ra) # 8000419e <write_head>
    install_trans(0); // Now install writes to home locations
    8000453c:	4501                	li	a0,0
    8000453e:	00000097          	auipc	ra,0x0
    80004542:	cda080e7          	jalr	-806(ra) # 80004218 <install_trans>
    log.lh.n = 0;
    80004546:	0001d797          	auipc	a5,0x1d
    8000454a:	1407ab23          	sw	zero,342(a5) # 8002169c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000454e:	00000097          	auipc	ra,0x0
    80004552:	c50080e7          	jalr	-944(ra) # 8000419e <write_head>
    80004556:	bdf5                	j	80004452 <end_op+0x52>

0000000080004558 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004558:	1101                	addi	sp,sp,-32
    8000455a:	ec06                	sd	ra,24(sp)
    8000455c:	e822                	sd	s0,16(sp)
    8000455e:	e426                	sd	s1,8(sp)
    80004560:	e04a                	sd	s2,0(sp)
    80004562:	1000                	addi	s0,sp,32
    80004564:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004566:	0001d917          	auipc	s2,0x1d
    8000456a:	10a90913          	addi	s2,s2,266 # 80021670 <log>
    8000456e:	854a                	mv	a0,s2
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	676080e7          	jalr	1654(ra) # 80000be6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004578:	02c92603          	lw	a2,44(s2)
    8000457c:	47f5                	li	a5,29
    8000457e:	06c7c563          	blt	a5,a2,800045e8 <log_write+0x90>
    80004582:	0001d797          	auipc	a5,0x1d
    80004586:	10a7a783          	lw	a5,266(a5) # 8002168c <log+0x1c>
    8000458a:	37fd                	addiw	a5,a5,-1
    8000458c:	04f65e63          	bge	a2,a5,800045e8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004590:	0001d797          	auipc	a5,0x1d
    80004594:	1007a783          	lw	a5,256(a5) # 80021690 <log+0x20>
    80004598:	06f05063          	blez	a5,800045f8 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000459c:	4781                	li	a5,0
    8000459e:	06c05563          	blez	a2,80004608 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045a2:	44cc                	lw	a1,12(s1)
    800045a4:	0001d717          	auipc	a4,0x1d
    800045a8:	0fc70713          	addi	a4,a4,252 # 800216a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045ac:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045ae:	4314                	lw	a3,0(a4)
    800045b0:	04b68c63          	beq	a3,a1,80004608 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045b4:	2785                	addiw	a5,a5,1
    800045b6:	0711                	addi	a4,a4,4
    800045b8:	fef61be3          	bne	a2,a5,800045ae <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045bc:	0621                	addi	a2,a2,8
    800045be:	060a                	slli	a2,a2,0x2
    800045c0:	0001d797          	auipc	a5,0x1d
    800045c4:	0b078793          	addi	a5,a5,176 # 80021670 <log>
    800045c8:	963e                	add	a2,a2,a5
    800045ca:	44dc                	lw	a5,12(s1)
    800045cc:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045ce:	8526                	mv	a0,s1
    800045d0:	fffff097          	auipc	ra,0xfffff
    800045d4:	daa080e7          	jalr	-598(ra) # 8000337a <bpin>
    log.lh.n++;
    800045d8:	0001d717          	auipc	a4,0x1d
    800045dc:	09870713          	addi	a4,a4,152 # 80021670 <log>
    800045e0:	575c                	lw	a5,44(a4)
    800045e2:	2785                	addiw	a5,a5,1
    800045e4:	d75c                	sw	a5,44(a4)
    800045e6:	a835                	j	80004622 <log_write+0xca>
    panic("too big a transaction");
    800045e8:	00004517          	auipc	a0,0x4
    800045ec:	12850513          	addi	a0,a0,296 # 80008710 <syscalls+0x200>
    800045f0:	ffffc097          	auipc	ra,0xffffc
    800045f4:	f50080e7          	jalr	-176(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800045f8:	00004517          	auipc	a0,0x4
    800045fc:	13050513          	addi	a0,a0,304 # 80008728 <syscalls+0x218>
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	f40080e7          	jalr	-192(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004608:	00878713          	addi	a4,a5,8
    8000460c:	00271693          	slli	a3,a4,0x2
    80004610:	0001d717          	auipc	a4,0x1d
    80004614:	06070713          	addi	a4,a4,96 # 80021670 <log>
    80004618:	9736                	add	a4,a4,a3
    8000461a:	44d4                	lw	a3,12(s1)
    8000461c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000461e:	faf608e3          	beq	a2,a5,800045ce <log_write+0x76>
  }
  release(&log.lock);
    80004622:	0001d517          	auipc	a0,0x1d
    80004626:	04e50513          	addi	a0,a0,78 # 80021670 <log>
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	670080e7          	jalr	1648(ra) # 80000c9a <release>
}
    80004632:	60e2                	ld	ra,24(sp)
    80004634:	6442                	ld	s0,16(sp)
    80004636:	64a2                	ld	s1,8(sp)
    80004638:	6902                	ld	s2,0(sp)
    8000463a:	6105                	addi	sp,sp,32
    8000463c:	8082                	ret

000000008000463e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000463e:	1101                	addi	sp,sp,-32
    80004640:	ec06                	sd	ra,24(sp)
    80004642:	e822                	sd	s0,16(sp)
    80004644:	e426                	sd	s1,8(sp)
    80004646:	e04a                	sd	s2,0(sp)
    80004648:	1000                	addi	s0,sp,32
    8000464a:	84aa                	mv	s1,a0
    8000464c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000464e:	00004597          	auipc	a1,0x4
    80004652:	0fa58593          	addi	a1,a1,250 # 80008748 <syscalls+0x238>
    80004656:	0521                	addi	a0,a0,8
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	4fe080e7          	jalr	1278(ra) # 80000b56 <initlock>
  lk->name = name;
    80004660:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004664:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004668:	0204a423          	sw	zero,40(s1)
}
    8000466c:	60e2                	ld	ra,24(sp)
    8000466e:	6442                	ld	s0,16(sp)
    80004670:	64a2                	ld	s1,8(sp)
    80004672:	6902                	ld	s2,0(sp)
    80004674:	6105                	addi	sp,sp,32
    80004676:	8082                	ret

0000000080004678 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004678:	1101                	addi	sp,sp,-32
    8000467a:	ec06                	sd	ra,24(sp)
    8000467c:	e822                	sd	s0,16(sp)
    8000467e:	e426                	sd	s1,8(sp)
    80004680:	e04a                	sd	s2,0(sp)
    80004682:	1000                	addi	s0,sp,32
    80004684:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004686:	00850913          	addi	s2,a0,8
    8000468a:	854a                	mv	a0,s2
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	55a080e7          	jalr	1370(ra) # 80000be6 <acquire>
  while (lk->locked) {
    80004694:	409c                	lw	a5,0(s1)
    80004696:	cb89                	beqz	a5,800046a8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004698:	85ca                	mv	a1,s2
    8000469a:	8526                	mv	a0,s1
    8000469c:	ffffe097          	auipc	ra,0xffffe
    800046a0:	b50080e7          	jalr	-1200(ra) # 800021ec <sleep>
  while (lk->locked) {
    800046a4:	409c                	lw	a5,0(s1)
    800046a6:	fbed                	bnez	a5,80004698 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046a8:	4785                	li	a5,1
    800046aa:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046ac:	ffffd097          	auipc	ra,0xffffd
    800046b0:	306080e7          	jalr	774(ra) # 800019b2 <myproc>
    800046b4:	591c                	lw	a5,48(a0)
    800046b6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046b8:	854a                	mv	a0,s2
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	5e0080e7          	jalr	1504(ra) # 80000c9a <release>
}
    800046c2:	60e2                	ld	ra,24(sp)
    800046c4:	6442                	ld	s0,16(sp)
    800046c6:	64a2                	ld	s1,8(sp)
    800046c8:	6902                	ld	s2,0(sp)
    800046ca:	6105                	addi	sp,sp,32
    800046cc:	8082                	ret

00000000800046ce <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046ce:	1101                	addi	sp,sp,-32
    800046d0:	ec06                	sd	ra,24(sp)
    800046d2:	e822                	sd	s0,16(sp)
    800046d4:	e426                	sd	s1,8(sp)
    800046d6:	e04a                	sd	s2,0(sp)
    800046d8:	1000                	addi	s0,sp,32
    800046da:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046dc:	00850913          	addi	s2,a0,8
    800046e0:	854a                	mv	a0,s2
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	504080e7          	jalr	1284(ra) # 80000be6 <acquire>
  lk->locked = 0;
    800046ea:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046ee:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046f2:	8526                	mv	a0,s1
    800046f4:	ffffe097          	auipc	ra,0xffffe
    800046f8:	c88080e7          	jalr	-888(ra) # 8000237c <wakeup>
  release(&lk->lk);
    800046fc:	854a                	mv	a0,s2
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	59c080e7          	jalr	1436(ra) # 80000c9a <release>
}
    80004706:	60e2                	ld	ra,24(sp)
    80004708:	6442                	ld	s0,16(sp)
    8000470a:	64a2                	ld	s1,8(sp)
    8000470c:	6902                	ld	s2,0(sp)
    8000470e:	6105                	addi	sp,sp,32
    80004710:	8082                	ret

0000000080004712 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004712:	7179                	addi	sp,sp,-48
    80004714:	f406                	sd	ra,40(sp)
    80004716:	f022                	sd	s0,32(sp)
    80004718:	ec26                	sd	s1,24(sp)
    8000471a:	e84a                	sd	s2,16(sp)
    8000471c:	e44e                	sd	s3,8(sp)
    8000471e:	1800                	addi	s0,sp,48
    80004720:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004722:	00850913          	addi	s2,a0,8
    80004726:	854a                	mv	a0,s2
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	4be080e7          	jalr	1214(ra) # 80000be6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004730:	409c                	lw	a5,0(s1)
    80004732:	ef99                	bnez	a5,80004750 <holdingsleep+0x3e>
    80004734:	4481                	li	s1,0
  release(&lk->lk);
    80004736:	854a                	mv	a0,s2
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	562080e7          	jalr	1378(ra) # 80000c9a <release>
  return r;
}
    80004740:	8526                	mv	a0,s1
    80004742:	70a2                	ld	ra,40(sp)
    80004744:	7402                	ld	s0,32(sp)
    80004746:	64e2                	ld	s1,24(sp)
    80004748:	6942                	ld	s2,16(sp)
    8000474a:	69a2                	ld	s3,8(sp)
    8000474c:	6145                	addi	sp,sp,48
    8000474e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004750:	0284a983          	lw	s3,40(s1)
    80004754:	ffffd097          	auipc	ra,0xffffd
    80004758:	25e080e7          	jalr	606(ra) # 800019b2 <myproc>
    8000475c:	5904                	lw	s1,48(a0)
    8000475e:	413484b3          	sub	s1,s1,s3
    80004762:	0014b493          	seqz	s1,s1
    80004766:	bfc1                	j	80004736 <holdingsleep+0x24>

0000000080004768 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004768:	1141                	addi	sp,sp,-16
    8000476a:	e406                	sd	ra,8(sp)
    8000476c:	e022                	sd	s0,0(sp)
    8000476e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004770:	00004597          	auipc	a1,0x4
    80004774:	fe858593          	addi	a1,a1,-24 # 80008758 <syscalls+0x248>
    80004778:	0001d517          	auipc	a0,0x1d
    8000477c:	04050513          	addi	a0,a0,64 # 800217b8 <ftable>
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	3d6080e7          	jalr	982(ra) # 80000b56 <initlock>
}
    80004788:	60a2                	ld	ra,8(sp)
    8000478a:	6402                	ld	s0,0(sp)
    8000478c:	0141                	addi	sp,sp,16
    8000478e:	8082                	ret

0000000080004790 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004790:	1101                	addi	sp,sp,-32
    80004792:	ec06                	sd	ra,24(sp)
    80004794:	e822                	sd	s0,16(sp)
    80004796:	e426                	sd	s1,8(sp)
    80004798:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000479a:	0001d517          	auipc	a0,0x1d
    8000479e:	01e50513          	addi	a0,a0,30 # 800217b8 <ftable>
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	444080e7          	jalr	1092(ra) # 80000be6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047aa:	0001d497          	auipc	s1,0x1d
    800047ae:	02648493          	addi	s1,s1,38 # 800217d0 <ftable+0x18>
    800047b2:	0001e717          	auipc	a4,0x1e
    800047b6:	fbe70713          	addi	a4,a4,-66 # 80022770 <ftable+0xfb8>
    if(f->ref == 0){
    800047ba:	40dc                	lw	a5,4(s1)
    800047bc:	cf99                	beqz	a5,800047da <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047be:	02848493          	addi	s1,s1,40
    800047c2:	fee49ce3          	bne	s1,a4,800047ba <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047c6:	0001d517          	auipc	a0,0x1d
    800047ca:	ff250513          	addi	a0,a0,-14 # 800217b8 <ftable>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	4cc080e7          	jalr	1228(ra) # 80000c9a <release>
  return 0;
    800047d6:	4481                	li	s1,0
    800047d8:	a819                	j	800047ee <filealloc+0x5e>
      f->ref = 1;
    800047da:	4785                	li	a5,1
    800047dc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047de:	0001d517          	auipc	a0,0x1d
    800047e2:	fda50513          	addi	a0,a0,-38 # 800217b8 <ftable>
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	4b4080e7          	jalr	1204(ra) # 80000c9a <release>
}
    800047ee:	8526                	mv	a0,s1
    800047f0:	60e2                	ld	ra,24(sp)
    800047f2:	6442                	ld	s0,16(sp)
    800047f4:	64a2                	ld	s1,8(sp)
    800047f6:	6105                	addi	sp,sp,32
    800047f8:	8082                	ret

00000000800047fa <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047fa:	1101                	addi	sp,sp,-32
    800047fc:	ec06                	sd	ra,24(sp)
    800047fe:	e822                	sd	s0,16(sp)
    80004800:	e426                	sd	s1,8(sp)
    80004802:	1000                	addi	s0,sp,32
    80004804:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004806:	0001d517          	auipc	a0,0x1d
    8000480a:	fb250513          	addi	a0,a0,-78 # 800217b8 <ftable>
    8000480e:	ffffc097          	auipc	ra,0xffffc
    80004812:	3d8080e7          	jalr	984(ra) # 80000be6 <acquire>
  if(f->ref < 1)
    80004816:	40dc                	lw	a5,4(s1)
    80004818:	02f05263          	blez	a5,8000483c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000481c:	2785                	addiw	a5,a5,1
    8000481e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004820:	0001d517          	auipc	a0,0x1d
    80004824:	f9850513          	addi	a0,a0,-104 # 800217b8 <ftable>
    80004828:	ffffc097          	auipc	ra,0xffffc
    8000482c:	472080e7          	jalr	1138(ra) # 80000c9a <release>
  return f;
}
    80004830:	8526                	mv	a0,s1
    80004832:	60e2                	ld	ra,24(sp)
    80004834:	6442                	ld	s0,16(sp)
    80004836:	64a2                	ld	s1,8(sp)
    80004838:	6105                	addi	sp,sp,32
    8000483a:	8082                	ret
    panic("filedup");
    8000483c:	00004517          	auipc	a0,0x4
    80004840:	f2450513          	addi	a0,a0,-220 # 80008760 <syscalls+0x250>
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	cfc080e7          	jalr	-772(ra) # 80000540 <panic>

000000008000484c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000484c:	7139                	addi	sp,sp,-64
    8000484e:	fc06                	sd	ra,56(sp)
    80004850:	f822                	sd	s0,48(sp)
    80004852:	f426                	sd	s1,40(sp)
    80004854:	f04a                	sd	s2,32(sp)
    80004856:	ec4e                	sd	s3,24(sp)
    80004858:	e852                	sd	s4,16(sp)
    8000485a:	e456                	sd	s5,8(sp)
    8000485c:	0080                	addi	s0,sp,64
    8000485e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004860:	0001d517          	auipc	a0,0x1d
    80004864:	f5850513          	addi	a0,a0,-168 # 800217b8 <ftable>
    80004868:	ffffc097          	auipc	ra,0xffffc
    8000486c:	37e080e7          	jalr	894(ra) # 80000be6 <acquire>
  if(f->ref < 1)
    80004870:	40dc                	lw	a5,4(s1)
    80004872:	06f05163          	blez	a5,800048d4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004876:	37fd                	addiw	a5,a5,-1
    80004878:	0007871b          	sext.w	a4,a5
    8000487c:	c0dc                	sw	a5,4(s1)
    8000487e:	06e04363          	bgtz	a4,800048e4 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004882:	0004a903          	lw	s2,0(s1)
    80004886:	0094ca83          	lbu	s5,9(s1)
    8000488a:	0104ba03          	ld	s4,16(s1)
    8000488e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004892:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004896:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000489a:	0001d517          	auipc	a0,0x1d
    8000489e:	f1e50513          	addi	a0,a0,-226 # 800217b8 <ftable>
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	3f8080e7          	jalr	1016(ra) # 80000c9a <release>

  if(ff.type == FD_PIPE){
    800048aa:	4785                	li	a5,1
    800048ac:	04f90d63          	beq	s2,a5,80004906 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048b0:	3979                	addiw	s2,s2,-2
    800048b2:	4785                	li	a5,1
    800048b4:	0527e063          	bltu	a5,s2,800048f4 <fileclose+0xa8>
    begin_op();
    800048b8:	00000097          	auipc	ra,0x0
    800048bc:	ac8080e7          	jalr	-1336(ra) # 80004380 <begin_op>
    iput(ff.ip);
    800048c0:	854e                	mv	a0,s3
    800048c2:	fffff097          	auipc	ra,0xfffff
    800048c6:	2a6080e7          	jalr	678(ra) # 80003b68 <iput>
    end_op();
    800048ca:	00000097          	auipc	ra,0x0
    800048ce:	b36080e7          	jalr	-1226(ra) # 80004400 <end_op>
    800048d2:	a00d                	j	800048f4 <fileclose+0xa8>
    panic("fileclose");
    800048d4:	00004517          	auipc	a0,0x4
    800048d8:	e9450513          	addi	a0,a0,-364 # 80008768 <syscalls+0x258>
    800048dc:	ffffc097          	auipc	ra,0xffffc
    800048e0:	c64080e7          	jalr	-924(ra) # 80000540 <panic>
    release(&ftable.lock);
    800048e4:	0001d517          	auipc	a0,0x1d
    800048e8:	ed450513          	addi	a0,a0,-300 # 800217b8 <ftable>
    800048ec:	ffffc097          	auipc	ra,0xffffc
    800048f0:	3ae080e7          	jalr	942(ra) # 80000c9a <release>
  }
}
    800048f4:	70e2                	ld	ra,56(sp)
    800048f6:	7442                	ld	s0,48(sp)
    800048f8:	74a2                	ld	s1,40(sp)
    800048fa:	7902                	ld	s2,32(sp)
    800048fc:	69e2                	ld	s3,24(sp)
    800048fe:	6a42                	ld	s4,16(sp)
    80004900:	6aa2                	ld	s5,8(sp)
    80004902:	6121                	addi	sp,sp,64
    80004904:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004906:	85d6                	mv	a1,s5
    80004908:	8552                	mv	a0,s4
    8000490a:	00000097          	auipc	ra,0x0
    8000490e:	34c080e7          	jalr	844(ra) # 80004c56 <pipeclose>
    80004912:	b7cd                	j	800048f4 <fileclose+0xa8>

0000000080004914 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004914:	715d                	addi	sp,sp,-80
    80004916:	e486                	sd	ra,72(sp)
    80004918:	e0a2                	sd	s0,64(sp)
    8000491a:	fc26                	sd	s1,56(sp)
    8000491c:	f84a                	sd	s2,48(sp)
    8000491e:	f44e                	sd	s3,40(sp)
    80004920:	0880                	addi	s0,sp,80
    80004922:	84aa                	mv	s1,a0
    80004924:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004926:	ffffd097          	auipc	ra,0xffffd
    8000492a:	08c080e7          	jalr	140(ra) # 800019b2 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000492e:	409c                	lw	a5,0(s1)
    80004930:	37f9                	addiw	a5,a5,-2
    80004932:	4705                	li	a4,1
    80004934:	04f76763          	bltu	a4,a5,80004982 <filestat+0x6e>
    80004938:	892a                	mv	s2,a0
    ilock(f->ip);
    8000493a:	6c88                	ld	a0,24(s1)
    8000493c:	fffff097          	auipc	ra,0xfffff
    80004940:	072080e7          	jalr	114(ra) # 800039ae <ilock>
    stati(f->ip, &st);
    80004944:	fb840593          	addi	a1,s0,-72
    80004948:	6c88                	ld	a0,24(s1)
    8000494a:	fffff097          	auipc	ra,0xfffff
    8000494e:	2ee080e7          	jalr	750(ra) # 80003c38 <stati>
    iunlock(f->ip);
    80004952:	6c88                	ld	a0,24(s1)
    80004954:	fffff097          	auipc	ra,0xfffff
    80004958:	11c080e7          	jalr	284(ra) # 80003a70 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000495c:	46e1                	li	a3,24
    8000495e:	fb840613          	addi	a2,s0,-72
    80004962:	85ce                	mv	a1,s3
    80004964:	05093503          	ld	a0,80(s2)
    80004968:	ffffd097          	auipc	ra,0xffffd
    8000496c:	d0c080e7          	jalr	-756(ra) # 80001674 <copyout>
    80004970:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004974:	60a6                	ld	ra,72(sp)
    80004976:	6406                	ld	s0,64(sp)
    80004978:	74e2                	ld	s1,56(sp)
    8000497a:	7942                	ld	s2,48(sp)
    8000497c:	79a2                	ld	s3,40(sp)
    8000497e:	6161                	addi	sp,sp,80
    80004980:	8082                	ret
  return -1;
    80004982:	557d                	li	a0,-1
    80004984:	bfc5                	j	80004974 <filestat+0x60>

0000000080004986 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004986:	7179                	addi	sp,sp,-48
    80004988:	f406                	sd	ra,40(sp)
    8000498a:	f022                	sd	s0,32(sp)
    8000498c:	ec26                	sd	s1,24(sp)
    8000498e:	e84a                	sd	s2,16(sp)
    80004990:	e44e                	sd	s3,8(sp)
    80004992:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004994:	00854783          	lbu	a5,8(a0)
    80004998:	c3d5                	beqz	a5,80004a3c <fileread+0xb6>
    8000499a:	84aa                	mv	s1,a0
    8000499c:	89ae                	mv	s3,a1
    8000499e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049a0:	411c                	lw	a5,0(a0)
    800049a2:	4705                	li	a4,1
    800049a4:	04e78963          	beq	a5,a4,800049f6 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049a8:	470d                	li	a4,3
    800049aa:	04e78d63          	beq	a5,a4,80004a04 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049ae:	4709                	li	a4,2
    800049b0:	06e79e63          	bne	a5,a4,80004a2c <fileread+0xa6>
    ilock(f->ip);
    800049b4:	6d08                	ld	a0,24(a0)
    800049b6:	fffff097          	auipc	ra,0xfffff
    800049ba:	ff8080e7          	jalr	-8(ra) # 800039ae <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049be:	874a                	mv	a4,s2
    800049c0:	5094                	lw	a3,32(s1)
    800049c2:	864e                	mv	a2,s3
    800049c4:	4585                	li	a1,1
    800049c6:	6c88                	ld	a0,24(s1)
    800049c8:	fffff097          	auipc	ra,0xfffff
    800049cc:	29a080e7          	jalr	666(ra) # 80003c62 <readi>
    800049d0:	892a                	mv	s2,a0
    800049d2:	00a05563          	blez	a0,800049dc <fileread+0x56>
      f->off += r;
    800049d6:	509c                	lw	a5,32(s1)
    800049d8:	9fa9                	addw	a5,a5,a0
    800049da:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049dc:	6c88                	ld	a0,24(s1)
    800049de:	fffff097          	auipc	ra,0xfffff
    800049e2:	092080e7          	jalr	146(ra) # 80003a70 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049e6:	854a                	mv	a0,s2
    800049e8:	70a2                	ld	ra,40(sp)
    800049ea:	7402                	ld	s0,32(sp)
    800049ec:	64e2                	ld	s1,24(sp)
    800049ee:	6942                	ld	s2,16(sp)
    800049f0:	69a2                	ld	s3,8(sp)
    800049f2:	6145                	addi	sp,sp,48
    800049f4:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049f6:	6908                	ld	a0,16(a0)
    800049f8:	00000097          	auipc	ra,0x0
    800049fc:	3ca080e7          	jalr	970(ra) # 80004dc2 <piperead>
    80004a00:	892a                	mv	s2,a0
    80004a02:	b7d5                	j	800049e6 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a04:	02451783          	lh	a5,36(a0)
    80004a08:	03079693          	slli	a3,a5,0x30
    80004a0c:	92c1                	srli	a3,a3,0x30
    80004a0e:	4725                	li	a4,9
    80004a10:	02d76863          	bltu	a4,a3,80004a40 <fileread+0xba>
    80004a14:	0792                	slli	a5,a5,0x4
    80004a16:	0001d717          	auipc	a4,0x1d
    80004a1a:	d0270713          	addi	a4,a4,-766 # 80021718 <devsw>
    80004a1e:	97ba                	add	a5,a5,a4
    80004a20:	639c                	ld	a5,0(a5)
    80004a22:	c38d                	beqz	a5,80004a44 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a24:	4505                	li	a0,1
    80004a26:	9782                	jalr	a5
    80004a28:	892a                	mv	s2,a0
    80004a2a:	bf75                	j	800049e6 <fileread+0x60>
    panic("fileread");
    80004a2c:	00004517          	auipc	a0,0x4
    80004a30:	d4c50513          	addi	a0,a0,-692 # 80008778 <syscalls+0x268>
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	b0c080e7          	jalr	-1268(ra) # 80000540 <panic>
    return -1;
    80004a3c:	597d                	li	s2,-1
    80004a3e:	b765                	j	800049e6 <fileread+0x60>
      return -1;
    80004a40:	597d                	li	s2,-1
    80004a42:	b755                	j	800049e6 <fileread+0x60>
    80004a44:	597d                	li	s2,-1
    80004a46:	b745                	j	800049e6 <fileread+0x60>

0000000080004a48 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a48:	715d                	addi	sp,sp,-80
    80004a4a:	e486                	sd	ra,72(sp)
    80004a4c:	e0a2                	sd	s0,64(sp)
    80004a4e:	fc26                	sd	s1,56(sp)
    80004a50:	f84a                	sd	s2,48(sp)
    80004a52:	f44e                	sd	s3,40(sp)
    80004a54:	f052                	sd	s4,32(sp)
    80004a56:	ec56                	sd	s5,24(sp)
    80004a58:	e85a                	sd	s6,16(sp)
    80004a5a:	e45e                	sd	s7,8(sp)
    80004a5c:	e062                	sd	s8,0(sp)
    80004a5e:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a60:	00954783          	lbu	a5,9(a0)
    80004a64:	10078663          	beqz	a5,80004b70 <filewrite+0x128>
    80004a68:	892a                	mv	s2,a0
    80004a6a:	8aae                	mv	s5,a1
    80004a6c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a6e:	411c                	lw	a5,0(a0)
    80004a70:	4705                	li	a4,1
    80004a72:	02e78263          	beq	a5,a4,80004a96 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a76:	470d                	li	a4,3
    80004a78:	02e78663          	beq	a5,a4,80004aa4 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a7c:	4709                	li	a4,2
    80004a7e:	0ee79163          	bne	a5,a4,80004b60 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a82:	0ac05d63          	blez	a2,80004b3c <filewrite+0xf4>
    int i = 0;
    80004a86:	4981                	li	s3,0
    80004a88:	6b05                	lui	s6,0x1
    80004a8a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a8e:	6b85                	lui	s7,0x1
    80004a90:	c00b8b9b          	addiw	s7,s7,-1024
    80004a94:	a861                	j	80004b2c <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a96:	6908                	ld	a0,16(a0)
    80004a98:	00000097          	auipc	ra,0x0
    80004a9c:	22e080e7          	jalr	558(ra) # 80004cc6 <pipewrite>
    80004aa0:	8a2a                	mv	s4,a0
    80004aa2:	a045                	j	80004b42 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004aa4:	02451783          	lh	a5,36(a0)
    80004aa8:	03079693          	slli	a3,a5,0x30
    80004aac:	92c1                	srli	a3,a3,0x30
    80004aae:	4725                	li	a4,9
    80004ab0:	0cd76263          	bltu	a4,a3,80004b74 <filewrite+0x12c>
    80004ab4:	0792                	slli	a5,a5,0x4
    80004ab6:	0001d717          	auipc	a4,0x1d
    80004aba:	c6270713          	addi	a4,a4,-926 # 80021718 <devsw>
    80004abe:	97ba                	add	a5,a5,a4
    80004ac0:	679c                	ld	a5,8(a5)
    80004ac2:	cbdd                	beqz	a5,80004b78 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ac4:	4505                	li	a0,1
    80004ac6:	9782                	jalr	a5
    80004ac8:	8a2a                	mv	s4,a0
    80004aca:	a8a5                	j	80004b42 <filewrite+0xfa>
    80004acc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ad0:	00000097          	auipc	ra,0x0
    80004ad4:	8b0080e7          	jalr	-1872(ra) # 80004380 <begin_op>
      ilock(f->ip);
    80004ad8:	01893503          	ld	a0,24(s2)
    80004adc:	fffff097          	auipc	ra,0xfffff
    80004ae0:	ed2080e7          	jalr	-302(ra) # 800039ae <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ae4:	8762                	mv	a4,s8
    80004ae6:	02092683          	lw	a3,32(s2)
    80004aea:	01598633          	add	a2,s3,s5
    80004aee:	4585                	li	a1,1
    80004af0:	01893503          	ld	a0,24(s2)
    80004af4:	fffff097          	auipc	ra,0xfffff
    80004af8:	266080e7          	jalr	614(ra) # 80003d5a <writei>
    80004afc:	84aa                	mv	s1,a0
    80004afe:	00a05763          	blez	a0,80004b0c <filewrite+0xc4>
        f->off += r;
    80004b02:	02092783          	lw	a5,32(s2)
    80004b06:	9fa9                	addw	a5,a5,a0
    80004b08:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b0c:	01893503          	ld	a0,24(s2)
    80004b10:	fffff097          	auipc	ra,0xfffff
    80004b14:	f60080e7          	jalr	-160(ra) # 80003a70 <iunlock>
      end_op();
    80004b18:	00000097          	auipc	ra,0x0
    80004b1c:	8e8080e7          	jalr	-1816(ra) # 80004400 <end_op>

      if(r != n1){
    80004b20:	009c1f63          	bne	s8,s1,80004b3e <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b24:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b28:	0149db63          	bge	s3,s4,80004b3e <filewrite+0xf6>
      int n1 = n - i;
    80004b2c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b30:	84be                	mv	s1,a5
    80004b32:	2781                	sext.w	a5,a5
    80004b34:	f8fb5ce3          	bge	s6,a5,80004acc <filewrite+0x84>
    80004b38:	84de                	mv	s1,s7
    80004b3a:	bf49                	j	80004acc <filewrite+0x84>
    int i = 0;
    80004b3c:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b3e:	013a1f63          	bne	s4,s3,80004b5c <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b42:	8552                	mv	a0,s4
    80004b44:	60a6                	ld	ra,72(sp)
    80004b46:	6406                	ld	s0,64(sp)
    80004b48:	74e2                	ld	s1,56(sp)
    80004b4a:	7942                	ld	s2,48(sp)
    80004b4c:	79a2                	ld	s3,40(sp)
    80004b4e:	7a02                	ld	s4,32(sp)
    80004b50:	6ae2                	ld	s5,24(sp)
    80004b52:	6b42                	ld	s6,16(sp)
    80004b54:	6ba2                	ld	s7,8(sp)
    80004b56:	6c02                	ld	s8,0(sp)
    80004b58:	6161                	addi	sp,sp,80
    80004b5a:	8082                	ret
    ret = (i == n ? n : -1);
    80004b5c:	5a7d                	li	s4,-1
    80004b5e:	b7d5                	j	80004b42 <filewrite+0xfa>
    panic("filewrite");
    80004b60:	00004517          	auipc	a0,0x4
    80004b64:	c2850513          	addi	a0,a0,-984 # 80008788 <syscalls+0x278>
    80004b68:	ffffc097          	auipc	ra,0xffffc
    80004b6c:	9d8080e7          	jalr	-1576(ra) # 80000540 <panic>
    return -1;
    80004b70:	5a7d                	li	s4,-1
    80004b72:	bfc1                	j	80004b42 <filewrite+0xfa>
      return -1;
    80004b74:	5a7d                	li	s4,-1
    80004b76:	b7f1                	j	80004b42 <filewrite+0xfa>
    80004b78:	5a7d                	li	s4,-1
    80004b7a:	b7e1                	j	80004b42 <filewrite+0xfa>

0000000080004b7c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b7c:	7179                	addi	sp,sp,-48
    80004b7e:	f406                	sd	ra,40(sp)
    80004b80:	f022                	sd	s0,32(sp)
    80004b82:	ec26                	sd	s1,24(sp)
    80004b84:	e84a                	sd	s2,16(sp)
    80004b86:	e44e                	sd	s3,8(sp)
    80004b88:	e052                	sd	s4,0(sp)
    80004b8a:	1800                	addi	s0,sp,48
    80004b8c:	84aa                	mv	s1,a0
    80004b8e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b90:	0005b023          	sd	zero,0(a1)
    80004b94:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b98:	00000097          	auipc	ra,0x0
    80004b9c:	bf8080e7          	jalr	-1032(ra) # 80004790 <filealloc>
    80004ba0:	e088                	sd	a0,0(s1)
    80004ba2:	c551                	beqz	a0,80004c2e <pipealloc+0xb2>
    80004ba4:	00000097          	auipc	ra,0x0
    80004ba8:	bec080e7          	jalr	-1044(ra) # 80004790 <filealloc>
    80004bac:	00aa3023          	sd	a0,0(s4)
    80004bb0:	c92d                	beqz	a0,80004c22 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	f44080e7          	jalr	-188(ra) # 80000af6 <kalloc>
    80004bba:	892a                	mv	s2,a0
    80004bbc:	c125                	beqz	a0,80004c1c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bbe:	4985                	li	s3,1
    80004bc0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bc4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bc8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bcc:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bd0:	00004597          	auipc	a1,0x4
    80004bd4:	bc858593          	addi	a1,a1,-1080 # 80008798 <syscalls+0x288>
    80004bd8:	ffffc097          	auipc	ra,0xffffc
    80004bdc:	f7e080e7          	jalr	-130(ra) # 80000b56 <initlock>
  (*f0)->type = FD_PIPE;
    80004be0:	609c                	ld	a5,0(s1)
    80004be2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004be6:	609c                	ld	a5,0(s1)
    80004be8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004bec:	609c                	ld	a5,0(s1)
    80004bee:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bf2:	609c                	ld	a5,0(s1)
    80004bf4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bf8:	000a3783          	ld	a5,0(s4)
    80004bfc:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c00:	000a3783          	ld	a5,0(s4)
    80004c04:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c08:	000a3783          	ld	a5,0(s4)
    80004c0c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c10:	000a3783          	ld	a5,0(s4)
    80004c14:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c18:	4501                	li	a0,0
    80004c1a:	a025                	j	80004c42 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c1c:	6088                	ld	a0,0(s1)
    80004c1e:	e501                	bnez	a0,80004c26 <pipealloc+0xaa>
    80004c20:	a039                	j	80004c2e <pipealloc+0xb2>
    80004c22:	6088                	ld	a0,0(s1)
    80004c24:	c51d                	beqz	a0,80004c52 <pipealloc+0xd6>
    fileclose(*f0);
    80004c26:	00000097          	auipc	ra,0x0
    80004c2a:	c26080e7          	jalr	-986(ra) # 8000484c <fileclose>
  if(*f1)
    80004c2e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c32:	557d                	li	a0,-1
  if(*f1)
    80004c34:	c799                	beqz	a5,80004c42 <pipealloc+0xc6>
    fileclose(*f1);
    80004c36:	853e                	mv	a0,a5
    80004c38:	00000097          	auipc	ra,0x0
    80004c3c:	c14080e7          	jalr	-1004(ra) # 8000484c <fileclose>
  return -1;
    80004c40:	557d                	li	a0,-1
}
    80004c42:	70a2                	ld	ra,40(sp)
    80004c44:	7402                	ld	s0,32(sp)
    80004c46:	64e2                	ld	s1,24(sp)
    80004c48:	6942                	ld	s2,16(sp)
    80004c4a:	69a2                	ld	s3,8(sp)
    80004c4c:	6a02                	ld	s4,0(sp)
    80004c4e:	6145                	addi	sp,sp,48
    80004c50:	8082                	ret
  return -1;
    80004c52:	557d                	li	a0,-1
    80004c54:	b7fd                	j	80004c42 <pipealloc+0xc6>

0000000080004c56 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c56:	1101                	addi	sp,sp,-32
    80004c58:	ec06                	sd	ra,24(sp)
    80004c5a:	e822                	sd	s0,16(sp)
    80004c5c:	e426                	sd	s1,8(sp)
    80004c5e:	e04a                	sd	s2,0(sp)
    80004c60:	1000                	addi	s0,sp,32
    80004c62:	84aa                	mv	s1,a0
    80004c64:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	f80080e7          	jalr	-128(ra) # 80000be6 <acquire>
  if(writable){
    80004c6e:	02090d63          	beqz	s2,80004ca8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c72:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c76:	21848513          	addi	a0,s1,536
    80004c7a:	ffffd097          	auipc	ra,0xffffd
    80004c7e:	702080e7          	jalr	1794(ra) # 8000237c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c82:	2204b783          	ld	a5,544(s1)
    80004c86:	eb95                	bnez	a5,80004cba <pipeclose+0x64>
    release(&pi->lock);
    80004c88:	8526                	mv	a0,s1
    80004c8a:	ffffc097          	auipc	ra,0xffffc
    80004c8e:	010080e7          	jalr	16(ra) # 80000c9a <release>
    kfree((char*)pi);
    80004c92:	8526                	mv	a0,s1
    80004c94:	ffffc097          	auipc	ra,0xffffc
    80004c98:	d66080e7          	jalr	-666(ra) # 800009fa <kfree>
  } else
    release(&pi->lock);
}
    80004c9c:	60e2                	ld	ra,24(sp)
    80004c9e:	6442                	ld	s0,16(sp)
    80004ca0:	64a2                	ld	s1,8(sp)
    80004ca2:	6902                	ld	s2,0(sp)
    80004ca4:	6105                	addi	sp,sp,32
    80004ca6:	8082                	ret
    pi->readopen = 0;
    80004ca8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cac:	21c48513          	addi	a0,s1,540
    80004cb0:	ffffd097          	auipc	ra,0xffffd
    80004cb4:	6cc080e7          	jalr	1740(ra) # 8000237c <wakeup>
    80004cb8:	b7e9                	j	80004c82 <pipeclose+0x2c>
    release(&pi->lock);
    80004cba:	8526                	mv	a0,s1
    80004cbc:	ffffc097          	auipc	ra,0xffffc
    80004cc0:	fde080e7          	jalr	-34(ra) # 80000c9a <release>
}
    80004cc4:	bfe1                	j	80004c9c <pipeclose+0x46>

0000000080004cc6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cc6:	7159                	addi	sp,sp,-112
    80004cc8:	f486                	sd	ra,104(sp)
    80004cca:	f0a2                	sd	s0,96(sp)
    80004ccc:	eca6                	sd	s1,88(sp)
    80004cce:	e8ca                	sd	s2,80(sp)
    80004cd0:	e4ce                	sd	s3,72(sp)
    80004cd2:	e0d2                	sd	s4,64(sp)
    80004cd4:	fc56                	sd	s5,56(sp)
    80004cd6:	f85a                	sd	s6,48(sp)
    80004cd8:	f45e                	sd	s7,40(sp)
    80004cda:	f062                	sd	s8,32(sp)
    80004cdc:	ec66                	sd	s9,24(sp)
    80004cde:	1880                	addi	s0,sp,112
    80004ce0:	84aa                	mv	s1,a0
    80004ce2:	8aae                	mv	s5,a1
    80004ce4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ce6:	ffffd097          	auipc	ra,0xffffd
    80004cea:	ccc080e7          	jalr	-820(ra) # 800019b2 <myproc>
    80004cee:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	ffffc097          	auipc	ra,0xffffc
    80004cf6:	ef4080e7          	jalr	-268(ra) # 80000be6 <acquire>
  while(i < n){
    80004cfa:	0d405263          	blez	s4,80004dbe <pipewrite+0xf8>
    80004cfe:	8ba6                	mv	s7,s1
  int i = 0;
    80004d00:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d02:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d04:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d08:	21c48c13          	addi	s8,s1,540
    80004d0c:	a08d                	j	80004d6e <pipewrite+0xa8>
      release(&pi->lock);
    80004d0e:	8526                	mv	a0,s1
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	f8a080e7          	jalr	-118(ra) # 80000c9a <release>
      return -1;
    80004d18:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d1a:	854a                	mv	a0,s2
    80004d1c:	70a6                	ld	ra,104(sp)
    80004d1e:	7406                	ld	s0,96(sp)
    80004d20:	64e6                	ld	s1,88(sp)
    80004d22:	6946                	ld	s2,80(sp)
    80004d24:	69a6                	ld	s3,72(sp)
    80004d26:	6a06                	ld	s4,64(sp)
    80004d28:	7ae2                	ld	s5,56(sp)
    80004d2a:	7b42                	ld	s6,48(sp)
    80004d2c:	7ba2                	ld	s7,40(sp)
    80004d2e:	7c02                	ld	s8,32(sp)
    80004d30:	6ce2                	ld	s9,24(sp)
    80004d32:	6165                	addi	sp,sp,112
    80004d34:	8082                	ret
      wakeup(&pi->nread);
    80004d36:	8566                	mv	a0,s9
    80004d38:	ffffd097          	auipc	ra,0xffffd
    80004d3c:	644080e7          	jalr	1604(ra) # 8000237c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d40:	85de                	mv	a1,s7
    80004d42:	8562                	mv	a0,s8
    80004d44:	ffffd097          	auipc	ra,0xffffd
    80004d48:	4a8080e7          	jalr	1192(ra) # 800021ec <sleep>
    80004d4c:	a839                	j	80004d6a <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d4e:	21c4a783          	lw	a5,540(s1)
    80004d52:	0017871b          	addiw	a4,a5,1
    80004d56:	20e4ae23          	sw	a4,540(s1)
    80004d5a:	1ff7f793          	andi	a5,a5,511
    80004d5e:	97a6                	add	a5,a5,s1
    80004d60:	f9f44703          	lbu	a4,-97(s0)
    80004d64:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d68:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d6a:	03495e63          	bge	s2,s4,80004da6 <pipewrite+0xe0>
    if(pi->readopen == 0 || pr->killed){
    80004d6e:	2204a783          	lw	a5,544(s1)
    80004d72:	dfd1                	beqz	a5,80004d0e <pipewrite+0x48>
    80004d74:	0289a783          	lw	a5,40(s3)
    80004d78:	2781                	sext.w	a5,a5
    80004d7a:	fbd1                	bnez	a5,80004d0e <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d7c:	2184a783          	lw	a5,536(s1)
    80004d80:	21c4a703          	lw	a4,540(s1)
    80004d84:	2007879b          	addiw	a5,a5,512
    80004d88:	faf707e3          	beq	a4,a5,80004d36 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d8c:	4685                	li	a3,1
    80004d8e:	01590633          	add	a2,s2,s5
    80004d92:	f9f40593          	addi	a1,s0,-97
    80004d96:	0509b503          	ld	a0,80(s3)
    80004d9a:	ffffd097          	auipc	ra,0xffffd
    80004d9e:	966080e7          	jalr	-1690(ra) # 80001700 <copyin>
    80004da2:	fb6516e3          	bne	a0,s6,80004d4e <pipewrite+0x88>
  wakeup(&pi->nread);
    80004da6:	21848513          	addi	a0,s1,536
    80004daa:	ffffd097          	auipc	ra,0xffffd
    80004dae:	5d2080e7          	jalr	1490(ra) # 8000237c <wakeup>
  release(&pi->lock);
    80004db2:	8526                	mv	a0,s1
    80004db4:	ffffc097          	auipc	ra,0xffffc
    80004db8:	ee6080e7          	jalr	-282(ra) # 80000c9a <release>
  return i;
    80004dbc:	bfb9                	j	80004d1a <pipewrite+0x54>
  int i = 0;
    80004dbe:	4901                	li	s2,0
    80004dc0:	b7dd                	j	80004da6 <pipewrite+0xe0>

0000000080004dc2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004dc2:	715d                	addi	sp,sp,-80
    80004dc4:	e486                	sd	ra,72(sp)
    80004dc6:	e0a2                	sd	s0,64(sp)
    80004dc8:	fc26                	sd	s1,56(sp)
    80004dca:	f84a                	sd	s2,48(sp)
    80004dcc:	f44e                	sd	s3,40(sp)
    80004dce:	f052                	sd	s4,32(sp)
    80004dd0:	ec56                	sd	s5,24(sp)
    80004dd2:	e85a                	sd	s6,16(sp)
    80004dd4:	0880                	addi	s0,sp,80
    80004dd6:	84aa                	mv	s1,a0
    80004dd8:	892e                	mv	s2,a1
    80004dda:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ddc:	ffffd097          	auipc	ra,0xffffd
    80004de0:	bd6080e7          	jalr	-1066(ra) # 800019b2 <myproc>
    80004de4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004de6:	8b26                	mv	s6,s1
    80004de8:	8526                	mv	a0,s1
    80004dea:	ffffc097          	auipc	ra,0xffffc
    80004dee:	dfc080e7          	jalr	-516(ra) # 80000be6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004df2:	2184a703          	lw	a4,536(s1)
    80004df6:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dfa:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dfe:	02f71563          	bne	a4,a5,80004e28 <piperead+0x66>
    80004e02:	2244a783          	lw	a5,548(s1)
    80004e06:	c38d                	beqz	a5,80004e28 <piperead+0x66>
    if(pr->killed){
    80004e08:	028a2783          	lw	a5,40(s4)
    80004e0c:	2781                	sext.w	a5,a5
    80004e0e:	ebc1                	bnez	a5,80004e9e <piperead+0xdc>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e10:	85da                	mv	a1,s6
    80004e12:	854e                	mv	a0,s3
    80004e14:	ffffd097          	auipc	ra,0xffffd
    80004e18:	3d8080e7          	jalr	984(ra) # 800021ec <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e1c:	2184a703          	lw	a4,536(s1)
    80004e20:	21c4a783          	lw	a5,540(s1)
    80004e24:	fcf70fe3          	beq	a4,a5,80004e02 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e28:	09505263          	blez	s5,80004eac <piperead+0xea>
    80004e2c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e2e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e30:	2184a783          	lw	a5,536(s1)
    80004e34:	21c4a703          	lw	a4,540(s1)
    80004e38:	02f70d63          	beq	a4,a5,80004e72 <piperead+0xb0>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e3c:	0017871b          	addiw	a4,a5,1
    80004e40:	20e4ac23          	sw	a4,536(s1)
    80004e44:	1ff7f793          	andi	a5,a5,511
    80004e48:	97a6                	add	a5,a5,s1
    80004e4a:	0187c783          	lbu	a5,24(a5)
    80004e4e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e52:	4685                	li	a3,1
    80004e54:	fbf40613          	addi	a2,s0,-65
    80004e58:	85ca                	mv	a1,s2
    80004e5a:	050a3503          	ld	a0,80(s4)
    80004e5e:	ffffd097          	auipc	ra,0xffffd
    80004e62:	816080e7          	jalr	-2026(ra) # 80001674 <copyout>
    80004e66:	01650663          	beq	a0,s6,80004e72 <piperead+0xb0>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e6a:	2985                	addiw	s3,s3,1
    80004e6c:	0905                	addi	s2,s2,1
    80004e6e:	fd3a91e3          	bne	s5,s3,80004e30 <piperead+0x6e>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e72:	21c48513          	addi	a0,s1,540
    80004e76:	ffffd097          	auipc	ra,0xffffd
    80004e7a:	506080e7          	jalr	1286(ra) # 8000237c <wakeup>
  release(&pi->lock);
    80004e7e:	8526                	mv	a0,s1
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	e1a080e7          	jalr	-486(ra) # 80000c9a <release>
  return i;
}
    80004e88:	854e                	mv	a0,s3
    80004e8a:	60a6                	ld	ra,72(sp)
    80004e8c:	6406                	ld	s0,64(sp)
    80004e8e:	74e2                	ld	s1,56(sp)
    80004e90:	7942                	ld	s2,48(sp)
    80004e92:	79a2                	ld	s3,40(sp)
    80004e94:	7a02                	ld	s4,32(sp)
    80004e96:	6ae2                	ld	s5,24(sp)
    80004e98:	6b42                	ld	s6,16(sp)
    80004e9a:	6161                	addi	sp,sp,80
    80004e9c:	8082                	ret
      release(&pi->lock);
    80004e9e:	8526                	mv	a0,s1
    80004ea0:	ffffc097          	auipc	ra,0xffffc
    80004ea4:	dfa080e7          	jalr	-518(ra) # 80000c9a <release>
      return -1;
    80004ea8:	59fd                	li	s3,-1
    80004eaa:	bff9                	j	80004e88 <piperead+0xc6>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eac:	4981                	li	s3,0
    80004eae:	b7d1                	j	80004e72 <piperead+0xb0>

0000000080004eb0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004eb0:	df010113          	addi	sp,sp,-528
    80004eb4:	20113423          	sd	ra,520(sp)
    80004eb8:	20813023          	sd	s0,512(sp)
    80004ebc:	ffa6                	sd	s1,504(sp)
    80004ebe:	fbca                	sd	s2,496(sp)
    80004ec0:	f7ce                	sd	s3,488(sp)
    80004ec2:	f3d2                	sd	s4,480(sp)
    80004ec4:	efd6                	sd	s5,472(sp)
    80004ec6:	ebda                	sd	s6,464(sp)
    80004ec8:	e7de                	sd	s7,456(sp)
    80004eca:	e3e2                	sd	s8,448(sp)
    80004ecc:	ff66                	sd	s9,440(sp)
    80004ece:	fb6a                	sd	s10,432(sp)
    80004ed0:	f76e                	sd	s11,424(sp)
    80004ed2:	0c00                	addi	s0,sp,528
    80004ed4:	84aa                	mv	s1,a0
    80004ed6:	dea43c23          	sd	a0,-520(s0)
    80004eda:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ede:	ffffd097          	auipc	ra,0xffffd
    80004ee2:	ad4080e7          	jalr	-1324(ra) # 800019b2 <myproc>
    80004ee6:	892a                	mv	s2,a0

  begin_op();
    80004ee8:	fffff097          	auipc	ra,0xfffff
    80004eec:	498080e7          	jalr	1176(ra) # 80004380 <begin_op>

  if((ip = namei(path)) == 0){
    80004ef0:	8526                	mv	a0,s1
    80004ef2:	fffff097          	auipc	ra,0xfffff
    80004ef6:	272080e7          	jalr	626(ra) # 80004164 <namei>
    80004efa:	c92d                	beqz	a0,80004f6c <exec+0xbc>
    80004efc:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004efe:	fffff097          	auipc	ra,0xfffff
    80004f02:	ab0080e7          	jalr	-1360(ra) # 800039ae <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f06:	04000713          	li	a4,64
    80004f0a:	4681                	li	a3,0
    80004f0c:	e5040613          	addi	a2,s0,-432
    80004f10:	4581                	li	a1,0
    80004f12:	8526                	mv	a0,s1
    80004f14:	fffff097          	auipc	ra,0xfffff
    80004f18:	d4e080e7          	jalr	-690(ra) # 80003c62 <readi>
    80004f1c:	04000793          	li	a5,64
    80004f20:	00f51a63          	bne	a0,a5,80004f34 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f24:	e5042703          	lw	a4,-432(s0)
    80004f28:	464c47b7          	lui	a5,0x464c4
    80004f2c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f30:	04f70463          	beq	a4,a5,80004f78 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f34:	8526                	mv	a0,s1
    80004f36:	fffff097          	auipc	ra,0xfffff
    80004f3a:	cda080e7          	jalr	-806(ra) # 80003c10 <iunlockput>
    end_op();
    80004f3e:	fffff097          	auipc	ra,0xfffff
    80004f42:	4c2080e7          	jalr	1218(ra) # 80004400 <end_op>
  }
  return -1;
    80004f46:	557d                	li	a0,-1
}
    80004f48:	20813083          	ld	ra,520(sp)
    80004f4c:	20013403          	ld	s0,512(sp)
    80004f50:	74fe                	ld	s1,504(sp)
    80004f52:	795e                	ld	s2,496(sp)
    80004f54:	79be                	ld	s3,488(sp)
    80004f56:	7a1e                	ld	s4,480(sp)
    80004f58:	6afe                	ld	s5,472(sp)
    80004f5a:	6b5e                	ld	s6,464(sp)
    80004f5c:	6bbe                	ld	s7,456(sp)
    80004f5e:	6c1e                	ld	s8,448(sp)
    80004f60:	7cfa                	ld	s9,440(sp)
    80004f62:	7d5a                	ld	s10,432(sp)
    80004f64:	7dba                	ld	s11,424(sp)
    80004f66:	21010113          	addi	sp,sp,528
    80004f6a:	8082                	ret
    end_op();
    80004f6c:	fffff097          	auipc	ra,0xfffff
    80004f70:	494080e7          	jalr	1172(ra) # 80004400 <end_op>
    return -1;
    80004f74:	557d                	li	a0,-1
    80004f76:	bfc9                	j	80004f48 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f78:	854a                	mv	a0,s2
    80004f7a:	ffffd097          	auipc	ra,0xffffd
    80004f7e:	afc080e7          	jalr	-1284(ra) # 80001a76 <proc_pagetable>
    80004f82:	8baa                	mv	s7,a0
    80004f84:	d945                	beqz	a0,80004f34 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f86:	e7042983          	lw	s3,-400(s0)
    80004f8a:	e8845783          	lhu	a5,-376(s0)
    80004f8e:	c7ad                	beqz	a5,80004ff8 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f90:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f92:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004f94:	6c85                	lui	s9,0x1
    80004f96:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f9a:	def43823          	sd	a5,-528(s0)
    80004f9e:	a42d                	j	800051c8 <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fa0:	00004517          	auipc	a0,0x4
    80004fa4:	80050513          	addi	a0,a0,-2048 # 800087a0 <syscalls+0x290>
    80004fa8:	ffffb097          	auipc	ra,0xffffb
    80004fac:	598080e7          	jalr	1432(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004fb0:	8756                	mv	a4,s5
    80004fb2:	012d86bb          	addw	a3,s11,s2
    80004fb6:	4581                	li	a1,0
    80004fb8:	8526                	mv	a0,s1
    80004fba:	fffff097          	auipc	ra,0xfffff
    80004fbe:	ca8080e7          	jalr	-856(ra) # 80003c62 <readi>
    80004fc2:	2501                	sext.w	a0,a0
    80004fc4:	1aaa9963          	bne	s5,a0,80005176 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004fc8:	6785                	lui	a5,0x1
    80004fca:	0127893b          	addw	s2,a5,s2
    80004fce:	77fd                	lui	a5,0xfffff
    80004fd0:	01478a3b          	addw	s4,a5,s4
    80004fd4:	1f897163          	bgeu	s2,s8,800051b6 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004fd8:	02091593          	slli	a1,s2,0x20
    80004fdc:	9181                	srli	a1,a1,0x20
    80004fde:	95ea                	add	a1,a1,s10
    80004fe0:	855e                	mv	a0,s7
    80004fe2:	ffffc097          	auipc	ra,0xffffc
    80004fe6:	08e080e7          	jalr	142(ra) # 80001070 <walkaddr>
    80004fea:	862a                	mv	a2,a0
    if(pa == 0)
    80004fec:	d955                	beqz	a0,80004fa0 <exec+0xf0>
      n = PGSIZE;
    80004fee:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ff0:	fd9a70e3          	bgeu	s4,s9,80004fb0 <exec+0x100>
      n = sz - i;
    80004ff4:	8ad2                	mv	s5,s4
    80004ff6:	bf6d                	j	80004fb0 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ff8:	4901                	li	s2,0
  iunlockput(ip);
    80004ffa:	8526                	mv	a0,s1
    80004ffc:	fffff097          	auipc	ra,0xfffff
    80005000:	c14080e7          	jalr	-1004(ra) # 80003c10 <iunlockput>
  end_op();
    80005004:	fffff097          	auipc	ra,0xfffff
    80005008:	3fc080e7          	jalr	1020(ra) # 80004400 <end_op>
  p = myproc();
    8000500c:	ffffd097          	auipc	ra,0xffffd
    80005010:	9a6080e7          	jalr	-1626(ra) # 800019b2 <myproc>
    80005014:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005016:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000501a:	6785                	lui	a5,0x1
    8000501c:	17fd                	addi	a5,a5,-1
    8000501e:	993e                	add	s2,s2,a5
    80005020:	757d                	lui	a0,0xfffff
    80005022:	00a977b3          	and	a5,s2,a0
    80005026:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000502a:	6609                	lui	a2,0x2
    8000502c:	963e                	add	a2,a2,a5
    8000502e:	85be                	mv	a1,a5
    80005030:	855e                	mv	a0,s7
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	3f2080e7          	jalr	1010(ra) # 80001424 <uvmalloc>
    8000503a:	8b2a                	mv	s6,a0
  ip = 0;
    8000503c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000503e:	12050c63          	beqz	a0,80005176 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005042:	75f9                	lui	a1,0xffffe
    80005044:	95aa                	add	a1,a1,a0
    80005046:	855e                	mv	a0,s7
    80005048:	ffffc097          	auipc	ra,0xffffc
    8000504c:	5fa080e7          	jalr	1530(ra) # 80001642 <uvmclear>
  stackbase = sp - PGSIZE;
    80005050:	7c7d                	lui	s8,0xfffff
    80005052:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005054:	e0043783          	ld	a5,-512(s0)
    80005058:	6388                	ld	a0,0(a5)
    8000505a:	c535                	beqz	a0,800050c6 <exec+0x216>
    8000505c:	e9040993          	addi	s3,s0,-368
    80005060:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005064:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005066:	ffffc097          	auipc	ra,0xffffc
    8000506a:	e00080e7          	jalr	-512(ra) # 80000e66 <strlen>
    8000506e:	2505                	addiw	a0,a0,1
    80005070:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005074:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005078:	13896363          	bltu	s2,s8,8000519e <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000507c:	e0043d83          	ld	s11,-512(s0)
    80005080:	000dba03          	ld	s4,0(s11)
    80005084:	8552                	mv	a0,s4
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	de0080e7          	jalr	-544(ra) # 80000e66 <strlen>
    8000508e:	0015069b          	addiw	a3,a0,1
    80005092:	8652                	mv	a2,s4
    80005094:	85ca                	mv	a1,s2
    80005096:	855e                	mv	a0,s7
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	5dc080e7          	jalr	1500(ra) # 80001674 <copyout>
    800050a0:	10054363          	bltz	a0,800051a6 <exec+0x2f6>
    ustack[argc] = sp;
    800050a4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050a8:	0485                	addi	s1,s1,1
    800050aa:	008d8793          	addi	a5,s11,8
    800050ae:	e0f43023          	sd	a5,-512(s0)
    800050b2:	008db503          	ld	a0,8(s11)
    800050b6:	c911                	beqz	a0,800050ca <exec+0x21a>
    if(argc >= MAXARG)
    800050b8:	09a1                	addi	s3,s3,8
    800050ba:	fb3c96e3          	bne	s9,s3,80005066 <exec+0x1b6>
  sz = sz1;
    800050be:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050c2:	4481                	li	s1,0
    800050c4:	a84d                	j	80005176 <exec+0x2c6>
  sp = sz;
    800050c6:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800050c8:	4481                	li	s1,0
  ustack[argc] = 0;
    800050ca:	00349793          	slli	a5,s1,0x3
    800050ce:	f9040713          	addi	a4,s0,-112
    800050d2:	97ba                	add	a5,a5,a4
    800050d4:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800050d8:	00148693          	addi	a3,s1,1
    800050dc:	068e                	slli	a3,a3,0x3
    800050de:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050e2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050e6:	01897663          	bgeu	s2,s8,800050f2 <exec+0x242>
  sz = sz1;
    800050ea:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050ee:	4481                	li	s1,0
    800050f0:	a059                	j	80005176 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050f2:	e9040613          	addi	a2,s0,-368
    800050f6:	85ca                	mv	a1,s2
    800050f8:	855e                	mv	a0,s7
    800050fa:	ffffc097          	auipc	ra,0xffffc
    800050fe:	57a080e7          	jalr	1402(ra) # 80001674 <copyout>
    80005102:	0a054663          	bltz	a0,800051ae <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005106:	058ab783          	ld	a5,88(s5)
    8000510a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000510e:	df843783          	ld	a5,-520(s0)
    80005112:	0007c703          	lbu	a4,0(a5)
    80005116:	cf11                	beqz	a4,80005132 <exec+0x282>
    80005118:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000511a:	02f00693          	li	a3,47
    8000511e:	a039                	j	8000512c <exec+0x27c>
      last = s+1;
    80005120:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005124:	0785                	addi	a5,a5,1
    80005126:	fff7c703          	lbu	a4,-1(a5)
    8000512a:	c701                	beqz	a4,80005132 <exec+0x282>
    if(*s == '/')
    8000512c:	fed71ce3          	bne	a4,a3,80005124 <exec+0x274>
    80005130:	bfc5                	j	80005120 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005132:	4641                	li	a2,16
    80005134:	df843583          	ld	a1,-520(s0)
    80005138:	158a8513          	addi	a0,s5,344
    8000513c:	ffffc097          	auipc	ra,0xffffc
    80005140:	cf8080e7          	jalr	-776(ra) # 80000e34 <safestrcpy>
  oldpagetable = p->pagetable;
    80005144:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005148:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000514c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005150:	058ab783          	ld	a5,88(s5)
    80005154:	e6843703          	ld	a4,-408(s0)
    80005158:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000515a:	058ab783          	ld	a5,88(s5)
    8000515e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005162:	85ea                	mv	a1,s10
    80005164:	ffffd097          	auipc	ra,0xffffd
    80005168:	9ae080e7          	jalr	-1618(ra) # 80001b12 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000516c:	0004851b          	sext.w	a0,s1
    80005170:	bbe1                	j	80004f48 <exec+0x98>
    80005172:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005176:	e0843583          	ld	a1,-504(s0)
    8000517a:	855e                	mv	a0,s7
    8000517c:	ffffd097          	auipc	ra,0xffffd
    80005180:	996080e7          	jalr	-1642(ra) # 80001b12 <proc_freepagetable>
  if(ip){
    80005184:	da0498e3          	bnez	s1,80004f34 <exec+0x84>
  return -1;
    80005188:	557d                	li	a0,-1
    8000518a:	bb7d                	j	80004f48 <exec+0x98>
    8000518c:	e1243423          	sd	s2,-504(s0)
    80005190:	b7dd                	j	80005176 <exec+0x2c6>
    80005192:	e1243423          	sd	s2,-504(s0)
    80005196:	b7c5                	j	80005176 <exec+0x2c6>
    80005198:	e1243423          	sd	s2,-504(s0)
    8000519c:	bfe9                	j	80005176 <exec+0x2c6>
  sz = sz1;
    8000519e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051a2:	4481                	li	s1,0
    800051a4:	bfc9                	j	80005176 <exec+0x2c6>
  sz = sz1;
    800051a6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051aa:	4481                	li	s1,0
    800051ac:	b7e9                	j	80005176 <exec+0x2c6>
  sz = sz1;
    800051ae:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051b2:	4481                	li	s1,0
    800051b4:	b7c9                	j	80005176 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051b6:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051ba:	2b05                	addiw	s6,s6,1
    800051bc:	0389899b          	addiw	s3,s3,56
    800051c0:	e8845783          	lhu	a5,-376(s0)
    800051c4:	e2fb5be3          	bge	s6,a5,80004ffa <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051c8:	2981                	sext.w	s3,s3
    800051ca:	03800713          	li	a4,56
    800051ce:	86ce                	mv	a3,s3
    800051d0:	e1840613          	addi	a2,s0,-488
    800051d4:	4581                	li	a1,0
    800051d6:	8526                	mv	a0,s1
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	a8a080e7          	jalr	-1398(ra) # 80003c62 <readi>
    800051e0:	03800793          	li	a5,56
    800051e4:	f8f517e3          	bne	a0,a5,80005172 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800051e8:	e1842783          	lw	a5,-488(s0)
    800051ec:	4705                	li	a4,1
    800051ee:	fce796e3          	bne	a5,a4,800051ba <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800051f2:	e4043603          	ld	a2,-448(s0)
    800051f6:	e3843783          	ld	a5,-456(s0)
    800051fa:	f8f669e3          	bltu	a2,a5,8000518c <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051fe:	e2843783          	ld	a5,-472(s0)
    80005202:	963e                	add	a2,a2,a5
    80005204:	f8f667e3          	bltu	a2,a5,80005192 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005208:	85ca                	mv	a1,s2
    8000520a:	855e                	mv	a0,s7
    8000520c:	ffffc097          	auipc	ra,0xffffc
    80005210:	218080e7          	jalr	536(ra) # 80001424 <uvmalloc>
    80005214:	e0a43423          	sd	a0,-504(s0)
    80005218:	d141                	beqz	a0,80005198 <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    8000521a:	e2843d03          	ld	s10,-472(s0)
    8000521e:	df043783          	ld	a5,-528(s0)
    80005222:	00fd77b3          	and	a5,s10,a5
    80005226:	fba1                	bnez	a5,80005176 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005228:	e2042d83          	lw	s11,-480(s0)
    8000522c:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005230:	f80c03e3          	beqz	s8,800051b6 <exec+0x306>
    80005234:	8a62                	mv	s4,s8
    80005236:	4901                	li	s2,0
    80005238:	b345                	j	80004fd8 <exec+0x128>

000000008000523a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000523a:	7179                	addi	sp,sp,-48
    8000523c:	f406                	sd	ra,40(sp)
    8000523e:	f022                	sd	s0,32(sp)
    80005240:	ec26                	sd	s1,24(sp)
    80005242:	e84a                	sd	s2,16(sp)
    80005244:	1800                	addi	s0,sp,48
    80005246:	892e                	mv	s2,a1
    80005248:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000524a:	fdc40593          	addi	a1,s0,-36
    8000524e:	ffffe097          	auipc	ra,0xffffe
    80005252:	ba2080e7          	jalr	-1118(ra) # 80002df0 <argint>
    80005256:	04054063          	bltz	a0,80005296 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000525a:	fdc42703          	lw	a4,-36(s0)
    8000525e:	47bd                	li	a5,15
    80005260:	02e7ed63          	bltu	a5,a4,8000529a <argfd+0x60>
    80005264:	ffffc097          	auipc	ra,0xffffc
    80005268:	74e080e7          	jalr	1870(ra) # 800019b2 <myproc>
    8000526c:	fdc42703          	lw	a4,-36(s0)
    80005270:	01a70793          	addi	a5,a4,26
    80005274:	078e                	slli	a5,a5,0x3
    80005276:	953e                	add	a0,a0,a5
    80005278:	611c                	ld	a5,0(a0)
    8000527a:	c395                	beqz	a5,8000529e <argfd+0x64>
    return -1;
  if(pfd)
    8000527c:	00090463          	beqz	s2,80005284 <argfd+0x4a>
    *pfd = fd;
    80005280:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005284:	4501                	li	a0,0
  if(pf)
    80005286:	c091                	beqz	s1,8000528a <argfd+0x50>
    *pf = f;
    80005288:	e09c                	sd	a5,0(s1)
}
    8000528a:	70a2                	ld	ra,40(sp)
    8000528c:	7402                	ld	s0,32(sp)
    8000528e:	64e2                	ld	s1,24(sp)
    80005290:	6942                	ld	s2,16(sp)
    80005292:	6145                	addi	sp,sp,48
    80005294:	8082                	ret
    return -1;
    80005296:	557d                	li	a0,-1
    80005298:	bfcd                	j	8000528a <argfd+0x50>
    return -1;
    8000529a:	557d                	li	a0,-1
    8000529c:	b7fd                	j	8000528a <argfd+0x50>
    8000529e:	557d                	li	a0,-1
    800052a0:	b7ed                	j	8000528a <argfd+0x50>

00000000800052a2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052a2:	1101                	addi	sp,sp,-32
    800052a4:	ec06                	sd	ra,24(sp)
    800052a6:	e822                	sd	s0,16(sp)
    800052a8:	e426                	sd	s1,8(sp)
    800052aa:	1000                	addi	s0,sp,32
    800052ac:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052ae:	ffffc097          	auipc	ra,0xffffc
    800052b2:	704080e7          	jalr	1796(ra) # 800019b2 <myproc>
    800052b6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052b8:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800052bc:	4501                	li	a0,0
    800052be:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052c0:	6398                	ld	a4,0(a5)
    800052c2:	cb19                	beqz	a4,800052d8 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052c4:	2505                	addiw	a0,a0,1
    800052c6:	07a1                	addi	a5,a5,8
    800052c8:	fed51ce3          	bne	a0,a3,800052c0 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052cc:	557d                	li	a0,-1
}
    800052ce:	60e2                	ld	ra,24(sp)
    800052d0:	6442                	ld	s0,16(sp)
    800052d2:	64a2                	ld	s1,8(sp)
    800052d4:	6105                	addi	sp,sp,32
    800052d6:	8082                	ret
      p->ofile[fd] = f;
    800052d8:	01a50793          	addi	a5,a0,26
    800052dc:	078e                	slli	a5,a5,0x3
    800052de:	963e                	add	a2,a2,a5
    800052e0:	e204                	sd	s1,0(a2)
      return fd;
    800052e2:	b7f5                	j	800052ce <fdalloc+0x2c>

00000000800052e4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052e4:	715d                	addi	sp,sp,-80
    800052e6:	e486                	sd	ra,72(sp)
    800052e8:	e0a2                	sd	s0,64(sp)
    800052ea:	fc26                	sd	s1,56(sp)
    800052ec:	f84a                	sd	s2,48(sp)
    800052ee:	f44e                	sd	s3,40(sp)
    800052f0:	f052                	sd	s4,32(sp)
    800052f2:	ec56                	sd	s5,24(sp)
    800052f4:	0880                	addi	s0,sp,80
    800052f6:	89ae                	mv	s3,a1
    800052f8:	8ab2                	mv	s5,a2
    800052fa:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052fc:	fb040593          	addi	a1,s0,-80
    80005300:	fffff097          	auipc	ra,0xfffff
    80005304:	e82080e7          	jalr	-382(ra) # 80004182 <nameiparent>
    80005308:	892a                	mv	s2,a0
    8000530a:	12050f63          	beqz	a0,80005448 <create+0x164>
    return 0;

  ilock(dp);
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	6a0080e7          	jalr	1696(ra) # 800039ae <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005316:	4601                	li	a2,0
    80005318:	fb040593          	addi	a1,s0,-80
    8000531c:	854a                	mv	a0,s2
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	b74080e7          	jalr	-1164(ra) # 80003e92 <dirlookup>
    80005326:	84aa                	mv	s1,a0
    80005328:	c921                	beqz	a0,80005378 <create+0x94>
    iunlockput(dp);
    8000532a:	854a                	mv	a0,s2
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	8e4080e7          	jalr	-1820(ra) # 80003c10 <iunlockput>
    ilock(ip);
    80005334:	8526                	mv	a0,s1
    80005336:	ffffe097          	auipc	ra,0xffffe
    8000533a:	678080e7          	jalr	1656(ra) # 800039ae <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000533e:	2981                	sext.w	s3,s3
    80005340:	4789                	li	a5,2
    80005342:	02f99463          	bne	s3,a5,8000536a <create+0x86>
    80005346:	0444d783          	lhu	a5,68(s1)
    8000534a:	37f9                	addiw	a5,a5,-2
    8000534c:	17c2                	slli	a5,a5,0x30
    8000534e:	93c1                	srli	a5,a5,0x30
    80005350:	4705                	li	a4,1
    80005352:	00f76c63          	bltu	a4,a5,8000536a <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005356:	8526                	mv	a0,s1
    80005358:	60a6                	ld	ra,72(sp)
    8000535a:	6406                	ld	s0,64(sp)
    8000535c:	74e2                	ld	s1,56(sp)
    8000535e:	7942                	ld	s2,48(sp)
    80005360:	79a2                	ld	s3,40(sp)
    80005362:	7a02                	ld	s4,32(sp)
    80005364:	6ae2                	ld	s5,24(sp)
    80005366:	6161                	addi	sp,sp,80
    80005368:	8082                	ret
    iunlockput(ip);
    8000536a:	8526                	mv	a0,s1
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	8a4080e7          	jalr	-1884(ra) # 80003c10 <iunlockput>
    return 0;
    80005374:	4481                	li	s1,0
    80005376:	b7c5                	j	80005356 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005378:	85ce                	mv	a1,s3
    8000537a:	00092503          	lw	a0,0(s2)
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	498080e7          	jalr	1176(ra) # 80003816 <ialloc>
    80005386:	84aa                	mv	s1,a0
    80005388:	c529                	beqz	a0,800053d2 <create+0xee>
  ilock(ip);
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	624080e7          	jalr	1572(ra) # 800039ae <ilock>
  ip->major = major;
    80005392:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005396:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000539a:	4785                	li	a5,1
    8000539c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800053a0:	8526                	mv	a0,s1
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	542080e7          	jalr	1346(ra) # 800038e4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053aa:	2981                	sext.w	s3,s3
    800053ac:	4785                	li	a5,1
    800053ae:	02f98a63          	beq	s3,a5,800053e2 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800053b2:	40d0                	lw	a2,4(s1)
    800053b4:	fb040593          	addi	a1,s0,-80
    800053b8:	854a                	mv	a0,s2
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	ce8080e7          	jalr	-792(ra) # 800040a2 <dirlink>
    800053c2:	06054b63          	bltz	a0,80005438 <create+0x154>
  iunlockput(dp);
    800053c6:	854a                	mv	a0,s2
    800053c8:	fffff097          	auipc	ra,0xfffff
    800053cc:	848080e7          	jalr	-1976(ra) # 80003c10 <iunlockput>
  return ip;
    800053d0:	b759                	j	80005356 <create+0x72>
    panic("create: ialloc");
    800053d2:	00003517          	auipc	a0,0x3
    800053d6:	3ee50513          	addi	a0,a0,1006 # 800087c0 <syscalls+0x2b0>
    800053da:	ffffb097          	auipc	ra,0xffffb
    800053de:	166080e7          	jalr	358(ra) # 80000540 <panic>
    dp->nlink++;  // for ".."
    800053e2:	04a95783          	lhu	a5,74(s2)
    800053e6:	2785                	addiw	a5,a5,1
    800053e8:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053ec:	854a                	mv	a0,s2
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	4f6080e7          	jalr	1270(ra) # 800038e4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053f6:	40d0                	lw	a2,4(s1)
    800053f8:	00003597          	auipc	a1,0x3
    800053fc:	3d858593          	addi	a1,a1,984 # 800087d0 <syscalls+0x2c0>
    80005400:	8526                	mv	a0,s1
    80005402:	fffff097          	auipc	ra,0xfffff
    80005406:	ca0080e7          	jalr	-864(ra) # 800040a2 <dirlink>
    8000540a:	00054f63          	bltz	a0,80005428 <create+0x144>
    8000540e:	00492603          	lw	a2,4(s2)
    80005412:	00003597          	auipc	a1,0x3
    80005416:	3c658593          	addi	a1,a1,966 # 800087d8 <syscalls+0x2c8>
    8000541a:	8526                	mv	a0,s1
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	c86080e7          	jalr	-890(ra) # 800040a2 <dirlink>
    80005424:	f80557e3          	bgez	a0,800053b2 <create+0xce>
      panic("create dots");
    80005428:	00003517          	auipc	a0,0x3
    8000542c:	3b850513          	addi	a0,a0,952 # 800087e0 <syscalls+0x2d0>
    80005430:	ffffb097          	auipc	ra,0xffffb
    80005434:	110080e7          	jalr	272(ra) # 80000540 <panic>
    panic("create: dirlink");
    80005438:	00003517          	auipc	a0,0x3
    8000543c:	3b850513          	addi	a0,a0,952 # 800087f0 <syscalls+0x2e0>
    80005440:	ffffb097          	auipc	ra,0xffffb
    80005444:	100080e7          	jalr	256(ra) # 80000540 <panic>
    return 0;
    80005448:	84aa                	mv	s1,a0
    8000544a:	b731                	j	80005356 <create+0x72>

000000008000544c <sys_dup>:
{
    8000544c:	7179                	addi	sp,sp,-48
    8000544e:	f406                	sd	ra,40(sp)
    80005450:	f022                	sd	s0,32(sp)
    80005452:	ec26                	sd	s1,24(sp)
    80005454:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005456:	fd840613          	addi	a2,s0,-40
    8000545a:	4581                	li	a1,0
    8000545c:	4501                	li	a0,0
    8000545e:	00000097          	auipc	ra,0x0
    80005462:	ddc080e7          	jalr	-548(ra) # 8000523a <argfd>
    return -1;
    80005466:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005468:	02054363          	bltz	a0,8000548e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000546c:	fd843503          	ld	a0,-40(s0)
    80005470:	00000097          	auipc	ra,0x0
    80005474:	e32080e7          	jalr	-462(ra) # 800052a2 <fdalloc>
    80005478:	84aa                	mv	s1,a0
    return -1;
    8000547a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000547c:	00054963          	bltz	a0,8000548e <sys_dup+0x42>
  filedup(f);
    80005480:	fd843503          	ld	a0,-40(s0)
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	376080e7          	jalr	886(ra) # 800047fa <filedup>
  return fd;
    8000548c:	87a6                	mv	a5,s1
}
    8000548e:	853e                	mv	a0,a5
    80005490:	70a2                	ld	ra,40(sp)
    80005492:	7402                	ld	s0,32(sp)
    80005494:	64e2                	ld	s1,24(sp)
    80005496:	6145                	addi	sp,sp,48
    80005498:	8082                	ret

000000008000549a <sys_read>:
{
    8000549a:	7179                	addi	sp,sp,-48
    8000549c:	f406                	sd	ra,40(sp)
    8000549e:	f022                	sd	s0,32(sp)
    800054a0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a2:	fe840613          	addi	a2,s0,-24
    800054a6:	4581                	li	a1,0
    800054a8:	4501                	li	a0,0
    800054aa:	00000097          	auipc	ra,0x0
    800054ae:	d90080e7          	jalr	-624(ra) # 8000523a <argfd>
    return -1;
    800054b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b4:	04054163          	bltz	a0,800054f6 <sys_read+0x5c>
    800054b8:	fe440593          	addi	a1,s0,-28
    800054bc:	4509                	li	a0,2
    800054be:	ffffe097          	auipc	ra,0xffffe
    800054c2:	932080e7          	jalr	-1742(ra) # 80002df0 <argint>
    return -1;
    800054c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c8:	02054763          	bltz	a0,800054f6 <sys_read+0x5c>
    800054cc:	fd840593          	addi	a1,s0,-40
    800054d0:	4505                	li	a0,1
    800054d2:	ffffe097          	auipc	ra,0xffffe
    800054d6:	940080e7          	jalr	-1728(ra) # 80002e12 <argaddr>
    return -1;
    800054da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054dc:	00054d63          	bltz	a0,800054f6 <sys_read+0x5c>
  return fileread(f, p, n);
    800054e0:	fe442603          	lw	a2,-28(s0)
    800054e4:	fd843583          	ld	a1,-40(s0)
    800054e8:	fe843503          	ld	a0,-24(s0)
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	49a080e7          	jalr	1178(ra) # 80004986 <fileread>
    800054f4:	87aa                	mv	a5,a0
}
    800054f6:	853e                	mv	a0,a5
    800054f8:	70a2                	ld	ra,40(sp)
    800054fa:	7402                	ld	s0,32(sp)
    800054fc:	6145                	addi	sp,sp,48
    800054fe:	8082                	ret

0000000080005500 <sys_write>:
{
    80005500:	7179                	addi	sp,sp,-48
    80005502:	f406                	sd	ra,40(sp)
    80005504:	f022                	sd	s0,32(sp)
    80005506:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005508:	fe840613          	addi	a2,s0,-24
    8000550c:	4581                	li	a1,0
    8000550e:	4501                	li	a0,0
    80005510:	00000097          	auipc	ra,0x0
    80005514:	d2a080e7          	jalr	-726(ra) # 8000523a <argfd>
    return -1;
    80005518:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000551a:	04054163          	bltz	a0,8000555c <sys_write+0x5c>
    8000551e:	fe440593          	addi	a1,s0,-28
    80005522:	4509                	li	a0,2
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	8cc080e7          	jalr	-1844(ra) # 80002df0 <argint>
    return -1;
    8000552c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000552e:	02054763          	bltz	a0,8000555c <sys_write+0x5c>
    80005532:	fd840593          	addi	a1,s0,-40
    80005536:	4505                	li	a0,1
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	8da080e7          	jalr	-1830(ra) # 80002e12 <argaddr>
    return -1;
    80005540:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005542:	00054d63          	bltz	a0,8000555c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005546:	fe442603          	lw	a2,-28(s0)
    8000554a:	fd843583          	ld	a1,-40(s0)
    8000554e:	fe843503          	ld	a0,-24(s0)
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	4f6080e7          	jalr	1270(ra) # 80004a48 <filewrite>
    8000555a:	87aa                	mv	a5,a0
}
    8000555c:	853e                	mv	a0,a5
    8000555e:	70a2                	ld	ra,40(sp)
    80005560:	7402                	ld	s0,32(sp)
    80005562:	6145                	addi	sp,sp,48
    80005564:	8082                	ret

0000000080005566 <sys_close>:
{
    80005566:	1101                	addi	sp,sp,-32
    80005568:	ec06                	sd	ra,24(sp)
    8000556a:	e822                	sd	s0,16(sp)
    8000556c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000556e:	fe040613          	addi	a2,s0,-32
    80005572:	fec40593          	addi	a1,s0,-20
    80005576:	4501                	li	a0,0
    80005578:	00000097          	auipc	ra,0x0
    8000557c:	cc2080e7          	jalr	-830(ra) # 8000523a <argfd>
    return -1;
    80005580:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005582:	02054463          	bltz	a0,800055aa <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005586:	ffffc097          	auipc	ra,0xffffc
    8000558a:	42c080e7          	jalr	1068(ra) # 800019b2 <myproc>
    8000558e:	fec42783          	lw	a5,-20(s0)
    80005592:	07e9                	addi	a5,a5,26
    80005594:	078e                	slli	a5,a5,0x3
    80005596:	97aa                	add	a5,a5,a0
    80005598:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000559c:	fe043503          	ld	a0,-32(s0)
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	2ac080e7          	jalr	684(ra) # 8000484c <fileclose>
  return 0;
    800055a8:	4781                	li	a5,0
}
    800055aa:	853e                	mv	a0,a5
    800055ac:	60e2                	ld	ra,24(sp)
    800055ae:	6442                	ld	s0,16(sp)
    800055b0:	6105                	addi	sp,sp,32
    800055b2:	8082                	ret

00000000800055b4 <sys_fstat>:
{
    800055b4:	1101                	addi	sp,sp,-32
    800055b6:	ec06                	sd	ra,24(sp)
    800055b8:	e822                	sd	s0,16(sp)
    800055ba:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055bc:	fe840613          	addi	a2,s0,-24
    800055c0:	4581                	li	a1,0
    800055c2:	4501                	li	a0,0
    800055c4:	00000097          	auipc	ra,0x0
    800055c8:	c76080e7          	jalr	-906(ra) # 8000523a <argfd>
    return -1;
    800055cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055ce:	02054563          	bltz	a0,800055f8 <sys_fstat+0x44>
    800055d2:	fe040593          	addi	a1,s0,-32
    800055d6:	4505                	li	a0,1
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	83a080e7          	jalr	-1990(ra) # 80002e12 <argaddr>
    return -1;
    800055e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055e2:	00054b63          	bltz	a0,800055f8 <sys_fstat+0x44>
  return filestat(f, st);
    800055e6:	fe043583          	ld	a1,-32(s0)
    800055ea:	fe843503          	ld	a0,-24(s0)
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	326080e7          	jalr	806(ra) # 80004914 <filestat>
    800055f6:	87aa                	mv	a5,a0
}
    800055f8:	853e                	mv	a0,a5
    800055fa:	60e2                	ld	ra,24(sp)
    800055fc:	6442                	ld	s0,16(sp)
    800055fe:	6105                	addi	sp,sp,32
    80005600:	8082                	ret

0000000080005602 <sys_link>:
{
    80005602:	7169                	addi	sp,sp,-304
    80005604:	f606                	sd	ra,296(sp)
    80005606:	f222                	sd	s0,288(sp)
    80005608:	ee26                	sd	s1,280(sp)
    8000560a:	ea4a                	sd	s2,272(sp)
    8000560c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000560e:	08000613          	li	a2,128
    80005612:	ed040593          	addi	a1,s0,-304
    80005616:	4501                	li	a0,0
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	81c080e7          	jalr	-2020(ra) # 80002e34 <argstr>
    return -1;
    80005620:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005622:	10054e63          	bltz	a0,8000573e <sys_link+0x13c>
    80005626:	08000613          	li	a2,128
    8000562a:	f5040593          	addi	a1,s0,-176
    8000562e:	4505                	li	a0,1
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	804080e7          	jalr	-2044(ra) # 80002e34 <argstr>
    return -1;
    80005638:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000563a:	10054263          	bltz	a0,8000573e <sys_link+0x13c>
  begin_op();
    8000563e:	fffff097          	auipc	ra,0xfffff
    80005642:	d42080e7          	jalr	-702(ra) # 80004380 <begin_op>
  if((ip = namei(old)) == 0){
    80005646:	ed040513          	addi	a0,s0,-304
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	b1a080e7          	jalr	-1254(ra) # 80004164 <namei>
    80005652:	84aa                	mv	s1,a0
    80005654:	c551                	beqz	a0,800056e0 <sys_link+0xde>
  ilock(ip);
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	358080e7          	jalr	856(ra) # 800039ae <ilock>
  if(ip->type == T_DIR){
    8000565e:	04449703          	lh	a4,68(s1)
    80005662:	4785                	li	a5,1
    80005664:	08f70463          	beq	a4,a5,800056ec <sys_link+0xea>
  ip->nlink++;
    80005668:	04a4d783          	lhu	a5,74(s1)
    8000566c:	2785                	addiw	a5,a5,1
    8000566e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005672:	8526                	mv	a0,s1
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	270080e7          	jalr	624(ra) # 800038e4 <iupdate>
  iunlock(ip);
    8000567c:	8526                	mv	a0,s1
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	3f2080e7          	jalr	1010(ra) # 80003a70 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005686:	fd040593          	addi	a1,s0,-48
    8000568a:	f5040513          	addi	a0,s0,-176
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	af4080e7          	jalr	-1292(ra) # 80004182 <nameiparent>
    80005696:	892a                	mv	s2,a0
    80005698:	c935                	beqz	a0,8000570c <sys_link+0x10a>
  ilock(dp);
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	314080e7          	jalr	788(ra) # 800039ae <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056a2:	00092703          	lw	a4,0(s2)
    800056a6:	409c                	lw	a5,0(s1)
    800056a8:	04f71d63          	bne	a4,a5,80005702 <sys_link+0x100>
    800056ac:	40d0                	lw	a2,4(s1)
    800056ae:	fd040593          	addi	a1,s0,-48
    800056b2:	854a                	mv	a0,s2
    800056b4:	fffff097          	auipc	ra,0xfffff
    800056b8:	9ee080e7          	jalr	-1554(ra) # 800040a2 <dirlink>
    800056bc:	04054363          	bltz	a0,80005702 <sys_link+0x100>
  iunlockput(dp);
    800056c0:	854a                	mv	a0,s2
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	54e080e7          	jalr	1358(ra) # 80003c10 <iunlockput>
  iput(ip);
    800056ca:	8526                	mv	a0,s1
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	49c080e7          	jalr	1180(ra) # 80003b68 <iput>
  end_op();
    800056d4:	fffff097          	auipc	ra,0xfffff
    800056d8:	d2c080e7          	jalr	-724(ra) # 80004400 <end_op>
  return 0;
    800056dc:	4781                	li	a5,0
    800056de:	a085                	j	8000573e <sys_link+0x13c>
    end_op();
    800056e0:	fffff097          	auipc	ra,0xfffff
    800056e4:	d20080e7          	jalr	-736(ra) # 80004400 <end_op>
    return -1;
    800056e8:	57fd                	li	a5,-1
    800056ea:	a891                	j	8000573e <sys_link+0x13c>
    iunlockput(ip);
    800056ec:	8526                	mv	a0,s1
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	522080e7          	jalr	1314(ra) # 80003c10 <iunlockput>
    end_op();
    800056f6:	fffff097          	auipc	ra,0xfffff
    800056fa:	d0a080e7          	jalr	-758(ra) # 80004400 <end_op>
    return -1;
    800056fe:	57fd                	li	a5,-1
    80005700:	a83d                	j	8000573e <sys_link+0x13c>
    iunlockput(dp);
    80005702:	854a                	mv	a0,s2
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	50c080e7          	jalr	1292(ra) # 80003c10 <iunlockput>
  ilock(ip);
    8000570c:	8526                	mv	a0,s1
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	2a0080e7          	jalr	672(ra) # 800039ae <ilock>
  ip->nlink--;
    80005716:	04a4d783          	lhu	a5,74(s1)
    8000571a:	37fd                	addiw	a5,a5,-1
    8000571c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005720:	8526                	mv	a0,s1
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	1c2080e7          	jalr	450(ra) # 800038e4 <iupdate>
  iunlockput(ip);
    8000572a:	8526                	mv	a0,s1
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	4e4080e7          	jalr	1252(ra) # 80003c10 <iunlockput>
  end_op();
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	ccc080e7          	jalr	-820(ra) # 80004400 <end_op>
  return -1;
    8000573c:	57fd                	li	a5,-1
}
    8000573e:	853e                	mv	a0,a5
    80005740:	70b2                	ld	ra,296(sp)
    80005742:	7412                	ld	s0,288(sp)
    80005744:	64f2                	ld	s1,280(sp)
    80005746:	6952                	ld	s2,272(sp)
    80005748:	6155                	addi	sp,sp,304
    8000574a:	8082                	ret

000000008000574c <sys_unlink>:
{
    8000574c:	7151                	addi	sp,sp,-240
    8000574e:	f586                	sd	ra,232(sp)
    80005750:	f1a2                	sd	s0,224(sp)
    80005752:	eda6                	sd	s1,216(sp)
    80005754:	e9ca                	sd	s2,208(sp)
    80005756:	e5ce                	sd	s3,200(sp)
    80005758:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000575a:	08000613          	li	a2,128
    8000575e:	f3040593          	addi	a1,s0,-208
    80005762:	4501                	li	a0,0
    80005764:	ffffd097          	auipc	ra,0xffffd
    80005768:	6d0080e7          	jalr	1744(ra) # 80002e34 <argstr>
    8000576c:	18054163          	bltz	a0,800058ee <sys_unlink+0x1a2>
  begin_op();
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	c10080e7          	jalr	-1008(ra) # 80004380 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005778:	fb040593          	addi	a1,s0,-80
    8000577c:	f3040513          	addi	a0,s0,-208
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	a02080e7          	jalr	-1534(ra) # 80004182 <nameiparent>
    80005788:	84aa                	mv	s1,a0
    8000578a:	c979                	beqz	a0,80005860 <sys_unlink+0x114>
  ilock(dp);
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	222080e7          	jalr	546(ra) # 800039ae <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005794:	00003597          	auipc	a1,0x3
    80005798:	03c58593          	addi	a1,a1,60 # 800087d0 <syscalls+0x2c0>
    8000579c:	fb040513          	addi	a0,s0,-80
    800057a0:	ffffe097          	auipc	ra,0xffffe
    800057a4:	6d8080e7          	jalr	1752(ra) # 80003e78 <namecmp>
    800057a8:	14050a63          	beqz	a0,800058fc <sys_unlink+0x1b0>
    800057ac:	00003597          	auipc	a1,0x3
    800057b0:	02c58593          	addi	a1,a1,44 # 800087d8 <syscalls+0x2c8>
    800057b4:	fb040513          	addi	a0,s0,-80
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	6c0080e7          	jalr	1728(ra) # 80003e78 <namecmp>
    800057c0:	12050e63          	beqz	a0,800058fc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057c4:	f2c40613          	addi	a2,s0,-212
    800057c8:	fb040593          	addi	a1,s0,-80
    800057cc:	8526                	mv	a0,s1
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	6c4080e7          	jalr	1732(ra) # 80003e92 <dirlookup>
    800057d6:	892a                	mv	s2,a0
    800057d8:	12050263          	beqz	a0,800058fc <sys_unlink+0x1b0>
  ilock(ip);
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	1d2080e7          	jalr	466(ra) # 800039ae <ilock>
  if(ip->nlink < 1)
    800057e4:	04a91783          	lh	a5,74(s2)
    800057e8:	08f05263          	blez	a5,8000586c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057ec:	04491703          	lh	a4,68(s2)
    800057f0:	4785                	li	a5,1
    800057f2:	08f70563          	beq	a4,a5,8000587c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057f6:	4641                	li	a2,16
    800057f8:	4581                	li	a1,0
    800057fa:	fc040513          	addi	a0,s0,-64
    800057fe:	ffffb097          	auipc	ra,0xffffb
    80005802:	4e4080e7          	jalr	1252(ra) # 80000ce2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005806:	4741                	li	a4,16
    80005808:	f2c42683          	lw	a3,-212(s0)
    8000580c:	fc040613          	addi	a2,s0,-64
    80005810:	4581                	li	a1,0
    80005812:	8526                	mv	a0,s1
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	546080e7          	jalr	1350(ra) # 80003d5a <writei>
    8000581c:	47c1                	li	a5,16
    8000581e:	0af51563          	bne	a0,a5,800058c8 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005822:	04491703          	lh	a4,68(s2)
    80005826:	4785                	li	a5,1
    80005828:	0af70863          	beq	a4,a5,800058d8 <sys_unlink+0x18c>
  iunlockput(dp);
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	3e2080e7          	jalr	994(ra) # 80003c10 <iunlockput>
  ip->nlink--;
    80005836:	04a95783          	lhu	a5,74(s2)
    8000583a:	37fd                	addiw	a5,a5,-1
    8000583c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005840:	854a                	mv	a0,s2
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	0a2080e7          	jalr	162(ra) # 800038e4 <iupdate>
  iunlockput(ip);
    8000584a:	854a                	mv	a0,s2
    8000584c:	ffffe097          	auipc	ra,0xffffe
    80005850:	3c4080e7          	jalr	964(ra) # 80003c10 <iunlockput>
  end_op();
    80005854:	fffff097          	auipc	ra,0xfffff
    80005858:	bac080e7          	jalr	-1108(ra) # 80004400 <end_op>
  return 0;
    8000585c:	4501                	li	a0,0
    8000585e:	a84d                	j	80005910 <sys_unlink+0x1c4>
    end_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	ba0080e7          	jalr	-1120(ra) # 80004400 <end_op>
    return -1;
    80005868:	557d                	li	a0,-1
    8000586a:	a05d                	j	80005910 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000586c:	00003517          	auipc	a0,0x3
    80005870:	f9450513          	addi	a0,a0,-108 # 80008800 <syscalls+0x2f0>
    80005874:	ffffb097          	auipc	ra,0xffffb
    80005878:	ccc080e7          	jalr	-820(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000587c:	04c92703          	lw	a4,76(s2)
    80005880:	02000793          	li	a5,32
    80005884:	f6e7f9e3          	bgeu	a5,a4,800057f6 <sys_unlink+0xaa>
    80005888:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000588c:	4741                	li	a4,16
    8000588e:	86ce                	mv	a3,s3
    80005890:	f1840613          	addi	a2,s0,-232
    80005894:	4581                	li	a1,0
    80005896:	854a                	mv	a0,s2
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	3ca080e7          	jalr	970(ra) # 80003c62 <readi>
    800058a0:	47c1                	li	a5,16
    800058a2:	00f51b63          	bne	a0,a5,800058b8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800058a6:	f1845783          	lhu	a5,-232(s0)
    800058aa:	e7a1                	bnez	a5,800058f2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058ac:	29c1                	addiw	s3,s3,16
    800058ae:	04c92783          	lw	a5,76(s2)
    800058b2:	fcf9ede3          	bltu	s3,a5,8000588c <sys_unlink+0x140>
    800058b6:	b781                	j	800057f6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058b8:	00003517          	auipc	a0,0x3
    800058bc:	f6050513          	addi	a0,a0,-160 # 80008818 <syscalls+0x308>
    800058c0:	ffffb097          	auipc	ra,0xffffb
    800058c4:	c80080e7          	jalr	-896(ra) # 80000540 <panic>
    panic("unlink: writei");
    800058c8:	00003517          	auipc	a0,0x3
    800058cc:	f6850513          	addi	a0,a0,-152 # 80008830 <syscalls+0x320>
    800058d0:	ffffb097          	auipc	ra,0xffffb
    800058d4:	c70080e7          	jalr	-912(ra) # 80000540 <panic>
    dp->nlink--;
    800058d8:	04a4d783          	lhu	a5,74(s1)
    800058dc:	37fd                	addiw	a5,a5,-1
    800058de:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058e2:	8526                	mv	a0,s1
    800058e4:	ffffe097          	auipc	ra,0xffffe
    800058e8:	000080e7          	jalr	ra # 800038e4 <iupdate>
    800058ec:	b781                	j	8000582c <sys_unlink+0xe0>
    return -1;
    800058ee:	557d                	li	a0,-1
    800058f0:	a005                	j	80005910 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058f2:	854a                	mv	a0,s2
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	31c080e7          	jalr	796(ra) # 80003c10 <iunlockput>
  iunlockput(dp);
    800058fc:	8526                	mv	a0,s1
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	312080e7          	jalr	786(ra) # 80003c10 <iunlockput>
  end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	afa080e7          	jalr	-1286(ra) # 80004400 <end_op>
  return -1;
    8000590e:	557d                	li	a0,-1
}
    80005910:	70ae                	ld	ra,232(sp)
    80005912:	740e                	ld	s0,224(sp)
    80005914:	64ee                	ld	s1,216(sp)
    80005916:	694e                	ld	s2,208(sp)
    80005918:	69ae                	ld	s3,200(sp)
    8000591a:	616d                	addi	sp,sp,240
    8000591c:	8082                	ret

000000008000591e <sys_open>:

uint64
sys_open(void)
{
    8000591e:	7131                	addi	sp,sp,-192
    80005920:	fd06                	sd	ra,184(sp)
    80005922:	f922                	sd	s0,176(sp)
    80005924:	f526                	sd	s1,168(sp)
    80005926:	f14a                	sd	s2,160(sp)
    80005928:	ed4e                	sd	s3,152(sp)
    8000592a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000592c:	08000613          	li	a2,128
    80005930:	f5040593          	addi	a1,s0,-176
    80005934:	4501                	li	a0,0
    80005936:	ffffd097          	auipc	ra,0xffffd
    8000593a:	4fe080e7          	jalr	1278(ra) # 80002e34 <argstr>
    return -1;
    8000593e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005940:	0c054163          	bltz	a0,80005a02 <sys_open+0xe4>
    80005944:	f4c40593          	addi	a1,s0,-180
    80005948:	4505                	li	a0,1
    8000594a:	ffffd097          	auipc	ra,0xffffd
    8000594e:	4a6080e7          	jalr	1190(ra) # 80002df0 <argint>
    80005952:	0a054863          	bltz	a0,80005a02 <sys_open+0xe4>

  begin_op();
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	a2a080e7          	jalr	-1494(ra) # 80004380 <begin_op>

  if(omode & O_CREATE){
    8000595e:	f4c42783          	lw	a5,-180(s0)
    80005962:	2007f793          	andi	a5,a5,512
    80005966:	cbdd                	beqz	a5,80005a1c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005968:	4681                	li	a3,0
    8000596a:	4601                	li	a2,0
    8000596c:	4589                	li	a1,2
    8000596e:	f5040513          	addi	a0,s0,-176
    80005972:	00000097          	auipc	ra,0x0
    80005976:	972080e7          	jalr	-1678(ra) # 800052e4 <create>
    8000597a:	892a                	mv	s2,a0
    if(ip == 0){
    8000597c:	c959                	beqz	a0,80005a12 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000597e:	04491703          	lh	a4,68(s2)
    80005982:	478d                	li	a5,3
    80005984:	00f71763          	bne	a4,a5,80005992 <sys_open+0x74>
    80005988:	04695703          	lhu	a4,70(s2)
    8000598c:	47a5                	li	a5,9
    8000598e:	0ce7ec63          	bltu	a5,a4,80005a66 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	dfe080e7          	jalr	-514(ra) # 80004790 <filealloc>
    8000599a:	89aa                	mv	s3,a0
    8000599c:	10050263          	beqz	a0,80005aa0 <sys_open+0x182>
    800059a0:	00000097          	auipc	ra,0x0
    800059a4:	902080e7          	jalr	-1790(ra) # 800052a2 <fdalloc>
    800059a8:	84aa                	mv	s1,a0
    800059aa:	0e054663          	bltz	a0,80005a96 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059ae:	04491703          	lh	a4,68(s2)
    800059b2:	478d                	li	a5,3
    800059b4:	0cf70463          	beq	a4,a5,80005a7c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059b8:	4789                	li	a5,2
    800059ba:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059be:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059c2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059c6:	f4c42783          	lw	a5,-180(s0)
    800059ca:	0017c713          	xori	a4,a5,1
    800059ce:	8b05                	andi	a4,a4,1
    800059d0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059d4:	0037f713          	andi	a4,a5,3
    800059d8:	00e03733          	snez	a4,a4
    800059dc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059e0:	4007f793          	andi	a5,a5,1024
    800059e4:	c791                	beqz	a5,800059f0 <sys_open+0xd2>
    800059e6:	04491703          	lh	a4,68(s2)
    800059ea:	4789                	li	a5,2
    800059ec:	08f70f63          	beq	a4,a5,80005a8a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059f0:	854a                	mv	a0,s2
    800059f2:	ffffe097          	auipc	ra,0xffffe
    800059f6:	07e080e7          	jalr	126(ra) # 80003a70 <iunlock>
  end_op();
    800059fa:	fffff097          	auipc	ra,0xfffff
    800059fe:	a06080e7          	jalr	-1530(ra) # 80004400 <end_op>

  return fd;
}
    80005a02:	8526                	mv	a0,s1
    80005a04:	70ea                	ld	ra,184(sp)
    80005a06:	744a                	ld	s0,176(sp)
    80005a08:	74aa                	ld	s1,168(sp)
    80005a0a:	790a                	ld	s2,160(sp)
    80005a0c:	69ea                	ld	s3,152(sp)
    80005a0e:	6129                	addi	sp,sp,192
    80005a10:	8082                	ret
      end_op();
    80005a12:	fffff097          	auipc	ra,0xfffff
    80005a16:	9ee080e7          	jalr	-1554(ra) # 80004400 <end_op>
      return -1;
    80005a1a:	b7e5                	j	80005a02 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a1c:	f5040513          	addi	a0,s0,-176
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	744080e7          	jalr	1860(ra) # 80004164 <namei>
    80005a28:	892a                	mv	s2,a0
    80005a2a:	c905                	beqz	a0,80005a5a <sys_open+0x13c>
    ilock(ip);
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	f82080e7          	jalr	-126(ra) # 800039ae <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a34:	04491703          	lh	a4,68(s2)
    80005a38:	4785                	li	a5,1
    80005a3a:	f4f712e3          	bne	a4,a5,8000597e <sys_open+0x60>
    80005a3e:	f4c42783          	lw	a5,-180(s0)
    80005a42:	dba1                	beqz	a5,80005992 <sys_open+0x74>
      iunlockput(ip);
    80005a44:	854a                	mv	a0,s2
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	1ca080e7          	jalr	458(ra) # 80003c10 <iunlockput>
      end_op();
    80005a4e:	fffff097          	auipc	ra,0xfffff
    80005a52:	9b2080e7          	jalr	-1614(ra) # 80004400 <end_op>
      return -1;
    80005a56:	54fd                	li	s1,-1
    80005a58:	b76d                	j	80005a02 <sys_open+0xe4>
      end_op();
    80005a5a:	fffff097          	auipc	ra,0xfffff
    80005a5e:	9a6080e7          	jalr	-1626(ra) # 80004400 <end_op>
      return -1;
    80005a62:	54fd                	li	s1,-1
    80005a64:	bf79                	j	80005a02 <sys_open+0xe4>
    iunlockput(ip);
    80005a66:	854a                	mv	a0,s2
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	1a8080e7          	jalr	424(ra) # 80003c10 <iunlockput>
    end_op();
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	990080e7          	jalr	-1648(ra) # 80004400 <end_op>
    return -1;
    80005a78:	54fd                	li	s1,-1
    80005a7a:	b761                	j	80005a02 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a7c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a80:	04691783          	lh	a5,70(s2)
    80005a84:	02f99223          	sh	a5,36(s3)
    80005a88:	bf2d                	j	800059c2 <sys_open+0xa4>
    itrunc(ip);
    80005a8a:	854a                	mv	a0,s2
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	030080e7          	jalr	48(ra) # 80003abc <itrunc>
    80005a94:	bfb1                	j	800059f0 <sys_open+0xd2>
      fileclose(f);
    80005a96:	854e                	mv	a0,s3
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	db4080e7          	jalr	-588(ra) # 8000484c <fileclose>
    iunlockput(ip);
    80005aa0:	854a                	mv	a0,s2
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	16e080e7          	jalr	366(ra) # 80003c10 <iunlockput>
    end_op();
    80005aaa:	fffff097          	auipc	ra,0xfffff
    80005aae:	956080e7          	jalr	-1706(ra) # 80004400 <end_op>
    return -1;
    80005ab2:	54fd                	li	s1,-1
    80005ab4:	b7b9                	j	80005a02 <sys_open+0xe4>

0000000080005ab6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ab6:	7175                	addi	sp,sp,-144
    80005ab8:	e506                	sd	ra,136(sp)
    80005aba:	e122                	sd	s0,128(sp)
    80005abc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005abe:	fffff097          	auipc	ra,0xfffff
    80005ac2:	8c2080e7          	jalr	-1854(ra) # 80004380 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ac6:	08000613          	li	a2,128
    80005aca:	f7040593          	addi	a1,s0,-144
    80005ace:	4501                	li	a0,0
    80005ad0:	ffffd097          	auipc	ra,0xffffd
    80005ad4:	364080e7          	jalr	868(ra) # 80002e34 <argstr>
    80005ad8:	02054963          	bltz	a0,80005b0a <sys_mkdir+0x54>
    80005adc:	4681                	li	a3,0
    80005ade:	4601                	li	a2,0
    80005ae0:	4585                	li	a1,1
    80005ae2:	f7040513          	addi	a0,s0,-144
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	7fe080e7          	jalr	2046(ra) # 800052e4 <create>
    80005aee:	cd11                	beqz	a0,80005b0a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005af0:	ffffe097          	auipc	ra,0xffffe
    80005af4:	120080e7          	jalr	288(ra) # 80003c10 <iunlockput>
  end_op();
    80005af8:	fffff097          	auipc	ra,0xfffff
    80005afc:	908080e7          	jalr	-1784(ra) # 80004400 <end_op>
  return 0;
    80005b00:	4501                	li	a0,0
}
    80005b02:	60aa                	ld	ra,136(sp)
    80005b04:	640a                	ld	s0,128(sp)
    80005b06:	6149                	addi	sp,sp,144
    80005b08:	8082                	ret
    end_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	8f6080e7          	jalr	-1802(ra) # 80004400 <end_op>
    return -1;
    80005b12:	557d                	li	a0,-1
    80005b14:	b7fd                	j	80005b02 <sys_mkdir+0x4c>

0000000080005b16 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b16:	7135                	addi	sp,sp,-160
    80005b18:	ed06                	sd	ra,152(sp)
    80005b1a:	e922                	sd	s0,144(sp)
    80005b1c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	862080e7          	jalr	-1950(ra) # 80004380 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b26:	08000613          	li	a2,128
    80005b2a:	f7040593          	addi	a1,s0,-144
    80005b2e:	4501                	li	a0,0
    80005b30:	ffffd097          	auipc	ra,0xffffd
    80005b34:	304080e7          	jalr	772(ra) # 80002e34 <argstr>
    80005b38:	04054a63          	bltz	a0,80005b8c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b3c:	f6c40593          	addi	a1,s0,-148
    80005b40:	4505                	li	a0,1
    80005b42:	ffffd097          	auipc	ra,0xffffd
    80005b46:	2ae080e7          	jalr	686(ra) # 80002df0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b4a:	04054163          	bltz	a0,80005b8c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b4e:	f6840593          	addi	a1,s0,-152
    80005b52:	4509                	li	a0,2
    80005b54:	ffffd097          	auipc	ra,0xffffd
    80005b58:	29c080e7          	jalr	668(ra) # 80002df0 <argint>
     argint(1, &major) < 0 ||
    80005b5c:	02054863          	bltz	a0,80005b8c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b60:	f6841683          	lh	a3,-152(s0)
    80005b64:	f6c41603          	lh	a2,-148(s0)
    80005b68:	458d                	li	a1,3
    80005b6a:	f7040513          	addi	a0,s0,-144
    80005b6e:	fffff097          	auipc	ra,0xfffff
    80005b72:	776080e7          	jalr	1910(ra) # 800052e4 <create>
     argint(2, &minor) < 0 ||
    80005b76:	c919                	beqz	a0,80005b8c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	098080e7          	jalr	152(ra) # 80003c10 <iunlockput>
  end_op();
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	880080e7          	jalr	-1920(ra) # 80004400 <end_op>
  return 0;
    80005b88:	4501                	li	a0,0
    80005b8a:	a031                	j	80005b96 <sys_mknod+0x80>
    end_op();
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	874080e7          	jalr	-1932(ra) # 80004400 <end_op>
    return -1;
    80005b94:	557d                	li	a0,-1
}
    80005b96:	60ea                	ld	ra,152(sp)
    80005b98:	644a                	ld	s0,144(sp)
    80005b9a:	610d                	addi	sp,sp,160
    80005b9c:	8082                	ret

0000000080005b9e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b9e:	7135                	addi	sp,sp,-160
    80005ba0:	ed06                	sd	ra,152(sp)
    80005ba2:	e922                	sd	s0,144(sp)
    80005ba4:	e526                	sd	s1,136(sp)
    80005ba6:	e14a                	sd	s2,128(sp)
    80005ba8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005baa:	ffffc097          	auipc	ra,0xffffc
    80005bae:	e08080e7          	jalr	-504(ra) # 800019b2 <myproc>
    80005bb2:	892a                	mv	s2,a0
  
  begin_op();
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	7cc080e7          	jalr	1996(ra) # 80004380 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005bbc:	08000613          	li	a2,128
    80005bc0:	f6040593          	addi	a1,s0,-160
    80005bc4:	4501                	li	a0,0
    80005bc6:	ffffd097          	auipc	ra,0xffffd
    80005bca:	26e080e7          	jalr	622(ra) # 80002e34 <argstr>
    80005bce:	04054b63          	bltz	a0,80005c24 <sys_chdir+0x86>
    80005bd2:	f6040513          	addi	a0,s0,-160
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	58e080e7          	jalr	1422(ra) # 80004164 <namei>
    80005bde:	84aa                	mv	s1,a0
    80005be0:	c131                	beqz	a0,80005c24 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	dcc080e7          	jalr	-564(ra) # 800039ae <ilock>
  if(ip->type != T_DIR){
    80005bea:	04449703          	lh	a4,68(s1)
    80005bee:	4785                	li	a5,1
    80005bf0:	04f71063          	bne	a4,a5,80005c30 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bf4:	8526                	mv	a0,s1
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	e7a080e7          	jalr	-390(ra) # 80003a70 <iunlock>
  iput(p->cwd);
    80005bfe:	15093503          	ld	a0,336(s2)
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	f66080e7          	jalr	-154(ra) # 80003b68 <iput>
  end_op();
    80005c0a:	ffffe097          	auipc	ra,0xffffe
    80005c0e:	7f6080e7          	jalr	2038(ra) # 80004400 <end_op>
  p->cwd = ip;
    80005c12:	14993823          	sd	s1,336(s2)
  return 0;
    80005c16:	4501                	li	a0,0
}
    80005c18:	60ea                	ld	ra,152(sp)
    80005c1a:	644a                	ld	s0,144(sp)
    80005c1c:	64aa                	ld	s1,136(sp)
    80005c1e:	690a                	ld	s2,128(sp)
    80005c20:	610d                	addi	sp,sp,160
    80005c22:	8082                	ret
    end_op();
    80005c24:	ffffe097          	auipc	ra,0xffffe
    80005c28:	7dc080e7          	jalr	2012(ra) # 80004400 <end_op>
    return -1;
    80005c2c:	557d                	li	a0,-1
    80005c2e:	b7ed                	j	80005c18 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c30:	8526                	mv	a0,s1
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	fde080e7          	jalr	-34(ra) # 80003c10 <iunlockput>
    end_op();
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	7c6080e7          	jalr	1990(ra) # 80004400 <end_op>
    return -1;
    80005c42:	557d                	li	a0,-1
    80005c44:	bfd1                	j	80005c18 <sys_chdir+0x7a>

0000000080005c46 <sys_exec>:

uint64
sys_exec(void)
{
    80005c46:	7145                	addi	sp,sp,-464
    80005c48:	e786                	sd	ra,456(sp)
    80005c4a:	e3a2                	sd	s0,448(sp)
    80005c4c:	ff26                	sd	s1,440(sp)
    80005c4e:	fb4a                	sd	s2,432(sp)
    80005c50:	f74e                	sd	s3,424(sp)
    80005c52:	f352                	sd	s4,416(sp)
    80005c54:	ef56                	sd	s5,408(sp)
    80005c56:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c58:	08000613          	li	a2,128
    80005c5c:	f4040593          	addi	a1,s0,-192
    80005c60:	4501                	li	a0,0
    80005c62:	ffffd097          	auipc	ra,0xffffd
    80005c66:	1d2080e7          	jalr	466(ra) # 80002e34 <argstr>
    return -1;
    80005c6a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c6c:	0c054a63          	bltz	a0,80005d40 <sys_exec+0xfa>
    80005c70:	e3840593          	addi	a1,s0,-456
    80005c74:	4505                	li	a0,1
    80005c76:	ffffd097          	auipc	ra,0xffffd
    80005c7a:	19c080e7          	jalr	412(ra) # 80002e12 <argaddr>
    80005c7e:	0c054163          	bltz	a0,80005d40 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c82:	10000613          	li	a2,256
    80005c86:	4581                	li	a1,0
    80005c88:	e4040513          	addi	a0,s0,-448
    80005c8c:	ffffb097          	auipc	ra,0xffffb
    80005c90:	056080e7          	jalr	86(ra) # 80000ce2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c94:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c98:	89a6                	mv	s3,s1
    80005c9a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c9c:	02000a13          	li	s4,32
    80005ca0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ca4:	00391513          	slli	a0,s2,0x3
    80005ca8:	e3040593          	addi	a1,s0,-464
    80005cac:	e3843783          	ld	a5,-456(s0)
    80005cb0:	953e                	add	a0,a0,a5
    80005cb2:	ffffd097          	auipc	ra,0xffffd
    80005cb6:	0a4080e7          	jalr	164(ra) # 80002d56 <fetchaddr>
    80005cba:	02054a63          	bltz	a0,80005cee <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005cbe:	e3043783          	ld	a5,-464(s0)
    80005cc2:	c3b9                	beqz	a5,80005d08 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cc4:	ffffb097          	auipc	ra,0xffffb
    80005cc8:	e32080e7          	jalr	-462(ra) # 80000af6 <kalloc>
    80005ccc:	85aa                	mv	a1,a0
    80005cce:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cd2:	cd11                	beqz	a0,80005cee <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cd4:	6605                	lui	a2,0x1
    80005cd6:	e3043503          	ld	a0,-464(s0)
    80005cda:	ffffd097          	auipc	ra,0xffffd
    80005cde:	0ce080e7          	jalr	206(ra) # 80002da8 <fetchstr>
    80005ce2:	00054663          	bltz	a0,80005cee <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ce6:	0905                	addi	s2,s2,1
    80005ce8:	09a1                	addi	s3,s3,8
    80005cea:	fb491be3          	bne	s2,s4,80005ca0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cee:	10048913          	addi	s2,s1,256
    80005cf2:	6088                	ld	a0,0(s1)
    80005cf4:	c529                	beqz	a0,80005d3e <sys_exec+0xf8>
    kfree(argv[i]);
    80005cf6:	ffffb097          	auipc	ra,0xffffb
    80005cfa:	d04080e7          	jalr	-764(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cfe:	04a1                	addi	s1,s1,8
    80005d00:	ff2499e3          	bne	s1,s2,80005cf2 <sys_exec+0xac>
  return -1;
    80005d04:	597d                	li	s2,-1
    80005d06:	a82d                	j	80005d40 <sys_exec+0xfa>
      argv[i] = 0;
    80005d08:	0a8e                	slli	s5,s5,0x3
    80005d0a:	fc040793          	addi	a5,s0,-64
    80005d0e:	9abe                	add	s5,s5,a5
    80005d10:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d14:	e4040593          	addi	a1,s0,-448
    80005d18:	f4040513          	addi	a0,s0,-192
    80005d1c:	fffff097          	auipc	ra,0xfffff
    80005d20:	194080e7          	jalr	404(ra) # 80004eb0 <exec>
    80005d24:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d26:	10048993          	addi	s3,s1,256
    80005d2a:	6088                	ld	a0,0(s1)
    80005d2c:	c911                	beqz	a0,80005d40 <sys_exec+0xfa>
    kfree(argv[i]);
    80005d2e:	ffffb097          	auipc	ra,0xffffb
    80005d32:	ccc080e7          	jalr	-820(ra) # 800009fa <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d36:	04a1                	addi	s1,s1,8
    80005d38:	ff3499e3          	bne	s1,s3,80005d2a <sys_exec+0xe4>
    80005d3c:	a011                	j	80005d40 <sys_exec+0xfa>
  return -1;
    80005d3e:	597d                	li	s2,-1
}
    80005d40:	854a                	mv	a0,s2
    80005d42:	60be                	ld	ra,456(sp)
    80005d44:	641e                	ld	s0,448(sp)
    80005d46:	74fa                	ld	s1,440(sp)
    80005d48:	795a                	ld	s2,432(sp)
    80005d4a:	79ba                	ld	s3,424(sp)
    80005d4c:	7a1a                	ld	s4,416(sp)
    80005d4e:	6afa                	ld	s5,408(sp)
    80005d50:	6179                	addi	sp,sp,464
    80005d52:	8082                	ret

0000000080005d54 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d54:	7139                	addi	sp,sp,-64
    80005d56:	fc06                	sd	ra,56(sp)
    80005d58:	f822                	sd	s0,48(sp)
    80005d5a:	f426                	sd	s1,40(sp)
    80005d5c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d5e:	ffffc097          	auipc	ra,0xffffc
    80005d62:	c54080e7          	jalr	-940(ra) # 800019b2 <myproc>
    80005d66:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d68:	fd840593          	addi	a1,s0,-40
    80005d6c:	4501                	li	a0,0
    80005d6e:	ffffd097          	auipc	ra,0xffffd
    80005d72:	0a4080e7          	jalr	164(ra) # 80002e12 <argaddr>
    return -1;
    80005d76:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d78:	0e054063          	bltz	a0,80005e58 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d7c:	fc840593          	addi	a1,s0,-56
    80005d80:	fd040513          	addi	a0,s0,-48
    80005d84:	fffff097          	auipc	ra,0xfffff
    80005d88:	df8080e7          	jalr	-520(ra) # 80004b7c <pipealloc>
    return -1;
    80005d8c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d8e:	0c054563          	bltz	a0,80005e58 <sys_pipe+0x104>
  fd0 = -1;
    80005d92:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d96:	fd043503          	ld	a0,-48(s0)
    80005d9a:	fffff097          	auipc	ra,0xfffff
    80005d9e:	508080e7          	jalr	1288(ra) # 800052a2 <fdalloc>
    80005da2:	fca42223          	sw	a0,-60(s0)
    80005da6:	08054c63          	bltz	a0,80005e3e <sys_pipe+0xea>
    80005daa:	fc843503          	ld	a0,-56(s0)
    80005dae:	fffff097          	auipc	ra,0xfffff
    80005db2:	4f4080e7          	jalr	1268(ra) # 800052a2 <fdalloc>
    80005db6:	fca42023          	sw	a0,-64(s0)
    80005dba:	06054863          	bltz	a0,80005e2a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dbe:	4691                	li	a3,4
    80005dc0:	fc440613          	addi	a2,s0,-60
    80005dc4:	fd843583          	ld	a1,-40(s0)
    80005dc8:	68a8                	ld	a0,80(s1)
    80005dca:	ffffc097          	auipc	ra,0xffffc
    80005dce:	8aa080e7          	jalr	-1878(ra) # 80001674 <copyout>
    80005dd2:	02054063          	bltz	a0,80005df2 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005dd6:	4691                	li	a3,4
    80005dd8:	fc040613          	addi	a2,s0,-64
    80005ddc:	fd843583          	ld	a1,-40(s0)
    80005de0:	0591                	addi	a1,a1,4
    80005de2:	68a8                	ld	a0,80(s1)
    80005de4:	ffffc097          	auipc	ra,0xffffc
    80005de8:	890080e7          	jalr	-1904(ra) # 80001674 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005dec:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dee:	06055563          	bgez	a0,80005e58 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005df2:	fc442783          	lw	a5,-60(s0)
    80005df6:	07e9                	addi	a5,a5,26
    80005df8:	078e                	slli	a5,a5,0x3
    80005dfa:	97a6                	add	a5,a5,s1
    80005dfc:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e00:	fc042503          	lw	a0,-64(s0)
    80005e04:	0569                	addi	a0,a0,26
    80005e06:	050e                	slli	a0,a0,0x3
    80005e08:	9526                	add	a0,a0,s1
    80005e0a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e0e:	fd043503          	ld	a0,-48(s0)
    80005e12:	fffff097          	auipc	ra,0xfffff
    80005e16:	a3a080e7          	jalr	-1478(ra) # 8000484c <fileclose>
    fileclose(wf);
    80005e1a:	fc843503          	ld	a0,-56(s0)
    80005e1e:	fffff097          	auipc	ra,0xfffff
    80005e22:	a2e080e7          	jalr	-1490(ra) # 8000484c <fileclose>
    return -1;
    80005e26:	57fd                	li	a5,-1
    80005e28:	a805                	j	80005e58 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e2a:	fc442783          	lw	a5,-60(s0)
    80005e2e:	0007c863          	bltz	a5,80005e3e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e32:	01a78513          	addi	a0,a5,26
    80005e36:	050e                	slli	a0,a0,0x3
    80005e38:	9526                	add	a0,a0,s1
    80005e3a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005e3e:	fd043503          	ld	a0,-48(s0)
    80005e42:	fffff097          	auipc	ra,0xfffff
    80005e46:	a0a080e7          	jalr	-1526(ra) # 8000484c <fileclose>
    fileclose(wf);
    80005e4a:	fc843503          	ld	a0,-56(s0)
    80005e4e:	fffff097          	auipc	ra,0xfffff
    80005e52:	9fe080e7          	jalr	-1538(ra) # 8000484c <fileclose>
    return -1;
    80005e56:	57fd                	li	a5,-1
}
    80005e58:	853e                	mv	a0,a5
    80005e5a:	70e2                	ld	ra,56(sp)
    80005e5c:	7442                	ld	s0,48(sp)
    80005e5e:	74a2                	ld	s1,40(sp)
    80005e60:	6121                	addi	sp,sp,64
    80005e62:	8082                	ret
	...

0000000080005e70 <kernelvec>:
    80005e70:	7111                	addi	sp,sp,-256
    80005e72:	e006                	sd	ra,0(sp)
    80005e74:	e40a                	sd	sp,8(sp)
    80005e76:	e80e                	sd	gp,16(sp)
    80005e78:	ec12                	sd	tp,24(sp)
    80005e7a:	f016                	sd	t0,32(sp)
    80005e7c:	f41a                	sd	t1,40(sp)
    80005e7e:	f81e                	sd	t2,48(sp)
    80005e80:	fc22                	sd	s0,56(sp)
    80005e82:	e0a6                	sd	s1,64(sp)
    80005e84:	e4aa                	sd	a0,72(sp)
    80005e86:	e8ae                	sd	a1,80(sp)
    80005e88:	ecb2                	sd	a2,88(sp)
    80005e8a:	f0b6                	sd	a3,96(sp)
    80005e8c:	f4ba                	sd	a4,104(sp)
    80005e8e:	f8be                	sd	a5,112(sp)
    80005e90:	fcc2                	sd	a6,120(sp)
    80005e92:	e146                	sd	a7,128(sp)
    80005e94:	e54a                	sd	s2,136(sp)
    80005e96:	e94e                	sd	s3,144(sp)
    80005e98:	ed52                	sd	s4,152(sp)
    80005e9a:	f156                	sd	s5,160(sp)
    80005e9c:	f55a                	sd	s6,168(sp)
    80005e9e:	f95e                	sd	s7,176(sp)
    80005ea0:	fd62                	sd	s8,184(sp)
    80005ea2:	e1e6                	sd	s9,192(sp)
    80005ea4:	e5ea                	sd	s10,200(sp)
    80005ea6:	e9ee                	sd	s11,208(sp)
    80005ea8:	edf2                	sd	t3,216(sp)
    80005eaa:	f1f6                	sd	t4,224(sp)
    80005eac:	f5fa                	sd	t5,232(sp)
    80005eae:	f9fe                	sd	t6,240(sp)
    80005eb0:	d71fc0ef          	jal	ra,80002c20 <kerneltrap>
    80005eb4:	6082                	ld	ra,0(sp)
    80005eb6:	6122                	ld	sp,8(sp)
    80005eb8:	61c2                	ld	gp,16(sp)
    80005eba:	7282                	ld	t0,32(sp)
    80005ebc:	7322                	ld	t1,40(sp)
    80005ebe:	73c2                	ld	t2,48(sp)
    80005ec0:	7462                	ld	s0,56(sp)
    80005ec2:	6486                	ld	s1,64(sp)
    80005ec4:	6526                	ld	a0,72(sp)
    80005ec6:	65c6                	ld	a1,80(sp)
    80005ec8:	6666                	ld	a2,88(sp)
    80005eca:	7686                	ld	a3,96(sp)
    80005ecc:	7726                	ld	a4,104(sp)
    80005ece:	77c6                	ld	a5,112(sp)
    80005ed0:	7866                	ld	a6,120(sp)
    80005ed2:	688a                	ld	a7,128(sp)
    80005ed4:	692a                	ld	s2,136(sp)
    80005ed6:	69ca                	ld	s3,144(sp)
    80005ed8:	6a6a                	ld	s4,152(sp)
    80005eda:	7a8a                	ld	s5,160(sp)
    80005edc:	7b2a                	ld	s6,168(sp)
    80005ede:	7bca                	ld	s7,176(sp)
    80005ee0:	7c6a                	ld	s8,184(sp)
    80005ee2:	6c8e                	ld	s9,192(sp)
    80005ee4:	6d2e                	ld	s10,200(sp)
    80005ee6:	6dce                	ld	s11,208(sp)
    80005ee8:	6e6e                	ld	t3,216(sp)
    80005eea:	7e8e                	ld	t4,224(sp)
    80005eec:	7f2e                	ld	t5,232(sp)
    80005eee:	7fce                	ld	t6,240(sp)
    80005ef0:	6111                	addi	sp,sp,256
    80005ef2:	10200073          	sret
    80005ef6:	00000013          	nop
    80005efa:	00000013          	nop
    80005efe:	0001                	nop

0000000080005f00 <timervec>:
    80005f00:	34051573          	csrrw	a0,mscratch,a0
    80005f04:	e10c                	sd	a1,0(a0)
    80005f06:	e510                	sd	a2,8(a0)
    80005f08:	e914                	sd	a3,16(a0)
    80005f0a:	6d0c                	ld	a1,24(a0)
    80005f0c:	7110                	ld	a2,32(a0)
    80005f0e:	6194                	ld	a3,0(a1)
    80005f10:	96b2                	add	a3,a3,a2
    80005f12:	e194                	sd	a3,0(a1)
    80005f14:	4589                	li	a1,2
    80005f16:	14459073          	csrw	sip,a1
    80005f1a:	6914                	ld	a3,16(a0)
    80005f1c:	6510                	ld	a2,8(a0)
    80005f1e:	610c                	ld	a1,0(a0)
    80005f20:	34051573          	csrrw	a0,mscratch,a0
    80005f24:	30200073          	mret
	...

0000000080005f2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f2a:	1141                	addi	sp,sp,-16
    80005f2c:	e422                	sd	s0,8(sp)
    80005f2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f30:	0c0007b7          	lui	a5,0xc000
    80005f34:	4705                	li	a4,1
    80005f36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f38:	c3d8                	sw	a4,4(a5)
}
    80005f3a:	6422                	ld	s0,8(sp)
    80005f3c:	0141                	addi	sp,sp,16
    80005f3e:	8082                	ret

0000000080005f40 <plicinithart>:

void
plicinithart(void)
{
    80005f40:	1141                	addi	sp,sp,-16
    80005f42:	e406                	sd	ra,8(sp)
    80005f44:	e022                	sd	s0,0(sp)
    80005f46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f48:	ffffc097          	auipc	ra,0xffffc
    80005f4c:	a3e080e7          	jalr	-1474(ra) # 80001986 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f50:	0085171b          	slliw	a4,a0,0x8
    80005f54:	0c0027b7          	lui	a5,0xc002
    80005f58:	97ba                	add	a5,a5,a4
    80005f5a:	40200713          	li	a4,1026
    80005f5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f62:	00d5151b          	slliw	a0,a0,0xd
    80005f66:	0c2017b7          	lui	a5,0xc201
    80005f6a:	953e                	add	a0,a0,a5
    80005f6c:	00052023          	sw	zero,0(a0)
}
    80005f70:	60a2                	ld	ra,8(sp)
    80005f72:	6402                	ld	s0,0(sp)
    80005f74:	0141                	addi	sp,sp,16
    80005f76:	8082                	ret

0000000080005f78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f78:	1141                	addi	sp,sp,-16
    80005f7a:	e406                	sd	ra,8(sp)
    80005f7c:	e022                	sd	s0,0(sp)
    80005f7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f80:	ffffc097          	auipc	ra,0xffffc
    80005f84:	a06080e7          	jalr	-1530(ra) # 80001986 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f88:	00d5179b          	slliw	a5,a0,0xd
    80005f8c:	0c201537          	lui	a0,0xc201
    80005f90:	953e                	add	a0,a0,a5
  return irq;
}
    80005f92:	4148                	lw	a0,4(a0)
    80005f94:	60a2                	ld	ra,8(sp)
    80005f96:	6402                	ld	s0,0(sp)
    80005f98:	0141                	addi	sp,sp,16
    80005f9a:	8082                	ret

0000000080005f9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f9c:	1101                	addi	sp,sp,-32
    80005f9e:	ec06                	sd	ra,24(sp)
    80005fa0:	e822                	sd	s0,16(sp)
    80005fa2:	e426                	sd	s1,8(sp)
    80005fa4:	1000                	addi	s0,sp,32
    80005fa6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	9de080e7          	jalr	-1570(ra) # 80001986 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fb0:	00d5151b          	slliw	a0,a0,0xd
    80005fb4:	0c2017b7          	lui	a5,0xc201
    80005fb8:	97aa                	add	a5,a5,a0
    80005fba:	c3c4                	sw	s1,4(a5)
}
    80005fbc:	60e2                	ld	ra,24(sp)
    80005fbe:	6442                	ld	s0,16(sp)
    80005fc0:	64a2                	ld	s1,8(sp)
    80005fc2:	6105                	addi	sp,sp,32
    80005fc4:	8082                	ret

0000000080005fc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fc6:	1141                	addi	sp,sp,-16
    80005fc8:	e406                	sd	ra,8(sp)
    80005fca:	e022                	sd	s0,0(sp)
    80005fcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fce:	479d                	li	a5,7
    80005fd0:	06a7c963          	blt	a5,a0,80006042 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005fd4:	0001d797          	auipc	a5,0x1d
    80005fd8:	02c78793          	addi	a5,a5,44 # 80023000 <disk>
    80005fdc:	00a78733          	add	a4,a5,a0
    80005fe0:	6789                	lui	a5,0x2
    80005fe2:	97ba                	add	a5,a5,a4
    80005fe4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005fe8:	e7ad                	bnez	a5,80006052 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005fea:	00451793          	slli	a5,a0,0x4
    80005fee:	0001f717          	auipc	a4,0x1f
    80005ff2:	01270713          	addi	a4,a4,18 # 80025000 <disk+0x2000>
    80005ff6:	6314                	ld	a3,0(a4)
    80005ff8:	96be                	add	a3,a3,a5
    80005ffa:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005ffe:	6314                	ld	a3,0(a4)
    80006000:	96be                	add	a3,a3,a5
    80006002:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006006:	6314                	ld	a3,0(a4)
    80006008:	96be                	add	a3,a3,a5
    8000600a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000600e:	6318                	ld	a4,0(a4)
    80006010:	97ba                	add	a5,a5,a4
    80006012:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006016:	0001d797          	auipc	a5,0x1d
    8000601a:	fea78793          	addi	a5,a5,-22 # 80023000 <disk>
    8000601e:	97aa                	add	a5,a5,a0
    80006020:	6509                	lui	a0,0x2
    80006022:	953e                	add	a0,a0,a5
    80006024:	4785                	li	a5,1
    80006026:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000602a:	0001f517          	auipc	a0,0x1f
    8000602e:	fee50513          	addi	a0,a0,-18 # 80025018 <disk+0x2018>
    80006032:	ffffc097          	auipc	ra,0xffffc
    80006036:	34a080e7          	jalr	842(ra) # 8000237c <wakeup>
}
    8000603a:	60a2                	ld	ra,8(sp)
    8000603c:	6402                	ld	s0,0(sp)
    8000603e:	0141                	addi	sp,sp,16
    80006040:	8082                	ret
    panic("free_desc 1");
    80006042:	00002517          	auipc	a0,0x2
    80006046:	7fe50513          	addi	a0,a0,2046 # 80008840 <syscalls+0x330>
    8000604a:	ffffa097          	auipc	ra,0xffffa
    8000604e:	4f6080e7          	jalr	1270(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006052:	00002517          	auipc	a0,0x2
    80006056:	7fe50513          	addi	a0,a0,2046 # 80008850 <syscalls+0x340>
    8000605a:	ffffa097          	auipc	ra,0xffffa
    8000605e:	4e6080e7          	jalr	1254(ra) # 80000540 <panic>

0000000080006062 <virtio_disk_init>:
{
    80006062:	1101                	addi	sp,sp,-32
    80006064:	ec06                	sd	ra,24(sp)
    80006066:	e822                	sd	s0,16(sp)
    80006068:	e426                	sd	s1,8(sp)
    8000606a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000606c:	00002597          	auipc	a1,0x2
    80006070:	7f458593          	addi	a1,a1,2036 # 80008860 <syscalls+0x350>
    80006074:	0001f517          	auipc	a0,0x1f
    80006078:	0b450513          	addi	a0,a0,180 # 80025128 <disk+0x2128>
    8000607c:	ffffb097          	auipc	ra,0xffffb
    80006080:	ada080e7          	jalr	-1318(ra) # 80000b56 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006084:	100017b7          	lui	a5,0x10001
    80006088:	4398                	lw	a4,0(a5)
    8000608a:	2701                	sext.w	a4,a4
    8000608c:	747277b7          	lui	a5,0x74727
    80006090:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006094:	0ef71163          	bne	a4,a5,80006176 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006098:	100017b7          	lui	a5,0x10001
    8000609c:	43dc                	lw	a5,4(a5)
    8000609e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060a0:	4705                	li	a4,1
    800060a2:	0ce79a63          	bne	a5,a4,80006176 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060a6:	100017b7          	lui	a5,0x10001
    800060aa:	479c                	lw	a5,8(a5)
    800060ac:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060ae:	4709                	li	a4,2
    800060b0:	0ce79363          	bne	a5,a4,80006176 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060b4:	100017b7          	lui	a5,0x10001
    800060b8:	47d8                	lw	a4,12(a5)
    800060ba:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060bc:	554d47b7          	lui	a5,0x554d4
    800060c0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060c4:	0af71963          	bne	a4,a5,80006176 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060c8:	100017b7          	lui	a5,0x10001
    800060cc:	4705                	li	a4,1
    800060ce:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060d0:	470d                	li	a4,3
    800060d2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060d4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060d6:	c7ffe737          	lui	a4,0xc7ffe
    800060da:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800060de:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060e0:	2701                	sext.w	a4,a4
    800060e2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060e4:	472d                	li	a4,11
    800060e6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060e8:	473d                	li	a4,15
    800060ea:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060ec:	6705                	lui	a4,0x1
    800060ee:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060f0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060f4:	5bdc                	lw	a5,52(a5)
    800060f6:	2781                	sext.w	a5,a5
  if(max == 0)
    800060f8:	c7d9                	beqz	a5,80006186 <virtio_disk_init+0x124>
  if(max < NUM)
    800060fa:	471d                	li	a4,7
    800060fc:	08f77d63          	bgeu	a4,a5,80006196 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006100:	100014b7          	lui	s1,0x10001
    80006104:	47a1                	li	a5,8
    80006106:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006108:	6609                	lui	a2,0x2
    8000610a:	4581                	li	a1,0
    8000610c:	0001d517          	auipc	a0,0x1d
    80006110:	ef450513          	addi	a0,a0,-268 # 80023000 <disk>
    80006114:	ffffb097          	auipc	ra,0xffffb
    80006118:	bce080e7          	jalr	-1074(ra) # 80000ce2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000611c:	0001d717          	auipc	a4,0x1d
    80006120:	ee470713          	addi	a4,a4,-284 # 80023000 <disk>
    80006124:	00c75793          	srli	a5,a4,0xc
    80006128:	2781                	sext.w	a5,a5
    8000612a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000612c:	0001f797          	auipc	a5,0x1f
    80006130:	ed478793          	addi	a5,a5,-300 # 80025000 <disk+0x2000>
    80006134:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006136:	0001d717          	auipc	a4,0x1d
    8000613a:	f4a70713          	addi	a4,a4,-182 # 80023080 <disk+0x80>
    8000613e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006140:	0001e717          	auipc	a4,0x1e
    80006144:	ec070713          	addi	a4,a4,-320 # 80024000 <disk+0x1000>
    80006148:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000614a:	4705                	li	a4,1
    8000614c:	00e78c23          	sb	a4,24(a5)
    80006150:	00e78ca3          	sb	a4,25(a5)
    80006154:	00e78d23          	sb	a4,26(a5)
    80006158:	00e78da3          	sb	a4,27(a5)
    8000615c:	00e78e23          	sb	a4,28(a5)
    80006160:	00e78ea3          	sb	a4,29(a5)
    80006164:	00e78f23          	sb	a4,30(a5)
    80006168:	00e78fa3          	sb	a4,31(a5)
}
    8000616c:	60e2                	ld	ra,24(sp)
    8000616e:	6442                	ld	s0,16(sp)
    80006170:	64a2                	ld	s1,8(sp)
    80006172:	6105                	addi	sp,sp,32
    80006174:	8082                	ret
    panic("could not find virtio disk");
    80006176:	00002517          	auipc	a0,0x2
    8000617a:	6fa50513          	addi	a0,a0,1786 # 80008870 <syscalls+0x360>
    8000617e:	ffffa097          	auipc	ra,0xffffa
    80006182:	3c2080e7          	jalr	962(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006186:	00002517          	auipc	a0,0x2
    8000618a:	70a50513          	addi	a0,a0,1802 # 80008890 <syscalls+0x380>
    8000618e:	ffffa097          	auipc	ra,0xffffa
    80006192:	3b2080e7          	jalr	946(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006196:	00002517          	auipc	a0,0x2
    8000619a:	71a50513          	addi	a0,a0,1818 # 800088b0 <syscalls+0x3a0>
    8000619e:	ffffa097          	auipc	ra,0xffffa
    800061a2:	3a2080e7          	jalr	930(ra) # 80000540 <panic>

00000000800061a6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061a6:	7159                	addi	sp,sp,-112
    800061a8:	f486                	sd	ra,104(sp)
    800061aa:	f0a2                	sd	s0,96(sp)
    800061ac:	eca6                	sd	s1,88(sp)
    800061ae:	e8ca                	sd	s2,80(sp)
    800061b0:	e4ce                	sd	s3,72(sp)
    800061b2:	e0d2                	sd	s4,64(sp)
    800061b4:	fc56                	sd	s5,56(sp)
    800061b6:	f85a                	sd	s6,48(sp)
    800061b8:	f45e                	sd	s7,40(sp)
    800061ba:	f062                	sd	s8,32(sp)
    800061bc:	ec66                	sd	s9,24(sp)
    800061be:	e86a                	sd	s10,16(sp)
    800061c0:	1880                	addi	s0,sp,112
    800061c2:	892a                	mv	s2,a0
    800061c4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061c6:	00c52c83          	lw	s9,12(a0)
    800061ca:	001c9c9b          	slliw	s9,s9,0x1
    800061ce:	1c82                	slli	s9,s9,0x20
    800061d0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061d4:	0001f517          	auipc	a0,0x1f
    800061d8:	f5450513          	addi	a0,a0,-172 # 80025128 <disk+0x2128>
    800061dc:	ffffb097          	auipc	ra,0xffffb
    800061e0:	a0a080e7          	jalr	-1526(ra) # 80000be6 <acquire>
  for(int i = 0; i < 3; i++){
    800061e4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061e6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800061e8:	0001db97          	auipc	s7,0x1d
    800061ec:	e18b8b93          	addi	s7,s7,-488 # 80023000 <disk>
    800061f0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800061f2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800061f4:	8a4e                	mv	s4,s3
    800061f6:	a051                	j	8000627a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800061f8:	00fb86b3          	add	a3,s7,a5
    800061fc:	96da                	add	a3,a3,s6
    800061fe:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006202:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006204:	0207c563          	bltz	a5,8000622e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006208:	2485                	addiw	s1,s1,1
    8000620a:	0711                	addi	a4,a4,4
    8000620c:	25548063          	beq	s1,s5,8000644c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006210:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006212:	0001f697          	auipc	a3,0x1f
    80006216:	e0668693          	addi	a3,a3,-506 # 80025018 <disk+0x2018>
    8000621a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000621c:	0006c583          	lbu	a1,0(a3)
    80006220:	fde1                	bnez	a1,800061f8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006222:	2785                	addiw	a5,a5,1
    80006224:	0685                	addi	a3,a3,1
    80006226:	ff879be3          	bne	a5,s8,8000621c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000622a:	57fd                	li	a5,-1
    8000622c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000622e:	02905a63          	blez	s1,80006262 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006232:	f9042503          	lw	a0,-112(s0)
    80006236:	00000097          	auipc	ra,0x0
    8000623a:	d90080e7          	jalr	-624(ra) # 80005fc6 <free_desc>
      for(int j = 0; j < i; j++)
    8000623e:	4785                	li	a5,1
    80006240:	0297d163          	bge	a5,s1,80006262 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006244:	f9442503          	lw	a0,-108(s0)
    80006248:	00000097          	auipc	ra,0x0
    8000624c:	d7e080e7          	jalr	-642(ra) # 80005fc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006250:	4789                	li	a5,2
    80006252:	0097d863          	bge	a5,s1,80006262 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006256:	f9842503          	lw	a0,-104(s0)
    8000625a:	00000097          	auipc	ra,0x0
    8000625e:	d6c080e7          	jalr	-660(ra) # 80005fc6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006262:	0001f597          	auipc	a1,0x1f
    80006266:	ec658593          	addi	a1,a1,-314 # 80025128 <disk+0x2128>
    8000626a:	0001f517          	auipc	a0,0x1f
    8000626e:	dae50513          	addi	a0,a0,-594 # 80025018 <disk+0x2018>
    80006272:	ffffc097          	auipc	ra,0xffffc
    80006276:	f7a080e7          	jalr	-134(ra) # 800021ec <sleep>
  for(int i = 0; i < 3; i++){
    8000627a:	f9040713          	addi	a4,s0,-112
    8000627e:	84ce                	mv	s1,s3
    80006280:	bf41                	j	80006210 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006282:	20058713          	addi	a4,a1,512
    80006286:	00471693          	slli	a3,a4,0x4
    8000628a:	0001d717          	auipc	a4,0x1d
    8000628e:	d7670713          	addi	a4,a4,-650 # 80023000 <disk>
    80006292:	9736                	add	a4,a4,a3
    80006294:	4685                	li	a3,1
    80006296:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000629a:	20058713          	addi	a4,a1,512
    8000629e:	00471693          	slli	a3,a4,0x4
    800062a2:	0001d717          	auipc	a4,0x1d
    800062a6:	d5e70713          	addi	a4,a4,-674 # 80023000 <disk>
    800062aa:	9736                	add	a4,a4,a3
    800062ac:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800062b0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062b4:	7679                	lui	a2,0xffffe
    800062b6:	963e                	add	a2,a2,a5
    800062b8:	0001f697          	auipc	a3,0x1f
    800062bc:	d4868693          	addi	a3,a3,-696 # 80025000 <disk+0x2000>
    800062c0:	6298                	ld	a4,0(a3)
    800062c2:	9732                	add	a4,a4,a2
    800062c4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062c6:	6298                	ld	a4,0(a3)
    800062c8:	9732                	add	a4,a4,a2
    800062ca:	4541                	li	a0,16
    800062cc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062ce:	6298                	ld	a4,0(a3)
    800062d0:	9732                	add	a4,a4,a2
    800062d2:	4505                	li	a0,1
    800062d4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800062d8:	f9442703          	lw	a4,-108(s0)
    800062dc:	6288                	ld	a0,0(a3)
    800062de:	962a                	add	a2,a2,a0
    800062e0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062e4:	0712                	slli	a4,a4,0x4
    800062e6:	6290                	ld	a2,0(a3)
    800062e8:	963a                	add	a2,a2,a4
    800062ea:	05890513          	addi	a0,s2,88
    800062ee:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800062f0:	6294                	ld	a3,0(a3)
    800062f2:	96ba                	add	a3,a3,a4
    800062f4:	40000613          	li	a2,1024
    800062f8:	c690                	sw	a2,8(a3)
  if(write)
    800062fa:	140d0063          	beqz	s10,8000643a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062fe:	0001f697          	auipc	a3,0x1f
    80006302:	d026b683          	ld	a3,-766(a3) # 80025000 <disk+0x2000>
    80006306:	96ba                	add	a3,a3,a4
    80006308:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000630c:	0001d817          	auipc	a6,0x1d
    80006310:	cf480813          	addi	a6,a6,-780 # 80023000 <disk>
    80006314:	0001f517          	auipc	a0,0x1f
    80006318:	cec50513          	addi	a0,a0,-788 # 80025000 <disk+0x2000>
    8000631c:	6114                	ld	a3,0(a0)
    8000631e:	96ba                	add	a3,a3,a4
    80006320:	00c6d603          	lhu	a2,12(a3)
    80006324:	00166613          	ori	a2,a2,1
    80006328:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000632c:	f9842683          	lw	a3,-104(s0)
    80006330:	6110                	ld	a2,0(a0)
    80006332:	9732                	add	a4,a4,a2
    80006334:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006338:	20058613          	addi	a2,a1,512
    8000633c:	0612                	slli	a2,a2,0x4
    8000633e:	9642                	add	a2,a2,a6
    80006340:	577d                	li	a4,-1
    80006342:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006346:	00469713          	slli	a4,a3,0x4
    8000634a:	6114                	ld	a3,0(a0)
    8000634c:	96ba                	add	a3,a3,a4
    8000634e:	03078793          	addi	a5,a5,48
    80006352:	97c2                	add	a5,a5,a6
    80006354:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006356:	611c                	ld	a5,0(a0)
    80006358:	97ba                	add	a5,a5,a4
    8000635a:	4685                	li	a3,1
    8000635c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000635e:	611c                	ld	a5,0(a0)
    80006360:	97ba                	add	a5,a5,a4
    80006362:	4809                	li	a6,2
    80006364:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006368:	611c                	ld	a5,0(a0)
    8000636a:	973e                	add	a4,a4,a5
    8000636c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006370:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006374:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006378:	6518                	ld	a4,8(a0)
    8000637a:	00275783          	lhu	a5,2(a4)
    8000637e:	8b9d                	andi	a5,a5,7
    80006380:	0786                	slli	a5,a5,0x1
    80006382:	97ba                	add	a5,a5,a4
    80006384:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006388:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000638c:	6518                	ld	a4,8(a0)
    8000638e:	00275783          	lhu	a5,2(a4)
    80006392:	2785                	addiw	a5,a5,1
    80006394:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006398:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000639c:	100017b7          	lui	a5,0x10001
    800063a0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063a4:	00492703          	lw	a4,4(s2)
    800063a8:	4785                	li	a5,1
    800063aa:	02f71163          	bne	a4,a5,800063cc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800063ae:	0001f997          	auipc	s3,0x1f
    800063b2:	d7a98993          	addi	s3,s3,-646 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800063b6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063b8:	85ce                	mv	a1,s3
    800063ba:	854a                	mv	a0,s2
    800063bc:	ffffc097          	auipc	ra,0xffffc
    800063c0:	e30080e7          	jalr	-464(ra) # 800021ec <sleep>
  while(b->disk == 1) {
    800063c4:	00492783          	lw	a5,4(s2)
    800063c8:	fe9788e3          	beq	a5,s1,800063b8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800063cc:	f9042903          	lw	s2,-112(s0)
    800063d0:	20090793          	addi	a5,s2,512
    800063d4:	00479713          	slli	a4,a5,0x4
    800063d8:	0001d797          	auipc	a5,0x1d
    800063dc:	c2878793          	addi	a5,a5,-984 # 80023000 <disk>
    800063e0:	97ba                	add	a5,a5,a4
    800063e2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800063e6:	0001f997          	auipc	s3,0x1f
    800063ea:	c1a98993          	addi	s3,s3,-998 # 80025000 <disk+0x2000>
    800063ee:	00491713          	slli	a4,s2,0x4
    800063f2:	0009b783          	ld	a5,0(s3)
    800063f6:	97ba                	add	a5,a5,a4
    800063f8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063fc:	854a                	mv	a0,s2
    800063fe:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006402:	00000097          	auipc	ra,0x0
    80006406:	bc4080e7          	jalr	-1084(ra) # 80005fc6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000640a:	8885                	andi	s1,s1,1
    8000640c:	f0ed                	bnez	s1,800063ee <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000640e:	0001f517          	auipc	a0,0x1f
    80006412:	d1a50513          	addi	a0,a0,-742 # 80025128 <disk+0x2128>
    80006416:	ffffb097          	auipc	ra,0xffffb
    8000641a:	884080e7          	jalr	-1916(ra) # 80000c9a <release>
}
    8000641e:	70a6                	ld	ra,104(sp)
    80006420:	7406                	ld	s0,96(sp)
    80006422:	64e6                	ld	s1,88(sp)
    80006424:	6946                	ld	s2,80(sp)
    80006426:	69a6                	ld	s3,72(sp)
    80006428:	6a06                	ld	s4,64(sp)
    8000642a:	7ae2                	ld	s5,56(sp)
    8000642c:	7b42                	ld	s6,48(sp)
    8000642e:	7ba2                	ld	s7,40(sp)
    80006430:	7c02                	ld	s8,32(sp)
    80006432:	6ce2                	ld	s9,24(sp)
    80006434:	6d42                	ld	s10,16(sp)
    80006436:	6165                	addi	sp,sp,112
    80006438:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000643a:	0001f697          	auipc	a3,0x1f
    8000643e:	bc66b683          	ld	a3,-1082(a3) # 80025000 <disk+0x2000>
    80006442:	96ba                	add	a3,a3,a4
    80006444:	4609                	li	a2,2
    80006446:	00c69623          	sh	a2,12(a3)
    8000644a:	b5c9                	j	8000630c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000644c:	f9042583          	lw	a1,-112(s0)
    80006450:	20058793          	addi	a5,a1,512
    80006454:	0792                	slli	a5,a5,0x4
    80006456:	0001d517          	auipc	a0,0x1d
    8000645a:	c5250513          	addi	a0,a0,-942 # 800230a8 <disk+0xa8>
    8000645e:	953e                	add	a0,a0,a5
  if(write)
    80006460:	e20d11e3          	bnez	s10,80006282 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006464:	20058713          	addi	a4,a1,512
    80006468:	00471693          	slli	a3,a4,0x4
    8000646c:	0001d717          	auipc	a4,0x1d
    80006470:	b9470713          	addi	a4,a4,-1132 # 80023000 <disk>
    80006474:	9736                	add	a4,a4,a3
    80006476:	0a072423          	sw	zero,168(a4)
    8000647a:	b505                	j	8000629a <virtio_disk_rw+0xf4>

000000008000647c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000647c:	1101                	addi	sp,sp,-32
    8000647e:	ec06                	sd	ra,24(sp)
    80006480:	e822                	sd	s0,16(sp)
    80006482:	e426                	sd	s1,8(sp)
    80006484:	e04a                	sd	s2,0(sp)
    80006486:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006488:	0001f517          	auipc	a0,0x1f
    8000648c:	ca050513          	addi	a0,a0,-864 # 80025128 <disk+0x2128>
    80006490:	ffffa097          	auipc	ra,0xffffa
    80006494:	756080e7          	jalr	1878(ra) # 80000be6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006498:	10001737          	lui	a4,0x10001
    8000649c:	533c                	lw	a5,96(a4)
    8000649e:	8b8d                	andi	a5,a5,3
    800064a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064a6:	0001f797          	auipc	a5,0x1f
    800064aa:	b5a78793          	addi	a5,a5,-1190 # 80025000 <disk+0x2000>
    800064ae:	6b94                	ld	a3,16(a5)
    800064b0:	0207d703          	lhu	a4,32(a5)
    800064b4:	0026d783          	lhu	a5,2(a3)
    800064b8:	06f70163          	beq	a4,a5,8000651a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064bc:	0001d917          	auipc	s2,0x1d
    800064c0:	b4490913          	addi	s2,s2,-1212 # 80023000 <disk>
    800064c4:	0001f497          	auipc	s1,0x1f
    800064c8:	b3c48493          	addi	s1,s1,-1220 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800064cc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064d0:	6898                	ld	a4,16(s1)
    800064d2:	0204d783          	lhu	a5,32(s1)
    800064d6:	8b9d                	andi	a5,a5,7
    800064d8:	078e                	slli	a5,a5,0x3
    800064da:	97ba                	add	a5,a5,a4
    800064dc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064de:	20078713          	addi	a4,a5,512
    800064e2:	0712                	slli	a4,a4,0x4
    800064e4:	974a                	add	a4,a4,s2
    800064e6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800064ea:	e731                	bnez	a4,80006536 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064ec:	20078793          	addi	a5,a5,512
    800064f0:	0792                	slli	a5,a5,0x4
    800064f2:	97ca                	add	a5,a5,s2
    800064f4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800064f6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064fa:	ffffc097          	auipc	ra,0xffffc
    800064fe:	e82080e7          	jalr	-382(ra) # 8000237c <wakeup>

    disk.used_idx += 1;
    80006502:	0204d783          	lhu	a5,32(s1)
    80006506:	2785                	addiw	a5,a5,1
    80006508:	17c2                	slli	a5,a5,0x30
    8000650a:	93c1                	srli	a5,a5,0x30
    8000650c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006510:	6898                	ld	a4,16(s1)
    80006512:	00275703          	lhu	a4,2(a4)
    80006516:	faf71be3          	bne	a4,a5,800064cc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000651a:	0001f517          	auipc	a0,0x1f
    8000651e:	c0e50513          	addi	a0,a0,-1010 # 80025128 <disk+0x2128>
    80006522:	ffffa097          	auipc	ra,0xffffa
    80006526:	778080e7          	jalr	1912(ra) # 80000c9a <release>
}
    8000652a:	60e2                	ld	ra,24(sp)
    8000652c:	6442                	ld	s0,16(sp)
    8000652e:	64a2                	ld	s1,8(sp)
    80006530:	6902                	ld	s2,0(sp)
    80006532:	6105                	addi	sp,sp,32
    80006534:	8082                	ret
      panic("virtio_disk_intr status");
    80006536:	00002517          	auipc	a0,0x2
    8000653a:	39a50513          	addi	a0,a0,922 # 800088d0 <syscalls+0x3c0>
    8000653e:	ffffa097          	auipc	ra,0xffffa
    80006542:	002080e7          	jalr	2(ra) # 80000540 <panic>
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
