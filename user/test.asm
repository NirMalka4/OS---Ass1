
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
    int pid = getpid(), i = 2;
  1c:	00000097          	auipc	ra,0x0
  20:	55e080e7          	jalr	1374(ra) # 57a <getpid>
  24:	8aaa                	mv	s5,a0
    while(i--)
        fork();
  26:	00000097          	auipc	ra,0x0
  2a:	4cc080e7          	jalr	1228(ra) # 4f2 <fork>
  2e:	00000097          	auipc	ra,0x0
  32:	4c4080e7          	jalr	1220(ra) # 4f2 <fork>
    const uint m = (loop_size >> 1);
    for (int i = 0; i < loop_size; i++) {
  36:	05205663          	blez	s2,82 <pause_system_dem+0x82>
  3a:	40195a1b          	sraiw	s4,s2,0x1
  3e:	4481                	li	s1,0
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
  40:	00001b97          	auipc	s7,0x1
  44:	9f0b8b93          	addi	s7,s7,-1552 # a30 <malloc+0xe8>
  48:	a031                	j	54 <pause_system_dem+0x54>
        }
        if (i == m) {
  4a:	029a0663          	beq	s4,s1,76 <pause_system_dem+0x76>
    for (int i = 0; i < loop_size; i++) {
  4e:	2485                	addiw	s1,s1,1
  50:	02990963          	beq	s2,s1,82 <pause_system_dem+0x82>
        if (i % interval == 0 && pid == getpid()) {
  54:	0334e7bb          	remw	a5,s1,s3
  58:	fbed                	bnez	a5,4a <pause_system_dem+0x4a>
  5a:	00000097          	auipc	ra,0x0
  5e:	520080e7          	jalr	1312(ra) # 57a <getpid>
  62:	ff5514e3          	bne	a0,s5,4a <pause_system_dem+0x4a>
            printf("pause system %d/%d completed.\n", i, loop_size);
  66:	864a                	mv	a2,s2
  68:	85a6                	mv	a1,s1
  6a:	855e                	mv	a0,s7
  6c:	00001097          	auipc	ra,0x1
  70:	81e080e7          	jalr	-2018(ra) # 88a <printf>
  74:	bfd9                	j	4a <pause_system_dem+0x4a>
            pause_system(pause_seconds);
  76:	855a                	mv	a0,s6
  78:	00000097          	auipc	ra,0x0
  7c:	522080e7          	jalr	1314(ra) # 59a <pause_system>
  80:	b7f9                	j	4e <pause_system_dem+0x4e>
        }
    }
    printf("\n");
  82:	00001517          	auipc	a0,0x1
  86:	9ce50513          	addi	a0,a0,-1586 # a50 <malloc+0x108>
  8a:	00001097          	auipc	ra,0x1
  8e:	800080e7          	jalr	-2048(ra) # 88a <printf>
}
  92:	60a6                	ld	ra,72(sp)
  94:	6406                	ld	s0,64(sp)
  96:	74e2                	ld	s1,56(sp)
  98:	7942                	ld	s2,48(sp)
  9a:	79a2                	ld	s3,40(sp)
  9c:	7a02                	ld	s4,32(sp)
  9e:	6ae2                	ld	s5,24(sp)
  a0:	6b42                	ld	s6,16(sp)
  a2:	6ba2                	ld	s7,8(sp)
  a4:	6161                	addi	sp,sp,80
  a6:	8082                	ret

00000000000000a8 <kill_system_dem>:

void kill_system_dem(int interval, int loop_size) {
  a8:	7139                	addi	sp,sp,-64
  aa:	fc06                	sd	ra,56(sp)
  ac:	f822                	sd	s0,48(sp)
  ae:	f426                	sd	s1,40(sp)
  b0:	f04a                	sd	s2,32(sp)
  b2:	ec4e                	sd	s3,24(sp)
  b4:	e852                	sd	s4,16(sp)
  b6:	e456                	sd	s5,8(sp)
  b8:	e05a                	sd	s6,0(sp)
  ba:	0080                	addi	s0,sp,64
  bc:	89aa                	mv	s3,a0
  be:	892e                	mv	s2,a1
    int pid = getpid(), i = 2;
  c0:	00000097          	auipc	ra,0x0
  c4:	4ba080e7          	jalr	1210(ra) # 57a <getpid>
  c8:	8aaa                	mv	s5,a0
    while(i--)
        fork();
  ca:	00000097          	auipc	ra,0x0
  ce:	428080e7          	jalr	1064(ra) # 4f2 <fork>
  d2:	00000097          	auipc	ra,0x0
  d6:	420080e7          	jalr	1056(ra) # 4f2 <fork>
    const uint m = (loop_size >> 1);
    for (int i = 0; i < loop_size; i++) {
  da:	05205563          	blez	s2,124 <kill_system_dem+0x7c>
  de:	40195a1b          	sraiw	s4,s2,0x1
  e2:	4481                	li	s1,0
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
  e4:	00001b17          	auipc	s6,0x1
  e8:	974b0b13          	addi	s6,s6,-1676 # a58 <malloc+0x110>
  ec:	a031                	j	f8 <kill_system_dem+0x50>
        }
        if (i == m) {
  ee:	029a0663          	beq	s4,s1,11a <kill_system_dem+0x72>
    for (int i = 0; i < loop_size; i++) {
  f2:	2485                	addiw	s1,s1,1
  f4:	02990863          	beq	s2,s1,124 <kill_system_dem+0x7c>
        if (i % interval == 0 && pid == getpid()) {
  f8:	0334e7bb          	remw	a5,s1,s3
  fc:	fbed                	bnez	a5,ee <kill_system_dem+0x46>
  fe:	00000097          	auipc	ra,0x0
 102:	47c080e7          	jalr	1148(ra) # 57a <getpid>
 106:	ff5514e3          	bne	a0,s5,ee <kill_system_dem+0x46>
            printf("kill system %d/%d completed.\n", i, loop_size);
 10a:	864a                	mv	a2,s2
 10c:	85a6                	mv	a1,s1
 10e:	855a                	mv	a0,s6
 110:	00000097          	auipc	ra,0x0
 114:	77a080e7          	jalr	1914(ra) # 88a <printf>
 118:	bfd9                	j	ee <kill_system_dem+0x46>
            kill_system();
 11a:	00000097          	auipc	ra,0x0
 11e:	488080e7          	jalr	1160(ra) # 5a2 <kill_system>
 122:	bfc1                	j	f2 <kill_system_dem+0x4a>
        }
    }
    printf("\n");
 124:	00001517          	auipc	a0,0x1
 128:	92c50513          	addi	a0,a0,-1748 # a50 <malloc+0x108>
 12c:	00000097          	auipc	ra,0x0
 130:	75e080e7          	jalr	1886(ra) # 88a <printf>
}
 134:	70e2                	ld	ra,56(sp)
 136:	7442                	ld	s0,48(sp)
 138:	74a2                	ld	s1,40(sp)
 13a:	7902                	ld	s2,32(sp)
 13c:	69e2                	ld	s3,24(sp)
 13e:	6a42                	ld	s4,16(sp)
 140:	6aa2                	ld	s5,8(sp)
 142:	6b02                	ld	s6,0(sp)
 144:	6121                	addi	sp,sp,64
 146:	8082                	ret

0000000000000148 <env>:
    }
    printf("\n");
}
*/

