
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
  20:	596080e7          	jalr	1430(ra) # 5b2 <getpid>
  24:	8aaa                	mv	s5,a0
    while(i--)
        fork();
  26:	00000097          	auipc	ra,0x0
  2a:	504080e7          	jalr	1284(ra) # 52a <fork>
  2e:	00000097          	auipc	ra,0x0
  32:	4fc080e7          	jalr	1276(ra) # 52a <fork>
    const uint m = (loop_size >> 1);
    for (int i = 0; i < loop_size; i++) {
  36:	05205663          	blez	s2,82 <pause_system_dem+0x82>
  3a:	40195a1b          	sraiw	s4,s2,0x1
  3e:	4481                	li	s1,0
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
  40:	00001b97          	auipc	s7,0x1
  44:	a28b8b93          	addi	s7,s7,-1496 # a68 <malloc+0xe8>
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
  5e:	558080e7          	jalr	1368(ra) # 5b2 <getpid>
  62:	ff5514e3          	bne	a0,s5,4a <pause_system_dem+0x4a>
            printf("pause system %d/%d completed.\n", i, loop_size);
  66:	864a                	mv	a2,s2
  68:	85a6                	mv	a1,s1
  6a:	855e                	mv	a0,s7
  6c:	00001097          	auipc	ra,0x1
  70:	856080e7          	jalr	-1962(ra) # 8c2 <printf>
  74:	bfd9                	j	4a <pause_system_dem+0x4a>
            pause_system(pause_seconds);
  76:	855a                	mv	a0,s6
  78:	00000097          	auipc	ra,0x0
  7c:	55a080e7          	jalr	1370(ra) # 5d2 <pause_system>
  80:	b7f9                	j	4e <pause_system_dem+0x4e>
        }
    }
    printf("\n");
  82:	00001517          	auipc	a0,0x1
  86:	a0650513          	addi	a0,a0,-1530 # a88 <malloc+0x108>
  8a:	00001097          	auipc	ra,0x1
  8e:	838080e7          	jalr	-1992(ra) # 8c2 <printf>
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
  c4:	4f2080e7          	jalr	1266(ra) # 5b2 <getpid>
  c8:	8aaa                	mv	s5,a0
    while(i--)
        fork();
  ca:	00000097          	auipc	ra,0x0
  ce:	460080e7          	jalr	1120(ra) # 52a <fork>
  d2:	00000097          	auipc	ra,0x0
  d6:	458080e7          	jalr	1112(ra) # 52a <fork>
    const uint m = (loop_size >> 1);
    for (int i = 0; i < loop_size; i++) {
  da:	05205563          	blez	s2,124 <kill_system_dem+0x7c>
  de:	40195a1b          	sraiw	s4,s2,0x1
  e2:	4481                	li	s1,0
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
  e4:	00001b17          	auipc	s6,0x1
  e8:	9acb0b13          	addi	s6,s6,-1620 # a90 <malloc+0x110>
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
 102:	4b4080e7          	jalr	1204(ra) # 5b2 <getpid>
 106:	ff5514e3          	bne	a0,s5,ee <kill_system_dem+0x46>
            printf("kill system %d/%d completed.\n", i, loop_size);
 10a:	864a                	mv	a2,s2
 10c:	85a6                	mv	a1,s1
 10e:	855a                	mv	a0,s6
 110:	00000097          	auipc	ra,0x0
 114:	7b2080e7          	jalr	1970(ra) # 8c2 <printf>
 118:	bfd9                	j	ee <kill_system_dem+0x46>
            kill_system();
 11a:	00000097          	auipc	ra,0x0
 11e:	4c0080e7          	jalr	1216(ra) # 5da <kill_system>
 122:	bfc1                	j	f2 <kill_system_dem+0x4a>
        }
    }
    printf("\n");
 124:	00001517          	auipc	a0,0x1
 128:	96450513          	addi	a0,a0,-1692 # a88 <malloc+0x108>
 12c:	00000097          	auipc	ra,0x0
 130:	796080e7          	jalr	1942(ra) # 8c2 <printf>
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
 160:	8bb2                	mv	s7,a2
    int result = 1;
    int loop_size = 1000000;
    int n_forks = 2;
    int pid;
    for (int i = 0; i < n_forks; i++) {
        pid = fork();
 162:	00000097          	auipc	ra,0x0
 166:	3c8080e7          	jalr	968(ra) # 52a <fork>
 16a:	85aa                	mv	a1,a0
        printf("pid: %d", pid);
 16c:	00001517          	auipc	a0,0x1
 170:	94450513          	addi	a0,a0,-1724 # ab0 <malloc+0x130>
 174:	00000097          	auipc	ra,0x0
 178:	74e080e7          	jalr	1870(ra) # 8c2 <printf>
        pid = fork();
 17c:	00000097          	auipc	ra,0x0
 180:	3ae080e7          	jalr	942(ra) # 52a <fork>
 184:	8a2a                	mv	s4,a0
        printf("pid: %d", pid);
 186:	85aa                	mv	a1,a0
 188:	00001517          	auipc	a0,0x1
 18c:	92850513          	addi	a0,a0,-1752 # ab0 <malloc+0x130>
 190:	00000097          	auipc	ra,0x0
 194:	732080e7          	jalr	1842(ra) # 8c2 <printf>
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
 1a6:	92ea8a93          	addi	s5,s5,-1746 # ad0 <malloc+0x150>
        		printf("%s %d/%d completed.\n", env_name, i, loop_size);
 1aa:	000f4937          	lui	s2,0xf4
 1ae:	24090913          	addi	s2,s2,576 # f4240 <__global_pointer$+0xf2f0f>
 1b2:	00001c17          	auipc	s8,0x1
 1b6:	906c0c13          	addi	s8,s8,-1786 # ab8 <malloc+0x138>
 1ba:	00950b37          	lui	s6,0x950
 1be:	2f9b0b13          	addi	s6,s6,761 # 9502f9 <__global_pointer$+0x94efc8>
 1c2:	a005                	j	1e2 <env+0x9a>
 1c4:	86ca                	mv	a3,s2
 1c6:	8626                	mv	a2,s1
 1c8:	85de                	mv	a1,s7
 1ca:	8562                	mv	a0,s8
 1cc:	00000097          	auipc	ra,0x0
 1d0:	6f6080e7          	jalr	1782(ra) # 8c2 <printf>
 1d4:	00bb1793          	slli	a5,s6,0xb
                for(long i = 0; i < 20000000000; i++){
 1d8:	17fd                	addi	a5,a5,-1
 1da:	fffd                	bnez	a5,1d8 <env+0x90>
    for (int i = 0; i < loop_size; i++) {
 1dc:	2485                	addiw	s1,s1,1
 1de:	03248363          	beq	s1,s2,204 <env+0xbc>
        if (i % loop_size / 1 == 0) {
 1e2:	0334e7bb          	remw	a5,s1,s3
 1e6:	fbfd                	bnez	a5,1dc <env+0x94>
        	if (pid == 0) {
 1e8:	fc0a0ee3          	beqz	s4,1c4 <env+0x7c>
                wait(&res);
 1ec:	fac40513          	addi	a0,s0,-84
 1f0:	00000097          	auipc	ra,0x0
 1f4:	34a080e7          	jalr	842(ra) # 53a <wait>
        		printf(" ");
 1f8:	8556                	mv	a0,s5
 1fa:	00000097          	auipc	ra,0x0
 1fe:	6c8080e7          	jalr	1736(ra) # 8c2 <printf>
 202:	bfe9                	j	1dc <env+0x94>
        }
        if (i % interval == 0) {
            result = result * size;
        }
    }
    printf("\n");
 204:	00001517          	auipc	a0,0x1
 208:	88450513          	addi	a0,a0,-1916 # a88 <malloc+0x108>
 20c:	00000097          	auipc	ra,0x0
 210:	6b6080e7          	jalr	1718(ra) # 8c2 <printf>
}
 214:	60e6                	ld	ra,88(sp)
 216:	6446                	ld	s0,80(sp)
 218:	64a6                	ld	s1,72(sp)
 21a:	6906                	ld	s2,64(sp)
 21c:	79e2                	ld	s3,56(sp)
 21e:	7a42                	ld	s4,48(sp)
 220:	7aa2                	ld	s5,40(sp)
 222:	7b02                	ld	s6,32(sp)
 224:	6be2                	ld	s7,24(sp)
 226:	6c42                	ld	s8,16(sp)
 228:	6125                	addi	sp,sp,96
 22a:	8082                	ret

000000000000022c <env_large>:

void env_large() {
 22c:	1141                	addi	sp,sp,-16
 22e:	e406                	sd	ra,8(sp)
 230:	e022                	sd	s0,0(sp)
 232:	0800                	addi	s0,sp,16
    env(1000000, 1000000, "env_large");
 234:	00001617          	auipc	a2,0x1
 238:	8a460613          	addi	a2,a2,-1884 # ad8 <malloc+0x158>
 23c:	000f45b7          	lui	a1,0xf4
 240:	24058593          	addi	a1,a1,576 # f4240 <__global_pointer$+0xf2f0f>
 244:	852e                	mv	a0,a1
 246:	00000097          	auipc	ra,0x0
 24a:	f02080e7          	jalr	-254(ra) # 148 <env>
}
 24e:	60a2                	ld	ra,8(sp)
 250:	6402                	ld	s0,0(sp)
 252:	0141                	addi	sp,sp,16
 254:	8082                	ret

0000000000000256 <env_freq>:

void env_freq() {
 256:	1141                	addi	sp,sp,-16
 258:	e406                	sd	ra,8(sp)
 25a:	e022                	sd	s0,0(sp)
 25c:	0800                	addi	s0,sp,16
    env(10, 10, "env_freq");
 25e:	00001617          	auipc	a2,0x1
 262:	88a60613          	addi	a2,a2,-1910 # ae8 <malloc+0x168>
 266:	45a9                	li	a1,10
 268:	4529                	li	a0,10
 26a:	00000097          	auipc	ra,0x0
 26e:	ede080e7          	jalr	-290(ra) # 148 <env>
}
 272:	60a2                	ld	ra,8(sp)
 274:	6402                	ld	s0,0(sp)
 276:	0141                	addi	sp,sp,16
 278:	8082                	ret

000000000000027a <main>:

int
main(int argc, char *argv[])
{
 27a:	1141                	addi	sp,sp,-16
 27c:	e406                	sd	ra,8(sp)
 27e:	e022                	sd	s0,0(sp)
 280:	0800                	addi	s0,sp,16
    //set_economic_mode_dem(10, 100);
    //pause_system_dem(10, 10, 100);
    //kill_system_dem(10, 100);
    env_large();
 282:	00000097          	auipc	ra,0x0
 286:	faa080e7          	jalr	-86(ra) # 22c <env_large>
    print_stats();
 28a:	00000097          	auipc	ra,0x0
 28e:	358080e7          	jalr	856(ra) # 5e2 <print_stats>
    printf("******************************\n");
 292:	00001517          	auipc	a0,0x1
 296:	86650513          	addi	a0,a0,-1946 # af8 <malloc+0x178>
 29a:	00000097          	auipc	ra,0x0
 29e:	628080e7          	jalr	1576(ra) # 8c2 <printf>
    env_freq();
 2a2:	00000097          	auipc	ra,0x0
 2a6:	fb4080e7          	jalr	-76(ra) # 256 <env_freq>
    print_stats();
 2aa:	00000097          	auipc	ra,0x0
 2ae:	338080e7          	jalr	824(ra) # 5e2 <print_stats>
    exit(0);
 2b2:	4501                	li	a0,0
 2b4:	00000097          	auipc	ra,0x0
 2b8:	27e080e7          	jalr	638(ra) # 532 <exit>

00000000000002bc <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 2bc:	1141                	addi	sp,sp,-16
 2be:	e422                	sd	s0,8(sp)
 2c0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2c2:	87aa                	mv	a5,a0
 2c4:	0585                	addi	a1,a1,1
 2c6:	0785                	addi	a5,a5,1
 2c8:	fff5c703          	lbu	a4,-1(a1)
 2cc:	fee78fa3          	sb	a4,-1(a5)
 2d0:	fb75                	bnez	a4,2c4 <strcpy+0x8>
    ;
  return os;
}
 2d2:	6422                	ld	s0,8(sp)
 2d4:	0141                	addi	sp,sp,16
 2d6:	8082                	ret

00000000000002d8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2d8:	1141                	addi	sp,sp,-16
 2da:	e422                	sd	s0,8(sp)
 2dc:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2de:	00054783          	lbu	a5,0(a0)
 2e2:	cb91                	beqz	a5,2f6 <strcmp+0x1e>
 2e4:	0005c703          	lbu	a4,0(a1)
 2e8:	00f71763          	bne	a4,a5,2f6 <strcmp+0x1e>
    p++, q++;
 2ec:	0505                	addi	a0,a0,1
 2ee:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2f0:	00054783          	lbu	a5,0(a0)
 2f4:	fbe5                	bnez	a5,2e4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 2f6:	0005c503          	lbu	a0,0(a1)
}
 2fa:	40a7853b          	subw	a0,a5,a0
 2fe:	6422                	ld	s0,8(sp)
 300:	0141                	addi	sp,sp,16
 302:	8082                	ret

0000000000000304 <strlen>:

uint
strlen(const char *s)
{
 304:	1141                	addi	sp,sp,-16
 306:	e422                	sd	s0,8(sp)
 308:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 30a:	00054783          	lbu	a5,0(a0)
 30e:	cf91                	beqz	a5,32a <strlen+0x26>
 310:	0505                	addi	a0,a0,1
 312:	87aa                	mv	a5,a0
 314:	4685                	li	a3,1
 316:	9e89                	subw	a3,a3,a0
 318:	00f6853b          	addw	a0,a3,a5
 31c:	0785                	addi	a5,a5,1
 31e:	fff7c703          	lbu	a4,-1(a5)
 322:	fb7d                	bnez	a4,318 <strlen+0x14>
    ;
  return n;
}
 324:	6422                	ld	s0,8(sp)
 326:	0141                	addi	sp,sp,16
 328:	8082                	ret
  for(n = 0; s[n]; n++)
 32a:	4501                	li	a0,0
 32c:	bfe5                	j	324 <strlen+0x20>

000000000000032e <memset>:

void*
memset(void *dst, int c, uint n)
{
 32e:	1141                	addi	sp,sp,-16
 330:	e422                	sd	s0,8(sp)
 332:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 334:	ce09                	beqz	a2,34e <memset+0x20>
 336:	87aa                	mv	a5,a0
 338:	fff6071b          	addiw	a4,a2,-1
 33c:	1702                	slli	a4,a4,0x20
 33e:	9301                	srli	a4,a4,0x20
 340:	0705                	addi	a4,a4,1
 342:	972a                	add	a4,a4,a0
    cdst[i] = c;
 344:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 348:	0785                	addi	a5,a5,1
 34a:	fee79de3          	bne	a5,a4,344 <memset+0x16>
  }
  return dst;
}
 34e:	6422                	ld	s0,8(sp)
 350:	0141                	addi	sp,sp,16
 352:	8082                	ret

