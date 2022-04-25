
user/_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <pause_system_dem>:
#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"


void pause_system_dem(int interval, int pause_seconds, int loop_size) {
   0:	715d                	addi	sp,sp,-80
   2:	e486                	sd	ra,72(sp)
   4:	e0a2                	sd	s0,64(sp)
   6:	fc26                	sd	s1,56(sp)
   8:	f84a                	sd	s2,48(sp)
   a:	f44e                	sd	s3,40(sp)
   c:	f052                	sd	s4,32(sp)
   e:	ec56                	sd	s5,24(sp)
  10:	e85a                	sd	s6,16(sp)
  12:	e45e                	sd	s7,8(sp)
  14:	0880                	addi	s0,sp,80
  16:	89aa                	mv	s3,a0
  18:	8b2e                	mv	s6,a1
  1a:	8932                	mv	s2,a2
    int pid = getpid(), i = 5;
  1c:	00000097          	auipc	ra,0x0
  20:	5b4080e7          	jalr	1460(ra) # 5d0 <getpid>
  24:	8aaa                	mv	s5,a0
    while(i--)
        fork();
  26:	00000097          	auipc	ra,0x0
  2a:	522080e7          	jalr	1314(ra) # 548 <fork>
  2e:	00000097          	auipc	ra,0x0
  32:	51a080e7          	jalr	1306(ra) # 548 <fork>
  36:	00000097          	auipc	ra,0x0
  3a:	512080e7          	jalr	1298(ra) # 548 <fork>
  3e:	00000097          	auipc	ra,0x0
  42:	50a080e7          	jalr	1290(ra) # 548 <fork>
  46:	00000097          	auipc	ra,0x0
  4a:	502080e7          	jalr	1282(ra) # 548 <fork>
    const uint m = (loop_size >> 1);
    for (int i = 0; i < loop_size; i++) {
  4e:	05205663          	blez	s2,9a <pause_system_dem+0x9a>
  52:	40195a1b          	sraiw	s4,s2,0x1
  56:	4481                	li	s1,0
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
  58:	00001b97          	auipc	s7,0x1
  5c:	a30b8b93          	addi	s7,s7,-1488 # a88 <malloc+0xea>
  60:	a031                	j	6c <pause_system_dem+0x6c>
        }
        if (i == m) {
  62:	029a0663          	beq	s4,s1,8e <pause_system_dem+0x8e>
    for (int i = 0; i < loop_size; i++) {
  66:	2485                	addiw	s1,s1,1
  68:	02990963          	beq	s2,s1,9a <pause_system_dem+0x9a>
        if (i % interval == 0 && pid == getpid()) {
  6c:	0334e7bb          	remw	a5,s1,s3
  70:	fbed                	bnez	a5,62 <pause_system_dem+0x62>
  72:	00000097          	auipc	ra,0x0
  76:	55e080e7          	jalr	1374(ra) # 5d0 <getpid>
  7a:	ff5514e3          	bne	a0,s5,62 <pause_system_dem+0x62>
            printf("pause system %d/%d completed.\n", i, loop_size);
  7e:	864a                	mv	a2,s2
  80:	85a6                	mv	a1,s1
  82:	855e                	mv	a0,s7
  84:	00001097          	auipc	ra,0x1
  88:	85c080e7          	jalr	-1956(ra) # 8e0 <printf>
  8c:	bfd9                	j	62 <pause_system_dem+0x62>
            pause_system(pause_seconds);
  8e:	855a                	mv	a0,s6
  90:	00000097          	auipc	ra,0x0
  94:	560080e7          	jalr	1376(ra) # 5f0 <pause_system>
  98:	b7f9                	j	66 <pause_system_dem+0x66>
        }
    }
    printf("\n");
  9a:	00001517          	auipc	a0,0x1
  9e:	a0e50513          	addi	a0,a0,-1522 # aa8 <malloc+0x10a>
  a2:	00001097          	auipc	ra,0x1
  a6:	83e080e7          	jalr	-1986(ra) # 8e0 <printf>
}
  aa:	60a6                	ld	ra,72(sp)
  ac:	6406                	ld	s0,64(sp)
  ae:	74e2                	ld	s1,56(sp)
  b0:	7942                	ld	s2,48(sp)
  b2:	79a2                	ld	s3,40(sp)
  b4:	7a02                	ld	s4,32(sp)
  b6:	6ae2                	ld	s5,24(sp)
  b8:	6b42                	ld	s6,16(sp)
  ba:	6ba2                	ld	s7,8(sp)
  bc:	6161                	addi	sp,sp,80
  be:	8082                	ret

00000000000000c0 <kill_system_dem>:

void kill_system_dem(int interval, int loop_size) {
  c0:	7139                	addi	sp,sp,-64
  c2:	fc06                	sd	ra,56(sp)
  c4:	f822                	sd	s0,48(sp)
  c6:	f426                	sd	s1,40(sp)
  c8:	f04a                	sd	s2,32(sp)
  ca:	ec4e                	sd	s3,24(sp)
  cc:	e852                	sd	s4,16(sp)
  ce:	e456                	sd	s5,8(sp)
  d0:	e05a                	sd	s6,0(sp)
  d2:	0080                	addi	s0,sp,64
  d4:	89aa                	mv	s3,a0
  d6:	892e                	mv	s2,a1
    int pid = getpid(), i = 5;
  d8:	00000097          	auipc	ra,0x0
  dc:	4f8080e7          	jalr	1272(ra) # 5d0 <getpid>
  e0:	8aaa                	mv	s5,a0
    while(i--)
        fork();
  e2:	00000097          	auipc	ra,0x0
  e6:	466080e7          	jalr	1126(ra) # 548 <fork>
  ea:	00000097          	auipc	ra,0x0
  ee:	45e080e7          	jalr	1118(ra) # 548 <fork>
  f2:	00000097          	auipc	ra,0x0
  f6:	456080e7          	jalr	1110(ra) # 548 <fork>
  fa:	00000097          	auipc	ra,0x0
  fe:	44e080e7          	jalr	1102(ra) # 548 <fork>
 102:	00000097          	auipc	ra,0x0
 106:	446080e7          	jalr	1094(ra) # 548 <fork>
    const uint m = (loop_size >> 1);
    for (int i = 0; i < loop_size; i++) {
 10a:	05205563          	blez	s2,154 <kill_system_dem+0x94>
 10e:	40195a1b          	sraiw	s4,s2,0x1
 112:	4481                	li	s1,0
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
 114:	00001b17          	auipc	s6,0x1
 118:	99cb0b13          	addi	s6,s6,-1636 # ab0 <malloc+0x112>
 11c:	a031                	j	128 <kill_system_dem+0x68>
        }
        if (i == m) {
 11e:	029a0663          	beq	s4,s1,14a <kill_system_dem+0x8a>
    for (int i = 0; i < loop_size; i++) {
 122:	2485                	addiw	s1,s1,1
 124:	02990863          	beq	s2,s1,154 <kill_system_dem+0x94>
        if (i % interval == 0 && pid == getpid()) {
 128:	0334e7bb          	remw	a5,s1,s3
 12c:	fbed                	bnez	a5,11e <kill_system_dem+0x5e>
 12e:	00000097          	auipc	ra,0x0
 132:	4a2080e7          	jalr	1186(ra) # 5d0 <getpid>
 136:	ff5514e3          	bne	a0,s5,11e <kill_system_dem+0x5e>
            printf("kill system %d/%d completed.\n", i, loop_size);
 13a:	864a                	mv	a2,s2
 13c:	85a6                	mv	a1,s1
 13e:	855a                	mv	a0,s6
 140:	00000097          	auipc	ra,0x0
 144:	7a0080e7          	jalr	1952(ra) # 8e0 <printf>
 148:	bfd9                	j	11e <kill_system_dem+0x5e>
            kill_system();
 14a:	00000097          	auipc	ra,0x0
 14e:	4ae080e7          	jalr	1198(ra) # 5f8 <kill_system>
 152:	bfc1                	j	122 <kill_system_dem+0x62>
        }
    }
    printf("\n");
 154:	00001517          	auipc	a0,0x1
 158:	95450513          	addi	a0,a0,-1708 # aa8 <malloc+0x10a>
 15c:	00000097          	auipc	ra,0x0
 160:	784080e7          	jalr	1924(ra) # 8e0 <printf>
}
 164:	70e2                	ld	ra,56(sp)
 166:	7442                	ld	s0,48(sp)
 168:	74a2                	ld	s1,40(sp)
 16a:	7902                	ld	s2,32(sp)
 16c:	69e2                	ld	s3,24(sp)
 16e:	6a42                	ld	s4,16(sp)
 170:	6aa2                	ld	s5,8(sp)
 172:	6b02                	ld	s6,0(sp)
 174:	6121                	addi	sp,sp,64
 176:	8082                	ret

0000000000000178 <env>:
    }
    printf("\n");
}
*/

