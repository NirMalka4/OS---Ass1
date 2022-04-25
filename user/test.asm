
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
  20:	572080e7          	jalr	1394(ra) # 58e <getpid>
  24:	8aaa                	mv	s5,a0
    while(i--)
        fork();
  26:	00000097          	auipc	ra,0x0
  2a:	4e0080e7          	jalr	1248(ra) # 506 <fork>
  2e:	00000097          	auipc	ra,0x0
  32:	4d8080e7          	jalr	1240(ra) # 506 <fork>
    const uint m = (loop_size >> 1);
    for (int i = 0; i < loop_size; i++) {
  36:	05205663          	blez	s2,82 <pause_system_dem+0x82>
  3a:	40195a1b          	sraiw	s4,s2,0x1
  3e:	4481                	li	s1,0
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
  40:	00001b97          	auipc	s7,0x1
  44:	a00b8b93          	addi	s7,s7,-1536 # a40 <malloc+0xe4>
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
  5e:	534080e7          	jalr	1332(ra) # 58e <getpid>
  62:	ff5514e3          	bne	a0,s5,4a <pause_system_dem+0x4a>
            printf("pause system %d/%d completed.\n", i, loop_size);
  66:	864a                	mv	a2,s2
  68:	85a6                	mv	a1,s1
  6a:	855e                	mv	a0,s7
  6c:	00001097          	auipc	ra,0x1
  70:	832080e7          	jalr	-1998(ra) # 89e <printf>
  74:	bfd9                	j	4a <pause_system_dem+0x4a>
            pause_system(pause_seconds);
  76:	855a                	mv	a0,s6
  78:	00000097          	auipc	ra,0x0
  7c:	536080e7          	jalr	1334(ra) # 5ae <pause_system>
  80:	b7f9                	j	4e <pause_system_dem+0x4e>
        }
    }
    printf("\n");
  82:	00001517          	auipc	a0,0x1
  86:	9de50513          	addi	a0,a0,-1570 # a60 <malloc+0x104>
  8a:	00001097          	auipc	ra,0x1
  8e:	814080e7          	jalr	-2028(ra) # 89e <printf>
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
  c4:	4ce080e7          	jalr	1230(ra) # 58e <getpid>
  c8:	8aaa                	mv	s5,a0
    while(i--)
        fork();
  ca:	00000097          	auipc	ra,0x0
  ce:	43c080e7          	jalr	1084(ra) # 506 <fork>
  d2:	00000097          	auipc	ra,0x0
  d6:	434080e7          	jalr	1076(ra) # 506 <fork>
    const uint m = (loop_size >> 1);
    for (int i = 0; i < loop_size; i++) {
  da:	05205563          	blez	s2,124 <kill_system_dem+0x7c>
  de:	40195a1b          	sraiw	s4,s2,0x1
  e2:	4481                	li	s1,0
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
  e4:	00001b17          	auipc	s6,0x1
  e8:	984b0b13          	addi	s6,s6,-1660 # a68 <malloc+0x10c>
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
 102:	490080e7          	jalr	1168(ra) # 58e <getpid>
 106:	ff5514e3          	bne	a0,s5,ee <kill_system_dem+0x46>
            printf("kill system %d/%d completed.\n", i, loop_size);
 10a:	864a                	mv	a2,s2
 10c:	85a6                	mv	a1,s1
 10e:	855a                	mv	a0,s6
 110:	00000097          	auipc	ra,0x0
 114:	78e080e7          	jalr	1934(ra) # 89e <printf>
 118:	bfd9                	j	ee <kill_system_dem+0x46>
            kill_system();
 11a:	00000097          	auipc	ra,0x0
 11e:	49c080e7          	jalr	1180(ra) # 5b6 <kill_system>
 122:	bfc1                	j	f2 <kill_system_dem+0x4a>
        }
    }
    printf("\n");
 124:	00001517          	auipc	a0,0x1
 128:	93c50513          	addi	a0,a0,-1732 # a60 <malloc+0x104>
 12c:	00000097          	auipc	ra,0x0
 130:	772080e7          	jalr	1906(ra) # 89e <printf>
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
 148:	711d                	addi	sp,sp,-96
 14a:	ec86                	sd	ra,88(sp)
 14c:	e8a2                	sd	s0,80(sp)
 14e:	e4a6                	sd	s1,72(sp)
 150:	e0ca                	sd	s2,64(sp)
 152:	fc4e                	sd	s3,56(sp)
 154:	f852                	sd	s4,48(sp)
 156:	f456                	sd	s5,40(sp)
 158:	f05a                	sd	s6,32(sp)
 15a:	ec5e                	sd	s7,24(sp)
 15c:	e862                	sd	s8,16(sp)
 15e:	1080                	addi	s0,sp,96
 160:	8b32                	mv	s6,a2
    int result = 1;
    int loop_size = 1000000;
    int n_forks = 2;
    int pid;
    for (int i = 0; i < n_forks; i++) {
        pid = fork();
 162:	00000097          	auipc	ra,0x0
 166:	3a4080e7          	jalr	932(ra) # 506 <fork>
 16a:	85aa                	mv	a1,a0
        printf("***%d***", pid);
 16c:	00001517          	auipc	a0,0x1
 170:	91c50513          	addi	a0,a0,-1764 # a88 <malloc+0x12c>
 174:	00000097          	auipc	ra,0x0
 178:	72a080e7          	jalr	1834(ra) # 89e <printf>
        pid = fork();
 17c:	00000097          	auipc	ra,0x0
 180:	38a080e7          	jalr	906(ra) # 506 <fork>
 184:	8a2a                	mv	s4,a0
        printf("***%d***", pid);
 186:	85aa                	mv	a1,a0
 188:	00001517          	auipc	a0,0x1
 18c:	90050513          	addi	a0,a0,-1792 # a88 <malloc+0x12c>
 190:	00000097          	auipc	ra,0x0
 194:	70e080e7          	jalr	1806(ra) # 89e <printf>
    }
    for (int i = 0; i < loop_size; i++) {
 198:	4481                	li	s1,0
        if (i % loop_size / 1 == 0) {
 19a:	000f49b7          	lui	s3,0xf4
 19e:	2409899b          	addiw	s3,s3,576
                    x *= i;
                }
        	} else {
                int res;
                wait(&res);
        		printf(" ");
 1a2:	00001a97          	auipc	s5,0x1
 1a6:	90ea8a93          	addi	s5,s5,-1778 # ab0 <malloc+0x154>
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
 1aa:	000f4937          	lui	s2,0xf4
 1ae:	24090913          	addi	s2,s2,576 # f4240 <__global_pointer$+0xf2f4f>
 1b2:	00001c17          	auipc	s8,0x1
 1b6:	8e6c0c13          	addi	s8,s8,-1818 # a98 <malloc+0x13c>
 1ba:	00989bb7          	lui	s7,0x989
 1be:	a005                	j	1de <env+0x96>
 1c0:	86ca                	mv	a3,s2
 1c2:	8626                	mv	a2,s1
 1c4:	85da                	mv	a1,s6
 1c6:	8562                	mv	a0,s8
 1c8:	00000097          	auipc	ra,0x0
 1cc:	6d6080e7          	jalr	1750(ra) # 89e <printf>
 1d0:	680b8793          	addi	a5,s7,1664 # 989680 <__global_pointer$+0x98838f>
                for(long i = 0; i < 10000000; i++){
 1d4:	17fd                	addi	a5,a5,-1
 1d6:	fffd                	bnez	a5,1d4 <env+0x8c>
    for (int i = 0; i < loop_size; i++) {
 1d8:	2485                	addiw	s1,s1,1
 1da:	03248363          	beq	s1,s2,200 <env+0xb8>
        if (i % loop_size / 1 == 0) {
 1de:	0334e7bb          	remw	a5,s1,s3
 1e2:	fbfd                	bnez	a5,1d8 <env+0x90>
        	if (pid == 0) {
 1e4:	fc0a0ee3          	beqz	s4,1c0 <env+0x78>
                wait(&res);
 1e8:	fac40513          	addi	a0,s0,-84
 1ec:	00000097          	auipc	ra,0x0
 1f0:	32a080e7          	jalr	810(ra) # 516 <wait>
        		printf(" ");
 1f4:	8556                	mv	a0,s5
 1f6:	00000097          	auipc	ra,0x0
 1fa:	6a8080e7          	jalr	1704(ra) # 89e <printf>
 1fe:	bfe9                	j	1d8 <env+0x90>
        }
        if (i % interval == 0) {
            result = result * size;
        }
    }
    printf("\n");
 200:	00001517          	auipc	a0,0x1
 204:	86050513          	addi	a0,a0,-1952 # a60 <malloc+0x104>
 208:	00000097          	auipc	ra,0x0
 20c:	696080e7          	jalr	1686(ra) # 89e <printf>
}
 210:	60e6                	ld	ra,88(sp)
 212:	6446                	ld	s0,80(sp)
 214:	64a6                	ld	s1,72(sp)
 216:	6906                	ld	s2,64(sp)
 218:	79e2                	ld	s3,56(sp)
 21a:	7a42                	ld	s4,48(sp)
 21c:	7aa2                	ld	s5,40(sp)
 21e:	7b02                	ld	s6,32(sp)
 220:	6be2                	ld	s7,24(sp)
 222:	6c42                	ld	s8,16(sp)
 224:	6125                	addi	sp,sp,96
 226:	8082                	ret

0000000000000228 <env_large>:

void env_large() {
 228:	1141                	addi	sp,sp,-16
 22a:	e406                	sd	ra,8(sp)
 22c:	e022                	sd	s0,0(sp)
 22e:	0800                	addi	s0,sp,16
    env(1000000, 1000000, "env_large");
 230:	00001617          	auipc	a2,0x1
 234:	88860613          	addi	a2,a2,-1912 # ab8 <malloc+0x15c>
 238:	000f45b7          	lui	a1,0xf4
 23c:	24058593          	addi	a1,a1,576 # f4240 <__global_pointer$+0xf2f4f>
 240:	852e                	mv	a0,a1
 242:	00000097          	auipc	ra,0x0
 246:	f06080e7          	jalr	-250(ra) # 148 <env>
}
 24a:	60a2                	ld	ra,8(sp)
 24c:	6402                	ld	s0,0(sp)
 24e:	0141                	addi	sp,sp,16
 250:	8082                	ret

0000000000000252 <env_freq>:

void env_freq() {
 252:	1141                	addi	sp,sp,-16
 254:	e406                	sd	ra,8(sp)
 256:	e022                	sd	s0,0(sp)
 258:	0800                	addi	s0,sp,16
    env(10, 10, "env_freq");
 25a:	00001617          	auipc	a2,0x1
 25e:	86e60613          	addi	a2,a2,-1938 # ac8 <malloc+0x16c>
 262:	45a9                	li	a1,10
 264:	4529                	li	a0,10
 266:	00000097          	auipc	ra,0x0
 26a:	ee2080e7          	jalr	-286(ra) # 148 <env>
}
 26e:	60a2                	ld	ra,8(sp)
 270:	6402                	ld	s0,0(sp)
 272:	0141                	addi	sp,sp,16
 274:	8082                	ret

0000000000000276 <main>:

int
main(int argc, char *argv[])
{
 276:	1141                	addi	sp,sp,-16
 278:	e406                	sd	ra,8(sp)
 27a:	e022                	sd	s0,0(sp)
 27c:	0800                	addi	s0,sp,16
    //set_economic_mode_dem(10, 100);
    //pause_system_dem(10, 10, 100);
    //kill_system_dem(10, 100);
    env_large();
 27e:	00000097          	auipc	ra,0x0
 282:	faa080e7          	jalr	-86(ra) # 228 <env_large>
    print_stats();
 286:	00000097          	auipc	ra,0x0
 28a:	338080e7          	jalr	824(ra) # 5be <print_stats>
    // env_freq();
    // print_stats();
    exit(0);
 28e:	4501                	li	a0,0
 290:	00000097          	auipc	ra,0x0
 294:	27e080e7          	jalr	638(ra) # 50e <exit>

0000000000000298 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 298:	1141                	addi	sp,sp,-16
 29a:	e422                	sd	s0,8(sp)
 29c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 29e:	87aa                	mv	a5,a0
 2a0:	0585                	addi	a1,a1,1
 2a2:	0785                	addi	a5,a5,1
 2a4:	fff5c703          	lbu	a4,-1(a1)
 2a8:	fee78fa3          	sb	a4,-1(a5)
 2ac:	fb75                	bnez	a4,2a0 <strcpy+0x8>
    ;
  return os;
}
 2ae:	6422                	ld	s0,8(sp)
 2b0:	0141                	addi	sp,sp,16
 2b2:	8082                	ret

00000000000002b4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2b4:	1141                	addi	sp,sp,-16
 2b6:	e422                	sd	s0,8(sp)
 2b8:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2ba:	00054783          	lbu	a5,0(a0)
 2be:	cb91                	beqz	a5,2d2 <strcmp+0x1e>
 2c0:	0005c703          	lbu	a4,0(a1)
 2c4:	00f71763          	bne	a4,a5,2d2 <strcmp+0x1e>
    p++, q++;
 2c8:	0505                	addi	a0,a0,1
 2ca:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2cc:	00054783          	lbu	a5,0(a0)
 2d0:	fbe5                	bnez	a5,2c0 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2d2:	0005c503          	lbu	a0,0(a1)
}
 2d6:	40a7853b          	subw	a0,a5,a0
 2da:	6422                	ld	s0,8(sp)
 2dc:	0141                	addi	sp,sp,16
 2de:	8082                	ret

00000000000002e0 <strlen>:

uint
strlen(const char *s)
{
 2e0:	1141                	addi	sp,sp,-16
 2e2:	e422                	sd	s0,8(sp)
 2e4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 2e6:	00054783          	lbu	a5,0(a0)
 2ea:	cf91                	beqz	a5,306 <strlen+0x26>
 2ec:	0505                	addi	a0,a0,1
 2ee:	87aa                	mv	a5,a0
 2f0:	4685                	li	a3,1
 2f2:	9e89                	subw	a3,a3,a0
 2f4:	00f6853b          	addw	a0,a3,a5
 2f8:	0785                	addi	a5,a5,1
 2fa:	fff7c703          	lbu	a4,-1(a5)
 2fe:	fb7d                	bnez	a4,2f4 <strlen+0x14>
    ;
  return n;
}
 300:	6422                	ld	s0,8(sp)
 302:	0141                	addi	sp,sp,16
 304:	8082                	ret
  for(n = 0; s[n]; n++)
 306:	4501                	li	a0,0
 308:	bfe5                	j	300 <strlen+0x20>

000000000000030a <memset>:

void*
memset(void *dst, int c, uint n)
{
 30a:	1141                	addi	sp,sp,-16
 30c:	e422                	sd	s0,8(sp)
 30e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 310:	ce09                	beqz	a2,32a <memset+0x20>
 312:	87aa                	mv	a5,a0
 314:	fff6071b          	addiw	a4,a2,-1
 318:	1702                	slli	a4,a4,0x20
 31a:	9301                	srli	a4,a4,0x20
 31c:	0705                	addi	a4,a4,1
 31e:	972a                	add	a4,a4,a0
    cdst[i] = c;
 320:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 324:	0785                	addi	a5,a5,1
 326:	fee79de3          	bne	a5,a4,320 <memset+0x16>
  }
  return dst;
}
 32a:	6422                	ld	s0,8(sp)
 32c:	0141                	addi	sp,sp,16
 32e:	8082                	ret