void env(int size, int interval, char* env_name) {
 148:	715d                	addi	sp,sp,-80
 14a:	e486                	sd	ra,72(sp)
 14c:	e0a2                	sd	s0,64(sp)
 14e:	fc26                	sd	s1,56(sp)
 150:	f84a                	sd	s2,48(sp)
 152:	f44e                	sd	s3,40(sp)
 154:	f052                	sd	s4,32(sp)
 156:	ec56                	sd	s5,24(sp)
 158:	e85a                	sd	s6,16(sp)
 15a:	e45e                	sd	s7,8(sp)
 15c:	0880                	addi	s0,sp,80
 15e:	8ab2                	mv	s5,a2
    int result = 1;
    int loop_size = 1000000;
    int n_forks = 2;
    int pid;
    for (int i = 0; i < n_forks; i++) {
        pid = fork();
 160:	00000097          	auipc	ra,0x0
 164:	392080e7          	jalr	914(ra) # 4f2 <fork>
 168:	85aa                	mv	a1,a0
        printf("%d", pid);
 16a:	00001517          	auipc	a0,0x1
 16e:	90e50513          	addi	a0,a0,-1778 # a78 <malloc+0x130>
 172:	00000097          	auipc	ra,0x0
 176:	718080e7          	jalr	1816(ra) # 88a <printf>
        pid = fork();
 17a:	00000097          	auipc	ra,0x0
 17e:	378080e7          	jalr	888(ra) # 4f2 <fork>
 182:	8a2a                	mv	s4,a0
        printf("%d", pid);
 184:	85aa                	mv	a1,a0
 186:	00001517          	auipc	a0,0x1
 18a:	8f250513          	addi	a0,a0,-1806 # a78 <malloc+0x130>
 18e:	00000097          	auipc	ra,0x0
 192:	6fc080e7          	jalr	1788(ra) # 88a <printf>
    }
    for (int i = 0; i < loop_size; i++) {
 196:	4481                	li	s1,0
        if (i % loop_size / 1 == 0) {
 198:	000f49b7          	lui	s3,0xf4
 19c:	2409899b          	addiw	s3,s3,576
        	if (pid == 0) {
        		printf("***%s %d/%d completed.\n", env_name, i, loop_size);
        	} else {
        		printf(" *** ");
 1a0:	00001b97          	auipc	s7,0x1
 1a4:	8f8b8b93          	addi	s7,s7,-1800 # a98 <malloc+0x150>
        		printf("***%s %d/%d completed.\n", env_name, i, loop_size);
 1a8:	000f4937          	lui	s2,0xf4
 1ac:	24090913          	addi	s2,s2,576 # f4240 <__global_pointer$+0xf2f67>
 1b0:	00001b17          	auipc	s6,0x1
 1b4:	8d0b0b13          	addi	s6,s6,-1840 # a80 <malloc+0x138>
 1b8:	a809                	j	1ca <env+0x82>
        		printf(" *** ");
 1ba:	855e                	mv	a0,s7
 1bc:	00000097          	auipc	ra,0x0
 1c0:	6ce080e7          	jalr	1742(ra) # 88a <printf>
    for (int i = 0; i < loop_size; i++) {
 1c4:	2485                	addiw	s1,s1,1
 1c6:	03248063          	beq	s1,s2,1e6 <env+0x9e>
        if (i % loop_size / 1 == 0) {
 1ca:	0334e7bb          	remw	a5,s1,s3
 1ce:	fbfd                	bnez	a5,1c4 <env+0x7c>
        	if (pid == 0) {
 1d0:	fe0a15e3          	bnez	s4,1ba <env+0x72>
        		printf("***%s %d/%d completed.\n", env_name, i, loop_size);
 1d4:	86ca                	mv	a3,s2
 1d6:	8626                	mv	a2,s1
 1d8:	85d6                	mv	a1,s5
 1da:	855a                	mv	a0,s6
 1dc:	00000097          	auipc	ra,0x0
 1e0:	6ae080e7          	jalr	1710(ra) # 88a <printf>
 1e4:	b7c5                	j	1c4 <env+0x7c>
        }
        if (i % interval == 0) {
            result = result * size;
        }
    }
    printf("\n");
 1e6:	00001517          	auipc	a0,0x1
 1ea:	86a50513          	addi	a0,a0,-1942 # a50 <malloc+0x108>
 1ee:	00000097          	auipc	ra,0x0
 1f2:	69c080e7          	jalr	1692(ra) # 88a <printf>
}
 1f6:	60a6                	ld	ra,72(sp)
 1f8:	6406                	ld	s0,64(sp)
 1fa:	74e2                	ld	s1,56(sp)
 1fc:	7942                	ld	s2,48(sp)
 1fe:	79a2                	ld	s3,40(sp)
 200:	7a02                	ld	s4,32(sp)
 202:	6ae2                	ld	s5,24(sp)
 204:	6b42                	ld	s6,16(sp)
 206:	6ba2                	ld	s7,8(sp)
 208:	6161                	addi	sp,sp,80
 20a:	8082                	ret

000000000000020c <env_large>:

void env_large() {
 20c:	1141                	addi	sp,sp,-16
 20e:	e406                	sd	ra,8(sp)
 210:	e022                	sd	s0,0(sp)
 212:	0800                	addi	s0,sp,16
    env(1000000, 1000000, "env_large");
 214:	00001617          	auipc	a2,0x1
 218:	88c60613          	addi	a2,a2,-1908 # aa0 <malloc+0x158>
 21c:	000f45b7          	lui	a1,0xf4
 220:	24058593          	addi	a1,a1,576 # f4240 <__global_pointer$+0xf2f67>
 224:	852e                	mv	a0,a1
 226:	00000097          	auipc	ra,0x0
 22a:	f22080e7          	jalr	-222(ra) # 148 <env>
}
 22e:	60a2                	ld	ra,8(sp)
 230:	6402                	ld	s0,0(sp)
 232:	0141                	addi	sp,sp,16
 234:	8082                	ret

0000000000000236 <env_freq>:

void env_freq() {
 236:	1141                	addi	sp,sp,-16
 238:	e406                	sd	ra,8(sp)
 23a:	e022                	sd	s0,0(sp)
 23c:	0800                	addi	s0,sp,16
    env(10, 10, "env_freq");
 23e:	00001617          	auipc	a2,0x1
 242:	87260613          	addi	a2,a2,-1934 # ab0 <malloc+0x168>
 246:	45a9                	li	a1,10
 248:	4529                	li	a0,10
 24a:	00000097          	auipc	ra,0x0
 24e:	efe080e7          	jalr	-258(ra) # 148 <env>
}
 252:	60a2                	ld	ra,8(sp)
 254:	6402                	ld	s0,0(sp)
 256:	0141                	addi	sp,sp,16
 258:	8082                	ret

000000000000025a <main>:

int
main(int argc, char *argv[])
{
 25a:	1141                	addi	sp,sp,-16
 25c:	e406                	sd	ra,8(sp)
 25e:	e022                	sd	s0,0(sp)
 260:	0800                	addi	s0,sp,16
    //set_economic_mode_dem(10, 100);
    //pause_system_dem(10, 10, 100);
    //kill_system_dem(10, 100);
    env_large();
 262:	00000097          	auipc	ra,0x0
 266:	faa080e7          	jalr	-86(ra) # 20c <env_large>
    print_stats();
 26a:	00000097          	auipc	ra,0x0
 26e:	340080e7          	jalr	832(ra) # 5aa <print_stats>
    env_freq();
 272:	00000097          	auipc	ra,0x0
 276:	fc4080e7          	jalr	-60(ra) # 236 <env_freq>
    exit(0);
 27a:	4501                	li	a0,0
 27c:	00000097          	auipc	ra,0x0
 280:	27e080e7          	jalr	638(ra) # 4fa <exit>

0000000000000284 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 284:	1141                	addi	sp,sp,-16
 286:	e422                	sd	s0,8(sp)
 288:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 28a:	87aa                	mv	a5,a0
 28c:	0585                	addi	a1,a1,1
 28e:	0785                	addi	a5,a5,1
 290:	fff5c703          	lbu	a4,-1(a1)
 294:	fee78fa3          	sb	a4,-1(a5)
 298:	fb75                	bnez	a4,28c <strcpy+0x8>
    ;
  return os;
}
 29a:	6422                	ld	s0,8(sp)
 29c:	0141                	addi	sp,sp,16
 29e:	8082                	ret

00000000000002a0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2a0:	1141                	addi	sp,sp,-16
 2a2:	e422                	sd	s0,8(sp)
 2a4:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2a6:	00054783          	lbu	a5,0(a0)
 2aa:	cb91                	beqz	a5,2be <strcmp+0x1e>
 2ac:	0005c703          	lbu	a4,0(a1)
 2b0:	00f71763          	bne	a4,a5,2be <strcmp+0x1e>
    p++, q++;
 2b4:	0505                	addi	a0,a0,1
 2b6:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2b8:	00054783          	lbu	a5,0(a0)
 2bc:	fbe5                	bnez	a5,2ac <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2be:	0005c503          	lbu	a0,0(a1)
}
 2c2:	40a7853b          	subw	a0,a5,a0
 2c6:	6422                	ld	s0,8(sp)
 2c8:	0141                	addi	sp,sp,16
 2ca:	8082                	ret

00000000000002cc <strlen>:

uint
strlen(const char *s)
{
 2cc:	1141                	addi	sp,sp,-16
 2ce:	e422                	sd	s0,8(sp)
 2d0:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2d2:	00054783          	lbu	a5,0(a0)
 2d6:	cf91                	beqz	a5,2f2 <strlen+0x26>
 2d8:	0505                	addi	a0,a0,1
 2da:	87aa                	mv	a5,a0
 2dc:	4685                	li	a3,1
 2de:	9e89                	subw	a3,a3,a0
 2e0:	00f6853b          	addw	a0,a3,a5
 2e4:	0785                	addi	a5,a5,1
 2e6:	fff7c703          	lbu	a4,-1(a5)
 2ea:	fb7d                	bnez	a4,2e0 <strlen+0x14>
    ;
  return n;
}
 2ec:	6422                	ld	s0,8(sp)
 2ee:	0141                	addi	sp,sp,16
 2f0:	8082                	ret
  for(n = 0; s[n]; n++)
 2f2:	4501                	li	a0,0
 2f4:	bfe5                	j	2ec <strlen+0x20>

00000000000002f6 <memset>:

void*
memset(void *dst, int c, uint n)
{
 2f6:	1141                	addi	sp,sp,-16
 2f8:	e422                	sd	s0,8(sp)
 2fa:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2fc:	ce09                	beqz	a2,316 <memset+0x20>
 2fe:	87aa                	mv	a5,a0
 300:	fff6071b          	addiw	a4,a2,-1
 304:	1702                	slli	a4,a4,0x20
 306:	9301                	srli	a4,a4,0x20
 308:	0705                	addi	a4,a4,1
 30a:	972a                	add	a4,a4,a0
    cdst[i] = c;
 30c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 310:	0785                	addi	a5,a5,1
 312:	fee79de3          	bne	a5,a4,30c <memset+0x16>
  }
  return dst;
}
 316:	6422                	ld	s0,8(sp)
 318:	0141                	addi	sp,sp,16
 31a:	8082                	ret

000000000000031c <strchr>:

char*
strchr(const char *s, char c)
{
 31c:	1141                	addi	sp,sp,-16
 31e:	e422                	sd	s0,8(sp)
 320:	0800                	addi	s0,sp,16
  for(; *s; s++)
 322:	00054783          	lbu	a5,0(a0)
 326:	cb99                	beqz	a5,33c <strchr+0x20>
    if(*s == c)
 328:	00f58763          	beq	a1,a5,336 <strchr+0x1a>
  for(; *s; s++)
 32c:	0505                	addi	a0,a0,1
 32e:	00054783          	lbu	a5,0(a0)
 332:	fbfd                	bnez	a5,328 <strchr+0xc>
      return (char*)s;
  return 0;
 334:	4501                	li	a0,0
}
 336:	6422                	ld	s0,8(sp)
 338:	0141                	addi	sp,sp,16
 33a:	8082                	ret
  return 0;
 33c:	4501                	li	a0,0
 33e:	bfe5                	j	336 <strchr+0x1a>

0000000000000340 <gets>:

char*
gets(char *buf, int max)
{
 340:	711d                	addi	sp,sp,-96
 342:	ec86                	sd	ra,88(sp)
 344:	e8a2                	sd	s0,80(sp)
 346:	e4a6                	sd	s1,72(sp)
 348:	e0ca                	sd	s2,64(sp)
 34a:	fc4e                	sd	s3,56(sp)
 34c:	f852                	sd	s4,48(sp)
 34e:	f456                	sd	s5,40(sp)
 350:	f05a                	sd	s6,32(sp)
 352:	ec5e                	sd	s7,24(sp)
 354:	1080                	addi	s0,sp,96
 356:	8baa                	mv	s7,a0
 358:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 35a:	892a                	mv	s2,a0
 35c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 35e:	4aa9                	li	s5,10
 360:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 362:	89a6                	mv	s3,s1
 364:	2485                	addiw	s1,s1,1
 366:	0344d863          	bge	s1,s4,396 <gets+0x56>
    cc = read(0, &c, 1);
 36a:	4605                	li	a2,1
 36c:	faf40593          	addi	a1,s0,-81
 370:	4501                	li	a0,0
 372:	00000097          	auipc	ra,0x0
 376:	1a0080e7          	jalr	416(ra) # 512 <read>
    if(cc < 1)
 37a:	00a05e63          	blez	a0,396 <gets+0x56>
    buf[i++] = c;
 37e:	faf44783          	lbu	a5,-81(s0)
 382:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 386:	01578763          	beq	a5,s5,394 <gets+0x54>
 38a:	0905                	addi	s2,s2,1
 38c:	fd679be3          	bne	a5,s6,362 <gets+0x22>
  for(i=0; i+1 < max; ){
 390:	89a6                	mv	s3,s1
 392:	a011                	j	396 <gets+0x56>
 394:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 396:	99de                	add	s3,s3,s7
 398:	00098023          	sb	zero,0(s3) # f4000 <__global_pointer$+0xf2d27>
  return buf;
}
 39c:	855e                	mv	a0,s7
 39e:	60e6                	ld	ra,88(sp)
 3a0:	6446                	ld	s0,80(sp)
 3a2:	64a6                	ld	s1,72(sp)
 3a4:	6906                	ld	s2,64(sp)
 3a6:	79e2                	ld	s3,56(sp)
 3a8:	7a42                	ld	s4,48(sp)
 3aa:	7aa2                	ld	s5,40(sp)
 3ac:	7b02                	ld	s6,32(sp)
 3ae:	6be2                	ld	s7,24(sp)
 3b0:	6125                	addi	sp,sp,96
 3b2:	8082                	ret

00000000000003b4 <stat>:

int
stat(const char *n, struct stat *st)
{
 3b4:	1101                	addi	sp,sp,-32
 3b6:	ec06                	sd	ra,24(sp)
 3b8:	e822                	sd	s0,16(sp)
 3ba:	e426                	sd	s1,8(sp)
 3bc:	e04a                	sd	s2,0(sp)
 3be:	1000                	addi	s0,sp,32
 3c0:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3c2:	4581                	li	a1,0
 3c4:	00000097          	auipc	ra,0x0
 3c8:	176080e7          	jalr	374(ra) # 53a <open>
  if(fd < 0)
 3cc:	02054563          	bltz	a0,3f6 <stat+0x42>
 3d0:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3d2:	85ca                	mv	a1,s2
 3d4:	00000097          	auipc	ra,0x0
 3d8:	17e080e7          	jalr	382(ra) # 552 <fstat>
 3dc:	892a                	mv	s2,a0
  close(fd);
 3de:	8526                	mv	a0,s1
 3e0:	00000097          	auipc	ra,0x0
 3e4:	142080e7          	jalr	322(ra) # 522 <close>
  return r;
}
 3e8:	854a                	mv	a0,s2
 3ea:	60e2                	ld	ra,24(sp)
 3ec:	6442                	ld	s0,16(sp)
 3ee:	64a2                	ld	s1,8(sp)
 3f0:	6902                	ld	s2,0(sp)
 3f2:	6105                	addi	sp,sp,32
 3f4:	8082                	ret
    return -1;
 3f6:	597d                	li	s2,-1
 3f8:	bfc5                	j	3e8 <stat+0x34>

00000000000003fa <atoi>:

int
atoi(const char *s)
{
 3fa:	1141                	addi	sp,sp,-16
 3fc:	e422                	sd	s0,8(sp)
 3fe:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 400:	00054603          	lbu	a2,0(a0)
 404:	fd06079b          	addiw	a5,a2,-48
 408:	0ff7f793          	andi	a5,a5,255
 40c:	4725                	li	a4,9
 40e:	02f76963          	bltu	a4,a5,440 <atoi+0x46>
 412:	86aa                	mv	a3,a0
  n = 0;
 414:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 416:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 418:	0685                	addi	a3,a3,1
 41a:	0025179b          	slliw	a5,a0,0x2
 41e:	9fa9                	addw	a5,a5,a0
 420:	0017979b          	slliw	a5,a5,0x1
 424:	9fb1                	addw	a5,a5,a2
 426:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 42a:	0006c603          	lbu	a2,0(a3)
 42e:	fd06071b          	addiw	a4,a2,-48
 432:	0ff77713          	andi	a4,a4,255
 436:	fee5f1e3          	bgeu	a1,a4,418 <atoi+0x1e>
  return n;
}
 43a:	6422                	ld	s0,8(sp)
 43c:	0141                	addi	sp,sp,16
 43e:	8082                	ret
  n = 0;
 440:	4501                	li	a0,0
 442:	bfe5                	j	43a <atoi+0x40>

0000000000000444 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 444:	1141                	addi	sp,sp,-16
 446:	e422                	sd	s0,8(sp)
 448:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 44a:	02b57663          	bgeu	a0,a1,476 <memmove+0x32>
    while(n-- > 0)
 44e:	02c05163          	blez	a2,470 <memmove+0x2c>
 452:	fff6079b          	addiw	a5,a2,-1
 456:	1782                	slli	a5,a5,0x20
 458:	9381                	srli	a5,a5,0x20
 45a:	0785                	addi	a5,a5,1
 45c:	97aa                	add	a5,a5,a0
  dst = vdst;
 45e:	872a                	mv	a4,a0
      *dst++ = *src++;
 460:	0585                	addi	a1,a1,1
 462:	0705                	addi	a4,a4,1
 464:	fff5c683          	lbu	a3,-1(a1)
 468:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 46c:	fee79ae3          	bne	a5,a4,460 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 470:	6422                	ld	s0,8(sp)
 472:	0141                	addi	sp,sp,16
 474:	8082                	ret
    dst += n;
 476:	00c50733          	add	a4,a0,a2
    src += n;
 47a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 47c:	fec05ae3          	blez	a2,470 <memmove+0x2c>
 480:	fff6079b          	addiw	a5,a2,-1
 484:	1782                	slli	a5,a5,0x20
 486:	9381                	srli	a5,a5,0x20
 488:	fff7c793          	not	a5,a5
 48c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 48e:	15fd                	addi	a1,a1,-1
 490:	177d                	addi	a4,a4,-1
 492:	0005c683          	lbu	a3,0(a1)
 496:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 49a:	fee79ae3          	bne	a5,a4,48e <memmove+0x4a>
 49e:	bfc9                	j	470 <memmove+0x2c>

00000000000004a0 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4a0:	1141                	addi	sp,sp,-16
 4a2:	e422                	sd	s0,8(sp)
 4a4:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4a6:	ca05                	beqz	a2,4d6 <memcmp+0x36>
 4a8:	fff6069b          	addiw	a3,a2,-1
 4ac:	1682                	slli	a3,a3,0x20
 4ae:	9281                	srli	a3,a3,0x20
 4b0:	0685                	addi	a3,a3,1
 4b2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4b4:	00054783          	lbu	a5,0(a0)
 4b8:	0005c703          	lbu	a4,0(a1)
 4bc:	00e79863          	bne	a5,a4,4cc <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4c0:	0505                	addi	a0,a0,1
    p2++;
 4c2:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4c4:	fed518e3          	bne	a0,a3,4b4 <memcmp+0x14>
  }
  return 0;
 4c8:	4501                	li	a0,0
 4ca:	a019                	j	4d0 <memcmp+0x30>
      return *p1 - *p2;
 4cc:	40e7853b          	subw	a0,a5,a4
}
 4d0:	6422                	ld	s0,8(sp)
 4d2:	0141                	addi	sp,sp,16
 4d4:	8082                	ret
  return 0;
 4d6:	4501                	li	a0,0
 4d8:	bfe5                	j	4d0 <memcmp+0x30>

00000000000004da <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4da:	1141                	addi	sp,sp,-16
 4dc:	e406                	sd	ra,8(sp)
 4de:	e022                	sd	s0,0(sp)
 4e0:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4e2:	00000097          	auipc	ra,0x0
 4e6:	f62080e7          	jalr	-158(ra) # 444 <memmove>
}
 4ea:	60a2                	ld	ra,8(sp)
 4ec:	6402                	ld	s0,0(sp)
 4ee:	0141                	addi	sp,sp,16
 4f0:	8082                	ret