void env(int size, int interval, char* env_name) {
 178:	711d                	addi	sp,sp,-96
 17a:	ec86                	sd	ra,88(sp)
 17c:	e8a2                	sd	s0,80(sp)
 17e:	e4a6                	sd	s1,72(sp)
 180:	e0ca                	sd	s2,64(sp)
 182:	fc4e                	sd	s3,56(sp)
 184:	f852                	sd	s4,48(sp)
 186:	f456                	sd	s5,40(sp)
 188:	f05a                	sd	s6,32(sp)
 18a:	ec5e                	sd	s7,24(sp)
 18c:	e862                	sd	s8,16(sp)
 18e:	1080                	addi	s0,sp,96
 190:	8bb2                	mv	s7,a2
    int result = 1;
    int loop_size = 1000000;
    int n_forks = 2;
    int pid;
    for (int i = 0; i < n_forks; i++) {
        pid = fork();
 192:	00000097          	auipc	ra,0x0
 196:	3b6080e7          	jalr	950(ra) # 548 <fork>
 19a:	85aa                	mv	a1,a0
        printf("pid: %d,", pid);
 19c:	00001517          	auipc	a0,0x1
 1a0:	93450513          	addi	a0,a0,-1740 # ad0 <malloc+0x132>
 1a4:	00000097          	auipc	ra,0x0
 1a8:	73c080e7          	jalr	1852(ra) # 8e0 <printf>
        pid = fork();
 1ac:	00000097          	auipc	ra,0x0
 1b0:	39c080e7          	jalr	924(ra) # 548 <fork>
 1b4:	8a2a                	mv	s4,a0
        printf("pid: %d,", pid);
 1b6:	85aa                	mv	a1,a0
 1b8:	00001517          	auipc	a0,0x1
 1bc:	91850513          	addi	a0,a0,-1768 # ad0 <malloc+0x132>
 1c0:	00000097          	auipc	ra,0x0
 1c4:	720080e7          	jalr	1824(ra) # 8e0 <printf>
    }
    for (int i = 0; i < loop_size; i++) {
 1c8:	4481                	li	s1,0
        if (i % loop_size / 1 == 0) {
 1ca:	000f49b7          	lui	s3,0xf4
 1ce:	2409899b          	addiw	s3,s3,576
                    x *= i;
                }
        	} else {
                int res;
                wait(&res);
        		printf(" ");
 1d2:	00001a97          	auipc	s5,0x1
 1d6:	926a8a93          	addi	s5,s5,-1754 # af8 <malloc+0x15a>
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
 1da:	000f4937          	lui	s2,0xf4
 1de:	24090913          	addi	s2,s2,576 # f4240 <__global_pointer$+0xf2f07>
 1e2:	00001c17          	auipc	s8,0x1
 1e6:	8fec0c13          	addi	s8,s8,-1794 # ae0 <malloc+0x142>
 1ea:	00950b37          	lui	s6,0x950
 1ee:	2f9b0b13          	addi	s6,s6,761 # 9502f9 <__global_pointer$+0x94efc0>
 1f2:	a005                	j	212 <env+0x9a>
 1f4:	86ca                	mv	a3,s2
 1f6:	8626                	mv	a2,s1
 1f8:	85de                	mv	a1,s7
 1fa:	8562                	mv	a0,s8
 1fc:	00000097          	auipc	ra,0x0
 200:	6e4080e7          	jalr	1764(ra) # 8e0 <printf>
 204:	00bb1793          	slli	a5,s6,0xb
                for(long i = 0; i < 20000000000; i++){
 208:	17fd                	addi	a5,a5,-1
 20a:	fffd                	bnez	a5,208 <env+0x90>
    for (int i = 0; i < loop_size; i++) {
 20c:	2485                	addiw	s1,s1,1
 20e:	03248363          	beq	s1,s2,234 <env+0xbc>
        if (i % loop_size / 1 == 0) {
 212:	0334e7bb          	remw	a5,s1,s3
 216:	fbfd                	bnez	a5,20c <env+0x94>
        	if (pid == 0) {
 218:	fc0a0ee3          	beqz	s4,1f4 <env+0x7c>
                wait(&res);
 21c:	fac40513          	addi	a0,s0,-84
 220:	00000097          	auipc	ra,0x0
 224:	338080e7          	jalr	824(ra) # 558 <wait>
        		printf(" ");
 228:	8556                	mv	a0,s5
 22a:	00000097          	auipc	ra,0x0
 22e:	6b6080e7          	jalr	1718(ra) # 8e0 <printf>
 232:	bfe9                	j	20c <env+0x94>
        }
        if (i % interval == 0) {
            result = result * size;
        }
    }
    printf("\n");
 234:	00001517          	auipc	a0,0x1
 238:	87450513          	addi	a0,a0,-1932 # aa8 <malloc+0x10a>
 23c:	00000097          	auipc	ra,0x0
 240:	6a4080e7          	jalr	1700(ra) # 8e0 <printf>
}
 244:	60e6                	ld	ra,88(sp)
 246:	6446                	ld	s0,80(sp)
 248:	64a6                	ld	s1,72(sp)
 24a:	6906                	ld	s2,64(sp)
 24c:	79e2                	ld	s3,56(sp)
 24e:	7a42                	ld	s4,48(sp)
 250:	7aa2                	ld	s5,40(sp)
 252:	7b02                	ld	s6,32(sp)
 254:	6be2                	ld	s7,24(sp)
 256:	6c42                	ld	s8,16(sp)
 258:	6125                	addi	sp,sp,96
 25a:	8082                	ret

000000000000025c <env_large>:

void env_large() {
 25c:	1141                	addi	sp,sp,-16
 25e:	e406                	sd	ra,8(sp)
 260:	e022                	sd	s0,0(sp)
 262:	0800                	addi	s0,sp,16
    env(1000000, 1000000, "env_large");
 264:	00001617          	auipc	a2,0x1
 268:	89c60613          	addi	a2,a2,-1892 # b00 <malloc+0x162>
 26c:	000f45b7          	lui	a1,0xf4
 270:	24058593          	addi	a1,a1,576 # f4240 <__global_pointer$+0xf2f07>
 274:	852e                	mv	a0,a1
 276:	00000097          	auipc	ra,0x0
 27a:	f02080e7          	jalr	-254(ra) # 178 <env>
}
 27e:	60a2                	ld	ra,8(sp)
 280:	6402                	ld	s0,0(sp)
 282:	0141                	addi	sp,sp,16
 284:	8082                	ret

0000000000000286 <env_freq>:

void env_freq() {
 286:	1141                	addi	sp,sp,-16
 288:	e406                	sd	ra,8(sp)
 28a:	e022                	sd	s0,0(sp)
 28c:	0800                	addi	s0,sp,16
    env(10, 10, "env_freq");
 28e:	00001617          	auipc	a2,0x1
 292:	88260613          	addi	a2,a2,-1918 # b10 <malloc+0x172>
 296:	45a9                	li	a1,10
 298:	4529                	li	a0,10
 29a:	00000097          	auipc	ra,0x0
 29e:	ede080e7          	jalr	-290(ra) # 178 <env>
}
 2a2:	60a2                	ld	ra,8(sp)
 2a4:	6402                	ld	s0,0(sp)
 2a6:	0141                	addi	sp,sp,16
 2a8:	8082                	ret

00000000000002aa <main>:

int
main(int argc, char *argv[])
{
 2aa:	1141                	addi	sp,sp,-16
 2ac:	e406                	sd	ra,8(sp)
 2ae:	e022                	sd	s0,0(sp)
 2b0:	0800                	addi	s0,sp,16
    //set_economic_mode_dem(10, 100);
    pause_system_dem(10, 10, 100);
 2b2:	06400613          	li	a2,100
 2b6:	45a9                	li	a1,10
 2b8:	4529                	li	a0,10
 2ba:	00000097          	auipc	ra,0x0
 2be:	d46080e7          	jalr	-698(ra) # 0 <pause_system_dem>
    kill_system_dem(10, 100);
 2c2:	06400593          	li	a1,100
 2c6:	4529                	li	a0,10
 2c8:	00000097          	auipc	ra,0x0
 2cc:	df8080e7          	jalr	-520(ra) # c0 <kill_system_dem>
    // env_large();
    // print_stats();
    // printf("******************************\n");
    // env_freq();
    // print_stats();
    exit(0);
 2d0:	4501                	li	a0,0
 2d2:	00000097          	auipc	ra,0x0
 2d6:	27e080e7          	jalr	638(ra) # 550 <exit>

00000000000002da <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 2da:	1141                	addi	sp,sp,-16
 2dc:	e422                	sd	s0,8(sp)
 2de:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2e0:	87aa                	mv	a5,a0
 2e2:	0585                	addi	a1,a1,1
 2e4:	0785                	addi	a5,a5,1
 2e6:	fff5c703          	lbu	a4,-1(a1)
 2ea:	fee78fa3          	sb	a4,-1(a5)
 2ee:	fb75                	bnez	a4,2e2 <strcpy+0x8>
    ;
  return os;
}
 2f0:	6422                	ld	s0,8(sp)
 2f2:	0141                	addi	sp,sp,16
 2f4:	8082                	ret

00000000000002f6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2f6:	1141                	addi	sp,sp,-16
 2f8:	e422                	sd	s0,8(sp)
 2fa:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2fc:	00054783          	lbu	a5,0(a0)
 300:	cb91                	beqz	a5,314 <strcmp+0x1e>
 302:	0005c703          	lbu	a4,0(a1)
 306:	00f71763          	bne	a4,a5,314 <strcmp+0x1e>
    p++, q++;
 30a:	0505                	addi	a0,a0,1
 30c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 30e:	00054783          	lbu	a5,0(a0)
 312:	fbe5                	bnez	a5,302 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 314:	0005c503          	lbu	a0,0(a1)
}
 318:	40a7853b          	subw	a0,a5,a0
 31c:	6422                	ld	s0,8(sp)
 31e:	0141                	addi	sp,sp,16
 320:	8082                	ret

0000000000000322 <strlen>:

uint
strlen(const char *s)
{
 322:	1141                	addi	sp,sp,-16
 324:	e422                	sd	s0,8(sp)
 326:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 328:	00054783          	lbu	a5,0(a0)
 32c:	cf91                	beqz	a5,348 <strlen+0x26>
 32e:	0505                	addi	a0,a0,1
 330:	87aa                	mv	a5,a0
 332:	4685                	li	a3,1
 334:	9e89                	subw	a3,a3,a0
 336:	00f6853b          	addw	a0,a3,a5
 33a:	0785                	addi	a5,a5,1
 33c:	fff7c703          	lbu	a4,-1(a5)
 340:	fb7d                	bnez	a4,336 <strlen+0x14>
    ;
  return n;
}
 342:	6422                	ld	s0,8(sp)
 344:	0141                	addi	sp,sp,16
 346:	8082                	ret
  for(n = 0; s[n]; n++)
 348:	4501                	li	a0,0
 34a:	bfe5                	j	342 <strlen+0x20>

000000000000034c <memset>:

void*
memset(void *dst, int c, uint n)
{
 34c:	1141                	addi	sp,sp,-16
 34e:	e422                	sd	s0,8(sp)
 350:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 352:	ce09                	beqz	a2,36c <memset+0x20>
 354:	87aa                	mv	a5,a0
 356:	fff6071b          	addiw	a4,a2,-1
 35a:	1702                	slli	a4,a4,0x20
 35c:	9301                	srli	a4,a4,0x20
 35e:	0705                	addi	a4,a4,1
 360:	972a                	add	a4,a4,a0
    cdst[i] = c;
 362:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 366:	0785                	addi	a5,a5,1
 368:	fee79de3          	bne	a5,a4,362 <memset+0x16>
  }
  return dst;
}
 36c:	6422                	ld	s0,8(sp)
 36e:	0141                	addi	sp,sp,16
 370:	8082                	ret

0000000000000372 <strchr>:

char*
strchr(const char *s, char c)
{
 372:	1141                	addi	sp,sp,-16
 374:	e422                	sd	s0,8(sp)
 376:	0800                	addi	s0,sp,16
  for(; *s; s++)
 378:	00054783          	lbu	a5,0(a0)
 37c:	cb99                	beqz	a5,392 <strchr+0x20>
    if(*s == c)
 37e:	00f58763          	beq	a1,a5,38c <strchr+0x1a>
  for(; *s; s++)
 382:	0505                	addi	a0,a0,1
 384:	00054783          	lbu	a5,0(a0)
 388:	fbfd                	bnez	a5,37e <strchr+0xc>
      return (char*)s;
  return 0;
 38a:	4501                	li	a0,0
}
 38c:	6422                	ld	s0,8(sp)
 38e:	0141                	addi	sp,sp,16
 390:	8082                	ret
  return 0;
 392:	4501                	li	a0,0
 394:	bfe5                	j	38c <strchr+0x1a>

0000000000000396 <gets>:

char*
gets(char *buf, int max)
{
 396:	711d                	addi	sp,sp,-96
 398:	ec86                	sd	ra,88(sp)
 39a:	e8a2                	sd	s0,80(sp)
 39c:	e4a6                	sd	s1,72(sp)
 39e:	e0ca                	sd	s2,64(sp)
 3a0:	fc4e                	sd	s3,56(sp)
 3a2:	f852                	sd	s4,48(sp)
 3a4:	f456                	sd	s5,40(sp)
 3a6:	f05a                	sd	s6,32(sp)
 3a8:	ec5e                	sd	s7,24(sp)
 3aa:	1080                	addi	s0,sp,96
 3ac:	8baa                	mv	s7,a0
 3ae:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 3b0:	892a                	mv	s2,a0
 3b2:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 3b4:	4aa9                	li	s5,10
 3b6:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 3b8:	89a6                	mv	s3,s1
 3ba:	2485                	addiw	s1,s1,1
 3bc:	0344d863          	bge	s1,s4,3ec <gets+0x56>
    cc = read(0, &c, 1);
 3c0:	4605                	li	a2,1
 3c2:	faf40593          	addi	a1,s0,-81
 3c6:	4501                	li	a0,0
 3c8:	00000097          	auipc	ra,0x0
 3cc:	1a0080e7          	jalr	416(ra) # 568 <read>
    if(cc < 1)
 3d0:	00a05e63          	blez	a0,3ec <gets+0x56>
    buf[i++] = c;
 3d4:	faf44783          	lbu	a5,-81(s0)
 3d8:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3dc:	01578763          	beq	a5,s5,3ea <gets+0x54>
 3e0:	0905                	addi	s2,s2,1
 3e2:	fd679be3          	bne	a5,s6,3b8 <gets+0x22>
  for(i=0; i+1 < max; ){
 3e6:	89a6                	mv	s3,s1
 3e8:	a011                	j	3ec <gets+0x56>
 3ea:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3ec:	99de                	add	s3,s3,s7
 3ee:	00098023          	sb	zero,0(s3) # f4000 <__global_pointer$+0xf2cc7>
  return buf;
}
 3f2:	855e                	mv	a0,s7
 3f4:	60e6                	ld	ra,88(sp)
 3f6:	6446                	ld	s0,80(sp)
 3f8:	64a6                	ld	s1,72(sp)
 3fa:	6906                	ld	s2,64(sp)
 3fc:	79e2                	ld	s3,56(sp)
 3fe:	7a42                	ld	s4,48(sp)
 400:	7aa2                	ld	s5,40(sp)
 402:	7b02                	ld	s6,32(sp)
 404:	6be2                	ld	s7,24(sp)
 406:	6125                	addi	sp,sp,96
 408:	8082                	ret

000000000000040a <stat>:

int
stat(const char *n, struct stat *st)
{
 40a:	1101                	addi	sp,sp,-32
 40c:	ec06                	sd	ra,24(sp)
 40e:	e822                	sd	s0,16(sp)
 410:	e426                	sd	s1,8(sp)
 412:	e04a                	sd	s2,0(sp)
 414:	1000                	addi	s0,sp,32
 416:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 418:	4581                	li	a1,0
 41a:	00000097          	auipc	ra,0x0
 41e:	176080e7          	jalr	374(ra) # 590 <open>
  if(fd < 0)
 422:	02054563          	bltz	a0,44c <stat+0x42>
 426:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 428:	85ca                	mv	a1,s2
 42a:	00000097          	auipc	ra,0x0
 42e:	17e080e7          	jalr	382(ra) # 5a8 <fstat>
 432:	892a                	mv	s2,a0
  close(fd);
 434:	8526                	mv	a0,s1
 436:	00000097          	auipc	ra,0x0
 43a:	142080e7          	jalr	322(ra) # 578 <close>
  return r;
}
 43e:	854a                	mv	a0,s2
 440:	60e2                	ld	ra,24(sp)
 442:	6442                	ld	s0,16(sp)
 444:	64a2                	ld	s1,8(sp)
 446:	6902                	ld	s2,0(sp)
 448:	6105                	addi	sp,sp,32
 44a:	8082                	ret
    return -1;
 44c:	597d                	li	s2,-1
 44e:	bfc5                	j	43e <stat+0x34>

0000000000000450 <atoi>:

int
atoi(const char *s)
{
 450:	1141                	addi	sp,sp,-16
 452:	e422                	sd	s0,8(sp)
 454:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 456:	00054603          	lbu	a2,0(a0)
 45a:	fd06079b          	addiw	a5,a2,-48
 45e:	0ff7f793          	andi	a5,a5,255
 462:	4725                	li	a4,9
 464:	02f76963          	bltu	a4,a5,496 <atoi+0x46>
 468:	86aa                	mv	a3,a0
  n = 0;
 46a:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 46c:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 46e:	0685                	addi	a3,a3,1
 470:	0025179b          	slliw	a5,a0,0x2
 474:	9fa9                	addw	a5,a5,a0
 476:	0017979b          	slliw	a5,a5,0x1
 47a:	9fb1                	addw	a5,a5,a2
 47c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 480:	0006c603          	lbu	a2,0(a3)
 484:	fd06071b          	addiw	a4,a2,-48
 488:	0ff77713          	andi	a4,a4,255
 48c:	fee5f1e3          	bgeu	a1,a4,46e <atoi+0x1e>
  return n;
}
 490:	6422                	ld	s0,8(sp)
 492:	0141                	addi	sp,sp,16
 494:	8082                	ret
  n = 0;
 496:	4501                	li	a0,0
 498:	bfe5                	j	490 <atoi+0x40>

000000000000049a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 49a:	1141                	addi	sp,sp,-16
 49c:	e422                	sd	s0,8(sp)
 49e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 4a0:	02b57663          	bgeu	a0,a1,4cc <memmove+0x32>
    while(n-- > 0)
 4a4:	02c05163          	blez	a2,4c6 <memmove+0x2c>
 4a8:	fff6079b          	addiw	a5,a2,-1
 4ac:	1782                	slli	a5,a5,0x20
 4ae:	9381                	srli	a5,a5,0x20
 4b0:	0785                	addi	a5,a5,1
 4b2:	97aa                	add	a5,a5,a0
  dst = vdst;
 4b4:	872a                	mv	a4,a0
      *dst++ = *src++;
 4b6:	0585                	addi	a1,a1,1
 4b8:	0705                	addi	a4,a4,1
 4ba:	fff5c683          	lbu	a3,-1(a1)
 4be:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 4c2:	fee79ae3          	bne	a5,a4,4b6 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 4c6:	6422                	ld	s0,8(sp)
 4c8:	0141                	addi	sp,sp,16
 4ca:	8082                	ret
    dst += n;
 4cc:	00c50733          	add	a4,a0,a2
    src += n;
 4d0:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 4d2:	fec05ae3          	blez	a2,4c6 <memmove+0x2c>
 4d6:	fff6079b          	addiw	a5,a2,-1
 4da:	1782                	slli	a5,a5,0x20
 4dc:	9381                	srli	a5,a5,0x20
 4de:	fff7c793          	not	a5,a5
 4e2:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4e4:	15fd                	addi	a1,a1,-1
 4e6:	177d                	addi	a4,a4,-1
 4e8:	0005c683          	lbu	a3,0(a1)
 4ec:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4f0:	fee79ae3          	bne	a5,a4,4e4 <memmove+0x4a>
 4f4:	bfc9                	j	4c6 <memmove+0x2c>

00000000000004f6 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4f6:	1141                	addi	sp,sp,-16
 4f8:	e422                	sd	s0,8(sp)
 4fa:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4fc:	ca05                	beqz	a2,52c <memcmp+0x36>
 4fe:	fff6069b          	addiw	a3,a2,-1
 502:	1682                	slli	a3,a3,0x20
 504:	9281                	srli	a3,a3,0x20
 506:	0685                	addi	a3,a3,1
 508:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 50a:	00054783          	lbu	a5,0(a0)
 50e:	0005c703          	lbu	a4,0(a1)
 512:	00e79863          	bne	a5,a4,522 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 516:	0505                	addi	a0,a0,1
    p2++;
 518:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 51a:	fed518e3          	bne	a0,a3,50a <memcmp+0x14>
  }
  return 0;
 51e:	4501                	li	a0,0
 520:	a019                	j	526 <memcmp+0x30>
      return *p1 - *p2;
 522:	40e7853b          	subw	a0,a5,a4
}
 526:	6422                	ld	s0,8(sp)
 528:	0141                	addi	sp,sp,16
 52a:	8082                	ret
  return 0;
 52c:	4501                	li	a0,0
 52e:	bfe5                	j	526 <memcmp+0x30>