0000000000000330 <strchr>:

char*
strchr(const char *s, char c)
{
 330:	1141                	addi	sp,sp,-16
 332:	e422                	sd	s0,8(sp)
 334:	0800                	addi	s0,sp,16
  for(; *s; s++)
 336:	00054783          	lbu	a5,0(a0)
 33a:	cb99                	beqz	a5,350 <strchr+0x20>
    if(*s == c)
 33c:	00f58763          	beq	a1,a5,34a <strchr+0x1a>
  for(; *s; s++)
 340:	0505                	addi	a0,a0,1
 342:	00054783          	lbu	a5,0(a0)
 346:	fbfd                	bnez	a5,33c <strchr+0xc>
      return (char*)s;
  return 0;
 348:	4501                	li	a0,0
}
 34a:	6422                	ld	s0,8(sp)
 34c:	0141                	addi	sp,sp,16
 34e:	8082                	ret
  return 0;
 350:	4501                	li	a0,0
 352:	bfe5                	j	34a <strchr+0x1a>

0000000000000354 <gets>:

char*
gets(char *buf, int max)
{
 354:	711d                	addi	sp,sp,-96
 356:	ec86                	sd	ra,88(sp)
 358:	e8a2                	sd	s0,80(sp)
 35a:	e4a6                	sd	s1,72(sp)
 35c:	e0ca                	sd	s2,64(sp)
 35e:	fc4e                	sd	s3,56(sp)
 360:	f852                	sd	s4,48(sp)
 362:	f456                	sd	s5,40(sp)
 364:	f05a                	sd	s6,32(sp)
 366:	ec5e                	sd	s7,24(sp)
 368:	1080                	addi	s0,sp,96
 36a:	8baa                	mv	s7,a0
 36c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 36e:	892a                	mv	s2,a0
 370:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 372:	4aa9                	li	s5,10
 374:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 376:	89a6                	mv	s3,s1
 378:	2485                	addiw	s1,s1,1
 37a:	0344d863          	bge	s1,s4,3aa <gets+0x56>
    cc = read(0, &c, 1);
 37e:	4605                	li	a2,1
 380:	faf40593          	addi	a1,s0,-81
 384:	4501                	li	a0,0
 386:	00000097          	auipc	ra,0x0
 38a:	1a0080e7          	jalr	416(ra) # 526 <read>
    if(cc < 1)
 38e:	00a05e63          	blez	a0,3aa <gets+0x56>
    buf[i++] = c;
 392:	faf44783          	lbu	a5,-81(s0)
 396:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 39a:	01578763          	beq	a5,s5,3a8 <gets+0x54>
 39e:	0905                	addi	s2,s2,1
 3a0:	fd679be3          	bne	a5,s6,376 <gets+0x22>
  for(i=0; i+1 < max; ){
 3a4:	89a6                	mv	s3,s1
 3a6:	a011                	j	3aa <gets+0x56>
 3a8:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3aa:	99de                	add	s3,s3,s7
 3ac:	00098023          	sb	zero,0(s3) # f4000 <__global_pointer$+0xf2d0f>
  return buf;
}
 3b0:	855e                	mv	a0,s7
 3b2:	60e6                	ld	ra,88(sp)
 3b4:	6446                	ld	s0,80(sp)
 3b6:	64a6                	ld	s1,72(sp)
 3b8:	6906                	ld	s2,64(sp)
 3ba:	79e2                	ld	s3,56(sp)
 3bc:	7a42                	ld	s4,48(sp)
 3be:	7aa2                	ld	s5,40(sp)
 3c0:	7b02                	ld	s6,32(sp)
 3c2:	6be2                	ld	s7,24(sp)
 3c4:	6125                	addi	sp,sp,96
 3c6:	8082                	ret

00000000000003c8 <stat>:

int
stat(const char *n, struct stat *st)
{
 3c8:	1101                	addi	sp,sp,-32
 3ca:	ec06                	sd	ra,24(sp)
 3cc:	e822                	sd	s0,16(sp)
 3ce:	e426                	sd	s1,8(sp)
 3d0:	e04a                	sd	s2,0(sp)
 3d2:	1000                	addi	s0,sp,32
 3d4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3d6:	4581                	li	a1,0
 3d8:	00000097          	auipc	ra,0x0
 3dc:	176080e7          	jalr	374(ra) # 54e <open>
  if(fd < 0)
 3e0:	02054563          	bltz	a0,40a <stat+0x42>
 3e4:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 3e6:	85ca                	mv	a1,s2
 3e8:	00000097          	auipc	ra,0x0
 3ec:	17e080e7          	jalr	382(ra) # 566 <fstat>
 3f0:	892a                	mv	s2,a0
  close(fd);
 3f2:	8526                	mv	a0,s1
 3f4:	00000097          	auipc	ra,0x0
 3f8:	142080e7          	jalr	322(ra) # 536 <close>
  return r;
}
 3fc:	854a                	mv	a0,s2
 3fe:	60e2                	ld	ra,24(sp)
 400:	6442                	ld	s0,16(sp)
 402:	64a2                	ld	s1,8(sp)
 404:	6902                	ld	s2,0(sp)
 406:	6105                	addi	sp,sp,32
 408:	8082                	ret
    return -1;
 40a:	597d                	li	s2,-1
 40c:	bfc5                	j	3fc <stat+0x34>

000000000000040e <atoi>:

int
atoi(const char *s)
{
 40e:	1141                	addi	sp,sp,-16
 410:	e422                	sd	s0,8(sp)
 412:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 414:	00054603          	lbu	a2,0(a0)
 418:	fd06079b          	addiw	a5,a2,-48
 41c:	0ff7f793          	andi	a5,a5,255
 420:	4725                	li	a4,9
 422:	02f76963          	bltu	a4,a5,454 <atoi+0x46>
 426:	86aa                	mv	a3,a0
  n = 0;
 428:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 42a:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 42c:	0685                	addi	a3,a3,1
 42e:	0025179b          	slliw	a5,a0,0x2
 432:	9fa9                	addw	a5,a5,a0
 434:	0017979b          	slliw	a5,a5,0x1
 438:	9fb1                	addw	a5,a5,a2
 43a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 43e:	0006c603          	lbu	a2,0(a3)
 442:	fd06071b          	addiw	a4,a2,-48
 446:	0ff77713          	andi	a4,a4,255
 44a:	fee5f1e3          	bgeu	a1,a4,42c <atoi+0x1e>
  return n;
}
 44e:	6422                	ld	s0,8(sp)
 450:	0141                	addi	sp,sp,16
 452:	8082                	ret
  n = 0;
 454:	4501                	li	a0,0
 456:	bfe5                	j	44e <atoi+0x40>

0000000000000458 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 458:	1141                	addi	sp,sp,-16
 45a:	e422                	sd	s0,8(sp)
 45c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 45e:	02b57663          	bgeu	a0,a1,48a <memmove+0x32>
    while(n-- > 0)
 462:	02c05163          	blez	a2,484 <memmove+0x2c>
 466:	fff6079b          	addiw	a5,a2,-1
 46a:	1782                	slli	a5,a5,0x20
 46c:	9381                	srli	a5,a5,0x20
 46e:	0785                	addi	a5,a5,1
 470:	97aa                	add	a5,a5,a0
  dst = vdst;
 472:	872a                	mv	a4,a0
      *dst++ = *src++;
 474:	0585                	addi	a1,a1,1
 476:	0705                	addi	a4,a4,1
 478:	fff5c683          	lbu	a3,-1(a1)
 47c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 480:	fee79ae3          	bne	a5,a4,474 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 484:	6422                	ld	s0,8(sp)
 486:	0141                	addi	sp,sp,16
 488:	8082                	ret
    dst += n;
 48a:	00c50733          	add	a4,a0,a2
    src += n;
 48e:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 490:	fec05ae3          	blez	a2,484 <memmove+0x2c>
 494:	fff6079b          	addiw	a5,a2,-1
 498:	1782                	slli	a5,a5,0x20
 49a:	9381                	srli	a5,a5,0x20
 49c:	fff7c793          	not	a5,a5
 4a0:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4a2:	15fd                	addi	a1,a1,-1
 4a4:	177d                	addi	a4,a4,-1
 4a6:	0005c683          	lbu	a3,0(a1)
 4aa:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4ae:	fee79ae3          	bne	a5,a4,4a2 <memmove+0x4a>
 4b2:	bfc9                	j	484 <memmove+0x2c>

00000000000004b4 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4b4:	1141                	addi	sp,sp,-16
 4b6:	e422                	sd	s0,8(sp)
 4b8:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4ba:	ca05                	beqz	a2,4ea <memcmp+0x36>
 4bc:	fff6069b          	addiw	a3,a2,-1
 4c0:	1682                	slli	a3,a3,0x20
 4c2:	9281                	srli	a3,a3,0x20
 4c4:	0685                	addi	a3,a3,1
 4c6:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4c8:	00054783          	lbu	a5,0(a0)
 4cc:	0005c703          	lbu	a4,0(a1)
 4d0:	00e79863          	bne	a5,a4,4e0 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4d4:	0505                	addi	a0,a0,1
    p2++;
 4d6:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4d8:	fed518e3          	bne	a0,a3,4c8 <memcmp+0x14>
  }
  return 0;
 4dc:	4501                	li	a0,0
 4de:	a019                	j	4e4 <memcmp+0x30>
      return *p1 - *p2;
 4e0:	40e7853b          	subw	a0,a5,a4
}
 4e4:	6422                	ld	s0,8(sp)
 4e6:	0141                	addi	sp,sp,16
 4e8:	8082                	ret
  return 0;
 4ea:	4501                	li	a0,0
 4ec:	bfe5                	j	4e4 <memcmp+0x30>