00000000000004f2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4f2:	4885                	li	a7,1
 ecall
 4f4:	00000073          	ecall
 ret
 4f8:	8082                	ret

00000000000004fa <exit>:
.global exit
exit:
 li a7, SYS_exit
 4fa:	4889                	li	a7,2
 ecall
 4fc:	00000073          	ecall
 ret
 500:	8082                	ret

0000000000000502 <wait>:
.global wait
wait:
 li a7, SYS_wait
 502:	488d                	li	a7,3
 ecall
 504:	00000073          	ecall
 ret
 508:	8082                	ret

000000000000050a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 50a:	4891                	li	a7,4
 ecall
 50c:	00000073          	ecall
 ret
 510:	8082                	ret

0000000000000512 <read>:
.global read
read:
 li a7, SYS_read
 512:	4895                	li	a7,5
 ecall
 514:	00000073          	ecall
 ret
 518:	8082                	ret

000000000000051a <write>:
.global write
write:
 li a7, SYS_write
 51a:	48c1                	li	a7,16
 ecall
 51c:	00000073          	ecall
 ret
 520:	8082                	ret

0000000000000522 <close>:
.global close
close:
 li a7, SYS_close
 522:	48d5                	li	a7,21
 ecall
 524:	00000073          	ecall
 ret
 528:	8082                	ret