0000000000000530 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 530:	1141                	addi	sp,sp,-16
 532:	e406                	sd	ra,8(sp)
 534:	e022                	sd	s0,0(sp)
 536:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 538:	00000097          	auipc	ra,0x0
 53c:	f62080e7          	jalr	-158(ra) # 49a <memmove>
}
 540:	60a2                	ld	ra,8(sp)
 542:	6402                	ld	s0,0(sp)
 544:	0141                	addi	sp,sp,16
 546:	8082                	ret

0000000000000548 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 548:	4885                	li	a7,1
 ecall
 54a:	00000073          	ecall
 ret
 54e:	8082                	ret

0000000000000550 <exit>:
.global exit
exit:
 li a7, SYS_exit
 550:	4889                	li	a7,2
 ecall
 552:	00000073          	ecall
 ret
 556:	8082                	ret

0000000000000558 <wait>:
.global wait
wait:
 li a7, SYS_wait
 558:	488d                	li	a7,3
 ecall
 55a:	00000073          	ecall
 ret
 55e:	8082                	ret

0000000000000560 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 560:	4891                	li	a7,4
 ecall
 562:	00000073          	ecall
 ret
 566:	8082                	ret

0000000000000568 <read>:
.global read
read:
 li a7, SYS_read
 568:	4895                	li	a7,5
 ecall
 56a:	00000073          	ecall
 ret
 56e:	8082                	ret

