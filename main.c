#include "FreeRTOS.h"
#include "gic.h"
#include "task.h"

#if configUSE_IDLE_HOOK
void vApplicationIdleHook(void)
{
  asm volatile ("cpsid if \n"
                "dsb      \n"
                "isb      \n"
                "wfi      \n"
                "cpsie if \n");
}
#endif

static void hvc_putc(int c)
{
  asm volatile (
    "mov r1, %1\n"
    "mov r0, %0\n"
    "hvc #1 \n"
    : : "i"(0x86000000), "r"(c) : "r0", "r1");
}

void hvc_puts(char const *s)
{
  char c;
  while ((c = *s++))
    hvc_putc(c);
}


static void task1(void *param)
{
	(void)param;
	while(1) {
//		hvc_puts("task1\n");
//		vTaskDelay(1);
		int a=10;
		int b=20;
	}
}

static void task2(void *param)
{
	(void)param;
	while(1) {
//		hvc_puts("task2\n");
//		vTaskDelay(1);
		int a=10;
		int b=20;
	}
}

void enableDualTimer0(unsigned int period)
{
	volatile uint32_t* DualTimer0 = (uint32_t*)0xE0101000;
	*(DualTimer0+0x2) = 0x0;	// Disable timer
	*(DualTimer0+0x0) = period;
//	*(DualTimer0+0x2) = 0xe3;	// Enable timer, ons-shot mode, enable interrupts, 32-bit counter
	*(DualTimer0+0x2) = 0xe2;	// Enable timer, periodic mode, enable interrupts, 32-bit counter
}
int main(void)
{
  xTaskCreate(task1, "task1", 200, NULL, 1, NULL);
  xTaskCreate(task2, "task2", 200, NULL, 1, NULL);

  gic_setup();

  enableDualTimer0(0x200);
//  hvc_puts("Hello from FreeRTOS!\n");
  vTaskStartScheduler();

  while(1);
  return 0;
}