000000000000052a <kill>:
.global kill
kill:
 li a7, SYS_kill
 52a:	4899                	li	a7,6
 ecall
 52c:	00000073          	ecall
 ret
 530:	8082                	ret

0000000000000532 <exec>:
.global exec
exec:
 li a7, SYS_exec
 532:	489d                	li	a7,7
 ecall
 534:	00000073          	ecall
 ret
 538:	8082                	ret

000000000000053a <open>:
.global open
open:
 li a7, SYS_open
 53a:	48bd                	li	a7,15
 ecall
 53c:	00000073          	ecall
 ret
 540:	8082                	ret

0000000000000542 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 542:	48c5                	li	a7,17
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 54a:	48c9                	li	a7,18
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 552:	48a1                	li	a7,8
 ecall
 554:	00000073          	ecall
 ret
 558:	8082                	ret

000000000000055a <link>:
.global link
link:
 li a7, SYS_link
 55a:	48cd                	li	a7,19
 ecall
 55c:	00000073          	ecall
 ret
 560:	8082                	ret

0000000000000562 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 562:	48d1                	li	a7,20
 ecall
 564:	00000073          	ecall
 ret
 568:	8082                	ret

000000000000056a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 56a:	48a5                	li	a7,9
 ecall
 56c:	00000073          	ecall
 ret
 570:	8082                	ret