0000000000000570 <write>:
.global write
write:
 li a7, SYS_write
 570:	48c1                	li	a7,16
 ecall
 572:	00000073          	ecall
 ret
 576:	8082                	ret

0000000000000578 <close>:
.global close
close:
 li a7, SYS_close
 578:	48d5                	li	a7,21
 ecall
 57a:	00000073          	ecall
 ret
 57e:	8082                	ret

0000000000000580 <kill>:
.global kill
kill:
 li a7, SYS_kill
 580:	4899                	li	a7,6
 ecall
 582:	00000073          	ecall
 ret
 586:	8082                	ret

0000000000000588 <exec>:
.global exec
exec:
 li a7, SYS_exec
 588:	489d                	li	a7,7
 ecall
 58a:	00000073          	ecall
 ret
 58e:	8082                	ret

0000000000000590 <open>:
.global open
open:
 li a7, SYS_open
 590:	48bd                	li	a7,15
 ecall
 592:	00000073          	ecall
 ret
 596:	8082                	ret

0000000000000598 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 598:	48c5                	li	a7,17
 ecall
 59a:	00000073          	ecall
 ret
 59e:	8082                	ret

00000000000005a0 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 5a0:	48c9                	li	a7,18
 ecall
 5a2:	00000073          	ecall
 ret
 5a6:	8082                	ret

