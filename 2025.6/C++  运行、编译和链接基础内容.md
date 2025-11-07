# C++  运行、编译和链接基础内容

任何变成语言最终无非产生：
	1. 指令
	2. 数据

产生的可执行程序：xxx.exe 存放在磁盘上
但调用时不可能直接加载到物理内存。

```cpp
int gdata1 = 10;	// .data
int gdata2 = 0;		// .bss
int gdata3;			// .bss

static int gdata4 = 11;	// .data
static int gdata5 = 0;	// .bss
static int gdata6;		// .bss

// 以上均为数据, 创建以后会在符号表中产生符号, 存放在数据段

int main() {
    int a = 12;		// stack
    /*
    mov dword ptr[a], 0ch	// .text
    a 只是指令, 不是数据, 不在符号表中产生符号
    函数运行时, 指令运行时, 在 stack 上给 a 开辟 4 byte 空间
    */
    
    int b = 0;		// stack
    int c;			// stack

    static int e = 13;	// .data
    static int f = 0;	// .bss
    static int g;		// .bss
    

    return 0;
}
```

程序调用时 linux 系统会给当前进程分配一个 4G 的虚拟地址空间

```
-------------用户空间--------------0x00000000
|			不可用				|
----------------------------------0x08048000
|			.text	.rodata		|
.text: 代码段; 代码存放处
.rodata: 只读数据段
	当编写:
		char* p = "hello, world";
		*p = 'a';
    可以编译通过, 但是运行会报错
    因为字符串你好世界存放在 .rodata 中, 尝试修改了 .rodata 的数据
    
    通常使用以下写法:
    	const char *p = "hello, world";
    可以避免此类问题
----------------------------------
|			.data				|
存放初始化的, 且初始化数值不为 0 的
----------------------------------
|			.bss				|
存放未初始化的, 或初始化值为 0 的
	当写下:
		int gdata; // 全局
		cout << gdata << endl;
    会打印出 0
    操作系统会自动为 .bss 进行 0 初始化
----------------------------------
|			heap				|
----------------------------------
|	加载共享库: *.dll   *.so		|
----------------------------------


				^^
				||
				||
|			stak 栈空间		|
----------------------------------
|		命令行参数 和 环境变量	|
-------------内核空间--------------0xC0000000	3G
|	ZONE_DMA
|	ZONE_NORMAL
|	ZONE_HIGHMEM
-----------------------------------0xFFFFFFFF
```

每个进程的用户区是独有的，内核空间是共享的。

> 进程之间的通信方式有哪些？
> 匿名管道通信；在内核空间划分一块内存，在此处写入数据实现通信。

```cpp
#include <iostream>

using namespace std;

int sum(int a, int b) {
    int temp = 0;
    temp = a + b;
    return temp;
}

int main() {
    int a = 0, b = 0;

    int ret = sum(a, b);

    return 0;
}
```

> 1. main 函数调用 sum，sum 执行完后怎么知道回到哪个函数中？
> 2. sum 函数执行完，回到 main 后怎么知道从哪一行指令继续执行？

栈帧创建过程（从下往上看；从高地址向低地址生长）

```
esp-------------------------

		0xCCCCCCCC

		rep stos	(对新栈帧空间的初始化)
		for
		
		mov dword ptr[ebp - 4], 0		给 tmp 开辟空间
		mov eax, dword ptr[ebp + 0ch]	将 a 的值存到 寄存器
		add eax, dword ptr[ebp + 8]		a + b
		mov dword ptr[ebp - 4], eax		赋值给 tmp
		mov eax, dword ptr[ebp - 4]
		
		
		mov esp, ebp			'}'产生的行为 => 回退栈空间
		
		回退后：
			pop ebp				出栈并将栈顶赋给 ebp
						ebp 回到 0x0018ff40 main 函数的栈底
			ret					把出栈的内容放入 pc 寄存器中
ebp-------------------------
		0x0018ff40
		psuh ebp			'{' 产生的行为
		mov ebp, esp
		sub esp, 4Ch	(给函数开辟4Ch空间)
esp'-------------------------
		0x08124458
-----------------------------
		call sum
		(完成两件事:
		1. 把此行指令的下一行的地址压栈
		2.)
		add esp, 8		----0x08124458		把形参栈帧清除
		mov dword ptr[ebp - 0ch], eax		把寄存器中的数值放入 ret 中
	
		(形参压栈完成, 进行函数调用)
-----------------------------
		10 => int a			压栈 (形参 a 的内存)
-----------------------------
		20 => int b			压栈 (形参 b 的内存)
		
		mov eax, dword ptr[ebp - 8]
		push eax
		mov eax, dword ptr[ebp - 4]
		push eax
esp--------------------------0x

-----------------------------	
		ret					以下为 mov 指令
-----------------------------	不涉及压栈
		b(ebp - 8)		20
-----------------------------
		a(ebp - 4)		10
ebp--------------------------0x0018ff40
						main 函数栈帧
```