00000000000004ee <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4ee:	1141                	addi	sp,sp,-16
 4f0:	e406                	sd	ra,8(sp)
 4f2:	e022                	sd	s0,0(sp)
 4f4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4f6:	00000097          	auipc	ra,0x0
 4fa:	f62080e7          	jalr	-158(ra) # 458 <memmove>
}
 4fe:	60a2                	ld	ra,8(sp)
 500:	6402                	ld	s0,0(sp)
 502:	0141                	addi	sp,sp,16
 504:	8082                	ret

0000000000000506 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 506:	4885                	li	a7,1
 ecall
 508:	00000073          	ecall
 ret
 50c:	8082                	ret

000000000000050e <exit>:
.global exit
exit:
 li a7, SYS_exit
 50e:	4889                	li	a7,2
 ecall
 510:	00000073          	ecall
 ret
 514:	8082                	ret

0000000000000516 <wait>:
.global wait
wait:
 li a7, SYS_wait
 516:	488d                	li	a7,3
 ecall
 518:	00000073          	ecall
 ret
 51c:	8082                	ret

000000000000051e <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 51e:	4891                	li	a7,4
 ecall
 520:	00000073          	ecall
 ret
 524:	8082                	ret

0000000000000526 <read>:
.global read
read:
 li a7, SYS_read
 526:	4895                	li	a7,5
 ecall
 528:	00000073          	ecall
 ret
 52c:	8082                	ret