0000000000000354 <strchr>:

char*
strchr(const char *s, char c)
{
 354:	1141                	addi	sp,sp,-16
 356:	e422                	sd	s0,8(sp)
 358:	0800                	addi	s0,sp,16
  for(; *s; s++)
 35a:	00054783          	lbu	a5,0(a0)
 35e:	cb99                	beqz	a5,374 <strchr+0x20>
    if(*s == c)
 360:	00f58763          	beq	a1,a5,36e <strchr+0x1a>
  for(; *s; s++)
 364:	0505                	addi	a0,a0,1
 366:	00054783          	lbu	a5,0(a0)
 36a:	fbfd                	bnez	a5,360 <strchr+0xc>
      return (char*)s;
  return 0;
 36c:	4501                	li	a0,0
}
 36e:	6422                	ld	s0,8(sp)
 370:	0141                	addi	sp,sp,16
 372:	8082                	ret
  return 0;
 374:	4501                	li	a0,0
 376:	bfe5                	j	36e <strchr+0x1a>

0000000000000378 <gets>:

char*
gets(char *buf, int max)
{
 378:	711d                	addi	sp,sp,-96
 37a:	ec86                	sd	ra,88(sp)
 37c:	e8a2                	sd	s0,80(sp)
 37e:	e4a6                	sd	s1,72(sp)
 380:	e0ca                	sd	s2,64(sp)
 382:	fc4e                	sd	s3,56(sp)
 384:	f852                	sd	s4,48(sp)
 386:	f456                	sd	s5,40(sp)
 388:	f05a                	sd	s6,32(sp)
 38a:	ec5e                	sd	s7,24(sp)
 38c:	1080                	addi	s0,sp,96
 38e:	8baa                	mv	s7,a0
 390:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 392:	892a                	mv	s2,a0
 394:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 396:	4aa9                	li	s5,10
 398:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 39a:	89a6                	mv	s3,s1
 39c:	2485                	addiw	s1,s1,1
 39e:	0344d863          	bge	s1,s4,3ce <gets+0x56>
    cc = read(0, &c, 1);
 3a2:	4605                	li	a2,1
 3a4:	faf40593          	addi	a1,s0,-81
 3a8:	4501                	li	a0,0
 3aa:	00000097          	auipc	ra,0x0
 3ae:	1a0080e7          	jalr	416(ra) # 54a <read>
    if(cc < 1)
 3b2:	00a05e63          	blez	a0,3ce <gets+0x56>
    buf[i++] = c;
 3b6:	faf44783          	lbu	a5,-81(s0)
 3ba:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3be:	01578763          	beq	a5,s5,3cc <gets+0x54>
 3c2:	0905                	addi	s2,s2,1
 3c4:	fd679be3          	bne	a5,s6,39a <gets+0x22>
  for(i=0; i+1 < max; ){
 3c8:	89a6                	mv	s3,s1
 3ca:	a011                	j	3ce <gets+0x56>
 3cc:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3ce:	99de                	add	s3,s3,s7
 3d0:	00098023          	sb	zero,0(s3) # f4000 <__global_pointer$+0xf2ccf>
  return buf;
}
 3d4:	855e                	mv	a0,s7
 3d6:	60e6                	ld	ra,88(sp)
 3d8:	6446                	ld	s0,80(sp)
 3da:	64a6                	ld	s1,72(sp)
 3dc:	6906                	ld	s2,64(sp)
 3de:	79e2                	ld	s3,56(sp)
 3e0:	7a42                	ld	s4,48(sp)
 3e2:	7aa2                	ld	s5,40(sp)
 3e4:	7b02                	ld	s6,32(sp)
 3e6:	6be2                	ld	s7,24(sp)
 3e8:	6125                	addi	sp,sp,96
 3ea:	8082                	ret

00000000000003ec <stat>:

int
stat(const char *n, struct stat *st)
{
 3ec:	1101                	addi	sp,sp,-32
 3ee:	ec06                	sd	ra,24(sp)
 3f0:	e822                	sd	s0,16(sp)
 3f2:	e426                	sd	s1,8(sp)
 3f4:	e04a                	sd	s2,0(sp)
 3f6:	1000                	addi	s0,sp,32
 3f8:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3fa:	4581                	li	a1,0
 3fc:	00000097          	auipc	ra,0x0
 400:	176080e7          	jalr	374(ra) # 572 <open>
  if(fd < 0)
 404:	02054563          	bltz	a0,42e <stat+0x42>
 408:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 40a:	85ca                	mv	a1,s2
 40c:	00000097          	auipc	ra,0x0
 410:	17e080e7          	jalr	382(ra) # 58a <fstat>
 414:	892a                	mv	s2,a0
  close(fd);
 416:	8526                	mv	a0,s1
 418:	00000097          	auipc	ra,0x0
 41c:	142080e7          	jalr	322(ra) # 55a <close>
  return r;
}
 420:	854a                	mv	a0,s2
 422:	60e2                	ld	ra,24(sp)
 424:	6442                	ld	s0,16(sp)
 426:	64a2                	ld	s1,8(sp)
 428:	6902                	ld	s2,0(sp)
 42a:	6105                	addi	sp,sp,32
 42c:	8082                	ret
    return -1;
 42e:	597d                	li	s2,-1
 430:	bfc5                	j	420 <stat+0x34>

0000000000000432 <atoi>:

int
atoi(const char *s)
{
 432:	1141                	addi	sp,sp,-16
 434:	e422                	sd	s0,8(sp)
 436:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 438:	00054603          	lbu	a2,0(a0)
 43c:	fd06079b          	addiw	a5,a2,-48
 440:	0ff7f793          	andi	a5,a5,255
 444:	4725                	li	a4,9
 446:	02f76963          	bltu	a4,a5,478 <atoi+0x46>
 44a:	86aa                	mv	a3,a0
  n = 0;
 44c:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 44e:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 450:	0685                	addi	a3,a3,1
 452:	0025179b          	slliw	a5,a0,0x2
 456:	9fa9                	addw	a5,a5,a0
 458:	0017979b          	slliw	a5,a5,0x1
 45c:	9fb1                	addw	a5,a5,a2
 45e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 462:	0006c603          	lbu	a2,0(a3)
 466:	fd06071b          	addiw	a4,a2,-48
 46a:	0ff77713          	andi	a4,a4,255
 46e:	fee5f1e3          	bgeu	a1,a4,450 <atoi+0x1e>
  return n;
}
 472:	6422                	ld	s0,8(sp)
 474:	0141                	addi	sp,sp,16
 476:	8082                	ret
  n = 0;
 478:	4501                	li	a0,0
 47a:	bfe5                	j	472 <atoi+0x40>

000000000000047c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 47c:	1141                	addi	sp,sp,-16
 47e:	e422                	sd	s0,8(sp)
 480:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 482:	02b57663          	bgeu	a0,a1,4ae <memmove+0x32>
    while(n-- > 0)
 486:	02c05163          	blez	a2,4a8 <memmove+0x2c>
 48a:	fff6079b          	addiw	a5,a2,-1
 48e:	1782                	slli	a5,a5,0x20
 490:	9381                	srli	a5,a5,0x20
 492:	0785                	addi	a5,a5,1
 494:	97aa                	add	a5,a5,a0
  dst = vdst;
 496:	872a                	mv	a4,a0
      *dst++ = *src++;
 498:	0585                	addi	a1,a1,1
 49a:	0705                	addi	a4,a4,1
 49c:	fff5c683          	lbu	a3,-1(a1)
 4a0:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 4a4:	fee79ae3          	bne	a5,a4,498 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 4a8:	6422                	ld	s0,8(sp)
 4aa:	0141                	addi	sp,sp,16
 4ac:	8082                	ret
    dst += n;
 4ae:	00c50733          	add	a4,a0,a2
    src += n;
 4b2:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 4b4:	fec05ae3          	blez	a2,4a8 <memmove+0x2c>
 4b8:	fff6079b          	addiw	a5,a2,-1
 4bc:	1782                	slli	a5,a5,0x20
 4be:	9381                	srli	a5,a5,0x20
 4c0:	fff7c793          	not	a5,a5
 4c4:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4c6:	15fd                	addi	a1,a1,-1
 4c8:	177d                	addi	a4,a4,-1
 4ca:	0005c683          	lbu	a3,0(a1)
 4ce:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4d2:	fee79ae3          	bne	a5,a4,4c6 <memmove+0x4a>
 4d6:	bfc9                	j	4a8 <memmove+0x2c>

00000000000004d8 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4d8:	1141                	addi	sp,sp,-16
 4da:	e422                	sd	s0,8(sp)
 4dc:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4de:	ca05                	beqz	a2,50e <memcmp+0x36>
 4e0:	fff6069b          	addiw	a3,a2,-1
 4e4:	1682                	slli	a3,a3,0x20
 4e6:	9281                	srli	a3,a3,0x20
 4e8:	0685                	addi	a3,a3,1
 4ea:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 4ec:	00054783          	lbu	a5,0(a0)
 4f0:	0005c703          	lbu	a4,0(a1)
 4f4:	00e79863          	bne	a5,a4,504 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 4f8:	0505                	addi	a0,a0,1
    p2++;
 4fa:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4fc:	fed518e3          	bne	a0,a3,4ec <memcmp+0x14>
  }
  return 0;
 500:	4501                	li	a0,0
 502:	a019                	j	508 <memcmp+0x30>
      return *p1 - *p2;
 504:	40e7853b          	subw	a0,a5,a4
}
 508:	6422                	ld	s0,8(sp)
 50a:	0141                	addi	sp,sp,16
 50c:	8082                	ret
  return 0;
 50e:	4501                	li	a0,0
 510:	bfe5                	j	508 <memcmp+0x30>