00000000000005a8 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 5a8:	48a1                	li	a7,8
 ecall
 5aa:	00000073          	ecall
 ret
 5ae:	8082                	ret

00000000000005b0 <link>:
.global link
link:
 li a7, SYS_link
 5b0:	48cd                	li	a7,19
 ecall
 5b2:	00000073          	ecall
 ret
 5b6:	8082                	ret

00000000000005b8 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 5b8:	48d1                	li	a7,20
 ecall
 5ba:	00000073          	ecall
 ret
 5be:	8082                	ret

00000000000005c0 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 5c0:	48a5                	li	a7,9
 ecall
 5c2:	00000073          	ecall
 ret
 5c6:	8082                	ret

00000000000005c8 <dup>:
.global dup
dup:
 li a7, SYS_dup
 5c8:	48a9                	li	a7,10
 ecall
 5ca:	00000073          	ecall
 ret
 5ce:	8082                	ret

00000000000005d0 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 5d0:	48ad                	li	a7,11
 ecall
 5d2:	00000073          	ecall
 ret
 5d6:	8082                	ret

00000000000005d8 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5d8:	48b1                	li	a7,12
 ecall
 5da:	00000073          	ecall
 ret
 5de:	8082                	ret

00000000000005e0 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5e0:	48b5                	li	a7,13
 ecall
 5e2:	00000073          	ecall
 ret
 5e6:	8082                	ret

00000000000005e8 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5e8:	48b9                	li	a7,14
 ecall
 5ea:	00000073          	ecall
 ret
 5ee:	8082                	ret

00000000000005f0 <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 5f0:	48d9                	li	a7,22
 ecall
 5f2:	00000073          	ecall
 ret
 5f6:	8082                	ret

00000000000005f8 <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 5f8:	48dd                	li	a7,23
 ecall
 5fa:	00000073          	ecall
 ret
 5fe:	8082                	ret

0000000000000600 <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 600:	48e1                	li	a7,24
 ecall
 602:	00000073          	ecall
 ret
 606:	8082                	ret

0000000000000608 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 608:	1101                	addi	sp,sp,-32
 60a:	ec06                	sd	ra,24(sp)
 60c:	e822                	sd	s0,16(sp)
 60e:	1000                	addi	s0,sp,32
 610:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 614:	4605                	li	a2,1
 616:	fef40593          	addi	a1,s0,-17
 61a:	00000097          	auipc	ra,0x0
 61e:	f56080e7          	jalr	-170(ra) # 570 <write>
}
 622:	60e2                	ld	ra,24(sp)
 624:	6442                	ld	s0,16(sp)
 626:	6105                	addi	sp,sp,32
 628:	8082                	ret