000000000000052e <write>:
.global write
write:
 li a7, SYS_write
 52e:	48c1                	li	a7,16
 ecall
 530:	00000073          	ecall
 ret
 534:	8082                	ret

0000000000000536 <close>:
.global close
close:
 li a7, SYS_close
 536:	48d5                	li	a7,21
 ecall
 538:	00000073          	ecall
 ret
 53c:	8082                	ret

000000000000053e <kill>:
.global kill
kill:
 li a7, SYS_kill
 53e:	4899                	li	a7,6
 ecall
 540:	00000073          	ecall
 ret
 544:	8082                	ret

0000000000000546 <exec>:
.global exec
exec:
 li a7, SYS_exec
 546:	489d                	li	a7,7
 ecall
 548:	00000073          	ecall
 ret
 54c:	8082                	ret

000000000000054e <open>:
.global open
open:
 li a7, SYS_open
 54e:	48bd                	li	a7,15
 ecall
 550:	00000073          	ecall
 ret
 554:	8082                	ret

0000000000000556 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 556:	48c5                	li	a7,17
 ecall
 558:	00000073          	ecall
 ret
 55c:	8082                	ret

000000000000055e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 55e:	48c9                	li	a7,18
 ecall
 560:	00000073          	ecall
 ret
 564:	8082                	ret

