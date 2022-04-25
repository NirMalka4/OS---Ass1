#include "kernel/types.h"
#include "user/user.h"
#include "kernel/fcntl.h"


void pause_system_dem(int interval, int pause_seconds, int loop_size) {
    int pid = getpid(), i = 2;
    while(i--)
        fork();
    const uint m = (loop_size >> 1);
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0 && pid == getpid()) {
            printf("pause system %d/%d completed.\n", i, loop_size);
        }
        if (i == m) {
            pause_system(pause_seconds);
        }
    }
    printf("\n");
}

void kill_system_dem(int interval, int loop_size) {
    int pid = getpid(), i = 2;
    while(i--)
        fork();
    const uint m = (loop_size >> 1);
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0 && pid == getpid()) {
            printf("kill system %d/%d completed.\n", i, loop_size);
        }
        if (i == m) {
            kill_system();
        }
    }
    printf("\n");
}

/*
void set_economic_mode_dem(int interval, int loop_size) {
    int pid = getpid();
    set_economic_mode(1);
    for (int i = 0; i < loop_size; i++) {
        if (i % interval == 0 && pid == getpid()) {
            printf("set economic mode %d/%d completed.\n", i, loop_size);
        }
        if (i == loop_size / 2) {
            set_economic_mode(0);
        }
    }
    printf("\n");
}
*/

void env(int size, int interval, char* env_name) {
    int result = 1;
    int loop_size = 1000000;
    int n_forks = 2;
    int pid;
    for (int i = 0; i < n_forks; i++) {
        pid = fork();
        printf("%d", pid);
    }
    for (int i = 0; i < loop_size; i++) {
        if (i % loop_size / 1 == 0) {
        	if (pid == 0) {
        		printf("***%s %d/%d completed.\n", env_name, i, loop_size);
        	} else {
        		printf(" *** ");
        	}
        }
        if (i % interval == 0) {
            result = result * size;
        }
    }
    printf("\n");
}

void env_large() {
    env(1000000, 1000000, "env_large");
}

void env_freq() {
    env(10, 10, "env_freq");
}

int
main(int argc, char *argv[])
{
    //set_economic_mode_dem(10, 100);
    //pause_system_dem(10, 10, 100);
    //kill_system_dem(10, 100);
    env_large();
    print_stats();
    env_freq();
    exit(0);
}