0000000000000512 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 512:	1141                	addi	sp,sp,-16
 514:	e406                	sd	ra,8(sp)
 516:	e022                	sd	s0,0(sp)
 518:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 51a:	00000097          	auipc	ra,0x0
 51e:	f62080e7          	jalr	-158(ra) # 47c <memmove>
}
 522:	60a2                	ld	ra,8(sp)
 524:	6402                	ld	s0,0(sp)
 526:	0141                	addi	sp,sp,16
 528:	8082                	ret

000000000000052a <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 52a:	4885                	li	a7,1
 ecall
 52c:	00000073          	ecall
 ret
 530:	8082                	ret

0000000000000532 <exit>:
.global exit
exit:
 li a7, SYS_exit
 532:	4889                	li	a7,2
 ecall
 534:	00000073          	ecall
 ret
 538:	8082                	ret

000000000000053a <wait>:
.global wait
wait:
 li a7, SYS_wait
 53a:	488d                	li	a7,3
 ecall
 53c:	00000073          	ecall
 ret
 540:	8082                	ret

0000000000000542 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 542:	4891                	li	a7,4
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <read>:
.global read
read:
 li a7, SYS_read
 54a:	4895                	li	a7,5
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <write>:
.global write
write:
 li a7, SYS_write
 552:	48c1                	li	a7,16
 ecall
 554:	00000073          	ecall
 ret
 558:	8082                	ret