0000000000000566 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 566:	48a1                	li	a7,8
 ecall
 568:	00000073          	ecall
 ret
 56c:	8082                	ret

000000000000056e <link>:
.global link
link:
 li a7, SYS_link
 56e:	48cd                	li	a7,19
 ecall
 570:	00000073          	ecall
 ret
 574:	8082                	ret

0000000000000576 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 576:	48d1                	li	a7,20
 ecall
 578:	00000073          	ecall
 ret
 57c:	8082                	ret

000000000000057e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 57e:	48a5                	li	a7,9
 ecall
 580:	00000073          	ecall
 ret
 584:	8082                	ret

0000000000000586 <dup>:
.global dup
dup:
 li a7, SYS_dup
 586:	48a9                	li	a7,10
 ecall
 588:	00000073          	ecall
 ret
 58c:	8082                	ret

000000000000058e <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 58e:	48ad                	li	a7,11
 ecall
 590:	00000073          	ecall
 ret
 594:	8082                	ret

0000000000000596 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 596:	48b1                	li	a7,12
 ecall
 598:	00000073          	ecall
 ret
 59c:	8082                	ret

000000000000059e <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 59e:	48b5                	li	a7,13
 ecall
 5a0:	00000073          	ecall
 ret
 5a4:	8082                	ret

00000000000005a6 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5a6:	48b9                	li	a7,14
 ecall
 5a8:	00000073          	ecall
 ret
 5ac:	8082                	ret

00000000000005ae <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 5ae:	48d9                	li	a7,22
 ecall
 5b0:	00000073          	ecall
 ret
 5b4:	8082                	ret

00000000000005b6 <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 5b6:	48dd                	li	a7,23
 ecall
 5b8:	00000073          	ecall
 ret
 5bc:	8082                	ret

00000000000005be <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 5be:	48e1                	li	a7,24
 ecall
 5c0:	00000073          	ecall
 ret
 5c4:	8082                	ret

00000000000005c6 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5c6:	1101                	addi	sp,sp,-32
 5c8:	ec06                	sd	ra,24(sp)
 5ca:	e822                	sd	s0,16(sp)
 5cc:	1000                	addi	s0,sp,32
 5ce:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5d2:	4605                	li	a2,1
 5d4:	fef40593          	addi	a1,s0,-17
 5d8:	00000097          	auipc	ra,0x0
 5dc:	f56080e7          	jalr	-170(ra) # 52e <write>
}
 5e0:	60e2                	ld	ra,24(sp)
 5e2:	6442                	ld	s0,16(sp)
 5e4:	6105                	addi	sp,sp,32
 5e6:	8082                	ret

00000000000005e8 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 5e8:	7139                	addi	sp,sp,-64
 5ea:	fc06                	sd	ra,56(sp)
 5ec:	f822                	sd	s0,48(sp)
 5ee:	f426                	sd	s1,40(sp)
 5f0:	f04a                	sd	s2,32(sp)
 5f2:	ec4e                	sd	s3,24(sp)
 5f4:	0080                	addi	s0,sp,64
 5f6:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5f8:	c299                	beqz	a3,5fe <printint+0x16>
 5fa:	0805c863          	bltz	a1,68a <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5fe:	2581                	sext.w	a1,a1
  neg = 0;
 600:	4881                	li	a7,0
 602:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 606:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 608:	2601                	sext.w	a2,a2
 60a:	00000517          	auipc	a0,0x0
 60e:	4d650513          	addi	a0,a0,1238 # ae0 <digits>
 612:	883a                	mv	a6,a4
 614:	2705                	addiw	a4,a4,1
 616:	02c5f7bb          	remuw	a5,a1,a2
 61a:	1782                	slli	a5,a5,0x20
 61c:	9381                	srli	a5,a5,0x20
 61e:	97aa                	add	a5,a5,a0
 620:	0007c783          	lbu	a5,0(a5)
 624:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 628:	0005879b          	sext.w	a5,a1
 62c:	02c5d5bb          	divuw	a1,a1,a2
 630:	0685                	addi	a3,a3,1
 632:	fec7f0e3          	bgeu	a5,a2,612 <printint+0x2a>
  if(neg)
 636:	00088b63          	beqz	a7,64c <printint+0x64>
    buf[i++] = '-';
 63a:	fd040793          	addi	a5,s0,-48
 63e:	973e                	add	a4,a4,a5
 640:	02d00793          	li	a5,45
 644:	fef70823          	sb	a5,-16(a4)
 648:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 64c:	02e05863          	blez	a4,67c <printint+0x94>
 650:	fc040793          	addi	a5,s0,-64
 654:	00e78933          	add	s2,a5,a4
 658:	fff78993          	addi	s3,a5,-1
 65c:	99ba                	add	s3,s3,a4
 65e:	377d                	addiw	a4,a4,-1
 660:	1702                	slli	a4,a4,0x20
 662:	9301                	srli	a4,a4,0x20
 664:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 668:	fff94583          	lbu	a1,-1(s2)
 66c:	8526                	mv	a0,s1
 66e:	00000097          	auipc	ra,0x0
 672:	f58080e7          	jalr	-168(ra) # 5c6 <putc>
  while(--i >= 0)
 676:	197d                	addi	s2,s2,-1
 678:	ff3918e3          	bne	s2,s3,668 <printint+0x80>
}
 67c:	70e2                	ld	ra,56(sp)
 67e:	7442                	ld	s0,48(sp)
 680:	74a2                	ld	s1,40(sp)
 682:	7902                	ld	s2,32(sp)
 684:	69e2                	ld	s3,24(sp)
 686:	6121                	addi	sp,sp,64
 688:	8082                	ret
    x = -xx;
 68a:	40b005bb          	negw	a1,a1
    neg = 1;
 68e:	4885                	li	a7,1
    x = -xx;
 690:	bf8d                	j	602 <printint+0x1a>