0000000000000572 <dup>:
.global dup
dup:
 li a7, SYS_dup
 572:	48a9                	li	a7,10
 ecall
 574:	00000073          	ecall
 ret
 578:	8082                	ret

000000000000057a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 57a:	48ad                	li	a7,11
 ecall
 57c:	00000073          	ecall
 ret
 580:	8082                	ret

0000000000000582 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 582:	48b1                	li	a7,12
 ecall
 584:	00000073          	ecall
 ret
 588:	8082                	ret

000000000000058a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 58a:	48b5                	li	a7,13
 ecall
 58c:	00000073          	ecall
 ret
 590:	8082                	ret

0000000000000592 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 592:	48b9                	li	a7,14
 ecall
 594:	00000073          	ecall
 ret
 598:	8082                	ret

000000000000059a <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 59a:	48d9                	li	a7,22
 ecall
 59c:	00000073          	ecall
 ret
 5a0:	8082                	ret

00000000000005a2 <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 5a2:	48dd                	li	a7,23
 ecall
 5a4:	00000073          	ecall
 ret
 5a8:	8082                	ret

00000000000005aa <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 5aa:	48e1                	li	a7,24
 ecall
 5ac:	00000073          	ecall
 ret
 5b0:	8082                	ret

00000000000005b2 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5b2:	1101                	addi	sp,sp,-32
 5b4:	ec06                	sd	ra,24(sp)
 5b6:	e822                	sd	s0,16(sp)
 5b8:	1000                	addi	s0,sp,32
 5ba:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5be:	4605                	li	a2,1
 5c0:	fef40593          	addi	a1,s0,-17
 5c4:	00000097          	auipc	ra,0x0
 5c8:	f56080e7          	jalr	-170(ra) # 51a <write>
}
 5cc:	60e2                	ld	ra,24(sp)
 5ce:	6442                	ld	s0,16(sp)
 5d0:	6105                	addi	sp,sp,32
 5d2:	8082                	ret