000000000000055a <close>:
.global close
close:
 li a7, SYS_close
 55a:	48d5                	li	a7,21
 ecall
 55c:	00000073          	ecall
 ret
 560:	8082                	ret

0000000000000562 <kill>:
.global kill
kill:
 li a7, SYS_kill
 562:	4899                	li	a7,6
 ecall
 564:	00000073          	ecall
 ret
 568:	8082                	ret

000000000000056a <exec>:
.global exec
exec:
 li a7, SYS_exec
 56a:	489d                	li	a7,7
 ecall
 56c:	00000073          	ecall
 ret
 570:	8082                	ret

0000000000000572 <open>:
.global open
open:
 li a7, SYS_open
 572:	48bd                	li	a7,15
 ecall
 574:	00000073          	ecall
 ret
 578:	8082                	ret

000000000000057a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 57a:	48c5                	li	a7,17
 ecall
 57c:	00000073          	ecall
 ret
 580:	8082                	ret

0000000000000582 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 582:	48c9                	li	a7,18
 ecall
 584:	00000073          	ecall
 ret
 588:	8082                	ret

000000000000058a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 58a:	48a1                	li	a7,8
 ecall
 58c:	00000073          	ecall
 ret
 590:	8082                	ret

0000000000000592 <link>:
.global link
link:
 li a7, SYS_link
 592:	48cd                	li	a7,19
 ecall
 594:	00000073          	ecall
 ret
 598:	8082                	ret