0000000000000692 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 692:	7119                	addi	sp,sp,-128
 694:	fc86                	sd	ra,120(sp)
 696:	f8a2                	sd	s0,112(sp)
 698:	f4a6                	sd	s1,104(sp)
 69a:	f0ca                	sd	s2,96(sp)
 69c:	ecce                	sd	s3,88(sp)
 69e:	e8d2                	sd	s4,80(sp)
 6a0:	e4d6                	sd	s5,72(sp)
 6a2:	e0da                	sd	s6,64(sp)
 6a4:	fc5e                	sd	s7,56(sp)
 6a6:	f862                	sd	s8,48(sp)
 6a8:	f466                	sd	s9,40(sp)
 6aa:	f06a                	sd	s10,32(sp)
 6ac:	ec6e                	sd	s11,24(sp)
 6ae:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6b0:	0005c903          	lbu	s2,0(a1)
 6b4:	18090f63          	beqz	s2,852 <vprintf+0x1c0>
 6b8:	8aaa                	mv	s5,a0
 6ba:	8b32                	mv	s6,a2
 6bc:	00158493          	addi	s1,a1,1
  state = 0;
 6c0:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6c2:	02500a13          	li	s4,37
      if(c == 'd'){
 6c6:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6ca:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6ce:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6d2:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6d6:	00000b97          	auipc	s7,0x0
 6da:	40ab8b93          	addi	s7,s7,1034 # ae0 <digits>
 6de:	a839                	j	6fc <vprintf+0x6a>
        putc(fd, c);
 6e0:	85ca                	mv	a1,s2
 6e2:	8556                	mv	a0,s5
 6e4:	00000097          	auipc	ra,0x0
 6e8:	ee2080e7          	jalr	-286(ra) # 5c6 <putc>
 6ec:	a019                	j	6f2 <vprintf+0x60>
    } else if(state == '%'){
 6ee:	01498f63          	beq	s3,s4,70c <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6f2:	0485                	addi	s1,s1,1
 6f4:	fff4c903          	lbu	s2,-1(s1)
 6f8:	14090d63          	beqz	s2,852 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 6fc:	0009079b          	sext.w	a5,s2
    if(state == 0){
 700:	fe0997e3          	bnez	s3,6ee <vprintf+0x5c>
      if(c == '%'){
 704:	fd479ee3          	bne	a5,s4,6e0 <vprintf+0x4e>
        state = '%';
 708:	89be                	mv	s3,a5
 70a:	b7e5                	j	6f2 <vprintf+0x60>
      if(c == 'd'){
 70c:	05878063          	beq	a5,s8,74c <vprintf+0xba>
      } else if(c == 'l') {
 710:	05978c63          	beq	a5,s9,768 <vprintf+0xd6>
      } else if(c == 'x') {
 714:	07a78863          	beq	a5,s10,784 <vprintf+0xf2>
      } else if(c == 'p') {
 718:	09b78463          	beq	a5,s11,7a0 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 71c:	07300713          	li	a4,115
 720:	0ce78663          	beq	a5,a4,7ec <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 724:	06300713          	li	a4,99
 728:	0ee78e63          	beq	a5,a4,824 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 72c:	11478863          	beq	a5,s4,83c <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 730:	85d2                	mv	a1,s4
 732:	8556                	mv	a0,s5
 734:	00000097          	auipc	ra,0x0
 738:	e92080e7          	jalr	-366(ra) # 5c6 <putc>
        putc(fd, c);
 73c:	85ca                	mv	a1,s2
 73e:	8556                	mv	a0,s5
 740:	00000097          	auipc	ra,0x0
 744:	e86080e7          	jalr	-378(ra) # 5c6 <putc>
      }
      state = 0;
 748:	4981                	li	s3,0
 74a:	b765                	j	6f2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 74c:	008b0913          	addi	s2,s6,8
 750:	4685                	li	a3,1
 752:	4629                	li	a2,10
 754:	000b2583          	lw	a1,0(s6)
 758:	8556                	mv	a0,s5
 75a:	00000097          	auipc	ra,0x0
 75e:	e8e080e7          	jalr	-370(ra) # 5e8 <printint>
 762:	8b4a                	mv	s6,s2
      state = 0;
 764:	4981                	li	s3,0
 766:	b771                	j	6f2 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 768:	008b0913          	addi	s2,s6,8
 76c:	4681                	li	a3,0
 76e:	4629                	li	a2,10
 770:	000b2583          	lw	a1,0(s6)
 774:	8556                	mv	a0,s5
 776:	00000097          	auipc	ra,0x0
 77a:	e72080e7          	jalr	-398(ra) # 5e8 <printint>
 77e:	8b4a                	mv	s6,s2
      state = 0;
 780:	4981                	li	s3,0
 782:	bf85                	j	6f2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 784:	008b0913          	addi	s2,s6,8
 788:	4681                	li	a3,0
 78a:	4641                	li	a2,16
 78c:	000b2583          	lw	a1,0(s6)
 790:	8556                	mv	a0,s5
 792:	00000097          	auipc	ra,0x0
 796:	e56080e7          	jalr	-426(ra) # 5e8 <printint>
 79a:	8b4a                	mv	s6,s2
      state = 0;
 79c:	4981                	li	s3,0
 79e:	bf91                	j	6f2 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7a0:	008b0793          	addi	a5,s6,8
 7a4:	f8f43423          	sd	a5,-120(s0)
 7a8:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7ac:	03000593          	li	a1,48
 7b0:	8556                	mv	a0,s5
 7b2:	00000097          	auipc	ra,0x0
 7b6:	e14080e7          	jalr	-492(ra) # 5c6 <putc>
  putc(fd, 'x');
 7ba:	85ea                	mv	a1,s10
 7bc:	8556                	mv	a0,s5
 7be:	00000097          	auipc	ra,0x0
 7c2:	e08080e7          	jalr	-504(ra) # 5c6 <putc>
 7c6:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7c8:	03c9d793          	srli	a5,s3,0x3c
 7cc:	97de                	add	a5,a5,s7
 7ce:	0007c583          	lbu	a1,0(a5)
 7d2:	8556                	mv	a0,s5
 7d4:	00000097          	auipc	ra,0x0
 7d8:	df2080e7          	jalr	-526(ra) # 5c6 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7dc:	0992                	slli	s3,s3,0x4
 7de:	397d                	addiw	s2,s2,-1
 7e0:	fe0914e3          	bnez	s2,7c8 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 7e4:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 7e8:	4981                	li	s3,0
 7ea:	b721                	j	6f2 <vprintf+0x60>
        s = va_arg(ap, char*);
 7ec:	008b0993          	addi	s3,s6,8
 7f0:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 7f4:	02090163          	beqz	s2,816 <vprintf+0x184>
        while(*s != 0){
 7f8:	00094583          	lbu	a1,0(s2)
 7fc:	c9a1                	beqz	a1,84c <vprintf+0x1ba>
          putc(fd, *s);
 7fe:	8556                	mv	a0,s5
 800:	00000097          	auipc	ra,0x0
 804:	dc6080e7          	jalr	-570(ra) # 5c6 <putc>
          s++;
 808:	0905                	addi	s2,s2,1
        while(*s != 0){
 80a:	00094583          	lbu	a1,0(s2)
 80e:	f9e5                	bnez	a1,7fe <vprintf+0x16c>
        s = va_arg(ap, char*);
 810:	8b4e                	mv	s6,s3
      state = 0;
 812:	4981                	li	s3,0
 814:	bdf9                	j	6f2 <vprintf+0x60>
          s = "(null)";
 816:	00000917          	auipc	s2,0x0
 81a:	2c290913          	addi	s2,s2,706 # ad8 <malloc+0x17c>
        while(*s != 0){
 81e:	02800593          	li	a1,40
 822:	bff1                	j	7fe <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 824:	008b0913          	addi	s2,s6,8
 828:	000b4583          	lbu	a1,0(s6)
 82c:	8556                	mv	a0,s5
 82e:	00000097          	auipc	ra,0x0
 832:	d98080e7          	jalr	-616(ra) # 5c6 <putc>
 836:	8b4a                	mv	s6,s2
      state = 0;
 838:	4981                	li	s3,0
 83a:	bd65                	j	6f2 <vprintf+0x60>
        putc(fd, c);
 83c:	85d2                	mv	a1,s4
 83e:	8556                	mv	a0,s5
 840:	00000097          	auipc	ra,0x0
 844:	d86080e7          	jalr	-634(ra) # 5c6 <putc>
      state = 0;
 848:	4981                	li	s3,0
 84a:	b565                	j	6f2 <vprintf+0x60>
        s = va_arg(ap, char*);
 84c:	8b4e                	mv	s6,s3
      state = 0;
 84e:	4981                	li	s3,0
 850:	b54d                	j	6f2 <vprintf+0x60>
    }
  }
}
 852:	70e6                	ld	ra,120(sp)
 854:	7446                	ld	s0,112(sp)
 856:	74a6                	ld	s1,104(sp)
 858:	7906                	ld	s2,96(sp)
 85a:	69e6                	ld	s3,88(sp)
 85c:	6a46                	ld	s4,80(sp)
 85e:	6aa6                	ld	s5,72(sp)
 860:	6b06                	ld	s6,64(sp)
 862:	7be2                	ld	s7,56(sp)
 864:	7c42                	ld	s8,48(sp)
 866:	7ca2                	ld	s9,40(sp)
 868:	7d02                	ld	s10,32(sp)
 86a:	6de2                	ld	s11,24(sp)
 86c:	6109                	addi	sp,sp,128
 86e:	8082                	ret

0000000000000870 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 870:	715d                	addi	sp,sp,-80
 872:	ec06                	sd	ra,24(sp)
 874:	e822                	sd	s0,16(sp)
 876:	1000                	addi	s0,sp,32
 878:	e010                	sd	a2,0(s0)
 87a:	e414                	sd	a3,8(s0)
 87c:	e818                	sd	a4,16(s0)
 87e:	ec1c                	sd	a5,24(s0)
 880:	03043023          	sd	a6,32(s0)
 884:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 888:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 88c:	8622                	mv	a2,s0
 88e:	00000097          	auipc	ra,0x0
 892:	e04080e7          	jalr	-508(ra) # 692 <vprintf>
}
 896:	60e2                	ld	ra,24(sp)
 898:	6442                	ld	s0,16(sp)
 89a:	6161                	addi	sp,sp,80
 89c:	8082                	ret

000000000000089e <printf>:

void
printf(const char *fmt, ...)
{
 89e:	711d                	addi	sp,sp,-96
 8a0:	ec06                	sd	ra,24(sp)
 8a2:	e822                	sd	s0,16(sp)
 8a4:	1000                	addi	s0,sp,32
 8a6:	e40c                	sd	a1,8(s0)
 8a8:	e810                	sd	a2,16(s0)
 8aa:	ec14                	sd	a3,24(s0)
 8ac:	f018                	sd	a4,32(s0)
 8ae:	f41c                	sd	a5,40(s0)
 8b0:	03043823          	sd	a6,48(s0)
 8b4:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8b8:	00840613          	addi	a2,s0,8
 8bc:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8c0:	85aa                	mv	a1,a0
 8c2:	4505                	li	a0,1
 8c4:	00000097          	auipc	ra,0x0
 8c8:	dce080e7          	jalr	-562(ra) # 692 <vprintf>
}
 8cc:	60e2                	ld	ra,24(sp)
 8ce:	6442                	ld	s0,16(sp)
 8d0:	6125                	addi	sp,sp,96
 8d2:	8082                	ret

00000000000008d4 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8d4:	1141                	addi	sp,sp,-16
 8d6:	e422                	sd	s0,8(sp)
 8d8:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8da:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8de:	00000797          	auipc	a5,0x0
 8e2:	21a7b783          	ld	a5,538(a5) # af8 <freep>
 8e6:	a805                	j	916 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 8e8:	4618                	lw	a4,8(a2)
 8ea:	9db9                	addw	a1,a1,a4
 8ec:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 8f0:	6398                	ld	a4,0(a5)
 8f2:	6318                	ld	a4,0(a4)
 8f4:	fee53823          	sd	a4,-16(a0)
 8f8:	a091                	j	93c <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8fa:	ff852703          	lw	a4,-8(a0)
 8fe:	9e39                	addw	a2,a2,a4
 900:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 902:	ff053703          	ld	a4,-16(a0)
 906:	e398                	sd	a4,0(a5)
 908:	a099                	j	94e <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 90a:	6398                	ld	a4,0(a5)
 90c:	00e7e463          	bltu	a5,a4,914 <free+0x40>
 910:	00e6ea63          	bltu	a3,a4,924 <free+0x50>
{
 914:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 916:	fed7fae3          	bgeu	a5,a3,90a <free+0x36>
 91a:	6398                	ld	a4,0(a5)
 91c:	00e6e463          	bltu	a3,a4,924 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 920:	fee7eae3          	bltu	a5,a4,914 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 924:	ff852583          	lw	a1,-8(a0)
 928:	6390                	ld	a2,0(a5)
 92a:	02059713          	slli	a4,a1,0x20
 92e:	9301                	srli	a4,a4,0x20
 930:	0712                	slli	a4,a4,0x4
 932:	9736                	add	a4,a4,a3
 934:	fae60ae3          	beq	a2,a4,8e8 <free+0x14>
    bp->s.ptr = p->s.ptr;
 938:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 93c:	4790                	lw	a2,8(a5)
 93e:	02061713          	slli	a4,a2,0x20
 942:	9301                	srli	a4,a4,0x20
 944:	0712                	slli	a4,a4,0x4
 946:	973e                	add	a4,a4,a5
 948:	fae689e3          	beq	a3,a4,8fa <free+0x26>
  } else
    p->s.ptr = bp;
 94c:	e394                	sd	a3,0(a5)
  freep = p;
 94e:	00000717          	auipc	a4,0x0
 952:	1af73523          	sd	a5,426(a4) # af8 <freep>
}
 956:	6422                	ld	s0,8(sp)
 958:	0141                	addi	sp,sp,16
 95a:	8082                	ret

000000000000095c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 95c:	7139                	addi	sp,sp,-64
 95e:	fc06                	sd	ra,56(sp)
 960:	f822                	sd	s0,48(sp)
 962:	f426                	sd	s1,40(sp)
 964:	f04a                	sd	s2,32(sp)
 966:	ec4e                	sd	s3,24(sp)
 968:	e852                	sd	s4,16(sp)
 96a:	e456                	sd	s5,8(sp)
 96c:	e05a                	sd	s6,0(sp)
 96e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 970:	02051493          	slli	s1,a0,0x20
 974:	9081                	srli	s1,s1,0x20
 976:	04bd                	addi	s1,s1,15
 978:	8091                	srli	s1,s1,0x4
 97a:	0014899b          	addiw	s3,s1,1
 97e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 980:	00000517          	auipc	a0,0x0
 984:	17853503          	ld	a0,376(a0) # af8 <freep>
 988:	c515                	beqz	a0,9b4 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 98a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 98c:	4798                	lw	a4,8(a5)
 98e:	02977f63          	bgeu	a4,s1,9cc <malloc+0x70>
 992:	8a4e                	mv	s4,s3
 994:	0009871b          	sext.w	a4,s3
 998:	6685                	lui	a3,0x1
 99a:	00d77363          	bgeu	a4,a3,9a0 <malloc+0x44>
 99e:	6a05                	lui	s4,0x1
 9a0:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9a4:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9a8:	00000917          	auipc	s2,0x0
 9ac:	15090913          	addi	s2,s2,336 # af8 <freep>
  if(p == (char*)-1)
 9b0:	5afd                	li	s5,-1
 9b2:	a88d                	j	a24 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 9b4:	00000797          	auipc	a5,0x0
 9b8:	14c78793          	addi	a5,a5,332 # b00 <base>
 9bc:	00000717          	auipc	a4,0x0
 9c0:	12f73e23          	sd	a5,316(a4) # af8 <freep>
 9c4:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9c6:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9ca:	b7e1                	j	992 <malloc+0x36>
      if(p->s.size == nunits)
 9cc:	02e48b63          	beq	s1,a4,a02 <malloc+0xa6>
        p->s.size -= nunits;
 9d0:	4137073b          	subw	a4,a4,s3
 9d4:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9d6:	1702                	slli	a4,a4,0x20
 9d8:	9301                	srli	a4,a4,0x20
 9da:	0712                	slli	a4,a4,0x4
 9dc:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9de:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9e2:	00000717          	auipc	a4,0x0
 9e6:	10a73b23          	sd	a0,278(a4) # af8 <freep>
      return (void*)(p + 1);
 9ea:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 9ee:	70e2                	ld	ra,56(sp)
 9f0:	7442                	ld	s0,48(sp)
 9f2:	74a2                	ld	s1,40(sp)
 9f4:	7902                	ld	s2,32(sp)
 9f6:	69e2                	ld	s3,24(sp)
 9f8:	6a42                	ld	s4,16(sp)
 9fa:	6aa2                	ld	s5,8(sp)
 9fc:	6b02                	ld	s6,0(sp)
 9fe:	6121                	addi	sp,sp,64
 a00:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a02:	6398                	ld	a4,0(a5)
 a04:	e118                	sd	a4,0(a0)
 a06:	bff1                	j	9e2 <malloc+0x86>
  hp->s.size = nu;
 a08:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a0c:	0541                	addi	a0,a0,16
 a0e:	00000097          	auipc	ra,0x0
 a12:	ec6080e7          	jalr	-314(ra) # 8d4 <free>
  return freep;
 a16:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a1a:	d971                	beqz	a0,9ee <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a1c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a1e:	4798                	lw	a4,8(a5)
 a20:	fa9776e3          	bgeu	a4,s1,9cc <malloc+0x70>
    if(p == freep)
 a24:	00093703          	ld	a4,0(s2)
 a28:	853e                	mv	a0,a5
 a2a:	fef719e3          	bne	a4,a5,a1c <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a2e:	8552                	mv	a0,s4
 a30:	00000097          	auipc	ra,0x0
 a34:	b66080e7          	jalr	-1178(ra) # 596 <sbrk>
  if(p == (char*)-1)
 a38:	fd5518e3          	bne	a0,s5,a08 <malloc+0xac>
        return 0;
 a3c:	4501                	li	a0,0
 a3e:	bf45                	j	9ee <malloc+0x92>
