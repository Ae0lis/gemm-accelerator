#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

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

    printf("Value at register 1: %u\n", regpt[1]);
    regpt[0] = 123;
    printf("Value at register 0: %u\n", regpt[0]);
    regpt[1] = 456;
    printf("Value at register 1: %u\n", regpt[1]);

    if(munmap(mempt, HW_BRIDGE_SPAN) != 0)
    {
        printf("ERROR: Failed to unmap memory!\n");
        close(fd);
        return(1);
    }

    close(fd);
    return(0);
}