000000000000059a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 59a:	48d1                	li	a7,20
 ecall
 59c:	00000073          	ecall
 ret
 5a0:	8082                	ret

00000000000005a2 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 5a2:	48a5                	li	a7,9
 ecall
 5a4:	00000073          	ecall
 ret
 5a8:	8082                	ret

00000000000005aa <dup>:
.global dup
dup:
 li a7, SYS_dup
 5aa:	48a9                	li	a7,10
 ecall
 5ac:	00000073          	ecall
 ret
 5b0:	8082                	ret

00000000000005b2 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 5b2:	48ad                	li	a7,11
 ecall
 5b4:	00000073          	ecall
 ret
 5b8:	8082                	ret

00000000000005ba <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5ba:	48b1                	li	a7,12
 ecall
 5bc:	00000073          	ecall
 ret
 5c0:	8082                	ret

00000000000005c2 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5c2:	48b5                	li	a7,13
 ecall
 5c4:	00000073          	ecall
 ret
 5c8:	8082                	ret

00000000000005ca <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5ca:	48b9                	li	a7,14
 ecall
 5cc:	00000073          	ecall
 ret
 5d0:	8082                	ret

00000000000005d2 <pause_system>:
.global pause_system
pause_system:
 li a7, SYS_pause_system
 5d2:	48d9                	li	a7,22
 ecall
 5d4:	00000073          	ecall
 ret
 5d8:	8082                	ret

00000000000005da <kill_system>:
.global kill_system
kill_system:
 li a7, SYS_kill_system
 5da:	48dd                	li	a7,23
 ecall
 5dc:	00000073          	ecall
 ret
 5e0:	8082                	ret

00000000000005e2 <print_stats>:
.global print_stats
print_stats:
 li a7, SYS_print_stats
 5e2:	48e1                	li	a7,24
 ecall
 5e4:	00000073          	ecall
 ret
 5e8:	8082                	ret

00000000000005ea <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5ea:	1101                	addi	sp,sp,-32
 5ec:	ec06                	sd	ra,24(sp)
 5ee:	e822                	sd	s0,16(sp)
 5f0:	1000                	addi	s0,sp,32
 5f2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5f6:	4605                	li	a2,1
 5f8:	fef40593          	addi	a1,s0,-17
 5fc:	00000097          	auipc	ra,0x0
 600:	f56080e7          	jalr	-170(ra) # 552 <write>
}
 604:	60e2                	ld	ra,24(sp)
 606:	6442                	ld	s0,16(sp)
 608:	6105                	addi	sp,sp,32
 60a:	8082                	ret

000000000000060c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 60c:	7139                	addi	sp,sp,-64
 60e:	fc06                	sd	ra,56(sp)
 610:	f822                	sd	s0,48(sp)
 612:	f426                	sd	s1,40(sp)
 614:	f04a                	sd	s2,32(sp)
 616:	ec4e                	sd	s3,24(sp)
 618:	0080                	addi	s0,sp,64
 61a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 61c:	c299                	beqz	a3,622 <printint+0x16>
 61e:	0805c863          	bltz	a1,6ae <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 622:	2581                	sext.w	a1,a1
  neg = 0;
 624:	4881                	li	a7,0
 626:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 62a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 62c:	2601                	sext.w	a2,a2
 62e:	00000517          	auipc	a0,0x0
 632:	4f250513          	addi	a0,a0,1266 # b20 <digits>
 636:	883a                	mv	a6,a4
 638:	2705                	addiw	a4,a4,1
 63a:	02c5f7bb          	remuw	a5,a1,a2
 63e:	1782                	slli	a5,a5,0x20
 640:	9381                	srli	a5,a5,0x20
 642:	97aa                	add	a5,a5,a0
 644:	0007c783          	lbu	a5,0(a5)
 648:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 64c:	0005879b          	sext.w	a5,a1
 650:	02c5d5bb          	divuw	a1,a1,a2
 654:	0685                	addi	a3,a3,1
 656:	fec7f0e3          	bgeu	a5,a2,636 <printint+0x2a>
  if(neg)
 65a:	00088b63          	beqz	a7,670 <printint+0x64>
    buf[i++] = '-';
 65e:	fd040793          	addi	a5,s0,-48
 662:	973e                	add	a4,a4,a5
 664:	02d00793          	li	a5,45
 668:	fef70823          	sb	a5,-16(a4)
 66c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 670:	02e05863          	blez	a4,6a0 <printint+0x94>
 674:	fc040793          	addi	a5,s0,-64
 678:	00e78933          	add	s2,a5,a4
 67c:	fff78993          	addi	s3,a5,-1
 680:	99ba                	add	s3,s3,a4
 682:	377d                	addiw	a4,a4,-1
 684:	1702                	slli	a4,a4,0x20
 686:	9301                	srli	a4,a4,0x20
 688:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 68c:	fff94583          	lbu	a1,-1(s2)
 690:	8526                	mv	a0,s1
 692:	00000097          	auipc	ra,0x0
 696:	f58080e7          	jalr	-168(ra) # 5ea <putc>
  while(--i >= 0)
 69a:	197d                	addi	s2,s2,-1
 69c:	ff3918e3          	bne	s2,s3,68c <printint+0x80>
}
 6a0:	70e2                	ld	ra,56(sp)
 6a2:	7442                	ld	s0,48(sp)
 6a4:	74a2                	ld	s1,40(sp)
 6a6:	7902                	ld	s2,32(sp)
 6a8:	69e2                	ld	s3,24(sp)
 6aa:	6121                	addi	sp,sp,64
 6ac:	8082                	ret
    x = -xx;
 6ae:	40b005bb          	negw	a1,a1
    neg = 1;
 6b2:	4885                	li	a7,1
    x = -xx;
 6b4:	bf8d                	j	626 <printint+0x1a>

