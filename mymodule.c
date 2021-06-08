#include <linux/init.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("hayatsu");
MODULE_DESCRIPTION("my module");
MODULE_VERSION("0.1");

static int __init mymodule_init(void)
{
	return 0;
}

static void __exit mymodule_exit(void)
{
}
module_init(mymodule_init);
module_exit(mymodule_exit);
