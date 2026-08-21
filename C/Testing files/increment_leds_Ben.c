#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h>

#define HW_BRIDGE_ADDR ( 0xff200000 )
#define HW_BRIDGE_SPAN ( 0x00200000 )
#define LED_OFFSET     ( 0x10040 )

// My own version of increment_leds, built to test my understanding of mmap on the DE1

int main(void)
{
    int fd = 0;
    void *mempt = NULL;
    volatile uint32_t *ledpt = NULL;

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

    ledpt = (volatile uint32_t *) (mempt + LED_OFFSET);

    *ledpt += 1;

    if(munmap(mempt, HW_BRIDGE_SPAN) != 0)
    {
        printf("ERROR: Failed to unmap memory!\n");
        close(fd);
        return(1);
    }

    close(fd);
    return(0);
}