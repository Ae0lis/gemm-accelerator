#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <time.h>

#define HW_BRIDGE_ADDR ( 0xff200000 )
#define HW_BRIDGE_SPAN ( 0x00200000 )
#define REG_OFFSET     ( 0x0 )

// Read from the register

int main(void)
{
    int fd = 0;
    void *mempt = NULL;
    volatile uint32_t *regpt = NULL;

    fd = open("/dev/mem", ( O_RDWR | O_SYNC ));
    if(fd == -1)
    {
        printf("ERROR: Failed to open /dev/mem!\n");
        return(1);
    }

    mempt = mmap(NULL, HW_BRIDGE_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, HW_BRIDGE_ADDR );
    if(mempt == MAP_FAILED)
    {
        printf("ERROR: Failed to map memory!\n");
        close(fd);
        return(1);
    }

    regpt = (volatile uint32_t *) (mempt + REG_OFFSET);

    printf("ID Code: %x\n", regpt[3]);

    regpt[1] = 1000000; // Set timer

    regpt[0] = 1; // Start

    struct timespec start, end;
    if(clock_gettime(CLOCK_MONOTONIC, &start) != 0)
    {
        printf("Failed to get clock start time\n");
    }
    uint32_t status;
    int tries = 0;
    int LIMIT = 10000000;
    do {
        status = regpt[2];
        tries++;
    } while ((!(status & 0x1) || (status & 0x2)) && tries < LIMIT);

    if (tries >= LIMIT) {
        printf("timeout, status = 0x%08x\n", status);
    }

    if(clock_gettime(CLOCK_MONOTONIC, &end) != 0)
    {
        printf("Failed to get clock end time\n");
    }

    // Calculate and print time
    double time_taken = (end.tv_sec - start.tv_sec) + (end.tv_nsec - start.tv_nsec) / 1e9;
    printf("Took %f seconds to execute\n", time_taken);

    if(munmap(mempt, HW_BRIDGE_SPAN) != 0)
    {
        printf("ERROR: Failed to unmap memory!\n");
        close(fd);
        return(1);
    }

    close(fd);
    return(0);
}