00000000000005d4 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5d4:	7139                	addi	sp,sp,-64
 5d6:	fc06                	sd	ra,56(sp)
 5d8:	f822                	sd	s0,48(sp)
 5da:	f426                	sd	s1,40(sp)
 5dc:	f04a                	sd	s2,32(sp)
 5de:	ec4e                	sd	s3,24(sp)
 5e0:	0080                	addi	s0,sp,64
 5e2:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5e4:	c299                	beqz	a3,5ea <printint+0x16>
 5e6:	0805c863          	bltz	a1,676 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5ea:	2581                	sext.w	a1,a1
  neg = 0;
 5ec:	4881                	li	a7,0
 5ee:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 5f2:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 5f4:	2601                	sext.w	a2,a2
 5f6:	00000517          	auipc	a0,0x0
 5fa:	4d250513          	addi	a0,a0,1234 # ac8 <digits>
 5fe:	883a                	mv	a6,a4
 600:	2705                	addiw	a4,a4,1
 602:	02c5f7bb          	remuw	a5,a1,a2
 606:	1782                	slli	a5,a5,0x20
 608:	9381                	srli	a5,a5,0x20
 60a:	97aa                	add	a5,a5,a0
 60c:	0007c783          	lbu	a5,0(a5)
 610:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 614:	0005879b          	sext.w	a5,a1
 618:	02c5d5bb          	divuw	a1,a1,a2
 61c:	0685                	addi	a3,a3,1
 61e:	fec7f0e3          	bgeu	a5,a2,5fe <printint+0x2a>
  if(neg)
 622:	00088b63          	beqz	a7,638 <printint+0x64>
    buf[i++] = '-';
 626:	fd040793          	addi	a5,s0,-48
 62a:	973e                	add	a4,a4,a5
 62c:	02d00793          	li	a5,45
 630:	fef70823          	sb	a5,-16(a4)
 634:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 638:	02e05863          	blez	a4,668 <printint+0x94>
 63c:	fc040793          	addi	a5,s0,-64
 640:	00e78933          	add	s2,a5,a4
 644:	fff78993          	addi	s3,a5,-1
 648:	99ba                	add	s3,s3,a4
 64a:	377d                	addiw	a4,a4,-1
 64c:	1702                	slli	a4,a4,0x20
 64e:	9301                	srli	a4,a4,0x20
 650:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 654:	fff94583          	lbu	a1,-1(s2)
 658:	8526                	mv	a0,s1
 65a:	00000097          	auipc	ra,0x0
 65e:	f58080e7          	jalr	-168(ra) # 5b2 <putc>
  while(--i >= 0)
 662:	197d                	addi	s2,s2,-1
 664:	ff3918e3          	bne	s2,s3,654 <printint+0x80>
}
 668:	70e2                	ld	ra,56(sp)
 66a:	7442                	ld	s0,48(sp)
 66c:	74a2                	ld	s1,40(sp)
 66e:	7902                	ld	s2,32(sp)
 670:	69e2                	ld	s3,24(sp)
 672:	6121                	addi	sp,sp,64
 674:	8082                	ret
    x = -xx;
 676:	40b005bb          	negw	a1,a1
    neg = 1;
 67a:	4885                	li	a7,1
    x = -xx;
 67c:	bf8d                	j	5ee <printint+0x1a>