因此，对于：

```cpp
int * func() {
    int data = 10;
    return & data;
}
```

为不安全的写法；当 } 执行后栈帧回退，栈空间已经交还给系统。
但是：

```cpp
int * p = func();
cout << *p << endl;
```

可以正常输出，栈帧回退并没有对栈空间进行清理

ps：

+ 当返回值 < 4 byte 时，由寄存器 eax 带回返回值。
+ 当 4 < 返回值 < 8 byte 时，由寄存器 eax, edx 带回返回值。
+ 当返回值 > 8 时，会产生临时量带出返回值。



编译过程：

|                       | 预编译                                             | 编译     | 汇编                     | 二进制可重定位的目标文件 (*.obj) |
| --------------------- | -------------------------------------------------- | -------- | ------------------------ | -------------------------------- |
| main.cpp<br />sum.cpp | # 开头的命令<br />除了如 #pragma lib，#pragma link | gcc，g++ | 根据对应架构生成汇编指令 | main.o<br />sum.o                |

链接过程：编译完成的所有 .o 文件 + 静态库文件

步骤一：
	所有 .o 文件段的合并
	符号表合并后，进行**符号解析**
步骤二：
	符号的重定位（重定向）

==> xxx.exe, a.out



假设原函数为

```shell
chipen@ubuntu:~/projects/GCCG++/build$ cat ../main.cpp
extern int gdata;
int sum(int, int);

int data = 20;


int main() {
        int a = gdata;
        int b = data;

        int ret = sum(a, b);

        return 0;
}
chipen@ubuntu:~/projects/GCCG++/build$ cat ../sum.cpp
int gdata = 10;

int sum(int a, int b) {
        return a + b;
}
```

检查符号表

```shell
chipen@ubuntu:~/projects/GCCG++/build$ objdump -t sum.o

sum.o:     file format elf64-x86-64

SYMBOL TABLE:
0000000000000000 l    df *ABS*  0000000000000000 sum.cpp
0000000000000000 l    d  .text  0000000000000000 .text
0000000000000000 g     O .data  0000000000000004 gdata
0000000000000000 g     F .text  0000000000000018 _Z3sumii


chipen@ubuntu:~/projects/GCCG++/build$ objdump -t main.o

main.o:     file format elf64-x86-64

SYMBOL TABLE:
0000000000000000 l    df *ABS*  0000000000000000 main.cpp
0000000000000000 l    d  .text  0000000000000000 .text
0000000000000000 g     O .data  0000000000000004 data		# 全局变量且不为 0，放在 .data
0000000000000000 g     F .text  0000000000000037 main		# main 函数存放在代码段
0000000000000000         *UND*  0000000000000000 gdata		# 也产生了符号
0000000000000000         *UND*  0000000000000000 _Z3sumii	# 符号
# 上面两个虽然产生符号但是不知道放在哪里（UND），只是对符号的引用
```

注释：

```shell
chipen@ubuntu:~/projects/GCCG++/build$ cat ../main.cpp
extern int gdata;		# 生成符号 *UND*
int sum(int, int);		# *UND*

int data = 20;			# .data


int main() {			# .text
        int a = gdata;
        int b = data;

        int ret = sum(a, b);

        return 0;
}chipen@ubuntu:~/projects/GCCG++/build$ cat ../sum.cpp
int gdata = 10;			# .data

int sum(int a, int b) {	# sum_int_int	.text
        return a + b;
```

ps：.o 文件的格式组成

```shell
ELF 文件头
.text
.data
.rodata
.bss
.symbal			# 符号表
.section_table

编译过程中符号是不分配虚拟地址的，分配在链接阶段完成	
```

带上调试信息再观察：