000000000000062a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 62a:	7139                	addi	sp,sp,-64
 62c:	fc06                	sd	ra,56(sp)
 62e:	f822                	sd	s0,48(sp)
 630:	f426                	sd	s1,40(sp)
 632:	f04a                	sd	s2,32(sp)
 634:	ec4e                	sd	s3,24(sp)
 636:	0080                	addi	s0,sp,64
 638:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 63a:	c299                	beqz	a3,640 <printint+0x16>
 63c:	0805c863          	bltz	a1,6cc <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 640:	2581                	sext.w	a1,a1
  neg = 0;
 642:	4881                	li	a7,0
 644:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 648:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 64a:	2601                	sext.w	a2,a2
 64c:	00000517          	auipc	a0,0x0
 650:	4dc50513          	addi	a0,a0,1244 # b28 <digits>
 654:	883a                	mv	a6,a4
 656:	2705                	addiw	a4,a4,1
 658:	02c5f7bb          	remuw	a5,a1,a2
 65c:	1782                	slli	a5,a5,0x20
 65e:	9381                	srli	a5,a5,0x20
 660:	97aa                	add	a5,a5,a0
 662:	0007c783          	lbu	a5,0(a5)
 666:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 66a:	0005879b          	sext.w	a5,a1
 66e:	02c5d5bb          	divuw	a1,a1,a2
 672:	0685                	addi	a3,a3,1
 674:	fec7f0e3          	bgeu	a5,a2,654 <printint+0x2a>
  if(neg)
 678:	00088b63          	beqz	a7,68e <printint+0x64>
    buf[i++] = '-';
 67c:	fd040793          	addi	a5,s0,-48
 680:	973e                	add	a4,a4,a5
 682:	02d00793          	li	a5,45
 686:	fef70823          	sb	a5,-16(a4)
 68a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 68e:	02e05863          	blez	a4,6be <printint+0x94>
 692:	fc040793          	addi	a5,s0,-64
 696:	00e78933          	add	s2,a5,a4
 69a:	fff78993          	addi	s3,a5,-1
 69e:	99ba                	add	s3,s3,a4
 6a0:	377d                	addiw	a4,a4,-1
 6a2:	1702                	slli	a4,a4,0x20
 6a4:	9301                	srli	a4,a4,0x20
 6a6:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 6aa:	fff94583          	lbu	a1,-1(s2)
 6ae:	8526                	mv	a0,s1
 6b0:	00000097          	auipc	ra,0x0
 6b4:	f58080e7          	jalr	-168(ra) # 608 <putc>
  while(--i >= 0)
 6b8:	197d                	addi	s2,s2,-1
 6ba:	ff3918e3          	bne	s2,s3,6aa <printint+0x80>
}
 6be:	70e2                	ld	ra,56(sp)
 6c0:	7442                	ld	s0,48(sp)
 6c2:	74a2                	ld	s1,40(sp)
 6c4:	7902                	ld	s2,32(sp)
 6c6:	69e2                	ld	s3,24(sp)
 6c8:	6121                	addi	sp,sp,64
 6ca:	8082                	ret
    x = -xx;
 6cc:	40b005bb          	negw	a1,a1
    neg = 1;
 6d0:	4885                	li	a7,1
    x = -xx;
 6d2:	bf8d                	j	644 <printint+0x1a>