00000000000006b6 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6b6:	7119                	addi	sp,sp,-128
 6b8:	fc86                	sd	ra,120(sp)
 6ba:	f8a2                	sd	s0,112(sp)
 6bc:	f4a6                	sd	s1,104(sp)
 6be:	f0ca                	sd	s2,96(sp)
 6c0:	ecce                	sd	s3,88(sp)
 6c2:	e8d2                	sd	s4,80(sp)
 6c4:	e4d6                	sd	s5,72(sp)
 6c6:	e0da                	sd	s6,64(sp)
 6c8:	fc5e                	sd	s7,56(sp)
 6ca:	f862                	sd	s8,48(sp)
 6cc:	f466                	sd	s9,40(sp)
 6ce:	f06a                	sd	s10,32(sp)
 6d0:	ec6e                	sd	s11,24(sp)
 6d2:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6d4:	0005c903          	lbu	s2,0(a1)
 6d8:	18090f63          	beqz	s2,876 <vprintf+0x1c0>
 6dc:	8aaa                	mv	s5,a0
 6de:	8b32                	mv	s6,a2
 6e0:	00158493          	addi	s1,a1,1
  state = 0;
 6e4:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6e6:	02500a13          	li	s4,37
      if(c == 'd'){
 6ea:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6ee:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6f2:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6f6:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6fa:	00000b97          	auipc	s7,0x0
 6fe:	426b8b93          	addi	s7,s7,1062 # b20 <digits>
 702:	a839                	j	720 <vprintf+0x6a>
        putc(fd, c);
 704:	85ca                	mv	a1,s2
 706:	8556                	mv	a0,s5
 708:	00000097          	auipc	ra,0x0
 70c:	ee2080e7          	jalr	-286(ra) # 5ea <putc>
 710:	a019                	j	716 <vprintf+0x60>
    } else if(state == '%'){
 712:	01498f63          	beq	s3,s4,730 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 716:	0485                	addi	s1,s1,1
 718:	fff4c903          	lbu	s2,-1(s1)
 71c:	14090d63          	beqz	s2,876 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 720:	0009079b          	sext.w	a5,s2
    if(state == 0){
 724:	fe0997e3          	bnez	s3,712 <vprintf+0x5c>
      if(c == '%'){
 728:	fd479ee3          	bne	a5,s4,704 <vprintf+0x4e>
        state = '%';
 72c:	89be                	mv	s3,a5
 72e:	b7e5                	j	716 <vprintf+0x60>
      if(c == 'd'){
 730:	05878063          	beq	a5,s8,770 <vprintf+0xba>
      } else if(c == 'l') {
 734:	05978c63          	beq	a5,s9,78c <vprintf+0xd6>
      } else if(c == 'x') {
 738:	07a78863          	beq	a5,s10,7a8 <vprintf+0xf2>
      } else if(c == 'p') {
 73c:	09b78463          	beq	a5,s11,7c4 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 740:	07300713          	li	a4,115
 744:	0ce78663          	beq	a5,a4,810 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 748:	06300713          	li	a4,99
 74c:	0ee78e63          	beq	a5,a4,848 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 750:	11478863          	beq	a5,s4,860 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 754:	85d2                	mv	a1,s4
 756:	8556                	mv	a0,s5
 758:	00000097          	auipc	ra,0x0
 75c:	e92080e7          	jalr	-366(ra) # 5ea <putc>
        putc(fd, c);
 760:	85ca                	mv	a1,s2
 762:	8556                	mv	a0,s5
 764:	00000097          	auipc	ra,0x0
 768:	e86080e7          	jalr	-378(ra) # 5ea <putc>
      }
      state = 0;
 76c:	4981                	li	s3,0
 76e:	b765                	j	716 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 770:	008b0913          	addi	s2,s6,8
 774:	4685                	li	a3,1
 776:	4629                	li	a2,10
 778:	000b2583          	lw	a1,0(s6)
 77c:	8556                	mv	a0,s5
 77e:	00000097          	auipc	ra,0x0
 782:	e8e080e7          	jalr	-370(ra) # 60c <printint>
 786:	8b4a                	mv	s6,s2
      state = 0;
 788:	4981                	li	s3,0
 78a:	b771                	j	716 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 78c:	008b0913          	addi	s2,s6,8
 790:	4681                	li	a3,0
 792:	4629                	li	a2,10
 794:	000b2583          	lw	a1,0(s6)
 798:	8556                	mv	a0,s5
 79a:	00000097          	auipc	ra,0x0
 79e:	e72080e7          	jalr	-398(ra) # 60c <printint>
 7a2:	8b4a                	mv	s6,s2
      state = 0;
 7a4:	4981                	li	s3,0
 7a6:	bf85                	j	716 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7a8:	008b0913          	addi	s2,s6,8
 7ac:	4681                	li	a3,0
 7ae:	4641                	li	a2,16
 7b0:	000b2583          	lw	a1,0(s6)
 7b4:	8556                	mv	a0,s5
 7b6:	00000097          	auipc	ra,0x0
 7ba:	e56080e7          	jalr	-426(ra) # 60c <printint>
 7be:	8b4a                	mv	s6,s2
      state = 0;
 7c0:	4981                	li	s3,0
 7c2:	bf91                	j	716 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7c4:	008b0793          	addi	a5,s6,8
 7c8:	f8f43423          	sd	a5,-120(s0)
 7cc:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7d0:	03000593          	li	a1,48
 7d4:	8556                	mv	a0,s5
 7d6:	00000097          	auipc	ra,0x0
 7da:	e14080e7          	jalr	-492(ra) # 5ea <putc>
  putc(fd, 'x');
 7de:	85ea                	mv	a1,s10
 7e0:	8556                	mv	a0,s5
 7e2:	00000097          	auipc	ra,0x0
 7e6:	e08080e7          	jalr	-504(ra) # 5ea <putc>
 7ea:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7ec:	03c9d793          	srli	a5,s3,0x3c
 7f0:	97de                	add	a5,a5,s7
 7f2:	0007c583          	lbu	a1,0(a5)
 7f6:	8556                	mv	a0,s5
 7f8:	00000097          	auipc	ra,0x0
 7fc:	df2080e7          	jalr	-526(ra) # 5ea <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 800:	0992                	slli	s3,s3,0x4
 802:	397d                	addiw	s2,s2,-1
 804:	fe0914e3          	bnez	s2,7ec <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 808:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 80c:	4981                	li	s3,0
 80e:	b721                	j	716 <vprintf+0x60>
        s = va_arg(ap, char*);
 810:	008b0993          	addi	s3,s6,8
 814:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 818:	02090163          	beqz	s2,83a <vprintf+0x184>
        while(*s != 0){
 81c:	00094583          	lbu	a1,0(s2)
 820:	c9a1                	beqz	a1,870 <vprintf+0x1ba>
          putc(fd, *s);
 822:	8556                	mv	a0,s5
 824:	00000097          	auipc	ra,0x0
 828:	dc6080e7          	jalr	-570(ra) # 5ea <putc>
          s++;
 82c:	0905                	addi	s2,s2,1
        while(*s != 0){
 82e:	00094583          	lbu	a1,0(s2)
 832:	f9e5                	bnez	a1,822 <vprintf+0x16c>
        s = va_arg(ap, char*);
 834:	8b4e                	mv	s6,s3
      state = 0;
 836:	4981                	li	s3,0
 838:	bdf9                	j	716 <vprintf+0x60>
          s = "(null)";
 83a:	00000917          	auipc	s2,0x0
 83e:	2de90913          	addi	s2,s2,734 # b18 <malloc+0x198>
        while(*s != 0){
 842:	02800593          	li	a1,40
 846:	bff1                	j	822 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 848:	008b0913          	addi	s2,s6,8
 84c:	000b4583          	lbu	a1,0(s6)
 850:	8556                	mv	a0,s5
 852:	00000097          	auipc	ra,0x0
 856:	d98080e7          	jalr	-616(ra) # 5ea <putc>
 85a:	8b4a                	mv	s6,s2
      state = 0;
 85c:	4981                	li	s3,0
 85e:	bd65                	j	716 <vprintf+0x60>
        putc(fd, c);
 860:	85d2                	mv	a1,s4
 862:	8556                	mv	a0,s5
 864:	00000097          	auipc	ra,0x0
 868:	d86080e7          	jalr	-634(ra) # 5ea <putc>
      state = 0;
 86c:	4981                	li	s3,0
 86e:	b565                	j	716 <vprintf+0x60>
        s = va_arg(ap, char*);
 870:	8b4e                	mv	s6,s3
      state = 0;
 872:	4981                	li	s3,0
 874:	b54d                	j	716 <vprintf+0x60>
    }
  }
}
 876:	70e6                	ld	ra,120(sp)
 878:	7446                	ld	s0,112(sp)
 87a:	74a6                	ld	s1,104(sp)
 87c:	7906                	ld	s2,96(sp)
 87e:	69e6                	ld	s3,88(sp)
 880:	6a46                	ld	s4,80(sp)
 882:	6aa6                	ld	s5,72(sp)
 884:	6b06                	ld	s6,64(sp)
 886:	7be2                	ld	s7,56(sp)
 888:	7c42                	ld	s8,48(sp)
 88a:	7ca2                	ld	s9,40(sp)
 88c:	7d02                	ld	s10,32(sp)
 88e:	6de2                	ld	s11,24(sp)
 890:	6109                	addi	sp,sp,128
 892:	8082                	ret

0000000000000894 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 894:	715d                	addi	sp,sp,-80
 896:	ec06                	sd	ra,24(sp)
 898:	e822                	sd	s0,16(sp)
 89a:	1000                	addi	s0,sp,32
 89c:	e010                	sd	a2,0(s0)
 89e:	e414                	sd	a3,8(s0)
 8a0:	e818                	sd	a4,16(s0)
 8a2:	ec1c                	sd	a5,24(s0)
 8a4:	03043023          	sd	a6,32(s0)
 8a8:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8ac:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8b0:	8622                	mv	a2,s0
 8b2:	00000097          	auipc	ra,0x0
 8b6:	e04080e7          	jalr	-508(ra) # 6b6 <vprintf>
}
 8ba:	60e2                	ld	ra,24(sp)
 8bc:	6442                	ld	s0,16(sp)
 8be:	6161                	addi	sp,sp,80
 8c0:	8082                	ret

00000000000008c2 <printf>:

void
printf(const char *fmt, ...)
{
 8c2:	711d                	addi	sp,sp,-96
 8c4:	ec06                	sd	ra,24(sp)
 8c6:	e822                	sd	s0,16(sp)
 8c8:	1000                	addi	s0,sp,32
 8ca:	e40c                	sd	a1,8(s0)
 8cc:	e810                	sd	a2,16(s0)
 8ce:	ec14                	sd	a3,24(s0)
 8d0:	f018                	sd	a4,32(s0)
 8d2:	f41c                	sd	a5,40(s0)
 8d4:	03043823          	sd	a6,48(s0)
 8d8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8dc:	00840613          	addi	a2,s0,8
 8e0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8e4:	85aa                	mv	a1,a0
 8e6:	4505                	li	a0,1
 8e8:	00000097          	auipc	ra,0x0
 8ec:	dce080e7          	jalr	-562(ra) # 6b6 <vprintf>
}
 8f0:	60e2                	ld	ra,24(sp)
 8f2:	6442                	ld	s0,16(sp)
 8f4:	6125                	addi	sp,sp,96
 8f6:	8082                	ret

00000000000008f8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8f8:	1141                	addi	sp,sp,-16
 8fa:	e422                	sd	s0,8(sp)
 8fc:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8fe:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 902:	00000797          	auipc	a5,0x0
 906:	2367b783          	ld	a5,566(a5) # b38 <freep>
 90a:	a805                	j	93a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 90c:	4618                	lw	a4,8(a2)
 90e:	9db9                	addw	a1,a1,a4
 910:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 914:	6398                	ld	a4,0(a5)
 916:	6318                	ld	a4,0(a4)
 918:	fee53823          	sd	a4,-16(a0)
 91c:	a091                	j	960 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 91e:	ff852703          	lw	a4,-8(a0)
 922:	9e39                	addw	a2,a2,a4
 924:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 926:	ff053703          	ld	a4,-16(a0)
 92a:	e398                	sd	a4,0(a5)
 92c:	a099                	j	972 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 92e:	6398                	ld	a4,0(a5)
 930:	00e7e463          	bltu	a5,a4,938 <free+0x40>
 934:	00e6ea63          	bltu	a3,a4,948 <free+0x50>
{
 938:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 93a:	fed7fae3          	bgeu	a5,a3,92e <free+0x36>
 93e:	6398                	ld	a4,0(a5)
 940:	00e6e463          	bltu	a3,a4,948 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 944:	fee7eae3          	bltu	a5,a4,938 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 948:	ff852583          	lw	a1,-8(a0)
 94c:	6390                	ld	a2,0(a5)
 94e:	02059713          	slli	a4,a1,0x20
 952:	9301                	srli	a4,a4,0x20
 954:	0712                	slli	a4,a4,0x4
 956:	9736                	add	a4,a4,a3
 958:	fae60ae3          	beq	a2,a4,90c <free+0x14>
    bp->s.ptr = p->s.ptr;
 95c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 960:	4790                	lw	a2,8(a5)
 962:	02061713          	slli	a4,a2,0x20
 966:	9301                	srli	a4,a4,0x20
 968:	0712                	slli	a4,a4,0x4
 96a:	973e                	add	a4,a4,a5
 96c:	fae689e3          	beq	a3,a4,91e <free+0x26>
  } else
    p->s.ptr = bp;
 970:	e394                	sd	a3,0(a5)
  freep = p;
 972:	00000717          	auipc	a4,0x0
 976:	1cf73323          	sd	a5,454(a4) # b38 <freep>
}
 97a:	6422                	ld	s0,8(sp)
 97c:	0141                	addi	sp,sp,16
 97e:	8082                	ret

0000000000000980 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 980:	7139                	addi	sp,sp,-64
 982:	fc06                	sd	ra,56(sp)
 984:	f822                	sd	s0,48(sp)
 986:	f426                	sd	s1,40(sp)
 988:	f04a                	sd	s2,32(sp)
 98a:	ec4e                	sd	s3,24(sp)
 98c:	e852                	sd	s4,16(sp)
 98e:	e456                	sd	s5,8(sp)
 990:	e05a                	sd	s6,0(sp)
 992:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 994:	02051493          	slli	s1,a0,0x20
 998:	9081                	srli	s1,s1,0x20
 99a:	04bd                	addi	s1,s1,15
 99c:	8091                	srli	s1,s1,0x4
 99e:	0014899b          	addiw	s3,s1,1
 9a2:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 9a4:	00000517          	auipc	a0,0x0
 9a8:	19453503          	ld	a0,404(a0) # b38 <freep>
 9ac:	c515                	beqz	a0,9d8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9ae:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9b0:	4798                	lw	a4,8(a5)
 9b2:	02977f63          	bgeu	a4,s1,9f0 <malloc+0x70>
 9b6:	8a4e                	mv	s4,s3
 9b8:	0009871b          	sext.w	a4,s3
 9bc:	6685                	lui	a3,0x1
 9be:	00d77363          	bgeu	a4,a3,9c4 <malloc+0x44>
 9c2:	6a05                	lui	s4,0x1
 9c4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 9c8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9cc:	00000917          	auipc	s2,0x0
 9d0:	16c90913          	addi	s2,s2,364 # b38 <freep>
  if(p == (char*)-1)
 9d4:	5afd                	li	s5,-1
 9d6:	a88d                	j	a48 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 9d8:	00000797          	auipc	a5,0x0
 9dc:	16878793          	addi	a5,a5,360 # b40 <base>
 9e0:	00000717          	auipc	a4,0x0
 9e4:	14f73c23          	sd	a5,344(a4) # b38 <freep>
 9e8:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9ea:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9ee:	b7e1                	j	9b6 <malloc+0x36>
      if(p->s.size == nunits)
 9f0:	02e48b63          	beq	s1,a4,a26 <malloc+0xa6>
        p->s.size -= nunits;
 9f4:	4137073b          	subw	a4,a4,s3
 9f8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9fa:	1702                	slli	a4,a4,0x20
 9fc:	9301                	srli	a4,a4,0x20
 9fe:	0712                	slli	a4,a4,0x4
 a00:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a02:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a06:	00000717          	auipc	a4,0x0
 a0a:	12a73923          	sd	a0,306(a4) # b38 <freep>
      return (void*)(p + 1);
 a0e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a12:	70e2                	ld	ra,56(sp)
 a14:	7442                	ld	s0,48(sp)
 a16:	74a2                	ld	s1,40(sp)
 a18:	7902                	ld	s2,32(sp)
 a1a:	69e2                	ld	s3,24(sp)
 a1c:	6a42                	ld	s4,16(sp)
 a1e:	6aa2                	ld	s5,8(sp)
 a20:	6b02                	ld	s6,0(sp)
 a22:	6121                	addi	sp,sp,64
 a24:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a26:	6398                	ld	a4,0(a5)
 a28:	e118                	sd	a4,0(a0)
 a2a:	bff1                	j	a06 <malloc+0x86>
  hp->s.size = nu;
 a2c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 a30:	0541                	addi	a0,a0,16
 a32:	00000097          	auipc	ra,0x0
 a36:	ec6080e7          	jalr	-314(ra) # 8f8 <free>
  return freep;
 a3a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 a3e:	d971                	beqz	a0,a12 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a40:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a42:	4798                	lw	a4,8(a5)
 a44:	fa9776e3          	bgeu	a4,s1,9f0 <malloc+0x70>
    if(p == freep)
 a48:	00093703          	ld	a4,0(s2)
 a4c:	853e                	mv	a0,a5
 a4e:	fef719e3          	bne	a4,a5,a40 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 a52:	8552                	mv	a0,s4
 a54:	00000097          	auipc	ra,0x0
 a58:	b66080e7          	jalr	-1178(ra) # 5ba <sbrk>
  if(p == (char*)-1)
 a5c:	fd5518e3          	bne	a0,s5,a2c <malloc+0xac>
        return 0;
 a60:	4501                	li	a0,0
 a62:	bf45                	j	a12 <malloc+0x92>