000000000000067e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 67e:	7119                	addi	sp,sp,-128
 680:	fc86                	sd	ra,120(sp)
 682:	f8a2                	sd	s0,112(sp)
 684:	f4a6                	sd	s1,104(sp)
 686:	f0ca                	sd	s2,96(sp)
 688:	ecce                	sd	s3,88(sp)
 68a:	e8d2                	sd	s4,80(sp)
 68c:	e4d6                	sd	s5,72(sp)
 68e:	e0da                	sd	s6,64(sp)
 690:	fc5e                	sd	s7,56(sp)
 692:	f862                	sd	s8,48(sp)
 694:	f466                	sd	s9,40(sp)
 696:	f06a                	sd	s10,32(sp)
 698:	ec6e                	sd	s11,24(sp)
 69a:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 69c:	0005c903          	lbu	s2,0(a1)
 6a0:	18090f63          	beqz	s2,83e <vprintf+0x1c0>
 6a4:	8aaa                	mv	s5,a0
 6a6:	8b32                	mv	s6,a2
 6a8:	00158493          	addi	s1,a1,1
  state = 0;
 6ac:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6ae:	02500a13          	li	s4,37
      if(c == 'd'){
 6b2:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6b6:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6ba:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6be:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6c2:	00000b97          	auipc	s7,0x0
 6c6:	406b8b93          	addi	s7,s7,1030 # ac8 <digits>
 6ca:	a839                	j	6e8 <vprintf+0x6a>
        putc(fd, c);
 6cc:	85ca                	mv	a1,s2
 6ce:	8556                	mv	a0,s5
 6d0:	00000097          	auipc	ra,0x0
 6d4:	ee2080e7          	jalr	-286(ra) # 5b2 <putc>
 6d8:	a019                	j	6de <vprintf+0x60>
    } else if(state == '%'){
 6da:	01498f63          	beq	s3,s4,6f8 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6de:	0485                	addi	s1,s1,1
 6e0:	fff4c903          	lbu	s2,-1(s1)
 6e4:	14090d63          	beqz	s2,83e <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6e8:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6ec:	fe0997e3          	bnez	s3,6da <vprintf+0x5c>
      if(c == '%'){
 6f0:	fd479ee3          	bne	a5,s4,6cc <vprintf+0x4e>
        state = '%';
 6f4:	89be                	mv	s3,a5
 6f6:	b7e5                	j	6de <vprintf+0x60>
      if(c == 'd'){
 6f8:	05878063          	beq	a5,s8,738 <vprintf+0xba>
      } else if(c == 'l') {
 6fc:	05978c63          	beq	a5,s9,754 <vprintf+0xd6>
      } else if(c == 'x') {
 700:	07a78863          	beq	a5,s10,770 <vprintf+0xf2>
      } else if(c == 'p') {
 704:	09b78463          	beq	a5,s11,78c <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 708:	07300713          	li	a4,115
 70c:	0ce78663          	beq	a5,a4,7d8 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 710:	06300713          	li	a4,99
 714:	0ee78e63          	beq	a5,a4,810 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 718:	11478863          	beq	a5,s4,828 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 71c:	85d2                	mv	a1,s4
 71e:	8556                	mv	a0,s5
 720:	00000097          	auipc	ra,0x0
 724:	e92080e7          	jalr	-366(ra) # 5b2 <putc>
        putc(fd, c);
 728:	85ca                	mv	a1,s2
 72a:	8556                	mv	a0,s5
 72c:	00000097          	auipc	ra,0x0
 730:	e86080e7          	jalr	-378(ra) # 5b2 <putc>
      }
      state = 0;
 734:	4981                	li	s3,0
 736:	b765                	j	6de <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 738:	008b0913          	addi	s2,s6,8
 73c:	4685                	li	a3,1
 73e:	4629                	li	a2,10
 740:	000b2583          	lw	a1,0(s6)
 744:	8556                	mv	a0,s5
 746:	00000097          	auipc	ra,0x0
 74a:	e8e080e7          	jalr	-370(ra) # 5d4 <printint>
 74e:	8b4a                	mv	s6,s2
      state = 0;
 750:	4981                	li	s3,0
 752:	b771                	j	6de <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 754:	008b0913          	addi	s2,s6,8
 758:	4681                	li	a3,0
 75a:	4629                	li	a2,10
 75c:	000b2583          	lw	a1,0(s6)
 760:	8556                	mv	a0,s5
 762:	00000097          	auipc	ra,0x0
 766:	e72080e7          	jalr	-398(ra) # 5d4 <printint>
 76a:	8b4a                	mv	s6,s2
      state = 0;
 76c:	4981                	li	s3,0
 76e:	bf85                	j	6de <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 770:	008b0913          	addi	s2,s6,8
 774:	4681                	li	a3,0
 776:	4641                	li	a2,16
 778:	000b2583          	lw	a1,0(s6)
 77c:	8556                	mv	a0,s5
 77e:	00000097          	auipc	ra,0x0
 782:	e56080e7          	jalr	-426(ra) # 5d4 <printint>
 786:	8b4a                	mv	s6,s2
      state = 0;
 788:	4981                	li	s3,0
 78a:	bf91                	j	6de <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 78c:	008b0793          	addi	a5,s6,8
 790:	f8f43423          	sd	a5,-120(s0)
 794:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 798:	03000593          	li	a1,48
 79c:	8556                	mv	a0,s5
 79e:	00000097          	auipc	ra,0x0
 7a2:	e14080e7          	jalr	-492(ra) # 5b2 <putc>
  putc(fd, 'x');
 7a6:	85ea                	mv	a1,s10
 7a8:	8556                	mv	a0,s5
 7aa:	00000097          	auipc	ra,0x0
 7ae:	e08080e7          	jalr	-504(ra) # 5b2 <putc>
 7b2:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7b4:	03c9d793          	srli	a5,s3,0x3c
 7b8:	97de                	add	a5,a5,s7
 7ba:	0007c583          	lbu	a1,0(a5)
 7be:	8556                	mv	a0,s5
 7c0:	00000097          	auipc	ra,0x0
 7c4:	df2080e7          	jalr	-526(ra) # 5b2 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7c8:	0992                	slli	s3,s3,0x4
 7ca:	397d                	addiw	s2,s2,-1
 7cc:	fe0914e3          	bnez	s2,7b4 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7d0:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7d4:	4981                	li	s3,0
 7d6:	b721                	j	6de <vprintf+0x60>
        s = va_arg(ap, char*);
 7d8:	008b0993          	addi	s3,s6,8
 7dc:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 7e0:	02090163          	beqz	s2,802 <vprintf+0x184>
        while(*s != 0){
 7e4:	00094583          	lbu	a1,0(s2)
 7e8:	c9a1                	beqz	a1,838 <vprintf+0x1ba>
          putc(fd, *s);
 7ea:	8556                	mv	a0,s5
 7ec:	00000097          	auipc	ra,0x0
 7f0:	dc6080e7          	jalr	-570(ra) # 5b2 <putc>
          s++;
 7f4:	0905                	addi	s2,s2,1
        while(*s != 0){
 7f6:	00094583          	lbu	a1,0(s2)
 7fa:	f9e5                	bnez	a1,7ea <vprintf+0x16c>
        s = va_arg(ap, char*);
 7fc:	8b4e                	mv	s6,s3
      state = 0;
 7fe:	4981                	li	s3,0
 800:	bdf9                	j	6de <vprintf+0x60>
          s = "(null)";
 802:	00000917          	auipc	s2,0x0
 806:	2be90913          	addi	s2,s2,702 # ac0 <malloc+0x178>
        while(*s != 0){
 80a:	02800593          	li	a1,40
 80e:	bff1                	j	7ea <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 810:	008b0913          	addi	s2,s6,8
 814:	000b4583          	lbu	a1,0(s6)
 818:	8556                	mv	a0,s5
 81a:	00000097          	auipc	ra,0x0
 81e:	d98080e7          	jalr	-616(ra) # 5b2 <putc>
 822:	8b4a                	mv	s6,s2
      state = 0;
 824:	4981                	li	s3,0
 826:	bd65                	j	6de <vprintf+0x60>
        putc(fd, c);
 828:	85d2                	mv	a1,s4
 82a:	8556                	mv	a0,s5
 82c:	00000097          	auipc	ra,0x0
 830:	d86080e7          	jalr	-634(ra) # 5b2 <putc>
      state = 0;
 834:	4981                	li	s3,0
 836:	b565                	j	6de <vprintf+0x60>
        s = va_arg(ap, char*);
 838:	8b4e                	mv	s6,s3
      state = 0;
 83a:	4981                	li	s3,0
 83c:	b54d                	j	6de <vprintf+0x60>
    }
  }
}
 83e:	70e6                	ld	ra,120(sp)
 840:	7446                	ld	s0,112(sp)
 842:	74a6                	ld	s1,104(sp)
 844:	7906                	ld	s2,96(sp)
 846:	69e6                	ld	s3,88(sp)
 848:	6a46                	ld	s4,80(sp)
 84a:	6aa6                	ld	s5,72(sp)
 84c:	6b06                	ld	s6,64(sp)
 84e:	7be2                	ld	s7,56(sp)
 850:	7c42                	ld	s8,48(sp)
 852:	7ca2                	ld	s9,40(sp)
 854:	7d02                	ld	s10,32(sp)
 856:	6de2                	ld	s11,24(sp)
 858:	6109                	addi	sp,sp,128
 85a:	8082                	ret

000000000000085c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 85c:	715d                	addi	sp,sp,-80
 85e:	ec06                	sd	ra,24(sp)
 860:	e822                	sd	s0,16(sp)
 862:	1000                	addi	s0,sp,32
 864:	e010                	sd	a2,0(s0)
 866:	e414                	sd	a3,8(s0)
 868:	e818                	sd	a4,16(s0)
 86a:	ec1c                	sd	a5,24(s0)
 86c:	03043023          	sd	a6,32(s0)
 870:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 874:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 878:	8622                	mv	a2,s0
 87a:	00000097          	auipc	ra,0x0
 87e:	e04080e7          	jalr	-508(ra) # 67e <vprintf>
}
 882:	60e2                	ld	ra,24(sp)
 884:	6442                	ld	s0,16(sp)
 886:	6161                	addi	sp,sp,80
 888:	8082                	ret

000000000000088a <printf>:

void
printf(const char *fmt, ...)
{
 88a:	711d                	addi	sp,sp,-96
 88c:	ec06                	sd	ra,24(sp)
 88e:	e822                	sd	s0,16(sp)
 890:	1000                	addi	s0,sp,32
 892:	e40c                	sd	a1,8(s0)
 894:	e810                	sd	a2,16(s0)
 896:	ec14                	sd	a3,24(s0)
 898:	f018                	sd	a4,32(s0)
 89a:	f41c                	sd	a5,40(s0)
 89c:	03043823          	sd	a6,48(s0)
 8a0:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8a4:	00840613          	addi	a2,s0,8
 8a8:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8ac:	85aa                	mv	a1,a0
 8ae:	4505                	li	a0,1
 8b0:	00000097          	auipc	ra,0x0
 8b4:	dce080e7          	jalr	-562(ra) # 67e <vprintf>
}
 8b8:	60e2                	ld	ra,24(sp)
 8ba:	6442                	ld	s0,16(sp)
 8bc:	6125                	addi	sp,sp,96
 8be:	8082                	ret

00000000000008c0 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8c0:	1141                	addi	sp,sp,-16
 8c2:	e422                	sd	s0,8(sp)
 8c4:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8c6:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8ca:	00000797          	auipc	a5,0x0
 8ce:	2167b783          	ld	a5,534(a5) # ae0 <freep>
 8d2:	a805                	j	902 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8d4:	4618                	lw	a4,8(a2)
 8d6:	9db9                	addw	a1,a1,a4
 8d8:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 8dc:	6398                	ld	a4,0(a5)
 8de:	6318                	ld	a4,0(a4)
 8e0:	fee53823          	sd	a4,-16(a0)
 8e4:	a091                	j	928 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8e6:	ff852703          	lw	a4,-8(a0)
 8ea:	9e39                	addw	a2,a2,a4
 8ec:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8ee:	ff053703          	ld	a4,-16(a0)
 8f2:	e398                	sd	a4,0(a5)
 8f4:	a099                	j	93a <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8f6:	6398                	ld	a4,0(a5)
 8f8:	00e7e463          	bltu	a5,a4,900 <free+0x40>
 8fc:	00e6ea63          	bltu	a3,a4,910 <free+0x50>
{
 900:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 902:	fed7fae3          	bgeu	a5,a3,8f6 <free+0x36>
 906:	6398                	ld	a4,0(a5)
 908:	00e6e463          	bltu	a3,a4,910 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 90c:	fee7eae3          	bltu	a5,a4,900 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 910:	ff852583          	lw	a1,-8(a0)
 914:	6390                	ld	a2,0(a5)
 916:	02059713          	slli	a4,a1,0x20
 91a:	9301                	srli	a4,a4,0x20
 91c:	0712                	slli	a4,a4,0x4
 91e:	9736                	add	a4,a4,a3
 920:	fae60ae3          	beq	a2,a4,8d4 <free+0x14>
    bp->s.ptr = p->s.ptr;
 924:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 928:	4790                	lw	a2,8(a5)
 92a:	02061713          	slli	a4,a2,0x20
 92e:	9301                	srli	a4,a4,0x20
 930:	0712                	slli	a4,a4,0x4
 932:	973e                	add	a4,a4,a5
 934:	fae689e3          	beq	a3,a4,8e6 <free+0x26>
  } else
    p->s.ptr = bp;
 938:	e394                	sd	a3,0(a5)
  freep = p;
 93a:	00000717          	auipc	a4,0x0
 93e:	1af73323          	sd	a5,422(a4) # ae0 <freep>
}
 942:	6422                	ld	s0,8(sp)
 944:	0141                	addi	sp,sp,16
 946:	8082                	ret