```shell
chipen@ubuntu:~/projects/GCCG++/build$ objdump -S main.o

main.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
int sum(int, int);

int data = 20;


int main() {
   0:   f3 0f 1e fa             endbr64
   4:   55                      push   %rbp
   5:   48 89 e5                mov    %rsp,%rbp
   8:   48 83 ec 10             sub    $0x10,%rsp
        int a = gdata;
   c:   8b 05 00 00 00 00       mov    0x0(%rip),%eax        # 12 <main+0x12>
  12:   89 45 f4                mov    %eax,-0xc(%rbp)
        int b = data;
  15:   8b 05 00 00 00 00       mov    0x0(%rip),%eax        # 1b <main+0x1b>
  1b:   89 45 f8                mov    %eax,-0x8(%rbp)

        int ret = sum(a, b);
  1e:   8b 55 f8                mov    -0x8(%rbp),%edx
  21:   8b 45 f4                mov    -0xc(%rbp),%eax
  24:   89 d6                   mov    %edx,%esi
  26:   89 c7                   mov    %eax,%edi
  28:   e8 00 00 00 00          call   2d <main+0x2d>
  2d:   89 45 fc                mov    %eax,-0x4(%rbp)

        return 0;
  30:   b8 00 00 00 00          mov    $0x0,%eax
  35:   c9                      leave
  36:   c3                      ret
chipen@ubuntu:~/projects/GCCG++/build$ objdump -S sum.o

sum.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <_Z3sumii>:
int gdata = 10;

int sum(int a, int b) {
   0:   f3 0f 1e fa             endbr64
   4:   55                      push   %rbp
   5:   48 89 e5                mov    %rsp,%rbp
   8:   89 7d fc                mov    %edi,-0x4(%rbp)
   b:   89 75 f8                mov    %esi,-0x8(%rbp)
        return a + b;
   e:   8b 55 fc                mov    -0x4(%rbp),%edx
  11:   8b 45 f8                mov    -0x8(%rbp),%eax
  14:   01 d0                   add    %edx,%eax
  16:   5d                      pop    %rbp
  17:   c3                      ret
```

从目标文件到可执行文件过程中：
合并了所有目标文件各个段：符号表的合并；**所有对符号的引用（UND）都要找到该符号定义的地方**
给所有符号（UND）分配虚拟地址 => 符号的重定向

不妨对比一下目标文件和可执行文件反汇编后的异同

```shell
chipen@ubuntu:~/projects/GCCG++/build$ objdump -t main.out

main.out:     file format elf64-x86-64

SYMBOL TABLE:
0000000000000000 l    df *ABS*  0000000000000000              Scrt1.o
00000000000003fc l     O .note.ABI-tag  0000000000000020              __abi_tag
...
0000000000000000 l    df *ABS*  0000000000000000              main.cpp
0000000000000000 l    df *ABS*  0000000000000000              sum.cpp
0000000000000000 l    df *ABS*  0000000000000000              crtstuff.c
...
0000000000004014 g     O .data  0000000000000004              gdata
0000000000001160 g     F .text  0000000000000018              _Z3sumii
...
0000000000004010 g     O .data  0000000000000004              data
0000000000004020 g       .bss   0000000000000000              _end
0000000000001040 g     F .text  0000000000000026              _start
0000000000004018 g       .bss   0000000000000000              __bss_start
0000000000001129 g     F .text  0000000000000037              main
...
```

可见各符号已经找到了对应的位置了

```shell
chipen@ubuntu:~/projects/GCCG++/build$ readelf -h main.out
ELF Header:
  Magic:   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00
  Class:                             ELF64
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              DYN (Position-Independent Executable file)	# 可执行文件
  Machine:                           Advanced Micro Devices X86-64
  Version:                           0x1
  Entry point address:               0x1040			# 入口地址
  Start of program headers:          64 (bytes into file)
  Start of section headers:          14056 (bytes into file)
  Flags:                             0x0
  Size of this header:               64 (bytes)
  Size of program headers:           56 (bytes)
  Number of program headers:         13
  Size of section headers:           64 (bytes)
  Number of section headers:         30
  Section header string table index: 29
```

> 程序执行后，是一股脑把数据都加载到内存中吗？
> 检查程序头中： LOAD 段告诉程序把那些段加载到内存中
>
> ```shell
> chipen@ubuntu:~/projects/GCCG++/build$ readelf -l main.out
> 
> Elf file type is DYN (Position-Independent Executable file)
> Entry point 0x1040
> There are 13 program headers, starting at offset 64
> 
> Program Headers:
>   Type           Offset             VirtAddr           PhysAddr
>                  FileSiz            MemSiz              Flags  Align
>   PHDR           0x0000000000000040 0x0000000000000040 0x0000000000000040
>                  0x00000000000002d8 0x00000000000002d8  R      0x8
>   INTERP         0x0000000000000318 0x0000000000000318 0x0000000000000318
>                  0x000000000000001c 0x000000000000001c  R      0x1
>       [Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]
>   LOAD           0x0000000000000000 0x0000000000000000 0x0000000000000000
>                  0x0000000000000660 0x0000000000000660  R      0x1000
>   LOAD           0x0000000000001000 0x0000000000001000 0x0000000000001000
>                  0x0000000000000185 0x0000000000000185  R E    0x1000
>   LOAD           0x0000000000002000 0x0000000000002000 0x0000000000002000
>                  0x00000000000000ec 0x00000000000000ec  R      0x1000
>   LOAD           0x0000000000002df0 0x0000000000003df0 0x0000000000003df0
>                  0x0000000000000228 0x0000000000000230  RW     0x1000
>   DYNAMIC        0x0000000000002e00 0x0000000000003e00 0x0000000000003e00
>                  0x00000000000001c0 0x00000000000001c0  RW     0x8
> ...
> ```
>
> 