00000000000006d4 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6d4:	7119                	addi	sp,sp,-128
 6d6:	fc86                	sd	ra,120(sp)
 6d8:	f8a2                	sd	s0,112(sp)
 6da:	f4a6                	sd	s1,104(sp)
 6dc:	f0ca                	sd	s2,96(sp)
 6de:	ecce                	sd	s3,88(sp)
 6e0:	e8d2                	sd	s4,80(sp)
 6e2:	e4d6                	sd	s5,72(sp)
 6e4:	e0da                	sd	s6,64(sp)
 6e6:	fc5e                	sd	s7,56(sp)
 6e8:	f862                	sd	s8,48(sp)
 6ea:	f466                	sd	s9,40(sp)
 6ec:	f06a                	sd	s10,32(sp)
 6ee:	ec6e                	sd	s11,24(sp)
 6f0:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6f2:	0005c903          	lbu	s2,0(a1)
 6f6:	18090f63          	beqz	s2,894 <vprintf+0x1c0>
 6fa:	8aaa                	mv	s5,a0
 6fc:	8b32                	mv	s6,a2
 6fe:	00158493          	addi	s1,a1,1
  state = 0;
 702:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 704:	02500a13          	li	s4,37
      if(c == 'd'){
 708:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 70c:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 710:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 714:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 718:	00000b97          	auipc	s7,0x0
 71c:	410b8b93          	addi	s7,s7,1040 # b28 <digits>
 720:	a839                	j	73e <vprintf+0x6a>
        putc(fd, c);
 722:	85ca                	mv	a1,s2
 724:	8556                	mv	a0,s5
 726:	00000097          	auipc	ra,0x0
 72a:	ee2080e7          	jalr	-286(ra) # 608 <putc>
 72e:	a019                	j	734 <vprintf+0x60>
    } else if(state == '%'){
 730:	01498f63          	beq	s3,s4,74e <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 734:	0485                	addi	s1,s1,1
 736:	fff4c903          	lbu	s2,-1(s1)
 73a:	14090d63          	beqz	s2,894 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 73e:	0009079b          	sext.w	a5,s2
    if(state == 0){
 742:	fe0997e3          	bnez	s3,730 <vprintf+0x5c>
      if(c == '%'){
 746:	fd479ee3          	bne	a5,s4,722 <vprintf+0x4e>
        state = '%';
 74a:	89be                	mv	s3,a5
 74c:	b7e5                	j	734 <vprintf+0x60>
      if(c == 'd'){
 74e:	05878063          	beq	a5,s8,78e <vprintf+0xba>
      } else if(c == 'l') {
 752:	05978c63          	beq	a5,s9,7aa <vprintf+0xd6>
      } else if(c == 'x') {
 756:	07a78863          	beq	a5,s10,7c6 <vprintf+0xf2>
      } else if(c == 'p') {
 75a:	09b78463          	beq	a5,s11,7e2 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 75e:	07300713          	li	a4,115
 762:	0ce78663          	beq	a5,a4,82e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 766:	06300713          	li	a4,99
 76a:	0ee78e63          	beq	a5,a4,866 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 76e:	11478863          	beq	a5,s4,87e <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 772:	85d2                	mv	a1,s4
 774:	8556                	mv	a0,s5
 776:	00000097          	auipc	ra,0x0
 77a:	e92080e7          	jalr	-366(ra) # 608 <putc>
        putc(fd, c);
 77e:	85ca                	mv	a1,s2
 780:	8556                	mv	a0,s5
 782:	00000097          	auipc	ra,0x0
 786:	e86080e7          	jalr	-378(ra) # 608 <putc>
      }
      state = 0;
 78a:	4981                	li	s3,0
 78c:	b765                	j	734 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 78e:	008b0913          	addi	s2,s6,8
 792:	4685                	li	a3,1
 794:	4629                	li	a2,10
 796:	000b2583          	lw	a1,0(s6)
 79a:	8556                	mv	a0,s5
 79c:	00000097          	auipc	ra,0x0
 7a0:	e8e080e7          	jalr	-370(ra) # 62a <printint>
 7a4:	8b4a                	mv	s6,s2
      state = 0;
 7a6:	4981                	li	s3,0
 7a8:	b771                	j	734 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 7aa:	008b0913          	addi	s2,s6,8
 7ae:	4681                	li	a3,0
 7b0:	4629                	li	a2,10
 7b2:	000b2583          	lw	a1,0(s6)
 7b6:	8556                	mv	a0,s5
 7b8:	00000097          	auipc	ra,0x0
 7bc:	e72080e7          	jalr	-398(ra) # 62a <printint>
 7c0:	8b4a                	mv	s6,s2
      state = 0;
 7c2:	4981                	li	s3,0
 7c4:	bf85                	j	734 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7c6:	008b0913          	addi	s2,s6,8
 7ca:	4681                	li	a3,0
 7cc:	4641                	li	a2,16
 7ce:	000b2583          	lw	a1,0(s6)
 7d2:	8556                	mv	a0,s5
 7d4:	00000097          	auipc	ra,0x0
 7d8:	e56080e7          	jalr	-426(ra) # 62a <printint>
 7dc:	8b4a                	mv	s6,s2
      state = 0;
 7de:	4981                	li	s3,0
 7e0:	bf91                	j	734 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7e2:	008b0793          	addi	a5,s6,8
 7e6:	f8f43423          	sd	a5,-120(s0)
 7ea:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7ee:	03000593          	li	a1,48
 7f2:	8556                	mv	a0,s5
 7f4:	00000097          	auipc	ra,0x0
 7f8:	e14080e7          	jalr	-492(ra) # 608 <putc>
  putc(fd, 'x');
 7fc:	85ea                	mv	a1,s10
 7fe:	8556                	mv	a0,s5
 800:	00000097          	auipc	ra,0x0
 804:	e08080e7          	jalr	-504(ra) # 608 <putc>
 808:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 80a:	03c9d793          	srli	a5,s3,0x3c
 80e:	97de                	add	a5,a5,s7
 810:	0007c583          	lbu	a1,0(a5)
 814:	8556                	mv	a0,s5
 816:	00000097          	auipc	ra,0x0
 81a:	df2080e7          	jalr	-526(ra) # 608 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 81e:	0992                	slli	s3,s3,0x4
 820:	397d                	addiw	s2,s2,-1
 822:	fe0914e3          	bnez	s2,80a <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 826:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 82a:	4981                	li	s3,0
 82c:	b721                	j	734 <vprintf+0x60>
        s = va_arg(ap, char*);
 82e:	008b0993          	addi	s3,s6,8
 832:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 836:	02090163          	beqz	s2,858 <vprintf+0x184>
        while(*s != 0){
 83a:	00094583          	lbu	a1,0(s2)
 83e:	c9a1                	beqz	a1,88e <vprintf+0x1ba>
          putc(fd, *s);
 840:	8556                	mv	a0,s5
 842:	00000097          	auipc	ra,0x0
 846:	dc6080e7          	jalr	-570(ra) # 608 <putc>
          s++;
 84a:	0905                	addi	s2,s2,1
        while(*s != 0){
 84c:	00094583          	lbu	a1,0(s2)
 850:	f9e5                	bnez	a1,840 <vprintf+0x16c>
        s = va_arg(ap, char*);
 852:	8b4e                	mv	s6,s3
      state = 0;
 854:	4981                	li	s3,0
 856:	bdf9                	j	734 <vprintf+0x60>
          s = "(null)";
 858:	00000917          	auipc	s2,0x0
 85c:	2c890913          	addi	s2,s2,712 # b20 <malloc+0x182>
        while(*s != 0){
 860:	02800593          	li	a1,40
 864:	bff1                	j	840 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 866:	008b0913          	addi	s2,s6,8
 86a:	000b4583          	lbu	a1,0(s6)
 86e:	8556                	mv	a0,s5
 870:	00000097          	auipc	ra,0x0
 874:	d98080e7          	jalr	-616(ra) # 608 <putc>
 878:	8b4a                	mv	s6,s2
      state = 0;
 87a:	4981                	li	s3,0
 87c:	bd65                	j	734 <vprintf+0x60>
        putc(fd, c);
 87e:	85d2                	mv	a1,s4
 880:	8556                	mv	a0,s5
 882:	00000097          	auipc	ra,0x0
 886:	d86080e7          	jalr	-634(ra) # 608 <putc>
      state = 0;
 88a:	4981                	li	s3,0
 88c:	b565                	j	734 <vprintf+0x60>
        s = va_arg(ap, char*);
 88e:	8b4e                	mv	s6,s3
      state = 0;
 890:	4981                	li	s3,0
 892:	b54d                	j	734 <vprintf+0x60>
    }
  }
}
 894:	70e6                	ld	ra,120(sp)
 896:	7446                	ld	s0,112(sp)
 898:	74a6                	ld	s1,104(sp)
 89a:	7906                	ld	s2,96(sp)
 89c:	69e6                	ld	s3,88(sp)
 89e:	6a46                	ld	s4,80(sp)
 8a0:	6aa6                	ld	s5,72(sp)
 8a2:	6b06                	ld	s6,64(sp)
 8a4:	7be2                	ld	s7,56(sp)
 8a6:	7c42                	ld	s8,48(sp)
 8a8:	7ca2                	ld	s9,40(sp)
 8aa:	7d02                	ld	s10,32(sp)
 8ac:	6de2                	ld	s11,24(sp)
 8ae:	6109                	addi	sp,sp,128
 8b0:	8082                	ret

00000000000008b2 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 8b2:	715d                	addi	sp,sp,-80
 8b4:	ec06                	sd	ra,24(sp)
 8b6:	e822                	sd	s0,16(sp)
 8b8:	1000                	addi	s0,sp,32
 8ba:	e010                	sd	a2,0(s0)
 8bc:	e414                	sd	a3,8(s0)
 8be:	e818                	sd	a4,16(s0)
 8c0:	ec1c                	sd	a5,24(s0)
 8c2:	03043023          	sd	a6,32(s0)
 8c6:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8ca:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8ce:	8622                	mv	a2,s0
 8d0:	00000097          	auipc	ra,0x0
 8d4:	e04080e7          	jalr	-508(ra) # 6d4 <vprintf>
}
 8d8:	60e2                	ld	ra,24(sp)
 8da:	6442                	ld	s0,16(sp)
 8dc:	6161                	addi	sp,sp,80
 8de:	8082                	ret

00000000000008e0 <printf>:

void
printf(const char *fmt, ...)
{
 8e0:	711d                	addi	sp,sp,-96
 8e2:	ec06                	sd	ra,24(sp)
 8e4:	e822                	sd	s0,16(sp)
 8e6:	1000                	addi	s0,sp,32
 8e8:	e40c                	sd	a1,8(s0)
 8ea:	e810                	sd	a2,16(s0)
 8ec:	ec14                	sd	a3,24(s0)
 8ee:	f018                	sd	a4,32(s0)
 8f0:	f41c                	sd	a5,40(s0)
 8f2:	03043823          	sd	a6,48(s0)
 8f6:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8fa:	00840613          	addi	a2,s0,8
 8fe:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 902:	85aa                	mv	a1,a0
 904:	4505                	li	a0,1
 906:	00000097          	auipc	ra,0x0
 90a:	dce080e7          	jalr	-562(ra) # 6d4 <vprintf>
}
 90e:	60e2                	ld	ra,24(sp)
 910:	6442                	ld	s0,16(sp)
 912:	6125                	addi	sp,sp,96
 914:	8082                	ret

0000000000000916 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 916:	1141                	addi	sp,sp,-16
 918:	e422                	sd	s0,8(sp)
 91a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 91c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 920:	00000797          	auipc	a5,0x0
 924:	2207b783          	ld	a5,544(a5) # b40 <freep>
 928:	a805                	j	958 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 92a:	4618                	lw	a4,8(a2)
 92c:	9db9                	addw	a1,a1,a4
 92e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 932:	6398                	ld	a4,0(a5)
 934:	6318                	ld	a4,0(a4)
 936:	fee53823          	sd	a4,-16(a0)
 93a:	a091                	j	97e <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 93c:	ff852703          	lw	a4,-8(a0)
 940:	9e39                	addw	a2,a2,a4
 942:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 944:	ff053703          	ld	a4,-16(a0)
 948:	e398                	sd	a4,0(a5)
 94a:	a099                	j	990 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 94c:	6398                	ld	a4,0(a5)
 94e:	00e7e463          	bltu	a5,a4,956 <free+0x40>
 952:	00e6ea63          	bltu	a3,a4,966 <free+0x50>
{
 956:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 958:	fed7fae3          	bgeu	a5,a3,94c <free+0x36>
 95c:	6398                	ld	a4,0(a5)
 95e:	00e6e463          	bltu	a3,a4,966 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 962:	fee7eae3          	bltu	a5,a4,956 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 966:	ff852583          	lw	a1,-8(a0)
 96a:	6390                	ld	a2,0(a5)
 96c:	02059713          	slli	a4,a1,0x20
 970:	9301                	srli	a4,a4,0x20
 972:	0712                	slli	a4,a4,0x4
 974:	9736                	add	a4,a4,a3
 976:	fae60ae3          	beq	a2,a4,92a <free+0x14>
    bp->s.ptr = p->s.ptr;
 97a:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 97e:	4790                	lw	a2,8(a5)
 980:	02061713          	slli	a4,a2,0x20
 984:	9301                	srli	a4,a4,0x20
 986:	0712                	slli	a4,a4,0x4
 988:	973e                	add	a4,a4,a5
 98a:	fae689e3          	beq	a3,a4,93c <free+0x26>
  } else
    p->s.ptr = bp;
 98e:	e394                	sd	a3,0(a5)
  freep = p;
 990:	00000717          	auipc	a4,0x0
 994:	1af73823          	sd	a5,432(a4) # b40 <freep>
}
 998:	6422                	ld	s0,8(sp)
 99a:	0141                	addi	sp,sp,16
 99c:	8082                	ret

000000000000099e <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 99e:	7139                	addi	sp,sp,-64
 9a0:	fc06                	sd	ra,56(sp)
 9a2:	f822                	sd	s0,48(sp)
 9a4:	f426                	sd	s1,40(sp)
 9a6:	f04a                	sd	s2,32(sp)
 9a8:	ec4e                	sd	s3,24(sp)
 9aa:	e852                	sd	s4,16(sp)
 9ac:	e456                	sd	s5,8(sp)
 9ae:	e05a                	sd	s6,0(sp)
 9b0:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 9b2:	02051493          	slli	s1,a0,0x20
 9b6:	9081                	srli	s1,s1,0x20
 9b8:	04bd                	addi	s1,s1,15
 9ba:	8091                	srli	s1,s1,0x4
 9bc:	0014899b          	addiw	s3,s1,1
 9c0:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 9c2:	00000517          	auipc	a0,0x0
 9c6:	17e53503          	ld	a0,382(a0) # b40 <freep>
 9ca:	c515                	beqz	a0,9f6 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9cc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9ce:	4798                	lw	a4,8(a5)
 9d0:	02977f63          	bgeu	a4,s1,a0e <malloc+0x70>
 9d4:	8a4e                	mv	s4,s3
 9d6:	0009871b          	sext.w	a4,s3
 9da:	6685                	lui	a3,0x1
 9dc:	00d77363          	bgeu	a4,a3,9e2 <malloc+0x44>
 9e0:	6a05                	lui	s4,0x1
 9e2:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9e6:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9ea:	00000917          	auipc	s2,0x0
 9ee:	15690913          	addi	s2,s2,342 # b40 <freep>
  if(p == (char*)-1)
 9f2:	5afd                	li	s5,-1
 9f4:	a88d                	j	a66 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 9f6:	00000797          	auipc	a5,0x0
 9fa:	15278793          	addi	a5,a5,338 # b48 <base>
 9fe:	00000717          	auipc	a4,0x0
 a02:	14f73123          	sd	a5,322(a4) # b40 <freep>
 a06:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 a08:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 a0c:	b7e1                	j	9d4 <malloc+0x36>
      if(p->s.size == nunits)
 a0e:	02e48b63          	beq	s1,a4,a44 <malloc+0xa6>
        p->s.size -= nunits;
 a12:	4137073b          	subw	a4,a4,s3
 a16:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a18:	1702                	slli	a4,a4,0x20
 a1a:	9301                	srli	a4,a4,0x20
 a1c:	0712                	slli	a4,a4,0x4
 a1e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a20:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a24:	00000717          	auipc	a4,0x0
 a28:	10a73e23          	sd	a0,284(a4) # b40 <freep>
      return (void*)(p + 1);
 a2c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a30:	70e2                	ld	ra,56(sp)
 a32:	7442                	ld	s0,48(sp)
 a34:	74a2                	ld	s1,40(sp)
 a36:	7902                	ld	s2,32(sp)
 a38:	69e2                	ld	s3,24(sp)
 a3a:	6a42                	ld	s4,16(sp)
 a3c:	6aa2                	ld	s5,8(sp)
 a3e:	6b02                	ld	s6,0(sp)
 a40:	6121                	addi	sp,sp,64
 a42:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a44:	6398                	ld	a4,0(a5)
 a46:	e118                	sd	a4,0(a0)
 a48:	bff1                	j	a24 <malloc+0x86>
  hp->s.size = nu;
 a4a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a4e:	0541                	addi	a0,a0,16
 a50:	00000097          	auipc	ra,0x0
 a54:	ec6080e7          	jalr	-314(ra) # 916 <free>
  return freep;
 a58:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a5c:	d971                	beqz	a0,a30 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a5e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a60:	4798                	lw	a4,8(a5)
 a62:	fa9776e3          	bgeu	a4,s1,a0e <malloc+0x70>
    if(p == freep)
 a66:	00093703          	ld	a4,0(s2)
 a6a:	853e                	mv	a0,a5
 a6c:	fef719e3          	bne	a4,a5,a5e <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a70:	8552                	mv	a0,s4
 a72:	00000097          	auipc	ra,0x0
 a76:	b66080e7          	jalr	-1178(ra) # 5d8 <sbrk>
  if(p == (char*)-1)
 a7a:	fd5518e3          	bne	a0,s5,a4a <malloc+0xac>
        return 0;
 a7e:	4501                	li	a0,0
 a80:	bf45                	j	a30 <malloc+0x92>