0000000000000948 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 948:	7139                	addi	sp,sp,-64
 94a:	fc06                	sd	ra,56(sp)
 94c:	f822                	sd	s0,48(sp)
 94e:	f426                	sd	s1,40(sp)
 950:	f04a                	sd	s2,32(sp)
 952:	ec4e                	sd	s3,24(sp)
 954:	e852                	sd	s4,16(sp)
 956:	e456                	sd	s5,8(sp)
 958:	e05a                	sd	s6,0(sp)
 95a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 95c:	02051493          	slli	s1,a0,0x20
 960:	9081                	srli	s1,s1,0x20
 962:	04bd                	addi	s1,s1,15
 964:	8091                	srli	s1,s1,0x4
 966:	0014899b          	addiw	s3,s1,1
 96a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 96c:	00000517          	auipc	a0,0x0
 970:	17453503          	ld	a0,372(a0) # ae0 <freep>
 974:	c515                	beqz	a0,9a0 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 976:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 978:	4798                	lw	a4,8(a5)
 97a:	02977f63          	bgeu	a4,s1,9b8 <malloc+0x70>
 97e:	8a4e                	mv	s4,s3
 980:	0009871b          	sext.w	a4,s3
 984:	6685                	lui	a3,0x1
 986:	00d77363          	bgeu	a4,a3,98c <malloc+0x44>
 98a:	6a05                	lui	s4,0x1
 98c:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 990:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 994:	00000917          	auipc	s2,0x0
 998:	14c90913          	addi	s2,s2,332 # ae0 <freep>
  if(p == (char*)-1)
 99c:	5afd                	li	s5,-1
 99e:	a88d                	j	a10 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 9a0:	00000797          	auipc	a5,0x0
 9a4:	14878793          	addi	a5,a5,328 # ae8 <base>
 9a8:	00000717          	auipc	a4,0x0
 9ac:	12f73c23          	sd	a5,312(a4) # ae0 <freep>
 9b0:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9b2:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9b6:	b7e1                	j	97e <malloc+0x36>
      if(p->s.size == nunits)
 9b8:	02e48b63          	beq	s1,a4,9ee <malloc+0xa6>
        p->s.size -= nunits;
 9bc:	4137073b          	subw	a4,a4,s3
 9c0:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9c2:	1702                	slli	a4,a4,0x20
 9c4:	9301                	srli	a4,a4,0x20
 9c6:	0712                	slli	a4,a4,0x4
 9c8:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9ca:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9ce:	00000717          	auipc	a4,0x0
 9d2:	10a73923          	sd	a0,274(a4) # ae0 <freep>
      return (void*)(p + 1);
 9d6:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 9da:	70e2                	ld	ra,56(sp)
 9dc:	7442                	ld	s0,48(sp)
 9de:	74a2                	ld	s1,40(sp)
 9e0:	7902                	ld	s2,32(sp)
 9e2:	69e2                	ld	s3,24(sp)
 9e4:	6a42                	ld	s4,16(sp)
 9e6:	6aa2                	ld	s5,8(sp)
 9e8:	6b02                	ld	s6,0(sp)
 9ea:	6121                	addi	sp,sp,64
 9ec:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9ee:	6398                	ld	a4,0(a5)
 9f0:	e118                	sd	a4,0(a0)
 9f2:	bff1                	j	9ce <malloc+0x86>
  hp->s.size = nu;
 9f4:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 9f8:	0541                	addi	a0,a0,16
 9fa:	00000097          	auipc	ra,0x0
 9fe:	ec6080e7          	jalr	-314(ra) # 8c0 <free>
  return freep;
 a02:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a06:	d971                	beqz	a0,9da <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a08:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a0a:	4798                	lw	a4,8(a5)
 a0c:	fa9776e3          	bgeu	a4,s1,9b8 <malloc+0x70>
    if(p == freep)
 a10:	00093703          	ld	a4,0(s2)
 a14:	853e                	mv	a0,a5
 a16:	fef719e3          	bne	a4,a5,a08 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a1a:	8552                	mv	a0,s4
 a1c:	00000097          	auipc	ra,0x0
 a20:	b66080e7          	jalr	-1178(ra) # 582 <sbrk>
  if(p == (char*)-1)
 a24:	fd5518e3          	bne	a0,s5,9f4 <malloc+0xac>
        return 0;
 a28:	4501                	li	a0,0
 a2a:	bf45                	j	9da <malloc+0x92>
